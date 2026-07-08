# 7. Best Practices — HIPAA / PHI DLP Pack (Microsoft Purview)

Field-tested practices for running PHI-focused Purview DLP across endpoint, cloud, and email so the
control stays trusted, effective, low-noise, and defensible. These complement the Implementation and
Testing guides.

## Simulate before you enforce — always
- **Never** switch a new or materially changed PHI DLP policy straight to enforce. Run it in
  **simulation** first, long enough to capture representative clinical/billing traffic (Req 2.6), and
  read the results before enabling.
- Use **simulation with policy tips** on the pilot ring when you want end-user feedback before hard
  block or encrypt.
- Treat **simulation mode as your permanent safety switch**: any enforced policy can be returned to
  simulation in one setting, instantly removing enforcement with no data change — this is your rollback.

## Tune for PHI, which is a combination — not a single token
- **Require co-occurrence** where it fits: match on an identifier (SSN/MRN) *and* a clinical detector
  (ICD-9/ICD-10) together, so a lone account number or a lone diagnosis code doesn't fire. This single
  change removes the largest source of PHI false positives.
- Start at **higher confidence** and a **realistic instance count** for bulk-leak detection (a roster
  export), but keep a **low count where a single-record disclosure matters** — tune per category with
  compliance, don't apply one threshold blindly.
- Use **Exact Data Match** against your patient/member roster for categories where pattern SITs over-
  fire — it matches your *actual* identifiers and drives false positives toward zero, at the cost of an
  upload + refresh cadence.
- Every false positive that reaches a clinician erodes trust in **every** policy tip. Budget for a
  tuning cycle, not a one-time build.

## Right-size the user experience for a clinical audience
- Show **clear, actionable policy tips** in plain clinical/business language — tell the user *why* it
  was flagged and *what to do* (use secure send / encrypt), not a compliance error code. Reuse one
  standard notice (`PHI DLP Notice – Standard – AllPolicies`).
- Prefer **encrypt** (for outbound PHI email) and **allow-with-justification / override** over hard
  block for categories where legitimate care coordination exists, then **review the overrides** —
  routine overriding means the policy is mis-scoped.
- Reserve **hard block** for the categories where compliance/legal require it; escalate to block one
  category at a time, re-validating each.

## Endpoint DLP specifics
- **Onboarding is the gate.** A Devices policy is inert until the device is onboarded (shared with
  Defender for Endpoint) and reporting — verify onboarding before blaming the policy. Prioritize
  clinician/billing workstations that handle PHI.
- Roll endpoint controls out **audit-first**: audit USB/print/cloud-upload activities before
  restricting, so you see real clinical usage patterns and avoid blocking legitimate workflows.
- Mind **unallowed vs allowed apps/browsers and network exceptions** — allow sanctioned clinical/billing
  tools and network paths so they aren't caught alongside exfiltration paths.

## Classification hygiene
- **Reuse the built-in HIPAA SITs** (SSN, ICD-9-CM, ICD-10-CM, DEA Number) wherever they fit; build
  custom/EDM/trainable only for genuine gaps (your MRN format, your member-ID format) — fewer,
  well-tuned detectors beat a sprawl of overlapping ones.
- **Version and document** each custom SIT/EDM schema (pattern, confidence, keywords, owner) so tuning
  changes are traceable for an audit.
- **Refresh EDM roster data** on a schedule — a stale roster silently degrades matching. Handle the
  roster export itself as PHI.

## Operations, evidence & governance (HIPAA-facing)
- Give PHI DLP **alerts an owner and an SLA** (Req 2.7), and a **standing escalation to the
  Privacy/Security Officer** for possible reportable disclosures. Match volume without triage is not a
  control — and the **breach determination is not a technical decision**.
- **Retain the evidence** the control produces (policy config, simulation FP measurement, alerts,
  dispositioned incidents) as your HIPAA control record — retention period is a records/compliance
  determination.
- Review **Activity Explorer** and the false-positive rate on a **recurring cadence**; re-tune as
  clinical and billing behavior drift.
- Enforce **least-privilege roles** and **separate policy authors from alert triagers** so PHI-evidence
  access stays minimal.
- Keep a **change log** of every simulate→enforce transition and every action escalation, with the
  compliance sign-off attached.

## Stay inside the boundary
- DLP is **one control**, not a guarantee — it inspects content it can classify (not scanned images
  without OCR, not strongly encrypted blobs); combine with **sensitivity labels, encryption, access
  controls, and insider-risk** where the PHI risk warrants.
- **Verify licensing/tenant** before relying on any endpoint or advanced-classifier capability, and
  confirm the **HIPAA template and its SITs** exist in your tenant — plans, the SIT library, and portal
  paths evolve; don't assume a feature is present.
- The **enforced action, the acceptable false-positive threshold, which data is PHI, and whether any
  event is a reportable HIPAA breach are compliance/privacy/legal determinations** — you provide the
  technical control and the evidence; they own the decision.
