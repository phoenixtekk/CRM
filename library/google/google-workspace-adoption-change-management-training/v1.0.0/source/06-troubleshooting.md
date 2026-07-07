# Troubleshooting

Common failure modes across the program and its tooling, with resolutions. Test IDs (T1–T6) refer to
Testing; artifact names use the `<Purpose> – <Scope> – <Stage>` convention.

---

## T1 — `adoption_config_check.py` reports FAIL

- **"no ADC" / no Application Default Credentials.** The account isn't authenticated. Run
  `gcloud auth application-default login` as an account holding the least-privilege **Reports-only**
  admin role, or configure a service account via domain-wide delegation. **Never** export or commit a
  service-account key to make this pass.
- **"Reports API not reachable / not enabled / insufficient role."** Enable the **Admin SDK API** in
  the associated Google Cloud project, and confirm the account has the **Reports** privilege
  (**admin.google.com → Account → Admin roles**). Wait a few minutes after enabling.
- **"WRITE scope(s) detected."** Something granted more than read-only. Re-authenticate ADC with only
  the read-only scopes; do not proceed with a write-capable credential — the program is read-only by
  design.
- **"missing libs."** `pip install google-api-python-client google-auth`.

## T2 — `adoption_metrics_report.py` returns empty / zeros

- **Data lag.** The Reports API can lag ~1–3 days; the tool already walks back from `today-2`. A very
  recent window may legitimately have no data — widen `--days` or wait a day. **Verify in your tenant.**
- **Edition/feature gating.** Some counters (and **Gemini** usage in particular) depend on the tenant
  edition and rollout — a `None`/blank for an app can mean "not reported for this edition", not "no
  usage". Confirm which metrics your edition exposes before treating a zero as a finding.
- **Auth error.** Resolve via T1 first, then retry.

## T3 — A wave is flagged `UNDER_RATIO` (`champion_roster_planner.py`)

- **Genuine shortfall.** Recruit more champions for the flagged `Champion Cohort – <BU> – Wave N`
  before that wave proceeds — this is a Configure gate (Req. 6). Do not lower the ratio just to pass.
- **Data mismatch.** Confirm `business_unit` and `wave` strings match **exactly** between
  `nominations.csv` and `waves.csv` (whitespace/casing differences split cohorts). Normalize the CSVs
  and re-run.
- **Nominal champions.** Champions without the agreed **time allocation** shouldn't count — validate
  the mandate before including them.

## T4 — Training gate fails (`training_completion_tracker.py` → `GATE: FAIL`)

- **Real stragglers.** The tool lists them — run a catch-up session / targeted reminders; the cohort
  (for that role) does **not** go live until the gate is met.
- **Status values not recognized.** The tracker counts statuses like *complete/completed/pass/done*.
  If your LMS exports a different label, map it to one of those in the export before running.
- **Email mismatch.** Completion is joined on `email` (case-insensitive). If the LMS uses aliases or
  display names, normalize to the primary Google address in both files.

## T5 — Hypercare overwhelmed or `STAFFING: SHORT`

- **`STAFFING: SHORT`.** Add floorwalkers or pull in `Champion Cohort – <BU> – Wave N` members to meet
  the `Hypercare Model – <Wave/Region> – Golive` plan; front-load day-0 coverage.
- **One theme dominates** (`hypercare_theme_analyzer.py`). A single large theme (e.g. "missing mail",
  "sign-in") signals a **comms or training gap** — fix that specific message/module and feed it forward
  to the next wave; don't just add support headcount to a preventable problem.
- **"Other" is the biggest bucket.** The keyword taxonomy in the analyzer needs tuning for your
  environment — add the recurring terms you see to the `THEMES` map and re-run.

## T6 — Adoption flat or below baseline (`TREND: FLAT`/`DOWN`)

- **Too soon.** Usage often dips right after cutover before recovering; measure at ~7–14 days, not
  day 1, and always **vs. the baseline** you captured in Assess.
- **Reinforcement gap.** A persistently flat cohort needs another push — reinforcement comms, a
  targeted refresher for the weak app, and champion nudging — before the wave is treated as done.
- **Wrong tool still in use.** If users keep using the old M365 tool, check whether coexistence/routing
  is inadvertently keeping the old path alive (that's a migration-side issue to escalate) and whether
  comms clearly told users to stop using the old tool.
- **Pilot failing.** If `Adoption Pilot – Wave 0 – Pilot` won't trend up after remediation, **hold**
  the next wave and revisit the OCM plan — do not scale a program that isn't working.

## Program-level issues

- **Sponsor gone quiet.** Champions and mandatory-training expectations lose authority. Re-secure the
  sponsor's per-wave leadership message before the next wave (Req. 2) — a program without visible
  sponsorship should not advance to Expand.
- **Comms not landing.** Confirm pre-cutover messages go to the **old (M365)** mailbox and post-cutover
  to the **new (Google)** mailbox, and that per-wave distribution groups resolve to the right cohort
  (Req. 3).
- **Gemini content promised but unavailable.** Only deliver the Gemini path to **licensed** cohorts and
  only for **enabled** features; if a feature isn't on for that OU, remove it from the path — **verify
  in your tenant** (Req. 7). Promising an unavailable feature erodes trust in the whole program.
