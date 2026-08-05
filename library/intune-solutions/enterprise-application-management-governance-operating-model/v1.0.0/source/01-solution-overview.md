# Solution Overview

## The problem this solves

Most organisations can *package* an application. Very few can answer these questions about the
applications already in their estate:

- **Who owns this app?** Not "who installed it" — who is accountable when it breaks, when the vendor
  ships a breaking change, or when Security asks whether it still needs to be there.
- **Who approved it, and on what evidence?** Was there a security review? A licence check? Is there a
  record, or did somebody just package it because a director asked?
- **What happens when it changes?** Who decides the app can be pushed to 12,000 devices? Who can stop
  the rollout? Who signs off the rollback?
- **Who supports it?** When the service desk gets a ticket, does it go to L1, L2, or the vendor — and
  is there a runbook, or is there one engineer who "just knows"?

When these questions have no answer, the estate accumulates **orphaned applications** (assigned to
groups nobody maintains, owned by people who left), **unreviewed applications** (no security or
licensing evidence), and **unsupportable applications** (no runbook, one hero engineer). Packaging
quality does not fix this. Better tooling does not fix this. What fixes it is an **operating model**:
named roles, a defined intake path, a decision forum with authority, published standards, a change
process with risk tiers, and a support model with real escalation paths.

**This solution is that operating model.** It is deliberately a *governance* product, not a technical
one.

## What this solution is NOT

This package does **not** teach application packaging or deployment mechanics. It assumes you either
already have those capabilities or will acquire them separately. Specifically, it does **not** cover:

- How to build a Win32 `.intunewin` package, write detection rules, or author requirement rules.
- How to configure third-party patch automation.
- How to troubleshoot a failing app install (exit codes, Management Extension logs, ESP blocks).
- How to configure WDAC policies, Defender for Endpoint, or App Protection policies in detail.

What it **does** cover is the layer above all of that: **who decides, on what basis, with what
evidence, and who is accountable afterwards** — plus exactly how those decisions are expressed as
objects inside Microsoft Intune so the governance is enforced rather than aspirational.

## The seven components of the operating model

The model has seven components. Each is defined in this package, and each produces a **named,
durable artefact** the organisation keeps.

### 1. Ownership and RACI

Every application in the estate has **four named accountabilities**:

| Role | Accountable for | Typically held by |
|---|---|---|
| **Application Owner** | The business need. Whether the app should exist at all, budget, licence count, renewal, and retirement. | A business function lead (Finance, HR, Clinical, Legal). |
| **Technical Owner** | The package, its configuration, its versions, its runbook, and its supportability. | An endpoint engineer or platform team member. |
| **Security Reviewer** | The risk assessment: data handled, network behaviour, vendor posture, control coverage. | Information Security. |
| **Deployment Engineer** | Executing the approved change: rings, timing, rollback, evidence. | Endpoint operations. |

The artefact is the **Application Register** — the authoritative list of every application, its four
owners, its review status, and its lifecycle state. Section 3 (Step 2) builds it, and
`APPOPS-Discovery.ps1` seeds it from your live tenant.

### 2. Intake and request workflow

A defined front door: how a new application enters the estate. Every request carries a **business
justification**, a **data classification**, a **licence/entitlement position**, and a **named
Application Owner** before it is allowed to consume engineering time. Requests that cannot supply
those four things are returned, not queued.

The artefact is the **Application Intake Request Form** and the **intake queue** that feeds the
review board.

### 3. The Application Review Board (ARB)

A standing decision forum with **explicit decision rights**. The ARB is not a discussion group — it
is the body that can say *approved*, *approved with conditions*, *deferred pending evidence*, or
*rejected*, and whose decision is binding. It meets on a fixed cadence, has defined membership and
quorum, and requires a defined **evidence pack** before an item is tabled.

The artefact is the **ARB Decision Record** — one entry per decision, retained for audit.

### 4. Standards and policy

A published definition of what **"approved"** means, so that approval is a test rather than an
opinion. Covers the security review criteria, the licensing and entitlement check, the packaging and
naming standards the estate must conform to, and the supportability bar an app must clear before it
is allowed into production.

The artefact is the **Application Standards Document** and the **naming convention** applied inside
Intune.

### 5. Change management

Applications change constantly — new versions, new configuration, new assignments, retirement. The
model classifies every change into a **risk tier**, and each tier carries a defined approval path,
deployment ring policy, change window, and rollback authority. It also defines the interface to a
formal **Change Advisory Board (CAB)** where one exists, so application changes are represented in
enterprise change control without every minor version consuming a CAB slot.

The artefact is the **Application Change Classification Matrix** and the **deployment ring
definitions** expressed as Entra groups in your tenant.

### 6. Operational support model

Who answers the ticket. A defined **L1 / L2 / L3 split** with explicit boundaries, escalation
triggers and paths, response and resolution targets per severity, and — critically — **named
ownership of every runbook**, so support knowledge is an organisational asset rather than a personal
one.

The artefact is the **Application Support Matrix** and one **Application Runbook** per production
application.

### 7. Metrics and evidence

The measures that prove the model is working, and the evidence trail that proves it to an auditor.
Coverage metrics (what fraction of the estate is owned, reviewed, ringed), flow metrics (intake to
decision time), quality metrics (change success rate, rollback rate), and risk metrics (orphaned
apps, overdue reviews).

The artefact is the **Application Governance Scorecard**, produced by `APPOPS-Report.ps1`.

## How governance connects to Intune and the security stack

Governance that lives only in a document is decoration. This model expresses each governance decision
as a **concrete object inside Microsoft Intune and Microsoft Entra ID**, so the platform enforces it:

| Governance decision | Expressed in the platform as |
|---|---|
| "This app has a technical owner." | The owner's name and the ARB decision reference recorded in the app's **Notes** field in Intune, stamped by `APPOPS-Remediation.ps1`. |
| "This app is approved for production." | Application of the Intune **scope tag** `Scope – App Management – Prod`. Unapproved apps carry `Scope – App Management – Pilot` only. |
| "Only the deployment engineers may change apps." | A custom Intune role, `Role – App Deployment Engineer`, scoped by scope tag, replacing broad Intune Administrator grants. |
| "Every rollout is ringed." | Three assigned Entra security groups — `PILOT – App Ring 1 – Validation`, `PILOT – App Ring 2 – Early Adopters`, `PROD – App Ring 3 – Broad` — and a rule that no app may be assigned directly to *All Users* or *All Devices*. |
| "The change was authorised and by whom." | Intune **audit logs**, exported into the ARB evidence pack by `APPOPS-Export-ApprovalEvidence.ps1`. |

The model also defines the **interface** to your security controls without re-specifying them:

- **Application Control (WDAC / App Control for Business)** — the ARB's approval decision is the
  *input* to your allow-list. The model defines who submits an app for allow-listing, when in the
  lifecycle it happens (after security review, before Ring 2), and who is accountable for the
  resulting policy change. It does not tell you how to author WDAC policy.
- **Microsoft Defender for Endpoint** — MDE's software inventory is a **discovery input** to the
  Application Register: apps present on endpoints but absent from the Register are, by definition,
  ungoverned. The model defines the reconciliation cadence and who acts on the exceptions.
- **App Protection Policies (MAM)** — the intake form's data-classification answer determines whether
  an application requires an App Protection Policy before approval. The model defines the trigger and
  the accountable reviewer, not the policy settings.

## The standard deployment model

This solution follows the same shape as every other solution in the category:
**Assess → Configure → Pilot → Validate → Expand.**

- **Assess** — inventory the existing estate, identify orphaned and unowned applications
  (`APPOPS-Discovery.ps1`).
- **Configure** — stand up the roles, groups, scope tags, register, standards, and forum.
- **Pilot** — run the model over a limited scope (one business unit or one application family) for
  two full ARB cycles.
- **Validate** — measure against the governance gates in Section 5 (`APPOPS-Validation.ps1`).
- **Expand** — extend to the whole estate and move to steady-state operation with the scorecard.

## Limitations and honest scope boundaries

- **This is an operating model, not a purchase of maturity.** It works only if the organisation
  actually assigns the named roles and holds the forum. A model nobody attends is a document.
- **It requires an accountable executive sponsor.** Decision rights are only real if somebody senior
  will back the ARB when a director's favourite application is rejected. If you cannot identify that
  sponsor, stop and secure it before Step 1.
- **It does not replace enterprise change management** where one exists. It defines the *interface*
  to CAB, so application changes are handled proportionately rather than duplicated.
- **Metrics require the register to be maintained.** The scripts can measure what is in Intune; they
  cannot measure business ownership that was never recorded.

## A note for Government tenants

The process, roles, decision rights, and artefacts in this solution are **identical** for Commercial
and US Government (GCC / GCC High / DoD) tenants. The only difference is the **portal URLs** you
navigate to:

| Purpose | Commercial | US Government |
|---|---|---|
| Intune admin centre | `https://intune.microsoft.com` | `https://endpoint.microsoft.us` |
| Entra / Azure portal | `https://entra.microsoft.com` / `https://portal.azure.com` | `https://portal.azure.us` |
| Sign-in authority | `https://login.microsoftonline.com` | `https://login.microsoftonline.us` |
| Microsoft Graph endpoint | `https://graph.microsoft.com` | `https://graph.microsoft.us` |

Every script in this package accepts a `-GraphEnvironment` parameter (`Global` or `USGov`) so it
targets the correct sovereign endpoint. Where a specific Intune feature's availability in GCC High or
DoD is uncertain, **verify for GCC High** against Microsoft's current US-sovereign-cloud service
availability documentation before relying on it in your standards.
