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
