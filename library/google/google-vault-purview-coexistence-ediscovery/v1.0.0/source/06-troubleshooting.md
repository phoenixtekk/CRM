# 6. Troubleshooting Guide — Vault ↔ Purview Coexistence: eDiscovery, Legal Hold & Retention

Use `GWVAULT-Discovery.ps1` / `GWVAULT-Validation.ps1` for the current Google-side state,
`GWVAULT-Report.ps1` for the both-sides coverage picture, and `GWVAULT-Remediation.ps1` (default
`-WhatIf`) to close a Vault-side coverage gap. Cross-check live state in **Vault → Matters** and the
**Purview portal → eDiscovery → Cases**.

> **Not legal advice.** This guide resolves *technical* faults (a hold not effective, a coverage gap,
> a search not returning). Whether the preserved scope is legally sufficient is a legal/records-counsel
> determination.

> **Verify in your tenant.** Vault's Gemini-app hold/retention support and the Purview eDiscovery
> experience evolve — confirm exact paths for your editions and defer volatile specifics to the
> vendors' documentation.

## A. A custodian is held on only one ecosystem (the coexistence gap)
| Symptom | Cause | Remediation |
|---|---|---|
| Custodian held in Vault but not Purview (or vice versa) | Parallel hold missed — holds do not sync | Run `GWVAULT-Report.ps1` to find the one-sided custodians; place the missing hold on the other platform (Vault matter hold, or Purview eDiscovery hold policy) under the matched matter name |
| Migrating custodian dropped out of hold mid-migration | Data moved from M365 to Workspace; only the old side was held | Re-run `GWVAULT-Discovery.ps1`; ensure the custodian is held on **both** sides for the migration overlap window |
| New group member not preserved | Purview group hold is a point-in-time snapshot at creation | Re-add the group as a data source (or add the member's mailbox/OneDrive) to refresh membership |

## B. Vault hold not preserving expected data
| Symptom | Cause | Remediation |
|---|---|---|
| A service's data not held | The hold doesn't include that service | Edit the hold in **Vault → Matters →** *(matter)* **→ Holds** to add the service (Gmail, Drive, Chat, Meet, Groups, Voice, Sites, Gemini app where available) |
| Data purged that should be kept | Retention rule modified/deleted without a hold covering it | Vault warns that changing retention can purge data; place a **hold** (takes precedence over retention) for anything under an active matter, and restore retention under change control |
| Gemini-app messages not held | Gemini-app hold/retention support is newer | Confirm the capability is available for your edition (**verify in your tenant**); add the Gemini app to the hold/retention where present |

## C. Purview hold not effective
- The hold can take **up to 24 hours** to take effect — check the hold policy's **Details** tab for
  each location's **hold status** before concluding it failed.
- **Licensing:** an eDiscovery hold requires an eligible license on **every held user**; frontline
  (F1/F3) users cannot be a hold target. Assign the required subscription/add-on, then reapply.
- **Teams/Groups scope:** holding a Team holds only the group mailbox + site — add members' mailboxes
  and OneDrive if their individual data is in scope.
- **Location changed:** if a SharePoint/OneDrive URL or a UPN changed, edit the hold's data sources and
  reapply so the scope stays accurate.

## D. Retention conflicts / purge risk
- **Purge out from under a hold:** align the two schedules to the **longer** period for shared classes,
  and rely on the **hold** (not retention) to preserve an active matter — Vault hold precedence and
  Purview most-restrictive-wins both keep held content.
- **Over-retention:** if content is kept longer than the approved schedule, confirm which preservation
  source is holding it (hold, retention policy/label, Litigation Hold, delay hold, Single Item
  Recovery on the Purview side) and release the correct one **only** with counsel sign-off.

## E. Discovery returns incomplete or mismatched results
| Symptom | Cause | Remediation |
|---|---|---|
| Item missing from a production | Searched only one platform | Run the matched search on **both** Vault and Purview and reconcile the two export sets |
| Duplicate items across productions | Coexistence overlap not de-duplicated | Reconcile Vault and Purview exports into a single de-duplicated production under counsel's direction |
| Encrypted/partially-indexed items missed by a query-based hold | Query conditions ineffective on such items | On Purview, limit query-based hold conditions to Date/Participants/Type; on both, prefer an infinite hold where completeness matters |

## F. Diagnostics quick reference
```powershell
# Read-only Google-side state and both-sides coverage
.\GWVAULT-Discovery.ps1
.\GWVAULT-Report.ps1

# Confirm the Vault hold/retention held for the pilot scope (Purview side flagged to confirm)
.\GWVAULT-Validation.ps1

# Preview closing a Vault-side coverage gap before applying
.\GWVAULT-Remediation.ps1 -WhatIf
```
Portal checks: **Vault → Matters** (holds) / **Vault → Retention**; **Purview portal → eDiscovery →
Cases → Hold policies** (Details tab for hold status) and **Data Lifecycle / Records management →
Retention policies**. *(Verify exact paths in your tenant.)*

## G. When to escalate
If holds are effective on **both** ecosystems, retention is aligned, and discovery still returns
incomplete or inconsistent results — capture the matter/case names, the custodian and workload, the
exact search, and the per-location hold status from each platform, and open a support case with
Google Workspace (Vault) and/or Microsoft (Purview) as appropriate. **Any question of legal
sufficiency (is the hold/scope defensible?) goes to legal/records counsel, not to support.** Volatile
Vault Gemini-app and Purview eDiscovery specifics are deferred to the vendors' documentation.
