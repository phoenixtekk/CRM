# 2. Requirements Guide — Microsoft Purview CJIS Compliance Program

Verify **every** requirement before building the program. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites (tenant/licensing, Purview roles, the S&C PowerShell
+ Graph toolchain, in-scope workloads, compliance/records/legal stakeholders, pilot & change control)
are in `global-requirements-purview.md` — this guide adds the CJIS-specific detail.

> **Environment/licensing boundary.** CJIS is generally satisfied only in **Microsoft 365 GCC High** or
> **Azure Government** under a signed Microsoft **CJIS Security Addendum**; **commercial M365 is
> generally not CJIS-authorized.** Capability availability and Compliance Manager assessment templates
> differ across these clouds and are **licensing-gated** (E5 / E5 Compliance; Audit Premium; some
> preview). Where this guide flags *"verify your environment/licensing/tenant,"* do so **with your CSA /
> CSO** before relying on a control — the program shows what you have, it never invents a control.

## 2.1 A CJIS-authorized environment and the Microsoft CJIS agreement
**Description:** A tenant in a **CJIS-authorized cloud** — typically **Microsoft 365 GCC High** or
**Azure Government** — covered by the Microsoft **CJIS Security Addendum / agreement** with your state or
the FBI, as coordinated by your **CSA/CSO**.
**Why:** CJI may only be processed in an authorized environment; the technical controls here are
necessary but **not sufficient** without the authorized environment and agreements (Overview boundary).
**Verify:** Confirm the tenant's cloud instance (GCC High / GovCloud) with your Microsoft account
team/CSA; confirm the CJIS Addendum is in place. `CMPCJIS-Discovery.ps1` reports **indicative**
environment/licensing hints but **cannot** attest the CJIS authorization — that is the CSA's.
**Implement:** If not in an authorized environment, **stop** — engage your CSA/CSO and Microsoft before
configuring CJI controls in a non-authorized tenant.

## 2.2 Compliance/data-governance licensing for the CJI controls
**Description:** The controls depend on licensing: **sensitivity labels + encryption** and **retention**
(E3 baseline; auto-labeling/advanced = E5), **DLP** (E3 baseline; advanced classifiers = E5), **Audit
(Premium)** for longer CJI audit retention (E5 / E5 Compliance), **Insider Risk** (E5 / E5 Compliance;
where used), and **Compliance Manager** CJIS/US-gov **assessment templates** (premium; verify GCC High
availability).
**Why:** A control can only be implemented where its capability is licensed and available in your cloud
(GR §1); unlicensed items are flagged *"verify,"* never fabricated.
**Verify:** M365 admin center → `Billing → Licenses`; `CMPCJIS-Discovery.ps1` reads `subscribedSkus` via
Graph and reports which CJI-control capabilities are licensed/reachable.
**Implement:** Assign/purchase the plan (e.g. E5 Compliance for Audit Premium / Insider Risk) before
expecting that control to be available.

## 2.3 Least-privilege Purview roles with separation of duties
**Description:** Least-privilege roles for each function: **Compliance Administrator / Information
Protection** (labels), **Compliance Data Administrator** (DLP/retention), **Records Management**
(records), **Audit** reader roles (audit evidence), and — where used — an **Insider Risk Management**
role held by a **separate** person. Global Administrator only where genuinely required.
**Why:** Purview uses fine-grained role groups and CJIS expects least privilege and separation of duties
(GR §2, §5); the CJI configurer, the audit-evidence reader, and any insider-risk reviewer are
deliberately separated.
**Verify:** Purview portal → `Settings → Roles & scopes / Permissions`; `CMPCJIS-ScopeCheck.ps1` reports
a permission error against any function the account can't perform.
**Implement:** Assign the least-privilege role groups under change control; keep insider-risk and
audit-investigation roles separate from the CJI-control configurer.

## 2.4 The CJI classification scheme and CJI identifiers (from the agency)
**Description:** The agency's definition of **what constitutes CJI/CHRI** in its data estate and how it
should be **classified** — the intent behind the `CJI – Protected – Label` and any **custom Sensitive
Information Types** (specific CJI identifiers — e.g. record numbers, dissemination markings — **come from
the agency**, not invented here).
**Why:** Labels, DLP, and retention key off the classification scheme (GR §4); the specific CJI
identifiers are agency data, and mis-defining them either over-blocks or leaks.
**Verify:** You can state what CJI looks like in your data and the intended label taxonomy; recorded in
the control map. `CMPCJIS-ScopeCheck.ps1` lists existing labels/SITs to build on.
**Implement:** Work with the agency's records/security owners to define CJI and the label/SIT scheme
before configuring policies.

## 2.5 Unified audit logging and an audit-retention target
**Description:** **Unified audit logging enabled** at the source and an agreed **retention target** for
CJI-touching audit activity (**Audit (Premium)** enables longer retention/retention policies for
specific activities).
**Why:** The CJIS **auditing & accountability** policy area needs an audit trail retained for the
required period; Purview audit is the source (GR §3). **The required retention duration is a CJIS/records
determination** — verify against your CJIS Security Policy version.
**Verify:** `CMPCJIS-Discovery.ps1` / `CMPCJIS-ScopeCheck.ps1` report `UnifiedAuditLogIngestionEnabled`
and whether Audit Premium is licensed; confirm the retention target with your CSA/records owner.
**Implement:** Enable unified audit logging under change control; license Audit Premium if the required
retention exceeds the default window.

## 2.6 A CJIS control map owner and the CSA/auditor engagement
**Description:** A named owner for the `CJIS Control Map – Purview – Baseline`, and engagement with the
agency's **CJIS Systems Officer (CSO)**, **CSA**, and **auditor** whose determinations the program must
satisfy (control satisfaction, retention schedule, environment authorization).
**Why:** Purview provides the technical method and evidence; **whether a control satisfies its CJIS
requirement is the CSA/auditor's determination** (GR §5, Overview boundary) — the program must be built
to their interpretation, not a technical default.
**Verify:** The control map has a named owner and the CSA/CSO/auditor are engaged and have reviewed the
mapping approach.
**Implement:** Identify the owner and engage the CJIS governance stakeholders before finalizing the map.

## 2.7 A bounded CJI pilot scope and change control
**Description:** A named **pilot scope** (`CJIS Pilot – CJI Scope – Stage1`) — a limited set of
users/sites/mailboxes containing (or simulating) CJI — to validate the label, DLP (in **test/simulation
mode**), and retention on before any tenant-wide enforcement, plus a **change-control** process.
**Why:** Label, DLP, and retention changes are high-impact; CJIS-scoped changes especially so — every
one is piloted in simulation/test first (GR §6).
**Verify:** A named pilot scope exists, simulation/test mode is confirmed available, and a change
window/approval path is agreed.
**Implement:** Define the pilot scope and change control before configuring or enforcing anything.

## 2.8 An evidence/reporting target for the formal audit
**Description:** Where the `CJIS Evidence – Formal Audit – Package` is produced and stored — the scripts
emit **CSV + HTML** by default (self-contained, no external calls) — and who (auditor/CSA) receives it,
via a **secured** channel appropriate to CJI-adjacent metadata.
**Why:** The deliverable is auditor-facing evidence; a defined, secured output/format is needed, and the
evidence itself (what's protected, where the gaps are) is sensitive.
**Verify:** The output location and secured distribution are agreed; `CMPCJIS-Report.ps1` writes the
package to the target.
**Implement:** Choose the secured output location and distribution before producing the package.
