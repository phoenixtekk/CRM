# 8. Deliverables Summary — HP Workforce Experience Platform (WXP) Integration with Intune

Everything included in this solution package, and what each piece is for.

## Documentation (this guide)
- **Executive Summary** — the business case and outcome in one page, and the explicit scope: the
  **integration method** (deploy the WXP agent via Intune + connect WXP to the Entra/Intune tenant), not
  the WXP subscription, and a complement to — not a replacement for — Microsoft Endpoint Analytics.
- **Solution Overview** — what HP WXP is and its lineage (formerly **HP TechPulse / Proactive Insights /
  Adaptive Endpoint Management**), the **two halves** of the integration (agent-via-Intune and the
  Entra tenant connector), what WXP uniquely monitors (hardware/DEX/sustainability), and how it
  complements Endpoint Analytics and generic DEX monitoring (cross-referenced, not rebuilt).
- **Requirements Guide** — every prerequisite with how to **verify** and how to **implement if missing**
  — the HP WXP subscription and console access, the agent installer + enrollment code, Win32 packaging
  tooling, the detection value, the Global-Admin consent, the connector service principal, network
  access, and the pilot group — plus the category-level Global Requirements.
- **Implementation Guide** — exact, ordered, click-by-click steps across four phases: assess and gather
  WXP tenant details, package the agent as the named Intune Win32 app (`HP WXP Agent - Pilot`) with the
  enrollment code and detection rule, connect WXP to the tenant via admin consent, then pilot, validate,
  and expand.
- **Testing & Validation** — eight tests with explicit pass/fail gates (including detection-stability,
  "device actually reports into WXP," connector-consented, and a negative test that Endpoint Analytics
  is unaffected) and an acceptance gate.
- **Troubleshooting** — top-down diagnosis for agent-install failures, reinstall loops, "installed but
  not reporting," connector/consent problems, and network/endpoint issues.
- **Best Practices** — packaging the agent the Intune way, keeping HP-renamed console values verified,
  establishing the connector cleanly, reversible pilot-first rollout, and positioning WXP alongside
  Microsoft-native monitoring.

## PowerShell scripts (Microsoft Graph) — `HPWXP-Scripts.zip`
All scripts are tenant-side (run from an admin workstation with the Microsoft Graph PowerShell SDK);
each has a header explaining **Purpose · How to run · Expected results**. Discovery, Validation, and
Report are **read-only**; Remediation and Set-ScopeTargeting **default to `-WhatIf`** (preview first,
then apply). HP-renamed names are **parameterized** (`-AppName`, `-ConnectorAppName`) so you match your
tenant.

1. **`HPWXP-Discovery.ps1`** — integration readiness: the HP WXP agent Win32 app is present and
   assigned, and the HP WXP tenant-connector service principal is present (name varies —
   `-ConnectorAppName`).
2. **`HPWXP-Validation.ps1`** — validates the agent app's **assignment** and per-device **install** state
   (Installed / Failed / Pending), with a clear PASS/FAIL summary.
3. **`HPWXP-Report.ps1`** — tenant-wide CSV report of Windows devices and whether the HP WXP agent is
   installed — the agent-coverage report.
4. **`HPWXP-Remediation.ps1`** — safe remediation of a missing/mis-scoped agent **assignment** (adds the
   Required assignment, preserving existing ones) and reports connector-consent status.
   **`-WhatIf` by default**; applies only when re-run to commit.
5. **`HPWXP-Set-ScopeTargeting.ps1`** — sets/adjusts the agent app's group assignment (include/exclude;
   replace or `-Add`) — the target-group builder. **`-WhatIf` by default.**

## Hero image
- **`HPWXP-hero.png`** — the product image used on the marketplace listing.

## How it's delivered
A **Word** document and **PDF** (cover, table of contents, page numbers, and a scripts appendix), plus
all five PowerShell scripts in a single **ZIP** — yours to keep and reuse across **unlimited devices**.

> **Note on scope:** an **HP WXP subscription/licensing is a prerequisite you supply** (edition and
> entitlements — verify with HP). Console menu names, the agent installer filename, the enrollment-code
> label, the connector app display name, Graph scopes, and WXP network endpoint URLs vary by HP release
> and are flagged **verify in the HP WXP admin console / current HP documentation** throughout.
