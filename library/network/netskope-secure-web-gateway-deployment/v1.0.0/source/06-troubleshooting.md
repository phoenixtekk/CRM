# 6. Troubleshooting Guide — Netskope Secure Web Gateway (SWG)

Use `NSSWG-Validation.ps1` for device state, `NSSWG-Discovery.ps1` for readiness,
`NSSWG-Report.ps1` for coverage/activity, and `NSSWG-Remediation.ps1` (default `-WhatIf`) for safe
fixes. The exact Netskope console screens referenced below are deferred to Netskope's documentation;
the named control is given so you can find it in your tenant.

## A. Device not steered / traffic bypassing the gateway
| Symptom | Cause | Remediation |
|---|---|---|
| Web activity not appearing in the tenant for a device | Client not installed, or device not in a steered scope | Run `NSSWG-Validation.ps1`; if not steered, add the device to `Web Steering – Pilot – Stage 1` / `Web Steering – Broad – Stage 2` and re-sync with `NSSWG-Remediation.ps1` |
| Client installed but steering inactive | Client not enrolled to the tenant, or upstream proxy interfering | Re-deploy `SWG Client Deployment – Managed Devices – Production`; remove conflicting upstream proxy for steered devices |
| Steering active on-network only | Steering scope/config not applied off-network | Confirm the steering configuration covers off-network in the Netskope steering control |

## B. HTTPS certificate errors
- Browsers show certificate warnings on inspected sites → the decryption certificate is not trusted.
  Confirm `Decryption Certificate – Managed Devices – Production` is in **Trusted Root Certification
  Authorities** (run `NSSWG-Validation.ps1`); re-deploy the Intune trusted-certificate profile.

## C. An app breaks under inspection
- A certificate-pinned app fails only when steered/decrypted → add it to the **SSL decryption bypass
  list** (the SSL decryption policy's exception control) so the flow is not inspected. Re-test.

## D. Wrong block / site miscategorized
| Symptom | Cause | Remediation |
|---|---|---|
| A legitimate site is blocked | Category set to block, or site miscategorized | Confirm the category in `URL Categorization Profile – Standard – Production`; submit a category-correction request and add a documented allow exception in `Web Filtering Policy – All Users – Production` |
| A site that should be blocked is allowed | Rule order or missing category | Reorder so block rules precede allow rules; add the category to the block set |

## E. Coaching/notification page not shown
- A coached category just blocks or allows with no page → confirm the rule action is **coach** (not
  block/allow) and that the gateway notification template is enabled for that action.

## F. Off-network policy inconsistent with on-network
- Off-network users get different behavior → confirm the same `Web Filtering Policy – All Users –
  Production` and steering scope apply regardless of network; identity-based (not IP-based) policy
  follows the user.

## G. Diagnostics quick reference (device side)
```powershell
Get-Service | Where-Object { $_.Name -like '*stagent*' -or $_.DisplayName -like '*Netskope*' }   # client service
Get-ChildItem Cert:\LocalMachine\Root | Where-Object { $_.Subject -like '*Netskope*' }            # decryption cert trusted
Resolve-DnsName www.example.com                                                                    # DNS works
```
Use `NSSWG-Validation.ps1` for a single pass/fail summary of the above.

## H. When to escalate
If the device shows the client running, steering active, and the certificate trusted, but traffic is
still not filtered as expected, collect the client logs and the policy/steering configuration and open
a Netskope support case (Netskope tenant-side policy evaluation is outside device-level remediation).
