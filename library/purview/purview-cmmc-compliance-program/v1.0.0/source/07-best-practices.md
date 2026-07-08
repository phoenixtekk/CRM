# 7. Best Practices — Microsoft Purview CMMC Compliance Program

- **Measure before you certify.** Compliance Manager gives you a defensible **posture and evidence**;
  it does not certify. Treat the score as your internal readiness signal and the **C3PAO assessment**
  as the determination — keep the two clearly separated so nobody mistakes a green score for a
  certificate.
- **Confirm the cloud first.** For CUI, verify whether you must run in **GCC High** (or GCC) *before*
  building — template availability, portal paths, and cmdlets differ, and building in the wrong cloud
  is rework and, for regulated CUI, a compliance failure.
- **Verify template availability, don't assume it.** The **CMMC Level 2 / NIST SP 800-171** template is
  premium and entitlement-gated, and its exact name evolves. Confirm it shows as *available to create*
  in your tenant and cloud before you promise a timeline.
- **Pilot one assessment end-to-end.** Validate ownership, evidence, and automatic testing on
  `CMMC Assessment – NIST 800-171 – Pilot` before building the production set. One clean assessment
  proves the model; ten half-owned ones prove nothing.
- **Map every action to its requirement.** Keep `CMMC Control Map – NIST 800-171` current so each
  improvement action is traceable to a NIST 800-171 requirement and family — that traceability is what
  a C3PAO reviews, and it is how you spot which of the 110 requirements are still uncovered.
- **Separate roles as a control, not a formality.** Least-privilege separation of Compliance Manager
  administrators, contributors, and read-only readers/assessors is itself an Access Control requirement
  — and it keeps your evidence defensible because access to it was governed.
- **Never mark implemented without proof (no false pass).** Set an action to Implemented only when the
  evidence exists; let genuinely-absent controls score as gaps and route them to the **POA&M**. An
  inflated score is the fastest way to fail a C3PAO assessment.
- **Automatic testing where it's real, manual evidence everywhere else.** Enable automatic testing so
  technical actions (audit, MFA/Conditional Access, DLP/retention/labels/encryption) self-update — but
  cross-check with `CMMC-Validation.ps1`, and don't assume auto-coverage for actions that need
  policy/procedure evidence.
- **Pilot high-impact technical remediation in simulation/test.** When an action recommends enabling
  DLP, encryption, retention, or tighter Conditional Access, roll it out in simulation/test under change
  control first — those are owned by their feature's solution, not switched on blind to chase a point.
- **Keep the SSP and POA&M as living documents.** The assessment measures against the **CUI boundary
  and SSP**; keep them, the evidence register, and the owners current on a cadence so the program is
  audit-ready continuously, not just before an assessment.
- **Report the trend, not just the number.** Run `CMMC-Report.ps1` on a schedule so leadership sees
  coverage-by-family moving toward the target level, and so remaining gaps have owners and dates ahead
  of the C3PAO engagement.
