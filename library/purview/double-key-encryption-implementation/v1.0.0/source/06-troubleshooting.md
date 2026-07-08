# 6. Troubleshooting Guide — Double Key Encryption (DKE) Implementation, Microsoft Purview

Use `IPDKE-Discovery.ps1` for the tenant's current label/DKE config, `IPDKE-Validation.ps1` to confirm
the named objects and endpoint, `IPDKE-Report.ps1` for DKE usage and the content-service exclusions,
`IPDKE-Scope-And-ServiceHealth.ps1` to probe the key service and build scope groups, and
`IPDKE-Remediation.ps1` (default `-WhatIf`) for the one safe fix (enable a disabled label policy).

## A. "Use Double Key Encryption" option is missing on the label
| Symptom | Cause | Remediation |
|---|---|---|
| No DKE option when configuring a label's encryption | Licensing does not include DKE | Confirm Microsoft 365 E5 / E5 Compliance (Requirement 2.1); run `IPDKE-Discovery.ps1`; **verify your licensing/tenant** against Microsoft's current DKE docs |
| Option present but greyed out | Role lacks label-configuration rights | Confirm Compliance Administrator / Information Protection Admin (Requirement 2.2) |

## B. Key-service endpoint does not respond / bad public key
- Browse to `https://dke.contoso.com/DKE-Key-01`; run
  `IPDKE-Scope-And-ServiceHealth.ps1 -DkeEndpointUrl https://dke.contoso.com/DKE-Key-01`.
- If unreachable: check the host is running, DNS resolves, the firewall/network path is open, and the
  service is bound to HTTPS. If TLS fails: confirm a trusted certificate (not self-signed) for the DNS
  name.
- If it responds but not with the public-key JSON: re-check the service's `appsettings.json` key
  **Name** (`DKE-Key-01`) and that the key pair was generated per Microsoft's docs; the URL path must
  match the configured key name.

## C. Users cannot apply the DKE label
| Symptom | Cause | Remediation |
|---|---|---|
| DKE label not visible in Office | Label policy not published to the user, or still propagating | Confirm the user is in `Purview - DKE Pilot Users` and that `Label Policy - DKE Ultra Confidential - DKE Pilot` targets them; allow up to 24 hours; `IPDKE-Validation.ps1` |
| Label visible but applying fails | Unsupported client/platform | Confirm a supported Windows Office desktop build with built-in labeling (Requirement 2.5); **verify current client support** |
| Apply fails with an auth/consent error | Entra app registration or admin consent incomplete | Re-check `App - DKE Key Service` (Application ID URI, exposed scope, admin consent granted); confirm `JwtAudience`/`JwtIssuer` in `appsettings.json` match the app and tenant |

## D. Users cannot open DKE content
| Symptom | Cause | Remediation |
|---|---|---|
| Authorized user cannot open the item | Client cannot reach the key service | Confirm reachability of `https://dke.contoso.com/DKE-Key-01` from the client network; the key service must be up (its availability gates access) |
| User denied opening the item | Not in the authorized readers | Confirm the user is in `SG - DKE Ultra Confidential Readers` and in the service's authorized-users setting; the two must align |
| Opens on one machine, not another | Endpoint blocked on that network segment | Open the network path to the DKE endpoint for that segment |

## E. DKE content not appearing in DLP / eDiscovery / Copilot
- **This is by design, not a fault.** Microsoft cannot decrypt DKE content, so it is excluded from
  content-based DLP, eDiscovery content search, co-authoring, and Copilot. Confirm the accepted
  trade-off (Overview, Limitations; Testing Test 5) and **verify the current unsupported-services list
  for your tenant**. If content services are required for this data, it should not be DKE-protected.

## F. Endpoint URL wrong on the label
- Run `IPDKE-Validation.ps1 -DkeEndpointUrl https://dke.contoso.com/DKE-Key-01`; if the label's URL
  does not match, edit the label in the Purview portal (Information Protection → Sensitivity labels →
  the label → **Encryption**) and correct the DKE endpoint URL. Changing it here is a portal decision —
  `IPDKE-Remediation.ps1` deliberately never edits DKE encryption.

## G. Diagnostics quick reference
```powershell
# Security & Compliance PowerShell (Exchange Online Management module)
Connect-IPPSSession
Get-Label | Select-Object DisplayName, Priority, EncryptionEnabled
Get-LabelPolicy | Select-Object Name, Enabled
# DKE endpoint (read-only reachability)
Invoke-WebRequest -Uri 'https://dke.contoso.com/DKE-Key-01' -UseBasicParsing | Select-Object StatusCode
```
Property names for the DKE endpoint URL on a label can vary by module version — the scripts probe the
likely names; verify against Microsoft's current DKE documentation.

## H. When to escalate
If licensing is correct, the label policy is published and propagated, the user is a supported client
in scope, the app registration/consent is complete, and the key-service endpoint is healthy — yet DKE
still fails after 24 hours — collect the output of `IPDKE-Discovery.ps1`, `IPDKE-Validation.ps1`, and
`IPDKE-Scope-And-ServiceHealth.ps1`, plus the key-service logs, and open a Microsoft support case.
Infrastructure issues with the key service (hosting, TLS, network) are handled by the team that owns
the host; regulatory/sovereignty questions go to compliance/legal.
