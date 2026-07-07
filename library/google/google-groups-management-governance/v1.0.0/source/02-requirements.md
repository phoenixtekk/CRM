# 2. Requirements

These are the **solution-specific** prerequisites for Google Groups management & governance. They
build on the shared **[Global Requirements — Google Workspace & Gemini Solutions](global-requirements-google.md)**
(Workspace/Cloud Identity tenant with super-admin, identity source of truth, a pilot scope + change
control, and security/compliance stakeholders) — those are assumed and are **not** repeated here.
Verify each item below before starting Section 3.

---

## 2.1 Super-admin (or delegated Groups admin) with Groups & Cloud Identity rights
- **Description:** A **super-admin**, or a custom admin role granting the **Groups** privileges
  (create/read/update/delete groups, manage group settings and membership) plus **Cloud Identity**
  rights for security/dynamic groups. API automation uses the **Admin SDK Directory (Groups, Members,
  Groups Settings)** and **Cloud Identity Groups** APIs.
- **Why required:** All group typing, naming, settings, ownership, dynamic/security-group configuration,
  and lifecycle actions are performed with these privileges.
- **How to verify:** In **admin.google.com → Account → Admin roles**, confirm the role holds the Groups
  and Cloud Identity privileges; confirm you can open **Directory → Groups** and edit a group's
  **Settings** and **Members**.
- **How to implement if missing:** Assign the built-in **Groups Admin** role plus Cloud Identity
  privileges, or a custom role scoped to the above, per least privilege.

## 2.2 Cloud Identity Premium (for dynamic groups & security groups)
- **Description:** **Cloud Identity Premium** licensing (bundled with Enterprise Workspace editions,
  or purchasable standalone) enabling **dynamic groups** and **Cloud Identity security groups**.
- **Why required:** Attribute-driven (dynamic) membership and the immutable **security label** used for
  access-granting groups are Premium features; without them the design falls back to static groups and
  manual review.
- **How to verify:** In **admin.google.com → Billing → Subscriptions**, confirm a Cloud Identity Premium
  (or equivalent Enterprise) subscription; attempt to create a test **dynamic group** in
  **Directory → Groups → Create group** (the dynamic option is present only with Premium — **verify in
  your tenant**).
- **How to implement if missing:** Acquire Cloud Identity Premium, or document that dynamic/security
  groups are out of scope for this tenant and use the static-group fallback throughout.

## 2.3 Group-type catalogue & naming standard (agreed and documented)
- **Description:** A written, stakeholder-agreed **type catalogue** (Distribution / Security-Access /
  Collaboration / Dynamic / External) with the **default policy per type**, and the **naming
  convention** (`<Type> – <Scope> – <Purpose>` display + email prefixes `dl-`/`sec-`/`collab-`/`dyn-`/`ext-`).
- **Why required:** Every configuration step, the naming/type validator tool, and all reporting key off
  this standard; without it, "governed" has no definition to enforce against.
- **How to verify:** Confirm a document exists naming the types, their default settings, and the exact
  naming/prefix rules, approved by the Groups/security owners.
- **How to implement if missing:** Author the type catalogue and naming standard from the reference
  design in Section 1 before running the validators; keep it as the source of truth the tools check
  against.

## 2.4 Directory attribute source of truth (for dynamic groups)
- **Description:** A **reliable, populated set of directory attributes** (e.g. `department`,
  `costCenter`, `orgUnitPath`, `location`) fed from the **HR/IGA source of truth** via the provisioning
  mechanism named in Global Requirement 4 (GCDS/SCIM), for any group whose membership will be **dynamic**.
- **Why required:** A dynamic group's membership is a **CEL query over these attributes** — if they are
  empty, stale, or inconsistent, the computed membership is wrong (and silently so).
- **How to verify:** In **Directory → Users**, spot-check that the attributes your CEL queries reference
  are populated and current for a representative sample; confirm the sync that maintains them is healthy.
- **How to implement if missing:** Populate and reconcile the attributes at the source and let the sync
  flow them into the directory **before** converting any group to dynamic; until then, keep those groups
  static.

## 2.5 Groups lifecycle owners & request/approval path
- **Description:** Named **owners of the Groups lifecycle** and an agreed **request → approve** intake
  path (a form/ticket queue) and **review/retire** cadence, plus the **change-control window** (from
  Global Requirement 5) for production settings changes.
- **Why required:** Governance is a process, not a one-time config: someone must approve new groups to
  the model, run access reviews, and authorise staged retirements; posting/external changes are
  high-impact and need change control.
- **How to verify:** Confirm a named intake queue/owner exists, a review cadence is agreed, and a change
  window/approval path is available for Groups settings changes.
- **How to implement if missing:** Stand up the intake queue (form/ticket), assign lifecycle owners, and
  agree the review cadence and change-control process before enforcing the model in production.

## 2.6 API access + least-privilege scopes for the Python tools
- **Description:** An authorized way for the Python tools to call Google APIs **without secrets in
  code**: either **Application Default Credentials (ADC)** for an authenticated admin, or a **service
  account with domain-wide delegation** impersonating an admin, granted only the scopes the tools need.
  Enable the **Admin SDK API** and **Cloud Identity API** on the project.
- **Why required:** The assessment/validation tools read Groups, members, and settings; the helpers
  (with `--apply`) write settings/membership. Least-privilege, secret-free auth is mandatory.
- **Read-only scopes (assessment/validation):** `admin.directory.group.readonly`,
  `admin.directory.group.member.readonly`, `apps.groups.settings` (read), `cloud-identity.groups.readonly`,
  `admin.directory.user.readonly`.
- **Write scopes (only for `--apply` helpers, granted separately):** `admin.directory.group`,
  `admin.directory.group.member`, `apps.groups.settings`, `cloud-identity.groups`.
- **How to verify:** Confirm the APIs are enabled, the ADC/service-account identity resolves, and a
  read-only tool run (e.g. `groups_inventory_hygiene_assessment.py`) returns data; confirm no key file
  is committed to the repo.
- **How to implement if missing:** Enable the APIs, configure ADC or DWD with the read-only scopes
  above, and add the write scopes only to the identity that runs the `--apply` helpers under change
  control.
