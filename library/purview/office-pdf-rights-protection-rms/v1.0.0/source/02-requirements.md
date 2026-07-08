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
