# Windows 365 Cloud PC Deployment & Management

> **Version 1.0.0** · Category: Azure Solutions · Solution code: W365

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Windows 365 Cloud PC Deployment & Management (Microsoft Intune)

Contractors, BYOD staff, and offshore teams need a corporate Windows desktop, but shipping and
managing a physical laptop for each one is slow, expensive, and hard to secure. **Windows 365**
gives every user a dedicated, always-on Windows desktop streamed from the cloud — joined to your
tenant, secured by the same Intune policies as your physical fleet, and reachable from any device.

This is a complete, **deploy-it-today** package for standing up Windows 365 Enterprise Cloud PCs
with Microsoft Intune, written for an administrator with no prior Cloud PC experience. It turns a
pile of one-off Cloud PCs into a repeatable, governed deployment: provisioning policies that build
desktops by group membership, a controlled image, a network connection you understand, and Intune
configuration, compliance, and security applied to Cloud PCs exactly as they are to laptops.

## What you get
- A plain-language **Solution Overview** of Windows 365 Enterprise — the provisioning-policy model,
  Azure Network Connection (ANC) vs. the Microsoft-hosted network, gallery vs. custom images, and
  how Cloud PCs are managed like physical devices in Intune.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite (licensing,
  Intune, Entra, networking, image, group design, Conditional Access).
- An **Implementation Guide** of precise, click-by-click steps in the required order — licensing and
  groups, the network connection, the image, the provisioning policy, user assignment, Intune
  management of Cloud PCs, securing access, then pilot, validate, and expand.
- Five **PowerShell scripts** for tenant-readiness discovery, Cloud PC health validation, a fleet and
  license-utilization report, safe remediation (reprovision/resize helpers), and a provisioning-target
  group builder.
- **Testing** and **Troubleshooting** guides for a confident rollout.

## What this delivers
A **policy-driven Cloud PC service**: a named provisioning policy that builds a dedicated Windows
desktop for every member of a target group, on a network connection of your choosing, from a known
image, secured by Conditional Access and managed by the same Intune compliance and configuration
profiles as your physical endpoints — proven on a pilot before you scale.

## The deployment model
**Assess → Configure → Pilot → Validate → Expand** — with a pilot gate before production.

## Outcome
Every eligible user with a dedicated, always-on Windows Cloud PC — provisioned by policy, secured and
managed in Intune alongside physical devices, reachable from anywhere — deployable by a single
administrator and validated before fleet rollout.


---


# 1. Solution Overview — Windows 365 Cloud PC Deployment & Management

## What Windows 365 is
Windows 365 is Microsoft's cloud service that gives each user a dedicated, always-on **Cloud PC** — a
personal Windows 10/11 desktop running in Microsoft's cloud and streamed to any device through a
browser or the Windows App. This solution uses **Windows 365 Enterprise**, which is managed through
**Microsoft Intune**: Cloud PCs are built by a **provisioning policy**, join your tenant, and are then
governed by the same Intune compliance, configuration, and app policies as your physical fleet.

> Windows 365 Enterprise (Intune-managed, what this solution uses) is different from Windows 365
> Business (a lightweight, self-service SKU capped at ~300 seats with no Intune-driven provisioning).
> Everything below assumes **Enterprise**.

## How it works
1. A **provisioning policy** defines how Cloud PCs are built — the join type, the network, the image,
   and the language/region — and is **assigned to a user group**. Every member of that group is
   automatically provisioned a Cloud PC (one per license).
2. The Cloud PC **joins your tenant** — either **Microsoft Entra join** (cloud-only) or **Microsoft
   Entra hybrid join** (line-of-sight to on-prem Active Directory), per the policy.
3. Networking is one of two models: the **Microsoft-hosted network** (Microsoft owns the plumbing,
   zero Azure footprint — the simplest path) or an **Azure Network Connection (ANC)** that routes
   Cloud PC traffic through *your* Azure virtual network (needed for hybrid join or on-prem reach).
4. The Cloud PC is built from an **image** — a Microsoft **gallery image** (Windows + Microsoft 365
   Apps, ready to go) or a **custom image** you capture in Azure with your baseline pre-installed.
5. Once provisioned, the Cloud PC **enrolls in Intune automatically** and receives your compliance,
   configuration, and app-deployment policies — managed identically to a physical device.
6. Users connect from **windows365.microsoft.com**, the **Windows App**, or an RDP client; access is
   secured with **Conditional Access**.

## What you can control
- **Who gets a Cloud PC** — by assigning the provisioning policy to a user group (license-gated).
- **Join type** — Microsoft Entra join or Microsoft Entra hybrid join.
- **Network** — Microsoft-hosted network or your own Azure Network Connection.
- **Image** — gallery or custom; updated centrally and re-used across policies.
- **Size / SKU** — vCPU / RAM / storage per license (e.g. 2vCPU/8GB/128GB), changeable via **resize**.
- **Management** — full Intune compliance, configuration, security baselines, and app deployment.
- **Lifecycle** — **reprovision** (rebuild to a clean image), **resize**, **restart**, and grace-period
  cleanup when a license is removed.

## Benefits
- **Desktop in minutes** — provisioned by policy on group membership; no laptop to ship or image.
- **Managed like metal** — the same Intune policies and reports cover Cloud PCs and physical devices.
- **Secure by default** — tenant-joined, Conditional Access-gated, compliance-enforced.
- **Reach anywhere** — any device with a browser or the Windows App becomes a corporate desktop.
- **Predictable cost** — a fixed per-user license instead of hardware procurement and refresh.

## Limitations (be honest with buyers)
- Each Cloud PC needs a **Windows 365 Enterprise license** *plus* the user holding **Intune + Entra
  ID P1** (the eligibility prerequisites) — license math is per user, not per device pool.
- **Hybrid join** and on-prem resource access require an **Azure Network Connection** (your Azure vNet,
  with the associated Azure cost and network design) — the Microsoft-hosted network cannot reach on-prem.
- A Cloud PC is **dedicated and personal** (one user); Windows 365 is not a pooled/multi-session
  service (that is Azure Virtual Desktop).
- **Custom images** are captured and stored in Azure and must be maintained (patched/re-captured) over time.
- GPU and very high-end workloads have limited SKU options; size to the workload.

## The standard deployment model
> **Configure licensing + groups → create the network connection → prepare the image → create the
> provisioning policy → assign to users → apply Intune management + security → validate on a pilot →
> expand to production.** Model: **Assess → Configure → Pilot → Validate → Expand**, with a pilot gate
> before production. This is the repeatable way to deliver Cloud PCs at scale.


---


# 2. Requirements Guide — Windows 365 Cloud PC Deployment & Management

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-azure-solutions.md`.

> Naming convention: every object created in this solution is named `<Purpose> – <Scope> – <Stage>`
> and reused verbatim throughout. The named objects this solution creates:
> - User group (pilot): `W365 – Users – Pilot`
> - User group (production): `W365 – Users – Production`
> - Azure Network Connection (only if hybrid/on-prem reach is needed): `W365 – ANC – Production`
> - Custom image (only if used): `W365 – Image – Win11-M365`
> - Provisioning policy (pilot): `W365 – Provisioning – Pilot`
> - Provisioning policy (production): `W365 – Provisioning – Production`
> - Conditional Access policy: `W365 – CA – CloudPC-Access`

## 2.1 Windows 365 Enterprise licensing
**Description:** A Windows 365 Enterprise license (sized to the workload, e.g. 2vCPU/8GB/128GB) for
every user who will receive a Cloud PC.
**Why:** Each provisioned Cloud PC consumes exactly one Windows 365 Enterprise license; no license,
no Cloud PC.
**Verify:** Microsoft 365 admin center (`https://admin.microsoft.com`) → **Billing → Licenses** —
confirm enough Windows 365 Enterprise seats of the chosen size for the in-scope users. Run
**`W365-Discovery.ps1`** to compare assigned vs. available.
**Implement:** Purchase Windows 365 Enterprise seats of the correct size; assign them to the in-scope
users (directly or via group-based licensing on `W365 – Users – Pilot` / `W365 – Users – Production`).

## 2.2 Eligibility licensing (Intune + Entra ID P1)
**Description:** Each Windows 365 Enterprise user must also hold a Microsoft Intune license and a
Microsoft Entra ID P1 (or higher) license.
**Why:** Windows 365 Enterprise provisioning and management run through Intune, and Conditional
Access / device-based controls require Entra ID P1. These are prerequisites, not optional add-ons.
**Verify:** **Billing → Licenses** — confirm Intune and Entra ID P1 (typically via M365 E3/E5,
Business Premium, or standalone) on the same users. Run **`W365-Validation.ps1`**.
**Implement:** Assign the missing Intune / Entra ID P1 entitlements to the in-scope users.

## 2.3 Microsoft Intune (MDM authority)
**Description:** Intune configured as the MDM authority, with automatic Windows enrollment available.
**Why:** Cloud PCs are provisioned and managed by Intune; they enroll automatically on build.
**Verify:** Microsoft Intune admin center (`https://intune.microsoft.com`) → **Devices** loads, and
**Devices → Enrollment → Automatic Enrollment** shows an MDM user scope.
**Implement:** Set MDM user scope to **All** (or the in-scope group) under **Automatic Enrollment**.

## 2.4 Entra ID user groups for targeting
**Description:** Security groups that the provisioning policy is assigned to: `W365 – Users – Pilot`
(a few representative users) and `W365 – Users – Production` (the broader population).
**Why:** Windows 365 provisions a Cloud PC for every member of the group the policy targets; the
group is the on/off switch for who gets a Cloud PC and underpins the pilot-then-expand model.
**Verify:** Entra admin center (`https://entra.microsoft.com`) → **Groups** — confirm both groups
exist with the exact names above. **`W365-Set-ProvisioningTargeting.ps1`** can create/populate them.
**Implement:** Create the two security groups using the exact names; add pilot users first.

## 2.5 Networking model — Microsoft-hosted network OR Azure Network Connection
**Description:** Decide how Cloud PC traffic is routed. **Microsoft-hosted network** (Microsoft owns
the network; zero Azure footprint) is the default and simplest. An **Azure Network Connection (ANC)**
named `W365 – ANC – Production` routes traffic through your own Azure virtual network and is **required**
for **Microsoft Entra hybrid join** or reaching **on-premises** resources.
**Why:** The network model determines join type and what the Cloud PC can reach; hybrid join and
on-prem line-of-sight are impossible on the Microsoft-hosted network.
**Verify:** Decide based on need. If cloud-only (Entra join, no on-prem reach) → Microsoft-hosted,
nothing to build. If hybrid/on-prem → Intune admin center → **Devices → Windows 365 → Azure network
connection** shows a healthy connection with all checks **Passed**.
**Implement (only if ANC is needed):** In the **Azure portal** create/confirm a virtual network +
subnet with outbound internet and (for hybrid) line-of-sight to a domain controller; then in Intune
create the ANC `W365 – ANC – Production` against that subnet and confirm all health checks pass. See
Implementation Step 2.

## 2.6 Device image — gallery OR custom
**Description:** The image Cloud PCs are built from. A Microsoft **gallery image** (Windows 11 +
Microsoft 365 Apps) needs no preparation. A **custom image** named `W365 – Image – Win11-M365`
(your baseline pre-installed) is captured in Azure and uploaded to Windows 365.
**Why:** The image sets the starting state of every Cloud PC; a custom image bakes in your standard
apps/config so users are productive immediately.
**Verify:** Intune admin center → **Devices → Windows 365 → Custom images** lists your image as
**Upload successful** (only if using custom). Otherwise no action — gallery images are always present.
**Implement (only if using custom):** Build and generalize a VM in Azure, capture it to an Azure
Compute Gallery, then upload it to Windows 365 as `W365 – Image – Win11-M365`. See Implementation Step 3.

## 2.7 Conditional Access for Cloud PC access
**Description:** A Conditional Access policy named `W365 – CA – CloudPC-Access` requiring MFA (and,
optionally, compliant device) for the Windows 365 / Cloud PC sign-in apps.
**Why:** Cloud PCs are reachable from any device on the internet; Conditional Access is the control
that keeps access to authorized, verified users.
**Verify:** Entra admin center → **Protection → Conditional Access** — confirm a policy named
`W365 – CA – CloudPC-Access` is **On** and scoped to the Windows 365 sign-in apps.
**Implement:** Create the policy (see Implementation Step 7) targeting the **Windows 365** /
**Azure Virtual Desktop** cloud apps, requiring MFA, assigned to the Cloud PC user groups.

## 2.8 Administrative roles
**Description:** An operator account with Intune administrator (and, for the ANC/image work, Azure
Contributor on the relevant subscription/resource group) rights.
**Why:** Creating provisioning policies, network connections, and images requires sufficient privilege.
**Verify:** Entra → **Roles & admins** for Intune Administrator; Azure → **Access control (IAM)** for
Contributor. Run **`W365-Validation.ps1`** to confirm the operator can read the Cloud PC endpoints.
**Implement:** Assign the minimum roles; prefer eligible (PIM) activation where available.

---
## Checklist
- [ ] Windows 365 Enterprise seats (correct size) for in-scope users — `W365-Discovery.ps1`
- [ ] Intune + Entra ID P1 on the same users — `W365-Validation.ps1`
- [ ] Intune MDM authority + automatic enrollment configured
- [ ] `W365 – Users – Pilot` and `W365 – Users – Production` groups created
- [ ] Network model chosen (Microsoft-hosted, or `W365 – ANC – Production` if hybrid/on-prem)
- [ ] Image chosen (gallery, or `W365 – Image – Win11-M365` if custom)
- [ ] `W365 – CA – CloudPC-Access` Conditional Access policy in place
- [ ] Operator holds Intune Administrator (+ Azure Contributor if ANC/image used)


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


# 3. Implementation Guide — Windows 365 Cloud PC Deployment & Management

Follow these steps **in order**. Most work is in the **Microsoft Intune admin center**
(`https://intune.microsoft.com`); identity work is in the **Microsoft Entra admin center**
(`https://entra.microsoft.com`); the optional Azure Network Connection and custom image use the
**Azure portal** (`https://portal.azure.com`).

> **Model:** Stand up a **Pilot** provisioning policy for a few users, validate the full experience,
> then create the **Production** policy and expand. The pilot gate comes before production.
>
> **Named objects (reuse verbatim):** groups `W365 – Users – Pilot` / `W365 – Users – Production`;
> network connection `W365 – ANC – Production`; image `W365 – Image – Win11-M365`; provisioning
> policies `W365 – Provisioning – Pilot` / `W365 – Provisioning – Production`; Conditional Access
> policy `W365 – CA – CloudPC-Access`.

## Step 1 — Create the user groups and confirm licensing
1. In Entra admin center go to **Identity → Groups → All groups → New group**.
2. **Group type:** Security. **Group name:** `W365 – Users – Pilot`. Add a few representative users as
   members. Click **Create**.
3. Repeat **New group** to create `W365 – Users – Production` (the broader population). Click **Create**.
4. In the Microsoft 365 admin center go to **Billing → Licenses** and confirm each member of
   `W365 – Users – Pilot` holds **Windows 365 Enterprise** + **Intune** + **Entra ID P1**. Assign any
   missing licenses (directly, or via group-based licensing on the group).

## Step 2 — (Only if hybrid join / on-prem reach is needed) Create the Azure Network Connection
> Skip this entire step if you are deploying cloud-only Cloud PCs (Microsoft Entra join, no on-prem
> reach). In that case you will choose the **Microsoft-hosted network** in Step 4 and build nothing here.
1. In the **Azure portal**, confirm (or create) a **Virtual network** and **subnet** in the region
   closest to your users, with outbound internet and — for hybrid join — line-of-sight to a domain
   controller. Note the subnet.
2. In the Intune admin center go to **Devices → Windows 365 → Azure network connection → Create**.
3. Choose the join type:
   - **Microsoft Entra join** — pick the subscription, resource group, virtual network, and subnet.
   - **Microsoft Entra hybrid join** — additionally supply the on-prem AD domain, an OU, and a
     domain-join account.
4. **Name:** `W365 – ANC – Production`. Click **Review + create**.
5. Wait for the connection's **health checks** to run and show **Checks passed** (DNS, domain join,
   endpoint reachability). Do not proceed until every check is green.

## Step 3 — (Only if using a custom image) Prepare and upload the image
> Skip this step to use a Microsoft **gallery image** (Windows 11 Enterprise + Microsoft 365 Apps),
> which needs no preparation. You will select the gallery image in Step 4.
1. In the **Azure portal**, build a VM from a supported Windows image, install your standard apps and
   baseline configuration, then **generalize** it (run `sysprep /generalize /oobe /shutdown`).
2. **Capture** the VM to an **Azure Compute Gallery** image version.
3. In the Intune admin center go to **Devices → Windows 365 → Custom images → Add**.
4. Select the captured image version. **Image name:** `W365 – Image – Win11-M365`. Click **Add**.
5. Wait for the status to read **Upload successful** before using it in a provisioning policy.

## Step 4 — Create the Pilot provisioning policy
1. In the Intune admin center go to **Devices → Windows 365 → Provisioning policies → Create policy**.
2. **General → Name:** `W365 – Provisioning – Pilot`.
3. **Join type:** choose **Microsoft Entra join** (cloud-only) or **Microsoft Entra hybrid join**.
4. **Network:**
   - For cloud-only with no on-prem reach, select **Microsoft hosted network** and pick the **region**
     (or "Automatic") and a geography.
   - For hybrid / on-prem reach, select **Azure network connection** and choose `W365 – ANC – Production`.
5. Click **Next** to **Image**. Select either a **Gallery image** (e.g. *Windows 11 Enterprise + Microsoft
   365 Apps*) or **Custom image → `W365 – Image – Win11-M365`**.
6. Click **Next** to **Configuration**. Set the **language & region**; leave the rest at defaults for
   the pilot. Click **Next**.
7. **Assignments → Add groups →** select `W365 – Users – Pilot`. Click **Next**.
8. **Review + create.** Provisioning begins automatically for every licensed member of the group;
   a Cloud PC appears under **Devices → Windows 365 → All Cloud PCs** within roughly 30–60 minutes.

## Step 5 — Apply Intune management to Cloud PCs
Cloud PCs enroll in Intune automatically; now apply your management policies to them via the user
groups (so they cover both Cloud PCs and physical devices the same way).
1. **Compliance:** **Devices → Compliance → Policies → Create policy → Windows 10 and later.** Name it
   `W365 – Compliance – Baseline`, set your rules (e.g. BitLocker, minimum OS, Defender), and under
   **Assignments** add `W365 – Users – Pilot` (later `W365 – Users – Production`). **Create**.
2. **Configuration:** **Devices → Configuration → Create → New policy → Windows 10 and later → Settings
   catalog.** Apply your standard device settings; assign to the same groups. **Create**.
3. **Apps:** **Apps → Windows → Add** the apps your users need and assign them to the Cloud PC user
   groups as **Required** so they install on the Cloud PCs.

## Step 6 — Verify the pilot Cloud PC experience
1. As a pilot user, browse to **`https://windows365.microsoft.com`** (or open the **Windows App**),
   confirm the Cloud PC tile appears, and **Connect**.
2. Confirm the desktop loads, sign-in succeeds, and the assigned apps are present.
3. In Intune, open **Devices → Windows 365 → All Cloud PCs** and confirm the device shows
   **Provisioned**. Run **`W365-Validation.ps1`** to confirm health, and **`W365-Report.ps1`** for the
   fleet/license view.

## Step 7 — Secure Cloud PC access with Conditional Access
1. In Entra admin center go to **Protection → Conditional Access → Policies → New policy**.
2. **Name:** `W365 – CA – CloudPC-Access`.
3. **Assignments → Users:** select `W365 – Users – Pilot` (add `W365 – Users – Production` later).
4. **Target resources → Cloud apps → Select apps:** add **Windows 365** and **Azure Virtual Desktop**
   (these cover the Cloud PC connection/gateway sign-in).
5. **Grant:** **Require multifactor authentication** (and, if desired, **Require device to be marked as
   compliant** for the connecting endpoint). 
6. Set **Enable policy** to **On** and click **Create**. Verify a pilot user is prompted for MFA on the
   next Cloud PC sign-in.

## Step 8 — Validate the pilot (gate)
1. Run **`W365-Validation.ps1`** → confirms Cloud PCs are provisioned and healthy and that licensing
   prerequisites are met.
2. Run **`W365-Report.ps1`** → confirms the Cloud PC inventory, status, sizes, and license utilization.
3. Complete the **Testing Guide**. Do not expand to production until every pilot gate passes.

## Step 9 — Expand to production
1. Create the production provisioning policy: repeat Step 4 with **Name:** `W365 – Provisioning –
   Production` and assign it to `W365 – Users – Production`. Use the same network and image as the
   validated pilot.
2. Add `W365 – Users – Production` to the compliance, configuration, app, and `W365 – CA – CloudPC-Access`
   assignments from Steps 5 and 7.
3. Add the production population to `W365 – Users – Production` (in waves if large). Cloud PCs provision
   automatically as users join the group.
4. Re-run **`W365-Report.ps1`** each wave to confirm provisioning success and license headroom; use
   **`W365-Remediation.ps1`** (defaults to -WhatIf) for any reprovision/resize fixes.

---
### Order of operations
`User groups + licensing → (ANC if needed) → (custom image if used) → Pilot provisioning policy →
Intune management → verify experience → Conditional Access → validate (gate) → expand to production`


---


# 5. Testing Guide — Windows 365 Cloud PC Deployment & Management

Run after the pilot provisioning policy applies (Implementation Step 6) and again before each
production wave. The pilot gate must pass before you expand.

## Test 1 — Provisioning succeeds
**Do:** Intune admin center → **Devices → Windows 365 → All Cloud PCs** (or open
`W365 – Provisioning – Pilot` → device status). Also run **`W365-Validation.ps1`**.
**Expected:** Each licensed member of `W365 – Users – Pilot` has a Cloud PC in status **Provisioned**
(no **Provisioning failed** / **In grace period**).

## Test 2 — User can connect
**Do:** As a pilot user, sign in at **`https://windows365.microsoft.com`** (or the Windows App) and
**Connect** to the Cloud PC.
**Expected:** The Cloud PC tile appears, the desktop loads, and the user reaches the Windows sign-in
and desktop without error.

## Test 3 — Image and apps are correct
**Do:** On the connected Cloud PC, confirm the OS build (`winver`) and that the expected baseline /
assigned apps are installed.
**Expected:** The desktop matches the selected gallery image or `W365 – Image – Win11-M365`, and the
apps assigned in Implementation Step 5 are present.

## Test 4 — Intune management applied
**Do:** Run **`W365-Validation.ps1`**, and in Intune check the Cloud PC under **Devices → All devices**
→ compliance + configuration state.
**Expected:** The Cloud PC is Intune-enrolled and shows **Compliant**, with the `W365 – Compliance –
Baseline` and configuration profiles applied.

## Test 5 — Conditional Access enforced
**Do:** Sign in to the Cloud PC as a pilot user with `W365 – CA – CloudPC-Access` **On**.
**Expected:** The user is prompted for MFA (and, if configured, blocked from a non-compliant connecting
device). Entra **Sign-in logs** show the policy applied to the Windows 365 app.

## Test 6 — Network model behaves as designed
**Do:** From the Cloud PC, confirm internet access; for an ANC deployment, confirm reach to an on-prem
resource (file share / domain resource) and, for hybrid join, confirm the device is domain-joined.
**Expected:** Microsoft-hosted Cloud PCs reach the internet; ANC Cloud PCs additionally reach on-prem
targets, and hybrid-joined Cloud PCs are domain-joined.

## Test 7 — Lifecycle actions work
**Do:** On a pilot Cloud PC, exercise **Restart** and **Reprovision** from **Devices → Windows 365 →
All Cloud PCs** (device actions). Optionally test a **Resize**.
**Expected:** Restart returns the Cloud PC healthy; Reprovision rebuilds it to the policy image and it
returns **Provisioned**; Resize changes the SKU without data loss to the OS configuration.

## Test 8 — Fleet and license report
**Do:** Run **`W365-Report.ps1`**.
**Expected:** A clear per-Cloud-PC inventory (user, status, size/SKU, provisioning policy) plus
license utilization (assigned vs. available Windows 365 seats), with laggards/failures flagged.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–6 pass for `W365 – Users – Pilot`; users connect and Cloud PCs are compliant and CA-protected |
| **Production pass** | Tests 1–5, 8 pass for each `W365 – Users – Production` wave, with license headroom confirmed |


---


# 6. Troubleshooting Guide — Windows 365 Cloud PC Deployment & Management

Use **`W365-Discovery.ps1`** / **`W365-Validation.ps1`** for tenant and Cloud PC state,
**`W365-Report.ps1`** for the fleet/license view, and **`W365-Remediation.ps1`** (defaults to
-WhatIf) for safe reprovision/resize fixes.

## A. Provisioning failed or stuck
| Symptom | Cause | Remediation |
|---|---|---|
| Cloud PC never appears for a user | User missing a required license | Confirm **Windows 365 Enterprise + Intune + Entra ID P1** on the user (`W365-Validation.ps1`); assign the missing seat |
| "Provisioning failed" on an ANC policy | Azure Network Connection health check failing | Intune → **Windows 365 → Azure network connection → `W365 – ANC – Production`**; fix the failed check (DNS, domain-join account, subnet endpoint reachability) and retry |
| Provisioning hangs / errors with hybrid join | Domain join / OU / line-of-sight problem | Verify the domain-join account, OU path, and DC line-of-sight from the ANC subnet; re-run the ANC health check |
| User not provisioned despite a license | User not in the assigned group | Confirm membership of `W365 – Users – Pilot` / `W365 – Users – Production`; the policy assignment is the trigger |

## B. User cannot connect
- Confirm the user opens **`https://windows365.microsoft.com`** (or the Windows App) and the Cloud PC
  shows **Provisioned**, not **In grace period** (which follows license removal).
- Check `W365 – CA – CloudPC-Access`: a misscoped Conditional Access policy (e.g. block from
  non-compliant device) can stop a legitimate connection. Review Entra **Sign-in logs** for the
  Windows 365 app to see which policy applied.
- Confirm the connecting client can reach the Cloud PC gateway endpoints (no proxy/firewall block of
  the Windows 365 / RDP gateway URLs).

## C. Image / app issues
| Symptom | Cause | Remediation |
|---|---|---|
| Cloud PC missing baseline apps | Using a gallery image but apps not assigned | Assign the apps as **Required** to the Cloud PC user group (Implementation Step 5) |
| Custom-image Cloud PCs are out of date | `W365 – Image – Win11-M365` not re-captured | Patch + re-capture the source VM, re-upload the image, and reprovision affected Cloud PCs |
| Reprovision reverts user changes | Expected — reprovision rebuilds to the policy image | Store user data in OneDrive / redirected folders; reprovision is a clean rebuild by design |

## D. Compliance / management not applying
- Confirm the Cloud PC is Intune-enrolled (**Devices → All devices**) and the user is in the group the
  compliance/configuration profiles are assigned to.
- Force a sync from the Cloud PC (**Settings → Accounts → Access work or school → Info → Sync**) and
  re-check after a policy cycle.

## E. Licensing / capacity
- "No licenses available" on assignment → buy more Windows 365 Enterprise seats of the chosen size;
  track utilization with `W365-Report.ps1`.
- Wrong SKU for the workload → use **Resize** (Devices → Windows 365 → All Cloud PCs → device action)
  rather than reprovisioning.

## F. Diagnostics quick reference
```powershell
# Tenant-side (Microsoft Graph — see scripts):
#   W365-Discovery.ps1   readiness: licenses, ANC, images, provisioning policies
#   W365-Validation.ps1  Cloud PC health + licensing prerequisites
#   W365-Report.ps1      fleet inventory + license utilization

# On a connected Cloud PC:
winver                                                    # OS build / image version
Get-ComputerInfo | Select WindowsProductName, OsBuildNumber, WindowsVersion
dsregcmd /status                                          # join state (AzureAdJoined / DomainJoined)
```

## G. When to escalate
If the user holds all required licenses, is in the assigned group, the ANC health checks pass, and the
Cloud PC still fails to provision or connect after a reprovision, capture the provisioning error from
**Devices → Windows 365 → All Cloud PCs** (device detail) and the Entra sign-in log entry, and open a
Microsoft support case for Windows 365.


---


# 7. Best Practices — Windows 365 Cloud PC Deployment & Management

- **Pilot before production, always.** Provision `W365 – Provisioning – Pilot` to a few real users,
  validate the full experience (connect, apps, compliance, Conditional Access), and only then create
  `W365 – Provisioning – Production`. The pilot catches image, network, and licensing problems before
  they hit the fleet.
- **Start on the Microsoft-hosted network.** It is the simplest, zero-Azure-footprint path. Only build
  an Azure Network Connection (`W365 – ANC – Production`) when you genuinely need **hybrid join** or
  **on-prem resource access** — it adds Azure cost and network design.
- **Gate on ANC health checks.** If you use an ANC, never assign it to a policy until every health check
  reads **Passed**; a failed check (DNS, domain join, endpoint reachability) means failed provisioning.
- **Target by group, not by user.** Assign provisioning, compliance, configuration, and Conditional
  Access to `W365 – Users – Pilot` / `W365 – Users – Production`. Adding a user to the group provisions
  a Cloud PC; removing them starts the grace-period cleanup. The group is the lifecycle switch.
- **Manage Cloud PCs like physical devices.** Reuse the same Intune compliance, configuration, and app
  policies across both fleets so there is one standard, not two.
- **Right-size, then resize.** Pick the smallest SKU that meets the workload and use **Resize** to move
  users up later — over-provisioning wastes license spend.
- **Secure the front door.** Require MFA (and ideally a compliant connecting device) via
  `W365 – CA – CloudPC-Access`. Cloud PCs are reachable from anywhere; Conditional Access is the control.
- **Keep one image standard.** If you use a custom image (`W365 – Image – Win11-M365`), patch and
  re-capture it on a schedule so reprovisioned Cloud PCs start current — otherwise prefer the
  always-updated gallery image and deliver apps/config through Intune.
- **Plan the license math per user.** Each Cloud PC needs Windows 365 Enterprise *and* the user holding
  Intune + Entra ID P1. Track utilization with `W365-Report.ps1` and keep seat headroom for new joiners.
- **Reprovision to recover, don't hand-fix.** For a broken Cloud PC, **Reprovision** rebuilds it to the
  policy image cleanly — faster and more consistent than manual repair.
- **Document the build.** Record the chosen join type, network model, image, SKU, and group targeting
  for audits and repeatability — this is what makes the deployment the repeatable way rather than a
  pile of one-offs.


---


# 8. Deliverables Summary — Windows 365 Cloud PC Deployment & Management

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What Windows 365 Enterprise is — provisioning policies, network models, images, Intune management, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing and the named objects |
| Global Requirements (Azure Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps (groups, ANC, image, provisioning policy, Intune management, Conditional Access, pilot, expand) |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `W365-Discovery.ps1` | Tenant readiness: Windows 365 / Intune / Entra ID P1 license counts, Azure Network Connections, custom images, and provisioning policies (read-only, Graph) |
| `W365-Validation.ps1` | Confirms Cloud PCs are provisioned and healthy and that licensing prerequisites are met (read-only, Graph) |
| `W365-Report.ps1` | Fleet inventory (user, status, size/SKU, policy) plus Windows 365 license utilization (read-only, Graph) |
| `W365-Remediation.ps1` | Safe reprovision / resize / restart helpers for unhealthy Cloud PCs — defaults to -WhatIf |
| `W365-Set-ProvisioningTargeting.ps1` | Creates/populates the `W365 – Users – Pilot` / `W365 – Users – Production` targeting groups (Graph) |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Every eligible user with a dedicated, always-on Windows Cloud PC — provisioned by policy, secured by
Conditional Access, managed in Intune alongside physical devices, and proven on a pilot before scale.
