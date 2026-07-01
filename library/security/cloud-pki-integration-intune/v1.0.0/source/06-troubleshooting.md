# 6. Troubleshooting Guide — Cloud PKI Integration with Intune

Use `CPKI-Discovery.ps1` for connector/profile state, `CPKI-Validation.ps1` for per-device issuance
and trust, `CPKI-Report.ps1` for fleet coverage/expiry, and `CPKI-Remediation.ps1` (default
`-WhatIf`) for safe fixes. Cloud-PKI **product** internals (console, connector install, CA template)
are deferred to the **vendor's documentation**.

## A. Connector unhealthy / no issuance
| Symptom | Cause | Remediation |
|---|---|---|
| All SCEP/PKCS profiles fail | Cloud PKI Intune connector down or expired | Run `CPKI-Discovery.ps1`; in the vendor console repair/re-register the connector per vendor docs; confirm **Active/healthy** in Intune → Certificate connectors |
| Connector missing in Intune | Connector never registered or wrong tenant | Re-run the vendor connector setup; confirm it targets this tenant and has the required Graph permissions |

## B. Trust chain problems
| Symptom | Cause | Remediation |
|---|---|---|
| Leaf installs but scenario fails | Root/intermediate not deployed or not trusted | Confirm `Trusted Root – Cloud PKI – All Devices` (and intermediate) is assigned to the device's group and shows **Succeeded**; run `CPKI-Validation.ps1` |
| Chain incomplete | Intermediate missing | Create `Trusted Intermediate – Cloud PKI – All Devices` and assign it to the same groups |

## C. Certificate not issuing to the device
| Symptom | Cause | Remediation |
|---|---|---|
| SCEP profile shows Error/Pending | Wrong SCEP URL, challenge failure, or group not assigned | Re-check the **SCEP server URLs** value against vendor docs; confirm the device is in the scope group; `CPKI-Remediation.ps1` (sync + re-evaluate) |
| PKCS profile fails | CA name / template name wrong, or cloud PKI doesn't support PKCS | Verify the issuing CA + template identifiers with the vendor; if PKCS unsupported, switch user issuance to SCEP (Certificate type **User**) |
| Subject/SAN rejected | Template doesn't permit the requested subject/SAN | Align the Intune profile's subject/SAN with what the cloud PKI template allows |

## D. Wi-Fi / VPN / auth scenario fails on the new certificate
- Confirm the scenario profile references the **cloud PKI** client certificate + root, not the legacy
  one (Implementation Step 6). Confirm the certificate's **EKU** includes **Client Authentication** and
  the **SAN** matches what the network/NPS/RADIUS or service expects.
- Check the device actually received the cloud certificate (`CPKI-Validation.ps1`) before blaming the
  scenario.

## E. Migration / coexistence issues
| Symptom | Cause | Remediation |
|---|---|---|
| Users lose network mid-migration | Legacy chain removed too early, or scenario re-pointed before issuance completed | Keep **both** roots trusted until devices hold a valid cloud certificate; re-point scenarios only after `CPKI-Report.ps1` confirms coverage; rollback = re-point to legacy |
| Devices still renewing from legacy CA | Legacy SCEP/PKCS profile still assigned | Drain: unassign the legacy profile per scenario only after the cloud certificate is validated fleet-wide |

## F. Expiry / renewal
- Near-expiry certificates with no renewal → confirm the **renewal threshold** is set on the SCEP/PKCS
  profile and the connector is healthy; `CPKI-Report.ps1` lists upcoming expiries to chase.

## G. Diagnostics quick reference
```powershell
# Local device certificate state (Windows)
Get-ChildItem Cert:\LocalMachine\My | Select-Object Subject, Issuer, NotAfter, Thumbprint
Get-ChildItem Cert:\LocalMachine\Root | Where-Object { $_.Subject -like '*<cloud PKI CA name>*' }
# Force an Intune sync
Start-Process -FilePath "C:\Windows\System32\deviceenroller.exe" -ArgumentList "/c /AutoEnrollMDM"
```
Use `CPKI-Discovery.ps1` / `CPKI-Validation.ps1` / `CPKI-Report.ps1` for the Graph-side picture.

## H. When to escalate
If the connector is healthy, the trust chain is present and trusted, the device is in the scope group
and synced, and the certificate still will not issue (or the scenario still fails on a valid
cloud-issued certificate), collect the SCEP/PKCS profile **device status** detail and the cloud PKI
connector/issuance logs and open a case with **the cloud PKI vendor** (issuance path) and/or
**Microsoft** (Intune profile delivery), as the evidence indicates.
