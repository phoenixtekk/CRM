# 6. Troubleshooting Guide — Migrating Cisco VPN Client Deployment from SCCM/GPO to Intune

Use `CVPNMIG-Discovery.ps1` to re-read the current state and delivery source, `CVPNMIG-Validation.ps1`
for per-device client/profile/cert/tunnel parity, `CVPNMIG-Report.ps1` for fleet legacy-vs-Intune
progress, and `CVPNMIG-Remediation.ps1` (default `-WhatIf`) for safe local cleanup.

> The Cisco client, its profile XML, and the head-end (ASA/Firepower) are Cisco's domain — for
> connect-failure internals follow Cisco's documentation. The issues below are the **migration-side**
> problems: double management, profile/version conflict, reinstall loops, and legacy residue.

## A. Double-managed device (SCCM/GPO **and** Intune both delivering)
| Symptom | Cause | Remediation |
|---|---|---|
| Client reinstalls repeatedly / version flip-flops | The device is still in the SCCM collection **and** the GPO scope while Intune also targets it — two authorities fighting | Enforce one-authority-per-device: in the SCCM console remove the device from the target collection, and in GPMC remove it from the GPO's security-group filter or move its computer object out of the linked OU; then `CVPNMIG-Remediation.ps1 -Execute` and `gpupdate /force`; re-check with `CVPNMIG-Discovery.ps1` |
| `CVPNMIG-Discovery.ps1` reports "SCCM + GPO (legacy — double source!)" after cutover | Legacy targeting was never removed at cutover | Complete Implementation Step 10 for that device before considering it migrated |

## B. VPN profile conflict (wrong or flip-flopping profile)
| Symptom | Cause | Remediation |
|---|---|---|
| Profile keeps reverting / two profiles present | A stale legacy profile XML remains alongside the Intune-delivered one, or the GPO still drops its copy | `CVPNMIG-Remediation.ps1` lists duplicate profile XML; confirm which is Intune-delivered, remove the stale legacy file, and stop the GPO from dropping it (descope/unlink) |
| Head-end list / split-tunnel differs after migration | The Intune-delivered XML is not byte-identical to the authoritative source | Re-deliver the authoritative profile (Implementation Step 5); `CVPNMIG-Validation.ps1 -ReferenceProfile` must report profile parity MATCH |

## C. Client reinstall loops
| Symptom | Cause | Remediation |
|---|---|---|
| Intune app cycles install → uninstall → install | Detection rule doesn't match how the client actually installs, so Intune thinks it's never installed | Fix the Win32 detection rule to match the real install evidence (MSI product code / client `.exe` version / uninstall key) captured by `CVPNMIG-Discovery.ps1`; re-sync |
| Loop persists after detection fix | SCCM/GPO still reinstalling under Intune (see A), or a stuck IME evaluation | Remove legacy targeting (A); then `CVPNMIG-Remediation.ps1 -Execute` restarts the Intune Management Extension so the app re-evaluates once |

## D. Certificate not accepted by the head-end
| Symptom | Cause | Remediation |
|---|---|---|
| Client installs and profile loads but the tunnel is refused | The Intune SCEP/PKCS certificate doesn't match the template intent the head-end trusts (subject/SAN, EKUs) | Compare the legacy AD CS template to the SCEP profile; align subject/SAN format, EKUs (Client Authentication), and key usage; confirm the Trusted-root profile installed the issuing CA. Certificate acceptance rules on the head-end are per Cisco docs |
| No client certificate present | SCEP profile not assigned to the wave, or the Certificate connector is down | Confirm `Cisco VPN – Client Cert (SCEP)` is assigned to the wave and the **Certificate connector** shows Active; `CVPNMIG-Validation.ps1` must report the cert present |

## E. Leftover GPO after cutover
- A device still receives the old client-install, profile-drop, or cert-enrolment GPO → it was never
  descoped. Remove the device from the GPO's security-group filter or OU, run
  `CVPNMIG-Remediation.ps1 -Execute` (which runs `gpupdate /force`), and verify with `gpresult /r` that
  the Cisco GPO no longer applies. When all waves are migrated, **unlink** the GPO(s) (Implementation
  Step 12).

## F. Rollback (a wave misbehaves)
- Re-add the wave's devices to the SCCM target collection and back into the GPO scope, and remove the
  Intune wave assignment — coexistence means the VPN never disappears. Fix the Intune delivery
  (client/profile/cert parity) and re-validate with `CVPNMIG-Validation.ps1` before retrying cutover.

## G. Diagnostics quick reference
```powershell
# Delivery source + artifacts on the device
powershell -File .\CVPNMIG-Discovery.ps1

# What GPOs still apply (look for the Cisco client/profile/cert GPOs)
gpresult /r /scope:computer

# Is the SCCM client present (legacy authority)?
Get-Service CcmExec -ErrorAction SilentlyContinue

# Intune Win32 app install + detection results
Get-Content "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log" -Tail 200

# Cisco profile XML files (duplicate = potential conflict)
Get-ChildItem "$env:ProgramData\Cisco" -Recurse -Filter *.xml -ErrorAction SilentlyContinue
```

## H. When to escalate
If the Intune-delivered client version, profile, and certificate all show parity (`CVPNMIG-Validation.ps1`
PASS), the device is confirmed Intune-only (`CVPNMIG-Discovery.ps1` shows no SCCM/GPO source), and the
tunnel still won't establish, the remaining issue is on the **Cisco** side (head-end configuration,
certificate acceptance, or client behavior) — collect the Cisco Secure Client logs and the
IntuneManagementExtension log and engage **Cisco support** per their documentation.
