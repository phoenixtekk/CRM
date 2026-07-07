# 2. Requirements

These are the **solution-specific** prerequisites for designing and governing the Drive & Shared
Drives architecture. They build on — and do not repeat — the shared **Global Requirements for Google
Workspace & Gemini Solutions** (`global-requirements-google.md`), which already cover the Workspace/
Cloud Identity tenant + super-admin (GR-1), the identity/provisioning source of truth (GR-4), the
pilot scope + change control (GR-5), and the security/compliance/governance stakeholders (GR-6).
Confirm those first; then satisfy the items below.

Each requirement is stated as **Description / Why required / How to verify / How to implement if
missing.**

---

## 2.1 Drive & Docs administration privilege
- **Description:** A super-admin, or a custom **admin role** with the **Drive and Docs** privilege
  (Admin console → **Account → Admin roles**), able to configure sharing settings, Shared Drive
  creation controls, and Shared Drive management.
- **Why required:** All sharing-policy and Shared Drive configuration in this solution is performed
  with this privilege; the Python tools authenticate as this identity (or a delegated service
  account) to read/manage Drive settings.
- **How to verify:** In **Admin console → Account → Admin roles**, confirm your role includes the
  **Services → Drive and Docs** privilege set; or sign in as super-admin.
- **How to implement if missing:** Assign the built-in **Super Admin** role or create a custom admin
  role granting **Drive and Docs**, and (for automation) a **service account with domain-wide
  delegation** scoped to the Drive/Admin SDK scopes named in §2.6.

## 2.2 Google Groups as the membership source of truth
- **Description:** **Google Groups** (synced from, or reconciled with, the directory source of truth
  in GR-4) that will be used as **Shared Drive members** and as the unit of access management — one or
  more groups per team/function (e.g. `grp-finance-ap@corp.example`).
- **Why required:** The design mandates **group-based membership**, not per-user grants, so access is
  auditable and directory-driven. Without governed groups, membership decays into ad-hoc user adds.
- **How to verify:** Confirm the relevant teams have corresponding Google Groups and that group
  membership is maintained by the source of truth (GCDS/SCIM or Groups for Business), not edited
  ad hoc.
- **How to implement if missing:** Define the group naming standard and provision the groups (from the
  IdP/HR source where possible); agree who owns group membership before granting Drive access.

## 2.3 Data classification & DLP policy inputs
- **Description:** The organization's **data-classification scheme** (e.g. Public / Internal /
  Confidential / Restricted) and the **DLP detectors** that map to it (national IDs, financial data,
  regulated content, custom word-lists/regex), owned by the security/data-governance stakeholders in
  GR-6.
- **Why required:** DLP-aligned sharing controls (Decision 5) block or warn on sensitive external
  sharing only if classification and detectors are defined; sharing policy alone cannot see content.
- **How to verify:** Confirm a documented classification scheme and the DLP detectors that implement
  it exist and are approved by data governance.
- **How to implement if missing:** Work with the GR-6 stakeholders to agree the classification scheme
  and detector set **before** authoring DLP rules; this solution consumes them, it does not invent them.

## 2.4 Enterprise-tier edition for advanced sharing controls (edition-gated)
- **Description:** **Target audiences**, **trust rules**, **DLP for Drive**, and the **security
  investigation tool** require **Enterprise Standard/Plus, Education Standard/Plus, or Enterprise
  Plus** (verify your exact edition mapping in your tenant).
- **Why required:** These are the controls that implement scoped external sharing and content-aware
  blocking. On lower editions the design falls back to OU-level sharing settings + manual review.
- **How to verify:** In **Admin console → Billing → Subscriptions**, confirm the edition; check that
  **Directory → Target audiences** and **Data → Data protection** (DLP) pages are present.
- **How to implement if missing:** Upgrade the affected OUs/licenses through Google or a reseller, or
  adopt the documented lower-tier fallback (OU sharing settings + `drive_sharing_exposure_assessment.py`
  driven manual review).

## 2.5 An agreed Shared Drives taxonomy & naming standard (design input)
- **Description:** A signed-off **taxonomy** (top-level domains) and **naming convention**
  `<Domain> – <Team/Function> – <Purpose>` for Shared Drives, plus the **role model** (which group is
  Manager / Content manager / Contributor / Viewer per Drive).
- **Why required:** Provisioning and governance are only consistent if the naming and role model are
  agreed up front; the provisioner tool enforces this standard.
- **How to verify:** Confirm the taxonomy/naming/role model document exists and is approved by the
  Drive service owner and the business stakeholders.
- **How to implement if missing:** Run the Design step (Implementation §3.2) to produce it before
  provisioning any production Shared Drives.

## 2.6 API access for the automation (Admin SDK + Drive API)
- **Description:** The **Admin SDK Directory & Reports APIs** and the **Drive API** enabled in a Google
  Cloud project, and an OAuth client **or** a service account with **domain-wide delegation** scoped to
  the read-only scopes the tools use (and, only where a tool is run with `--apply`, the corresponding
  write scopes).
- **Why required:** The five Python tools read sharing/ownership/membership state (and, for the
  provisioner, optionally create/manage Shared Drives) via these APIs.
- **How to verify:** In the Cloud project, confirm **Admin SDK API** and **Google Drive API** are
  enabled; in **Admin console → Security → API controls → Domain-wide delegation**, confirm the
  client ID is authorized for the scopes.
- **How to implement if missing:** Enable the APIs, create the OAuth client / service account, and
  authorize the scopes:
  - `https://www.googleapis.com/auth/admin.directory.group.readonly`
  - `https://www.googleapis.com/auth/admin.reports.audit.readonly`
  - `https://www.googleapis.com/auth/drive.readonly` (read/assessment)
  - `https://www.googleapis.com/auth/drive` and
    `https://www.googleapis.com/auth/admin.directory.group` **only** for `--apply` provisioning/
    membership changes.
  **No keys are committed or hardcoded** — the tools use OAuth/ADC or a securely-referenced credential
  (see §3 and each script's header).
