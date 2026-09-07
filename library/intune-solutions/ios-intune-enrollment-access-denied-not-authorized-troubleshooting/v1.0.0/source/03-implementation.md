# Implementation — Root-Cause & Remediation Guide

The step-by-step runbook: capture the diagnostic IDs, read the failed enrollment sign-in, check the four
gates in order, remediate the one that blocked it, and validate a clean re-enrollment. Portal paths use
the commercial hosts; for **GCC High / DoD** use the `*.microsoft.us` equivalents.

---

## Phase 1 — Capture and read the failed sign-in (the deterministic step)

### Step 1.1 — Capture the diagnostic block
1. From the "Access Denied" screen, record the **Activity Id**, **Session Id**, **Timestamp**, and the
   affected user's **UPN**.

### Step 1.2 — Find the failed enrollment sign-in
1. Run **`ENRLDX-Get-EnrollmentSignin.ps1`** with the user (and, if known, the correlation ID / time).
   It returns the failed sign-ins for the **Microsoft Intune Enrollment** and **Microsoft Intune** apps
   with the **failure reason** and the **applied Conditional Access** result.
2. Or, in **Entra admin center → Monitoring → Sign-in logs**, filter to the user and timestamp, find
   the failed enrollment sign-in, and read the **Failure reason** and the **Conditional Access** tab.

### Step 1.3 — Interpret the failure reason
- **"…not licensed" / no Intune service plan** → Phase 2A (license).
- **"…blocked by policy" / MDM scope** → Phase 2B (MDM user scope).
- **Enrollment restriction / device cap** → Phase 2C.
- **A Conditional Access policy shows Failure** → Phase 2D.
- **Account disabled / guest** → Phase 2E.

> If the sign-in log is unambiguous, go straight to that phase. Otherwise, work Phases 2A–2D in order —
> they are ordered by likelihood.

---

## Phase 2 — Check and remediate the gate

### Phase 2A — Intune license
1. Run **`ENRLDX-Get-UserIntuneLicense.ps1`** for the user. Confirm an **Intune** service plan
   (`INTUNE_A`) is **assigned and enabled** (via a Microsoft 365 E3/E5, EMS, or standalone Intune SKU).
2. If missing/disabled: **Microsoft 365 admin center → the user → Licenses** → assign an Intune-bearing
   license (or enable the Intune service plan). Wait for propagation, then retry.

### Phase 2B — MDM user scope
1. Run **`ENRLDX-Get-MdmUserScope.ps1`**. Confirm the **Microsoft Intune** MDM user scope is **All**, or
   a group that includes the user.
2. If **None** or a group the user isn't in: **Entra admin center → Devices → Mobility (MDM and WIP) →
   Microsoft Intune** → set **MDM user scope** to **All** (or add the user to the scoped group). Confirm
   the **MDM terms of use / discovery / compliance URLs** are the defaults.

### Phase 2C — Enrollment restrictions
1. Run **`ENRLDX-Get-EnrollmentRestrictions.ps1`**. Check:
   - **Device platform restriction** — is **iOS/iPadOS** *Allowed*? Is **personally owned** *Allowed*
     (for a BYO device)?
   - **Device limit restriction** — is the user already at their enrolled-device cap?
2. Remediate in **Intune → Devices → Enrollment → Enrollment restrictions**: allow the iOS/iPadOS
   platform and/or personal ownership for the user's assigned restriction, or raise/clear the device
   limit. For **corporate/ADE** devices, also confirm the serial is assigned to the **Intune ADE token
   in ABM** with an enrollment profile assigned.

### Phase 2D — Conditional Access
1. Run **`ENRLDX-Get-EnrollmentCA.ps1`** to list CA policies targeting the **Microsoft Intune
   Enrollment** and **Microsoft Intune** cloud apps.
2. If a policy blocks the sign-in (or requires a grant a not-yet-enrolled device can't meet, e.g.
   *require compliant device*), scope it to **exclude enrollment** appropriately, or add the enrollment
   apps/user to the exclusion — never simply disable the policy. Re-check the sign-in log.

### Phase 2E — Account
1. Confirm the account is a **member (not guest/B2B)**, sign-in is **not blocked/disabled**, and the
   user holds any group membership required by scope or CA. Fix the account condition.

---

## Phase 3 — Re-enroll and validate

1. On the device, remove the management profile (**Settings → General → VPN & Device Management →**
   remove), then retry enrollment (Company Portal for BYO; re-run Setup Assistant for ADE).
2. Re-run **`ENRLDX-Get-EnrollmentSignin.ps1`** — the enrollment sign-in for the user should now show
   **Success**, and the device should appear in **Intune → Devices**.
3. Keep the before/after sign-in evidence and the gate finding with the ticket.

---

## Phase 4 — Prevent recurrence
1. If the cause was **MDM scope** or an **enrollment restriction**, fix it for the **class** of users
   (the scoped group or the restriction assignment), not just this user, so the next enrollment does not
   hit the same wall.
2. If the cause was **Conditional Access**, document the enrollment exclusion pattern so future CA
   changes preserve it.
