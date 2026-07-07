# Requirements

These are the **solution-specific** prerequisites for a GWMME (Google Workspace Migration for
Microsoft Exchange) implementation. They build **on** the shared category requirements in
`global-requirements-google.md` — the Google Workspace/Cloud Identity tenant (GR-1), source M365/Entra
access (GR-2), DNS control for routed domains (GR-3), identity source of truth (GR-4), a pilot scope
and change control (GR-5), and security/compliance stakeholders (GR-6). Do not re-establish those
here; the items below are what GWMME specifically adds.

Verify each item before starting Section 03 (Implementation).

> **Verify for your version.** GWMME is a versioned Google tool. Its exact supported Exchange/EWS
> versions, host OS/.NET prerequisites, mapping-file columns, and permission model are defined by the
> **build you download**. Confirm every tool-specific value below against **Google's current GWMME
> documentation** before you rely on it.

---

## R1. GWMME migration host — `Migration Host – GWMME – Primary`

- **Description:** A dedicated **Windows host** (physical or VM) reserved for the migration, meeting
  GWMME's documented OS/.NET/runtime prerequisites, with strong, stable connectivity to both the
  Microsoft source and the internet-facing Google endpoints. Sized with adequate CPU/RAM/disk for
  logs and working data.
- **Why required:** GWMME is a **client-side** tool; it runs on this host and its throughput/stability
  depend on it. A shared or under-resourced machine causes throttled, failed, or slow runs.
- **How to verify:** Confirm the host meets the GWMME system requirements for your version (OS
  version, .NET/runtime), can resolve and reach the source EWS endpoint and Google endpoints, and has
  disk headroom for logs.
- **How to implement if missing:** Provision a clean, patched Windows VM as
  `Migration Host – GWMME – Primary`; install the GWMME prerequisites Google lists for your version;
  restrict access to the migration team.

## R2. Source Exchange / M365 access + read identity — `Source Access – Exchange – App Impersonation`

- **Description:** An identity on the **Microsoft source** with the rights to **read the mailboxes in
  scope** — typically **application impersonation / application access** so one identity can read
  every in-scope mailbox — plus network reachability to the source **EWS** endpoint (Exchange Online
  or on-prem Exchange).
- **Why required:** GWMME must read each source mailbox's mail, calendar, and contacts. Without the
  correct impersonation/application permission, GWMME can authenticate but cannot open the mailboxes,
  producing permission failures.
- **How to verify:** Confirm the identity exists, is granted the impersonation/application access
  scope over the target mailboxes, and that EWS is reachable and enabled for the source. (Exact
  grant mechanism — RBAC impersonation role vs. app registration with the required application
  permission — depends on Exchange Online vs. on-prem; **verify for your version/source.**)
- **How to implement if missing:** On the Microsoft side, create/authorize the read identity and grant
  it impersonation/application access over the in-scope mailboxes under change control; confirm EWS is
  enabled. Record it as `Source Access – Exchange – App Impersonation`.

## R3. Google destination service identity — `Service Identity – Google – Migration`

- **Description:** A **Google service identity** (service account / OAuth credential) authorized to
  write **mail, calendar, and contacts** into the target Workspace users, with the migration API
  scopes GWMME requires enabled and domain-wide authorization granted where the tool needs it.
- **Why required:** GWMME writes into each target user's Gmail/calendar/contacts on the Google side and
  must be authorized to do so across the domain for the users in scope.
- **How to verify:** In the Google Admin console and Google Cloud, confirm the service identity exists,
  the required APIs are enabled, and the migration scopes are authorized for the tool. (Exact scopes
  and authorization steps are defined by the GWMME build — **verify for your version.**)
- **How to implement if missing:** Create the service identity, enable the required APIs, and grant the
  migration scopes per Google's current GWMME setup documentation. **Do not export or commit its key**;
  store credentials securely. Record it as `Service Identity – Google – Migration`.

## R4. Target Google users provisioned — `Mapping – Users – Master`

- **Description:** The **target Workspace users** for every migrating mailbox already **exist and are
  licensed** in the destination tenant, and a **master mapping** of source mailbox → target Google
  user is prepared (the input GWMME consumes, typically a CSV).
- **Why required:** GWMME migrates **into an existing target user**; it does not create accounts. A
  missing/misnamed target, or a wrong mapping row, sends data to the wrong mailbox or fails the row.
- **How to verify:** Reconcile the source mailbox list against provisioned Google users; confirm every
  in-scope source has a licensed target and exactly one mapping row.
- **How to implement if missing:** Provision/license the missing target users (via your identity
  source of truth / provisioning — GR-4), then build/complete `Mapping – Users – Master`. The
  assessment script in this solution generates the reconciliation and the mapping skeleton.

## R5. Source inventory & sizing — for wave design

- **Description:** A **read-only inventory** of the source: mailbox list, per-mailbox **item counts and
  sizes**, and special cases (shared mailboxes, resource/room calendars, very large or very old
  mailboxes, archives).
- **Why required:** Wave sizing and the throttling budget depend on **how much** is moving. Large
  mailboxes and special cases need their own handling; without sizing you cannot plan safe batches or
  set expectations for run time.
- **How to verify:** Confirm you can enumerate source mailboxes with counts/sizes (via the Microsoft
  side) and have flagged special cases.
- **How to implement if missing:** Run the discovery/assessment step (Section 03, Assess) to produce
  the inventory feeding `Mapping – Users – Master` and the wave plan.

## R6. Mail-flow / cutover coexistence plan + rollback — `Rollback Plan – Cutover – Mail`

- **Description:** A decided approach for **mail delivery during and after migration** (does mail keep
  flowing to the source until cutover, and when do **MX/DNS** change to Google?), with a **documented
  rollback** for the mail-flow and DNS changes.
- **Why required:** Mail routing, MX, and cutover are **high-impact** production changes; a botched
  cutover means lost or bounced mail. GWMME copies data but does not route live mail — that is a
  DNS/mail-flow decision that must have a back-out.
- **How to verify:** Confirm the coexistence/cutover decision is documented, the DNS/MX change window
  and approvers exist (GR-3, GR-5), and `Rollback Plan – Cutover – Mail` is written and approved.
- **How to implement if missing:** Decide the coexistence model, schedule the MX/DNS cutover under
  change control, and author `Rollback Plan – Cutover – Mail` (revert MX, re-point clients) before any
  production cutover.

---

*All Microsoft-side and Google-side steps are performed under the change-control process from GR-5.
Tool-specific values (versions, scopes, mapping columns, dialogs) are confirmed against Google's
current GWMME documentation — never assumed.*
