# 5. Testing Guide — Android Enterprise Enrollment Troubleshooting

Testing here proves two things: that the **diagnostic tools read the tenant correctly**, and that each
**fix actually resolves the reproduced failure** at its pass/fail gate. Run the environment tests once, then
the symptom tests for whichever failure you are triaging. Every test is **reproduce → check → gate**.

## A. Environment validation (run once, before diagnosing)
| # | Test | How | Pass |
|---|---|---|---|
| A1 | Graph connectivity & read scopes | `ANDROIDDX-EnrollmentReadiness.ps1 -Days 14` | Runs clean; readiness table prints; no permission error |
| A2 | Binding is readable | `ANDROIDDX-BindingHealth.ps1 -JsonPath .\binding.json` | Prints `BindStatus`/owner/sync; snapshot written |
| A3 | Reachability tool runs from device network | `ANDROIDDX-EndpointReachability.ps1 -CsvPath .\endpoints.csv` on the device segment | Every required endpoint `Reachable`; CSV written |
| A4 | Reproduction device ready | Factory reset `Repro Device – Android – Test`; note OS build + GMS | Device wipes and is ready to re-enroll |
| A5 | Scope helper preview | `ANDROIDDX-Set-ScopeTargeting.ps1 -GroupName "Enrollment Scope - Android - Pilot" -MembersCsv .\pilot-users.csv -WhatIf` | Shows planned adds; writes nothing |

## B. Binding / connector (Playbook A)
| # | Test | Pass |
|---|---|---|
| B1 | Binding healthy | `ANDROIDDX-BindingHealth.ps1` reports `bound`, owner present, sync `success` and recent |
| B2 | One model only | Exactly one of account-enterprise / Google Workspace binding is in place |
| B3 | App sync recovers | After a forced sync, `LastAppSyncStatus = success` |
| **Gate** | **Binding gate** | **All of B1–B3 pass before diagnosing anything downstream** |

## C. Enrollment-method path (Playbook C)
| # | Test | Pass |
|---|---|---|
| C1 | Device-owner profile present | Readiness tool shows ≥1 `androidDeviceOwnerEnrollmentProfile` for fully managed/dedicated/corp-WP |
| C2 | Correct method state | Reproduction device provisions into the intended state (work profile vs fully managed vs dedicated) |
| C3 | Token valid | QR/token is current (not expired); a regenerated token enrolls |

## D. Network / endpoints (Playbook D)
| # | Test | Pass |
|---|---|---|
| D1 | Endpoints reachable | `ANDROIDDX-EndpointReachability.ps1` = all required hosts `Reachable` from the device network |
| D2 | No TLS interception on Google hosts | Proxy does not intercept TLS to `accounts.google.com` / `*.googleapis.com` / `play.google.com` |
| D3 | Device basics | Device date/time correct; Google Play services present/current (GMS devices) |

## E. Dev-vs-prod (Playbook B)
| # | Test | Pass |
|---|---|---|
| E1 | Snapshots exportable | `ANDROIDDX-DiagnosticReport.ps1 -JsonPath` produces a dev and a prod snapshot |
| E2 | Diff surfaces drift | `-CompareConfig` lists the differing settings (or confirms none) |
| E3 | Reconciled prod enrolls | After reconciling the surfaced difference, prod reproduction device enrolls |

## F. Account add (Playbook F) — the headline symptom
| # | Test | Pass |
|---|---|---|
| F1 | Correct flow used | The managed account is added by the profile/enrollment (not a manual consumer Gmail add) |
| F2 | Managed account provisions | Reproduction device adds the **managed** Google account; managed Google Play is usable |
| F3 | Endpoints clear | D1–D3 pass (account-add failures are usually binding or endpoint) |

## G. Post-AMAPI (Playbook E)
| # | Test | Pass |
|---|---|---|
| G1 | Re-enrollment requirement known | Whether the change forces re-enrollment is **verified against current Microsoft guidance / the tenant** |
| G2 | Fresh tokens | Regenerated QR/tokens enroll; old ones retired |
| G3 | Post-migration sync | `LastAppSyncStatus = success` after a forced sync |

## H. Fix-confirmation gates (must pass before expanding)
| Symptom fixed | Gate |
|---|---|
| Can't add a Google account | Reproduction device adds the managed account; managed Google Play usable (F2) |
| Dev works / prod fails | Prod reproduction device completes web/account-driven enrollment (E3) |
| Binding/connector error | `bound` + owner + `success` sync (B1) |
| Endpoint block | All endpoints `Reachable`, no Google-host TLS interception (D1–D2) |
| Method provisioning | Device lands in the intended method state (C2) |
| Post-AMAPI | Reproduction device enrolls under the post-AMAPI path; sync `success` (G1–G3) |

## Exit criteria (ready to expand)
- The routed Playbook node's **pass/fail gate** is green on `Repro Device – Android – Test`.
- The fix passes on **two or three** `Enrollment Scope – Android – Pilot` devices.
- `ANDROIDDX-EnrollmentReadiness.ps1` shows PASS on the previously-failing checks.
- Any high-impact change (binding/connector/AMAPI) was applied in the **change window** with the **rollback**
  recorded, and re-enrollment behavior was **verified**, not assumed.
