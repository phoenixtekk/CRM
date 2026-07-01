# 5. Testing & Validation — macOS Automated Device Enrollment with SSO

Validate against a **pilot device** before expanding. Each test has an explicit **pass/fail gate**.
Use the included PowerShell scripts (Microsoft Graph) for tenant-side checks and the on-device steps
for the user experience.

## Test 1 — Tenant readiness
**Procedure:** Run `ADEMAC-Discovery.ps1`.
**Pass:** APNs certificate **Active** (expiry > 30 days), an **ADE/enrollment token** present
(expiry > 30 days), at least one **macOS enrollment profile**, Company Portal app assigned, and a
**Platform SSO** configuration profile present.
**Fail:** Any of the above missing or expiring within 30 days → resolve before enrolling devices.

## Test 2 — Device appears as ADE
**Procedure:** In Intune → Enrollment program tokens → (token) → **Devices**, locate the pilot serial;
or run `ADEMAC-DeviceReport.ps1`.
**Pass:** The serial is listed, **profile assigned**, status ready for enrollment.
**Fail:** Serial missing → re-check ABM MDM-server assignment (R5) and **Sync**.

## Test 3 — Zero-touch enrollment
**Procedure:** Erase the pilot Mac and run Setup Assistant on a managed network.
**Pass:** A **Remote Management** screen names your organization; enrollment completes without manual
MDM profile installation; the device shows in **Intune → Devices → macOS** within minutes.
**Fail:** No Remote Management screen → device not assigned/synced, or network blocks
`mdmenrollment.apple.com` (R9).

## Test 4 — Supervision and lock
**Procedure:** Inspect the enrolled device in Intune (or run `ADEMAC-Validation.ps1`).
**Pass:** Device is **Supervised = Yes** and **Corporate-owned**; management is **locked**
(user cannot remove the MDM profile).
**Fail:** Supervised = No → the enrollment profile did not enable Supervised (Step 7); re-erase and
re-enroll after correcting.

## Test 5 — Company Portal + Platform SSO registration
**Procedure:** After desktop loads, confirm Company Portal installed and complete the **Register**
prompt; then check the SSO state.
**Pass:** Company Portal reports the device **registered**; macOS shows the Platform SSO login-window
prompt / key indicator; `ADEMAC-Validation.ps1` reports the SSO profile **applied**.
**Fail:** No registration prompt → confirm Company Portal is **Required** (R7) and the SSO profile is
assigned to the user/device (Step 11), then retry.

## Test 6 — Single sign-on works
**Procedure:** On the Mac, open a Microsoft 365 web app (e.g. `https://outlook.office.com`) in Safari
and Edge/Chrome; open a native app that supports the broker.
**Pass:** Sign-in is **silent** (no password prompt) using the registered Entra identity.
**Fail:** Repeated password prompts → verify the SSO extension URLs and identifiers (Step 11), and
that the Microsoft Enterprise SSO extension is present.

## Test 7 — Secure Enclave authentication method
**Procedure:** Confirm the Platform SSO method in effect.
**Pass:** Authentication uses the **Secure Enclave key** (hardware-bound); the user's local password
is decoupled from Entra.
**Fail:** Method shows password sync when Secure Enclave was intended → correct the SSO profile
setting (Step 11) and re-register.

## Test 8 — Compliance & Conditional Access
**Procedure:** Review the device's **Compliance** in Intune; if Conditional Access is configured,
test access from the Mac.
**Pass:** Device is **Compliant**; Conditional Access (report-only or on) evaluates the Mac as a
managed, registered device.
**Fail:** Non-compliant → review the assigned compliance policy and OS minimum (R6).

## Acceptance gate
Proceed to **Expand** only when Tests 1–8 pass on at least one pilot Mac and the user-experience
checks (silent SSO, clean first-run) are confirmed by a real pilot user.
