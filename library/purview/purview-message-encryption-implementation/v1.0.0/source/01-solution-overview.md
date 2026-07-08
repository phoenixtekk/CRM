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
