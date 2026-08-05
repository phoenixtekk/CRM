# 7. Best Practices — Application Management Current-State Assessment & Modernization Roadmap

- **Score from evidence, never from opinion.** Every level in the `APPASMT – Scoring Sheet` must cite
  the artifact, interview note, or script output that justifies it. A maturity number nobody can trace
  to evidence is a survey dressed as an assessment — and the first hostile question in the readout will
  expose it.

- **"Insufficient Evidence" is a valid, honest result — use it.** A dimension you could not read or
  whose artifact was never produced scores "Insufficient Evidence," not a guessed L1. Guessing a low
  score to avoid a blank is the fastest way to lose the room; the real finding is "we could not evidence
  this — grant access / produce the standard."

- **Keep it read-only, and say so up front.** The five scripts use only `.Read.All` scopes and the
  Intune **Read Only Operator** role. Lead the engagement with that promise: it removes the change-window
  objection, shortens time-to-start by weeks, and means the customer will let you run it again.

- **Reconcile interviews against the tenant — the gap is the gold.** People describe the process they
  intend; the tenant shows the process they run. When "we always pilot in rings" meets an All-Devices
  assignment, that contradiction is often the single most valuable finding in the assessment. Record it,
  don't smooth it over.

- **Set target levels before you score.** Not every organization needs L5 everywhere. Agree each
  dimension's target in the `APPASMT – Assessment Charter` first — a score without a target has no gap,
  and a gap is what the roadmap is made of.

- **Size effort in bands, not false-precision quotes.** Use S/M/L/XL with a day range. An assessment
  that hands over day-exact estimates it cannot stand behind loses more credibility than one that
  honestly says "L: 10–15 days, refine against your rates and constraints."

- **Rate risk on consequence, not on how annoying it is.** Use the `APPASMT – Risk Matrix`
  (likelihood × business impact). Three live versions of a browser is Critical because it is unpatched
  RCE exposure, not merely untidy. Frame every finding in the language of consequence the sponsor cares
  about.

- **Sequence for momentum: quick wins fund the foundations.** Wave 1 exists to build credibility and
  cut risk fast (remove orphaned assignments, retire dead apps, turn on the install report). Delivering
  visible wins in the first 30 days is what earns the mandate for the harder Wave 2 and Wave 3 work.

- **Respect the boundary — assess and sequence, do not re-teach the build.** Where a finding points at
  governance, packaging standards, retirement, uninstall remediation, or monitoring tooling, state the
  direction and the effort and stop. The detailed build is a separate workstream. An assessment that
  drifts into implementation becomes a document nobody finishes reading.

- **Draw the dependencies explicitly.** A strategic item that depends on a foundational one cannot start
  early — say so with an arrow on the `APPASMT – Roadmap One-Pager`. A roadmap without dependencies is a
  wish list; the arrows are what make it executable.

- **Write the executive summary for the one person who reads only it.** Overall band, the three
  highest-risk findings, the key dependency, next-week quick wins, and the headline effort — on one
  page. If the sponsor can make the funding decision from that page alone, the assessment did its job.

- **Retain everything, named, for the re-run.** Keep the Evidence Pack, Scoring Sheet, Findings
  Register, and Roadmap named exactly as this solution names them. The trend across a second run in
  6–12 months is the proof the investment worked — but only if the first run was captured in a
  comparable form.
