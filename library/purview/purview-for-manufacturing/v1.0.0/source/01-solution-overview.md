# 1. Solution Overview — Microsoft Purview for Manufacturing

## What this delivers
This solution stands up a **Manufacturing-tailored Microsoft Purview program** — sensitivity labels,
Data Loss Prevention (DLP), retention/records, and compliance posture — aligned to the two data
obligations that define the sector: **protecting intellectual property (IP)** (CAD/CAM designs,
process specs, formulas, bills of material, firmware/source) and **safeguarding Controlled
Unclassified Information (CUI)** for defense-supply-chain work under **CMMC / NIST SP 800-171**
(including export-controlled technical data — **ITAR / EAR**). It is delivered end to end in
Microsoft Purview: designed, configured, **piloted in simulation/test**, validated against pass/fail
gates, then expanded to enforcement.

## Why Manufacturing is different
- **IP is the crown jewel.** Designs, tooling, process know-how, and firmware are the business — a
  leaked drawing or BOM is a competitive and contractual loss, not just a compliance ticket.
- **CUI / CMMC obligations.** Manufacturers in the defense industrial base (DIB) must protect CUI to
  **NIST SP 800-171** and evidence it for **CMMC** assessment; several 800-171 controls map directly
  to Purview (media protection, access control, audit, and — with Microsoft's guidance — CUI
  labelling and DLP).
- **Export control.** Technical data under **ITAR / EAR** must not reach unauthorized (often foreign)
  persons — a DLP and labelling concern with legal weight.
- **Heavy external sharing.** OEMs, suppliers, and contract manufacturers exchange drawings and specs
  constantly; protection must travel with the file, not stop at the tenant boundary.

## How it works in Purview
1. A small, Manufacturing-specific **sensitivity-label taxonomy** (Public → Internal →
   Confidential-IP → CUI, with an export-controlled variant) is published so labels appear in Office,
   Outlook, and the web and **travel with the file** (encryption + visual marking).
2. **Auto-labeling and custom classifiers** help identify IP and CUI at scale (a custom
   sensitive-information type for drawing/part numbers; the CUI trainable classifier where licensed),
   run first in **simulation**.
3. **DLP policies** detect CUI, export-controlled data, and IP markers across Exchange, SharePoint,
   OneDrive, Teams, and managed endpoints — deployed **audit-first**, tuned, then enforced.
4. **Retention & records** keep quality, contract, and CUI records for the required period and dispose
   of them defensibly; **records management** makes regulatory records immutable with disposition
   review.
5. **Compliance Manager** tracks the **CMMC / NIST 800-171** improvement actions so the program is
   evidenced, not just configured.

## What you can control
- The label taxonomy, label order/priority, and the protection each label applies (encryption,
  marking, sharing restrictions) — tuned for IP and CUI.
- Where labels publish and whether **auto-labeling / trainable classifiers** apply them by content.
- DLP scope (Exchange, SharePoint, OneDrive, Teams, endpoint devices), the sensitive-information
  types / labels a policy matches (CUI, ITAR/EAR, IP part-number patterns), and the action
  (audit → notify → block).
- Retention duration, trigger, and end-of-life action (delete, retain, or declare a record), plus
  disposition review for records.

## Benefits
- **IP that travels protected** — a label encrypts and marks a drawing or spec so it stays protected
  when shared to a supplier or OEM.
- **CUI safeguarded and evidenced** — DLP + labels + audit map to NIST 800-171 / CMMC and produce the
  evidence an assessor expects.
- **Fewer leaks, fewer false positives** — DLP tuned in audit before it blocks real risk without
  blocking legitimate manufacturing work.
- **Defensible retention** — quality and contract records kept and disposed on a defined schedule.

## Limitations (be honest with buyers)
- Auto-labeling at rest, endpoint DLP, trainable classifiers, and advanced records require the higher
  **Microsoft 365 E5 / E5 Compliance** plans; the Requirements Guide names the licensing — **verify
  your licensing/tenant**.
- **CMMC / CUI applicability, the export-control determination (ITAR/EAR), retention schedules, and
  records file plans are legal/compliance determinations** — this solution provides the technical
  method and evidence, **not** the determination; those are deferred to your compliance, records,
  privacy, legal, and export-control functions.
- Purview protects data **in Microsoft 365**; OT/shop-floor systems, PLM/PDM, and CAD file shares
  outside M365 are out of scope unless their data lands in M365 workloads.
- Encryption applied by a label can affect legacy CAD/engineering apps that do not understand the
  protection — **pilot before broad enforcement**.

## The standard deployment model
> **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce)**, with a **DLP
> audit gate** before any policy enforces, simulation for auto-labeling, and a documented rollback.
