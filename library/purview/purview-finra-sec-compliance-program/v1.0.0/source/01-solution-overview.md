# 1. Solution Overview — Microsoft Purview FINRA/SEC Compliance Program

## What this solution is
A regulated broker-dealer or investment adviser lives and dies by two questions from an examiner:
*"Show me the control"* and *"Show me the evidence."* FINRA and SEC obligations — supervision of
electronic communications, books-and-records preservation, and a demonstrable audit trail — need to be
**mapped to concrete controls**, those controls **configured**, and the whole thing **evidenced** in a
form you can hand to an examiner without a scramble. This solution builds that program on **Microsoft
Purview**: it maps the technical control surface (records retention, communication supervision, audit)
to a FINRA/SEC-aligned control register, **configures** the controls in Purview — regulatory records
retention, communication-compliance (supervisory) supervision, and audit evidence retention —
**pilots them in simulation/test/disabled mode first**, validates, and produces an **evidence binder**
you can defend. It uses only the **Microsoft Purview portal** (`purview.microsoft.com`), **Security &
Compliance PowerShell** (`Connect-IPPSSession`), and **Microsoft Graph** — no third-party tooling.

> **This is a technical-control-and-evidence program, not a legal opinion.** The specific records that
> must be retained, for how long, under which rule; who must be supervised and against what lexicon;
> and whether any given configuration *satisfies* a rule are **regulatory, records, and legal
> determinations** deferred to your **compliance, records, and legal functions**. This solution
> provides the Purview method, the configured control, and the evidence — **not** the determination
> that it meets FINRA Rule 4511/3110, SEA Rule 17a-4, or the SEC Books-and-Records / Marketing rules.

## Why this matters
- **Records preservation is examinable and largely non-retroactive.** Communications and books-and-records must be preserved (historically in a non-rewriteable, non-erasable "WORM" form; SEA Rule 17a-4 was amended in 2022–2023 to also permit an **audit-trail** alternative). Purview delivers this with **regulatory records** labels and immutable retention — but only from the day they are applied forward, which is why configuring *now* matters.
- **Communication supervision is a named control.** FINRA supervision expectations (Rule 3110) require a system to review registered persons' electronic communications. Purview **Communication Compliance** (the supervisory-review capability) is the Microsoft control that operationalizes this — and it is **HR/privacy-sensitive**, so it must be built with privacy-by-design, pseudonymization where available, and strict reviewer role separation.
- **Evidence is the deliverable examiners actually want.** A control that works but can't be *shown* to work fails an exam. This solution's reporting produces a **control-to-configuration-to-evidence** binder so "the control is in place" is provable, not asserted.
- **The controls are licensing-dependent and evolving.** Regulatory records, Communication Compliance, Audit Premium, and auto-classification require **Microsoft 365 E5** or the **E5 Compliance** add-on; the portal and rule tooling change. Capabilities are **cited or flagged "verify your licensing/tenant"**, never assumed.

## How it works
1. **Assess.** Discover what you already have — compliance licensing/plans, the least-privilege roles, existing retention labels/policies, any Communication Compliance policies, unified-audit state, and audit retention — so the program is built on facts, not assumptions.
2. **Design the control map.** With compliance/records/legal, map the in-scope FINRA/SEC obligations to the three Purview control domains (records retention, communication supervision, audit evidence) and to the **named artifacts** below. The rule-to-control mapping is the compliance function's determination; this solution provides the register structure and the technical control.
3. **Configure — in simulation/test first.** Create the regulatory-records retention labels and policy, the communication-supervision policy (**in test mode**), and the audit evidence-retention policy. Every high-impact change is piloted disabled/simulated before enforcement.
4. **Pilot & validate.** Prove the labels apply and preserve, the supervision policy generates review items against test content (in test mode), and audit evidence is retained — on a bounded **pilot scope** before tenant-wide enforcement.
5. **Produce the evidence.** Generate the control-mapping + evidence binder (control → Purview object → configuration → proof) for the compliance/audit file.
6. **Expand & operate.** Move from test to enforcement on the approved scope, schedule the read-only re-assessment so drift is caught, and hand the binder and runbook to the compliance function as a standing procedure.

## The control stack this solution configures
- **Records & data lifecycle** — retention **labels** (including **records** and, where licensed, **regulatory records** with immutable, un-disablable retention) and retention **policies** across Exchange, SharePoint, OneDrive, and Teams — the books-and-records preservation control.
- **Communication Compliance** — the **supervisory-review** capability that scans registered persons' electronic communications against policies/conditions and routes items to reviewers — the supervision control. *HR/privacy-sensitive.*
- **Audit (Standard/Premium)** — unified audit logging and **audit log retention policies** keeping the evidence of who did what — the audit-trail control.
- **Compliance Manager** — regulatory **assessment templates** (e.g. FINRA/SEC-relevant templates, subject to your licensing) that track improvement actions and score control implementation — the control-tracking layer (configured in-portal; determination of applicability is compliance's).
- **Disposition review** — reviewed disposal at end of retention, so records aren't kept forever without governance.

## What you can control
- Which **retention labels/policies** implement the records-preservation control, their scope, and whether they use **records**/**regulatory records** (immutable) behavior.
- The **Communication Compliance** policy scope, conditions, and reviewers — built in **test mode** first.
- Which record types/operations/users get **extended audit retention** as evidence.
- The **control register** (which rule maps to which Purview object) and the **evidence binder** contents.
- The **pilot scope** validated in simulation/test/disabled mode before any enforcement.

## Limitations (be honest with buyers)
- **We configure the control; we do not make the determination.** Retention schedules, which communications/records are in scope, supervisory lexicons, and whether a configuration satisfies a specific FINRA/SEC rule are **compliance/records/legal** determinations. **Verify with your regulatory functions.**
- **Regulatory records are effectively irreversible by design.** A **regulatory record** label cannot be removed and its retention cannot be shortened/disabled — that is the point, and the reason it is **piloted with non-regulatory records first** and only applied under explicit compliance sign-off.
- **Preservation is largely not retroactive.** Labels/policies preserve from application forward; they do not reach back to create history that wasn't captured.
- **Communication Compliance is privacy-sensitive and license-gated.** It requires the right licensing and must be built with privacy-by-design, reviewer role separation, and (where available) pseudonymization; **outcomes and case actions are HR/legal's, not this solution's.**
- **17a-4 / WORM vs audit-trail alternative, and third-party attestations.** Whether your chosen configuration meets the amended SEA Rule 17a-4 (electronic recordkeeping requirements, including the audit-trail alternative) and any required third-party/undertaking letters are **legal determinations** — **verify with counsel and your records function.**

## Naming convention (used in every doc and script)
Every artifact this solution creates is named `<Purpose> – <Scope> – <Stage>` and reused verbatim
across the docs, scripts, and portal. The standard set:

| Artifact | Name |
|---|---|
| Regulatory-records retention label | `Records – FINRA/SEC Regulated – Regulatory` |
| Records retention-label publish policy | `Retention – FINRA/SEC Records – Publish` |
| Communications-store retention policy | `Retention – FINRA/SEC Comms Store – Immutable` |
| Communication-supervision policy (test) | `Supervision – Registered Persons Comms – Test` |
| Audit evidence retention policy | `Audit Retention – FINRA/SEC Evidence – LongTerm` |
| Compliance Manager assessment | `Assessment – FINRA/SEC Controls – Program` |
| Disposition-review stage | `Disposition – FINRA/SEC Records – Review` |
| Control-mapping register | `Control Map – FINRA/SEC – Purview` |
| Evidence binder export | `Evidence – FINRA/SEC Controls – Binder` |
| Pilot validation scope | `FINRA/SEC Pilot – Registered Persons – Stage1` |

## The standard deployment model
> Assess the controls and licensing you have → design the rule-to-control map with compliance/legal →
> configure records retention, communication supervision, and audit evidence → **pilot in
> simulation/test/disabled mode** on a limited scope → validate the controls work and produce evidence →
> expand to enforcement. Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate →
> Expand (enforce).** High-impact controls (regulatory records, supervision, retention) are always
> piloted before enforcement.
