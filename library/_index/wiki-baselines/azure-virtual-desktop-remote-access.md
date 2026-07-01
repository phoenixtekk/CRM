# Azure Virtual Desktop Remote Access (Windows & macOS Clients)

> **Version 1.0.0** · Category: Azure Solutions · Solution code: AVD

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Azure Virtual Desktop Remote Access (Windows & macOS Clients)

**Azure Solutions**

Remote staff, contractors, and federal teams need a real Windows desktop and internal applications from wherever they are — including from a Mac — without exposing systems directly or shipping hardware. **Azure Virtual Desktop (AVD)** delivers Windows desktops and individual apps from Azure, reached securely through a thin client on Windows and macOS, governed by Microsoft Entra ID and Conditional Access. This package stands up AVD correctly: host pools, a workspace, application groups, identity, FSLogix profiles, and validated client access on both platforms.

This is a complete, **deploy-it-today** package for implementing Azure Virtual Desktop, written for an administrator with no prior AVD experience.

## What you get
- A plain-language **Solution Overview** of host pools (pooled vs. personal), workspaces, application groups, identity, FSLogix, and the Windows and macOS client experience.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite — subscription, licensing, identity, networking, image, FSLogix storage, and Conditional Access.
- An **Implementation Guide** of precise, click-by-click Azure portal steps in the required order, through connecting both the Windows and macOS clients.
- Five **PowerShell scripts** for AVD readiness discovery, host-pool and client-access validation, a usage/assignment report, safe remediation of unhealthy hosts, and an assignment-group builder.
- **Testing** and **Troubleshooting** guides for a confident rollout.

## What this delivers
A governed remote-desktop service — a pooled host pool of session hosts published through a workspace and a Desktop application group, users assigned by group, profiles roamed with FSLogix, and every connection gated by a Conditional Access MFA policy — validated from both Windows and macOS clients.

## The deployment model
**Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Secure, governed remote access to full Windows desktops and apps — delivered from Azure and reachable from both Windows and macOS — deployable by a single administrator and proven on a pilot before you scale.


---


# 1. Solution Overview — Azure Virtual Desktop Remote Access

## What Azure Virtual Desktop is
Azure Virtual Desktop (AVD) is Microsoft's cloud service for delivering a full Windows desktop and individual Windows applications from Azure, reached securely over the internet from a thin client app. Instead of shipping laptops or exposing on-premises systems, you run the session hosts (the actual Windows VMs) inside your Azure subscription, publish them through a workspace, and users connect from the AVD client on Windows or macOS. Identity is governed by Microsoft Entra ID, access is gated by Conditional Access, and user profiles roam between hosts with FSLogix.

## How it works
1. A `host pool` is a collection of identical Windows session-host VMs. It is either pooled (many users share a set of multi-session hosts) or personal (each user gets a dedicated host).
2. An `application group` publishes what users see from that host pool — either a full Desktop or a curated set of RemoteApps.
3. A `workspace` bundles one or more application groups into the single entry the user subscribes to in the AVD client.
4. Users and groups are assigned to an application group; Entra ID authenticates them and Conditional Access decides whether the connection is allowed.
5. `FSLogix` stores each user's profile on a file share so the desktop, settings, and Outlook/Teams cache follow the user across any pooled host.
6. The user opens the AVD client on Windows or macOS, signs in with their Entra ID account, and the desktop or apps stream down over the Remote Desktop Protocol.

## What you can control
- Host pool type (pooled multi-session vs. personal) and the session-host VM size, image, and count.
- What is published — a full `Desktop` application group, a `RemoteApp` application group, or both.
- Who gets access, through Entra ID group assignment to the application group.
- Sign-in security through Conditional Access (require MFA, compliant device, trusted network).
- Profile storage and roaming behavior through FSLogix on an Azure Files or Azure NetApp Files share.
- Autoscale / start-on-connect to control running cost when hosts are idle.

## Benefits
- **Remote access without exposure** — internal Windows desktops and apps reach users anywhere, with no inbound ports opened to on-premises systems.
- **Cross-platform** — the same governed desktop is reachable from both Windows and macOS clients.
- **Governed entry** — every connection passes Entra ID and Conditional Access, so MFA and device/location rules are enforced at the door.
- **Consistent profiles** — FSLogix means a user gets the same desktop on any pooled host, with no roaming-profile pain.
- **Elastic cost** — autoscale and start-on-connect run session hosts only when people are working.

## Limitations (be honest with buyers)
- AVD delivers Windows desktops/apps; it does not publish macOS or Linux desktops (macOS is a client only).
- Session hosts are real VMs you size, image, and patch — capacity planning and an update strategy still apply.
- FSLogix needs a performant, highly available file share; an undersized share is the most common cause of slow logons.
- Rich connection/usage insights depend on enabling the AVD Insights workbook and a Log Analytics workspace (noted in requirements).

## The deployment model
> **Assess identity, networking, and licensing → configure the host pool, workspace, application groups, FSLogix and Conditional Access → pilot to a small group → validate the Windows and macOS client experience → expand to the full audience.** The repeatable model: **Assess → Configure → Pilot → Validate → Expand.**


---


# 2. Requirements Guide — Azure Virtual Desktop Remote Access

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify · Implement-if-missing.** Category-wide prerequisites are in `global-requirements-azure-solutions.md`. Named objects use the `<Purpose> – <Scope> – <Stage>` convention and are reused verbatim in `03-implementation.md`.

## 2.1 Azure subscription and resource group
- **Description:** An Azure subscription with Contributor (or Owner) rights and a resource group to hold the AVD objects, named `AVD – Resource Group – Core`.
- **Why:** Host pools, session-host VMs, the workspace, and application groups are Azure resources that live in a subscription/resource group.
- **Verify:** `portal.azure.com` → **Subscriptions** confirms an active subscription; **Resource groups** confirms (or lets you create) `AVD – Resource Group – Core`. Run `AVD-Discovery.ps1`.
- **Implement-if-missing:** Create the resource group in a supported AVD region; ensure the operating account has Contributor on it.

## 2.2 AVD licensing entitlement
- **Description:** A per-user eligible license — Microsoft 365 E3/E5/A3/A5/F3/Business Premium, or Windows E3/E5 — for every AVD user.
- **Why:** Access to Windows 10/11 multi-session and single-session in AVD is gated by these license SKUs; unlicensed use is not permitted.
- **Verify:** M365 admin center → **Billing → Licenses**; confirm each AVD user holds an eligible SKU.
- **Implement-if-missing:** Assign an eligible license to every AVD user (or to the `AVD – Users – Pilot` / `AVD – Users – Production` groups).

## 2.3 Identity — Entra ID (or hybrid) for users and hosts
- **Description:** User accounts in Microsoft Entra ID, and a join model for the session hosts — Microsoft Entra join, or Microsoft Entra hybrid join with Entra Connect syncing from Active Directory.
- **Why:** Users authenticate with Entra ID; the session hosts must be joined so users can sign in and so policy applies. Hybrid is required when sessions need line-of-sight to on-premises file/app servers using Kerberos.
- **Verify:** Entra → **Users** lists the AVD users; decide and record the host join model. If hybrid, confirm Entra Connect sync health. Run `AVD-Discovery.ps1`.
- **Implement-if-missing:** Ensure users exist in Entra ID; choose Entra join (cloud-only) or stand up Entra Connect + line-of-sight to a domain controller for hybrid join.

## 2.4 Virtual network and connectivity
- **Description:** An Azure virtual network named `AVD – VNet – Core` (with a session-host subnet) in the AVD region, with DNS that resolves the chosen identity provider, and any required route to on-premises.
- **Why:** Session hosts live on this VNet; they must resolve and reach the domain (for hybrid) and any internal resources users need.
- **Verify:** `portal.azure.com` → **Virtual networks** confirms the VNet/subnet; test name resolution and connectivity from a test VM on the subnet.
- **Implement-if-missing:** Create the VNet/subnet; set DNS to your domain controllers (hybrid) or default Azure DNS (cloud-only); add VPN/ExpressRoute peering if on-premises access is needed.

## 2.5 Session-host VM image
- **Description:** A Windows image for the session hosts — Windows 11 Enterprise multi-session (pooled) or Windows 11 Enterprise (personal), from the Azure Marketplace or a custom image; session-host names use the prefix `avdsh-`.
- **Why:** The image determines the OS and the apps baked into every host; multi-session is required for pooled cost-sharing.
- **Verify:** In the host-pool creation blade, confirm the gallery image is selectable; for custom images confirm the image version exists in a compute gallery.
- **Implement-if-missing:** Select a Marketplace image, or build and publish a custom image (with your line-of-business apps and FSLogix agent) to an Azure Compute Gallery.

## 2.6 FSLogix profile storage
- **Description:** A highly available SMB file share for FSLogix profile containers, named `AVD – FSLogix Share – Core` (Azure Files with Entra Kerberos/AD authentication, or Azure NetApp Files).
- **Why:** Pooled hosts are interchangeable; FSLogix roams the user profile so the desktop is consistent on whichever host the user lands. This is mandatory for pooled host pools.
- **Verify:** `portal.azure.com` → **Storage accounts** (or **Azure NetApp Files**) confirms the share and that the session hosts can authenticate to it.
- **Implement-if-missing:** Create the share, enable identity-based (Kerberos) authentication, set NTFS + share permissions so users can create their own container, and record the UNC path.

## 2.7 Conditional Access readiness
- **Description:** Microsoft Entra ID P1 (or higher) so a Conditional Access policy named `AVD – Conditional Access – MFA` can govern AVD sign-in.
- **Why:** Remote access to a full desktop must be protected; Conditional Access enforces MFA and device/location conditions on the AVD and Azure cloud apps.
- **Verify:** Entra → **Conditional Access** is available (indicates P1); confirm a break-glass account is excluded from any new policy.
- **Implement-if-missing:** Acquire Entra ID P1 (included in M365 E3/E5/Business Premium); plan the policy targeting the AVD users and the AVD cloud apps.

## 2.8 The AVD client on Windows and macOS
- **Description:** The Windows Desktop client (or the new Windows App) on Windows endpoints, and the macOS AVD client from the Mac App Store on Mac endpoints.
- **Why:** The published desktop/apps are reached through the AVD client; both platforms must be covered for cross-OS access.
- **Verify:** On a Windows test device the Windows App / Remote Desktop client is installed; on a Mac the Windows App (or Microsoft Remote Desktop) is installed from the App Store.
- **Implement-if-missing:** Deploy the Windows App to Windows endpoints (Intune/winget); install the macOS client from the Mac App Store on Mac endpoints.

## 2.9 Assignment groups
- **Description:** Entra ID security groups for assignment — `AVD – Users – Pilot` and `AVD – Users – Production`.
- **Why:** Application-group assignment, licensing, and Conditional Access all target groups, so a user is granted access by group membership alone.
- **Verify:** Entra → **Groups** lists both groups. Run `AVD-Set-UserAssignmentTargeting.ps1` to create them if absent.
- **Implement-if-missing:** Create the two security groups; start `AVD – Users – Pilot` with a few representative users.

---
## Checklist
- [ ] Azure subscription + resource group `AVD – Resource Group – Core`
- [ ] Eligible AVD license per user
- [ ] Entra ID users + host join model (Entra join or hybrid) decided
- [ ] VNet `AVD – VNet – Core` with DNS/connectivity
- [ ] Session-host image chosen (`avdsh-` prefix)
- [ ] FSLogix share `AVD – FSLogix Share – Core` ready
- [ ] Entra ID P1 for `AVD – Conditional Access – MFA`
- [ ] AVD client installed on Windows and macOS test devices
- [ ] Groups `AVD – Users – Pilot` and `AVD – Users – Production` created


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


# 3. Implementation Guide — Azure Virtual Desktop Remote Access

Follow these steps **in order**, in the **Azure portal** at `portal.azure.com` → search **Azure Virtual Desktop**. Object names use the `<Purpose> – <Scope> – <Stage>` convention from `02-requirements.md` and must be reused verbatim.

> **Model:** Stand up one pooled host pool, publish a Desktop, assign a small pilot, validate the Windows and macOS clients, then expand to production. Identity and FSLogix are configured before users connect.

## Step 1 — Create the assignment groups
1. `portal.azure.com` → **Microsoft Entra ID → Groups → New group → Security**. Name `AVD – Users – Pilot`, add a few representative users. **Create**.
2. Repeat to create `AVD – Users – Production` (the full audience). **Create**.
3. Confirm each member holds an eligible AVD license (Requirement 2.2).

## Step 2 — Prepare identity and networking
1. Decide the host join model (Entra join for cloud-only, or Entra hybrid join for line-of-sight to on-premises).
2. Confirm the virtual network `AVD – VNet – Core` exists with a session-host subnet and correct DNS (Requirement 2.4).
3. For Entra-joined hosts that need access to an Azure Files FSLogix share, confirm the share has identity-based authentication enabled (Requirement 2.6).

## Step 3 — Create the host pool
1. `portal.azure.com` → **Azure Virtual Desktop → Host pools → Create**.
2. **Basics:** Subscription, resource group `AVD – Resource Group – Core`, host pool name `AVD – Host Pool – Pilot`, location = your AVD region.
3. **Host pool type:** **Pooled** (shared multi-session). Set **Load balancing** to **Breadth-first**. (Choose **Personal** here instead only if each user must own a dedicated host.)
4. **Virtual machines:** **Yes, add virtual machines**. Resource group `AVD – Resource Group – Core`, **Name prefix** `avdsh-`, virtual network `AVD – VNet – Core` + session-host subnet, image = your chosen image (Requirement 2.5), VM size and count sized to the pilot.
5. **Domain to join:** select **Microsoft Entra ID** (or **Active Directory** for hybrid) per Step 2; tick **Enroll VM with Intune** only if managing hosts with Intune.
6. **Workspace:** choose **Yes, create a workspace** and name it `AVD – Workspace – Core` (this also creates the Desktop application group). **Review + create → Create**.

## Step 4 — Confirm the workspace and application group
1. **Azure Virtual Desktop → Application groups** — confirm a **Desktop** application group exists for `AVD – Host Pool – Pilot`; rename it (or its friendly name) to `AVD – App Group – Desktop`.
2. **Azure Virtual Desktop → Workspaces →** `AVD – Workspace – Core` **→ Application groups** — confirm `AVD – App Group – Desktop` is registered to the workspace. If not, **+ Add** it.
3. (Optional, to publish individual apps instead of a full desktop) **Application groups → Create → RemoteApp**, host pool `AVD – Host Pool – Pilot`, name `AVD – App Group – RemoteApp`, add the published apps, then register it to `AVD – Workspace – Core`.

## Step 5 — Assign users
1. **Azure Virtual Desktop → Application groups →** `AVD – App Group – Desktop` **→ Assignments → + Add**.
2. Add the group `AVD – Users – Pilot`. **Select**.
3. (Hybrid only) Also grant the same users the **Virtual Machine User Login** role on the host-pool resource group so they can sign in to the session hosts.

## Step 6 — Configure FSLogix on the session hosts
1. Confirm the FSLogix agent is present on the session hosts (baked into the image, or installed now).
2. **Azure Virtual Desktop → Host pools →** `AVD – Host Pool – Pilot` **→ Session hosts** to confirm the `avdsh-` hosts are **Available**.
3. Point FSLogix at the profile share `AVD – FSLogix Share – Core` by setting (via Intune Settings catalog, Group Policy, or registry) `Enabled = 1` and `VHDLocations` = the share UNC path under `HKLM:\SOFTWARE\FSLogix\Profiles`.
4. Ensure the FSLogix users have Modify rights on the share so each user's profile container can be created.

## Step 7 — Apply Conditional Access
1. `portal.azure.com` → **Microsoft Entra ID → Conditional Access → + New policy**. Name `AVD – Conditional Access – MFA`.
2. **Users:** include `AVD – Users – Pilot`; **exclude** your break-glass account.
3. **Target resources → Cloud apps:** include **Azure Virtual Desktop** (and **Microsoft Remote Desktop** / **Windows Cloud Login** as listed for your tenant).
4. **Grant:** **Require multifactor authentication**. Set the policy to **On**. **Create**.

## Step 8 — Connect the Windows client (validate)
1. On a Windows pilot device install the **Windows App** (or **Remote Desktop client**) — `Add work or school account` / subscribe to `https://client.wvd.microsoft.com/arm/webclient/index.html` via **Subscribe with URL**.
2. Sign in as a pilot user (Entra ID); complete the Conditional Access MFA prompt.
3. Confirm `AVD – Workspace – Core` appears and the **Desktop** (from `AVD – App Group – Desktop`) launches to a full Windows session.

## Step 9 — Connect the macOS client (validate)
1. On a Mac pilot device install the **Windows App** (or **Microsoft Remote Desktop**) from the **Mac App Store**.
2. **Add Workspace** → enter `https://client.wvd.microsoft.com/arm/webclient/index.html` (or sign in with the work account) and authenticate as a pilot user; complete MFA.
3. Confirm `AVD – Workspace – Core` and its Desktop appear and the session launches from macOS exactly as on Windows.

## Step 10 — Validate the pilot
1. Run `AVD-Validation.ps1` to confirm the host pool, session hosts (`avdsh-`), workspace, and Desktop application group are healthy and assigned.
2. Run `AVD-Report.ps1` to confirm pilot user sessions and assignments.
3. Complete the **Testing Guide** (`05-testing.md`) — both clients connect, the profile roams, and Conditional Access enforces MFA.

## Step 11 — Expand to production
1. Add session-host capacity to `AVD – Host Pool – Pilot` (or create `AVD – Host Pool – Production` for full scale) sized to the production audience.
2. Add the group `AVD – Users – Production` to `AVD – App Group – Desktop` (Step 5) and to the `AVD – Conditional Access – MFA` policy (Step 7).
3. Configure autoscale / start-on-connect to control idle cost, and re-run `AVD-Report.ps1` each cycle to track usage and assignment.

---
### Order of operations
`Groups → Identity + networking → Host pool → Workspace/app group → Assign users → FSLogix → Conditional Access → Windows client → macOS client → Validate → Expand`


---


# 5. Testing Guide — Azure Virtual Desktop Remote Access

Run after the pilot is configured (Implementation Step 10) and after each expansion.

## Test 1 — Host pool and session hosts healthy
**Do:** `portal.azure.com` → **Azure Virtual Desktop → Host pools →** `AVD – Host Pool – Pilot` **→ Session hosts**; or run `AVD-Validation.ps1`.
**Expected:** The `avdsh-` session hosts show **Available** with status **OK**.

## Test 2 — Workspace and Desktop published
**Do:** **Azure Virtual Desktop → Workspaces →** `AVD – Workspace – Core` **→ Application groups**.
**Expected:** `AVD – App Group – Desktop` is registered, and the pilot group `AVD – Users – Pilot` is assigned to it.

## Test 3 — Windows client connects
**Do:** On a Windows pilot device, subscribe in the Windows App / Remote Desktop client and launch the Desktop as a pilot user.
**Expected:** `AVD – Workspace – Core` appears; the Desktop launches to a full Windows session.

## Test 4 — macOS client connects
**Do:** On a Mac pilot device, add the workspace in the Windows App / Microsoft Remote Desktop and launch the Desktop as a pilot user.
**Expected:** The same workspace and Desktop appear and launch from macOS, matching the Windows experience.

## Test 5 — Conditional Access enforces MFA
**Do:** Sign in from either client as a pilot user covered by `AVD – Conditional Access – MFA`.
**Expected:** The user is prompted for multifactor authentication before the session opens; the break-glass account is unaffected.

## Test 6 — FSLogix profile roams
**Do:** Sign in to the pooled Desktop, create a file on the desktop, sign out, sign in again (landing on any `avdsh-` host).
**Expected:** A profile container exists on `AVD – FSLogix Share – Core`, and the file and settings persist across sessions.

## Test 7 — Usage and assignment report
**Do:** Run `AVD-Report.ps1`.
**Expected:** A clear list of host pools, application groups, assigned groups, and active/recent user sessions.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–6 pass — both clients connect, MFA is enforced, and the profile roams |
| **Production pass** | Tests 1–3, 5, 7 pass for the production audience before broad rollout |


---


# 6. Troubleshooting Guide — Azure Virtual Desktop Remote Access

Use `AVD-Validation.ps1` / `AVD-Discovery.ps1` for host-pool and readiness state, `AVD-Report.ps1` for usage and assignment, and `AVD-Remediation.ps1` (defaults to `-WhatIf`) for safe host fixes.

## A. Workspace or desktop does not appear in the client
| Symptom | Cause | Remediation |
|---|---|---|
| User sees no workspace | User not assigned, or assigned to the wrong application group | Confirm the user is in `AVD – Users – Pilot` and that group is assigned to `AVD – App Group – Desktop` |
| Workspace appears but is empty | Application group not registered to the workspace | Register `AVD – App Group – Desktop` to `AVD – Workspace – Core` (Implementation Step 4) |
| Subscribe URL fails | Wrong feed URL or stale cache | Use the ARM feed `https://client.wvd.microsoft.com/arm/webclient/index.html`; sign out and re-subscribe |

## B. Session host unavailable or won't accept connections
| Symptom | Cause | Remediation |
|---|---|---|
| `avdsh-` host shows Unavailable | Agent/host stopped or deallocated | Run `AVD-Validation.ps1`; start the VM; use `AVD-Remediation.ps1` (drop `-WhatIf` to act) to drain/restart |
| Status `Needs assistance` | AVD agent or boot-loader unhealthy | Restart the host; if persistent, reinstall the AVD agent or rebuild from the image |
| Pooled pool refuses new sessions | Drain mode on, or at max session limit | Turn off drain mode; add session-host capacity |

## C. Sign-in fails after authentication
- For Entra-joined hosts, confirm users hold the **Virtual Machine User Login** role on the host-pool resource group.
- For hybrid hosts, confirm Entra Connect sync is healthy and the host has line-of-sight to a domain controller.
- A blocked sign-in right after MFA usually means a Conditional Access grant the user can't satisfy — review `AVD – Conditional Access – MFA`.

## D. Conditional Access locking everyone out
- Confirm the break-glass account is **excluded** from `AVD – Conditional Access – MFA`.
- Use **Conditional Access → Insights and reporting** (What If) to confirm the policy targets only the intended users and the AVD cloud apps.

## E. FSLogix / profile problems
| Symptom | Cause | Remediation |
|---|---|---|
| Slow logon / temp profile | Share unreachable or permissions wrong | Confirm `AVD – FSLogix Share – Core` is reachable and users have Modify rights; check `VHDLocations` |
| Profile not roaming | FSLogix not enabled on the host | Confirm `Enabled = 1` and `VHDLocations` under `HKLM:\SOFTWARE\FSLogix\Profiles` |
| Container in use / locked | Stale session holding the VHD | Sign the user fully out of all hosts; clear the lock per FSLogix guidance |

## F. macOS client specifics
- If the Mac client cannot add the workspace, confirm the latest **Windows App** / **Microsoft Remote Desktop** from the Mac App Store and use the same ARM feed URL as Windows.
- macOS sign-in uses the same Entra ID account and MFA as Windows; a Mac-only failure with a working Windows client points to an outdated Mac client or a clock/keychain issue on the Mac.

## G. Diagnostics quick reference
```powershell
Get-AzWvdHostPool -ResourceGroupName 'AVD - Resource Group - Core'
Get-AzWvdSessionHost -ResourceGroupName 'AVD - Resource Group - Core' -HostPoolName 'AVD - Host Pool - Pilot'
Get-AzWvdUserSession -ResourceGroupName 'AVD - Resource Group - Core' -HostPoolName 'AVD - Host Pool - Pilot'
Get-ItemProperty 'HKLM:\SOFTWARE\FSLogix\Profiles' -ErrorAction SilentlyContinue
```
The **AVD Insights** workbook (Azure Monitor) gives connection success, latency, and host-health detail.

## H. When to escalate
If the host pool is healthy, the user is assigned and licensed, Conditional Access permits the sign-in, and the client still cannot connect after re-subscribing and a host restart, collect the AVD Insights connection diagnostics and the client error code and open a Microsoft support case.


---


# 7. Best Practices — Azure Virtual Desktop Remote Access

- **Pilot before you scale.** A small `AVD – Users – Pilot` group on a single host pool catches image, profile, and Conditional Access issues before they reach the whole audience — the single most important practice.
- **Assign by group, never by user.** Grant access through `AVD – Users – Pilot` / `AVD – Users – Production` so adding a person is one group membership, not a portal change to the application group.
- **Choose the host pool type deliberately.** Use pooled multi-session for cost efficiency where users share a standard desktop; use personal only when a user genuinely needs a dedicated, persistent host.
- **Get FSLogix right first.** Size the `AVD – FSLogix Share – Core` for performance and high availability; an undersized or slow share is the top cause of slow logons and corrupt profiles.
- **Govern the front door.** Keep `AVD – Conditional Access – MFA` enforcing MFA (and, where possible, compliant-device or trusted-location conditions), and always exclude a break-glass account.
- **Name everything consistently.** Reuse the `<Purpose> – <Scope> – <Stage>` names and the `avdsh-` host prefix so the environment is self-documenting and scriptable.
- **Validate both clients every cycle.** Confirm the Windows and macOS clients each connect after image or policy changes — the two platforms can diverge.
- **Control idle cost.** Enable autoscale / start-on-connect so session hosts run only when users are working.
- **Keep images current.** Patch and rebuild the session-host image on a cadence; pin a known-good image version in a compute gallery for repeatable host creation.
- **Watch usage.** Track sessions and assignment with `AVD-Report.ps1` (and the AVD Insights workbook) to right-size capacity and chase unused assignments.


---


# 8. Deliverables Summary — Azure Virtual Desktop Remote Access

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What AVD is — host pools (pooled vs. personal), workspace, application groups, identity, FSLogix, Windows + macOS clients, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Azure Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Azure portal steps (host pool, workspace, app group, assignment, FSLogix, Conditional Access, Windows + macOS clients) |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `AVD-Discovery.ps1` | Reports AVD readiness — subscription, resource group, host pools, session hosts, and identity context (read-only) |
| `AVD-Validation.ps1` | Confirms the host pool, session hosts, workspace, and Desktop application group are healthy and assigned (read-only) |
| `AVD-Report.ps1` | Usage and assignment report — host pools, application groups, assigned groups, and user sessions (read-only) |
| `AVD-Remediation.ps1` | Safe remediation of unhealthy session hosts (drain/restart); defaults to `-WhatIf` |
| `AVD-Set-UserAssignmentTargeting.ps1` | Builds the `AVD – Users – Pilot` / `AVD – Users – Production` assignment groups and adds members |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Secure, governed remote access to full Windows desktops and apps — delivered from Azure, reachable from both Windows and macOS, with roaming profiles and MFA at the door — proven on a pilot before you scale.
