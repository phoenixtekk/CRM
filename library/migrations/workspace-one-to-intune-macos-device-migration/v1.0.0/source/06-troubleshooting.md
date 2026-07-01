# 6. Troubleshooting Guide — Workspace ONE to Intune: macOS Device Migration

Use `WS1MAC-Discovery.ps1` for tenant/enrollment readiness, `WS1MAC-Validation.ps1` for per-device
enrollment and parity, `WS1MAC-Report.ps1` for fleet/ring status, and `WS1MAC-Remediation.ps1` for
safe sync-based fixes (preview first). Workspace ONE-side issues (release/unenroll) are deferred to
VMware Workspace ONE documentation.

## A. Mac will not re-enroll into Intune
| Symptom | Cause | Remediation |
|---|---|---|
| ADE Mac does not pick up the enrollment profile | Profile not assigned to the token, or token not synced after ABM reassignment | Confirm `WS1MAC Enrollment - macOS - ADE` is assigned to the token; sync the token; run `WS1MAC-Discovery.ps1` |
| Mac still managed by Workspace ONE | Source management not released before re-enrollment | Release the Mac from Workspace ONE (deferred to VMware docs), then re-enroll |
| Enrollment fails with push errors | APNs certificate expired or wrong Apple ID | Renew the APNs certificate with the long-term Apple ID; never let it lapse |

## B. ABM reassignment not reflecting in Intune
| Symptom | Cause | Remediation |
|---|---|---|
| Reassigned Macs do not appear under the Intune token | Token not synced, or wrong MDM server selected in ABM | In ABM confirm the Mac's MDM server is `WS1MAC Intune - macOS MDM Server`; in Intune sync the enrollment program token |
| Devices show under the old token | They were assigned to the prior MDM server | Reassign in ABM, then sync; the device moves on the next sync |

## C. Configuration parity gaps after enrollment
| Symptom | Cause | Remediation |
|---|---|---|
| A setting/restriction is missing | Control not mapped, or in the wrong Intune surface | Re-check the Step 4 mapping; add it to `WS1MAC Parity - macOS Settings - Pilot`, a custom profile, or a shell script as appropriate |
| Custom profile not applied | Wrong deployment channel or malformed `.mobileconfig` | Re-upload a valid `.mobileconfig` to `WS1MAC Parity - macOS Custom - Pilot`; confirm the channel |
| Shell-script control drifts back | No re-enforcement schedule | Set a run frequency on `WS1MAC Parity - macOS Shell - Pilot`; run `WS1MAC-Remediation.ps1` to re-sync |

## D. Object shows Error / not applied
- Confirm the Mac is enrolled and in the assigned ring group; run `WS1MAC-Validation.ps1`.
- Run `WS1MAC-Remediation.ps1` (preview, then `-WhatIf:$false`) to issue a device sync so the parity
  objects re-evaluate.
- Resolve any conflicting policy that targets the same payload.

## E. FileVault / certificate continuity
- FileVault recovery keys and certificate-based items do not carry over with the device; treat each as
  an explicit parity item and re-issue under Intune. If FileVault escrow is missing post-migration,
  confirm the FileVault policy is assigned and the Mac has re-escrowed its key.

## F. Coexistence confusion (two authorities)
- A Mac briefly managed by both during cutover should be released from Workspace ONE promptly. If a
  Mac is stuck dual-managed, release the source first, then re-sync Intune.

## G. When to escalate
If a Mac is assigned to `WS1MAC Intune - macOS MDM Server` in ABM, released from Workspace ONE, the
token is synced, and the device still will not enroll or apply parity after a sync, collect the device
enrollment state from `WS1MAC-Validation.ps1` and open a Microsoft support case (or, for the source
release behavior, a VMware Workspace ONE support case).
