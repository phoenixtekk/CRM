# Troubleshooting — Device Compliance Policies (Government / GCC High edition)

GCC-High-specific symptoms first, then the general compliance issues that also apply here. For
each: **Symptom → Likely cause → Fix.** Cross-references point to the cited parity reference.

---

## GCC High / sovereign-cloud issues

### The admin center looks empty, or "your changes didn't save"

- **Cause:** You're signed into the **Commercial** portal (`intune.microsoft.com`), not the
  sovereign one. Your GCC High objects live in a physically separate datacenter and don't
  appear there.
- **Fix:** Open **`https://intune.microsoft.us/`** and sign in at `login.microsoftonline.us`.
  Confirm the URL bar shows `.us`. Re-do the change in the correct cloud.
  [[MS-GOV-EP]](gcc-high-parity-notes.md)

### PowerShell returns no policies / "Insufficient privileges" / connects to the wrong tenant

- **Cause:** `Connect-MgGraph` defaulted to **Global** (Commercial `graph.microsoft.com`)
  instead of US Gov, so it's querying the wrong cloud.
- **Fix:** Reconnect with **`Connect-MgGraph -Environment USGov`** (DoD: `USGovDoD`). Verify
  with `(Get-MgContext).Environment` → should read `USGov`. Set
  `$PSDefaultParameterValues['Connect-MgGraph:Environment'] = 'USGov'` so it never happens
  again. All five scripts already pass `-Environment USGov`.
  [[MS-GRAPH-ENV]](gcc-high-parity-notes.md)

### Enrollment or compliance check-in fails intermittently behind the proxy

- **Cause:** SSL/TLS inspection on `*.manage.microsoft.us` (or the Defender/EPM
  `*.dm.microsoft.us` endpoints), or only the Commercial `.com` endpoints are allowed.
- **Fix:** **Exempt `*.manage.microsoft.us` from SSL inspection** — Microsoft does not support
  inspecting it — and allow the full sovereign endpoint list in `02-requirements.md` R4
  (including `login.microsoftonline.us`, `graph.microsoft.us`,
  `enterpriseregistration.microsoftonline.us`, `*.events.data.microsoft.com`).
  [[MS-GOV-EP]](gcc-high-parity-notes.md)

### Require BitLocker / Secure Boot / code integrity never resolves (stuck Not applicable / Error)

- **Cause:** These three settings depend on **Device Health Attestation (DHA)**, whose GCC High
  availability Microsoft's own docs **contradict** — one lists it as *planned/not yet
  available*, the other says it runs in GCC High. On some GCC High tenants they may not
  evaluate. [[MS-GOV-SVC]](gcc-high-parity-notes.md) [[MS-WIN-COMPL]](gcc-high-parity-notes.md)
- **Fix:**
  1. First rule out the boot-time delay: DHA settings only settle **after a reboot**, even when
     BitLocker is already fully encrypted. Reboot the device and re-sync.
  2. If they still never resolve, DHA appears unavailable on your tenant — set the three to
     **Not configured** and use **System Security → Encryption → Encryption of data storage**
     (BitLocker check without DHA) plus **TPM** instead. Record the decision.

### A Mobile Threat Defense connector I use on Commercial isn't listed

- **Cause:** MTD connectors appear in GCC High **only if the vendor supports GCC High**; fewer
  partners do than on Commercial. [[MS-GOV-SVC]](gcc-high-parity-notes.md)
  [[MS-MTD-COMPL]](gcc-high-parity-notes.md)
- **Fix:** Confirm your MTD vendor's GCC High support and onboard the GCC-High-capable connector,
  or leave the mobile **Device Threat Level** setting **Not configured** and rely on the Windows
  baseline.

### The Device Threat Level rule won't apply to a device group

- **Cause:** The MTD *Require the device to be at or under the Device Threat Level* setting
  supports **user groups only** — targeting device groups is unsupported.
  [[MS-MTD-COMPL]](gcc-high-parity-notes.md)
- **Fix:** Assign that policy to **user** groups.

### I can't find Autopilot / Chrome Enterprise / Store for Business to complete a step

- **Cause:** These are **not available** in GCC High/DoD. [[MS-GOV-SVC]](gcc-high-parity-notes.md)
- **Fix:** Enroll Windows via **automatic enrollment / Entra join** (not Autopilot). Don't
  design ChromeOS compliance (no Chrome Enterprise Connector). See the not-available list in
  `gcc-high-parity-notes.md` §6 before treating any Commercial feature as available.

---

## General compliance issues (also apply in GCC High)

### A device is stuck "In progress" and never returns a compliance result

- **Cause:** The device hasn't synced or checked in since the policy was assigned; first
  evaluation can take hours.
- **Fix:** Force a **Sync** from `intune.microsoft.us` → the device → **Sync**, or from the
  device's work-account settings. Confirm the device is enrolled and online. Reboot if
  DHA-measured settings are involved. [[MS-WIN-COMPL]](gcc-high-parity-notes.md)

### Firewall shows "Error" or unexpectedly "Not compliant"

- **Cause:** A sync right after reboot/wake can transiently error; or a **Group Policy Object**
  configured the firewall to allow all inbound / turn it off, which **overrides** the Intune
  setting.
- **Fix:** Manually sync and re-evaluate. Remove conflicting GPO firewall settings, or migrate
  firewall configuration into Intune device-configuration policy so the two don't fight.
  [[MS-WIN-COMPL]](gcc-high-parity-notes.md)

### BitLocker is on, but the device still reports non-compliant for Require BitLocker

- **Cause:** DHA measures this at **boot time**; the device hasn't rebooted since encryption
  completed.
- **Fix:** **Reboot** the device, then sync. (If it still never resolves, see the DHA section
  above.) [[MS-WIN-COMPL]](gcc-high-parity-notes.md)

### The machine risk score setting won't populate

- **Cause:** **Microsoft Defender for Endpoint** isn't onboarded/connected in the tenant.
- **Fix:** Onboard MDE (its security settings management **is** supported in GCC High/DoD), then
  the *Require the device to be at or under the machine risk score* setting will evaluate. If
  MDE isn't in use, leave it **Not configured**.
  [[MS-GOV-SVC]](gcc-high-parity-notes.md) [[MS-WIN-COMPL]](gcc-high-parity-notes.md)

### Users are unexpectedly blocked from resources

- **Cause:** Conditional Access (`CA-Require-Compliant-GovHigh`) is enforcing "require
  compliant" on a population the compliance policy hasn't finished evaluating, or a user's
  device is genuinely noncompliant.
- **Fix:** Check **`entra.microsoft.us` → Sign-in logs** → the Conditional Access result for the
  user. Keep CA in **Report-only** until the compliance rollout has reached that population;
  ensure the compliance policy leads and CA follows. Confirm a **break-glass** account is
  excluded from CA.

### The noncompliance email never arrives

- **Cause:** No notification template attached, the schedule delay hasn't elapsed, or the
  device isn't actually noncompliant yet.
- **Fix:** Confirm `MT-Compliance-Noncompliant-GovHigh` is attached as a **Send email to end
  user** action with a reached schedule, and that the device shows **Not compliant**. Verify the
  email body uses `portal.manage.microsoft.us` links, not Commercial `.com` links.

---

## When to re-run the scripts

- After **any** portal change → `DCPG-Validation.ps1` to confirm named objects and pilot
  scoping.
- Investigating fleet status → `DCPG-Report.ps1` for the per-device rollup.
- Suspected drift (e.g. a policy widened to All devices) → `DCPG-Discovery.ps1`, then
  `DCPG-Remediation.ps1 -WhatIf` to preview a fix before applying with `-Commit`.

All read-only scripts are safe to run any time and connect with `-Environment USGov`.
