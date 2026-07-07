# Requirements

These are the **solution-specific** prerequisites for running Microsoft 365 messaging support
operations with ITIL discipline. They build **on** the shared category prerequisites in
`global-requirements-messaging.md` (a Microsoft 365 tenant with Exchange Online; least-privilege
Exchange/365 admin access; the ExchangeOnlineManagement (EXO V3) + Microsoft Graph toolchain; DNS
control; hybrid Exchange/AD access where applicable; and a pilot scope + change control). Verify the
shared set first, then confirm the items below. Each item lists **Description / Why required / How to
verify / How to implement if missing.**

> Note on access: this is a *support-operations* solution, so the admin access it needs is
> **least-privilege operational** access for the support tiers (read-heavy for L2, change-capable for
> L3), plus the ITSM tooling and people/process items below. It does not itself require any new
> mail-flow configuration.

## R1. A ticketing / ITSM tool with recorded SLAs

- **Description:** A ticketing / IT Service Management system (any vendor — e.g. ServiceNow, Jira Service
  Management, Freshservice, Zendesk, Halo) that can hold **incident** and **problem** record types,
  **categories**, **priorities**, **assignment groups** (for L2/L3), and **SLA timers**, and that can
  **export tickets to CSV** for reporting.
- **Why required:** The incident and problem lifecycles, the escalation paths, and every metric
  (SLA, FCR, CSAT, reopen rate) live in this tool. Two of the included scripts read a **CSV export** of
  tickets, so CSV export is a hard requirement.
- **How to verify:** Confirm you can create an Incident and a Problem record, set category/priority, and
  export a ticket list to CSV with at least these fields (names vary by tool): a ticket ID, created/opened
  timestamp, resolved/closed timestamp, priority/severity, category, assignment group, reopened flag or
  reopen count, first-contact-resolved flag, and CSAT score.
- **How to implement if missing:** Stand up (or extend) the ITSM tool; define the record types,
  categories, priorities, and assignment groups per the Implementation Guide; enable CSV export.

## R2. Messaging admin access for the support tiers (least privilege)

- **Description:** Operational Microsoft 365 access scoped to each tier: **L2** typically needs a
  **read/triage** posture (e.g. **View-Only Organization Management**, plus targeted role groups such as
  **Help Desk** or **Recipient Management** for the specific tasks it owns — reading mail flow, releasing
  quarantine, managing mailbox permissions); **L3** needs **change-capable** roles (e.g. **Organization
  Management** / **Hygiene Management** / **Records Management** as the task requires). Delegated,
  role-based, MFA-protected.
- **Why required:** L2 must diagnose without the ability to make broad production changes; L3 must be
  able to remediate. The included scripts connect with the **operator's own** modern-auth account and
  inherit its permissions — they carry **no credentials**.
- **How to verify:** In the Microsoft 365 admin center / **Exchange admin center (EAC) → Roles**, confirm
  the role-group membership for representative L2 and L3 accounts. Confirm `Connect-ExchangeOnline` and,
  where used, `Connect-MgGraph` succeed for those accounts.
- **How to implement if missing:** Have a Global/Exchange Administrator create/assign the least-privilege
  role groups for each tier under change control. Least privilege is version-independent guidance;
  **verify exact role-group names/capabilities in your tenant** as Microsoft periodically adjusts them.

## R3. Microsoft Graph permission for Service Health (service-availability handling)

- **Description:** The ability to read the **Service Health** / **Service Communications** data
  programmatically — Microsoft Graph delegated scope **`ServiceHealth.Read.All`** (used by the Service
  Health triage helper), *or* equivalent portal access to the **Service Health Dashboard** in the M365
  admin center for teams that read it manually.
- **Why required:** Fast "is it us or Microsoft?" triage depends on reading current **service issues**
  and **advisories**. `ServiceHealth.Read.All` requires **admin consent** and an appropriate admin role
  to view service health.
- **How to verify:** Confirm the operator can open **Health → Service health** in the M365 admin center;
  for the script path, confirm `Connect-MgGraph -Scopes "ServiceHealth.Read.All"` consents and
  `Get-MgServiceAnnouncementIssue` returns data. **Verify scope availability in your tenant/cloud** —
  Government clouds use `graph.microsoft.us`.
- **How to implement if missing:** Have an administrator grant/consent the delegated scope, or designate
  who has portal Service Health visibility for on-call.

## R4. An on-call rota and escalation contacts

- **Description:** A defined **on-call rotation** for after-hours **major incidents** (who is paged, in
  what order, with a documented secondary/backup), plus current **escalation contacts**: L3 engineering,
  the Microsoft support entry point (M365 admin center Support / Premier/Unified contract details), and
  the third-party vendor support contacts (gateway, archive, signature).
- **Why required:** Major messaging incidents (org-wide mail-flow outage, domain-wide auth failure)
  happen outside business hours; a rota and current contacts are what turn a page into a coordinated
  response.
- **How to verify:** Confirm a published rota (in the ITSM tool or a paging tool such as PagerDuty/Opsgenie
  or an on-call calendar) and a current contacts list; confirm the Microsoft support entitlement is known.
- **How to implement if missing:** Build the rota, assign primary/secondary per period, and record
  escalation contacts in a single, access-controlled runbook location.

## R5. A knowledge-base (KB) platform

- **Description:** A platform to hold **KB articles** and **named runbooks** (a wiki, the ITSM tool's KB
  module, SharePoint, or similar) with **versioning**, **ownership**, and a **review date** per article.
- **Why required:** First-Call-Resolution, reopen-reduction, and onboarding all depend on current,
  findable knowledge. The problem-management loop publishes **known-error** workarounds here.
- **How to verify:** Confirm analysts can find, create, and version KB articles, and that each article
  can carry an owner and a next-review date.
- **How to implement if missing:** Stand up (or nominate) the KB platform and seed the structure defined
  in the Implementation Guide (categories mirror the ticket categories).

## R6. Defined SLA targets and the metric baseline

- **Description:** Agreed **SLA targets** per priority (response and resolution), and a **baseline** for
  the operational metrics you will manage to: SLA attainment, **First-Call-Resolution (FCR)**, **CSAT**,
  and **reopen rate**.
- **Why required:** You cannot manage to SLA or show improvement without agreed targets and a starting
  baseline; the Reporting script computes attainment against the targets you set.
- **How to verify:** Confirm documented SLA targets per priority and a first measurement of FCR / CSAT /
  reopen rate exist (even if rough).
- **How to implement if missing:** Agree SLA targets with the service owner, then run the Reporting
  script once over a recent ticket export to establish the baseline.

## R7. Reporting / analyst workstation

- **Description:** A workstation with **PowerShell 5.1 or 7+**, the **ExchangeOnlineManagement (EXO V3)**
  module, and (for the Service Health helper) the **Microsoft.Graph** PowerShell module, able to reach
  the M365 endpoints for your cloud (Commercial or Government).
- **Why required:** The five included scripts run here.
- **How to verify:** `Get-Module -ListAvailable ExchangeOnlineManagement, Microsoft.Graph`; confirm
  `Connect-ExchangeOnline` succeeds.
- **How to implement if missing:** `Install-Module ExchangeOnlineManagement` and `Install-Module
  Microsoft.Graph` (current user scope), then confirm modern-auth sign-in.
