# 2. Requirements

These are the **solution-specific** prerequisites for implementing event-based retention in Microsoft
Purview. They build **on** the shared Purview category requirements in
**`global-requirements-purview.md`** (a Microsoft 365 tenant with the required Purview/compliance
licensing; least-privilege Purview roles and portal access; the Security & Compliance PowerShell + Graph
toolchain; the in-scope data sources/workloads; the compliance/records/privacy/legal stakeholders; and a
pilot scope with change control). Do not repeat those — verify them first, then confirm the event-based
prerequisites below. Each is stated as **Description / Why / Verify / Implement if missing.**

---

## 2.1 Compliance licensing for event-based retention & records
- **Description:** The Microsoft 365 / Microsoft Purview licensing that unlocks **event-based retention
  labels**, and — where the category is also a record — **records management** (record / regulatory-record
  labels, the file plan) and **auto-apply** label policies. These advanced retention capabilities are
  generally in an **E5 / E5 Compliance-class** plan or the equivalent Purview add-on; basic date-based
  retention is broadly available but is **not** what this solution needs.
- **Why required:** Event-based retention is **plan-gated**. Without the right plan, the "start retention
  based on an event" trigger, event types, and any record designation in the design cannot be created.
- **Verify:** In the Microsoft 365 admin center → Billing → Licenses, confirm the compliance plan/add-on.
  In the Microsoft Purview portal, confirm **Data lifecycle management** and (for records categories)
  **Records management** are visible, and that the **Events** area is present. *Feature-to-plan mapping
  changes — verify the exact entitlement in your tenant.*
- **Implement if missing:** Have licensing assign/purchase the required compliance plan or add-on to the
  admin (and any accounts that will manage events and records) before configuration.

## 2.2 The event-based schedule (input from records & legal)
- **Description:** For each event-based category, the authoritative determinations from records/legal: the
  **event** that starts the clock (termination, contract expiry, product end-of-life, …), the **retention
  period after the event**, whether the category is a **record** or **regulatory record**, the applicable
  **regulatory citation/authority**, and the disposition path at expiry (automatic vs review).
- **Why required:** This solution **implements** these determinations; it does not author them. The event
  types, labels, and durations are a direct translation of the schedule — without it there is nothing
  correct to configure, and no event/period may be invented.
- **Verify:** Confirm records/legal has provided (or signed off) the event-based categories naming, for
  each, the event, the post-event period, record status, citation, and disposition — or at least a pilot
  subset.
- **Implement if missing:** This is **deferred to the records-management / compliance / legal functions** —
  request the determinations before configuring. Do not invent events, retention periods, record status, or
  disposition rules.

## 2.3 The system of record and the event-raise process (operational owner)
- **Description:** For every event type, the **authoritative system of record** that knows when the event
  actually happens (**HR/HRIS** for termination, **contract-lifecycle-management/CLM** for contract expiry,
  **PLM/ERP** for product end-of-life), and a named **operational owner and process** for **raising the
  retention event** when the system of record signals the event — including which **asset ID(s) / keyword(s)**
  identify the affected content.
- **Why required:** An event type and label do nothing until an event is **raised** with matching asset IDs
  / keywords. This is the single most common point of failure: labels sit **pending forever** if no reliable
  process raises the event. The raise process — manual, scripted, or integrated — is a core deliverable.
- **Verify:** Confirm, per event type, the system of record, the signal that indicates the event, the owner
  who raises the event, and the asset-ID / keyword values that will be supplied. Confirm whether raising is
  manual (portal), scripted (`New-ComplianceRetentionEvent`), or integrated from the system of record.
- **Implement if missing:** Identify the system of record and owner, and define the raise process (Section 3
  provides the scripted method) before relying on any event-based label in production.

## 2.4 The asset-ID / keyword matching strategy and its data
- **Description:** The decision, per event-based category, of **how content is matched** to a retention
  event — **asset ID** (the **Compliance Asset Id** property on SharePoint/OneDrive documents) or **keyword**
  (query, typically for Exchange) — **and** confirmation that the matching data will actually exist on the
  content: which identifier is used (employee ID / contract number / SKU), **who stamps it, and when**
  (ideally at ingestion), before any event is raised.
- **Why required:** When an event is raised, Purview matches content by asset ID / keyword; if the
  `Compliance Asset Id` was never stamped, or the keyword does not match, the event **finds nothing** and no
  clock starts. Matching is only as good as the data on the content.
- **Verify:** Confirm the matching mechanism per category; confirm the asset-ID source/format and the
  stamping process (or the keyword query and that it reliably matches in-scope content and excludes
  out-of-scope content); confirm the `Compliance Asset Id` column is available on the in-scope
  SharePoint/OneDrive locations. *Property behavior and names are version-dependent — verify in your tenant.*
- **Implement if missing:** Define the asset-ID scheme and stamping process (at ingestion where possible),
  or define and test the keyword query, so matching data exists on content before events are raised.

## 2.5 Roles for event-based retention & records
- **Description:** The least-privilege role groups to create and operate event-based retention in Microsoft
  Purview: **Records Management** or **Compliance Administrator** / **Compliance Data Administrator** for
  event types, labels, and label policies; and — because **raising a retention event starts real retention
  clocks** — a controlled, named set of accounts authorized to **raise events**. Where categories are
  records, the corresponding records role and (for disposition) **Disposition Management** apply, deferred to
  the records product.
- **Why required:** Creating event types, event-based labels, and label policies requires the matching
  Purview role; raising events is high-impact and must be restricted to authorized operators to prevent an
  accidental or premature clock start.
- **Verify:** Microsoft Purview portal → **Roles & scopes → Permissions (role groups)** — confirm the
  admin's membership; confirm exactly which accounts can raise events.
- **Implement if missing:** Have a Global Admin / Compliance Admin add accounts to the least-privilege role
  groups under change control, and formally designate (and limit) the event-raising operators.

## 2.6 In-scope workloads and content state (SPO / OneDrive / Exchange)
- **Description:** Confirmation of which **workloads and locations** hold the event-based content and that
  they support the matching mechanism — **SharePoint/OneDrive** for asset-ID matching (the documents that
  carry the `Compliance Asset Id`), and **Exchange** where keyword matching is used — plus how labels reach
  that content (published, auto-applied, or default library label, the last deferred to the SharePoint
  records product).
- **Why required:** Asset-ID matching is a SharePoint/OneDrive mechanic; keyword matching is typical for
  Exchange. Scoping the wrong workloads or locations means labels never reach the content, or events never
  match it.
- **Verify:** Confirm the in-scope locations per category and that the intended matching mechanism is
  supported there; confirm the label-application method per location.
- **Implement if missing:** Define the location scope and application method per category before authoring
  labels and policies.

## 2.7 Alignment with the broader retention/records program (not duplication)
- **Description:** Knowledge of the organization's **existing Microsoft Purview retention/records posture**
  — existing retention labels/policies, existing event types, and the org-wide **data lifecycle & records
  management** program — so this event-based work **aligns** to it (consistent label names, no duplicate
  event types, understood **retention precedence**) rather than conflicting.
- **Why required:** Event-based labels interact with any other retention touching the same content via
  Microsoft's retention-precedence rules; a duplicate event type or an unaware overlapping label produces
  the wrong effective outcome. Records declaration, the file plan, and disposition operations are owned by
  the broader program.
- **Verify:** Enumerate existing labels, event types, and policies (`Get-ComplianceTag`,
  `Get-ComplianceRetentionEventType`, `Get-RetentionCompliancePolicy`) and confirm which are owned by the
  broader program; note any overlap.
- **Implement if missing:** Engage the retention/records program owners; capture the existing baseline (the
  assessment script does this) before adding event types or labels.

## 2.8 Automation toolchain for event-based retention
- **Description:** The **Security & Compliance PowerShell** endpoint (`Connect-IPPSSession` from the
  **ExchangeOnlineManagement** module) for event types, labels, label policies, and raising events
  (`Get-/New-/Set-ComplianceRetentionEventType`, `New-ComplianceTag`, `New-RetentionCompliancePolicy`/`Rule`,
  `Get-/New-ComplianceRetentionEvent`), and **Microsoft Graph PowerShell** for supporting reads — a
  modern-auth / MFA-capable admin.
- **Why required:** The provided scripts and the configuration/raise steps run through Security & Compliance
  PowerShell (and Graph for supporting reads); both must connect.
- **Verify:** `Connect-IPPSSession` succeeds and `Get-ComplianceTag` / `Get-ComplianceRetentionEventType`
  return without error; `Connect-MgGraph` succeeds where used. In Government clouds, confirm the correct
  `-ConnectionUri` / endpoint.
- **Implement if missing:** Install the **ExchangeOnlineManagement** and **Microsoft.Graph** modules and
  confirm modern-auth sign-in before running steps. Never store credentials in scripts.

## 2.9 Change control and a documented rollback for event-based retention
- **Description:** An approved change window and a **rollback plan** specific to event-based retention: how
  to unpublish/disable a label policy, how to remove a non-record event-based label, and the explicit note
  that **a raised event that has already started (and, for retain-then-delete, elapsed) a delete clock, and
  any regulatory-record designation, cannot be rolled back**.
- **Why required:** Raising an event and starting a retention clock on real content is high-impact; a
  documented, rehearsed rollback is the safety net for the reversible parts (labels, policies) and forces a
  conscious decision on the irreversible parts (an elapsed event-based deletion, a regulatory record).
- **Verify:** Confirm a change ticket, an approver, and a written rollback covering label-policy disable,
  label removal, and the explicit no-rollback flag on any regulatory-record category and on any real (non-test)
  event that starts a delete clock.
- **Implement if missing:** Author the rollback (Section 3 provides the steps), get change-control sign-off,
  and explicitly flag irreversible categories/actions as **no-rollback** before applying them. Raise test
  events only on disposable assets.
