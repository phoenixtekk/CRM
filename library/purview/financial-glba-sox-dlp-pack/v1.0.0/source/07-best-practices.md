# 7. Best Practices — Financial (GLBA/SOX) DLP Pack (Microsoft Purview)

Field-tested practices for running GLBA/SOX-aligned DLP for financial and NPI data across endpoint, cloud,
and email so the control stays trusted, effective, low-noise, and defensible. These complement the
Implementation and Testing guides.

## Simulate before you enforce — always
- **Never** switch a new or materially changed financial DLP policy straight to enforce. Run it in
  **simulation** first, long enough to capture representative finance traffic — **span at least one
  month-end/reporting cycle** (Req 2.6) — and read the results before enabling.
- Use **simulation with policy tips** on the finance pilot ring when you want end-user feedback before hard
  block.
- Treat **simulation mode as your permanent safety switch**: any enforced policy can be returned to
  simulation in one setting, instantly removing enforcement with no data change — this is your rollback,
  and it means a DLP change can never take down month-end close.

## Tune for a low false-positive rate (adoption depends on it)
- Start at **higher confidence** and a **realistic instance count** — a single card/account number is
  noise; ten in one file is a leak. Bulk-exfiltration thresholds cut false positives dramatically.
- **Financial numeric patterns over-fire.** Built-in *Credit Card Number*, *ABA Routing Number*, and
  *U.S. Bank Account Number* SITs, and any broad custom `Account Number`/`GL Account Code` SIT, will match
  internal reference numbers, invoice IDs, and GL codes unless you require **supporting keywords and
  proximity** for context.
- Use **Exact Data Match** for customer NPI where pattern SITs over-fire — it matches your *actual* account
  data and drives false positives toward zero, at the cost of an upload + refresh cadence.
- Every false positive that reaches a finance user erodes trust in **every** policy tip. Budget for a
  tuning cycle, not a one-time build.

## Right-size the user experience for finance
- Show **clear, actionable policy tips** in business language — tell the user *why* and *what to do*, not a
  compliance error code. Reuse one standard notice (`DLP Notice – GLBA NPI – AllPolicies`).
- Prefer **allow-with-justification / override** over hard block for categories with legitimate business
  exceptions (vendor payments, sanctioned external reporting), then **review the overrides** — routine
  overriding means the policy is mis-scoped.
- Reserve **hard block / encrypt** for the categories where compliance/legal require it (e.g. bulk customer
  NPI to external recipients); escalate to block one category at a time, re-validating each.

## Endpoint DLP specifics (finance/treasury laptops)
- **Onboarding is the gate.** A Devices policy is inert until the finance device is onboarded (shared with
  Defender for Endpoint) and reporting — verify onboarding before blaming the policy.
- Roll endpoint controls out **audit-first**: audit USB/print/cloud-upload activities before restricting,
  so you see real finance workflows and avoid blocking legitimate ones.
- Mind **unallowed vs allowed apps/browsers and network exceptions** — allow sanctioned finance tools and
  network paths so they aren't caught alongside exfiltration paths.

## Classification hygiene
- **Reuse built-in financial SITs and the GLBA / U.S. Financial Data templates** wherever they fit; build
  custom/EDM/fingerprint/trainable only for genuine gaps (internal account numbers, GL codes, statement
  templates). Fewer, well-tuned detectors beat a sprawl of overlapping ones.
- **Version and document** each custom SIT/EDM schema/fingerprint (pattern, confidence, keywords, owner) so
  tuning changes are traceable — traceability supports SOX change-control expectations.
- **Refresh EDM data and re-fingerprint statement templates** on a schedule — stale sources silently
  degrade matching.

## GLBA/SOX operations & governance
- Give financial DLP **alerts an owner and an SLA** (Req 2.7), and **control who may view NPI in the match
  evidence** — the evidence itself contains protected data. Forward to SIEM/Sentinel where central SecOps
  needs visibility.
- **Separate policy authors from alert triagers** where possible — segregation of duties matters for SOX.
- Review **Activity Explorer** and the false-positive rate on a **recurring cadence**; re-tune as data and
  behavior drift.
- Keep a **change log** of every simulate→enforce transition and every action escalation, with the
  compliance sign-off attached — this is your GLBA safeguards / SOX control evidence.

## Stay inside the boundary
- DLP is **one control**, not GLBA/SOX compliance on its own — it inspects content it can classify; combine
  with sensitivity labels, encryption, access controls, and insider-risk where the risk warrants.
- **Verify licensing/tenant** before relying on any endpoint, EDM, fingerprinting, trainable-classifier, or
  named-template capability — plans, portal paths, and template names evolve; don't assume a feature is
  present.
- **Which data is NPI under GLBA, which records are SOX-scoped, the enforced action per category, retention
  obligations, and acceptable false-positive thresholds are compliance/records/privacy/legal
  determinations** — you provide the technical control and the evidence; they own the decision.
