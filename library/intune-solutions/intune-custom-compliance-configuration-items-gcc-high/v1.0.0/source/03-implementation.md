# Implementation — Intune Custom Compliance & Configuration Items (Scripted), Government (GCC High) Edition

This is the ordered, click-by-click implementation using the **GCC High (`*.us`)** portals. Every navigation path below is the **US Government** admin center. GCC-High-specific caveats are called out **inline at the step where they bite**, not buried at the end.

Deployment model: **Assess → Configure → Pilot → Validate → Expand**, with a gate after each phase.

> **Before you start:** finish the **Assess** phase in `02-requirements.md`. You should already have: an Intune Administrator sign-in that works at `https://intune.microsoft.us/`, the Microsoft Graph PowerShell SDK connecting with `-Environment USGov`, and a discovery script that emits valid compressed JSON on a test device.

---

## Phase 1 — Configure

### Step 1.1 — Create the pilot and production groups (Entra US Gov)

1. Go to **`https://entra.microsoft.us`** → **Groups → All groups → New group**.
2. Group type **Security**. Name it **`CUSTCOMPG-Pilot-Devices`**. Membership type **Assigned** (or Dynamic if you prefer a rule). Create.
3. Repeat to create **`CUSTCOMPG-Prod-Devices`**.
4. Add 3–10 representative test devices to `CUSTCOMPG-Pilot-Devices`.

> **GCC High caveat:** this is `entra.microsoft.us`, **not** `entra.microsoft.com`. A bookmark to the commercial portal will sign you into the wrong cloud (or nowhere). Reuse these exact group names in the JSON scoping and in `CUSTCOMPG-Set-ScopeTargeting.ps1`.

### Step 1.2 — Create the scope tag (optional but recommended)

1. **`https://intune.microsoft.us/`** → **Tenant administration → Roles → Scope (Tags) → Create**.
2. Name it **`CUSTCOMPG`**. Assign later to the compliance policy for RBAC/reporting hygiene.

> **GCC High caveat (important):** the **discovery-script upload workflow does not support scope tags**, and you must be assigned the **Default** scope tag to create/edit/view discovery scripts ([Create discovery scripts](https://learn.microsoft.com/en-us/intune/intune-service/protect/compliance-custom-script)). So the `CUSTCOMPG` scope tag applies to the **policy**, not the script. Confirm your admin holds the Default scope tag (Requirement R3) or the **Scripts → Add** blade will not let you proceed.

### Step 1.3 — Finalize the discovery script and JSON rules file

1. On a representative Windows device, run your discovery script (this solution's pattern) and confirm the **last line** is `return $hash | ConvertTo-Json -Compress` — the output must be **one compressed line** ([Create discovery scripts](https://learn.microsoft.com/en-us/intune/intune-service/protect/compliance-custom-script)).
2. Open **`CUSTCOMPG-Rules.json`** and confirm every rule's `SettingName` **exactly** matches (case-sensitive) a key returned by the script, and each rule's `DataType` matches the value's type.
3. Run **`CUSTCOMPG-Validation.ps1`** to catch key/type mismatches, JSON schema errors, and size/runtime limit risks before upload.

**JSON rules file — the shape Intune expects.** Each rule object carries: `SettingName`, `Operator` (e.g. `IsEquals`, `GreaterEquals`), `DataType` (e.g. `Boolean`, `String`, `Int64`, `Version`), `Operand` (the compliant value), a `MoreInfoUrl`, and localized `RemediationStrings` (Title + Description shown to the user in Company Portal). Example skeleton:

```json
{
  "Rules": [
    {
      "SettingName": "TPMChipPresent",
      "Operator": "IsEquals",
      "DataType": "Boolean",
      "Operand": true,
      "MoreInfoUrl": "https://aka.ms/compliance",
      "RemediationStrings": [
        {
          "Language": "en_US",
          "Title": "TPM chip must be present and enabled",
          "Description": "This device must have a TPM present. Contact the service desk."
        }
      ]
    }
  ]
}
```

> **GCC High caveat:** point `MoreInfoUrl` at an internal/government-appropriate help page, not a commercial link that GCC High users may not be able to reach. Intune does **not** validate the discovery script for syntax — test it yourself.

### Step 1.4 — Add the discovery script to Intune

1. **`https://intune.microsoft.us/`** → **Endpoint security → Device compliance → Scripts → Add → Windows**.
2. **Basics:** Name **`CUSTCOMPG-Discovery-Win`**. Add a clear description.
3. **Settings → Detection script:** paste the finalized discovery script. Configure the toggles:
   - **Run this script using the logged on credentials** — leave **No** to run as System unless your check needs the user context.
   - **Enforce script signature check** — set **Yes** only if you sign the script; otherwise **No**.
   - **Run script in 64-bit PowerShell Host** — set **Yes** if your discovery calls 64-bit-only cmdlets/paths.
4. **Review + create.**

> **GCC High caveat:** navigation is identical to commercial, but you must be in `intune.microsoft.us`. **Each discovery script binds to exactly one compliance policy** — do not try to reuse `CUSTCOMPG-Discovery-Win` across multiple policies.

### Step 1.5 — Create the custom compliance policy and attach script + JSON

1. **`https://intune.microsoft.us/`** → **Devices → Compliance → Create policy** → Platform **Windows 10 and later** → **Create**.
2. **Basics:** Name **`CUSTCOMPG-Compliance-Baseline`**.
3. **Compliance settings → Custom Compliance → Custom compliance = Require.**
   - **Select your discovery script:** choose **`CUSTCOMPG-Discovery-Win`**.
   - **Upload the JSON file:** upload **`CUSTCOMPG-Rules.json`**.
4. **Actions for noncompliance:** start conservative — **Mark device noncompliant** after a grace period (e.g., 1 day), plus an email notification. Do **not** wire this into Conditional Access yet.
5. **Scope tags:** add **`CUSTCOMPG`**.
6. **Assignments:** assign to **`CUSTCOMPG-Pilot-Devices`** only. **Create.**

> **GCC High caveat:** because Graph Explorer is unavailable in GCC High, use **`CUSTCOMPG-Discovery.ps1`** (with `-Environment USGov`) to confirm the policy and script objects exist as expected instead of poking the API in a browser.

**Gate to leave Configure:** the script `CUSTCOMPG-Discovery-Win` and policy `CUSTCOMPG-Compliance-Baseline` exist, the JSON uploaded without error, and assignment targets **only** the pilot group.

---

## Phase 2 — Pilot

### Step 2.1 — Sync and force evaluation

1. On a pilot device: **Settings → Accounts → Access work or school → Info → Sync**, or from **`https://intune.microsoft.us/` → Devices → All devices → [device] → Sync**.
2. Allow time for the discovery script to run and results to return over `*.manage.microsoft.us`.

> **GCC High caveat:** if the device's proxy **breaks TLS** on `*.manage.microsoft.us`, results never return and the device shows no custom-compliance status (not a failure — a silence). This is the #1 GCC High gotcha. Confirm R7 (SSL inspection exempted).

### Step 2.2 — Confirm results with the reporting script

1. Run **`CUSTCOMPG-Report.ps1`** (connects `-Environment USGov`) to pull per-device compliance state for `CUSTCOMPG-Compliance-Baseline` across the pilot group.
2. Cross-check in `https://intune.microsoft.us/` → **Devices → Compliance → `CUSTCOMPG-Compliance-Baseline` → Device status**.

**Gate to leave Pilot:** at least one pilot device reports a **Compliant** and one deliberately-failing device reports **Not compliant** for the expected setting — proving the script *and* the JSON grading both work end-to-end in GCC High.

---

## Phase 3 — Validate

Run the full validation playbook in `05-testing.md`. At minimum:

- Discovery output matches JSON keys (case-sensitive) on real devices — `CUSTCOMPG-Validation.ps1`.
- A known-bad device is correctly flagged **Not compliant** with the right remediation string in Company Portal (`portal.manage.microsoft.us`).
- Grace period and noncompliance actions behave as configured.
- No devices are stuck in "no result" (the TLS-inspection symptom).

**Gate to leave Validate:** every test in `05-testing.md` passes on the pilot group; false-positive/false-negative rate is zero on the deliberate test cases.

---

## Phase 4 — Expand

### Step 4.1 — Widen scope in controlled waves

1. Use **`CUSTCOMPG-Set-ScopeTargeting.ps1`** (default **`-WhatIf`** — it only *previews* membership changes) to stage devices into `CUSTCOMPG-Prod-Devices` in waves.
2. Re-run with `-WhatIf:$false` **only after** reviewing the preview.
3. In `https://intune.microsoft.us/` → **Devices → Compliance → `CUSTCOMPG-Compliance-Baseline` → Assignments**, add **`CUSTCOMPG-Prod-Devices`**.

### Step 4.2 — Only now, wire into Conditional Access (optional)

1. After a clean validation window, in `https://entra.microsoft.us` → **Protection → Conditional Access**, require **compliant device** for the target apps — expanding gradually.

> **GCC High caveat:** verify the specific Conditional Access + compliance behavior is live in **your** GCC High tenant before enforcing — government clouds can lag commercial (see `gcc-high-parity-notes.md`). Test with a pilot account first; a misconfigured CA rule can lock users out.

### Step 4.3 — Report and hand off

1. Schedule **`CUSTCOMPG-Report.ps1`** for periodic compliance snapshots.
2. Keep the discovery script, JSON, and group names under change control so the solution stays auditable.

**Gate to leave Expand:** production group fully assigned, reporting scheduled, Conditional Access (if used) enforced only after a clean validation window, and rollback steps in `06-troubleshooting.md` are known to the operators.
