# 7. Best Practices — FERPA DLP Pack (Microsoft Purview)

Field-tested practices for running education-record DLP across endpoint, cloud, and email so the control
stays trusted, effective, and low-noise in an academic environment. These complement the Implementation and
Testing guides.

## Simulate before you enforce — always
- **Never** switch a new or materially changed DLP policy straight to enforce. Run it in **simulation**
  first, long enough to capture representative academic traffic (a grading or admissions cycle is ideal —
  Req 2.6), and read the results before enabling.
- Use **simulation with policy tips** on the pilot ring when you want faculty/staff feedback before hard
  block.
- Treat **simulation mode as your permanent safety switch**: any enforced policy can be returned to
  simulation in one setting, instantly removing enforcement with no data change — this is your rollback.

## Get the student-identifier classification right
- **There is no reliable built-in student-ID detector** — build `Student ID – Custom SIT – FERPA` tuned to
  your local ID format, with **supporting keywords and proximity** so a bare number doesn't fire.
- Use **Exact Data Match** (`Student Records – EDM – FERPA`) for categories where pattern SITs over-fire — it
  matches your *actual* enrolled records and drives false positives toward zero, at the cost of an upload +
  refresh cadence tied to enrollment.
- **Reuse built-in SITs** (SSN, names, addresses, bank account) wherever they fit; build custom/EDM/trainable
  only for genuine gaps — fewer, well-tuned detectors beat a sprawl of overlapping ones.

## Tune for a low false-positive rate (adoption depends on it)
- Start at **higher confidence** and a **realistic instance count** — a single student ID is often
  legitimate; a roster of them in one outbound file is a leak. Bulk-exfiltration thresholds cut false
  positives dramatically.
- Every false positive that reaches a faculty member erodes trust in **every** policy tip. Budget for a
  tuning cycle, not a one-time build.
- Re-simulate after each change and re-measure — don't stack multiple tuning changes blind.

## Respect the directory-vs-non-directory boundary
- **DLP detects content; the registrar/FERPA function decides treatment.** The same name-and-address content
  may be disclosable **directory information** for one student and protected for another who has opted out.
  Don't encode a FERPA determination into a detector — scope and action follow the compliance decision.
- Where the FERPA function scopes a mailbox/site out (e.g. the registrar's controlled disclosure workflow),
  implement it as a **documented exception**, not a silently weakened policy.

## Right-size the user experience
- Show **clear, actionable policy tips** in plain academic language — tell the user *why* and *what to do*,
  not a compliance error code. Reuse one standard notice (`FERPA DLP Notice – Standard – AllPolicies`).
- Prefer **allow-with-justification / override** over hard block for categories where legitimate academic
  exceptions exist, then **review the overrides** — routine overriding means the policy is mis-scoped.
- Reserve **hard block** for the categories where the FERPA function requires it (e.g. external sharing of
  non-directory records); escalate to block one category at a time, re-validating each.

## Endpoint DLP specifics
- **Onboarding is the gate.** A Devices policy is inert until the faculty/staff device is onboarded (shared
  with Defender for Endpoint) and reporting — verify onboarding before blaming the policy.
- Roll endpoint controls out **audit-first**: audit USB/print/cloud-upload activities before restricting, so
  you see real record-handling patterns and avoid blocking legitimate academic workflows.
- Mind **unallowed vs allowed apps/browsers and network exceptions** — configure the allowed-app and
  network-path lists so sanctioned SIS/LMS tools aren't caught alongside exfiltration paths.

## Operations & governance
- Give DLP **alerts an owner and an SLA** (Req 2.7). Match volume without triage is not a control. Forward to
  SIEM/Sentinel where central SecOps needs visibility — but keep evidence access least-privilege since it can
  contain student PII.
- Review **Activity Explorer** and the false-positive rate on a **recurring cadence**; re-tune as data and
  behavior drift across terms.
- Enforce **least-privilege roles** and, where possible, **separate policy authors from alert triagers**.
- **Refresh EDM data** on a schedule aligned to enrollment — stale EDM data silently degrades matching.
- Keep a **change log** of every simulate→enforce transition and every action escalation, with the FERPA/
  registrar sign-off attached.

## Stay inside the boundary
- DLP is **one control**, not a guarantee — it inspects content it can classify; combine with sensitivity
  labels, encryption, and insider-risk where the risk warrants.
- **Verify licensing/tenant** before relying on any endpoint or advanced-classifier capability, and before
  assuming a FERPA-labeled policy template exists — plans and portal paths evolve; don't assume a feature is
  present.
- The **FERPA treatment, the enforced action, and the acceptable false-positive threshold per category are
  compliance/registrar/legal determinations** — you provide the technical control and the evidence; they own
  the decision.
