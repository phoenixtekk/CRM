# Azure Virtual Desktop — Deployment, Golden Image & FSLogix

> **Version 1.0.0** · Category: Azure · Solution code: AVDDEP

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Azure Virtual Desktop: Deployment, Golden Image & FSLogix

**Azure Solutions**

Deploying Azure Virtual Desktop (AVD) by hand produces snowflake session hosts, roaming-profile pain, and a runaway bill. Every host is patched slightly differently, profiles do not follow users cleanly, and idle VMs run all night. This package builds AVD the engineered way: a **versioned golden image** produced by a repeatable build pipeline, session hosts deployed from that image by **infrastructure-as-code (Bicep)**, **FSLogix profile containers** on a correctly sized Azure Files or Azure NetApp Files share, **role-based access control** on the AVD objects, a **drain-mode patch workflow** for updates, and **autoscale scaling plans** that shut idle hosts down.

This is a complete, **deploy-it-today** package for the *build and operate* side of AVD, written for an administrator with no prior image-pipeline or IaC experience.

## Scope boundary
This solution covers the **deployment, imaging, host-pool build, FSLogix storage, and scaling** side of AVD. It does **not** re-cover end-user client access and connectivity from Windows and macOS — that is the companion **Azure Virtual Desktop Remote Access (Windows & macOS Clients)** solution. Where the two meet (host pools, workspaces, FSLogix), this guide cross-references rather than duplicates.

## What you get
- A plain-language **Solution Overview** of golden images, Azure Compute Gallery versioning, image-build pipelines, IaC session-host deployment, FSLogix storage sizing, RBAC, drain/patch, and scaling plans.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite specific to the build — a build/source VM, Azure Compute Gallery, FSLogix storage account, IaC tooling, and Azure roles.
- An **Implementation Guide** of precise, ordered steps: build and capture the golden image, version it in a gallery, deploy pilot session hosts from Bicep, wire up FSLogix, assign RBAC, apply a scaling plan, then expand.
- Five **automation artifacts** — read-only discovery, validation, and reporting scripts (PowerShell/Az), a **Bicep** session-host + scaling-plan template, and a gated drain/patch maintenance script.
- **Testing** and **Troubleshooting** guides for a confident rollout.

## What this delivers
A repeatable, cost-controlled AVD estate: session hosts built from one **versioned image** in an Azure Compute Gallery, deployed by **Bicep** (not hand-built), profiles roamed by **FSLogix** on a right-sized share, updates rolled out with **drain mode**, and idle capacity removed by an **autoscale scaling plan** — proven on a pilot host pool before you scale.

## The deployment model
**Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Consistent golden images, roaming profiles, IaC-deployed hosts, and automatic cost control — an AVD estate a single administrator can build, version, and operate, proven on a pilot before production.

## Effort
Roughly two to four days for a first pilot host pool (image build and capture is the longest single step), then hours per subsequent wave because the image, the Bicep template, and the scaling plan are reused.


---


# 1. Solution Overview — Azure Virtual Desktop: Deployment, Golden Image & FSLogix

## What this solution is
This is the **build-and-operate** side of Azure Virtual Desktop (AVD). Where the companion *AVD Remote Access* solution covers how end users connect from Windows and macOS clients, this solution covers how you **produce a consistent golden image**, **deploy session hosts from it with code**, **store user profiles at scale with FSLogix**, **control who can administer the estate (RBAC)**, and **keep cost down with autoscale** — so the estate is repeatable instead of hand-built.

If you have not yet created any AVD host pool at all, deploy the pilot host pool described here; the *AVD Remote Access* solution then covers publishing it to end users and validating the Windows/macOS client experience. The two are designed to be used together without overlap.

## How the technology works
1. A **golden image** is a single, fully configured Windows master (Windows 11 Enterprise multi-session, plus your agents, runtime, and line-of-business apps) that every session host is built from. Building once and cloning many is what makes hosts identical instead of snowflakes.
2. An **Azure Compute Gallery** (formerly Shared Image Gallery) stores that image as an **image definition** with numbered, immutable **image versions** (for example `1.0.0`, `1.1.0`). Because each version is immutable, you always know exactly what a host was built from, and you can replicate a version to multiple regions and roll back to a prior version.
3. An **image-build pipeline** turns "build a new image" into a repeatable job. It starts from a source (the Azure Marketplace base image or your previous gallery version), applies your customizations (Windows Update, app installs, FSLogix agent, optimizations), then captures the result as a **new image version**. This can be a documented manual capture, or automated with **Azure VM Image Builder** (Azure Image Builder / VM image templates) so the same definition rebuilds monthly.
4. **Session hosts** are the real Windows VMs that carry user sessions. Deploying them from **infrastructure-as-code (Bicep)** — referencing a specific gallery image version — means a host pool of ten or a hundred hosts is one reviewable, re-runnable template, not a hundred manual VM creations.
5. **FSLogix profile containers** store each user's Windows profile as a VHDX on a file share (**Azure Files** or **Azure NetApp Files**). On a pooled multi-session host pool, a user can land on any host and their profile, settings, and Outlook/Teams cache follow them. Correct **sizing, redundancy, and permissions** on that share is the single biggest driver of logon performance.
6. **Role-based access control (RBAC)** on the AVD objects (using the built-in *Desktop Virtualization* roles) governs who can operate the host pools, workspaces, and application groups without handing out broad subscription rights.
7. A **scaling plan** attached to the host pool ramps session hosts up before business hours and drains/deallocates them when idle, so you pay for compute only when people are working.
8. A **drain-and-patch workflow** takes hosts out of rotation gracefully (drain mode), updates them (or replaces them with a new image version), and returns them to service — so updates never disconnect an active user mid-session.

## The standard deployment model
> **Assess** your subscription, licensing, regions, and where profiles and images will live → **Configure** the Compute Gallery, build and version the golden image, and prepare FSLogix storage → **Pilot** a small host pool deployed from the image by Bicep, with FSLogix and a scaling plan → **Validate** image currency, host health, profile roaming, RBAC, and scaling against explicit pass/fail gates → **Expand** to production waves, reusing the same image, template, and scaling plan.
>
> The repeatable model: **Assess → Configure → Pilot → Validate → Expand.**

## What you can control
- **Image contents and cadence** — what is baked into the golden image, and how often a new version is built.
- **Versioning and rollback** — immutable gallery versions and multi-region replication; roll a host pool back to a prior version if a new one regresses.
- **Deployment method** — session hosts deployed reproducibly from a Bicep template pinned to a specific image version.
- **Profile storage** — FSLogix on Azure Files vs Azure NetApp Files, share sizing, redundancy, and identity (Kerberos) model.
- **Administration** — least-privilege RBAC on the AVD objects using the built-in Desktop Virtualization roles.
- **Cost** — autoscale scaling plans, ramp schedules, and capacity thresholds.
- **Updates** — drain-mode patch cycles or image-version replacement, host by host, with no mid-session disconnects.

## Scope — in
Golden-image build and capture; Azure Compute Gallery image definitions and versions; an image-build pipeline (manual-capture method plus the Azure VM Image Builder option); Bicep deployment of a host pool and session hosts from a gallery image version; FSLogix profile-container storage design and configuration on Azure Files / Azure NetApp Files; RBAC on the AVD objects; a scaling plan for cost control; and the drain/patch update workflow.

## Scope — out (covered elsewhere or by the customer)
- **End-user client access and connectivity** from Windows and macOS, workspace subscription, and the connection experience — see the companion **AVD Remote Access (Windows & macOS Clients)** solution.
- **Conditional Access / MFA policy design** for AVD sign-in — covered by the Remote Access solution and your Entra security baseline.
- **Which applications belong in the image**, application packaging/licensing, and **data-residency, records, and regulatory determinations** — these are customer business, compliance, and legal decisions; this guide provides the technical build, not the decision.
- **Production change approval** — disruptive steps (image cutover, host replacement, scaling changes) are staged behind your own change-management process.

## Authentication and connections used
- **Azure RBAC** (Owner/Contributor to build; Desktop Virtualization roles to operate) on the subscription or resource group in scope.
- **Microsoft Entra ID** for the identity that session hosts and FSLogix storage join to (Entra join, Entra Domain Services, or AD DS — verify which your tenant uses).
- **Az PowerShell modules** (`Az.Accounts`, `Az.Compute`, `Az.DesktopVirtualization`, `Az.Storage`, `Az.Resources`) for the discovery, validation, reporting, and maintenance scripts.
- **Bicep / Azure Resource Manager** for the session-host and scaling-plan deployment template.

*Feature availability, image SKUs, licensing, and any preview capabilities (for example Azure VM Image Builder regional availability or Entra-Kerberos for Azure Files) change over time — verify current availability in your tenant and region before you build.*


---


# 2. Requirements — Azure Virtual Desktop: Deployment, Golden Image & FSLogix

The **category-level platform prerequisites** (an Entra tenant, admin roles, licensing baseline, network connectivity, change control, and backup/rollback posture) are covered once in **`global-requirements-azure-solutions.md`** — read that first. This document adds only the requirements **specific to building and operating AVD**: the image pipeline, IaC deployment, FSLogix storage, and scaling. Each item is structured **Description / Why required / How to verify / How to implement if missing**.

> Naming convention (reused verbatim throughout): every object is named `<Purpose> – <Scope> – <Stage>`, for example `AVD – Host Pool – Pilot` and `AVD – Session Host – Production`. Azure resource types that forbid spaces/hyphens (notably the Compute Gallery) use the technical form noted at each object.

---

## R1. An AVD-eligible Windows license per user

- **Description:** Each user connecting to AVD holds an eligible license — Microsoft 365 E3/E5/A3/A5/F3/Business Premium, or Windows E3/E5, or a per-user access license for external users.
- **Why required:** Windows 11 Enterprise multi-session session hosts require an eligible license per connecting user; without it the deployment is out of compliance.
- **How to verify:** In the Microsoft 365 admin center → **Billing → Licenses**, confirm the in-scope users carry an eligible SKU. Cross-check the current eligible-license list in Microsoft's AVD documentation — *verify current availability, entitlements change.*
- **How to implement if missing:** Assign an eligible SKU to each in-scope user, or procure per-user access licensing for external users, before publishing the pilot.

## R2. Azure Compute Gallery for image versioning

- **Description:** An Azure Compute Gallery (formerly Shared Image Gallery) with an **image definition** for the AVD image, into which numbered **image versions** are published. Logical name `AVD – Compute Gallery – Core`; because galleries forbid spaces and hyphens, the technical resource name is `avd_compute_gallery_core`, with image definition `avd-win11-m365-multisession`.
- **Why required:** The gallery is what makes the image *versioned, immutable, replicable, and roll-back-able*. Deploying from a Marketplace image directly gives you no version history and no rollback.
- **How to verify:** In the portal, open **Azure Compute Gallery** and confirm the gallery, the image definition (OS: Windows, generation: **Gen2**, security type matching your VMs), and at least one version exist. Or run `AVDDEP-Discovery.ps1`, which lists galleries, definitions, and versions.
- **How to implement if missing:** Create the gallery and an image definition (Section 3, Step 2). Set the image definition's OS state to **Generalized** and generation to **Gen2** to match modern AVD VM sizes.

## R3. A build/source VM for the golden image

- **Description:** A temporary "build" VM — `AVD – Image Build VM – Staging` — from the correct base (Windows 11 Enterprise **multi-session** + Microsoft 365 Apps, Gen2) used to install and configure everything before capture.
- **Why required:** The golden image is produced by customizing a live VM and then generalizing/capturing it. A dedicated, disposable build VM keeps the process repeatable and keeps production hosts untouched during builds.
- **How to verify:** Confirm you can create a VM from the intended base image SKU in the target region (**Marketplace → Windows 11 Enterprise multi-session + Microsoft 365 Apps**), and that its size supports **Gen2 / Trusted Launch** if you use those.
- **How to implement if missing:** Deploy the build VM from the base image (Section 3, Step 3). Keep it in a dedicated `AVD – Resource Group – Imaging` resource group so build artifacts are isolated.

## R4. FSLogix profile-container storage (Azure Files or Azure NetApp Files)

- **Description:** A file share for FSLogix profile containers — either an **Azure Files** premium (SMB) share or an **Azure NetApp Files** volume — sized for the user population, with an identity source (AD DS, Entra Domain Services, or Entra Kerberos) the session hosts can authenticate to. Logical name `AVD – Profile Share – Core`.
- **Why required:** On pooled multi-session hosts, profiles must live off-host so they roam. An undersized or high-latency share is the single most common cause of slow logons and profile corruption.
- **How to verify:** Confirm the share/volume exists, its tier (premium Azure Files or the correct ANF service level) and size match the plan (allow ~5–30 GB per profile depending on Outlook/Teams cache), and that session hosts can mount it with the chosen identity. `AVDDEP-Validate.ps1` checks that hosts have the FSLogix registry pointing at the share.
- **How to implement if missing:** Provision the share/volume, set NTFS and share-level permissions (users: modify; admins: full), join the storage to your identity source, and record the UNC path for the FSLogix configuration (Section 3, Step 6). *Entra Kerberos for Azure Files may be in preview in some clouds/regions — verify current availability.*

## R5. Bicep / IaC tooling and deployment rights

- **Description:** The **Azure CLI** (or Az PowerShell) with **Bicep** installed, and RBAC rights to deploy resources into the target resource group (Contributor plus *Desktop Virtualization Contributor*).
- **Why required:** Session hosts are deployed from the provided `AVDDEP-SessionHosts.bicep` template. Deploying requires Bicep tooling and the rights to create VMs, NICs, and AVD host-pool resources.
- **How to verify:** Run `az bicep version` (or `Get-Command bicep`), and confirm your account holds Contributor + Desktop Virtualization Contributor on the target scope in **Subscriptions → Access control (IAM)**.
- **How to implement if missing:** Install Bicep (`az bicep install`), and have an Owner assign the required roles (least privilege — scope to the resource group, not the subscription, where possible).

## R6. Host-pool registration path and networking

- **Description:** A virtual network/subnet in the target region for the session hosts, with line-of-sight to the FSLogix storage and to the identity source, and a **host-pool registration token** issued at deploy time so new hosts join the pool.
- **Why required:** Session-host VMs need a subnet, DNS that resolves your identity source, and a valid (unexpired) registration token to join the AVD host pool. An expired token is the classic cause of "VM deployed but not showing as a session host."
- **How to verify:** Confirm the subnet exists and resolves internal DNS; the Bicep deployment generates a fresh registration token, so verify the host pool's token expiry in **Host pool → Registration key** if you register hosts manually.
- **How to implement if missing:** Create/select the subnet, ensure DNS points at the identity source, and let the Bicep template mint a fresh token at deploy time (tokens are short-lived — generate at deploy, do not reuse old ones).

## R7. Azure Monitor / Log Analytics workspace (recommended)

- **Description:** A Log Analytics workspace connected to the host pool and session hosts to surface connection, performance, and FSLogix diagnostics (AVD Insights).
- **Why required:** Validating "is the estate healthy and are logons fast?" depends on host and FSLogix telemetry. Without it, troubleshooting is blind.
- **How to verify:** In **Azure Virtual Desktop → Insights**, confirm a workspace is configured and hosts report data.
- **How to implement if missing:** Create a Log Analytics workspace and enable AVD Insights (diagnostic settings on the host pool + the AVD Insights workbook). This is recommended, not blocking, for the pilot.


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


# 3. Implementation Guide — Azure Virtual Desktop: Deployment, Golden Image & FSLogix

Follow these steps in order. Every object you create is named with the convention `<Purpose> – <Scope> – <Stage>` and reused verbatim in later steps, in **Testing**, and in the scripts. Portal paths are current as of authoring; Microsoft renames blades occasionally — *verify the exact label in your portal*. **Pilot first**: build one image, one pilot host pool, prove it, then expand.

> Before you start, run **`AVDDEP-Discovery.ps1`** to capture what already exists (galleries, host pools, session hosts, storage, scaling plans). This is your baseline and your rollback reference (global requirement G6).

---

## Step 1 — Create the resource groups and the Compute Gallery

1. In the Azure portal, go to **Resource groups → + Create** and create two groups in your target region:
   - `AVD – Resource Group – Core` — holds the host pool, workspace, application group, and scaling plan.
   - `AVD – Resource Group – Imaging` — holds the build VM and the Compute Gallery, so build artifacts stay isolated.
2. Go to **Azure Compute Gallery → + Create**, in `AVD – Resource Group – Imaging`. Give it the technical name **`avd_compute_gallery_core`** (galleries forbid spaces and hyphens; this is the logical `AVD – Compute Gallery – Core`). Create.
3. Open the gallery → **Definitions → + Add / Create a VM image definition**:
   - **Name:** `avd-win11-m365-multisession`
   - **OS type:** Windows · **OS state:** Generalized · **VM generation:** **Gen2**
   - Publisher/Offer/SKU: your own identifiers (e.g. `contoso / avd / win11-multisession`).
   - Create. You now have a definition ready to receive versions.

## Step 2 — Deploy the build VM

1. Go to **Virtual machines → + Create**. Under **Image**, choose **See all images → Marketplace** and select **Windows 11 Enterprise multi-session + Microsoft 365 Apps** (Gen2). *Verify the exact SKU name in Marketplace — Microsoft revises image names.*
2. Name it `AVD – Image Build VM – Staging`, place it in `AVD – Resource Group – Imaging`, size it modestly (e.g. a D4s-class VM — this is a build box, not a session host), and place it on your build subnet.
3. Leave it **not** joined to your production identity during build (a workgroup build VM is cleanest for generalizing). Create and connect over RDP/Bastion.

## Step 3 — Build the golden image (customize the source)

On `AVD – Image Build VM – Staging`, apply your standard build. Keep a written checklist so every future rebuild is identical:
1. Run **Windows Update** fully; reboot until clean.
2. Install the **FSLogix agent** (latest) — configuration comes later via policy/registry, not baked-in secrets.
3. Install line-of-business apps and runtimes that belong on every host.
4. Apply the **Microsoft AVD image optimizations** (the Virtual Desktop Optimization Tool / recommended settings) to trim background tasks.
5. Do **not** run Sysprep manually yet if you will capture through the portal (the capture flow generalizes for you). Remove any per-user or secret material.

> Everything disruptive here is on a disposable build VM, so there is no production impact. This is the only place app contents are decided — *which* apps belong in the image is a customer decision (Overview, "Scope — out").

## Step 4 — Capture the image as a gallery version

1. On the build VM's blade, click **Capture** (top toolbar).
2. Choose **Yes, share it to a gallery as a VM image version.**
3. Target gallery **`avd_compute_gallery_core`**, image definition **`avd-win11-m365-multisession`**.
4. **Version number:** `1.0.0` (use semantic versions; a monthly patch becomes `1.1.0`, a rebuild-from-scratch `2.0.0`).
5. Set **replica count** and **target regions** to match where you will deploy hosts (replicate to each region you run host pools in).
6. Tick **Automatically delete this virtual machine after capture** so the build VM is cleaned up.
7. Create. When the version shows **Succeeded**, you have an immutable, versioned golden image. Confirm with `AVDDEP-Report.ps1` (image inventory).

## Step 5 — Prepare FSLogix profile storage

1. Provision the profile share `AVD – Profile Share – Core` — either an **Azure Files** premium file share or an **Azure NetApp Files** volume — in the host-pool region (co-locate with hosts for low latency).
2. Join the storage to your identity source (AD DS, Entra Domain Services, or Entra Kerberos for Azure Files — *verify current availability in your cloud/region*).
3. Set permissions: **Users → Modify** on the share (so each user can create their own container), **Admins → Full**. Remove broad inherited rights.
4. Record the UNC path (e.g. `\\avdprofilescore.file.core.windows.net\profiles`). You will point FSLogix at it in Step 8.

## Step 6 — Deploy the pilot host pool and session hosts with Bicep

1. Open the provided **`AVDDEP-SessionHosts.bicep`** and set its parameters:
   - `hostPoolName`: `AVD – Host Pool – Pilot`
   - `hostPoolType`: `Pooled`, `loadBalancerType`: `BreadthFirst`
   - `galleryImageId`: the resource ID of version `1.0.0` of `avd-win11-m365-multisession`
   - `sessionHostCount`: **2** (pilot), `vmSize`: your standard multi-session size
   - `subnetId`, `resourceGroup`: `AVD – Resource Group – Core`, `location`: your region
2. **Preview first (never apply blind):**
   ```
   az deployment group what-if \
     --resource-group "AVD – Resource Group – Core" \
     --template-file AVDDEP-SessionHosts.bicep \
     --parameters @avddep.pilot.parameters.json
   ```
   Review the what-if output — it must show the host pool, 2 VMs/NICs, and the scaling-plan association being **created**, nothing being deleted.
3. Deploy (swap `what-if` for `create`). The template mints a **fresh host-pool registration token** at deploy time (requirement R6) so the new hosts join `AVD – Host Pool – Pilot` automatically.
4. Confirm the two hosts appear under **Host pool → Session hosts** as **Available**. Run `AVDDEP-Validate.ps1` to confirm agent health and image provenance.

> The host pool, workspace, and application-group *plumbing* is created here; **publishing to end users and validating the Windows/macOS client** is the companion *AVD Remote Access* solution — do not duplicate that work here.

## Step 7 — Assign RBAC on the AVD objects

1. On `AVD – Host Pool – Pilot` → **Access control (IAM) → + Add role assignment**, assign **Desktop Virtualization Host Pool Contributor** to the operators group `AVD – Operators – Group`.
2. On `AVD – Resource Group – Core`, assign **Desktop Virtualization Contributor** to the same group for day-to-day operation, and keep **Owner** limited to the platform team.
3. Prefer eligible (PIM) activation over standing access where your licensing allows (global requirement G2). Confirm with `AVDDEP-Validate.ps1` (RBAC section).

## Step 8 — Configure FSLogix on the session hosts

1. FSLogix is installed in the image (Step 3); now point it at the share. Apply the FSLogix settings by **Group Policy** or the registry values under `HKLM\SOFTWARE\FSLogix\Profiles`:
   - `Enabled = 1`
   - `VHDLocations = \\avdprofilescore.file.core.windows.net\profiles` (the Step 5 UNC path)
   - `DeleteLocalProfileWhenVHDShouldApply = 1`, `FlipFlopProfileDirectoryName = 1`
2. Sign a pilot user in twice on different hosts and confirm a `Profile_<username>.vhdx` appears on the share and the profile roams. `AVDDEP-Validate.ps1` reports the FSLogix registry state per host.

## Step 9 — Create and assign the autoscale scaling plan

1. Go to **Azure Virtual Desktop → Scaling plans → + Create**. Name it `AVD – Scaling Plan – Pilot`, region matching the host pool, **host pool type: Pooled**.
2. Add a schedule (e.g. `Weekdays`): ramp-up before business hours, peak during the day, ramp-down and off-peak after hours, with a **capacity threshold** (e.g. 75–80%) and **minimum percent of hosts** during ramp-down.
3. Under **Host pool assignments**, tick **`AVD – Host Pool – Pilot`** and **Enable autoscale**.
4. Grant the AVD service principal the **Power On/Off** rights it needs (the portal prompts for the required custom role assignment). Confirm the plan and schedule with `AVDDEP-Report.ps1` (scaling section).

## Step 10 — Establish the drain-and-patch workflow

1. When a new image version (e.g. `1.1.0`) is ready, you patch by **replacing hosts**, not editing live ones: put existing hosts into **drain mode**, let sessions finish, then deploy replacement hosts from the new version and remove the old.
2. Preview the drain safely with **`AVDDEP-Maintenance.ps1`** — it **defaults to `-WhatIf`**, listing which hosts *would* be drained and their active session counts. Only with an explicit `-Apply` does it set drain mode.
3. Re-run `AVDDEP-SessionHosts.bicep` with `galleryImageId` pointed at `1.1.0` to add fresh hosts, confirm health, then remove the drained old hosts. This is a **change-controlled** action (global requirements G5/G6) — do it in a window with a rollback (redeploy the prior image version) ready.

## Step 11 — Validate the pilot, then expand

1. Run the full **Testing** guide (`05-testing.md`) against `AVD – Host Pool – Pilot`. All gates must pass before expanding.
2. To expand, reuse the same artifacts: bump `sessionHostCount` and deploy a `AVD – Host Pool – Production` from the **same** image version and Bicep template, attach a `AVD – Scaling Plan – Production`, and assign RBAC. No hand-building — every wave is the same reviewable deployment.

### Order of operations (summary)
Resource groups + gallery → build VM → customize → capture version `1.0.0` → FSLogix storage → **what-if** then deploy pilot hosts (Bicep) → RBAC → FSLogix config → scaling plan → drain/patch workflow → validate → expand to production from the same image and template.


---


# 5. Testing & Validation — Azure Virtual Desktop: Deployment, Golden Image & FSLogix

Run every check against the pilot (`AVD – Host Pool – Pilot`) before expanding to production. Each test has an explicit **pass/fail gate**. The scripts referenced here are in the `scripts/` folder and are read-only except `AVDDEP-Maintenance.ps1`, which defaults to a safe `-WhatIf` preview.

> Run order: `AVDDEP-Discovery.ps1` → `AVDDEP-Validate.ps1` → `AVDDEP-Report.ps1`. Use `AVDDEP-Maintenance.ps1` (preview mode) only to rehearse the drain/patch gate.

---

## Test 1 — Golden image is versioned in the gallery
- **How:** Run `AVDDEP-Discovery.ps1` (or `AVDDEP-Report.ps1`). Confirm `avd_compute_gallery_core` contains the definition `avd-win11-m365-multisession` with version `1.0.0` in state **Succeeded**, replicated to each target region.
- **Pass:** The version exists, is Succeeded, and is Gen2/Generalized.
- **Fail:** No version, a Failed replication, or a generation mismatch → revisit Section 3, Step 4.

## Test 2 — Session hosts were built from the intended image version
- **How:** Run `AVDDEP-Validate.ps1`. It reports each session host's source image reference and flags any host whose image does **not** match the gallery version the host pool was deployed from.
- **Pass:** All hosts in `AVD – Host Pool – Pilot` trace to gallery version `1.0.0`.
- **Fail:** A host built from a Marketplace image or an older version → it is a snowflake; redeploy it from Bicep (Step 6).

## Test 3 — Session hosts are healthy and registered
- **How:** In **Host pool → Session hosts**, confirm both pilot hosts show **Available** with a healthy AVD agent; `AVDDEP-Validate.ps1` reports agent/status per host.
- **Pass:** All pilot hosts **Available**, no **Unavailable**/**Upgrading**/**NeedsAssistance**.
- **Fail:** A host stuck not-registered usually means an expired registration token (requirement R6) → redeploy so a fresh token is minted; do not hand-edit.

## Test 4 — FSLogix profiles roam
- **How:** Sign a pilot user into two different hosts in turn. Confirm a `Profile_<user>.vhdx` is created on `AVD – Profile Share – Core` and that desktop/settings/Outlook cache follow the user. `AVDDEP-Validate.ps1` confirms the FSLogix registry on each host points at the correct UNC path with `Enabled=1`.
- **Pass:** One container per user on the share; profile identical across hosts; logon completes in a reasonable time.
- **Fail:** A fresh temp profile each logon, or no VHDX → check share permissions (users: Modify) and the `VHDLocations` value (Section 3, Step 8).

## Test 5 — RBAC is least-privilege and correct
- **How:** `AVDDEP-Validate.ps1` lists role assignments on the host pool and resource group. Confirm operators hold **Desktop Virtualization** roles, not broad **Owner/Contributor** at subscription scope.
- **Pass:** Operators have Desktop Virtualization Contributor / Host Pool Contributor scoped to the RG/host pool; Owner is limited to the platform team.
- **Fail:** Broad standing Owner on operators → tighten per Section 3, Step 7 (prefer PIM).

## Test 6 — Scaling plan controls capacity
- **How:** `AVDDEP-Report.ps1` prints the scaling plan, its schedules, and the host-pool assignment. Confirm `AVD – Scaling Plan – Pilot` is **enabled** and assigned to `AVD – Host Pool – Pilot`. Observe that off-peak drives idle hosts to deallocated.
- **Pass:** Plan enabled and assigned; ramp-up/ramp-down/off-peak schedule present; idle hosts deallocate off-peak.
- **Fail:** Plan not assigned, or hosts never power down → confirm the AVD service principal has Power On/Off rights (Section 3, Step 9).

## Test 7 — IaC deployment is reproducible (what-if is clean)
- **How:** Re-run the Section 3, Step 6 `az deployment group what-if` against the pilot parameters.
- **Pass:** What-if reports **no changes** (the deployed state matches the template) — proving the estate is fully described by code.
- **Fail:** What-if wants to change/recreate resources you did not change → a manual drift crept in; reconcile the template to reality before expanding.

## Test 8 — Drain/patch workflow is safe (rehearsal)
- **How:** Run `AVDDEP-Maintenance.ps1` in its **default `-WhatIf`** mode. Confirm it lists which hosts *would* be drained and their active session counts **without changing anything**.
- **Pass:** Preview lists targets and session counts; no drain mode is actually set.
- **Fail:** Any state change in preview mode, or the script errors → do not run `-Apply`; resolve first.

---

### Exit criteria (all must be green before expanding)
Image version Succeeded (T1) · hosts trace to that version (T2) · hosts Available (T3) · FSLogix roams (T4) · RBAC least-privilege (T5) · scaling plan enabled and cost-effective (T6) · what-if clean/reproducible (T7) · drain preview safe (T8). Only then deploy `AVD – Host Pool – Production` from the same image and template.


---


# 6. Troubleshooting — Azure Virtual Desktop: Deployment, Golden Image & FSLogix

Common failures on the build/deploy/FSLogix/scaling side, as **symptom → cause → fix**. Run `AVDDEP-Discovery.ps1` and `AVDDEP-Validate.ps1` first — most issues show up there. (Client-connection problems from Windows/macOS belong to the companion *AVD Remote Access* solution.)

---

## Image build & gallery

**Symptom — image version stuck in *Creating* or *Failed* replication.**
- **Cause:** Region replication in progress, quota shortfall in a target region, or a generalize/capture that did not complete cleanly.
- **Fix:** Check the version's replication status per region; ensure compute quota exists in each target region; if the capture failed, redeploy the build VM and re-capture. Confirm the build VM was **generalized** (OS state *Generalized*) before capture.

**Symptom — new session hosts won't build from the gallery image ("image not found" / generation mismatch).**
- **Cause:** The image definition generation (Gen1/Gen2) or security type does not match the VM size, or the `galleryImageId` points at a definition instead of a specific version.
- **Fix:** Ensure the definition is **Gen2** and the VM size supports it (and Trusted Launch if used). Point `galleryImageId` at a full **version** resource ID (`.../versions/1.0.0`), not the definition.

**Symptom — every host looks slightly different despite "using the image."**
- **Cause:** Some hosts were created from a Marketplace image or an older version, i.e. snowflakes.
- **Fix:** `AVDDEP-Validate.ps1` (Test 2) flags hosts whose image does not trace to the expected version — redeploy those from `AVDDEP-SessionHosts.bicep` pinned to the correct version.

## Session-host deployment (Bicep)

**Symptom — VMs deploy but never appear as session hosts in the host pool.**
- **Cause:** Expired or reused host-pool **registration token** (the single most common cause).
- **Fix:** Registration tokens are short-lived. Let the Bicep template mint a fresh token at deploy time (do not reuse an old one). Redeploy so a new token is issued, then confirm hosts appear as **Available**.

**Symptom — `what-if` wants to delete or recreate resources you did not change.**
- **Cause:** Manual drift — someone edited the estate in the portal after the last deploy.
- **Fix:** Reconcile the template to reality (import the manual change into the Bicep or revert the manual change) until `what-if` reports **no changes** (Testing T7). Never expand to production on a dirty what-if.

**Symptom — deployment fails on the admin password parameter.**
- **Cause:** Password complexity not met, or the secure parameter was left empty.
- **Fix:** Supply a compliant password via a **secure parameter or Key Vault reference** — never hard-code it. Meet Windows complexity rules (length + character classes).

## FSLogix / profiles

**Symptom — users get a fresh temporary profile every logon; no VHDX on the share.**
- **Cause:** FSLogix not enabled, wrong `VHDLocations`, or the user lacks Modify rights on the share.
- **Fix:** Confirm `HKLM\SOFTWARE\FSLogix\Profiles` has `Enabled=1` and the correct UNC in `VHDLocations` (`AVDDEP-Validate.ps1`, Test 4). Set share permissions so **Users = Modify**. Verify the storage is joined to the identity source the hosts authenticate to.

**Symptom — logons are very slow.**
- **Cause:** Undersized/high-latency profile storage, cross-region profile I/O, or antivirus scanning the VHDX.
- **Fix:** Use **premium** Azure Files or the correct Azure NetApp Files service level, **co-located** with the hosts. Exclude the FSLogix VHDX path from AV real-time scanning per your vendor's AVD guidance.

**Symptom — "profile already in use" / users locked out of their profile.**
- **Cause:** A prior session did not release the container (host crash), or the same user is active on two hosts.
- **Fix:** Confirm breadth-first load balancing and single-session-per-user behavior; clear the stale lock on the container; ensure `DeleteLocalProfileWhenVHDShouldApply=1` so local remnants don't conflict.

## RBAC

**Symptom — operators can't manage the host pool, or hold far more rights than they should.**
- **Cause:** Missing Desktop Virtualization role, or broad standing Owner/Contributor at subscription scope.
- **Fix:** Assign **Desktop Virtualization Host Pool Contributor** / **Desktop Virtualization Contributor** scoped to the host pool/RG; remove broad Owner from operators and prefer **PIM** eligibility (`AVDDEP-Validate.ps1`, Test 5).

## Scaling & cost

**Symptom — idle hosts never power down; the bill keeps climbing.**
- **Cause:** No scaling plan assigned, plan disabled, or the AVD service principal lacks Power On/Off rights.
- **Fix:** Confirm `AVD – Scaling Plan – Pilot` is **enabled and assigned** to the host pool (`AVDDEP-Report.ps1`), and that the required custom role for power actions is granted (the portal prompts for it during plan creation).

**Symptom — users get disconnected during the day.**
- **Cause:** Ramp-down schedule set too aggressively / `rampDownForceLogoffUsers` enabled during business hours.
- **Fix:** Review the schedule times and thresholds in the scaling plan; keep force-logoff off for interactive audiences and set a sensible `rampDownWaitTimeMinutes`.

## Drain / patch

**Symptom — updating a host disconnected an active user mid-session.**
- **Cause:** A host was patched or replaced without draining first.
- **Fix:** Always **drain then replace**. Preview with `AVDDEP-Maintenance.ps1` (default `-WhatIf`) to see active session counts, drain with `-Apply` in a maintenance window, let sessions finish, then deploy replacement hosts from the new image version. Rollback = `-Undrain -Apply` or redeploy the prior image version.


---


# 7. Best Practices — Azure Virtual Desktop: Deployment, Golden Image & FSLogix

Keep the estate clean, repeatable, and cheap. These practices keep hosts identical, profiles fast, and the bill predictable.

## Golden image discipline
- **One source of truth.** Every session host comes from a **gallery image version** — never a hand-patched live host. If you edit a host directly, you have created a snowflake; rebuild it from the image instead.
- **Semantic versioning with intent.** Monthly Windows/app patch → minor bump (`1.0.0` → `1.1.0`); a from-scratch rebuild or major OS change → major bump (`2.0.0`). The version number should tell you what changed.
- **Keep a written build checklist** (Section 3, Step 3) so any engineer can reproduce the image. Better still, graduate the manual capture to **Azure VM Image Builder** so the definition rebuilds on a schedule — *verify VM Image Builder availability in your region/cloud.*
- **Replicate versions** to every region you run hosts in, and **retain the previous version** so you can roll a host pool back if a new image regresses.

## FSLogix and profile performance
- **Co-locate** the profile share with the session hosts (same region) — cross-region profile I/O is the top cause of slow logons.
- **Size for the real profile**, including Outlook cached mode and Teams cache; premium Azure Files or the right Azure NetApp Files service level, not standard storage.
- **Least-privilege share permissions** (users: Modify, admins: Full) so users create only their own container.
- **Exclude** the FSLogix VHDX path from on-host antivirus real-time scanning to avoid logon stalls (follow your AV vendor's AVD guidance).

## Deployment and change control
- **What-if before every apply.** The Bicep `what-if` (Testing T7) is your drift detector and your change record — a clean what-if means the estate equals the code.
- **Fresh registration tokens at deploy time.** Never reuse an old token; let the template mint one. Expired tokens are the classic "VM deployed but not a session host" failure.
- **Patch by replacement, not by hand.** Use the drain-and-patch workflow (Section 3, Step 10): drain old hosts, deploy new ones from the new image version, remove the old — no mid-session disconnects, and a clean rollback (redeploy the prior version).

## Cost control
- **Always attach a scaling plan.** Idle multi-session hosts running overnight are the biggest avoidable cost. Tune ramp-down aggressively for non-24×7 audiences.
- **Right-size the VM SKU** to real session density; measure with AVD Insights before scaling out.
- **Deallocate the imaging build VM** (auto-delete after capture) so build boxes never linger.

## Security and governance
- **Least-privilege RBAC** with the Desktop Virtualization roles; prefer **PIM** eligible activation over standing Owner.
- **Defer the business decisions** — which apps belong in the image, data-residency and records requirements, and production change approval are customer compliance/legal/ops calls, not technical defaults (Overview, "Scope — out").
- **Enable AVD Insights / Log Analytics** so health, logon time, and FSLogix errors are observable, not guessed.

## Where to go next (adjacent catalog areas)
- **Azure Virtual Desktop Remote Access (Windows & macOS Clients)** — the companion solution for publishing this estate to end users and validating client connectivity and Conditional Access. Deploy this build solution first, then that one.
- **Azure Security Baseline & Governance** — Azure Policy, RBAC, and guardrails to wrap the subscription your AVD estate lives in.
- **Windows 365 Cloud PC Deployment** — for personal, always-on Cloud PCs where per-user simplicity beats pooled multi-session economics; useful to compare against pooled AVD for parts of your population.
- **Azure Kubernetes Service Secure Baseline** — if the same team runs containerized workloads alongside AVD and wants the same IaC-and-baseline rigor.


---


# 8. Deliverables Summary — Azure Virtual Desktop: Deployment, Golden Image & FSLogix

Everything in this solution, at a glance. This is the *build and operate* side of AVD (imaging, IaC deployment, FSLogix storage, RBAC, scaling); end-user client access from Windows/macOS is the companion **AVD Remote Access** solution.

## Documentation (source/)
| Document | Purpose |
|---|---|
| `executive-summary.md` | What the solution is, the scope boundary vs. AVD Remote Access, what you get, and the effort. |
| `01-solution-overview.md` | How golden images, Compute Gallery versioning, image pipelines, IaC deployment, FSLogix, RBAC, drain/patch, and scaling work; the Assess → Configure → Pilot → Validate → Expand model; in/out of scope. |
| `02-requirements.md` | Build-specific prerequisites (license, Compute Gallery, build VM, FSLogix storage, Bicep tooling, networking, monitoring) with verify / implement-if-missing. References the shared `global-requirements-azure-solutions.md`. |
| `03-implementation.md` | Ordered, click-by-click build: resource groups + gallery, build VM, customize, capture version `1.0.0`, FSLogix storage, what-if-then-deploy pilot hosts by Bicep, RBAC, FSLogix config, scaling plan, drain/patch, then expand. Every object named `<Purpose> – <Scope> – <Stage>`. |
| `05-testing.md` | Eight pass/fail validation gates (image versioned, hosts trace to version, hosts healthy, FSLogix roams, RBAC least-privilege, scaling effective, what-if clean, drain safe) with exit criteria. |
| `06-troubleshooting.md` | Symptom → cause → fix for image/gallery, Bicep deployment, FSLogix, RBAC, scaling, and drain/patch failures. |
| `07-best-practices.md` | Golden-image discipline, FSLogix performance, change control, cost control, security, and where to go next in the catalog. |
| `08-deliverables-summary.md` | This inventory. |
| `global-requirements-azure-solutions.md` | Shared Azure category prerequisites (tenant, roles, licensing, connectivity, change control, rollback). |

## Automation (scripts/)
| Script | Purpose |
|---|---|
| `AVDDEP-Discovery.ps1` | **Read-only.** Inventories the Azure context, Compute Galleries/definitions/versions, host pools and session hosts (with image provenance), profile storage, and scaling plans — your pre-change baseline. |
| `AVDDEP-Validate.ps1` | **Read-only.** Runs the Testing gates: image provenance, host availability, FSLogix registry, least-privilege RBAC, and scaling-plan assignment, printing PASS/FAIL per check. |
| `AVDDEP-Report.ps1` | **Read-only.** Produces an inventory/cost-posture report — per-host size, drain state and active sessions, image versions in use, and scaling schedules (optional CSV export). |
| `AVDDEP-SessionHosts.bicep` | **Infrastructure-as-code.** Deploys the host pool, workspace + Desktop app group, N session hosts from a specified gallery image version, and a scaling plan — with a fresh registration token minted at deploy time. Always run `what-if` first. |
| `AVDDEP-Maintenance.ps1` | **Gated change (defaults to `-WhatIf` preview).** Drain-and-patch workflow: previews which hosts would be drained and their session counts; only `-Apply` sets/lifts drain mode, ahead of image-version replacement. |

## Package
Delivered as a **Complete Solution Package (PDF + Word + scripts)** — the eight guides above compiled to a Word document and a PDF, plus all five automation artifacts (three PowerShell scripts, one Bicep template, one gated PowerShell maintenance script) in a single ZIP — yours to keep and reuse on every AVD rollout.
