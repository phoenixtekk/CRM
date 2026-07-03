# 2. Requirements Guide — Microsoft Defender for Endpoint Integration (Government / GCC High)

Confirm every requirement below **before** you configure anything. The **category-level global
requirements** (Entra tenant, Intune subscription, admin roles, enrollment, pilot group, supported
Windows, network access) are covered in `global-requirements-intune-solutions.md` — but note that
**on GCC High each of those is verified against the `.us` portals**, not the Commercial `.com`
portals. The requirements here are the **MDE-integration-specific** and **GCC-High-specific** ones.

Each entry follows: **Description · Why · Verify · Implement-if-missing.**

> **Sovereign-cloud reminder:** everywhere the global requirements say `entra.microsoft.com`,
> `intune.microsoft.com`, or `login.microsoftonline.com`, use **`entra.microsoft.us`**,
> **`intune.microsoft.us`**, and **`login.microsoftonline.us`** on GCC High.

---

## R1. GCC High tenant (US sovereign cloud)
**Description:** The tenant is a genuine **GCC High** tenant in the Azure US Government environment.
**Why:** MDE for US Government is built in Azure US Government; the connector, endpoints, and portals
only exist in the sovereign cloud. Commercial steps do not apply.
**Verify:** You can sign in at **`https://intune.microsoft.us`** and **`https://security.microsoft.us`**
and see *your* tenant. Signing in at the `.com` equivalents shows a different (or empty) tenant.
**Implement:** This is a tenant-provisioning decision made with your Microsoft Government licensing
partner; it cannot be changed after the fact. If `security.microsoft.us` does not resolve to your
tenant, confirm with your licensing partner whether you are GCC, GCC High, or DoD and use the
matching portal (see `gcc-high-parity-notes.md`).

## R2. US Government MDE licensing (GCC High SKUs)
**Description:** Each protected desktop/user is covered by a **US Gov** MDE-bearing license, and each
protected server by a **US Gov** server license — **not** the Commercial SKUs.
**Why:** MDE for US Government requires a US-Gov volume-licensing offer; Commercial MDE licenses do
not entitle the GCC High service.
**Verify:** In **`portal.office365.us`** → **Billing → Licenses**, confirm one of the GCC High
desktop offers per user, e.g. **Microsoft 365 E5 for GCC High**, **Microsoft 365 G5 Security for GCC
High**, **Microsoft Defender for Endpoint for GCC High**, or **Windows 10 Enterprise E5 for GCC
High**. (**G3** includes **Defender for Endpoint Plan 1**.) For servers, confirm **Microsoft
Defender for Endpoint Server for GCC High** or **Microsoft Defender for servers – Government**.
**Implement:** Purchase/assign the correct **GCC High** SKUs through your Government licensing
channel. Cited: Microsoft — *"…for US Government customers,"* Licensing requirements.

> **DoD tenants:** substitute the **…for DOD** SKUs (e.g. Microsoft 365 G5 for DOD). Cited: same
> source.

## R3. Administrative roles for the integration
**Description:** The operator holds the Intune RBAC permissions needed to build the connection,
onboard devices, and set risk-based compliance — plus an Entra role for Conditional Access.
**Why:** Each stage of the integration is gated by a distinct permission.
**Verify:** In **`intune.microsoft.us`** → **Tenant administration → Roles**, confirm your account
has (or is assigned a role that includes) all of:
- **Mobile Threat Defense**: *Modify* + *Read* — to establish the Intune↔Defender connection.
- **Endpoint Detection and Response**: *Assign*, *Create*, *Read*, *Update* — to onboard via EDR policy.
- **Device compliance policies**: *Assign*, *Create*, *Read*, *Update* — to set risk-level compliance.

The built-in **Endpoint Security Manager** Intune role is the least-privileged role that includes all
of these. For Conditional Access you additionally need the Entra **Conditional Access Administrator**
role (assigned in `entra.microsoft.us`).
**Implement:** Assign **Endpoint Security Manager** (or a custom Intune role with the permissions
above) in `intune.microsoft.us`; assign **Conditional Access Administrator** in `entra.microsoft.us`.
Reserve Global Administrator for tenant-wide changes only. Cited: Microsoft — Intune/Defender
integration, RBAC.

## R4. Access to the GCC High Defender portal
**Description:** You can reach and administer **`https://security.microsoft.us`** (the GCC High
Defender portal).
**Why:** You enable the Intune connection and monitor onboarding/risk here; it is where the
service-to-service toggle lives.
**Verify:** `security.microsoft.us` loads, shows your tenant, and **Settings → Endpoints** is
available.
**Implement:** Ensure your account has a Defender/Security role in the GCC High tenant (e.g. Security
Administrator) and that `*.microsoft.us` is reachable through your proxy/filtering (see R6).

## R5. Devices enrolled in Intune (GCC High) and MDE-eligible
**Description:** Target Windows devices are enrolled in the **GCC High** Intune tenant and are
**Entra ID joined or Entra hybrid joined** (required for the Windows MDE compliance integration).
**Why:** Policies only reach enrolled devices; the Windows integration requires Entra (hybrid) join.
**Verify:** `intune.microsoft.us` → **Devices → All devices** shows the device as managed; its
**Join type** is *Microsoft Entra joined* or *Microsoft Entra hybrid joined*.
**Implement:** Enroll via automatic enrollment/Entra join in the GCC High tenant. Cited: Microsoft —
Intune/Defender integration, supported platforms.

## R6. Network reachability to US Gov MDE service endpoints
**Description:** Devices can reach the **US Government** MDE onboarding/telemetry service URLs, and
admins/scripts can reach the **US Gov** sign-in, Graph, and MDE API hosts.
**Why:** If a proxy/firewall allows only specific domains, the **Gov/GCC/DoD** MDE URLs must be on
the allow-list or onboarding and sensor health fail — often *silently* (the sensor never checks in).
**Verify (devices):** From a pilot device, confirm outbound HTTPS reaches the Microsoft-published
**Gov/GCC/DoD** MDE endpoints. Microsoft publishes two lists:
- **Streamlined Connectivity URL list for Gov/GCC/DoD** (a reduced URL set or static IP ranges — a
  dedicated endpoint group supports streamlined connectivity in Government), and
- **Standard Connectivity URL list for Gov/GCC/DoD** (the full per-service DNS records).

**Verify (admin/scripts):** `login.microsoftonline.us`, `graph.microsoft.us`, and the MDE API
`api-gov.securitycenter.microsoft.us` (GCC High/DoD) / `api-gcc.securitycenter.microsoft.us` (GCC)
are reachable.
**Implement:** Add the Microsoft-published **Gov/GCC/DoD** URL/IP ranges to the proxy/firewall
allow-list (prefer the **streamlined** Gov list where supported). Cited: Microsoft — Required
connectivity settings (Gov/GCC/DoD); API. **Do not** use the Commercial MDE URL list on GCC High.

> **Downlevel/MMA note:** if you onboard a downlevel Windows Server via the Microsoft Monitoring
> Agent, you **must** select **Azure US Government** as the Azure Cloud (or set
> `OPINSIGHTS_WORKSPACE_AZURE_CLOUD_TYPE=1`); otherwise the agent points at the Commercial cloud.
> Cited: Microsoft — Endpoint versions, note.

## R7. Supported OS build for the MDE sensor (GCC High)
**Description:** Target OS is a supported build for the US Government MDE service.
**Why:** The sensor and the correct-environment onboarding depend on a supported, current build; some
downlevel builds require a specific KB **before** onboarding to point them at the Gov environment.
**Verify:** `winver` on Windows (Windows 11, or Windows 10 21H1+ recommended; older builds are
deprecated — upgrade). For servers, use the **unified/modern** solution (Server 2016 / 2012 R2 modern).
**Implement:** Bring devices to a current, supported build; for downlevel Windows 10 that still
requires it, deploy the required KB **before** onboarding so the sensor registers to the **Gov**
environment. Cited: Microsoft — Endpoint versions (the patch must be deployed *before* onboarding to
configure MDE to the correct environment).

---

### Requirements gate (must pass before Configure)
- [ ] R1 GCC High tenant confirmed at `security.microsoft.us` **and** `intune.microsoft.us`.
- [ ] R2 US Gov MDE licensing assigned (desktop + server as applicable).
- [ ] R3 Endpoint Security Manager (or equivalent) + Conditional Access Administrator held.
- [ ] R4 GCC High Defender portal reachable; **Settings → Endpoints** available.
- [ ] R5 Pilot devices enrolled and Entra (hybrid) joined in the GCC High tenant.
- [ ] R6 Gov/GCC/DoD MDE endpoints + US Gov sign-in/Graph/API reachable through filtering.
- [ ] R7 Supported OS build; required pre-onboarding KB deployed on downlevel devices.

*Sources: Microsoft Learn — "Microsoft Defender for Endpoint for US Government customers"
(licensing, portal URLs, endpoint versions, connectivity, API); "Integrate Microsoft Defender for
Endpoint with Intune for Device Compliance" (RBAC, prerequisites, supported platforms). Verify all
GCC High / DoD specifics against your tenant.*
