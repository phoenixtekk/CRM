# Windows 365 Cloud PC Deployment & Management — Government (GCC High)

> **Version 1.0.0** · Category: Azure · Solution code: W365G

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Windows 365 Cloud PC Deployment & Management, Government / GCC High (Microsoft Intune)

Government agencies, public entities, and cleared contractors need a corporate Windows desktop that
lives in a US sovereign cloud — but standing up Windows 365 on a **GCC High** tenant is *not* the
Commercial process with a different sign-in. The sovereign admin and end-user URLs differ, and several
Windows 365 and Intune capabilities lag, are limited, or are absent versus Commercial. Deploy with
Commercial steps and it silently fails: empty-looking portals, unavailable options, and features you
designed around that don't exist in GCC High.

This is a complete, **deploy-it-today** package for standing up **Windows 365 Enterprise (Government)
Cloud PCs** on a **GCC High** tenant with the **government Microsoft Intune** instance, written for an
administrator with no prior Cloud PC or sovereign-cloud experience. It turns a pile of one-off Cloud
PCs into a repeatable, governed deployment on the correct `.us` portals — provisioning policies that
build desktops by group membership, a network connection you understand, a hardened image, and Intune
configuration, compliance, and security applied to Cloud PCs exactly as they are to laptops — with
every **Commercial-vs-GCC-High** difference called out so the government tenant is configured
correctly.

## What you get
- A plain-language **Solution Overview** of Windows 365 Enterprise (Government) — the
  provisioning-policy model, Azure (Government) Network Connection vs. the Microsoft-hosted network,
  gallery vs. custom images, Intune management — **plus an explicit "Commercial vs GCC High — what's
  different" section**.
- A **GCC High Parity Notes** reference: the full Commercial→`.us` portal/endpoint map and every
  cited Windows 365 / Intune feature-parity gap, with anything unconfirmed flagged "verify for GCC
  High."
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite (GCC High tenant,
  Government licensing including G3/G5, roles, sovereign portal access, `.us` endpoints through
  filtering).
- An **Implementation Guide** of precise, click-by-click steps in the required order using the **`.us`
  government portals**, with GCC-High-only caveats inline at the step where they matter.
- Five **PowerShell scripts** — discovery, validation, reporting, safe remediation, and a targeting
  group builder — all connecting to **Microsoft Graph US Gov** endpoints (`-Environment USGov`).
- **Testing** and **Troubleshooting** guides with pass/fail gates and GCC-High-specific gotchas.

## What this delivers
A **policy-driven Cloud PC service on GCC High**: a named provisioning policy that builds a dedicated
Windows desktop for every member of a target group, on a network of your choosing, from a known image,
secured by Conditional Access and managed by the same government Intune compliance and configuration
profiles as your physical endpoints — hosted in US government data centers and proven on a pilot
before you scale.

## The deployment model
**Assess → Configure → Pilot → Validate → Expand** — with a pilot gate before production.

## Outcome
Every eligible user with a dedicated, always-on Windows Cloud PC in the US sovereign cloud —
provisioned by policy, reached via `windows365.microsoft.us`, secured and managed in the government
Intune instance alongside physical devices — deployable by a single administrator, with the Commercial
pitfalls and GCC High parity gaps handled, and validated before fleet rollout.


---


# 1. Solution Overview — Windows 365 Cloud PC Deployment & Management (Government / GCC High)

## What Windows 365 Government is
Windows 365 is Microsoft's cloud service that gives each user a dedicated, always-on **Cloud PC** —
a personal Windows 10/11 desktop running in Microsoft's cloud and streamed to any device through a
browser or the Windows App. **Windows 365 Government** is the edition for US government agencies,
public entities, and contractors that qualify for the **US sovereign clouds (GCC and GCC High)**; the
Cloud PCs and underlying resources are hosted in **US government data centers** and pass the audits
required for those clouds. This solution is the **GCC High** edition — it uses **Windows 365
Enterprise (Government)** managed through **Microsoft Intune (government cloud)**: Cloud PCs are built
by a **provisioning policy**, join your tenant, and are governed by the same Intune compliance,
configuration, and app policies as your physical fleet. [What is Windows 365 Government, Microsoft
Learn.]

> Windows 365 Enterprise (Intune-managed, what this solution uses) is different from Windows 365
> Business (a lightweight, self-service SKU). Everything below assumes **Enterprise (Government)** on
> a **GCC High** tenant.

## Commercial vs GCC High — what's different
This is the section that keeps a government deployment from silently failing. **GCC High is not the
Commercial portal with a different sign-in** — the sovereign-cloud admin and end-user URLs differ,
and several Windows 365 / Intune capabilities lag or are absent. Two things to internalize:

1. **GCC ≠ GCC High.** In **GCC**, Cloud PCs run in Azure Government but the admin and end-user
   endpoints stay on the **commercial `.com`** domain. In **GCC High**, the whole experience is
   sovereign and moves to the **`.us`** domain. **This package is authored for GCC High.** [Set up
   tenants for Windows 365 Government, Microsoft Learn.]
2. **Use the `.us` portals and endpoints throughout** (full map in `gcc-high-parity-notes.md`):

   | Purpose | Commercial | **GCC High (use this)** |
   |---|---|---|
   | Sign-in (auth) | `login.microsoftonline.com` | `login.microsoftonline.us` |
   | Microsoft 365 admin | `admin.microsoft.com` | `admin.microsoft.us` |
   | Microsoft Intune admin | `intune.microsoft.com` | `intune.microsoft.us` |
   | Microsoft Entra admin | `entra.microsoft.com` | `entra.microsoft.us` |
   | Azure portal | `portal.azure.com` | `portal.azure.us` |
   | Windows 365 end-user | `windows365.microsoft.com` | `windows365.microsoft.us` |
   | Microsoft Graph | `graph.microsoft.com` | `graph.microsoft.us` (`-Environment USGov`) |

3. **Plan around the parity gaps.** In GCC High, do **not** design the deployment to depend on:
   the **Windows 365 Security baseline**, **GPU Cloud PCs**, **Windows 365 Boot / Switch / Reserve**,
   the **new Teams client / multimedia redirection**, a **W365 monitoring dashboard / system alerts**,
   **Cloud PC audit logs in Log Analytics**, **Copilot in Intune**, **cross-region DR**, or Intune's
   **Windows Autopilot, Remote Help, Windows Autopatch / update rings, or Windows Backup for
   Organizations** — none of these are available in GCC High today. Harden Cloud PCs with an ordinary
   Intune **Settings catalog** profile + compliance policy instead of the W365 baseline. Full cited
   list in `gcc-high-parity-notes.md`. [What is Windows 365 Government; Microsoft Intune Government
   Service overview, Microsoft Learn.]

Everything **else** — the provisioning-policy model, join types, network models, images, lifecycle,
and Intune management — **works the same as Commercial**. Only the portals, endpoints, and the gaps
above change.

## How it works (GCC High)
1. A **provisioning policy** defines how Cloud PCs are built — the join type, the network, the image,
   and the language/region — and is **assigned to a user group**. Every licensed member of that group
   is automatically provisioned a Cloud PC (one per license). All admin work is in the **government**
   Intune admin center at **`https://intune.microsoft.us`**.
2. The Cloud PC **joins your tenant** — either **Microsoft Entra join** (cloud-only) or **Microsoft
   Entra hybrid join** (line-of-sight to on-prem AD), per the policy.
3. Networking is one of two models: the **Microsoft-hosted network** (Microsoft owns the plumbing,
   zero Azure footprint — the simplest path, and the recommended GCC High starting point) or an
   **Azure Network Connection (ANC)** that routes Cloud PC traffic through *your* Azure Government
   virtual network (needed for hybrid join or on-prem reach). **Multi-Region Selection** (US
   Government region group) is available on the Microsoft-hosted network for resiliency. [Announcing
   Multi-Region Selection for Windows 365 in Government Community Cloud, Microsoft.]
4. The Cloud PC is built from an **image** — a Microsoft **gallery image** (Windows + Microsoft 365
   Apps, ready to go) or a **custom image** you maintain. In GCC High, **verify the current
   GCC-High-specific custom-image / ANC setup procedure** before building either — the published GCC
   Setup Tool / tenant-mapping flow is documented for GCC and Microsoft states it does **not** apply
   to GCC High. [Set up tenants for Windows 365 Government, Microsoft Learn.]
5. Once provisioned, the Cloud PC **enrolls in the government Intune instance automatically** and
   receives your compliance, configuration, and app-deployment policies — managed identically to a
   physical device.
6. Users connect from **`https://windows365.microsoft.us`**, the **Windows App**, or an RDP client;
   access is secured with **Conditional Access** in the government Entra admin center.

## What you can control
- **Who gets a Cloud PC** — by assigning the provisioning policy to a user group (license-gated).
- **Join type** — Microsoft Entra join or Microsoft Entra hybrid join.
- **Network** — Microsoft-hosted network (with US Government region group) or your own Azure
  Government Network Connection.
- **Image** — gallery or custom; updated centrally and re-used across policies.
- **Size / SKU** — vCPU / RAM / storage per license (e.g. 2vCPU/8GB/128GB), changeable via **resize**.
  (Note: **GPU SKUs are not available in GCC High.**)
- **Management** — full Intune compliance, configuration, and app deployment (build hardening from a
  Settings catalog profile, since the **W365 Security baseline is unavailable in GCC High**).
- **Lifecycle** — **reprovision** (rebuild to a clean image), **resize**, **restart**, and grace-period
  cleanup when a license is removed.

## Benefits
- **Sovereign desktop in minutes** — provisioned by policy on group membership; hosted in US
  government data centers meeting FedRAMP High / ITAR / DFARS expectations. [What is Windows 365
  Government, Microsoft.]
- **Managed like metal** — the same government Intune policies and reports cover Cloud PCs and
  physical devices.
- **Secure by default** — tenant-joined, Conditional Access-gated, compliance-enforced, on `.us`
  sovereign endpoints.
- **Reach anywhere** — any device with a browser or the Windows App becomes a corporate desktop via
  `windows365.microsoft.us`.
- **Predictable cost** — a fixed per-user license instead of hardware procurement and refresh.

## Limitations (be honest with buyers)
- Each Cloud PC needs a **Windows 365 Enterprise (Government) license** *plus* the user holding
  **Intune + Entra ID P1** (the eligibility prerequisites) — license math is per user, not per pool.
- **Hybrid join** and on-prem resource access require an **Azure Network Connection** in **Azure
  Government** (with associated Azure cost and network design) — the Microsoft-hosted network cannot
  reach on-prem.
- A Cloud PC is **dedicated and personal** (one user); Windows 365 is not a pooled/multi-session
  service (that is Azure Virtual Desktop — and AVD multi-session is itself not an Intune-managed
  feature in GCC High).
- **GCC High parity gaps** (see the section above and `gcc-high-parity-notes.md`) remove several
  Commercial conveniences — plan without them.
- **Custom images / ANC** must follow the **GCC-High-specific** procedure — **verify for GCC High**
  before relying on the GCC Setup Tool flow.

## The standard deployment model
> **Configure licensing + groups → (verify GCC-High ANC/image setup if used) → create the
> provisioning policy → assign to users → apply Intune management + security → validate on a pilot →
> expand to production.** Model: **Assess → Configure → Pilot → Validate → Expand**, with a pilot gate
> before production. This is the repeatable way to deliver Cloud PCs at scale on GCC High.


---


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


# 3. Implementation Guide — Windows 365 Cloud PC Deployment & Management (Government / GCC High)

Follow these steps **in order**. Most work is in the **government Microsoft Intune admin center**
(`https://intune.microsoft.us`); identity work is in the **government Microsoft Entra admin center**
(`https://entra.microsoft.us`); the optional Azure Network Connection and custom image use the
**Azure Government portal** (`https://portal.azure.us`); licensing is in the **government Microsoft
365 admin center** (`https://admin.microsoft.us`).

> **Sovereign portals only.** If any of these open a Commercial `.com` experience, stop — you are
> signed in to the wrong cloud. Sign in with your **`.us`** government credentials. The full
> Commercial→GCC-High URL map is in `gcc-high-parity-notes.md`.

> **Model:** Stand up a **Pilot** provisioning policy for a few users, validate the full experience,
> then create the **Production** policy and expand. The pilot gate comes before production.
>
> **Named objects (reuse verbatim):** groups `W365G – Users – Pilot` / `W365G – Users – Production`;
> network connection `W365G – ANC – Production`; image `W365G – Image – Win11-M365`; provisioning
> policies `W365G – Provisioning – Pilot` / `W365G – Provisioning – Production`; compliance policy
> `W365G – Compliance – Baseline`; Conditional Access policy `W365G – CA – CloudPC-Access`.

## Step 0 — Confirm you are on GCC High (not GCC)
1. Sign in at **`https://admin.microsoft.us`** and confirm the tenant resolves with your government
   (`.onmicrosoft.us`) identity.
2. Open **`https://intune.microsoft.us`** and confirm **Devices** loads.
3. If your admin/end-user endpoints are on the **`.com`** domain, you are on **GCC**, not GCC High —
   stop and use the Commercial edition of this solution instead. [Set up tenants for Windows 365
   Government, Microsoft Learn — GCC uses commercial endpoints; GCC High uses `.us`.]

## Step 1 — Create the user groups and confirm licensing
1. In the Entra admin center (`https://entra.microsoft.us`) go to **Identity → Groups → All groups →
   New group**.
2. **Group type:** Security. **Group name:** `W365G – Users – Pilot`. Add a few representative users
   as members. Click **Create**.
3. Repeat **New group** to create `W365G – Users – Production` (the broader population). Click **Create**.
4. In the Microsoft 365 admin center (`https://admin.microsoft.us`) go to **Billing → Licenses** and
   confirm each member of `W365G – Users – Pilot` holds **Windows 365 Enterprise (Government)** +
   **Intune** + **Entra ID P1** (typically via **M365 G3/G5 Government**). Assign any missing licenses
   (directly, or via group-based licensing on the group). Remember **GPU SKUs are unavailable in GCC
   High** — pick a CPU/RAM SKU.

## Step 2 — (Only if hybrid join / on-prem reach is needed) Create the Azure Government Network Connection
> Skip this entire step if you are deploying cloud-only Cloud PCs (Microsoft Entra join, no on-prem
> reach). In that case you will choose the **Microsoft-hosted network** in Step 4 and build nothing here.
>
> **GCC High caveat — verify first.** Microsoft's published **Windows 365 GCC Setup Tool /
> tenant-mapping** procedure (mapping the `.com` tenant to an Azure Government `.us` tenant and
> granting the Windows 365 service principal) is documented **for GCC** and Microsoft states it
> **does not apply to GCC High**. Before building an ANC in GCC High, **verify the current
> GCC-High-specific ANC procedure** for your tenant. [Set up tenants for Windows 365 Government,
> Microsoft Learn.]
1. In the **Azure Government portal** (`https://portal.azure.us`), confirm (or create) a **Virtual
   network** and **subnet** in the **US Government region** closest to your users, with outbound
   internet and — for hybrid join — line-of-sight to a domain controller. Note the subnet.
2. In the Intune admin center (`https://intune.microsoft.us`) go to **Devices → Windows 365 → Azure
   network connection → Create**.
3. Choose the join type:
   - **Microsoft Entra join** — pick the Azure Government subscription, resource group, virtual
     network, and subnet.
   - **Microsoft Entra hybrid join** — additionally supply the on-prem AD domain, an OU, and a
     domain-join account.
4. **Name:** `W365G – ANC – Production`. Click **Review + create**.
5. Wait for the connection's **health checks** to run and show **Checks passed** (DNS, domain join,
   endpoint reachability). Do not proceed until every check is green.

## Step 3 — (Only if using a custom image) Prepare and upload the image
> Skip this step to use a Microsoft **gallery image** (Windows 11 Enterprise + Microsoft 365 Apps),
> which needs no preparation. You will select the gallery image in Step 4. **This is the recommended
> GCC High fast path.**
>
> **GCC High caveat — verify first.** Custom-image support depends on the same GCC-High-specific
> setup as the ANC (above). **Verify the current GCC-High procedure** before capturing/uploading —
> the GCC Setup Tool flow does not apply to GCC High.
1. In the **Azure Government portal** (`https://portal.azure.us`), build a VM from a supported Windows
   image, install your standard apps and baseline, then **generalize** it
   (`sysprep /generalize /oobe /shutdown`).
2. **Capture** the VM to an **Azure Compute Gallery** image version (in Azure Government).
3. In the Intune admin center go to **Devices → Windows 365 → Custom images → Add**.
4. Select the captured image version. **Image name:** `W365G – Image – Win11-M365`. Click **Add**.
5. Wait for the status to read **Upload successful** before using it in a provisioning policy.

## Step 4 — Create the Pilot provisioning policy
1. In the Intune admin center (`https://intune.microsoft.us`) go to **Devices → Windows 365 →
   Provisioning policies → Create policy**.
2. **General → Name:** `W365G – Provisioning – Pilot`.
3. **Join type:** choose **Microsoft Entra join** (cloud-only) or **Microsoft Entra hybrid join**.
4. **Network:**
   - For cloud-only with no on-prem reach, select **Microsoft hosted network** and pick the **US
     Government region group** (or specific US Gov regions) for placement/resiliency. [Announcing
     Multi-Region Selection for Windows 365 in Government Community Cloud, Microsoft.]
   - For hybrid / on-prem reach, select **Azure network connection** and choose `W365G – ANC – Production`.
5. Click **Next** to **Image**. Select either a **Gallery image** (e.g. *Windows 11 Enterprise +
   Microsoft 365 Apps*) or **Custom image → `W365G – Image – Win11-M365`**.
6. Click **Next** to **Configuration**. Set the **language & region**; leave the rest at defaults for
   the pilot. (Do **not** expect the *Windows 365 Security baseline* option — it is unavailable in GCC
   High; hardening is applied in Step 5.) Click **Next**.
7. **Assignments → Add groups →** select `W365G – Users – Pilot`. Click **Next**.
8. **Review + create.** Provisioning begins automatically for every licensed member of the group; a
   Cloud PC appears under **Devices → Windows 365 → All Cloud PCs** within roughly 30–60 minutes.

## Step 5 — Apply Intune management and hardening to Cloud PCs
Cloud PCs enroll in the government Intune instance automatically; now apply management via the user
groups (so they cover both Cloud PCs and physical devices the same way). **Because the Windows 365
Security baseline is unavailable in GCC High, harden with a Settings catalog profile instead.**
1. **Compliance:** **Devices → Compliance → Policies → Create policy → Windows 10 and later.** Name it
   `W365G – Compliance – Baseline`, set your rules (e.g. BitLocker, minimum OS, Defender), and under
   **Assignments** add `W365G – Users – Pilot` (later `W365G – Users – Production`). **Create**.
2. **Configuration (hardening):** **Devices → Configuration → Create → New policy → Windows 10 and
   later → Settings catalog.** Apply your standard hardening/device settings (the replacement for the
   W365 baseline); assign to the same groups. **Create**.
3. **Apps:** **Apps → Windows → Add** the apps your users need and assign them to the Cloud PC user
   groups as **Required** so they install on the Cloud PCs.

## Step 6 — Verify the pilot Cloud PC experience
1. As a pilot user, browse to **`https://windows365.microsoft.us`** (or open the **Windows App**),
   confirm the Cloud PC tile appears, and **Connect**.
2. Confirm the desktop loads, sign-in succeeds, and the assigned apps are present.
3. In Intune, open **Devices → Windows 365 → All Cloud PCs** and confirm the device shows
   **Provisioned**. Run **`W365G-Validation.ps1`** to confirm health, and **`W365G-Report.ps1`** for
   the fleet/license view (both use Graph US Gov, `-Environment USGov`).

## Step 7 — Secure Cloud PC access with Conditional Access
1. In the Entra admin center (`https://entra.microsoft.us`) go to **Protection → Conditional Access →
   Policies → New policy**.
2. **Name:** `W365G – CA – CloudPC-Access`.
3. **Assignments → Users:** select `W365G – Users – Pilot` (add `W365G – Users – Production` later).
4. **Target resources → Cloud apps → Select apps:** add **Windows 365** and **Azure Virtual Desktop**
   (these cover the Cloud PC connection/gateway sign-in).
5. **Grant:** **Require multifactor authentication** (and, if desired, **Require device to be marked
   as compliant** for the connecting endpoint).
6. Set **Enable policy** to **On** and click **Create**. Verify a pilot user is prompted for MFA on
   the next Cloud PC sign-in via `windows365.microsoft.us`.

## Step 8 — Validate the pilot (gate)
1. Run **`W365G-Validation.ps1`** → confirms Cloud PCs are provisioned and healthy and that licensing
   prerequisites are met.
2. Run **`W365G-Report.ps1`** → confirms the Cloud PC inventory, status, sizes, and license utilization.
3. Complete the **Testing Guide**. Do not expand to production until every pilot gate passes.

## Step 9 — Expand to production
1. Create the production provisioning policy: repeat Step 4 with **Name:** `W365G – Provisioning –
   Production` and assign it to `W365G – Users – Production`. Use the same network and image as the
   validated pilot.
2. Add `W365G – Users – Production` to the compliance, configuration/hardening, app, and
   `W365G – CA – CloudPC-Access` assignments from Steps 5 and 7.
3. Add the production population to `W365G – Users – Production` (in waves if large). Cloud PCs
   provision automatically as users join the group.
4. Re-run **`W365G-Report.ps1`** each wave to confirm provisioning success and license headroom; use
   **`W365G-Remediation.ps1`** (defaults to -WhatIf) for any reprovision/resize fixes.

---
### Order of operations
`Confirm GCC High → user groups + licensing → (Azure-Gov ANC if needed, verify GCC-High procedure) →
(custom image if used, verify GCC-High procedure) → Pilot provisioning policy → Intune management +
Settings-catalog hardening → verify experience (windows365.microsoft.us) → Conditional Access →
validate (gate) → expand to production`


---


# 5. Testing Guide — Windows 365 Cloud PC Deployment & Management (Government / GCC High)

Run after the pilot provisioning policy applies (Implementation Step 6) and again before each
production wave. The pilot gate must pass before you expand. All admin steps use the **`.us`**
sovereign portals; all scripts connect to **Graph US Gov** (`-Environment USGov`).

## Test 1 — Provisioning succeeds
**Do:** Intune admin center (`https://intune.microsoft.us`) → **Devices → Windows 365 → All Cloud
PCs** (or open `W365G – Provisioning – Pilot` → device status). Also run **`W365G-Validation.ps1`**.
**Expected:** Each licensed member of `W365G – Users – Pilot` has a Cloud PC in status **Provisioned**
(no **Provisioning failed** / **In grace period**).

## Test 2 — User can connect (sovereign end-user portal)
**Do:** As a pilot user, sign in at **`https://windows365.microsoft.us`** (or the Windows App) and
**Connect** to the Cloud PC.
**Expected:** The Cloud PC tile appears, the desktop loads, and the user reaches the Windows sign-in
and desktop without error. (Confirm you used the **`.us`** end-user URL, not `.com`.)

## Test 3 — Image and apps are correct
**Do:** On the connected Cloud PC, confirm the OS build (`winver`) and that the expected baseline /
assigned apps are installed.
**Expected:** The desktop matches the selected gallery image or `W365G – Image – Win11-M365`, and the
apps assigned in Implementation Step 5 are present.

## Test 4 — Intune management + hardening applied (no W365 baseline dependency)
**Do:** Run **`W365G-Validation.ps1`**, and in Intune check the Cloud PC under **Devices → All
devices** → compliance + configuration state.
**Expected:** The Cloud PC is Intune-enrolled (government instance) and shows **Compliant**, with the
`W365G – Compliance – Baseline` and the **Settings catalog** hardening profile applied. (Confirm
hardening comes from the Settings catalog profile — the **W365 Security baseline is unavailable in
GCC High**.)

## Test 5 — Conditional Access enforced
**Do:** Sign in to the Cloud PC as a pilot user with `W365G – CA – CloudPC-Access` **On**.
**Expected:** The user is prompted for MFA (and, if configured, blocked from a non-compliant
connecting device). Entra **Sign-in logs** (`entra.microsoft.us`) show the policy applied to the
Windows 365 app.

## Test 6 — Network model behaves as designed
**Do:** From the Cloud PC, confirm internet access; for an ANC deployment, confirm reach to an on-prem
resource (file share / domain resource) and, for hybrid join, confirm the device is domain-joined.
**Expected:** Microsoft-hosted Cloud PCs reach the internet; ANC Cloud PCs additionally reach on-prem
targets, and hybrid-joined Cloud PCs are domain-joined. (ANC traffic routes through your **Azure
Government** vNet.)

## Test 7 — Lifecycle actions work
**Do:** On a pilot Cloud PC, exercise **Restart** and **Reprovision** from **Devices → Windows 365 →
All Cloud PCs** (device actions). Optionally test a **Resize** (CPU/RAM SKUs only — no GPU in GCC High).
**Expected:** Restart returns the Cloud PC healthy; Reprovision rebuilds it to the policy image and it
returns **Provisioned**; Resize changes the SKU without data loss to the OS configuration.

## Test 8 — Fleet and license report
**Do:** Run **`W365G-Report.ps1`**.
**Expected:** A clear per-Cloud-PC inventory (user, status, size/SKU, provisioning policy) plus
license utilization (assigned vs. available Windows 365 Government seats), with laggards/failures
flagged.

## Test 9 — Parity-gap sanity check (GCC High specific)
**Do:** Confirm the deployment does not depend on any GCC-High-unsupported feature — no reliance on
the W365 Security baseline, GPU SKUs, Windows 365 Boot/Switch/Reserve, the W365 monitoring dashboard,
Cloud PC audit logs in Log Analytics, or Intune Autopilot/Remote Help/Autopatch/update rings.
**Expected:** Every management dependency is satisfied by a feature confirmed available in GCC High
(see `gcc-high-parity-notes.md`). Anything not confirmed is flagged **verify for GCC High** and has a
tested fallback.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–6, 9 pass for `W365G – Users – Pilot`; users connect via `windows365.microsoft.us` and Cloud PCs are compliant and CA-protected |
| **Production pass** | Tests 1–5, 8, 9 pass for each `W365G – Users – Production` wave, with license headroom confirmed |


---


# 6. Troubleshooting Guide — Windows 365 Cloud PC Deployment & Management (Government / GCC High)

Use **`W365G-Discovery.ps1`** / **`W365G-Validation.ps1`** for tenant and Cloud PC state,
**`W365G-Report.ps1`** for the fleet/license view, and **`W365G-Remediation.ps1`** (defaults to
-WhatIf) for safe reprovision/resize fixes. All scripts connect to **Graph US Gov**
(`-Environment USGov`); all portal steps use the **`.us`** sovereign URLs.

## A. "The portal looks empty / broken / I can't see my tenant" (most common GCC High issue)
| Symptom | Cause | Remediation |
|---|---|---|
| Signed in but tenant/objects don't appear | Signed in to a **Commercial `.com`** portal against a GCC High tenant | Use the sovereign URLs: `admin.microsoft.us`, `intune.microsoft.us`, `entra.microsoft.us`, `portal.azure.us`, end-user `windows365.microsoft.us` |
| Script returns no data / auth errors | Graph connected to the **global** cloud, not US Gov | Connect with `-Environment USGov` (Graph root `graph.microsoft.us`); the scripts do this by default |
| "This applies to GCC, not GCC High" while following a Microsoft article | You're on a **GCC** (commercial-endpoint) procedure | Confirm your edition (Step 0 of Implementation). If endpoints are `.com`, you are on **GCC** — use the Commercial edition of this solution |
| MFA/redirect loops on Cloud PC sign-in | Auth pointed at `login.microsoftonline.com` | Ensure clients/policies use `login.microsoftonline.us` for the government tenant |

## B. Provisioning failed or stuck
| Symptom | Cause | Remediation |
|---|---|---|
| Cloud PC never appears for a user | User missing a required license | Confirm **Windows 365 Enterprise (Government) + Intune + Entra ID P1** on the user (`W365G-Validation.ps1`); assign the missing seat |
| "Provisioning failed" on an ANC policy | Azure (Government) Network Connection health check failing | Intune (`intune.microsoft.us`) → **Windows 365 → Azure network connection → `W365G – ANC – Production`**; fix the failed check (DNS, domain-join account, subnet endpoint reachability) and retry |
| ANC / custom image won't set up at all | GCC High requires a **different** setup than the GCC Setup Tool / tenant-mapping flow | The published GCC Setup Tool procedure **does not apply to GCC High** — **verify the current GCC-High-specific ANC/custom-image procedure** for your tenant before retrying [Set up tenants for Windows 365 Government, Microsoft Learn] |
| Provisioning hangs / errors with hybrid join | Domain join / OU / line-of-sight problem | Verify the domain-join account, OU path, and DC line-of-sight from the ANC subnet (in **Azure Government**); re-run the ANC health check |
| User not provisioned despite a license | User not in the assigned group | Confirm membership of `W365G – Users – Pilot` / `W365G – Users – Production`; the policy assignment is the trigger |
| No GPU SKU available when sizing | **GPU Cloud PCs are not available in GCC High** | Choose a CPU/RAM SKU; move GPU-dependent workloads off Cloud PC [What is Windows 365 Government, Microsoft Learn] |

## C. User cannot connect
- Confirm the user opens **`https://windows365.microsoft.us`** (the sovereign end-user portal) or the
  Windows App, and the Cloud PC shows **Provisioned**, not **In grace period** (which follows license
  removal).
- Check `W365G – CA – CloudPC-Access`: a misscoped Conditional Access policy (e.g. block from
  non-compliant device) can stop a legitimate connection. Review Entra **Sign-in logs**
  (`entra.microsoft.us`) for the Windows 365 app to see which policy applied.
- Confirm the connecting client can reach the **government** Windows 365 / RDP gateway endpoints (no
  proxy/firewall block of the `.us` sovereign endpoint set — the `.com` allow-list is not sufficient).

## D. Image / app issues
| Symptom | Cause | Remediation |
|---|---|---|
| Cloud PC missing baseline apps | Using a gallery image but apps not assigned | Assign the apps as **Required** to the Cloud PC user group (Implementation Step 5) |
| Custom-image Cloud PCs are out of date | `W365G – Image – Win11-M365` not re-captured | Patch + re-capture the source VM in **Azure Government**, re-upload the image, and reprovision affected Cloud PCs |
| Reprovision reverts user changes | Expected — reprovision rebuilds to the policy image | Store user data in OneDrive / redirected folders; reprovision is a clean rebuild by design (and your DR substitute — cross-region DR is unavailable in GCC High) |

## E. Compliance / hardening not applying
- Confirm the Cloud PC is enrolled in the **government** Intune instance (**Devices → All devices**)
  and the user is in the group the compliance/configuration profiles are assigned to.
- Remember hardening comes from your **Settings catalog** profile, not the Windows 365 Security
  baseline (which is **unavailable in GCC High**). If you were looking for the W365 baseline option,
  it will not appear — that is expected.
- Force a sync from the Cloud PC (**Settings → Accounts → Access work or school → Info → Sync**) and
  re-check after a policy cycle.

## F. "Feature X is missing" — GCC High parity gaps (expected, not a bug)
Several Commercial features simply do not exist in GCC High. If you can't find one of these, it's a
parity gap, not a misconfiguration — see `gcc-high-parity-notes.md` for the full cited list:
- **Windows 365:** Security baseline, GPU Cloud PCs, Windows 365 Boot (GCC only)/Switch/Reserve, new
  Teams client, multimedia redirection, W365 monitoring dashboard / system alerts / email
  notifications, Cloud PC audit logs in Log Analytics, Copilot in Intune, cross-region DR.
- **Intune:** Windows Autopilot, Remote Help, Windows Autopatch and Feature/Quality/Expedite/Driver
  update rings, Windows Backup for Organizations, Security Copilot, Device Health Attestation.

## G. Licensing / capacity
- "No licenses available" on assignment → buy more Windows 365 Enterprise (Government) seats of the
  chosen size; track utilization with `W365G-Report.ps1`.
- Wrong SKU for the workload → use **Resize** (Devices → Windows 365 → All Cloud PCs → device action;
  CPU/RAM SKUs only) rather than reprovisioning.

## H. Diagnostics quick reference
```powershell
# Tenant-side (Microsoft Graph US Gov — see scripts; all connect with -Environment USGov):
#   W365G-Discovery.ps1   readiness: licenses, ANC, images, provisioning policies
#   W365G-Validation.ps1  Cloud PC health + licensing prerequisites + parity notes
#   W365G-Report.ps1      fleet inventory + license utilization

# On a connected Cloud PC:
winver                                                    # OS build / image version
Get-ComputerInfo | Select-Object WindowsProductName, OsBuildNumber, WindowsVersion
dsregcmd /status                                          # join state (AzureAdJoined / DomainJoined)
```

## I. When to escalate
If the user holds all required licenses, is in the assigned group, the ANC health checks pass, you are
confirmed on GCC High with `.us` endpoints, and the Cloud PC still fails to provision or connect after
a reprovision, capture the provisioning error from **Devices → Windows 365 → All Cloud PCs** (device
detail) and the Entra sign-in log entry, and open a Microsoft support case for **Windows 365
Government**.

---
### Sources
- What is Windows 365 Government? — https://learn.microsoft.com/en-us/windows-365/enterprise/introduction-windows-365-government
- Set up tenants for Windows 365 Government — https://learn.microsoft.com/en-us/windows-365/enterprise/set-up-tenants-windows-365-gcc
- Microsoft Intune Government Service overview — https://learn.microsoft.com/en-us/intune/fundamentals/government-service
- Microsoft Graph national cloud deployments — https://learn.microsoft.com/en-us/graph/deployments


---


# 7. Best Practices — Windows 365 Cloud PC Deployment & Management (Government / GCC High)

- **Confirm GCC High before anything else.** GCC and GCC High are different clouds. If your admin and
  end-user endpoints are on `.com`, you are on **GCC** — use the Commercial edition. This package is
  for **GCC High**, where everything is on the sovereign `.us` domain. Signing in to a Commercial URL
  against a GCC High tenant is the most common "it looks broken" failure.
- **Use the `.us` portals and endpoints everywhere.** Admin: `intune.microsoft.us`,
  `entra.microsoft.us`, `admin.microsoft.us`, `portal.azure.us`. End-user: `windows365.microsoft.us`.
  Scripts: Graph `graph.microsoft.us` via `-Environment USGov`. Keep this map (in
  `gcc-high-parity-notes.md`) next to the runbook.
- **Design without the GCC High parity gaps.** Do **not** build the deployment on features that are
  unavailable in GCC High: the **Windows 365 Security baseline**, **GPU Cloud PCs**, **Windows 365
  Boot/Switch/Reserve**, the **W365 monitoring dashboard / system alerts**, **Cloud PC audit logs in
  Log Analytics**, **Copilot in Intune**, **cross-region DR**, or Intune **Autopilot / Remote Help /
  Autopatch / update rings / Windows Backup for Organizations**. Harden with a **Settings catalog**
  profile, monitor with `W365G-Report.ps1` + Intune device views, and keep user data in OneDrive so
  reprovision is your recovery path.
- **Pilot before production, always.** Provision `W365G – Provisioning – Pilot` to a few real users,
  validate the full sovereign experience (connect via `windows365.microsoft.us`, apps, compliance,
  Conditional Access), and only then create `W365G – Provisioning – Production`.
- **Start on the Microsoft-hosted network with the US Government region group.** It is the simplest,
  zero-Azure-footprint path and gives multi-region resiliency. Only build an **Azure Government**
  Network Connection (`W365G – ANC – Production`) when you genuinely need **hybrid join** or
  **on-prem reach** — and **verify the current GCC-High-specific ANC/custom-image procedure** first,
  because the published GCC Setup Tool / tenant-mapping flow does **not** apply to GCC High.
- **Gate on ANC health checks.** If you use an ANC, never assign it to a policy until every health
  check reads **Passed**; a failed check (DNS, domain join, endpoint reachability) means failed
  provisioning.
- **Target by group, not by user.** Assign provisioning, compliance, configuration, and Conditional
  Access to `W365G – Users – Pilot` / `W365G – Users – Production`. Adding a user provisions a Cloud
  PC; removing them starts grace-period cleanup. The group is the lifecycle switch.
- **Manage Cloud PCs like physical devices.** Reuse the same government Intune compliance,
  configuration, and app policies across both fleets so there is one standard, not two.
- **Right-size, then resize — CPU/RAM only.** Pick the smallest SKU that meets the workload and use
  **Resize** to move users up later. **GPU SKUs are unavailable in GCC High**, so plan GPU-dependent
  workloads elsewhere.
- **Secure the front door.** Require MFA (and ideally a compliant connecting device) via
  `W365G – CA – CloudPC-Access`. Cloud PCs are reachable from anywhere; Conditional Access is the
  control.
- **Keep one image standard.** If you use a custom image (`W365G – Image – Win11-M365`), patch and
  re-capture it on a schedule so reprovisioned Cloud PCs start current — otherwise prefer the
  always-updated gallery image and deliver apps/config through Intune.
- **Plan the license math per user.** Each Cloud PC needs Windows 365 Enterprise (Government) *and*
  the user holding Intune + Entra ID P1 (typically M365 G3/G5 Government). Track utilization with
  `W365G-Report.ps1` and keep seat headroom for new joiners.
- **Reprovision to recover, don't hand-fix.** For a broken Cloud PC, **Reprovision** rebuilds it to
  the policy image cleanly — and it is your DR substitute given cross-region DR is unavailable in GCC
  High. Keep user data in OneDrive / redirected folders.
- **Document the build and the sovereign specifics.** Record the chosen join type, network model,
  image, SKU, group targeting, **and the `.us` endpoints / parity-gap decisions** for audits and
  repeatability — this is what makes the GCC High deployment repeatable rather than a pile of one-offs.


---


# 8. Deliverables Summary — Windows 365 Cloud PC Deployment & Management (Government / GCC High)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case, sovereign context, and what's in the box |
| 1. Solution Overview | What Windows 365 Enterprise (Government) is, plus **"Commercial vs GCC High — what's different"** |
| GCC High Parity Notes | Full Commercial→`.us` portal/endpoint map and every cited Windows 365 / Intune parity gap |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing, `.us` portals, and the named objects |
| Global Requirements (Azure Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps on the government portals (groups, ANC, image, provisioning policy, Intune management + hardening, Conditional Access, pilot, expand) with GCC-High caveats inline |
| 5. Testing Guide | Validation procedures with pass/fail gates, including a GCC-High parity-gap check |
| 6. Troubleshooting Guide | Field issues and remediation, including sovereign-endpoint and parity-gap gotchas |
| 7. Best Practices | Field-proven recommendations for a GCC High deployment |

## PowerShell scripts (Microsoft Graph US Gov — `-Environment USGov`)
| Script | What it does |
|---|---|
| `W365G-Discovery.ps1` | Tenant readiness: Windows 365 Government / Intune / Entra ID P1 license counts, Azure Network Connections, custom images, and provisioning policies (read-only, Graph US Gov) |
| `W365G-Validation.ps1` | Confirms Cloud PCs are provisioned and healthy and that licensing prerequisites are met; flags GCC-High parity considerations (read-only, Graph US Gov) |
| `W365G-Report.ps1` | Fleet inventory (user, status, size/SKU, policy) plus Windows 365 Government license utilization (read-only, Graph US Gov) |
| `W365G-Remediation.ps1` | Safe reprovision / resize / restart helpers for unhealthy Cloud PCs — defaults to -WhatIf (Graph US Gov) |
| `W365G-Set-ScopeTargeting.ps1` | Creates/populates the `W365G – Users – Pilot` / `W365G – Users – Production` targeting groups — defaults to -WhatIf (Graph US Gov) |

## What the buyer receives
- This implementation guide as a **Word** document and **PDF**.
- All five **PowerShell scripts** (US Gov Graph endpoints) in a single ZIP.
- A repeatable process following the model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Every eligible user with a dedicated, always-on Windows Cloud PC in the US sovereign cloud —
provisioned by policy, secured by Conditional Access, managed in the government Intune instance
alongside physical devices, reached via `windows365.microsoft.us`, with the Commercial pitfalls and
GCC High parity gaps handled, and proven on a pilot before scale.
