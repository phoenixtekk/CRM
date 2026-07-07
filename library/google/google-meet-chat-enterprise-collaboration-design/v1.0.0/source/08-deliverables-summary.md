# Deliverables Summary

Everything included in this solution, on one page.

## Documentation

- **Solution Overview** — the Meet + Chat collaboration model: meeting safety/host controls,
  recording/transcription and storage, external access, Chat spaces + governance, history/retention,
  and bot/app policy; the reference model, benefits, limitations, and deployment model.
- **Requirements Guide** — the solution-specific prerequisites (edition/Vault, OU + configuration
  groups, governed Recording Storage Shared Drive, retention/eDiscovery policy, external-collaboration
  decision, Chat app allowlist, least-privilege API access), each with how to *verify* and *implement*,
  layered on the shared Google global requirements.
- **Implementation Guide** — exact, ordered, pilot-first steps following **Assess → Design → Configure
  → Pilot → Validate → Expand**, with every artifact named and pass/fail gates + rollbacks per phase.
- **Testing & Validation** — nine procedures, each with an explicit pass/fail expectation, plus the
  automated validator/health run.
- **Troubleshooting** — common Meet/Chat governance failure modes (API-limits/throttling, permission/
  scope errors, external-policy and retention pitfalls, drift) and their resolutions.
- **Best Practices** — durable practices for scaling collaboration governance.
- **Executive Summary** — outcome, approach, and why the engagement is low-risk.

## The 5 Python tools (Google Workspace Admin SDK / Reports API)

All are **read-only or `--dry-run` by default**, use **least-privilege OAuth/ADC** credentials, and
contain **no hardcoded secrets or keys**.

1. **`meet_chat_settings_assessment.py`** — *Assessment / discovery (read-only).* Baselines the tenant:
   OU tree and configuration groups via the Admin SDK, plus a manual-check worksheet for the UI-only
   Meet/Chat safety, external, history, recording, and Vault settings. Produces `Meet+Chat Baseline –
   Enterprise – Assess`.
2. **`meet_chat_settings_config_helper.py`** — *Configuration / orchestration helper (dry-run default).*
   Turns a reviewed `design.json` into a named, ordered change plan; applies the API-supported changes
   (scoping-group membership) only with `--apply`, and emits an operator run-book for console-only
   controls (never faked). Used to configure the Pilot OU and expand wave by wave.
3. **`external_retention_policy_validator.py`** — *Validation / report generator (read-only).* Compares
   the external-access and Chat retention design against observed values and reports **drift** with a
   pass/fail per control; backs the `Chat External Policy – Allowlisted Domains – Enforce` and `Vault
   Retention – Chat 3yr – Enforce` gates.
4. **`meet_chat_usage_report.py`** — *Usage / adoption report (Reports API, read-only).* Summarizes
   Meet and Chat activity and external exposure over a look-back window into a CSV, to size adoption
   and prioritize the external-access design.
5. **`meet_chat_policy_health_check.py`** — *Policy / health / drift check (read-only).* Scores the
   governance posture against best-practice checks (external scoped, recording governed, history/
   retention present, app allowlist, not-inherited) and flags findings by severity; ideal on a schedule
   to catch drift between reviews.
