# Deliverables Summary

Everything included in this solution, on one page.

## Documentation

- **Solution Overview** — the retirement model (completeness verification, data disposition vs
  retention/legal-hold, licensing wind-down, identity/app cleanup, DNS/integration cutover, formal
  closure), reference design, benefits, limitations, and the pilot-first deployment model.
- **Requirements Guide** — the solution-specific prerequisites (migration sign-off, least-privilege
  Graph read app, secret handling, retention/legal-hold inputs, evidence store, admin roles, DNS
  control, pilot scope), each with how to verify and how to implement if missing — building on the
  Google category's shared global requirements.
- **Implementation Guide** — the six phases with named artifacts, exact ordered steps, pass/fail gates,
  and rollback windows: Assess → Completeness → Disposition → Licensing → Identity → DNS → Closure.
- **Testing & Validation** — a validation procedure per gate, each with explicit PASS/FAIL signals,
  plus an end-to-end pilot acceptance test.
- **Troubleshooting** — common failure modes (auth, throttling, false completeness gaps, DNS/mail-flow
  breakage, closure blockers) and their resolutions.
- **Best Practices** — durable practices for a clean, auditable, safe-by-default exit.
- **Executive Summary** — the outcome, approach, and why it is safe and governed, for sponsors.

## The 5 Python tools

All are **Python** using **Microsoft Graph** via `msal` (auth) + `requests` (calls); **read-only or
`--dry-run` by default**, `--apply` required for any change; **no hardcoded credentials** (they read
`M365DECOM_TENANT_ID` / `M365DECOM_CLIENT_ID` / `M365DECOM_CLIENT_SECRET` from the environment).

1. **`verify_migration_completeness.py`** — *assessment / discovery (read-only).* Reconciles each
   in-scope user's mailbox item counts, last-activity, OneDrive usage, and group/shared-mailbox
   coverage against the migration baseline via Graph usage reports and directory reads, flagging
   residuals and post-cutover Microsoft-side activity. Feeds **Gate 1**.

2. **`license_winddown_helper.py`** — *configuration / provisioning helper (dry-run default).* Models
   assigned SKUs per user, computes reclaimable vs retained seats and the projected monthly saving,
   and — only with `--apply` — removes license assignments (never cancels subscriptions) for a named
   scope. Feeds **Gate 3**.

3. **`inventory_app_and_orphans.py`** — *policy / guardrail + inventory.* Enumerates Entra app
   registrations, enterprise apps (service principals), long-lived/expired credentials, and
   stale/guest/orphaned accounts; classifies them; and — with `--apply` — disables (default) or removes
   named objects. Also runs in `--mode data` to inventory data-bearing objects for disposition. Feeds
   **Gates 2 and 4**.

4. **`map_dns_integration.py`** — *scope / config mapper (read-only).* For each domain, resolves and
   classifies MX, SPF, DKIM, DMARC, autodiscover, `enterpriseregistration`/`enterpriseenrollment`,
   Teams SRV, and Microsoft verification records as RE-POINT-TO-GOOGLE / REMOVE / KEEP, and lists Entra
   verified domains and app reply URLs as integration signals. Plans the Phase 5 cutover. Feeds
   **Gate 5**.

5. **`decommission_report.py`** — *validation / report generator.* Runs the pre-closure guardrail
   `--precheck` (all prior gates evidenced, no routing domain, no assigned license on non-retained
   accounts, no residual apps, zero unresolved holds) and generates the final **HTML closure evidence
   pack** consolidating every gate's result and the subscription-cancellation dates. Feeds **Gate 6**.
