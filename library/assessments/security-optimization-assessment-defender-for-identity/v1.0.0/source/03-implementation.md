# 3. Implementation — Security Optimization Assessment: Defender for Identity

This is the exact, ordered procedure to run the assessment end to end. It is **read-only** throughout — you install no sensor, change no DSA, and plant no honeytoken; the only artifacts you create are an assessor identity context, a scope file, and the output report. Follow the steps in order and reuse the exact object names below in later steps, testing, and troubleshooting.

**Naming convention** — every object you create uses `<Purpose> – <Scope> – <Stage>`:
| Object | Name to use |
|---|---|
| Read-only app registration (optional, for unattended Graph reads) | `SOA-MDI-Reader – Tenant – Assess` |
| Scope definition file | `SOAMDI-Scope – Forest – Assess.json` |
| Output run folder | `SOAMDI-Run – <yyyy-mm-dd> – Assess` |
| Scorecard (CSV) | `SOAMDI-Scorecard – Forest – Assess.csv` |
| Findings report (HTML) | `SOAMDI-Findings – Forest – Assess.html` |

## Stage 0 — Confirm scope and baseline (Assess)
1. Agree the **in-scope forest/domains** with the owner and confirm the authoritative list of **domain controllers** and any **AD FS / AD CS / Entra Connect** servers (R5).
2. Record the **baseline** — Microsoft MDI best-practice guidance + identity Secure Score, and any org standard (R6). *Verify against current Microsoft guidance at run time.*
3. Create **`SOAMDI-Scope – Forest – Assess.json`** capturing: scope description, the expected DC/AD FS/AD CS counts, baseline name, and run date.

## Stage 1 — Establish read-only access (Assess)
4. Confirm the assessor holds **Security Reader** / **Global Reader** in Entra, and a read-only Defender role that can view **Settings → Identities** (R4). Grant **no** write role. For AD, use a normal read-only domain account (R2).
5. **(Optional, for unattended Graph reads)** create the **`SOA-MDI-Reader – Tenant – Assess`** app registration with **read-only** Graph permissions (`SecurityEvents.Read.All`, `AdvancedHunting.Read.All`) and admin-consent. Add **no** write permissions.
6. From a domain-joined host, confirm the AD module (R2): `Get-ADDomainController -Filter * | Measure-Object`. Confirm `Connect-MgGraph` with the read scopes succeeds.

## Stage 2 — Validate the read (Pilot the read)
7. Run **`SOAMDI-Validate.ps1`**. It confirms the identity can (a) enumerate DCs via AD read, (b) connect to Graph with read scopes, (c) run an advanced-hunting query (`IdentityInfo | take 1`) — and asserts **no write scope** is present. Fix any gap before continuing.
8. Confirm the DC count from AD reconciles with the AD team's expectation (Stage 0) — a mismatch here is a scope problem to resolve *before* measuring coverage.

## Stage 3 — Discover the configuration (Assess)
9. Create the run folder **`SOAMDI-Run – <yyyy-mm-dd> – Assess`** (R7, restricted).
10. Run **`SOAMDI-Discovery.ps1 -ScopeFile "SOAMDI-Scope – Forest – Assess.json" -OutputDir "SOAMDI-Run – <yyyy-mm-dd> – Assess"`**. It collects, read-only:
    - the **AD inventory** — all domain controllers, and AD FS / AD CS role holders (the coverage denominator);
    - the MDI **sensor** list and health where available (via Graph/portal export; portal-confirmation items flagged **verify**);
    - the **directory-service account (DSA)** signal (present? gMSA? — flagged for portal confirmation where no API);
    - **honeytoken / tagged-entity** state (via advanced hunting + portal confirmation);
    - **ISPM** recommendations (MDI posture assessments + identity Secure Score recommendations);
    - detection **exclusions** where readable, and identity detection activity (`IdentityDirectoryEvents` volume).
    All written to the run folder as JSON/CSV. Nothing is changed.

## Stage 4 — Reconcile sensor coverage (Assess)
11. Run **`SOAMDI-Coverage.ps1 -InputDir "SOAMDI-Run – <yyyy-mm-dd> – Assess"`**. It computes the centerpiece:
    - **DC sensor coverage** = DCs with an installed & healthy sensor ÷ total DCs (from AD), **naming every un-sensored or unhealthy DC** — the critical blind spots;
    - **AD FS / AD CS coverage** = role servers with a sensor ÷ total;
    - a **honeytoken presence** count and a **DSA present/hardened** signal.
    The blind-spot server list is written explicitly for the remediation work list.

## Stage 5 — Score against best practice (Assess)
12. Run **`SOAMDI-Assess.ps1 -InputDir "SOAMDI-Run – <yyyy-mm-dd> – Assess" -Baseline "<MDI guidance + identity Secure Score>" -OutputCsv "SOAMDI-Scorecard – Forest – Assess.csv"`**. It scores each check **Pass / Partial / Fail / N-A**, assigns a **severity** (un-sensored DC = High), rolls up a **weighted posture score (%)**, and writes the scorecard with the baseline stamped in.

## Stage 6 — Generate the findings report (Validate → deliver)
13. Run **`SOAMDI-Report.ps1 -InputDir "SOAMDI-Run – <yyyy-mm-dd> – Assess" -Scorecard "SOAMDI-Scorecard – Forest – Assess.csv" -OutputHtml "SOAMDI-Findings – Forest – Assess.html"`**. It produces the **risk-ranked HTML report** (High → Low, each with area, evidence, affected servers/count, and a remediation pointer) plus a tracking CSV. The un-sensored-DC list surfaces at the top.
14. **Validate the report reconciles** with the portal: spot-check the top findings — e.g. a DC the report flags as un-sensored should not appear (healthy) under **Settings → Identities → Sensors**; a `verify`-flagged DSA item should be confirmed against the portal.

## Stage 7 — Review and hand off (Expand)
15. Walk the security owner through the report, leading with the **un-sensored domain controllers**. **Risk-acceptance and remediation priority are their decisions** — annotate accepted exceptions (e.g. a DC being decommissioned).
16. Hand the ordered backlog to the paired **Remediation Playbook** (pilot-first) for the fixes — install missing sensors, harden the DSA to a gMSA, plant/tag honeytokens, work the ISPM backlog. Make no changes from this assessment.
17. **Re-run to trend** — same scope file, new dated run folder — so coverage climbing toward 100% is provable, especially after new DCs are promoted.
