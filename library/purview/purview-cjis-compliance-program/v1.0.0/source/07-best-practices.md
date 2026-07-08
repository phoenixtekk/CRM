# 7. Best Practices — A CJIS Program Purview Can Defend

Operating principles for keeping the CJIS-aligned Purview controls accurate, least-privilege, and
audit-ready. Grounded in Microsoft's public guidance, the FBI CJIS Security Policy's intent, and the
**Assess → Design → Configure → Pilot → Validate → Expand** model.

## Configure the technical control; defer the determination
- Purview implements **technical** controls — classification, encryption, DLP, retention, audit. Whether
  a control **satisfies** its CJIS requirement, whether the environment is **authorized**, and what the
  **retention schedule** is, are **CSA / CJIS auditor / records** determinations. Build to their
  interpretation, record it in the control map, and never assert compliance the program can't attest.
- Map by **policy area / control intent**, and **verify area/control numbers against your current CJIS
  Security Policy version** (5.9.x vs 6.0 differ, and 6.0 aligns to NIST 800-53). Don't hard-code a
  control number you can't confirm with your CSO.

## Environment first — commercial cloud is not a shortcut
- CJI belongs only in an **authorized environment** — **GCC High** or **Azure Government** — under the
  Microsoft **CJIS Security Addendum**. Confirm this **before** configuring CJI controls; a perfectly
  configured control in a non-authorized tenant is still non-compliant.
- Capability availability and Compliance Manager assessment templates **differ** across GCC High / Azure
  Government and are **licensing-gated** — verify each control's availability in **your** cloud, not the
  commercial docs.

## Pilot every high-impact control in simulation/test first
- The CJI label, DLP, and retention are high-impact — a mis-scoped CJI DLP rule can block legitimate
  criminal-justice work or leak CJI. **Always** deploy DLP in **test/simulation mode**, keep the label
  **unpublished/pilot-scoped**, and stage retention **before** enforcing.
- Review the DLP **simulation results** with the agency's **security officer** before enforcement — the
  simulation is where over-blocking and false-negatives are caught safely. Enforcement is a separate,
  deliberate, change-controlled step.

## Least privilege and separation of duties
- Separate the **CJI-control configurer**, the **audit-evidence reader**, and any **insider-risk
  reviewer** — CJIS expects least privilege and separation of duties. Use least-privilege Purview role
  groups; reserve Global/Compliance Administrator for where it's genuinely required.
- Where **Insider Risk** is used, keep it **aggregate and de-identified**, under a **separate** role, with
  outcomes **deferred to the agency's HR/legal and CJIS governance** — never expose case detail in the
  CJIS program artifacts.

## Audit is the accountability backbone — protect it
- **Auditing & accountability** is a core CJIS policy area. Keep **unified audit logging on**, license
  **Audit (Premium)** where the required retention exceeds the default window, and confirm the retention
  **duration** with your CSA/records owner (it's a determination, not a default).
- Treat the audit trail and the evidence package as sensitive — they reveal where CJI lives and where the
  gaps are. Secure the storage and distribution of the evidence.

## Make the evidence repeatable
- Auditors want **repeatable evidence**, not ad-hoc screenshots. Produce the `CJIS Evidence – Formal
  Audit – Package` the same way every cycle: per control, the implementing Purview object, its state, and
  the audit reference. Schedule the read-only chain so the package is current when the audit lands.
- Where a **Compliance Manager** CJIS/US-gov assessment template is available in your cloud, align the
  package to it — but the **control-satisfaction determination stays with the CSA/auditor**.

## Respect the licensing and preview reality
- Advanced DLP, auto-labeling, Audit Premium, Insider Risk, and premium assessment templates are **E5 /
  E5 Compliance** (some **preview**) and cloud-specific. Populate a control only where its capability is
  genuinely licensed and available, and **verify the current supported method** — Purview's capabilities
  and the portal evolve, and GCC High / Azure Government lag or differ.

## Keep CJI identifiers with the agency
- The specific **CJI/CHRI identifiers** that drive the label/SITs are **agency data** — defined by the
  agency's records/security owners, not invented by the tool. Mis-defining them either over-blocks
  legitimate work or leaks CJI. Version the classification scheme and review it as the estate changes.
