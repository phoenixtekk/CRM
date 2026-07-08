# Office & PDF Rights Protection (RMS/IRM) — Microsoft Purview

> **Version 1.0.0** · Category: Purview · Solution code: IPRMS

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Office & PDF Rights Protection (RMS/IRM), Microsoft Purview

## The problem
Most data controls stop at the perimeter. DLP inspects at egress and conditional access gates the app,
but the moment a sensitive document is forwarded, copied to a USB stick, or exported to PDF and shared,
it is a plain file that anyone can open. Perimeter-only protection leaves no control that travels **with
the content** — and PDF exports, where so much sensitive data ends up, are frequently the widest gap.
Left unaddressed, this is a compliance gap and a data-risk exposure: a single over-shared file is
readable by anyone who receives it.

## The solution
A complete, self-guided configuration of **label-based encryption and usage rights** for Office
documents and PDFs — the capability historically called Azure Rights Management (RMS) / Information
Rights Management (IRM), now delivered through Microsoft Purview sensitivity labels. Protection is
embedded in the file: the content is encrypted and carries an enforced policy for **who can open it and
what they can do** (view, edit, copy, print, forward). It configures a small set of **protection
labels** — a template-based internal grant, a user-driven Do-Not-Forward / Encrypt-Only label, and a
named-recipient view-only label — with offline-access and content-expiry, covering **Office and PDF**,
piloted on a ring and validated before it touches everyone. It uses only the Microsoft Purview portal,
Security & Compliance PowerShell, and the AIPService module — no third-party tooling.

## How it works
The engagement follows one disciplined model: **Assess → Design → Configure → Pilot → Validate →
Expand.** Assess whether the Rights Management service is activated and the current label-encryption
posture; confirm the **super-user recovery** path so encrypted content is never unrecoverable; design
the per-label usage rights with the accountable owner; configure encryption on the labels and publish
them to a **pilot ring only**; validate that the right people open Office and PDF files with the right
rights, the wrong people are denied, and recovery works; then expand to the broad policy. Because label
encryption has **no simulation mode**, the pilot ring is the safety mechanism — every write is previewed
with `-WhatIf` first. Five PowerShell tools — read-only or `-WhatIf` by default — automate discovery,
label-protection configuration, effective-settings validation, posture reporting, and a readiness/health
check.

## What is delivered
- Six implementation documents (Overview, Requirements, Implementation, Testing, Best Practices, Troubleshooting) plus this summary.
- Five PowerShell tools: posture assessment, a label-protection configuration/remediation helper (template rights, user-defined DNF/Encrypt-Only, offline/expiry, publish, remove-protection rollback), effective-settings validation, posture-matrix reporting, and a readiness/health helper.
- A named, gated, reversible rollout with a confirmed recovery path and explicit pass/fail criteria at every step.

## Business outcome
Persistent protection that **survives sharing** — sensitive Office documents and PDF exports stay
encrypted and rights-controlled wherever they travel, with a confirmed recovery path for records and
legal. The protection is configured, piloted, validated, and defensible — at a fraction of the cost of
a bespoke consulting engagement.

## Important boundaries
*Who* may access what, the content-expiry rules, and how encrypted content is preserved and produced for
legal-hold and eDiscovery are **determinations owned by your compliance, security, records, and legal
functions** — this solution provides the technical configuration method, the super-user recovery method,
and evidence, not the determination. The label taxonomy is assumed to exist; Double Key Encryption and
HYOK are separate builds. Label encryption, protected-PDF handling, and external sharing are
**licensing-/tenant-/reader-dependent** and the Purview portal is evolving — availability, portal paths,
and cmdlet/advanced-setting keys are flagged "verify your licensing/tenant," never assumed or invented.


---


# 1. Solution Overview — Office & PDF Rights Protection (RMS/IRM), Microsoft Purview

## What this solution is
Most data controls stop at the perimeter: DLP inspects at egress, conditional access gates the app,
but once a document leaves the tenant it is a plain file. **Rights protection** — the encryption and
usage-rights engine historically called **Azure Rights Management (RMS)** / **Information Rights
Management (IRM)**, now delivered through **Microsoft Purview sensitivity-label encryption** — attaches
**persistent protection to the file itself**: the content is encrypted and carries an embedded policy
that says *who* can open it and *what* they can do (view, edit, copy, print, reply/forward). That
protection travels with the file to a USB stick, a personal inbox, or a partner's laptop.

This solution configures **label-based encryption and usage rights for Office documents and PDFs** —
so protection travels with the file — using the Microsoft Purview portal and Security & Compliance
PowerShell. It confirms the **Rights Management service is activated**, designs a small set of
**protection labels** (an encrypt-only / Do-Not-Forward nudge, a template-based "all employees" grant,
and a **named-recipient** custom grant), configures each label's **encryption, usage rights, offline
access, and content-expiry**, ensures **Office and PDF** files inherit that protection, pilots on a
small ring first, validates that the right people can open files and the wrong people cannot, then
expands.

## Why this matters
- **Protection that survives sharing.** Encryption + usage rights are embedded in the file, so an
  over-shared, forwarded, or exfiltrated document is still unreadable to anyone outside the grant.
- **Usage rights, not just encryption.** Beyond "can they open it", rights control **print, copy,
  edit, and forward** — so a viewer can read but not extract, and a partner can comment but not save a
  clear copy.
- **PDF is a first-class citizen.** So much sensitive content is exported to PDF (statements,
  contracts, reports); label-based protection covers **protected PDFs**, closing a common gap where
  Office files were protected but their PDF exports were not.
- **Revocable and time-boxed.** Content expiry and offline-access limits mean access can lapse
  automatically; super-users and revocation give records/legal a recovery and takedown path.
- **The evidence trail.** Protection state per label — encryption on, rights defined, expiry set — is
  exportable as evidence that persistent protection is actually configured, not merely intended.

## What "rights protection" configures (the levers)
| Lever | What it does | Where it is set |
|---|---|---|
| **RMS/Rights Management activation** | The tenant-level encryption service that issues and enforces use licenses | M365 admin center / `AIPService` PowerShell — must be **Activated** |
| **Label encryption** | Turns a sensitivity label into a protection label (content is encrypted on apply) | The **label's** encryption settings (`Set-Label -EncryptionEnabled`) |
| **Usage rights** | Who can do what: view / edit / copy / print / reply / forward / full control | Label encryption: **assigned permissions** (template) or **user-defined** |
| **Do Not Forward / Encrypt-Only** | User-driven protections for email (DNF) and files (encrypt-only, user picks recipients) | Label set to **user-defined** permissions (`EncryptionDoNotForward` / `EncryptionPromptUser`) |
| **Offline access & content expiry** | How long a use license is valid offline, and whether access lapses on a date/after N days | Label encryption (`EncryptionOfflineAccessDays`, `EncryptionContentExpiredOnDateInDaysOrNever`) |
| **Office & PDF coverage** | Office apps and protected-PDF handling apply and honor the encryption | Office apps + tenant/SharePoint-OneDrive settings for labeled PDFs |

> **Assigned (template) vs user-defined permissions is the core design choice.** *Assigned* permissions
> bake a fixed grant into the label (e.g. "All employees can view+edit; nobody else"). *User-defined*
> permissions let the user choose recipients at protect time (Do Not Forward for mail, encrypt-only for
> files). Most designs use **both**: template labels for known audiences, user-defined labels for
> ad-hoc protection.

## Protection-label design (the starting point — confirm with your governance owners)
> A **technical starting point**; the final grants (who, what rights, expiry) are an
> information-governance / legal determination — confirm with the accountable owner. Names here are
> reused verbatim across the docs and scripts.

| Label | Protection type | Usage rights (starting point) | Typical use |
|---|---|---|---|
| `Confidential \ All Employees` | **Assigned (template)** | All authenticated org users: **Co-Author** (view, edit, print, copy); no rights to externals | Internal-only sensitive content |
| `Confidential \ Recipients Only` | **User-defined** (Encrypt-Only / Do Not Forward) | User picks recipients at protect time; recipients get view/edit but **cannot forward** | Ad-hoc sensitive mail/files |
| `Highly Confidential \ Named Recipients` | **Assigned (template)** | A **named group** only, **Viewer** rights (view, no print/copy/edit); externals by explicit address | Board / M&A / regulated data |

## Naming convention (used in every doc and script)
| Artifact | Name |
|---|---|
| Protection label — template, internal | `Confidential \ All Employees` |
| Protection label — user-defined | `Confidential \ Recipients Only` |
| Protection label — named recipients | `Highly Confidential \ Named Recipients` |
| Label policy (pilot) | `RMSPolicy – Pilot – Ring1` |
| Label policy (broad) | `RMSPolicy – Broad – AllUsers` |
| Pilot ring group | `grp-rms-pilot@contoso.com` |
| Named-recipient group | `grp-rms-named-recipients@contoso.com` |
| RMS super-user group (recovery) | `grp-rms-superusers@contoso.com` |

## What you can control
- **Which labels encrypt**, and whether each uses **assigned** (fixed grant) or **user-defined** rights.
- **The exact usage rights** per audience (view / edit / copy / print / reply / forward / full control).
- **Offline-access window** and **content expiry** per label.
- **Office and PDF coverage** — that protected PDFs open for the right people in supported readers.
- **Recovery** — the super-user group so records/legal can always open protected content.
- **Rollout order** — pilot ring → broad — and rollback (remove protection from a label / unpublish).

## Limitations (be honest with buyers)
- **Encryption is high-impact and mostly not "simulatable".** Applying encryption to a label changes how
  every file with that label opens. There is **no service-side simulation** for label encryption — the
  safe mechanism is a **pilot label policy scoped to a pilot ring**, validated before broad publish. This
  solution enforces pilot-first for exactly that reason, and starts encryption **off/unpublished**.
- **RMS must be activated first.** If the Rights Management service is not **Activated**, no label
  encryption works. This solution verifies activation before configuring labels.
- **Reader/app support matters.** Protected Office files open in current Office apps; **protected PDFs**
  open in Microsoft Edge and readers with Microsoft Information Protection support — **verify your PDF
  reader/tenant support**; older or third-party readers may not honor protection.
- **External recipients need an identity.** A recipient outside the tenant must authenticate (org
  account, Microsoft account, or a one-time passcode where supported) to obtain a use license — **verify
  the current external-sharing options for your tenant**.
- **Double Key Encryption (DKE) and HYOK are out of scope.** This solution covers cloud-based RMS label
  encryption; DKE/HYOK are separate builds.
- **Determinations are deferred.** *Who* may access what, retention/records implications of encrypted
  content, and legal-hold/eDiscovery handling of encrypted files are **governance/legal determinations**
  — this solution provides the configuration method and evidence.

## The standard deployment model
> Assess RMS activation and current label-encryption posture → design the protection labels and usage
> rights (assigned vs user-defined, expiry, offline) → configure on a **pilot label policy scoped to a
> pilot ring** (`-WhatIf` → commit), encryption unpublished until validated → validate that the right
> people can open Office and PDF files and the wrong people cannot → **expand** to the broad policy →
> validate → operate (recovery, revocation, evidence).
> Pattern: **Assess → Design → Configure → Pilot → Validate → Expand.**


---


# 2. Requirements Guide — Office & PDF Rights Protection (RMS/IRM), Microsoft Purview

Verify **every** requirement below before starting the Implementation Guide. These are the
**solution-specific** prerequisites for configuring label-based encryption and usage rights for Office
and PDF; they build on the shared **Global Requirements — Microsoft Purview Solutions** (licensing,
least-privilege roles, Security & Compliance PowerShell + Graph toolchain, in-scope workloads,
compliance/records/legal stakeholders, and a pilot scope with change control). Read the Global
Requirements first; this guide does not repeat them.

> **Determination note.** *Who* may open protected content, *what* usage rights each audience gets,
> content-expiry rules, and how encrypted content is handled for records/legal-hold/eDiscovery are
> **information-governance and legal determinations** owned by your compliance/security/records/legal
> stakeholders — not technical defaults. This solution provides the **configuration method and
> evidence**; confirm the protection intent with the accountable owner before enforcing.

---

## 2.1 A published sensitivity-label taxonomy already exists
- **Description:** This solution turns specific labels into **protection (encryption) labels**; the
  **labels themselves** must already exist (e.g. `Confidential`, `Highly Confidential`, and the
  sublabels this solution names). If the taxonomy does not exist, build it first (the labels/taxonomy
  solution) — you cannot enable encryption on a label that does not exist.
- **Why required:** `Set-Label` encryption settings target existing labels by name/GUID.
- **How to verify:** `Get-Label | Format-Table DisplayName,Name,Priority` returns the intended
  taxonomy; the labels appear in Purview → **Information Protection → Sensitivity labels**.
- **How to implement if missing:** Create the taxonomy first; return here once the labels exist.

## 2.2 Licensing for sensitivity labeling with encryption
- **Description:** Sensitivity labels with **encryption / Rights Management protection** are included in
  Microsoft 365 plans that carry **Azure Information Protection Plan 1 / MIP** (broadly, Microsoft 365
  **E3** covers manual labeling with protection; **E5 / E5 Compliance** adds automatic/recommended
  client-side classification and advanced capabilities). Encrypted content also requires the **Rights
  Management service** to be available on the tenant. **Verify your licensing/tenant** — Microsoft's
  licensing tables are the authority; do not assume a capability is included.
- **Why required:** Label encryption will not apply/enforce without the plan that includes protection.
- **How to verify:** M365 admin center → subscriptions/add-ons; confirm the label's **Encryption** page
  is available in the Purview portal; confirm the RMS/Rights Management service state (see 2.5).
- **How to implement if missing:** Assign/purchase the required plan for the pilot users before
  enabling label encryption.

## 2.3 Information Protection role (least privilege)
- **Description:** The Purview role this solution needs is **Information Protection Admin** (create/manage
  sensitivity labels, their **encryption** settings, and label policies). For **RMS service activation
  and super-user** operations you additionally need a role that can run the **AIPService** cmdlets
  (typically **Global Administrator** or a delegated RMS admin) — reserve this for a minimal named group.
- **Why required:** `Set-Label` encryption cmdlets are gated by Information Protection Admin; RMS
  activation/super-user cmdlets (`AIPService`) require the elevated role.
- **How to verify:** Purview → **Roles & scopes → Permissions** confirms Information Protection Admin;
  confirm who holds the RMS/Global Admin role for activation.
- **How to implement if missing:** Assign the least-privilege roles under change control; keep RMS
  activation/super-user tightly held.

## 2.4 Security & Compliance PowerShell + AIPService toolchain
- **Description:** A workstation with the **ExchangeOnlineManagement** module (`Connect-IPPSSession` for
  Security & Compliance PowerShell — used for `Set-Label`/`Get-Label`), the **AIPService** module
  (`Connect-AipService` — used to read/activate the Rights Management service and manage super-users),
  and optionally **Microsoft Graph PowerShell**, all with a modern-auth / MFA-capable admin.
- **Why required:** Label encryption runs through S&C PowerShell; RMS activation/super-user and
  service-state checks run through AIPService. The provided scripts use these modules.
- **How to verify:** `Connect-IPPSSession` then `Get-Label` succeeds; `Connect-AipService` then
  `Get-AipServiceConfiguration` returns without error.
- **How to implement if missing:** `Install-Module ExchangeOnlineManagement` and `Install-Module
  AIPService` (`-Scope CurrentUser`); confirm modern-auth sign-in. See the Global Requirements.

## 2.5 The Rights Management (RMS) service is available and activated
- **Description:** Label encryption depends on the tenant's **Rights Management / Azure RMS** service
  being **Activated**. It must be turned on (M365 admin center → **Settings → Org settings →
  Microsoft Azure Information Protection**, or `Enable-AipService`) and reachable.
- **Why required:** If the service is **not activated**, applying an encryption label fails and protected
  content cannot be issued a use license.
- **How to verify:** `Get-AipServiceConfiguration` shows the functional state **Activated** (the provided
  `IPRMS-Discovery.ps1` / `IPRMS-Readiness.ps1` report it).
- **How to implement if missing:** Activate the service (`Enable-AipService`) under change control before
  configuring label encryption.

## 2.6 IRM enabled for the in-scope workloads (Exchange / SharePoint-OneDrive) and PDF handling
- **Description:** For protection to apply where content lives and moves, **Information Rights Management
  (IRM)** must be enabled for the relevant workloads — **Exchange Online** (`Get-/Set-IRMConfiguration`)
  for mail protection (Do Not Forward / Encrypt-Only), and **SharePoint Online / OneDrive** for labeled
  files. For **PDF**, confirm the tenant setting that lets SharePoint/OneDrive and Office honor **labeled
  and protected PDFs**, and confirm your users' **PDF readers support Microsoft Information Protection**.
- **Why required:** DNF/Encrypt-Only rely on Exchange IRM; protected PDFs rely on tenant/workload support
  and a compatible reader.
- **How to verify:** `Get-IRMConfiguration` (Exchange Online) shows IRM enabled; confirm the
  SharePoint/OneDrive and PDF-protection settings in the admin portals; **verify current PDF-reader
  support for your tenant**.
- **How to implement if missing:** Enable IRM for the required workloads and confirm PDF handling before
  the pilot; where reader support is uncertain, standardize on a supported reader (e.g. Microsoft Edge).

## 2.7 A pilot ring and a pilot-policy commitment (encryption is not simulatable)
- **Description:** A named **pilot ring** (the group backing `RMSPolicy – Pilot – Ring1`) to receive the
  protection labels **first**, and an explicit commitment that encryption is validated on the pilot
  before broad publish. Because label encryption has **no service-side simulation**, the pilot ring **is**
  the safety mechanism, and encryption stays **unpublished** until validated.
- **Why required:** Encryption changes how files open for everyone; a mis-scoped grant can lock people
  out of their own content. The pilot surfaces this before it hits the org.
- **How to verify:** Confirm the pilot group membership, a change window, and an approver.
- **How to implement if missing:** Create the pilot group and agree change control before enabling any
  encryption.

## 2.8 A super-user / recovery decision and the named audiences
- **Description:** A decision, from your governance/records/legal owners, on: the **super-user group**
  (`grp-rms-superusers@contoso.com`) that can always decrypt protected content for recovery, eDiscovery,
  and legal hold; the **named-recipient group** (`grp-rms-named-recipients@contoso.com`) for the
  restricted label; and the **usage rights, offline-access, and content-expiry** each label should grant.
- **Why required:** Encrypted content is unrecoverable without a super-user path; the grants and expiry
  are real business decisions, not technical defaults. Legal-hold/eDiscovery of encrypted content depends
  on the super-user configuration.
- **How to verify:** Confirm the super-user group, the named-recipient group, and the per-label rights/
  expiry with the accountable owner (`Get-AipServiceSuperUserGroup` shows the current super-user group).
- **How to implement if missing:** Get the recovery model and per-label grants signed off before
  configuring encryption; enable and populate the super-user group before broad publish.


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


# 3. Implementation Guide — Office & PDF Rights Protection (RMS/IRM), Microsoft Purview

Follow these steps in order. This guide assesses RMS activation and the current label-encryption
posture, designs the protection labels and usage rights, configures each label's encryption on a
**pilot label policy scoped to a pilot ring** (encryption stays unpublished until validated), validates
that the right people can open Office and PDF files and the wrong people cannot, then expands. Artifact
names are fixed — create them with the exact names in §1 and reuse them everywhere. **Encryption has no
service-side simulation, so the pilot ring is the safety gate.** Every write via the config helper
defaults to `-WhatIf`; add `-Commit` to apply.

> Model: prove RMS activation, the grants, offline/expiry, and Office+PDF behaviour on a pilot ring,
> then expand. **Assess → Design → Configure → Pilot → Validate → Expand.** Verify current portal paths,
> licensing, cmdlet/advanced-setting keys, and PDF-reader support for your tenant as you go — the portal
> and PDF handling evolve; nothing here is invented.

## Step 1 — Assess current state (read-only)
1. Run `IPRMS-Discovery.ps1`. It reports the **RMS/Rights Management service state** (activated?), which
   labels already have **encryption enabled** and their **protection type** (template vs user-defined),
   the **usage rights** each defines, offline-access and content-expiry values, whether a **super-user
   group** is configured, and the Exchange **IRM** state. No changes are made.
2. In the Purview portal (**Information Protection → Sensitivity labels**) confirm the taxonomy exists
   and note which labels are candidates for protection.
3. Record gaps against the Requirements checklist. Do **not** proceed past: RMS not activated, missing
   Information Protection role, missing labels, or no pilot ring/super-user decision — remediate first.

## Step 2 — Confirm RMS activation and the recovery (super-user) path
1. Confirm the Rights Management service is **Activated** (`Get-AipServiceConfiguration`; Req 2.5). If it
   is not, activate it (`Enable-AipService`) under change control before continuing.
2. Confirm the **super-user group** decision (Req 2.8). Enable super-user and set the group so records/
   legal can always recover protected content: `Enable-AipServiceSuperUserFeature`, then
   `Set-AipServiceSuperUserGroup -GroupEmailAddress "grp-rms-superusers@contoso.com"`. **Pass/fail:**
   `Get-AipServiceSuperUserGroup` returns the group. **Do this before broad publish** — encrypted content
   is unrecoverable without it.

## Step 3 — Design the protection labels and usage rights
1. Confirm, with the accountable owner, the per-label grants from §1: `Confidential \ All Employees`
   (template — all org users, Co-Author), `Confidential \ Recipients Only` (user-defined — DNF/
   Encrypt-Only), `Highly Confidential \ Named Recipients` (template — the named group, Viewer only).
2. Decide **offline-access days** and **content-expiry** per label (e.g. offline 7 days for the
   restricted label, Never-expire for the internal one) — these are governance decisions (Req 2.8).
3. Confirm the **named-recipient group** (`grp-rms-named-recipients@contoso.com`) exists and is correct.

## Step 4 — Prepare the pilot label policy (encryption unpublished)
1. If a policy scoped to the pilot ring does not exist, create it: `IPRMS-LabelProtection.ps1
   -CreatePilotPolicy -PolicyName "RMSPolicy – Pilot – Ring1" -PilotGroup "grp-rms-pilot@contoso.com"
   -WhatIf`, review, then `-Commit`. Do **not** add the encryption labels to a broadly-published policy
   yet — configure encryption on the labels first (Steps 5–7), validate on the pilot, then publish.

## Step 5 — Configure the template (assigned-rights) label — `Confidential \ All Employees`
1. Run `IPRMS-LabelProtection.ps1 -SetTemplate -LabelName "Confidential\All Employees"
   -RightsIdentity "AuthenticatedUsers" -Rights "VIEW,EDIT,PRINT,EXTRACT,DOCEDIT,OBJMODEL"
   -OfflineDays 30 -Expiry Never -WhatIf`. It shows the `Set-Label -EncryptionEnabled $true
   -EncryptionProtectionType Template -EncryptionRightsDefinitions …` it would apply — **without making
   changes**. Review the rights, then re-run with `-Commit`.
2. **Pass/fail:** `Get-Label "Confidential\All Employees"` shows `EncryptionEnabled = True`,
   protection type **Template**, and the rights definition for the org audience. **Rollback:** re-run
   with `-RemoveProtection -Commit` (sets `EncryptionProtectionType RemoveProtection`).

## Step 6 — Configure the user-defined label — `Confidential \ Recipients Only`
1. Run `IPRMS-LabelProtection.ps1 -SetUserDefined -LabelName "Confidential\Recipients Only"
   -DoNotForward -EncryptOnly -WhatIf`. It shows how it would set the label to **user-defined**
   permissions (`EncryptionProtectionType UserDefined`) with **Do Not Forward** for mail and
   **Encrypt-Only** prompting for files — the user chooses recipients at protect time. Review, then
   `-Commit`.
2. **Pass/fail:** the label shows protection type **UserDefined** with DNF/encrypt-only behaviour.
   **Rollback:** `-RemoveProtection -Commit`.

## Step 7 — Configure the named-recipient label — `Highly Confidential \ Named Recipients`
1. Run `IPRMS-LabelProtection.ps1 -SetTemplate -LabelName "Highly Confidential\Named Recipients"
   -RightsIdentity "grp-rms-named-recipients@contoso.com" -Rights "VIEW,VIEWRIGHTSDATA" -OfflineDays 7
   -Expiry Never -WhatIf`, review, then `-Commit`. This grants **Viewer-only** rights (view, no print/
   copy/edit) to the named group and nobody else.
2. **Pass/fail:** the label shows Template protection with the restricted rights for the named group
   only. **Rollback:** `-RemoveProtection -Commit`.

## Step 8 — Publish the protection labels to the pilot ring only
1. Add the three configured labels to `RMSPolicy – Pilot – Ring1` (portal **Label policies → edit →
   Labels**, or `IPRMS-LabelProtection.ps1 -PublishToPolicy -PolicyName "RMSPolicy – Pilot – Ring1"
   -Labels "Confidential\All Employees","Confidential\Recipients Only","Highly Confidential\Named
   Recipients" -Commit`). Confirm the policy publishes **only** to `grp-rms-pilot@contoso.com`.
2. Confirm Exchange **IRM** is enabled (Req 2.6) so DNF/Encrypt-Only work in Outlook, and confirm PDF
   handling for the pilot.

## Step 9 — Validate on the pilot (Office and PDF, right vs wrong recipient)
1. Run `IPRMS-Validation.ps1 -LabelName "Confidential\All Employees"` (read-only) to confirm the label's
   **effective** encryption settings match the design; repeat for the other two labels.
2. Complete the Testing Guide: as a pilot user, apply each label to an Office document and a **PDF
   export**, confirm an in-scope user can open with the intended rights, and confirm an out-of-scope
   user is **denied**; confirm DNF prevents forwarding; confirm a super-user can recover.
3. **Gate:** every label opens for the right people with the right rights, denies the wrong people, PDF
   protection is honored in a supported reader, and super-user recovery works — before expanding.

## Step 10 — Expand to the broad policy (enforce)
1. Add the **same, signed-off** labels to `RMSPolicy – Broad – AllUsers` (portal or
   `IPRMS-LabelProtection.ps1 -PublishToPolicy -PolicyName "RMSPolicy – Broad – AllUsers" -Labels … -WhatIf`
   then `-Commit`). The label **encryption settings are already on the labels** — expansion only widens
   *who the labels are published to*; no per-label re-configuration is needed.
2. **Gate:** re-validate a sample against the broad policy (`IPRMS-Validation.ps1`), confirm super-user
   recovery, and confirm a documented rollback (remove protection / unpublish) per label.

## Step 11 — Operate: evidence, recovery, and revocation
1. Run `IPRMS-Report.ps1 -CsvFolder <path>` to export the **protection posture matrix** (per label:
   encryption on/off, protection type, rights, offline days, expiry) plus RMS activation and super-user
   state — the evidence for the governance owner.
2. Run `IPRMS-Readiness.ps1` on a cadence to catch **RMS deactivation, IRM disabled, a missing super-user
   group, or a protection label left in the pilot policy after expansion**.
3. Document the **recovery** path (super-user) and the **revocation** path (`Get-AipServiceDocumentLog` /
   revoke where applicable — **verify current revocation tooling for your tenant**). Legal-hold and
   eDiscovery handling of encrypted content is a **legal/records determination** — this solution provides
   the super-user recovery method, not the legal decision.

---
### Order of operations
`Assess (RMS activated? posture) → Confirm activation + super-user recovery → Design labels/rights →
Prepare pilot policy → Configure template label → Configure user-defined label → Configure named-recipient
label → Publish to pilot ring → Validate (Office + PDF, right vs wrong, recovery) → Expand to broad →
Operate (evidence, recovery, revocation)`


---


# 5. Testing & Validation Guide — Office & PDF Rights Protection (RMS/IRM)

Run these tests after the Implementation Guide, **in order**. Each has an explicit **pass/fail** signal
and a rollback. Do not expand from the pilot ring to the broad policy until the relevant tests pass —
because label encryption has **no simulation mode**, these pilot tests **are** your safety gate. Checks
use the Purview portal, Security & Compliance PowerShell, and the AIPService module; the provided
scripts automate the read-only ones.

> **Reminder:** you are validating that protection *behaves as designed* (right people open with the
> right rights, wrong people are denied, PDF is covered, recovery works) — not deciding *who* should have
> access or how encrypted content is handled for legal/records; those are governance/legal
> determinations from §2.

## Test 1 — RMS service is activated and recoverable
- **How:** `IPRMS-Readiness.ps1` (or `Get-AipServiceConfiguration` / `Get-AipServiceSuperUserGroup`).
- **Pass:** the Rights Management service is **Activated**, the super-user feature is enabled, and
  `grp-rms-superusers@contoso.com` is set as the super-user group.
- **Fail:** service not activated → `Enable-AipService`; no super-user → enable and set the group
  (Step 2) **before** any broad publish.

## Test 2 — Each label's effective encryption matches the design
- **How:** `IPRMS-Validation.ps1 -LabelName "Confidential\All Employees"` (repeat for each label).
- **Pass:** `EncryptionEnabled = True`; protection type is **Template** (assigned) or **UserDefined** as
  designed; the rights definition, offline days, and expiry match §1.
- **Fail:** a setting is missing/wrong → re-run the relevant `IPRMS-LabelProtection.ps1` mode with
  `-Commit` and re-validate.

## Test 3 — A template label protects an Office document for the right audience
- **How:** as a pilot user, apply `Confidential \ All Employees` to a Word/Excel/PowerPoint file; have an
  **in-scope** org user open it.
- **Pass:** the file is encrypted (protection banner shown) and the in-scope user opens it with the
  intended rights (view/edit/print/copy for Co-Author).
- **Fail:** file not encrypted (allow client sync; confirm the label's encryption is on) or wrong rights
  → re-check Step 5.

## Test 4 — The wrong recipient is denied
- **How:** share the same protected file with an **out-of-scope** account (e.g. an external address not
  in any grant).
- **Pass:** the out-of-scope user is **denied** — they cannot obtain a use license / cannot open the
  content.
- **Fail:** an out-of-scope user opens it → the grant is too broad (e.g. AuthenticatedUsers where a named
  group was intended) → correct the rights definition (Step 5/7) and re-test. This is the most important
  protection test.

## Test 5 — Usage rights actually restrict (view-only means no print/copy)
- **How:** as a member of `grp-rms-named-recipients@contoso.com`, open a file labeled `Highly
  Confidential \ Named Recipients`.
- **Pass:** the user can **view** but the app blocks **print, copy, and edit** (Viewer rights only).
- **Fail:** the user can print/copy → the rights definition granted more than VIEW → correct it
  (Step 7) and re-test.

## Test 6 — Do Not Forward / Encrypt-Only works in Outlook
- **How:** as a pilot user, apply `Confidential \ Recipients Only` to an email and send to a recipient;
  the recipient attempts to **forward**.
- **Pass:** the recipient can read but **cannot forward** (Do Not Forward); for Encrypt-Only files, the
  content is encrypted to the chosen recipients.
- **Fail:** forwarding succeeds → confirm Exchange **IRM** is enabled (Req 2.6) and the label is
  user-defined with DNF (Step 6).

## Test 7 — A protected PDF opens for the right people in a supported reader
- **How:** export/label a **PDF** as `Confidential \ All Employees`; open it in a supported reader
  (e.g. Microsoft Edge) as an in-scope user, then attempt as an out-of-scope user.
- **Pass:** the in-scope user opens the protected PDF with the intended rights; the out-of-scope user is
  denied; the reader honors the protection.
- **Fail:** the PDF opens unprotected, or a supported reader can't open it → confirm PDF protection/
  handling is enabled (Req 2.6) and the reader supports Microsoft Information Protection — **verify your
  PDF-reader/tenant support**.

## Test 8 — Super-user recovery works
- **How:** as a member of `grp-rms-superusers@contoso.com`, open a file protected with a label whose
  grant does **not** include you.
- **Pass:** the super-user can open/decrypt the content for recovery — the records/legal recovery path
  exists.
- **Fail:** super-user cannot open → confirm the super-user feature is enabled and the group is set
  (Step 2); allow propagation.

## Test 9 — Content expiry / offline access behave as configured
- **How:** review a label with a content-expiry or short offline-access value and confirm the
  configuration (`IPRMS-Validation.ps1`); where an expiry date is set, confirm access lapses per design.
- **Pass:** offline-access days and content-expiry match §1; expired content is no longer openable by
  standard users (super-user recovery still works).
- **Fail:** values differ from the design → re-apply via `IPRMS-LabelProtection.ps1` and re-validate.

## Test 10 — Broad-policy publish matches the accepted pilot, and posture evidence is complete
- **How:** after Step 10, `IPRMS-Validation.ps1` on a sample against the broad policy and
  `IPRMS-Report.ps1 -CsvFolder <path>`.
- **Pass:** the labels published to `RMSPolicy – Broad – AllUsers` carry the **accepted** pilot encryption
  settings; the posture report lists every label's encryption/type/rights/offline/expiry plus RMS
  activation and super-user state — matching the signed-off design.
- **Fail:** a gap or mismatch → reconcile and re-export; confirm no protection label was left only in the
  pilot policy.

---
### Exit criteria (all must be true before broad enforcement)
`RMS activated + super-user recovery works · each label's encryption matches design · right audience opens
with right rights · wrong recipient denied · view-only restricts print/copy · DNF/Encrypt-Only works ·
protected PDF honored in a supported reader · content-expiry/offline as configured · broad == accepted
pilot · posture evidence complete · rollback (remove protection/unpublish) documented per label`


---


# 6. Troubleshooting Guide — Office & PDF Rights Protection (RMS/IRM), Microsoft Purview

Symptom → likely root cause → fix. Use **`IPRMS-Discovery.ps1`** (RMS state / encryption posture),
**`IPRMS-Readiness.ps1`** (activation / super-user / IRM / licensing / pilot sanity),
**`IPRMS-Validation.ps1`** (a label's effective encryption), and **`IPRMS-Report.ps1`** (posture matrix)
to confirm before and after each fix. Label encryption has **no simulation mode**, so most issues surface
on the **pilot ring first** — that is by design. Cmdlet/parameter names and PDF-reader support are
**tenant-/version-dependent**; where flagged, **verify against current Microsoft guidance / your tenant**.

## A. Service availability / setup

### Applying an encryption label fails (content won't protect)
- **RMS not activated.** Label encryption depends on the Rights Management service being **Activated**.
  **Fix:** `IPRMS-Readiness.ps1` (or `Get-AipServiceConfiguration`); if not activated, `Enable-AipService`
  under change control (Req 2.5), then retry.
- **Wrong role.** Label encryption edits need **Information Protection Admin**; activation/super-user need
  RMS/Global Admin. **Fix:** confirm the roles (Req 2.3).

### The Encryption page/settings aren't available on the label
- **Licensing insufficient.** Label encryption requires an AIP/MIP-enabled plan. **Fix:**
  `IPRMS-Readiness.ps1` licensing signal; confirm the plan in the M365 admin center — **verify your
  licensing/tenant** (Req 2.2).

### `Set-Label -Encryption*` parameter is rejected
- **Cmdlet/param drift.** Encryption parameter names can vary by module version. **Fix:** confirm the
  ExchangeOnlineManagement module is current; **verify the exact parameter against current Microsoft
  documentation**; the script flags encryption params.

## B. Protection doesn't apply (false negatives)

### A file labeled with a protection label isn't encrypted
- **Client hasn't synced / label not published to the user.** **Fix:** confirm the label is published in
  the policy scoping the user (`IPRMS-Discovery.ps1`); allow client sync (restart Office); confirm the
  user is in `grp-rms-pilot@contoso.com` during pilot.
- **Encryption not actually enabled on the label.** **Fix:** `IPRMS-Validation.ps1 -LabelName …`; if
  `EncryptionEnabled` is false, re-run `IPRMS-LabelProtection.ps1 -SetTemplate/-SetUserDefined -Commit`.

### Do Not Forward / Encrypt-Only doesn't work in Outlook
- **Exchange IRM not enabled.** **Fix:** `IPRMS-Readiness.ps1` IRM check (or `Get-IRMConfiguration`);
  enable IRM for Exchange Online (Req 2.6); confirm the label is **user-defined** with DNF (Step 6).

## C. Protection is wrong / too broad (the critical failures)

### The wrong recipient can open protected content
- **Grant too broad.** Most common cause: the rights definition grants **AuthenticatedUsers** where a
  **named group** was intended. **Fix:** `IPRMS-Validation.ps1 -LabelName … -ExpectIdentity
  "grp-rms-named-recipients@contoso.com"` flags an over-broad grant; re-run `IPRMS-LabelProtection.ps1
  -SetTemplate -RightsIdentity "<named group>" -Rights "VIEW,VIEWRIGHTSDATA" -Commit`. Re-test with
  Test 4 — proving the wrong recipient is **denied** is the point of the control.

### A view-only recipient can still print or copy
- **Rights definition too permissive.** VIEW alone should not allow print/extract. **Fix:** confirm the
  rights string is exactly the intended set (e.g. `VIEW,VIEWRIGHTSDATA` — no `PRINT`/`EXTRACT`/`DOCEDIT`);
  re-apply (Step 7) and re-test (Test 5). RMS usage-right keywords — **verify the exact set against
  current Microsoft documentation**.

### A default/auto grant encrypted content nobody intended to protect
- **Encryption on a label that's applied too widely.** **Fix:** encryption should be on deliberate
  protection labels, not a broad default. Remove protection from the over-applied label
  (`IPRMS-LabelProtection.ps1 -RemoveProtection -Commit`) and re-scope which label carries encryption.

## D. External recipients

### An external partner can't open a file they should be able to
- **No identity / external sharing not configured.** External recipients must authenticate to get a use
  license. **Fix:** confirm the grant includes the external address/domain; **verify the current
  external-sharing / one-time-passcode options for your tenant**; have the recipient sign in with a
  supported identity.

## E. PDF specifics

### A protected PDF opens unprotected, or a valid reader can't open it
- **PDF protection/handling not enabled, or reader unsupported.** **Fix:** confirm labeled/protected
  **PDF** handling is enabled for the tenant/workload (Req 2.6); open in a reader that supports Microsoft
  Information Protection (e.g. Microsoft Edge); **verify your PDF-reader/tenant support** — older/third-
  party readers may not honor protection. Where support is uncertain, standardize on a supported reader.

## F. Recovery / continuity

### Encrypted content can't be recovered (departed user / mis-scoped grant)
- **No super-user configured.** Without a super-user, encrypted content locked to an unavailable identity
  is unrecoverable. **Fix:** enable the super-user feature and set `grp-rms-superusers@contoso.com`
  (Step 2); confirm with Test 8. **Do this before broad publish.**

### The super-user still can't open a protected file
- **Feature/group not propagated, or membership wrong.** **Fix:** `Get-AipServiceSuperUserGroup` returns
  the group; confirm the tester is a member; allow propagation; re-test.

## G. Rollout / drift

### A protection label is stranded in the pilot policy after expansion
- **Not published to the broad policy (or configured but never published).** **Fix:** `IPRMS-Readiness.ps1`
  flags encrypting labels published only to a pilot-named policy or not published at all; publish the
  accepted labels to `RMSPolicy – Broad – AllUsers` (Step 10).

### RMS/IRM/super-user silently changed
- **Config drift.** **Fix:** run `IPRMS-Discovery.ps1` / `IPRMS-Report.ps1` on a cadence; reconcile any
  change to RMS activation, the super-user group, IRM, or a label's protection against the signed-off design.

---
## Escalation checklist
1. `IPRMS-Readiness.ps1` — RMS Activated? super-user set? IRM enabled? licensing signal? pilot sanity?
2. `IPRMS-Discovery.ps1` — which labels encrypt, with what type/rights/offline/expiry?
3. `IPRMS-Validation.ps1 -LabelName … -ExpectType … -ExpectIdentity …` — does the grant match the design,
   and is it **not** over-broad (no AuthenticatedUsers where a named group was intended)?
4. Live test — right recipient opens with the right rights (Test 3/5), **wrong recipient denied** (Test 4),
   PDF honored (Test 7), super-user recovers (Test 8).
5. Still stuck → capture the exact behaviour and **verify the current Microsoft guidance / your tenant**
   for RMS usage rights, encryption parameters, and PDF-reader support before a tenant-wide change. *Who*
   may access what and how encrypted content is handled for legal/records remain governance/legal
   determinations — this guide fixes the *technical protection*, not the *access decision*.


---


# 7. Best Practices — Office & PDF Rights Protection (RMS/IRM)

Field-tested practices for making **persistent, label-based protection** actually protect — without
locking users out of their own content or breaking legitimate sharing. These complement the
Implementation and Testing guides.

## Designing usage rights (grant the least that works)
- **Right people, right rights — not just "encrypted".** Encryption alone is blunt; the value is in
  **usage rights**. Grant **Viewer** (view only) where content should not be printed/copied/edited, and
  **Co-Author** where collaboration is needed. Start narrow; widen only on evidence.
- **Template vs user-defined, on purpose.** Use **assigned (template)** rights for known audiences
  (all employees, a named group) so the grant is consistent and auditable; use **user-defined** (Do Not
  Forward / Encrypt-Only) for ad-hoc protection where the user knows the recipients. Don't force
  user-defined for content that always has the same audience.
- **Beware AuthenticatedUsers vs a named group.** `AuthenticatedUsers` grants *every authenticated org
  user* — appropriate for "all employees", wrong for board/M&A content. For restricted labels, grant a
  **named group** and confirm with Test 4 that the wrong recipient is denied.
- **Externals need an identity and an intent.** Sharing protected content externally requires the
  recipient to authenticate. Decide deliberately whether a label allows external addresses; **verify the
  current external-sharing/one-time-passcode options for your tenant**.

## Rollout discipline (encryption is not simulatable — so pilot is everything)
- **There is no service-side simulation for label encryption.** The setting takes effect the moment a
  file is labeled. The **pilot ring is your only safety net** — configure encryption on the labels,
  publish **only** to `RMSPolicy – Pilot – Ring1`, validate, then publish to `RMSPolicy – Broad –
  AllUsers`.
- **`-WhatIf` before every commit.** Every provided config action previews with `-WhatIf` and changes
  nothing until `-Commit`. Read the preview — a wrong rights definition can lock people out.
- **Test the denial, not just the access.** The most important test is that the **wrong** recipient is
  **denied** (Test 4). "It opens for me" proves nothing about whether protection is real.

## Recovery, revocation, and continuity (non-negotiable)
- **Configure super-users before broad publish.** Encrypted content is **unrecoverable** without a
  super-user. Enable the super-user feature and set `grp-rms-superusers@contoso.com` **before** any label
  is published broadly (Step 2). Keep the group tiny and audited — a super-user can read everything.
- **Plan for the departing-employee / lost-key case.** Content encrypted to an individual who leaves, or
  a mis-scoped grant, is only recoverable via super-user — confirm the recovery path works (Test 8)
  before you rely on it.
- **Know the revocation path.** For content that must be taken down, confirm the current revocation/
  document-tracking tooling for your tenant (`Get-AipServiceDocumentLog` and related) — **verify current
  tooling**, it evolves.
- **Legal hold / eDiscovery of encrypted content is a legal determination.** eDiscovery can index and
  process protected content when configured, but *how* encrypted content is preserved and produced is a
  **legal/records decision** — this solution provides the super-user recovery method, not the decision.

## Office and PDF specifics
- **Cover the PDF gap deliberately.** Protecting Office files but not their PDF exports is a common quiet
  leak. Confirm labeled/protected **PDF** handling is enabled and that users' readers honor it (Test 7);
  where reader support is uncertain, **standardize on a supported reader** (e.g. Microsoft Edge).
- **Offline access is a trade-off.** A long offline-access window is convenient but means a revoked/
  expired grant keeps working offline until the license lapses. Set offline days to match the label's
  sensitivity (shorter for the most restricted label).
- **Content expiry where the data has a shelf life.** For time-sensitive content, set content expiry so
  access lapses automatically — but confirm super-user recovery still works after expiry.

## Avoiding drift and conflicts
- **Encryption lives on the label, publish lives on the policy.** Changing *who* gets a label is a
  policy change; changing *how it protects* is a label change. Keep that distinction clear so an
  expansion never silently alters a grant.
- **Retire the pilot cleanly.** After broad rollout, ensure no protection label is left published **only**
  to the pilot policy, or (worse) a label configured but never published. `IPRMS-Readiness.ps1` flags this.
- **Re-baseline periodically.** Run `IPRMS-Discovery.ps1` / `IPRMS-Report.ps1` on a cadence to catch RMS
  deactivation, a dropped super-user group, IRM disabled, or a label's protection changed unexpectedly.

## Security & safety hygiene
- **No credentials in code.** All scripts authenticate interactively via `Connect-IPPSSession` /
  `Connect-AipService`; never embed secrets. Store exported evidence securely — it describes your
  protection posture.
- **Read-only or `-WhatIf` by default.** Discovery/validation/reporting/readiness scripts are read-only;
  the protection script defaults to `-WhatIf` and requires `-Commit` for any write. Keep it that way.
- **Verify licensing/tenant/reader support before relying on a capability.** Label encryption, PDF
  protection, and external sharing are plan-/tenant-dependent and the portal evolves — flag, don't assume.


---


# 8. Deliverables Summary — Office & PDF Rights Protection (RMS/IRM), Microsoft Purview

## What you receive
A complete, self-guided package to configure **label-based encryption and usage rights for Office
documents and PDFs** in Microsoft Purview — so protection travels with the file — piloted on a ring,
validated, then expanded, using the Microsoft Purview portal, Security & Compliance PowerShell, and the
AIPService module. Includes the recovery (super-user) and evidence path.

## Documentation
| Document | What it gives you |
|---|---|
| **Solution Overview** | The rights-protection levers (RMS activation, label encryption, usage rights, DNF/Encrypt-Only, offline/expiry, Office+PDF coverage), assigned-vs-user-defined design, the protection-label design, the naming convention, and the deployment model. |
| **Requirements Guide** | Solution-specific prerequisites (existing label taxonomy, licensing for label encryption, Information Protection role + RMS/Global Admin for activation, S&C PowerShell + AIPService, RMS activated, IRM enabled for the workloads + PDF handling, a pilot ring, and a super-user/recovery and named-audience decision) on top of the Purview Global Requirements. |
| **Implementation Guide** | Ordered steps: assess RMS + posture → confirm activation + super-user recovery → design labels/rights → prepare pilot policy → configure the template, user-defined, and named-recipient labels → publish to the pilot ring → validate (Office + PDF, right vs wrong, recovery) → expand to broad → operate. Each step named, gated, reversible; `-WhatIf` before every commit; pilot-first (no simulation). |
| **Testing & Validation Guide** | 10 pass/fail tests — RMS activated + recoverable, effective encryption per label, template label protects for the right audience, wrong recipient denied, view-only restricts print/copy, DNF/Encrypt-Only, protected PDF honored, super-user recovery, expiry/offline, and broad == accepted pilot. |
| **Best Practices** | Designing least-privilege usage rights, no-simulation rollout discipline, recovery/revocation/continuity, Office+PDF specifics, avoiding drift/conflicts, and safety guidance. |
| **Troubleshooting Guide** | The common failure modes (label won't encrypt, RMS not activated, wrong recipient can open, view-only can still print, DNF not honored, PDF opens unprotected, super-user can't recover, external can't open) with resolutions. |

## PowerShell tools (5)
All run through `Connect-IPPSSession` (Security & Compliance PowerShell) and/or `Connect-AipService`
(AIPService); read-only or `-WhatIf` by default, writes gated behind `-Commit`. No credentials in code.

| Script | Role | Default |
|---|---|---|
| `IPRMS-Discovery.ps1` | **Posture assessment** — report the RMS/Rights Management service state, which labels have encryption enabled and their protection type, usage rights, offline/expiry, the super-user group, and Exchange IRM state. | Read-only |
| `IPRMS-LabelProtection.ps1` | **Configuration / remediation helper** — create the pilot policy, set a label to **template (assigned)** rights, set a label to **user-defined** (Do Not Forward / Encrypt-Only), set offline-access and content-expiry, publish labels to a policy, and remove protection (rollback). | `-WhatIf` |
| `IPRMS-Validation.ps1` | **Effective-settings validation** — confirm a label's resolved encryption settings (enabled, protection type, rights definition, offline days, expiry) match the signed-off design. | Read-only |
| `IPRMS-Report.ps1` | **Posture matrix / evidence** — export the protection matrix across all labels (encryption on/off, type, rights, offline, expiry) plus RMS activation and super-user state to CSV. | Read-only |
| `IPRMS-Readiness.ps1` | **Scope/health helper** — check RMS activated, super-user configured, Exchange IRM enabled, licensing signal, and pilot-scope sanity (protection labels left only in the pilot policy). | Read-only |

## Outcomes
- A signed-off set of **protection labels** configured in the tenant — encryption + the right usage
  rights per audience, so protection travels with Office **and** PDF files.
- A confirmed **recovery path** (super-user) so encrypted content is never unrecoverable, and a known
  revocation path.
- Protection **piloted on a ring** and validated (right people open, wrong people denied, PDF covered)
  before broad publish — the safe substitute for a non-existent simulation mode.
- Repeatable read-only tooling to report the protection posture and catch RMS/IRM/super-user drift.

## Explicitly out of scope (deferred)
- **The label taxonomy, content marking, DLP, retention, and auto-labeling at scale** — assumed to exist
  or covered by separate Purview solutions; this solution configures *encryption and rights* over the
  labels.
- **Double Key Encryption (DKE) and HYOK** — separate builds; this covers cloud-based RMS label encryption.
- **Who may access what, content-expiry rules, and how encrypted content is preserved/produced for
  legal-hold/eDiscovery** — governance and legal determinations owned by compliance/security/records/
  legal; this solution provides the configuration method, recovery method, and evidence.
- Any capability your **licensing/tenant/PDF-reader** does not include — verify before relying on label
  encryption, PDF protection, or external sharing.
