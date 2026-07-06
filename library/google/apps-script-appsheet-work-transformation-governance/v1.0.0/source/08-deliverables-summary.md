# Deliverables Summary

This solution delivers everything needed to establish and operate work-transformation governance for
Google Apps Script and AppSheet — the written guidance and the supporting scripts — so a competent
admin/architect can run it self-guided and pilot-first.

## Documentation

| Guide | What it gives you |
|-------|-------------------|
| **Solution Overview** | The automation governance model for Apps Script + AppSheet: where the risk is (data access/OAuth scopes, sharing, app access) and how admin guardrails, an approval/review pattern, and environment/sharing standards channel it. |
| **Requirements** | Prerequisites with Description / Why / Verify / Implement — admin access, AppSheet edition awareness (Core vs Enterprise Plus), data-governance baseline, high-risk OAuth-scope capability, a named review model, and a pilot OU/change control. |
| **Implementation** | Step-by-step: configure Apps Script app access/OAuth control and AppSheet security/governance policies and data region; define the tiered approval/review pattern and the Build/Pilot/Production environments and reuse baseline; pilot; validate; expand — with rollback. |
| **Testing** | Eight guardrail-conformance gates (app access posture, high-risk scopes, external sharing, external sources/webhooks, require sign-in, deploy control, owner/environment discipline, builders-can-still-ship) with explicit pass/fail and the expand gate. |
| **Troubleshooting** | Common failure modes and fixes — broken app access, over-tight guardrails blocking builders, scope/authorization errors, AppSheet policy vs Core-setting confusion, propagation delay, edition gating. |
| **Best Practices** | Safe citizen development — least scope, internal-only by default, require sign-in, owner of record, Build→Pilot→Prod, reuse the governed baseline, tiered review, and a one-page review checklist. |

## Scripts (5)

All scripts carry a standard header (Synopsis / Purpose / How to run / Expected results / Notes).
The three inventory/validation/report scripts are **read-only** where they read live systems; the two
change-capable scripts default to **`-WhatIf`** (preview only) and make no change until explicitly
run without it.

| Script | Role | Change-safe |
|--------|------|-------------|
| **GWAUTO-Discovery.ps1** | Inventory Apps Script projects and AppSheet apps — owners, OAuth scopes, connected sources, sharing exposure. | Read-only |
| **GWAUTO-Validation.ps1** | Check guardrail conformance against the Testing gates (app access posture, sharing, sources, sign-in, deploy control). | Read-only |
| **GWAUTO-Report.ps1** | Automation coverage and risk report — scope breadth, external sharing, data sensitivity, ownership gaps. | Read-only |
| **GWAUTO-Remediation.ps1** | Bring flagged items toward conformance (owner assignment, sharing/scope fixes). Defaults to `-WhatIf`. | `-WhatIf` default |
| **GWAUTO-Set-ScopeTargeting.ps1** | Set which OUs/groups/teams the guardrails and review model target. Defaults to `-WhatIf`. | `-WhatIf` default |

## Outcome

Run end-to-end, the deliverables convert an ungoverned Apps Script/AppSheet estate into an
inventoried, guardrailed, reviewed capability: builders ship fast within a governed baseline;
IT holds the standard; and the business gets workflow automation that is fast **and** safe — not
shadow IT.
