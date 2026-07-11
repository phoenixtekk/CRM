# 3. Implementation — Security Optimization Assessment: Defender for Endpoint

This is the exact, ordered procedure to run the assessment end to end. It is **read-only** throughout — you create no policies and change no configuration; the only artifacts you create are an assessor identity, a scope file, and the output report. Follow the steps in order and reuse the exact object names below in later steps, testing, and troubleshooting.

**Naming convention** — every object you create uses `<Purpose> – <Scope> – <Stage>`:
| Object | Name to use |
|---|---|
| Read-only app registration (optional, for unattended runs) | `SOA-MDE-Reader – Tenant – Assess` |
| Scope definition file | `SOAMDE-Scope – Fleet – Assess.json` |
| Output run folder | `SOAMDE-Run – <yyyy-mm-dd> – Assess` |
| Scorecard (CSV) | `SOAMDE-Scorecard – Fleet – Assess.csv` |
| Findings report (HTML) | `SOAMDE-Findings – Fleet – Assess.html` |

## Stage 0 — Confirm scope and baseline (Assess)
1. Agree the **in-scope device population** with the owner (all endpoints / a business unit / servers vs. workstations) and record the **expected device count** from Intune, AD, or the CMDB (R4).
2. Record the **baseline** you will score against (Microsoft security baseline + Secure Score endpoint recommendations, and any approved org standard) (R6). *Verify it against current Microsoft guidance at run time.*
3. Create the scope file **`SOAMDE-Scope – Fleet – Assess.json`** capturing: scope description, expected device count, platform filter (Windows/macOS/Linux/servers), baseline name, and run date. The scripts read this so every run is comparable.

## Stage 1 — Establish read-only access (Assess)
4. Sign in to `security.microsoft.com` as the assessor. Under **Settings → Microsoft Defender XDR → Permissions and roles** (or **Endpoints → Roles**, depending on whether unified RBAC is enabled — *verify current layout*), confirm the assessor holds **Security Reader** / a read-only role. Do **not** grant any write/manage role for the assessment.
5. **(Optional, for unattended/scheduled runs)** In Entra → **App registrations → New registration**, create **`SOA-MDE-Reader – Tenant – Assess`**. Under **API permissions**, add **application** read-only permissions: Graph `SecurityEvents.Read.All`, `SecurityActions.Read.All`, `DeviceManagementConfiguration.Read.All`, `DeviceManagementManagedDevices.Read.All`, and (WindowsDefenderATP) `Machine.Read.All`, `SecurityRecommendation.Read.All`, `Vulnerability.Read.All`, `AdvancedHunting.Read.All`. Click **Grant admin consent**. Add **no** write permissions. *Verify current permission names.*
6. Open PowerShell 7+ and confirm the modules (R5): `Connect-MgGraph -Scopes "SecurityEvents.Read.All","DeviceManagementConfiguration.Read.All","DeviceManagementManagedDevices.Read.All"`. Consent read-only if prompted.

## Stage 2 — Validate the read (Pilot the read)
7. Run **`SOAMDE-Validate.ps1`**. It confirms the current identity can (a) connect to Graph with read scopes, (b) read the MDE machine list, and (c) run a trivial advanced-hunting query — and it asserts that **no write scope** is present. If any check fails, fix access (R2/R3) before continuing; see Troubleshooting.
8. Confirm the numbers reconcile: the machine count `SOAMDE-Validate.ps1` reports should be in the same ballpark as **Assets → Devices** in the portal. A large mismatch means a scope or permission problem, not a finding — resolve it first.

## Stage 3 — Discover the configuration (Assess)
9. Create the run folder **`SOAMDE-Run – <yyyy-mm-dd> – Assess`** as the output location (R7, restricted).
10. Run **`SOAMDE-Discovery.ps1 -ScopeFile "SOAMDE-Scope – Fleet – Assess.json" -OutputDir "SOAMDE-Run – <yyyy-mm-dd> – Assess"`**. It collects, read-only:
    - device inventory with **onboarding status** and **sensor health** (Active / Inactive / ImpairedCommunication / NoSensorData);
    - **next-gen protection** settings where exposed (real-time / cloud-delivered / PUA), **EDR block mode** state;
    - **ASR rules** state per device/policy (Block / Audit / Warn / Not-configured);
    - **tamper protection** state;
    - **web/network protection** state;
    - the delivery **policies** (Intune endpoint security policies / baselines) touching these settings;
    - **Exposure Score** and endpoint **Secure Score** recommendations.
    Everything is written to the run folder as raw JSON/CSV for the scoring pass. Nothing is changed.

## Stage 4 — Check coverage per area (Assess)
11. Run **`SOAMDE-Coverage.ps1 -InputDir "SOAMDE-Run – <yyyy-mm-dd> – Assess" -ExpectedDeviceCount <n>`**. It computes, per area, the covered-vs-gap picture:
    - **Onboarding coverage** = onboarded & Active ÷ expected count (R4), with the list of missing/inactive devices;
    - **ASR coverage** = rules in **Block** ÷ recommended rule set, per device and overall, calling out rules stuck in **Audit**;
    - **Tamper protection coverage** = devices with tamper protection on ÷ total;
    - **EDR block mode / network protection** coverage.
    Devices and policies with gaps are listed explicitly so remediation has a work list.

## Stage 5 — Score against best practice (Assess)
12. Run **`SOAMDE-Assess.ps1 -InputDir "SOAMDE-Run – <yyyy-mm-dd> – Assess" -Baseline "<baseline name>" -OutputCsv "SOAMDE-Scorecard – Fleet – Assess.csv"`**. It evaluates each check as **Pass / Partial / Fail / N-A**, assigns a **severity** to each non-pass, rolls the areas up into a **weighted posture score (%)**, and writes the scorecard CSV. The baseline name is stamped into the output so the score is defensible.

## Stage 6 — Generate the findings report (Validate → deliver)
13. Run **`SOAMDE-Report.ps1 -InputDir "SOAMDE-Run – <yyyy-mm-dd> – Assess" -Scorecard "SOAMDE-Scorecard – Fleet – Assess.csv" -OutputHtml "SOAMDE-Findings – Fleet – Assess.html"`**. It produces a **risk-ranked HTML report** (findings sorted High → Low, each with area, evidence, affected count, and a remediation pointer) plus a companion CSV for tracking. The exposure drivers from Stage 3 are folded into the ranking.
14. **Validate the report reconciles** with the portal for a spot-check: pick the top-severity finding and confirm it against the relevant portal blade (e.g. an ASR rule shown as "Audit" in the report should read Audit in the endpoint security policy). This is the assessment's own accuracy gate — see Testing.

## Stage 7 — Review and hand off (Expand)
15. Walk the security owner through the report. **Risk-acceptance and remediation priority are their decisions** — annotate accepted exceptions vs. items to fix.
16. Hand the ordered backlog to the paired **Remediation Playbook** (pilot-first, `-WhatIf`-gated) for the fixes. Do **not** make changes from this assessment.
17. **Re-run to trend.** Schedule a periodic re-run (same scope file, new dated run folder) so the posture score is tracked over time and remediation is provably closing gaps.
