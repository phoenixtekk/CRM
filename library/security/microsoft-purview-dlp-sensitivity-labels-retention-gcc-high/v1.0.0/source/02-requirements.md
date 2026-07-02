# Requirements — Purview DLP, Labels & Retention (Government / GCC High)

Confirm every prerequisite below **before** you configure anything. This edition assumes a **GCC
High** tenant throughout — the portals and endpoints are the US sovereign-cloud hosts, not the
Commercial ones. Category-level prerequisites (Entra tenant, admin roles, pilot group, network
access) are in `global-requirements-security.md`; the items here are **Purview- and GCC-High-specific**.

Each requirement is written as **Description · Why · Verify · Implement if missing.**

---

## R1. A Microsoft 365 Government – GCC High tenant

**Description:** An active **Microsoft 365 Government – GCC High** tenant (US sovereign cloud), not a
Commercial or GCC (moderate) tenant.
**Why:** GCC High uses different sovereign endpoints and has a different Purview feature-parity
profile. Commercial steps and URLs will not work, and features you plan for may not exist here.
**Verify:** Sign in at **`https://login.microsoftonline.us`** and open **`https://portal.office365.us`**.
In the Microsoft 365 admin center, the environment/branding indicates a US Government (GCC High)
tenant. The Purview portal loads at **`https://compliance.microsoft.us`** (or `purview.microsoft.us`),
**not** `.com`.
**Implement if missing:** GCC High requires eligibility validation and onboarding through Microsoft /
an authorized Gov reseller — you cannot self-provision it like Commercial. See Microsoft Learn *Plan
for Microsoft Purview — GCC High deployments*, Steps 1–2. This is a procurement action, not a portal
click.

## R2. Government Purview licensing (G3 / G5 / G5 Compliance)

**Description:** Purview information-protection, DLP, and retention licensing via **Microsoft 365
Government G3/G5**, **G5 Compliance**, or **G5 Information Protection & Governance** add-ons — the
**Gov** SKUs, not Commercial E3/E5.
**Why:** Feature access follows the same E3-vs-E5 split as Commercial (auto-labeling, records
management, Adaptive Protection are G5/E5-class), **on top of** GCC High parity gaps. Missing G5
means missing auto-labeling and records management entirely.
**Verify:** `portal.office365.us` → **Billing → Licenses**; confirm **Microsoft 365 G3/G5** and any
**G5 Compliance** / **Information Protection & Governance** SKUs. Cross-check the feature you need
against the *Microsoft Purview service description*.
**Implement if missing:** Acquire the appropriate Gov SKU / add-on through your Gov licensing channel
and assign it to the admin and pilot users. (See `gcc-high-parity-notes.md` §6.)

## R3. Purview administrative roles

**Description:** Role-group membership sufficient to author labels, DLP, and retention — **Compliance
Administrator** (or **Compliance Data Administrator**) plus **Information Protection Admin** /
**Information Protection** role group; **Records Management** for records; **Organization Management**
for role assignment.
**Why:** Creating and publishing labels, DLP policies, and retention/records policies requires these
Purview role groups. Global Administrator works but is over-privileged for day-to-day authoring.
**Verify:** `compliance.microsoft.us` → **Settings → Roles & scopes → Permissions** (Microsoft
Purview solutions); confirm the operator is in **Compliance Administrator** and
**Information Protection** (and **Records Management** if doing records).
**Implement if missing:** Add the operator to the required role groups in **Roles & scopes →
Permissions**. Reserve **Global Administrator** for tenant-wide changes only.

## R4. Access to the GCC High Purview compliance portal

**Description:** The operator can reach and use **`https://compliance.microsoft.us`** (Microsoft
Purview portal, rolling to `purview.microsoft.us`).
**Why:** All label/DLP/retention authoring happens here. If filtering blocks the `.us` sovereign
hosts, nothing can be configured.
**Verify:** Browse to **`https://compliance.microsoft.us`**; the Purview solutions (Information
Protection, Data Loss Prevention, Data Lifecycle Management, Records Management) load.
**Implement if missing:** Allow the GCC High Purview/Defender hosts through proxy/filtering (see R6),
and confirm the account has R3 roles.

## R5. A label taxonomy, data owners, a pilot scope, and change control

**Description:** A short **agreed label taxonomy** (e.g. `Public`, `General`, `Confidential`,
`Confidential \ CUI`), named **data owners** who approve classification meaning, a named **pilot
group**, and a **change-control/rollback** process (labeling and DLP-block changes can disrupt users).
**Why:** Purview is a business-classification system, not just a technical control. Publishing labels
or enforcing DLP without owner agreement and a pilot causes user disruption and mislabeled data.
**Verify:** A one-page taxonomy exists with owner sign-off; a pilot Entra security group named
**`SG-Purview-Pilot`** exists (`entra.microsoft.us` → Groups); a change ticket template with approver,
window, and rollback exists.
**Implement if missing:** Draft the taxonomy with data owners; create **`SG-Purview-Pilot`** in
`entra.microsoft.us`; adopt the change-control process from `global-requirements-security.md` (G8).

## R6. Network / filtering allow-list for GCC High endpoints

**Description:** Outbound HTTPS to the **GCC High sovereign endpoints** for portals, service-side
protection, endpoint DLP, and the labeling client/scanner.
**Why:** Enrollment, policy sync, auto-labeling, DLP telemetry, and script access all use the `.us`
Gov hosts. If only the `.com` Commercial hosts are allowed, GCC High Purview will not function.
**Verify:** From an admin workstation, reach **`https://login.microsoftonline.us`**,
**`https://compliance.microsoft.us`**, **`https://security.microsoft.us`**, and
**`https://graph.microsoft.us`**.
**Implement if missing:** Allow Microsoft's published **Office 365 U.S. Government GCC High** URL/IP
ranges through proxy/firewall (the Gov endpoint list is separate from the Commercial "Office 365
Worldwide" list). Include the labeling client, endpoint-DLP, and PowerShell Gov endpoints.

## R7. Managed endpoints onboarded for Endpoint DLP (if using device DLP)

**Description:** Windows/macOS devices onboarded to **Microsoft Defender / Endpoint** in the GCC High
tenant and visible for **Endpoint DLP**.
**Why:** Endpoint DLP (copy-to-USB, print, cloud-upload controls) — **Available** in GCC High — only
covers onboarded devices. Unonboarded devices are invisible to device DLP.
**Verify:** `compliance.microsoft.us` → **Settings → Device onboarding**; devices show onboarded. In
`security.microsoft.us`, devices are enrolled.
**Implement if missing:** Onboard devices per Microsoft's Endpoint DLP onboarding for GCC High, then
turn on device monitoring in Purview **Settings → Device onboarding**.

## R8. Parity confirmation for the specific features you intend to use

**Description:** A completed check of the **GCC High parity table** for every Purview feature this
deployment depends on (specific SITs, trainable classifiers, auto-labeling surfaces, records
options, Adaptive Protection).
**Why:** Several Commercial features are **not available** in GCC High (named-entity SITs, mobile
auto-labeling, trainable-classifier-driven *records* labels, end-of-retention label actions, records
Power Automate, Priva). Designing around a missing feature wastes the pilot.
**Verify:** Work through `gcc-high-parity-notes.md`; for each feature you need, confirm status is
**Available** in the live Microsoft doc **and** the option is visible in `compliance.microsoft.us`.
**Implement if missing:** Where a needed feature is *in development / on backlog*, choose the GA
alternative (e.g. built-in SIT/EDM/keyword instead of named-entity SIT; condition-based record
policy instead of classifier-based) and record the substitution in the design.

---

**The deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**
