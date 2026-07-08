# Troubleshooting — Endpoint DLP for Windows

The failures you will actually hit, with the most likely cause and the fix. Work top-down: **most
"the policy isn't working" reports trace back to onboarding, browser coverage, condition matching, or
simulation-vs-enforce confusion — not the rule itself.** Where a portal path or cmdlet parameter is
named, **verify it against your tenant** — the Purview portal and endpoint restriction options evolve.

---

## 1. A device shows no endpoint activity at all

**Symptoms:** Copy/print/upload a matching file on a device and **nothing** appears in Activity
explorer (Devices); the policy never fires.

**Likely causes & fixes**
- **Device isn't onboarded.** The #1 cause. Confirm the device appears under **Purview → Devices**
  (Settings → Device onboarding). If not, re-run your onboarding method (Intune/GPO/local script/
  ConfigMgr). There is **no** S&C PowerShell cmdlet to onboard — it is a portal/management-tool
  action.
- **Unsupported / unpatched Windows build.** Endpoint sensing needs a supported build (Windows 10
  1809+ / Windows 11) and a current antimalware client (R3). Patch and retest.
- **Onboarding still propagating.** After onboarding, allow time for the device to register and for
  activity to surface — endpoint telemetry is **not** instant. Wait and retry.
- **Check the proxy signal:** `DLPWIN-ScopeHealth.ps1` reports managed-device counts (Graph) — but
  remember that is a **proxy**; the authoritative check is the **Devices** list in the portal.

---

## 2. Some channels work, but Chrome/Firefox uploads are invisible

**Symptoms:** Cloud-egress is caught in **Edge** but not in **Chrome** or **Firefox**.

**Fix**
- **Deploy the Microsoft Purview browser extension** to Chrome/Firefox (R7). Edge is native; Chrome/
  Firefox **cannot** see cloud-egress or clipboard-to-web without the extension.
- Until the extension is deployed, treat those browsers as **unallowed browsers** in the Endpoint DLP
  settings so egress through them is controlled rather than silently uncovered.
- Verify the extension is actually installed/managed on a sample device (via your browser enterprise
  policy).

---

## 3. The rule fires on the wrong things (false positives)

**Symptoms:** Legitimate work is flagged/blocked — a corporate USB, a sanctioned printer, an approved
SaaS upload.

**Likely causes & fixes**
- **Allow-list groups not referenced (or stale).** Add the corporate device to `USBG-Corporate`, the
  printer to `PRNG-Corporate`, or the domain to the sanctioned **service domains** list, and make sure
  the rule actually references the group.
- **Condition too broad.** If a rule keys on "all content" instead of a **sensitivity label / SIT**,
  it will match everything. Tighten the condition (R5). `DLPWIN-Validate.ps1` gate **A6** flags rules
  with no readable content condition.
- **SIT confidence/count too loose.** Raise the confidence level or instance count on the sensitive
  information type to cut noise, then re-test.
- Tune **in simulation** — never tune by loosening an already-enforcing block in production.

---

## 4. The rule doesn't fire on content it should

**Symptoms:** A file you expect to match is copied/printed with no policy match.

**Likely causes & fixes**
- **Content doesn't carry the label/SIT.** The test file must actually carry the **sensitivity label**
  or contain the **sensitive information type** the rule keys on. Confirm the label is applied / the
  SIT pattern is present (seed a known match).
- **Label not published / SIT not in scope.** Confirm the label is published to the user (Information
  Protection → Label policies) and the SIT exists (Data classification). `DLPWIN-Discovery.ps1`
  inventories both.
- **Rule disabled.** `DLPWIN-Validate.ps1` gate **A5b** flags disabled rules.

---

## 5. Simulation looks fine but enforcement doesn't block

**Symptoms:** In simulation the activity is recorded; after "turning it on" the block/warn still
doesn't happen.

**Likely causes & fixes**
- **Policy still in a Test mode.** Simulation records but does **not** block. To enforce, move the
  policy out of simulation: portal → turn the policy **On**; PowerShell →
  `Set-DlpCompliancePolicy -Identity EDLP-Windows-Pilot -Mode Enable`. `DLPWIN-Validate.ps1` gate
  **A3** shows the current mode.
- **Rule action still Audit.** The rule's endpoint restriction may be **Audit** even though the policy
  is enforcing. Set the per-channel action to **Warn/Block** per the R8 decision.
- **Device out of scope.** Enforcement only applies to devices in the policy's Devices scope. Confirm
  with `DLPWIN-ScopeHealth.ps1` / gate **A4**.
- **Propagation delay.** Policy/action changes take time to reach endpoints. Wait, then retest.

---

## 6. `New-DlpComplianceRule` fails on the endpoint restriction

**Symptoms:** `DLPWIN-Configure.ps1 -Commit` (or manual scripting) errors when setting the endpoint
restriction, e.g. an invalid Setting name or value.

**Fix**
- **Verify the exact Setting names and values for your tenant.** The endpoint-restriction Setting
  names (e.g. removable media, print, clipboard, network share, cloud egress) and permitted values
  (`Audit` / `Warn` / `Block` / `Ignore`) **evolve**. Run `Get-Help New-DlpComplianceRule -Full` and
  check current Microsoft docs, then adjust the hashtable. The script deliberately **prints the
  planned Setting names** so you can verify before `-Commit`.
- **Prefer the portal for the first build** if PowerShell parameter names are uncertain, then read the
  result back with `DLPWIN-Discovery.ps1` to learn the exact shape in your tenant.

---

## 7. `-EndpointDlpLocation` / scope errors

**Symptoms:** Creating the policy errors on the location/scope value.

**Fix**
- The **Devices** location is scoped by user/group (or `All`). Confirm the pilot group
  (`SG-EDLP-Pilot`) exists and the identifier is one your tenant accepts. `DLPWIN-ScopeHealth.ps1`
  reports the group and the current scope.
- Avoid `All` during the pilot — scope to the pilot group first (gate **A4**).

---

## 8. Activity report is empty or export fails

**Symptoms:** `DLPWIN-Report.ps1` returns no activity, or the Activity Explorer export warns and
skips.

**Likely causes & fixes**
- **Licensing/permission.** `Export-ActivityExplorerData` is licensing-dependent; the script **warns
  and degrades to policy-modes only** rather than failing. Fall back to **Purview → Activity explorer**
  (filter to **Devices**) in the portal.
- **Quiet pilot window.** A small pilot may simply have no activity in the window — widen `-Days` or
  perform the sanctioned test actions from `05-testing.md` first.
- **Role.** Ensure the connected account holds a role that can read Activity Explorer.

---

## 9. "It blocked an admin / broke a workflow" — emergency rollback

**Do this immediately, then diagnose:**
- Return the policy to **simulation** or **off**:
  `Set-DlpCompliancePolicy -Identity EDLP-Windows-Pilot -Mode TestWithoutNotifications` (simulation)
  or `-Mode Disable` (off). Either **stops enforcement at once.**
- Or set the offending **rule's action back to Audit**.
- Then work the relevant section above (usually §3 false positives or §5 scope), fix **in
  simulation**, re-validate with `DLPWIN-Validate.ps1`, and only then re-enforce.

---

## When to escalate to the determination owners (not a technical fix)

Some questions are **not** troubleshooting — they are **determinations** that belong to compliance /
security / records / HR-legal (see `global-requirements-purview.md` §5):

- *Should* this channel be **blocked** or only **audited**? → the **R8** decision owners.
- Is *this content* actually sensitive / in scope? → **compliance / data owners**.
- Is a user's action a **violation**, and what is the consequence? → **HR / legal**.

Provide them the **evidence** (`DLPWIN-Report.ps1`, Activity explorer, the validation output) — not a
verdict.
