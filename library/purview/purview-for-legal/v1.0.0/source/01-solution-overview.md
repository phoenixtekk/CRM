# 1. Solution Overview — Microsoft Purview for Legal

## What this solution is
A law firm or a corporate legal department holds two things nobody else in the tenant holds in the same
concentration: **attorney-client privileged material** and **matter records** that carry retention,
records, and legal-hold obligations. Generic tenant configuration does not fit that reality — privilege
is inadvertently disclosed, matter content is under- or over-retained, and there is no evidence that any
control is actually in place. This solution is a **Legal-tailored Purview program** that *curates and
sequences* the granular Purview capabilities for a legal organization rather than re-teaching each one:
it stands up (1) **sensitivity labels** for privileged and matter-confidential content — with
encryption; (2) **DLP** to prevent the inadvertent disclosure of privileged material across email,
SharePoint, OneDrive, Teams and endpoints — **piloted in simulation**; (3) **retention & records** for
the matter lifecycle (matter-based retention, disposition review, and legal-hold *coordination*) plus an
**audit-evidence** trail; and (4) tracks the whole thing in **Compliance Manager**. It uses only the
**Microsoft Purview portal** (`purview.microsoft.com`), **Security & Compliance PowerShell**
(`Connect-IPPSSession`), and **Microsoft Graph** — no third-party tooling.

> **This is a technical-control-and-evidence program, not a legal determination.** *Which* content is
> privileged, how matters map to content and retention, what the records schedule is, and whether any
> given matter is under a **legal hold** are **legal and records determinations** owned by your firm's
> **legal, records, and compliance functions**. This solution provides the configured control, the
> register, and the evidence — it does **not** decide privilege, matter scope, retention duration, or
> hold. **Legal holds and eDiscovery case actions are the legal function's; this solution provides the
> technical method and references them, it does not create the hold decision.**

## Why this matters
- **Privilege, once disclosed, is hard to claw back.** An email to the wrong recipient or a mislabeled document can waive privilege. Sensitivity labels (with encryption) plus DLP are the Microsoft controls that keep privileged and matter-confidential content inside the firm — but they only protect content **from the point they are applied forward**, which is why configuring now matters.
- **DLP is high-impact and must not be dropped into enforcement blind.** A DLP policy that blocks legal's own routine sharing on day one is worse than none — it trains people to work around it. Purview DLP supports a **simulation (test) mode** that surfaces what *would* have matched without blocking anything; this program always pilots there first.
- **Matter records live and die on retention.** Matter content must be retained per the records schedule and disposed of under governance — not kept forever by accident, not deleted prematurely. Purview retention labels/policies and **disposition review** operationalize the matter lifecycle; **legal hold** overrides disposal, and coordinating that override is a legal function you *support*, not decide.
- **Evidence is the deliverable.** "We protect privileged material" is an assertion; a **control → configuration → proof** binder is evidence. This program produces one.
- **The controls are licensing-dependent and evolving.** Encryption labels, advanced/endpoint DLP, records/regulatory-records retention, and Audit Premium require **Microsoft 365 E5** or the **E5 Compliance** add-on; the portal changes. Capabilities are **cited or flagged "verify your licensing/tenant"**, never assumed.

## How it works
1. **Assess.** Discover what the tenant already has — compliance licensing/plans, the least-privilege roles, existing sensitivity labels and label policies, DLP policies, retention labels/policies, unified-audit state and audit retention, and (read-only) any existing eDiscovery holds — so the program is built on facts.
2. **Design the control map.** With legal/records, map the in-scope obligations (privilege protection, matter confidentiality, matter records retention, disposition, hold coordination, audit evidence) to the four Purview control domains and to the **named artifacts** below. The privilege/matter/retention/hold determinations are legal's; this solution provides the register and the technical control.
3. **Configure — safely.** Create the sensitivity labels (privileged / matter-confidential, with encryption), the DLP policy **in simulation**, the matter-records retention label + publish policy, the audit-evidence retention policy, and the disposition-review stage. Every high-impact change is piloted disabled/simulated before enforcement.
4. **Pilot & validate.** Prove the labels apply and encrypt, the DLP policy matches privileged content **in simulation** (nothing blocked yet), retention preserves matter content, and audit evidence is retained — on a bounded **pilot scope** before tenant-wide enforcement.
5. **Produce the evidence.** Generate the control-mapping + evidence binder (control → Purview object → configuration → proof) for the legal/compliance file.
6. **Expand & operate.** Move DLP from simulation to enforcement and expand the labels/retention on the approved scope, schedule the read-only re-assessment so drift is caught, and hand the register, binder, and runbook to legal/records as a standing procedure.

## The control stack this solution curates
- **Sensitivity labels (Information Protection)** — `Get/New-Label` + `Get/New-LabelPolicy`: a label for **attorney-client privileged** content (encrypted, restricted) and one for **matter-confidential / work-product** content, published to the legal population — the confidentiality control.
- **Data Loss Prevention** — `Get/New-DlpCompliancePolicy` + `Get/New-DlpComplianceRule`: a policy that detects privileged/matter-confidential content (by label and/or sensitive info types) across Exchange, SharePoint, OneDrive, Teams and **Endpoint**, **built in simulation/test mode first** — the inadvertent-disclosure control. *High-impact.*
- **Retention & records (Data Lifecycle / Records Management)** — `Get/New-ComplianceTag` + `Get/New-RetentionCompliancePolicy`: matter-based retention labels/policies and a **disposition-review** stage for reviewed disposal — the matter-records lifecycle control. **Legal hold overrides disposal; hold decisions are legal's** (`Get-CaseHoldPolicy` is referenced read-only only).
- **Audit (Standard/Premium)** — unified audit logging and **audit log retention policies** (`Get-UnifiedAuditLogRetentionPolicy`) keeping the evidence of who did what — the audit-trail control.
- **Compliance Manager** — an **assessment** that tracks the legal control implementation and improvement actions — the control-tracking layer (configured in-portal; applicability is legal/compliance's determination).

## What you can control
- Which **sensitivity labels** implement privilege / matter-confidentiality, their **encryption** settings, and their publish scope.
- The **DLP** policy's detection (labels + sensitive info types), its **locations** (email/SharePoint/OneDrive/Teams/Endpoint), and — critically — that it runs in **simulation** until validated.
- Which **retention labels/policies** implement the matter-records schedule, and whether disposal is governed by **disposition review**.
- Which operations/users get **extended audit retention** as evidence.
- The **control register** (`Control Map – Legal – Purview`) and the **evidence binder** contents.
- The **pilot scope** validated before any enforcement.

## Limitations (be honest with buyers)
- **We configure the control; legal makes the determination.** What is privileged, how matters map to content, the retention schedule, and whether any matter is under **legal hold** are **legal/records** determinations. **Verify with your legal and records functions.**
- **Legal holds and eDiscovery case actions are legal's.** This solution references the technical method (`Get-CaseHoldPolicy` read-only, eDiscovery holds in-portal) but **does not create, release, or scope a hold** — that is a legal decision with legal consequences.
- **Protection is largely not retroactive.** Labels, DLP, and retention act **from application forward**; they do not reach back to protect or preserve content that was never labeled or captured.
- **DLP and encryption are high-impact.** An encryption label can make content unreadable to unlicensed/external parties; a DLP block can interrupt legitimate legal work. Both are **piloted (simulation/test) first** with documented rollback before enforcement.
- **Records/regulatory-records retention can be irreversible by design.** Where the matter schedule calls for a **regulatory record** label (immutable, non-removable), it is gated hardest — applied only under explicit legal/records sign-off. **Verify the exact behavior in your tenant.**

## Naming convention (used in every doc and script)
Every artifact this solution creates is named `<Purpose> – <Scope> – <Stage>` and reused verbatim
across the docs, scripts, and portal. The standard set:

| Artifact | Name |
|---|---|
| Privileged sensitivity label (encrypted) | `Protect – Legal Privileged – Restricted` |
| Matter-confidential sensitivity label | `Protect – Legal Matter Confidential – Confidential` |
| DLP policy for privileged material (simulation) | `DLP – Legal Privileged – Simulate` |
| Matter-records retention publish policy | `Retention – Legal Matter Records – Publish` |
| Disposition-review stage | `Disposition – Legal Records – Review` |
| Audit evidence retention policy | `Audit Retention – Legal Evidence – LongTerm` |
| Compliance Manager assessment | `Assessment – Legal Controls – Program` |
| Control-mapping register | `Control Map – Legal – Purview` |
| Evidence binder export | `Evidence – Legal Controls – Binder` |
| Pilot validation scope | `Legal Pilot – Privileged Data – Stage1` |

## The standard deployment model
> Assess the controls and licensing you have → design the obligation-to-control map with legal/records →
> configure sensitivity labels, DLP, matter retention, and audit evidence → **pilot in
> simulation/test/disabled mode** on a limited scope → validate the controls work and produce evidence →
> expand to enforcement. Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate →
> Expand (enforce).** High-impact controls (encryption labels, DLP, records retention) are always
> piloted before enforcement; legal holds and privilege/retention determinations are legal's.
