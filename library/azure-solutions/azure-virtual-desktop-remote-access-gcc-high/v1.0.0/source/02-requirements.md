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
