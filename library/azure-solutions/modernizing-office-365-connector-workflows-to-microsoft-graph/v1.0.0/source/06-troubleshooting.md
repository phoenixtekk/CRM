# 6. Troubleshooting Guide — Modernizing Office 365 Connector Workflows to Microsoft Graph

Use `O365GRAPH-Discovery.ps1` / `O365GRAPH-Classify.ps1` for inventory/classification state, `O365GRAPH-Validate.ps1` for PASS/FAIL per flow, `O365GRAPH-Report.ps1` for program progress, and `O365GRAPH-Set-AppRole.ps1` (`-WhatIf` first) for the app-role grant. Objects are referenced by their `<Purpose> – <Scope> – <Stage>` names. Volatile Microsoft specifics are flagged **verify against current documentation**.

## A. A flow was missed in the inventory
| Symptom | Cause | Remediation |
|---|---|---|
| A connector-based flow surfaces after migration "completed" | Discovery covered only the Logic Apps (Azure) side; the Power Automate side wasn't enumerated | Re-run `O365GRAPH-Discovery.ps1` **and** the Power Platform enumeration for every in-scope environment; merge both into `Connector-Flow-Inventory – Estate – Program.csv`. The Power Platform method is a **verify-against-docs** item — confirm it lists all environments |
| A Logic App uses O365 but wasn't flagged | The connector id wasn't in the match list, or the connection is referenced indirectly | Confirm the connector identifiers in `O365GRAPH-Discovery.ps1` against current Microsoft connector names (verify); inspect the workflow's connections blade directly |
| A subscription/resource group is absent | Reader wasn't granted at that scope | Grant Reader at the missing scope (requirement 2.1) and re-run discovery — inventory completeness (Testing Test 1) must pass before classifying |

## B. Parity break after cutover
| Symptom | Cause | Remediation |
|---|---|---|
| Migrated flow runs but produces a different result than the legacy flow | No captured parity baseline, or a Graph shape that doesn't match the old connector action 1:1 | **Roll back per flow** (re-enable the legacy flow, disable the migrated one — requirement 2.7), compare against the captured baseline, adjust the Graph logic per the assigned sibling pattern (#1/#2/#3), then re-cut-over and re-run Testing Test 2 |
| Event-driven flow misses events after cutover | Change-notification subscription not created/renewed correctly | Follow **sibling #2** for the change-notification handover and renewal; the max subscription lifetime + renewal cadence are **verify-against-docs** items |
| Polling flow drifts on schedule/dedupe | Polling cadence or state handling differs from the legacy flow | Follow **sibling #3** for the polling pattern; confirm the schedule matches the baseline |
| You can't roll back | The legacy flow was deleted, not disabled | Legacy flows must be **disabled, not deleted**, through the grace period (Best Practices). Rebuild from source/export if deleted; re-establish the rollback before the next cutover |

## C. Power Automate flow can't use a managed identity
- **This is expected for many Power Automate flows.** Power Automate typically authenticates through **connection references** tied to a user or service account and does **not** consume Azure managed identities the way Logic Apps do — **whether a given flow/connector can is a verify-against-current-documentation item.**
- **Route to the alternative** the classification tagged **Re-platform**: either (a) **re-platform** the flow into an **Azure Logic App** and apply the managed-identity Graph pattern (siblings #1/#2/#3/#5), or (b) re-point it at a **least-privilege service principal / connection** so it no longer runs on a user or shared service-account credential. Pick the option that fits the flow's owner and platform; confirm the current capability against Microsoft docs before committing.
- Do **not** record a Re-platform flow as "migrated" until it meets the same end-state test as a Logic App: no stored user/service-account credential (Testing Test 4).

## D. Permission / consent gaps
| Symptom | Cause | Remediation |
|---|---|---|
| `O365GRAPH-Set-AppRole.ps1` throws "app-role not found as Application permission" | Wrong or renamed Graph permission name | Confirm the current least-privilege application permission name against Microsoft documentation (verify) and pass it as `-GraphAppRole` |
| Migrated flow gets 403 from Graph | The app-role was never consented, or is scoped away | Confirm the app-role assignment exists (`O365GRAPH-Set-AppRole.ps1 -WhatIf` reports it); ensure a consent-capable role admin-consented it (requirement 2.3) |
| Flow can read a mailbox it shouldn't | The Graph mail permission is tenant-wide and not scoped | Apply the scoping construct **per sibling #4** (Application Access Policy or Graph RBAC-for-Exchange) to constrain the identity to only its mailbox(es); re-run Testing Test 5. Which mechanism to use is a **verify-against-docs** item |
| Can't create the managed identity or grant consent | Missing Contributor on the Logic App or a consent-capable role | Assign the minimum roles at the narrowest scope (requirement 2.3); separate "create identity" from "consent permission" where duties are split |

## E. Regression to connector-based auth
- **Symptom:** the governance scan (`O365GRAPH-Report.ps1` / `O365GRAPH-Validate.ps1`) shows a **new** connector-based flow, or a migrated flow that **reverted** to a stored-credential connection.
- **Cause:** new automation built the old way, or a migrated flow edited back to an Office 365 connection.
- **Remediation:** treat it as a wave-of-one — inventory it, classify it, migrate it with the per-flow playbook, and scope it per #4. Reinforce the standard that new M365 automation is built managed-identity-Graph-first (Implementation Phase 7). A rising migrated count that later falls is the signal governance caught a regression.

## F. Diagnostics quick reference
```powershell
# Re-baseline the Logic Apps side of the inventory
.\O365GRAPH-Discovery.ps1 -OutputCsv '.\Connector-Flow-Inventory - Estate - Program.csv'

# Re-score risk + migratability
.\O365GRAPH-Classify.ps1 -InputCsv '.\Connector-Flow-Inventory - Estate - Program.csv' `
                         -OutputCsv '.\Migration-Register - Estate - Program.csv'

# PASS/FAIL a migrated flow (managed identity + Graph, no stored credential)
.\O365GRAPH-Validate.ps1 -LogicAppName 'Contoso-MailNotify' -ResourceGroup 'rg-automation'

# Program dashboard / governance scan
.\O365GRAPH-Report.ps1 -Register '.\Migration-Register - Estate - Program.csv'

# Grant the app-role (dry run first, then -Apply); scope the mailbox reach per sibling #4
.\O365GRAPH-Set-AppRole.ps1 -ManagedIdentityObjectId '<mi sp object id>' -GraphAppRole 'Mail.Read'          # -WhatIf default
.\O365GRAPH-Set-AppRole.ps1 -ManagedIdentityObjectId '<mi sp object id>' -GraphAppRole 'Mail.Read' -Apply
```

## G. When to escalate
If the inventory is complete, the managed identity is assigned, the app-role is consented and scoped per #4, and a migrated flow still fails parity or Graph calls still 403 after the normal propagation window, collect `O365GRAPH-Validate.ps1` and `O365GRAPH-Report.ps1` output plus the flow's definition and open a Microsoft support case. For Power Automate managed-identity capability questions and national-cloud endpoint parity, confirm against current Microsoft documentation before escalating.
