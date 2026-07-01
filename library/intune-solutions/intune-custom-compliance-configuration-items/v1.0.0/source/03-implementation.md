# 3. Implementation Guide — Intune Custom Compliance & Configuration Items (Scripted)

Follow these steps **in order**, in the **Microsoft Intune admin center** (`https://intune.microsoft.com`).

> **Model:** Author a detection script and a JSON rule for the check the built-in settings can't
> reach, add any scripted configuration items to set the state, upload and create a custom compliance
> policy, assign to a pilot, validate evaluation and the Conditional Access effect, then expand.

Name every artifact `<Purpose> – <Scope> – <Stage>` and reuse the name verbatim across the policy,
the group, and the docs. This solution uses these names:

| Artifact | Name |
|---|---|
| Detection script | `RegAppCheck – Custom Compliance – Pilot` |
| JSON rule file | `RegAppCheck-Rule – Custom Compliance – Pilot.json` |
| Custom compliance policy | `Custom Compliance – Windows – Pilot` |
| Scripted config item | `SecuritySetting – Config Item – Pilot` |
| Pilot device group | `CustomCompliance – Devices – Pilot` |

## Step 1 — Create the scope groups
1. Entra → `Groups → New group` → Security → `CustomCompliance – Devices – Pilot` (a few
   representative devices). Create. (Or run `CUSTCOMP-Set-ScopeTargeting.ps1`.)
2. Create `CustomCompliance – Devices – Broad` (the rest of the fleet). Create.

## Step 2 — Author the detection script
The detection script runs on the device and must output a **single-line JSON object** whose property
names match the setting names your rule file references. Here is a worked example that checks a
registry value and an app version:

```powershell
# RegAppCheck – Custom Compliance – Pilot  (detection script)
$reg = (Get-ItemProperty 'HKLM:\SOFTWARE\Contoso\Security' -Name 'HardeningLevel' -ErrorAction SilentlyContinue).HardeningLevel
$app = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -eq 'Contoso Agent' } | Select-Object -First 1).DisplayVersion
$out = @{
    HardeningLevel = [int]($reg  | ForEach-Object { $_ }) 
    AgentVersion   = [string]($app | ForEach-Object { $_ })
}
return $out | ConvertTo-Json -Compress
```

Save it as a `.ps1` file. The script emits, for example, `{"HardeningLevel":2,"AgentVersion":"4.1.0"}`.

## Step 3 — Author the JSON rule file
The rule file tells Intune how to judge each setting the script returned, and the message the user
sees when a rule fails. It matches the property names from Step 2:

```json
{
  "Rules": [
    {
      "SettingName": "HardeningLevel",
      "Operator": "GreaterEquals",
      "DataType": "Int64",
      "Operand": 2,
      "MoreInfoUrl": "https://intranet.contoso.com/hardening",
      "RemediationStrings": [
        { "Language": "en_US",
          "Title": "Security hardening not applied",
          "Description": "This device must be at hardening level 2 or higher. Apply the security config item, then sync." }
      ]
    },
    {
      "SettingName": "AgentVersion",
      "Operator": "GreaterEquals",
      "DataType": "Version",
      "Operand": "4.1.0",
      "MoreInfoUrl": "https://intranet.contoso.com/agent",
      "RemediationStrings": [
        { "Language": "en_US",
          "Title": "Contoso Agent out of date",
          "Description": "Update Contoso Agent to 4.1.0 or later, then sync." }
      ]
    }
  ]
}
```

Validate the pairing before upload: run `CUSTCOMP-Validation.ps1 -ScriptPath <script.ps1> -RulePath <rule.json>`.

## Step 4 — Add scripted configuration items (set the state)
For state that must be **set** (so the rule above can pass), author a scripted configuration item.
1. Go to `Devices → Configuration → Create → New policy`.
2. Platform: Windows 10 and later. Profile type: Settings catalog. Create.
3. Name: `SecuritySetting – Config Item – Pilot`.
4. Add the setting the templates can't reach (search the settings catalog, or use a custom OMA-URI /
   registry setting that writes `HardeningLevel`). Set the required value.
5. Assignments → Add groups → `CustomCompliance – Devices – Pilot`. Create.

## Step 5 — Upload the detection script
1. Go to `Devices → Compliance → Scripts → Add`.
2. Name: `RegAppCheck – Custom Compliance – Pilot`. Next.
3. Paste the detection script from Step 2. Set `Run this script using the logged-on credentials` =
   No; `Enforce script signature check` per your standard; `Run script in 64-bit PowerShell` = Yes.
   Next.
4. Review + add.

## Step 6 — Create the custom compliance policy
1. Go to `Devices → Compliance → Create policy`.
2. Platform: Windows 10 and later. Create.
3. Name: `Custom Compliance – Windows – Pilot`. Next.
4. On Compliance settings → `Custom Compliance` → set `Custom compliance` = Require, choose the
   uploaded script `RegAppCheck – Custom Compliance – Pilot`, and upload the JSON rule file from
   Step 3. Next.
5. Actions for noncompliance: keep `Mark device noncompliant` (add a grace period if desired). Next.
6. Assignments → Add groups → `CustomCompliance – Devices – Pilot`. Next.
7. Review + create.

## Step 7 — Require compliance in Conditional Access
1. Entra → `Security → Conditional Access → New policy` (or use the existing require-compliant policy).
2. Grant → `Require device to be marked as compliant`. Start in `Report-only` mode for the pilot
   users. Save.

## Step 8 — Apply on a pilot device
1. On a pilot device, sync policy (`Settings → Accounts → Access work or school → Info → Sync`).
2. Confirm the config item applied and the detection script ran, or run `CUSTCOMP-Report.ps1`.

## Step 9 — Validate the pilot
1. Run `CUSTCOMP-Discovery.ps1` on a pilot device → confirms the device-side values the script reads.
2. Run `CUSTCOMP-Report.ps1` → confirms custom-compliance status across the pilot group (Graph).
3. Confirm a device that fails a rule shows the remediation message and turns noncompliant; confirm
   the Conditional Access report-only result reflects it. Complete the Testing Guide.

## Step 10 — Expand to production
1. Assign the detection script, config item, and custom compliance policy to
   `CustomCompliance – Devices – Broad`; roll out in waves.
2. Move the Conditional Access policy from `Report-only` to `On` once coverage is confirmed.
3. Re-validate each wave with `CUSTCOMP-Report.ps1`.

---
### Order of operations
`Scope groups → Detection script → JSON rule → Config item → Upload script → Custom compliance policy → CA require-compliant → Apply → Validate → Expand`
