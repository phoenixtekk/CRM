# 7. Best Practices — GDPR / PII DLP Pack (Microsoft Purview)

Field-tested practices for running personal-data DLP across endpoint, cloud, and email so the control stays
trusted, effective, and low-noise. These complement the Implementation and Testing guides.

## Simulate before you enforce — always
- **Never** switch a new or materially changed DLP policy straight to enforce. Run it in **simulation**
  first, long enough to capture representative business traffic (a normal operating cycle — Req 2.6), and
  read the results before enabling.
- Use **simulation with policy tips** on the pilot ring when you want staff feedback before hard block.
- Treat **simulation mode as your permanent safety switch**: any enforced policy can be returned to
  simulation in one setting, instantly removing enforcement with no data change — this is your rollback.

## Get the EU personal-data classification right
- **The EU is many identifier schemes, not one.** Reuse the **EU/GDPR built-in SITs** (national ID,
  passport, TIN, social-security-equivalent, driver's licence, debit card, IBAN, full names) and the
  **per-country** variants for the member states you operate in — build custom only for genuine gaps.
- **There is no clean built-in for bespoke references** — build `EU National ID – Custom SIT – GDPR` tuned
  to the local format, with **supporting keywords and proximity** so a bare number doesn't fire.
- Use **Exact Data Match** (`Data Subject Records – EDM – GDPR`) for categories where pattern SITs over-fire
  — it matches your *actual* records and drives false positives toward zero, at the cost of an upload +
  refresh cadence. (Confirm the DPO position on hashing a personal-data table.)
- For **special-category (Article 9)** content — health, biometric-context, etc. — use **trainable
  classifiers** or keyword evidence, not a lone regex; *what* counts as special category is a DPO/legal call.

## Tune for a low false-positive rate (adoption depends on it)
- Start at **higher confidence** and a **realistic instance count** — a single national ID is often
  legitimate; a bulk data-subject list in one outbound file is a leak. Bulk-exfiltration thresholds cut false
  positives dramatically.
- Every false positive that reaches a staff member erodes trust in **every** policy tip. Budget for a tuning
  cycle, not a one-time build.
- Re-simulate after each change and re-measure — don't stack multiple tuning changes blind.

## Respect the GDPR determination boundary
- **DLP detects content; the DPO/legal function decides treatment.** Lawful basis, special-category status,
  whether a transfer is a **restricted cross-border transfer** and its safeguard, and retention are legal
  determinations — don't encode them into a detector; scope and action follow the compliance decision.
- Add **transfer awareness** with the *recipient is external* condition where cross-border movement is a
  concern, but the *legal* treatment of the transfer stays with legal.
- Where the DPO function scopes a mailbox/site out (e.g. a controlled DSAR-fulfilment workflow), implement it
  as a **documented exception**, not a silently weakened policy.

## Right-size the user experience
- Show **clear, actionable policy tips** in plain business language — tell the user *why* and *what to do*,
  not a compliance error code. Reuse one standard notice (`GDPR DLP Notice – Standard – AllPolicies`).
- Prefer **allow-with-justification / override** over hard block for categories where legitimate business
  exceptions exist, then **review the overrides** — routine overriding means the policy is mis-scoped.
- Reserve **hard block** for the categories where the DPO function requires it (e.g. external/cross-border
  sharing of national-ID or special-category data); escalate to block one category at a time, re-validating.

## Endpoint DLP specifics
- **Onboarding is the gate.** A Devices policy is inert until the device is onboarded (shared with Defender
  for Endpoint) and reporting — verify onboarding before blaming the policy.
- Roll endpoint controls out **audit-first**: audit USB/print/cloud-upload activities before restricting, so
  you see real personal-data-handling patterns and avoid blocking legitimate business workflows.
- Mind **unallowed vs allowed apps/browsers and network exceptions** — configure the allowed-app and
  network-path lists so sanctioned CRM/HR tools aren't caught alongside exfiltration paths.

## Operations & governance
- Give DLP **alerts an owner and an SLA** (Req 2.7). Match volume without triage is not a control. Wire a
  **DPO/breach hand-off** for real exposures so notifiable-breach timelines aren't missed. Forward to
  SIEM/Sentinel where central SecOps needs visibility — but keep evidence access least-privilege since it
  contains personal data (data-minimisation on the control's own records).
- Review **Activity Explorer** and the false-positive rate on a **recurring cadence**; re-tune as data and
  behaviour drift.
- Enforce **least-privilege roles** and, where possible, **separate policy authors from alert triagers**.
- **Refresh EDM data** on a schedule aligned to the source set — stale EDM data silently degrades matching.
- Keep a **change log** of every simulate→enforce transition and every action escalation, with the DPO/legal
  sign-off attached.

## Stay inside the boundary
- DLP is **one control**, not a guarantee — it inspects content it can classify; combine with sensitivity
  labels, encryption, and insider-risk where the risk warrants.
- **Verify licensing/tenant** before relying on any endpoint or advanced-classifier capability, and before
  assuming a GDPR-labeled policy template exists — plans and portal paths evolve; don't assume a feature is
  present.
- **Lawful basis, special-category status, cross-border-transfer treatment, the enforced action, and the
  acceptable false-positive threshold per category are data-protection/privacy (DPO)/legal determinations** —
  you provide the technical control and the evidence; they own the decision.
