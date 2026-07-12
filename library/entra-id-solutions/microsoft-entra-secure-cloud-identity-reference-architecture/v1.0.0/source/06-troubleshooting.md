# 6. Troubleshooting Guide — Microsoft Entra: Secure Cloud Identity Reference Architecture

This is a **design deliverable**, so the "failures" are mostly failures of *evidence gathering* and
*design completeness*, not tenant outages. Use `ENTARCH-Discovery.ps1` for the current posture,
`ENTARCH-IdentityInventory.ps1` and `ENTARCH-PrivilegedAccessReview.ps1` for the identity and
privileged inventories, `ENTARCH-Report.ps1` (and its KQL) for posture metrics, and
`ENTARCH-Validate.ps1` to check the blueprint against the tenant. All scripts are read-only.

## A. Assessment scripts fail to connect or read
| Symptom | Cause | Remediation |
|---|---|---|
| `Connect-MgGraph` fails or scopes missing | Graph SDK not installed, or read scopes not consented | `Install-Module Microsoft.Graph -Scope CurrentUser`; re-run and accept the read-only scopes (`Directory.Read.All`, `Policy.Read.All`, `RoleManagement.Read.Directory`, `AuditLog.Read.All`, `Application.Read.All`) |
| `Connect-AzAccount` fails | Az module missing or no subscription context | `Install-Module Az -Scope CurrentUser`; sign in; the subscription/RBAC section is optional context — skip if no Azure subscription |
| Reads return little/nothing | Operator lacks `Global Reader` / `Security Reader` | Assign the read-only roles (requirement 2.1); confirm you are in the correct tenant |

## B. Posture / KQL evidence is thin or empty
| Symptom | Cause | Remediation |
|---|---|---|
| Sign-in KQL returns nothing | Logs not streamed to Log Analytics, or short retention | Query the portal `Monitoring -> Sign-in logs` directly, or configure `Diagnostic settings` to stream `SignInLogs`/`AuditLogs`; widen the time range |
| MFA-coverage numbers look wrong | Mixed per-user MFA and Conditional Access, or registration vs. enforcement confusion | Read registration from the authentication-methods report and enforcement from CA; the report distinguishes them — do not conflate "registered" with "required" |
| Legacy-auth count is zero but you expected some | Legacy auth may already be blocked, or the lookback is too short | Confirm existing CA legacy-auth block from Discovery; widen `-LookbackDays`; a true zero is a good finding — record it |

## C. Licensing reality does not match the design's assumptions
- The most common design flaw: an `ADR` assumes **P2**, **Entra ID Governance**, **Global Secure
  Access**, or **Verified ID** the tenant does not hold. `ENTARCH-Discovery.ps1` reports the true
  license position. Fix the design, not the tenant: either make license acquisition an explicit
  `Phase 0`/roadmap prerequisite, or design a documented P1-only interim and note the gap. Always flag
  the dependency *verify current availability in your tenant* — bundles and preview status change.

## D. A decision has no owner / the design stalls
- A domain with no named accountable owner is a finding, not a blocker. Record the decision as
  `ADR-0nn ... - <Domain>` in **`Proposed`** status with the open question stated, and escalate to get
  an owner. Never invent the answer to keep moving — an unowned invented decision is worse than a
  documented open one.

## E. The design conflicts with an existing control
| Symptom | Cause | Remediation |
|---|---|---|
| New design contradicts a live CA policy or PIM config | Assess did not classify the existing control | Go back to Stage 1: tag every existing control **adopt / adjust / replace**; reconcile the `ADR` against the adopt set so the design is gap-only, not a silent overwrite |
| Two ADRs disagree | Decisions made in different domains without cross-check | Cross-reference the conflicting `ADR`s; supersede the weaker one with a new `ADR` (status `Superseded`) — keep the history |

## F. `ENTARCH-Validate.ps1` flags gaps
| Symptom | Cause | Remediation |
|---|---|---|
| Break-glass not found | No emergency accounts exist yet | Design mandates two cloud-only accounts; record their creation as `Phase 0 - Foundation`; do not finalize the privileged-access domain without them |
| Mandated design groups missing | They are roadmap items, not yet built | Expected before the builds run — the validation distinguishes "missing (roadmap)" from "missing (should exist)"; confirm they are scheduled in the roadmap |
| All-users CA policy with no exclusions | A pre-existing lock-out risk the design must reconcile | Flag it in the Zero Trust domain; the `ENTZTCA` build fixes it (exclude break-glass) — record the reconciliation as an `ADR` |

## G. The blueprint is treated as the build (scope confusion)
- Symptom: a stakeholder expects Conditional Access, PIM, or governance to be *configured* by this
  deliverable. Cause: this is the **design**, not the build. Remediation: point to the domain's build
  cross-reference and the roadmap phase — the configuration is delivered by `ENTZTCA` / `ENTPIM` /
  `ENTIGA` etc. Set this expectation at kickoff (see the Solution Overview "this is a design product").

## H. Diagnostics quick reference
```powershell
# Confirm read-only Graph context and the true licensing position
Connect-MgGraph -Scopes 'Directory.Read.All','Policy.Read.All','RoleManagement.Read.Directory' -NoWelcome
((Invoke-MgGraphRequest -Method GET -Uri '/v1.0/subscribedSkus').value).servicePlans.servicePlanName |
  Where-Object { $_ -match 'AAD_PREMIUM|Governance|GLOBAL_SECURE_ACCESS|Verified' } | Sort-Object -Unique
# Count permanent (non-PIM) privileged role assignments — a key design driver
(Invoke-MgGraphRequest -Method GET -Uri '/v1.0/roleManagement/directory/roleAssignments?$count=true' -Headers @{ ConsistencyLevel='eventual' }).'@odata.count'
```

## I. When to escalate
This deliverable changes nothing in the tenant, so there is no outage to escalate. Escalate instead
when a **design decision** cannot be made because an owner is unavailable or a regulatory/data-residency
constraint is unclear — that is a business/compliance escalation, and the architecture records the open
`ADR` until it is resolved. If the Assess scripts reveal an **active** security problem (for example a
surge of risky sign-ins or a suspicious privileged assignment), treat that as a security incident on
its own track — do not wait for the design to complete.
