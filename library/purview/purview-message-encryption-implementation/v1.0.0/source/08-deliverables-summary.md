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
