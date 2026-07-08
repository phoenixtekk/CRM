# 7. Best Practices — Microsoft Purview Administrator Training

Field-proven recommendations for building durable Purview administrator competence — and for the
operational habits the training must instill.

- **Train the safe-rollout pattern, not just the feature.** The single most valuable thing an
  administrator can internalize is **scope-first, simulate-first, validate-before-enforce**. Every lab
  is built that way on purpose — a training group, simulation/test/disabled mode, a pass/fail gate — so
  the habit transfers directly to production, where DLP, labels, retention, and auto-labeling are all
  high-impact.
- **Never let a training policy enforce.** DLP stays in **test** mode; auto-labeling stays in
  **simulation**; retention uses **illustrative** periods; eDiscovery holds only a **training**
  custodian. The validation gates explicitly FAIL an enabled/enforcing training policy — treat that as a
  hard stop, not a warning.
- **Prefer a sandbox/training tenant.** A dedicated tenant removes all doubt. When you must train in
  production, confine every lab to `TRAIN-Pilot-Users` and simulation/test, and **tear down to the
  baseline** afterward — the `OPSTRAIN-LabBaseline.ps1` snapshot is what "clean" means.
- **Use the `TRAIN-` naming convention verbatim.** Consistent, prefixed names make every training
  artifact unmistakable, let `OPSTRAIN-LabValidate.ps1` find and check it, and make teardown reliable —
  the same object-naming discipline production Purview work needs.
- **Teach least privilege from Module 0.** Have each trainee operate from the **least-privilege role
  group** for their module, with Global Administrator reserved. Learning to do the job without over-
  permission is itself a core competency and a security control.
- **Keep Insider Risk and Communication Compliance privacy-first.** These are HR/privacy-sensitive.
  Always enable **pseudonymization/anonymization**, enforce **strict role separation** (analyst vs
  investigator vs admin — different people), use **no real employee data** in training, and make clear
  that **case outcomes are HR/legal's determination**, never the administrator's.
- **Draw the configure-vs-determine line explicitly.** The administrator *configures the technical
  control*; the *records schedule, file plan, legal hold, and case outcome* are decided by
  compliance/records/privacy/HR/legal. Bake this into every relevant lab and into the Module 10 RACI so
  a trained admin never mistakes a mechanic for a mandate.
- **Validate competence with evidence, not attendance.** "Trained" means each lab's pass/fail gate was
  met and captured in the `OPSTRAIN-CompetencyReport.ps1` output — an evidenced capability, re-runnable
  when you onboard the next administrator.
- **Turn labs into runbooks.** The value compounds when Module 10 converts the labs into the recurring
  operational work — weekly DLP alert triage, monthly label-coverage review, retention/records request
  routing, audit-search handling, and change-control for any new policy. Assign owners; the runbook is
  the deliverable, not the memory of the lab.
- **Verify licensing per module, and degrade gracefully.** Advanced DLP, auto-labeling, insider risk,
  communication compliance, Audit Premium, eDiscovery Premium, and DSPM need **E5 / E5 Compliance**
  (some preview). Where a feature is unlicensed, run a **read-only walkthrough** and set the gate to
  "can navigate and explain" — never assume a capability is present.
- **Verify evolving portal surfaces in your tenant.** Purview paths and cmdlet behavior change. Confirm
  exact toggles for your tenant, flag anything volatile **"verify in your tenant,"** and defer to
  Microsoft's current documentation — never invent a path or cmdlet to make a lab "work."
- **Re-run the curriculum for every new hire.** The whole package is reusable: run readiness, stand up
  the scope, run the labs, validate, tear down. Onboarding a new Purview administrator becomes a known,
  evidenced, low-risk process instead of another round of trial-and-error on production.
