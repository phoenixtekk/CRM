# 1. Solution Overview — MSP Tool Stack Design & Standup — PSA, RMM & Patch Management

## What this solution delivers

A managed-services practice runs on a small set of internal platforms that, together, form its operating backbone. This solution designs and **stands up that backbone** end to end: the **PSA** (Professional Services Automation — ticketing, contracts, time tracking, billing), the **RMM** (Remote Monitoring & Management — agents, monitoring, scripting, automation), and a **Patch Management** engine (delivered either through the RMM or through Microsoft Intune / Windows Update for Business), plus the **integrations** that make them behave as one system (PSA↔RMM ticket sync, asset/CMDB feed, alert→ticket flow). It also delivers the **operating standards** (naming, site taxonomy, policies, roles) and a repeatable **client-onboarding workflow** so every new managed client is stood up the same way, every time.

This is a multi-platform **program**, not a single product wizard. The deliverables are vendor-neutral by design: the architecture, selection criteria, standards, integration design, onboarding workflow, and validation apply regardless of which PSA, RMM, or patch engine the practice selects. Where a concrete console is named (for example Microsoft Intune as the patch engine), exact navigation paths are given; where the platform is vendor-specific, you are directed to the chosen vendor's admin console and documentation for the product-specific clicks.

## Who this is for

- A new or growing MSP that needs to assemble its core tool stack for the first time.
- An established practice consolidating fragmented or inherited tooling onto a clean, standardized model.
- An IT department adopting the managed-services operating model internally (multi-site or multi-business-unit).

## The standard MSP operating model

The standard MSP operating model treats the stack as three cooperating planes:

1. **System of record (PSA).** Where work, contracts, time, and money live. The PSA is the single source of truth for tickets, clients (companies), configurations, agreements, and billing.
2. **System of action (RMM).** Where the practice sees and changes endpoints — agents on every managed device, monitoring, alerting, remote control, and scripted automation.
3. **System of compliance (Patch).** Where operating-system and third-party updates are governed on a ring-based schedule with measurable compliance, run by the RMM's patch module or by Intune / Windows Update for Business (WUfB).

The value of the stack is in the **seams**: alerts from the RMM become tickets in the PSA automatically; assets discovered by the RMM populate the PSA's CMDB; technician time logged against a ticket flows to billing. Designing those seams deliberately — rather than letting each tool operate in isolation — is what separates a professional practice from a collection of disconnected tools.

## Phase model

This solution follows a seven-stage phase model. Each stage maps to the factory's Assess → Configure → Pilot → Validate → Expand lifecycle:

| Stage | Purpose | Lifecycle |
|-------|---------|-----------|
| **Assess** | Inventory current tooling, contracts, and readiness; pick platforms against selection criteria. | Assess |
| **Design** | Define the operating standards: naming, site taxonomy, policy model, role model, integration design. | Configure |
| **Stand up** | Provision the PSA, RMM, and patch engine; apply the standards. | Configure |
| **Integrate** | Wire PSA↔RMM ticket sync, asset/CMDB feed, and alert→ticket flow. | Configure |
| **Onboard a client** | Run the standardized client-onboarding template against a pilot client. | Pilot |
| **Validate** | Verify each plane and each integration with PASS/FAIL evidence. | Validate |
| **Operate** | Adopt the day-to-day operating cadence; expand to the full client base. | Expand |

## Named objects you will create

This solution uses a strict `<Purpose> – <Scope> – <Stage>` naming convention, reused verbatim across every object so the stack is self-documenting. The core objects created are:

- **PSA boards/queues:** `Service Desk – Reactive – Triage`, `Service Desk – Reactive – Dispatch`, `Projects – Onboarding – Delivery`, `NOC – Alerts – Automated`.
- **RMM sites/policies:** `Client Site – {ClientName} – Production`, `Monitoring Policy – Workstation – Standard`, `Monitoring Policy – Server – Standard`, `Automation Policy – Maintenance – Nightly`.
- **Patch rings:** `Patch Ring – Pilot – Stage0`, `Patch Ring – Early – Stage1`, `Patch Ring – Broad – Stage2`, `Patch Ring – Critical Servers – Stage3`.
- **Integration:** `Integration – PSA-RMM – Bi-Directional`.
- **Client-onboarding template:** `Onboarding Template – Managed Client – Standard`.

Every object created later in this solution reuses these exact names.

## Scope and boundaries

**In scope:** platform selection criteria; provisioning and baseline configuration of the PSA, RMM, and patch engine; the operating standards; the three core integrations; a repeatable client-onboarding workflow; validation and an operating cadence.

**Out of scope:** selecting or negotiating client-facing service offerings and pricing; security tooling beyond securing the stack itself (EDR, SIEM, email security are separate solutions); detailed accounting/general-ledger configuration in the PSA's billing module beyond enabling the time→invoice flow; backup/BCDR tooling.

## Outcomes

On completion the practice has a standardized, integrated tool stack: one PSA system of record, one RMM system of action, one governed patch engine, three live integrations, a documented operating standard, and a proven onboarding workflow that stands up a new managed client repeatably and verifiably.
