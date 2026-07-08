# 1. Solution Overview — Microsoft Purview ITAR Compliance Program

## What this delivers
This solution stands up an **ITAR-aligned export-control program in Microsoft Purview**. The
International Traffic in Arms Regulations (**ITAR**, 22 CFR 120–130, administered by the U.S. State
Department's **DDTC**) govern **defense articles and technical data** on the **U.S. Munitions List
(USML)**. The core data-security obligation: **export-controlled technical data must not reach
unauthorized persons** — and under ITAR, granting a **foreign person** access to technical data (even
inside your own tenant) is a **"deemed export."** This program maps that obligation to the Microsoft
Purview controls that **protect and evidence** it — sensitivity labels that encrypt and restrict to
**authorized U.S. persons**, DLP that blocks export-controlled data to unauthorized recipients, retention
for export records, and **Compliance Manager** evidence — configured, **piloted in simulation/test**,
validated, and operable.

## Why ITAR needs Purview
- **Protection must travel with the data.** A USML technical-data document shared to a foreign person is
  an unauthorized export; a **label that encrypts and restricts to authorized U.S. persons** keeps the
  protection with the file, not at the network boundary.
- **Deemed exports are an access problem.** ITAR treats access-by-a-foreign-person as an export —
  access controls, labeling, and DLP recipient conditions are the technical mitigations.
- **Evidence matters.** A voluntary disclosure or an audit expects demonstrable controls and records —
  Purview supplies labels, DLP, audit, and a control-evidence register.
- **Sovereign cloud.** ITAR data generally requires a **U.S. sovereign cloud (GCC High)**; this is a
  licensing/tenant determination the program flags, not a technical default.

## How it works in Purview
1. A **sensitivity label** — `Sensitivity Label - ITAR Technical Data - Authorized US Persons` —
   **encrypts** and restricts technical data to **authorized U.S. persons / named recipients only**, with
   export-control marking.
2. A **custom sensitive-information type** (USML/ITAR markers) and/or the export-control SITs help detect
   technical data at scale, run first in **simulation**.
3. **DLP** detects export-controlled data and **hard-blocks** sends to unauthorized (foreign/unlisted)
   recipients across Exchange, SharePoint, OneDrive, Teams, and managed endpoints — deployed **audit-
   first**, tuned, then enforced.
4. **Retention** keeps **export records** for the required period with defensible disposal.
5. **Compliance Manager** tracks the export-control / NIST SP 800-171 improvement actions so the program
   is **evidenced**, not just configured.

## What you can control
- The label's encryption/permissions (authorized U.S. persons only) and export-control marking.
- Detection (custom USML/ITAR SIT, export-control SITs) and whether auto-labeling applies it.
- DLP scope, the recipient conditions (hard-block to unauthorized/foreign persons), and endpoint actions
  (USB, print, upload).
- Export-record retention duration and disposition.

## Benefits
- **Deemed-export risk reduced** — technical data encrypted and restricted to authorized U.S. persons,
  protection travelling with the file.
- **Unauthorized sends hard-blocked** — DLP prevents export-controlled data reaching unauthorized
  recipients, tuned in audit first.
- **Endpoint leak paths covered** — USB, print, and browser-upload of technical data governed.
- **Audit-ready evidence** — controls mapped and evidenced in Compliance Manager.

## Limitations (be honest with buyers)
- Auto-labeling at rest, endpoint DLP, trainable classifiers, advanced records, and premium Compliance
  Manager assessments require **Microsoft 365 E5 / E5 Compliance**; ITAR data generally requires **GCC
  High** — the Requirements Guide names the licensing/cloud; **verify your licensing/tenant.**
- **ITAR applicability, USML classification (what is a defense article / technical data), U.S.-person
  determination, licensing/agreements (e.g. TAA, DSP-5), and any voluntary-disclosure decision are
  export-control/legal determinations.** This solution provides the technical method and evidence, **not**
  the determination.
- A Compliance Manager template specific to **ITAR** may not exist in your plan/cloud — where absent,
  evidence the controls against **NIST SP 800-171** / a custom assessment and record the mapping;
  **verify your tenant.**
- Purview protects data **in Microsoft 365**; engineering/PLM systems, file shares, and physical media
  outside M365 are out of scope unless their data lands in M365 workloads.

## The standard deployment model
> **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce)**, with a **DLP
> audit gate** before any policy enforces, simulation for auto-labeling, and a documented rollback.
