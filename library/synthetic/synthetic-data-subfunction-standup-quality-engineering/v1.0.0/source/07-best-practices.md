# Best Practices

Durable practices for running the synthetic-data sub-function as a repeatable, measured service. These
outlast any single engine or program.

## Operating model

- **One front door.** Every request enters through `Intake Scheme – Sub-Function – v1` — no side
  channels. Side-channel work is invisible to the KPIs and corrodes prioritization. If the sponsor
  wants something expedited, expedite it *through* intake with a documented priority override.
- **Pods own outcomes, not tasks.** Keep the Validation & Governance pod's release decision
  independent from the Generation pod. The team that builds the dataset should not be the sole judge
  of whether it passes the gate.
- **Charter what you will *not* do.** The `Capability Charter` is as much about scope exclusions
  (production data platform, legal determinations, unbounded ad-hoc pulls) as inclusions. A shared
  service dies from unbounded scope.
- **Size before you commit.** Run `podcapacity.py` before accepting a wave of new demand; commit only
  to what utilization ≤ ceiling supports. Protect flow efficiency by capping WIP.

## Engineering

- **Engine-agnostic behind an interface.** Treat Synthea, commercial platforms, and AI/model
  frameworks as swappable engines behind the reference architecture's engine interface. Never scatter
  a vendor's console specifics through your pipeline; when a step is version-specific, cite the
  vendor's documentation and flag "verify against your version."
- **Everything is named and versioned.** Datasets, configs, and validation records use the
  `<Purpose> – <Scope> – <Stage>` convention and carry a version. `Synthetic EHR – Pilot – v1` and
  `Synthetic EHR – Pilot – v2` must be distinguishable and traceable to their validation records.
- **Configuration as data.** Keep the reference architecture, intake scheme, and KPI definitions as
  machine-readable config that the tools validate (`refarchvalidate.py`, `intakequeue.py`,
  `kpirollup.py`) — not as prose only. Re-validate on every change.
- **Reproducibility.** Record the engine, parameters, and seed for every dataset so a validation
  result can be reproduced.

## Validation & quality

- **No release without a validation record.** A dataset ships with `Validation Record – <Scope> – v<n>`
  or it does not ship. "Looks fine" is not evidence.
- **Fidelity claims require a reference.** If there is no governed reference or agreed published
  distribution, report distributional fidelity as **N/A**, not as a pass. Coverage and structure still
  gate.
- **Trend the quality KPIs, not just the point value.** A single validation pass rate says little;
  the trend of pass rate, defect escape, and rework is the signal that the sub-function is maturing.

## Privacy & safety (non-negotiable)

- **Never real PHI in a shared harness/twin/AI test environment.** This is architectural, not a
  policy sticker — the reference architecture's data-flow boundary enforces it, and `refarchvalidate.py`
  checks that the boundary is asserted.
- **Reference data is read-only and minimized.** When measuring fidelity against real statistics,
  access is read-only, minimized to the fields needed, and under the governing privacy controls.
- **Tools are safe by default.** Every script defaults to dry-run for anything that writes, never
  writes synthetic output to shared locations by default, and never emits real data values in reports.
- **The determination is not yours.** Privacy screens produce evidence and a technical pass/fail;
  HIPAA/HITRUST de-identification determinations, IRB/privacy sign-off, and disclosure-risk acceptance
  belong to privacy/compliance/legal. Escalate; do not self-clear a quasi-identifier risk.

## Maturity & scaling

- **Assess on a cadence.** Re-run `maturityassess.py` at each review; advance one level deliberately
  rather than declaring maturity you have not evidenced.
- **Expand by request type, then by program.** Prove a new request type end-to-end (through gates)
  before offering it broadly. Growth that outruns the gates produces escaped defects and privacy risk.
- **Keep the baseline honest.** The Assess-stage baseline is the yardstick; do not quietly redefine
  KPIs to look better. A downward trend in rework and defect escape is the credible story to the
  sponsor.
