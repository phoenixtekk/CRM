# 2. Requirements Guide — ServiceNow ↔ Microsoft Intune Integration (Device Inventory & CMDB Sync)

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide Intune prerequisites are in
`global-requirements-intune-solutions.md`. This is a **two-platform** integration, so the
requirements are grouped: **Microsoft (Intune / Entra / Graph)**, then **ServiceNow**.

> **Accuracy note:** ServiceNow product names, plugin/store-app packaging, and CMDB class names
> change across releases. Where this guide names a specific ServiceNow app, plugin, table, or field,
> **confirm it against the ServiceNow Store / docs for your instance release** before relying on it.
> The Microsoft Graph scope names below are verified against Microsoft Learn (current at authoring).

---

## Part A — Microsoft (Intune / Entra / Graph)

### 2.1 Microsoft Intune with devices enrolled
**Description:** An Intune-bearing subscription with the target devices enrolled and reporting.
**Why:** ServiceNow can only import devices Intune actually knows about; unenrolled devices are not in
the Graph feed.
**Verify:** `https://intune.microsoft.com` → **Devices → All devices** shows the fleet; each device
has a recent **last check-in**.
**Implement:** Assign Intune (M365 E3/E5, Business Premium, or Intune Plan 1); enable automatic
enrollment and enroll devices (see the Device Enrollment solution).

### 2.2 Microsoft Entra application registration (for ServiceNow to authenticate)
**Description:** A dedicated Entra **app registration** ServiceNow uses to call Microsoft Graph —
named `SVC – ServiceNow CMDB – Intune Read` (use one clear, auditable name).
**Why:** ServiceNow authenticates to Graph with this app's **Client ID + Client Secret + Tenant ID**
(client-credentials OAuth 2.0). A dedicated app keeps the integration auditable and independently
revocable.
**Verify:** Entra admin center → **Identity → Applications → App registrations**; the app exists and
its **Application (client) ID** and **Directory (tenant) ID** are recorded.
**Implement:** Entra → **App registrations → New registration** → name `SVC – ServiceNow CMDB –
Intune Read`, single-tenant → **Register** (full click-path in §3, Step 1).

### 2.3 Client secret (or certificate) on the app registration
**Description:** A client secret (or certificate credential) on the app above, with a tracked expiry.
**Why:** It is the credential ServiceNow presents to Graph. An expired secret silently breaks the
feed.
**Verify:** App registration → **Certificates & secrets**; a valid, unexpired secret/cert exists and
its **expiry date is recorded** for renewal.
**Implement:** **Certificates & secrets → New client secret**, description `ServiceNow CMDB feed`,
choose a defined lifetime (e.g. 12–24 months), copy the **Value** once. Set a renewal reminder.

### 2.4 Microsoft Graph **application** permissions (least privilege, read-only) + admin consent
**Description:** The app registration must hold these **Application** (app-only) Graph permissions,
**admin-consented**:
- **`DeviceManagementManagedDevices.Read.All`** — read managed devices (device, category, **detected
  app**, malware info). *This is the core inventory scope.*
- **`DeviceManagementApps.Read.All`** — read Intune app inventory (client apps / app config).
- **`DeviceManagementServiceConfig.Read.All`** — read enrollment/service configuration context.
- **`Directory.Read.All`** — resolve users/ownership for the device→owner association.

**Why:** These are the exact scopes the ServiceNow Intune connector uses to read device + app
inventory. All are **read-only**; none permit changing Intune. Least-privilege rule: **do not** grant
`…ReadWrite.All` or `…PrivilegedOperations.All` — a CMDB feed never needs write.
**Verify:** App registration → **API permissions**; the four Application permissions are listed with
**"Granted for <tenant>"** (green check). Confirm they are **Application**, not Delegated.
**Implement:** **API permissions → Add a permission → Microsoft Graph → Application permissions**, add
the four scopes, then **Grant admin consent for <tenant>**. (Run `SNOWINT-Preflight.ps1` to confirm.)

> **Least-privilege guidance:** the minimum for device inventory alone is
> `DeviceManagementManagedDevices.Read.All`. Add `DeviceManagementApps.Read.All` only if you import
> the app inventory, and `Directory.Read.All` only to resolve owner/user detail. Grant the smallest
> set your connector configuration actually reads.

### 2.5 Global / Privileged Role Administrator to grant consent
**Description:** An admin who can grant tenant-wide admin consent for application Graph permissions.
**Why:** Application permissions require admin consent before Graph will honor them.
**Verify:** Entra → **Roles and administrators**; you hold **Global Administrator** or **Privileged
Role Administrator** (Cloud Application Administrator can grant consent for many app permissions).
**Implement:** Have a Global Administrator perform the **Grant admin consent** click in Step 2.4.

### 2.6 Network egress to Microsoft Graph from ServiceNow's caller
**Description:** Outbound HTTPS from wherever the connection is made (ServiceNow instance directly, or
a **MID Server** if your design routes Graph calls through one) to the Graph endpoint.
**Why:** No egress to Graph = no feed.
**Verify:** From the caller, reach `https://graph.microsoft.com` (Commercial) — or the sovereign
endpoint below for Gov. If a MID Server is used, confirm it is **Up** in ServiceNow.
**Implement:** Allow outbound 443 to `graph.microsoft.com` and `login.microsoftonline.com` (Commercial)
through the proxy/firewall; if using a MID Server, install/validate it first.

---

## Part B — ServiceNow

### 2.7 Supported ServiceNow release + CMDB
**Description:** A supported ServiceNow release (e.g. current N/N-1 family) with the CMDB in use.
**Why:** Connector packaging and CMDB identifier rules differ by release; the CMDB must exist as the
target of record.
**Verify:** ServiceNow → **System Diagnostics → Stats** (or the instance banner) shows the release;
the CMDB (**Configuration → All**) is populated.
**Implement:** Upgrade to a supported release; ensure CMDB is in use.

### 2.8 ITOM Visibility **or** ITOM Discovery subscription (for the Service Graph Connector)
**Description:** The **Service Graph Connector for Microsoft Intune** requires a Subscription-Unit-based
**ITOM Visibility** or **ITOM Discovery** subscription.
**Why:** The Store connector and its Service Graph data-stream framework are entitled under ITOM.
**Verify:** Confirm the ITOM Visibility/Discovery entitlement with your ServiceNow account team, and
that the connector installs from the Store.
**Implement:** License ITOM Visibility or Discovery; **or** use the custom Integration Hub / REST +
Transform Map import path (which does not require the Store connector) — see §3.
**Verify against current ServiceNow licensing for your release.**

### 2.9 Service Graph Connector for Microsoft Intune (+ its dependencies) installed
**Description:** The Store app **"Service Graph Connector for Microsoft Intune"** and its dependencies
(Integration Hub / Flow Designer, Integration Commons for CMDB / the Service Graph framework, and the
CMDB CI Class Models) installed and active.
**Why:** These deliver the data streams, the robust transform, and IRE write-through.
**Verify:** **System Applications → All Available Applications → All** (or **Store → Downloads**); the
connector and its dependencies show **Installed**.
**Implement:** Install the connector from the ServiceNow Store; accept/plugin-activate its
dependencies. **Confirm the exact app name, version, and dependency list on the Store for your
release** (names have changed across releases).

### 2.10 ServiceNow roles to configure the connector
**Description:** An admin who can create connection & credential aliases, configure the data source,
and run the import.
**Why:** Configuring an Integration Hub connector and CMDB transform requires elevated ServiceNow
roles.
**Verify:** You hold the roles the connector documents (commonly `admin`, plus discovery/integration
admin roles such as `sn_disco.*` / `integration_hub_admin`).
**Implement:** Have a ServiceNow administrator assign the required roles. **Verify the exact role
names in the connector's docs for your release.**

### 2.11 CMDB Identification and Reconciliation (IRE) identifier for devices
**Description:** CMDB **identifier rules** for the hardware classes keyed on a stable identifier —
typically **serial number** — so Intune records dedupe against existing CIs (including the current
Workspace ONE feed's CIs).
**Why:** Without a matching identifier, the Intune feed would **create duplicate CIs** instead of
updating the existing device.
**Verify:** **Configuration → CI Class Manager → (Hardware / Computer / Handheld class) →
Identification/Reconciliation**; a serial-number-based identifier rule is active.
**Implement:** Ensure the out-of-box hardware identifier (serial number) is enabled and that both the
Intune and Workspace ONE feeds are registered as **discovery sources** so reconciliation, not
duplication, occurs. **Verify the exact class names + identifier entries for your release.**

---

## Government / sovereign cloud (GCC High / DoD) — read before configuring a Gov tenant
US Government tenants do **not** use the Commercial endpoints. The **integration model is identical**;
only the endpoints change:
- **Graph endpoint:** `https://graph.microsoft.us` (GCC High / GCC) or `https://dod-graph.microsoft.us`
  (DoD) — **not** `graph.microsoft.com`.
- **Sign-in authority:** `https://login.microsoftonline.us` — not `login.microsoftonline.com`.
- **Intune admin portal:** `https://intune.microsoft.us` (Manage endpoint on the US Gov cloud).

Configure the ServiceNow connection's OAuth token URL and Graph base URL to the **`.us` sovereign
endpoints**, and confirm the Store connector supports an overridable/sovereign endpoint (some
connector versions assume the Commercial Graph host). **Verify for GCC High** whether your connector
release exposes a configurable Graph/authority endpoint; if not, the custom Integration Hub import
(with the `.us` endpoints) is the fallback. The PowerShell validation scripts in this package are
cloud-aware — run them with `-Cloud USGov` (or `USGovDoD`).

---

## Checklist
**Microsoft**
- [ ] Intune subscription; target devices enrolled and checking in
- [ ] Entra app registration `SVC – ServiceNow CMDB – Intune Read` (client ID + tenant ID recorded)
- [ ] Client secret/cert created; **expiry date recorded**
- [ ] Graph **Application** permissions granted + **admin-consented** — `DeviceManagementManagedDevices.Read.All`, `DeviceManagementApps.Read.All`, `DeviceManagementServiceConfig.Read.All`, `Directory.Read.All`
- [ ] Egress to Graph (`graph.microsoft.com` / `graph.microsoft.us` for Gov)
- [ ] `SNOWINT-Preflight.ps1` passes

**ServiceNow**
- [ ] Supported release; CMDB in use
- [ ] ITOM Visibility or Discovery subscription (or custom-import path chosen)
- [ ] Service Graph Connector for Microsoft Intune + dependencies installed
- [ ] Configuration roles assigned
- [ ] Serial-number IRE identifier active; Intune + Workspace ONE registered as discovery sources
