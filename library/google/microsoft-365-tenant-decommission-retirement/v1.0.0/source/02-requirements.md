# Requirements

These are the **solution-specific** prerequisites for decommissioning and retiring the source
Microsoft 365 tenant after the move to Google. They build on the shared **Global Requirements —
Google Workspace & Gemini Solutions** (`global-requirements-google.md`); in particular this solution
relies on GR-2 (source **Microsoft 365 / Entra** admin access), GR-3 (**DNS control** for the routed
domains), GR-5 (a **pilot scope** and change control), and GR-6 (**security, legal/eDiscovery, and
data-governance stakeholders**). Do not re-verify the shared six here — verify the items below.

> Reminder on the vendor boundary: Microsoft / Entra admin paths and Graph endpoints are authored at
> exact, current detail from Microsoft's public documentation. Where a capability or closure mechanic
> is version-dependent, it is flagged **"verify in your tenant"** — never invented.

---

## R1. Signed-off migration completion (the go/no-go)

- **Description:** A formal statement from the migration project that user-facing cutover to Google
  Workspace is **complete** — mail is delivered to Google, users work in Google, and no production
  workflow still depends on Microsoft 365.
- **Why required:** Teardown is destructive. Nothing in Phase 2 onward may run until the migration
  owner confirms cutover is done; the Phase 1 completeness verification *proves* this technically, but
  the business sign-off is the authority to begin.
- **How to verify:** Obtain the migration project's cutover sign-off (change record / email of record)
  and confirm the Google MX record is authoritative for each domain (`dig MX <domain>` returns Google,
  e.g. `smtp.google.com` / `aspmx.l.google.com`).
- **How to implement if missing:** Do **not** start. Return to the migration project and complete
  cutover; re-engage this runbook once sign-off exists.

## R2. Microsoft Graph read access for the tooling (least privilege)

- **Description:** An **Entra app registration** for the decommission tools — named
  `Decommission Read – Source-Tenant – v1` — granted **application** permissions with **read-only**
  scopes and admin consent: `User.Read.All`, `Group.Read.All`, `Directory.Read.All`,
  `Application.Read.All`, `AuditLog.Read.All`, `Domain.Read.All`, `Organization.Read.All`, and (for
  mailbox/usage completeness) `Reports.Read.All`. No write scopes are needed for verification/inventory.
- **Why required:** The five Python tools authenticate via `msal` (client-credentials flow) and read
  the tenant through Graph. Read-only scopes keep the tooling safe by default.
- **How to verify:** In the **Microsoft Entra admin center → Identity → Applications → App
  registrations**, confirm the app exists, has the scopes above under **API permissions** with
  **"Granted for <tenant>"**, and that a **client secret or certificate** is available to the operator
  (stored in the environment, never in code — see R3).
- **How to implement if missing:** Register the app (**App registrations → New registration**), add
  the Graph **Application** permissions above, click **Grant admin consent**, then create a
  certificate (preferred) or client secret under **Certificates & secrets**. Record the
  **Application (client) ID**, **Directory (tenant) ID**, and credential in the operator's secret store.

## R3. Operator credential handling (no secrets in code or repo)

- **Description:** The tenant ID, client ID, and client secret/certificate for R2 are provided to the
  tools **through the environment** (environment variables or the operator's secrets manager), never
  committed, never printed.
- **Why required:** These credentials can read the entire directory; leaking them is a breach. The
  tools are written to read `M365DECOM_TENANT_ID`, `M365DECOM_CLIENT_ID`, and
  `M365DECOM_CLIENT_SECRET` from the environment and refuse to run if absent — they contain no
  hardcoded credentials.
- **How to verify:** Confirm the three variables are set in the operator's session
  (`echo $M365DECOM_TENANT_ID` on the operator host) and that no credential appears in any script,
  config file, or the repo.
- **How to implement if missing:** Export the variables from the secret store at runtime (e.g.
  `export M365DECOM_CLIENT_SECRET=$(vault kv get -field=secret …)`); never paste secrets into files.

## R4. Retention schedule + legal-hold / eDiscovery register (from legal/records)

- **Description:** The organization's **records-retention schedule** and the current **legal-hold /
  eDiscovery** register (which mailboxes, sites, or users are under hold, and any active matters),
  supplied by the legal/records/compliance functions (GR-6).
- **Why required:** Data disposition (Phase 2) is gated on this. Data under hold or within a retention
  window must be **exported/preserved**, not deleted. This solution provides the technical inventory
  and export method; **the determination of what to keep, and for how long, belongs to legal/records.**
- **How to verify:** Confirm you have the retention schedule and a current hold register, and a named
  approver who signs off disposition. In **Microsoft Purview → Data Lifecycle Management / eDiscovery**
  confirm which holds are active *(exact Purview navigation is version-dependent — verify in your
  tenant)*.
- **How to implement if missing:** Do not dispose of any data. Engage legal/records to produce the
  schedule and hold register and to designate the disposition approver before Phase 2.

## R5. Records / evidence store for exports and closure artifacts

- **Description:** A destination the organization controls (e.g. a governed Google Drive shared drive,
  an archive bucket, or the records system) for **exported data** that must be preserved and for the
  **evidence pack** every phase produces.
- **Why required:** Preserved data must land somewhere durable and access-controlled; the audit trail
  (per-gate inventories, the final checklist/report) must be retained independently of the tenant
  being closed.
- **How to verify:** Confirm the store exists, is access-controlled, and its retention is at least as
  long as the longest applicable obligation from R4.
- **How to implement if missing:** Stand up (or nominate) the store and confirm its permissions before
  exporting anything.

## R6. Global Administrator (or scoped closure roles) on the Microsoft 365 tenant

- **Description:** For the *write* actions in Phases 3–6 (license reclamation, app-registration
  removal, DNS changes on Microsoft-hosted zones, subscription cancellation, tenant deletion), the
  operator needs **Global Administrator**, or the least-privilege combination the step names (e.g.
  **License Administrator**, **Application Administrator**, **Domain Name Administrator**, and
  **Billing Administrator**). *Tenant deletion prerequisites are version-dependent — verify current
  requirements in your tenant.*
- **Why required:** Verification is read-only (R2), but the teardown actions change or remove tenant
  objects and ultimately delete the tenant.
- **How to verify:** In **Entra admin center → Roles and administrators**, confirm the operator holds
  the required role(s).
- **How to implement if missing:** Have the tenant owner assign the role(s), preferably just-in-time
  for the change window, and remove them afterward.

## R7. DNS control and change window for the routed domains

- **Description:** Authoritative control of each domain's DNS zone (GR-3) **and** an agreed
  change-control window, because MX/SPF/DKIM/DMARC/autodiscover changes are high-impact.
- **Why required:** Phase 5 re-points survivors to Google and removes dead Microsoft records; a
  mistake here breaks mail flow.
- **How to verify:** Confirm write access to each authoritative zone and a booked change window with
  rollback approval.
- **How to implement if missing:** Obtain zone access and schedule the change window with the DNS
  owners before Phase 5.

## R8. Named pilot scope for the teardown

- **Description:** A **bounded first scope** (one domain, a small mailbox/account set, or a single DNS
  zone) to run the full procedure against before expanding tenant-wide — the GR-5 pilot applied to
  decommission.
- **Why required:** The house model is pilot-first; proving inventory → disposition → cleanup →
  re-point on a small scope de-risks the fleet-wide run.
- **How to verify:** Confirm the pilot scope is named and agreed with stakeholders.
- **How to implement if missing:** Choose and document the pilot scope before Phase 1's expand step.
