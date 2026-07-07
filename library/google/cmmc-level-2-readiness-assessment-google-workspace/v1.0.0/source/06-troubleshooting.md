# Troubleshooting

Common failure modes during CMMC Level 2 readiness on Google Workspace, and how to resolve them. These
address the **technical readiness and evidence** work — they do **not** resolve assessment,
applicability, or legal questions, which stay with your assessor/compliance/legal team.

---

## Authentication & API access

**Symptom: `assess-nist-controls.py --check-auth` fails, or tools return 401/403.**
- Confirm the service account has **domain-wide delegation** and that the delegated scopes in the Admin
  console **exactly match** the `*.readonly` scopes the tool requests (a superset or mismatch is
  rejected).
- Confirm `--subject` is a **super-admin (or sufficiently privileged) user** to impersonate.
- Confirm the **Admin SDK (Directory + Reports)**, **Drive**, and **Groups Settings** APIs are enabled
  in the Cloud project.
- Never work around this by granting **write** scopes to the read-only tools — fix the read-only grant.

**Symptom: 403 "insufficient permission" only on the Reports/audit calls.**
- The `admin.reports.audit.readonly` scope must be delegated *and* the impersonated user must have
  privilege to read audit logs. Add the scope and re-consent.

## Throttling / rate limits

**Symptom: 429 / `rateLimitExceeded` / `userRateLimitExceeded` on large tenants.**
- The Admin SDK enforces per-project and per-user quotas. For large boundary OUs, run during off-peak,
  and page results (the tools already use `maxResults`); extend them with exponential backoff on 429 if
  you add deeper enumeration.
- Split very large evidence collections by application (`collect-evidence.py` already writes per-app
  files) or by time window (`--days`) to stay under quota.
- Request a quota increase for the Cloud project if sustained collection needs it.

## Evidence gaps

**Symptom: T9 fails — a `configured` control has no evidence in the package.**
- Re-run `collect-evidence.py --live`; confirm the audit source that carries that control is included in
  `AUDIT_SOURCES` and that the events actually occurred in the lookback window (perform the action, then
  re-collect).
- If a control is genuinely manual (AT/PS/PE/IR), its evidence is a **documented procedure/attestation**,
  not an API export — attach it to the package by hand and index it.

**Symptom: audit-log evidence is empty for an application.**
- Log availability and latency vary by application and edition; some events surface with delay. Widen
  the window and re-collect. If an application's logging is edition-gated, record it as a **POA&M** item
  ("verify-edition") rather than asserting the control.

## DLP behaves unexpectedly

**Symptom: DLP blocks legitimate work (false positives) in the pilot.**
- Keep the rule as **`DLP – CUI – Monitor`** while tuning; review the hits, refine the detector
  (thresholds, dictionaries, context), and only then promote to **`DLP – CUI – Enforce`**. **Do not**
  promote to enforce fleet-wide on a failing pilot (Gate 3).

**Symptom: DLP misses CUI-shaped content (false negatives).**
- Broaden/adjust the detector against sample CUI; validate with T5 before evidencing. Detector accuracy
  is a tuning exercise — budget pilot iterations for it.

## Boundary drift & scope errors

**Symptom: `cui-boundary-check.py` reports external or out-of-OU members.**
- High-severity **external-group-member** findings mean CUI groups admit external domains — remove them
  or, if intentional and approved, document the exception with your compliance owner (acceptability is
  *their* call).
- **member-outside-boundary-ou** means a CUI-group member's account lives outside the boundary OU, so it
  misses the boundary controls — move the account into `CUI – Boundary – Org`.
- Re-run after every joiner/mover/leaver; tie membership to the identity source to prevent recurrence.

**Symptom: Drive external-sharing exposure suspected but not fully enumerated.**
- The boundary checker flags Drive sharing as a follow-up: run a `Drive files.list` external-sharing scan
  against your **shared-drive inventory** (read-only) to enumerate per-file exposure. The tool does not
  fabricate a private API for this — extend it against the documented Drive API.

## Edition-gated features

**Symptom: Assured Controls / data-region / client-side encryption not present in the console.**
- These are **edition/contract/rollout dependent**. Confirm your edition and add-ons under **Billing →
  Subscriptions**; if unavailable, this is **not a hard test failure** — record a **POA&M** item
  (`verify-edition`) and pursue the edition/add-on or a documented compensating control. **Never assert
  a control is met on a feature you cannot confirm exists in your tenant.**

## SSP / POA&M generation

**Symptom: `generate-ssp-poam.py` errors "control map not found / empty".**
- Run `assess-nist-controls.py` first to produce the control-map CSV, then point `--control-map` at it.

**Symptom: POA&M shows zero open items but you know gaps exist.**
- The POA&M is generated from **status**. Zero open items means every row is marked `configured` — check
  for **over-stated** statuses in the control map. Honest `partial`/`verify-edition` statuses are safer
  than an optimistic `configured` that becomes an assessment finding.

## Rollback

**Symptom: an enforcing control blocked users after expansion.**
- Every high-impact control has a documented prior value in the control map. Restore it (set DLP to
  monitor/off, unassign the CAA level, revert the sharing policy, disable the export sink) — the change
  is scoped to the boundary OU/pilot group, so rollback never affects the wider tenant. Re-pilot before
  re-expanding.
