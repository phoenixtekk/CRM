# Testing & Validation

Each procedure below has an explicit **expected pass/fail** signal. Run the Assess/Configure checks
before Pilot, and run the Pilot validation gates before scaling to any production wave. All measurement
is **read-only**.

---

## T1 — Read-only measurement access works (`adoption_config_check.py`)

**Procedure**
```
python scripts/adoption_config_check.py
```

**Pass:** the tool reports ADC is configured, the **Admin SDK Reports** and **Directory** APIs are
reachable, and it confirms **no write/OAuth write scopes** are in use (guardrail OK).
**Fail:** ADC not found, API not enabled, insufficient role, or a write scope detected. Resolve per
Troubleshooting T1 before proceeding — do **not** work around a missing role by granting broad admin.

> Reports API data can lag ~1–3 days and some counters depend on the tenant edition — **verify in your
> tenant**; a zero on day-0 is not necessarily a failure.

---

## T2 — Adoption baseline captured (`adoption_metrics_report.py`)

**Procedure**
```
python scripts/adoption_metrics_report.py --days 30 --out baseline_adoption.csv
```

**Pass:** `baseline_adoption.csv` contains per-app active-usage rows (Gmail, Drive, Docs, Meet, Chat,
and Gemini where reported) for the window. This is the `Adoption Metrics – Enterprise – v1` baseline.
**Fail:** empty output or an auth error → resolve access (T1) and retry.

---

## T3 — Champion coverage meets ratio (`champion_roster_planner.py`)

**Procedure**
```
python scripts/champion_roster_planner.py --roster nominations.csv \
    --waves waves.csv --ratio 75 --out champion_plan.csv
```

**Pass:** every wave in `champion_plan.csv` has champions ≥ (wave users ÷ ratio); no wave is flagged
`UNDER_RATIO`. Cohorts are named `Champion Cohort – <BU> – Wave N`.
**Fail:** one or more waves flagged `UNDER_RATIO` → recruit more champions for those BUs before the
wave proceeds (this is a Configure gate).

---

## T4 — Training completion gate met (`training_completion_tracker.py`)

**Procedure**
```
python scripts/training_completion_tracker.py --completions lms_export.csv \
    --roster wave0_roster.csv --wave "Wave 0" --required-rate 0.90 --out wave0_completion.csv
```

**Pass:** per-role completion ≥ the required rate (default 90%, org-tuned); the tool prints
`GATE: PASS` and lists any stragglers.
**Fail:** `GATE: FAIL` for a role → that role's cohort does **not** go live until completion is met
(chase stragglers, run a catch-up session). This is the go-live gate.

---

## T5 — Hypercare is staffed and themes are understood (`hypercare_theme_analyzer.py`)

**Procedure**
```
python scripts/hypercare_theme_analyzer.py --tickets wave0_tickets.csv \
    --expected-floorwalkers 20 --actual-floorwalkers 20 --out wave0_themes.csv
```

**Pass:** floorwalker coverage meets the `Hypercare Model – Wave 0 – Golive` plan (`STAFFING: OK`) and
the tool produces a ranked theme list so the top pain points are known and can be fed back into
comms/training.
**Fail:** `STAFFING: SHORT` (add floorwalkers/champions) or an unexplained spike in one theme
(indicates a comms/training gap to fix before the next wave).

---

## T6 — Adoption is trending up vs. baseline (`adoption_metrics_report.py`)

**Procedure** (after ~7–14 days post-cutover)
```
python scripts/adoption_metrics_report.py --days 14 --ou "Wave 0" \
    --baseline baseline_adoption.csv --target-rate 0.70 --out wave0_adoption.csv
```

**Pass:** per-app active-usage for the wave is **above baseline** and moving toward the target; the
tool prints `TREND: UP` per app meeting target.
**Fail:** flat or below baseline (`TREND: FLAT`/`DOWN`) → the cohort needs another push (reinforcement
comms, targeted training, more champion nudging) before the program treats the wave as done, and
**hold** the next wave if the pilot itself is failing.

---

## Pilot validation summary (the scale-out gate)

`Adoption Pilot – Wave 0 – Pilot` **passes** — and the program may advance to **Expand** — only when
**T4 (training gate)**, **T5 (hypercare staffed, themes understood)**, and **T6 (adoption trending
up)** all pass for Wave 0. Any failure triggers the documented **hold/rollback**: pause the next wave,
remediate, re-validate.
