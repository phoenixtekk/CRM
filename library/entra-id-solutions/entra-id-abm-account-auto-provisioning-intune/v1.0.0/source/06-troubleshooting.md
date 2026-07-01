# 6. Troubleshooting Guide — Entra ID + ABM Federation & Account Auto-Provisioning

Use **`ABMPROV-Discovery.ps1`** for federation/provisioning/ADE/APNs readiness,
**`ABMPROV-Validation.ps1`** for per-user/per-device state, **`ABMPROV-Report.ps1`** for fleet
coverage, and **`ABMPROV-Remediation.ps1`** (default `-WhatIf`) for safe fixes. ABM-side console
specifics are deferred to Apple's official documentation.

## A. Federation conflicts / existing personal Apple IDs
| Symptom | Cause | Remediation |
|---|---|---|
| User can't get a Managed Apple ID; "in use" | A personal Apple ID already uses the work-email (domain capture conflict) | Re-run the ABM domain-capture report; have the user change their personal Apple ID to a different email; re-check before re-provisioning |
| Federated sign-in fails for some users | Those users still have a conflicting personal Apple ID, or were not in the change window | Resolve the conflict (above); confirm the user is in the federated, provisioned scope |
| Whole-domain sign-in concerns after federation | Federation is domain-wide for Apple sign-in | Expected — keep provisioning scoped to the pilot group until conflicts clear; communicate the change |

## B. SCIM provisioning failures (Entra → ABM)
| Symptom | Cause | Remediation |
|---|---|---|
| Provisioning job won't start / Test Connection fails | ABM authorization not completed or expired | Re-authorize ABM under Provisioning → Admin Credentials; Test Connection (ABM screen deferred to Apple docs) |
| Some users never provision | They aren't in the assigned scope group, or "Sync only assigned" excludes them | Add them to `Managed Apple ID Provisioning – Pilot – Stage`/`– Corp – Prod`; run `ABMPROV-Remediation.ps1` to fix membership |
| Per-user errors in Provisioning logs | Attribute mapping / unresolved conflict | Check Mappings (stable identifier + verified-domain email); resolve any Apple-ID conflict; let the next cycle retry |
| Quota / not-found errors | App not assigned, or scope set to "all" by mistake | Confirm the app is assigned to the scope group and Scope = "Sync only assigned users and groups" |

## C. COD (Corporate-Owned) enrollment issues
| Symptom | Cause | Remediation |
|---|---|---|
| Device doesn't show "Remote Management" | Serial not assigned to the Intune MDM server in ABM, or token not synced | Assign the serial to `Intune – iOS COD` in ABM (deferred to Apple docs); Intune → token → Devices → Sync (allow for Apple rate limits) |
| Enrolls but not supervised / not account-driven | Wrong ADE profile or profile not assigned | Confirm `iOS COD – ADE – Pilot` has Supervised + account-driven and is assigned to the serial |
| User can't sign in during setup | Federation/Managed Apple ID not ready for that user | Confirm the user is federated and provisioned (`ABMPROV-Validation.ps1`) before enrolling their device |

## D. BYOD (account-driven User Enrollment) issues
| Symptom | Cause | Remediation |
|---|---|---|
| Enrollment offers the wrong (older) flow | iOS too old for account-driven User Enrollment, or wrong enrollment type | Update iOS (Requirement 2.7); confirm the profile is account-driven User Enrollment assigned to `iOS BYOD – Users – Pilot` |
| Work account won't add | Federated Managed Apple ID missing for the user | Provision/JIT the Managed Apple ID first; verify with `ABMPROV-Validation.ps1` |
| Personal data appears managed | Device was enrolled with device enrollment, not User Enrollment | Re-enroll via account-driven User Enrollment (the privacy-preserving model) |

## E. Shared (no-affinity) enrollment issues
| Symptom | Cause | Remediation |
|---|---|---|
| Device asks for a primary user | Profile has user affinity | Use `iOS Shared – ADE – Pilot` with **Enroll without user affinity** |
| Expecting Apple "Shared iPad" on iPhone | iPhones have no Shared iPad feature | Use no-affinity + restrictions + Managed Apple ID / shared app sign-in (see Overview / Section 4) |
| Staff can't access the app | Shared sign-in not set up | Sign in to the relevant app/service with the Managed Apple ID or shared account |

## F. Apple connection (APNs / ADE token)
| Symptom | Cause | Remediation |
|---|---|---|
| No iPhones can be managed | APNs certificate expired or wrong Apple ID | Renew APNs with the **same** company Apple ID (Implementation Step 7); never switch the Apple ID |
| COD devices stop flowing from ABM | ADE token expired | Renew the enrollment program token (re-upload the new `.p7m`) — `ABMPROV-Discovery.ps1` reports expiry |

## G. Diagnostics quick reference
- `ABMPROV-Discovery.ps1` — federation app, provisioning job status, ADE token, APNs readiness.
- `ABMPROV-Validation.ps1` — per-user Managed Apple ID + per-device enrollment model.
- `ABMPROV-Report.ps1` — provisioning coverage + COD/BYOD/Shared breakdown.
- Entra → `Apple Business Manager – Federation – Prod` → **Provisioning → Provisioning logs** for
  per-user provisioning results.

## H. When to escalate
If federation is configured, conflicts are clear, the provisioning job is On and healthy, the user is in
the assigned scope, and a Managed Apple ID still won't provision after a cycle, capture the Provisioning
log entry and the ABM domain-capture report state and open a Microsoft (Entra provisioning) and/or Apple
(ABM) support case as the failure side indicates.
