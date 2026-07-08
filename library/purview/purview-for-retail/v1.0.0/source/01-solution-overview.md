# 1. Solution Overview — Microsoft Purview for Retail

## What this solution is
Retail organizations handle two kinds of data that carry specific obligations: **payment card data**
(cardholder data — primarily the **Primary Account Number / PAN**) governed by **PCI-DSS**, and a
large volume of **customer personal data** (names, contact details, addresses, purchase and loyalty
history) governed by privacy law. This solution configures **Microsoft Purview** — sensitivity
labels, Data Loss Prevention (DLP), retention/records, and a PCI-DSS compliance baseline — into a
**Retail-tailored data-protection program** across Microsoft 365 and managed endpoints.

The retail-specific goal is deliberate and defensible: **keep payment card data out of Microsoft 365
where it does not belong, protect the customer PII that legitimately lives there, and retain both on a
defined schedule** — so a cardholder-data leak or an over-retention finding is prevented and the
program is evidenced against PCI-DSS.

> **The PCI-DSS posture this solution takes (be explicit).** For most retailers, general-productivity
> systems (Exchange, SharePoint, OneDrive, Teams, endpoints) are **out of PCI-DSS scope** and should
> **stay** out of scope — cardholder data belongs in the segmented, PCI-certified payment environment,
> not in email or a SharePoint site. Purview's role here is to **detect and block PAN** from landing
> in these systems (keeping them out of scope) and to **protect and retain** the customer PII that
> legitimately does. **What data is in PCI scope, the applicable PCI-DSS requirements, and the required
> retention periods are compliance/legal determinations** made by the organization's QSA / compliance,
> records, and privacy functions — this solution provides the **technical configuration and evidence**,
> not the determination.

## The Purview capabilities used
1. **Sensitivity labels** — persistent tags for retail data (`Retail Public`, `Retail Internal`,
   `Customer PII - Confidential`, `Cardholder Data - Restricted`) that mark and, where appropriate,
   encrypt content and travel with the file.
2. **Data Loss Prevention (DLP)** — policies built from Microsoft's **PCI Data Security Standard** and
   **PII** templates plus the **Credit Card Number** sensitive-information type, deployed first in
   **test/audit** and tuned before they **block** the movement of PAN and customer PII across Exchange,
   SharePoint, OneDrive, Teams, and endpoints.
3. **Retention & records** — labels and policies that keep transaction and customer records for the
   required period and dispose of them defensibly, and that minimize storage of any cardholder data in
   line with PCI-DSS's data-minimization principle.
4. **Compliance baseline** — a **Microsoft Purview Compliance Manager** assessment using the **PCI-DSS**
   template (licensing-dependent) to track technical controls and produce evidence.

## How it works
1. You agree a small retail label taxonomy with data owners and publish it to a pilot group.
2. Auto-labeling runs in **simulation** to find where cardholder data and customer PII actually live.
3. DLP policies (PCI + PII) run in **test/audit** on the pilot; you review the matches (the **DLP audit
   gate**), tune out false positives, and only then switch to **block**.
4. Retention labels/policies set how long retail records live and enforce data minimization for any
   cardholder data.
5. Compliance Manager tracks the PCI-related technical controls; every action is logged for reporting.

## What you can control
- The retail label taxonomy and the protection each label applies (marking, encryption, sharing limits).
- DLP scope (Exchange, SharePoint, OneDrive, Teams, endpoints), which sensitive-information types and
  labels each policy matches (PAN, PII), and the action (audit → block).
- Retention duration, trigger, and end-of-life action for retail records; records/disposition review.
- Which PCI-DSS controls Compliance Manager tracks and evidences.

## Benefits
- **PCI scope kept small** — DLP blocks PAN from reaching email/collaboration/endpoints, so those
  systems stay out of PCI scope rather than being dragged into it by stray cardholder data.
- **Customer PII protected** — labels and DLP protect the personal data retail legitimately holds,
  reducing breach and privacy exposure.
- **Defensible retention** — retail records are kept and disposed of on a defined schedule; cardholder
  data storage is minimized.
- **Evidenced compliance** — classification, DLP events, and PCI controls are reportable for auditors.

## Limitations (be honest with buyers)
- Auto-labeling at rest, endpoint DLP, and Compliance Manager premium (PCI-DSS) templates require
  **Microsoft 365 E5** or the **E5 Compliance** add-on — the Requirements Guide names the licensing;
  **verify your licensing/tenant**.
- Purview does **not** make Microsoft 365 a PCI-compliant cardholder-data environment. It reduces the
  chance cardholder data lands there; the certified payment environment remains separate.
- DLP detects PAN with high accuracy but not perfectly (Luhn-checked patterns); the audit gate exists
  to tune before enforcing.
- Retention deletion is irreversible once the period elapses; validate on a pilot first.
- Regulatory/PCI/records determinations are made by compliance/QSA/legal, not by this configuration.

## The standard deployment model
> **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce)** — DLP runs in
> audit before it blocks (the DLP audit gate), auto-labeling runs in simulation before it labels, and
> retention is piloted before it deletes, each with explicit pass/fail gates and a documented rollback.
