# 2. Requirements Guide — Sensitivity Label Taxonomy Design

Verify **every** requirement below before starting the Implementation Guide. These are the
**solution-specific** prerequisites for designing and building a sensitivity label taxonomy; they build
on the shared **Global Requirements — Microsoft Purview Solutions** (licensing, least-privilege roles,
Security & Compliance PowerShell + Graph toolchain, in-scope workloads, compliance/records/legal
stakeholders, and a pilot scope with change control). Read the Global Requirements first; this guide
does not repeat them.

> **Deferral note (security / compliance / records).** The **tier count, the final label names, which
> tiers encrypt, and the exact rights model** referenced here are **determinations owned by your
> security, compliance, records, and legal functions** — not technical defaults. This solution provides
> the **design method, the mapping template, and the configuration**; it does not decide the
> classification scheme. Confirm the taxonomy and protection mapping with the accountable owners before
> publishing.

---

## 2.1 Licensing for sensitivity labels, protection, and content marking
- **Description:** **Manual sensitivity labeling**, **content marking** (header/footer/watermark), and
  **encryption** applied through a label are available broadly (the Microsoft 365 E3 tier covers manual
  sensitivity labeling and label-based encryption). More advanced label behaviors (some auto-labeling,
  co-authoring on encrypted files at scale, and certain classifier-driven features that other solutions
  build on) are **E5 / E5 Compliance**-tier — this design solution stays within manual labels +
  protection + publishing, which E3 covers.
- **Why required:** You cannot create or publish protecting labels without the tenant plan that includes
  sensitivity labeling and rights protection.
- **How to verify:** M365 admin center → subscriptions/add-ons; confirm **Information Protection** is
  visible in the Purview portal. **Verify your licensing/tenant** — Microsoft's licensing tables are the
  authority.
- **How to implement if missing:** Ensure the tenant has the plan covering sensitivity labeling and
  rights management before building protecting labels.

## 2.2 Information Protection Admin role (least privilege)
- **Description:** The Purview role group this solution needs is **Information Protection Admin**
  (create/manage sensitivity labels and label policies). **Global Administrator is not required** for
  taxonomy work.
- **Why required:** The sensitivity-label cmdlets (`New-Label`, `Set-Label`, `New-LabelPolicy`,
  `Set-LabelPolicy`) and portal panes are gated by this role group.
- **How to verify:** Purview portal → **Roles & scopes → Permissions**; confirm your admin account is in
  *Information Protection* (or *Information Protection Admin*).
- **How to implement if missing:** Add the admin to the least-privilege role group under change control;
  wait for role propagation before running cmdlets.

## 2.3 Security & Compliance PowerShell connectivity
- **Description:** A workstation with the **ExchangeOnlineManagement** module (which provides
  `Connect-IPPSSession` for Security & Compliance PowerShell) and, where Graph is used for evidence,
  **Microsoft Graph PowerShell** — with a modern-auth / MFA-capable admin account.
- **Why required:** All five provided scripts and every label/policy cmdlet run through
  `Connect-IPPSSession`.
- **How to verify:** `Connect-IPPSSession` succeeds and `Get-Label` returns without error.
- **How to implement if missing:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser`; confirm
  modern-auth sign-in. See the Global Requirements for the full toolchain.

## 2.4 A classification scheme and in-scope workloads
- **Description:** An agreed **classification scheme** — how many sensitivity tiers the organization
  recognizes and what each means (e.g. `Public` / `Internal` / `Confidential` / `Highly Confidential`)
  — and the **workloads in scope** (Exchange, SharePoint, OneDrive, Teams; endpoints where client-side
  labeling applies). The scheme is the input to the taxonomy design; without it the labels are arbitrary.
- **Why required:** The taxonomy structure (tier count, sublabels) and the protection mapping key off the
  classification scheme and where labels will be used.
- **How to verify:** Confirm the tier scheme and the in-scope workloads with security/compliance
  stakeholders. Check whether any classification scheme already exists (data-classification framework,
  ISO/regulatory scheme) to align to.
- **How to implement if missing:** Agree the tier scheme (typically 3–5 tiers) before authoring labels;
  the Overview's sample taxonomy is a starting point to react to, not a default to adopt blindly.

## 2.5 A pilot ring and a pilot-first commitment
- **Description:** A named **pilot ring** — a small group of users (e.g. the group backing
  `SL Policy - Pilot - Ring1`) — to publish the designed labels to first, and an explicit commitment that
  **encrypting labels are validated in the pilot** before broad publish (`SL Policy - Broad - AllUsers`).
- **Why required:** Encryption and content-marking behavior is best surfaced cheaply in a small ring;
  the house model requires a pilot/test pass before broad enforcement.
- **How to verify:** Confirm the pilot-ring group membership, a change window, and an approver.
- **How to implement if missing:** Create the pilot group and agree the change-control path before
  publishing anything.

## 2.6 Rights-management (encryption) prerequisites
- **Description:** For labels that **encrypt**, the tenant's **Azure Rights Management / unified labeling
  protection** service must be active, and you must decide the **rights model** — which mail-enabled
  security groups get which usage rights (e.g. Co-Author, Reviewer, Viewer) per encrypting label. The
  Overview's protection mapping is the template for this decision.
- **Why required:** An encrypting label cannot protect if the protection service is not enabled; the
  rights definition (points at a group) is a required input to `New-Label -EncryptionEnabled`.
- **How to verify:** Confirm the protection (Rights Management) service is **activated**; confirm each
  rights group named in the mapping (`grp-all-employees@…`, `grp-trusted-people@…`,
  `grp-specified-people@…`) exists and has the intended members.
- **How to implement if missing:** Activate the protection service and create/confirm the mail-enabled
  security groups used in the rights definitions before building encrypting labels.

## 2.7 A signed-off taxonomy and protection-mapping sheet
- **Description:** Before any label is created, a **signed-off design artifact** exists: the tier list
  (display names, internal names, order, tooltips), the parent/sublabel structure, and the
  **protection/marking mapping** (which labels encrypt, the rights per group, the header/footer/
  watermark). This is the design deliverable the configuration implements verbatim.
- **Why required:** Renaming or reordering after publish is disruptive (existing content keeps the old
  label); the design must be agreed before it is built so it does not have to be rebuilt.
- **How to verify:** The design sheet exists and is signed off by the accountable security/compliance
  owner; every internal `Name` is unique and does not collide with an existing label (confirm via
  `IPTAX-Discovery.ps1`).
- **How to implement if missing:** Run the Design step (Implementation Step 2) with the governance owners
  and capture the sheet before creating labels.
