# Deliverables Summary

Everything included in this solution, on one page.

## Documentation

| Document | What it covers |
|---|---|
| **Solution Overview** | The CloudM Migrate model (platform, connections, profiles, scan/pre-stage/delta), where it fits vs native + other tools, the wave approach, and the deployment model. |
| **Requirements Guide** | Solution-specific prerequisites R1–R7 (CloudM platform, M365 source app registration, Google service account + DWD, destination users/Shared Drives, user-list mapping, profile design, cutover/rollback) on top of the shared Google global requirements. |
| **Implementation Guide** | Exact ordered steps: Assess → Design → Configure → Pilot → Validate → Expand, with named artifacts, pass/fail gates, and rollback. CloudM console internals deferred to CloudM docs. |
| **Testing & Validation** | T1–T8 validation procedures with expected pass/fail, including item-count reconciliation, permissions, and mail-flow checks. |
| **Troubleshooting** | Common failure modes — throttling/API limits, app-consent/DWD permission errors, incomplete/delta items, mail-flow issues — with resolutions. |
| **Best Practices** | Durable practices for reliable sequencing, throttling, validation, change control, and credential hygiene. |
| **Executive Summary** | Crisp outcome/approach/why-low-risk summary for decision-makers. |

## Python tools (5)

All tools are **safe-by-default** (read-only or `--dry-run` unless `--apply`), use **OAuth / ADC**
(no hardcoded credentials or keys), and target the **Google Workspace Admin SDK / APIs** (and read
the Microsoft side only where noted). Requires Python 3.10+; where Google client libraries are used:
`pip install google-api-python-client google-auth`.

| Script | What it does |
|---|---|
| **`assess-migration-readiness.py`** | Read-only discovery/assessment. Sizes the migration from the Google destination directory (user/license coverage) and a source inventory export (mailbox/OneDrive/SharePoint sizes), and flags gaps. Produces the assessment baseline. |
| **`build-migration-userlist.py`** | Builds the source→destination **user-list CSV** that CloudM consumes: reconciles a source user export against the Google directory, maps file sources to Shared Drives. Dry-run by default; `--apply` writes the CSV. Headers align to CloudM's import template (verify for your version). |
| **`plan-migration-waves.py`** | **Wave planner + throttling guidance.** Groups users into sequenced waves (pilot first), orders pre-stage/delta passes, and computes concurrency guidance to stay under Microsoft Graph / Google API throttling ceilings. Read-only planning output. |
| **`validate-migration-report.py`** | **Post-migration validation report generator.** Compares destination Gmail/Drive item counts against the scan baseline per user, spot-checks Drive/Shared-Drive permissions (`--check-permissions`), and reports pass/fail per the agreed tolerance. Read-only. |
| **`check-migration-health.py`** | **Policy/health/throttling check.** Between passes, watches destination account/license health and surfaces throttling/error signals so drift is caught before it compounds across waves. Read-only. |

## Packaging

- `CLOUDM-Solution.pdf` — compiled solution document (all sections above).
- `CLOUDM-Scripts.zip` — the five Python tools.
