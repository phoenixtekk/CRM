# Best Practices

Durable practices for keeping Microsoft 365 mail hygiene effective and low-false-positive over time.

## Baseline & policy management

- **Prefer preset security policies.** The **Standard** preset is the recommended baseline for most
  users; **Strict** for high-risk roles (execs, finance, IT admins). Presets are Microsoft-maintained
  and stay current — you inherit new protections automatically. Reach for custom policies only for a
  specific gap the preset cannot express.
- **Understand policy precedence.** For a given user, only the **highest-priority matching policy of
  each type** applies. Presets have their own ordering (Strict > Standard > custom > default). Keep
  custom policies minimal and their priority deliberate.
- **Never disable filtering to fix a false positive.** Every exception belongs in the **Tenant
  Allow/Block List**, scoped and time-bound. `SCL -1` transport rules and broad allow-list rules are
  the #1 cause of both missed threats and confusing behavior — retire them.

## Licensing discipline

- **Know your plan and re-verify it.** EOP-only vs Defender for Office 365 Plan 1/2 determines what
  you can configure. License changes (or bundle changes) alter available features. Confirm capability
  **in the tenant**, not from the SKU name — Defender for Office 365 feature availability also differs
  on **Government clouds (GCC / GCC High / DoD)**.

## Authentication foundation

- **Keep SPF, DKIM, and DMARC healthy on every sending domain.** Hygiene reasons over authenticated
  signals; weak authentication increases both false positives and missed spoofing. Move DMARC from
  `p=none` (monitor) toward `p=quarantine`/`p=reject` as data supports it.
- **Enable DKIM for all custom domains** (`Set-DkimSigningConfig -Enabled $true` after the CNAMEs
  exist), not just the onmicrosoft domain.

## Quarantine & allow/block governance

- **Review quarantine on a schedule** (the reporting script produces the review report). Unreviewed
  quarantine means real false positives are lost and real threats go unstudied.
- **Use notifications** so end-users can self-serve release requests for false positives — reduces
  help-desk load and mail loss.
- **Right-size release permissions:** admin-only release for high-confidence phishing/malware;
  request-release for spam/bulk.
- **Time-bound TABL allows.** Set expirations; a permanent allow is a standing risk. Review the
  allow list periodically and remove stale entries.

## Tuning to minimize false positives

- **Tune from data, incrementally.** Adjust the **BCL** (bulk) threshold or add a specific TABL
  allow based on observed misfiling — never a broad downgrade.
- **Keep impersonation-protection lists tight.** Protect a small set of genuinely high-value
  users/domains; over-broad impersonation lists generate false positives.
- **Use spoof intelligence insight** and the spoof-intelligence analysis report to allow legitimate
  spoofers (e.g. bulk senders sending on your behalf) deliberately, rather than loosening spoof
  protection.

## Third-party gateways

- If a third-party hygiene gateway sits in front of EOP, configure **Enhanced Filtering for
  Connectors (skip listing)** so EOP evaluates the true source IP, and avoid double-filtering
  conflicts. Defer the third-party console to the vendor's docs; integrate at the connector level.

## Change control & operations

- **Every hygiene change is high-impact to production mail** — stage on a pilot, validate against the
  gates, keep a rollback. Name every artifact `<Purpose> – <Scope> – <Stage>` and reuse the name.
- **Run the assessment script periodically** to detect configuration drift (new bypass rules,
  policies out of baseline, expired-but-still-present allows).
- **Schedule the reporting script** so quarantine review and false-positive/spoof analysis are
  routine, not reactive.
- **Automate read-only; gate writes.** All provided scripts are read-only or `-WhatIf` by default;
  changes require an explicit switch — keep that discipline in any further automation. No stored
  credentials; always modern-auth `Connect-ExchangeOnline` / `Connect-MgGraph`.
