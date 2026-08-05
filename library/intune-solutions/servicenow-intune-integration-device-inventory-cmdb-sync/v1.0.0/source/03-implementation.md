# 3. Implementation Guide — ServiceNow ↔ Microsoft Intune Integration (Device Inventory & CMDB Sync)

Follow these steps **in order**. You work in two consoles: the **Microsoft Entra admin center**
(`https://entra.microsoft.com`) and **Intune** (`https://intune.microsoft.com`) on the Microsoft
side, and your **ServiceNow instance** on the ServiceNow side.

> **Model:** Entra app registration & consent → ServiceNow connection → field/CMDB mapping & IRE →
> scheduled import → validate.

> **Names drift — verify as you go.** The Microsoft-side steps and Graph scopes are stable and
> verified. On the ServiceNow side, the exact **menu paths, connector app name, data-stream names,
> and CMDB class/field names change across releases** — confirm each against the connector's docs for
> **your** instance release. Where a name is release-specific it is flagged inline.

---

## PART 1 — Microsoft side: register the app and consent the read-only scopes

### Step 1 — Register the Entra application ServiceNow will use
1. Go to `https://entra.microsoft.com` → **Identity → Applications → App registrations**.
2. Click **New registration**.
3. **Name:** `SVC – ServiceNow CMDB – Intune Read`.
4. **Supported account types:** **Accounts in this organizational directory only (single tenant)**.
5. Leave **Redirect URI** blank (this is a client-credentials, app-only integration). Click **Register**.
6. On the app **Overview**, copy and record the **Application (client) ID** and the **Directory
   (tenant) ID** — ServiceNow needs both.

### Step 2 — Create the client secret
1. In the app, open **Certificates & secrets → Client secrets → New client secret**.
2. **Description:** `ServiceNow CMDB feed`. **Expires:** choose a defined lifetime (e.g. 24 months).
   Click **Add**.
3. **Copy the secret Value immediately** (it is shown only once) and store it in your secret vault.
   **Record the expiry date** for renewal.
   *(A certificate credential is a stronger alternative to a secret — use one if your ServiceNow
   connection supports certificate auth.)*

### Step 3 — Add the least-privilege Graph Application permissions
1. In the app, open **API permissions → Add a permission → Microsoft Graph → Application permissions**.
2. Add each of these (search by name, tick, **Add permissions**):
   - `DeviceManagementManagedDevices.Read.All`
   - `DeviceManagementApps.Read.All`
   - `DeviceManagementServiceConfig.Read.All`
   - `Directory.Read.All`
3. Confirm each row shows **Application** (not Delegated). Remove any unused default delegated
   permission you do not need. **Do not** add any `…ReadWrite.All` or
   `…PrivilegedOperations.All` scope — this feed is read-only.

### Step 4 — Grant admin consent
1. Still on **API permissions**, click **Grant admin consent for <tenant>** → **Yes**.
2. Confirm every permission row shows **"Granted for <tenant>"** with a green check.
3. Validate from a Microsoft-side workstation: run **`SNOWINT-Preflight.ps1`** (Commercial) — it
   confirms the app can authenticate, the four scopes are consented, and managed devices are readable.
   For a Gov tenant run `SNOWINT-Preflight.ps1 -Cloud USGov`.

> **Government (GCC High / DoD):** perform Steps 1–4 in `https://entra.microsoft.com` for your Gov
> tenant, but note the ServiceNow connection (Part 2) must target `https://graph.microsoft.us` and
> `https://login.microsoftonline.us`. See §2 Government note. **Verify for GCC High** that your
> connector release supports the sovereign endpoints.

---

## PART 2 — ServiceNow side: install and connect

### Step 5 — Install the connector and its dependencies
1. In ServiceNow, open the **Store** (or **System Applications → All Available Applications → All**).
2. Find **"Service Graph Connector for Microsoft Intune"**, click **Install/Update**, and install its
   dependencies (Integration Hub / Flow Designer, Integration Commons for CMDB / Service Graph
   framework, CMDB CI Class Models).
3. Confirm the connector and dependencies show **Installed / Active**.
   *(No ITOM entitlement? Skip to the custom-import alternative at the end of Part 3.)*
   **Confirm the exact app name, version, and dependency list on the Store for your release.**

### Step 6 — Create the connection & credential alias to Microsoft Graph
1. Open the connector's guided setup (commonly under **Service Graph Connectors** or the connector's
   application menu) → the **Microsoft Intune** connection.
2. Enter the values from Part 1:
   - **Tenant ID** = Directory (tenant) ID (Step 1).
   - **Client ID** = Application (client) ID (Step 1).
   - **Client Secret** = the secret Value (Step 2).
   - **Graph / token endpoint** = Commercial (`graph.microsoft.com` / `login.microsoftonline.com`) —
     **or** the `.us` sovereign endpoints for a Gov tenant.
3. Save. Use the connection's **Test** action to confirm authentication succeeds. If your design uses
   a **MID Server** for egress, select it here and confirm it is **Up**.
   **Verify the exact field labels and connection/credential-alias flow in the connector docs for your
   release.**

---

## PART 3 — Map the CMDB model, reconcile, and schedule

### Step 7 — Confirm the data streams and CMDB target classes
1. In the connector's configuration, review the enabled **data streams** and their CMDB targets:
   - **Managed devices** → the **computer** class **`cmdb_ci_computer`** (Windows/macOS
     laptops/desktops) and the **handheld/mobile** class (iOS/Android) — confirm the exact handheld
     class name for your release (e.g. `cmdb_ci_handheld_computing`).
   - **Detected / installed applications** → the software/installed-software model — **confirm the
     exact target table for your release**.
2. Enable only the streams you want (device inventory is the core; enable the app stream only if you
   will consume the app inventory).
   **The CMDB class names above are release-specific — verify each in CI Class Manager / the connector
   docs before relying on them.**

### Step 8 — Verify/adjust the field mapping and IRE identifier
1. Review the connector's **robust transform / field map** so Intune fields land on the right CI
   fields: **serial number**, name, manufacturer, model, OS + version, **assigned/primary user**
   (ownership), **compliance state**, and **last check-in**.
2. Confirm **Identification and Reconciliation (IRE)** matches on a stable identifier —
   **serial number** — so each Intune device **updates the existing CI** rather than creating a
   duplicate. **Configuration → CI Class Manager → (class) → Identification/Reconciliation.**
3. **Reconcile against the existing Workspace ONE feed:** ensure both **Microsoft Intune** and
   **Workspace ONE** are registered **discovery sources** and that the serial-number identifier is the
   same for both, so an Intune record lands on the **same CI** the WS1 feed already created — no
   duplicate device.

### Step 9 — Schedule the import
1. In the connector, set the **data stream schedule** to run on a cadence (e.g. **daily**). Enable it.
2. For the first run, trigger the import **manually** to validate before leaving it on the schedule.
   **Verify the exact scheduling control name for your release.**

### Step 10 — Pilot: run once and validate a known device
1. Run the import (manual trigger). Wait for it to complete.
2. On the **Microsoft** side, export the same dataset with **`SNOWINT-Export-ManagedDevices.ps1`** →
   a CSV of Intune managed devices (the exact set ServiceNow should import) for reconciliation.
3. In ServiceNow, open the CMDB and find a **known pilot device by serial number**. Confirm:
   - It exists as **one** CI (no duplicate), in the correct hardware class.
   - Owner, OS, compliance, and last check-in are populated and correct.
   - Its **discovery source** includes **Intune**.
4. Run **`SNOWINT-Validate-Sync.ps1 -CmdbCsv <export from ServiceNow>`** to compare the Intune device
   set against a CMDB export (serials present/missing/duplicated). Complete the **Testing Guide**.

### Step 11 — Expand to production (and retire the Workspace ONE feed)
1. Widen the import scope from the pilot set to the full fleet; let it run on the daily schedule.
2. Run **`SNOWINT-Report-Coverage.ps1`** to confirm managed-device coverage by platform/ownership
   matches expectations wave over wave.
3. Once the Intune feed is validated and coverage matches the Workspace ONE feed, **retire the
   Workspace ONE connector's schedule** — the CIs persist and reconcile onto the Intune source; only
   the discovery source changes. *(The device migration itself is the WS1PROG program — out of scope
   here.)*

---

## Alternative (no ITOM entitlement): custom Integration Hub import
If you cannot license the Store connector, build the same feed with native ServiceNow tooling:
1. Create an **OAuth 2.0 (client-credentials) application registry** entry in ServiceNow pointing at
   the Entra app from Part 1, scope `https://graph.microsoft.com/.default` (or the `.us` equivalent).
2. Create **REST messages / a Data Source** that GET `…/deviceManagement/managedDevices` (and
   `…/deviceManagement/detectedApps`), handling paging (`@odata.nextLink`).
3. Land the JSON via **Transform Maps** into `cmdb_ci_computer` / the handheld class, **coalescing on
   serial number** (or route through the **IRE API** so reconciliation matches the Store connector).
4. Schedule the import (Scheduled Data Import / Scheduled Job).
This path uses the **same Microsoft setup and the same CMDB target model** as the connector.

---
### Order of operations
`Entra app registration → client secret → read-only Graph scopes → admin consent → (Preflight) →
install connector → connection to Graph → data streams + CMDB classes → field map + serial-number IRE
→ reconcile vs Workspace ONE → schedule → pilot import → validate → expand → retire WS1 feed`
