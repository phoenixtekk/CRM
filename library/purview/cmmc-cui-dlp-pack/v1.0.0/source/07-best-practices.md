# 7. Best Practices — CMMC / CUI DLP Pack (Microsoft Purview)

Field-tested practices for running CUI-tuned Purview DLP so the control stays trusted, effective, low-noise,
and **defensible in an assessment**. These complement the Implementation and Testing guides.

## Label first, keywords second
- **Key policies on the `CUI` sensitivity label** as the primary condition — it follows the marking decision
  a human or auto-labeling policy already made, and is far more precise than string matching. Use the
  **marking keyword SIT** as the *backstop* for marked-but-unlabeled CUI, not the primary detector.
- **Never invent CUI markings.** Build the marking SIT only from the exact banner/portion strings compliance
  supplies (NARA CUI Registry / your marking policy). Add proximity/context so a stray "CUI" mention in
  guidance text doesn't fire.
- Getting the label right feeds the whole safeguarding program (encryption, auto-labeling, insider risk) —
  invest there, not in ever-more-complex DLP regex.

## Simulate before you enforce — always
- **Never** switch a new or materially changed CUI DLP policy straight to enforce. Run it in **simulation**
  first, long enough to capture representative CUI traffic (Req 2.7), and read the results before enabling.
- Use **simulation with policy tips** on the pilot ring when you want end-user feedback before hard block.
- Treat **simulation mode as your permanent safety switch**: any enforced policy returns to simulation in one
  setting, instantly removing enforcement with no data change — this is your rollback.

## Scope to the CUI enclave
- Focus enforcement on the **users, sites, and devices that actually handle CUI** (Req 2.4). Enclave scoping
  cuts false positives, shrinks blast radius, and keeps the control narrative clean for an assessor.
- Add a condition for **external recipient / external sharing** so internal enclave movement of CUI isn't
  flagged as a leak — the risk is CUI *leaving* the boundary.

## Tune for a low false-positive rate (adoption depends on it)
- Label-keyed matching should already be precise; most false positives come from the **marking keyword SIT**
  over-firing — fix it with proximity, context keywords, and targeted exceptions (e.g. a CUI-training
  library), not by loosening the label condition.
- Every false positive that reaches a user erodes trust in **every** policy tip. Budget for a tuning cycle,
  not a one-time build.

## Right-size the user experience
- Show **clear, actionable policy tips** in plain language — tell the user the content is **marked CUI** and
  what they may/may not do, not a compliance error code. Reuse one standard notice
  (`CUI Notice – Standard – AllPolicies`).
- Prefer **allow-with-justification / override** over hard block where legitimate contract exceptions exist,
  then **review the overrides** — routine overriding means the policy is mis-scoped. Reserve **hard block/
  encrypt** for the categories where compliance requires it.

## Endpoint DLP specifics
- **Onboarding is the gate.** A Devices policy is inert until the device is onboarded (shared with Defender
  for Endpoint) and reporting — verify onboarding before blaming the policy.
- Roll endpoint controls out **audit-first**: audit USB/print/cloud-upload of CUI before restricting, so you
  see real usage and avoid blocking legitimate contract workflows.
- Mind **allowed vs unallowed apps/browsers and network exceptions** so sanctioned tools aren't caught
  alongside exfiltration paths.

## GCC High & tenant discipline
- **Confirm the tenant type** (Commercial / GCC / **GCC High**) and **verify every portal path and
  capability** against that environment's Microsoft docs — GCC High differs and preview features may not be
  present. Flag, don't assume.
- Whether CUI (especially export-controlled categories) **must reside in GCC High** is a compliance/contracts
  determination — not a technical default.

## Evidence & operations (this is what an assessor asks for)
- Give CUI DLP **alerts an owner and an SLA** (Req 2.8). Match volume without triage is not a control.
- **Retain the evidence trail** — alert dispositions, Activity Explorer exports, the simulate→enforce change
  log, and compliance sign-offs — so the control can be *shown*, not just claimed.
- Review **Activity Explorer** and the false-positive rate on a **recurring cadence**; re-tune as data and
  behavior drift.
- Enforce **least-privilege roles** and, where possible, **separate policy authors from alert triagers**.

## Stay inside the boundary
- DLP is **one supporting control**, not a compliance guarantee — combine it with the CUI **sensitivity
  label + encryption**, access control, and insider-risk where the risk warrants.
- The **enforced action, the CUI categories/markings in scope, GCC High residency, DFARS incident-reporting,
  and all CMMC / NIST SP 800-171 satisfaction and assessment determinations** are **compliance / contracts /
  legal / C3PAO** decisions — you provide the technical control and the evidence; they own the call.
