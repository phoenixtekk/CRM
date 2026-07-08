# Container Labeling (Teams, Groups & Sites) — Microsoft Purview

> **Version 1.0.0** · Category: Purview · Solution code: IPCONT

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Container Labeling (Teams, Groups & Sites)

Most organizations protect the **file** and ignore the **container**. A sensitivity label on a document
controls that document — but the Microsoft Team, Microsoft 365 Group, or SharePoint site it lives in was
created with whatever defaults the creator clicked: public or private, guests allowed or not, external
sharing wide open, and downloadable to any personal laptop. That container is the real perimeter, and
left ungoverned it is both a compliance gap and a data-risk exposure. This solution closes that gap using
**container sensitivity labels** in Microsoft Purview.

It gives you a repeatable way to govern **privacy** (Public vs Private), **guest access** (whether owners
may add external users), **external sharing** (how broadly a labeled site may be shared), and
**unmanaged-device access** (full / web-only / blocked, via Microsoft Entra Conditional Access) for
Teams, Groups, and Sites — configured, **piloted on a small ring in test first**, validated against
pass/fail gates, and reported for coverage. Everything uses only the Microsoft Purview portal, the
Microsoft 365 / Entra admin centers, Security & Compliance PowerShell, Microsoft Graph, and the
SharePoint Online Management Shell.

This is a complete, deploy-it-today package written for a competent M365/compliance administrator, built
around a clean three-tier taxonomy — **General**, **Confidential**, and **Highly Confidential** — each
mapping to concrete privacy, guest, sharing, and device settings.

## What you get
- A plain-language Solution Overview of container labels and the three-tier taxonomy.
- A Requirements Guide with verify / implement-if-missing for every prerequisite — including the
  licensing that gates the unmanaged-device control (Entra ID P1) and the one-time tenant enablement.
- An Implementation Guide of precise, ordered portal + PowerShell + Graph + SharePoint steps, with labels
  applied **pilot-first** and each label, policy, and container named.
- Five PowerShell scripts: container discovery, a configuration/remediation helper (`-WhatIf` by default,
  handling both one-time enablement and label application), a validation checker, a coverage report, and
  a prerequisite/health helper.
- Testing and Troubleshooting guides for a confident, safe rollout.

## What this delivers
Teams, Groups, and Sites labeled to a governed posture: Private where they should be, guest access
controlled by label, external sharing tightened per tier, and confidential content web-only or blocked
from unmanaged devices — validated on a pilot ring before the estate, and evidenced by a coverage report.

## The deployment model
Assess → Design → Configure → Pilot → Validate → Expand.

## Scope boundary
This solution governs the **container**, not the files inside it — file/email classification and
encryption are the subject of the dedicated file sensitivity-labeling solution, commonly deployed
alongside this one. The unmanaged-device access control is **licensing-dependent (Entra ID P1) — verify
against your plan.** Which data warrants which tier, and who may be a guest, are decided by the
organization's compliance, data-owner, privacy, and legal functions — this solution provides the
technical method and the evidence, not the determination.

## Outcome
Govern the container, not just the file — Teams, Groups, and Sites protected by named sensitivity labels
controlling privacy, guests, sharing, and device access, delivered, validated, and defensible in
Microsoft Purview.


---


# 1. Solution Overview — Container Labeling (Teams, Groups & Sites)

## What this solution is
Most organizations classify the **file** and forget the **container**. A sensitivity label on a document
controls that document — but the Microsoft Team, Microsoft 365 Group, or SharePoint site it lives in was
created with whatever defaults the creator clicked: public or private, guests allowed or not, external
sharing wide open, and downloadable to any personal laptop. That is the gap this solution closes. It uses
**container sensitivity labels** — sensitivity labels scoped to **Groups & sites** in Microsoft Purview —
to govern the container itself:

- **Privacy** — whether a Team/Group is **Public** or **Private** by label.
- **Guest (external user) access** — whether owners may add people outside your organization as guests.
- **External sharing** — how broadly a labeled SharePoint site may be shared (anyone / new-and-existing
  guests / existing guests only / only people in your organization).
- **Unmanaged-device access** — whether a labeled site is reachable at **full access**, **limited
  web-only access** (no download/print/sync), or **blocked** from devices that aren't
  compliant/domain-joined, via Microsoft Entra Conditional Access.

Everything is done with the **Microsoft Purview portal** (purview.microsoft.com), the **Microsoft 365 /
Entra admin centers**, **Security & Compliance PowerShell** (`Connect-IPPSSession`), **Microsoft Graph**,
and **SharePoint Online Management Shell** — no third-party tooling. Container labels are configured,
**piloted on a small ring first**, validated against pass/fail gates, and then expanded.

> **Container labels govern the container, not the files inside it.** A container label sets privacy,
> guest, sharing, and device-access behavior for the Team/Group/Site. It does **not** encrypt or classify
> the individual files — that is the job of **file/email sensitivity labels** (a separate Purview
> solution). The two are complementary and are commonly deployed together; this solution delivers the
> container half.

## Why this matters
- **The container is the perimeter.** Guest access, external sharing, and unmanaged-device download are
  decided at the container level. An unlabeled container inherits tenant defaults — which are frequently
  more permissive than the data inside warrants.
- **Creation-time defaults are sticky.** A Team created "Public with guests allowed" tends to stay that
  way for years. Labeling at (and after) creation replaces ad-hoc choices with a governed, named posture.
- **Unmanaged-device access is invisible until it's a breach.** Without a container label driving
  Conditional Access, confidential-site content is downloadable to any personal device. The label makes
  "web-only, no download" or "blocked" a property of the site, enforced automatically.
- **It is defensible and auditable.** "Every site holding sensitive project data is Private, guest-free,
  and web-only from unmanaged devices" is a statement you can evidence with a report — not a hope.

## How it works
1. **Assess.** Read the tenant's enablement state (are container labels even turned on?), the
   container-scoped labels that exist, the SharePoint external-sharing baseline, and an inventory of
   existing Teams/Groups/Sites with their current privacy, guest, sharing, and label state — read-only.
2. **Design.** Define a **container label taxonomy** (below) mapping each tier to concrete privacy,
   guest, external-sharing, and unmanaged-device settings, aligned to the data-classification intent your
   stakeholders set.
3. **Configure.** Enable container labeling for the tenant (a one-time directory setting + label sync),
   author the container labels in the Purview portal, and publish them to users via a label policy.
4. **Pilot.** Apply the labels to a **pilot ring** of a few named Teams/Groups/Sites first, and publish
   the label policy to a **pilot user group** — never tenant-wide on day one. Container settings that
   affect guest access and device access are **high-impact**; prove them on the ring.
5. **Validate.** Confirm each piloted container carries the intended label and that privacy, guest,
   sharing, and unmanaged-device posture actually match the label's definition. Run the pass/fail gates.
6. **Expand.** Broaden the label policy to all intended users, apply labels to the wider container
   estate, optionally set a **default container label** for new containers, and hand ongoing coverage to
   operations.

## The container label taxonomy (design used throughout)
Three tiers are used consistently across the docs, scripts, and portal. Adjust names/settings to your
classification scheme — the **determination** of which data warrants which tier belongs to your
compliance/data-owner stakeholders; this solution provides the technical mapping.

| Label | Privacy | Guest access | External sharing (SharePoint) | Unmanaged-device access |
|---|---|---|---|---|
| **`Container – General`** | Private | Allowed | New and existing guests | Allow full access |
| **`Container – Confidential`** | Private | Existing guests only | Existing guests only | Allow limited, web-only access |
| **`Container – Highly Confidential`** | Private | Not allowed | Only people in your organization | Block access |

> **Unmanaged-device access (limited / blocked) requires Microsoft Entra ID P1 and SharePoint
> Conditional Access**, and is enforced through the label's SharePoint site setting. Availability is
> **licensing-dependent — verify against your own tenant and plan.** Where P1/Conditional Access is not
> available, the label still governs privacy, guest, and external-sharing settings.

## What you can control
- Whether container labeling is enabled for the tenant at all.
- The container label taxonomy: privacy, guest access, external sharing, and unmanaged-device access per
  tier.
- Which users the label policy publishes to, and whether a **default** container label applies to new
  containers.
- Which existing Teams/Groups/Sites get which label, and in what order (pilot ring → expand).

## Limitations (be honest with buyers)
- **Container labels govern the container, not the files.** No file-level encryption or classification —
  see the file/email sensitivity-labeling solution for that.
- **Enablement is a one-time, tenant-level action.** Turning on container labels sets the Entra
  `Group.Unified` directory setting (`EnableMIPLabels = True`) and syncs labels; it changes how labels
  behave org-wide, so it is piloted and change-controlled like any tenant setting.
- **Unmanaged-device and external-sharing controls are licensing-gated.** The Conditional Access
  (limited/blocked device access) settings require **Entra ID P1** and SharePoint; some behaviors depend
  on your SharePoint tenant baseline. **Verify availability against your licensing and tenant.**
- **Label creation is done in the portal.** The provided scripts **apply existing labels** to containers,
  read state, validate, and report — they do **not** author labels via `New-Label` (label authoring with
  container parameters is done in the Purview portal, per the Implementation Guide) to avoid fragile,
  hard-to-review label definitions in code.
- **The Purview portal is evolving.** Portal paths and the exact protection-settings page names change;
  they are cited as of authoring and flagged **"verify in your tenant."**
- **Classification determinations are deferred.** Which data is "Confidential" vs "Highly Confidential,"
  and who may be a guest, are decided by your compliance, data-owner, privacy, and security stakeholders —
  this solution provides the technical method and the evidence, not the determination.

## Naming convention (used in every doc and script)
| Artifact | Name |
|---|---|
| Enablement-state / container inventory export | `Container Inventory – Assess` |
| Container label taxonomy | `Container Labels – Taxonomy – Design` |
| Container label policy (publishes labels to users) | `Container Labels – Groups & Sites – Policy` |
| One-time tenant enablement record | `Container Labeling – Enablement` |
| Pilot ring (containers + users) | `Container Labels – Pilot Ring – Stage1` |
| Coverage / posture report | `Container Inventory – Report` |
| Prerequisite / health check output | `Container Scope – Map` |

## The standard deployment model
> Assess the tenant and container estate → design the label taxonomy → enable container labeling, author
> and publish the labels → apply to a pilot ring → validate every gate → expand to the estate.
> Pattern: **Assess → Design → Configure → Pilot → Validate → Expand.**


---


# 2. Requirements Guide — Container Labeling (Teams, Groups & Sites)

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-purview.md` (the six
shared requirements: compliance licensing, least-privilege Purview roles, the S&C PowerShell + Graph
toolchain, in-scope data sources, compliance/records/privacy/legal stakeholders, and a pilot scope with
change control) — those are referenced here, not repeated.

## 2.1 Sensitivity-label licensing, plus Entra ID P1 for device/sharing controls
**Description:** A tenant licensed for **sensitivity labels** (Microsoft 365 E3 includes manual
labeling; container labeling works on this baseline for privacy/guest/external-sharing), **plus
Microsoft Entra ID P1** for the **unmanaged-device access** control (limited/blocked access via
Conditional Access) and SharePoint site-level Conditional Access. (Global Requirement 1.)
**Why:** The privacy, guest, and external-sharing container settings work on the labeling baseline; the
**unmanaged-device Conditional Access** settings are gated on Entra ID P1 + SharePoint.
**Verify:** M365 admin center → `Billing → Licenses` shows the label + Entra ID P1 SKUs;
`IPCONT-Check-Prereqs.ps1` reports the label and P1 signals. Confirm the container-label scope appears in
the Purview portal.
**Implement:** Assign/purchase Entra ID P1 (or a plan that includes it) before configuring the
unmanaged-device access settings. Where P1 is unavailable, scope the labels to privacy/guest/external
sharing only and record the device-access control as deferred. **Verify against your own plan.**

## 2.2 Least-privilege roles across Purview, Entra, and SharePoint
**Description:** **Information Protection Admin** (or **Compliance Administrator**) to author and publish
container labels; a **Global Administrator** or **Groups Administrator** for the one-time
`EnableMIPLabels` directory setting; a **SharePoint Administrator** for the SharePoint tenant/site
external-sharing and Conditional Access baseline. (Global Requirement 2 — least privilege.)
**Why:** Container labeling spans three surfaces — the label (Purview), the group directory setting
(Entra), and the site sharing/CA behavior (SharePoint) — each with its own least-privilege role.
**Verify:** Purview portal → `Settings → Roles & scopes → Permissions` shows Information Protection Admin;
Entra shows the Groups/Global Admin; SharePoint admin center access confirmed. `Connect-IPPSSession`
succeeds.
**Implement:** Assign the least-privilege role on each surface; reserve Global Administrator only for the
one-time enablement and Graph admin-consent steps.

## 2.3 Security & Compliance PowerShell, Graph, and SharePoint Online toolchain
**Description:** A workstation with **ExchangeOnlineManagement** (`Connect-IPPSSession`), the
**Microsoft Graph PowerShell SDK**, the **AIPService** module (provides `Execute-AzureAdLabelSync`), and
the **Microsoft.Online.SharePoint.PowerShell** module (`Connect-SPOService`), with a modern-auth/MFA
admin. (Global Requirement 3.)
**Why:** Labels are read via S&C PowerShell; container labeling is enabled and applied via Graph; the
label sync uses AIPService; site sharing/CA state is read/set via SharePoint Online Management Shell.
**Verify:** `Get-Module -ListAvailable ExchangeOnlineManagement, Microsoft.Graph.Authentication,
AIPService, Microsoft.Online.SharePoint.PowerShell`; the connect cmdlets succeed.
`IPCONT-Check-Prereqs.ps1` reports which modules/connections are present.
**Implement:** `Install-Module ExchangeOnlineManagement, Microsoft.Graph, AIPService,
Microsoft.Online.SharePoint.PowerShell -Scope CurrentUser`; confirm modern-auth sign-in.

## 2.4 Graph permission scopes (read-first; write only to apply)
**Description:** Delegated Graph scopes — **read** for discovery/validation/reporting
(`Group.Read.All`, `Directory.Read.All`, `Sites.Read.All`, `InformationProtectionPolicy.Read`), and
**write** only for the enablement/apply steps (`Directory.ReadWrite.All` for the `Group.Unified`
directory setting, `Group.ReadWrite.All` to set a group's `assignedLabels`).
**Why:** The safe-by-default scripts read state with read scopes; write scopes are consented only when
you enable container labeling or apply a label.
**Verify:** `IPCONT-Discover-Containers.ps1` (read-only) connects with read scopes and reports if consent
is missing; the apply script requests write scopes explicitly.
**Implement:** Consent read scopes at first `Connect-MgGraph`; a Global Administrator grants admin
consent for the write scopes once in Entra (`Identity → Applications → Enterprise applications`).

## 2.5 Container labeling **enabled** for the tenant (`EnableMIPLabels`)
**Description:** The Entra **`Group.Unified`** directory setting **`EnableMIPLabels = True`**, plus a
one-time **`Execute-AzureAdLabelSync`** so sensitivity labels are available to Groups/Teams/Sites.
**Why:** Until `EnableMIPLabels` is `True` and labels are synced, container-scoped labels **cannot be
applied** to Teams/Groups/Sites — this is the gate for everything else.
**Verify:** `IPCONT-Check-Prereqs.ps1` reads the `Group.Unified` setting and reports `EnableMIPLabels`;
in the Purview portal, the container-scope option is selectable on a label.
**Implement:** Run `IPCONT-Set-ContainerLabels.ps1 -EnablePrerequisites -Commit` (one-time; wraps the
`Group.Unified` setting update and `Execute-AzureAdLabelSync`). This is a **tenant-level change** — pilot
and change-control it. **Verify the exact method against current Microsoft guidance for your tenant** —
the directory-settings surface is evolving (legacy AzureADPreview vs Microsoft Graph).

## 2.6 Container-scoped sensitivity labels authored and published
**Description:** The container labels (`Container – General`, `Container – Confidential`,
`Container – Highly Confidential`) authored in the Purview portal with scope **Groups & sites** and their
privacy/guest/external-sharing/device settings, published via the **`Container Labels – Groups & Sites –
Policy`** label policy.
**Why:** A label must exist and be published to a user before that user can apply it to a container; the
policy is what surfaces the labels in Teams/SharePoint.
**Verify:** `Get-Label` lists the container labels; `Get-LabelPolicy` shows the policy;
`IPCONT-Check-Prereqs.ps1` confirms container-scoped labels are present. Confirm the labels appear when
creating a Team/site as a policy member.
**Implement:** Author the labels (Implementation Guide Step 3) and publish them to the pilot user group
first, then expand.

## 2.7 SharePoint external-sharing baseline compatible with the labels
**Description:** The SharePoint **tenant** external-sharing level (`Get-SPOTenant.SharingCapability`) must
be **at least as permissive** as the most permissive label setting you intend to use — a label cannot
grant sharing broader than the tenant allows.
**Why:** Container labels **tighten** sharing per site; they cannot loosen it beyond the tenant ceiling.
If the tenant is "Only people in your organization," a label's "New and existing guests" has no effect.
**Verify:** `IPCONT-Check-Prereqs.ps1` reports the tenant `SharingCapability` and
`ConditionalAccessPolicy`. Confirm it against the label taxonomy.
**Implement:** Adjust the SharePoint tenant sharing baseline (SharePoint admin, change-controlled) so the
label taxonomy is expressible; record the baseline in `Container Scope – Map`.

## 2.8 In-scope containers, data-classification intent, and stakeholders
**Description:** The **Teams/Groups/Sites in scope**, the **classification intent** that maps data
sensitivity to the three tiers, and engagement with **compliance, data-owner, privacy, security, and
legal** stakeholders (Global Requirements 4 & 5).
**Why:** Which container gets which label is a business/classification decision, and guest access has
privacy/legal implications — the determination is the stakeholders', the implementation is yours.
**Verify:** The in-scope container list and the tier mapping are agreed; named approvers recorded.
`IPCONT-Discover-Containers.ps1` produces the inventory to map against.
**Implement:** Capture the classification intent and tier mapping before applying labels.

## 2.9 A pilot ring and change control
**Description:** A **pilot ring** — `Container Labels – Pilot Ring – Stage1`: a small set of named
Teams/Groups/Sites **and** a pilot user group for the label policy — plus a **change-control** process
(Global Requirement 6).
**Why:** Guest-access, external-sharing, and device-access changes are high-impact; prove them on a ring
before the estate. Applying a "Block access from unmanaged devices" label to a busy site without piloting
will generate help-desk tickets.
**Verify:** The ring (containers + users) is defined and a change window/approval path exists.
**Implement:** Define the ring and agree change control before applying labels or enabling tenant-wide.

---
## Checklist
- [ ] Sensitivity-label licensing confirmed; Entra ID P1 available for device/sharing controls (or device control deferred)
- [ ] Information Protection Admin (Purview), Groups/Global Admin (Entra), SharePoint Admin assigned least-privilege
- [ ] ExchangeOnlineManagement + Graph SDK + AIPService + SharePoint Online Shell installed; connects succeed
- [ ] Graph read scopes consented; write scopes reserved for enable/apply
- [ ] `EnableMIPLabels = True` + `Execute-AzureAdLabelSync` done (or scheduled, pilot-first)
- [ ] Container labels authored (Groups & sites scope) and `Container Labels – Groups & Sites – Policy` published to pilot users
- [ ] SharePoint tenant `SharingCapability` compatible with the label taxonomy
- [ ] In-scope containers + tier mapping agreed; stakeholders named
- [ ] `Container Labels – Pilot Ring – Stage1` (containers + users) defined; change control agreed


---


# Global Requirements — Microsoft Purview Solutions

These requirements apply to **every** solution in the **Purview** category (implementing and managing
Microsoft Purview, sensitivity & retention labels, DLP, data lifecycle & records, insider risk,
communication compliance, audit, data security posture management, and data governance). Verify each
before starting a solution's implementation steps.

> **Vendor boundary (applies to every Purview solution).** The **Microsoft Purview portal**
> (purview.microsoft.com), the **Microsoft 365 admin center**, **Security & Compliance PowerShell**
> (`Connect-IPPSSession`), and **Microsoft Graph** are authored at exact, current click-by-click /
> cmdlet detail from Microsoft's public documentation. Microsoft Purview features are heavily
> **licensing-/plan-dependent** (many require **Microsoft 365 E5** or the **E5 Compliance** add-on;
> some are in preview) and the portal is **actively evolving** — capability availability and portal
> paths are **cited or flagged "verify your licensing/tenant"**, never asserted or invented.
> **Regulatory, records-retention, and legal determinations** (retention schedules, records file plans,
> legal holds, insider-risk case actions, regulatory applicability) are **deferred to the organization's
> compliance, records, privacy, and legal functions** — the solutions provide the technical
> configuration method and evidence, not the determination. Automation is **PowerShell** (Security &
> Compliance PowerShell / Graph) — never with hardcoded credentials or secrets.

## 1. Microsoft 365 tenant with the required Purview/compliance licensing
- **Description:** A Microsoft 365 tenant with the **compliance licensing** the capability requires
  (E3 for baseline; **E5 / E5 Compliance** for advanced DLP, auto-labeling, insider risk, communication
  compliance, Audit Premium, DSPM, etc.).
- **Why required:** Most Purview capabilities are plan-gated; the feature won't be available without the
  right plan.
- **How to verify:** In the M365 admin center confirm the subscription/add-ons; check the feature is
  visible in the Purview portal.
- **How to implement if missing:** Assign/purchase the required licensing before starting.

## 2. Purview roles (least-privilege) and portal access
- **Description:** Access with the least-privilege **Purview / compliance role** the solution names
  (e.g. Compliance Administrator, Compliance Data Administrator, Information Protection, Records
  Management, Insider Risk, eDiscovery, Audit roles), with Global Administrator only where required.
- **Why required:** Purview uses fine-grained role groups; configuration requires the matching role.
- **How to verify:** Purview portal → **Roles & scopes / Permissions** — confirm the role membership.
- **How to implement if missing:** Assign the least-privilege role group under change control.

## 3. Security & Compliance PowerShell + Graph toolchain
- **Description:** A workstation with **Security & Compliance PowerShell** (`Connect-IPPSSession` via the
  ExchangeOnlineManagement module) and **Microsoft Graph PowerShell**, modern-auth / MFA-capable admin.
- **Why required:** Configuration, automation, and the provided scripts run through these.
- **How to verify:** `Connect-IPPSSession` and `Connect-MgGraph` succeed with the admin account.
- **How to implement if missing:** Install the modules and confirm modern-auth sign-in before running steps.

## 4. Data sources & scope in scope
- **Description:** The **workloads and data sources** in scope (Exchange, SharePoint, OneDrive, Teams,
  endpoints/devices, and — for data governance — the broader data estate) and a **data-classification /
  sensitivity** intent to drive labels, DLP, and retention.
- **Why required:** Purview policies key off the in-scope workloads and the classification scheme.
- **How to verify:** Confirm the in-scope workloads and the classification/sensitivity approach with
  stakeholders.
- **How to implement if missing:** Define the scope and classification intent before authoring policies.

## 5. Compliance, records, privacy & legal stakeholders
- **Description:** Engagement with the **compliance, records-management, privacy, security, and legal**
  stakeholders whose policies the configuration must satisfy (retention schedules, records file plans,
  regulatory obligations, insider-risk and communication-compliance policy, legal hold).
- **Why required:** Purview configuration must align to enterprise policy and legal/records requirements,
  not technical defaults; several capabilities have HR/legal sensitivity.
- **How to verify:** Confirm the applicable policies, the records schedule, and named approvers.
- **How to implement if missing:** Identify the owners and capture the requirements before configuring.

## 6. A pilot scope and change control
- **Description:** A **pilot scope** (users/sites/policies in simulation or a limited ring) to validate
  on before tenant-wide enforcement, and a **change-control** process — most Purview policies support a
  **simulation / test / disabled** mode that MUST be used before enforcement.
- **Why required:** Every solution follows an **Assess → Design → Configure → Pilot (simulate) → Validate
  → Expand (enforce)** model; DLP, labels, retention, and insider-risk changes are high-impact.
- **How to verify:** Confirm a named pilot scope, that simulation/test mode is available, and a change
  window/approval path.
- **How to implement if missing:** Define the pilot and agree change control before enforcing anything.

*The deployment model across every Purview solution is the same: **Assess → Design → Configure → Pilot
(simulate/test) → Validate → Expand (enforce)**, with explicit pass/fail gates and a documented rollback.
Automation is delivered as **PowerShell** (Security & Compliance PowerShell / Graph) — never with
hardcoded credentials or secrets. Regulatory/records/legal determinations are deferred to the relevant
governance functions.*


---


# 3. Implementation Guide — Container Labeling (Teams, Groups & Sites)

Follow these steps **in order**. Work spans the **Microsoft Purview portal** (purview.microsoft.com), the
**Microsoft 365 / Entra admin centers**, **Security & Compliance PowerShell** (`Connect-IPPSSession`),
**Microsoft Graph**, and **SharePoint Online Management Shell** (`Connect-SPOService`). Writes are
previewed with `-WhatIf` before `-Commit`. Artifact names follow the convention from the Overview and are
reused verbatim.

> **Model:** Assess the tenant + container estate → design the label taxonomy → enable container
> labeling, author + publish labels → apply to a **pilot ring** (containers + users) → validate every
> gate → expand. Pattern: **Assess → Design → Configure → Pilot → Validate → Expand.**
>
> **Portal paths are cited as of authoring and the Purview portal is evolving — verify each path in your
> own tenant.** The unmanaged-device access control is **licensing-dependent (Entra ID P1) — verify
> against your plan** (Requirement 2.1). Container settings are **high-impact** (guest access, external
> sharing, device access) — pilot on the ring before the estate.

## Step 1 — Assess the tenant and container estate (Assess)
1. Run `IPCONT-Check-Prereqs.ps1 -CsvPath .\ContainerScope.csv`. Read-only, it reports: the
   `Group.Unified` `EnableMIPLabels` state, whether container-scoped labels exist, the SharePoint tenant
   `SharingCapability` and `ConditionalAccessPolicy` baseline, Entra ID P1 signal, and module/connection
   health. It writes `Container Scope – Map`.
2. Run `IPCONT-Discover-Containers.ps1 -CsvPath .\ContainerInventory.csv`. Read-only, it enumerates every
   M365 Group/Team and SharePoint site with its current **privacy**, **guest-allowed**, **external
   sharing**, and **assigned sensitivity label**, flagging unlabeled containers. It writes
   `Container Inventory – Assess`.
3. **Pass/fail:** you have a complete inventory of containers with current posture, and you know whether
   container labeling is enabled and whether the tenant sharing baseline supports your intended taxonomy.

## Step 2 — Design the container label taxonomy (Design)
1. Build `Container Labels – Taxonomy – Design` — the three tiers and their exact settings:

   | Label | Privacy | Guest access | External sharing | Unmanaged-device access |
   |---|---|---|---|---|
   | `Container – General` | Private | Allowed | New and existing guests | Allow full access |
   | `Container – Confidential` | Private | Existing guests only | Existing guests only | Allow limited, web-only access |
   | `Container – Highly Confidential` | Private | Not allowed | Only people in your organization | Block access |

2. Map each in-scope container to a tier with your **data-owner/compliance stakeholders** — the tier
   assignment is their determination; you implement it. Record the mapping in the inventory.
3. **Pass/fail:** every in-scope container has an agreed target tier, and each tier's settings are
   expressible under the tenant sharing baseline and licensing (device-access needs Entra ID P1).

## Step 3 — Enable container labeling and author + publish the labels (Configure)
1. **Enable container labeling (one-time, tenant-level).** Dry-run first:
   `IPCONT-Set-ContainerLabels.ps1 -EnablePrerequisites -WhatIf` — it shows it would set the
   `Group.Unified` directory setting `EnableMIPLabels = True` and run `Execute-AzureAdLabelSync`. Apply
   with `-EnablePrerequisites -Commit` (Global/Groups Admin). Writes `Container Labeling – Enablement`.
   **Verify the current enablement method against Microsoft guidance for your tenant** — the
   directory-settings surface is evolving.
2. **Author the labels in the Purview portal** → `Information protection → Labels → Create a label`
   (verify path). For each tier, on the **Scope** page select **Groups & sites**, then on the protection
   pages set:
   - **Privacy and external user access** → Privacy = **Private**; "Let group owners add people outside
     the org as guests" = per tier (`General`: on; `Confidential`: existing only; `Highly Confidential`:
     off).
   - **External sharing and device access** (name varies — verify) → external sharing per tier; and
     **"Use Conditional Access to protect labeled SharePoint sites"** → `General`: full access;
     `Confidential`: **limited, web-only access**; `Highly Confidential`: **block access**. The
     device-access options require **Entra ID P1** — verify.
3. **Publish the labels.** Create the label policy **`Container Labels – Groups & Sites – Policy`** →
   include the three container labels → publish to the **pilot user group** first (not all users).
   Optionally set the policy's **default label for containers** to `Container – General` so new
   containers are governed by default. Confirm with `Get-Label` / `Get-LabelPolicy`.
4. **Pass/fail:** `EnableMIPLabels` reports `True`; the three container labels exist with Groups & sites
   scope; the policy is published to the pilot users; the labels appear when a pilot user creates a
   Team/site.

## Step 4 — Apply labels to the pilot ring (Configure, pilot-first)
1. Prepare a targets CSV (`ContainerName`, `Identity` [group id or site URL], `Label`) for the
   `Container Labels – Pilot Ring – Stage1` containers.
2. Dry-run: `IPCONT-Set-ContainerLabels.ps1 -TargetsPath .\PilotTargets.csv -WhatIf`. With `-WhatIf` (the
   default) it makes **no changes** — it prints, per container, the label it *would* apply (groups via
   Graph `assignedLabels`, sites via `Set-SPOSite -SensitivityLabel`) and the exact **reverse** command.
3. Read every line against the taxonomy and the pilot ring. Apply with `-TargetsPath .\PilotTargets.csv
   -Commit`. Only the pilot-ring containers are touched.
4. **Pass/fail + rollback:** each pilot container reports the intended label; privacy/guest/sharing
   change to match. Rollback = re-apply the prior label (or clear it) with the reverse command the script
   prints for each change.

## Step 5 — Validate the pilot ring (Pilot → Validate)
1. Run `IPCONT-Validate-ContainerLabels.ps1 -TargetsPath .\PilotTargets.csv`. Read-only, it confirms each
   target carries the intended label **and** that privacy, guest access, external sharing, and (where P1)
   unmanaged-device posture match the label's definition — pass/fail per container.
2. Have a pilot owner confirm real behavior: a Private/guest-free `Highly Confidential` Team rejects an
   external invite; a `Confidential` site opens **web-only** from an unmanaged device (no download).
3. Complete the **Testing Guide** on the ring. **Pass/fail:** all Testing-Guide gates pass on
   `Container Labels – Pilot Ring – Stage1`.

## Step 6 — Expand to the estate (Expand)
1. Broaden `Container Labels – Groups & Sites – Policy` from the pilot user group to all intended users
   (portal). Confirm the labels surface at container creation tenant-wide.
2. Apply labels to the wider container estate in waves: build the full targets CSV from the inventory,
   dry-run `-WhatIf`, review, `-Commit` per wave. Re-run `IPCONT-Validate-ContainerLabels.ps1` after each
   wave.
3. Run `IPCONT-Report-ContainerLabeling.ps1 -CsvPath .\ContainerReport.csv` to produce
   `Container Inventory – Report` — the coverage percentage and posture across all containers — as the
   management evidence artifact, and re-run it on a schedule to keep coverage healthy.
4. **Pass/fail:** coverage of in-scope containers meets the agreed target; the report shows privacy,
   guest, sharing, and device posture matching each container's assigned tier.

---
### Order of operations
`Assess tenant + estate → design taxonomy → enable container labeling (EnableMIPLabels + sync) → author
labels (Groups & sites) → publish policy to pilot users → apply labels to pilot ring (-WhatIf then
-Commit) → validate ring → expand policy + apply in waves → report coverage`


---


# 5. Testing Guide — Container Labeling (Teams, Groups & Sites)

Run after each configuration step. Every test is safe (read-only or a `-WhatIf` preview) except where it
asks you to observe real behavior in a labeled container. Validate on the
`Container Labels – Pilot Ring – Stage1` before treating the tenant as production-ready.

## Test 1 — Prerequisites and enablement are in place
**Do:** Run `IPCONT-Check-Prereqs.ps1`.
**Expected:** `EnableMIPLabels` reports `True`; container-scoped labels exist; the SharePoint tenant
`SharingCapability`/`ConditionalAccessPolicy` baseline is reported and is compatible with the taxonomy;
the required modules/connections are healthy. Any gap (e.g. P1 missing → device-access deferred) is
recorded, not guessed.

## Test 2 — Discovery inventory is complete and accurate
**Do:** Run `IPCONT-Discover-Containers.ps1`; spot-check a few containers in the Teams/SharePoint admin
centers.
**Expected:** Every M365 Group/Team and site is listed with its current privacy, guest-allowed, external
sharing, and assigned label; unlabeled containers are flagged. The spot-checks match.

## Test 3 — Enablement dry-run makes no changes
**Do:** Run `IPCONT-Set-ContainerLabels.ps1 -EnablePrerequisites -WhatIf`.
**Expected:** It states it *would* set `EnableMIPLabels = True` and run `Execute-AzureAdLabelSync` — and
changes nothing. Re-reading the `Group.Unified` setting shows it unchanged until `-Commit`.

## Test 4 — Labels exist with Groups & sites scope and are published
**Do:** Run `Get-Label | Where-Object {$_.ContentType -match 'Site' -or $_.DisplayName -like 'Container*'}`
and `Get-LabelPolicy`; as a pilot user, start creating a new Team/site.
**Expected:** The three container labels exist with the Groups & sites scope; `Container Labels – Groups &
Sites – Policy` is published to the pilot users; the labels appear in the container-creation UI for a
policy member and **not** for a non-member.

## Test 5 — Apply dry-run makes no changes and prints reverse commands
**Do:** Run `IPCONT-Set-ContainerLabels.ps1 -TargetsPath .\PilotTargets.csv -WhatIf`; afterward re-run
`IPCONT-Discover-Containers.ps1` on a target.
**Expected:** The dry-run lists the label it *would* apply per container plus the exact reverse command;
the target's assigned label is unchanged — `-WhatIf` truly changed nothing.

## Test 6 — Labels apply and the container posture matches the tier
**Do:** After `-Commit` on the pilot ring, run `IPCONT-Validate-ContainerLabels.ps1 -TargetsPath
.\PilotTargets.csv`.
**Expected:** Each target carries the intended label, and privacy, guest access, and external sharing
match the tier definition (e.g. `Highly Confidential` → Private, guests not allowed, org-only sharing).

## Test 7 — Guest access is governed by the label
**Do:** As an owner of a `Container – Highly Confidential` Team/Group, attempt to add an external guest.
**Expected:** The invite is blocked (guests not allowed by the label). On a `Container – General`
container the same action succeeds — the label, not the tenant default, is deciding.

## Test 8 — Unmanaged-device access is enforced (where Entra ID P1 applies)
**Do:** From a device that is **not** compliant/domain-joined, open a `Container – Confidential` site,
then a `Container – Highly Confidential` site.
**Expected:** `Confidential` opens **web-only** (no download/print/sync); `Highly Confidential` is
**blocked**. `General` opens with full access. (If P1/Conditional Access is not licensed, this test is
recorded as deferred, not failed.)

## Test 9 — Coverage report reflects reality
**Do:** Run `IPCONT-Report-ContainerLabeling.ps1`; review `Container Inventory – Report`.
**Expected:** The report shows the coverage percentage of in-scope containers and, per container, the
assigned tier and actual privacy/guest/sharing/device posture — matching what Tests 6–8 observed.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–9 pass on `Container Labels – Pilot Ring – Stage1`: prerequisites/enablement confirmed, inventory accurate, labels published, apply is safe + reversible, applied posture matches each tier, guest + device controls enforced (device where P1 applies) |
| **Expand pass** | Tests 5–6 and 9 pass again after each expansion wave, with coverage of in-scope containers meeting the agreed target and no container's posture drifting from its assigned tier |


---


# 6. Troubleshooting Guide — Container Labeling (Teams, Groups & Sites)

Field issues and how to resolve them, in the order you are likely to hit them. Every check here is safe.

## The container-label scope ("Groups & sites") isn't selectable on a label
**Symptom:** When creating/editing a sensitivity label, the **Groups & sites** scope is greyed out or the
protection settings never apply to containers.
**Cause:** Container labeling isn't enabled for the tenant — the `Group.Unified` directory setting
`EnableMIPLabels` is not `True`, or labels haven't been synced.
**Fix:** Run `IPCONT-Check-Prereqs.ps1` and read the `EnableMIPLabels` line. Enable with
`IPCONT-Set-ContainerLabels.ps1 -EnablePrerequisites -Commit` (Global/Groups Admin) — it sets the setting
and runs `Execute-AzureAdLabelSync`. **Verify the current enablement method against Microsoft guidance for
your tenant** — the directory-settings surface is evolving (legacy AzureADPreview vs Microsoft Graph).

## `Execute-AzureAdLabelSync` isn't recognized / the sync step warns
**Symptom:** The enablement `-Commit` prints a warning on the label-sync step, or the cmdlet is missing.
**Cause:** The **AIPService** module isn't installed, or `Connect-AIPService` didn't complete.
**Fix:** `Install-Module AIPService -Scope CurrentUser -Force`; run `Connect-AIPService` then
`Execute-AzureAdLabelSync`. The setting change (`EnableMIPLabels`) is the gating action; the sync makes
labels available faster. Verify AIPService availability/guidance for your tenant.

## A published container label doesn't appear when creating a Team/site
**Symptom:** A pilot user creates a Team/site but sees no container labels (or not the expected one).
**Cause:** The label policy isn't published to that user, the label lacks the **Groups & sites** scope,
or label sync hasn't propagated yet.
**Fix:** Confirm `Container Labels – Groups & Sites – Policy` includes the user (`Get-LabelPolicy`), that
the label has container scope (`Get-Label`), and allow time for propagation. A non-member correctly sees
nothing — that is the policy gating access, not a bug.

## Applying a label to a group fails with "insufficient privileges" (403)
**Symptom:** `IPCONT-Set-ContainerLabels.ps1 -Commit` errors PATCHing a group's `assignedLabels`.
**Cause:** The delegated Graph write scope wasn't consented — `Group.ReadWrite.All` (and
`Directory.ReadWrite.All` for the enablement step).
**Fix:** Re-run `Connect-MgGraph` with the scopes in the script header and consent; if admin consent is
required, a Global Administrator approves them once in Entra → Enterprise applications. Discovery and
validation need **read** scopes only.

## `[MISSING LABEL]` — the label name isn't found in the catalog
**Symptom:** The apply script reports the target label isn't in the published catalog.
**Cause:** The label isn't published to the running account, or the display name in the targets CSV
doesn't match the label exactly.
**Fix:** Run `Get-Label` / `IPCONT-Check-Prereqs.ps1` to see the exact published label names; correct the
CSV `Label` column. The label must be **published** (in a label policy) to be resolvable.

## A site label applied but external sharing didn't actually tighten
**Symptom:** A `Container – Highly Confidential` site still allows guest sharing.
**Cause:** The **SharePoint tenant** `SharingCapability` ceiling, or the label can only *tighten* sharing
— it can't exceed the tenant, and per-site sharing can be overridden. Or propagation lag.
**Fix:** Confirm the tenant baseline with `IPCONT-Check-Prereqs.ps1`; remember a label **tightens**, so a
tenant already at "Only people in your organization" makes a broader label setting a no-op. Verify the
per-site sharing with `Get-SPOSite -Detailed`. Allow time for the setting to apply.

## Unmanaged-device access isn't limited/blocked as the label says
**Symptom:** A `Container – Confidential` site downloads fine from an unmanaged device.
**Cause:** The unmanaged-device (Conditional Access) control requires **Entra ID P1** and SharePoint
Conditional Access; without P1 the label's device setting has no enforcement. Or the tenant/site
`ConditionalAccessPolicy` isn't set to limited/block.
**Fix:** Run `IPCONT-Check-Prereqs.ps1` — if `AAD_PREMIUM` isn't detected, record the device control as
**deferred (not licensed)** and scope the label to privacy/guest/external-sharing. Where P1 exists, verify
the SharePoint `ConditionalAccessPolicy` and the label's device-access setting. **Verify against your
plan.**

## Guest was still addable to a "no guests" container
**Symptom:** An owner added an external guest to a `Container – Highly Confidential` Group.
**Cause:** The label wasn't actually applied to that container, the guest setting on the label isn't
"not allowed," or the tenant-level B2B/guest policy is overriding. Propagation lag is also possible.
**Fix:** Validate with `IPCONT-Validate-ContainerLabels.ps1` that the container carries the label and
privacy is `Private`; confirm the label's guest setting; check the Entra external-collaboration settings
aren't contradicting. Re-test after propagation.

## `Connect-SPOService` fails or sites aren't enumerated
**Symptom:** The discovery/report/validate scripts skip SharePoint sites.
**Cause:** `-SPOAdminUrl` wasn't supplied, the **Microsoft.Online.SharePoint.PowerShell** module is
missing, or the account lacks SharePoint Administrator.
**Fix:** Install the module, pass `-SPOAdminUrl https://<tenant>-admin.sharepoint.com`, and connect as a
SharePoint Administrator. Group/Team data still comes from Graph without SPO — only site-level sharing
requires the SPO connection.

## Validation reports FAIL "label != expected" right after applying
**Symptom:** `IPCONT-Validate-ContainerLabels.ps1` shows the old/empty label just after `-Commit`.
**Cause:** Label assignment to a container can take time to propagate across Graph/SharePoint.
**Fix:** Wait and re-run validation. If it persists, re-check the apply output for an error and confirm
the label is published and the target identity (group id / site URL) is correct.

---
### When to stop and escalate
- A required control is **not licensed** (e.g. Entra ID P1 for device access) and the plan can't change →
  record it as deferred and scope the labels to what you have; do not assume the control is active.
- A **classification/guest determination** is being asked of you (which data is "Highly Confidential,"
  who may be a guest) → escalate to compliance, data-owner, privacy, or legal. This solution provides the
  technical method and evidence, not the determination.
- A portal path or protection-settings page name **doesn't match your tenant** → the Purview portal is
  actively evolving; verify the current path in your tenant before assuming the guide is wrong about the
  *step*.


---


# 7. Best Practices — Container Labeling (Teams, Groups & Sites)

- **Govern the container and the file — they are complementary, not either/or.** Container labels set
  privacy, guest, sharing, and device access for the Team/Group/Site; file/email labels classify and
  encrypt the content inside. Deploy container labeling knowing it is the perimeter half; pair it with
  file labeling for defense in depth.
- **Enable container labeling once, deliberately, and pilot it.** Setting `EnableMIPLabels = True` and
  running the label sync is a tenant-level change to how labels behave org-wide. Dry-run it, apply it in
  a change window, and verify the enablement method against current Microsoft guidance — the
  directory-settings surface is evolving.
- **Design the taxonomy before you touch a container.** Three clear tiers (General / Confidential /
  Highly Confidential) with explicit privacy/guest/sharing/device settings beat a sprawl of one-off
  labels. Fewer, well-understood tiers are adopted; many overlapping ones are ignored.
- **Set a default container label so new containers are governed from birth.** A default label on the
  policy (e.g. `Container – General`) means a newly created Team/site is never fully ungoverned — the
  common failure mode this solution exists to prevent.
- **Pilot guest and device controls on a ring first — they generate tickets when wrong.** "Block access
  from unmanaged devices" or "no guests" applied to a busy site without piloting will surprise users.
  Prove behavior on a handful of named containers and pilot users before the estate.
- **Always dry-run applies.** Run the apply script with `-WhatIf` and read every line before `-Commit`;
  it prints the exact reverse command per container so rollback is trivial.
- **Respect the SharePoint tenant sharing ceiling.** A container label can only **tighten** sharing, not
  loosen it beyond the tenant `SharingCapability`. Confirm the tenant baseline supports the taxonomy, or
  the "New and existing guests" tier will silently do nothing.
- **Verify the unmanaged-device control against your licensing.** The limited/blocked device-access
  settings require **Entra ID P1** and SharePoint Conditional Access. Where P1 is absent, scope the
  labels to privacy/guest/external-sharing and record the device control as deferred — don't assume it
  is active.
- **Report coverage on a schedule and treat drift as an incident.** Re-run the reporting script
  regularly; an in-scope container that lost its label or drifted from its tier is a governance gap to
  close, not a cosmetic issue.
- **Apply labels with PowerShell for scale, the portal for authoring.** Author labels (with their
  container settings) in the Purview portal where they are reviewable; apply them across many containers
  with the provided scripts. Don't hand-edit label definitions in code.
- **Keep the tier determination with the business.** Which data is Confidential vs Highly Confidential,
  and who may be a guest, are compliance/data-owner/privacy/legal decisions. You provide the technical
  mapping and the evidence; they own the determination.
- **Treat portal paths as provisional.** The Purview portal and the protection-settings page names are
  actively changing — verify each path in your tenant rather than trusting a screenshot from last
  quarter.


---


# 8. Deliverables Summary — Container Labeling (Teams, Groups & Sites)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | Container sensitivity labels for Teams/Groups/Sites — privacy, guest access, external sharing, and unmanaged-device access; the three-tier taxonomy; the phased model; limitations; naming convention |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing (label + Entra ID P1 licensing, Purview/Entra/SharePoint roles, S&C PowerShell + Graph + AIPService + SPO toolchain, `EnableMIPLabels` enablement, published labels, sharing baseline) |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered portal + PowerShell + Graph + SPO steps: assess, design taxonomy, enable container labeling, author + publish labels, apply pilot-first, validate, expand |
| 5. Testing Guide | Validation procedures with pass/fail gates, including guest and unmanaged-device behavior |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `IPCONT-Discover-Containers.ps1` | **Discovery** — read-only inventory of every M365 Group/Team and SharePoint site with current privacy, guest-allowed, external sharing, and assigned sensitivity label; flags unlabeled containers. Writes `Container Inventory – Assess` |
| `IPCONT-Set-ContainerLabels.ps1` | **Configuration/Remediation** — `-WhatIf` by default, `-Commit` to apply. `-EnablePrerequisites` performs the one-time tenant enablement (`Group.Unified` `EnableMIPLabels = True` + `Execute-AzureAdLabelSync`); with a targets CSV it applies a named container label to groups (Graph `assignedLabels`) and sites (`Set-SPOSite -SensitivityLabel`), printing the reverse command per change. Pilot-first |
| `IPCONT-Validate-ContainerLabels.ps1` | **Validation** — read-only pass/fail: confirms each target carries the intended label and that privacy, guest access, external sharing, and (where P1) unmanaged-device posture match the label's tier |
| `IPCONT-Report-ContainerLabeling.ps1` | **Reporting** — read-only coverage/posture export across all containers (labeled %, per-container tier and actual privacy/guest/sharing state). Writes `Container Inventory – Report` |
| `IPCONT-Check-Prereqs.ps1` | **Scope/health helper** — read-only: reports `EnableMIPLabels`, presence of container-scoped labels, SharePoint tenant `SharingCapability`/`ConditionalAccessPolicy` baseline, Entra ID P1 signal, and module/connection health. Writes `Container Scope – Map` |

All scripts are **safe by default** — read-only, or a `-WhatIf` preview requiring an explicit `-Commit`
to change anything. No credentials or secrets are stored in code; every script uses interactive
modern-auth (`Connect-IPPSSession` / `Connect-MgGraph` / `Connect-SPOService` / `Connect-AIPService`).

## What the buyer receives
- This implementation guide as a **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the model: **Assess → Design → Configure → Pilot → Validate → Expand.**

## Outcome
Teams, Groups, and SharePoint sites governed at the container level — privacy, guest access, external
sharing, and unmanaged-device access set by a named sensitivity label, piloted on a ring, validated
against pass/fail gates, and reported for coverage — so the container is protected, not just the file
inside it, and the posture is defensible and evidenced.
