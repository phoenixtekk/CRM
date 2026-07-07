# Requirements

These are the **solution-specific** prerequisites for executing an M365→Google migration with
CloudM Migrate. They build on the shared **[Global Requirements — Google Workspace & Gemini
Solutions](global-requirements-google.md)**, which cover the baseline every Google-category solution
assumes: a provisioned **Google Workspace / Cloud Identity tenant with super-admin** (GR-1), the
**source Microsoft 365 / Entra environment with admin access** (GR-2), **DNS control** for the routed
domains (GR-3), an **identity source of truth and provisioning model** (GR-4), a **pilot OU/group and
change control** (GR-5), and **security/compliance stakeholders** (GR-6). Verify those first; the
prerequisites below are additive and CloudM/migration-specific.

> **Vendor boundary reminder.** CloudM platform capabilities, licensing, and console internals are
> deferred to CloudM's own documentation and flagged **"verify for your version."** The Google and
> Microsoft/Entra items below are authored at exact detail from the vendors' public docs.

---

## R1. CloudM Migrate platform provisioned (hosted or self-hosted)

- **Description:** A licensed CloudM Migrate environment. Either **hosted** (CloudM-run SaaS) or
  **self-hosted** on one or more Windows migration servers sized for the workload. Name the instance
  `Migration Platform – Enterprise – Prod`.
- **Why required:** The platform is the engine that holds the migration configuration and executes
  scan/pre-stage/delta passes. Nothing runs without it.
- **How to verify:** Sign in to the CloudM Migrate platform and confirm you can reach the migration
  configuration area and that your license covers M365→Google mail + files (and SharePoint if in
  scope). **Verify edition, license counts, and feature coverage in CloudM's licensing docs — deferred
  to CloudM.**
- **How to implement if missing:** Procure the license and stand up the platform per CloudM's
  deployment guide. For self-hosted, provision the migration server(s) meeting CloudM's stated OS,
  CPU/RAM, and .NET/runtime prerequisites (**verify current sizing and prerequisites for your
  version**), on a network with outbound HTTPS to both Microsoft and Google API endpoints.

## R2. Microsoft 365 source app registration (Entra ID)

- **Description:** An **Entra ID app registration** that CloudM authenticates as to read the source:
  Exchange Online mailboxes, OneDrive, and SharePoint. Name it `Source Connection – M365 – Prod`.
- **Why required:** CloudM reads source data over Microsoft Graph and Exchange APIs; a properly
  consented app registration (or the app-based access CloudM's connector documents) is the source
  identity.
- **How to verify:** In the **Entra admin center → App registrations**, confirm the app exists, has
  the **application permissions** CloudM's M365 connector requires (typically Graph mail/files/sites
  read plus Exchange access), and that **admin consent** has been granted (green check under **API
  permissions**). Confirm the client secret/certificate is current and stored securely. **The exact
  permission scopes are defined by CloudM's connector docs — verify for your version.**
- **How to implement if missing:** Create the app registration (**Entra admin center → App
  registrations → New registration**), add the API permissions CloudM specifies, **Grant admin
  consent for the tenant**, and create a client secret or upload a certificate. Record the
  Application (client) ID, Directory (tenant) ID, and secret/cert into the CloudM connection — never
  into source-controlled files.

## R3. Google Workspace destination service account with domain-wide delegation

- **Description:** A **Google Cloud service account** with **domain-wide delegation (DWD)** authorized
  in the Google Admin console for the OAuth scopes CloudM's Google connector requires (Gmail insert,
  Drive, Calendar, Contacts, Directory read). Name it `Destination Connection – Google – Prod`.
- **Why required:** CloudM writes migrated data into each destination user's Gmail/Drive by
  impersonating them; DWD is the mechanism that authorizes that impersonation tenant-wide.
- **How to verify:** In **Google Cloud console → IAM & Admin → Service Accounts**, confirm the account
  and its key exist and DWD is enabled. In **admin.google.com → Security → Access and data control →
  API controls → Domain-wide delegation**, confirm the service account's **client ID** is present with
  the required scopes listed. **Confirm the exact scope list against CloudM's Google connector docs —
  verify for your version.**
- **How to implement if missing:** Create the service account and a JSON key in Google Cloud; enable
  DWD; then in the Admin console add the service account **Client ID** under **Domain-wide delegation**
  with the CloudM-specified OAuth scopes (comma-separated). Also enable the required **APIs** (Gmail,
  Drive, Admin SDK, Calendar, People) in the Cloud project. Store the JSON key in the CloudM
  platform's secured credential store — never in the repo.

## R4. Destination users and Shared Drives provisioned

- **Description:** The **destination Google Workspace accounts** for the wave's users exist and are
  licensed, and any **Shared Drives** that will receive SharePoint/team content are created and named
  (`<Team> Shared Drive`). Provisioning flows from the identity source of truth (GR-4) via GCDS/SCIM.
- **Why required:** CloudM writes into existing destination mailboxes/Drives; missing or unlicensed
  target accounts cause per-user failures.
- **How to verify:** In **admin.google.com → Directory → Users**, confirm the wave's target accounts
  exist and are licensed. In **Shared drives**, confirm the target Shared Drives exist.
- **How to implement if missing:** Provision users via GCDS/SCIM from the source of truth; assign
  licenses; pre-create Shared Drives for team/SharePoint destinations.

## R5. Source→destination mapping (user list CSV)

- **Description:** A **user-list CSV** mapping each source M365 identity (UPN/primary SMTP) to its
  destination Google address, plus any file source→Shared Drive mappings. This is the artifact CloudM
  consumes to scope a run. (The included `build-migration-userlist.py` tool generates a
  connector-agnostic version of this from the Google directory + a source export — **align the final
  column headers to CloudM's import template for your version.**)
- **Why required:** CloudM scopes each scan/pre-stage/delta pass to the users in the list; an
  incorrect mapping migrates data to the wrong account.
- **How to verify:** Confirm every source UPN resolves to exactly one destination address that exists
  in the Google directory, and that there are no duplicates or unmapped rows.
- **How to implement if missing:** Export the source user list from M365/Entra, reconcile against the
  Google directory, and produce the mapping CSV (the tool assists). Review with the identity owner
  before import.

## R6. Migration profile design decided

- **Description:** A documented decision on **what** each wave migrates (mail incl. date-range filter,
  calendar, contacts, OneDrive, SharePoint), **fidelity expectations**, **throttling limits**, and
  **exclusions** (e.g. Recoverable Items, huge archives). Captured as `Migration Profile –
  Mail+Drive – Standard`.
- **Why required:** The profile is the reusable contract for every wave; deciding it once keeps waves
  consistent and makes pre-stage/delta behavior predictable.
- **How to verify:** Confirm the profile choices are written down and approved by the migration and
  security owners (retention/eDiscovery implications per GR-6).
- **How to implement if missing:** Run a design workshop to set scope, filters, and throttling; record
  the decisions; then build the profile in CloudM (**console steps deferred to CloudM docs**).

## R7. Change window, cutover plan, and rollback

- **Description:** An approved **change window** for each wave's **MX/mail-routing cutover** (GR-3
  DNS), a written **cutover runbook**, and a documented **rollback** (revert MX, keep M365 authoritative)
  should validation fail.
- **Why required:** Cutover changes mail flow — the highest-impact change in the project. Rollback must
  be pre-agreed, not improvised.
- **How to verify:** Confirm the change ticket, window, approvers, and rollback steps exist for the
  wave.
- **How to implement if missing:** Draft the cutover runbook and rollback, route through change
  control (GR-5), and get sign-off before the wave's cutover.
