# 8. Deliverables Summary

Everything included in this solution, on one page.

## Documentation
| Document | What it gives you |
|---|---|
| **1. Solution Overview** | What meeting/webinar policy configuration is here, how it works, the reference model/artifacts, benefits, limitations, and the explicit boundary vs Teams Phone, Purview label definition, and other Teams solutions. |
| **2. Requirements** | Solution-specific prerequisites (Teams Premium gate for templates/sensitivity, least-privilege roles, cohort groups, agreed baseline, recording storage, compliance-defined labels, Commercial-vs-Gov) with verify/implement steps — on top of the shared Teams requirements. |
| **3. Implementation** | Exact ordered steps: assess → design the policy set → org settings → build meeting policies → webinars/town halls → templates + sensitivity (Premium) → pilot assign by group → validate → expand in waves, with pass/fail gates and a rollback. Every artifact named. |
| **5. Testing & Validation** | Eleven tests (policies exist, org anonymous stance, assignments/ranks, effective policy, lobby, recording/transcription, presenter role, webinars/town halls, template+sensitivity, recording storage, no blast radius), each with pass/fail. |
| **6. Troubleshooting** | Common failure modes (policy not taking effect, wrong effective policy, anonymous still joining, template not showing, recording missing, webinar blocked) with root cause and fix. |
| **7. Best Practices** | Durable practices for policy design, security defaults, recording/storage, webinars, Teams Premium, and assignment/change discipline. |
| **Executive Summary** | Crisp outcome/approach/why-low-risk summary for decision-makers. |

## PowerShell scripts (5) — MicrosoftTeams module / Microsoft Graph
All are **safe by default** (read-only or `-WhatIf`/report unless an explicit `-Commit`), use modern-auth
`Connect-MicrosoftTeams` / `Connect-MgGraph` (no stored credentials), and reuse the artifact names from
the reference model.

| Script | What it does | Safe default |
|---|---|---|
| **TEAMSMTG-Discovery.ps1** | Read-only assessment: every meeting policy, the events policy, org meeting configuration, recording/storage-relevant settings, and existing group assignments. Emits `Meeting Posture – Teams – Discovery`. | Read-only |
| **TEAMSMTG-Set-MeetingPolicy.ps1** | Idempotently creates/updates the meeting policies (`Standard`/`Exec`/`Restricted` + pilot, optionally Global) with lobby, anonymous, recording, transcription, presenter-role, and recording-expiration settings. | Preview unless `-Commit`; `-WhatIf` |
| **TEAMSMTG-Set-EventsAndTemplates.ps1** | Idempotently creates/updates the events policy (`Events Policy – Standard/Restricted – Prod`) for webinars + town halls, and reports the Teams Premium template/sensitivity readiness (flags what must be done in the admin center + Purview). | Preview unless `-Commit`; `-WhatIf` |
| **TEAMSMTG-Validation.ps1** | Read-only pass/fail validation of policy existence, org anonymous stance, assignments/ranks, and per-user effective policy for a sample group; emits `Meeting Validation – Teams – Report`. | Read-only |
| **TEAMSMTG-AssignmentReport.ps1** | Scope/health helper: reports group policy assignments and the effective policy per sampled user; with `-AssignGroup … -Commit`, applies a ranked `New-CsGroupPolicyAssignment` (previews with `-WhatIf`). | Report unless `-Commit`; `-WhatIf` |

> **Licensing note:** meeting **templates**, **sensitivity labels on meetings**, **watermark**, and
> **prevent-copy** are **Teams Premium** — verify entitlement in your tenant/plan before relying on
> them. **Sensitivity-label meaning and retention are a Microsoft Purview / compliance determination**,
> not an implementer decision — the template only attaches an existing published label.
