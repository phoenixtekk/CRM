# 6. Troubleshooting Guide — SSL/TLS Inspection & Decryption Rollout (Netskope)

Use `NSSSL-Validation.ps1` / `NSSSL-Discovery.ps1` for device certificate-trust state,
`NSSSL-Report.ps1` for fleet readiness, and `NSSSL-Remediation.ps1` (default `-WhatIf`) for safe
fixes. Netskope console specifics are deferred to the official Netskope documentation.

## A. Certificate warnings on decrypted sites
| Symptom | Cause | Remediation |
|---|---|---|
| Every decrypted site shows a certificate warning | Inspection root not in the device trusted root store | Run `NSSSL-Validation.ps1`; if missing, run `NSSSL-Remediation.ps1` to request a sync, confirm the trusted-certificate profile is assigned to the device's group |
| Warning on some sites only | Missing intermediate in the chain | Deploy the inspection intermediate as a second Trusted certificate profile (Intermediate store) |
| Trust deployed but still warning | Device not synced / profile not applied yet | Force a sync; re-run `NSSSL-Validation.ps1` after a policy cycle |

## B. Applications breaking after decryption is enabled
- Certificate-pinned applications reject the inspection certificate by design. Add them to
  `Do-Not-Decrypt – Sensitive & Pinned – All Stages` so they are passed through, not decrypted.
- Confirm the bypass list is evaluated before the decrypt rule (rule order), or pinned traffic may be
  decrypted before the bypass matches.

## C. Sensitive traffic being decrypted unexpectedly
- A banking/health site shows the inspection certificate instead of its own -> it is being decrypted.
  Confirm the category is in the do-not-decrypt list and that the bypass rule precedes the decrypt
  rule in the decryption policy.

## D. Pilot scope leaking to non-pilot users
- Non-pilot devices are being decrypted -> the decryption policy scope or the assigned group is wider
  than intended. Confirm `SSL Inspection – Pilot Group – Pilot` is scoped only to
  `SSL Inspection – Pilot Users – Pilot`.

## E. User-experience / performance complaints
- Validate page-load responsiveness on pilot devices (Testing Test 6). If degradation is real, stage
  expansion more slowly and review which categories truly need decryption; bypass low-value,
  high-volume categories where appropriate.

## F. Diagnostics quick reference
```powershell
# Inspection root present in the device trusted root store?
Get-ChildItem Cert:\LocalMachine\Root | Where-Object { $_.Subject -match 'Netskope' } | Format-List Subject, Thumbprint, NotAfter
# Validate the chain of a specific cert
$c = Get-ChildItem Cert:\LocalMachine\Root | Where-Object { $_.Subject -match 'Netskope' } | Select-Object -First 1
(New-Object System.Security.Cryptography.X509Certificates.X509Chain).Build($c)
```

## G. When to escalate
If the inspection root is confirmed present and validates, the device is synced, the do-not-decrypt
list and rule order are correct, and decryption still misbehaves (warnings, broken apps, wrong
bypass), capture the device certificate-trust state from `NSSSL-Report.ps1` and the Netskope policy
configuration, then open a case with Netskope support per the official Netskope documentation.
