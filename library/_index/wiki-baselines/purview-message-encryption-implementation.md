# Purview Message Encryption (OME) Implementation — Microsoft Purview

> **Version 1.0.0** · Category: Purview · Solution code: IPOME

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Purview Message Encryption (OME) in Microsoft Purview

## The problem

Email is still the main way sensitive information leaves an organization — contracts, payroll, health
and financial details, account numbers — and by default it leaves **unprotected**. Once a message
reaches an external recipient it can be forwarded, printed, copied, and stored anywhere, with no
control and no record. That is a compliance gap and a data-risk exposure at the same time: the
information is out, and there is no way to restrict or account for what happens to it.

## The solution

This solution implements **Purview Message Encryption** — the current **Office 365 Message Encryption
(OME)**, built on **Azure Rights Management** — so that outbound email can be **encrypted, branded, and
usage-restricted**, to any recipient, on any device:

- **Encrypt** — the message is protected in transit and at rest; the recipient can read and reply.
- **Do Not Forward** — the message is encrypted **and** the recipient **cannot forward, print, or
  copy** it, for the most sensitive sends.
- **Your branding** — the encryption experience carries **your** logo, colour, and text, so recipients
  trust it rather than mistaking it for phishing.
- **Automatic, rule-driven** — mail flow rules apply the right protection when a message matches a
  condition (a keyword, a sensitivity label, an external recipient), so protection doesn't depend on a
  user remembering.

## How it works

We follow a repeatable model — **Assess → Design → Configure → Pilot → Validate → Expand** — that
enables the **encryption foundation first** (Azure RMS, proven healthy), sets the **branding**, then
builds the mail flow rules in **Audit mode scoped to a pilot group**, where they **match and log but do
not yet encrypt**. Only after sanctioned test sends prove the experience end to end — encrypted,
branded, readable by internal and external recipients, and (for Do Not Forward) genuinely
non-forwardable — do the rules move to **Enforce**, and scope widens deliberately.

The solution ships as **self-guided documentation plus five PowerShell tools** (Exchange Online /
Security & Compliance PowerShell / Graph) that assess readiness and RMS health, configure branding and
the rules (Audit-first), validate the wiring, and produce a leadership rollup — all **read-only or
`-WhatIf`/Audit-mode by default**, with **no credentials in code**.

## Why it matters

- **Sensitive email is protected** — encrypted and, where needed, non-forwardable, instead of leaving
  in the clear.
- **Recipients trust it** — a branded experience that reaches anyone, inside or outside the
  organization.
- **Automatic and defensible** — rule-driven encryption with an evidence trail (message trace),
  piloted before it enforces, so nothing breaks silently.
- **A fraction of consulting cost** — the same disciplined method a specialist would use, delivered as
  a repeatable, tested runbook.

## Important boundaries

OME is **licensing-dependent**: **Basic OME** (via Azure Information Protection, included in common
E3/E5 plans) provides encryption, the two templates, and a **single default** branding; **custom
branding templates, message revocation, and expiration** require **Advanced Message Encryption**
(Microsoft 365 E5 / E5 Compliance) — capability availability and exact portal paths/parameters should
be **verified against your licensing and tenant**. Deciding **what is sensitive** — which mail must be
encrypted and what triggers Do Not Forward — is a **compliance, privacy, and legal determination** for
your organization; this solution provides the technical method, the pilot discipline, and the evidence,
not the determination.


---


# Solution Overview — Purview Message Encryption (OME) in Microsoft Purview

## What this solution delivers

Email is still the way most sensitive information leaves an organization — a contract, a payroll
file, a patient summary, a set of account numbers — and by default it leaves **in the clear**. Once a
message crosses to an external recipient it can be forwarded, printed, copied, and retained anywhere,
with no control and no evidence of who did what. That is a compliance gap and a data-risk exposure at
the same time. **Purview Message Encryption** — the current, "new" **Office 365 Message Encryption
(OME)**, built on **Azure Rights Management (Azure RMS)** — closes it: outbound email can be
**encrypted**, branded with your organization's look, and delivered with a **usage restriction** such
as **Do Not Forward (DNF)** or **Encrypt-only**, to recipients inside or outside the tenant, on any
device.

This solution walks a competent-but-novice administrator through a **complete, repeatable OME
deployment**:

1. **Turn on the encryption foundation** — confirm/enable **Azure RMS** for the tenant
   (`Set-IRMConfiguration -AzureRMSLicensingEnabled $true`) and prove it healthy with
   `Test-IRMConfiguration`. No RMS, no OME.
2. **Brand the encryption experience** — configure the **OME branding** (the encryption portal /
   wrapper email your recipients see) with your logo, colours, and text via **`Set-OMEConfiguration`**
   (the default configuration), and — where licensing allows — a **custom branding template** via
   **`New-OMEConfiguration`** for specific flows.
3. **Make encryption happen automatically with rules** — build **mail flow (transport) rules** that
   apply the **`Encrypt`** or **`Do Not Forward`** protection template when a message matches a
   condition (a keyword, a sensitivity label, an external recipient, a classification), **piloted in
   the rule's `Audit` mode and scoped to a pilot group first**, so nothing encrypts in production
   until you have proven the match.
4. **Give users the manual controls too** — the **Encrypt** and **Do Not Forward** options in Outlook
   / Outlook on the web, so a person can protect a one-off message deliberately.
5. **Validate, then expand** — prove the end-to-end path (message → rule match → encrypted, branded,
   restricted delivery → recipient reads it) with sanctioned test sends, then widen scope and flip
   the rules from **Audit** to **Enforce** deliberately.

Together these turn **plaintext outbound email** into **encrypted, branded, usage-restricted** email
— configured, piloted, validated, and defensible.

## OME, the two templates, and where the pieces live — read this first

- **OME is built on Azure RMS.** The "new" OME encrypts the message and controls what the recipient
  can do with it (view, reply, forward). It is delivered through **Exchange Online** — so the
  configuration cmdlets live in **Exchange Online PowerShell** (`Connect-ExchangeOnline`), **not**
  Security & Compliance PowerShell. That is deliberate and correct for this capability; the scripts
  here connect to Exchange Online (and, for label-driven encryption, Security & Compliance PowerShell).
- **The two built-in protection templates.**
  - **`Encrypt`** — the message is encrypted; the recipient can read, **reply, and forward** (the
    protection travels, but usage is not restricted). Good for "keep it confidential in transit and at
    rest, but let them work with it."
  - **`Do Not Forward` (DNF)** — the message is encrypted **and** the recipient **cannot forward,
    print, or copy** it. Good for the most sensitive one-to-one or one-to-few sends.
  - **Encrypt-only** is a lighter, forward-permitting option surfaced to users in Outlook.
- **Branding is a separate object.** The **OME configuration** (`Get/Set/New-OMEConfiguration`)
  controls the *look* of the encryption experience — the wrapper email text, the portal logo,
  background colour, and disclaimer. The **default** configuration ("OME Configuration") brands every
  OME send; **custom** branding templates (multiple, per-flow) require **Advanced Message Encryption**
  (see licensing below).
- **Rules apply the templates.** A **mail flow (transport) rule** with the action *Apply Office 365
  Message Encryption and rights protection* (parameter `ApplyRightsProtectionTemplate` = `Encrypt` or
  `Do Not Forward`, optionally with a custom branding template) is what makes encryption **automatic**
  based on a condition. Rules have a **`Mode`** — **`Audit`**, **`AuditAndNotify`**, or **`Enforce`** —
  which is our pilot lever: build in **`Audit`** first (the rule matches and logs but **does not
  encrypt**), then flip to **`Enforce`**.

> **Determinations are the business's, not the tool's.** *Which* messages must be encrypted, *what*
> classification triggers DNF, and *how long* protected mail may be readable are **compliance/privacy/
> legal determinations** for your organization (see `global-requirements-purview.md` §5). This
> solution delivers the **technical method, the pilot discipline, and the evidence** — not the policy
> decision about what is sensitive.

## Basic OME vs Advanced Message Encryption — licensing shapes what you get

OME capability is **licensing-dependent** — verify against your tenant:

- **Basic OME** (Azure RMS via **Azure Information Protection**, included in Microsoft 365 E3/E5,
  Office 365 E3/E5, Microsoft 365 Business Premium, EMS E3/E5, AIP Plan 1): encryption, the **Encrypt**
  and **Do Not Forward** templates, and a **single default** branding configuration.
- **Advanced Message Encryption** (Microsoft 365 E5, Office 365 E5, Microsoft 365 E5 Compliance /
  Information Protection & Governance): **multiple custom branding templates**, plus, for mail sent to
  external recipients via the OME portal, **message revocation** (`Set-OMEMessageRevocation`) and
  **expiration**.

> **Verify availability against your licensing/tenant.** Custom branding templates, revocation, and
> expiration are **Advanced** features; if you only have Basic OME, plan on the **default** branding
> and the two templates, and treat revocation/expiration as "verify your licensing."

## The standard deployment model

Every step follows the same repeatable model, with an explicit **pass/fail gate** between phases:

**Assess → Design → Configure → Pilot (Audit mode / pilot group) → Validate → Expand (Enforce).**

- **Assess** — confirm licensing (Basic vs Advanced OME), Exchange admin roles, that **Azure RMS is
  enabled and healthy** (`Test-IRMConfiguration`), the in-scope trigger conditions, and
  compliance/privacy sign-off on *what* gets encrypted.
- **Design** — decide the branding, the rule conditions, the template per condition (`Encrypt` vs
  `Do Not Forward`), the pilot scope, and name every object.
- **Configure** — enable RMS, set the branding, then build the mail flow rules in **`Audit` mode**,
  scoped to a **pilot group**.
- **Pilot** — send sanctioned test mail; confirm the rules **match** (Audit logs / message trace)
  **without encrypting production mail**.
- **Validate** — run the pass/fail gates in `05-testing.md` (RMS health, branding renders, template
  applied, recipient experience, DNF actually blocks forwarding).
- **Expand** — flip the rules from **Audit** to **Enforce**, then widen scope deliberately, re-running
  the gates.

## What's in the box

- This overview, a **Requirements** guide, an ordered **Implementation** guide, **Testing** (pass/fail
  gates), **Troubleshooting**, **Best Practices**, and a **Deliverables Summary** + **Executive
  Summary**.
- **Five PowerShell tools** (Exchange Online PowerShell / Security & Compliance PowerShell / Graph):
  a **discovery/readiness** assessment, a **configuration/remediation** helper for branding and the
  mail flow rules (`-WhatIf`/Audit-first), a **validation** checker, an **encryption reporting**
  rollup, and a **scope/health** helper — **read-only or `-WhatIf` by default; no credentials in
  code**.

> **Sources:** Microsoft Learn — *Message encryption* / *Office 365 Message Encryption*, *Set up new
> Office 365 Message Encryption capabilities*, *Add branding to encrypted messages*
> (`Get/Set/New-OMEConfiguration`), *Define mail flow rules to encrypt email messages*
> (`ApplyRightsProtectionTemplate`, rule `Mode`), *Manage Azure Information Protection / IRM for
> Exchange Online* (`Set-IRMConfiguration`, `Test-IRMConfiguration`), and *Advanced Message
> Encryption* (custom templates, revocation, expiration). OME is **licensing-dependent** (Basic OME
> via AIP; Advanced Message Encryption for custom branding / revocation / expiration) and the
> Purview/Exchange portals **evolve** — **verify capability availability and exact paths/parameters
> against your licensing/tenant** rather than assuming.


---


# Requirements — Purview Message Encryption (OME) in Microsoft Purview

Confirm every prerequisite below **before** you configure anything. Category-level prerequisites
(tenant, compliance licensing model, least-privilege roles, S&C PowerShell / Graph toolchain,
in-scope data sources, compliance/privacy/legal stakeholders, pilot scope + change control) are in
`global-requirements-purview.md` — reference them; they are **not** repeated here. The items below are
the ones **specific to OME**: the **Azure RMS foundation**, the **Exchange Online** administration
surface, the **branding** object, the **mail flow rules**, and the licensing that separates **Basic**
from **Advanced** message encryption.

Each requirement is written as **Description · Why · Verify · Implement if missing.**

> **Note the toolchain nuance.** OME is delivered through **Exchange Online**, so its cmdlets
> (`Set-IRMConfiguration`, `*-OMEConfiguration`, `*-TransportRule`) live in **Exchange Online
> PowerShell** (`Connect-ExchangeOnline`), not Security & Compliance PowerShell. Label-driven
> encryption uses S&C PowerShell (`Connect-IPPSSession`). Both are in the ExchangeOnlineManagement
> module (`global-requirements-purview.md` §3).

---

## R1. Licensing for OME — Basic (AIP/Azure RMS) vs Advanced Message Encryption

**Description:** For **Basic OME** (encryption, the `Encrypt` and `Do Not Forward` templates, a single
**default** branding), the **Azure Information Protection / Azure RMS** entitlement included in
Microsoft 365 E3/E5, Office 365 E3/E5, Microsoft 365 Business Premium, EMS E3/E5, or AIP Plan 1,
assigned to the **senders** whose mail will be encrypted. For **Advanced Message Encryption** (multiple
**custom** branding templates, message **revocation**, and **expiration** for external recipients),
Microsoft 365 E5 / Office 365 E5 / Microsoft 365 E5 Compliance (Information Protection & Governance).
**Why:** OME rides on Azure RMS; the template and default branding are Basic, but custom branding /
revocation / expiration are **Advanced-only**. Senders must be licensed for the protection to apply.
**Verify:** Microsoft 365 admin center → **Billing → Licenses** — confirm the AIP/RMS entitlement and,
for Advanced, the E5/E5 Compliance SKU. `OME-Discovery.ps1` reports RMS enablement and flags whether
custom-branding/revocation features are in play. Cross-check the *Microsoft Purview / Azure Information
Protection service description* — **verify against your licensing/tenant.**
**Implement if missing:** Acquire/assign the AIP/RMS entitlement for Basic OME; add E5/E5 Compliance
where custom branding, revocation, or expiration are required. Do **not** design around Advanced
features you are not licensed for.

## R2. Azure Rights Management (Azure RMS) enabled and healthy for the tenant

**Description:** Azure RMS **activated** for the tenant and **enabled for Exchange Online IRM**
(`Set-IRMConfiguration -AzureRMSLicensingEnabled $true`), passing `Test-IRMConfiguration`.
**Why:** OME cannot encrypt anything if the RMS foundation is off or unhealthy — every template, rule,
and branding depends on it.
**Verify:** Exchange Online PowerShell — `Get-IRMConfiguration` shows `AzureRMSLicensingEnabled : True`;
`Test-IRMConfiguration -Sender <addr> -Recipient <addr>` returns **PASS** on all checks.
`OME-Discovery.ps1` / `OME-ScopeHealth.ps1` report this.
**Implement if missing:** In Exchange Online PowerShell run `Set-IRMConfiguration
-AzureRMSLicensingEnabled $true`, then re-run `Test-IRMConfiguration`. (Azure RMS activation itself is
in the Microsoft Purview / Azure portal — **verify the current path in your tenant.**)

## R3. Exchange Online administration roles (least privilege)

**Description:** An admin with the rights to configure **IRM**, **OME configuration**, and **mail flow
(transport) rules** — the Exchange Online **Organization Management** role, or a least-privilege custom
role group that includes the **Transport Rules** and **IRM/message-encryption** management roles.
Global Administrator only where genuinely required (e.g. initial Azure RMS activation).
**Why:** `Set-IRMConfiguration`, `*-OMEConfiguration`, and `*-TransportRule` are Exchange Online admin
actions; without the matching role they fail.
**Verify:** Exchange admin center → **Roles**, or `Get-ManagementRoleAssignment` for the account.
`OME-Discovery.ps1` reports whether the connected account can read the relevant configuration.
**Implement if missing:** Assign the least-privilege Exchange role group under change control; reserve
Global Administrator for the one-time RMS activation only.

## R4. The encryption **branding** decision (default configuration, and any custom templates)

**Description:** The branding your recipients should see on the OME experience — the wrapper email
text, portal **logo**, **background/accent colour**, **disclaimer**, and "read the message" text — set
on the **default** OME configuration, plus a decision on whether any **custom** branding templates
(Advanced only) are needed for specific flows.
**Why:** The encryption portal/wrapper is a recipient-facing, trust-critical surface; unbranded or
default-Microsoft branding undermines confidence and looks like phishing. Custom templates need
**Advanced Message Encryption** (R1).
**Verify:** Exchange Online PowerShell — `Get-OMEConfiguration` shows the default configuration and any
custom ones. `OME-Discovery.ps1` lists existing OME configurations.
**Implement if missing:** Gather the approved logo (per Microsoft's size/format guidance — **verify
current limits**), colours, and text; set them on the default configuration (`OME-Set-...` /
`Set-OMEConfiguration`). Only create custom templates if licensed and a flow genuinely needs distinct
branding.

## R5. The trigger conditions and template mapping (what gets encrypted, and how)

**Description:** The **conditions** that should cause encryption (e.g. a subject/keyword like
`[encrypt]`, a **sensitivity label**, an **external** recipient, a classification / sensitive info
type) and the **template** each maps to (`Encrypt` vs `Do Not Forward`), agreed with
compliance/privacy.
**Why:** The mail flow rule keys off these conditions; getting them wrong either **over-encrypts**
(breaking legitimate flows / recipient usability) or **under-encrypts** (leaving sensitive mail in the
clear). The *what-is-sensitive* determination is the business's (§5), not a technical default.
**Verify:** Confirm the agreed condition→template mapping in writing with compliance/privacy before
authoring rules. `OME-Discovery.ps1` inventories any existing OME rules.
**Implement if missing:** Work with compliance/privacy to define the conditions and template mapping;
start narrow (a keyword + external recipient) and add classification/label conditions as they mature.

## R6. Sensitivity labels / classification (optional but recommended trigger source)

**Description:** Where you want encryption driven by **classification** rather than a keyword, the
**sensitivity labels** (or sensitive info types) that the rule — or the label's own protection — will
key on, published and in use on the in-scope mail.
**Why:** Label-driven encryption is more robust than a keyword: a **Confidential** or **Highly
Confidential** label can either **apply encryption itself** (label-based protection, which can invoke
OME branding for email) or serve as a **mail flow rule condition** that applies a template.
**Verify:** Purview → **Information Protection → Labels / Label policies** shows the labels published;
S&C PowerShell `Get-Label` reads them. `OME-Discovery.ps1` (with S&C session) reports label presence.
**Implement if missing:** Publish the needed labels first (this can be a separate labeling project). If
you have no labels yet, start with keyword/recipient conditions and add label conditions once labeling
is in use.

## R7. Recipient experience and supported flows

**Description:** Awareness of how **different recipients** read protected mail — Microsoft 365
recipients read it inline; other recipients (Outlook.com, Gmail, Yahoo, or arbitrary providers) use a
**one-time passcode** or federated sign-in via the **OME portal** — and confirmation that these flows
are acceptable for your correspondents.
**Why:** OME is designed to reach **any** recipient, but the external experience (portal + OTP) differs
from inline reading; setting expectations avoids "the encrypted email doesn't work" support tickets.
**Verify:** Confirm the intended external recipient domains and test the OTP/portal flow to one during
the pilot (Testing Gate 5). **Verify current supported-recipient behaviour in Microsoft docs.**
**Implement if missing:** Document the recipient experience for your help desk and end-users
(`HELP_CENTER`-style guidance) before broad rollout.

## R8. A pilot scope and Audit-mode change control

**Description:** A **named pilot sender group** (`SG-OME-Pilot`) and agreement to build the mail flow
rules in **`Audit` mode** (the rule matches and logs but **does not encrypt**) scoped to that group
first, under a **change-control** process, before any tenant-wide **`Enforce`**.
**Why:** A mis-scoped encryption rule can encrypt mail that must stay readable by systems/recipients
that can't handle OME, or over-restrict with DNF; Audit mode + a pilot group prove the **match**
without changing delivery, so you can tune before enforcing. (`global-requirements-purview.md` §6.)
**Verify:** Confirm `SG-OME-Pilot` exists, that the rules will be created with `-Mode Audit`, and a
change window/approval path. `OME-ScopeHealth.ps1` previews the pilot group and rule scope.
**Implement if missing:** Create the pilot group, author rules in `Audit` mode, and agree change
control before flipping any rule to `Enforce`.


---


# Global Requirements — Microsoft Purview Solutions

These requirements apply to **every** solution in the **Purview** category (implementing and managing
Microsoft Purview, sensitivity & retention labels, DLP, data lifecycle & records, insider risk,
communication compliance, audit, data security posture management, and data governance). Verify each
before starting a solution's implementation steps.

> **Vendor boundary (applies to every Purview solution).** The **Microsoft Purview portal**
> (purview.microsoft.com), the **Microsoft 365 admin center**, **Security & Compliance PowerShell**
> (`Connect-IPPSSession`), and **Microsoft Graph** are authored at exact, current click-by-click /
> cmdlet detail from Microsoft's public documentation. Microsoft Purview features are heavily
> **licensing-/plan-dependent** (many require **Microsoft 365 E5** or the **E5 Compliance** add-on;
> some are in preview) and the portal is **actively evolving** — capability availability and portal
> paths are **cited or flagged "verify your licensing/tenant"**, never asserted or invented.
> **Regulatory, records-retention, and legal determinations** (retention schedules, records file plans,
> legal holds, insider-risk case actions, regulatory applicability) are **deferred to the organization's
> compliance, records, privacy, and legal functions** — the solutions provide the technical
> configuration method and evidence, not the determination. Automation is **PowerShell** (Security &
> Compliance PowerShell / Graph) — never with hardcoded credentials or secrets.

## 1. Microsoft 365 tenant with the required Purview/compliance licensing
- **Description:** A Microsoft 365 tenant with the **compliance licensing** the capability requires
  (E3 for baseline; **E5 / E5 Compliance** for advanced DLP, auto-labeling, insider risk, communication
  compliance, Audit Premium, DSPM, etc.).
- **Why required:** Most Purview capabilities are plan-gated; the feature won't be available without the
  right plan.
- **How to verify:** In the M365 admin center confirm the subscription/add-ons; check the feature is
  visible in the Purview portal.
- **How to implement if missing:** Assign/purchase the required licensing before starting.

## 2. Purview roles (least-privilege) and portal access
- **Description:** Access with the least-privilege **Purview / compliance role** the solution names
  (e.g. Compliance Administrator, Compliance Data Administrator, Information Protection, Records
  Management, Insider Risk, eDiscovery, Audit roles), with Global Administrator only where required.
- **Why required:** Purview uses fine-grained role groups; configuration requires the matching role.
- **How to verify:** Purview portal → **Roles & scopes / Permissions** — confirm the role membership.
- **How to implement if missing:** Assign the least-privilege role group under change control.

## 3. Security & Compliance PowerShell + Graph toolchain
- **Description:** A workstation with **Security & Compliance PowerShell** (`Connect-IPPSSession` via the
  ExchangeOnlineManagement module) and **Microsoft Graph PowerShell**, modern-auth / MFA-capable admin.
- **Why required:** Configuration, automation, and the provided scripts run through these.
- **How to verify:** `Connect-IPPSSession` and `Connect-MgGraph` succeed with the admin account.
- **How to implement if missing:** Install the modules and confirm modern-auth sign-in before running steps.

## 4. Data sources & scope in scope
- **Description:** The **workloads and data sources** in scope (Exchange, SharePoint, OneDrive, Teams,
  endpoints/devices, and — for data governance — the broader data estate) and a **data-classification /
  sensitivity** intent to drive labels, DLP, and retention.
- **Why required:** Purview policies key off the in-scope workloads and the classification scheme.
- **How to verify:** Confirm the in-scope workloads and the classification/sensitivity approach with
  stakeholders.
- **How to implement if missing:** Define the scope and classification intent before authoring policies.

## 5. Compliance, records, privacy & legal stakeholders
- **Description:** Engagement with the **compliance, records-management, privacy, security, and legal**
  stakeholders whose policies the configuration must satisfy (retention schedules, records file plans,
  regulatory obligations, insider-risk and communication-compliance policy, legal hold).
- **Why required:** Purview configuration must align to enterprise policy and legal/records requirements,
  not technical defaults; several capabilities have HR/legal sensitivity.
- **How to verify:** Confirm the applicable policies, the records schedule, and named approvers.
- **How to implement if missing:** Identify the owners and capture the requirements before configuring.

## 6. A pilot scope and change control
- **Description:** A **pilot scope** (users/sites/policies in simulation or a limited ring) to validate
  on before tenant-wide enforcement, and a **change-control** process — most Purview policies support a
  **simulation / test / disabled** mode that MUST be used before enforcement.
- **Why required:** Every solution follows an **Assess → Design → Configure → Pilot (simulate) → Validate
  → Expand (enforce)** model; DLP, labels, retention, and insider-risk changes are high-impact.
- **How to verify:** Confirm a named pilot scope, that simulation/test mode is available, and a change
  window/approval path.
- **How to implement if missing:** Define the pilot and agree change control before enforcing anything.

*The deployment model across every Purview solution is the same: **Assess → Design → Configure → Pilot
(simulate/test) → Validate → Expand (enforce)**, with explicit pass/fail gates and a documented rollback.
Automation is delivered as **PowerShell** (Security & Compliance PowerShell / Graph) — never with
hardcoded credentials or secrets. Regulatory/records/legal determinations are deferred to the relevant
governance functions.*


---


# Implementation — Purview Message Encryption (OME) in Microsoft Purview

This is the ordered, do-this-then-that guide. It follows the standard model
(**Assess → Design → Configure → Pilot (Audit mode / pilot group) → Validate → Expand (Enforce)**) and
— because a mis-scoped encryption rule changes how mail is delivered — it enables the **RMS foundation
first**, sets **branding**, then builds the mail flow rules in **`Audit` mode scoped to a pilot group**
before anything encrypts in production. Every object is named verbatim so the scripts, testing, and
troubleshooting line up. Replace the `contoso.com` / sample names with your own.

> **Toolchain note.** OME is administered in **Exchange Online** — these steps use **Exchange Online
> PowerShell** (`Connect-ExchangeOnline`): `Set-IRMConfiguration`, `*-OMEConfiguration`,
> `*-TransportRule`, `Test-IRMConfiguration`. Label-driven encryption additionally uses **S&C
> PowerShell** (`Connect-IPPSSession`). Some settings (Azure RMS activation, and the branding preview)
> are surfaced in the Microsoft Purview / Exchange admin portals — where a path or parameter may differ
> by tenant/licence, **verify against your licensing/tenant.**

> **Hard gate before you enforce.** Do **not** flip any mail flow rule from `Audit` to `Enforce` until
> compliance/privacy have confirmed **what** should be encrypted and to which template (R5), and the
> Testing gates pass. *What is sensitive* is a business determination (`global-requirements-purview.md`
> §5), not a technical default.

---

## Phase 0 — Assess (confirm you can build safely)

1. **Confirm licensing (R1).** Verify the AIP/Azure RMS entitlement for the pilot senders (Basic OME);
   confirm E5/E5 Compliance if you need **custom branding / revocation / expiration** (Advanced).
2. **Confirm the RMS foundation (R2).** Connect Exchange Online PowerShell and run
   **`OME-Discovery.ps1`** (read-only). Confirm `AzureRMSLicensingEnabled : True` and that
   `Test-IRMConfiguration` passes.
   - **Gate 0a:** RMS is enabled and `Test-IRMConfiguration` passes → continue. Otherwise run
     `Set-IRMConfiguration -AzureRMSLicensingEnabled $true` (and activate Azure RMS in the portal),
     then re-test.
3. **Confirm roles (R3).** The connected account holds Exchange **Organization Management** (or the
   least-privilege transport-rules + IRM role group).
4. **Confirm the toolchain** (`global-requirements-purview.md` §3): `Connect-ExchangeOnline` succeeds
   (and `Connect-IPPSSession` if you will use label-driven encryption).

## Phase 1 — Design (agree it with compliance/privacy, then name everything)

Decide and **record with compliance/privacy**:

- **Branding (R4):** the default OME configuration's logo, background/accent colour, portal text,
  disclaimer, and email text; and whether any **custom** template (`OME-Branding-Corp`, Advanced only)
  is needed.
- **Trigger conditions → template (R5):**
  - **`OME-Encrypt-Outbound-Pilot`** — condition: sender ∈ **`SG-OME-Pilot`** **AND** (subject
    contains **`[encrypt]`** **OR** recipient is **external**) → template **`Encrypt`**.
  - **`OME-DoNotForward-Confidential`** — condition: message carries the **`Highly Confidential`**
    sensitivity label (or the agreed classification/header) → template **`Do Not Forward`**.
- **Pilot scope:** a named group, **`SG-OME-Pilot`**, holding a small set of sanctioned pilot senders.
- **Manual controls:** confirm the Outlook **Encrypt** / **Do Not Forward** options are enabled for
  users who need to protect one-off messages deliberately.

## Phase 2 — Configure the RMS foundation and branding

In **Exchange Online PowerShell**:

1. **Enable RMS (if not already, R2).** `Set-IRMConfiguration -AzureRMSLicensingEnabled $true`, then
   `Test-IRMConfiguration -Sender pilot@contoso.com -Recipient external@example.com` — confirm all
   checks **PASS**.
2. **Set the default branding.** Use **`OME-Configure.ps1 -Action Branding -WhatIf`** to preview, then
   `-Commit` to apply, or run `Set-OMEConfiguration` directly against the default configuration
   (identity **"OME Configuration"**) — logo, `BackgroundColor`, `EmailText`, `PortalText`,
   `DisclaimerText`, `ReadButtonText` (**verify current property names in your tenant**).
3. **(Advanced only) Create a custom branding template.** If licensed, `New-OMEConfiguration -Identity
   "OME-Branding-Corp"` then `Set-OMEConfiguration -Identity "OME-Branding-Corp" ...` for a per-flow
   look.
- **Pass/fail:** `Get-OMEConfiguration` returns the branding you set; a test send renders it (Phase 4 /
  Testing Gate 4). **Rollback:** re-run `Set-OMEConfiguration` to restore prior values (record the
  originals first with `OME-Discovery.ps1`).

## Phase 3 — Build the mail flow rules in AUDIT mode, scoped to the pilot

In **Exchange Online PowerShell**, create the rules with **`OME-Configure.ps1 -Action MailFlowRules
-WhatIf`** (prints the exact plan), then **`-Commit`** (creates them in **`Audit` mode**). The
equivalent direct commands:

1. **`OME-Encrypt-Outbound-Pilot`** (template `Encrypt`, Audit first):
   ```powershell
   New-TransportRule -Name "OME-Encrypt-Outbound-Pilot" `
     -FromMemberOf "SG-OME-Pilot@contoso.com" `
     -SentToScope NotInOrganization `
     -SubjectContainsWords "[encrypt]" `
     -ApplyRightsProtectionTemplate "Encrypt" `
     -Mode Audit
   ```
   (Combine/loosen the `-SubjectContainsWords` / `-SentToScope` conditions to match your Phase-1
   design; to apply a custom branding template add `-ApplyRightsProtectionCustomizationTemplate
   "OME-Branding-Corp"` — **verify the exact parameter name in your tenant**.)
2. **`OME-DoNotForward-Confidential`** (template `Do Not Forward`, Audit first):
   ```powershell
   New-TransportRule -Name "OME-DoNotForward-Confidential" `
     -FromMemberOf "SG-OME-Pilot@contoso.com" `
     -HeaderMatchesMessageHeader "msip_labels" `
     -HeaderMatchesPatterns "<Highly Confidential label GUID>" `
     -ApplyRightsProtectionTemplate "Do Not Forward" `
     -Mode Audit
   ```
   (The `msip_labels` header carries the applied sensitivity-label GUID — **verify the header name and
   your label GUID**; alternatively key on a keyword/classification per Phase 1.)
- **Pilot rule:** every rule is created with **`-Mode Audit`** and scoped to **`SG-OME-Pilot`**. In
  `Audit` mode the rule **matches and logs but does not encrypt** — so nothing changes for real mail
  yet.
- **Pass/fail:** `Get-TransportRule` shows both rules **enabled, `Mode = Audit`**, scoped to the pilot
  group. `OME-Validate.ps1` confirms mode/scope. **Rollback:** `Disable-TransportRule` (or
  `Remove-TransportRule`); Audit mode changes nothing for users, so pilot rollback is trivial.

## Phase 4 — Pilot and validate (run the gates)

Work the gates in `05-testing.md`. In summary, from a **sanctioned pilot sender** in `SG-OME-Pilot`:

- Send a test message that matches `OME-Encrypt-Outbound-Pilot` (subject `[encrypt]`, external
  recipient). In **`Audit` mode**, confirm via **message trace** / rule Audit logs that the rule
  **matched** — without the message actually being encrypted yet.
- Temporarily flip **only the one pilot rule** to `Enforce` for a controlled test window (or use a
  dedicated test rule) and confirm a real test send is **encrypted, branded, and readable** by an
  internal and an external test recipient (OTP/portal for external — R7).
- Confirm **`Do Not Forward`** actually **prevents forwarding/printing/copying** for the recipient.
- Confirm reporting (`OME-Report.ps1`) reconciles with **message trace**.
- **Do not enforce broadly** until every gate passes **and** compliance/privacy confirm the
  condition→template mapping (R5).

## Phase 5 — Expand (enforce, then widen — only after the gate passes)

1. **Flip rules to Enforce.** Change each rule's mode: `Set-TransportRule -Identity
   "OME-Encrypt-Outbound-Pilot" -Mode Enforce` (and the DNF rule). Watch the first cohort closely via
   message trace and help-desk signal.
2. **Widen scope deliberately** — add members to `SG-OME-Pilot` (or broaden the rule's `-FromMemberOf`
   / `-SentToScope`) **group-by-group**, not tenant-wide in one move, using `OME-ScopeHealth.ps1`
   (read-only preview) to stage the expansion. **Re-run the gates** after each expansion.
3. **(Advanced) Enable revocation/expiration if licensed.** For external OME-portal mail, confirm
   `Get-OMEMessageStatus` and `Set-OMEMessageRevocation` are available, and set expiration on the OME
   configuration (`ExternalMailExpiryInDays` — **verify property/licensing**).

---

### Rollback summary

| Change | Rollback |
| --- | --- |
| Branding wrong / broken logo | Re-run `Set-OMEConfiguration` to restore the prior values (captured by `OME-Discovery.ps1` before you changed them). |
| Encryption rule too broad / breaking a flow | `Set-TransportRule -Mode Audit` (or `Disable-TransportRule`) — encryption stops immediately; tune conditions and re-pilot. |
| DNF too restrictive for a flow | Change that rule's template to `Encrypt`, or narrow its condition; DNF only where forwarding must be blocked. |
| Rule scoped too far | Remove members from `SG-OME-Pilot` (`OME-ScopeHealth.ps1` preview first), or tighten `-FromMemberOf`; the rule follows the scope. |
| RMS/IRM change caused mail issues | Re-run `Test-IRMConfiguration` to isolate; `Set-IRMConfiguration` to correct; RMS enablement is tenant-wide, so change it under change control. |

> **Never** treat OME as a substitute for the business decision about **what is sensitive**. The
> conditions and templates here **enforce** a policy; deciding *which mail* must be encrypted, and for
> how long it may be readable, is a **compliance/privacy/legal determination** (§5). This solution
> provides the method and the evidence, not the determination.


---


# Testing & Validation — Purview Message Encryption (OME) in Microsoft Purview

Run these gates in order. Each has an explicit **pass/fail** signal. **Do not enforce broadly** (Phase
5 — flip rules from `Audit` to `Enforce` and widen scope) until every gate passes **and**
compliance/privacy have confirmed the condition→template mapping. Where a gate involves a real send,
use a **sanctioned pilot sender** in `SG-OME-Pilot` and **test recipients** (one internal Microsoft
365 mailbox, one external mailbox on a different provider) — do not test on production correspondence.

Use the scripts where noted; they are read-only or `-WhatIf`/Audit-mode and change nothing you don't
approve.

---

## Gate 1 — Licensing is in place (Basic vs Advanced)

**Why:** OME rides on Azure RMS/AIP; custom branding, revocation, and expiration are **Advanced-only**.
**How:** Confirm the AIP/Azure RMS entitlement for the pilot senders; confirm E5/E5 Compliance if you
rely on custom branding / revocation / expiration. Run `OME-Discovery.ps1`.
**Pass:** Senders are licensed for Basic OME; any Advanced feature you plan to use is licensed.
**Fail:** Senders unlicensed, or a design depends on an Advanced feature you don't have → acquire/assign,
or redesign to Basic (default branding, two templates) before proceeding.

## Gate 2 — Azure RMS is enabled and healthy

**Why:** No RMS, no encryption — every template, rule, and branding depends on it.
**How:** Exchange Online PowerShell — `Get-IRMConfiguration` (`AzureRMSLicensingEnabled : True`) and
`Test-IRMConfiguration -Sender <pilot> -Recipient <external>`. `OME-ScopeHealth.ps1` runs these.
**Pass:** `AzureRMSLicensingEnabled` is **True** and `Test-IRMConfiguration` returns **PASS** on all
checks (RMS online, templates retrieved, encrypt/decrypt round-trip).
**Fail:** RMS disabled or any `Test-IRMConfiguration` check fails → enable RMS
(`Set-IRMConfiguration -AzureRMSLicensingEnabled $true`) / activate Azure RMS, then re-test.

## Gate 3 — The protection templates are available

**Why:** The rules apply `Encrypt` / `Do Not Forward`; they must exist and be published.
**How:** Exchange Online PowerShell — `Get-RMSTemplate` lists the available templates.
`OME-Discovery.ps1` reports them.
**Pass:** The **`Encrypt`** and **`Do Not Forward`** templates are returned and enabled.
**Fail:** Templates missing → confirm RMS is active (Gate 2) and allow propagation; **verify template
availability in your tenant.**

## Gate 4 — Branding is configured and renders correctly

**Why:** The encryption portal/wrapper is recipient-facing and trust-critical; wrong or missing
branding looks like phishing.
**How:** `Get-OMEConfiguration` shows the branding you set (logo, colour, text). Then send a
sanctioned encrypted test to an internal and an external recipient and **view** the wrapper/portal.
**Pass:** `Get-OMEConfiguration` returns your intended values; the recipient sees your logo, colour,
and text (not default Microsoft branding, unless that is the deliberate choice).
**Fail:** Branding absent, broken (logo too large / wrong format), or wrong → re-run
`Set-OMEConfiguration` (Implementation Phase 2) and re-test; **verify current logo size/format limits.**

## Gate 5 — The rules are healthy, in AUDIT mode, scoped to the pilot

**Why:** A prematurely-enforcing or over-scoped rule encrypts (or DNFs) mail that must stay readable.
**How:** `Get-TransportRule`; `OME-Configure.ps1 -Action MailFlowRules -WhatIf` to re-print the plan;
`OME-Validate.ps1` to confirm mode/scope.
**Pass:** `OME-Encrypt-Outbound-Pilot` and `OME-DoNotForward-Confidential` are **enabled**, **`Mode =
Audit`**, scoped to **`SG-OME-Pilot`**, each with the correct condition and template.
**Fail:** A rule is already `Enforce`, over-scoped, disabled, or has the wrong condition/template →
correct before testing detections.

## Gate 6 — A matching message is detected in AUDIT (without being encrypted)

**Why:** Proves the condition matches the intended mail **before** anything encrypts.
**How:** From a pilot sender, send a message that matches `OME-Encrypt-Outbound-Pilot` (subject
`[encrypt]`, external recipient). Review **message trace** / the rule's Audit results.
**Pass:** Message trace / Audit shows the rule **matched** the test message; a **non-matching** control
message (no `[encrypt]`, internal only) did **not** match. The matching message is **not** encrypted
(Audit mode).
**Fail:** No match on the test, or a match on the control → fix the rule conditions/scope before
enforcing.

## Gate 7 — A real encrypted send is encrypted, branded, and readable

**Why:** Proves the end-to-end path in a controlled window before broad enforcement.
**How:** In a controlled test window, flip **only the pilot Encrypt rule** to `Enforce` (or use a
dedicated test rule), send a sanctioned message, and open it as **(a)** an internal Microsoft 365
recipient and **(b)** an external recipient (one-time passcode / OME portal — R7). Then return the rule
to `Audit` if broad enforcement isn't yet approved.
**Pass:** Both recipients can read the message; the external recipient completes the OTP/portal flow;
the branding renders. Message trace shows the message was encrypted by the rule.
**Fail:** Either recipient cannot read it, the OTP/portal flow fails, or the rule didn't encrypt →
check RMS health (Gate 2), recipient support (R7), and the rule action.

## Gate 8 — Do Not Forward actually restricts the recipient

**Why:** DNF's value is that the recipient **cannot** forward/print/copy — this must be proven, not
assumed.
**How:** Send a sanctioned message via the `Do Not Forward` path to an internal test recipient and
attempt to **forward**, **print**, and **copy** it.
**Pass:** Forward/print/copy are **blocked/greyed** for the DNF message; the same actions are allowed
on an ordinary (`Encrypt`-only) message.
**Fail:** The recipient can forward/print a DNF message → confirm the rule applied `Do Not Forward`
(not `Encrypt`), and that the recipient client honours RMS restrictions.

## Gate 9 — Reporting reconciles with message trace

**Why:** Leadership needs a defensible summary of what was encrypted, without over-collecting.
**How:** Run `OME-Report.ps1` (read-only) and compare its rollup to **message trace** (and, for
Advanced external mail, `Get-OMEMessageStatus`).
**Pass:** The rollup (encrypted-message counts by rule/template/time) reconciles with message trace;
no content or recipient data is exposed beyond what the report is authorized to show.
**Fail:** Rollup diverges materially from message trace → message trace is authoritative; reconcile
before reporting.

## Gate 10 — Compliance/privacy confirm the mapping before broad enforcement

**Why:** *What* must be encrypted and *what* triggers DNF are business determinations, not technical
defaults.
**How:** Walk the condition→template mapping with compliance/privacy: which conditions encrypt, which
apply DNF, and the recipient experience.
**Pass:** Compliance/privacy confirm the mapping and the recipient experience in writing.
**Fail:** Ambiguity about what should be encrypted, or the mapping isn't signed off → resolve **before**
flipping rules to `Enforce`.

---

### Exit criteria (all must be true before Expand/enforce)

- [ ] Licensing in place — Basic (and Advanced where relied on) (Gate 1)
- [ ] Azure RMS enabled and healthy; `Test-IRMConfiguration` passes (Gate 2)
- [ ] `Encrypt` and `Do Not Forward` templates available (Gate 3)
- [ ] Branding configured and renders correctly (Gate 4)
- [ ] Rules healthy, `Audit` mode, pilot-scoped (Gate 5)
- [ ] Matching message detected in Audit without being encrypted (Gate 6)
- [ ] Controlled real send: encrypted, branded, readable internally + externally (Gate 7)
- [ ] Do Not Forward restricts forward/print/copy (Gate 8)
- [ ] Reporting reconciles with message trace (Gate 9)
- [ ] Compliance/privacy confirmed the condition→template mapping (Gate 10)


---


# 6. Troubleshooting — Purview Message Encryption (OME) in Microsoft Purview

The failure modes you'll hit configuring and operating OME. Each: **symptom → likely cause → fix.**
Most "encryption isn't working" reports are actually RMS not enabled, a rule still in `Audit` mode, a
condition that doesn't match, or a recipient-experience issue — this guide separates those from real
faults. OME is administered in **Exchange Online PowerShell** (`Connect-ExchangeOnline`); label-driven
encryption also uses **S&C PowerShell** (`Connect-IPPSSession`).

## `Test-IRMConfiguration` fails, or `AzureRMSLicensingEnabled` is False
- **Cause A — RMS not enabled.** Azure RMS/IRM is the foundation; without it nothing encrypts. **Fix:**
  `Set-IRMConfiguration -AzureRMSLicensingEnabled $true`, activate Azure RMS in the portal, then
  re-run `OME-ScopeHealth.ps1 -Sender <pilot> -Recipient <external>` (Gate 2).
- **Cause B — licensing.** The sender lacks an AIP/Azure RMS entitlement. **Fix:** confirm licensing
  (Requirement R1); **verify your licensing/tenant** — plan names evolve.
- **Cause C — propagation.** RMS was just enabled. **Fix:** allow propagation, then re-test.

## `Get-RMSTemplate` returns no `Encrypt` / `Do Not Forward` template
- **Cause:** RMS isn't active yet, or templates haven't propagated. **Fix:** confirm Gate 2 passes,
  allow time, re-run `OME-Discovery.ps1`. **Verify template availability in your tenant** — do not
  invent template names.

## A message that should encrypt isn't being encrypted
- **Cause A — rule in Audit mode (expected during pilot).** In `Audit` the rule **matches and logs but
  does not encrypt** — this is by design until you enforce. **Fix:** confirm with `OME-Validate.ps1`;
  encryption begins only when the rule is deliberately flipped to `Enforce` (Phase 5, after the gates).
- **Cause B — condition mismatch.** The subject keyword (`[encrypt]`), recipient scope
  (`NotInOrganization`), or label header/GUID doesn't match the test message. **Fix:** re-check the
  rule conditions against the test (`OME-Configure.ps1 -Action MailFlowRules -WhatIf` reprints the
  plan); confirm the sender is in `SG-OME-Pilot`.
- **Cause C — sender out of scope.** The sender isn't a member of `SG-OME-Pilot`. **Fix:** confirm
  membership with `OME-ScopeHealth.ps1`.

## The label-driven Do-Not-Forward rule doesn't fire
- **Cause:** the `msip_labels` header pattern doesn't match your actual label GUID, or the message
  never carried the label. **Fix:** capture the real header from a labeled test message and confirm the
  **Highly Confidential** label GUID (**verify the header name and your label GUID in your tenant**);
  alternatively key on the agreed keyword/classification per the Phase-1 design. *Which* mail warrants
  DNF is a compliance/privacy determination — configure to their mapping.

## External recipient can't open the encrypted message
- **Cause A — recipient experience.** External recipients read via **one-time passcode / OME portal**
  (Requirement R7); a mail/social account mismatch or a blocked portal breaks the flow. **Fix:** have
  them use the OTP path; confirm the OME portal is reachable from their side.
- **Cause B — branding renders as untrusted.** Missing/broken branding looks like phishing. **Fix:**
  re-run `Set-OMEConfiguration` (Phase 2), verify with `OME-Validate.ps1` and a test send (Gate 4);
  **verify current logo size/format limits.**

## Branding doesn't appear, or the logo is broken
- **Cause A — wrong identity.** You set branding on a custom template but the rule uses the default
  configuration (or vice-versa). **Fix:** confirm which configuration the rule applies; align them.
- **Cause B — logo format/size.** The image exceeds current limits or is an unsupported format.
  **Fix:** resize/reformat; **verify current limits in your tenant.**
- **Cause C — Advanced feature without licensing.** Custom branding templates need **Advanced Message
  Encryption (E5 / E5 Compliance)**. **Fix:** confirm licensing (R1) or fall back to default branding.

## `Set-OMEConfiguration` / `New-TransportRule` — "term is not recognized"
- **Cause:** wrong endpoint. `*-OMEConfiguration`, `*-IRMConfiguration`, `*-TransportRule`,
  `Test-IRMConfiguration`, `Get-RMSTemplate` are **Exchange Online PowerShell**
  (`Connect-ExchangeOnline`). **Fix:** connect Exchange Online; both endpoints ship in
  `ExchangeOnlineManagement`.

## A rule is encrypting more mail than intended after enforcement
- **Cause:** the condition is too broad (e.g. all external recipients) or the scope was widened too
  fast. **Fix (immediate):** `Set-TransportRule -Mode Audit` (or `Disable-TransportRule`) — encryption
  stops at once; tune the condition and re-pilot. Widen scope **group-by-group** with
  `OME-ScopeHealth.ps1`, re-running the gates each time.

## `OME-Report.ps1` counts don't match message trace
- **Cause:** message trace is authoritative; the report is a scoped rollup and message trace does not
  label every path as "encrypted." **Fix:** reconcile against message trace and, for Advanced external
  mail, `Get-OMEMessageStatus` (Gate 9). Message-trace retention is tenant-dependent — **verify.**

## Revocation / expiration options aren't available
- **Cause:** message revocation and expiration are **Advanced Message Encryption** features and apply to
  OME-portal (external) mail. **Fix:** confirm E5 / E5 Compliance licensing (R1); confirm
  `Get-OMEMessageStatus` / `Set-OMEMessageRevocation` and the expiration property in your tenant
  (**verify property/licensing**).

## When to escalate beyond this solution
- **What must be encrypted, what triggers Do Not Forward, and how long external mail stays readable** →
  **compliance / privacy / legal** (this solution configures and evidences the method; the mapping is
  their determination — deferred).
- **Records-retention or legal-hold interaction with encrypted mail** → **records / legal.**
- **Feature genuinely absent despite correct licensing** → verify against current Microsoft
  documentation and open a Microsoft support case; OME/Advanced Message Encryption capabilities evolve.


---


# Best Practices — Purview Message Encryption (OME) in Microsoft Purview

Field-tested guidance for running OME well. It follows the same order the solution is built: get the
**RMS foundation and branding** right, then let **rules** apply encryption — piloted in `Audit` mode,
proportionate to sensitivity, and defensible.

## 1. Enable and prove the RMS foundation before anything else

- OME is only as healthy as **Azure RMS** underneath it. Confirm `AzureRMSLicensingEnabled : True` and
  a clean `Test-IRMConfiguration` **before** you build branding or rules — most "encryption isn't
  working" tickets trace back to an RMS/IRM problem, not the rule.
- Treat RMS enablement as a **tenant-wide, change-controlled** action; it affects all message
  encryption, not just your pilot.

## 2. Brand the experience — an unbranded portal reads as phishing

- Recipients (especially external ones) are asked to click a link and, often, complete a one-time
  passcode. If the wrapper and portal carry **default Microsoft branding or no branding**, people
  distrust it. Set your **logo, colour, and text** on the default OME configuration so the experience
  is unmistakably yours.
- Keep the disclaimer and "read the message" text **clear and reassuring** — tell recipients why they
  received an encrypted message and what to do. Follow Microsoft's current **logo size/format** limits
  (verify them; oversized logos fail to render).

## 3. Always pilot rules in AUDIT mode, scoped to a group

- A mail flow rule with `-Mode Audit` **matches and logs but does not encrypt** — this is your
  simulation. Build every OME rule in `Audit` first, scoped to **`SG-OME-Pilot`**, and confirm the
  match in **message trace** before flipping to `Enforce`.
- Expand **group-by-group** (or by loosening `-SentToScope` / conditions deliberately), never
  tenant-wide in one move. Re-run the Testing gates after each expansion.

## 4. Pick the template that fits the flow — Encrypt vs Do Not Forward

- **`Encrypt`** protects the message but lets the recipient **reply and forward** — right when the
  recipient needs to work with the content or route it onward within their own controls.
- **`Do Not Forward`** additionally blocks **forward/print/copy** — reserve it for the most sensitive
  one-to-one / one-to-few sends where onward sharing must be prevented. DNF *everything* creates
  friction and drives workarounds; use it deliberately.

## 5. Prefer classification-driven triggers over fragile keywords

- A subject keyword like `[encrypt]` is a fine **starting** trigger, but it depends on users
  remembering it. As labeling matures, drive encryption from a **sensitivity label** (a `Confidential`
  / `Highly Confidential` label can apply protection itself or serve as a rule condition) so the
  strongest protection follows the **classification**, not a typed string.
- Keep the condition→template mapping **narrow and explicit**; over-broad conditions (e.g. "encrypt all
  external mail") break automated flows and recipient usability.

## 6. Set recipient expectations to cut support load

- Document the **recipient experience** for both internal (inline) and external (OTP / OME portal)
  correspondents, and give the help desk a short runbook. Most "the encrypted email is broken" tickets
  are unfamiliarity, not failure.
- Test the **external** experience to your real correspondent domains during the pilot — the OTP/portal
  flow varies by provider (Outlook.com, Gmail, etc.).

## 7. Use Advanced features only where licensed — and know their limits

- **Custom branding templates**, **message revocation** (`Set-OMEMessageRevocation`), and **expiration**
  require **Advanced Message Encryption** (E5 / E5 Compliance). Don't design around them on a Basic OME
  tenant — plan on the **default** branding and the two templates.
- Revocation/expiration apply to mail read via the **OME portal** (typically external recipients);
  they don't retroactively control a message a Microsoft 365 recipient already opened inline. **Verify
  current behaviour and licensing in your tenant.**

## 8. Don't over-encrypt the plumbing

- Encrypting mail that flows to **systems** (ticketing, journaling, archiving, downstream automation)
  that can't process OME will **break** those flows. Exclude or narrowly scope rules away from
  service/system mailboxes, and confirm journaling/archiving still capture what compliance needs.

## 9. Keep the evidence trail — message trace and reporting

- **Message trace** (and, for Advanced, `Get-OMEMessageStatus`) is the authoritative record of what was
  encrypted. Report **counts by rule/template/time** (`OME-Report.ps1`) for leadership; don't rebuild
  a shadow log of message contents.
- Retention/disposition of mail-flow and encryption evidence is a **records/legal determination** — do
  not delete it to "clean up."

## 10. Separate the technical control from the sensitivity decision

- OME **enforces** a policy; it does not **decide** what is sensitive. Keep the condition→template
  mapping owned by **compliance/privacy**, reviewed as classification and regulation evolve. The
  administrator operates the control; the business owns the determination
  (`global-requirements-purview.md` §5).

## 11. Verify against your tenant — the surfaces evolve

- OME templates, the `*-OMEConfiguration` properties, transport-rule parameters (e.g. the custom-branding
  parameter name), and Advanced-feature availability are **licensing-dependent** and the Exchange/Purview
  portals **change**. Confirm exact paths, parameters, and capability availability **against your
  licensing/tenant** rather than assuming; treat anything in preview as such.


---


# Deliverables Summary — Purview Message Encryption (OME) in Microsoft Purview

Everything included in this solution, and what each piece is for.

## Documentation

| Document | Purpose |
| --- | --- |
| **Solution Overview** (`01-solution-overview.md`) | What OME delivers, the RMS foundation, the `Encrypt` / `Do Not Forward` templates, branding, rule-driven encryption, Basic vs Advanced licensing, and the Assess→Design→Configure→Pilot(Audit)→Validate→Expand model. |
| **Requirements** (`02-requirements.md`) | OME-specific prerequisites — Basic vs Advanced licensing, Azure RMS enabled/healthy, Exchange admin roles, the branding decision, the trigger→template mapping, optional label triggers, recipient experience, and the pilot/Audit-mode change control. |
| **Implementation** (`03-implementation.md`) | Ordered steps: enable RMS, set branding, build the mail flow rules in **`Audit` mode** scoped to a pilot group, validate in a controlled window, then flip to **`Enforce`** and expand — each object named, with pass/fail gates and rollback. |
| **Testing & Validation** (`05-testing.md`) | Ten pass/fail gates from licensing and RMS health through template/branding, Audit-mode detection, a controlled real send, Do-Not-Forward restriction, reporting reconciliation, and the compliance/privacy sign-off before enforcement. |
| **Troubleshooting** (`06-troubleshooting.md`) | The common OME failure modes (RMS/IRM off, `Test-IRMConfiguration` failing, branding not rendering, rule not matching or matching too much, external recipient can't open, DNF not restricting, Advanced features unavailable) and how to resolve them. |
| **Best Practices** (`07-best-practices.md`) | RMS-first, brand the experience, pilot in Audit, right template per flow, classification-driven triggers, recipient expectations, Advanced-only limits, don't over-encrypt system flows, evidence integrity, and separating the control from the sensitivity decision. |
| **Executive Summary** (`executive-summary.md`) | One-page business framing for decision-makers. |

## PowerShell tools (5)

All tools are **read-only or `-WhatIf`/Audit-mode by default**, authenticate **interactively** (no
credentials in code), and use **Exchange Online PowerShell** (`Connect-ExchangeOnline`) and/or
**Security & Compliance PowerShell** (`Connect-IPPSSession`) / **Microsoft Graph** (`Connect-MgGraph`).
Azure RMS activation and the branding **preview** are portal actions; these tools handle discovery,
configuration (branding + rules), validation, reporting, and scope/health.

| Script | Type | What it does |
| --- | --- | --- |
| **`OME-Discovery.ps1`** | Read-only | OME **readiness/discovery**: reports the IRM/Azure RMS configuration (`AzureRMSLicensingEnabled`), the available RMS templates (`Encrypt` / `Do Not Forward`), existing OME configurations (default + custom branding), any existing mail flow rules that apply/remove OME, and licensing hints (Basic vs Advanced). Changes nothing. |
| **`OME-Configure.ps1`** | `-WhatIf` default | **Configuration/remediation** helper. `-Action Branding` previews/sets the OME branding (`Set-OMEConfiguration`, or `New-OMEConfiguration` for a custom template). `-Action MailFlowRules` prints and (with `-Commit`) creates the `OME-Encrypt-Outbound-Pilot` and `OME-DoNotForward-Confidential` rules **in `Audit` mode**, scoped to `SG-OME-Pilot`; a separate `-Enforce` switch is required to flip a rule to `Enforce`. `-WhatIf` by default; nothing changes without `-Commit`. |
| **`OME-Validate.ps1`** | Read-only | **Validation checker**: reports whether the OME prerequisites/config are met — RMS enabled, `Test-IRMConfiguration` result, the two rules present with their `Mode` and scope, branding present — as pass/fail lines aligned to `05-testing.md`. |
| **`OME-Report.ps1`** | Read-only | **Encryption reporting rollup**: summarizes encrypted-message activity from **message trace** (by rule/template/time) to CSV for a leadership rollup, and — where Advanced Message Encryption applies — reports `Get-OMEMessageStatus` for a supplied message ID. Notes message trace as authoritative; no content/recipient over-collection. |
| **`OME-ScopeHealth.ps1`** | Read-only | **Scope/health helper**: runs `Test-IRMConfiguration` (sender/recipient round-trip) and reports RMS/IRM health, the `SG-OME-Pilot` membership and each OME rule's scope, so expansion stays deliberate and reversible; previews the current scope before you widen it. |

## Named objects (verbatim — used across docs, scripts, and tests)

- **Pilot sender group:** `SG-OME-Pilot`
- **Protection templates:** **`Encrypt`**, **`Do Not Forward`** (and user-facing **Encrypt-only**)
- **Default branding object:** the default OME configuration (identity **"OME Configuration"**);
  **custom** template (Advanced only): **`OME-Branding-Corp`**
- **Mail flow (transport) rules:**
  - `OME-Encrypt-Outbound-Pilot` — sender ∈ `SG-OME-Pilot` AND (subject `[encrypt]` OR external
    recipient) → template **`Encrypt`** (Audit first)
  - `OME-DoNotForward-Confidential` — message labeled **`Highly Confidential`** (or agreed
    classification) → template **`Do Not Forward`** (Audit first)

## What this solution deliberately does NOT do

- It does **not** decide **what is sensitive** or which mail must be encrypted — that condition→template
  mapping is a **compliance/privacy determination** (`global-requirements-purview.md` §5).
- It does **not** enforce encryption before piloting rules in **`Audit` mode** and passing the gates.
- It does **not** invent cmdlets, template names, `*-OMEConfiguration` properties, or transport-rule
  parameters — where a name/parameter or capability is licensing- or tenant-specific, it says "verify
  in your tenant."
- It does **not** assume **Advanced Message Encryption** (custom branding, revocation, expiration) —
  those are flagged as E5/E5-Compliance features to verify.
- It does **not** store credentials or secrets; every tool authenticates interactively and defaults to
  read-only or `-WhatIf`.
