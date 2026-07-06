# 2. Requirements — Microsoft 365 ↔ Google Workspace Coexistence

Verify **every** requirement below before starting the implementation runbook (`03-implementation.md`).
Each requirement is stated as **Description → Why required → How to verify → How to implement if
missing**. These are in addition to the Google-category **global requirements**
(`global-requirements-google.md`), which cover the base tenants, DNS control, identity source of
truth, pilot scope, and governance stakeholders.

**Naming used throughout (reuse verbatim):**
- Shared vanity domain: `contoso.com`
- Google role account (used by Exchange to read Google availability): `svc-interop-exo@contoso.com`
- Exchange role account (used by Google to read Exchange availability): `svc-interop-gcal@contoso.com`
- Exchange outbound relay connector: **`Coexistence – EXO→Google Connector`**
- Directory-sync marker OU/group: **`Coexistence – Synced`**
- Pilot group: **`Coexistence – Pilot Members`**

---

## R1 — Administrative access to **both** platforms

- **Description:** A **Google Workspace super-admin** account **and** a Microsoft 365 account with the
  roles the steps name (Exchange admin for mail flow/connectors; Global Admin or the least-privilege
  equivalent for domain, Calendar-endpoint, and directory work).
- **Why required:** Every pillar changes configuration on both sides; you cannot configure split
  delivery, Interop, or directory sync from one platform alone.
- **How to verify:** Sign in to **admin.google.com** as super-admin and to **admin.microsoft.com** /
  **admin.exchange.microsoft.com** with the required role.
- **How to implement if missing:** Obtain the roles from each tenant owner before starting; record
  them in change-control.

## R2 — Shared/verified domain on both platforms

- **Description:** The domain being coexisted (`contoso.com`) is **added and verified** on *both*
  Google Workspace and Microsoft 365.
- **Why required:** Split delivery requires the same SMTP domain to be a recognized (accepted) domain
  on each platform so each can decide "mine, or relay to the other."
- **How to verify:** Google Admin console → **Account → Domains → Manage domains** shows the domain
  verified; Microsoft 365 admin center → **Settings → Domains** shows it verified; Exchange admin
  center → **Mail flow → Accepted domains** lists it.
- **How to implement if missing:** Add and verify the domain (TXT/CNAME) on whichever platform is
  missing it. Do **not** yet change its authoritative/relay type — that is a Configure-phase step.

## R3 — DNS control for MX, SPF, DKIM, DMARC

- **Description:** Ability to edit the authoritative DNS zone for `contoso.com` — specifically **MX**
  (routing primary), **SPF** (authorize both senders), **DKIM** (one selector per platform), and
  **DMARC**.
- **Why required:** MX decides which platform is inbound-primary; SPF/DKIM/DMARC must accommodate two
  sending platforms or legitimate mail will fail authentication and be dropped.
- **How to verify:** Confirm write access to the zone; record the **current** MX/SPF/DKIM/DMARC as the
  rollback baseline (`GWCOEX-Discovery.ps1` captures the M365 side; capture the Google/DNS side too).
- **How to implement if missing:** Coordinate with the DNS owner; stage all changes under change
  control with lowered TTLs first (see `07-best-practices.md`).

## R4 — Decided **MX-primary** platform and routing direction

- **Description:** A documented decision on which platform is **MX-primary** during coexistence and
  therefore which platform **relays** unknown recipients to the other (and when, if ever, MX flips).
- **Why required:** Split delivery is asymmetric — exactly one platform receives inbound first and
  relays the remainder. The relay connector and Google routing rule are built for that direction.
- **How to verify:** Confirm the current MX target and the agreed coexistence direction are written
  down and approved.
- **How to implement if missing:** Decide with the migration owners (typical early state: Google
  MX-primary relaying unknowns to M365; late state: the reverse). Record it; the runbook builds to it.

## R5 — Exchange side ready for internal-relay mail flow

- **Description:** On Exchange Online, the ability to set the shared domain's **Accepted Domain** type
  to **Internal relay** and to create an **outbound connector** to Google's smart host.
- **Why required:** Without internal-relay + a connector, Exchange NDRs mail addressed to Google-hosted
  recipients instead of relaying it.
- **How to verify:** Exchange admin center → **Mail flow → Accepted domains** (can you edit the type?)
  and **Mail flow → Connectors** (can you create a connector?). `GWCOEX-Discovery.ps1` reports the
  current accepted-domain types and connectors.
- **How to implement if missing:** Grant the Exchange admin role; confirm no conflicting existing
  connector already claims the domain.

## R6 — Google side ready for split-delivery routing

- **Description:** Access to **Apps → Google Workspace → Gmail → Routing** (and **Hosts**) in the
  Google Admin console to define a **split-delivery** rule that routes unknown recipients to the M365
  host.
- **Why required:** This is the Google-side mirror of internal relay — it forwards mail for
  recipients not hosted in Google to Exchange Online rather than bouncing.
- **How to verify:** Confirm the Gmail **Routing** and **Hosts** pages are accessible; note the M365
  inbound host (`contoso-com.mail.protection.outlook.com`).
- **How to implement if missing:** Assign a role that includes Gmail settings; obtain the domain's
  M365 `*.mail.protection.outlook.com` value from Microsoft 365 admin center → **Settings → Domains**.

## R7 — Free/busy interop prerequisites (both directions)

- **Description:** The building blocks for **Calendar Interop**:
  - a dedicated **Google role account** `svc-interop-exo@contoso.com` (standard user, Calendar enabled,
    no personal calendar use) that Exchange uses to read Google availability;
  - a dedicated **Exchange role account** `svc-interop-gcal@contoso.com` (standard mailbox, password
    non-expiring if basic auth) that Google uses to read Exchange availability;
  - an **Exchange endpoint** reachable by Google — **Microsoft 365 Graph API** endpoint (app
    registration with the required Calendars permission) or the legacy **EWS URL**
    (`https://outlook.office365.com/EWS/Exchange.asmx`) over **port 443** with a public-CA TLS
    certificate.
- **Why required:** Interop is bidirectional and each direction authenticates with its own role
  account; Google must reach the Exchange endpoint to resolve availability.
- **How to verify:** Confirm both role accounts exist and are licensed/enabled; from the internet,
  confirm the Exchange endpoint responds on 443. **Graph-API endpoint availability can be
  preview/rolling-out — verify the endpoint types offered in your tenant.**
- **How to implement if missing:** Create the two role accounts; register the app (Graph) or confirm
  EWS reachability; apply availability sharing (`Set-MailboxCalendarFolder … -SharingPermissionFlags`
  / detail level) on the Exchange side.

## R8 — Directory-sync mechanism and host

- **Description:** A **directory-sync** path from the identity source of truth into **both** platforms:
  **Google Cloud Directory Sync (GCDS)** installed on a supported host with LDAP access to AD (for the
  Google side), and Entra provisioning (Entra Connect / cloud sync, or native Entra) for the Microsoft
  side. A dedicated **Google provisioning admin** (e.g. `svc-gcds@contoso.com`) for GCDS OAuth.
- **Why required:** A unified directory/GAL across platforms depends on the same source projecting
  users, groups, and cross-platform contacts into each ecosystem. GCDS is **one-way** (never writes to
  AD).
- **How to verify:** Confirm the source of truth (per global requirement 4), that GCDS's host can reach
  LDAP (port 389/636), and that the Google provisioning admin can authorize GCDS. `GWCOEX-Discovery.ps1`
  reports the M365/Entra recipient and contact counts.
- **How to implement if missing:** Stand up a GCDS host (separate from the domain controller is
  recommended), create the provisioning admin, and define which OUs/groups sync. Decide how each
  platform represents the *other* platform's recipients (Google **shared contacts** ↔ Exchange
  **mail contacts / mail users**).

## R9 — A pilot scope and change control

- **Description:** A named **pilot group** (**`Coexistence – Pilot Members`**) spanning both platforms
  (some Google-hosted, some M365-hosted users) and a change-control window for mail-flow/DNS/identity
  changes.
- **Why required:** The model is **Assess → Configure → Pilot → Validate → Expand**; mail-flow and DNS
  changes are high-impact and must be proven on a small, representative set before fleet rollout.
- **How to verify:** Confirm the pilot group exists with members on both platforms and that an approval
  path/window is available.
- **How to implement if missing:** Create **`Coexistence – Pilot Members`**; include at least a few
  users on each platform plus one resource/room and one shared mailbox equivalent; agree the change
  window with the owners.

---

*All prerequisites met? Proceed to `03-implementation.md`. Any gap — especially R3 (DNS), R4 (routing
direction), or R9 (pilot) — is a stop condition: coexistence changes production mail flow and must not
begin until the baseline is captured and the pilot and rollback are in place.*
