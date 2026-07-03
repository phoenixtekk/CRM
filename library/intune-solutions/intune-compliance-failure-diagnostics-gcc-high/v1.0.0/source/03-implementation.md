# 3. Diagnostic Playbook — Compliance-Failure Diagnostics & Remediation (Government / GCC High)

This is a **symptom-driven** playbook. Start from what the user or the portal reports, follow the
branch, apply the fix in the **correct GCC High blade**, then validate. Every portal path uses the
**`*.us`** sovereign URLs — if you ever land on a `.com` portal, you are in the wrong cloud and the
device you're looking at isn't there.

> **Work in `https://intune.microsoft.us`** (Intune admin center) and **`https://portal.azure.us`**
> (Entra ID). Scripts connect with `Connect-MgGraph -Environment USGov` (DoD: `-Environment USGovDoD`).

> **GCC High note (read first):** before deep-diving a rule, confirm the rule's feature is actually
> **supported** in GCC High (see the ⚑ markers below and `gcc-high-parity-notes.md`). A rule that
> depends on an absent/planned Gov feature can never evaluate — that's a parity gap, not a
> misconfiguration.

---

## Step 0 — Assess: capture the exact symptom (read-only)

1. In **`intune.microsoft.us`** → **Devices → All devices**, open the affected device → **Device
   compliance**. Note the **overall state** and the **per-policy / per-setting** state.
2. Run **`INTCOMPDXG-Discovery.ps1`** (US Gov Graph) to snapshot the device: enrollment state, last
   check-in time, which compliance policies apply, and each failing setting.
3. Run **`INTCOMPDXG-Report.ps1`** to see the failure across the affected group (is this one device or
   a pattern?).

Match the **overall state** to a branch:

| Symptom (state) | Go to |
| --- | --- |
| **Not evaluated** / **No compliance policies assigned** | Branch A |
| **In grace period** | Branch B |
| **Not compliant** (a specific setting fails) | Branch C |
| **Compliant in Intune, but user still blocked** | Branch D |
| Device **missing / stale / last check-in old** | Branch E |

---

## Branch A — "Not evaluated" or "No policy assigned"

The device isn't being measured at all. In GCC High this is very often an **endpoint / TLS** problem,
not a policy problem.

**Decision tree**

1. **Is a compliance policy actually assigned to this device's group?**
   - `intune.microsoft.us` → **Devices → Compliance → Policies** → open the policy → **Assignments**.
   - If no policy targets the device's group → assign one (or use **`INTCOMPDXG-Set-ScopeTargeting.ps1`**,
     default `-WhatIf`, to preview then apply the group assignment). Done.
2. **Is the "mark devices with no compliance policy" tenant default set to *Not compliant*?**
   - **Devices → Compliance → Compliance policy settings** → **Mark devices with no compliance policy
     assigned as** → for CA to work this is usually **Not compliant**. Note the **compliance status
     validity period** here too (Branch B).
3. **Can the device reach the GCC High service endpoints?** ⚑ **GCC High-specific**
   - On the device confirm reachability of **`*.manage.microsoft.us`** and **`login.microsoftonline.us`**.
   - **Confirm the proxy is NOT doing SSL/TLS inspection** on `*.manage.microsoft.us` (and
     `*.dm.microsoft.us` for Defender/EPM). TLS interception there breaks check-in silently — classic
     GCC High cause of **Not evaluated**. Fix the proxy exclusion (section 2, R5), then force a sync.
4. **Force a check-in and re-evaluate:** device **Settings → Accounts → Access work or school → Info
   → Sync**, or **Sync** from the device page in `intune.microsoft.us`. Re-run Discovery.

**Fix → Validate:** after assignment/endpoint fix, run **`INTCOMPDXG-Validation.ps1`** and confirm the
device moves to **Compliant** (or to a specific failing setting → Branch C).

---

## Branch B — "In grace period"

The device failed a rule but is inside the configured grace window; it will flip to **Not compliant**
when the window expires.

1. Open the device → **Device compliance** → identify **which policy** granted grace and **which
   setting** is failing.
2. Treat the failing setting as **Branch C** (fix the underlying setting now, before the window
   closes).
3. Review the grace period itself: policy → **Actions for noncompliance** → the **"Mark device
   noncompliant"** schedule (in days). A grace period that's too long hides real failures; too short
   blocks users mid-remediation. Adjust deliberately, then Pilot.

---

## Branch C — "Not compliant" on a specific setting (the common case)

Read the **failing setting name** from the device's **Device compliance** detail, then jump to the
matching sub-branch. Each shows: what it checks, the GCC High nuance, where to fix it, and how to
validate.

### C1 — BitLocker / Secure Boot / Code Integrity (Device Health)
- **Checks:** the Windows compliance rules **Require BitLocker**, **Require Secure Boot**, **Require
  code integrity** — all evaluated via the **Device Health Attestation (DHA)** service.
- ⚑ **GCC High nuance:** the **core** BitLocker / Secure Boot / Code Integrity rules **do** use the
  DHA service across Commercial, **GCC High**, and DoD. However, Microsoft lists **some newer Windows
  DHA capabilities as *planned* (not yet available)** in GCC High — so a rule that depends on an
  expanded DHA capability may not evaluate. **Verify for GCC High** which specific DHA-backed attribute
  your rule uses before promising it works (see `gcc-high-parity-notes.md`).
- **Diagnose on the device:** run **`INTCOMPDXG-Discovery.ps1`** — it reports TPM readiness, Secure
  Boot state, and BitLocker OS-drive protection. Common root causes: device hasn't **rebooted** since
  encryption; firmware/TPM out of date; the device can't reach the attestation dependency
  (`has.spserv.microsoft.com`, **no SSL inspection**).
- **Fix:** encrypt the OS drive (or fix the DHA/attestation reachability), **reboot**, force a sync.
- **Validate:** `INTCOMPDXG-Validation.ps1` → the setting reports PASS and the device turns Compliant.

### C2 — Minimum OS version / OS build
- **Checks:** the device's OS build meets the policy's **Minimum OS version**.
- **Fix:** patch the device. Note ⚑ that several **Windows update features** (feature/quality/expedite/
  driver updates, Autopatch) are **not available in GCC High**, so you cannot lean on those Intune
  update workflows to remediate — use your available patching mechanism, then re-sync.
- **Validate:** `winver` on the device; re-run Validation.

### C3 — Antivirus / antispyware / Microsoft Defender real-time protection
- **Checks:** Defender is on, signatures current, real-time protection enabled.
- ⚑ **GCC High nuance:** **Defender for Endpoint security-settings-management is supported** in GCC
  High and DoD (you can manage Defender on Defender-onboarded devices via Intune). Confirm the device
  reaches **`*.dm.microsoft.us`** (**no SSL inspection**) for Defender check-in.
- **Fix:** enable/repair Defender; confirm signature update path; force sync.
- **Validate:** Discovery reports Defender state; device turns Compliant.

### C4 — Device threat level (Mobile Threat Defense)
- **Checks:** the device's **risk level** from an MTD connector is at/below the allowed threshold.
- ⚑ **GCC High nuance (critical):** **MTD connectors work only for vendors that ALSO support GCC
  High.** If your MTD vendor isn't present in Gov, this rule **cannot be evaluated** and the device may
  be stuck. In `intune.microsoft.us` → **Tenant administration → Connectors and tokens** you only see
  the connectors available in Gov.
- **Fix:** if no GCC High MTD connector exists for your vendor, **remove or replace** the "device
  threat level" rule (parity gap, not a bug). If a supported connector exists, confirm it's connected
  and the device is enrolled with the MTD app.
- **Validate:** re-run Report; the rule now evaluates (or is removed).

### C5 — Password / passcode / encryption (mobile) and jailbreak/root
- **Checks:** password complexity, encryption, jailbreak/root status per platform.
- ⚑ **GCC High nuance:** standard MDM compliance settings are supported; platform coverage matches
  Commercial (Windows, iOS/iPadOS, macOS, Android, AOSP, Linux GA). AOSP has some device restrictions —
  **verify for GCC High** if you rely on a specific AOSP capability.
- **Fix:** correct the setting on-device or via a configuration profile; force sync.
- **Validate:** Validation reports PASS.

### C6 — Custom compliance (script-based) rules
- **Checks:** a custom compliance script + JSON evaluated on the device.
- **Diagnose:** confirm the detection script deploys and returns the expected JSON; a script that
  can't run (execution policy, missing dependency) reads as non-compliant.
- **Fix:** correct/redeploy the script; force sync. Re-run Discovery.

---

## Branch D — "Compliant in Intune, but the user is still blocked"

The device is Compliant in `intune.microsoft.us`, yet the user is denied Microsoft 365. This is almost
always **Conditional Access**, not compliance.

1. **`portal.azure.us`** → **Microsoft Entra ID → Security → Conditional Access** → **Sign-in logs**
   (or **Monitoring → Sign-in logs**) → open the blocked sign-in → **Conditional Access** tab → find
   the **policy that blocked** and the **grant control** ("Require device to be marked as compliant").
2. **Compliance-state propagation lag:** a device that *just* turned compliant may not have propagated
   to Entra yet. Have the user sign out/in; re-check after propagation.
3. **Platform mismatch:** the CA policy may target a platform the device reports differently. Confirm
   the CA policy's **Conditions → Device platforms** matches.
4. **Fix in the correct portal:** compliance rules in `intune.microsoft.us`; the **grant control** in
   `portal.azure.us` CA. Don't edit a compliance policy to fix a CA problem.

---

## Branch E — Device missing, stale, or last check-in is old

Compliance is evaluated at check-in; a device that stopped checking in goes stale and reads
non-compliant.

1. **Confirm enrollment:** `intune.microsoft.us` → **Devices → All devices**. If absent, the device
   isn't enrolled in **this** tenant. ⚑ Remember there is **no in-place migration** from Commercial to
   GCC High — a device enrolled in a Commercial tenant will never appear here; it must **unenroll then
   re-enroll** in the Gov tenant.
2. **Endpoint reachability (GCC High):** re-check **`*.manage.microsoft.us`** / **`*.dm.microsoft.us`**
   reachability and the **no-SSL-inspection** rule (section 2, R5). A device silently losing check-in
   is usually a proxy/TLS regression.
3. **Provisioning context:** ⚑ **classic Windows Autopilot is not available in GCC High** — if a device
   "wasn't compliant right out of provisioning," the Commercial Autopilot compliance timing guidance
   doesn't apply; use **Autopilot device preparation** (some modes still planned) or standard
   enrollment.
4. **Force sync / re-enroll** as needed; re-run Discovery and Report.

---

## Step Final — Pilot → Validate → Expand every change

1. **Pilot:** apply the fix to **one affected device or a small group** first
   (`INTCOMPDXG-Set-ScopeTargeting.ps1`, default `-WhatIf`, to preview the assignment).
2. **Validate:** `INTCOMPDXG-Validation.ps1` on a pilot device + confirm **Compliant** in
   `intune.microsoft.us`; `INTCOMPDXG-Report.ps1` for the group.
3. **Remediate at scale (carefully):** `INTCOMPDXG-Remediation.ps1` runs **`-WhatIf` by default** —
   review the planned actions, then re-run with `-Execute` (or `-WhatIf:$false`) only after the pilot
   passes.
4. **Expand:** widen the assignment in waves; re-validate each wave. A compliance change that flips a
   fleet to **Not compliant** blocks every user at once through Conditional Access — never skip Pilot.

---
### Order of operations
`Capture symptom (Discovery/Report) → branch A–E → fix in the correct *.us blade → Pilot → Validate
(Validation + portal) → Remediate (-WhatIf first) → Expand in waves`
