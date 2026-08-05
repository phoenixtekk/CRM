# Requirements

These are the prerequisites to **call** the Graph Copilot admin (beta) endpoints and to run this
runbook's diagnostics. Confirm each before you start; missing any one of them is itself one of the
failure causes the playbook diagnoses. Every entry follows **Description / Why / Verify /
Implement-if-missing.**

> **Sources verified on the build date** (all `learn.microsoft.com`): the Package Management API
> overview and its `copilotpackages-list` / `copilotpackagedetail-get` reference pages; the
> `copilotpolicysetting-get` reference; the *Microsoft 365 Copilot APIs overview* and *Security and
> authentication for Microsoft 365 Copilot APIs* concept pages; the Microsoft Graph *permissions
> reference*, *throttling guidance*, and *national cloud deployments* pages. Because this is a beta
> surface, re-verify anything marked **"beta — verify against current Microsoft documentation."**

---

## R1. Microsoft Graph tooling (PowerShell SDK or an equivalent HTTP client)

**Description:** The **Microsoft Graph PowerShell SDK** (`Microsoft.Graph` and, for beta paths, the
`Microsoft.Graph.Beta` modules), or any HTTP client (Graph Explorer, `curl`, Postman) that can send a
bearer token to `https://graph.microsoft.com`. This runbook's scripts use `Connect-MgGraph` and
`Invoke-MgGraphRequest`.

**Why:** The Copilot admin endpoints are ordinary Microsoft Graph REST endpoints; you reach them with
the same tooling and token flow as any other Graph call. `Invoke-MgGraphRequest` lets you call a raw
beta path (including one with no typed SDK cmdlet) and read the **real** status code and error body —
which is exactly what diagnosis needs.

**Verify:** `Get-Module Microsoft.Graph -ListAvailable` returns a version; `Get-Command
Connect-MgGraph` resolves.

**Implement if missing:** `Install-Module Microsoft.Graph -Scope CurrentUser` and
`Install-Module Microsoft.Graph.Beta -Scope CurrentUser`. Update an old SDK with
`Update-Module Microsoft.Graph`. (Graph Explorer at `https://developer.microsoft.com/graph/graph-explorer`
is a good zero-install way to reproduce a call interactively.)

---

## R2. A signed-in administrator (delegated user context)

**Description:** A **work or school account** you can sign in with interactively — **not** an
application-only (client-credentials) identity — that holds a sufficient **admin role** (R4).

**Why:** The Copilot admin endpoints authenticate and authorize the **signed-in user**. In current
behavior, the package catalog endpoint **rejects application-only tokens** with
`403 Forbidden` / *"Access is denied. User context is required by the requested resource."* even when
the app has the `CopilotPackages.Read.All` **application** permission granted — despite the reference
page listing Application permissions as supported. The policy-settings endpoint documents **Application
as "Not supported"** outright. **Treat these endpoints as delegated-only.** *(Beta — verify against
current Microsoft documentation; the documented-vs-enforced permission model has been changing.)*

**Verify:** After `Connect-MgGraph`, run `(Get-MgContext).Account` — it must show a **user** UPN, not
a service-principal/app id. `(Get-MgContext).AuthType` should be `Delegated`.

**Implement if missing:** Sign in interactively:
`Connect-MgGraph -Scopes "CopilotPackages.Read.All" -Environment Global` (or device-code:
`Connect-MgGraph -UseDeviceAuthentication`). Do not use `-ClientSecret` / certificate app-only auth for
these endpoints.

---

## R3. The correct permission scopes in the token

**Description:** The token you present must **contain** the scope the endpoint requires:

| Endpoint | Least-privileged delegated scope | Higher-privileged | App permission |
|---|---|---|---|
| `catalog/packages` (list) and `catalog/packages/{id}` (read) | `CopilotPackages.Read.All` | `CopilotPackages.ReadWrite.All` | Documented but **not reliably enforced** — treat as delegated-only (R2) |
| `catalog/packages/{id}` block/unblock/reassign/update (write, preview) | `CopilotPackages.ReadWrite.All` | — | Same caveat |
| `policySettings/{id}` (read) | `CopilotPolicySettings.Read` | `CopilotPolicySettings.ReadWrite` | **Not supported** |
| `reports/getMicrosoft365CopilotUsageUserDetail` (GA fallback) | `Reports.Read.All` | — | `Reports.Read.All` |

**Why:** A token missing the scope yields `403 Forbidden`. The scope names are **exact** — do not
guess or abbreviate them. Note that `CopilotPackages.*` and `CopilotPolicySettings.*` are **different**
scope families for **different** endpoints; a token good for one is not good for the other.

**Verify:** After connecting, `(Get-MgContext).Scopes` lists the scopes actually in your token. The
runbook's `CPADMDX-Resolve-Scopes.ps1` reports **have vs need** for the endpoint you name. (You can
also paste the access token into `https://jwt.ms` and read the `scp` claim — never paste a token
anywhere else.)

**Implement if missing:** Reconnect requesting the scope, e.g.
`Connect-MgGraph -Scopes "CopilotPackages.Read.All","CopilotPolicySettings.Read"`. If the tenant blocks
user consent, you also need R5 (admin consent).

---

## R4. A sufficient administrator role (Entra directory role)

**Description:** The signed-in user must hold an admin role that authorizes tenant-wide Copilot/agent
administration. The **least-privileged** built-in role for Microsoft 365 Copilot and Microsoft Agent
365 administration is **AI Administrator**; **Global Administrator** is the superset that always
satisfies it.

**Why:** Even with the right scope in the token (R3), a **delegated** call to a tenant-wide admin
resource is refused if the *user* lacks an admin role — a `403 Forbidden`. Scope (consent) and role
(assignment) are **independent** gates; you need both. *(Microsoft's Graph reference pages for the
package endpoints do not name an exact directory role; **AI Administrator / Global Administrator** is
the documented role for managing agents in the Microsoft 365 admin center. **Beta — verify the exact
role the Graph endpoint honors against current Microsoft documentation.**)*

**Verify:** Entra admin center → **Roles and administrators** → search the user; or the runbook's
`CPADMDX-Preflight.ps1` reports the user's directory-role memberships (via
`GET /me/memberOf/microsoft.graph.directoryRole`).

**Implement if missing:** Assign **AI Administrator** (preferred, least privilege) to the operator in
Entra → **Roles and administrators** → *AI Administrator* → **Add assignments**; reserve **Global
Administrator** for people who genuinely need tenant-wide control. Allow for role-activation delay if
the role is PIM-eligible rather than active.

---

## R5. Admin consent granted for the scope in the tenant

**Description:** The `CopilotPackages.*` and `CopilotPolicySettings.*` `.All`/admin scopes require
**admin consent** in the tenant for the app you sign in through (for interactive SDK use, that app is
**Microsoft Graph Command Line Tools**, appId `14d82eec-204b-4c2f-b7e8-296a70dad67c`).

**Why:** If the tenant disables user consent and no admin has consented, the sign-in either cannot
grant the scope (so R3 fails) or Graph returns `403`. Consent is how a scope actually lands in a token.

**Verify:** Entra → **Enterprise applications** → *Microsoft Graph Command Line Tools* → **Permissions**
shows the Copilot scopes as **granted for the organization**; or attempt `Connect-MgGraph -Scopes ...`
and read whether consent was blocked.

**Implement if missing:** A Global Administrator grants admin consent once — either at the interactive
consent prompt (**Consent on behalf of your organization**) or in Entra → the app → **Grant admin
consent**. For a custom app registration, grant the delegated Copilot scopes on its **API permissions**
blade and click **Grant admin consent**.

---

## R6. The correct cloud (sovereign-cloud endpoint) — and its availability limit

**Description:** Target the Graph endpoint for **your** cloud:

| Cloud | Graph host | `Connect-MgGraph -Environment` | Copilot admin beta available? |
|---|---|---|---|
| Commercial / Global | `graph.microsoft.com` | `Global` | **Yes** |
| US Gov GCC High | `graph.microsoft.us` | `USGov` | **No** (Global-only today) |
| US Gov DoD | `dod-graph.microsoft.us` | `USGovDoD` | **No** (Global-only today) |
| China (21Vianet) | `microsoftgraph.chinacloudapi.cn` | `China` | **No** |

**Why:** A token from one cloud sent to another cloud's host fails authentication (`401`). More
importantly, the **Package Management** and **policy-settings** admin endpoints are published as
**Global-only** — their national-cloud table shows ❌ for US Gov L4, US Gov L5 (DoD), and 21Vianet. In
a Gov tenant the call can therefore fail even when scope, role, consent, and cloud target are all
correct, because the **feature is not offered in that cloud** (Branch F). *(Beta — cloud availability
can change; verify the per-endpoint national-cloud table for GCC High/DoD against current Microsoft
documentation.)*

**Verify:** `(Get-MgContext).Environment` shows the cloud you connected to. The scripts print the
resolved Graph host so you can confirm you hit the intended cloud.

**Implement if missing:** Connect with the matching switch, e.g.
`Connect-MgGraph -Environment USGov -Scopes "CopilotPackages.Read.All"`. If you are in GCC High/DoD and
the endpoint is unavailable there, use the supported fallbacks (`04`-testing and Branch F): admin-center
export, GA endpoints that *are* offered in your cloud, and Purview audit logs.

---

## R7. Microsoft 365 Copilot licensing — and the Agent 365 note

**Description:** A **Microsoft 365 Copilot** license on a qualifying base plan (E3/E5 or equivalent)
for the users whose Copilot data you work with. Separately, Microsoft's **current** Package Management
API docs state: *"Access to the Package Management API requires a Microsoft Agent 365 license."*

**Why:** Copilot API capabilities are gated on Copilot licensing. The **Agent 365** requirement for the
package catalog endpoint is **newer and changed**: the original announcement said *"no additional
license or add-on is required,"* and the reference pages were later updated to require **Agent 365**.
This is exactly the kind of preview-volatile prerequisite to check. **The customer has already ruled
out Agent 365 licensing as their blocker** — so treat this requirement as *acknowledged and excluded*,
and use Branch G only to *confirm* it is not the cause before moving on.

**Verify:** Microsoft 365 admin center → **Billing → Licenses** shows Copilot (and, if applicable,
Agent 365) seats assigned to the relevant users.

**Implement if missing:** Assign the appropriate licenses (out of scope for this runbook to purchase).
If Agent 365 is genuinely required by your target endpoint and you do not have it, that is a **product
limitation for you today** (Branch J), not a code bug — pursue the supported fallback. *(Beta — verify
the current license requirement on the endpoint's reference page.)*

---

## R8. Tenant preview enablement (feature flighting)

**Description:** The beta Copilot admin endpoints roll out **tenant-by-tenant**. Your tenant must be
**flighted** for the specific endpoint.

**Why:** A correctly-formed, correctly-authorized call can still return `403 Forbidden` / *"Access is
denied to the requested resource."* or `404` purely because the preview feature has not reached your
tenant. Multiple tenants report this on Microsoft Q&A for `catalog/packages`. There is no self-service
switch — it is Microsoft-side flighting.

**Verify:** Compare the same call in a tenant known to be enabled, or confirm via the Microsoft 365
admin center whether the **Agents** / Agent Registry surface (which the API mirrors) is present. If the
UI surface is absent, the API is likely not flighted either.

**Implement if missing:** Wait for the rollout, raise a Microsoft support case for eligibility, and in
the meantime use the supported fallbacks (Branch F/J). Do not keep retrying a flighting gap in a tight
loop — it will not change until Microsoft enables it.

---

## R9. A named diagnostic evidence folder and output file

**Description:** A working folder for the diagnostic outputs this runbook produces. Name it exactly
**`CPADMDX-Diagnostics`**, and have the scripts write their summary to
**`CPADMDX-Findings.json`** (and a human-readable **`CPADMDX-Findings.txt`**) inside it.

**Why:** Diagnosis is only useful if it is captured. Reusing one fixed folder and file name keeps
evidence together across preflight, probe, scope-resolution, and fallback tests, and gives you a single
artifact to attach to a Microsoft support case. Every script and every testing gate in this solution
refers to **`CPADMDX-Diagnostics\CPADMDX-Findings.json`** by that exact name.

**Verify:** The folder exists and `CPADMDX-Findings.json` is written after a run.

**Implement if missing:** `New-Item -ItemType Directory -Path .\CPADMDX-Diagnostics` (the
`CPADMDX-Report-Findings.ps1` script creates it if absent).

---

See `global-requirements-copilot.md` for the category-wide Copilot prerequisites (tenant, licensing,
identity, data readiness, roles, governance) that apply to every Copilot solution.
