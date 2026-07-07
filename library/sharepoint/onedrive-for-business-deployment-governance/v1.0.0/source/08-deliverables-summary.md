# 8. Deliverables Summary — OneDrive for Business Deployment & Governance

Everything included in this solution, on one page.

## Documentation
| Document | What it gives you |
|---|---|
| **01 – Solution Overview** | The OneDrive model: silent client deployment, KFM, sync controls, storage/retention, sharing alignment, and offboarding — plus the reference design and the artifact naming convention. |
| **02 – Requirements** | The six OneDrive-specific prerequisites (managed-device policy channel, Entra join for silent sign-in, tenant ID + domain GUIDs, storage/retention decision, org sharing ceiling, offboarding model) — each with Verify / Implement — building on the SharePoint category global requirements. |
| **03 – Implementation** | Exact, ordered, pilot-first steps: Assess → Design → Configure (client, KFM, sync, storage/retention/sharing, offboarding) → Pilot → Validate → Expand, with pass/fail gates and a documented rollback. Every artifact named. |
| **05 – Testing & Validation** | Eight validation tests (silent sign-in, KFM, sync restriction, personal-sync block, quota/retention, sharing alignment, offboarding access, governance report), each with expected pass/fail, and the go/no-go gate. |
| **06 – Troubleshooting** | The common failure modes (silent sign-in not working, KFM blocked, sync not blocked/over-blocked, offboarding access, report empty) with root cause and resolution. |
| **07 – Best Practices** | Durable practices for client, sync, storage/retention/sharing, offboarding, and ongoing assurance. |
| **Executive Summary** | The outcome, approach, and why the rollout is low-risk — for approvers. |

## PowerShell scripts (5) — safe by default (read-only or `-WhatIf`)
| Script | What it does |
|---|---|
| **ODFBGOV-Discovery.ps1** | **Read-only.** Assesses the OneDrive posture: tenant default quota, orphaned-site retention, OneDrive sharing capability, conditional/limited access, sync-client restriction, provisioned OneDrive sites, and (optional) Graph usage — writes the `OneDrive Baseline – Tenant – Discovery` export. |
| **ODFBGOV-Configure.ps1** | **Dry-run by default (`-WhatIf` / no `-Commit`).** Tenant sync-control + storage/retention/sharing helper: sets default quota, orphaned retention, `OneDriveSharingCapability`, web-only access, and the domain-join sync allow-list — previews every change (current → proposed) before applying with `-Commit`. |
| **ODFBGOV-Set-OffboardingAccess.ps1** | **Dry-run by default.** Offboarding/data-retention helper: resolves a departing user's OneDrive, grants the manager site-collection admin for handoff, and reports the retention window — never deletes anything; legal/records hold deferred to compliance. |
| **ODFBGOV-Report.ps1** | **Read-only.** Governance report: per-OneDrive storage used vs quota (headroom %), last activity, sharing, and NearQuota/Stale flags, to CSV/HTML — the `OneDrive Governance – Tenant – Report`. |
| **ODFBGOV-Set-Scope.ps1** | **Read-only helper.** Resolves the tenant ID (KFM + tenant sync restriction) and AD domain GUID(s) (domain-join sync restriction), and emits a reviewed `.reg` reference template of the documented client policy value names. |

All scripts use modern-auth `Connect-*` (no stored credentials or secrets), default to read-only or
`-WhatIf`, and require `-Commit` to write. Cmdlet/parameter and portal detail follow Microsoft public
documentation; plan- and cloud-dependent behavior (storage maxima, Government cloud URLs) is flagged
**"verify in your tenant."**
