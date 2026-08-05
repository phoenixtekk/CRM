# Implementation

Follow these steps in order. The build produces one artifact — the **`Agent Builder Governance
Register`** — by whichever path your tenant supports. Every object you create is named; reuse the exact
name verbatim in Testing, Troubleshooting, and the scripts.

> **Naming used throughout:** Entra app registration **`AGBINV – Agent Governance – Graph Reader`**;
> export folder **`C:\AgentGovernance\Exports`**; output register **`Agent Builder Governance
> Register`** (CSV `AgentBuilder-Governance-Register_<date>.csv`); scheduled task **`AGBINV – Monthly
> Agent Inventory Export`**.

## Step 0 — Choose your cloud and your path

1. Confirm your cloud (R7). For Government clouds, the Graph Package Management API is not available —
   you will use **Path A**.
2. Choose the path:
   - **Path A — Microsoft 365 admin center export** (no code, no Agent 365 entitlement). Use this if
     Agent 365 is ruled out (your case), if you are in a Government cloud, or if you just want the
     inventory quickly. Steps 1 and 5–8.
   - **Path B — Microsoft Graph Package Management API** (scriptable, includes granular
     `allowedUsersAndGroups` sharing). Use this if the Agent 365 entitlement and API rollout are in
     place and you want a recurring, complete register. Steps 1–8.
3. You may run **both**: Path A for the inventory baseline, Path B to enrich it with resolved sharing.

## Step 1 — Confirm prerequisites

1. Verify R1 (role — **AI Administrator** is the least-privileged practical choice), R2 (scope
   `CopilotPackages.Read.All` with consent, Path B), R4 (Agent 365 entitlement — verify), R5 (Agent
   Builder in use), R7 (cloud), and R8/R9 (workstation, storage).
2. Create the export folder **`C:\AgentGovernance\Exports`** if it does not exist (the scripts create
   it automatically, but creating it now lets you set folder permissions first per R9).

## Step 2 — (Path B) Run the preflight and decode the result

This is the step that answers "why was my request blocked or failed."

1. On the run host, open **PowerShell 7+**.
2. Run the preflight, targeting your cloud:
   ```
   pwsh -File .\AGBINV-Connect-Preflight.ps1 -Environment Global
   ```
   (Use `-Environment USGov` or `-Environment USGovDoD` for Government clouds.)
3. Read its verdict. The preflight signs in, reports the scopes and roles on your context, then calls
   `GET /copilot/admin/catalog/packages?$top=1` and **decodes the response**:
   - **`200 OK`** — the API is live for your tenant and your identity is authorized. Proceed to Step 3.
   - **`401`** — token/authentication problem (wrong cloud audience, expired token). Re-connect; confirm
     `-Environment` matches your tenant.
   - **`403`** — authorized identity but access denied. The preflight prints the likely cause in
     priority order: (1) missing `CopilotPackages.Read.All` scope / no admin consent → fix R2;
     (2) role not qualifying → fix R1; (3) Agent 365 entitlement not present → R4; (4) tenant feature
     not enabled → R6.
   - **`404`** — the API is not present for your tenant/cloud (R6 rollout, or a Government cloud where
     it is unavailable) → use **Path A**.
   Troubleshooting T2–T7 expand each branch.

## Step 3 — (Path B) List agents, filtered to Agent Builder only

1. Run the inventory export, which lists packages and **filters to Agent Builder declarative agents**,
   excluding Copilot Studio:
   ```
   pwsh -File .\AGBINV-Export-AgentInventory.ps1 -Environment Global `
        -OutputPath C:\AgentGovernance\Exports
   ```
2. Internally this calls
   `GET /copilot/admin/catalog/packages?$filter=platform eq 'Microsoft 365 Copilot Agent Builder'`
   and additionally keeps only packages whose `elementTypes` contains `declarativeAgent`. It writes one
   row per agent with: `Id`, `DisplayName`, `Type`, `Publisher`, `Platform`, `ElementTypes`, `IsBlocked`,
   `AvailableTo`, `DeployedTo`, `LastModifiedDateTime`, `Version`.
3. The output file is **`AgentBuilder-Inventory_<date>.csv`** — the inventory backbone. Note that the
   list call gives `AvailableTo`/`DeployedTo` only as `all`/`some`/`none`; the *who* comes in Step 4.

> **Why the filter matters.** Without the `platform` filter you would also capture Copilot Studio
> agents (`platform` = `Copilot Studio`) and Microsoft/partner agents. The filter is what keeps the
> register scoped to Agent Builder, so it does not overlap the governance your Copilot Studio approval
> gates already provide.

## Step 4 — (Path B) Resolve each agent's sharing to users and groups

1. Run the sharing export, which calls the **per-agent detail** endpoint for each agent from Step 3 and
   reads **`allowedUsersAndGroups`**:
   ```
   pwsh -File .\AGBINV-Export-AgentSharing.ps1 -Environment Global `
        -InventoryCsv C:\AgentGovernance\Exports\AgentBuilder-Inventory_<date>.csv `
        -OutputPath C:\AgentGovernance\Exports
   ```
2. For each agent it calls `GET /copilot/admin/catalog/packages/{id}`, reads `allowedUsersAndGroups`
   (each entry is `{ resourceId, resourceType }` where `resourceType` is `user` or `group`), and
   **resolves** each `resourceId` to a display name / UPN via `GET /users/{id}` or `GET /groups/{id}`.
   It also captures `acquireUsersAndGroups`, `availableTo`, `deployedTo`, and `sensitivity`.
3. The output file is **`AgentBuilder-Sharing_<date>.csv`** — one row per **agent × recipient**, with
   `AgentId`, `AgentName`, `RecipientType` (User/Group), `RecipientId`, `RecipientName`, `RecipientUpnOrMail`.

> **Honest note on the summary fields.** If an agent's `availableTo` is `all` (shared with **Anyone in
> your organization**), there may be no explicit per-user entries to resolve — the register should record
> that agent as **org-wide shared**, which is itself the highest-attention governance state. The script
> labels these explicitly rather than showing an empty recipient list.

## Step 5 — (Path A) Export the inventory from the Microsoft 365 admin center

Use this path when Agent 365 is ruled out, in Government clouds, or as an independent cross-check.

1. Sign in to the **Microsoft 365 admin center** (`admin.microsoft.com`; GCC High:
   `portal.office365.us`).
2. In the left navigation, select **Agents** > **All agents** > **Registry**.
3. Select **Filter**, and under **Platform** choose **Microsoft 365 Copilot Agent Builder** (deselect
   Copilot Studio and others). Optionally add **Publisher type** = *Shared by creator* to focus on
   user-shared agents.
4. Select **Export**. Choose scope **Filtered agents** (so you export only the Agent Builder set you
   filtered to). Save the CSV into **`C:\AgentGovernance\Exports`**.
5. The exported CSV includes name, status, channel, created/last-modified dates, publisher, publisher
   type, version, **owner**, description, platform, and more (30-plus fields). It gives you owner and
   inventory; it does **not** reliably enumerate the individual shared-with recipients — that granular
   list comes from Path B's `allowedUsersAndGroups`. Record this limitation in the register.

## Step 6 — Build the Agent Builder Governance Register

1. Run the register generator to merge the inventory and sharing exports into the review artifact:
   ```
   pwsh -File .\AGBINV-Report-GovernanceRegister.ps1 `
        -InventoryCsv C:\AgentGovernance\Exports\AgentBuilder-Inventory_<date>.csv `
        -SharingCsv   C:\AgentGovernance\Exports\AgentBuilder-Sharing_<date>.csv `
        -OutputPath   C:\AgentGovernance\Exports
   ```
   (Path A only: pass the admin-center CSV to `-InventoryCsv` and omit `-SharingCsv`; the register will
   carry inventory + owner, with sharing marked *"admin-center export — recipients not enumerated."*)
2. The generator writes **`AgentBuilder-Governance-Register_<date>.csv`** — one row per agent with:
   agent name, owner, status/publish state, platform, created/modified, **sharing scope** (Org-wide /
   Specific / Only owner), **shared-with recipients** (semicolon-joined names, Path B), and blank review
   columns: **`OwnerConfirmed`**, **`SharingApproved`**, **`Action`** (Keep / Restrict sharing /
   Reassign owner / Block / Delete), **`ReviewedBy`**, **`ReviewedOn`**.
3. This CSV is the **`Agent Builder Governance Register`**. Store it in the R9 location.

## Step 7 — Pilot: reconcile one slice before trusting the whole

1. Pick a small, known set — e.g. agents owned by your own pilot user or a single department.
2. Open Copilot Chat as (or with) an agent owner and note, for one agent, exactly who it is shared with
   (**Share** dialog → recipients).
3. Confirm that same agent's row in the register lists the identical recipients (Path B) or at least the
   correct owner and status (Path A). Resolve any mismatch now (usually a delegated-permission gap or a
   filter that dropped/added the wrong platform) — this is the trust gate.

## Step 8 — Expand and record the governance decisions

1. Remove the pilot filter and export the full tenant set (Steps 3–6, or Step 5 for Path A).
2. Have the register **owner** review each row: confirm the owner, approve or challenge the sharing
   scope (org-wide shares get first attention), and set **`Action`**.
3. Execute approved actions in the **Microsoft 365 admin center** (block, reassign owner) or by asking
   the agent owner to change sharing in Copilot; record the decision in the register.
4. Schedule the recurring export (see Best Practices) so the register stays current — the scheduled task
   is named **`AGBINV – Monthly Agent Inventory Export`**.
