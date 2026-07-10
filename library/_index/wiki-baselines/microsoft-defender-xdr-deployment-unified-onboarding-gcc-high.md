# Microsoft Defender XDR Deployment & Unified Onboarding — Government (GCC High)

> **Version 1.0.0** · Category: Defender · Solution code: DEFXDRG

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Microsoft Defender XDR Deployment & Unified Onboarding — Government (GCC High)

**White-label · Defender · Government (GCC High) edition**

**For US public-sector and Defense-Industrial-Base tenants.** This is the sovereign-cloud edition of the
unified Defender XDR onboarding method — the identical commercial approach, adapted for Microsoft's US
Government national cloud (`security.microsoft.us`, Azure Government `portal.azure.us`, `graph.microsoft.us`
/ DoD `dod-graph.microsoft.us`, `login.microsoftonline.us`, Intune `intune.microsoft.us`). Because GCC High
and DoD can lag commercial in **pillar, feature, connector, and preview availability**, every such point is
flagged **verify against current Microsoft Government documentation**, and the edition ships a dedicated
`gcc-high-parity-notes.md` covering endpoints, parity gaps, and FedRAMP High / DoD IL4-5 / CMMC / ITAR
data-residency context.

Most tenants already own Microsoft Defender XDR but run it as four disconnected point products — Defender for Endpoint in one console, Defender for Identity in another, Defender for Office 365 in the Exchange/email world, and Defender for Cloud Apps somewhere else. A modern attack that moves **identity → endpoint → email → cloud** is seen only in fragments, and each console only tells part of the story. This solution onboards all four pillars into the **unified Defender portal at `security.microsoft.us`**, turns on **cross-pillar incident correlation**, sets a **unified RBAC** role model, and establishes a **Secure Score baseline** — so one portal sees the whole attack.

This is a complete, **deploy-it-today** package written for an administrator with no prior Defender XDR experience. It onboards a **pilot ring first**, keeps automated response in an **approval/simulate** posture until trusted, and never disables an existing control to "test."

## What you get
- A plain-language **Solution Overview** of the four pillars, the unified portal, cross-domain correlation, unified RBAC, and Secure Score.
- A **Requirements Guide** with verify / implement-if-missing for every solution-specific prerequisite.
- An **Implementation Guide** of exact, ordered portal steps — onboard Endpoint, deploy Identity sensors, activate Office 365 and Cloud Apps, wire unified RBAC, and baseline Secure Score, pilot-first.
- Five **PowerShell scripts** (Microsoft Graph Security + Az) plus **KQL advanced-hunting** queries for readiness discovery, per-pillar validation, coverage/Secure-Score reporting, a `-WhatIf`-gated pilot-ring onboarding helper, and a cross-pillar correlation hunt.
- **Testing** and **Troubleshooting** guides for a confident rollout.

## What this delivers
Four Defender pillars — **Endpoint (MDE)**, **Identity (MDI)**, **Office 365 (MDO)**, and **Cloud Apps (MDCA)** — onboarded into the single portal at `security.microsoft.us`, **unified incident correlation** stitching alerts from all pillars into one incident, a **unified role-based access** model so analysts get one consistent permission set, and a **Secure Score baseline** you can trend — all proven on a pilot ring before tenant-wide expansion.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand** — onboard a pilot ring, keep automated response approval-gated, validate correlation, then expand.

## Boundary
This solution **onboards the Defender XDR suite itself** into the unified portal. It is distinct from a SIEM-integration engagement that streams XDR into Microsoft Sentinel — that is a separate, adjacent solution. Incident-response decisions, automated-response guardrails, and licensing determinations remain the customer's security, operations, and licensing functions; this guide provides the technical configuration. **Government-edition boundary:** GCC High/DoD **pillar, feature, and connector availability** must be confirmed against current Microsoft Government documentation, and the **accreditation boundary / impact-level** determination is the customer's ISSO/compliance decision — this guide supplies the technical method, not the authorization.

## Effort
A competent administrator can complete the pilot-ring onboarding and validation in a focused engagement, then expand on a controlled cadence. Sensor deployment on domain controllers and endpoint onboarding scale with device/DC count.


---


# 1. Solution Overview — Microsoft Defender XDR Deployment & Unified Onboarding — Government (GCC High)

> **Government (GCC High) edition.** This is the US Government national-cloud edition for public-sector
> and Defense-Industrial-Base (DIB) tenants. It mirrors the commercial onboarding method exactly, adapted
> for the **sovereign cloud**: the unified Defender portal is **`security.microsoft.us`**, Azure/Entra
> live in **Azure Government** (`portal.azure.us`), Microsoft Graph is **`graph.microsoft.us`** (DoD:
> `dod-graph.microsoft.us`), and sign-in is **`login.microsoftonline.us`**. Whether specific Defender
> **pillars** (MDE/MDI/MDO/MDCA), features, connectors, or previews are available — and their advanced-
> hunting tables — **can lag or differ in GCC High and DoD** and is flagged throughout **verify against
> current Microsoft Government documentation**. See `gcc-high-parity-notes.md` for the endpoint table,
> pillar/feature parity gaps, and FedRAMP High / DoD IL4-5 / CMMC / ITAR context.

## What Microsoft Defender XDR is
Microsoft Defender XDR (extended detection and response) is a suite of four security products that share one portal and one incident model at `security.microsoft.us` (GCC High):

- **Defender for Endpoint (MDE)** — endpoint detection and response (EDR), antivirus, and vulnerability signal from Windows, macOS, Linux, iOS, and Android devices.
- **Defender for Identity (MDI)** — on-premises Active Directory / AD FS threat detection from sensors installed on domain controllers and federation servers.
- **Defender for Office 365 (MDO)** — email and collaboration protection (Safe Links, Safe Attachments, anti-phishing) for Exchange Online, Teams, SharePoint, and OneDrive.
- **Defender for Cloud Apps (MDCA)** — cloud-app discovery and control (CASB), session policies, and SaaS risk signal.

Onboarded together, these pillars feed a **single incident queue** where alerts that belong to the same attack are automatically **correlated** into one incident — so an analyst sees an attack move from a phished mailbox (MDO) to a signed-in identity (MDI) to a compromised laptop (MDE) to a risky OAuth grant (MDCA) as **one story**, not four disconnected alerts.

## Why this matters
Nearly every Microsoft 365 E5 / E5 Security tenant already **owns** these products, but they are commonly run as silos: the endpoint team lives in one console, the email team in another, and Cloud Apps and Identity are barely touched. Cross-domain attacks are exactly the ones that slip between those seams — the alert in each console looks like low-severity noise, but together they are a clear intrusion. Bringing all four into the unified portal turns those fragments into **correlated incidents**, gives every analyst **one consistent permission model** instead of four separate RBAC systems, and produces a single **Secure Score** you can baseline and improve. The goal is one correlated XDR portal that sees the whole attack, proven on a small pilot ring before it changes anything tenant-wide.

## How it works
1. **Defender for Endpoint** is activated and devices are **onboarded** to a **pilot ring** first — via Intune (endpoint security / EDR policy), Group Policy, or a local onboarding script — so devices start reporting EDR signal to the portal.
2. **Defender for Identity** is activated and lightweight **sensors** are installed on **domain controllers** (and AD FS / AD CS servers where present) to detect identity attacks against on-prem AD.
3. **Defender for Office 365** and **Defender for Cloud Apps** are activated in the portal; their policies (Safe Links / Safe Attachments for MDO, app connectors / session control for MDCA) begin in a monitor-first posture.
4. **Cross-pillar incident correlation** is confirmed — alerts from all four pillars land in the single **Incidents** queue and are automatically grouped, and **advanced hunting** shows every pillar's tables (device, identity, email, cloud-app) streaming.
5. **Unified RBAC** is configured in the Defender portal so a single role model (reader / operator / admin) governs access across all pillars, replacing per-pillar permissions.
6. **Secure Score** is captured as a **baseline** and the top recommendations are triaged, giving a single posture number to trend over time.
7. **Automated response (AIR)** is kept in an **approval / simulate** posture during the pilot and only moved toward automatic remediation once the correlation and coverage are trusted.

## What you can control
- **Onboarding channel per pillar** — Intune / GPO / script for endpoints; sensor install for identity; portal activation and policy for email and cloud apps.
- **Pilot ring** — which devices, users, and sensors onboard first before tenant-wide expansion.
- **Unified RBAC** — one role model (reader / operator / admin) across all four pillars instead of four separate permission systems.
- **Automated-response posture** — approval-required or full-automation levels, kept approval-gated until trusted.
- **Secure Score focus** — which recommendations to remediate first against the baseline.

## Limitations (be honest with buyers)
- Each pillar and several features are **license-gated** (e.g. Defender for Endpoint P1/P2, Defender for Identity, Defender for Office 365 P1/P2, Defender for Cloud Apps). Onboarding without the plan fails or silently limits features. In **GCC High/DoD**, whether a given pillar, feature, connector, or preview is even **available** can lag or differ from commercial — *verify current Government availability against Microsoft Government documentation; do not assume commercial parity.*
- **Defender for Identity sensors** run on domain controllers and require resources, network reach, and a change window; they are not a portal-only toggle.
- **Correlation and advanced-hunting tables** populate over time — expect a delay after onboarding before all pillars show signal.
- This solution **onboards the XDR suite into its own unified portal**; it does **not** stream XDR into Microsoft Sentinel — that SIEM integration is a separate, adjacent solution.
- XDR improves detection and response; it does not replace patching, backup, identity hardening, or the SOC's incident-response decisions.

## Connections and authentication used
- The **unified Defender portal** (`security.microsoft.us` — GCC High) for all pillar activation, RBAC, incidents, and Secure Score.
- **Microsoft Graph Security** and the **Microsoft 365 Defender** APIs (via the `Microsoft.Graph` PowerShell modules) for read-only discovery, validation, reporting, and advanced-hunting queries — connected to the US Gov cloud with **`Connect-MgGraph -Environment USGov`** (`graph.microsoft.us`; **DoD: `-Environment USGovDoD` / `dod-graph.microsoft.us`** — *verify your cloud*).
- **Az PowerShell** (`Connect-AzAccount -Environment AzureUSGovernment`) where a Log Analytics workspace in **Azure Government** is used for continuous export.
- **Intune / Microsoft Endpoint Manager** (or GPO / script) as the endpoint onboarding channel — the GCC High Intune admin center (**`intune.microsoft.us`** — *verify current GCC High portal URL*).
- Sign-in / token host is **`login.microsoftonline.us`**.
- Least-privilege roles: **Security Administrator** for configuration, **Security Reader** for read-only work, and **Global Administrator** only for one-time first-service activation.

## The standard deployment model
> **Assess readiness (licenses, roles, onboarding reach) → configure/activate each pillar → onboard a pilot ring (devices, sensors, users) → validate correlation, RBAC, and Secure Score on the pilot → expand tenant-wide.** Repeatable pattern: **Assess → Configure → Pilot → Validate → Expand**, with automated response kept approval-gated until trusted.


---


# 2. Requirements Guide — Microsoft Defender XDR Deployment & Unified Onboarding

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify · Implement-if-missing.** Category-wide prerequisites (tenant, licensing, admin roles, onboarding reach, network access, pilot ring, workspace, response governance) are in `global-requirements-defender.md` — do not repeat them; the items below are **specific to onboarding the four XDR pillars into the unified portal**. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

> **GCC High / DoD parity caveat (read before you scope).** This is the **Government (GCC High)**
> edition. Portals are national-cloud (`security.microsoft.us`, `portal.azure.us`, `graph.microsoft.us`
> / DoD `dod-graph.microsoft.us`, `login.microsoftonline.us`; Intune admin center `intune.microsoft.us`
> — *verify current GCC High portal URL*). Critically, **whether a given Defender pillar (MDE/MDI/MDO/
> MDCA), feature, connector, unified-RBAC capability, or preview is available in GCC High/DoD — and its
> advanced-hunting tables — can lag or differ from commercial.** Do **not** assume commercial parity;
> **verify each against current Microsoft Government documentation** and confirm in your tenant. Full
> endpoint table and parity/compliance context are in `gcc-high-parity-notes.md`.

## 2.1 Unified Defender portal reachable and initialized
**Description:** Access to `https://security.microsoft.us` with the unified portal experience available for the tenant.
**Why:** Every pillar is activated, correlated, and governed from this single portal; onboarding starts here.
**Verify:** Sign in to `security.microsoft.us` as a Security Administrator and confirm **Incidents**, **Assets**, **Settings**, and **System → Permissions and roles** load. Run `DEFXDRG-Discovery.ps1`.
**Implement-if-missing:** Confirm the tenant is provisioned and the required admin role is assigned; the portal initializes on first admin sign-in.

## 2.2 Endpoint onboarding channel (Intune / GPO / script)
**Description:** A working management channel to onboard devices to Defender for Endpoint — Intune (or Configuration Manager), Group Policy, or the local onboarding script — targeting a **pilot ring** first.
**Why:** MDE collects EDR signal only from onboarded devices; the channel must reach the pilot devices before any expansion.
**Verify:** Intune enrolled devices exist (or GPO reaches the pilot OU); `DEFXDRG-Discovery.ps1` reports onboarding coverage.
**Implement-if-missing:** Establish the onboarding channel (see the adjacent Intune *Defender for Endpoint Integration* solution) and create the pilot device group `MDE Onboarding – Pilot Ring – Pilot`.

## 2.3 Domain controllers reachable for Defender for Identity sensors
**Description:** Domain controllers (and AD FS / AD CS servers where present) that can host the **Defender for Identity sensor**, with outbound reach to the MDI service and a change window to install.
**Why:** MDI detects on-prem identity attacks from sensors installed directly on these servers; there is no agentless option for AD.
**Verify:** Confirm DC OS version support, resources, and network reach to the MDI service URLs; `DEFXDRG-Discovery.ps1` lists candidate DCs and sensor status. *Verify current sensor OS support and endpoint list.*
**Implement-if-missing:** Schedule a change window, confirm sensor prerequisites, and plan the sensor install per DC (Step 3 of the Implementation Guide).

## 2.4 Directory Service account for MDI (where required)
**Description:** A read-only **Directory Service Account (DSA)** for Defender for Identity, per current MDI guidance (gMSA recommended).
**Why:** The sensor uses the DSA to query AD for additional context; without it, some detections are limited.
**Verify:** Confirm a gMSA (or standard read-only account) is created and configured in MDI settings; `DEFXDRG-Discovery.ps1` notes DSA configuration. *Verify current MDI DSA requirements.*
**Implement-if-missing:** Create the gMSA and register it under **Settings → Identities → Directory Service accounts** in the portal.

## 2.5 Exchange Online / collaboration workloads for MDO
**Description:** Exchange Online mail flow (and Teams/SharePoint/OneDrive where MDO covers collaboration) in the tenant.
**Why:** Defender for Office 365 policies (Safe Links, Safe Attachments, anti-phishing) apply to these workloads; without them there is nothing to protect.
**Verify:** `security.microsoft.us` → **Email & collaboration → Policies & rules**; confirm the tenant routes mail through Exchange Online.
**Implement-if-missing:** Confirm Exchange Online is the mail path and the MDO plan (P1/P2) is licensed. *Verify current MDO plan features in your tenant.*

## 2.6 Cloud Apps activation and (optional) app connectors for MDCA
**Description:** Defender for Cloud Apps enabled, with the automatic **Defender for Endpoint integration** for discovery and any **app connectors** for the SaaS apps you intend to govern.
**Why:** MDCA discovers and controls cloud-app usage; connectors and the MDE integration are what feed it signal.
**Verify:** `security.microsoft.us` → **Cloud apps → Cloud discovery / App connectors**; `DEFXDRG-Discovery.ps1` reports MDCA status.
**Implement-if-missing:** Turn on Cloud Apps, enable the MDE-to-MDCA discovery integration, and add connectors for priority SaaS apps (monitor-first).

## 2.7 Pilot ring defined (devices, users, sensors)
**Description:** A named pilot ring: pilot **devices** (`MDE Onboarding – Pilot Ring – Pilot`), pilot **users** (`XDR Pilot Users – Pilot Ring – Pilot`), and the first **domain controller(s)** to carry a sensor.
**Why:** XDR onboarding and any automated response are validated on a ring before tenant-wide rollout (per `global-requirements-defender.md` G6).
**Verify:** The groups exist in Entra/Intune and the pilot DC is chosen; `DEFXDRG-Validate.ps1` checks membership.
**Implement-if-missing:** Create the two groups and select the pilot DC before onboarding anything that acts automatically.

## 2.8 Unified RBAC role decision
**Description:** A decision to adopt the Defender portal's **unified role-based access control** and the roles to grant (reader / operator / admin) across all pillars.
**Why:** Unified RBAC replaces four separate per-pillar permission systems with one; the role model must be agreed before granting access.
**Verify:** `security.microsoft.us` → **System → Permissions and roles**; confirm unified RBAC is available and note current per-pillar permissions. *Verify current unified RBAC activation steps in your tenant.*
**Implement-if-missing:** Plan the role assignments `XDR Security Reader – Tenant – Prod` and `XDR Security Operator – Tenant – Prod` (Step 6).

## 2.9 Response governance position
**Description:** An agreed position on **automated investigation and response (AIR)** — approval-required vs automatic remediation levels — kept approval-gated during the pilot.
**Why:** AIR can take disruptive actions (isolate device, delete mail, disable user); the organization must decide the guardrails (per `global-requirements-defender.md` G8).
**Verify:** A documented response policy exists; automation is in an approval/simulate posture. `DEFXDRG-Validate.ps1` reports the current AIR automation level.
**Implement-if-missing:** Keep AIR approval-gated at first; *incident-response and automation guardrail decisions are the SOC/security team's — this guide covers the technical configuration.*

---
## Checklist
- [ ] Unified Defender portal reachable and initialized — `DEFXDRG-Discovery.ps1`
- [ ] Endpoint onboarding channel (Intune/GPO/script) + pilot device group
- [ ] Domain controllers reachable for MDI sensors + change window
- [ ] MDI Directory Service Account (gMSA) prepared
- [ ] Exchange Online / collaboration workloads present for MDO
- [ ] Cloud Apps enabled + MDE discovery integration / connectors
- [ ] Pilot ring defined (devices, users, sensor DC) — `DEFXDRG-Validate.ps1`
- [ ] Unified RBAC role decision made
- [ ] Response governance (AIR approval-gated) documented


---


# Global Requirements — Defender (category-level)

These requirements apply to every solution in the Defender category (Microsoft Defender XDR and Defender
for Cloud). Published once at the category level so listings stay small. Confirm before deploying any
Defender solution. Each entry: Description / Why / Verify / Implement-if-missing.

> Defender changes touch detection and response for the whole tenant. Onboard in a ring (pilot devices/
> users first), keep automated response in an approval/simulate posture until trusted, and never disable
> an existing control to "test."

## G1. Microsoft 365 / Entra tenant
Description: An active Microsoft 365 tenant with Entra ID.
Why: Defender XDR services and the unified portal (security.microsoft.com) are tenant workloads.
Verify: Sign in to `https://security.microsoft.com` as an administrator.
Implement: Provision a Microsoft 365 tenant and confirm Entra ID identities exist.

## G2. Defender licensing
Description: The Defender plans for the pillars in scope — e.g. Defender for Endpoint P1/P2, Defender for Identity, Defender for Office 365 P1/P2, Defender for Cloud Apps, and Defender for Cloud plans.
Why: Each pillar/feature is license-gated; onboarding without the plan fails or silently limits features.
Verify: Admin center -> `Billing -> Licenses` (or the Defender portal). *Confirm the exact plan each feature needs — verify current availability in your tenant.*
Implement: Assign the required plans (often bundled in M365 E5 / E5 Security) before onboarding.

## G3. Administrative roles (least privilege)
Description: Security Administrator (and Global Administrator for first-time service activation).
Why: Onboarding, RBAC, and policy changes in the Defender portal require these roles.
Verify: Entra -> `Roles and administrators`; confirm Security Administrator.
Implement: Assign Security Administrator; reserve Global Administrator for one-time activations.

## G4. Onboarding reach to endpoints / identity / workloads
Description: A management channel to onboard the pillars — Intune/Configuration Manager/GPO/script for endpoints, domain controllers/AD FS for Identity sensors, and cloud connectors for Defender for Cloud.
Why: Each pillar collects signal from a source that must be reachable and instrumented.
Verify: Endpoints are managed (Intune/CM); DCs are reachable; cloud subscriptions are connected. Run the solution's discovery script.
Implement: Establish the onboarding channel per pillar (see the relevant catalog endpoint/identity solutions).

## G5. Network access to Defender service endpoints
Description: Outbound HTTPS to the Microsoft Defender / Microsoft 365 service URLs from onboarded assets.
Why: Sensors and agents report to the cloud service; blocked endpoints break onboarding and detections.
Verify: Confirm the documented Defender endpoint URLs/IP ranges are allowed. *Verify current endpoint list.*
Implement: Allow the Defender/M365 endpoints through proxy/firewall.

## G6. A pilot ring
Description: A defined set of pilot devices/users/subscriptions to onboard first.
Why: XDR onboarding and automated response are validated on a ring before tenant-wide rollout.
Verify: A pilot group exists in Entra/Intune.
Implement: Create the pilot ring before enabling anything that acts automatically.

## G7. Log Analytics workspace (where required)
Description: A Log Analytics workspace for Defender for Cloud / advanced hunting export where used.
Why: Some Defender data and continuous export land in a workspace.
Verify: A workspace exists and is access-controlled. Run the discovery script.
Implement: Provision a workspace (or reuse the SIEM/observability one) with least-privilege access.

## G8. Response governance
Description: An agreed position on automated response (auto-remediation levels, approval requirements).
Why: XDR/AIR can take disruptive actions (isolate, delete, disable); the organization must decide the guardrails.
Verify: A documented response policy exists; automation is in an approval/simulate posture until trusted.
Implement: Define response guardrails; keep AIR/automation approval-gated at first. *Incident-response decisions are the SOC/security team's; this guide covers the technical configuration.*

---
The deployment model (all solutions): Assess -> Configure -> Pilot -> Validate -> Expand.


---


# 3. Implementation Guide — Microsoft Defender XDR Deployment & Unified Onboarding

Follow these steps **in order**. Most work is in the **unified Defender portal** (`https://security.microsoft.us` — GCC High); endpoint onboarding uses the **GCC High Intune admin center** (`https://intune.microsoft.us` — *verify current GCC High portal URL*) as the default channel. Sign-in is `login.microsoftonline.us`; Entra/Azure are in **Azure Government** (`portal.azure.us`). Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

> **National-cloud note (GCC High).** All portal URLs below are the US Gov equivalents; the delivered scripts default to the US Gov cloud (`Connect-MgGraph -Environment USGov` / `Connect-AzAccount -Environment AzureUSGovernment`; DoD: `-Environment USGovDoD`). **Whether a given pillar/feature/connector is available in GCC High/DoD — verify against current Microsoft Government documentation before enabling it.**

> **Model:** Activate each pillar, onboard a **pilot ring** first (a few devices, one or two DCs, a pilot user group), validate that all four pillars stream signal and correlate, and only then expand. Keep **automated response (AIR)** in an **approval/simulate** posture throughout the pilot. Never disable an existing control to "test."

## Naming (set once, reuse verbatim)
- Pilot device group (Entra/Intune): `MDE Onboarding – Pilot Ring – Pilot`
- Pilot user group (Entra): `XDR Pilot Users – Pilot Ring – Pilot`
- Intune EDR onboarding profile: `MDE Onboarding – Pilot Ring – Pilot`
- Unified RBAC role assignment (read-only): `XDR Security Reader – Tenant – Prod`
- Unified RBAC role assignment (operator): `XDR Security Operator – Tenant – Prod`
- Advanced-hunting saved query: `XDR Cross-Pillar Correlation Check – Tenant – Validate`

## Step 1 — Assess readiness
1. Sign in to `security.microsoft.us` as a **Security Administrator**.
2. Run `DEFXDRG-Discovery.ps1` to capture the current state: licensed Defender plans, admin roles, which pillars are already active, device onboarding coverage, candidate domain controllers for MDI, and MDO/MDCA status.
3. In **Entra** (via the Azure Government portal `portal.azure.us` → **Microsoft Entra ID**; the Entra admin center national-cloud URL — *verify current GCC High portal URL*) → **Groups**, create the two pilot groups: `MDE Onboarding – Pilot Ring – Pilot` (pilot devices) and `XDR Pilot Users – Pilot Ring – Pilot` (pilot users). Choose one or two domain controllers as the pilot sensor host(s).

## Step 2 — Onboard Defender for Endpoint (pilot ring)
1. `security.microsoft.us` → **Settings → Endpoints → Onboarding**. If MDE is not yet initialized, complete the one-time activation.
2. Choose the deployment method **Intune** (default). Confirm the **Microsoft Defender for Endpoint connector** is turned on: `intune.microsoft.us` (GCC High Intune admin center — *verify current GCC High portal URL*) → **Endpoint security → Microsoft Defender for Endpoint** → **Connection status: Enabled**.
3. In Intune → **Endpoint security → Endpoint detection and response** → **Create Policy** (platform: Windows). Name it `MDE Onboarding – Pilot Ring – Pilot`. Set **Microsoft Defender for Endpoint client configuration package type = Auto from connector**.
4. **Assignments:** assign only to `MDE Onboarding – Pilot Ring – Pilot`. **Review + create.**
5. On a pilot device, confirm onboarding: `security.microsoft.us` → **Assets → Devices** shows the device as onboarded. (For GPO/script channels, use the onboarding package from **Settings → Endpoints → Onboarding** against the pilot OU instead.)
6. Run `DEFXDRG-Validate.ps1 -Pillar Endpoint` to confirm pilot devices report EDR signal.

## Step 3 — Deploy Defender for Identity sensors (pilot DC)
1. `security.microsoft.us` → **Settings → Identities**. If MDI is not initialized, complete the one-time activation.
2. **Settings → Identities → Directory Service accounts** → add the read-only **DSA** (gMSA recommended) prepared in requirements.
3. **Settings → Identities → Sensors** → **Add sensor** → download the sensor package and copy the **access key**.
4. During the approved change window, install the sensor on the **pilot domain controller**, supplying the access key. Repeat for AD FS / AD CS servers only after the DC sensor is healthy.
5. **Settings → Identities → Sensors** — confirm the pilot sensor shows **Running / Healthy**.
6. Run `DEFXDRG-Validate.ps1 -Pillar Identity` to confirm the sensor is healthy and identity signal is flowing.

## Step 4 — Activate Defender for Office 365 (monitor-first)
1. `security.microsoft.us` → **Email & collaboration → Policies & rules → Threat policies**.
2. Enable **Safe Attachments** and **Safe Links** using **Preset security policies** (Standard or Strict) — scope the preset to the pilot users `XDR Pilot Users – Pilot Ring – Pilot` first, so mail flow for the wider org is unchanged.
3. Confirm **anti-phishing** is on for the pilot scope. Leave org-wide expansion for Step 8.
4. Run `DEFXDRG-Validate.ps1 -Pillar Office365` to confirm MDO policies are active and `EmailEvents` signal appears in advanced hunting.

## Step 5 — Activate Defender for Cloud Apps (discovery-first)
1. `security.microsoft.us` → **Cloud apps → Cloud discovery → Settings** → enable the **Microsoft Defender for Endpoint integration** so onboarded pilot devices feed cloud-app discovery automatically.
2. **Cloud apps → App connectors** → add connectors for priority SaaS apps in **monitor** mode (no session/blocking policy yet).
3. Confirm discovery data appears under **Cloud apps → Cloud discovery → Dashboard**.
4. Run `DEFXDRG-Validate.ps1 -Pillar CloudApps` to confirm MDCA is active and `CloudAppEvents` signal appears.

## Step 6 — Configure unified RBAC
1. `security.microsoft.us` → **System → Permissions and roles → Roles** (Microsoft Defender XDR unified RBAC). If unified RBAC is not yet activated, complete the one-time activation. *Verify current unified RBAC activation steps in your tenant.*
2. Create/assign a read-only role assignment `XDR Security Reader – Tenant – Prod` granting **Security data → Read** across all data sources, assigned to your read-only analysts.
3. Create/assign an operator role assignment `XDR Security Operator – Tenant – Prod` granting read plus **response** permissions (device isolation, mail remediation) — but keep AIR approval-gated (Step 7).
4. Run `DEFXDRG-Validate.ps1 -Pillar RBAC` to confirm the unified role assignments exist and per-pillar permissions are consolidated.

## Step 7 — Keep automated response approval-gated
1. `security.microsoft.us` → **Settings → Endpoints → Advanced features** — confirm **Automated Investigation** is on but the device group's **automation level** is set to **Semi — require approval** (not full automation) during the pilot.
2. Confirm no response playbook auto-isolates or auto-disables without approval. Record the current AIR level with `DEFXDRG-Report.ps1`.
3. *Automation guardrails and the decision to move toward full automation are the SOC/security team's — this guide leaves AIR approval-gated.*

## Step 8 — Validate correlation and Secure Score on the pilot
1. Run `DEFXDRG-Hunt.ps1` to execute the advanced-hunting query `XDR Cross-Pillar Correlation Check – Tenant – Validate` — it confirms every pillar's tables (`DeviceInfo`, `IdentityInfo`, `EmailEvents`, `CloudAppEvents`) are streaming.
2. `security.microsoft.us` → **Incidents** — confirm alerts from multiple pillars group into single incidents (use the correlation test in the Testing Guide).
3. `security.microsoft.us` → **Secure Score** — record the starting score with `DEFXDRG-Report.ps1 -SaveBaseline` and triage the top recommendations.
4. Complete the **Testing Guide** before expanding.

## Step 9 — Expand tenant-wide
1. **Endpoint:** broaden the Intune assignment of `MDE Onboarding – Pilot Ring – Pilot` (or create the next ring) to cover remaining devices in waves.
2. **Identity:** install sensors on the remaining domain controllers (and AD FS / AD CS) in change windows until all are healthy.
3. **Office 365 / Cloud Apps:** expand the MDO preset policy scope and MDCA connectors/policies from pilot users to the full tenant.
4. **Response:** only after correlation and coverage are trusted, review AIR automation levels with the SOC (still their decision).
5. Re-baseline with `DEFXDRG-Report.ps1 -SaveBaseline` and track coverage/Secure-Score drift each cycle.

---
### Order of operations
`Assess → onboard Endpoint (pilot) → deploy Identity sensor (pilot DC) → activate Office 365 (pilot users) → activate Cloud Apps (discovery) → configure unified RBAC → keep AIR approval-gated → validate correlation + Secure Score → expand`


---


# 5. Testing Guide — Microsoft Defender XDR Deployment & Unified Onboarding

Run these checks after the pilot onboarding (Steps 2–8) and again after each expansion wave. Each test has a **pass/fail gate**; do not expand tenant-wide until the pilot passes. Objects are referenced by the exact names from the Implementation Guide.

## Test 1 — Endpoint (MDE) onboarding
**Procedure:** Run `DEFXDRG-Validate.ps1 -Pillar Endpoint`. In `security.microsoft.us` → **Assets → Devices**, confirm each pilot device (from `MDE Onboarding – Pilot Ring – Pilot`) appears as **Onboarded**.
**Pass:** Every pilot device is onboarded and reporting; the script reports EDR signal within the expected window.
**Fail:** A pilot device is missing or "Can be onboarded" — see Troubleshooting *Device not onboarding*.

## Test 2 — Identity (MDI) sensor health
**Procedure:** Run `DEFXDRG-Validate.ps1 -Pillar Identity`. In **Settings → Identities → Sensors**, confirm the pilot DC sensor is **Running / Healthy**.
**Pass:** The sensor is healthy, the DSA is configured, and identity signal is flowing.
**Fail:** Sensor "Not configured / Unhealthy" — see Troubleshooting *MDI sensor unhealthy*.

## Test 3 — Office 365 (MDO) policy active
**Procedure:** Run `DEFXDRG-Validate.ps1 -Pillar Office365`. Send a benign EICAR-style test through the standard Microsoft test procedure to a pilot user, or confirm Safe Links rewriting on a test message.
**Pass:** MDO preset policy is applied to `XDR Pilot Users – Pilot Ring – Pilot`; `EmailEvents` appears in advanced hunting.
**Fail:** Policy not applied or no email signal — see Troubleshooting *MDO no email signal*.

## Test 4 — Cloud Apps (MDCA) discovery
**Procedure:** Run `DEFXDRG-Validate.ps1 -Pillar CloudApps`. In **Cloud apps → Cloud discovery → Dashboard**, confirm discovery data from pilot devices.
**Pass:** MDCA is active, the MDE integration feeds discovery, and `CloudAppEvents` appears.
**Fail:** No discovery data — see Troubleshooting *MDCA no discovery data*.

## Test 5 — Cross-pillar correlation
**Procedure:** Run `DEFXDRG-Hunt.ps1` to execute `XDR Cross-Pillar Correlation Check – Tenant – Validate`. Confirm all four tables (`DeviceInfo`, `IdentityInfo`, `EmailEvents`, `CloudAppEvents`) return recent rows. Then, in **Incidents**, confirm alerts from more than one pillar have grouped into a single incident (use a Microsoft attack-simulation or safe test alert per pillar where available).
**Pass:** All four pillar tables stream, and multi-pillar alerts correlate into one incident.
**Fail:** A table is empty or alerts stay separate — see Troubleshooting *No cross-pillar correlation*.

## Test 6 — Unified RBAC
**Procedure:** Run `DEFXDRG-Validate.ps1 -Pillar RBAC`. Sign in (or use a test account) with `XDR Security Reader – Tenant – Prod` and confirm read-only access across pillars; confirm `XDR Security Operator – Tenant – Prod` has response permissions.
**Pass:** One unified role model governs all pillars; reader cannot take response actions, operator can.
**Fail:** Access is inconsistent or still per-pillar — see Troubleshooting *Unified RBAC not effective*.

## Test 7 — Automated response is approval-gated
**Procedure:** Run `DEFXDRG-Report.ps1` and confirm the pilot device group's **automation level** is **Semi — require approval** (not full automation).
**Pass:** AIR is approval-gated; no action auto-executes on the pilot without approval.
**Fail:** Automation is set higher than agreed — reset per Implementation Step 7 and confirm with the SOC.

## Test 8 — Secure Score baseline captured
**Procedure:** Run `DEFXDRG-Report.ps1 -SaveBaseline`. Confirm a Secure Score value and top recommendations are recorded to the baseline file.
**Pass:** A Secure Score baseline exists to trend against.
**Fail:** No score returned — allow time after onboarding, then re-run; see Troubleshooting *Secure Score empty*.

---
### Exit gate
All eight tests pass on the pilot ring **before** any tenant-wide expansion (Implementation Step 9). Re-run Tests 1–5 and 8 after each expansion wave and compare against the saved baseline.


---


# 6. Troubleshooting Guide — Microsoft Defender XDR Deployment & Unified Onboarding

Common field issues, in **symptom → cause → fix** form. Run `DEFXDRG-Discovery.ps1` and `DEFXDRG-Validate.ps1` first — most causes surface there.

## Device not onboarding (MDE)
**Symptom:** A pilot device stays "Can be onboarded" in **Assets → Devices** and reports no EDR signal.
**Cause:** The Intune EDR profile `MDE Onboarding – Pilot Ring – Pilot` is not assigned to the device, the MDE-Intune connector is off, or the device cannot reach the Defender service endpoints.
**Fix:** Confirm the device is in `MDE Onboarding – Pilot Ring – Pilot`; confirm **Endpoint security → Microsoft Defender for Endpoint → Connection status: Enabled** in Intune; verify outbound HTTPS to the Defender endpoint URLs (per `global-requirements-defender.md` G5). Force an Intune sync and re-run `DEFXDRG-Validate.ps1 -Pillar Endpoint`.

## MDI sensor unhealthy
**Symptom:** The domain-controller sensor shows **Unhealthy** or **Not configured** in **Settings → Identities → Sensors**.
**Cause:** Missing/mis-scoped Directory Service Account, blocked outbound reach to the MDI service, insufficient DC resources, or an unsupported sensor OS.
**Fix:** Verify the DSA (gMSA) under **Directory Service accounts**; confirm the DC can reach the MDI service URLs; confirm DC resources and a supported OS version (*verify current sensor OS support*). Reinstall the sensor with a fresh access key if needed, then re-run `DEFXDRG-Validate.ps1 -Pillar Identity`.

## MDO no email signal
**Symptom:** Test 3 fails — no `EmailEvents` rows or Safe Links not rewriting for pilot users.
**Cause:** The preset security policy is not scoped to `XDR Pilot Users – Pilot Ring – Pilot`, mail is not routing through Exchange Online, or the MDO plan is not licensed.
**Fix:** Confirm the preset policy scope includes the pilot users; confirm Exchange Online is the mail path; verify the MDO P1/P2 plan (*verify current plan features*). Allow time for signal, then re-run `DEFXDRG-Validate.ps1 -Pillar Office365`.

## MDCA no discovery data
**Symptom:** **Cloud discovery → Dashboard** is empty; `CloudAppEvents` returns nothing.
**Cause:** The Defender for Endpoint → Cloud Apps discovery integration is off, or pilot devices are not yet onboarded to MDE.
**Fix:** Turn on the MDE integration under **Cloud apps → Cloud discovery → Settings**; confirm pilot devices are onboarded (Test 1 must pass first); add app connectors in monitor mode. Re-run `DEFXDRG-Validate.ps1 -Pillar CloudApps`.

## No cross-pillar correlation
**Symptom:** Test 5 fails — a hunting table is empty, or alerts from different pillars stay as separate incidents.
**Cause:** One pillar is not fully onboarded/streaming yet, or not enough time has passed for tables and correlation to populate.
**Fix:** Run `DEFXDRG-Hunt.ps1` to see exactly which table is empty and fix that pillar's onboarding first; allow warm-up time (tables populate over hours). Correlation only groups alerts that share entities — confirm the test alerts share a device/user/mailbox. **In GCC High/DoD, first confirm the pillar and its advanced-hunting table are even available in your cloud** — a persistently empty table can mean the feature/connector lags or is unavailable, not that onboarding failed (*verify against current Microsoft Government documentation*). Re-run once each pillar streams.

## Unified RBAC not effective
**Symptom:** Analysts still see inconsistent access, or the unified role assignments don't take effect.
**Cause:** Unified RBAC is not activated for the tenant, legacy per-pillar permissions still override, or the role assignment scope/data-source is wrong.
**Fix:** Confirm unified RBAC activation under **System → Permissions and roles** (*verify current activation steps*); confirm `XDR Security Reader – Tenant – Prod` / `XDR Security Operator – Tenant – Prod` grant the right data sources; allow propagation time and re-test with a pilot account. Re-run `DEFXDRG-Validate.ps1 -Pillar RBAC`.

## Automated response acted without approval
**Symptom:** A device was isolated or a user disabled automatically during the pilot.
**Cause:** The device group's AIR **automation level** is set higher than **Semi — require approval**.
**Fix:** Reset the automation level to **Semi — require approval** (Implementation Step 7), confirm with the SOC, and record the level with `DEFXDRG-Report.ps1`. *The automation-guardrail decision is the security team's.*

## Secure Score empty
**Symptom:** `DEFXDRG-Report.ps1 -SaveBaseline` returns no Secure Score.
**Cause:** Onboarding is too recent for Secure Score to compute, or the account lacks read permission to the score.
**Fix:** Allow time after onboarding; confirm the running account has at least Security Reader; re-run the report. If still empty, verify pillar activation in the portal.

## Script cannot authenticate
**Symptom:** `DEFXDRG-*.ps1` fails on connect or returns access-denied.
**Cause:** The Microsoft Graph / Az modules are missing, consent to the required read scopes was not granted, the account lacks Security Reader, or the script connected to the **wrong national cloud** (e.g. commercial `graph.microsoft.com` from a GCC High tenant).
**Fix:** Let the script install the modules (it checks on run); sign in to the **US Gov cloud** with `Connect-MgGraph -Environment USGov` (GCC High; **DoD:** `-Environment USGovDoD`) and `Connect-AzAccount -Environment AzureUSGovernment`, and consent to the read-only scopes; confirm Security Reader (or higher). The scripts default to the US Gov cloud. *Verify the correct national-cloud endpoints for your cloud against current Microsoft Government documentation.* Re-run the script.


---


# 7. Best Practices — Microsoft Defender XDR Deployment & Unified Onboarding

Field-proven guidance for keeping the unified XDR deployment clean, correlated, and low-risk.

## Onboard in rings, never all at once
- Always onboard a **pilot ring** first — a few devices (`MDE Onboarding – Pilot Ring – Pilot`), one or two domain controllers, and a pilot user group (`XDR Pilot Users – Pilot Ring – Pilot`) — validate, then expand in waves.
- Sequence the pillars but let signal accumulate: onboard Endpoint and the Identity sensor first (they take longest), then activate Office 365 and Cloud Apps, which are portal-side toggles.

## Keep automated response approval-gated until trusted
- Leave **AIR** at **Semi — require approval** during the pilot and early expansion. Move toward higher automation only after correlation and coverage are proven — and that decision belongs to the SOC/security team, not the deployment.
- Never let a response playbook auto-isolate a device or auto-disable a user before the org has agreed the guardrails.

## Prefer one unified role model
- Adopt **unified RBAC** and retire per-pillar permissions so analysts have one consistent role (reader / operator / admin) across Endpoint, Identity, Office, and Cloud Apps. This removes the "who can see what in which console" confusion that fragments a SOC.
- Grant least privilege: read-only analysts get `XDR Security Reader – Tenant – Prod`; only responders get `XDR Security Operator – Tenant – Prod`.

## Treat Secure Score as a trend, not a target
- Capture a **baseline** with `DEFXDRG-Report.ps1 -SaveBaseline` and work the highest-impact recommendations first. Track the delta each cycle rather than chasing a single number.
- Re-baseline after each expansion wave so the trend reflects real coverage growth.

## Let correlation and tables warm up
- After onboarding, allow time before judging correlation — advanced-hunting tables (`DeviceInfo`, `IdentityInfo`, `EmailEvents`, `CloudAppEvents`) populate over hours, not seconds. Use `DEFXDRG-Hunt.ps1` to confirm each pillar is streaming before expecting multi-pillar incidents.

## Protect the Identity sensors
- Domain-controller sensors are security-critical infrastructure. Keep them healthy, patched, and monitored; a silent sensor blinds MDI. Use the DSA (gMSA) per current guidance and review sensor health on a cadence.

## Keep licensing and preview facts current (GCC High/DoD lag commercial)
- Each pillar and feature is **license-gated** (MDE P1/P2, MDI, MDO P1/P2, MDCA). Before enabling a feature, **verify current availability and plan requirements in your tenant** — do not assume a feature is included.
- **In GCC High/DoD, availability itself lags or differs from commercial.** Whether a pillar, connector, unified-RBAC capability, preview, or AI/Copilot feature exists in your Government cloud — and which advanced-hunting tables it populates — **must be verified against current Microsoft Government documentation** for your specific cloud (GCC High vs DoD IL5). Never assume commercial parity. See `gcc-high-parity-notes.md`.

## Defer the security decisions to the owners
- Automated-response guardrails, incident-response runbooks, and which recommendations are "must-fix" are **the security/SOC team's** determinations. This solution delivers the technical onboarding and validation; the operating decisions stay with the customer.

## Where to go next
Once the XDR suite is onboarded and correlating, natural next steps in the catalog:
- **Defender for Office 365 (P2) — Threat Explorer, Attack Simulation & AIR** to go deep on the email pillar.
- **Microsoft Defender for Cloud — CSPM & Secure Score Remediation** to extend posture management to cloud workloads.
- The **Sentinel** SOC/XDR integration solution to stream this correlated XDR into a SIEM for long-term hunting and SOAR.
- **Entra ID governance / Conditional Access** solutions to harden the identity layer that MDI protects.


---


# 8. Deliverables Summary — Microsoft Defender XDR Deployment & Unified Onboarding

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What Defender XDR is — the four pillars (MDE/MDI/MDO/MDCA), the unified portal, cross-pillar correlation, unified RBAC, Secure Score; benefits, limitations |
| 2. Requirements Guide | Solution-specific prerequisites with Verify / Implement-if-missing |
| Global Requirements (Defender) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps — onboard Endpoint, deploy Identity sensors, activate Office 365 & Cloud Apps, unified RBAC, Secure Score, pilot-first |
| 5. Testing Guide | Eight validation tests with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations and where to go next |
| GCC High Parity Notes (`gcc-high-parity-notes.md`) | Government-edition addendum: national-cloud endpoints (`security.microsoft.us`, `portal.azure.us`, `graph.microsoft.us` / DoD `dod-graph.microsoft.us`, `login.microsoftonline.us`, Intune `intune.microsoft.us`), the GCC High/DoD **pillar/feature/connector parity gaps** each flagged *verify against current Microsoft Government documentation*, and **compliance & data-residency context** (FedRAMP High, DoD IL4/IL5, CMMC 2.0, ITAR/EAR, US-persons) |

## PowerShell scripts (Microsoft Graph Security / Az + KQL)
| Script | What it does |
|---|---|
| `DEFXDRG-Discovery.ps1` | Read-only readiness — licensed Defender plans, admin roles, per-pillar activation status, device onboarding coverage, candidate DCs for MDI, MDO/MDCA status |
| `DEFXDRG-Validate.ps1` | Per-pillar validation (`-Pillar Endpoint\|Identity\|Office365\|CloudApps\|RBAC`) — confirms onboarding, sensor health, policy activation, and unified role assignments |
| `DEFXDRG-Report.ps1` | Coverage + Secure Score report with top recommendations and drift versus a saved baseline; reports the AIR automation level |
| `DEFXDRG-Onboard-DeviceRing.ps1` | `-WhatIf`-gated helper that assigns the Intune EDR onboarding profile to the pilot device ring (safe preview by default) |
| `DEFXDRG-Hunt.ps1` | Runs the KQL advanced-hunting query `XDR Cross-Pillar Correlation Check` via Graph Security to confirm all four pillar tables stream (read-only) |

## What the buyer receives
- This solution as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** (with embedded KQL) in a single ZIP.
- A repeatable process following the model **Assess → Configure → Pilot → Validate → Expand** — pilot-ring onboarding with automated response kept approval-gated until trusted.

Delivered as a **Complete Solution Package (PDF + Word + scripts)**.

## Outcome
One correlated XDR portal that sees an attack move identity → endpoint → email → cloud — four pillars onboarded into `security.microsoft.us`, cross-pillar incidents correlated, one unified role model, and a Secure Score baseline to trend — proven on a pilot ring before you scale.
