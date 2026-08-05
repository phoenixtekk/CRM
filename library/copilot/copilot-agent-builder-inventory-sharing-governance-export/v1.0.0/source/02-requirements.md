# Requirements

Each requirement follows the house pattern: **Description / Why required / How to verify / How to
implement if missing.** Confirm every item before you run the export — most "blocked or failed"
Graph requests trace directly to R1, R2, R3, or R4.

> **API-version and rollout note (read first).** The Copilot Package Management API used in Path B
> (`/copilot/admin/catalog/packages`) released from preview very recently and is documented in **both
> `v1.0` and `beta`**. Prefer `v1.0` in production. Several facts below (the Agent 365 entitlement, the
> tenant rollout, national-cloud availability) are **preview-volatile — verify each against current
> Microsoft Learn for your tenant** rather than assuming. Where a fact is uncertain, this document says
> so explicitly.

## R1 — A qualifying administrator role for the Copilot admin surfaces and the Package API

- **Description:** The signed-in identity must hold one of the admin roles that Microsoft authorizes for
  the Agent Registry and the Copilot Package Management API. Documented qualifying roles include
  **Global Administrator**, **AI Administrator**, **Cloud Application Administrator**, **Application
  Administrator**, and **Copilot Administrator**. The Agent Registry documentation states the Graph API
  "works with the **AI Administrator** role" — **AI Administrator** is the least-privileged practical
  choice for read-only governance.
- **Why required:** The API authorizes on the caller's role *in addition to* the OAuth scope. A correct
  token with an unqualified role returns **403**.
- **How to verify:** **Microsoft Entra admin center** > **Roles & administrators** > search **AI
  Administrator** (or Global Administrator) > confirm your account is listed. After connecting in
  PowerShell, you can also confirm effective access with the preflight script (R-flow in
  Implementation Step 2).
- **How to implement if missing:** Assign **AI Administrator** to the governance account:
  **Roles & administrators** > **AI Administrator** > **Add assignments** > select the account > (prefer
  a time-bound, eligible assignment via **Privileged Identity Management**). Re-sign-in so the new role
  is in the token.

## R2 — The Graph permission scope `CopilotPackages.Read.All`, with admin consent

- **Description:** Path B calls require the delegated (or application) permission **`CopilotPackages.Read.All`**
  (read-only). The read/write scope `CopilotPackages.ReadWrite.All` exists but is **not needed** for
  inventory and sharing export — stay read-only. Delegated is supported; application permission is also
  documented as supported for unattended runs.
- **Why required:** Without the scope on the access token (and tenant admin consent granted for it), the
  API returns **403** before it ever looks at the data. This is the single most common cause of the
  customer's failure.
- **How to verify:** Decode the access token (e.g. paste into `jwt.ms`) and confirm `CopilotPackages.Read.All`
  is present in the `scp` (delegated) or `roles` (application) claim. The preflight script also reports
  the scopes on the current context.
- **How to implement if missing:**
  - **Interactive/delegated (fastest):** the scripts request the scope at `Connect-MgGraph -Scopes
    CopilotPackages.Read.All`; a Global Administrator must **consent** on first use (or pre-consent it).
  - **Unattended/application:** register an Entra app (see R3), add **`CopilotPackages.Read.All`** as an
    **Application** permission under **API permissions** > **Microsoft Graph**, then **Grant admin
    consent for <tenant>**.

## R3 — (Path B, unattended only) An Entra app registration for app-only runs

- **Description:** For a scheduled, unattended export you register an Entra application named
  **`AGBINV – Agent Governance – Graph Reader`** with the **application** permission
  `CopilotPackages.Read.All` and a certificate credential.
- **Why required:** The recurring monthly export (Best Practices) runs with no signed-in user; app-only
  auth with a certificate is the supported unattended pattern. Interactive runs do **not** need this.
- **How to verify:** **Entra admin center** > **App registrations** > confirm **`AGBINV – Agent
  Governance – Graph Reader`** exists, has `CopilotPackages.Read.All` (Application) with a green
  "Granted" consent state, and a valid certificate under **Certificates & secrets**.
- **How to implement if missing:** **App registrations** > **New registration** > name it
  **`AGBINV – Agent Governance – Graph Reader`** > **Register**; add the application permission and grant
  consent (R2); upload a certificate (prefer certificate over client secret). Record the
  **Application (client) ID** and **Directory (tenant) ID** for the scripts.

## R4 — The Microsoft Agent 365 entitlement for the Package Management API (VERIFY for your tenant)

- **Description:** **Current** Microsoft Learn for both the list and detail calls states: *"Access to
  the Package Management API requires a Microsoft Agent 365 license."* Earlier preview guidance had
  implied only a Copilot admin feature flag was required. Because this changed as the API released, the
  entitlement is a **must-verify** item, not a settled fact.
- **Why required:** If the entitlement is truly enforced and absent, Path B returns **403** even with a
  perfect role and scope — which can look identical to a permissions problem. Distinguishing the two is
  in Troubleshooting T3.
- **How to verify:** **Microsoft 365 admin center** > **Billing** > **Licenses** / **Subscriptions** —
  look for a **Microsoft Agent 365** (or agent-management) subscription. Then run the **preflight
  script**: a clean `403` on `/copilot/admin/catalog/packages` *after* R1/R2 are confirmed points at
  this entitlement (or R6 rollout). *(Verify against current Microsoft documentation — Microsoft may
  adjust this entitlement as the API matures.)*
- **How to implement if missing:** Two options. **(a)** Acquire the Agent 365 entitlement if your
  organization wants the programmatic path. **(b)** Use **Path A** — the Microsoft 365 admin center
  Agent Registry **Export to CSV** — which produces the inventory **without** the Agent 365 entitlement.
  You told us you already ruled Agent 365 out; if that is final, **Path A is your supported route to the
  inventory today**, and Path B remains available for the sharing detail only if/when the entitlement is
  in place.

## R5 — Agent Builder enabled and in use in the tenant (the population to inventory)

- **Description:** Users must actually be creating and sharing Agent Builder agents, and Agent Builder
  must not be disabled by policy — otherwise the inventory is legitimately empty.
- **Why required:** An empty result is only correct if there are genuinely no Agent Builder agents; you
  need to know which it is.
- **How to verify:** **Microsoft 365 admin center** > **Agents** > **All agents** > **Registry** — look
  for entries under **Shared by creator** with **Platform** = *Microsoft 365 Copilot Agent Builder*. In
  Copilot Chat, **New agent** should be available to a test user.
- **How to implement if missing:** If Agent Builder is intentionally disabled, that is a valid governance
  state (record it). If it should be available, review the agent controls in **Microsoft 365 admin
  center** > **Copilot** / **Integrated apps** agent settings.

## R6 — The Package Management API rolled out to your tenant (Path B; VERIFY)

- **Description:** The API released tenant-by-tenant. A tenant that has not yet received it returns
  **404** (endpoint not present) or **403** (backend feature not enabled) regardless of role/scope.
- **Why required:** This is indistinguishable from a permissions error without a deliberate test — and
  no tenant-side toggle forces earlier availability.
- **How to verify:** Run the **preflight script**. A `404` on the list endpoint with a valid token and
  qualifying role indicates the API is not present for the tenant; a `200` confirms it is live.
- **How to implement if missing:** There is no self-service enablement — use **Path A** in the meantime
  and re-test Path B after Microsoft confirms general availability for your cloud/tenant. *(Verify
  current rollout state on Microsoft Learn / the Microsoft 365 Message Center — MC1173195 tracks this
  API.)*

## R7 — Cloud instance and endpoint selection (Commercial vs US Government)

- **Description:** Know your cloud and target the right endpoints. Path B's Package Management API is
  documented as **Global-only** — **not** available in **US Government L4 (GCC High)**, **US Government
  L5 (DoD)**, or **China (21Vianet)**.
- **Why required:** In a Government cloud, Path B will not return data because the API is not deployed
  there — not because of a permissions problem. Using the wrong Graph host also fails authentication.
- **How to verify:** Confirm your admin-center URL (`admin.microsoft.com` Commercial vs
  `portal.office365.us` GCC High) and, after connecting, `(Get-MgContext).Environment`.
- **How to implement if missing / Government substitution table:**

  | Setting | Commercial (Global) | US Gov GCC High (L4) | US Gov DoD (L5) |
  |---|---|---|---|
  | Graph host | `graph.microsoft.com` | `graph.microsoft.us` | `dod-graph.microsoft.us` |
  | `Connect-MgGraph -Environment` | `Global` | `USGov` | `USGovDoD` |
  | M365 admin center | `admin.microsoft.com` | `portal.office365.us` | `portal.office365.us` |
  | **Package Management API (Path B)** | **Available** | **Not available — verify for GCC High** | **Not available** |
  | **Inventory method** | Path A or Path B | **Path A (admin center export)** | **Path A (admin center export)** |

  In Government clouds, use **Path A**. Also verify that **Agent Builder itself** is available in your
  Government cloud before expecting any agents to inventory — agent feature parity in GCC High/DoD is
  incomplete. **Do not assume GCC High parity — verify for GCC High.**

## R8 — A workstation with PowerShell 7+ and the Microsoft Graph SDK (Path B)

- **Description:** A machine running **PowerShell 7+** with the **Microsoft.Graph** modules to run the
  scripts.
- **Why required:** The scripts use `Connect-MgGraph` / `Invoke-MgGraphRequest`.
- **How to verify:** `$PSVersionTable.PSVersion` (≥ 7.0) and `Get-Module Microsoft.Graph -ListAvailable`.
- **How to implement if missing:** Install PowerShell 7+, then `Install-Module Microsoft.Graph -Scope
  CurrentUser`.

## R9 — A storage location for the exported register and a review owner

- **Description:** A controlled folder — **`C:\AgentGovernance\Exports`** on the run host (or a governed
  SharePoint/Teams location) — to hold the exported CSV/JSON, and a **named owner** who reviews the
  **`Agent Builder Governance Register`**.
- **Why required:** The export lists people and groups (personal-adjacent data); it must live somewhere
  access-controlled and be owned by someone accountable for acting on it.
- **How to verify:** The folder exists and is restricted to the governance team; a named owner is
  recorded in the register header.
- **How to implement if missing:** Create **`C:\AgentGovernance\Exports`** (the scripts create it if
  absent) or a permission-scoped SharePoint library; assign the register owner in your governance model.
