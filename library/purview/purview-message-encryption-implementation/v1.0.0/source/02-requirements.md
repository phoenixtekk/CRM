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
