# 2. Requirements Guide — Microsoft Purview Automation Framework

Verify **every** requirement before deploying anything. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites (tenant/licensing, Purview roles, the S&C PowerShell +
Graph toolchain, in-scope workloads, compliance/records/legal stakeholders, pilot & change control) are in
`global-requirements-purview.md` — this guide adds the automation-specific detail.

> **Licensing/tenant boundary.** The policy types this framework automates are **plan-gated**: advanced DLP
> (fingerprint/EDM/trainable-classifier conditions), auto-labeling, and several retention capabilities
> require **Microsoft 365 E5** or **E5 Compliance**; some features and cmdlet parameters (notably the DLP
> **simulation/mode** values) are **evolving or in preview**. Where this guide flags "verify your licensing/
> tenant," confirm the capability and the exact parameter values in your tenant before relying on them.

## 2.1 Compliance licensing for the policy types you automate
**Description:** The framework deploys **DLP**, **sensitivity-label**, and **retention** policy objects. Baseline DLP/labels/retention exist with E3-class licensing; **advanced DLP conditions, auto-labeling, and some retention features require E5 / E5 Compliance** (GR §1).
**Why:** A config that references an E5-only condition will fail to deploy on an E3 tenant — the capability isn't there, not a script fault.
**Verify:** M365 admin center → `Billing → Licenses`; `OPSAUTO-Health.ps1` reads `subscribedSkus` via Graph and reports whether an E5/E5-Compliance-bearing plan is present, and flags config entries that need it.
**Implement:** Assign/purchase the licensing the config's policies require before deploying those policies; scope the config to what your plan supports.

## 2.2 Purview roles (least-privilege) for each policy type
**Description:** Deploying and reading each object needs the matching role group: **Compliance Administrator** or **Compliance Data Administrator** for DLP and retention; **Information Protection** (Admin) for sensitivity labels and label policies; **View-Only** equivalents for the read-only discovery/validate/report tools. Reserve Global Administrator for exceptional cases only.
**Why:** Purview uses fine-grained role groups; create/update requires the write role, and the read-only tooling should run under a view-only role (GR §2).
**Verify:** Purview portal → `Settings → Roles & scopes / Permissions` — confirm membership. `OPSAUTO-Health.ps1` attempts a benign read of each object type and reports which are permitted.
**Implement:** Assign the least-privilege role group per policy type under change control; run read-only tools (Discovery/Validate/Report) with a view-only account, and Deploy with the write role.

## 2.3 Security & Compliance PowerShell + Graph toolchain
**Description:** A workstation with the `ExchangeOnlineManagement` module (provides `Connect-IPPSSession` for **all** the `*-DlpCompliancePolicy`, `*-Label`, `*-RetentionCompliancePolicy` cmdlets) and `Microsoft.Graph` (for licensing reads), driven by a modern-auth / MFA admin.
**Why:** Every policy object this framework manages is a **Security & Compliance PowerShell** object; Graph is used only for licensing/reporting reads (GR §3).
**Verify:** `Get-Module -ListAvailable ExchangeOnlineManagement, Microsoft.Graph`; `Connect-IPPSSession` and `Connect-MgGraph` succeed. `OPSAUTO-Health.ps1` connects and reports module versions and endpoint reachability.
**Implement:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser`; `Install-Module Microsoft.Graph -Scope CurrentUser`. Keep the module current — the S&C cmdlet surface evolves.

## 2.4 A reviewed desired-state config (`Automation Config – Purview Ops – Baseline`)
**Description:** The JSON config that lists the DLP/label/retention policies the framework manages, each with its managed attributes (name, locations/scope, mode, identifying settings). **Its content — which info types, which durations, which labels — comes from compliance/records/legal**, not from the framework.
**Why:** The framework is only as correct as the config; the config is the reviewable record of the compliance decision (GR §4, §5).
**Verify:** The config validates against the framework's expected shape (`OPSAUTO-Deploy.ps1 -ValidateConfigOnly` parses it and reports structural errors) and every policy's *content* has a named compliance/records/legal owner.
**Implement:** Author the config from the approved policy design; capture the approver per policy. Start with a small, high-confidence subset for the pilot.

## 2.5 In-scope locations/workloads and a classification intent
**Description:** The **workloads/locations** each policy targets (Exchange, SharePoint, OneDrive, Teams, endpoints) and the **classification/sensitivity** intent driving the labels/DLP/retention (GR §4).
**Why:** Every deployed policy keys off its locations and the classification scheme; a mis-scoped policy is a high-impact mistake.
**Verify:** The config's `locations`/`scope` per policy match the agreed in-scope workloads; stakeholders have confirmed the classification approach.
**Implement:** Define scope and classification intent before authoring config; do not deploy tenant-wide locations during pilot.

## 2.6 Compliance, records, privacy & legal ownership of policy content
**Description:** Named owners — from **compliance, records, privacy, security, legal** — for the *content* of each managed policy (retention durations, records intent, DLP sensitive-info-type selection, label taxonomy) (GR §5).
**Why:** These are governance determinations, not technical defaults; the framework configures to them and defers the determination.
**Verify:** Each policy in the config maps to a documented decision and a named approver.
**Implement:** Capture the determinations and approvals before deploying the corresponding policy.

## 2.7 A pilot scope, change control, and understanding of the safe-first modes
**Description:** A bounded **pilot scope** — `Automation Pilot – Ops Scope – Stage1` (a few locations/users/policies) — plus an agreed change window, and a shared understanding that the framework deploys DLP in **test/simulation mode**, labels **unpublished**, and retention **unenforced/pilot-scoped**, and that **enforcement is a separate explicit step** (GR §6).
**Why:** DLP, label, and retention changes are high-impact; every solution follows Assess → Design → Configure → **Pilot (simulate)** → Validate → Expand (enforce).
**Verify:** A named pilot scope and change approval exist; the team agrees nothing enforces without a deliberate `-Enforce -Commit`. **Confirm the DLP test/simulation mode values your tenant accepts** (2.1) — they are evolving.
**Implement:** Define the pilot scope and change window; agree the enforce gate before running any `-Commit`.
