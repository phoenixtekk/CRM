# 6. Troubleshooting Guide — Netskope Client Troubleshooting & Diagnostics Toolkit

This product *is* a troubleshooting toolkit, so this section serves two purposes: (A) the
failure-class runbooks themselves, and (B) troubleshooting the solution — when the toolkit or its
scripts misbehave. Use `NSDIAG-Discovery.ps1` / `NSDIAG-Validation.ps1` for device state,
`NSDIAG-Report.ps1` for device context, and `NSDIAG-Remediation.ps1` for safe fixes.

> **Vendor boundary:** client-internal log paths and Netskope console menus are deferred to the
> official Netskope documentation. The runbooks below describe the failure-class approach and stop at
> the operating-system edge, then hand off to vendor docs/support with the diagnostic bundle.

## Part A — Failure-class runbooks (diagnose then resolve)

### A1. `Client Triage – Steering – Diagnose/Resolve`
| Symptom | Likely cause | Diagnose | Resolve |
|---|---|---|---|
| Traffic not steered to Netskope | Client service/process not running | `NSDIAG-Discovery.ps1` shows service stopped | `NSDIAG-Remediation.ps1 -Restart` |
| Running but no steering | Config not applied / stale | Discovery shows running but Validation shows no steering | `NSDIAG-Remediation.ps1 -Repair`; if unchanged, `-ReEnroll` |
| Some traffic bypasses | Exception/bypass set | Validation flags bypassed destinations | Review the bypass in the Netskope console (deferred to vendor docs) |

### A2. `Client Triage – Authentication – Diagnose/Resolve`
| Symptom | Likely cause | Diagnose | Resolve |
|---|---|---|---|
| Auth/sign-in loop | Identity/SSO loop or stale session | `NSDIAG-Validation.ps1` reports auth state not established | Correct any clock skew, then `NSDIAG-Remediation.ps1 -ReEnroll` |
| Enrollment incomplete | Client never finished enrolling | Discovery shows partial enrollment state | `NSDIAG-Remediation.ps1 -ReEnroll`; confirm device context in `NSDIAG-Report.ps1` |
| Works on some devices only | Device not compliant/managed | `NSDIAG-Report.ps1` shows non-compliant/never-synced | Remediate compliance/enrollment in Intune; re-validate |

### A3. `Client Triage – Performance – Diagnose/Resolve`
| Symptom | Likely cause | Diagnose | Resolve |
|---|---|---|---|
| Slow browsing with client on | Path/latency to the cloud edge | `NSDIAG-Validation.ps1` reports high TCP latency | Investigate the egress path; confirm nearest edge per Netskope docs |
| Slow first-byte / name lookups | DNS resolution delay | Validation reports slow DNS | Fix DNS (resolver/egress); re-test |
| Large transfers slow | Inspection overhead on a specific app | Steering healthy, app-specific slowness | Apply the documented inspection bypass for that app (deferred to Netskope console docs) |

### A4. `Client Triage – Certificate – Diagnose/Resolve`
| Symptom | Likely cause | Diagnose | Resolve |
|---|---|---|---|
| Untrusted-certificate warnings | Decryption root not trusted on device | `NSDIAG-Discovery.ps1` shows the decryption cert missing from trust store | Deploy/trust the decryption root via Intune (cert source per Netskope deployment docs) |
| A pinned app breaks behind proxy | App refuses inspection (cert pinning) | TLS errors only for that app | Add the documented inspection bypass for the pinned app (deferred to Netskope docs) |
| TLS errors after a change | Cert rotated/expired | Validation reports TLS handshake failures | Confirm the current decryption cert is trusted; redeploy if rotated |

## Part B — Troubleshooting the solution itself

### B1. Scripts won't run or report access denied
- Run elevated: `powershell -ExecutionPolicy Bypass -File .\NSDIAG-Discovery.ps1`.
- Confirm local admin (Requirement 2.2); read-only scripts still need elevation to read services/certs.

### B2. `NSDIAG-Report.ps1` can't connect to Graph
- Install the Microsoft Graph SDK and grant `DeviceManagementManagedDevices.Read.All`.
- If consent fails, have an admin grant the scope, then retry `Connect-MgGraph`.

### B3. Remediation seems to do nothing
- By design: `NSDIAG-Remediation.ps1` defaults to `-WhatIf` and only previews. Re-run with the
  explicit action switch (and a change window) to apply.

### B4. Discovery can't find the client
- The client may not be installed (Requirement 2.1) — deploy it per Netskope docs and re-run, or the
  process/service names differ on your client version (confirm against Netskope docs and adjust the
  runbook note).

## Part C — When to escalate to Netskope support
If the bundle shows the client running, steering applied, the device compliant, the decryption cert
trusted, connectivity healthy, and the issue persists, the fault is likely cloud/console-side. Escalate
with the complete `Diagnostic Bundle – Endpoint – Collect` **plus** the client's own logs (locate per
Netskope's documentation for your client version) so Netskope support starts from facts.
