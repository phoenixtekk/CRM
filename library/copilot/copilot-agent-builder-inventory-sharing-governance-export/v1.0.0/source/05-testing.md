# Testing & Validation

Each gate has an explicit **PASS / FAIL** criterion. Do not declare the register trustworthy until the
gates that apply to your path pass. Path B adds the sharing-accuracy gates; Path A stops at inventory
completeness.

## Gate 1 — Preflight returns a clear, correct verdict (Path B)

- **Do:** Run `AGBINV-Connect-Preflight.ps1 -Environment <cloud>`.
- **PASS:** The script prints the signed-in account, its scopes (including `CopilotPackages.Read.All`),
  its roles, and a decoded HTTP result (`200`/`401`/`403`/`404`) with a named likely cause.
- **FAIL:** The script errors without a decoded verdict, or reports `200` but a later call fails — recheck
  R1/R2 and re-run.

## Gate 2 — The API is reachable OR the fallback is confirmed

- **Do:** Read the preflight verdict.
- **PASS:** Either the preflight returns `200` (Path B available), **or** it returns `403`/`404` and you
  have confirmed the specific cause (R4 entitlement, R6 rollout, or Government cloud) and switched to
  **Path A**.
- **FAIL:** You are guessing which cause applies — go to Troubleshooting T2–T7 and distinguish them
  before proceeding.

## Gate 3 — Inventory is scoped to Agent Builder only (no Copilot Studio)

- **Do:** Open `AgentBuilder-Inventory_<date>.csv` (Path B) or the filtered admin-center export (Path A).
- **PASS:** Every row's **Platform** is *Microsoft 365 Copilot Agent Builder*; no row shows *Copilot
  Studio* or a partner/Microsoft publisher. (Path B: every row's `ElementTypes` contains
  `declarativeAgent`.)
- **FAIL:** Any Copilot Studio or non-Agent-Builder row is present — the platform filter was not applied;
  re-run Step 3/Step 5 with the filter.

## Gate 4 — Inventory is complete against the admin center

- **Do:** Compare the row count and agent names in the register against **Microsoft 365 admin center >
  Agents > All agents > Registry**, filtered to Platform = *Microsoft 365 Copilot Agent Builder*.
- **PASS:** The two lists match agent-for-agent (allowing for the minutes-level refresh lag between the
  portal and an export).
- **FAIL:** The register is missing agents present in the portal (or vice versa) — check paging in the
  export (the script must follow `@odata.nextLink`) and that no residual pilot filter is applied.

## Gate 5 — Sharing recipients are accurate (Path B)

- **Do:** Pick two agents — one shared with **Specific users**, one shared with **Anyone in your
  organization**. For the first, open the owner's **Share** dialog and note the recipients. For the
  second, confirm it is a broad share.
- **PASS:** The **Specific users** agent's register row lists exactly the same users/groups (resolved to
  names); the **Anyone in your organization** agent is labeled **Org-wide shared** (not an empty
  recipient list).
- **FAIL:** Recipients differ, are missing, or an org-wide share shows blank — most often a delegated
  scope/consent gap or an unresolved object ID (see Troubleshooting T5).

## Gate 6 — Group recipients resolve to real groups (Path B)

- **Do:** For any agent shared to a group, confirm the register's `RecipientName` matches a real Entra
  group.
- **PASS:** Each group `resourceId` resolves to a group display name; no rows show a raw GUID as the name.
- **FAIL:** Raw GUIDs remain — the resolver lacked directory read or the object is a different type;
  verify the account can read `GET /groups/{id}` and `GET /users/{id}`.

## Gate 7 — Owners are populated and ownerless agents are flagged

- **Do:** Scan the register's **Owner** column.
- **PASS:** Every agent has an owner, or agents with no owner are explicitly flagged **(ownerless)** —
  matching the admin center's *Agents without owners* count.
- **FAIL:** Owner is blank without the ownerless flag — reconcile against the admin center's ownerless
  filter.

## Gate 8 — The register is safe-to-store and reviewable

- **Do:** Confirm the register lives in the R9 location and carries the review columns.
- **PASS:** `AgentBuilder-Governance-Register_<date>.csv` is in `C:\AgentGovernance\Exports` (or the
  governed SharePoint location), access is restricted to the governance team, and the `OwnerConfirmed`
  / `SharingApproved` / `Action` columns are present and empty, ready for review.
- **FAIL:** The file is in an uncontrolled location or lacks the review columns — re-run Step 6 and move
  it into the controlled store.

## Gate 9 — The recurring export runs unattended (after Best Practices)

- **Do:** After scheduling, trigger **`AGBINV – Monthly Agent Inventory Export`** once manually.
- **PASS:** A fresh dated register appears in `C:\AgentGovernance\Exports` with no interactive sign-in.
- **FAIL:** The task prompts for credentials or errors — app-only auth (R3) is not configured; fix the
  certificate/consent and re-test.

## Gate 10 — Government cloud behaves as documented (if applicable)

- **Do:** In a GCC High/DoD tenant, run the preflight with `-Environment USGov`/`USGovDoD`.
- **PASS:** The preflight reports the Package API is unavailable in that cloud and directs you to Path A;
  the admin-center export produces the inventory.
- **FAIL:** You assumed Path B would work in Government and treated its failure as a permissions bug —
  re-read R7 and use Path A. **Verify for GCC High.**
