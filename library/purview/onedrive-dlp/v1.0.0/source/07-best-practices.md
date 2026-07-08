# 7. Best Practices — OneDrive for Business DLP (Microsoft Purview)

Field-tested practices for running Purview DLP for OneDrive so the control stays trusted, effective, and
low-noise. These complement the Implementation and Testing guides.

## Simulate before you enforce — always
- **Never** switch a new or materially changed OneDrive DLP policy straight to enforce. Run it in
  **simulation** first, long enough to capture representative content and sharing activity (Req 2.6), and
  read the results before enabling.
- Use **simulation with policy tips** on the pilot ring when you want end-user feedback before hard
  restrict.
- Treat **simulation mode as your permanent safety switch**: any enforced policy can be returned to
  simulation in one setting, instantly removing enforcement with no data change — this is your rollback.

## Separate "at rest" from "shared" — act proportionally
- Split the control into an **at-rest** rule (sensitive content stored in OneDrive) and an
  **external-share** rule (that content shared outside the org). They warrant different thresholds and
  actions: at-rest is often *audit/notify* with a higher instance count; external over-share is the
  high-severity case and justifies a **lower threshold and a stronger action**.
- Target the **specific risky share**, not all sharing — use the *shared with people outside my
  organization* condition so internal collaboration is never disrupted.
- The most valuable single control is usually **restricting sensitive "anyone with the link" shares** —
  those are the widest-reachable and the least intentional.

## Tune for a low false-positive rate (adoption depends on it)
- Start at **higher confidence** and a **realistic instance count** for at-rest matches — a single
  credit-card match is noise; ten in one file is a leak.
- Add **supporting keywords and proximity** to custom SITs so context is required, not just a pattern.
- Use **Exact Data Match** for categories where pattern SITs over-fire — it matches your *actual* data
  and drives false positives toward zero, at the cost of an upload + refresh cadence.
- Every false positive that reaches a user erodes trust in **every** policy tip. Budget for a tuning
  cycle, not a one-time build.

## Right-size the user experience
- Show **clear, actionable policy tips** — tell the user *why* and *what to do* ("this file contains
  card numbers; remove the anyone-link or share internally only"), in business language, not a compliance
  error code. Reuse one standard notice (`DLP Notice – OneDrive – Standard`).
- Prefer **allow-with-justification / override** over hard restrict for categories where legitimate
  external sharing exists, then **review the overrides** — routine overriding means the policy is
  mis-scoped.
- Reserve **block external access** (removing links/external users) for the categories where compliance/
  legal require it; escalate one category at a time, re-validating each.

## Coordinate with tenant sharing settings
- DLP acts on the *sensitive* over-shares; the **tenant OneDrive/SharePoint external-sharing setting**
  governs sharing broadly. Treat them as complementary — DLP is the content-aware control, the tenant
  setting is the blunt boundary. Tightening the tenant setting is a separate, change-controlled action.
- Know your current posture (Req 2.3) before enforcing so you can predict how many external over-shares
  DLP will surface.

## Classification hygiene
- **Reuse built-in SITs** wherever they fit; build custom/EDM/trainable only for genuine gaps — fewer,
  well-tuned detectors beat a sprawl of overlapping ones.
- **Version and document** each custom SIT/EDM schema (pattern, confidence, keywords, owner) so tuning
  changes are traceable.
- **Refresh EDM data** on a schedule — stale EDM data silently degrades matching.

## Operations & governance
- Give DLP **alerts an owner and an SLA** (Req 2.7). Match volume without triage is not a control.
  Forward to SIEM/Sentinel where central SecOps needs visibility.
- Review **Activity Explorer** and the false-positive rate on a **recurring cadence**; re-tune as content
  and sharing behavior drift.
- Enforce **least-privilege roles** and, where possible, **separate policy authors from alert triagers**.
- Keep a **change log** of every simulate→enforce transition and every action escalation, with the
  compliance sign-off attached.

## Stay inside the boundary
- DLP is **one control**, not a guarantee — it inspects content it can classify; combine with
  sensitivity labels, tenant sharing controls, and insider-risk where the risk warrants.
- **Verify licensing/tenant** before relying on any custom/advanced-classifier capability — plans and
  portal paths evolve; don't assume a feature is present.
- The **enforced action and the acceptable false-positive threshold per category are compliance/legal
  determinations** — you provide the technical control and the evidence; they own the decision.
