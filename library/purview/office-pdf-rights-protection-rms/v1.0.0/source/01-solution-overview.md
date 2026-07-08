# 1. Solution Overview — Office & PDF Rights Protection (RMS/IRM), Microsoft Purview

## What this solution is
Most data controls stop at the perimeter: DLP inspects at egress, conditional access gates the app,
but once a document leaves the tenant it is a plain file. **Rights protection** — the encryption and
usage-rights engine historically called **Azure Rights Management (RMS)** / **Information Rights
Management (IRM)**, now delivered through **Microsoft Purview sensitivity-label encryption** — attaches
**persistent protection to the file itself**: the content is encrypted and carries an embedded policy
that says *who* can open it and *what* they can do (view, edit, copy, print, reply/forward). That
protection travels with the file to a USB stick, a personal inbox, or a partner's laptop.

This solution configures **label-based encryption and usage rights for Office documents and PDFs** —
so protection travels with the file — using the Microsoft Purview portal and Security & Compliance
PowerShell. It confirms the **Rights Management service is activated**, designs a small set of
**protection labels** (an encrypt-only / Do-Not-Forward nudge, a template-based "all employees" grant,
and a **named-recipient** custom grant), configures each label's **encryption, usage rights, offline
access, and content-expiry**, ensures **Office and PDF** files inherit that protection, pilots on a
small ring first, validates that the right people can open files and the wrong people cannot, then
expands.

## Why this matters
- **Protection that survives sharing.** Encryption + usage rights are embedded in the file, so an
  over-shared, forwarded, or exfiltrated document is still unreadable to anyone outside the grant.
- **Usage rights, not just encryption.** Beyond "can they open it", rights control **print, copy,
  edit, and forward** — so a viewer can read but not extract, and a partner can comment but not save a
  clear copy.
- **PDF is a first-class citizen.** So much sensitive content is exported to PDF (statements,
  contracts, reports); label-based protection covers **protected PDFs**, closing a common gap where
  Office files were protected but their PDF exports were not.
- **Revocable and time-boxed.** Content expiry and offline-access limits mean access can lapse
  automatically; super-users and revocation give records/legal a recovery and takedown path.
- **The evidence trail.** Protection state per label — encryption on, rights defined, expiry set — is
  exportable as evidence that persistent protection is actually configured, not merely intended.

## What "rights protection" configures (the levers)
| Lever | What it does | Where it is set |
|---|---|---|
| **RMS/Rights Management activation** | The tenant-level encryption service that issues and enforces use licenses | M365 admin center / `AIPService` PowerShell — must be **Activated** |
| **Label encryption** | Turns a sensitivity label into a protection label (content is encrypted on apply) | The **label's** encryption settings (`Set-Label -EncryptionEnabled`) |
| **Usage rights** | Who can do what: view / edit / copy / print / reply / forward / full control | Label encryption: **assigned permissions** (template) or **user-defined** |
| **Do Not Forward / Encrypt-Only** | User-driven protections for email (DNF) and files (encrypt-only, user picks recipients) | Label set to **user-defined** permissions (`EncryptionDoNotForward` / `EncryptionPromptUser`) |
| **Offline access & content expiry** | How long a use license is valid offline, and whether access lapses on a date/after N days | Label encryption (`EncryptionOfflineAccessDays`, `EncryptionContentExpiredOnDateInDaysOrNever`) |
| **Office & PDF coverage** | Office apps and protected-PDF handling apply and honor the encryption | Office apps + tenant/SharePoint-OneDrive settings for labeled PDFs |

> **Assigned (template) vs user-defined permissions is the core design choice.** *Assigned* permissions
> bake a fixed grant into the label (e.g. "All employees can view+edit; nobody else"). *User-defined*
> permissions let the user choose recipients at protect time (Do Not Forward for mail, encrypt-only for
> files). Most designs use **both**: template labels for known audiences, user-defined labels for
> ad-hoc protection.

## Protection-label design (the starting point — confirm with your governance owners)
> A **technical starting point**; the final grants (who, what rights, expiry) are an
> information-governance / legal determination — confirm with the accountable owner. Names here are
> reused verbatim across the docs and scripts.

| Label | Protection type | Usage rights (starting point) | Typical use |
|---|---|---|---|
| `Confidential \ All Employees` | **Assigned (template)** | All authenticated org users: **Co-Author** (view, edit, print, copy); no rights to externals | Internal-only sensitive content |
| `Confidential \ Recipients Only` | **User-defined** (Encrypt-Only / Do Not Forward) | User picks recipients at protect time; recipients get view/edit but **cannot forward** | Ad-hoc sensitive mail/files |
| `Highly Confidential \ Named Recipients` | **Assigned (template)** | A **named group** only, **Viewer** rights (view, no print/copy/edit); externals by explicit address | Board / M&A / regulated data |

## Naming convention (used in every doc and script)
| Artifact | Name |
|---|---|
| Protection label — template, internal | `Confidential \ All Employees` |
| Protection label — user-defined | `Confidential \ Recipients Only` |
| Protection label — named recipients | `Highly Confidential \ Named Recipients` |
| Label policy (pilot) | `RMSPolicy – Pilot – Ring1` |
| Label policy (broad) | `RMSPolicy – Broad – AllUsers` |
| Pilot ring group | `grp-rms-pilot@contoso.com` |
| Named-recipient group | `grp-rms-named-recipients@contoso.com` |
| RMS super-user group (recovery) | `grp-rms-superusers@contoso.com` |

## What you can control
- **Which labels encrypt**, and whether each uses **assigned** (fixed grant) or **user-defined** rights.
- **The exact usage rights** per audience (view / edit / copy / print / reply / forward / full control).
- **Offline-access window** and **content expiry** per label.
- **Office and PDF coverage** — that protected PDFs open for the right people in supported readers.
- **Recovery** — the super-user group so records/legal can always open protected content.
- **Rollout order** — pilot ring → broad — and rollback (remove protection from a label / unpublish).

## Limitations (be honest with buyers)
- **Encryption is high-impact and mostly not "simulatable".** Applying encryption to a label changes how
  every file with that label opens. There is **no service-side simulation** for label encryption — the
  safe mechanism is a **pilot label policy scoped to a pilot ring**, validated before broad publish. This
  solution enforces pilot-first for exactly that reason, and starts encryption **off/unpublished**.
- **RMS must be activated first.** If the Rights Management service is not **Activated**, no label
  encryption works. This solution verifies activation before configuring labels.
- **Reader/app support matters.** Protected Office files open in current Office apps; **protected PDFs**
  open in Microsoft Edge and readers with Microsoft Information Protection support — **verify your PDF
  reader/tenant support**; older or third-party readers may not honor protection.
- **External recipients need an identity.** A recipient outside the tenant must authenticate (org
  account, Microsoft account, or a one-time passcode where supported) to obtain a use license — **verify
  the current external-sharing options for your tenant**.
- **Double Key Encryption (DKE) and HYOK are out of scope.** This solution covers cloud-based RMS label
  encryption; DKE/HYOK are separate builds.
- **Determinations are deferred.** *Who* may access what, retention/records implications of encrypted
  content, and legal-hold/eDiscovery handling of encrypted files are **governance/legal determinations**
  — this solution provides the configuration method and evidence.

## The standard deployment model
> Assess RMS activation and current label-encryption posture → design the protection labels and usage
> rights (assigned vs user-defined, expiry, offline) → configure on a **pilot label policy scoped to a
> pilot ring** (`-WhatIf` → commit), encryption unpublished until validated → validate that the right
> people can open Office and PDF files and the wrong people cannot → **expand** to the broad policy →
> validate → operate (recovery, revocation, evidence).
> Pattern: **Assess → Design → Configure → Pilot → Validate → Expand.**
