# Implementation

Follow these steps in order. They implement the house model **Assess → Design → Configure → Pilot →
Validate → Expand**, **pilot-first**. Every artifact is named with the convention
`<Purpose> – <Scope> – <Stage>` and that exact name is reused in Testing, Troubleshooting, and the
scripts. Production/org-wide actions (launching a wave, sending all-user comms, gating go-live) carry
an explicit pass/fail gate and a documented rollback/hold.

> The five Python tools referenced below live in `scripts/` and are read-only or `--dry-run` by
> default; pass `--apply` only where a tool supports a write and you have reviewed the dry-run output.

---

## Phase 1 — Assess

### 1.1 Confirm the wave schedule and baseline the population
1. Obtain the migration **wave schedule** (cohort → cutover date → user count → OUs/groups) — Req. 1.
2. Confirm each wave maps to real OUs/groups: **admin.google.com → Directory → Organizational units**
   and **Directory → Groups**.
3. Run the **adoption baseline assessment** to snapshot current Workspace usage and directory
   readiness **before** any program action, so improvement is measurable later:
   ```
   python scripts/adoption_metrics_report.py --days 30 --out baseline_adoption.csv
   ```
   This reads the Admin SDK Reports API (read-only) and writes a per-app active-usage baseline. Save
   it as the `Adoption Metrics – Enterprise – v1` baseline.

### 1.2 Assess audience, roles, and Gemini licensing
1. Segment the population into **roles** (e.g. Frontline, Knowledge Worker, Manager/Exec, IT/Admin) —
   these become `Learning Path – <Role> – v1`.
2. Confirm **which cohorts are Gemini-licensed** and which Gemini features are enabled (Req. 7);
   **verify in your tenant** — mark each cohort Gemini-eligible or not.
3. Record the assessment as the input to `Adoption Program – Enterprise – v1`.

**Gate A (Assess → Design):** wave schedule confirmed, baseline captured, roles + Gemini eligibility
recorded. If any is missing, do not proceed.

---

## Phase 2 — Design

### 2.1 Author the master OCM plan — `Adoption Program – Enterprise – v1`
1. Document, for the whole program: the sponsor and mandate (Req. 2), the awareness → training →
   reinforcement arc, the champion model, the hypercare model, and the metrics plan.
2. Define **adoption targets** per app (e.g. "≥ X% of a wave active in Gmail within 14 days of
   cutover") — org-tuned; these become the Validate gates.

### 2.2 Design the champion network — `Champion Network – Enterprise – v1`
1. Set the **champion ratio** (default ~1 per 50–100 users; tune per Req. 6) and the time allocation.
2. Plan the recruitment, training-ahead, content-equipping, and recognition model.

### 2.3 Design the comms plan — `Comms Plan – Enterprise – v1`
1. Build the awareness calendar **relative to each wave's cutover date** (e.g. T-21 announce, T-7
   "what changes", T-1 "go-live tomorrow", T+0 "you're live / get help", T+7 tips).
2. Map each message to a channel (Req. 3) and note that **pre-cutover** messages go to the **old
   (M365) mailbox** and **post-cutover** to the **new (Google) mailbox**.

### 2.4 Design role-based learning paths — `Learning Path – <Role> – v1`
1. For each role, define modules across **Gmail, Drive, Docs/Sheets/Slides, Meet, Chat/Spaces**, sized
   to what the role does (frontline = lean; knowledge worker = full; manager = delegation/Meet).
2. Add a **Gemini** module **only** to paths for Gemini-eligible cohorts, and only for **enabled**
   features (Help me write, side-panel, Gems where available) — **verify in your tenant**; label
   preview features as such.
3. Define the **completion gate**: which modules must be complete before that role's cohort go-live.

### 2.5 Design the hypercare model — `Hypercare Model – <Wave/Region> – Golive`
1. Size the support surface: floorwalker coverage (default ~1 floorwalker per 75–150 users on day 0,
   tapering over the hypercare window, tuned per site), a triage/ticket path, and champion escalation.
2. Define the hypercare **exit criteria** (e.g. ticket rate below threshold, adoption trending up).

**Gate B (Design → Configure):** `Adoption Program – Enterprise – v1` and its sub-plans authored and
sponsor-approved.

---

## Phase 3 — Configure

### 3.1 Build the champion roster and wave plan
1. Collect BU nominations into a roster CSV, then generate the wave-aligned cohorts and coverage check:
   ```
   python scripts/champion_roster_planner.py --roster nominations.csv \
       --waves waves.csv --ratio 75 --out champion_plan.csv
   ```
   This produces `Champion Cohort – <BU> – Wave N` assignments and flags any wave under the target
   ratio (dry-run/report only — it writes a plan file, changes nothing in the tenant).
2. Fill coverage gaps flagged by the tool before that wave proceeds.

### 3.2 Stand up the completion-tracking source
1. Configure the LMS/roster (Req. 4) with a course per `Learning Path – <Role> – v1`.
2. Confirm completion can be exported to CSV for the tracker.

### 3.3 Enable read-only measurement access
1. Create/confirm the least-privilege **Reports**-only admin role (Req. 5) and enable the **Admin SDK
   API** in the associated Google Cloud project.
2. Authenticate the tooling with **ADC** (`gcloud auth application-default login`, or a service
   account via domain-wide delegation) — **never** export or commit a key.
3. Smoke-test read access:
   ```
   python scripts/adoption_config_check.py
   ```
   This validates that ADC works, the Reports/Directory APIs are reachable, and **no write scopes** are
   present (guardrail check) — see Testing.

**Gate C (Configure → Pilot):** champion plan meets ratio, completion source live, read-only
measurement verified.

---

## Phase 4 — Pilot (`Adoption Pilot – Wave 0 – Pilot`)

Run the **entire OCM cycle** on a small, friendly cohort before any production wave.

1. **Awareness:** execute the `Comms Plan – Enterprise – v1` sequence against Wave 0 dates.
2. **Training:** deliver the relevant `Learning Path – <Role> – v1` to the pilot; track completion:
   ```
   python scripts/training_completion_tracker.py --completions lms_export.csv \
       --roster wave0_roster.csv --wave "Wave 0" --out wave0_completion.csv
   ```
   Confirm the completion **gate** is met (per role) before pilot cutover.
3. **Cutover:** the migration program cuts Wave 0 over (this program does not perform the migration).
4. **Hypercare:** staff `Hypercare Model – Wave 0 – Golive` (floorwalkers + champions). Capture tickets.
5. **Analyze themes:** find where users struggled so comms/training can be improved before scale-out:
   ```
   python scripts/hypercare_theme_analyzer.py --tickets wave0_tickets.csv \
       --out wave0_themes.csv
   ```
6. **Measure:** after ~7–14 days, compare pilot usage to the baseline:
   ```
   python scripts/adoption_metrics_report.py --days 14 --ou "Wave 0" \
       --baseline baseline_adoption.csv --out wave0_adoption.csv
   ```

---

## Phase 5 — Validate (pilot pass/fail gate)

Evaluate `Adoption Pilot – Wave 0 – Pilot` against the gates (see Testing for exact procedures):

- **Training delivered & gate met** — required modules complete for the pilot roles.
- **Hypercare staffed & coping** — coverage met; ticket rate falling toward exit criteria; top themes
  identified and mapped back into comms/training fixes.
- **Adoption trending up** — per-app active usage above baseline and moving toward targets.

**Rollback / hold:** if a gate fails, **do not scale**. Hold the next wave, extend hypercare, re-run
the weakest comms/training step for the pilot, apply the theme-analyzer fixes, and re-validate. The
program only advances to Expand when Wave 0 passes.

---

## Phase 6 — Expand (production waves)

For **each** production wave, repeat the Pilot cycle with the improvements folded in:

1. Regenerate the wave's `Champion Cohort – <BU> – Wave N` and confirm ratio
   (`champion_roster_planner.py`).
2. Run `Comms Plan – Enterprise – v1` on the wave's dates.
3. Deliver training; enforce the completion gate (`training_completion_tracker.py`).
4. Cut over (migration program) → staff `Hypercare Model – <Wave/Region> – Golive`.
5. Analyze themes (`hypercare_theme_analyzer.py`) and feed fixes forward to the next wave.
6. Measure adoption vs. baseline/targets (`adoption_metrics_report.py`); publish to
   `Adoption Metrics – Enterprise – v1`.
7. Apply the **per-wave rollback/hold**: any wave failing its gates pauses further waves until fixed.

Continue until all waves are live, adoption is at/above target, and hypercare has exited to
steady-state support (champions + normal service desk).
