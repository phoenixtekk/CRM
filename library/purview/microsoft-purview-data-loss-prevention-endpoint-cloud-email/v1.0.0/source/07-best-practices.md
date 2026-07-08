# 7. Best Practices — Microsoft Purview Data Loss Prevention (DLP)

Field-tested practices for running Purview DLP across endpoint, cloud, and email so the control stays
trusted, effective, and low-noise. These complement the Implementation and Testing guides.

## Simulate before you enforce — always
- **Never** switch a new or materially changed DLP policy straight to enforce. Run it in **simulation**
  first, long enough to capture representative traffic (Req 2.6), and read the results before enabling.
- Use **simulation with policy tips** on the pilot ring when you want end-user feedback before hard block.
- Treat **simulation mode as your permanent safety switch**: any enforced policy can be returned to
  simulation in one setting, instantly removing enforcement with no data change — this is your rollback.

## Tune for a low false-positive rate (adoption depends on it)
- Start at **higher confidence** and a **realistic instance count** — a single credit-card match is noise;
  ten in one file is a leak. Bulk-exfiltration thresholds cut false positives dramatically.
- Add **supporting keywords and proximity** to custom SITs so context is required, not just a pattern.
- Use **Exact Data Match** for categories where pattern SITs over-fire — it matches your *actual* data and
  drives false positives toward zero, at the cost of an upload + refresh cadence.
- Every false positive that reaches a user erodes trust in **every** policy tip. Budget for a tuning cycle,
  not a one-time build.

## Right-size the user experience
- Show **clear, actionable policy tips** — tell the user *why* and *what to do*, in business language, not
  a compliance error code. Reuse one standard notice (`DLP Notice – Standard – AllPolicies`).
- Prefer **allow-with-justification / override** over hard block for categories where legitimate business
  exceptions exist, then **review the overrides** — routine overriding means the policy is mis-scoped.
- Reserve **hard block** for the categories where compliance/legal require it; escalate to block one
  category at a time, re-validating each.

## Endpoint DLP specifics
- **Onboarding is the gate.** A Devices policy is inert until the device is onboarded (shared with Defender
  for Endpoint) and reporting — verify onboarding before blaming the policy.
- Roll endpoint controls out **audit-first**: audit USB/print/cloud-upload activities before restricting,
  so you see real usage patterns and avoid blocking legitimate workflows.
- Mind **unallowed vs allowed apps/browsers and network exceptions** — configure the allowed-app and
  network-path lists so sanctioned tools aren't caught alongside exfiltration paths.

## Classification hygiene
- **Reuse built-in SITs** wherever they fit; build custom/EDM/trainable only for genuine gaps — fewer,
  well-tuned detectors beat a sprawl of overlapping ones.
- **Version and document** each custom SIT/EDM schema (pattern, confidence, keywords, owner) so tuning
  changes are traceable.
- **Refresh EDM data** on a schedule — stale EDM data silently degrades matching.

## Operations & governance
- Give DLP **alerts an owner and an SLA** (Req 2.7). Match volume without triage is not a control. Forward
  to SIEM/Sentinel where central SecOps needs visibility.
- Review **Activity Explorer** and the false-positive rate on a **recurring cadence**; re-tune as data and
  behavior drift.
- Enforce **least-privilege roles** and, where possible, **separate policy authors from alert triagers**.
- Keep a **change log** of every simulate→enforce transition and every action escalation, with the
  compliance sign-off attached.

## Stay inside the boundary
- DLP is **one control**, not a guarantee — it inspects content it can classify; combine with sensitivity
  labels, encryption, and insider-risk where the risk warrants.
- **Verify licensing/tenant** before relying on any endpoint or advanced-classifier capability — plans and
  portal paths evolve; don't assume a feature is present.
- The **enforced action and the acceptable false-positive threshold per category are compliance/legal
  determinations** — you provide the technical control and the evidence; they own the decision.
