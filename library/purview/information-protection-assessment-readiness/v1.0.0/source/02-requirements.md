# 2. Requirements Guide — Information Protection Assessment & Readiness (Microsoft Purview)

Verify **every** requirement before running the assessment. Each entry: **Description · Why required ·
How to verify · How to implement if missing.** Category-wide Purview prerequisites (a tenant with the
required **compliance licensing**, least-privilege **Purview roles**, the **Security & Compliance
PowerShell + Graph** toolchain, **in-scope data sources**, **compliance/records/privacy/legal
stakeholders**, and a **pilot scope + change control**) are in `global-requirements-purview.md` —
confirm those **first**; this guide adds the assessment-specific items and does **not** duplicate the six.

> **Artifact names used throughout (use verbatim):**
> posture discovery output `Information Protection - Estate - Discovery` (CSV);
> gap register `Information Protection - Gaps - Register` (CSV);
> roadmap/scorecard `Information Protection - Roadmap - Scorecard`;
> simulation pilot policy (auto-labeling) `Information Protection - Pilot - Simulation`;
> pilot label policy (optional) `Information Protection - Label Policy - Pilot`;
> pilot scope group `Information Protection - Pilot Users`.

## 2.1 Compliance licensing sufficient to *read* the posture (category G1)
**Description:** A Microsoft 365 tenant where the information-protection controls you want to assess are
**visible**. Manual sensitivity labeling + basic DLP are **E3**-class; **auto-labeling**, **advanced
DLP**, and **DSPM** need **E5 / E5 Compliance** (some DSPM/AI features are in **preview**).
**Why required:** The assessment can only report on controls the tenant can surface; an unlicensed
capability reads as **"not available,"** which is itself a valid finding but must not be mistaken for a gap.
**How to verify:** M365 admin center → subscriptions/add-ons; confirm **Information Protection** and
**DLP** are visible in the Purview portal. Run **`IPASSESS-ScopeHealth.ps1`** — it reports which
capabilities are readable.
**How to implement if missing:** Assess what you can under current licensing; flag licensing-gated
dimensions as **not available — verify your licensing/tenant**; recommend licensing in the roadmap if the
capability is required.

## 2.2 Least-privilege read roles for the assessment (category G2)
**Description:** Read access via the least-privilege Purview roles: **Information Protection Reader** (or
**Information Protection Analyst**) for labels/auto-labeling, **Compliance Data Administrator** or
**Global Reader** for DLP visibility, and — to read label **coverage** in **Content Explorer** — the
**Content Explorer List Viewer / Content Viewer** roles. No enforcement rights are needed to assess.
**Why required:** Purview uses fine-grained role groups; the discovery cmdlets and portal surfaces
return data only with the matching read role.
**How to verify:** Purview portal → **Roles & scopes → Permissions**; confirm membership. Run
**`IPASSESS-ScopeHealth.ps1`** — it fails clearly if the S&C session lacks read access.
**How to implement if missing:** Assign the least-privilege **reader** role groups under change control.
The **Pilot Remediation** step (2.6) additionally needs an **Information Protection Admin** to *create* a
simulation policy — grant that only for the pilot.

## 2.3 Security & Compliance PowerShell + Graph reachable (category G3)
**Description:** A workstation with **ExchangeOnlineManagement** (for `Connect-IPPSSession`) and
**Microsoft Graph PowerShell**, PowerShell 5.1+ or 7+, modern-auth / MFA admin.
**Why required:** Every discovery, validation, and reporting script runs through Security & Compliance
PowerShell (labels/DLP/auto-labeling) and, optionally, Graph (group scope).
**How to verify:** `Connect-IPPSSession` succeeds and `Get-Label` returns without error; `Connect-MgGraph`
succeeds. **`IPASSESS-ScopeHealth.ps1`** confirms both.
**How to implement if missing:** `Install-Module ExchangeOnlineManagement` and `Install-Module
Microsoft.Graph`; confirm modern-auth sign-in before running steps.

## 2.4 In-scope workloads and data sources defined (category G4)
**Description:** The **workloads** the assessment covers — **Exchange, SharePoint, OneDrive, Teams,
Endpoint (Windows/macOS), Defender for Cloud Apps** — and the **data-classification / sensitivity
intent** that "good posture" is measured against.
**Why required:** Posture is measured **per workload**; "coverage" is meaningless without knowing which
workloads are in scope, and gaps are ranked against the intended sensitivity scheme.
**How to verify:** Confirm the in-scope workloads and the classification intent with stakeholders and
record them in the assessment scope.
**How to implement if missing:** Agree the workload scope and the sensitivity intent **before** scoring —
otherwise every workload with no coverage reads as a gap regardless of intent.

## 2.5 A readiness baseline to score against
**Description:** The **baseline** the current posture is compared to — the six dimensions in the Overview
(taxonomy, publishing/coverage, encryption/protection, auto-labeling, DLP coverage/mode, SITs), each with
a target the organization considers "ready." The engagement ships a default baseline; refine it with the
stakeholders.
**Why required:** A gap is the distance between **current** and **target**; without an agreed target the
scorecard is subjective.
**How to verify:** The baseline dimensions and their targets are written down and agreed by
compliance/security stakeholders.
**How to implement if missing:** Use the default baseline shipped in **`IPASSESS-Validation.ps1`** /
**`IPASSESS-Report.ps1`** as a starting point and tune the targets with stakeholders before finalizing.

## 2.6 A pilot scope for the one validated fix (category G6)
**Description:** A **small pilot group/scope** (`Information Protection - Pilot Users`) and a
**change-control** window so the single recommended fix can be validated in **simulation** without
touching production. Auto-labeling simulation applies **nothing**; DLP test mode blocks **nothing**;
label pilots publish to the **pilot group only**.
**Why required:** Even a simulation policy is a created object; the model is **pilot-in-simulation
first**, and creating it should follow change control.
**How to verify:** A named pilot group and an approval window exist; the operator has (temporary)
**Information Protection Admin** for the pilot only.
**How to implement if missing:** Define the pilot group and agree change control before the Pilot
Remediation step; keep the rest of the assessment **read-only**.

## 2.7 Stakeholders for determinations (category G5)
**Description:** Named **compliance, records, privacy, and legal** stakeholders who own the
**determinations** the assessment defers — what data *must* be labeled/encrypted/retained, regulatory
applicability, and whether a recommended fix should ultimately be enforced.
**Why required:** The assessment provides the technical posture and a ranked roadmap; **whether** to act
on a gap (and how far) is a governance decision, not a technical default.
**How to verify:** The owners are identified and will review the gap register and roadmap.
**How to implement if missing:** Identify the owners before delivering the roadmap so recommendations map
to an accountable decision-maker.

---
## Checklist
- [ ] Compliance licensing sufficient to read the posture; gated features flagged (2.1 / G1)
- [ ] Least-privilege **reader** roles assigned; IP Admin only for the pilot (2.2 / G2)
- [ ] `Connect-IPPSSession` + `Connect-MgGraph` succeed on the workstation (2.3 / G3)
- [ ] In-scope workloads + classification intent defined (2.4 / G4)
- [ ] Readiness baseline (six dimensions + targets) agreed (2.5)
- [ ] Pilot group `Information Protection - Pilot Users` + change window for the one fix (2.6 / G6)
- [ ] Compliance/records/privacy/legal stakeholders named for determinations (2.7 / G5)
