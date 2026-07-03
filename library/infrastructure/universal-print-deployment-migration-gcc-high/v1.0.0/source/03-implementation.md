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
