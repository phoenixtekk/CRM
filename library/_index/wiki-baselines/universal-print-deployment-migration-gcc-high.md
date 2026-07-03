# Universal Print Deployment & Print-Server Retirement — Government (GCC High)

> **Version 1.0.0** · Category: Infrastructure · Solution code: UPRTG

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Universal Print Deployment & Print-Server Retirement (Government / GCC High)

## The opportunity

On-premises Windows print servers are a recurring cost and risk: OS patching, per-site hardware,
driver management, and single points of failure. **Universal Print** — Microsoft's cloud print
service — removes that infrastructure by publishing printers from Microsoft Entra ID and
delivering print jobs through the cloud to managed Windows devices. This solution deploys it on a
**GCC High** tenant and retires the legacy print servers, safely.

## Why a Government (GCC High) edition is different

Universal Print in the US sovereign cloud is **not** the Commercial service with a different
sign-in. It runs on dedicated GCC High infrastructure with **different portal URLs, different
service endpoints, different Graph endpoints, and different licensing** — and it has a few
feature-parity gaps versus Commercial. Configuring a GCC High tenant with Commercial steps causes
**silent failures**. This edition corrects every portal (`*.us`), every endpoint
(`*.print.azure.us`), and every script (`-Environment USGov`).

## Two availability facts leadership should know

- **Universal Print is generally available in GCC and GCC High** — this deployment is fully
  supported for a GCC High tenant.
- **Universal Print is not available in DoD** at this time. Tenants in the DoD cloud cannot yet
  deploy it. (Source: Microsoft. *Verify against the Microsoft 365 roadmap.*)
- **Some features lag in GCC High** — notably **Delegated Administration** and **macOS
  printing** — so the deployment is designed to work around those gaps rather than assume them.

## Approach

The deployment follows a disciplined, pilot-first model with a **gate at every phase**:

**Assess → Configure → Pilot → Validate → Expand.**

No print server is retired until every printer it hosted is proven working in Universal Print.
Five bundled PowerShell scripts (all US-Gov-Graph aware) automate discovery, validation,
reporting, and safe (`-WhatIf`-first) remediation so the work is repeatable and auditable — and
executable by a novice-to-intermediate administrator.

## Value

- **Eliminates print-server infrastructure** — patching, hardware refresh, and per-site
  management cost.
- **Correct the first time on GCC High** — no rework from Commercial steps that silently fail.
- **Low-risk rollout** — pilot and wave gates with rollback; servers retired only after proof.
- **Compliance-aligned** — Universal Print is FedRAMP-certified via Office 365 and runs on the US
  sovereign cloud with TLS 1.2 encryption (verify accreditation scope for your tenant).
- **A fraction of consulting cost** — self-guided, tested, and reusable.

## Bottom line

Universal Print deployed correctly on GCC High — right portals, right endpoints, parity gaps
handled — and proven on a pilot before you scale, so legacy print servers are retired without an
outage.


---


# Solution Overview — Universal Print Deployment & Print-Server Retirement (Government / GCC High)

## Availability up front — read this first

**Universal Print IS available in GCC High.** Microsoft announced **general availability of
Universal Print in GCC and GCC High**, and the service is documented as running on the US
sovereign cloud with its own `*.print.azure.us` service endpoints and US Gov identity
(`login.microsoftonline.us`). This solution is written for a **GCC High** tenant.

Two availability facts you must internalize before you begin — both are current Microsoft
statements (see `gcc-high-parity-notes.md` for citations):

- **DoD is NOT supported.** Universal Print is *not* available in the Microsoft 365 **DoD**
  cloud at time of authoring. If your tenant is DoD (not GCC High), **stop** — this solution
  does not apply, and there is no supported Universal Print deployment for you yet. *Verify for
  GCC High/DoD before scoping.*
- **GCC High has feature-parity gaps vs Commercial.** Microsoft states it is "aiming for
  feature parity," but at authoring time specific features lag in GCC High — notably
  **Delegated Administration** ("coming to GCC High soon") and **macOS client printing** ("not
  yet available for GCC High"). These are called out inline where they matter and consolidated
  in `gcc-high-parity-notes.md`. Do not assume a Commercial how-to step works unchanged.

If you were handed the Commercial edition of this solution by mistake, it will point you at
`portal.azure.com`, `graph.microsoft.com`, and `login.microsoftonline.com` — **none of which
serve a GCC High tenant.** This edition corrects every portal, endpoint, and Graph environment
for the US sovereign cloud.

## What this solution does

Universal Print is Microsoft's cloud-based print service. It removes the need for on-premises
**Windows print servers**, print-server OS patching, and per-site print infrastructure by
publishing printers from Microsoft Entra ID and delivering print jobs through the cloud to
Entra-joined Windows endpoints. This solution takes a GCC High tenant from "we still run
print servers" to "printers are published in Universal Print, endpoints print through the
cloud, and the legacy print server is retired" — safely, on a pilot-first path, with a
rollback at every gate.

The deployment follows the standard repeatable model used across all Infrastructure
solutions:

**Assess → Configure → Pilot → Validate → Expand**

Each phase has an explicit **gate** — you do not proceed until the prior phase passes its
validation criteria. The five bundled PowerShell scripts (all connecting to **US Gov Graph**
with `-Environment USGov`) automate discovery, validation, reporting, and safe remediation so
a novice administrator can execute the whole sequence and prove each gate.

## The deployment model at a glance

| Phase | Goal | Gate to pass before moving on |
| --- | --- | --- |
| **Assess** | Inventory current print servers, printers, drivers, and per-printer job volume; confirm GCC High licensing and endpoints. | `UPRTG-Discovery.ps1` runs clean; every prerequisite in `02-requirements.md` verified. |
| **Configure** | Enable Universal Print, register the connector, publish and share the first printers, set targeting groups. | Printers appear as **Shared** in the Universal Print portal (`portal.azure.us`). |
| **Pilot** | Add one pilot printer + the pilot security group; users print end-to-end through the cloud. | Pilot users complete real print jobs; `UPRTG-Validation.ps1` passes for the pilot scope. |
| **Validate** | Confirm print success rate, driver behavior, secure release, and reporting for the pilot. | No open Sev-1/Sev-2 issues; sign-off recorded. |
| **Expand** | Roll out remaining printers/sites in waves; retire the legacy print server(s). | Each wave validated before the next; print server decommissioned only after its printers are proven in Universal Print. |

## Commercial vs GCC High — what's different

This is the section that keeps a government tenant from being configured with Commercial
steps that silently fail. Everything below is specific to the **US sovereign cloud**.

| Area | Commercial | GCC High (this edition) |
| --- | --- | --- |
| Azure / Universal Print admin portal | `portal.azure.com` | **`portal.azure.us`** (Azure Government) |
| Microsoft 365 admin center | `admin.microsoft.com` | **`portal.office365.us`** |
| Microsoft Intune / Endpoint admin | `intune.microsoft.com` | **`intune.microsoft.us`** (endpoint.microsoft.us) |
| Microsoft Entra admin | `entra.microsoft.com` | **`entra.microsoft.us`** (or Entra blade in `portal.azure.us`) |
| Sign-in / identity authority | `login.microsoftonline.com` | **`login.microsoftonline.us`** |
| Microsoft Graph endpoint | `graph.microsoft.com` | **`graph.microsoft.us`** |
| Graph PowerShell environment | `-Environment Global` (default) | **`-Environment USGov`** |
| Universal Print service endpoints | `*.print.microsoft.com` | **`*.print.azure.us`** (print, register, discovery, notification, graph) |
| Licensing SKUs | M365 E3/E5, Windows E3/E5 | **G3/G5 Gov** — `SPE_E3_USGOV_GCCHIGH`, `SPE_E5_USGOV_GCCHIGH`, or `Universal_Print_for_GCCHIGH` standalone |
| Windows client support | All supported Windows | **Windows 11 22H2+ native**; Windows 10 / older Win 11 require three registry keys to point at the US Gov authority/Graph (see `03-implementation.md`) |
| Delegated Administration | Available | **Coming to GCC High "soon"** — *verify for GCC High* before designing scoped admin |
| macOS client printing | Available | **Not yet available for GCC High** — *verify for GCC High* |
| DoD availability | N/A | **Universal Print not available in DoD at all** |

Three practical consequences of that table:

1. **Every portal URL in this edition ends in `.us`.** If a screen you land on ends in `.com`,
   you are in the wrong cloud and your GCC High credentials will not work there.
2. **Every script connects with `-Environment USGov`.** A script that omits this authenticates
   against the Commercial identity endpoint and fails for a GCC High account.
3. **Licensing is mandatory for administrators too.** In Government, **all users — including
   the admins who configure Universal Print — must hold an eligible Universal Print license**
   (G3/G5 Gov or the standalone SKU). This is a stricter rule than many admins expect.

## Who this is for

A novice-to-intermediate administrator on a **GCC High** Microsoft 365 tenant who needs to
stand up Universal Print correctly the first time and retire aging print servers without an
outage — and without being tripped up by Commercial documentation that points at the wrong
cloud.

## What you get

- **This overview** and a full **Requirements Guide** (`02-requirements.md`) with verify +
  implement steps for every prerequisite on GCC High.
- A step-by-step **Implementation Guide** (`03-implementation.md`) using the `.us` portals,
  with GCC-High-only caveats placed at the exact step where they bite.
- **Five PowerShell scripts** — Discovery, Validation, Report, Remediation, and
  Set-ScopeTargeting — all US-Gov-Graph aware.
- A **Testing guide** (`05-testing.md`), a **Troubleshooting guide** (`06-troubleshooting.md`),
  **Best practices** (`07-best-practices.md`), a **Deliverables summary** (`08-deliverables-summary.md`),
  an **Executive summary**, and the cited **`gcc-high-parity-notes.md`** parity reference.

## The bottom line

Universal Print deployed correctly on GCC High — right portals, right endpoints, parity gaps
handled — and proven on a pilot before you scale, so the legacy print server is retired only
after its printers work in the cloud.


---


# Requirements Guide — Universal Print on GCC High

Confirm **every** requirement below before you configure anything. The category-level
prerequisites live in `global-requirements-infrastructure.md`; this guide adds the
**GCC-High-specific** requirements and, where the global list assumes Commercial URLs,
**overrides them with the US sovereign-cloud equivalents**. Each entry gives you: what it is,
why it matters, how to **verify** it, and how to **implement** it if it is missing.

> **Portal reminder.** On GCC High, every admin portal ends in `.us`. If a page you open ends
> in `.com`, you are in the wrong cloud — sign out and use the `.us` URL listed here.

---

## R1. A GCC High tenant (not Commercial, not DoD)

- **What:** Your Microsoft 365 tenant must be a **GCC High** tenant.
- **Why:** Universal Print is GA in **GCC and GCC High** but **not in DoD**. Commercial steps
  and endpoints do not serve GCC High. This whole solution assumes GCC High.
- **Verify:** Sign in at **`https://portal.office365.us`** (Microsoft 365 Government admin
  center). Confirm the tenant loads there and **not** at `admin.microsoft.com`. In
  **`https://portal.azure.us`** confirm the Azure Government portal loads with your account.
- **Implement:** If you are on Commercial, this GCC High edition does not apply — use the
  Commercial edition. If you are on **DoD**, **stop**: Universal Print is not available in DoD;
  there is no supported deployment. *Verify for GCC High/DoD.*

## R2. Universal Print licensing — for every user AND every admin

- **What:** An eligible Universal Print license assigned to **all** users who will print **and
  to every administrator who will configure the service**.
- **Why:** In Government, Microsoft explicitly requires that **all users, including
  administrators, be assigned an eligible license** to use *or configure* Universal Print. Each
  license also contributes print jobs to a shared monthly pool.
- **Verify:** In **`https://portal.office365.us`** → **Billing → Licenses**, confirm one of the
  GCC High SKUs below is owned and assigned. In **Users → Active users**, spot-check that the
  admin account and pilot users each have it.
- **Implement:** Assign one of these GCC High SKUs (part numbers as published by Microsoft):
  - **Microsoft 365 E3 GCC High** — `SPE_E3_USGOV_GCCHIGH` (100 jobs/user/month)
  - **Microsoft 365 E5 GCC High** — `SPE_E5_USGOV_GCCHIGH` (100 jobs/user/month)
  - **Universal Print for GCC High (standalone)** — `Universal_Print_for_GCCHIGH_USGOV_GCCHIGH` (5 jobs/month)

  After assignment, **allow up to 24 hours** for Universal Print access to appear.

## R3. Administrative roles (GCC High)

- **What:** The operator needs a role that can enable Universal Print and manage printers:
  **Printer Administrator** (least privilege for day-to-day) — plus **Global Administrator**
  for the one-time enable and connector registration if required.
- **Why:** Publishing printers, sharing them, and registering the connector require elevated
  rights. Universal Print exposes **Printer Administrator** and **Printer Technician** roles for
  least-privilege operation.
- **Verify:** In **`https://entra.microsoft.us`** (or the Entra blade inside `portal.azure.us`)
  → **Roles and administrators**, confirm your account holds **Printer Administrator** (and, for
  first-time enablement, **Global Administrator**).
- **Implement:** Assign **Printer Administrator** to the operator. Reserve **Global
  Administrator** for the tenant-wide enable step only. **Note:** *Delegated Administration*
  (scoped Printer Administrator via Entra administrative units) is **coming to GCC High
  "soon"** — do not design a scoped-admin model that depends on it yet; *verify for GCC High.*

## R4. Universal Print service is enabled for the tenant

- **What:** Universal Print must be turned on for the tenant.
- **Why:** Nothing can be published until the service is enabled.
- **Verify:** In **`https://portal.azure.us`**, search **Universal Print** and open the blade.
  It should load without a "service not available / license required" banner.
- **Implement:** With an eligible license (R2) assigned, open the **Universal Print** blade in
  `portal.azure.us`; enablement is automatic once licensing propagates (allow 24 h).

## R5. Connector host (for existing / non-cloud-ready printers)

- **What:** A Windows host running the **Universal Print connector** to bridge existing
  network/USB printers into the cloud. Recommended: **Windows 11 64-bit Pro/Enterprise
  (build 22631+)** or **Windows Server 2025**; supported (not recommended): Windows 10
  (19045+) / Windows Server 2022. Requires **.NET Framework 4.8+**.
- **Why:** Printers that are not "Universal Print ready" reach the cloud only through the
  connector. Microsoft notes **no Universal-Print-ready printers connect directly in GCC/GCC
  High yet** — so in GCC High you will almost always use the connector.
- **Verify:** Confirm the host is 64-bit, on a recommended build, has .NET 4.8+
  (`Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' -Name Release`),
  runs 24×7 (sleep/hibernate disabled), and has constant internet.
- **Implement:** Provision a dedicated always-on host; disable power saving; install .NET 4.8+;
  download the connector from `https://aka.ms/UPConnector`. **Do not clone** a registered
  connector host (clones interfere and block printing).

## R6. Network access to Universal Print GCC High endpoints

- **What:** Outbound HTTPS (TLS 1.2) from the connector host and client endpoints to the **GCC
  High** Universal Print endpoints and US Gov identity/Graph.
- **Why:** GCC High uses **dedicated `*.print.azure.us` endpoints** and the **US Gov identity
  authority**, not the Commercial `*.print.microsoft.com` / `login.microsoftonline.com` URLs.
  If your proxy/firewall only allows Commercial URLs, GCC High printing fails silently.
- **Verify:** From the connector host and a client, confirm outbound 443 to:
  - `https://print.print.azure.us`
  - `https://register.print.azure.us`
  - `https://discovery.print.azure.us`
  - `https://notification.print.azure.us`
  - `https://graph.print.azure.us`
  - `https://login.microsoftonline.us/`
  - `https://graph.microsoft.us`
- **Implement:** Allow the URLs above through the proxy/firewall. If the connector uses a proxy,
  set the proxy for the **LocalSystem** account with `bitsadmin` (per Microsoft's connector
  guidance) — a user-context proxy is not enough for the connector service.

## R7. Entra-joined / Intune-managed Windows endpoints

- **What:** The Windows devices that will print must be **Microsoft Entra joined** (or hybrid)
  and, ideally, **Intune-managed** (via `https://intune.microsoft.us`).
- **Why:** Universal Print discovers and deploys printers to Entra-joined devices; Intune is how
  you deploy printers and the Win10 registry keys (R8) at scale.
- **Verify:** In **`https://intune.microsoft.us`** → **Devices → All devices**, confirm the
  device appears and is compliant. On the device, `dsregcmd /status` shows `AzureAdJoined: YES`.
- **Implement:** Enable automatic enrollment and Entra join per your standard build. See the
  global prerequisites for baseline enrollment steps.

## R8. Windows client version (GCC High native vs registry-keyed)

- **What:** Client Windows version determines whether Universal Print works natively.
- **Why:** In GCC High, **Windows 11 22H2 and later is supported natively.** **Windows 10 and
  earlier Windows 11** require **three registry keys** that point the print stack at the US Gov
  authority and Graph — without them, those clients try Commercial endpoints and fail.
- **Verify:** `winver` on each client. For any client below Win 11 22H2, confirm the three
  `HKCU\SOFTWARE\Microsoft\Print\MPS` values are present (see `03-implementation.md`, Step 8).
- **Implement:** Prefer upgrading pilot devices to **Windows 11 22H2+**. Where you must support
  Windows 10 / older Win 11, deploy the three registry keys (OAuthAuthority =
  `https://login.microsoftonline.us/common`, MSGraphBaseUrl = `https://graph.microsoft.us/v1.0`,
  MSGraphResourceId = `https://graph.microsoft.us`) via Intune to the user context.

## R9. Microsoft Graph PowerShell (US Gov)

- **What:** The **Microsoft.Graph** PowerShell module, used by the five bundled scripts, able
  to connect with **`-Environment USGov`**.
- **Why:** The scripts read printer/share/connector state from **`graph.microsoft.us`**. Without
  `-Environment USGov` the module authenticates against Commercial and your GCC High account
  fails.
- **Verify:** `Get-Module Microsoft.Graph -ListAvailable` shows the module; then
  `Connect-MgGraph -Environment USGov -Scopes "Printer.Read.All"` completes sign-in against
  `login.microsoftonline.us`.
- **Implement:** `Install-Module Microsoft.Graph -Scope CurrentUser`. All bundled scripts pass
  `-Environment USGov` for you.

## R10. Current print environment inventory (the "from" state)

- **What:** A documented inventory of existing **print servers, shared printers, drivers, ports,
  and per-printer job volume**.
- **Why:** You retire print servers only after their printers are proven in Universal Print.
  You cannot plan waves or size the job pool without this baseline.
- **Verify:** Run `UPRTG-Discovery.ps1` (read-only) to enumerate what Universal Print already
  sees, and cross-reference against your print-server `Get-Printer` exports.
- **Implement:** On each print server, export `Get-Printer`, `Get-PrinterDriver`, and
  `Get-PrinterPort`; record monthly job counts per printer to size the shared job pool.

---

## Requirements checklist (all must pass before Configure)

| # | Requirement | Verified at (GCC High URL / command) |
| --- | --- | --- |
| R1 | GCC High tenant (not DoD) | `portal.office365.us`, `portal.azure.us` |
| R2 | UP license for users **and** admins | `portal.office365.us` → Licenses |
| R3 | Printer Administrator role | `entra.microsoft.us` → Roles |
| R4 | Universal Print enabled | `portal.azure.us` → Universal Print |
| R5 | Connector host ready | Win 11 22631+/WS2025, .NET 4.8+ |
| R6 | `*.print.azure.us` endpoints allowed | outbound 443 test |
| R7 | Entra-joined / Intune-managed clients | `intune.microsoft.us` → Devices |
| R8 | Win 11 22H2+ (or registry keys) | `winver` / registry check |
| R9 | Graph PowerShell `-Environment USGov` | `Connect-MgGraph -Environment USGov` |
| R10 | Print environment inventory captured | `UPRTG-Discovery.ps1` |

When every row is verified, proceed to `03-implementation.md`.


---


# Global Requirements — Infrastructure Solutions (category-level)

These requirements apply to **every** solution in the **Infrastructure** category. They are
published once at the category level so individual listings stay small. Confirm these before
deploying *any* Infrastructure solution. Each entry: Description · Why · Verify · Implement-if-missing.

## G1. Microsoft Entra ID tenant
Description: An active Microsoft Entra ID (Azure AD) tenant.
Why: It is the identity backbone for Microsoft 365, Entra ID, and Intune-managed infrastructure — including device sign-in, group targeting, and shared cloud resources.
Verify: Sign in to `https://entra.microsoft.com` as an administrator.
Implement: Create a Microsoft 365 / Azure subscription, which provisions a tenant.

## G2. Microsoft 365 / Intune subscription
Description: A Microsoft 365 plan that includes Microsoft Intune and the cloud service the solution relies on.
Why: Intune delivers configuration, deployment, and policy targeting; the bundled Microsoft 365 services back the cloud capability being deployed.
Verify: `https://intune.microsoft.com` loads; **Tenant administration → Tenant status** shows active.
Implement: Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1.

## G3. Administrative roles
Description: Appropriate Entra / Intune admin roles for the operator.
Why: Creating cloud service settings, policies, and deployments requires elevated rights.
Verify: Entra → **Roles and administrators**; confirm **Intune Administrator** (plus any service-specific admin role the solution calls out).
Implement: Assign **Intune Administrator**; reserve Global Administrator for tenant-wide changes.

## G4. Device enrollment in Intune
Description: Targeted Windows devices are enrolled and manageable.
Why: Deployments and policies only reach enrolled, Entra-joined devices.
Verify: Intune → **Devices → All devices**; the device appears and is **compliant**.
Implement: Enable **Automatic Enrollment** and join devices to Entra ID.

## G5. Pilot security group
Description: A Microsoft Entra security group for the pilot population (users or devices).
Why: Every solution is piloted before fleet rollout — the pilot is the gate.
Verify: Entra → **Groups**; the pilot group exists.
Implement: Entra → **Groups → New group** → **Security** → add members.

## G6. Supported Windows baseline
Description: Windows 10 21H2+ or Windows 11 with current updates.
Why: Modern Intune and Microsoft 365 cloud features assume a patched, supported OS.
Verify: `winver`, or Intune → device → **Hardware**.
Implement: Deploy update rings or upgrade to Windows 11.

## G7. Network access to Microsoft cloud endpoints
Description: Outbound HTTPS to Microsoft 365, Entra, and Intune service URLs.
Why: Enrollment, policy sync, authentication, and the cloud service traffic depend on these endpoints.
Verify: From a device, reach `https://login.microsoftonline.com` and `https://enrollment.manage.microsoft.com`.
Implement: Allow Microsoft's published Microsoft 365 / Intune URL and IP ranges through the proxy/firewall.

---
The repeatable deployment model (all solutions): Assess → Configure → Pilot → Validate → Expand.


---


# Implementation Guide — Universal Print on GCC High

This guide takes you from an enabled GCC High tenant to published, shared, pilot-validated
printers and, finally, a retired print server — following **Assess → Configure → Pilot →
Validate → Expand** with a **gate** at each phase. Every portal URL ends in `.us`. Every script
connects with `-Environment USGov`. Object names below are **reused consistently** — create them
once and reference them at every later step.

> **Before you start:** complete `02-requirements.md`. Do not begin Configure until all ten
> requirements verify. GCC-High-only caveats are flagged **[GCC High]** at the step where they
> bite.

## Naming convention (create once, reuse everywhere)

| Object | Name to use | Where |
| --- | --- | --- |
| Pilot security group | `UP-Pilot-Users` | Entra (`entra.microsoft.us`) |
| Expand wave group (per wave) | `UP-Wave1-Users`, `UP-Wave2-Users`, … | Entra |
| Connector | `UP-Connector-Site1` | Connector host / UP portal |
| Pilot printer share | `UP-Pilot-Printer-01` | Universal Print portal |
| Production printer shares | `UP-<Site>-<Model>-NN` | Universal Print portal |

---

# PHASE 1 — ASSESS

## Step 1 — Confirm the cloud and licensing

1. Sign in to **`https://portal.office365.us`** (Microsoft 365 Government admin center).
2. **Billing → Licenses** — confirm a GCC High UP SKU is present (`SPE_E3_USGOV_GCCHIGH`,
   `SPE_E5_USGOV_GCCHIGH`, or `Universal_Print_for_GCCHIGH_USGOV_GCCHIGH`).
3. **Users → Active users** — confirm **your admin account** and each intended pilot user has
   the license assigned. **[GCC High]** Admins without a license cannot even configure the
   service.
4. If you just assigned licenses, **wait up to 24 hours** before expecting Universal Print to
   appear.

**Expected result:** Eligible license owned and assigned to admin + pilot users.

## Step 2 — Baseline the current print environment (read-only)

1. On the admin workstation, install Graph PowerShell if needed:
   `Install-Module Microsoft.Graph -Scope CurrentUser`.
2. Run the discovery script (read-only, US Gov Graph):
   ```
   powershell -ExecutionPolicy Bypass -File .\UPRTG-Discovery.ps1
   ```
   Sign in when prompted — the browser opens **`login.microsoftonline.us`**. The script reports
   whether Universal Print is reachable, lists any already-registered printers/shares/connectors,
   and checks the GCC High endpoints.
3. On each legacy print server, export the "from" state:
   ```
   Get-Printer | Export-Csv .\printers.csv -NoTypeInformation
   Get-PrinterDriver | Export-Csv .\drivers.csv -NoTypeInformation
   Get-PrinterPort | Export-Csv .\ports.csv -NoTypeInformation
   ```
4. Record **monthly job volume per printer** to size the shared job pool (each G3/G5 Gov license
   contributes 100 jobs/month to the pool).

**Gate (Assess → Configure):** `UPRTG-Discovery.ps1` runs clean against `graph.microsoft.us`,
and every `02-requirements.md` row is verified.

---

# PHASE 2 — CONFIGURE

## Step 3 — Open the Universal Print portal (GCC High)

1. Sign in to **`https://portal.azure.us`** (Azure **Government** portal — note the `.us`).
2. Search **Universal Print** and open the blade. It must load without a licensing/availability
   banner. **[GCC High]** If it shows "not available," you are either unlicensed (Step 1) or in
   the wrong cloud (you opened `portal.azure.com`).

**Expected result:** Universal Print blade loads in `portal.azure.us`.

## Step 4 — Prepare the connector host

**[GCC High]** No Universal-Print-ready printers connect directly in GCC High yet, so you will
use the **connector** for existing printers.

1. On the always-on host (`UP-Connector-Site1`), confirm **.NET Framework 4.8+** and that
   sleep/hibernate are disabled.
2. **[GCC High]** Ensure outbound 443 to the **`*.print.azure.us`** endpoints, `login.microsoftonline.us`,
   and `graph.microsoft.us` (see `02-requirements.md` R6). If a proxy is used, set it for the
   **LocalSystem** account with `bitsadmin` — the connector runs as a service.
3. Download the connector from **`https://aka.ms/UPConnector`** and install it.

**Expected result:** Connector app installed on `UP-Connector-Site1`.

## Step 5 — Register the connector

1. Launch the connector app; click **Login** and sign in with your GCC High admin account (you
   are redirected to **`login.microsoftonline.us`**).
2. In **Connector name**, enter **`UP-Connector-Site1`** and click **Register**.
3. After registration, the app lists local/network printers available to register.
4. Configure connector options: leave **Automatically collect diagnostics** per your policy, and
   enable **Hybrid AD configuration** only if on-prem AD identity must be used for print jobs
   (and only after meeting its prerequisites).

**[GCC High] Warning:** never **clone** a registered connector host — parallel clones interfere
and block printing.

**Expected result:** `UP-Connector-Site1` shows **Registered** and lists printers.

## Step 6 — Register and share the first printers

1. In the connector app, select the printer(s) to onboard and **Register** them with Universal
   Print.
2. In **`https://portal.azure.us`** → **Universal Print → Printers**, confirm the registered
   printer appears.
3. Select the printer → **Share**. Give the share a reusable name, e.g. **`UP-Pilot-Printer-01`**.
4. On the **Share** blade, choose **who** can access it — for the pilot, you will grant the
   `UP-Pilot-Users` group in Step 7.

**Expected result:** The printer shows as **Shared** in Universal Print with share name
`UP-Pilot-Printer-01`.

## Step 7 — Create targeting groups

1. In **`https://entra.microsoft.us`** → **Groups → New group → Security**, create
   **`UP-Pilot-Users`** and add the pilot users.
2. (Optional, recommended) Pre-create empty **`UP-Wave1-Users`**, **`UP-Wave2-Users`** groups for
   later expansion.
3. You can build/populate these groups repeatably with the bundled script:
   ```
   powershell -ExecutionPolicy Bypass -File .\UPRTG-Set-ScopeTargeting.ps1 -GroupName "UP-Pilot-Users" -WhatIf
   ```
   Review the `-WhatIf` plan, then re-run **without** `-WhatIf` to apply.
4. On the `UP-Pilot-Printer-01` share, grant access to **`UP-Pilot-Users`**.

**Gate (Configure → Pilot):** printer is **Shared**, `UP-Pilot-Users` exists and is granted on
the share.

---

# PHASE 3 — PILOT

## Step 8 — Prepare pilot clients

1. Confirm each pilot device is **Entra-joined** and, ideally, **Intune-managed**
   (`intune.microsoft.us`).
2. **[GCC High]** Check `winver`:
   - **Windows 11 22H2 or later** → natively supported, no registry keys needed.
   - **Windows 10 / earlier Windows 11** → deploy these **three registry keys** to the **user**
     context (via Intune or a user-context script), then have the user sign out/in:
     ```
     reg add "HKCU\SOFTWARE\Microsoft\Print\MPS" /t REG_SZ /v "OAuthAuthority"  /d "https://login.microsoftonline.us/common" /f
     reg add "HKCU\SOFTWARE\Microsoft\Print\MPS" /t REG_SZ /v "MSGraphBaseUrl"  /d "https://graph.microsoft.us/v1.0" /f
     reg add "HKCU\SOFTWARE\Microsoft\Print\MPS" /t REG_SZ /v "MSGraphResourceId" /d "https://graph.microsoft.us" /f
     ```
     Without these, older clients try Commercial endpoints and printer discovery fails.

**Expected result:** Pilot clients are Entra-joined and (if pre-22H2) carry the three US Gov
registry keys.

## Step 9 — Deploy the printer to pilot users

Two supported methods:

- **User self-service (quickest for pilot):** on a pilot client, **Settings → Bluetooth &
  devices → Printers & scanners → Add device → Add a Universal Print printer**. The user (signed
  in with their GCC High account) sees `UP-Pilot-Printer-01` because they are in `UP-Pilot-Users`.
- **Intune-managed deployment (repeatable):** In **`https://intune.microsoft.us`** use the
  Universal Print printer provisioning (Printers) capability to assign `UP-Pilot-Printer-01` to
  the `UP-Pilot-Users` group so the printer is installed automatically.

**Expected result:** Pilot users see and can select `UP-Pilot-Printer-01`.

## Step 10 — First print jobs

1. Have pilot users print real documents (a mix: mono, color, duplex).
2. Confirm jobs complete and appear in **`portal.azure.us` → Universal Print → Usage and
   Reports**.
3. Run validation for the pilot scope:
   ```
   powershell -ExecutionPolicy Bypass -File .\UPRTG-Validation.ps1
   ```

**Gate (Pilot → Validate):** pilot users complete real jobs; `UPRTG-Validation.ps1` passes.

---

# PHASE 4 — VALIDATE

## Step 11 — Prove the pilot

1. Run the reporting script to capture evidence:
   ```
   powershell -ExecutionPolicy Bypass -File .\UPRTG-Report.ps1
   ```
   It writes an HTML/CSV report of printers, shares, connector state, and pilot targeting.
2. Confirm: print success rate acceptable, drivers behave, secure release works if used, and
   **Usage and Reports** shows the pilot jobs.
3. Address any issues with `06-troubleshooting.md`. For safe fixes, use:
   ```
   powershell -ExecutionPolicy Bypass -File .\UPRTG-Remediation.ps1 -WhatIf
   ```
   Review the `-WhatIf` plan before re-running without it.
4. Record **sign-off**.

**Gate (Validate → Expand):** no open Sev-1/Sev-2 issues; pilot sign-off recorded.

---

# PHASE 5 — EXPAND & RETIRE THE PRINT SERVER

## Step 12 — Roll out in waves

1. For each wave, create/populate `UP-Wave1-Users` (then Wave2, …) with
   `UPRTG-Set-ScopeTargeting.ps1` (run `-WhatIf` first).
2. Register and **share** the wave's printers (`UP-<Site>-<Model>-NN`), grant the wave group,
   and deploy via Intune.
3. **Validate each wave** (`UPRTG-Validation.ps1` + `UPRTG-Report.ps1`) before starting the next.

## Step 13 — Retire the legacy print server(s)

**Retire a print server only after every one of its printers is proven in Universal Print.**

1. Confirm each printer that lived on the server is now Shared in Universal Print and validated
   in a wave.
2. Redirect/print-test from representative clients to confirm no dependency remains on the old
   server (GPO print deployment, mapped `\\server\printer` shares).
3. Remove the server's printer shares from GPO/scripts; monitor for a defined soak period (e.g.
   1–2 weeks) with the server still powered but shares removed.
4. When no fallback is needed, decommission the print-server role / host.

**[GCC High] parity check before retirement:** if your retirement design assumed **Delegated
Administration** (scoped admin) or **macOS** printing, re-confirm current GCC High availability
first — both were **lagging in GCC High** at authoring (*verify for GCC High*). Do not retire a
server that is the only path for a not-yet-available GCC High capability your users depend on.

**Final result:** printers published in Universal Print on GCC High, endpoints printing through
the cloud, legacy print server(s) retired — each step proven before the next.

---

## Endpoint quick-reference (GCC High)

| Service | GCC High endpoint |
| --- | --- |
| Print | `https://print.print.azure.us` |
| Registration | `https://register.print.azure.us` |
| Discovery | `https://discovery.print.azure.us` |
| Notification | `https://notification.print.azure.us` |
| Graph (print) | `https://graph.print.azure.us` |
| Identity | `https://login.microsoftonline.us/` |
| Microsoft Graph | `https://graph.microsoft.us` |
| Graph PowerShell | `Connect-MgGraph -Environment USGov` |


---


# Testing & Validation — Universal Print on GCC High

Testing follows the same **Assess → Configure → Pilot → Validate → Expand** gates as the
implementation. Each phase has explicit **pass/fail** criteria. Do not advance a phase until its
tests pass. All Graph-based checks run against **`graph.microsoft.us`** via
`-Environment USGov`; all portal checks use **`.us`** URLs.

> Run the bundled scripts in this order at each gate: **Discovery → Validation → Report**.
> `UPRTG-Discovery.ps1`, `UPRTG-Validation.ps1`, and `UPRTG-Report.ps1` are all **read-only**.

---

## Test set A — Assess gate

| # | Test | How | Pass | Fail action |
| --- | --- | --- | --- | --- |
| A1 | Correct cloud | Open `portal.office365.us` and `portal.azure.us`; both load with your account | Both `.us` portals load | If only `.com` works, you are on Commercial — wrong edition |
| A2 | Licensing (users + admin) | `portal.office365.us` → Licenses / Users | GCC High UP SKU assigned to admin **and** pilot users | Assign SKU; wait ≤24 h (R2) |
| A3 | UP reachable via US Gov Graph | `UPRTG-Discovery.ps1` | Script signs in at `login.microsoftonline.us`, reports UP reachable | See `06-troubleshooting.md` T1/T2 |
| A4 | Endpoint reachability | Discovery script endpoint check + manual 443 test to `*.print.azure.us` | All GCC High endpoints reachable | Open firewall/proxy (R6) |

**Gate:** A1–A4 all pass.

---

## Test set B — Configure gate

| # | Test | How | Pass | Fail action |
| --- | --- | --- | --- | --- |
| B1 | Connector registered | `portal.azure.us` → Universal Print → Connectors | `UP-Connector-Site1` shows **Registered** | Re-register (Impl. Step 5); check LocalSystem proxy |
| B2 | Printer registered | UP → Printers | Printer listed | Re-register from connector app |
| B3 | Printer shared | UP → Printer → Share | Share `UP-Pilot-Printer-01` shows **Shared** | Re-share (Impl. Step 6) |
| B4 | Targeting group exists | `entra.microsoft.us` → Groups | `UP-Pilot-Users` exists, has members, granted on share | `UPRTG-Set-ScopeTargeting.ps1 -WhatIf` then apply |

**Gate:** B1–B4 all pass.

---

## Test set C — Pilot gate

| # | Test | How | Pass | Fail action |
| --- | --- | --- | --- | --- |
| C1 | Client readiness | `winver` on each pilot device | Win 11 22H2+ **or** three US Gov registry keys present (pre-22H2) | Deploy registry keys (Impl. Step 8) |
| C2 | Printer visible to user | Pilot user: Add a Universal Print printer | `UP-Pilot-Printer-01` appears | Confirm group membership + share grant |
| C3 | End-to-end print | Print mono, color, duplex | All jobs complete at the device | See `06-troubleshooting.md` |
| C4 | Job accounting | `portal.azure.us` → UP → Usage and Reports | Pilot jobs appear | Wait for report refresh; recount |
| C5 | Automated validation | `UPRTG-Validation.ps1` | Script reports PASS for pilot scope | Follow the script's per-check remediation hint |

**Gate:** C1–C5 all pass.

---

## Test set D — Validate gate

| # | Test | How | Pass | Fail action |
| --- | --- | --- | --- | --- |
| D1 | Evidence report | `UPRTG-Report.ps1` | HTML/CSV report generated with printers, shares, connector, targeting | Re-run; check output path |
| D2 | Success rate | Review pilot job outcomes | Acceptable success rate, no recurring failures | Root-cause via troubleshooting |
| D3 | Secure release (if used) | QR/badge release test | Job releases correctly | Verify secure-release config |
| D4 | No open Sev-1/Sev-2 | Issue log review | None open | Resolve before Expand |
| D5 | Sign-off | Record approver + date | Sign-off captured | — |

**Gate:** D1–D5 all pass; pilot signed off.

---

## Test set E — Expand & retirement gate (per wave)

| # | Test | How | Pass | Fail action |
| --- | --- | --- | --- | --- |
| E1 | Wave targeting | `UPRTG-Set-ScopeTargeting.ps1 -WhatIf` then apply | `UP-WaveN-Users` populated, granted on wave shares | Re-run apply |
| E2 | Wave printers shared | UP → Printers | Each wave printer **Shared** | Re-share |
| E3 | Wave validation | `UPRTG-Validation.ps1` + `UPRTG-Report.ps1` | PASS for wave scope | Troubleshoot before next wave |
| E4 | No residual server dependency | Client print test with old share removed | Prints via cloud, not `\\server\printer` | Remove GPO/mapped print deployment |
| E5 | Retirement safety (parity) | Confirm no reliance on **Delegated Admin** / **macOS** that is not yet in GCC High | Confirmed not blocking | Keep server until GCC High parity confirmed (*verify for GCC High*) |

**Gate per wave:** E1–E5 pass **before** starting the next wave and **before** decommissioning
the print server whose printers that wave covered.

---

## Regression / ongoing checks

- **Monthly:** `UPRTG-Report.ps1` for a current inventory; review **Usage and Reports** against
  the licensed job pool so you don't exhaust it.
- **After any change:** re-run **Discovery → Validation → Report**.
- **After OS upgrades:** re-check `winver`; devices upgraded **to** Win 11 22H2+ no longer need
  the registry keys, but leaving them in place is harmless.


---


# Troubleshooting — Universal Print on GCC High

GCC-High-specific symptoms and fixes. Most Universal Print problems on a Government tenant trace
back to one of four root causes: **wrong cloud (`.com` instead of `.us`)**, **missing
`-Environment USGov`**, **missing US Gov registry keys on older clients**, or **blocked
`*.print.azure.us` endpoints**. Work the table for your symptom; each fix references the relevant
implementation step.

> Re-run **`UPRTG-Discovery.ps1` → `UPRTG-Validation.ps1`** after any fix to confirm resolution.

---

## T1. Sign-in fails / "account doesn't exist" / redirect error when connecting Graph

- **Likely cause:** Connecting against the **Commercial** identity endpoint. A GCC High account
  does not exist at `login.microsoftonline.com`.
- **Fix:** Always connect with **`Connect-MgGraph -Environment USGov`** (all bundled scripts do
  this). Confirm the sign-in page shows **`login.microsoftonline.us`**. If you scripted
  `Connect-MgGraph` yourself, add `-Environment USGov`.
- **Verify:** `UPRTG-Discovery.ps1` completes sign-in and reports UP reachable.

## T2. Universal Print blade shows "not available" or licensing banner in the portal

- **Likely cause A — wrong cloud:** You opened **`portal.azure.com`**. GCC High uses
  **`portal.azure.us`**.
- **Likely cause B — licensing:** The admin account has **no eligible UP license**, or licensing
  hasn't propagated yet.
- **Fix:** Open **`portal.azure.us`**. In `portal.office365.us` confirm the admin holds a GCC
  High SKU (`SPE_E3_USGOV_GCCHIGH` / `SPE_E5_USGOV_GCCHIGH` / `Universal_Print_for_GCCHIGH_USGOV_GCCHIGH`).
  **Wait up to 24 hours** after assigning a license.
- **Reference:** `02-requirements.md` R2/R4; `03-implementation.md` Steps 1, 3.

## T3. Printer discovery fails on Windows 10 / older Windows 11 clients (works on Win 11 22H2+)

- **Likely cause:** Pre-22H2 clients are not natively supported in GCC High and are trying
  **Commercial** print endpoints because the **three US Gov registry keys** are missing.
- **Fix:** Deploy to the **user** context (via Intune or user-context script), then have the user
  sign out/in:
  ```
  reg add "HKCU\SOFTWARE\Microsoft\Print\MPS" /t REG_SZ /v "OAuthAuthority"    /d "https://login.microsoftonline.us/common" /f
  reg add "HKCU\SOFTWARE\Microsoft\Print\MPS" /t REG_SZ /v "MSGraphBaseUrl"    /d "https://graph.microsoft.us/v1.0" /f
  reg add "HKCU\SOFTWARE\Microsoft\Print\MPS" /t REG_SZ /v "MSGraphResourceId" /d "https://graph.microsoft.us" /f
  ```
- **Best fix:** Upgrade the device to **Windows 11 22H2+**, which works natively with no keys.
- **Reference:** `03-implementation.md` Step 8; `gcc-high-parity-notes.md` §4.

## T4. Connector won't register or drops offline

- **Likely cause A — endpoints blocked:** Proxy/firewall does not allow the GCC High
  **`*.print.azure.us`** endpoints and `login.microsoftonline.us` / `graph.microsoft.us`.
- **Likely cause B — proxy in user context only:** The connector runs as a **service
  (LocalSystem)**; a user-context proxy setting doesn't apply.
- **Likely cause C — cloned host:** A cloned connector host runs in parallel and blocks printing.
- **Fix:** Allow the endpoints in `02-requirements.md` R6. Set the proxy for **LocalSystem** with
  `bitsadmin`. If cloned, turn off the clone (or remove the connector from the clone **without**
  unregistering printers).
- **Reference:** `03-implementation.md` Steps 4–5.

## T5. Endpoints unreachable / intermittent print failures

- **Likely cause:** Firewall allows Commercial UP URLs (`*.print.microsoft.com`) but **not** the
  GCC High `*.print.azure.us` set.
- **Fix:** Explicitly allow, on both connector host and clients, outbound 443 to:
  `print.print.azure.us`, `register.print.azure.us`, `discovery.print.azure.us`,
  `notification.print.azure.us`, `graph.print.azure.us`, `login.microsoftonline.us`,
  `graph.microsoft.us`.
- **Verify:** `UPRTG-Discovery.ps1` endpoint check passes.
- **Reference:** `gcc-high-parity-notes.md` §3.

## T6. Printer registered but users can't see it

- **Likely cause:** The printer is registered but **not Shared**, or the user's **targeting
  group** isn't granted on the share, or the user isn't in the group.
- **Fix:** In `portal.azure.us` → Universal Print → Printers → Share the printer (`UP-Pilot-Printer-01`)
  and grant **`UP-Pilot-Users`**. Confirm the user is a member (`entra.microsoft.us` → Groups).
  Re-run targeting with `UPRTG-Set-ScopeTargeting.ps1 -WhatIf` then apply.
- **Reference:** `03-implementation.md` Steps 6–7, 9.

## T7. Delegated (scoped) admin not working in GCC High

- **Likely cause:** **Delegated Administration** was **not yet available in GCC High** at
  authoring ("coming soon").
- **Fix:** Manage centrally with **Printer Administrator** / **Printer Technician** roles for now.
  **Verify current GCC High availability** before designing a scoped-admin model.
- **Reference:** `gcc-high-parity-notes.md` §6.

## T8. macOS users can't print

- **Likely cause:** **macOS client printing was not yet available in GCC High** at authoring.
- **Fix:** Do not rely on Universal Print for Mac users on GCC High yet, and do not retire a
  server that is their only print path. **Verify current GCC High availability.**
- **Reference:** `gcc-high-parity-notes.md` §6.

## T9. Print jobs succeed but don't appear in reporting / job pool concerns

- **Likely cause:** Report refresh lag, or misunderstanding of job counting.
- **Fix:** Check **`portal.azure.us` → Universal Print → Usage and Reports**. Remember a **single
  document = one job** regardless of pages/copies/color/duplex; a job counts only when completed.
  If the pool is near exhaustion, buy 500/10,000-job add-ons.
- **Reference:** `07-best-practices.md` §2.

## T10. "It worked in the lab (Commercial) but not in production (GCC High)"

- **Likely cause:** The lab used Commercial portals/endpoints/Graph; production is GCC High.
- **Fix:** Re-check every URL ends in `.us`, every script uses `-Environment USGov`, endpoints are
  `*.print.azure.us`, and licensing is the GCC High SKU. This is the single most common
  cross-cloud mistake — the **Commercial vs GCC High** table in `01-solution-overview.md` is your
  checklist.

## T11. DoD tenant — nothing works

- **Likely cause:** **Universal Print is not available in DoD.** This is expected, not a
  misconfiguration.
- **Fix:** There is no supported Universal Print deployment in DoD at authoring. Track the
  Microsoft 365 roadmap. **Verify for DoD** before assuming a change.
- **Reference:** `gcc-high-parity-notes.md` §1.

---

## Escalation checklist (before opening a Microsoft support case)

1. `UPRTG-Discovery.ps1` output (US Gov Graph reachable? endpoints reachable?).
2. `UPRTG-Report.ps1` current-state report (printers, shares, connector, targeting).
3. Confirm cloud: all portals `.us`, all scripts `-Environment USGov`.
4. Confirm licensing propagated (≥24 h) for the affected users **and** the admin.
5. Client `winver` + registry-key presence for any pre-22H2 device.
6. Endpoint allow-list includes the full `*.print.azure.us` set.
7. Note whether the blocked capability is a known **GCC High parity gap** (Delegated Admin,
   macOS) rather than a fault.


---


# Best Practices — Universal Print on GCC High

These practices keep a **GCC High** Universal Print deployment correct, compliant, and
retirement-ready. They complement the phase gates in `03-implementation.md` and `05-testing.md`.

## 1. Stay in the sovereign cloud — every time

- **Bookmark only the `.us` portals:** `portal.azure.us`, `portal.office365.us`,
  `intune.microsoft.us`, `entra.microsoft.us`. Never trust a `.com` tab for GCC High work.
- **Every script and Graph call uses `-Environment USGov`.** Make it a review checklist item —
  a missing `-Environment USGov` silently targets Commercial and fails for a GCC High account.
- **Allow the `*.print.azure.us` endpoints explicitly** on proxy/firewall, plus
  `login.microsoftonline.us` and `graph.microsoft.us`. Do not assume Commercial UP URLs cover
  GCC High — they do not.

## 2. License discipline (Government-specific)

- **License admins too.** In Government, administrators must hold an eligible UP license to even
  configure the service — assign it to the operator account first, then wait up to 24 h.
- **Size the job pool from real data.** Each G3/G5 Gov license adds 100 jobs/month to a shared
  pool; unused jobs expire monthly. Use `UPRTG-Report.ps1` + **Usage and Reports** to watch
  consumption and buy 500/10,000-job add-ons *before* you exhaust the pool.
- **A job = one document** regardless of pages/copies/color/duplex — factor that into pool
  sizing.

## 3. Pilot-first, always gate

- Never publish fleet-wide before the pilot passes. Use `UP-Pilot-Users` as the single pilot
  gate, then `UP-Wave1-Users`, `UP-Wave2-Users`, … for controlled expansion.
- **Validate each wave** with Discovery → Validation → Report before the next. A green pilot is
  not permission to skip wave validation.

## 4. Retire print servers safely

- **Prove before you retire.** Decommission a print server only after every printer it hosted is
  Shared in Universal Print and validated in a wave.
- **Soak with the server powered but shares removed** (1–2 weeks) so you have an instant
  fallback before final decommission.
- **Remove the old print path** (GPO print deployment, mapped `\\server\printer`) so clients
  cannot silently keep using the legacy server.

## 5. Respect GCC High parity gaps (design around them)

- **Delegated Administration** (scoped Printer Administrator via Entra administrative units) was
  **coming to GCC High "soon"** at authoring. If you need scoped, per-department admin, **verify
  current GCC High availability** before designing for it; until then, manage centrally with
  **Printer Administrator** / **Printer Technician** roles.
- **macOS client printing** was **not yet available in GCC High** at authoring. Do not promise
  Mac users cloud printing and do not retire a server that is their only path until you **verify
  for GCC High**.
- **No direct-connect UP-ready printers in GCC High yet** — plan on the **connector** for
  existing printers.
- Treat every "verify for GCC High" flag as a real pre-deployment task, because GCC High parity
  changes over time — re-check Microsoft's current Government docs.

## 6. Connector hygiene

- Use a **dedicated, always-on** host (sleep/hibernate disabled, constant internet, .NET 4.8+).
- **Never clone** a registered connector host — parallel clones interfere and block printing.
- If behind a proxy, set the proxy for the **LocalSystem** account (`bitsadmin`) — the connector
  runs as a service, not in a user session.
- Name connectors by site (`UP-Connector-Site1`) and size printers-per-connector per Microsoft
  guidance rather than piling every printer onto one.

## 7. Client-version strategy

- **Prefer Windows 11 22H2+** for pilot and expansion devices — it works natively in GCC High
  with no registry keys.
- Where Windows 10 / older Win 11 must be supported, deploy the **three US Gov registry keys**
  via **Intune** to the user context; standardize the deployment so no device is missed.
- Devices upgraded to Win 11 22H2+ no longer need the keys; leaving them is harmless.

## 8. Naming, targeting, and least privilege

- **Create objects once and reuse them** (`UP-Pilot-Users`, `UP-Pilot-Printer-01`,
  `UP-Connector-Site1`, `UP-<Site>-<Model>-NN`). Consistent names make reports and audits
  legible.
- Target printers to **groups**, never individuals, and build/maintain those groups repeatably
  with `UPRTG-Set-ScopeTargeting.ps1` (always `-WhatIf` first).
- Operate day-to-day as **Printer Administrator**; reserve **Global Administrator** for the
  one-time enable/registration.

## 9. Change safety

- Every remediation runs **`-WhatIf` first** — review the plan, then apply. `UPRTG-Remediation.ps1`
  and `UPRTG-Set-ScopeTargeting.ps1` default to `-WhatIf`.
- Re-run **Discovery → Validation → Report** after any change and keep the dated reports as an
  audit trail.

## 10. Monitoring and lifecycle

- Monthly: run `UPRTG-Report.ps1`, reconcile printers/shares/targeting, and check job-pool
  consumption in **Usage and Reports**.
- Watch Microsoft's Government roadmap/docs for GCC High parity progress (Delegated Admin, macOS,
  direct-connect printers, DoD availability) and revisit any design that was working around a gap.


---


# Deliverables Summary — Universal Print Deployment & Print-Server Retirement (GCC High)

This solution is a complete, self-guided package for deploying Universal Print on a **GCC High**
tenant and retiring legacy print servers. Everything below is included.

## Documents

| Deliverable | What it gives you |
| --- | --- |
| **01 — Solution Overview** | What the solution does, the Assess→Configure→Pilot→Validate→Expand model, and the full **Commercial vs GCC High — what's different** table (portals, endpoints, licensing, client support) with the availability caveat up front. |
| **02 — Requirements Guide** | Ten GCC-High-specific prerequisites (R1–R10), each with **verify** and **implement** steps against `.us` portals, plus a pass/fail checklist. |
| **03 — Implementation Guide** | Ordered, click-by-click steps across all five phases using the GCC High portals, with **[GCC High]** caveats inline (registry keys, connector, parity gaps) and a reusable naming convention. |
| **05 — Testing & Validation** | Pass/fail test sets A–E, one per phase gate, tied to the bundled scripts. |
| **06 — Troubleshooting** | GCC-High-specific symptoms and fixes (wrong-cloud errors, `-Environment USGov`, registry keys, connector, endpoints, licensing propagation). |
| **07 — Best Practices** | Ten practice areas: sovereign-cloud discipline, licensing, pilot gating, safe server retirement, parity-gap design, connector hygiene, client strategy, naming, change safety, monitoring. |
| **gcc-high-parity-notes.md** | Cited Commercial-vs-GCC-High reference: availability, portals, endpoints, client support, licensing, and confirmed parity gaps — with sources and "verify for GCC High/DoD" flags. |
| **Executive Summary** | One-page business-level summary for approvers. |
| **global-requirements-infrastructure.md** | Category-level prerequisites shared across all Infrastructure solutions. |

## PowerShell scripts (all connect to US Gov Graph, `-Environment USGov`)

| Script | Type | What it does |
| --- | --- | --- |
| **UPRTG-Discovery.ps1** | Read-only | Confirms UP reachability on GCC High, lists printers/shares/connectors, checks the `*.print.azure.us` endpoints. Run at the Assess gate. |
| **UPRTG-Validation.ps1** | Read-only | Validates the pilot/wave scope against pass/fail criteria (printer shared, targeting granted, connector healthy). Run at Pilot/Expand gates. |
| **UPRTG-Report.ps1** | Read-only | Generates a dated HTML/CSV evidence report of printers, shares, connector state, and targeting. Run at the Validate gate and monthly. |
| **UPRTG-Remediation.ps1** | Change (default `-WhatIf`) | Safely fixes common configuration drift (e.g., re-grant targeting, re-share). Shows a `-WhatIf` plan first; apply only after review. |
| **UPRTG-Set-ScopeTargeting.ps1** | Change (default `-WhatIf`) | Builds/populates pilot and wave targeting groups and grants them on shares, repeatably. Shows a `-WhatIf` plan first. |

## How the pieces fit the phases

- **Assess:** Requirements Guide + `UPRTG-Discovery.ps1` → Assess gate (Test set A).
- **Configure:** Implementation Steps 3–7 + `UPRTG-Set-ScopeTargeting.ps1` → Configure gate (Test set B).
- **Pilot:** Implementation Steps 8–10 + `UPRTG-Validation.ps1` → Pilot gate (Test set C).
- **Validate:** Implementation Step 11 + `UPRTG-Report.ps1` + `UPRTG-Remediation.ps1` → Validate gate (Test set D).
- **Expand & Retire:** Implementation Steps 12–13 + all scripts per wave → Expand gate (Test set E).

## Outcome

Universal Print published on GCC High with the correct sovereign-cloud portals and endpoints,
parity gaps handled, pilot-proven, and legacy print servers retired only after their printers are
validated in the cloud.
