# 7. Best Practices — Microsoft Purview for Education (FERPA)

Field-proven recommendations for an education-tailored Purview program that is accurate, defensible,
and low-friction for staff and students.

## Design
- **Let governance own the determinations.** FERPA applicability, retention periods, file plans, and
  legal holds are **records/privacy/legal** calls. Configure Purview to **enforce** them; never invent a
  retention period or decide what an education record is on your own. Capture named approvers.
- **Keep the label taxonomy small and human.** Four labels staff understand (`EDU - Public` →
  `EDU - Highly Confidential`, with `EDU - Student Record (FERPA)`) beat a sprawling set nobody applies
  correctly. Complexity causes mislabeling, which undermines every downstream control.
- **Make the student ID the anchor signal.** Education-record detection is only as good as your
  **custom `EDU - Student ID` SIT**. Invest in getting its pattern and false-positive rate right — it
  is what makes DLP and auto-labeling "understand" education records. There is **no built-in FERPA SIT**.
- **Design labels → DLP → retention as one chain.** Labels classify, DLP protects the labeled/detected
  data, retention keeps and disposes it. Wiring them to the **same** education-record definition keeps
  the program coherent (the whole point of the industry bundle).

## Pilot in simulation/test — always
- **Never enforce first.** Create DLP in **Test** and auto-labeling in **simulation**, on a **pilot
  scope**, every time. Review what *would* happen before it happens. This is the single most important
  habit in a live education tenant.
- **Read the Test/simulation results before enforcing.** A Test DLP policy and an auto-label simulation
  exist to be *reviewed*. Move to Enforce/on only after the matches look right and change control
  approves — then expand in waves, validating each.
- **Use synthetic data for testing.** Test DLP and labels with **fake** student records, never real
  ones — testing must not itself create a FERPA exposure.

## Accuracy and friction
- **Tune for false positives before you enforce.** Over-eager DLP blocks legitimate teaching/registrar
  work and trains staff to route around it. Adjust SIT confidence, instance counts, and conditions in
  Test until precision is acceptable.
- **Publish labels with a sensible default, not mandatory (at first).** Start with a default label and
  optional justification; only make labeling **mandatory** after staff are trained — mandatory is an
  enforcing change.
- **Protect containers used for student data.** Where student records live in specific Teams/SharePoint
  sites, use **container labels** so the site itself carries protection, not just individual files.

## Retention & records (handle with extra care)
- **Retention preserves content — confirm the period first.** Once applied, retained content stays for
  the period even if you unpublish the label. **Do not apply retention until the records owner signs off
  the schedule.** Use **disposition review** where records management requires human sign-off before
  deletion.
- **Separate "retain" from "delete."** Be explicit about whether a label retains-then-deletes,
  retains-only, or deletes-only, and match it to the records schedule — a wrong disposition rule is a
  records incident.

## Evidence & posture
- **Turn Audit on and keep it on.** Label, DLP, and retention activity in the audit log is your evidence
  the program operates. Use **Audit Premium** retention where licensed.
- **Work Compliance Manager continuously.** Treat `EDU - FERPA Posture` improvement actions as a living
  backlog with attached evidence — it turns a pile of policies into a **scored, defensible** posture for
  any FERPA inquiry.

## Operations, automation & security
- **Run the scripts read-only first.** `EDU-Discovery` / `EDU-Validation` / `EDU-Report` /
  `EDU-Scope-Health` are read-only; `EDU-Set-Configuration` defaults to **`-WhatIf`** and creates DLP in
  **Test** even with `-Commit`. Preview before you write; enforcement is always a separate, deliberate,
  human step.
- **Least privilege, no secrets.** Connect with the **least Purview role groups / Graph scopes** each
  task needs; **never** put credentials, tokens, or student data in scripts or source control. Use
  modern-auth / MFA admin accounts.
- **Verify licensing/tenant at every plan-gated step.** Advanced DLP, auto-labeling simulation, records
  management, and premium Compliance Manager assessments require **E5 / E5 Compliance** and the portal
  evolves — confirm availability and paths against **current Microsoft guidance / your tenant** rather
  than assuming.
- **Document rollback for every enforcing change.** Know the revert before you enforce: set DLP back to
  **Test** / disable it; remove the pilot group from the label policy to stop offering labels; remember
  **retained content stays retained** — which is exactly why retention goes last and only after sign-off.
