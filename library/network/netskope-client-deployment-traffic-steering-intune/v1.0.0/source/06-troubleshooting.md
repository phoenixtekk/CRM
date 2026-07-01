# 6. Troubleshooting Guide — Netskope Client Deployment & Traffic Steering at Scale (Intune)

Use `NSCLIENT-Discovery.ps1` and `NSCLIENT-Validation.ps1` for device state, `NSCLIENT-Report.ps1` for
fleet deployment status, and `NSCLIENT-Remediation.ps1` (default -WhatIf) for safe fixes. Netskope
console-side diagnostics (steering analytics, tenant policy state) are deferred to the official
Netskope documentation.

## A. Client not installing via Intune
| Symptom | Cause | Remediation |
|---|---|---|
| App shows Failed | Wrong silent-install/uninstall command or bad detection rule | Re-check the install command and detection rule against Netskope docs; re-run `NSCLIENT-Discovery.ps1` |
| App stuck Pending | Device not synced or not in the ring group | Confirm group membership; sync the device; run `NSCLIENT-Remediation.ps1 -WhatIf` then apply |
| Installs but not detected | Detection rule does not match the installed client | Update the detection rule to the real install path/version/service per Netskope docs |

## B. Client installed but not healthy
| Symptom | Cause | Remediation |
|---|---|---|
| Installed but not enrolled to tenant | Enrollment token/SSO method missing or wrong | Confirm the enrollment method (Netskope docs); reinstall with correct enrollment parameters |
| Service not running | Service stopped or blocked | Confirm the client service state with `NSCLIENT-Validation.ps1`; restart/reinstall via `NSCLIENT-Remediation.ps1` |
| Enrolled but not steering | Steering profile not scoped to this device | Confirm the device/user is in scope of `Steering Profile – Corporate – Production` (Netskope docs) |

## C. Steering breaks a business app
- Add the affected app to `Steering Exceptions – Business Apps – Production` (Netskope docs), confirm
  the exception is active, then re-test on a pilot device before widening.
- For SSL pinning/cert errors specifically, see section D before assuming a steering issue.

## D. Certificate / SSL inspection errors
| Symptom | Cause | Remediation |
|---|---|---|
| Cert warnings on inspected sites | Decryption certificate not trusted on the device | Confirm the Intune trusted-certificate profile applied; widen its assignment to the device's ring group |
| One app fails TLS but others work | App pins certificates and cannot be inspected | Add the app to the steering/decryption exception list (Netskope docs) |

## E. Some devices uncovered after a wave
- Run `NSCLIENT-Report.ps1` to find devices with no/failed client; confirm they are in the correct ring
  group with `NSCLIENT-Set-RolloutRingTargeting.ps1 -WhatIf`, then sync and remediate.

## F. Rolling back (live-traffic safety)
- To back out: remove the ring group from the `Netskope Client – Windows – Production` assignment,
  and/or disable/narrow the steering profile scope in the Netskope tenant (global G7). Communicate the
  change and re-validate the remaining rings with `NSCLIENT-Validation.ps1`.

## G. When to escalate
If the app deploys, the client is installed/running/enrolled, the device is synced and in scope, and
steering still does not engage (or a non-excepted app still breaks), collect the client logs per the
Netskope documentation and open a Netskope support case; for Intune delivery failures collect the
Intune app install status and open a Microsoft support case.
