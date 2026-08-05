# Testing and Validation

The point of testing is not to confirm the documents exist — it is to prove the **governance gates
actually function**: that an agent cannot reach business use without an owner and an approval, that
an unreviewed org-wide share is caught, and that a stale or ownerless agent is retired. Each gate
below has an explicit **PASS / FAIL** criterion. Do not proceed to Step 13 (expand) until every gate
passes for the pilot scope.

Use the exact object names from Section 3 throughout.

---

## Gate 1 — Build eligibility is enforced

**What you are proving:** only members of `AGBGOV – Agent Builders` can create agents (where your
policy restricts build).

**Procedure**
1. Sign in as a test user who is **not** in `AGBGOV – Agent Builders`.
2. Open Microsoft 365 Copilot → **Agents → New agent / Agent Builder**.

**PASS:** the test user cannot create an agent (Agent Builder is unavailable or blocked), consistent
with the Copilot Control System agent access setting from Step 5a.
**FAIL:** the unsanctioned user can build and share an agent. Re-check Step 5a — confirm **Specific
users/groups** is set to `AGBGOV – Agent Builders` and that the change has propagated (allow time for
tenant replication).

> If your policy is deliberately **open build** with post-hoc governance, mark this gate **N/A** and
> record that decision — but Gate 2 and Gate 3 then carry the whole load.

---

## Gate 2 — Org-wide sharing is restricted

**What you are proving:** an ordinary user cannot share an agent with **"Anyone in your
organization"** — the core gap this product closes.

**Procedure**
1. Sign in as a sanctioned builder who is **not** in `AGBGOV – Agent Sharing – Org-Wide Approved`.
2. Build a trivial test agent named `AGBGOV – Test – Sharing Gate – Pilot`.
3. Select **Share** and inspect the sharing options.

**PASS:** the **Anyone in your organization** option is **greyed out** (with the restriction tooltip)
and only **Only you** / **Specific users in your organization** are available.
**FAIL:** the user can select **Anyone in your organization**. Re-check Step 5b — confirm the agent
sharing control is set to **Specific users or groups** = `AGBGOV – Agent Sharing – Org-Wide
Approved`, and remember the documented behaviour that the control affects **new** sharing actions
only.

---

## Gate 3 — The intake / approval gate holds

**What you are proving:** an agent cannot reach `Approved – business use` without passing the ARB.

**Procedure**
1. Submit the test agent through the `AGBGOV – Agent Intake Request Form`.
2. Attempt to record it as `Approved – business use` in the register **without** an
   `AGBGOV – Agent Decision Record` entry.
3. Run the validation script against the register export:
   ```
   powershell -ExecutionPolicy Bypass -File .\AGBGOV-Validation.ps1 -RegisterCsv .\AGBGOV-Register-Export.csv -CsvPath .\Validation-Gate3.csv
   ```

**PASS:** `AGBGOV-Validation.ps1` reports **G3_ApprovalRecorded = FAIL** for that agent (approval
claimed with no `AGBARB-` reference), catching the bypass.
**FAIL:** the script reports PASS despite the missing decision record. Confirm the register's
`Lifecycle State` and `ARB Decision Reference` columns are populated as designed and that the export
carries them.

---

## Gate 4 — The org-catalog publish path requires admin approval

**What you are proving:** submitting an agent to the org catalog routes to an admin, and publication
is an admin action.

**Procedure**
1. As a sanctioned builder, **submit the test agent to your org catalog**.
2. As the Agent Admin, open Microsoft 365 admin center → **Agents → All agents → Registry** and find
   the pending **agent request**.

**PASS:** the agent appears as a pending request and does **not** show in **Built by your org** in the
Agent Store until the admin publishes it; the admin can **publish** or **reject** it.
**FAIL:** the agent appears in **Built by your org** with no admin action. Re-check Step 5c and
confirm the approval path is active (Government tenants: confirm the request queue is visible —
publishing to the org is supported in GCCH/GCCM).

---

## Gate 5 — Sensitive-data agents require a data review

**What you are proving:** an agent over `Confidential`/`Restricted` sources cannot be approved without
a named Data & Security Reviewer.

**Procedure**
1. In the register, create a test entry with `Data Classification = Confidential`, `Lifecycle State =
   Approved – business use`, an owner and sponsor, but **no** Data & Security Reviewer.
2. Run `AGBGOV-Validation.ps1` as in Gate 3.

**PASS:** the script reports **G4_DataReview = FAIL** for that agent.
**FAIL:** the script reports PASS. Confirm the `Data & Security Reviewer` and `Data Classification`
columns are present and correctly named in the export.

---

## Gate 6 — Broadly-shared and ownerless agents are surfaced

**What you are proving:** the monthly sweep finds the agents that need review.

**Procedure**
1. Ensure at least one test agent is shared org-wide and at least one has no owner (or use the real
   baseline).
2. Run:
   ```
   powershell -ExecutionPolicy Bypass -File .\AGBGOV-Review-SharedAgents.ps1 -CsvPath .\SharedReview-Gate6.csv
   ```
   (Government / no-Graph: add `-RegistryCsv .\ExportedAgents.csv -Environment USGov`.)

**PASS:** the output CSV lists the org-wide agent with `Reason = OrgWideShare` and the ownerless agent
with `Reason = NoOwner` and `RecommendedAction = Retire-or-Reassign`.
**FAIL:** a known broadly-shared or ownerless agent is missing. Confirm the input source (Graph or
Registry export) actually contains the sharing/owner columns.

---

## Gate 7 — Retirement is real and evidenced

**What you are proving:** an agent can be blocked, notice given, deleted, and the evidence retained.

**Procedure**
1. Run the Step 10 retirement procedure on the test agent: block it in the Agent Registry, record the
   decision, then (after confirming) delete it.
2. Confirm the `AGBGOV – Agent Retirement Log` has an entry with block date, delete date, and reason.
3. Confirm the agent no longer appears to end users and is gone from the Agent Registry.

**PASS:** the agent is blocked/deleted, the retirement log entry exists, and end users can no longer
invoke it.
**FAIL:** the agent still runs, or no log entry exists. Blocking is reversible — re-block and complete
the log before deletion. Remember deletion is **permanent**; the block-then-wait sequence is
mandatory.

---

## Gate 8 — The governance scorecard is trending the right way

**What you are proving:** the model is measurably improving coverage and reducing risk.

**Procedure**
1. Run `AGBGOV-Report.ps1` at the end of pilot cycle 1 and again at cycle 2.
2. Compare the two scorecard rows.

**PASS:** across the two cycles, `PctWithOwner`, `PctWithApproval`, and `PctWithReviewDate` rise, and
`OwnerlessAgents`, `OverdueReviews`, and `SensitiveAgentsNoReviewer` fall (or are zero) for the pilot
scope.
**FAIL:** the numbers are flat or worse. Hold the Step 12 retrospective, find which gate produced the
rework, amend the standards, and run another cycle before expanding.

---

## Exit criteria for the pilot

All of Gates 1–8 **PASS** (or are explicitly recorded **N/A** with a documented reason), the pilot
scope shows a positive scorecard trend, and the retrospective actions are folded into the standards
document (version incremented). Only then run Step 13 (expand to the whole tenant).
