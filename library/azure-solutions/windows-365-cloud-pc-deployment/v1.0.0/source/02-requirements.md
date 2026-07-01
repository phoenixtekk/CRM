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
