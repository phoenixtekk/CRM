# Azure Virtual Desktop Remote Access (Windows & macOS Clients) — Government (GCC High)

> **Version 1.0.0** · Category: Azure · Solution code: AVDG

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Azure Virtual Desktop Remote Access (Government / Azure Government · GCC High)

## The problem
Azure Virtual Desktop (AVD) on a **GCC High / Azure Government** tenant is **not** the Commercial portal with a different sign-in. The admin portals, the client feed URLs, the sign-in endpoint, and the session-host service endpoints are all **different** in the US sovereign cloud — and some capabilities **lag, are limited, or are absent** versus Commercial. Teams that follow a Commercial runbook verbatim typically end up with clients subscribed to the wrong feed and session hosts that fail to register because a `.us` endpoint is blocked. The failures are quiet, and they surface late.

## The solution
This is the **Government (Azure Government / GCC High) edition** of the AVD Remote Access solution: AVD authored end to end for the US sovereign cloud. It uses the correct portals (**`portal.azure.us`**), the correct client feed (**`rdweb.wvd.azure.us`**), the correct Government service endpoints (`*.wvd.azure.us`, `*.usgovcloudapi.net`), and the identity model a Gov tenant actually supports — with **Commercial-vs-Azure-Government parity gaps called out** so nothing silently fails.

## What's inside
- **Solution Overview** with an explicit *Commercial vs Azure Government — what's different* table.
- **Requirements Guide** — ten verifiable prerequisites (tenant, Government licensing, roles, resource provider, identity model, image, networking + the Gov endpoint allow-list, clients, pilot group, change control).
- **Implementation Guide** — ordered, click-to-implement steps in the Gov portals, following **Assess → Configure → Pilot → Validate → Expand** with a gate at every stage and GCC-High caveats inline.
- **Testing & Troubleshooting** — twelve pass/fail test cases and a symptom→fix guide for the common sovereign-cloud failures.
- **Five PowerShell scripts** — Discovery, Validation, Report, Remediation (`-WhatIf`), and Set-ScopeTargeting — all on **US Gov** Azure/Graph endpoints.
- **GCC High parity reference** — cited, so you verify feature availability before you depend on it.

## The outcome
AVD deployed **correctly on GCC High** — right portals, right endpoints, parity gaps handled — proven on a small pilot before you scale, expanded in controlled waves, with a documented rollback. Self-guided and tested, at a fraction of the cost of a bespoke consulting engagement.

## Who it's for
Government, defense, and regulated organizations — and the MSPs and integrators serving them — deploying or correcting AVD on an Azure Government / GCC High tenant, who need the sovereign-cloud specifics up front rather than learned the hard way.


---


# Solution Overview — Azure Virtual Desktop Remote Access (Government / Azure Government · GCC High)

This is the **Government (Azure Government / GCC High) edition** of the Azure Virtual Desktop (AVD) Remote Access solution. It publishes Windows desktops and applications from session hosts running in **Azure Government** and delivers them to **Windows and macOS clients** — authored end to end for the US sovereign cloud, using the correct `*.us` admin portals, US Government service endpoints, and the identity model that a GCC High / Azure Government tenant actually supports.

The goal is a government tenant configured **correctly the first time** — not with Commercial steps that silently fail because the portal URL, the client feed URL, or a feature simply is not the same in the sovereign cloud.

> **Naming convention (used throughout):** every object you create is named `<Purpose> – <Scope> – <Stage>` and reused verbatim. Example: `AVD Host Pool – Finance – Pilot`, `AVD Workspace – Finance – Prod`, `AVD Users – Finance – Pilot`.

---

## What this solution delivers

- A **host pool**, **workspace**, and **application group** deployed in Azure Government, published to a named group of pilot users first, then expanded.
- **Session hosts** (Windows 11 / Windows 10 Enterprise multi-session, or single-session) joined per your chosen identity model (Microsoft Entra join or AD DS / Microsoft Entra Domain Services).
- **Client access from Windows App / Remote Desktop client on Windows and macOS**, subscribed to the **Azure Government feed URL** — not the Commercial one.
- **Five PowerShell scripts** — Discovery, Validation, Report, Remediation (default `-WhatIf`), and Set-ScopeTargeting — all connecting to **US Gov** Azure and Microsoft Graph endpoints (`-Environment AzureUSGovernment` / `USGov`).
- A **Commercial-vs-Azure Government parity reference** (`gcc-high-parity-notes.md`) so you know, before you start, which capabilities differ or lag in the sovereign cloud.

---

## Commercial vs Azure Government — what's different

AVD is a single product, but the sovereign cloud is **not the Commercial portal with a different sign-in**. The control plane, the admin portals, the client feed URLs, and the session-host service endpoints are all distinct. If you follow a Commercial runbook verbatim on a GCC High tenant, the most common outcome is that clients subscribe to the wrong feed, or session hosts fail agent registration because a `.us` endpoint is blocked. The table below is the short version; the fully cited detail is in `gcc-high-parity-notes.md`.

| Area | Commercial | Azure Government / GCC High |
| --- | --- | --- |
| Azure portal | `portal.azure.com` | **`portal.azure.us`** |
| Microsoft 365 / Entra admin | `admin.microsoft.com`, `entra.microsoft.com` | **`portal.office365.us`**, **`entra.microsoft.us`** |
| Sign-in / authentication endpoint | `login.microsoftonline.com` | **`login.microsoftonline.us`** |
| AVD client **feed URL** (subscribe) | `https://rdweb.wvd.microsoft.com` (or `.../api/arm/feeddiscovery`) | **`https://rdweb.wvd.azure.us`** (feed discovery: `https://rdweb.wvd.azure.us/api/arm/feeddiscovery?aadtenant=<yourdomain>`) |
| AVD **web client** | `https://client.wvd.microsoft.com/arm/webclient` | **`https://rdweb.wvd.azure.us/arm/webclient/index.html`** |
| Session-host service traffic FQDN | `*.wvd.microsoft.com` | **`*.wvd.azure.us`** |
| `ms-avd:` URI `env` value | `avdarm` | **`usgov`** |
| PowerShell / CLI environment | `AzureCloud` (default) | **`AzureUSGovernment`** (`Connect-AzAccount -Environment AzureUSGovernment`; Graph `Connect-MgGraph -Environment USGov`) |
| Feature availability | New features land here first | **Parity lags** — features release in Commercial first and arrive in Gov later, in preview, or not at all. Verify each feature for Azure Government before you rely on it. |

**The single most important takeaway:** point admins at `portal.azure.us` and point clients at `rdweb.wvd.azure.us`. Those two substitutions prevent the majority of "it works in the demo tenant but not in ours" failures.

Sources: AVD is available in sovereign clouds including Azure for US Government ([Microsoft Learn — Prerequisites](https://learn.microsoft.com/en-us/azure/virtual-desktop/prerequisites)); Gov feed/web-client and session-host FQDNs ([Required FQDNs and endpoints — Azure for US Government tab](https://learn.microsoft.com/en-us/azure/virtual-desktop/safe-url-list?tabs=azure-for-us-government)); `env=usgov` URI value ([URI schemes](https://learn.microsoft.com/en-us/azure/virtual-desktop/uri-scheme)).

---

## The deployment model — Assess → Configure → Pilot → Validate → Expand

Every step in the Implementation Guide fits this model, and each stage has an **exit gate** — you do not proceed until the gate passes.

1. **Assess** — Confirm you are on a GCC High / Azure Government tenant, the licensing entitles AVD, the `Microsoft.DesktopVirtualization` resource provider is registered, roles are in place, and the required `*.us` endpoints are reachable. *(Gate: Discovery script reports all green; requirements in `02-requirements.md` all verified.)*
2. **Configure** — Create the named host pool, workspace, and application group in `portal.azure.us`; deploy session hosts on the chosen identity model; assign the pilot user group. *(Gate: resources exist with the agreed names; session hosts show **Available**.)*
3. **Pilot** — Publish to `AVD Users – <Scope> – Pilot` only; those users subscribe to the **Gov feed URL** from Windows App / Remote Desktop client on Windows and macOS. *(Gate: every pilot user connects to a desktop and launches a published app.)*
4. **Validate** — Run the Validation and Report scripts; confirm connectivity, profile behavior, and performance against the pass/fail criteria in `05-testing.md`. *(Gate: all test cases pass; no open Sev-1/Sev-2 issues.)*
5. **Expand** — Use `AVDG-Set-ScopeTargeting.ps1` to grow the assignment group in controlled waves, re-validating after each wave. *(Gate: each wave validated before the next is added.)*

---

## Who this is for

Government, defense, and regulated organizations (and their MSPs / integrators) standing up or correcting AVD on a **GCC High or Azure Government** tenant, who need the sovereign-cloud specifics called out rather than discovered the hard way. Novice-friendly, click-to-implement, with full Azure Government navigation at every step.

## What you need before you start

See `02-requirements.md` for the full, verifiable prerequisite list (layered on the Azure Solutions global requirements in `global-requirements-azure-solutions.md`). At a glance: a GCC High / Azure Government tenant, Gov-appropriate licensing (e.g., Microsoft 365 G3/G5 or Windows Enterprise E3/E5 Gov entitlement for AVD), the correct Azure roles, `portal.azure.us` access, and the `*.us` / `*.usgovcloudapi.net` endpoints allowed through your filtering.


---


# Requirements Guide — Azure Virtual Desktop Remote Access (Azure Government / GCC High)

These are the **solution-specific** requirements, layered on top of the platform baseline in `global-requirements-azure-solutions.md` (G1–G6). Every requirement below is structured **Description / Why / Verify / Implement**. Where a Government/GCC High specific applies, it is called out inline; unconfirmed specifics are flagged **"verify for Azure Government."**

> Reuse the naming convention `<Purpose> – <Scope> – <Stage>` for every object you create while satisfying these requirements.

---

## R1. Confirmed GCC High / Azure Government tenant

- **Description:** The tenant is a US sovereign-cloud tenant (Microsoft 365 GCC High / DoD paired with Microsoft Entra ID in Azure Government), not a Commercial or GCC (moderate) tenant.
- **Why:** The admin portals, sign-in endpoint, AVD feed URL, and session-host service endpoints are all different in the sovereign cloud. Every step in this solution assumes `*.us` portals and endpoints; running it against a Commercial tenant points clients at the wrong feed and blocks agent registration.
- **Verify:** Sign in at **`https://portal.azure.us`** and **`https://portal.office365.us`**. Confirm the sign-in redirects through **`login.microsoftonline.us`** and your primary domain resolves (GCC High tenants commonly use `<name>.onmicrosoft.us`). In `entra.microsoft.us` → **Overview**, confirm the tenant.
- **Implement:** If you are on Commercial/GCC and require GCC High, provision through an authorized AOS-G reseller (per global requirement G1). This is a procurement action, not a config change — flag it early.

> **GCC High note (cited):** GCC High/DoD are built on Azure Government and use Microsoft Entra ID Gov; the `.onmicrosoft.us` domain and `login.microsoftonline.us` endpoint are used only for GCC High and DoD. See `gcc-high-parity-notes.md`.

## R2. AVD-eligible licensing (Government SKUs)

- **Description:** Every user connecting to AVD holds a license that entitles Azure Virtual Desktop, using the **Government** variants of the eligible SKUs.
- **Why:** AVD access rights are granted by the Windows/Microsoft 365 license; without an entitling SKU the deployment is not licensed and Windows on the session hosts must instead use per-user access pricing.
- **Verify:** In **`portal.office365.us`** → **Billing → Licenses**, confirm each in-scope user has an AVD-entitling SKU — e.g., **Microsoft 365 G3/G5** (Government), **Office 365 G3/G5** with a qualifying Windows Enterprise entitlement, or **Windows Enterprise E3/E5** (Government). Windows Server session hosts require **RDS CALs with Software Assurance** or **RDS User Subscription Licenses**.
- **Implement:** Procure the correct Government SKUs and assign them to `AVD Users – <Scope> – Pilot`. For external/commercial-purpose users, enroll an Azure subscription for per-user access pricing.

> The eligible-SKU list (M365 E3/E5/A3/A5/F3/Business Premium; Windows Enterprise E3/E5; Windows Education A3/A5; Windows VDA) is documented for AVD generally; the **Government tenant uses the G-series equivalents**. Confirm your exact SKU entitlement with your licensing channel — **verify for Azure Government** that a given SKU is offered in your Gov agreement. Source: [Prerequisites — Operating systems and licenses](https://learn.microsoft.com/en-us/azure/virtual-desktop/prerequisites).

## R3. Azure roles for AVD deployment (least privilege)

- **Description:** The operating accounts hold the RBAC roles needed to create AVD objects and session hosts, and to register the resource provider.
- **Why:** Host pool / workspace / application-group creation and VM deployment require sufficient RBAC; registering `Microsoft.DesktopVirtualization` requires the `*/register/action` operation (included in Contributor or Owner).
- **Verify:** In **`portal.azure.us`** → **Subscriptions → Access control (IAM)**, confirm the deploying account has **Contributor** or **Owner** on the target subscription/resource group, plus **Desktop Virtualization Contributor** (or the granular Host Pool/Application Group/Workspace Contributor roles) for AVD object management. In `entra.microsoft.us` → **Roles & admins**, confirm any directory roles needed for group/assignment work.
- **Implement:** Assign the minimum roles; prefer PIM-eligible activation where available in your Gov tenant. Name any custom role assignment scope-group `AVD Admins – <Scope> – Prod`.

## R4. `Microsoft.DesktopVirtualization` resource provider registered

- **Description:** The AVD resource provider is registered on the target subscription in Azure Government.
- **Why:** AVD objects cannot be created until the provider is registered; this is a per-subscription action.
- **Verify:** In **`portal.azure.us`** → **Subscriptions → (your subscription) → Resource providers**, search **Microsoft.DesktopVirtualization** and confirm status **Registered**. (Scripted: `Get-AzResourceProvider -ProviderNamespace Microsoft.DesktopVirtualization` after `Connect-AzAccount -Environment AzureUSGovernment`.)
- **Implement:** Select the provider → **Register**, or run `Register-AzResourceProvider -ProviderNamespace Microsoft.DesktopVirtualization`. `AVDG-Remediation.ps1` performs this (default `-WhatIf`). Source: [Prerequisites](https://learn.microsoft.com/en-us/azure/virtual-desktop/prerequisites).

## R5. Supported identity model chosen and reachable

- **Description:** One supported identity scenario is selected and functional: **Microsoft Entra-only** (session hosts Microsoft Entra joined, cloud users), **Entra ID + AD DS** (hybrid), or **Entra ID + Microsoft Entra Domain Services**.
- **Why:** Microsoft Entra ID always authenticates AVD users; session hosts must join the same Entra tenant or an AD domain reachable from the session-host VNet. Profile and SSO options depend on the model chosen.
- **Verify:** Decide the model and confirm prerequisites: for hybrid, Microsoft Entra Connect is syncing (UPN or SID matches across AD DS and Entra); for Entra-only, users exist in Entra ID (no personal Microsoft accounts). Confirm the session-host VNet can reach domain controllers/DNS if using AD DS or Entra Domain Services.
- **Implement:** Stand up the missing piece (Entra Connect for hybrid; a domain-join account **without MFA** for the join). Record the choice in the runbook.

> **GCC High note:** the supported identity scenarios (Entra-only, Entra + AD DS, Entra + Entra Domain Services) are the same set as Commercial. **Intune management** of session hosts is supported in Azure Government (GCC, GCC High, DoD) for Entra-joined / hybrid-joined hosts, but **not** for hosts joined to Microsoft Entra Domain Services, and Windows Server hosts can't enroll in Intune. Some newer identity features (e.g., **external identities**) reached Azure Government later than Commercial and parts remain in preview — **verify for Azure Government** before relying on them. Sources: [Prerequisites — Identity](https://learn.microsoft.com/en-us/azure/virtual-desktop/prerequisites), [Intune for AVD](https://learn.microsoft.com/en-us/intune/solutions/azure-virtual-desktop).

## R6. Supported session-host OS image (from the Gov Marketplace)

- **Description:** Session hosts use a supported 64-bit OS: Windows 11/10 Enterprise multi-session, Windows 11/10 Enterprise, or Windows Server 2016–2025.
- **Why:** Only these editions are supported; N/KN/LTSC editions, 32-bit, Arm64, Ultra/Ephemeral OS disks, and VM Scale Sets are **not** supported for session hosts.
- **Verify:** In **`portal.azure.us`** → Marketplace, confirm the intended image is available in your Gov region. Confirm the region hosts the compute you need.
- **Implement:** Select a supported image (or a custom image in an Azure Compute Gallery). Name the host pool `AVD Host Pool – <Scope> – Pilot`.

## R7. Networking, region, and the Government endpoint allow-list

- **Description:** A VNet/subnet exists in the same Azure Government region as the session hosts, with outbound access (TCP 443) to the **US Gov** AVD service endpoints; no inbound ports required.
- **Why:** Session hosts establish an outbound reverse connection to the AVD service; if the Gov service FQDNs are blocked, agent registration and connections fail. The endpoints are the `.us` / `.usgovcloudapi.net` set, **not** the Commercial `*.wvd.microsoft.com` set.
- **Verify:** Confirm the VNet region matches the session-host region and RTT to that region is < 150 ms from users. Confirm your firewall/proxy allows the **Azure for US Government** endpoint set (see the allow-list below). The `AVDG-Validation.ps1` script and Microsoft's *Agent URL Tool* both check reachability.
- **Implement:** Create the VNet/subnet; open outbound 443 to the Gov endpoints; prefer the `WindowsVirtualDesktop` service tag and `AzureCloud`/`AzureMonitor`/`AzureActiveDirectory` tags for Azure Government where supported. Do **not** open inbound 3389.

**Required Azure Government session-host endpoints (allow outbound):**

| Address (US Gov) | Port | Purpose |
| --- | --- | --- |
| `*.wvd.azure.us` | 443 | AVD service traffic (incl. TCP RDP) |
| `*.service.windows.usgovcloud.microsoft` | 443 | Service traffic |
| `*.windows.usgovcloud.microsoft` | 443 | Service traffic |
| `*.windows.usgovcloud-static.microsoft` | 443 | Service traffic |
| `login.microsoftonline.us` | 443 | Authentication |
| `*.prod.warm.ingest.monitor.core.usgovcloudapi.net` | 443 | Agent / diagnostics |
| `gcs.monitoring.core.usgovcloudapi.net` | 443 | Agent traffic |
| `azkms.core.usgovcloudapi.net` | 1688 | Windows activation |
| `mrsglobalstugviffx.blob.core.usgovcloudapi.net` | 443 | Agent / SxS stack updates |
| `wvdportalstorageblob.blob.core.usgovcloudapi.net` | 443 | Azure portal support |
| `ctldl.windowsupdate.com` | 80 | Certificates |
| `ocsp.msocsp.com` | 80 | Certificates |

**Required Azure Government client endpoints (allow outbound on user devices):** `login.microsoftonline.us`, `*.wvd.azure.us`, `*.servicebus.usgovcloudapi.net`, plus the shared `go.microsoft.com`, `aka.ms`, `learn.microsoft.com`, `privacy.microsoft.com`, `*.cdn.office.net`, `graph.microsoft.com`, `windows.cloud.microsoft`, `windows365.microsoft.com`, `ecs.office.com`.

Source: [Required FQDNs and endpoints — Azure for US Government tab](https://learn.microsoft.com/en-us/azure/virtual-desktop/safe-url-list?tabs=azure-for-us-government). Note the two Azure fabric IPs (`169.254.169.254`, `168.63.129.16`) must **not** be proxied or redirected.

## R8. Supported clients on Windows and macOS, pointed at the Gov feed

- **Description:** Pilot users have **Windows App** or the **Remote Desktop client** installed on Windows and/or macOS, subscribed to the **Azure Government** feed.
- **Why:** These are the supported clients; the RADC and MSTSC clients are not supported. On the sovereign cloud they must subscribe to the **Gov** feed URL, not the Commercial one.
- **Verify:** On Windows, subscribe using feed URL **`https://rdweb.wvd.azure.us`** (or feed discovery `https://rdweb.wvd.azure.us/api/arm/feeddiscovery?aadtenant=<yourdomain>`). On macOS, install Windows App from the Mac App Store → **Add Work or School Account** and subscribe to the same Gov feed. Web client: **`https://rdweb.wvd.azure.us/arm/webclient/index.html`**.
- **Implement:** Deploy the client; document the Gov feed URL in user instructions (`HELP_CENTER` / onboarding). For scripted/URI subscription use `ms-rd:subscribe?url=https://rdweb.wvd.azure.us` and for direct connect set the URI `env=usgov`. Sources: [URI schemes](https://learn.microsoft.com/en-us/azure/virtual-desktop/uri-scheme), [Required FQDNs — US Gov](https://learn.microsoft.com/en-us/azure/virtual-desktop/safe-url-list?tabs=azure-for-us-government).

## R9. Named pilot user group and assignment plan

- **Description:** A named security group `AVD Users – <Scope> – Pilot` contains the initial pilot cohort; an expansion plan defines later waves.
- **Why:** Publishing to a small named group first contains blast radius and makes validation meaningful; scoped expansion keeps each wave testable.
- **Verify:** In `entra.microsoft.us` → **Groups**, confirm the pilot group exists and contains only pilot users. Confirm it is the group assigned to the application group.
- **Implement:** Create the group and assign it to the AVD application group. Use `AVDG-Set-ScopeTargeting.ps1` (default `-WhatIf`) to add later waves in a controlled way.

## R10. Change control, backup, and rollback (per G5/G6)

- **Description:** An approved change window and a documented rollback exist for the deployment and each expansion wave.
- **Why:** AVD publishing changes are user-facing; a tested back-out protects the pilot cohort and satisfies governance.
- **Verify:** Confirm an approved change record, a scheduled window, and a written rollback (e.g., remove group assignment, deallocate hosts) before executing.
- **Implement:** Capture pre-change state with `AVDG-Discovery.ps1` / `AVDG-Report.ps1`; document the back-out; rehearse where feasible.


---


# Global Requirements — Azure Solutions

These requirements are common to **every** Azure Solutions solution in the standard program model. They are the baseline platform prerequisites that any Azure/Microsoft 365 engagement assumes. Each is structured **Description / Why / Verify / Implement-if-missing**. Solution-specific requirements (see `02-requirements.md`) are layered on top of these.

> Naming convention: every created object is named `<Purpose> – <Scope> – <Stage>` and reused verbatim throughout the engagement.

---

## G1. A Microsoft 365 / Entra tenant

- **Description:** An active Microsoft 365 / Microsoft Entra tenant for the cloud(s) in scope (commercial and/or government).
- **Why:** All identity, licensing, and service configuration is anchored to a tenant; nothing can be configured without one.
- **Verify:** Sign in to the relevant admin center (`https://admin.microsoft.com`) and confirm the tenant resolves and is active under **Settings → Org settings**.
- **Implement-if-missing:** Provision the tenant through the appropriate channel (commercial: standard; government: via an authorized AOS-G reseller).

## G2. Administrative roles (least privilege)

- **Description:** Appropriately scoped admin roles for the work — Global Administrator for tenant-wide changes, and service-specific roles (Exchange, SharePoint, Teams, Azure Owner/Contributor) for day-to-day.
- **Why:** Every configuration and migration action requires a role with sufficient privilege; least-privilege scoping limits blast radius and satisfies audit requirements.
- **Verify:** In Entra → **Roles & admins**, confirm the operating accounts hold the required roles. In Azure → **Subscriptions → Access control (IAM)**, confirm RBAC assignments.
- **Implement-if-missing:** Assign the minimum roles needed; prefer eligible (PIM) activation over standing access where available.

## G3. Licensing baseline

- **Description:** Sufficient Microsoft 365 and/or Azure licensing/credit for all in-scope users and workloads.
- **Why:** Features and capacity (mailboxes, SharePoint storage, AVD, VMs) are gated by license SKUs and subscription quota.
- **Verify:** **Billing → Licenses** for M365; **Subscriptions → Usage + quotas** for Azure. Compare assigned/available against the in-scope object count.
- **Implement-if-missing:** Procure the correct SKUs and request quota increases sized to the workload (add headroom for shared/resource objects).

## G4. Network connectivity to Microsoft 365 / Azure endpoints

- **Description:** Reliable network egress to the required Microsoft 365 and Azure service endpoints (and the sovereign `.us` endpoints for government clouds), with sufficient bandwidth.
- **Why:** All cloud administration and any data movement depends on connectivity to the correct endpoint set; government clouds use distinct endpoints from commercial.
- **Verify:** Confirm reachability to the relevant endpoints (commercial `*.microsoft.com` / government `*.microsoft.us`, `*.azure.us`, `*.office365.us`). Measure sustained bandwidth against the data volume.
- **Implement-if-missing:** Open firewall/proxy allowances for the correct endpoint set; scale bandwidth or add ExpressRoute (matching the cloud — Gov ExpressRoute for Gov regions).

## G5. Change control & maintenance window

- **Description:** An approved change-management process with scheduled maintenance windows and a stakeholder communications plan.
- **Why:** Cloud changes can be outward-facing and disruptive; controlled windows and comms reduce business impact and satisfy governance/compliance.
- **Verify:** Confirm an approved change record and a scheduled window for each disruptive action.
- **Implement-if-missing:** Stand up a lightweight change/approval process; schedule windows; prepare user comms templates.

## G6. Backup / rollback posture

- **Description:** A defined backup and rollback position for any change — config export, data backup, and a documented back-out procedure before any disruptive action.
- **Why:** Cloud changes are not always reversible by default; a tested rollback is the safety net for cutovers and bulk operations.
- **Verify:** Confirm pre-change config/state is captured and a written rollback exists for each disruptive change.
- **Implement-if-missing:** Export current configuration/state; document and (where feasible) rehearse the rollback before executing the change.


---


# Implementation Guide — Azure Virtual Desktop Remote Access (Azure Government / GCC High)

Ordered, click-to-implement steps using the **Azure Government** portals. GCC-High / Azure-Government caveats are called out **inline at the step where they matter**. Follow the deployment model **Assess → Configure → Pilot → Validate → Expand**, and do not pass a stage until its **gate** is green.

> **Before you touch anything:** you are working in the US sovereign cloud. Admin URL is **`portal.azure.us`** (not `portal.azure.com`), and clients subscribe to **`rdweb.wvd.azure.us`** (not `rdweb.wvd.microsoft.com`). Keep the naming convention `<Purpose> – <Scope> – <Stage>` and reuse names verbatim.

---

## Stage 1 — Assess

### Step 1.1 — Confirm you are in Azure Government
1. Browse to **`https://portal.azure.us`** and sign in. Your sign-in must redirect through **`login.microsoftonline.us`**.
2. Top-right → confirm the correct **directory/tenant** (GCC High domains are often `<name>.onmicrosoft.us`).
3. Open **`https://portal.office365.us`** → **Billing → Licenses** and confirm AVD-entitling **Government** SKUs are assigned to your pilot users (R2).

> **Caveat:** If either portal bounces you to `portal.azure.com` / `admin.microsoft.com`, you are on a Commercial/GCC tenant, not GCC High — stop and confirm the tenant (R1) before continuing.

### Step 1.2 — Register the resource provider
1. In `portal.azure.us` → **Subscriptions** → select your subscription → **Resource providers**.
2. Search **`Microsoft.DesktopVirtualization`**. If status is **NotRegistered**, select it → **Register**. Wait for **Registered**.

> Scripted equivalent (Gov): `Connect-AzAccount -Environment AzureUSGovernment` then `Register-AzResourceProvider -ProviderNamespace Microsoft.DesktopVirtualization`.

### Step 1.3 — Confirm roles and endpoints
1. **Subscriptions → Access control (IAM)** → confirm your account has **Contributor/Owner** plus **Desktop Virtualization Contributor** (R3).
2. Allow the **Azure for US Government** session-host and client endpoints through your firewall/proxy (R7 table). Key ones: `*.wvd.azure.us`, `*.service.windows.usgovcloud.microsoft`, `login.microsoftonline.us`, and the `*.usgovcloudapi.net` agent/monitor endpoints.
3. Run **`AVDG-Discovery.ps1`** (read-only) to snapshot the tenant/subscription and confirm the provider, roles, and reachable endpoints.

> **GATE 1 (Assess):** Discovery reports the provider Registered, roles present, and Gov endpoints reachable; all `02-requirements.md` items verified. Do not configure until green.

---

## Stage 2 — Configure

### Step 2.1 — Create the host pool
1. `portal.azure.us` → search **Azure Virtual Desktop** → **Host pools** → **Create**.
2. **Basics:** Subscription, Resource group (e.g., `rg-avd-<scope>-prod`), **Host pool name** = **`AVD Host Pool – <Scope> – Pilot`**, **Location** = your Azure Government region (this sets where host-pool *metadata* is stored).
   > **Caveat:** the **Location** field must be an Azure Government region. Session-host compute can be in any Gov region, but keep it close to users (RTT < 150 ms).
3. **Host pool type:** **Pooled** (multi-session) or **Personal** per your design. Choose a load-balancing algorithm (Breadth-first for pilot is typical).
4. **Validation environment:** set **No** for production pilots unless you intend to receive early service updates.

### Step 2.2 — Add session hosts
1. On the **Virtual Machines** tab of the create flow (or later via **Session hosts → +**), set **Add virtual machines = Yes**.
2. **Image:** pick a supported OS from the **Gov** Marketplace (Windows 11 Enterprise multi-session recommended for pooled). Avoid N/KN/LTSC, 32-bit, Arm64, Ultra/Ephemeral OS disks, and VM Scale Sets (R6).
3. **Name prefix:** e.g., `avdsh-<scope>` (becomes `avdsh-<scope>-0`, `-1`, …).
4. **Identity — choose your model (R5):**
   - **Microsoft Entra ID** (cloud-native): select **Microsoft Entra ID**; optionally tick **Enroll VM with Intune** (supported in Azure Government for Entra-joined hosts).
   - **Active Directory** (AD DS / Entra Domain Services): select **Active Directory**, provide the domain-join UPN/OU.
     > **Caveat:** the domain-join account **must not have MFA enabled**, or the join fails. Hosts joined to **Microsoft Entra Domain Services cannot be managed by Intune**; **Windows Server** hosts cannot enroll in Intune at all.
5. **Networking:** select the VNet/subnet from R7 (same Gov region). Do not assign public IPs; do not open inbound 3389.
6. **Domain/credentials:** provide the local admin (and domain-join, if AD) credentials. Create.
7. Wait until **Session hosts** shows each host **Status = Available**.

> **Caveat (endpoints):** if a host stalls at **Needs assistance** / fails agent registration, the usual cause on Gov is a blocked `.us` endpoint. Re-check `*.wvd.azure.us` and the `*.usgovcloudapi.net` agent endpoints (R7), then run `AVDG-Validation.ps1`.

### Step 2.3 — Create the workspace and application group
1. **Application groups:** an app group (**Desktop** type for full desktop) is created with the host pool. Rename/confirm it as **`AVD App Group – <Scope> – Pilot`**.
2. **Workspaces** → **Create** → **`AVD Workspace – <Scope> – Prod`** → in **Application groups**, **register** the app group above.
   > A published resource only appears to users once its app group is **registered to a workspace** — a common "nothing shows up in the client" cause.

> **GATE 2 (Configure):** host pool, workspace, and app group exist with the agreed names; all session hosts **Available**; app group registered to the workspace.

---

## Stage 3 — Pilot

### Step 3.1 — Assign the pilot group
1. `entra.microsoft.us` → **Groups** → confirm **`AVD Users – <Scope> – Pilot`** (R9) contains only pilot users.
2. In the AVD **Application group → Assignments → +** → add the pilot group. Assign only the pilot group at this stage.

### Step 3.2 — Subscribe clients to the Government feed
> **This is the step most likely to go wrong if you reuse Commercial instructions.** Use the **Gov** feed URL.

- **Windows (Windows App or Remote Desktop client):**
  1. Install **Windows App** (Microsoft Store) or the **Remote Desktop client**.
  2. **Subscribe with URL** → enter **`https://rdweb.wvd.azure.us`** (or feed discovery `https://rdweb.wvd.azure.us/api/arm/feeddiscovery?aadtenant=<yourdomain>`).
  3. Sign in with the Gov work account (`user@<name>.onmicrosoft.us` or your Gov domain).
- **macOS (Windows App):**
  1. Install **Windows App** from the **Mac App Store**.
  2. Open it → **+** → **Add Work or School Account** → sign in with the Gov account → subscribe to the same **`https://rdweb.wvd.azure.us`** feed.
- **Web client (any OS):** browse to **`https://rdweb.wvd.azure.us/arm/webclient/index.html`**.
- **Scripted / URI:** subscribe with `ms-rd:subscribe?url=https://rdweb.wvd.azure.us`; direct connect with `ms-avd:connect?...&env=usgov&version=0`.

> **Caveat:** Do **not** use `rdweb.wvd.microsoft.com` or `client.wvd.microsoft.com` — those are Commercial and will not return Gov resources. The `ms-avd:` `env` value for Azure Government is **`usgov`** (Commercial is `avdarm`).

### Step 3.3 — First connection
1. Each pilot user opens the subscribed workspace, launches the **desktop**, and launches at least one **published app**.
2. Confirm resources appear and the session connects over TCP 443 (RDP Shortpath/UDP is an optimization, not a requirement).

> **GATE 3 (Pilot):** every pilot user (Windows and macOS as applicable) subscribes to the Gov feed, connects to a desktop, and launches a published app.

---

## Stage 4 — Validate

1. Run **`AVDG-Validation.ps1`** (read-only, Gov endpoints) — confirms provider, host-pool/session-host health, workspace/app-group registration, assignment, and endpoint reachability.
2. Run **`AVDG-Report.ps1`** to produce the deployment report (inventory + pass/fail summary) for your change record.
3. Walk the test cases in `05-testing.md`; resolve any failures.

> **GATE 4 (Validate):** all `05-testing.md` cases pass; Report shows no Sev-1/Sev-2 open items.

---

## Stage 5 — Expand

1. Plan waves (e.g., +25 users each). For each wave, run **`AVDG-Set-ScopeTargeting.ps1`** (default **`-WhatIf`**) to preview adding users to **`AVD Users – <Scope> – Pilot`** (or a `– Prod` group), review the plan, then re-run with `-Confirm`/`-WhatIf:$false` to apply.
2. Scale session hosts if needed (add hosts to the pool with the same name prefix); confirm each new host reaches **Available**.
3. Re-run **`AVDG-Validation.ps1`** after each wave.

> **GATE 5 (Expand):** each wave validated before the next is added; host capacity keeps pace with assigned users.

---

## Rollback (per R10 / G6)
- Remove the group assignment from the application group (users lose access immediately, hosts untouched).
- Deallocate/delete session hosts if backing out entirely.
- Unregister the app group from the workspace to hide resources without deleting them.
- Keep the pre-change `AVDG-Discovery.ps1` / `AVDG-Report.ps1` output as the restore reference.


---


# Testing & Validation — Azure Virtual Desktop Remote Access (Azure Government / GCC High)

Run these test cases at **Gate 4 (Validate)** and after every expansion wave. Each case has an explicit **pass/fail**. Capture evidence (screenshots / script output) for your change record. Scripts referenced here connect to **US Gov** endpoints (`-Environment AzureUSGovernment` / `USGov`).

> Tenant reminder: admin at **`portal.azure.us`**, clients subscribe to **`rdweb.wvd.azure.us`**.

---

## T1. Tenant & environment is Azure Government
- **Steps:** Sign in to `portal.azure.us`; confirm redirect through `login.microsoftonline.us`; run `AVDG-Discovery.ps1`.
- **Pass:** Portal is `.us`, sign-in is `login.microsoftonline.us`, Discovery reports environment **AzureUSGovernment**.
- **Fail:** Any Commercial URL (`portal.azure.com`, `login.microsoftonline.com`) appears — you are on the wrong cloud; stop.

## T2. Resource provider registered
- **Steps:** `AVDG-Validation.ps1`, or portal **Subscriptions → Resource providers**.
- **Pass:** `Microsoft.DesktopVirtualization` = **Registered**.
- **Fail:** NotRegistered → run `AVDG-Remediation.ps1` (review `-WhatIf` plan first).

## T3. AVD objects exist with correct names
- **Steps:** Confirm host pool `AVD Host Pool – <Scope> – Pilot`, workspace `AVD Workspace – <Scope> – Prod`, app group `AVD App Group – <Scope> – Pilot`.
- **Pass:** All three exist, correctly named, app group **registered** to the workspace.
- **Fail:** Missing object or unregistered app group → resources won't appear in clients.

## T4. Session hosts healthy
- **Steps:** AVD → **Session hosts**; or `AVDG-Validation.ps1`.
- **Pass:** Every host **Status = Available**, agent/SxS versions current.
- **Fail:** **Needs assistance / Unavailable** → almost always a blocked `.us` endpoint (T8) or a domain-join issue (MFA on the join account).

## T5. Assignment scoped to pilot group
- **Steps:** App group → **Assignments**.
- **Pass:** Only `AVD Users – <Scope> – Pilot` assigned.
- **Fail:** Broader/other group assigned → correct before proceeding.

## T6. Windows client subscribes to the Gov feed
- **Steps:** On Windows, subscribe with **`https://rdweb.wvd.azure.us`**; sign in with the Gov account.
- **Pass:** Workspace and resources appear.
- **Fail:** "We couldn't find any resources" → confirm the **Gov** feed URL (not `rdweb.wvd.microsoft.com`), correct account, and T3/T5.

## T7. macOS client subscribes to the Gov feed
- **Steps:** On macOS, Windows App → **Add Work or School Account** → subscribe to **`https://rdweb.wvd.azure.us`**.
- **Pass:** Resources appear and a desktop connects.
- **Fail:** No resources → same checks as T6; confirm Windows App (not the legacy Microsoft Remote Desktop macOS app pointed at Commercial).

## T8. Government endpoints reachable from session hosts
- **Steps:** `AVDG-Validation.ps1` endpoint check, and/or Microsoft's *Agent URL Tool* on a host.
- **Pass:** `*.wvd.azure.us`, `*.service.windows.usgovcloud.microsoft`, `login.microsoftonline.us`, and the `*.usgovcloudapi.net` agent/monitor endpoints all reachable on 443.
- **Fail:** Any blocked → open it in the firewall/proxy (R7); re-test.

## T9. Desktop connection and published app launch
- **Steps:** As a pilot user, connect to the desktop; launch a published app.
- **Pass:** Desktop session established over 443; app launches; input/display normal.
- **Fail:** Connection drops or app won't launch → check host health (T4), profile/identity (T10), endpoints (T8).

## T10. Identity / profile behavior for the chosen model
- **Steps:** Sign in as a pilot user; confirm SSO/prompt behavior and FSLogix profile load (if configured) matches the chosen model (R5).
- **Pass:** Sign-in succeeds per design; profile loads (if FSLogix configured); no repeated auth loops.
- **Fail:** Auth loops or profile errors → verify hybrid sync (UPN/SID match), or Entra-only profile prerequisites. **Verify for Azure Government** that any SSO/passwordless/external-identity feature you depend on is available in Gov (see `gcc-high-parity-notes.md`).

## T11. Report generated
- **Steps:** `AVDG-Report.ps1`.
- **Pass:** Report lists inventory + pass/fail and shows **no open Sev-1/Sev-2**.
- **Fail:** Open Sev-1/Sev-2 → remediate before Gate 4 sign-off.

## T12. Rollback rehearsed
- **Steps:** In a controlled window, remove then re-add the pilot group assignment.
- **Pass:** Access is revoked and restored as expected; back-out is documented.
- **Fail:** Rollback doesn't behave as documented → fix the runbook before expanding.

---

### Exit criteria (Gate 4)
All of T1–T12 **pass**, evidence captured, and the Report shows no open Sev-1/Sev-2. Only then proceed to **Stage 5 — Expand**.


---


# Troubleshooting — Azure Virtual Desktop Remote Access (Azure Government / GCC High)

Symptom → likely cause → fix, focused on the failures that are **specific to the US sovereign cloud**. Most Gov-only AVD problems come down to three things: the **wrong portal/feed URL**, a **blocked `.us` endpoint**, or a **domain-join/MFA** issue. Work top-down.

> Admin at **`portal.azure.us`**; clients subscribe to **`rdweb.wvd.azure.us`**; scripts on **`AzureUSGovernment`** / Graph **`USGov`**.

---

## A. "We couldn't find any resources" in the client
- **Cause 1 — wrong (Commercial) feed URL.** The client was subscribed to `rdweb.wvd.microsoft.com` / `client.wvd.microsoft.com`.
  - **Fix:** Remove the workspace and re-subscribe to **`https://rdweb.wvd.azure.us`** (feed discovery `https://rdweb.wvd.azure.us/api/arm/feeddiscovery?aadtenant=<yourdomain>`).
- **Cause 2 — app group not registered to a workspace.**
  - **Fix:** AVD → **Workspaces → (your workspace) → Application groups → +** register `AVD App Group – <Scope> – Pilot` (see `03-implementation.md` Step 2.3 / test T3).
- **Cause 3 — user not assigned.**
  - **Fix:** App group → **Assignments → +** add `AVD Users – <Scope> – Pilot` (T5).
- **Cause 4 — wrong account/tenant.** User signed in with a Commercial or wrong-domain account.
  - **Fix:** Sign in with the Gov work account (`user@<name>.onmicrosoft.us` or your Gov domain) via `login.microsoftonline.us`.

## B. macOS client shows nothing / won't add the account
- **Cause — legacy app or Commercial endpoint.** Using the old Microsoft Remote Desktop macOS app or a Commercial feed.
  - **Fix:** Install **Windows App** from the **Mac App Store** → **+** → **Add Work or School Account** → subscribe to **`https://rdweb.wvd.azure.us`** (T7). Confirm the client endpoints `*.wvd.azure.us` and `*.servicebus.usgovcloudapi.net` are allowed on the device network.

## C. Admin portal redirects to Commercial
- **Cause — wrong tenant / wrong portal.** You opened `portal.azure.com` or you're actually on a Commercial/GCC tenant.
  - **Fix:** Use **`portal.azure.us`** / **`portal.office365.us`**. If sign-in still lands on `login.microsoftonline.com`, the tenant is not GCC High — re-confirm R1 before proceeding.

## D. Session host stuck at "Needs assistance" / agent won't register
- **Cause 1 — blocked Gov endpoints (most common).** `*.wvd.azure.us` or the `*.usgovcloudapi.net` agent/monitor endpoints are blocked by firewall/proxy.
  - **Fix:** Allow the full **Azure for US Government** session-host set (R7 / parity notes §3): `*.wvd.azure.us`, `*.service.windows.usgovcloud.microsoft`, `login.microsoftonline.us`, `*.prod.warm.ingest.monitor.core.usgovcloudapi.net`, `gcs.monitoring.core.usgovcloudapi.net`, `mrsglobalstugviffx.blob.core.usgovcloudapi.net`, etc. Re-run `AVDG-Validation.ps1` and Microsoft's *Agent URL Tool* (T8).
- **Cause 2 — fabric IPs proxied.** `169.254.169.254` / `168.63.129.16` are being intercepted/redirected.
  - **Fix:** Ensure these are never proxied or routed away (they must reach the Azure fabric directly).
- **Cause 3 — registration token expired.**
  - **Fix:** Regenerate the host-pool registration key and re-add the host.

## E. Domain join fails during host deployment
- **Cause 1 — MFA on the join account.** The domain-join account has MFA enabled.
  - **Fix:** Use a domain-join account **without MFA** (scoped, monitored). Re-deploy the host.
- **Cause 2 — no line of sight to DC/DNS.** The session-host VNet can't reach the domain controller/DNS.
  - **Fix:** Confirm VNet/DNS routing to the DC (R5/R7); fix the OU path if specified.
- **Cause 3 — Entra Domain Services + Intune expectation.** You expected Intune management but hosts are Entra-Domain-Services-joined.
  - **Fix:** Entra-Domain-Services-joined hosts **can't** be Intune-managed; switch to Entra-join or hybrid, or manage via GPO (parity notes §6).

## F. Sign-in loops / SSO prompts unexpectedly
- **Cause 1 — hybrid identity mismatch.** UPN or SID doesn't match across AD DS and Entra ID.
  - **Fix:** Correct the mismatch and re-sync Entra Connect (R5).
- **Cause 2 — SSO/passwordless feature not GA in Gov.** You configured an SSO/passwordless path that isn't available in Azure Government yet.
  - **Fix:** **Verify for Azure Government** (parity notes §7) that the specific SSO/WHfB/FIDO2/Entra-Kerberos path is GA in your Gov tenant; fall back to a supported method.

## G. Scripts connect to the wrong cloud / no data
- **Cause — default (Commercial) environment.** `Connect-AzAccount` / `Connect-MgGraph` ran without the Gov environment.
  - **Fix:** Use **`Connect-AzAccount -Environment AzureUSGovernment`** and **`Connect-MgGraph -Environment USGov`**. All five scripts default to Gov; don't override to Commercial.

## H. FSLogix profile won't load
- **Cause — identity/storage prerequisites for the model.** For Entra-join + Azure Files, users must be hybrid identities and the storage path configured accordingly.
  - **Fix:** Match FSLogix prerequisites to your identity model (R5 / best practices). **Verify for Azure Government** that the Azure Files Entra-Kerberos / cloud-only path you're using is GA in Gov before relying on it.

## I. A feature "should exist" but isn't in the Gov portal
- **Cause — parity lag.** The feature has shipped to Commercial but not yet to Azure Government.
  - **Fix:** Check `gcc-high-parity-notes.md` and Microsoft's current Gov docs; treat recently-announced features as **verify for Azure Government**. Design around GA-in-Gov capabilities only.

---

### Escalation checklist
1. Confirm cloud: `portal.azure.us` + `login.microsoftonline.us` (T1).
2. Confirm endpoints reachable: `AVDG-Validation.ps1` (T8).
3. Confirm objects/assignment: `AVDG-Discovery.ps1` (T3/T5).
4. Capture `AVDG-Report.ps1` output and attach to the ticket.


---


# Best Practices — Azure Virtual Desktop Remote Access (Azure Government / GCC High)

Operating guidance for running AVD well on the US sovereign cloud. These complement the ordered steps in `03-implementation.md` and the checks in `05-testing.md`.

> Admin at **`portal.azure.us`**; clients subscribe to **`rdweb.wvd.azure.us`**; PowerShell/CLI use **`AzureUSGovernment`** / Graph **`USGov`**.

---

## Sovereign-cloud discipline
- **Bookmark the `.us` portals** and remove Commercial bookmarks from the admin workstation to avoid muscle-memory mistakes: `portal.azure.us`, `portal.office365.us`, `entra.microsoft.us`, sign-in `login.microsoftonline.us`.
- **Standardize the Gov feed URL** in every piece of user documentation and onboarding: `https://rdweb.wvd.azure.us`. Treat any appearance of `rdweb.wvd.microsoft.com` as a bug.
- **Assume parity lag.** Before designing around any AVD feature, confirm it is GA in Azure Government — features ship to Commercial first. Keep `gcc-high-parity-notes.md` next to your design and re-verify at build time. Flag anything unconfirmed as **"verify for Azure Government."**

## Naming & reuse
- Name every object `<Purpose> – <Scope> – <Stage>` and reuse verbatim: `AVD Host Pool – Finance – Pilot`, `AVD Workspace – Finance – Prod`, `AVD App Group – Finance – Pilot`, `AVD Users – Finance – Pilot`. Consistent names make the scripts, the report, and the rollback unambiguous.

## Identity & access
- Prefer the **simplest identity model that meets policy** — Entra-only removes domain controllers from the critical path; use hybrid (AD DS) only where line-of-business apps require it.
- The **domain-join account must not have MFA** (it breaks the automated join) — scope it tightly and monitor it.
- Use **least privilege** for admins (Desktop Virtualization Contributor over Owner where possible) and PIM-eligible activation if available in your Gov tenant.
- **Never open inbound 3389.** AVD uses an outbound reverse connection. For host troubleshooting use just-in-time VM access, not a standing RDP port; don't assign public IPs to hosts.

## Networking & endpoints
- Allow the **US Gov endpoint set** (R7) via **service tags** (`WindowsVirtualDesktop`, `AzureActiveDirectory`, `AzureMonitor`, `AzureCloud`) rather than hand-maintained IPs.
- **Never proxy or redirect** the Azure fabric IPs `169.254.169.254` and `168.63.129.16` — doing so breaks provisioning and health.
- Keep session hosts in the Gov region **closest to users** (RTT < 150 ms); enable RDP Shortpath where the network supports UDP for a better experience.
- Use **Azure Firewall's AVD protection** / FQDN tags to lock down outbound traffic without breaking the service.

## Profiles & images
- Use **FSLogix** for pooled multi-session profiles; store containers on Azure Files/NetApp Files, and match the identity prerequisites for your model (hybrid identities for Entra-join + Azure Files). **Verify for Azure Government** that the specific Azure Files Entra Kerberos/cloud-only path you intend is GA in Gov before committing.
- Build a **golden image** in an Azure Compute Gallery for repeatable, patched hosts; avoid unsupported editions (N/KN/LTSC), 32-bit, Arm64, Ultra/Ephemeral OS disks, and VM Scale Sets.

## Management & operations
- Use **Intune** for session-host policy where supported in your Gov tenant (Entra-joined / hybrid-joined hosts). Remember: **Entra Domain Services-joined** and **Windows Server** hosts can't enroll in Intune.
- Turn on **AVD Insights / diagnostics** to the Gov Log Analytics endpoints (`*.usgovcloudapi.net`) from day one — it's your evidence for T4/T9 troubleshooting.
- **Pilot small, expand in waves** with `AVDG-Set-ScopeTargeting.ps1` (default `-WhatIf`), re-validating after each wave. Scale host capacity to keep pace with assigned users.

## Change control & safety
- Every deployment and expansion wave runs inside an **approved change window** with a **written rollback** (R10). Capture pre-change state with Discovery/Report first.
- Keep **Remediation and Set-ScopeTargeting on `-WhatIf` by default**; require an explicit confirmation to make changes.
- Rehearse the rollback (remove/re-add assignment) before the first real expansion.

## Security & compliance posture
- Keep everything **inside the Azure Government boundary** — GCC High/DoD identity, data residency, and service dependencies are designed to stay in Azure Government; do not reach back to Commercial services for AVD dependencies.
- Enforce **Conditional Access / MFA for users** (not the domain-join service account) using the Gov Entra endpoints.
- Never store tokens, keys, or credentials in scripts or docs; the provided scripts are read-only or `-WhatIf` by default and hold no secrets.


---


# Deliverables Summary — Azure Virtual Desktop Remote Access (Azure Government / GCC High)

Everything included in this Government (Azure Government / GCC High) edition, and how the pieces fit together.

> This edition is authored for the US sovereign cloud: admin at **`portal.azure.us`**, clients at **`rdweb.wvd.azure.us`**, scripts on **`AzureUSGovernment`** / Graph **`USGov`**.

---

## Documents (source/)

| Document | What it gives you |
| --- | --- |
| `01-solution-overview.md` | What the solution delivers, the deployment model, and the **Commercial vs Azure Government — what's different** table (portals, feed URLs, endpoints, parity). |
| `02-requirements.md` | Ten solution-specific requirements (R1–R10), each **Description / Why / Verify / Implement**, layered on the Azure global requirements — including the Government endpoint allow-list. |
| `03-implementation.md` | Ordered click-to-implement steps in the Gov portals, **Assess → Configure → Pilot → Validate → Expand**, with GCC-High caveats inline and stage gates. |
| `05-testing.md` | Twelve pass/fail test cases (T1–T12) for Gate 4 and each expansion wave. |
| `06-troubleshooting.md` | Symptom → cause → fix for the common Gov-specific failures (wrong feed, blocked `.us` endpoints, join/MFA, parity). |
| `07-best-practices.md` | Operating guidance: sovereign-cloud discipline, identity, networking, profiles, management, change control, compliance. |
| `gcc-high-parity-notes.md` | Cited Commercial-vs-Azure-Government reference: portals, endpoints, and feature-parity gaps to verify. |
| `executive-summary.md` | One-page summary for decision-makers. |
| `global-requirements-azure-solutions.md` | Shared Azure platform baseline (G1–G6). *(Provided; not part of this authoring pass.)* |

## Scripts (scripts/)

All scripts connect to **US Gov** endpoints (`Connect-AzAccount -Environment AzureUSGovernment`; `Connect-MgGraph -Environment USGov`). Discovery, Validation, and Report are **read-only**; Remediation and Set-ScopeTargeting default to **`-WhatIf`**.

| Script | Purpose | Mode |
| --- | --- | --- |
| `AVDG-Discovery.ps1` | Snapshot the Gov tenant/subscription: provider registration, roles, AVD objects, session hosts, assignments. | Read-only |
| `AVDG-Validation.ps1` | Validate the deployment against pass/fail criteria, including Gov endpoint reachability. | Read-only |
| `AVDG-Report.ps1` | Produce a deployment report (inventory + pass/fail) for the change record. | Read-only |
| `AVDG-Remediation.ps1` | Fix common gaps (e.g., register the resource provider). | `-WhatIf` default |
| `AVDG-Set-ScopeTargeting.ps1` | Build/grow the assignment group in controlled waves. | `-WhatIf` default |

---

## How to use the set
1. **Assess** with `AVDG-Discovery.ps1` and `02-requirements.md`.
2. **Configure** per `03-implementation.md` in `portal.azure.us`.
3. **Pilot** — subscribe Windows/macOS clients to `rdweb.wvd.azure.us`.
4. **Validate** with `AVDG-Validation.ps1` + `05-testing.md`, capture `AVDG-Report.ps1`.
5. **Expand** in waves with `AVDG-Set-ScopeTargeting.ps1`, re-validating each wave.

Consult `gcc-high-parity-notes.md` whenever you rely on a specific feature, and `06-troubleshooting.md` when a step doesn't behave. Keep every change inside an approved window with a documented rollback (R10).
