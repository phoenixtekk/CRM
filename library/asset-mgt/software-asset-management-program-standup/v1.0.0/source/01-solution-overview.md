# 1. Solution Overview — Software Asset Management (SAM) Program Standup & Governance

## What a SAM program is
Software Asset Management (SAM) is the discipline of governing software entitlements and deployments
across their whole life. A SAM program is not a tool and not a spreadsheet — it is a defined
lifecycle, a set of named owners, a documented set of standard operating procedures, a measured set
of KPIs, and a single system of record, all working together so software is governed deliberately
rather than rediscovered in an audit. This solution stands the program up in the repeatable way:
named artifacts you assign once and reuse everywhere.

## Why this matters
Spreadsheet SAM fails for predictable reasons. Nobody owns renewals, so contracts auto-renew at list
price or lapse. Nobody reconciles entitlements against deployment, so you over-buy in one place and
sit under-licensed (audit-exposed) in another. There are no KPIs, so "are we compliant?" has no
answer until a publisher audit forces one. A real program fixes the cause, not the symptom: it
assigns the lifecycle to owners, runs it on a cadence, and measures it — turning compliance and
savings from luck into a repeatable outcome. The rest of this solution is the how; this section is
the why.

## The SAM lifecycle
The program governs every title through five stages. Each stage has an owner and a standard operating
procedure (see the Implementation Guide).

1. Request — a user or team needs software; the request is captured through one intake channel,
   classified, and routed for approval against budget and policy.
2. Entitlement — an approved request is fulfilled from existing entitlements where possible
   (reharvested or pooled) or procured; the purchase and contract terms are recorded in the system of
   record.
3. Deployment — the entitled software is delivered to the user or device, and the assignment is
   recorded so deployment can later be reconciled against entitlement.
4. Reconciliation — on a cadence, deployed/used quantities are compared to entitled quantities to
   produce an Effective License Position (ELP): compliant, over-licensed (savings), or under-licensed
   (risk).
5. Renewal / Retirement — contracts approaching renewal are reviewed against the ELP and actual usage
   so you renew the right quantity, renegotiate, or retire and reharvest unused entitlements.

## Roles and RACI
A program needs named people, not job titles in the abstract. The core roles are an Executive Sponsor
(accountable for the program), a SAM Lead (runs the program day to day), a Procurement Liaison (owns
contracts and renewals), an IT/Deployment Owner (owns deployment and discovery data), and a Finance
Liaison (owns budget and chargeback). The Implementation Guide names a single RACI — SAM RACI –
Program – All Stages — that maps each lifecycle stage to these roles.

## Standard operating procedures and workflows
Each lifecycle stage is documented as a repeatable SOP so the program runs the same way regardless of
who is on shift. The Implementation Guide authors a named SOP set — SAM SOP Set – Program – All
Stages — one procedure per stage, plus the supporting workflows (intake routing, approval, renewal
review).

## KPIs and the system of record
The program is measured by a named KPI set — SAM KPI Set – Program – All Stages — covering license
compliance, reconciliation coverage, renewal lead time, reharvest savings, and request cycle time.
All of it is anchored to a single system of record — the entitlement register — named SAM Register –
Entitlements – System of Record, which holds entitlements, contracts, renewal dates, and the latest
ELP.

## ITIL v4 alignment
A SAM program is an ITIL v4 practice (IT Asset Management), and it interlocks with adjacent practices:
Service Request Management feeds the Request stage, Change Enablement governs deployment changes,
Service Configuration Management (the CMDB) shares asset data, and Supplier Management owns the
publisher relationships behind renewals. Aligning to ITIL v4 means the program reuses the
organization's existing request, change, and configuration practices instead of building parallel
ones — and it makes the program legible to any ITSM-literate stakeholder.

## What this is not
This program governs the process and the data. It does not replace a discovery tool, a procurement
system, or a contract repository — it orchestrates them into one governed lifecycle with one system
of record. Where tenant data is needed (for example, confirming entitlement and usage coverage), the
included scripts read it through Microsoft Graph; they do not move money or change contracts.

## The deployment model
> Define scope and roles, stand up the system of record and intake, author the SOP set and KPI set,
> run the first governance cycle on a pilot scope, validate against the gate, then expand across the
> estate. The repeatable way: Assess, then Configure, then Pilot, then Validate, then Expand.
