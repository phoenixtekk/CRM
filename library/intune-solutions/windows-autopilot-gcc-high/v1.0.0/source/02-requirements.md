# Requirements — Windows Autopilot (Government / GCC High)

This is the **Assess** gate. Confirm **every** requirement below **before** you configure
anything in `03-implementation.md`. Each entry gives **Description · Why · Verify ·
Implement-if-missing**. The category-level prerequisites (Entra tenant, Intune subscription,
admin roles, enrollment, pilot group, Windows baseline, network access) are in
`global-requirements-intune-solutions.md` — this file adds the **GCC-High-specific** and
**device-preparation-specific** requirements on top.

> **Portal reminder:** all verification below uses the `*.us` admin centers —
> `https://intune.microsoft.us`, `https://entra.microsoft.us` *(verify for GCC High)*,
> `https://portal.azure.us`, `https://portal.office365.us`. Sign-in is at
> `https://login.microsoftonline.us`.

---

## R1. Genuine GCC High (or DoD) tenant — not Commercial/GCC

**Description:** The tenant is a **GCC High** or **DoD** government-cloud tenant (Azure
Government, IL4/IL5), not a Commercial tenant and not "GCC" (which, for Intune, *is* the
Commercial service instance).
**Why:** The supported technology, portals, and endpoints in this solution only apply to the
government cloud. Classic Autopilot's absence — and device preparation's availability — are
properties of GCC High/DoD specifically.
**Verify:** You sign in at `https://login.microsoftonline.us` and reach
`https://intune.microsoft.us`. In Intune, **Devices → Windows → Enrollment** shows the
**Windows Autopilot device preparation** tile and you do **not** see a classic "Windows
Autopilot" / "Deployment Profiles" import. `WAPG-Discovery.ps1` reports the Graph environment
as **USGov**.
**Implement:** If you are on Commercial/GCC, this solution's sovereign steps do not apply —
use the Commercial edition instead. There is **no in-place migration** between Commercial and
the government cloud (devices must unenroll and re-enroll). *(Microsoft, Intune Government
Service overview.)*

## R2. US Government licensing (Gov SKUs)

**Description:** Users are licensed with **US Government** plans that include Intune and
Microsoft Entra ID — e.g. **Microsoft 365 G3/G5 (GCC High)** or standalone **Intune Plan 1
for Government**.
**Why:** Device preparation, MDM enrollment, and policy delivery require an Intune-bearing
Gov license on the provisioning user.
**Verify:** `https://portal.office365.us` → **Users → Active users** → the pilot user shows a
Gov license with Intune; `https://intune.microsoft.us` → **Tenant administration → Tenant
status** shows active.
**Implement:** Assign the appropriate **Government** SKU (not the Commercial SKU) to each
provisioning/pilot user.

## R3. Administrative roles for device preparation

**Description:** The operator holds sufficient Entra/Intune roles: **Intune Administrator**
(or the least-privilege `WAPG Device Preparation Administrator` role this solution creates),
plus **Global Administrator** available for the one-time service-principal/consent steps.
**Why:** Creating device preparation profiles, enrollment settings, and the assigned device
group requires elevated rights; the least-privilege role needs the **Enrollment time device
membership assignment** permission specifically.
**Verify:** `https://entra.microsoft.us` *(verify for GCC High)* → **Roles and administrators**
→ confirm **Intune Administrator**.
**Implement:** Assign **Intune Administrator**; build the scoped `WAPG Device Preparation
Administrator` role in `03-implementation.md` Step 4 for day-to-day operators.

## R4. Supported Windows 11 build for device preparation

**Description:** Target devices run a **device-preparation-supported** Windows 11 build:
**Windows 11 24H2 or later**, **or** Windows 11 **23H2/22H2 with KB5035942** (March 2024
build 22621/22631.3374) **or later**.
**Why:** Windows Autopilot **device preparation** has a higher OS floor than classic
Autopilot. **Windows 10 is not supported** for device preparation.
**Verify:** On the device, run `winver`; or in Intune → device → **Hardware**.
**Implement:** Re-image/refresh with compliant OEM-optimized Windows 11 media (24H2, or
22H2/23H2 patched to KB5035942 or later). *(Microsoft, Autopilot device preparation overview
→ Requirements.)*

## R5. Device not already registered as a classic Autopilot device

**Description:** The target device is **not** registered/added as a **Windows Autopilot**
device anywhere.
**Why:** If a device is registered as a classic Autopilot device, the **Autopilot profile
takes precedence** over the device preparation policy and provisioning follows the (absent)
classic path.
**Verify:** The device does not appear under any Windows Autopilot registration. (In GCC High
you generally will not have this surface at all; the risk is a device previously registered in
a *Commercial* tenant.)
**Implement:** **Deregister** the device from Windows Autopilot before provisioning via device
preparation. *(Microsoft, Autopilot device preparation overview.)*

## R6. Intune Provisioning Client service principal present

**Description:** The **Intune Provisioning Client** first-party service principal
(**AppId `f1346770-5b25-470b-88bd-d5744ab7952c`**, sometimes named **Intune Autopilot
ConfidentialClient**) exists in the tenant and can be added as a **group owner**.
**Why:** Enrollment Time Grouping works by this principal **owning** the assigned device
group. Without it, the device group stays empty at OOBE and nothing deploys.
**Verify:** `WAPG-Discovery.ps1` reports the principal as **FOUND**; or search for the AppId
under **Enterprise applications** in `https://entra.microsoft.us`.
**Implement:** Open `https://intune.microsoft.us` once as **Global Administrator** to
provision the principal; re-run `WAPG-Discovery.ps1` to confirm.

## R7. Users may join devices to Microsoft Entra + automatic enrollment enabled

**Description:** Provisioning users are permitted to **Entra-join** devices, and **automatic
MDM enrollment** is enabled for their scope.
**Why:** The user-driven flow Entra-joins the device and auto-enrolls it into Intune during
OOBE.
**Verify:** `https://entra.microsoft.us` *(verify for GCC High)* → **Devices → Device
settings** → **Users may join devices to Microsoft Entra** includes your provisioning users;
`https://intune.microsoft.us` → **Devices → Enrollment → Automatic Enrollment** → **MDM user
scope** covers them.
**Implement:** Set both in `03-implementation.md` Step 3.

## R8. Microsoft Graph PowerShell SDK with US Gov environment

**Description:** The **Microsoft.Graph** PowerShell SDK is installed on the operator
workstation and can connect with **`-Environment USGov`** (or `USGovDoD`).
**Why:** All five scripts in this solution connect to **US Gov Graph** (`graph.microsoft.us`);
a Commercial/Global connection queries the wrong cloud.
**Verify:** `Get-Module -ListAvailable Microsoft.Graph`; then
`Connect-MgGraph -Environment USGov` and confirm `(Get-MgContext).Environment` prints
**USGov**.
**Implement:** `Install-Module Microsoft.Graph -Scope CurrentUser`. *(Microsoft, Microsoft
Graph national cloud deployments.)*

## R9. Sovereign endpoints reachable; no SSL inspection on the MDM service

**Description:** The provisioning network reaches the **`*.us` sovereign endpoints** and
exempts the Intune MDM service from SSL inspection.
**Why:** Enrollment, policy sync, authentication, and the device-preparation deployment
service all depend on these endpoints; `*.manage.microsoft.us` must **not** be SSL-inspected.
**Verify:** From the provisioning network, resolve/reach `login.microsoftonline.us`,
`portal.manage.microsoft.us`, `graph.microsoft.us`,
`enterpriseregistration.microsoftonline.us`, and `login.live.com`; confirm NTP (UDP 123) to
`time.windows.com`; confirm `*.manage.microsoft.us` is inspection-exempt.
**Implement:** Allow Microsoft's published **US Government** URL/IP ranges through the
proxy/firewall and exempt `*.manage.microsoft.us` from TLS inspection. Do **not** paste
Commercial `*.manage.microsoft.com` values. *(Microsoft, Network endpoints for US government
deployments; Autopilot device preparation requirements → Networking.)*

## R10. (Conditional) Corporate identifiers, only if blocking personal devices

**Description:** If you use **enrollment restrictions** to block personal Windows enrollment,
the trusted devices' **corporate identifiers** (manufacturer/model/serial) are pre-uploaded.
**Why:** Device preparation only needs corporate identifiers when enrollment restrictions
would otherwise block the device — it is **not** the classic Autopilot hardware-hash import.
**Verify:** `https://intune.microsoft.us` → **Devices → Enrollment → Corporate device
identifiers** lists the trusted devices.
**Implement:** Upload identifiers per `03-implementation.md` Step 11 (only if you block
personal devices). *(Microsoft, Autopilot device preparation overview → Corporate identifiers.)*

---

## Assess gate (pass/fail summary)

Proceed to **Configure** only when **all** are TRUE:

- [ ] R1 — Confirmed **GCC High/DoD** (Graph **USGov**; device-preparation tile present; no classic Autopilot blade).
- [ ] R2 — Provisioning/pilot users hold **Gov** Intune licensing.
- [ ] R3 — Operator has **Intune Administrator** (Global Admin available for one-time steps).
- [ ] R4 — Devices run a **device-preparation-supported Windows 11** build (not Windows 10).
- [ ] R5 — Target devices are **not** registered as classic Autopilot devices.
- [ ] R6 — **Intune Provisioning Client** principal exists and can own a group.
- [ ] R7 — Users may **Entra-join**; **automatic enrollment** covers them.
- [ ] R8 — **Microsoft.Graph** SDK installed; `-Environment USGov` connects.
- [ ] R9 — Sovereign endpoints reachable; `*.manage.microsoft.us` **not** SSL-inspected.
- [ ] R10 — (If blocking personal devices) corporate identifiers uploaded.

## Sources

- Microsoft, *Microsoft Intune Government Service overview* (GCC High/DoD availability;
  no Commercial↔Gov migration).
- Microsoft, *Overview / requirements of Windows Autopilot device preparation* (Windows 11
  build floor, Entra-join only, Provisioning Client owner, corporate identifiers, Autopilot
  precedence).
- Microsoft, *Network endpoints for US government deployments* (sovereign endpoints, no SSL
  inspection).
- Microsoft, *Microsoft Graph national cloud deployments* (`-Environment USGov`).
