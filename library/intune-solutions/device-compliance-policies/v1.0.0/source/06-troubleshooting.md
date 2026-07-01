# 6. Troubleshooting Guide — Device Compliance Policies

Use **`DCP-Validation.ps1`** / **`DCP-Discovery.ps1`** to confirm device state and
**`DCP-Remediation.ps1`** for safe fixes.

## A. Device shows Not compliant unexpectedly
| Symptom | Cause | Remediation |
|---|---|---|
| Compliant device marked Not compliant | A required rule isn't met (firewall off, AV stale, OS below min) | Run `DCP-Discovery.ps1` to find the failing facet; remediate; sync |
| "Compliant" but no policy | No policy assigned + tenant default = Not compliant | Assign the policy to the device's group |
| Stuck "In grace period" | Grace period not elapsed | Wait for the scheduled action, or shorten the grace period |

## B. Evaluation / sync issues
| Symptom | Cause | Remediation |
|---|---|---|
| Status not updating | Device hasn't checked in | Run `DCP-Remediation.ps1` (forces MDM sync); confirm device online |
| BitLocker/Secure Boot "not evaluated" | Health attestation not reporting | Ensure TPM + Secure Boot enabled; reboot; allow attestation to report |

## C. Policy conflicts
- Multiple compliance policies with conflicting settings → Intune uses the most restrictive, but mixed assignments cause confusion. Run `DCP-ConflictCheck.ps1`; consolidate to one authoritative policy per scope.
- A legacy GPO/another MDM setting the same security control can fight Intune — remove the duplicate.

## D. Conditional Access interplay
- Users blocked unexpectedly → a CA policy requires compliant device but the device is Not compliant. Verify with **Entra → Sign-in logs**; fix the compliance failure or scope the CA policy.
- Always pilot CA in **Report-only** first to see impact before enforcing.

## E. Defender for Endpoint threat-level rule
- Threat-level rule always failing → the Defender for Endpoint connector isn't Active, or the device isn't onboarded. Confirm the connector and onboarding (see the Defender integration solution).

## F. Diagnostics quick reference
```powershell
Get-MpComputerStatus                 # Defender AV / real-time protection
Get-NetFirewallProfile               # firewall state
manage-bde -status                   # BitLocker
Confirm-SecureBootUEFI               # Secure Boot
```
Intune: **Devices → device → Device compliance** shows per-setting pass/fail.

## G. When to escalate
If `DCP-Discovery.ps1` shows all facets healthy but the device still reports Not compliant after a
sync and attestation cycle, collect the compliance evaluation details and open a Microsoft support case.
