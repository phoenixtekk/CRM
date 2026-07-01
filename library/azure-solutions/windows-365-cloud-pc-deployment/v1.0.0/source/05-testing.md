# 5. Testing Guide — Windows 365 Cloud PC Deployment & Management

Run after the pilot provisioning policy applies (Implementation Step 6) and again before each
production wave. The pilot gate must pass before you expand.

## Test 1 — Provisioning succeeds
**Do:** Intune admin center → **Devices → Windows 365 → All Cloud PCs** (or open
`W365 – Provisioning – Pilot` → device status). Also run **`W365-Validation.ps1`**.
**Expected:** Each licensed member of `W365 – Users – Pilot` has a Cloud PC in status **Provisioned**
(no **Provisioning failed** / **In grace period**).

## Test 2 — User can connect
**Do:** As a pilot user, sign in at **`https://windows365.microsoft.com`** (or the Windows App) and
**Connect** to the Cloud PC.
**Expected:** The Cloud PC tile appears, the desktop loads, and the user reaches the Windows sign-in
and desktop without error.

## Test 3 — Image and apps are correct
**Do:** On the connected Cloud PC, confirm the OS build (`winver`) and that the expected baseline /
assigned apps are installed.
**Expected:** The desktop matches the selected gallery image or `W365 – Image – Win11-M365`, and the
apps assigned in Implementation Step 5 are present.

## Test 4 — Intune management applied
**Do:** Run **`W365-Validation.ps1`**, and in Intune check the Cloud PC under **Devices → All devices**
→ compliance + configuration state.
**Expected:** The Cloud PC is Intune-enrolled and shows **Compliant**, with the `W365 – Compliance –
Baseline` and configuration profiles applied.

## Test 5 — Conditional Access enforced
**Do:** Sign in to the Cloud PC as a pilot user with `W365 – CA – CloudPC-Access` **On**.
**Expected:** The user is prompted for MFA (and, if configured, blocked from a non-compliant connecting
device). Entra **Sign-in logs** show the policy applied to the Windows 365 app.

## Test 6 — Network model behaves as designed
**Do:** From the Cloud PC, confirm internet access; for an ANC deployment, confirm reach to an on-prem
resource (file share / domain resource) and, for hybrid join, confirm the device is domain-joined.
**Expected:** Microsoft-hosted Cloud PCs reach the internet; ANC Cloud PCs additionally reach on-prem
targets, and hybrid-joined Cloud PCs are domain-joined.

## Test 7 — Lifecycle actions work
**Do:** On a pilot Cloud PC, exercise **Restart** and **Reprovision** from **Devices → Windows 365 →
All Cloud PCs** (device actions). Optionally test a **Resize**.
**Expected:** Restart returns the Cloud PC healthy; Reprovision rebuilds it to the policy image and it
returns **Provisioned**; Resize changes the SKU without data loss to the OS configuration.

## Test 8 — Fleet and license report
**Do:** Run **`W365-Report.ps1`**.
**Expected:** A clear per-Cloud-PC inventory (user, status, size/SKU, provisioning policy) plus
license utilization (assigned vs. available Windows 365 seats), with laggards/failures flagged.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–6 pass for `W365 – Users – Pilot`; users connect and Cloud PCs are compliant and CA-protected |
| **Production pass** | Tests 1–5, 8 pass for each `W365 – Users – Production` wave, with license headroom confirmed |
