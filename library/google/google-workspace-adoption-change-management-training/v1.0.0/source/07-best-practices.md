# Best Practices

Durable practices for running the adoption, change-management, and training program at enterprise
scale. These sustain adoption **after** the migration team has moved on.

## Program & change management

- **Lead with a real sponsor, not a logo.** The `Adoption Program – Enterprise – v1` mandate must be
  visibly carried by the executive sponsor at every wave — a leadership message at each go-live beats
  any amount of IT email. If the sponsor goes quiet, the program stalls; re-engage before scaling.
- **Align everything to the wave, not the calendar.** Time awareness, training, and hypercare
  **relative to each cohort's cutover date**, so no cohort trains three weeks early (and forgets) or
  the day after (too late).
- **Make it about the job, not the tool.** Frame change as "how you'll do *your* work" per role — not
  "we're moving to Google". Role-based `Learning Path – <Role> – v1` content should use the audience's
  real tasks.
- **Pilot honestly.** `Adoption Pilot – Wave 0 – Pilot` exists to *find problems*. Pick a friendly but
  representative cohort, and treat a failed gate as success (you caught it before 150k users).

## Champion network

- **Protect champion time.** A champion without allocated time (Req. 6) is a name on a slide. Confirm
  the time mandate per `Champion Cohort – <BU> – Wave N` before counting them toward coverage.
- **Train champions ahead of their cohort.** They must be fluent *before* their business unit cuts
  over so they can floor-walk credibly.
- **Recognize them.** Visible recognition (sponsor shout-outs, a badge, manager awareness) keeps the
  network alive across many waves; unrecognized champions quietly stop.
- **Close the loop with champions' field intelligence.** They see pain first — route their feedback
  into `Comms Plan – Enterprise – v1` and `Learning Path – <Role> – v1` updates each wave.

## Training

- **Just-in-time, bite-sized, multi-modal.** Short micro-learning + quick-reference guides + a few
  live sessions beat one long course. Record live sessions for shift workers and stragglers.
- **Gate go-live on completion, and mean it.** The 90%-per-role gate (T4) is a genuine hold — waiving
  it teaches the org the gate is optional.
- **Teach Gemini only where it's licensed and enabled.** Deliver the Gemini module **only** to
  Gemini-eligible cohorts and only for **turned-on** features; **verify in your tenant** and label
  preview features. Promising a feature a cohort can't use erodes trust in the whole program.

## Hypercare & support

- **Front-load floorwalkers on day 0, then taper.** The first 48–72 hours generate most tickets; staff
  `Hypercare Model – <Wave/Region> – Golive` heavy early and taper against real ticket-rate data, not
  a fixed date.
- **Define hypercare exit criteria up front** (ticket rate + adoption trend), so the transition to
  steady-state support (champions + normal service desk) is evidence-based, not arbitrary.
- **Mine ticket themes every wave** (`hypercare_theme_analyzer.py`) and *act on the top three* before
  the next wave — the same confusion should not recur wave after wave.

## Measurement & data hygiene

- **Measure read-only, always.** The program **never** writes user data to measure it; keep tooling on
  ADC with a **Reports-only** role and run `adoption_config_check.py` to prove no write scopes crept in.
- **No secrets in tooling.** Never export or commit service-account keys; use ADC / the environment.
  Treat any key file as an incident.
- **Baseline before you touch anything**, then always report **vs. baseline** — "up from where we
  started" is the honest adoption story and the ROI evidence the sponsor needs.
- **Respect the data lag and edition caveats.** Reports API can lag ~1–3 days and some counters depend
  on edition/features — **verify in your tenant** before declaring a trend; don't over-react to a
  single day.

## Sustaining adoption

- **Hand off, don't drop.** When hypercare exits, transfer the champion network and the
  `Adoption Metrics – Enterprise – v1` dashboard to a steady-state owner so usage keeps being watched.
- **Keep a reinforcement drumbeat.** Periodic tips, "new feature" comms (especially as Gemini features
  roll out), and refreshers stop the post-cutover usage dip from becoming permanent.
