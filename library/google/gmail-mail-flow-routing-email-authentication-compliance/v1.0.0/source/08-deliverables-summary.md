# Deliverables Summary

Everything included in this solution, on one page.

## Documentation

- **Solution Overview** — the Gmail mail plane: routing/hosts, split & dual delivery,
  SPF/DKIM/DMARC, content-compliance/routing rules, and the enforcement journey.
- **Requirements Guide** — the shared Google global requirements plus seven solution-specific
  prerequisites (verified domains + DNS, super-admin + Admin SDK access, documented current flow,
  RUA mailbox, legitimate-sender inventory, compliance policy, pilot cohort + rollback).
- **Implementation Guide** — Assess → Design → Configure → Pilot → Validate → Expand, pilot-first,
  every route/host/record/rule named `<Purpose> – <Scope> – <Stage>`, with pass/fail gates and a
  documented rollback for every high-impact change.
- **Testing & Validation** — eight procedures (T1–T8) each with an explicit pass and fail signal,
  culminating in Gate D.
- **Troubleshooting** — the common mail-plane failure modes and their resolutions.
- **Best Practices** — durable practices, especially moving DMARC to enforcement without breaking
  legitimate senders.
- **Executive Summary** — the outcome, approach, and why it is low-risk.

## The 5 Python tools (Admin SDK / APIs; read-only or dry-run by default; no keys in code)

1. **`mailplane_dns_audit.py`** — *Assessment / discovery (read-only).* Audits **MX, SPF, DKIM, and
   DMARC** DNS posture across all domains, counts SPF DNS lookups against the 10-lookup limit, and
   flags gaps. Produces the `Mailplane Baseline` artifact.

2. **`dmarc_rua_analyzer.py`** — *Validation / report generator (read-only).* Parses **DMARC
   aggregate (RUA) reports** (`.xml/.gz/.zip`), aggregates volume by sending source, and computes the
   **% of legitimate volume aligned** — the evidence gate for advancing DMARC.

3. **`mailplane_config_export.py`** — *Configuration / export helper (read-only).* Exports readable
   mail-plane config (domains/aliases) via the **Admin SDK** and validates that supplied routing/
   compliance artifact **names follow the convention** — the change-record and rollback reference.

4. **`mailauth_validate.py`** — *Policy / health check (read-only).* Validates a domain's **SPF/DKIM/
   DMARC** records for correctness and against the intended enforcement stage; produces a per-check
   PASS/FAIL report.

5. **`dmarc_policy_planner.py`** — *Scope / config helper (dry-run by default).* Computes the **next
   safe DMARC record** (`none → quarantine → reject`) given measured alignment and a `pct` ramp, and
   returns a **SAFE/HOLD** decision. It only prints the record — it never publishes DNS.

## Packaged output

- **`GWMAIL-Solution.pdf`** — the compiled solution document (all sections above).
- **`GWMAIL-Scripts.zip`** — the five Python tools.

All scripts are Python 3.10+, argparse-driven with `--help`, standard-library-first (optional
`dnspython`, `google-api-python-client`/`google-auth` where noted), read-only or `--dry-run` by
default, and contain **no hardcoded credentials or keys** (OAuth / ADC only).
