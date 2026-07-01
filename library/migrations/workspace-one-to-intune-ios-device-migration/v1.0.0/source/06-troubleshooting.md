# 6. Troubleshooting Guide — Workspace ONE to Intune iOS/iPadOS Device Migration

Use `WS1IOS-Validation.ps1` / `WS1IOS-Discovery.ps1` for state, `WS1IOS-Report.ps1` for fleet status, and
`WS1IOS-Remediation.ps1` for safe fixes (default `-WhatIf`).

## A. Device will not move to Intune
| Symptom | Cause | Remediation |
|---|---|---|
| Device still managed by Workspace ONE after ABM re-assignment | Not yet erased — re-assignment only takes effect on the next Setup Assistant | Erase the device (Erase All Content and Settings or remote wipe) so it re-enrolls under Intune |
| Re-assigned device does not show in Intune | ADE not synced, or profile not assigned | In Intune on the token > Devices click Sync (allow for Apple rate limits), then Assign profile |
| Setup Assistant shows the old organization | ABM still points to the Workspace ONE MDM server | Re-confirm Edit MDM Server in ABM is `Intune MDM Server – Apple – Migration` before erasing |

## B. Enrollment / supervision problems
| Symptom | Cause | Remediation |
|---|---|---|
| Device enrolls but is not supervised | Manual enrollment instead of ADE, or supervision off in the profile | Use ADE (Setup Assistant) with the enrollment profile; confirm Supervised is enabled in the profile |
| Remote Management screen skipped | Device not in ABM under the Intune server | Verify the serial is assigned to the Intune MDM server and synced into Intune |
| Enrollment fails after erase | APNs cert expired or ADE token stale | Run `WS1IOS-Discovery.ps1`; renew the APNs cert / re-download the ADE token if flagged |

## C. App or profile parity gaps
| Symptom | Cause | Remediation |
|---|---|---|
| Apps not installing after re-enroll | App not assigned to the ring group, or no VPP licenses | Confirm Required assignment to the ring group; check the VPP token and available licenses |
| Wi-Fi / VPN / email missing | Parity profile not assigned to the ring group | Assign `iOS Parity – Corporate Wi-Fi – Cutover` and the other parity profiles to the ring group |
| Device shows Not compliant | Compliance policy not assigned, or rule not met | Assign `iOS Parity – Compliance Baseline – Cutover`; check OS version / passcode / jailbreak rules |

## D. Ring and group issues
- Device not picking up policy: confirm it is a member of `iOS Migration – Pilot Ring – Pilot` (or the broad ring)
  and that profiles/apps are assigned to that exact group.

## E. Rollback
- To revert a device: in ABM re-assign it back to the Workspace ONE MDM server, erase, and re-enroll through Setup
  Assistant so source management is restored. Keep the Workspace ONE MDM server live until the ring is signed off.

## F. Source-platform issues (Workspace ONE)
- Workspace ONE console behavior, its profile export, and its unenrollment steps are the source vendor's domain and
  are deferred to VMware documentation. This guide covers the Intune and Apple Business Manager side.

## G. When to escalate
If a device is correctly assigned to the Intune MDM server in ABM, synced, erased, and still will not enroll after
an APNs/ADE check passes, capture the device console logs and open an Apple Business Manager and/or Microsoft
support case.
