# 3. Implementation — Security Optimization Assessment: Defender for Office 365

This is the exact, ordered procedure to run the assessment end to end. It is **read-only** throughout — you edit no policy and remove no allow-list entry; the only artifacts you create are an assessor identity, a scope file, and the output report. Follow the steps in order and reuse the exact object names below in later steps, testing, and troubleshooting.

**Naming convention** — every object you create uses `<Purpose> – <Scope> – <Stage>`:
| Object | Name to use |
|---|---|
| Read-only app registration (optional, for unattended Graph reads) | `SOA-MDO-Reader – Tenant – Assess` |
| Scope definition file | `SOAMDO-Scope – Tenant – Assess.json` |
| Output run folder | `SOAMDO-Run – <yyyy-mm-dd> – Assess` |
| Scorecard (CSV) | `SOAMDO-Scorecard – Tenant – Assess.csv` |
| Findings report (HTML) | `SOAMDO-Findings – Tenant – Assess.html` |

## Stage 0 — Confirm scope and baseline (Assess)
1. Agree the **in-scope recipient population** with the owner and record the **expected mailbox count** from an authoritative source (R5).
2. Record the **baseline** — preset **Strict** or **Standard** + Secure Score MDO recommendations, and any org standard (R6). *Verify against current Microsoft guidance at run time.*
3. Create **`SOAMDO-Scope – Tenant – Assess.json`** capturing: scope description, expected mailbox count, chosen preset baseline (Standard/Strict), and run date.

## Stage 1 — Establish read-only access (Assess)
4. In `security.microsoft.com` (or Entra → Roles), confirm the assessor holds **Global Reader** / **Security Reader** / **View-Only Configuration** — enough to read every threat policy, transport rules, and the Tenant Allow/Block List (R3). Grant **no** write role.
5. **(Optional, for unattended Graph reads)** create the **`SOA-MDO-Reader – Tenant – Assess`** app registration with **read-only** Graph permissions (`SecurityEvents.Read.All`, `AdvancedHunting.Read.All`) and admin-consent. Add **no** write permissions.
6. Install/confirm modules (R2): `Install-Module ExchangeOnlineManagement -Scope CurrentUser`. Confirm `Connect-ExchangeOnline` and `Connect-IPPSSession` succeed with the assessor.

## Stage 2 — Validate the read (Pilot the read)
7. Run **`SOAMDO-Validate.ps1`**. It confirms the identity can read (a) an anti-phish, Safe Links, Safe Attachments, anti-spam and anti-malware policy, (b) the **preset** policy rules, (c) **transport rules** and the **Tenant Allow/Block List**, and (d) a Graph advanced-hunting query — and asserts **no write scope/role** is present. Fix any gap before continuing.
8. Confirm the policy counts reported reconcile with **Threat policies** in the portal.

## Stage 3 — Discover every policy and rule (Assess)
9. Create the run folder **`SOAMDO-Run – <yyyy-mm-dd> – Assess`** (R7, restricted).
10. Run **`SOAMDO-Discovery.ps1 -ScopeFile "SOAMDO-Scope – Tenant – Assess.json" -OutputDir "SOAMDO-Run – <yyyy-mm-dd> – Assess"`**. It collects, read-only:
    - anti-spam (hosted content filter) policies + rules, and the **outbound** spam policy;
    - anti-malware policies;
    - **anti-phish** policies (impersonation/spoof settings);
    - **Safe Links** and **Safe Attachments** policies + rules;
    - **preset** security policy rules (EOP + ATP protection policy rules) and their state;
    - the **connection filter** (IP allow/block) and **DKIM** config;
    - **transport (mail-flow) rules** and the **Tenant Allow/Block List** (for bypass hygiene);
    - Secure Score MDO recommendations and advanced-hunting `EmailEvents` volume signals.
    All written to the run folder as JSON/CSV. Nothing is changed.

## Stage 4 — Check coverage and bypass hygiene (Assess)
11. Run **`SOAMDO-Coverage.ps1 -InputDir "SOAMDO-Run – <yyyy-mm-dd> – Assess" -ExpectedMailboxCount <n>`**. It computes:
    - **Protection coverage** — which recipients are covered by an anti-phish / Safe Links / Safe Attachments policy, and who is covered by **nothing** or only by a weak/default policy (using policy priority to resolve the **effective** policy);
    - **Preset usage** — whether Standard/Strict presets are enabled and their scope;
    - **Bypass hygiene** — a consolidated list of every override that weakens filtering: Tenant Allow/Block List entries, per-policy allowed senders/domains, **transport rules that set SCL -1 or skip filtering**, connection-filter IP allow lists, and disabled protections.
    Gap and bypass lists are written explicitly.

## Stage 5 — Score against best practice (Assess)
12. Run **`SOAMDO-Assess.ps1 -InputDir "SOAMDO-Run – <yyyy-mm-dd> – Assess" -Baseline "<preset + Secure Score>" -OutputCsv "SOAMDO-Scorecard – Tenant – Assess.csv"`**. It scores each check **Pass / Partial / Fail / N-A**, assigns a **severity** to each non-pass (bypass findings weighted high), rolls up a **weighted posture score (%)**, and writes the scorecard with the baseline stamped in.

## Stage 6 — Generate the findings report (Validate → deliver)
13. Run **`SOAMDO-Report.ps1 -InputDir "SOAMDO-Run – <yyyy-mm-dd> – Assess" -Scorecard "SOAMDO-Scorecard – Tenant – Assess.csv" -OutputHtml "SOAMDO-Findings – Tenant – Assess.html"`**. It produces the **risk-ranked HTML report** (High → Low, each with area, evidence, affected recipients/count, and a remediation pointer) plus a tracking CSV. Bypass findings surface at the top.
14. **Validate the report reconciles** with the portal: spot-check the top findings — e.g. a transport rule the report flags as setting SCL -1 should read that way in **Mail flow → Rules**; a Safe Attachments policy shown as **Monitor** should read Monitor in the portal.

## Stage 7 — Review and hand off (Expand)
15. Walk the security owner through the report, especially the **bypass** findings. **Risk-acceptance and remediation priority are their decisions** — annotate accepted exceptions (e.g. a deliberately allow-listed vendor).
16. Hand the ordered backlog to the paired **Remediation Playbook** (pilot-first) for the fixes. Make no changes from this assessment.
17. **Re-run to trend** — same scope file, new dated run folder — so the posture score and the shrinking bypass list are tracked over time.
