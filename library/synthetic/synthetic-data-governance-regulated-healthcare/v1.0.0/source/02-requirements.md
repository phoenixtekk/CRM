# Requirements

These are the **solution-specific** prerequisites for standing up synthetic data governance. They
build **on** the six category-wide requirements in `global-requirements-synthetic.md` (a Python
data/engineering environment, a target clinical data model, an isolated non-production environment,
privacy/governance/compliance stakeholders and policy, AI/QA use cases and a pilot scope, and
read-only minimized reference access). Verify those first — this file does not repeat them.

The governance work also inherits the category **safety/vendor/regulatory boundary**: never real
PHI into a shared harness/twin/AI test environment; vendor tooling is referenced at the pattern
level; and HIPAA/HITRUST de-identification, IRB/privacy sign-off, and disclosure-risk acceptance are
**deferred** to the organization's privacy, compliance, and legal functions.

---

## R1. A declared control set (the standards to align to)

- **Description:** A written, versioned list of the specific controls the synthetic-data capability
  must align to — the selected HIPAA Security Rule safeguards, the applicable HITRUST CSF control
  references, and any enterprise data-governance control identifiers — each with a stable ID and a
  short statement. This is the **input** the control mapping is measured against.
- **Why required:** The compliance checker (Tool 4) maps the governance controls this solution
  operates to *your* declared control set. Without a declared set there is nothing to align to and
  no evidence view to produce.
- **How to verify:** Confirm with the compliance/privacy function that a versioned control set
  exists, that each control has an ID and statement, and that it is the authoritative list for this
  capability. Save it as `Declared Control Set – Enterprise – v1`.
- **How to implement if missing:** Ask the compliance function to declare the in-scope controls
  (they decide which apply — this solution does not). Capture them in the control-set JSON the
  checker consumes. Do **not** invent controls or their applicability.

## R2. A synthetic-asset classification scheme

- **Description:** A small, explicit set of classification values for synthetic/test assets — for
  example `synthetic-only` (no real data used), `derived-from-real-stats` (built from governed
  reference statistics), and `contains-minimized-real` (read-only minimized real data under the
  privacy controls) — each with a handling rule (allowed environments, access, retention).
- **Why required:** Classification drives access, approval scrutiny, and which controls apply. The
  catalog and approval tools record it per asset; without an agreed scheme classifications are
  inconsistent and ungovernable.
- **How to verify:** Confirm the scheme is documented, that each value has a handling rule, and that
  the privacy function has reviewed it. Save it as `Classification Scheme – Enterprise – v1`.
- **How to implement if missing:** Draft the scheme with the data-governance and privacy
  stakeholders during **Design**; keep it minimal (3–5 values). The classification of any specific
  asset is a stewarded decision, not an automated one.

## R3. Named governance roles (owner / steward / reviewer / consumer)

- **Description:** The people (or role assignments) who will operate the governance: a **data
  owner** accountable for each asset domain, a **steward** who catalogs and classifies, a
  **privacy/compliance reviewer** who approves releases, and the **consumers** (AI/QA teams) who
  request assets. Map to the existing RACI where one exists.
- **Why required:** Approval and classification are recorded human decisions; they need named,
  accountable roles. An approval record with no reviewer is not an approval.
- **How to verify:** Confirm each role has a named holder (or group) and that reviewers have the
  authority to approve releases. Save as `Governance Roles – Enterprise – v1`.
- **How to implement if missing:** Assign the roles during **Design**, reusing existing
  data-governance roles where possible. A single person may hold multiple roles in a small org, but
  requester and approver must not be the same person on a given release.

## R4. A catalog store location (governed, versioned)

- **Description:** A governed, access-controlled, version-controlled location for the JSON-backed
  governance registers (catalog, classification/approval log, control mapping) — for example a
  restricted repository or the metadata layer of an existing enterprise data catalog. It holds
  **metadata only**, never the asset payloads and never real PHI.
- **Why required:** The registers are the evidence of governance. They must be durable, auditable
  (change-tracked), and access-controlled so approval records cannot be silently altered.
- **How to verify:** Confirm the location exists, is access-controlled and version-tracked, and that
  the steward can write to it while consumers can read the parts they need. Save as
  `Governance Register Store – Enterprise – v1`.
- **How to implement if missing:** Provision a restricted, version-controlled location before
  registering the first asset. The Python tools read/write JSON files that live here.

## R5. An inventory hook into where synthetic/test assets live

- **Description:** A read path to the environments and storage where synthetic/test assets actually
  exist today (sandbox buckets, test databases, AI feature stores) so the assessment can discover
  what is already out there — even if only as a provided inventory export (paths + basic metadata),
  never the payloads.
- **Why required:** Governance starts by finding the shadow assets already in circulation. The
  readiness assessment (Tool 1) profiles an inventory to show how many assets have no lineage,
  classification, or approval today.
- **How to verify:** Confirm you can obtain a metadata inventory (asset id/path, environment,
  approximate origin) of existing synthetic/test assets — read-only, metadata-only.
- **How to implement if missing:** Ask the platform/AI teams for an inventory export of their test
  data locations. If none exists, the assessment starts from the pilot's assets only and the
  expansion phase widens coverage.
