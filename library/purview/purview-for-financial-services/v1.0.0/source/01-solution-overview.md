# 1. Solution Overview — Microsoft Purview for Financial Services

## What this delivers
This solution stands up a **Financial Services-tailored Microsoft Purview program** — sensitivity
labels, Data Loss Prevention (DLP), data lifecycle & records management, and communication
compliance — configured to support a firm's obligations under **FINRA**, the **SEC**, and the
**Gramm-Leach-Bliley Act (GLBA / Reg S-P)**. Every policy is deployed on the house model, piloted in
**simulation / test** where the capability supports it, validated against pass/fail gates, and only
then enforced and expanded.

> **Boundary you must honor.** This solution supplies the **technical configuration method and the
> evidence** — not the regulatory determination. Which records are in scope, the exact retention
> periods, the supervision/lexicon requirements, and the applicability of any rule are **compliance,
> records, privacy, and legal determinations** and are deferred to those functions. Purview features
> are **licensing-/plan-dependent** (much of this requires **Microsoft 365 E5** or the **E5
> Compliance** add-on) and the portal evolves — **verify your licensing/tenant** before relying on a
> capability.

## The four Purview capabilities this program combines
1. **Sensitivity labels** — persistent classification (for example `FS Public`, `FS Internal`,
   `FS Confidential (NPI/GLBA)`, `FS Restricted (MNPI)`) that can encrypt, mark, and restrict sharing
   of nonpublic personal information (NPI) and material nonpublic information (MNPI). The protection
   travels with the file.
2. **Data Loss Prevention (DLP)** — policies that detect financial and customer data (bank account and
   ABA routing numbers, SSNs, card numbers, SWIFT/IBAN, or a matched sensitivity label) and act —
   audit, warn, or block — as users share it across Exchange, SharePoint, OneDrive, Teams, and managed
   endpoints. Microsoft ships **U.S. Gramm-Leach-Bliley Act (GLBA)** and **U.S. Financial Data**
   policy templates as starting points (verify availability in your tenant).
3. **Data lifecycle & records management** — retention labels and policies that keep books-and-records
   for the required period and control disposition. A retention label can be configured as a
   **regulatory record** and a retention policy can carry a **Preservation Lock** so the configuration
   itself becomes immutable — the mechanism Microsoft positions (per its published Cohasset Associates
   assessment) for **SEC Rule 17a-4(f)**, **FINRA Rule 4511(c)**, and **CFTC Rule 1.31(c)–(d)**
   electronic-records requirements. *Whether a given record must be preserved this way is a
   records/legal determination.*
4. **Communication compliance** — supervisory review of employee communications for regulatory risk.
   Purview ships financial-services templates (for example **Monitor for regulatory compliance**,
   **Monitor for money laundering**, **Monitor for stock manipulation**, **Monitor for gifts and
   entertainment**), supporting a firm's **FINRA Rule 3110** supervision program. *The
   supervision scheme, lexicons, and any case outcome are compliance/legal determinations.*

## How it works
1. You agree a small **FS label taxonomy** with the data owners and publish it to a pilot group with a
   label policy; auto-labeling can apply the NPI label automatically by content match — first in
   **simulation**.
2. DLP policies reference financial sensitive-information types and/or the FS labels. Each policy is
   deployed in **test/audit** mode first; you review the matches (the **DLP audit gate**), tune out
   false positives, and only then enforce.
3. **Retention labels and policies** set how long communications and books-and-records live and what
   happens at end-of-life (retain, delete, or declare a **regulatory record** with disposition
   review). **Preservation Lock** is applied only after the records/legal owner confirms the schedule.
4. A **communication compliance** policy is stood up in a limited pilot for supervisory review, with
   strict **role separation** (admin vs. analyst vs. investigator) and privacy-by-design.
5. Every action is logged in the Purview **audit** and **Activity explorer**, so classification, DLP,
   records, and supervision coverage is reportable and defensible.

## What you can control
- The FS label taxonomy, order/priority, and each label's protection (encryption, marking, sharing
  limits for NPI and MNPI).
- Where labels publish and whether auto-labeling applies the NPI label by content match.
- DLP scope (Exchange, SharePoint, OneDrive, Teams, endpoints), the financial sensitive-info types or
  labels a policy matches, and the action (audit, notify, block).
- Retention duration, trigger, end-of-life action, **regulatory-record** declaration, disposition
  review, and **Preservation Lock**.
- The communication-compliance policy scope, conditions/templates, and reviewer role separation.

## Benefits
- **Protection that travels** — a sensitivity label encrypts and marks NPI/MNPI so it stays protected
  outside the firm.
- **Fewer leaks, fewer false positives** — DLP tuned in audit before enforcement blocks real customer-
  data leakage without blocking legitimate work.
- **Defensible books-and-records** — communications and records kept and disposed on a defined
  schedule, with an immutability mechanism aligned to SEC/FINRA/CFTC electronic-records rules.
- **Supervisable communications** — a communication-compliance program that supports FINRA 3110
  supervision with privacy-by-design and role separation.
- **Reportable coverage** — classification, DLP, records, and supervision evidence visible per service.

## Limitations (be honest with buyers)
- Auto-labeling at rest, endpoint DLP, records management, communication compliance, and Audit
  (Premium) require the higher Microsoft 365 / Purview plans (E5 or the E5 Compliance add-on) — the
  Requirements Guide names the licensing; **verify your tenant**.
- **Preservation Lock is effectively irreversible** — once applied you cannot make the retention
  policy less restrictive or remove locations. Apply it **only** after the records/legal owner signs
  off the schedule.
- **Regulatory alignment is not automatic.** Configuring Purview does not, by itself, make a firm
  compliant; the determinations (what is a record, how long, what is supervised) are the firm's, and
  Microsoft's 17a-4 positioning rests on a specific configuration described in its Cohasset
  assessment — confirm with your compliance and legal owners.
- Communication compliance is **HR/privacy-sensitive** — pseudonymization and strict role separation
  are required; outcomes are deferred to HR/legal.
- Encryption applied by a label can affect legacy/third-party apps; pilot before broad enforcement.

## The standard deployment model
> **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce).** Labels and
> auto-labeling run in **simulation**, DLP runs in **audit** behind a mandatory audit gate,
> communication compliance runs on a **limited pilot**, and **Preservation Lock** is applied only
> after records/legal sign-off — each stage with explicit pass/fail gates and a documented rollback.
