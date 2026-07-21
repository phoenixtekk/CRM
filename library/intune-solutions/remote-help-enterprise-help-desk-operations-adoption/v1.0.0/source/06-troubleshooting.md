# 6. Troubleshooting Guide — Remote Help Operations & Adoption

Use **`RHELPOPS-Discovery.ps1`** to see the current role/scope model, **`RHELPOPS-Validate.ps1`** for
a PASS/FAIL check of the whole model, **`RHELPOPS-Test-Scope.ps1`** to prove a tier's reach, and
**`RHELPOPS-Report.ps1`** for KPI data. Object names match the Implementation Guide exactly.

> This layer assumes Remote Help is already deployed (base `remote-help` solution). If the app won't
> enable/install or a session won't connect **at all**, that is a base-deployment issue — see the
> base Remote Help solution's troubleshooting, not this one.

## A. Agent can't help / wrong scope
| Symptom | Cause | Remediation |
|---|---|---|
| Agent can't help a user they should | Agent not in the tier group, or the scope group doesn't contain that user | Add the agent to `RHELP-T1/2/3-Agents`; add the user to the correct `RHELP-Scope-*` group; run `RHELPOPS-Test-Scope.ps1` |
| Agent **can** help a user they should NOT (over-reach) | Role scope too broad, or tier assigned an extra scope group | Run `RHELPOPS-Test-Scope.ps1` (reports over-reach); remove the extra scope group from that tier's assignment (`RHELP Assignment – Tier N`) |
| Agent has more control than intended (e.g. Tier 1 can take control) | Wrong role on the tier | Confirm the tier uses its role — Tier 1 → `RHELP Role – Tier 1 View`, Tier 2 → `…Control`, Tier 3 → `…Elevation`; re-assign with `RHELPOPS-Set-RoleScope.ps1` |
| Scope seems ignored | How Remote Help evaluates scope groups vs. scope tags may differ from expectation | **Verify the current scope-gating behavior against Microsoft documentation**; re-run Testing Test 1 to confirm the actual boundary before trusting it |

## B. Unattended access not available / not among tiers
| Symptom | Cause | Remediation |
|---|---|---|
| Unattended option missing entirely | Remote Help may not offer unattended for your platform/scenario, or it isn't enabled | **Verify availability against current Microsoft documentation**; if unsupported, record it in the policy and route those cases to an alternative governed path — do not work around it |
| Unattended works on a device it shouldn't | Device wrongly in `RHELP-Scope-Unattended-Devices` | Remove the device from the group; keep only approved kiosks/shared/no-consent devices |
| A non-Tier-3 tier can run unattended | Unattended scope attached to a role other than Tier 3 | Detach `RHELP-Scope-Unattended-Devices` from Tier 1/Tier 2 assignments; keep it only on `RHELP Assignment – Tier 3`; re-run `RHELPOPS-Validate.ps1` |
| Unattended session has no approving change | Guardrail skipped | Enforce the change/ticket precondition (Step 4.3); reject sessions without it |

## C. Session not logged to a ticket
| Symptom | Cause | Remediation |
|---|---|---|
| Completed session leaves no ticket record | Agent started ad-hoc, not from a ticket | Enforce "every session starts from a ticket" (Step 5b.1); coach the agent |
| Ticket record missing required fields | Logging step skipped | Require start/end time, attended/unattended, actions, and outcome on close (Step 5b.6); add it to the ticket template |
| Can't tie platform activity to a ticket | No ticket id captured | Record the `TicketId` in the session log so `RHELPOPS-Report.ps1` output can be joined to ITSM data |

## D. KPIs missing / can't report
| Symptom | Cause | Remediation |
|---|---|---|
| `RHELPOPS-Report.ps1` returns nothing | Reporting access missing, or the Graph usage endpoint differs | Grant the reporting account read access; **verify the current Remote Help usage endpoint/scopes against Microsoft documentation**; fall back to Intune → Tenant administration → Remote Help usage report |
| Volume shows but outcome/adoption KPIs blank | Those KPIs need ITSM data | Enrich the CSV with ticket data (attended/unattended, handle time, FCR, escalation, ticket id) per the provided columns |
| Per-tier split missing | Tier isn't derivable from platform data alone | Map the agent to its tier group (from `RHELPOPS-Discovery.ps1`) when enriching the report |
| `RHELPOPS-Validate.ps1` FAILs "reporting reachable" | Audit/usage endpoint didn't respond | Confirm scopes/permissions and endpoint; retry |

## E. Low adoption
| Symptom | Cause | Remediation |
|---|---|---|
| Users don't request help / low adoption rate | No single request path or unclear comms | Publish the "How to get remote help" note (Step 7b.1); make the ticket queue the one entry point |
| Users decline sessions | Trust/consent not set | State plainly that agents are Entra-authenticated, sessions need **consent**, and are **audited** |
| Agents don't use the tool | Enablement gap | Train each tier on capability, scope, escalation, and logging (Step 7b.3) |
| Adoption can't be measured | No defined entry point/KPI | Define the adoption-rate KPI (eligible tickets using Remote Help) and measure from the ticket queue |

## F. Scripts
Run from a workstation with the **Microsoft Graph PowerShell SDK** installed
(`Install-Module Microsoft.Graph -Scope CurrentUser`). All are read-only **except**
`RHELPOPS-Set-RoleScope.ps1`, which **defaults to `-WhatIf`** (dry run) and changes nothing until you
pass `-WhatIf:$false`.

| Script | Use it when |
|---|---|
| `RHELPOPS-Discovery.ps1` | You need to see the current role assignments, scope groups, and who-can-help-whom |
| `RHELPOPS-Validate.ps1` | You want a PASS/FAIL on role/scope model, reporting, and unattended governance |
| `RHELPOPS-Test-Scope.ps1` | You must prove a tier is scoped to the intended users and no more (over-reach/gap) |
| `RHELPOPS-Report.ps1` | You need the usage/outcome/adoption KPI export (CSV) |
| `RHELPOPS-Set-RoleScope.ps1` | You want to apply/adjust one tier's role+scope binding (dry-run first) |

```powershell
# See the current model
powershell -ExecutionPolicy Bypass -File .\RHELPOPS-Discovery.ps1

# Validate the whole operating model (exit code = number of failed checks)
powershell -ExecutionPolicy Bypass -File .\RHELPOPS-Validate.ps1

# Prove Tier 1 is scoped to standard users and no more
powershell -ExecutionPolicy Bypass -File .\RHELPOPS-Test-Scope.ps1 -TierAgentGroup RHELP-T1-Agents -ExpectedScopeGroup RHELP-Scope-Standard-Users

# Export KPIs
powershell -ExecutionPolicy Bypass -File .\RHELPOPS-Report.ps1 -Days 30 -CsvPath C:\Temp\rhelpops-kpis.csv

# Assign a role+scope to a tier (DRY RUN by default; add -WhatIf:$false to commit)
powershell -ExecutionPolicy Bypass -File .\RHELPOPS-Set-RoleScope.ps1 -RoleName 'RHELP Role – Tier 1 View' -AgentGroup RHELP-T1-Agents -ScopeGroup RHELP-Scope-Standard-Users -AssignmentName 'RHELP Assignment – Tier 1'
```

## G. When to escalate
If the role/scope model validates (`RHELPOPS-Validate.ps1` PASS), scope proves correct
(`RHELPOPS-Test-Scope.ps1` PASS), unattended is governed to Tier 3 only, and sessions still behave
unexpectedly (scope not honored, unattended behaving differently than documented), capture the
behavior and **verify the current Remote Help capability against Microsoft documentation**; if it
still conflicts, open a Microsoft Intune support case with the role/assignment details.
