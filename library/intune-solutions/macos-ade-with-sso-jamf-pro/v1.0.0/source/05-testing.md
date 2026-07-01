# 5. Testing & Validation — macOS Automated Device Enrollment with SSO (Jamf Pro + Microsoft Intune)

Validate against a **pilot device** before expanding. Each test has an explicit **pass/fail gate**.
Use the included PowerShell scripts for tenant-side checks (Microsoft Graph and the Jamf Pro API) and
the on-device steps for the user experience.

## Test 1 — Jamf side readiness
**Procedure:** Run `JAMFADE-JamfReadiness.ps1` (Jamf Pro API).
**Pass:** Jamf **APNs** valid (>30 days), an **Automated Device Enrollment** instance present with a
token >30 days, at least one macOS **PreStage Enrollment**, and a **Single Sign-On Extensions**
(Platform SSO) configuration profile present.
**Fail:** Any missing or expiring within 30 days → resolve before enrolling devices.

## Test 2 — Intune/Entra side readiness
**Procedure:** Run `JAMFADE-Discovery.ps1` (Microsoft Graph).
**Pass:** **Jamf** shows as an **Active** device-compliance partner for macOS, a macOS **compliance
policy** exists, a **Conditional Access** policy targets macOS requiring compliance, and the macOS
**Company Portal** is available.
**Fail:** Partner not active, or compliance/CA policy missing → fix per Implementation §Phase 4.

## Test 3 — Device appears as ADE in Jamf
**Procedure:** In Jamf → Automated Device Enrollment → (instance), or run `JAMFADE-JamfReadiness.ps1`.
**Pass:** The pilot serial is listed and **scoped to the PreStage**, ready for enrollment.
**Fail:** Serial missing → re-check ABM MDM-server assignment (R5) and **Refresh** the instance.

## Test 4 — Zero-touch enrollment into Jamf
**Procedure:** Erase the pilot Mac and run Setup Assistant on a managed network.
**Pass:** A **Remote Management** screen names your organization (Jamf); enrollment completes without
manual MDM-profile installation; the device appears in **Jamf → Computers** within minutes.
**Fail:** No Remote Management screen → device not assigned/refreshed, or network blocks
`mdmenrollment.apple.com` (R12).

## Test 5 — Supervision and lock
**Procedure:** Inspect the enrolled device in Jamf (or run `JAMFADE-JamfReadiness.ps1`).
**Pass:** Device is **Supervised = Yes** and the MDM profile is **mandatory** (user cannot remove it).
**Fail:** Supervised = No → the PreStage did not enable **Supervision** (Step 7); re-erase and
re-enroll after correcting.

## Test 6 — Company Portal + Platform SSO registration
**Procedure:** After desktop loads, confirm Company Portal installed and complete the **Register**
prompt; then check the SSO state.
**Pass:** Company Portal reports the device **registered**; macOS shows the Platform SSO login-window
prompt / key indicator; `JAMFADE-Validation.ps1` reports the device **registered** in Entra and the SSO
profile **applied**.
**Fail:** No registration prompt → confirm Company Portal is scoped/installed (R8) and the SSO profile
is scoped (Step 10), then retry.

## Test 7 — Single sign-on works
**Procedure:** On the Mac, open a Microsoft 365 web app (e.g. `https://outlook.office.com`) in Safari
and Edge/Chrome; open a native app that supports the broker.
**Pass:** Sign-in is **silent** (no password prompt) using the registered Entra identity.
**Fail:** Repeated password prompts → verify the SSO extension URLs and identifiers (Step 10), and
that the Microsoft Enterprise SSO extension is present.

## Test 8 — Secure Enclave authentication method
**Procedure:** Confirm the Platform SSO method in effect.
**Pass:** Authentication uses the **Secure Enclave key** (hardware-bound); the local password is
decoupled from Entra.
**Fail:** Method shows password sync when Secure Enclave was intended → correct the SSO profile (Step
10) and **re-register**.

## Test 9 — Compliance flows Jamf → Intune
**Procedure:** Review the pilot Mac in **Intune → Devices → macOS** (or run `JAMFADE-Validation.ps1` /
`JAMFADE-DeviceReport.ps1`).
**Pass:** The Mac appears as **partner-managed (Jamf)** with a **Compliant** state reported to Intune.
**Fail:** Device absent or non-compliant → confirm the Device Compliance integration is **Active**
(R10) and the Jamf compliance scope includes the device (Step 12).

## Test 10 — Conditional Access enforces SSO
**Procedure:** With the CA policy in **report-only**, sign in to Microsoft 365 from the Mac and review
Entra **sign-in logs**.
**Pass:** The CA policy evaluates the Mac as **compliant** and (if configured) satisfies the
phishing-resistant strength; in **report-only** it shows "would have applied / granted."
**Fail:** Policy reports non-compliant or not-registered → resolve Tests 6/9 first, then re-test
before switching CA to **On**.

## Acceptance gate
Proceed to **Expand** only when Tests 1–10 pass on at least one pilot Mac and the user-experience
checks (silent SSO, clean first-run) are confirmed by a real pilot user. Switch Conditional Access
from **report-only** to **On** only after Test 10 passes.
