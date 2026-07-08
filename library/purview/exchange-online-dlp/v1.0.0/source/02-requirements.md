# Requirements — Exchange Online DLP in Microsoft Purview

Confirm every prerequisite below **before** you configure anything. Category-level prerequisites
(tenant, compliance licensing model, least-privilege roles, Security & Compliance PowerShell / Graph
toolchain, in-scope data sources, compliance/privacy/legal stakeholders, pilot scope + change
control) are in `global-requirements-purview.md` — reference them; they are **not** repeated here.
The items below are the ones **specific to Exchange Online DLP**: the **content to key on**, the
**recipient-scope decisions**, **policy tips**, **transport-rule interaction**, and the **pilot
sender scope**.

Each requirement is written as **Description · Why · Verify · Implement if missing.**

---

## R1. DLP-capable licensing for Exchange, assigned to in-scope senders

**Description:** Licensing that includes **Data Loss Prevention for Exchange Online**. Baseline DLP is
broadly available, but **advanced** conditions/classifiers, deeper simulation reporting, and some
**encryption** actions can require **Microsoft 365 E5** or the **E5 Compliance** add-on. Message
encryption actions additionally depend on **Microsoft Purview Message Encryption (OME) / Azure Rights
Management** being enabled.
**Why:** DLP is plan-gated at the advanced tier, and the encrypt action will not be available unless
message encryption is enabled in the tenant.
**Verify:** Microsoft 365 admin center → **Billing → Licenses** confirms the SKU/add-on; in the
Purview portal, **Data Loss Prevention** exposes the **Exchange email** location. Confirm message
encryption is enabled (`Get-IRMConfiguration` / `Get-OMEConfiguration`) before relying on an encrypt
action. Cross-check advanced features against the *Microsoft Purview service description* — **verify
against your licensing/tenant.**
**Implement if missing:** Acquire/assign the required SKU/add-on and enable Purview Message Encryption
before authoring encrypt rules.

## R2. Least-privilege roles for DLP authoring (and mail-flow awareness)

**Description:** The least-privilege roles, mapped to **named** people:
- **Compliance Administrator** or **Compliance Data Administrator** (or the **DLP Compliance
  Management** role group) to author the DLP policy and rules.
- Read access to **Exchange mail-flow (transport) rules** (e.g. an Exchange **View-Only Organization
  Management** role) so you can see how existing transport rules interact with DLP.
- **Global Administrator** only where genuinely required (e.g. first-time service enablement or
  enabling message encryption).
**Why:** Purview uses fine-grained role groups; DLP authoring and Exchange mail-flow administration are
distinct duties and should not be over-granted to one account.
**Verify:** Purview portal → **Roles & scopes / Permissions** confirms the DLP role membership;
`Connect-IPPSSession` succeeds and `Get-DlpCompliancePolicy` returns. `DLPEXO-Discovery.ps1` reports
the DLP and transport-rule signals it can read.
**Implement if missing:** Assign the least-privilege role for each duty under change control.

## R3. In-scope sensitive content — sensitive information types and/or sensitivity labels

**Description:** The **sensitive content** the rules will match — **sensitive information types**
(built-in such as *Credit Card Number*, *U.S. Social Security Number (SSN)*, or custom SITs / EDM /
trainable classifiers) **and/or** **sensitivity labels** (e.g. *Confidential*) already published and
in use — that define *what* triggers each rule, plus the intended **instance count / confidence**
thresholds.
**Why:** A DLP rule acts on **content that matches a condition**; without SITs or labels to match, the
rule has nothing to key on (or would apply to *all* mail, which is rarely intended).
**Verify:** Purview → **Data classification → Sensitive info types** lists the SITs; **Information
Protection → Labels** shows published labels. `DLPEXO-Discovery.ps1 -IncludeSensitiveTypes`
inventories both. Confirm the *count/confidence* thresholds with your data owners.
**Implement if missing:** Select/adopt the needed SITs (and confidence/count thresholds) and, where
you will key on labels, confirm the sensitivity labels are published. **Regulatory applicability of a
given SIT is a compliance determination — not a technical default.**

## R4. Recipient-scope decision (external vs internal, trusted-partner domains)

**Description:** A documented decision on **which recipient scope is risky** — typically **external**
(outside the organization) is the primary concern, with **internal** handled for visibility — and an
explicit list of **trusted-partner domains** to treat as an **exception** so sanctioned business flows
(e.g. an outsourced payroll processor) are not blocked.
**Why:** DLP rules key off recipient scope; blocking *all* external mail containing a SIT is usually
too broad, and a missing partner exception will block legitimate business the moment you enforce.
**Verify:** Confirm the external/internal scope and the trusted-partner domain list **in writing** with
compliance/security. **Whether a domain is "trusted" is a business/compliance determination**, captured
here, not chosen by the administrator.
**Implement if missing:** Capture the recipient-scope decision and the partner-domain exception list
before authoring the rules that reference them.

## R5. Per-scenario action decision (notify / warn / encrypt / block) — agreed with stakeholders

**Description:** A documented decision, **per scenario** (sensitive→external high volume,
sensitive→external low volume, labeled→external, sensitive→internal), of the intended action —
**Notify (policy tip)**, **Warn with override / business justification**, **Encrypt**, or **Block** —
agreed with **compliance / security** (and privacy/legal where the action affects users or business
partners).
**Why:** The action is a **policy decision, not a technical default**; encrypting or blocking a message
has real operational and business impact and must reflect enterprise policy, not the administrator's
preference.
**Verify:** Confirm the per-scenario action matrix **in writing** before you move any rule from
simulation to enforce.
**Implement if missing:** Capture the decision with the relevant owners; until then, deploy **notify /
simulation only.** (See `global-requirements-purview.md` §5.)

## R6. Policy-tip and notification plan

**Description:** The **policy-tip** and **notification** design: the custom **policy-tip text** shown
to senders in Outlook, whether senders may **override** (with/without business justification) or
**report a false positive**, whether the **sender** and/or a **compliance mailbox / admin** receive an
email notification, and whether an **incident report** is generated.
**Why:** Policy tips and notifications are the user-education and evidence layer; a block with no
explanation generates tickets and workarounds, and an unrecorded match yields no evidence.
**Verify:** Confirm the tip text, override options, and notification/incident-report recipients with
stakeholders. **Verify policy-tip rendering per Outlook client (desktop/web/mobile) in your tenant** —
tip support varies by client.
**Implement if missing:** Draft the tip text and notification/override plan before authoring the
rules; a compliance mailbox for notifications/incident reports should exist first.

## R7. Transport-rule (mail-flow) interaction reviewed

**Description:** A review of existing **Exchange mail-flow (transport) rules** — especially any that
already **block, redirect, encrypt, or add headers** based on content or recipient — so the new DLP
policy does not **duplicate, conflict with, or be pre-empted by** them (e.g. a transport rule that
already deletes a message before DLP evaluates it, or two controls both stamping encryption).
**Why:** DLP and transport rules **coexist** and both act in transport; overlap causes confusing
double-actions or silent pre-emption that looks like "DLP isn't working."
**Verify:** Review transport rules (`Get-TransportRule`, or Exchange admin center → **Mail flow →
Rules**). `DLPEXO-Discovery.ps1` flags transport rules that reference content/encryption/block actions
for you to review. **Determining which control owns a given behavior is a design decision — capture
it.**
**Implement if missing:** Reconcile overlaps **before** enforcing DLP — decide which control owns each
behavior and remove/adjust the duplicate.

## R8. A named pilot sender scope and change control (simulation/test first)

**Description:** A **named pilot sender scope** (a mail-enabled security group of pilot senders, e.g.
`SG-DLPEXO-Pilot`, used at the **rule level** via a sender condition) and agreement to run the policy
in **simulation/test mode first** (`TestWithNotifications` / `TestWithoutNotifications`), under a
**change-control** process, before any enforcing, tenant-wide rollout.
**Why:** DLP block/encrypt actions are high-impact; simulation scoped to a small sender ring proves the
scenarios are seen and the rules *would* act **without** disrupting real mail flow, and lets you tune
before enforcing.
**Verify:** Confirm the pilot group exists, that **simulation/test mode** is used, and a change
window/approval path. `DLPEXO-ScopeHealth.ps1` reports the pilot group and the policy's current scope
and mode.
**Implement if missing:** Define the pilot group, deploy in simulation, and agree change control before
enabling enforcement.

> **Note on Exchange location scope.** In Purview DLP, the **Exchange** location is generally scoped as
> **All** (all mailboxes); a *pilot* is achieved by (a) running the policy in a **Test/simulation
> mode** and (b) scoping the **rules** to the **pilot sender group** (a sender/`From member of`
> condition), then widening the rule scope as you expand. **Verify the exact scoping parameters in your
> tenant** — they evolve.
