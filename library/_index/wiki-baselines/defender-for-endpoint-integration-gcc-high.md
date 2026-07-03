# Microsoft Defender for Endpoint Integration — Government (GCC High)

> **Version 1.0.0** · Category: Intune · Solution code: MDEG

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Microsoft Defender for Endpoint Integration (Government / GCC High)

## The problem
Microsoft Defender for Endpoint (MDE) in **GCC High** is **not** the Commercial product behind a
different sign-in. The sovereign-cloud admin portals differ (every one is a `.us` host), the device
onboarding and telemetry endpoints differ, the automation environment differs (US Gov Microsoft
Graph), and **some capabilities lag, are limited, or are absent** versus Commercial. Teams that
follow Commercial guidance on a GCC High tenant get sent to portals that show the wrong tenant and
lean on features that silently aren't there — producing gaps that only surface during an incident or
an audit.

## What this solution does
This is the **Government (GCC High) edition** of the MDE Integration solution. It takes a novice
administrator, click by click, through wiring **Defender for Endpoint** to **Microsoft Intune** on a
**US sovereign-cloud** tenant so that **device risk drives compliance and access**:

- Enable the **Intune ↔ MDE connector** in the **GCC High Defender portal** (`security.microsoft.us`).
- Onboard devices via an Intune **EDR policy** using **Auto from connector**, so the sensor registers
  to the **US Government** environment.
- Wire the **machine risk score** into a device **compliance policy**, and optionally enforce with
  **Conditional Access** (require a compliant device).
- **Pilot → validate → expand** in waves, with a gate at each boundary.

Throughout, it uses the correct **`.us` portals**, the **US Gov MDE API** base URIs, the
**Gov/GCC/DoD connectivity URL lists**, and **US Gov Graph** (`-Environment USGov`) — and it calls
out the **Commercial-vs-GCC High/DoD parity gaps** (with citations) so you configure to what your
tenant actually has.

## What's included
- Nine documents: overview (with a Commercial-vs-GCC High section), requirements, ordered
  implementation, testing gates, troubleshooting, best practices, a **cited parity reference**, this
  summary, and the shared category requirements.
- **Five PowerShell scripts** (discovery, validation, reporting, safe remediation, scope targeting),
  all connecting to **US Gov Graph**; read-only tools are read-only, change tools default to
  **`-WhatIf`**.

## Why it matters
- **Correct by construction:** sovereign portals and Gov endpoints, so nothing silently talks to the
  Commercial cloud.
- **Parity handled:** you know which features are present in GCC High/DoD and where to write a manual
  playbook — no surprises mid-incident.
- **Proven before you scale:** every capability is validated on a pilot with explicit pass/fail gates
  before fleet rollout, and each wave leaves an evidence record for audit (useful for CMMC/DoD
  programs).

## Bottom line
Microsoft Defender for Endpoint deployed **correctly on GCC High** — right portals, right endpoints,
parity gaps handled — and **proven on a pilot before you scale**. Self-guided, tested, at a fraction
of consulting cost.

*Sources: Microsoft Learn — "Microsoft Defender for Endpoint for US Government customers"; Intune ↔
Defender integration guidance. Verify GCC High / DoD specifics in your tenant.*


---


# 1. Solution Overview — Microsoft Defender for Endpoint Integration (Government / GCC High)

This is the **Government (GCC High) edition** of the Microsoft Defender for Endpoint (MDE)
Integration solution. It walks a novice administrator through wiring **Microsoft Defender for
Endpoint** to **Microsoft Intune** on a **US sovereign-cloud (GCC High)** tenant, so device risk
signals drive compliance and access — using the **`.us` admin portals**, **US Gov service
endpoints**, and **US Gov Microsoft Graph**, with the **Commercial-vs-GCC High parity gaps** called
out where they change what you can do.

> **Why a separate Government edition?** GCC High is **not** the Commercial portal behind a different
> sign-in. The admin URLs differ, the device onboarding endpoints differ, the Graph environment
> differs, and **some MDE capabilities lag, are limited, or are absent** versus Commercial. Following
> Commercial steps on a GCC High tenant leads you to portals that don't exist there and to features
> that silently aren't present. This edition gives you the **sovereign-correct** path.

## What this solution delivers

The Intune ↔ MDE integration lets Defender assess **device risk in real time** and lets Intune
**automatically mark a compromised device noncompliant**, so Conditional Access can block it from
corporate resources until it is remediated. In this edition you will:

1. **Establish the service-to-service connection** between Intune (GCC High) and MDE (GCC High).
2. **Onboard devices** to MDE using an Intune **Endpoint detection and response (EDR)** policy.
3. **Wire the MDE machine risk score into a device compliance policy.**
4. **(Recommended) Enforce with Conditional Access** — require a compliant device.
5. **Validate on a pilot**, then **expand** in waves.

## The portals you will use (GCC High — memorize these)

| Purpose | Commercial URL | **GCC High URL (use this)** |
| --- | --- | --- |
| Sign-in / authentication | `login.microsoftonline.com` | **`login.microsoftonline.us`** |
| Microsoft Entra admin center | `entra.microsoft.com` | **`entra.microsoft.us`** |
| Azure portal | `portal.azure.com` | **`portal.azure.us`** |
| Microsoft Intune admin center | `intune.microsoft.com` | **`intune.microsoft.us`** |
| Microsoft Defender portal (MDE) | `security.microsoft.com` | **`security.microsoft.us`** |
| Microsoft Purview / compliance | `compliance.microsoft.com` | **`compliance.microsoft.us`** |
| Microsoft 365 admin center | `admin.microsoft.com` | **`portal.office365.us`** |

> The Defender portal URL differs again for **DoD** (`security.apps.mil`) and **GCC**
> (`security.microsoft.com`). This solution targets **GCC High → `security.microsoft.us`**. If your
> tenant is GCC or DoD, substitute the matching portal from the table in
> `gcc-high-parity-notes.md`. Cited: Microsoft, *"Microsoft Defender for Endpoint for US Government
> customers"* — Portal URLs.

## Commercial vs GCC High — what's different

Read this before you start. These are the differences that actually change the steps:

- **Different admin portals.** Every portal is a `.us` (or `portal.office365.us`) host, not `.com`.
  A bookmark or a doc that sends you to `security.microsoft.com` is Commercial and will show you the
  wrong (or an empty) tenant.
- **Different sign-in authority.** Authentication is `login.microsoftonline.us`. Scripts and API
  clients must target the **US Gov** authority, not the Commercial one.
- **Different Microsoft Graph environment.** Automation connects with
  **`Connect-MgGraph -Environment USGov`** (US Gov L4 Graph, `graph.microsoft.us`). A script that
  omits `-Environment USGov` silently talks to the Commercial cloud and returns nothing for your
  tenant.
- **Different MDE API base URIs.** The Defender for Endpoint API is
  `https://api-gov.securitycenter.microsoft.us` for **GCC High & DoD** (and
  `https://api-gcc.securitycenter.microsoft.us` for GCC) — **not** the public
  `api.securitycenter.microsoft.com`. Cited: Microsoft, *"…for US Government customers"* — API.
- **Different device onboarding/telemetry endpoints.** Devices must reach the **US Gov service
  URLs** (the "Gov/GCC/DoD" connectivity URL lists), not the Commercial MDE endpoints. Use the
  **streamlined** Gov URL list where supported to reduce the allow-list. Cited: Microsoft — Required
  connectivity settings (Gov/GCC/DoD).
- **Feature parity gaps.** Some capabilities are **not available** in GCC High/DoD (for example
  **Microsoft Threat Experts** and **enterprise IoT security**), and **Microsoft Secure Score** is
  present but omits some recommendations. Automated investigation & response and other analytics/
  reporting/integration surfaces have historically lagged Commercial — **verify what is present in
  your tenant today.** The full, cited map is in `gcc-high-parity-notes.md`.

> Everything else — the *shape* of the integration (connector → EDR onboarding → risk into
> compliance → Conditional Access) — is the same as Commercial. The prevention, detection,
> investigation, and remediation engine is the same underlying technology, built in the Azure US
> Government environment. Cited: Microsoft, *"…for US Government customers"* — overview.

## Objects this solution creates (named, and reused across the docs)

You will create and **reuse** these exact objects throughout the guide:

| Object | Name | Where |
| --- | --- | --- |
| Pilot security group | **`SG-MDE-Pilot`** | Entra (`entra.microsoft.us`) → Groups |
| Production wave group | **`SG-MDE-Prod-Wave1`** | Entra → Groups |
| EDR onboarding policy | **`MDE - EDR Onboarding - Pilot`** | Intune → Endpoint security |
| Windows compliance policy (risk-wired) | **`CP-Windows-MDE-Risk`** | Intune → Devices → Compliance |
| Conditional Access policy (optional) | **`CA-Require-Compliant-MDE`** | Entra → Conditional Access |

## The standard deployment model

Like every solution in this library, you follow **Assess → Configure → Pilot → Validate → Expand**,
with a **gate** at each boundary (do not proceed until the gate passes):

1. **Assess** — confirm GCC High tenant, US Gov licensing, roles, portal access, and endpoint
   reachability (`02-requirements.md`).
2. **Configure** — enable the connector, create the EDR onboarding policy, wire risk into compliance
   (`03-implementation.md`).
3. **Pilot** — assign to **`SG-MDE-Pilot`** only.
4. **Validate** — run the included scripts and the Testing Guide (`05-testing.md`); confirm devices
   onboarded, sensor healthy, risk score flowing, compliance reacting.
5. **Expand** — roll out to **`SG-MDE-Prod-Wave1`** and subsequent waves, re-validating each.

## What's inside

- **`02-requirements.md`** — every prerequisite with **Verify** and **Implement-if-missing**, tuned
  for GCC High (US Gov licensing, roles, `.us` portal access, Gov connectivity URLs).
- **`03-implementation.md`** — the exact ordered click-path on the GCC High portals, with GCC-High
  caveats inline at the step where they matter, including the **Intune ↔ MDE connector for Gov**.
- **`05-testing.md`** — pass/fail validation gates.
- **`06-troubleshooting.md`** — GCC-High-specific gotchas (wrong-cloud symptoms, endpoint blocks).
- **`07-best-practices.md`** — operating guidance for a sovereign tenant.
- **`gcc-high-parity-notes.md`** — the cited Commercial-vs-GCC High/DoD parity reference.
- **5 PowerShell scripts** — discovery, validation, reporting, safe remediation, and scope-group
  targeting, all connecting to **US Gov Graph** (`-Environment USGov`).

---
*Sources: Microsoft Learn, "Microsoft Defender for Endpoint for US Government customers"
(learn.microsoft.com/defender-endpoint/gov); "Integrate Microsoft Defender for Endpoint with Intune
for Device Compliance" (learn.microsoft.com/intune). Verify all GCC High / DoD specifics against
your tenant, as US Gov availability changes over time.*


---


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


---


# Global Requirements — Intune Solutions (category-level)

These requirements apply to **every** solution in the **Intune Solutions**
category. They are published once at the category level so individual listings stay small.
Confirm these before deploying *any* Intune solution. Each entry: **Description · Why · Verify · Implement-if-missing.**

## G1. Microsoft Entra ID tenant
**Description:** An active Microsoft Entra ID (Azure AD) tenant.
**Why:** It is the identity backbone for every cloud and Intune-managed resource.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create a Microsoft 365/Azure subscription, which provisions a tenant.

## G2. Microsoft Intune subscription
**Description:** An Intune-bearing license plan.
**Why:** Intune delivers all configuration, compliance, and security policies.
**Verify:** `https://intune.microsoft.com` loads; **Tenant administration → Tenant status** shows active.
**Implement:** Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1.

## G3. Administrative roles
**Description:** Appropriate Entra/Intune admin roles for the operator.
**Why:** Creating policies and enrollment settings requires elevated rights.
**Verify:** Entra → **Roles and administrators**; confirm **Intune Administrator**.
**Implement:** Assign **Intune Administrator**; reserve Global Administrator for tenant-wide changes.

## G4. Device enrollment in Intune
**Description:** Targeted Windows devices are enrolled and manageable.
**Why:** Policies only reach enrolled devices.
**Verify:** Intune → **Devices → All devices**; the device appears and is **compliant**.
**Implement:** Enable **Automatic Enrollment** and join devices to Entra ID.

## G5. Pilot security group
**Description:** A Microsoft Entra security group for pilot/targeted users or devices.
**Why:** Every solution is piloted before fleet rollout.
**Verify:** Entra → **Groups**; the pilot group exists.
**Implement:** Entra → **Groups → New group** → **Security** → add members.

## G6. Supported Windows baseline
**Description:** Windows 10 21H2+ or Windows 11 with current updates.
**Why:** Modern Intune features assume a patched, supported OS.
**Verify:** `winver`, or Intune → device → **Hardware**.
**Implement:** Deploy **Update rings** or upgrade to Windows 11.

## G7. Network access to Microsoft cloud endpoints
**Description:** Outbound HTTPS to Microsoft 365, Entra, and Intune service URLs.
**Why:** Enrollment, policy sync, and authentication depend on these endpoints.
**Verify:** From a device, reach `https://login.microsoftonline.com` and `https://enrollment.manage.microsoft.com`.
**Implement:** Allow Microsoft's published Office 365/Intune URL & IP ranges through proxy/firewall.

---
**The standard deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


# 3. Implementation Guide — Microsoft Defender for Endpoint Integration (Government / GCC High)

Follow these steps **in order**. You use both the **GCC High Defender portal**
(**`security.microsoft.us`**) and the **GCC High Intune admin center**
(**`intune.microsoft.us`**). Group and Conditional Access work happens in the **GCC High Entra admin
center** (**`entra.microsoft.us`**). **Do not** use the `.com` portals — they are Commercial.

> **Model:** Enable the connector → EDR onboarding policy → assign to pilot → wire risk into
> compliance → (optional) require compliant device with Conditional Access → validate → expand.

> **GCC High caveat (read first):** every screen below is the *same* as Commercial in layout, but
> lives at a `.us` host and acts on your sovereign tenant. If a step sends you to a portal that shows
> a different tenant, you are on the wrong cloud — check the URL ends in `.us`.

---

## Step 1 — Turn on the Intune connection (GCC High Defender portal)
1. Open **`https://security.microsoft.us`** and sign in (authority `login.microsoftonline.us`).
2. Go to **Settings → Endpoints → Advanced features**.
3. Set **Microsoft Intune connection** to **On**.
4. Select **Save preferences**.

> **GCC High note:** this is the sovereign Defender portal. The toggle name is identical to
> Commercial, but it establishes the service-to-service link *within* the US Gov environment. Cited:
> Microsoft — Portal URLs (GCC High = `security.microsoft.us`); Intune/Defender integration
> (enable the connection).

## Step 2 — Confirm the connector in Intune (GCC High)
1. Open **`https://intune.microsoft.us`**.
2. Go to **Endpoint security → Microsoft Defender for Endpoint**.
3. Confirm **Connection status: Available / Active**. If it still shows *Unavailable*, wait a few
   minutes and select **Refresh** — the service-to-service handshake can take a short time.
4. If you plan to manage security configuration from Intune, set **Allow Microsoft Defender for
   Endpoint to enforce Endpoint Security Configurations** to **On**.

> **GCC High caveat:** the connector is Gov-to-Gov. If status never becomes *Active*, the most common
> causes are (a) you toggled the connection in the Commercial Defender portal by mistake, or (b) the
> `*.microsoft.us` endpoints are blocked by filtering (see `02-requirements.md` R6). Validate with
> **`MDEG-Validation.ps1`** (connector check).

## Step 3 — Create the pilot group (GCC High Entra)
1. Open **`https://entra.microsoft.us`** → **Groups → New group**.
2. **Group type:** Security. **Group name:** **`SG-MDE-Pilot`**.
3. Add your pilot devices (or pilot users) as members. Select **Create**.

> Reuse this exact group name in the assignment steps. Build the production wave group
> **`SG-MDE-Prod-Wave1`** the same way now or at expansion time.

## Step 4 — Create the EDR onboarding policy (GCC High Intune)
1. In **`intune.microsoft.us`** → **Endpoint security → Endpoint detection and response → Create
   Policy**.
2. **Platform:** **Windows**. **Profile:** **Endpoint detection and response**. Select **Create**.
3. **Name:** **`MDE - EDR Onboarding - Pilot`**. Select **Next**.
4. On **Configuration settings**:
   - **Microsoft Defender for Endpoint client configuration package type:** **Auto from connector**
     — the onboarding blob is supplied by the *GCC High* connection you enabled in Step 1, so the
     sensor registers to the **US Government** environment automatically. **Do not** paste a manually
     downloaded Commercial onboarding package.
   - **Sample sharing** and telemetry options: set per your organization's data-handling policy.
   Select **Next**.
5. **Scope tags:** apply if you use RBAC scoping (see `MDEG-Set-ScopeTargeting.ps1`). Select **Next**.

> **GCC High caveat:** because the package is **Auto from connector**, the correct **Gov** onboarding
> endpoints are baked in — this is the safest way to guarantee devices point at `*.microsoft.us`
> service URLs and not the Commercial endpoints. Cited: Microsoft — onboarding via Intune; Endpoint
> versions (correct-environment onboarding).

## Step 5 — Assign the onboarding policy to the pilot
1. On **Assignments**, select **Add groups** and add **`SG-MDE-Pilot`**. Select **Next**.
2. Review and select **Create**.

> **Gate — Pilot:** assign to **`SG-MDE-Pilot` only**. Do not add production groups yet.

## Step 6 — Wire the machine risk score into device compliance (GCC High Intune)
1. In **`intune.microsoft.us`** → **Devices → Compliance**.
2. Edit your Windows compliance policy, or create **`CP-Windows-MDE-Risk`** (**Create policy →
   Platform: Windows 10 and later**).
3. Under **Microsoft Defender for Endpoint**, set **Require the device to be at or under the machine
   risk score** to **Medium** (use **Low** for stricter scopes; **High** is the most permissive).
4. On **Actions for noncompliance**, keep the default *Mark device noncompliant* (tune grace period
   to your policy). Select **Save**.
5. On **Assignments**, assign to **`SG-MDE-Pilot`** (same population as onboarding). Select **Save**.

> This is the step that turns an MDE risk signal into an Intune compliance state. Cited: Microsoft —
> Intune/Defender integration (create a compliance policy to set the device risk level).

## Step 7 — (Recommended) Enforce with Conditional Access (GCC High Entra)
1. Open **`https://entra.microsoft.us`** → **Protection → Conditional Access → New policy**.
2. **Name:** **`CA-Require-Compliant-MDE`**.
3. **Users:** your pilot users. **Target resources:** the apps you want to protect.
4. **Grant:** **Require device to be marked as compliant**. Enable the policy (start in *Report-only*
   if you want to observe first).

> A device whose MDE risk exceeds your threshold (Step 6) becomes **Not compliant**, and this policy
> then blocks its access until it is remediated. Conditional Access lives in Entra and needs the
> **Conditional Access Administrator** role. Cited: Microsoft — configure Conditional Access to block
> noncompliant devices.

## Step 8 — Validate the pilot
1. On a pilot device, run **`MDEG-Discovery.ps1`** then **`MDEG-Validation.ps1`** — confirm the
   device is onboarded to the **US Gov** MDE service and the sensor is healthy.
2. Run **`MDEG-Validation.ps1`** connector check — confirms the Intune ↔ MDE connector is **Active**.
3. Run **`MDEG-Report.ps1`** — confirms devices appear onboarded and a **risk score** is flowing into
   Intune compliance.
4. Complete the **Testing Guide** (`05-testing.md`) and pass every gate.

> **Gate — Validate:** do not expand until onboarding, sensor health, connector status, risk flow,
> and compliance reaction all pass on the pilot.

## Step 9 — Expand to production (in waves)
1. Create **`SG-MDE-Prod-Wave1`** (if not already) in `entra.microsoft.us`.
2. Add **`SG-MDE-Prod-Wave1`** to the **Assignments** of both **`MDE - EDR Onboarding - Pilot`**
   (onboarding) and **`CP-Windows-MDE-Risk`** (compliance). Roll out one wave at a time.
3. Confirm risk-based compliance behaves as expected on the wave **before** broadening Conditional
   Access enforcement out of Report-only.
4. Re-validate each wave with **`MDEG-Validation.ps1`** and **`MDEG-Report.ps1`**.

> **GCC High expansion caveat:** before you lean on any **analytics/reporting/response** feature
> (e.g. automated investigation & response, advanced hunting integrations), confirm it is actually
> present in *your* GCC High/DoD tenant — several such surfaces lag Commercial. See
> `gcc-high-parity-notes.md` and **verify for GCC High/DoD** in your tenant.

---
### Order of operations
`Enable connector (security.microsoft.us) → Confirm in Intune (intune.microsoft.us) → Pilot group
(entra.microsoft.us) → EDR onboarding policy (Auto from connector) → Assign to SG-MDE-Pilot → Risk
into CP-Windows-MDE-Risk → (CA require compliant) → Validate with MDEG-* scripts → Expand in waves`

*Sources: Microsoft Learn — "Integrate Microsoft Defender for Endpoint with Intune for Device
Compliance"; "Configure Microsoft Defender for Endpoint in Intune"; "Onboard devices to Microsoft
Defender for Endpoint using Intune"; "Microsoft Defender for Endpoint for US Government customers"
(portal URLs, onboarding environment, connectivity). Verify GCC High / DoD specifics in your tenant.*


---


# 5. Testing Guide — Microsoft Defender for Endpoint Integration (Government / GCC High)

Work through every test below on the **pilot** before you expand. Each test has an explicit
**Pass / Fail** gate. All portal checks use the **`.us`** (GCC High) portals; all script checks use
the included **US Gov Graph** scripts (`-Environment USGov`).

> **Do not expand** (`03-implementation.md` Step 9) until **every** test here passes on
> **`SG-MDE-Pilot`**.

---

## T1. Connector is Active (Gov-to-Gov)
**Do:** In **`intune.microsoft.us`** → **Endpoint security → Microsoft Defender for Endpoint**, read
**Connection status**. Then run **`MDEG-Validation.ps1`** and read the connector line.
**Pass:** Portal shows **Available / Active**; the script reports the Intune↔MDE connector enabled.
**Fail:** *Unavailable* / disabled → re-check Step 1 was done in **`security.microsoft.us`** (not
`.com`), and that `*.microsoft.us` is not blocked (`02-requirements.md` R6).

## T2. Pilot device is onboarded to the US Gov MDE service
**Do:** On a pilot device run **`MDEG-Discovery.ps1`**, then **`MDEG-Validation.ps1`**.
**Pass:** The device reports **onboarded** and the sensor **running/healthy**, and the onboarding
**environment resolves to US Government** (Gov service URLs, not Commercial).
**Fail:** Not onboarded → confirm the EDR policy (`MDE - EDR Onboarding - Pilot`) is assigned to
`SG-MDE-Pilot` and the device has synced. Onboarded but pointing at Commercial endpoints → the
package was not **Auto from connector**, or a required pre-onboarding KB was missing on a downlevel
build (`02-requirements.md` R7).

## T3. Device appears in the GCC High Defender portal
**Do:** In **`security.microsoft.us`** → **Assets → Devices**, find the pilot device.
**Pass:** The device is listed with a health state and a **risk level**.
**Fail:** Absent after allowing time to check in → sensor cannot reach the **Gov** service endpoints
(R6), or you are viewing the Commercial portal (`security.microsoft.com`).

## T4. Risk score flows into Intune compliance
**Do:** Run **`MDEG-Report.ps1`**. Cross-check in `intune.microsoft.us` → **Devices → Compliance →**
`CP-Windows-MDE-Risk` → device status.
**Pass:** The pilot device shows a machine **risk score**, and its Intune **compliance state**
reflects the `CP-Windows-MDE-Risk` threshold (at/under = Compliant; above = Noncompliant).
**Fail:** No risk score in Intune → the risk setting isn't wired (Step 6) or the connector isn't
active (T1).

## T5. Risk-to-noncompliance reaction (controlled test)
**Do:** On a pilot device, generate a benign MDE detection using Microsoft's guidance (do **not** use
real malware), then re-run **`MDEG-Report.ps1`** and watch the compliance state.
**Pass:** MDE raises the device risk above your threshold and Intune flips the device to
**Noncompliant** within the expected interval.
**Fail:** Risk rises but compliance does not change → threshold in `CP-Windows-MDE-Risk` is too
permissive, or the compliance policy isn't assigned to the pilot population.

## T6. Conditional Access enforcement (if configured)
**Do:** With `CA-Require-Compliant-MDE` enabled (out of Report-only), attempt access from the
device made noncompliant in T5.
**Pass:** Access to the targeted resource is **blocked** while the device is Noncompliant; access
restores after remediation returns the device to Compliant.
**Fail:** Access still granted → CA policy is Report-only, not scoped to the test user/app, or the
device didn't reach Noncompliant (T5).

## T7. Scripts run cleanly against US Gov Graph
**Do:** Run each of **`MDEG-Discovery.ps1`**, **`MDEG-Validation.ps1`**, **`MDEG-Report.ps1`**.
**Pass:** Each connects with **`-Environment USGov`**, returns your tenant's data, and produces no
authority/endpoint errors.
**Fail:** Empty results or a Commercial-authority error → the session connected to the Commercial
cloud; reconnect with `-Environment USGov` (the scripts do this by default — see
`06-troubleshooting.md`).

## T8. Parity expectations confirmed for this tenant
**Do:** Open `gcc-high-parity-notes.md`. For each feature your rollout depends on, confirm in
`security.microsoft.us` that it is actually present in **your** GCC High/DoD tenant.
**Pass:** Every feature your design relies on is available (or you have a documented manual
playbook for the gap).
**Fail:** A relied-upon feature is absent (e.g. Microsoft Threat Experts) → adjust the design and
flag it; **verify for GCC High/DoD**.

---
### Testing gate summary
| Test | Gate |
| --- | --- |
| T1 Connector Active | Available/Active in `intune.microsoft.us` + script |
| T2 Device onboarded (Gov) | Onboarded + healthy + US Gov environment |
| T3 Device in Defender portal | Listed in `security.microsoft.us` with risk level |
| T4 Risk → compliance | Risk score visible; compliance reflects threshold |
| T5 Risk → noncompliance | Device flips Noncompliant on elevated risk |
| T6 CA enforcement | Noncompliant device blocked (if CA configured) |
| T7 Scripts vs US Gov Graph | Clean `-Environment USGov` runs, tenant data returned |
| T8 Parity confirmed | Relied-upon features present or playbooked |

*Sources: Microsoft Learn — Intune/Defender integration and US Government customers pages. Verify
GCC High / DoD specifics in your tenant.*


---


# 6. Troubleshooting — Microsoft Defender for Endpoint Integration (Government / GCC High)

Symptoms and fixes specific to running the integration on **GCC High**. Most GCC High problems trace
back to one root cause: **something is pointed at the Commercial cloud instead of the US sovereign
cloud.** Check that first.

> **Golden rule:** if a portal, script, or device "can't see the tenant / the feature is missing,"
> confirm you are on a **`.us`** host / `-Environment USGov` / a **Gov** service endpoint before
> anything else.

---

## A. Connector never becomes Active
**Symptoms:** In `intune.microsoft.us` → Endpoint security → Microsoft Defender for Endpoint,
**Connection status** stays *Unavailable*.
**Likely causes & fixes:**
1. **Toggle set in the wrong portal.** You must enable **Microsoft Intune connection** in
   **`security.microsoft.us`** (GCC High Defender portal) → **Settings → Endpoints → Advanced
   features**. If you set it in `security.microsoft.com`, it affects a Commercial tenant. Re-do in
   `.us`.
2. **`*.microsoft.us` blocked.** Filtering is dropping the sovereign endpoints. Allow the Gov/GCC/DoD
   URLs (`02-requirements.md` R6) and re-check.
3. **Propagation delay.** Wait a few minutes and select **Refresh**.
**Verify fixed:** `MDEG-Validation.ps1` reports the connector enabled and portal shows
**Available/Active**.

## B. Device onboarded but pointing at the wrong cloud
**Symptoms:** Device shows onboarded locally but never appears in `security.microsoft.us`, or appears
in the Commercial portal.
**Likely causes & fixes:**
1. **Manual Commercial onboarding package.** The EDR policy used a pasted package sourced from the
   Commercial cloud. Recreate the policy with **Configuration package type = Auto from connector**
   (`03-implementation.md` Step 4) so the **Gov** endpoints are baked in.
2. **Downlevel device missing the pre-onboarding KB.** On some downlevel Windows 10 builds the
   required KB must be deployed **before** onboarding so the sensor registers to the Gov environment.
   Offboard, deploy the KB, re-onboard. Cited: Microsoft — Endpoint versions.
3. **MMA server on Commercial cloud.** Reinstall/reconfigure the agent selecting **Azure US
   Government** (or `OPINSIGHTS_WORKSPACE_AZURE_CLOUD_TYPE=1`).
**Verify fixed:** `MDEG-Validation.ps1` resolves the onboarding environment to **US Government** and
the device appears in `security.microsoft.us`.

## C. Sensor unhealthy / not reporting
**Symptoms:** Device present but sensor state is *Inactive*/*Misconfigured*, or risk never updates.
**Likely causes & fixes:**
1. **Gov service endpoints blocked** after a network change — re-apply the streamlined/standard
   Gov/GCC/DoD URL allow-list.
2. **Time/certificate issues** on the device preventing TLS to `*.microsoft.us`.
3. **Proxy not honoring the device's system context** — MDE uses the system account; ensure the
   proxy config applies system-wide.
**Verify fixed:** `MDEG-Validation.ps1` shows the sensor healthy and last-seen recent.

## D. Risk score not flowing into Intune compliance
**Symptoms:** Device is in the Defender portal with a risk level, but Intune compliance shows no MDE
risk.
**Likely causes & fixes:**
1. **Risk not wired into the policy.** In `CP-Windows-MDE-Risk` set **Require the device to be at or
   under the machine risk score** (`03-implementation.md` Step 6).
2. **Connector not active** (see A).
3. **Compliance policy not assigned** to the device's group (`SG-MDE-Pilot` / `SG-MDE-Prod-Wave1`).
**Verify fixed:** `MDEG-Report.ps1` shows the device with a risk score and the expected compliance
state.

## E. Conditional Access not blocking a noncompliant device
**Symptoms:** A device is Noncompliant but still reaches resources.
**Likely causes & fixes:**
1. **CA policy in Report-only.** Move `CA-Require-Compliant-MDE` to **On** once validated.
2. **Scope mismatch** — the test user/app isn't in the policy's assignment.
3. **Grant control** isn't **Require device to be marked as compliant**.
**Verify fixed:** T6 in `05-testing.md` passes.

## F. Scripts return nothing / authority errors
**Symptoms:** `MDEG-*` scripts run but return empty results, or throw an authentication/authority
error.
**Likely causes & fixes:**
1. **Connected to the Commercial cloud.** The Graph session must use **`-Environment USGov`**. The
   included scripts default to this — if you customized them, restore it. Run
   `Disconnect-MgGraph` then re-run the script so it reconnects to US Gov.
2. **Wrong module version.** Ensure a current **Microsoft.Graph** module is installed
   (`Install-Module Microsoft.Graph`).
3. **Missing scopes/consent.** Re-consent the delegated scopes the script requests when prompted.
**Verify fixed:** `MDEG-Discovery.ps1` returns your tenant's devices with no authority error.

## G. "The feature isn't there" (parity, not a bug)
**Symptoms:** A capability shown in Commercial docs (e.g. Microsoft Threat Experts, enterprise IoT
security, some Secure Score recommendations, certain analytics/reporting) is missing in
`security.microsoft.us`.
**Likely cause & fix:** This is **expected parity behavior**, not a fault. GCC High/DoD lack some
capabilities and lag others. Consult `gcc-high-parity-notes.md`, confirm availability for your tenant,
and use a documented manual playbook for the gap. **Flag "verify for GCC High/DoD"** on anything
unconfirmed; do not assume Commercial behavior. Cited: Microsoft — Feature parity with commercial.

---
### Fast triage checklist
- [ ] Every portal URL ends in **`.us`** (GCC High).
- [ ] Every script session used **`-Environment USGov`**.
- [ ] EDR package is **Auto from connector** (Gov endpoints baked in).
- [ ] Gov/GCC/DoD connectivity URLs allowed through filtering.
- [ ] Downlevel devices patched **before** onboarding; MMA set to **Azure US Government**.
- [ ] Risk wired into `CP-Windows-MDE-Risk`; connector **Active**.
- [ ] Missing feature checked against `gcc-high-parity-notes.md` (parity, not a bug).

*Sources: Microsoft Learn — "Microsoft Defender for Endpoint for US Government customers"; Intune ↔
Defender integration pages. Verify GCC High / DoD specifics in your tenant.*


---


# 7. Best Practices — Microsoft Defender for Endpoint Integration (Government / GCC High)

Operating guidance for running the Intune ↔ MDE integration on a **GCC High** tenant. These build on
the implementation and testing guides and assume you have passed the pilot gates.

## Stay on the sovereign portals — always
- **Bookmark the `.us` portals** and delete Commercial bookmarks from admin workstations:
  `security.microsoft.us`, `intune.microsoft.us`, `entra.microsoft.us`, `portal.azure.us`,
  `portal.office365.us`, `login.microsoftonline.us`. A single stray `.com` bookmark is the #1 cause
  of "I don't see the tenant / the feature is missing" confusion on GCC High.
- **Standardize automation on US Gov Graph.** Every script connects with **`-Environment USGov`**;
  never let a runbook default to the Commercial cloud. The included `MDEG-*` scripts do this for you.
- **Use the correct MDE API base URI** in any custom tooling:
  `api-gov.securitycenter.microsoft.us` (GCC High/DoD) or `api-gcc.securitycenter.microsoft.us`
  (GCC) — never the public `api.securitycenter.microsoft.com`.

## Onboarding hygiene
- **Prefer "Auto from connector"** for the EDR onboarding package so devices always register to the
  **US Government** environment. Avoid manually pasted onboarding blobs, which are easy to source
  from the wrong (Commercial) cloud.
- **Patch downlevel devices before onboarding.** Some downlevel Windows 10 builds need a specific KB
  deployed *first* so the sensor points at the Gov environment; onboarding before patching can
  register the device to the wrong environment. Cited: Microsoft — Endpoint versions.
- **For MMA-based downlevel servers,** always choose **Azure US Government** as the Azure Cloud (or
  `OPINSIGHTS_WORKSPACE_AZURE_CLOUD_TYPE=1`). Prefer the modern unified solution where possible.

## Connectivity
- **Use the streamlined Gov/GCC/DoD URL list** where supported to keep the proxy/firewall allow-list
  small; fall back to the standard Gov/GCC/DoD list when a device needs the full set. Never mix in
  the Commercial URL list. Cited: Microsoft — Required connectivity settings.
- **Re-check connectivity after network changes.** A new proxy rule that drops `*.microsoft.us` will
  silently break sensor check-in; `MDEG-Validation.ps1` surfaces stale/unhealthy sensors early.

## Rollout discipline (Assess → Configure → Pilot → Validate → Expand)
- **One population at a time.** Assign onboarding and `CP-Windows-MDE-Risk` to `SG-MDE-Pilot`, then
  to `SG-MDE-Prod-Wave1`, then subsequent waves — re-validating each wave.
- **Start Conditional Access in Report-only.** Observe who *would* be blocked before enforcing
  `CA-Require-Compliant-MDE`, so a misconfigured risk threshold cannot lock users out.
- **Choose the risk threshold deliberately.** Start at **Medium**; move to **Low** only for
  high-assurance scopes after you understand the noise profile in your environment.

## Know your parity — and playbook the gaps
- **Verify feature availability in *your* tenant, not from Commercial docs.** GCC High/DoD lag
  Commercial in parts of analytics, reporting, and integration; some features are absent
  (e.g. **Microsoft Threat Experts**, **enterprise IoT security**), and **Microsoft Secure Score**
  omits some recommendations. Cited: Microsoft — Feature parity with commercial.
- **Write a manual playbook for each gap you depend on.** Where automated investigation/response or a
  reporting surface is unavailable, document the manual detection→triage→response steps your SOC will
  run instead, and **flag "verify for GCC High/DoD"** on any capability you have not personally
  confirmed present.
- **Re-check parity periodically.** US Gov availability changes over time; a feature absent today may
  reach GA later. Revisit `gcc-high-parity-notes.md` against the live Microsoft page each quarter.

## Least privilege & separation
- Operate day-to-day with **Endpoint Security Manager** (Intune) rather than Global Administrator.
- Keep **Conditional Access Administrator** separate and use it deliberately; CA changes affect
  access tenant-wide.
- Apply **scope tags** (`MDEG-Set-ScopeTargeting.ps1`) so regional/mission admins only see their
  own devices and policies.

## Change safety
- **Run remediation with `-WhatIf` first.** `MDEG-Remediation.ps1` and `MDEG-Set-ScopeTargeting.ps1`
  default to `-WhatIf`; review the planned changes, then re-run intentionally to apply.
- **Keep evidence.** Save `MDEG-Report.ps1` output per wave as your onboarding/compliance record for
  audit (CMMC/DoD programs frequently ask for it).

*Sources: Microsoft Learn — "Microsoft Defender for Endpoint for US Government customers"; Intune ↔
Defender integration pages. Verify GCC High / DoD specifics in your tenant.*


---


# 8. Deliverables Summary — Microsoft Defender for Endpoint Integration (Government / GCC High)

Everything included in the **Government (GCC High) edition** of the MDE Integration solution, and how
the pieces fit together.

## Documents

| File | What it gives you |
| --- | --- |
| `01-solution-overview.md` | The solution, the `.us` portal map, and an explicit **Commercial vs GCC High — what's different** section. |
| `02-requirements.md` | MDE-integration + GCC-High prerequisites, each with **Verify** and **Implement-if-missing**, ending in a requirements gate. |
| `03-implementation.md` | The exact ordered click-path on the **GCC High** portals, including the **Intune ↔ MDE connector for Gov**, with GCC-High caveats inline. |
| `05-testing.md` | Eight pass/fail validation gates for the pilot. |
| `06-troubleshooting.md` | GCC-High-specific symptoms and fixes (wrong-cloud root cause, endpoint blocks, parity-vs-bug). |
| `07-best-practices.md` | Operating guidance for a sovereign tenant (portals, onboarding hygiene, rollout discipline, parity playbooks, least privilege). |
| `gcc-high-parity-notes.md` | The **cited** Commercial-vs-GCC High/DoD parity reference (portals, API, licensing, connectivity, feature gaps). |
| `executive-summary.md` | One-page business framing for approvers. |
| `global-requirements-intune-solutions.md` | Category-level prerequisites shared by all Intune solutions. |

## PowerShell scripts (all connect to **US Gov Graph**, `-Environment USGov`)

| Script | Type | What it does |
| --- | --- | --- |
| `MDEG-Discovery.ps1` | Read-only | Inventories devices, onboarding state, and the sovereign context so you know your starting point. |
| `MDEG-Validation.ps1` | Read-only | Validates the Intune↔MDE connector, sensor health, and that onboarding resolves to the **US Government** environment. |
| `MDEG-Report.ps1` | Read-only | Reports onboarded devices, machine risk scores, and Intune compliance state — your per-wave evidence record. |
| `MDEG-Remediation.ps1` | Change (**`-WhatIf` default**) | Fixes common gaps (e.g. re-assigns onboarding/compliance to the correct group) after showing planned changes. |
| `MDEG-Set-ScopeTargeting.ps1` | Change (**`-WhatIf` default`**) | Applies scope tags / group targeting so regional/mission admins see only their own devices and policies. |

> **Safety:** discovery/validation/report scripts are strictly **read-only**. The two change scripts
> default to **`-WhatIf`** — they show what they *would* do; re-run intentionally (removing `-WhatIf`
> or passing `-Confirm:$false` where offered) to apply.

## Named objects you build (reused across the docs)

| Object | Name |
| --- | --- |
| Pilot security group | `SG-MDE-Pilot` |
| Production wave group | `SG-MDE-Prod-Wave1` |
| EDR onboarding policy | `MDE - EDR Onboarding - Pilot` |
| Windows compliance policy (risk-wired) | `CP-Windows-MDE-Risk` |
| Conditional Access policy (optional) | `CA-Require-Compliant-MDE` |

## How to use this solution
1. Read `01-solution-overview.md` (esp. **Commercial vs GCC High**).
2. Pass the requirements gate in `02-requirements.md`.
3. Execute `03-implementation.md` **in order** on the `.us` portals.
4. Validate against `05-testing.md` on `SG-MDE-Pilot`; use `06-troubleshooting.md` if a gate fails.
5. Expand in waves per `03-implementation.md` Step 9; keep `MDEG-Report.ps1` output as evidence.
6. Consult `gcc-high-parity-notes.md` before depending on any analytics/reporting/response feature.

*Sources: Microsoft Learn — US Government customers page; Intune ↔ Defender integration pages.
Verify GCC High / DoD specifics in your tenant.*
