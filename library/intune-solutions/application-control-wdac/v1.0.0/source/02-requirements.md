# 2. Requirements Guide — Application Control (WDAC)

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

## 2.1 Licensing
**Description:** Intune (Plan 1). WDAC/App Control is a Windows feature (no separate license).
**Why:** Intune delivers and reports the App Control policy.
**Verify:** M365 admin center → **Billing → Licenses**.
**Implement:** Assign M365 E3/E5 or Business Premium (Intune included).

## 2.2 Supported Windows OS
**Description:** Windows 10 1903+ or Windows 11 (App Control for Business CSP).
**Why:** The Intune App Control policy and managed-installer trust require a supported build.
**Verify:** `winver`; run **`WDAC-Discovery.ps1`**.
**Implement:** Patch/upgrade to a supported build.

## 2.3 Device enrollment
**Description:** Devices enrolled in Intune.
**Why:** The policy applies only to enrolled devices.
**Verify:** Intune → **Devices → All devices**.
**Implement:** Enable automatic enrollment; enroll devices.

## 2.4 Application inventory
**Description:** Awareness of the apps users legitimately run, and how they are installed.
**Why:** Audit mode reveals untrusted apps; you must decide how each becomes trusted (managed installer, ISG, signature).
**Verify:** Review **`WDAC-AuditReport.ps1`** output during the audit phase.
**Implement:** Prefer deploying apps via **Intune (managed installer)** so they're trusted automatically; document any exceptions.

## 2.5 App deployment via Intune (recommended)
**Description:** Business apps deployed through Intune as managed installs.
**Why:** With the managed-installer trust option, Intune-deployed apps are automatically allowed.
**Verify:** Intune → **Apps → Windows**.
**Implement:** Move key app deployments into Intune before enforcing.

## 2.6 Recovery plan
**Description:** A way to remove/replace the policy if enforcement is too strict.
**Why:** WDAC is powerful; you need a safe rollback.
**Verify:** Confirm **`WDAC-Remediation.ps1`** (policy-removal path) and an Intune unassign procedure.
**Implement:** Document removing the assignment (and local policy clear) for recovery.

---
## Checklist
- [ ] Intune licensing assigned
- [ ] Windows 10 1903+/11 — `WDAC-Discovery.ps1`
- [ ] Devices enrolled
- [ ] App inventory + trust approach decided (prefer managed installer)
- [ ] Key apps deployed via Intune
- [ ] Recovery/rollback procedure confirmed
- [ ] Pilot Entra group created
