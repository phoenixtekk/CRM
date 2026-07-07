# Troubleshooting

Common failure modes when executing an M365→Google migration with CloudM Migrate, and how to
resolve them. Named artifacts (`Source Connection – M365 – Prod`, `Destination Connection – Google –
Prod`, `Migration Profile – Mail+Drive – Standard`, `Migration Wave – <Scope> – <Stage>`) refer back
to Implementation and Testing.

> **CloudM console specifics are deferred to CloudM's documentation.** Where a fix lives inside the
> CloudM console, the *symptom and direction* are given here; exact clicks and version behavior are
> CloudM's to document — **verify for your version.**

---

## Connections & authentication

### `Destination Connection – Google – Prod` fails to authenticate / impersonate
- **Symptom:** Connection test fails, or per-user writes fail with `unauthorized_client` /
  impersonation denied.
- **Cause:** Domain-wide delegation (DWD) scope mismatch or missing API enablement.
- **Fix:** In **admin.google.com → Security → Access and data control → API controls → Domain-wide
  delegation**, confirm the service account **Client ID** is present and its scope list **exactly**
  matches CloudM's Google connector requirements (a single missing scope fails impersonation). Confirm
  the Cloud project has Gmail, Drive, Admin SDK, Calendar, and People APIs **enabled**. Re-test.
  `validate-migration-report.py` uses the same DWD path — if it errors on `with_subject`, the grant is
  the likely culprit.

### `Source Connection – M365 – Prod` fails
- **Symptom:** Source test fails to authenticate or cannot enumerate mailboxes.
- **Cause:** Entra app registration missing admin consent, missing permissions, or an expired
  secret/certificate.
- **Fix:** In **Entra admin center → App registrations →** your app **→ API permissions**, confirm the
  permissions CloudM's M365 connector requires are present and show **admin consent granted** (green
  check). Confirm the client secret/certificate has not expired; rotate if needed and update the
  CloudM connection (never store the secret in the repo).

## Throttling & API limits

### Throughput collapses / many 429 / backoff during pre-stage or delta
- **Symptom:** Passes slow dramatically; run log shows HTTP 429, "rate limit", "too many requests".
- **Cause:** Microsoft Graph/Exchange or Gmail/Drive provider throttling — expected under high
  concurrency.
- **Fix:** **Lower concurrency**, don't retry blindly. Start from the ceiling
  `plan-migration-waves.py` recommends and **halve it** on repeated throttling. Keep total simultaneous
  user migrations across **all** running waves under the ceiling. Shift pre-stage to off-hours. Run
  `check-migration-health.py --run-log <export>` to quantify throttling signals before re-running.

### One user or mailbox is disproportionately slow
- **Symptom:** A single very large mailbox/OneDrive stalls a wave.
- **Cause:** Per-mailbox provider limits and item volume.
- **Fix:** Pre-stage large mailboxes **early and separately** (flagged by
  `assess-migration-readiness.py --large-mailbox-gb`); consider date-range filtering in the profile for
  the deepest archives (record the exclusion so validation tolerance accounts for it).

## Item counts & delta issues

### Item-count variance over tolerance in `Validation Report – <Scope> – <Stage>`
- **Symptom:** `validate-migration-report.py` reports a user FAIL — destination counts below the scan
  baseline beyond tolerance.
- **Cause:** Incomplete items (throttling truncation, transient errors), or a legitimate exclusion not
  subtracted from the expected count.
- **Fix:** First confirm the gap isn't an **agreed exclusion** (Recoverable Items, filtered date
  range) — subtract those from expected. If it's real, **re-run a Delta** for that user, then
  re-validate. Persistent per-item failures: review the run-log error rows and CloudM's
  documented handling for those item types (**verify for your version**).

### Items delivered after cutover are missing
- **Symptom:** Mail that arrived in M365 during the MX switch isn't in Google.
- **Cause:** No post-cutover delta was run.
- **Fix:** Always run a **post-cutover `Delta Run – <Scope> – <Stage>`** to sweep items delivered to
  M365 during the switch. Make it a required step in the cutover runbook.

## Permissions & sharing

### Over-sharing / unexpected "anyone" links flagged
- **Symptom:** `validate-migration-report.py --check-permissions` reports `over-shared` items.
- **Cause:** Source sharing translated to broad Google sharing, or profile permission-mapping settings.
- **Fix:** Correct the sharing on the affected items; review the profile's permission-handling options
  and re-run a permission spot-check (**verify CloudM permission-mapping behavior for your version**).

### Shared Drive content lands in the wrong place or with wrong members
- **Symptom:** SharePoint/team content in an unexpected Shared Drive or with wrong membership.
- **Cause:** Incorrect file source→Shared Drive mapping in the user list.
- **Fix:** Fix the mapping (regenerate with `build-migration-userlist.py`, review, re-import),
  re-migrate the affected content, re-validate T4.

## Mail flow after cutover

### Mail not delivering to Gmail, or outbound failing SPF/DKIM/DMARC
- **Symptom:** T5 fails — inbound not arriving or outbound authentication failing.
- **Cause:** MX/DNS not fully switched, or SPF/DKIM/DMARC misaligned for Google.
- **Fix:** Verify the domain's **MX** points to Google and that **SPF**, **DKIM** (Google-published
  key), and **DMARC** are aligned. Treat DNS changes under change control. If a wave's mail flow can't
  be made healthy, invoke the documented **rollback** (revert MX, keep M365 authoritative) and
  re-cut in the next window.

## Destination accounts

### Users missing or suspended at migration time
- **Symptom:** `check-migration-health.py` reports MISSING or INACTIVE destination accounts; per-user
  writes fail.
- **Cause:** Provisioning (GCDS/SCIM) lag, unlicensed, or suspended accounts.
- **Fix:** Provision/license/unsuspend the affected accounts from the identity source of truth before
  re-running the wave's delta. Re-run the health check to confirm HEALTHY before proceeding.
