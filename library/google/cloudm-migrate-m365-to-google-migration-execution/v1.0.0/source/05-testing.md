# Testing & Validation

Each wave must pass these validations before it is closed. Run them at the pilot
(`Migration Wave – Pilot – Wave0`) first, then for every production wave. Where a test is scripted,
the tool is named. Record results in the wave's `Validation Report – <Scope> – <Stage>`.

> Item-count variance is measured against the **Scan baseline** captured before the pre-stage pass.
> Agree a tolerance up front (e.g. ≤0.5% per user, with any excluded item types — Recoverable Items,
> filtered date ranges — subtracted from the expected count so the comparison is apples-to-apples).

---

## T1. Connection authentication

- **Procedure:** In CloudM, test `Source Connection – M365 – Prod` and
  `Destination Connection – Google – Prod`.
- **Expected PASS:** both authenticate; source enumerates a sample mailbox; destination impersonates a
  sample destination user.
- **FAIL:** auth error or impersonation denied → see Troubleshooting (app-consent / DWD scope
  mismatch).

## T2. Scan baseline captured

- **Procedure:** Confirm the Scan pass completed for every user in the wave and totals were recorded.
- **Expected PASS:** per-user item counts and sizes recorded for mail, OneDrive, and SharePoint in
  scope; zero users failed to scan.
- **FAIL:** any user missing a scan total → resolve access for that user before pre-stage.

## T3. Item-count reconciliation (mail + files)

- **Procedure:** Run `validate-migration-report.py` to compare destination item counts (Gmail
  messages via Gmail API; Drive files via Drive API) against the Scan baseline, per user, after the
  final post-cutover delta.
- **Expected PASS:** per-user variance within the agreed tolerance for every user in the wave;
  variances explained by known exclusions.
- **FAIL:** any user over tolerance → triage in Troubleshooting (incomplete items / throttling
  truncation), re-run delta, re-validate.

## T4. Drive & Shared Drive permissions

- **Procedure:** With `validate-migration-report.py --check-permissions`, spot-check a sample of
  migrated Drive items and Shared Drives: sharing/membership matches the intended mapping.
- **Expected PASS:** sampled items have the expected members/roles; no unexpected public/"anyone"
  sharing was introduced.
- **FAIL:** permission drift or over-sharing → correct sharing, review the profile's permission
  handling (**verify CloudM permission-mapping behavior for your version**).

## T5. Mail flow after cutover

- **Procedure:** Send an inbound test (external → migrated user) and an outbound test (migrated user →
  external) after the MX cutover.
- **Expected PASS:** inbound lands in Gmail; outbound passes **SPF, DKIM, and DMARC** (check the
  received-message authentication results).
- **FAIL:** non-delivery or auth failure → check MX/DNS records and SPF/DKIM/DMARC alignment for the
  domain (high-impact — treat under change control).

## T6. Calendar & contacts fidelity

- **Procedure:** Spot-check a sample of migrated calendars and contacts against the source.
- **Expected PASS:** future meetings, recurrence, and key contacts present; known-reduced-fidelity
  items match CloudM's documented fidelity matrix.
- **FAIL:** missing future meetings → re-run with calendar in scope; document any vendor-known
  fidelity gaps.

## T7. Error triage completeness

- **Procedure:** Review the wave's per-user error report; run `check-migration-health.py` for the
  aggregate error/throttling picture.
- **Expected PASS:** every error is either resolved or explicitly accepted with a reason; no
  unexplained failures.
- **FAIL:** unexplained errors remain → do not close the wave; resolve or formally accept each.

## T8. User acceptance (pilot)

- **Procedure:** Pilot users confirm they can access mail, calendar, and files in Google and that
  recent items are present.
- **Expected PASS:** pilot users sign off; no blocking access issues.
- **FAIL:** blocking issue → invoke pilot rollback (revert MX, M365 authoritative), fix, re-run.

---

### Wave close gate

A wave is **closed** only when **T1–T7 PASS** (and **T8** for the pilot). Any FAIL routes to
Troubleshooting, a corrective delta re-run, and re-validation — or, for a cutover-level failure, the
documented rollback.
