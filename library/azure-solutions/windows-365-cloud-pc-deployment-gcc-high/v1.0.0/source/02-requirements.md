# 2. Requirements Guide — Windows 365 Cloud PC Deployment & Management (Government / GCC High)

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-azure-solutions.md`;
the full Commercial-vs-GCC-High map is in `gcc-high-parity-notes.md`.

> **Use the GCC High `.us` portals throughout.** Sign-in `login.microsoftonline.us`; M365 admin
> `admin.microsoft.us`; Intune admin `intune.microsoft.us`; Entra admin `entra.microsoft.us`; Azure
> `portal.azure.us`; end-user `windows365.microsoft.us`; Graph `graph.microsoft.us`
> (`-Environment USGov`). Signing in to a Commercial `.com` URL against a GCC High tenant is the #1
> cause of "my tenant looks empty / broken."

> Naming convention: every object created in this solution is named `<Purpose> – <Scope> – <Stage>`
> and reused verbatim throughout. The named objects this solution creates:
> - User group (pilot): `W365G – Users – Pilot`
> - User group (production): `W365G – Users – Production`
> - Azure Network Connection (only if hybrid/on-prem reach is needed): `W365G – ANC – Production`
> - Custom image (only if used): `W365G – Image – Win11-M365`
> - Provisioning policy (pilot): `W365G – Provisioning – Pilot`
> - Provisioning policy (production): `W365G – Provisioning – Production`
> - Compliance policy: `W365G – Compliance – Baseline`
> - Conditional Access policy: `W365G – CA – CloudPC-Access`

## 2.0 A GCC High tenant (not GCC, not Commercial)
**Description:** A Microsoft 365 **GCC High** tenant (domain typically ending `.onmicrosoft.us`),
provisioned through an authorized AOS-G reseller, with eligibility to use the US sovereign clouds.
**Why:** GCC High is a physically and logically separate sovereign instance; its portals, endpoints,
and feature set differ from both Commercial and GCC. Using the wrong edition's steps silently fails.
**Verify:** Sign in at **`https://admin.microsoft.us`** and confirm the tenant resolves; confirm the
Intune admin center loads at **`https://intune.microsoft.us`**. If your admin/end-user endpoints are
on `.com` (not `.us`), you are on **GCC**, not GCC High — use the Commercial edition of this solution.
**Implement:** Procure/confirm a GCC High tenant via an authorized government channel. Do not attempt
to migrate a Commercial tenant in place — there is no built-in Commercial↔government migration.
[Microsoft Intune Government Service overview, Microsoft Learn.]

## 2.1 Windows 365 Enterprise (Government) licensing
**Description:** A Windows 365 Enterprise (Government) license (sized to the workload, e.g.
2vCPU/8GB/128GB) for every user who will receive a Cloud PC. **GPU SKUs are not available in GCC
High** — size to CPU/RAM only.
**Why:** Each provisioned Cloud PC consumes exactly one Windows 365 Enterprise (Government) license;
no license, no Cloud PC.
**Verify:** Microsoft 365 admin center (`https://admin.microsoft.us`) → **Billing → Licenses** —
confirm enough Windows 365 Enterprise (Government) seats of the chosen size for the in-scope users.
Run **`W365G-Discovery.ps1`** to compare assigned vs. available (Graph US Gov).
**Implement:** Purchase Windows 365 Enterprise (Government) seats of the correct size; assign them to
the in-scope users (directly or via group-based licensing on the targeting groups). [What is Windows
365 Government, Microsoft Learn.]

## 2.2 Eligibility licensing (Intune + Entra ID P1, government)
**Description:** Each Windows 365 Enterprise (Government) user must also hold a Microsoft Intune
(government) license and a Microsoft Entra ID P1 (or higher) license — typically via **Microsoft 365
G3/G5 (Government)**.
**Why:** Provisioning and management run through the government Intune instance, and Conditional
Access / device-based controls require Entra ID P1. Prerequisites, not optional add-ons.
**Verify:** **Billing → Licenses** (`admin.microsoft.us`) — confirm Intune and Entra ID P1 on the same
users. Run **`W365G-Validation.ps1`**.
**Implement:** Assign the missing Intune / Entra ID P1 (G3/G5 Government) entitlements to the in-scope
users.

## 2.3 Microsoft Intune government instance (MDM authority)
**Description:** The government Intune instance configured as the MDM authority, with automatic
Windows enrollment available.
**Why:** Cloud PCs are provisioned and managed by the government Intune service; they enroll
automatically on build.
**Verify:** Intune admin center (`https://intune.microsoft.us`) → **Devices** loads, and
**Devices → Enrollment → Automatic Enrollment** shows an MDM user scope.
**Implement:** Set MDM user scope to **All** (or the in-scope group) under **Automatic Enrollment**.
Note the government Intune instance is a shared IL4/IL5 service. [Microsoft Intune Government Service
overview, Microsoft Learn.]

## 2.4 Entra ID user groups for targeting (government)
**Description:** Security groups that the provisioning policy is assigned to: `W365G – Users – Pilot`
(a few representative users) and `W365G – Users – Production` (the broader population).
**Why:** Windows 365 provisions a Cloud PC for every member of the group the policy targets; the group
is the on/off switch and underpins the pilot-then-expand model.
**Verify:** Entra admin center (`https://entra.microsoft.us`) → **Groups** — confirm both groups exist
with the exact names above. **`W365G-Set-ScopeTargeting.ps1`** can create/populate them (Graph US Gov).
**Implement:** Create the two security groups using the exact names; add pilot users first.

## 2.5 Networking model — Microsoft-hosted network OR Azure Government Network Connection
**Description:** Decide how Cloud PC traffic is routed. **Microsoft-hosted network** (Microsoft owns
the network; zero Azure footprint; supports the **US Government region group** / Multi-Region
Selection) is the default and the recommended GCC High starting point. An **Azure Network Connection
(ANC)** named `W365G – ANC – Production` routes traffic through your own **Azure Government** virtual
network and is **required** for **Microsoft Entra hybrid join** or reaching **on-premises** resources.
**Why:** The network model determines join type and what the Cloud PC can reach; hybrid join and
on-prem line-of-sight are impossible on the Microsoft-hosted network.
**Verify:** Decide based on need. If cloud-only (Entra join, no on-prem reach) → Microsoft-hosted,
nothing to build. If hybrid/on-prem → Intune admin center (`intune.microsoft.us`) → **Devices →
Windows 365 → Azure network connection** shows a healthy connection with all checks **Passed**.
**Implement (only if ANC is needed):** In the **Azure Government portal** (`portal.azure.us`) confirm a
virtual network + subnet with outbound internet and (for hybrid) line-of-sight to a domain
controller; then create the ANC `W365G – ANC – Production` and confirm health checks pass. **Verify
the current GCC-High-specific ANC/custom-image setup procedure first** — the published GCC Setup Tool
/ tenant-mapping flow is documented for **GCC** and does **not** apply to GCC High. See Implementation
Step 2. [Set up tenants for Windows 365 Government, Microsoft Learn.]

## 2.6 Device image — gallery OR custom
**Description:** The image Cloud PCs are built from. A Microsoft **gallery image** (Windows 11 +
Microsoft 365 Apps) needs no preparation and is the fast path. A **custom image** named
`W365G – Image – Win11-M365` is maintained by you.
**Why:** The image sets the starting state of every Cloud PC; a custom image bakes in your standard
apps/config so users are productive immediately.
**Verify:** Intune admin center (`intune.microsoft.us`) → **Devices → Windows 365 → Custom images**
lists your image as **Upload successful** (only if using custom). Otherwise no action — gallery images
are always present.
**Implement (only if using custom):** Follow the **GCC-High-specific** custom-image procedure
(**verify for GCC High** — the GCC Setup Tool flow does not apply), then upload as
`W365G – Image – Win11-M365`. See Implementation Step 3.

## 2.7 Cloud PC hardening — Settings catalog profile (NOT the W365 Security baseline)
**Description:** An Intune **Settings catalog** configuration profile plus a compliance policy
`W365G – Compliance – Baseline` that harden and gate the Cloud PCs.
**Why:** The **Windows 365 Security baseline is not yet supported in GCC High**, so you must harden
via an ordinary Settings catalog profile and enforce state via a compliance policy instead of relying
on the built-in baseline. [What is Windows 365 Government, Microsoft Learn.]
**Verify:** Intune → **Devices → Configuration** shows your Settings catalog profile assigned to the
Cloud PC user groups; **Devices → Compliance** shows `W365G – Compliance – Baseline` assigned.
**Implement:** Create the profile + compliance policy (Implementation Step 5) and assign to the
targeting groups.

## 2.8 Conditional Access for Cloud PC access (government)
**Description:** A Conditional Access policy named `W365G – CA – CloudPC-Access` requiring MFA (and,
optionally, compliant device) for the Windows 365 / Cloud PC sign-in apps.
**Why:** Cloud PCs are reachable from any device on the internet; Conditional Access keeps access to
authorized, verified users.
**Verify:** Entra admin center (`https://entra.microsoft.us`) → **Protection → Conditional Access** —
confirm a policy named `W365G – CA – CloudPC-Access` is **On** and scoped to the Windows 365 sign-in
apps.
**Implement:** Create the policy (see Implementation Step 7) targeting the **Windows 365** / **Azure
Virtual Desktop** cloud apps, requiring MFA, assigned to the Cloud PC user groups.

## 2.9 Administrative roles
**Description:** An operator account with **Intune Administrator** (and, for the ANC/image work,
**Owner/Contributor on the relevant Azure Government subscription/resource group**) rights, held in
the **government** tenant.
**Why:** Creating provisioning policies, network connections, and images requires sufficient privilege
in the sovereign tenant.
**Verify:** Entra (`entra.microsoft.us`) → **Roles & admins** for Intune Administrator; Azure
(`portal.azure.us`) → **Access control (IAM)** for Contributor. Run **`W365G-Validation.ps1`** to
confirm the operator can read the Cloud PC endpoints via Graph US Gov.
**Implement:** Assign the minimum roles; prefer eligible (PIM) activation where available.

## 2.10 Network egress to sovereign `.us` endpoints
**Description:** Firewall/proxy allowances for the **US government** service endpoints (`*.microsoft.us`,
`*.azure.us`, `*.office365.us`) and the Windows 365 / RDP gateway endpoints for the government cloud.
**Why:** All administration and Cloud PC connectivity depends on reaching the correct **sovereign**
endpoint set — the Commercial `*.microsoft.com` allowances are not sufficient.
**Verify:** Confirm reachability to the `.us` admin portals and to `windows365.microsoft.us`; confirm
the connecting clients can reach the government Windows 365 gateway endpoints. Consult the Microsoft
**US government endpoints** references for the current allow-list. [Microsoft 365 U.S. Government GCC
High endpoints; Network endpoints for US government deployments (Intune), Microsoft Learn.]
**Implement:** Open the correct **sovereign** endpoint set on firewall/proxy; scale bandwidth to the
Cloud PC population.

---
## Checklist
- [ ] GCC High tenant confirmed (`.us` portals resolve) — not GCC/Commercial
- [ ] Windows 365 Enterprise (Government) seats (correct size, **no GPU SKU**) — `W365G-Discovery.ps1`
- [ ] Intune + Entra ID P1 (G3/G5 Government) on the same users — `W365G-Validation.ps1`
- [ ] Government Intune MDM authority + automatic enrollment configured
- [ ] `W365G – Users – Pilot` and `W365G – Users – Production` groups created
- [ ] Network model chosen (Microsoft-hosted, or `W365G – ANC – Production` if hybrid/on-prem; ANC via GCC-High procedure — verify)
- [ ] Image chosen (gallery, or `W365G – Image – Win11-M365` via GCC-High procedure if custom)
- [ ] `W365G – Compliance – Baseline` + Settings catalog hardening profile (NOT W365 baseline)
- [ ] `W365G – CA – CloudPC-Access` Conditional Access policy in place
- [ ] Operator holds Intune Administrator (+ Azure Gov Contributor if ANC/image used)
- [ ] Sovereign `.us` endpoints allowed through firewall/proxy
