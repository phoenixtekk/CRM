# 5. Testing & Validation Guide — Business Glossary & Stewardship Program (Microsoft Purview)

Validation is a set of **pass/fail gates**. The pilot is not "done" until every gate below passes on
`DGGLOSS-Domain-Pilot`. Run the read-only scripts to gather evidence; capture the output as the
validation record. Where a check depends on a portal feature that is evolving, **verify the current
path and availability for your tenant**.

> Principle: a term is trustworthy only when it has an **agreed definition**, a **named owner and
> steward**, an **approved status**, and it is **kept current**. The gates below test exactly those
> properties — not merely that a term row exists.

---

## Gate 1 — Readiness and roles
- **Test:** Run `DGGLOSS-Discovery.ps1`. Confirm the Unified Catalog endpoint is reachable, the pilot
  domain exists (or is ready to create), and governance roles (domain owner / data owner / steward)
  are assigned at the domain scope.
- **Pass:** Endpoint PASS; `DGGLOSS-Domain-Pilot` present; each governance role shows assigned.
- **Fail:** Endpoint unreachable, domain missing, or a role shows unassigned → remediate per
  Requirements R1/R2 before continuing.

## Gate 2 — Scope recorded
- **Test:** Run `DGGLOSS-Set-Scope.ps1` and confirm the manifest lists the pilot domain, the 5–10
  candidate terms, the owner/steward mapping, and the re-certification interval.
- **Pass:** A complete scope manifest is produced and matches what the data owner agreed.
- **Fail:** Missing terms, owners, or interval → complete the scope with the data owner and re-run.

## Gate 3 — Glossary seeded in Draft (no premature publishing)
- **Test:** After `DGGLOSS-Configure-Glossary.ps1` `-WhatIf` then `-Commit`, run `DGGLOSS-Report.ps1`.
- **Pass:** All seeded terms exist in **Draft** status, each with a definition, an owner, and a
  steward; **none** is Published yet.
- **Fail:** A term is missing a definition/owner/steward, or a term was Published before owner
  approval → correct and re-run. (A Draft term is not business-visible; safe to fix.)

## Gate 4 — Workflow blocks unapproved publishing
- **Test:** Attempt to move a test Draft term to **Published** as a **data steward** (not the
  approver). Then have the **approver** approve and publish it.
- **Pass:** The steward alone cannot Publish; only after approver approval does the term reach
  **Published**.
- **Fail:** A term reaches Published without approver sign-off → fix the workflow / manual gate per
  Implementation Step 5 before Publishing further. **Verify approval-workflow availability for your
  tenant.**

## Gate 5 — Published terms are owned, defined, and linked
- **Test:** Run `DGGLOSS-Validate.ps1` against the pilot domain.
- **Pass:** Every **Published** pilot term has an approved definition, a named owner and steward, and
  (where applicable) at least one linked critical data element / asset.
- **Fail:** Any Published term missing a definition, owner, steward, or intended link → return it to
  Draft/Review, correct, re-approve.

## Gate 6 — Upkeep cadence is evidenced
- **Test:** Run `DGGLOSS-Report.ps1` and review the stewardship report.
- **Pass:** The report shows: term counts by status; **zero** unowned Published terms; and no
  Published term past the re-certification interval (or each such term flagged for review). The steward
  cadence (e.g. monthly) is scheduled.
- **Fail:** Unowned Published terms, or stale terms with no review action → assign owners / re-certify
  or retire (**Expired**) before declaring the program operational.

---

## Overall pilot pass/fail
The pilot **passes** only when **Gates 1–6 all pass** on `DGGLOSS-Domain-Pilot`. Record the script
outputs as the validation evidence pack. Do **not** expand to further governance domains until the
pilot gate is green. On expansion, re-run Gates 1–6 per new domain.

## Rollback summary
Glossary changes are low-blast-radius: a **Draft** term is not business-visible, so the safe rollback
for any misconfiguration is to keep the term in **Draft** (or delete it) and correct the definition,
owner, or link before re-approving. Retiring a bad Published term is a status change to **Expired**,
not a data deletion. No user data is modified by any step in this solution.
