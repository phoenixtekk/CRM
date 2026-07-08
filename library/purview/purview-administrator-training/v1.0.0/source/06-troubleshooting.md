# 6. Troubleshooting Guide — Microsoft Purview Administrator Training

Use `OPSTRAIN-Readiness.ps1` for the current environment/connectivity state, `OPSTRAIN-LabBaseline.ps1`
for the known-good "before," `OPSTRAIN-LabValidate.ps1 -Lab …` to re-check a lab's pass/fail gate, and
`OPSTRAIN-CompetencyReport.ps1` for the roll-up. Cross-check live state in the **Purview portal**.

> **Training, not determination.** This guide resolves *technical* faults in the training environment
> (a lab object missing, a wrong mode, connectivity, a scope error). Whether an *illustrative*
> taxonomy/period is *correct in production* is a records/legal/privacy determination — out of scope.

> **Verify in your tenant.** Purview availability is **licensing-dependent** and paths **evolve** — a
> "feature not visible" symptom is very often **licensing**, not a fault. Confirm exact paths for your
> tenant and defer volatile specifics to Microsoft's documentation.

## A. Connectivity & toolchain
| Symptom | Cause | Remediation |
|---|---|---|
| `OPSTRAIN-Readiness.ps1` says not connected | No S&C PowerShell session | Run `Connect-IPPSSession` (ExchangeOnlineManagement module) with a modern-auth/MFA admin, then re-run |
| Graph checks skipped/fail | Not connected to Graph, or missing scopes | `Connect-MgGraph` with the scopes the check needs (e.g. group read); consent if prompted |
| `Get-Label` errors immediately | Session expired or wrong role | Reconnect; confirm the admin holds a Purview role that can read labels (GR §2) |
| Cmdlet "not recognized" | Module not installed / old version | `Install-Module ExchangeOnlineManagement` / `Install-Module Microsoft.Graph`; update to current |

## B. Scope group problems (`TRAIN-Pilot-Users`)
| Symptom | Cause | Remediation |
|---|---|---|
| Readiness reports the group missing | Not yet created | `OPSTRAIN-LabScope.ps1` (preview) then `-Commit`, or create it in **Entra ID → Groups** |
| A real user appears in the group | Wrong member added | Remove immediately — the group must contain **only test accounts**; this gate protects every lab |
| Label/DLP won't target the group | Group type not supported for that policy, or replication delay | Use a supported group type for the policy; allow directory replication and retry |

## C. Lab 1 Labels
| Symptom | Cause | Remediation |
|---|---|---|
| Test account doesn't see the label | Label not published, wrong scope, or client not synced | Confirm `TRAIN-LabelPolicy-Pilot` publishes `TRAIN-Label-Confidential` to `TRAIN-Pilot-Users`; allow policy propagation (can take time); restart the Office client |
| `OPSTRAIN-LabValidate.ps1 -Lab Labels` FAIL | Label or policy name mismatch | Match names verbatim (`TRAIN-Label-Confidential`, `TRAIN-LabelPolicy-Pilot`); re-check `Get-Label`/`Get-LabelPolicy` |
| A real user saw the label | Policy scoped too broadly | Narrow the policy to `TRAIN-Pilot-Users` **only**; unpublish and republish scoped |

## D. Lab 2 DLP — the critical "never enforce" checks
| Symptom | Cause | Remediation |
|---|---|---|
| Validate FAIL: `Mode = Enable` | Policy was turned on instead of test | **Set it back to test** (`Set-DlpCompliancePolicy -Mode TestWithoutNotifications`) — a training DLP policy must never enforce; or delete it |
| No match on the synthetic document | Rule condition / sensitive info type mismatch | Confirm the rule's sensitive info type matches the synthetic content; allow policy sync before testing |
| Content was actually blocked | Policy was enforcing | This is a FAIL — revert to test mode or delete; investigate why it was enabled |
| Advanced DLP options missing | Unlicensed | Author a basic policy in test mode, or run read-only (**verify licensing**) |

## E. Lab 4 Auto-labeling — simulation only
| Symptom | Cause | Remediation |
|---|---|---|
| Validate FAIL: not in simulation | Policy enabled | Return to **simulation** (never enable a training auto-label policy) or delete `TRAIN-AutoLabel-Sim` |
| No simulation results | Not enough matching content, or run not finished | Add synthetic matching content; allow the simulation to complete (can take time) |
| Auto-labeling not available | Unlicensed (E5) | Walkthrough only; set the gate to "explain simulation vs enable" (**verify licensing**) |

## F. Lab 3 Retention
| Symptom | Cause | Remediation |
|---|---|---|
| Policy won't delete at teardown | Retention objects have a removal window | Expected — log it; retention policies/labels can take time to fully remove (a real operational lesson) |
| Can't mark the label a record | Records management not licensed, or intentionally avoided | Don't mark records in a shared training tenant; discuss what it would do (**verify licensing**) |
| Validate FAIL | Name/period mismatch | Match `TRAIN-Retention-Pilot`/`TRAIN-RetLabel-Illustrative`; confirm the illustrative period via `Get-RetentionComplianceRule` |

## G. Modules 5–6 Insider Risk / Communication Compliance
| Symptom | Cause | Remediation |
|---|---|---|
| Feature not visible | Unlicensed (E5) | Walkthrough only; gate = "explain the policy model, privacy controls, role separation" (**verify licensing**) |
| Can't separate roles | One person holds all roles | Assign analyst / investigator / admin to **different** people — role separation is a privacy control, not optional |
| Anonymization off | Setting not enabled | Turn on **pseudonymization/anonymization** before any walkthrough; never use real employee data |
| Pressure to "resolve a case" in training | Confusing configure with determine | Stop — **case outcomes are HR/legal's determination**; training only covers the technical policy config |

## H. Module 7 Audit
| Symptom | Cause | Remediation |
|---|---|---|
| Search returns nothing | Window too narrow, activity not logged yet, or auditing off | Widen the window; confirm unified audit logging is on; generate then search for a known activity |
| Older events missing | Audit **Standard** retention limit | Expected — discuss **Audit Premium** longer retention (**verify licensing**) |

## I. Module 8 eDiscovery
| Symptom | Cause | Remediation |
|---|---|---|
| Custodian not on hold | Holds can take up to 24h; or licensing | Wait up to 24h; confirm the **training** custodian's license supports being held; re-check the case |
| A real custodian was added | Wrong account | Remove immediately — hold **only** a `TRAIN-Pilot-Users` test account; never a real custodian |
| Premium features missing | Unlicensed | Run a Standard case or walkthrough (**verify licensing**) |

## J. Validation / competency roll-up
| Symptom | Cause | Remediation |
|---|---|---|
| `-Lab All` shows unexpected FAILs | Name mismatch or feature unlicensed | Match object names verbatim; for unlicensed features record "walkthrough only" as the documented reason |
| Teardown check still shows `TRAIN-` objects | Not fully removed, or retention in its window | Remove remaining objects; log any retention object still inside its removal window |
| Report empty | Validation not run first | Run `OPSTRAIN-LabValidate.ps1 -Lab All` before `OPSTRAIN-CompetencyReport.ps1` |

## When to escalate to the governance functions (not a "fix")
- A trainee asks what the **real** retention period, records classification, legal hold scope, or
  insider-risk/communication-compliance **case outcome** should be → that is **not** a training fault to
  fix. Route it to **records / legal / privacy / HR** — the training deliberately uses illustrative
  values and defers the determination.
