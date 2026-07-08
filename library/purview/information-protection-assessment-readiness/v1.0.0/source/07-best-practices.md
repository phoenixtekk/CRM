# 7. Best Practices — Information Protection Assessment & Readiness (Microsoft Purview)

Field-proven recommendations for a credible, defensible posture assessment that leads to a roadmap people
actually execute.

## Assessing posture
- **Measure before you build.** Resist the urge to "just create a few more labels." The value here is the
  **baseline** — what protects the estate today — and you can only improve what you have measured.
- **Read-only until the one pilot.** Steps 1–5 change nothing; keep it that way. Run every discovery,
  scoring, and reporting script with **reader** roles, and grant **Information Protection Admin** only for
  the single simulation pilot, then remove it.
- **Distinguish "gap" from "unlicensed."** An E5-only capability that is dark on an E3 tenant is **not a
  configuration gap** — it is a licensing decision. Record it as **not available — verify your
  licensing/tenant** and put licensing in the roadmap only if the capability is actually required.
- **Coverage is the hidden gap.** Created-but-unpublished labels and DLP policies stuck in **Test** are
  the most common findings — the controls exist but protect nothing. Weight them accordingly.

## Scoring and the roadmap
- **Agree the baseline first.** A gap is the distance from **current** to **target**; if the target isn't
  agreed with compliance/security stakeholders, the scorecard is just opinion. Tune the default baseline
  before you score.
- **Rank by value ÷ effort, not by severity alone.** A "publish the label you already built" quick win
  often beats a high-severity item that needs a quarter of work. The roadmap's job is **sequence**.
- **Attribute every determination.** Whether a gap *must* be closed for a regulation is a
  compliance/records/legal call. Put the owner function on every gap row; provide the technical method and
  evidence, **not** the determination.
- **Make the scorecard repeatable.** Keep the discovery + validation scripts so the same measurement can
  be re-run after each follow-on fix — a rising score per dimension is the proof the program is working.

## Piloting safely
- **Always pilot in simulation/test, never enforce.** Auto-labeling **simulation**
  (`TestWithoutNotifications`) labels nothing; DLP **test** blocks nothing; label pilots publish to the
  **pilot group only**. This engagement proves the **fix path**, it does not deploy it.
- **Preview with `-WhatIf` before `-Commit`.** The Pilot Remediation script defaults to `-WhatIf`; look
  at exactly what it would create before you create it.
- **Roll the pilot back cleanly.** A simulation policy labeled nothing, so removing it reverts nothing —
  delete it after validating, unless the follow-on engagement is starting immediately.
- **One fix, well proven.** Validate a single, high-value, low-risk fix thoroughly rather than half-piloting
  several. Credibility comes from one proven path, not many started ones.

## Operating and handing off
- **Deliver to a decision-maker.** The roadmap is a decision artifact — present it to the accountable
  compliance/security owners, not just IT, so the ranked work gets funded.
- **Enforcement is a separate, change-controlled engagement.** Turning a validated fix into an enforced
  program (enable DLP, publish tenant-wide, enable auto-labeling) is follow-on work under change control —
  scope it explicitly, don't let it bleed into the assessment.
- **Re-assess on a cadence.** Posture drifts as the estate grows; re-run the assessment periodically (and
  after major M365 changes) so the baseline stays honest.

## Automation & security
- **Read-only first, least privilege always.** Discovery / ScopeHealth / Validation / Report are
  **read-only**; Pilot Remediation defaults to **`-WhatIf`** and creates only a **simulation** object.
  Connect with the **least Graph scopes** and the least Purview role each task needs.
- **No secrets in code.** Never place credentials, tokens, or connection strings in scripts or source
  control; rely on interactive modern-auth (`Connect-IPPSSession` / `Connect-MgGraph`).
- **Don't invent capability.** Where a cmdlet or portal path isn't readable, the scripts report **"not
  available — verify your licensing/tenant"** rather than asserting a feature exists. Keep that discipline
  in the written findings too.
