# Global Requirements — Copilot category

These requirements are common to **every** solution in the **Copilot** category. They sit once at the
category level; each solution's own `02-requirements.md` adds the requirements specific to that
solution. Each item follows the house pattern: **Description / Why required / How to verify / How to
implement if missing.**

## GC1 — A Microsoft 365 tenant with Microsoft 365 Copilot enabled

- **Description:** An active Microsoft 365 tenant in which Microsoft 365 Copilot (and, where relevant,
  the agent surfaces) is turned on.
- **Why required:** Agents, Copilot admin surfaces, and the Copilot Graph APIs only exist in a tenant
  where Copilot is provisioned.
- **How to verify:** Sign in to the **Microsoft 365 admin center** (`admin.microsoft.com`) and confirm
  **Copilot** appears in the left navigation, and **Billing** > **Licenses** shows a Microsoft 365
  Copilot subscription.
- **How to implement if missing:** Acquire and assign Microsoft 365 Copilot licensing before proceeding;
  Copilot governance tasks have no meaning until Copilot is present.

## GC2 — A qualifying administrator role (least privilege)

- **Description:** The person performing Copilot governance work holds an appropriate Entra admin role —
  and no more than needed.
- **Why required:** Copilot admin surfaces and APIs are gated to specific roles; over-privileged
  accounts violate least privilege and audit expectations.
- **How to verify:** **Microsoft Entra admin center** (`entra.microsoft.com`) > **Roles &
  administrators** > confirm the account's assigned roles.
- **How to implement if missing:** Assign the least-privileged role the task requires (this solution
  names the exact roles in R1) via **Roles & administrators** > (role) > **Add assignments**, ideally
  time-bound through Privileged Identity Management.

## GC3 — Microsoft Graph PowerShell SDK (for the scriptable tasks)

- **Description:** The **Microsoft.Graph** PowerShell modules installed on the workstation used to run
  any Graph-based script.
- **Why required:** Every script in the Copilot solutions authenticates with `Connect-MgGraph` and calls
  Graph through the SDK.
- **How to verify:** In PowerShell 7+, run `Get-Module Microsoft.Graph -ListAvailable`.
- **How to implement if missing:** `Install-Module Microsoft.Graph -Scope CurrentUser` (and install
  **PowerShell 7+** first if needed).

## GC4 — Awareness that Copilot admin/API features are preview-volatile

- **Description:** Copilot admin controls and Graph endpoints evolve quickly; some are in preview or
  roll out tenant-by-tenant.
- **Why required:** A step that is correct today can change; assuming stability leads to wrong
  conclusions when a call fails only because a feature has not reached your tenant.
- **How to verify:** Cross-check any Copilot admin/API step against current Microsoft Learn before
  relying on it in production; note the API version (`v1.0` vs `beta`).
- **How to implement if missing:** Treat preview-flagged behavior as "verify against current Microsoft
  documentation" and prefer `v1.0` endpoints over `beta` where both exist.

## GC5 — Sovereign-cloud awareness (Commercial vs Government)

- **Description:** Knowledge of whether your tenant is Commercial (`graph.microsoft.com`,
  `admin.microsoft.com`) or a US Government cloud (GCC High `graph.microsoft.us` /
  `portal.office365.us`; DoD `dod-graph.microsoft.us`), and that Copilot/agent feature parity differs.
- **Why required:** Endpoints and feature availability differ by cloud; several Copilot APIs are
  Global-only.
- **How to verify:** Confirm the tenant's cloud instance in the admin center URL and in
  `(Get-MgContext).Environment` after connecting.
- **How to implement if missing:** Select the correct `-Environment` for scripts and consult the
  per-solution government section for parity caveats.
