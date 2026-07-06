# 6. Troubleshooting Guide — SharePoint Online & OneDrive → Google Drive / Shared Drives Migration

Use `GWDRIVE-Discovery.ps1` for the source content/permission inventory, `GWDRIVE-Validation.ps1` for
per-item files/permissions/sharing validation, `GWDRIVE-Report.ps1` for coverage/exceptions, and
`GWDRIVE-Remediation.ps1` (runs with `-WhatIf` by default) for safe fixes to identity-map / permission
gaps. Failures **inside the migration engine** (a specific file's transfer, a tool connector) are
diagnosed in the tool's own docs; this guide covers the **mapping, permission, sharing, structure, and
validation** issues this solution owns.

## A. A migrated file has no access / lost permissions
| Symptom | Cause | Remediation |
|---|---|---|
| File arrived but no one (or the wrong people) can open it | A source principal was **not in the identity map**, so its grant was dropped | Add the missing principal to `GWDRIVE Mapping - Identity - Source to Google`; re-apply with `GWDRIVE-Remediation.ps1` (`-WhatIf:$false`) and re-run `GWDRIVE-Validation.ps1` (Testing Test 4) |
| Whole scope has no grants | The identity map was incomplete for that scope's principals | Complete the map for the scope, remediate, re-validate — completeness is a gate ([CloudM — Drive permission changes](https://support.cloudm.io/hc/en-us/articles/25031144447644-Google-Drive-Permission-Changes-Microsoft-365-to-Google-Workspace)) |

## B. Permissions were flattened (everyone is a Viewer)
- A team that should still edit lands as view-only. The **permission translation table** is wrong or
  incomplete for that source level. Fix `GWDRIVE Mapping - Permissions - Level to Role` so the source
  level maps to the correct Google role (Contribute → Contributor, manage-content → Content manager,
  Full Control → Manager), re-apply, and re-run Testing Test 3.

## C. Team content ended up in a personal My Drive
- A SharePoint site/library was mapped to a My Drive and now has a single personal owner. Correct
  `GWDRIVE Mapping - Content & Structure - Source to Target` to target a **Shared Drive**, re-migrate
  that scope, and re-validate. Team content must never live in one person's My Drive.

## D. Sharing was widened or lost
| Symptom | Cause | Remediation |
|---|---|---|
| A file is now shared "anyone with the link" when it should not be | Anyone-link share translated without a policy check | Fix `GWDRIVE Mapping - Sharing - Link & Grant Rules` to down-scope anyone-links to domain/named and flag for owner review; re-apply and re-run Testing Test 5 |
| A previously-shared file is no longer shared | Organization-link or grant not translated | Confirm the sharing rule and identity map cover it; re-apply and re-validate |

## E. Folders appear greyed out to users
- Users report visible-but-unopenable folders. This is expected Google Drive behavior for content they
  could not see in SharePoint — **visibility changed, not access**. Brief users to expect it; where it
  causes confusion, place restricted content in separate top-level folders before migrating (Best
  Practices).

## F. A Shared Drive hit a limit
- A migration into one Shared Drive stalls or is rejected near **500,000 items**, **600 members**, or
  deep nesting. Split the source across multiple Shared Drives in
  `GWDRIVE Mapping - Content & Structure - Source to Target` (one per library / access boundary) and
  re-run ([Google — shared drive limits](https://support.google.com/a/answer/7338880)).

## G. File counts don't reconcile
- Target item count is lower than source. Some items are legitimate tool exclusions (system files,
  unsupported types); others are real misses. Run `GWDRIVE-Report.ps1` for the exception list, confirm
  the excluded types against the tool's docs, and re-migrate the genuine misses before passing the
  wave (Testing Test 2).

## H. The same problem recurs every wave
- A defect fixed only for one item/scope reappears. Fix the **mapping artifact** (content, permission,
  identity, or sharing) — not just the item — so later waves inherit the fix (Implementation Step 5).
  Recurring issues are almost always an un-fixed mapping, not bad luck.

## I. Graph scripts fail to connect
- `GWDRIVE-Discovery.ps1`, `GWDRIVE-Validation.ps1`, `GWDRIVE-Report.ps1`, and
  `GWDRIVE-Set-ScopeTargeting.ps1` use Microsoft Graph against the source Microsoft 365 / Entra
  tenant. If connection fails, confirm the Microsoft Graph PowerShell SDK is installed and the
  signed-in account holds the read scopes the script requests (`Sites.Read.All`, `Files.Read.All`,
  `User.Read.All`, `Group.Read.All`; `Group.ReadWrite.All` for scope targeting) — consent on first
  run, then re-run.

## J. Diagnostics quick reference
```powershell
.\GWDRIVE-Discovery.ps1                                        # source content/permission/sharing inventory
.\GWDRIVE-Set-ScopeTargeting.ps1 -GroupName "..." -ScopeCsv .\wave.csv   # -WhatIf by default
.\GWDRIVE-Validation.ps1 -ScopeCsv .\wave.csv                  # per-item files/permissions/sharing
.\GWDRIVE-Report.ps1 -ScopeCsv .\wave.csv                      # coverage + exception list
.\GWDRIVE-Remediation.ps1 -IdentityMapCsv .\identity-map.csv   # -WhatIf by default; add -WhatIf:$false to act
```

## K. When to escalate
If the identity map is complete, the permission/sharing translations are correct, the tool reports the
move finished, and `GWDRIVE-Validation.ps1` still reports gaps after remediation, capture the
`GWDRIVE-Validation.ps1` and `GWDRIVE-Report.ps1` output and review the affected scope with the content
owners, the identity/provisioning owner, and the migration-tool vendor before passing the wave.
