# 2. Requirements — Exact Data Match (EDM) in Microsoft Purview

These are the **solution-specific** prerequisites for configuring EDM, **on top of** the six category
prerequisites in `global-requirements-purview.md` (tenant/licensing, least-privilege roles, the
S&C-PowerShell/Graph toolchain, in-scope data sources, compliance/privacy/legal stakeholders, and a
pilot scope + change control). Verify each item below — with its **Description / Why / Verify /
Implement** — before starting the Implementation Guide.

> **Boundary reminder.** EDM is **licensing-dependent** and the portal/limits **evolve** — treat every
> version number and portal path here as **"verify in your tenant."** *Which* records are lawful to
> load, their **minimisation and retention**, are **privacy/compliance/legal determinations** (GR §5) —
> this solution provides the technical method and evidence, not the determination.

---

## R1 — EDM-capable licensing (E5 / E5 Compliance)

- **Description:** EDM-based classification requires **Microsoft 365 E5**, the **E5 Compliance**
  add-on, or the **Information Protection & Governance** license on the tenant (and on users where the
  consuming capability — e.g. auto-labeling — is per-user licensed).
- **Why required:** EDM schemas and EDM SITs are not available without the qualifying plan; the
  *Exact data match* node will be absent or read-only otherwise.
- **How to verify:** M365 admin center → **Billing → Licenses** confirms the SKU/add-on; in the
  Purview portal, **Data classification → Classifiers → Exact data match (EDM)** is present and lets
  you create a schema.
- **How to implement if missing:** Assign/purchase the qualifying licensing before starting.
  **(Verify the current EDM licensing matrix on Microsoft Learn — plan names change.)**

## R2 — EDM authoring roles (least privilege)

- **Description:** An admin account holding a role that can **create/manage EDM schemas and SITs** —
  typically membership in **Compliance Administrator** or **Compliance Data Administrator** (the
  **Organization Management** / **Security Administrator** role groups also qualify), assigned in the
  Purview portal. Global Administrator is **not** required and should not be used for routine work.
- **Why required:** Creating the schema, the rule package, and the SIT is gated on these role groups
  (GR §2 — least privilege).
- **How to verify:** Purview portal → **Settings → Roles & scopes → Permissions** (or the
  *Microsoft Purview* role groups) confirms the account's membership; the account can open the EDM
  wizard and see **Create EDM schema**.
- **How to implement if missing:** Add the account to the least-privilege qualifying role group under
  change control.

## R3 — EDM_DataUploaders authorization (upload account)

- **Description:** The account that will run `EdmUploadAgent.exe` to hash and upload the data must be a
  member of the **`EDM_DataUploaders`** security group in **Microsoft Entra ID** (the group name is
  fixed and expected by the service).
- **Why required:** The Upload Agent authenticates as this account; upload is **rejected** if the
  account is not in `EDM_DataUploaders`.
- **How to verify:** In Entra ID / Graph, confirm the group **`EDM_DataUploaders`** exists and the
  upload account is a member; `EdmUploadAgent.exe /Authorize` completes sign-in without an
  authorization error. `PURVEDM-Discovery.ps1` reports the group and membership.
- **How to implement if missing:** Create the `EDM_DataUploaders` security group in Entra ID and add
  the upload account, then re-authorize. **(Verify the exact required group name / any tenant-specific
  variation on Microsoft Learn.)**

## R4 — The EDM Upload Agent installed for the correct cloud

- **Description:** The **EDM Upload Agent** (`EdmUploadAgent.exe`) installed on a domain-joined,
  access-controlled Windows host **from the download that matches your cloud instance** —
  **Commercial**, **GCC**, **GCC High**, or **DoD** each have a **different** Upload Agent build and
  endpoint.
- **Why required:** The Agent is the **only** way to hash and upload; a mismatched-cloud build will
  fail to authenticate/upload. (Government tenants **must** use their cloud's build — see the Gov note
  below.)
- **How to verify:** `EdmUploadAgent.exe /?` runs and reports its version; `/Authorize` succeeds
  against your cloud.
- **How to implement if missing:** Download and install the Upload Agent build for your cloud from the
  current Microsoft Learn "Get started with EDM" page. **(Download links and switches evolve — verify
  the current page and run `EdmUploadAgent.exe /?`.)**

> **Government (GCC High / DoD) note.** Sovereign clouds use **distinct** Upload Agent downloads,
> service endpoints, and sometimes portal URLs (e.g. `purview.microsoft.us`). Confirm the correct
> build and endpoints for your cloud before hashing — a Commercial-cloud agent will not work in GCC
> High/DoD.

## R5 — The sensitive-data source and schema design (with the data owner)

- **Description:** A defined **source records set** you can export to `.csv`/`.tsv`, and an agreed
  **schema** design: the fields (columns), which field is the **primary/searchable element**, which
  are **supporting elements**, and the per-field **configurable-match** options (ignore case / ignore
  delimiters). Header row field names must match the schema exactly.
- **Why required:** The schema and the SIT logic both key off this design; a wrong primary element or
  mismatched header breaks matching. Field-count and row/size limits apply.
- **How to verify:** Confirm with the **data owner** the columns, the primary element, the supporting
  elements, and that an export in the required format is producible within the documented limits.
  `PURVEDM-Schema.ps1 -WhatIf` validates a candidate schema definition.
- **How to implement if missing:** Work with the data owner to define the schema and produce a
  representative export. **(Verify current field-count, row-count, and file-size limits on Microsoft
  Learn — they have increased over time.)**

## R6 — A secure host and secret handling for hashing (salt + plaintext)

- **Description:** An **access-controlled host** to run the Agent on, a plan for the **salt** (supply
  a secret salt or let the Agent generate one — either way **record it securely and reuse it**), and a
  procedure to **securely delete the plaintext export** after hashing.
- **Why required:** The export is live sensitive data and the salt is a secret that makes hashes
  non-reversible and enables future matching/refresh. Mishandling either is a data-exposure risk.
- **How to verify:** The host has restricted access; a secret store holds the salt; a secure-deletion
  step is defined. **No salt or plaintext appears in any script, log, or repo** (the provided scripts
  never take a salt or read source data).
- **How to implement if missing:** Provision the host, choose the salt-handling approach, and define
  secure deletion before exporting any data.

## R7 — In-scope workloads and a consuming policy design

- **Description:** The **workloads** where the EDM SIT will be enforced (Exchange, SharePoint,
  OneDrive, Teams, Endpoint — GR §4) and the **consuming policy** design: at minimum a **DLP policy**
  (this solution's default), optionally auto-labeling or retention that references the EDM SIT.
- **Why required:** An EDM SIT does nothing until a policy uses it; the workloads and action are what
  produce protection.
- **How to verify:** Confirm the target workloads and the intended DLP policy/rule (name, conditions,
  action) with compliance.
- **How to implement if missing:** Design the DLP policy and rule to reference the EDM SIT, to be
  built in **simulation** in the Implementation Guide.

## R8 — Pilot scope, change control, and the refresh plan

- **Description:** A named **pilot ring** (`SG-EDM-Pilot`) to validate on, a **change-control**
  path for simulate→enforce, and an owner/cadence for the **data refresh** (re-hash + re-upload as
  the source data changes; the data store must not go stale).
- **Why required:** DLP is high-impact (pilot in simulation first — GR §6), and EDM matching quality
  **decays** if the hashed data isn't refreshed.
- **How to verify:** A named pilot ring exists, a change window/approver is identified, and a refresh
  owner + cadence (and, ideally, a scheduled re-upload task) are agreed.
- **How to implement if missing:** Define the pilot ring, the change-control path, and the refresh
  schedule before enforcing. `PURVEDM-Set-Scope.ps1` helps manage the pilot ring; the Best Practices
  guide covers automating refresh.

---

### Requirements checklist

| # | Requirement | Verify with |
|---|---|---|
| R1 | EDM-capable licensing (E5 / E5 Compliance) | Admin center licenses; EDM node present |
| R2 | EDM authoring role (least privilege) | Purview Roles & scopes |
| R3 | `EDM_DataUploaders` membership (upload account) | Entra group + `/Authorize`; `PURVEDM-Discovery.ps1` |
| R4 | EDM Upload Agent for the correct cloud | `EdmUploadAgent.exe /?` + `/Authorize` |
| R5 | Source data + schema design (with data owner) | Data-owner sign-off; `PURVEDM-Schema.ps1 -WhatIf` |
| R6 | Secure host + salt/plaintext handling | Host ACLs; secret store; secure-delete step |
| R7 | In-scope workloads + consuming DLP policy design | Compliance-agreed policy/rule/action |
| R8 | Pilot ring, change control, refresh plan | Named ring/approver/refresh owner + cadence |

> The six **category** prerequisites in `global-requirements-purview.md` still apply in full — this
> list is additive.
