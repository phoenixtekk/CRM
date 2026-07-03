# 5. Testing Guide — Windows 365 Cloud PC Deployment & Management (Government / GCC High)

Run after the pilot provisioning policy applies (Implementation Step 6) and again before each
production wave. The pilot gate must pass before you expand. All admin steps use the **`.us`**
sovereign portals; all scripts connect to **Graph US Gov** (`-Environment USGov`).

## Test 1 — Provisioning succeeds
**Do:** Intune admin center (`https://intune.microsoft.us`) → **Devices → Windows 365 → All Cloud
PCs** (or open `W365G – Provisioning – Pilot` → device status). Also run **`W365G-Validation.ps1`**.
**Expected:** Each licensed member of `W365G – Users – Pilot` has a Cloud PC in status **Provisioned**
(no **Provisioning failed** / **In grace period**).

## Test 2 — User can connect (sovereign end-user portal)
**Do:** As a pilot user, sign in at **`https://windows365.microsoft.us`** (or the Windows App) and
**Connect** to the Cloud PC.
**Expected:** The Cloud PC tile appears, the desktop loads, and the user reaches the Windows sign-in
and desktop without error. (Confirm you used the **`.us`** end-user URL, not `.com`.)

## Test 3 — Image and apps are correct
**Do:** On the connected Cloud PC, confirm the OS build (`winver`) and that the expected baseline /
assigned apps are installed.
**Expected:** The desktop matches the selected gallery image or `W365G – Image – Win11-M365`, and the
apps assigned in Implementation Step 5 are present.

## Test 4 — Intune management + hardening applied (no W365 baseline dependency)
**Do:** Run **`W365G-Validation.ps1`**, and in Intune check the Cloud PC under **Devices → All
devices** → compliance + configuration state.
**Expected:** The Cloud PC is Intune-enrolled (government instance) and shows **Compliant**, with the
`W365G – Compliance – Baseline` and the **Settings catalog** hardening profile applied. (Confirm
hardening comes from the Settings catalog profile — the **W365 Security baseline is unavailable in
GCC High**.)

## Test 5 — Conditional Access enforced
**Do:** Sign in to the Cloud PC as a pilot user with `W365G – CA – CloudPC-Access` **On**.
**Expected:** The user is prompted for MFA (and, if configured, blocked from a non-compliant
connecting device). Entra **Sign-in logs** (`entra.microsoft.us`) show the policy applied to the
Windows 365 app.

## Test 6 — Network model behaves as designed
**Do:** From the Cloud PC, confirm internet access; for an ANC deployment, confirm reach to an on-prem
resource (file share / domain resource) and, for hybrid join, confirm the device is domain-joined.
**Expected:** Microsoft-hosted Cloud PCs reach the internet; ANC Cloud PCs additionally reach on-prem
targets, and hybrid-joined Cloud PCs are domain-joined. (ANC traffic routes through your **Azure
Government** vNet.)

## Test 7 — Lifecycle actions work
**Do:** On a pilot Cloud PC, exercise **Restart** and **Reprovision** from **Devices → Windows 365 →
All Cloud PCs** (device actions). Optionally test a **Resize** (CPU/RAM SKUs only — no GPU in GCC High).
**Expected:** Restart returns the Cloud PC healthy; Reprovision rebuilds it to the policy image and it
returns **Provisioned**; Resize changes the SKU without data loss to the OS configuration.

## Test 8 — Fleet and license report
**Do:** Run **`W365G-Report.ps1`**.
**Expected:** A clear per-Cloud-PC inventory (user, status, size/SKU, provisioning policy) plus
license utilization (assigned vs. available Windows 365 Government seats), with laggards/failures
flagged.

## Test 9 — Parity-gap sanity check (GCC High specific)
**Do:** Confirm the deployment does not depend on any GCC-High-unsupported feature — no reliance on
the W365 Security baseline, GPU SKUs, Windows 365 Boot/Switch/Reserve, the W365 monitoring dashboard,
Cloud PC audit logs in Log Analytics, or Intune Autopilot/Remote Help/Autopatch/update rings.
**Expected:** Every management dependency is satisfied by a feature confirmed available in GCC High
(see `gcc-high-parity-notes.md`). Anything not confirmed is flagged **verify for GCC High** and has a
tested fallback.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–6, 9 pass for `W365G – Users – Pilot`; users connect via `windows365.microsoft.us` and Cloud PCs are compliant and CA-protected |
| **Production pass** | Tests 1–5, 8, 9 pass for each `W365G – Users – Production` wave, with license headroom confirmed |
