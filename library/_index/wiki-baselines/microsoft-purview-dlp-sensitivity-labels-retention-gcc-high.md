# Microsoft Purview — DLP, Sensitivity Labels & Retention (Government / GCC High)

> **Version 1.0.0** · Category: Security · Solution code: PURVIEWG

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Microsoft Purview DLP, Labels & Retention (Government / GCC High)

## The problem

Microsoft Purview in **GCC High is not the Commercial product with a different sign-in.** The admin
portals are separate US sovereign-cloud endpoints (`compliance.microsoft.us`, `security.microsoft.us`,
`login.microsoftonline.us`), and **several Purview capabilities lag, are limited, or are absent**
versus Commercial. A government tenant configured from Commercial runbooks silently fails — options
simply are not present, and steps assume features that do not exist in GCC High.

## What this solution does

It deploys the three Purview pillars — **sensitivity labels + auto-labeling**, **Data Loss
Prevention**, and **retention + records management** — **correctly for GCC High**: the right portals,
the right endpoints, and the Commercial-vs-GCC-High **feature parity gaps called out at the exact
step where they matter**. It follows a repeatable **Assess → Configure → Pilot → Validate → Expand**
model with pass/fail gates, so the configuration is proven on a named pilot before it scales.

## The GCC High differences that matter (doc-confirmed)

Drawn from Microsoft's *Plan for Microsoft Purview — GCC High deployments* service description:

- **Named-entity sensitive information types** are **not available** — DLP and auto-labeling are
  built from GA building blocks (built-in SITs, Exact Data Match, keywords, regex).
- **Auto-labeling on Office *mobile* clients** is **not available**; service-side (EXO/SPO/OneDrive)
  and desktop/web client-side auto-labeling **are**.
- **Auto-applying *records* labels with trainable classifiers**, and **applying a retention label
  action at end of the retention period**, are **not available** — condition/event-based retention
  is used instead.
- **Records-management Power Automate and several Graph APIs** are **not available**.
- **Adaptive Protection** (risk-based DLP) is **rolling out to Gov clouds** — verify before relying
  on it. **Microsoft Priva** is **not available**.

Where a GCC High specific could not be confirmed, the solution states the Commercial behavior and
**explicitly flags "verify for GCC High"** rather than inventing menus or parity claims.

## Business outcome

An ungoverned data estate — unclassified data, DLP noise, no retention, compliance gaps — becomes a
**governed** one: data **labeled, protected, and retained** on a US sovereign cloud, configured the
repeatable way, validated on a pilot, and safe to expand. Self-guided and tested, at a fraction of
consulting cost.

**Deployment model:** Assess → Configure → Pilot → Validate → Expand.


---


# Solution Overview — Microsoft Purview DLP, Sensitivity Labels & Retention (Government / GCC High)

## What this solution delivers

This is the **Government (GCC High)** edition of the Microsoft Purview information-protection
solution. It walks a competent-but-novice administrator through deploying three Purview pillars on a
**US sovereign-cloud (GCC High)** tenant, the repeatable way:

1. **Sensitivity labels + label policies (+ auto-labeling)** — classify and, where appropriate,
   encrypt content so protection travels with the data.
2. **Data Loss Prevention (DLP)** across Exchange, SharePoint, OneDrive, Teams, and endpoints —
   detect and control the movement of sensitive information, **starting in audit and tuning before
   you enforce**.
3. **Retention labels & policies and records management** — keep what must be kept, dispose of what
   must go, on a defensible schedule.

Together these turn an **ungoverned data estate** (unclassified data, DLP noise, no retention,
compliance gaps) into a **governed** one: data that is **labeled, protected, and retained** — proven
on a pilot before you scale.

## Why GCC High is a different solution, not a re-login

Microsoft Purview in **GCC High is not the Commercial portal with a different sign-in.** Two things
differ in ways that break Commercial runbooks:

- **The portals and endpoints are different sovereign-cloud hosts** — you administer Purview at
  `compliance.microsoft.us` (rolling to `purview.microsoft.us`), sign in at
  `login.microsoftonline.us`, and your scripts must target **US Gov Graph endpoints**
  (`Connect-MgGraph -Environment USGov`). Point a Commercial runbook at `compliance.microsoft.com`
  and you are in the wrong cloud.
- **Feature parity lags Commercial.** Several Purview capabilities that are generally available in
  Commercial are, in GCC High, in preview, "in development", or "on the engineering backlog" — i.e.
  **not present**. Following Commercial steps that assume those features will silently fail: the menu
  or option simply is not there.

This edition calls out the correct GCC High portals/endpoints at each step, and flags the parity
gaps **where they matter**, so a government tenant is configured correctly. The full parity reference
lives in `gcc-high-parity-notes.md` and is cited throughout.

## The Purview information-protection model (how the pieces fit)

- **Sensitivity labels** are the classification taxonomy (e.g. `Public`, `General`,
  `Confidential`, `Confidential \ CUI`). A **label policy** publishes labels to users/groups and sets
  behavior (default label, mandatory labeling, downgrade justification). **Auto-labeling** applies a
  label without user action, based on conditions (built-in sensitive information types, Exact Data
  Match, keyword dictionaries, or trainable classifiers).
- **DLP policies** watch for sensitive content (the same SITs/EDM/classifiers) as it is stored,
  shared, or exfiltrated, and take actions (audit, notify, block, restrict) across M365 locations
  and managed endpoints. A **sensitivity label can itself be a DLP condition** — label once, enforce
  everywhere.
- **Retention labels / policies** govern how long content lives and what happens at end of life
  (retain, then delete; delete only; or declare a **record** with a locked retention). **Records
  management** adds file plan, disposition review, and proof of disposal for regulated content.

The design principle across all three is **assign once, repeat everywhere**: a small, well-named
taxonomy drives labeling, DLP, and retention consistently, instead of one-off policies per team.

## Commercial vs GCC High — what's different

*(Doc-confirmed from Microsoft's "Plan for Microsoft Purview — GCC High deployments" service
description unless flagged. See `gcc-high-parity-notes.md` for the full table and citations.)*

**Portals & endpoints (always different):**

| Purpose | Commercial | GCC High |
| --- | --- | --- |
| Sign-in | `login.microsoftonline.com` | `login.microsoftonline.us` |
| Microsoft 365 admin | `admin.microsoft.com` | `portal.office365.us` |
| Purview / compliance | `compliance.microsoft.com` | `compliance.microsoft.us` (→ `purview.microsoft.us`) |
| Security portal | `security.microsoft.com` | `security.microsoft.us` |
| Entra admin | `entra.microsoft.com` | `entra.microsoft.us` |
| Graph (scripts) | `graph.microsoft.com` (`-Environment Global`) | `graph.microsoft.us` (`-Environment USGov`) |

**Feature parity gaps that change how you design (GCC High status in parentheses):**

- **Named entity SITs and their policy-authoring templates** are **not available** (*on engineering
  backlog*). Build DLP/auto-label conditions from **built-in SITs, Exact Data Match, keyword
  dictionaries, and regex SITs** instead.
- **Auto-labeling for Office *mobile* clients** is **not available** (*on engineering backlog*).
  Client-side auto-labeling on Windows/Mac/web and service-side auto-labeling for
  EXO/SPO/OneDrive **are** available.
- **Applying a "default label" to unlabeled files in a SharePoint library**, and **default label on
  documents being edited**, are **not available** (*in development*). Plan default-labeling around
  what is GA (label policy default label for users; service-side auto-labeling).
- **Granular Conditional Access via sensitivity labels for SPO sites** is **not available** (*on
  engineering backlog*). Verify container/site-label behavior separately for GCC High.
- **Auto-applying *retention/records* labels with trainable classifiers** is **not available**
  (*in development*), and **"apply retention label action at end of retention period"** is **not
  available** (*on engineering backlog*). Trainable classifiers **do** work for **client-side
  auto-labeling** of sensitivity labels (GA).
- **Records-management Power Automate integration** and several **Graph APIs (records, eDiscovery
  export, Teams export)** are **not available** (*in development / backlog*).
- **Adaptive Protection** (Insider Risk → dynamic DLP) is **rolling out to Gov clouds** (GCC/GCC
  High/DoD), not long-established — **verify it is present in your tenant** before designing on it.
- **DSPM for AI** is available but **"Browse to URL" policy cannot be created** in GCC-H; only
  supported AI sites apply.
- **Microsoft Priva** (Privacy Risk Management, Subject Rights Requests) is **not available**
  (*in development*).

Where a specific classifier, SIT, or option is not visible in `compliance.microsoft.us`, treat it as
a **GCC High parity gap, not a permissions problem** — re-check the parity table before troubleshooting.

## The standard deployment model

Every step in this solution follows the same repeatable model, with an explicit **pass/fail gate**
between phases:

**Assess → Configure → Pilot → Validate → Expand.**

- **Assess** — confirm licensing (Gov G3/G5), roles, portal access, and which features are actually
  available in your GCC High tenant (the parity check).
- **Configure** — design the label taxonomy and build labels, label policy, DLP policies (in
  **audit/test** mode), and retention labels/policies. Name every object verbatim.
- **Pilot** — publish to a **named pilot group** only.
- **Validate** — run the pass/fail gates in `05-testing.md` against the pilot.
- **Expand** — widen scope group-by-group only after the gate passes.

## What's in the box

- This overview, a **Requirements** guide, an ordered **Implementation** guide, **Testing** (pass/fail
  gates), **Troubleshooting** (with GCC-High-specific gotchas), **Best Practices**, and a
  **Deliverables Summary** + **Executive Summary**.
- A **GCC High parity notes** reference (`gcc-high-parity-notes.md`) with per-feature status and
  Microsoft citations.
- **Five PowerShell scripts** (Graph SDK, US Gov endpoints): Discovery, Validation, Report,
  Remediation, and Set-ScopeTargeting — read-only tools default to read-only; change tools default
  to `-WhatIf`.

> **Sources:** Microsoft Learn — *Plan for Microsoft Purview — GCC High deployments*
> (`.../plan-for-microsoft-purview-gcc-high-deployments`); *Microsoft Purview service description*;
> *Adaptive Protection* docs; MSPortals.io US Government portals. Full citations in
> `gcc-high-parity-notes.md`.


---


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


---


# Global Requirements — Security solutions (Intune + Entra ID + cloud PKI) (category-level)

These requirements apply to **every** solution in the **Security solutions (Intune + Entra ID +
cloud PKI)** category. They are published once at the category level so individual listings stay
small. Confirm these before deploying *any* security solution in this category. Each entry:
**Description · Why · Verify · Implement-if-missing.**

## G1. Microsoft Entra ID tenant
**Description:** An active Microsoft Entra ID tenant.
**Why:** It is the identity backbone for every cloud-managed device, certificate, and security policy.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create a Microsoft 365 / Azure subscription, which provisions a tenant.

## G2. Microsoft Intune subscription
**Description:** An Intune-bearing license plan.
**Why:** Intune delivers the configuration, certificate, compliance, and security policies these solutions rely on.
**Verify:** `https://intune.microsoft.com` loads; **Tenant administration → Tenant status** shows active.
**Implement:** Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1.

## G3. Administrative roles
**Description:** Appropriate Entra/Intune admin roles for the operator.
**Why:** Creating certificate profiles, connectors, and security policies requires elevated rights.
**Verify:** Entra → **Roles and administrators**; confirm **Intune Administrator**.
**Implement:** Assign **Intune Administrator**; reserve Global Administrator for tenant-wide changes.

## G4. Device enrollment in Intune
**Description:** Targeted devices are enrolled and manageable.
**Why:** Certificate and security policies only reach enrolled devices.
**Verify:** Intune → **Devices → All devices**; the device appears and is **compliant**.
**Implement:** Enable **Automatic Enrollment** and join devices to Entra ID.

## G5. Pilot security group
**Description:** A Microsoft Entra security group for pilot/targeted users or devices.
**Why:** Every solution in this category is piloted before fleet rollout — especially anything that touches authentication.
**Verify:** Entra → **Groups**; the pilot group exists.
**Implement:** Entra → **Groups → New group** → **Security** → add members.

## G6. Supported, current OS baseline
**Description:** Devices on a vendor-supported, currently-patched OS (Windows 10/11, iOS/iPadOS, Android, or macOS as applicable).
**Why:** Modern Intune certificate and security features assume a supported, patched OS.
**Verify:** `winver` (Windows), device **Settings → About**, or Intune → device → **Hardware**.
**Implement:** Patch/upgrade to a supported build before deploying policies.

## G7. Network access to Microsoft cloud endpoints
**Description:** Outbound HTTPS to Microsoft 365, Entra, and Intune service URLs.
**Why:** Enrollment, policy sync, certificate issuance, and authentication depend on these endpoints.
**Verify:** From a device, reach `https://login.microsoftonline.com` and `https://enrollment.manage.microsoft.com`.
**Implement:** Allow Microsoft's published Microsoft 365 / Intune URL and IP ranges through proxy/firewall.

## G8. Change control for authentication-impacting changes
**Description:** A documented change-control / rollback process for any change that touches certificates, Wi-Fi, VPN, or sign-in.
**Why:** Certificate and authentication changes can lock users out of network or apps if misconfigured; a pilot gate and rollback are mandatory.
**Verify:** A change ticket exists with an approver, a maintenance window, and a documented rollback step.
**Implement:** Record the change, name a pilot group, define the rollback, and get approval before assigning to production.

---
**The deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


# Implementation — Purview DLP, Labels & Retention (Government / GCC High)

Follow these steps **in order**. Every navigation path uses the **GCC High** portals — sign in at
**`https://login.microsoftonline.us`** and work in **`https://compliance.microsoft.us`** (the
Microsoft Purview portal; it may redirect to `purview.microsoft.us`). If a portal loads at a `.com`
host, stop — you are in the Commercial cloud.

**Naming — use these object names verbatim** (reuse them exactly in later steps and in the scripts):

| Object | Name to create and reuse |
| --- | --- |
| Pilot Entra security group | `SG-Purview-Pilot` |
| Sensitivity labels | `Public`, `General`, `Confidential`, `Confidential \ CUI` |
| Label policy | `LP-Purview-Pilot` |
| Auto-labeling policy (service-side) | `AL-CUI-ServiceSide` |
| DLP policy | `DLP-CUI-Baseline` |
| DLP rule (inside the policy) | `DLP-CUI-Baseline-Rule1` |
| Retention label | `Ret-CUI-7yr` |
| Retention label policy (auto-apply) | `RP-CUI-7yr-Auto` |
| Org-wide retention policy | `RP-Baseline-Retain` |

**GCC High parity reminders are inlined at the step where they matter.** Full detail:
`gcc-high-parity-notes.md`.

---

## Phase 0 — Assess (gate before you build)

1. Sign in at **`https://login.microsoftonline.us`**; open **`https://compliance.microsoft.us`**.
   Confirm the Purview solutions **Information Protection**, **Data Loss Prevention**, **Data
   Lifecycle Management**, and **Records Management** all appear in the left navigation.
2. Confirm licensing (R2) at **`https://portal.office365.us` → Billing → Licenses** — G3/G5 (+ G5
   Compliance / IP&G) present.
3. Confirm roles (R3) at **`compliance.microsoft.us` → Settings → Roles & scopes → Permissions**.
4. Confirm **`SG-Purview-Pilot`** exists at **`https://entra.microsoft.us` → Groups**. If not:
   **Groups → New group → Security**, name it `SG-Purview-Pilot`, add pilot users.
5. **Run the parity check (R8).** For every feature you intend to use, confirm **Available** in
   `gcc-high-parity-notes.md` and that the option is visible in the portal.

**Gate:** portal loads at `.us`, licensing/roles present, pilot group exists, parity check done.
Do not proceed until all pass.

---

## Phase 1 — Sensitivity labels + label policy

### Step 1.1 — Create the labels

1. In **`compliance.microsoft.us`** go to **Information Protection → Labels** (under **Solutions**;
   in the newer Purview portal this is **Information Protection → Sensitivity labels**).
2. **+ Create a label**. Create these four, in order, with these exact names:
   - `Public` — scope **Items** (Files & emails). No encryption, no content marking.
   - `General` — scope **Items**. No encryption; optional footer "General".
   - `Confidential` — scope **Items**. Turn on **Encrypt** (assign permissions to your org),
     content marking footer "Confidential".
   - `Confidential \ CUI` — create `Confidential` first, then create **CUI** as a **sublabel** of
     `Confidential`. Turn on **Encrypt** with a restrictive permission set; content marking header
     "CUI".
3. For each label, complete the wizard (scope → protection settings → content marking → auto-labeling
   for files/emails **left OFF here**; you configure auto-labeling in Phase 2).

> **GCC High note (containers):** if you want to label **Teams/Groups/SharePoint sites**
> (container labels), enable **Groups & sites** scope. Container labeling is available, but
> **granular Conditional Access via sensitivity labels for SPO sites is *not available* in GCC High**
> (*on engineering backlog*) — do not design site access-control on that feature. Verify container
> behavior in your tenant. (`gcc-high-parity-notes.md` §2.)

### Step 1.2 — Publish the labels with a label policy

1. **Information Protection → Label policies → Publish labels**.
2. Select `Public`, `General`, `Confidential`, `Confidential \ CUI`.
3. **Assign to users and groups:** choose **`SG-Purview-Pilot`** only (pilot scope).
4. Policy settings:
   - **Default label for documents/emails:** `General`.
   - **Require users to apply a label** (mandatory labeling): **On** for the pilot.
   - **Require justification to remove a label or lower classification:** **On**.
5. **Name the policy `LP-Purview-Pilot`**; finish.

> **GCC High note:** applying a **"default label" to unlabeled files uploaded to a SharePoint
> library**, and **default label on documents being edited**, are **not available** in GCC High
> (*in development*). The **user default label** above (via label policy) **is** available. Do not
> rely on library-side default labeling yet.

**Gate:** pilot users see the four labels in Word/Excel/PowerPoint/Outlook (allow up to a few hours
to replicate). If not visible, see `06-troubleshooting.md`.

---

## Phase 2 — Auto-labeling (service-side)

### Step 2.1 — Build conditions from GA classifiers only

> **GCC High parity — read first:** **Named entity SITs and their policy-authoring templates are
> *not available*** in GCC High (*on engineering backlog*). Build conditions from **built-in
> sensitive information types**, **Exact Data Match (EDM)** (Available), **keyword dictionaries**,
> and **regex SITs**. **Trainable classifiers** work for **client-side** auto-labeling (Available)
> but **not** for auto-applying *records* labels (*in development*). **Office *mobile* auto-labeling
> is *not available***. (`gcc-high-parity-notes.md` §2.)

1. If you need a custom match, create it first under **Data classification → Classifiers →
   Sensitive info types** (built-in/EDM/keyword/regex) or **Exact data match**. Do **not** select a
   named-entity SIT — it will not be present.

### Step 2.2 — Create the service-side auto-labeling policy

1. **Information Protection → Auto-labeling** → **+ Create auto-labeling policy**.
2. Choose a template or **Custom**. **Locations:** Exchange Online, SharePoint Online, OneDrive
   (service-side auto-labeling for these three is **Available** in GCC High).
3. **Rules:** add conditions using the GA SITs/EDM/keywords from Step 2.1 (e.g. content contains your
   CUI EDM/keyword set).
4. **Label to apply:** `Confidential \ CUI`.
5. **Scope:** restrict to **`SG-Purview-Pilot`** mailboxes/sites where possible.
6. **Name the policy `AL-CUI-ServiceSide`**. Create it in **simulation (test) mode** — do **not**
   turn on immediately.
7. Run **simulation**, review matches in the policy's results, then turn the policy **On** only after
   the pilot gate passes.

**Gate:** simulation shows expected matches with acceptable false positives; no unexpected mass-label.

---

## Phase 3 — DLP (audit first, then enforce)

### Step 3.1 — Create the DLP policy in test/audit mode

1. **Data Loss Prevention → Policies → + Create policy**.
2. **Custom** policy. **Locations:** Exchange, SharePoint, OneDrive, **Teams chat and channel**, and
   **Devices (Endpoint DLP)** — all **Available** in GCC High (Endpoint DLP requires onboarded
   devices, R7).
3. **Create rule** named **`DLP-CUI-Baseline-Rule1`**:
   - **Conditions:** *Content contains* → your GA SITs/EDM/keywords **and/or** *Content contains
     sensitivity label* → `Confidential \ CUI` (label-as-condition = "label once, enforce
     everywhere").
   - **Actions:** for the pilot, **audit only** — **no block**. (Notify admin; optional policy tip.)
4. **Name the policy `DLP-CUI-Baseline`**.
5. Set the policy **mode to *Test it out* / *Run in test mode* (audit)** — **not** "Turn it on".
   Scope to **`SG-Purview-Pilot`** where the location supports user scoping.

> **GCC High note (SITs):** confirm each SIT in your rule is a **built-in/EDM/keyword/regex** type,
> not a named-entity SIT (not available). **Adaptive Protection** (risk-based DLP) is **rolling out
> to Gov clouds** — if you plan to gate DLP actions on Insider Risk levels, **verify Adaptive
> Protection is present in your tenant first** (`gcc-high-parity-notes.md` §5).

### Step 3.2 — Tune, then enforce

1. Let the policy run in **test/audit** for the pilot window. Review matches in **Data Loss
   Prevention → Alerts** and **Activity Explorer** (**Available** in GCC High).
2. Tune conditions to reduce false positives.
3. Only after the pilot gate passes, edit `DLP-CUI-Baseline`, add **Block** / **Restrict** actions
   (with user override + justification if appropriate), and switch mode to **On**. Expand scope
   group-by-group.

**Gate:** DLP matches are accurate in audit; enforcement change goes through change control (G8)
before any block is enabled.

---

## Phase 4 — Retention & records

### Step 4.1 — Org-wide baseline retention policy

1. **Data Lifecycle Management → Retention policies → + New retention policy**.
2. **Name `RP-Baseline-Retain`**. **Locations:** Exchange email, SharePoint, OneDrive, Microsoft 365
   Groups, **Teams chat / channel / meeting recordings** (all **Available** in GCC High).
3. Set retain-then-delete for your baseline period. **Adaptive scopes** (Available) can target by
   attribute if needed.

### Step 4.2 — Retention label for CUI

1. **Data Lifecycle Management → Retention labels → + Create a label**.
2. **Name `Ret-CUI-7yr`**. Set **Retain items for 7 years**, then choose the end-of-period behavior.

> **GCC High note:** **"Apply retention *label* action at end of retention period"** is **not
> available** (*on engineering backlog*). For the end-of-life step, use a supported behavior
> (retain-then-delete, or start a disposition review) rather than a label-action-at-end-of-period.
> (`gcc-high-parity-notes.md` §4.)

3. To make it a **record**, enable **Mark items as a record** (records management is **Available**).
   Use **Preservation Lock** (Available) where immutability is required.

### Step 4.3 — Auto-apply the retention label

1. **Retention labels → `Ret-CUI-7yr` → Auto-apply** (or **Label policies → Auto-apply a label**).
2. **Name the policy `RP-CUI-7yr-Auto`**. Condition: content contains your **GA SITs/EDM/keywords**.

> **GCC High note:** **auto-applying record policies *with trainable classifiers*** is **not
> available** (*in development*). Use **condition-based** (keyword/SIT/EDM) or **event-based**
> auto-apply for records, which **is** available.

3. Scope to **`SG-Purview-Pilot`** where supported; publish.

### Step 4.4 — Disposition / file plan (records)

1. **Records Management → File plan** — import/define record categories; **File plan manager**,
   **regulatory records**, **proof of disposal**, and **disposition review** are **Available**.
2. **Multi-stage disposition review** is **Rolling out** — verify it is present before relying on it.

> **GCC High note:** **Records Management Power Automate integration** and **Records Management Graph
> APIs** are **not available** (*backlog / in development*). Do not build record automations on
> Power Automate/Graph for records yet.

**Gate:** retention/records applied to pilot content as expected; disposition review reachable for
records.

---

## Phase 5 — Pilot → Validate → Expand

1. **Pilot** is already scoped to **`SG-Purview-Pilot`** across labels, DLP (audit), and retention.
2. **Validate** using the pass/fail gates in `05-testing.md`. Run **`PURVIEWG-Validation.ps1`** and
   **`PURVIEWG-Report.ps1`** (US Gov Graph) to confirm coverage.
3. **Expand** only after gates pass: widen the label policy and DLP scope group-by-group (use
   **`PURVIEWG-Set-ScopeTargeting.ps1`**, which defaults to `-WhatIf`), and flip DLP from audit to
   enforce under change control.

---

**The deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**

> **Sources:** Microsoft Learn — *Plan for Microsoft Purview — GCC High deployments* (parity table);
> *Microsoft Purview service description*; *Adaptive Protection* docs. Portals: `portal.office365.us`,
> `compliance.microsoft.us`/`purview.microsoft.us`, `security.microsoft.us`, `entra.microsoft.us`,
> `login.microsoftonline.us`. Full citations in `gcc-high-parity-notes.md`.


---


# Testing — Purview DLP, Labels & Retention (Government / GCC High)

Run these gates against the **pilot** (`SG-Purview-Pilot`) before expanding. Each gate has an
explicit **PASS / FAIL** condition. A FAIL sends you to `06-troubleshooting.md`; do not expand scope
or enable enforcement until every applicable gate is **PASS**. Portals are the GCC High `.us` hosts;
scripts connect with **`Connect-MgGraph -Environment USGov`**.

---

## Gate 0 — Sovereign-cloud sanity (must pass first)

- **Test:** In a browser, load `https://compliance.microsoft.us`; run
  `PURVIEWG-Discovery.ps1` and confirm it connected to the **US Gov** Graph endpoint.
- **PASS:** Portal loads at a `.us` host; script reports environment `USGov` /
  `graph.microsoft.us`.
- **FAIL:** Any portal or script resolves to a `.com` host → you are targeting Commercial; stop and
  fix endpoint/environment before any other test.

## Gate 1 — Licensing & roles present

- **Test:** `portal.office365.us → Billing → Licenses` shows G3/G5 (+ G5 Compliance/IP&G);
  `compliance.microsoft.us → Settings → Roles & scopes → Permissions` shows the operator in
  **Compliance Administrator** and **Information Protection**.
- **PASS:** Both present. **FAIL:** Missing SKU or role → cannot author the corresponding feature.

## Gate 2 — Parity check completed

- **Test:** For every feature this deployment uses, `gcc-high-parity-notes.md` status is **Available**
  and the option is visible in `compliance.microsoft.us`.
- **PASS:** Every needed feature is Available and visible. **FAIL:** A needed feature is *in
  development / backlog* (e.g. named-entity SIT, mobile auto-label, classifier-based record label) →
  substitute the GA alternative before continuing.

## Gate 3 — Labels published and visible

- **Test:** A pilot user opens Word/Excel/PowerPoint/Outlook and checks the **Sensitivity** control.
- **PASS:** `Public`, `General`, `Confidential`, `Confidential \ CUI` all appear; `General` is the
  default; removing/lowering a label prompts for justification.
- **FAIL:** Labels missing after replication time → check `LP-Purview-Pilot` assignment to
  `SG-Purview-Pilot`; see troubleshooting.

## Gate 4 — Manual + mandatory labeling works

- **Test:** Pilot user saves a new document without a label.
- **PASS:** Mandatory labeling prompts for a label before save/send; applying `Confidential \ CUI`
  encrypts and marks the file per its config.
- **FAIL:** No prompt, or encryption/marking absent → verify label protection settings and policy
  mandatory-labeling toggle.

## Gate 5 — Service-side auto-labeling simulation is accurate

- **Test:** `AL-CUI-ServiceSide` runs in **simulation**; review matched items.
- **PASS:** Expected CUI content matches; false-positive rate acceptable; no unexpected mass match.
- **FAIL:** Over/under-matching → tune conditions (GA SITs/EDM/keywords only) and re-simulate.
  Confirm you did **not** use a named-entity SIT (not available in GCC High).

## Gate 6 — DLP detects in audit (no block yet)

- **Test:** Pilot user triggers a match for `DLP-CUI-Baseline` / `DLP-CUI-Baseline-Rule1` (e.g.
  emails/shares test CUI content). Check **DLP → Alerts** and **Activity Explorer**.
- **PASS:** The event is detected and recorded in audit; **no user was blocked** (policy still in
  test mode).
- **FAIL:** No detection → verify conditions, locations, and that the policy is scoped to the pilot;
  confirm SIT types are GA in GCC High.

## Gate 7 — Endpoint DLP (only if in scope)

- **Test:** On an **onboarded** device, a pilot user attempts a monitored action (copy CUI to USB /
  print / cloud upload).
- **PASS:** The action is recorded in audit for onboarded devices.
- **FAIL:** Nothing recorded → confirm the device is onboarded (`Settings → Device onboarding`) and
  device location is enabled in the policy.

## Gate 8 — DLP enforcement (post-tuning, change-controlled)

- **Test:** After audit tuning and change-control approval, enable **Block/Restrict** on
  `DLP-CUI-Baseline` and re-test the same action.
- **PASS:** Action is blocked/restricted with the expected policy tip; override/justification behaves
  as configured.
- **FAIL:** Not blocked, or blocks legitimate work → revert to audit, retune, re-approve.

## Gate 9 — Retention applied

- **Test:** Confirm `RP-Baseline-Retain` covers the intended locations; confirm `Ret-CUI-7yr` (via
  `RP-CUI-7yr-Auto`) applies to matching pilot content.
- **PASS:** Retention label present on matching items; org-wide policy active; end-of-period behavior
  is a **supported** action (not the unavailable "apply label action at end of period").
- **FAIL:** Label not applied → verify auto-apply conditions are GA SITs/EDM/keywords (not
  classifier-based for records) and scope.

## Gate 10 — Records & disposition (only if records in scope)

- **Test:** Declare a test item a record via `Ret-CUI-7yr`; open **Records Management → Disposition**.
- **PASS:** Item is a record (locked as configured); disposition review is reachable; proof of
  disposal available.
- **FAIL:** Record behavior missing → confirm records management is licensed (G5) and the label's
  "mark as record" is set; multi-stage review is *rolling out* — verify presence.

## Gate 11 — Script validation clean

- **Test:** Run `PURVIEWG-Validation.ps1` and `PURVIEWG-Report.ps1` (US Gov Graph).
- **PASS:** Validation reports labels/DLP/retention present and scoped as designed; report lists
  coverage with no unexpected gaps.
- **FAIL:** Reported gaps → remediate (see `PURVIEWG-Remediation.ps1`, which defaults to `-WhatIf`)
  and re-run.

---

**Expansion gate:** proceed from Pilot to Expand **only** when Gates 0–6 and 9 are PASS (plus 7/8/10
where in scope) and any DLP enforcement change has change-control approval.

**The deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


# Troubleshooting — Purview DLP, Labels & Retention (Government / GCC High)

Work top-down. The first section covers the failures that are **unique to GCC High** — check these
before generic Purview troubleshooting, because in GCC High "it's not there" is often a **parity
gap**, not a misconfiguration.

---

## A. GCC-High-specific gotchas

### A1. A menu/option/feature simply isn't there
**Symptom:** A step in a Commercial guide references a menu, toggle, SIT, or classifier that does not
exist in your portal.
**Likely cause:** It is a **GCC High parity gap** — the feature is *in development* or *on the
engineering backlog*, i.e. **not available** in GCC High.
**Check / fix:** Open `gcc-high-parity-notes.md` and confirm the feature's status. Common ones:
**named-entity SITs** (not available), **Office *mobile* auto-labeling** (not available),
**default label on SharePoint upload / on documents being edited** (not available),
**auto-apply records with trainable classifiers** (not available), **retention label action at end
of period** (not available), **records Power Automate / Graph APIs** (not available), **Microsoft
Priva** (not available). Use the GA alternative documented in `03-implementation.md`. Do **not** file
a support case for a backlog feature.

### A2. Wrong cloud — portal or script hit a `.com` host
**Symptom:** Sign-in loops, "tenant not found", empty portal, or a script authenticates but sees no
Purview objects.
**Likely cause:** You reached the **Commercial** cloud (`compliance.microsoft.com`,
`login.microsoftonline.com`, or `Connect-MgGraph -Environment Global`) instead of GCC High.
**Fix:** Use the `.us` hosts only — `login.microsoftonline.us`, `compliance.microsoft.us`
(→ `purview.microsoft.us`), `security.microsoft.us`, `entra.microsoft.us`, `portal.office365.us`. In
scripts, connect with **`Connect-MgGraph -Environment USGov`** (DoD: `USGovDoD`). Verify with
`(Get-MgContext).Environment` = `USGov`. Run `PURVIEWG-Discovery.ps1`, which reports the environment.

### A3. Endpoint blocked by filtering
**Symptom:** Portal will not load, or the labeling client / endpoint DLP / scripts cannot reach the
service, on-network only.
**Likely cause:** Proxy/firewall allows the **Commercial** Office 365 endpoint list but not the
**Office 365 U.S. Government GCC High** list (the `.us` sovereign hosts are a separate published set).
**Fix:** Allow the GCC High URL/IP ranges (portals, `graph.microsoft.us`,
`login.microsoftonline.us`, the Security & Compliance PowerShell Gov URI, endpoint-DLP and labeling
client endpoints). Re-test R6 reachability from an on-network workstation.

### A4. Security & Compliance PowerShell won't connect
**Symptom:** `Connect-IPPSSession` fails or connects to the wrong org.
**Fix:** Use the GCC High connection: `Connect-IPPSSession -ConnectionUri
https://ps.compliance.protection.office365.us/powershell-liveid/ -ExchangeEnvironmentName
O365USGovGCCHigh` (per Microsoft "Connect to Security & Compliance PowerShell"). The Graph-SDK
scripts in this solution use `-Environment USGov`; cmdlet-based label/DLP work uses the URI above.

### A5. Trainable classifier not selectable
**Symptom:** A pre-trained classifier you expected is missing when authoring an auto-label/retention
condition.
**Likely cause:** In GCC High, trainable classifiers are **Available for client-side sensitivity
auto-labeling** but **not** for auto-applying **records** labels (*in development*); individual
classifier availability can also lag.
**Fix:** For records auto-apply, use **condition-based** (keyword/SIT/EDM) or **event-based** rules.
For sensitivity auto-labeling, confirm the specific classifier is listed before designing on it —
**verify for GCC High** if unsure.

### A6. Adaptive Protection options missing
**Symptom:** Risk-based DLP (Insider Risk levels as a DLP condition) not available.
**Likely cause:** Adaptive Protection is **rolling out to Gov clouds** (GCC/GCC High/DoD) — it may
not yet be enabled in your tenant.
**Fix:** Verify presence in `compliance.microsoft.us` (Insider Risk Management → Adaptive
Protection); if absent, do not design DLP on it yet. Ship standard DLP and add Adaptive Protection
when it lands.

---

## B. Labels not appearing for users

- **Cause:** `LP-Purview-Pilot` not assigned to `SG-Purview-Pilot`, or replication delay.
- **Fix:** `compliance.microsoft.us → Information Protection → Label policies` — confirm the policy
  targets `SG-Purview-Pilot` and includes all four labels. Allow up to a few hours; have the user
  restart the Office app / sign out and in. Confirm the user has a G3/G5 license (R2).

## C. Mandatory labeling / justification not enforced

- **Cause:** Policy toggles off, or the client is older than the setting supports.
- **Fix:** In `LP-Purview-Pilot`, confirm **Require users to apply a label** and **Require
  justification to remove/lower** are on. Ensure supported, current Office builds (G6).

## D. Auto-labeling not matching (or over-matching)

- **Cause:** Conditions use a non-GA SIT (named-entity — not available), or thresholds too
  broad/narrow; policy still in simulation.
- **Fix:** Rebuild conditions from **built-in SITs / EDM / keyword / regex**. Re-run **simulation**
  on `AL-CUI-ServiceSide`; review matches; tune; only then turn On. Remember mobile-client
  auto-labeling is not available in GCC High.

## E. DLP not detecting

- **Cause:** Wrong locations, policy scoped away from the pilot, non-GA SIT, or (for devices)
  unonboarded endpoints.
- **Fix:** Confirm `DLP-CUI-Baseline` locations (EXO/SPO/OneDrive/Teams/Devices) and that
  `DLP-CUI-Baseline-Rule1` conditions are GA SITs/EDM/keywords or the `Confidential \ CUI` label.
  For Endpoint DLP, confirm devices are onboarded (`Settings → Device onboarding`, R7). Check **DLP →
  Alerts** and **Activity Explorer**.

## F. DLP blocking legitimate work

- **Cause:** Enforcement enabled before audit tuning, or conditions too broad.
- **Fix:** Set `DLP-CUI-Baseline` back to **test/audit**, retune to cut false positives, get
  change-control approval, then re-enable Block/Restrict with user override/justification.

## G. Retention not applying / wrong end-of-life behavior

- **Cause:** Auto-apply conditions non-GA (classifier-based for records — not available), scope
  mismatch, or an attempt to use "apply label action at end of period" (not available in GCC High).
- **Fix:** Use condition/event-based auto-apply for `RP-CUI-7yr-Auto`; set a **supported**
  end-of-period behavior (retain-then-delete or disposition review). Confirm `RP-Baseline-Retain`
  locations.

## H. Records / disposition not working

- **Cause:** Records management not licensed (needs G5), "Mark as record" not set, or reliance on a
  *rolling-out* feature (multi-stage disposition review) or an unavailable one (records Power
  Automate / Graph).
- **Fix:** Confirm G5; enable **Mark items as a record** on `Ret-CUI-7yr`; verify multi-stage review
  presence before relying on it; do not automate records via Power Automate/Graph in GCC High yet.

## I. Scripts fail or report nothing

- **Cause:** Connected to Commercial Graph, missing scopes, or insufficient role.
- **Fix:** Reconnect with `Connect-MgGraph -Environment USGov` and the scopes listed in each
  script's **HOW TO RUN** header; confirm the operator's Purview roles (R3). Run
  `PURVIEWG-Discovery.ps1` first to confirm the environment and connectivity.

---

**When in doubt about a GCC High specific:** re-open the Microsoft *Plan for Microsoft Purview — GCC
High deployments* page and the Microsoft 365 Roadmap filtered to **GCC High**, and re-confirm the
feature status before troubleshooting further. Never assume Commercial behavior carries over.

**The deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


# Best Practices — Purview DLP, Labels & Retention (Government / GCC High)

Field-proven guidance for the **assign-once, repeat-everywhere** model on a **GCC High** tenant.

## Sovereign-cloud discipline (GCC High)

- **Bookmark the `.us` portals and never the `.com` ones.** Sign in at `login.microsoftonline.us`;
  administer at `compliance.microsoft.us` (→ `purview.microsoft.us`), `security.microsoft.us`,
  `entra.microsoft.us`, `portal.office365.us`. A Commercial URL in a GCC High runbook is a defect.
- **Every script targets US Gov Graph** — `Connect-MgGraph -Environment USGov` (never `Global`).
  Bake this into the header of every runbook so no one connects to the wrong cloud.
- **Treat "the option isn't there" as a parity gap, not a bug.** Before opening a support case,
  check `gcc-high-parity-notes.md` — if the feature is *in development / on backlog*, it genuinely
  is not present, and the fix is to use the GA alternative, not to troubleshoot.
- **Re-verify parity before each design.** Microsoft ships to GCC High continuously; a feature on
  the backlog last quarter may be GA now (and vice-versa). The live *Plan for Microsoft Purview —
  GCC High deployments* page is the source of truth.

## Taxonomy & labels

- **Keep the taxonomy short** — four or five labels (`Public`, `General`, `Confidential`,
  `Confidential \ CUI`) beat a sprawling tree nobody applies correctly. Get **data-owner sign-off**
  on what each label *means* before publishing.
- **Name every object verbatim and reuse it** — `LP-Purview-Pilot`, `AL-CUI-ServiceSide`,
  `DLP-CUI-Baseline`, `Ret-CUI-7yr`. Consistent names make the scripts, reports, and handover
  legible.
- **Use the label as the currency:** make `Confidential \ CUI` a **DLP condition** and a
  **retention/auto-apply condition** so one classification drives protection *and* retention —
  "label once, enforce everywhere."
- **Prefer GA classification building blocks** — built-in SITs, **Exact Data Match**, keyword
  dictionaries, regex. **Do not design on named-entity SITs** (not available in GCC High).
  Trainable classifiers are fine for **client-side sensitivity auto-labeling**, but **not** for
  auto-applying *records* labels in GCC High.

## DLP

- **Always audit before you enforce.** Ship every DLP policy in **test/audit** mode, tune out false
  positives against the pilot, and only then add **Block/Restrict** — under change control (G8).
- **Scope to the pilot group first**, expand group-by-group. A tenant-wide block on day one is how
  you take users offline.
- **Turn on policy tips and clear user justification** so users self-correct instead of filing
  tickets.
- **Endpoint DLP only covers onboarded devices** — reconcile onboarding coverage before claiming
  device protection.
- **Adaptive Protection** (risk-based DLP) is **rolling out to Gov clouds** — adopt it only after
  confirming it is present in your tenant; do not assume it from Commercial docs.

## Retention & records

- **Separate baseline retention from targeted retention:** an org-wide `RP-Baseline-Retain` for the
  floor, plus targeted `Ret-CUI-7yr` for regulated content.
- **Use adaptive scopes** (Available) to target by attribute instead of hand-maintaining locations.
- **Records need immutability:** enable **Mark as record** and **Preservation Lock** where the
  schedule must be defensible — but remember Preservation Lock cannot be undone.
- **Plan end-of-life around GA behavior:** "apply retention *label* action at end of period" is
  **not available** in GCC High — use retain-then-delete or disposition review instead.
- **Don't build record automations on Power Automate/Graph** yet — records Power Automate and records
  Graph APIs are **not available** in GCC High.

## Operations

- **Run the read-only scripts on a schedule** — `PURVIEWG-Discovery.ps1`, `PURVIEWG-Validation.ps1`,
  `PURVIEWG-Report.ps1` — to catch drift (an unscoped label, a disabled DLP rule, missing retention).
- **Keep change-tools in `-WhatIf` by default** — `PURVIEWG-Remediation.ps1` and
  `PURVIEWG-Set-ScopeTargeting.ps1` preview first; only run with `-Execute`/`-WhatIf:$false` after
  review and approval.
- **Every enforcement change is a change ticket** — approver, maintenance window, named pilot,
  documented rollback (per `global-requirements-security.md` G8).
- **Least privilege:** author with **Compliance Administrator** + **Information Protection** role
  groups, not Global Administrator.

**The deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


# Deliverables Summary — Purview DLP, Labels & Retention (Government / GCC High)

This solution deploys Microsoft Purview **sensitivity labels + auto-labeling**, **DLP**, and
**retention + records** on a **US sovereign-cloud (GCC High)** tenant, correctly — right portals,
right endpoints, and Commercial-vs-GCC-High parity gaps handled — proven on a pilot before scale.

## Documents

| File | Purpose |
| --- | --- |
| `01-solution-overview.md` | The Purview model on GCC High; how the sovereign cloud differs (portals, endpoints, parity); the Assess→Configure→Pilot→Validate→Expand model. Includes a **Commercial vs GCC High** subsection. |
| `02-requirements.md` | Each prerequisite as **Description / Why / Verify / Implement-if-missing** — GCC High tenant, Gov G3/G5 licensing, Purview roles, `compliance.microsoft.us` access, endpoint allow-list, parity confirmation. |
| `03-implementation.md` | Exact ordered steps in the GCC High portals: labels + label policy, service-side auto-labeling, DLP (audit→enforce), retention + records — with GCC-High URLs and parity caveats inline where they matter. |
| `05-testing.md` | Pass/fail gates from sovereign-cloud sanity through enforcement and script validation. |
| `06-troubleshooting.md` | GCC-High-specific gotchas (feature not present, endpoint blocked, wrong portal/cloud) plus common failures. |
| `07-best-practices.md` | The assign-once, repeat-everywhere model, tuned for GCC High. |
| `gcc-high-parity-notes.md` | Reference: per-feature Commercial-vs-GCC-High status with Microsoft citations or explicit "verify for GCC High" flags. |
| `global-requirements-security.md` | Category-level prerequisites shared by all security solutions. |
| `executive-summary.md` | One-page summary for decision-makers. |

## Scripts (PowerShell, Microsoft Graph SDK, **US Gov endpoints**)

All scripts connect with **`Connect-MgGraph -Environment USGov`** for GCC High. Read-only tools are
read-only; change tools default to **`-WhatIf`**.

| Script | Role | Default |
| --- | --- | --- |
| `PURVIEWG-Discovery.ps1` | Inventory labels, label policies, DLP policies, retention/records config in the GCC High tenant. | Read-only |
| `PURVIEWG-Validation.ps1` | Check that the named objects exist and are scoped as designed; flag gaps. | Read-only |
| `PURVIEWG-Report.ps1` | Coverage / classification / DLP-event report for review. | Read-only |
| `PURVIEWG-Remediation.ps1` | Safely remediate detected gaps. | **`-WhatIf`** |
| `PURVIEWG-Set-ScopeTargeting.ps1` | Build/adjust the protection-scope group (`SG-Purview-Pilot`) membership and policy targeting for staged expansion. | **`-WhatIf`** |

## Named objects (created and reused verbatim)

`SG-Purview-Pilot` · labels `Public`, `General`, `Confidential`, `Confidential \ CUI` · label policy
`LP-Purview-Pilot` · auto-labeling `AL-CUI-ServiceSide` · DLP `DLP-CUI-Baseline` /
`DLP-CUI-Baseline-Rule1` · retention `Ret-CUI-7yr`, policies `RP-CUI-7yr-Auto`, `RP-Baseline-Retain`.

## Outcome

A GCC High tenant with a small, owner-approved label taxonomy driving **classification**,
**DLP** (audited then enforced), and **retention/records** — with every parity gap either handled by
a GA alternative or explicitly flagged for verification, and read-only scripts to detect drift.

**The deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**
