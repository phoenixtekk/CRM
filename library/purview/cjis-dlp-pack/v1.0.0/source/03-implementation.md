# 3. Implementation Guide — CJIS DLP Pack (Microsoft Purview)

This is the **build** guide: how to stand up CJI Data Loss Prevention across the M365 workloads, pilot it
in **simulation/test**, validate it, and only then enforce. Work **Part A** to assess and design, **Part
B** to configure and pilot, **Part C** to validate and expand. Detection and policy come from the
**Microsoft Purview portal** and **Security & Compliance PowerShell** (`Connect-IPPSSession`); DLP alerts
for evidence come from **Microsoft Graph**. Every config change is run **`-WhatIf` first** and only
committed with `-Commit` under change control. Artifact names follow the
`<Purpose> – <Scope> – <Stage>` convention and are reused verbatim across docs, scripts, and the portal.

> **Model:** Assess → Design (CJI detection) → Configure (in **simulation/test**) → Pilot & tune →
> Validate → Expand (**enforce**). High-impact DLP changes are **always piloted in simulation/test before
> enforcement**; every change is reversible and recorded. Whether data *is* CJI, the CJI retention
> schedule, and the CJIS audit conclusions are **deferred to your CSO/TAC, compliance, and legal**.

## Named artifacts
| Artifact | Name |
|---|---|
| CJI custom sensitive info type | `CJI Sensitive Info Type – CHRI – Custom` |
| CJI keyword dictionary | `CJI Keyword Dictionary – CJIS – Terms` |
| DLP policy (pilot / simulation) | `CJIS CJI Protection – AllWorkloads – Pilot` |
| DLP detection rule | `CJI Detection Rule – Identifiers+CHRI – v1` |
| Policy baseline (drift reference) | `Policy Baseline – CJIS DLP – <date>` |
| Evidence report | `CJI DLP Evidence – CJIS – Report` |
| Workload scope map | `Workload Scope – CJIS DLP – Map` |
| Change record | `Change Record – CJIS DLP – ChangeControl` |
| Pilot ring | `CJIS Pilot Ring – Stage1` |

---
# Part A — Assess & design

## Step 1 — Assess the estate (read-only)
1. Confirm least-privilege DLP administration is in place (Requirement 2.2) and connect:
   `Connect-IPPSSession`.
2. Run `DLPCJIS-Discovery.ps1` to inventory existing DLP policies and rules, the available
   sensitive-information-types, and any CJI-related custom classification already present. It writes the
   policy register and confirms toolchain connectivity.
3. Run `DLPCJIS-Scope-Health.ps1` to produce `Workload Scope – CJIS DLP – Map`: which workloads are
   available, endpoint onboarding status, and which DLP surfaces your licensing unlocks (Requirement 2.1,
   2.5). **Pass:** you have a written inventory of existing DLP, available SITs, and the licensed coverage.
4. Once the current state is agreed as known-good, run `DLPCJIS-Discovery.ps1 -SaveBaseline` to write
   `Policy Baseline – CJIS DLP – <date>` — the reference future drift checks diff against.

## Step 2 — Design the CJI detection (Design)
1. With your CSO/TAC and compliance stakeholders (Requirement 2.6), agree **how CJI is detected** in your
   content (Requirement 2.4). Typical building blocks:
   - A **custom sensitive information type** `CJI Sensitive Info Type – CHRI – Custom` — regex for the
     criminal-justice identifiers in scope (e.g. agency case/incident number formats, III/NCIC reference
     patterns) with **keyword evidence** to raise precision.
   - A **keyword dictionary** `CJI Keyword Dictionary – CJIS – Terms` — CHRI/criminal-justice context
     terms your authority confirms (record type names, disposition terms, source-system labels).
   - **Supporting built-in SITs** (e.g. U.S. SSN, U.S. driver's-license number) used *in combination*
     with the CJI context — not alone — so an SSN in a routine HR file does not match.
   - Where **EDM** is licensed (E5), an **Exact Data Match** schema against a known CJI identifier export
     for high-precision matching of specific records.
2. Author the custom SIT / keyword dictionary in the portal → `Data classification → Classifiers →
   Sensitive info types` (verify path). Set an initial **confidence level** (start Medium) and
   **instance count** (e.g. 1+) for the pilot; these are the primary tuning knobs.
   **Pass:** the CJI classification exists and test-matches sample CJI content but not routine documents.
   *(What identifiers/terms define CJI is your authority's determination; this step implements it.)*

---
# Part B — Configure in simulation & pilot

## Step 3 — Create the DLP policy in simulation/test (Configure)
1. Confirm `DLPCJIS-Set-Policy.ps1` is safe by default: with no `-Commit` it **previews** and writes
   nothing. Preview the intended policy:
   `DLPCJIS-Set-Policy.ps1 -SitName "CJI Sensitive Info Type – CHRI – Custom" -WhatIf`.
2. Create the policy and rule in **test mode** with `-Commit`:
   `DLPCJIS-Set-Policy.ps1 -SitName "CJI Sensitive Info Type – CHRI – Custom" -Mode TestWithNotifications
   -Commit`. This creates:
   - Policy `CJIS CJI Protection – AllWorkloads – Pilot` scoped to Exchange, SharePoint, OneDrive, and
     Teams (and Endpoint where licensed), targeting `CJIS Pilot Ring – Stage1`.
   - Rule `CJI Detection Rule – Identifiers+CHRI – v1` matching the CJI classification, with the intended
     **action staged but not blocking** (test mode surfaces matches and policy tips without enforcing).
   **Pass:** `Get-DlpCompliancePolicy` shows the policy `Mode = TestWithNotifications`; the rule exists.
   **Rollback:** `DLPCJIS-Set-Policy.ps1 -Disable -Commit` sets the policy to `Disable` (no effect on users).
3. Confirm nothing is blocking: in test mode, users are not restricted — the policy only records what it
   *would* have done.

## Step 4 — Pilot & tune (Pilot)
1. Let the policy run in simulation over the agreed pilot period on `CJIS Pilot Ring – Stage1`.
2. Review matches with `DLPCJIS-Report.ps1` — it reads DLP alerts (Graph, Requirement 2.7) and produces
   `CJI DLP Evidence – CJIS – Report`: what matched, on which workload, and the (simulated) action.
3. **Tune** the CJI classification and the rule's confidence/instance thresholds until the match set is
   right — real CJI caught, routine case/admin work not flagged. Each tuning edit is previewed (`-WhatIf`)
   and applied (`-Commit`) and recorded in `Change Record – CJIS DLP – ChangeControl`.
   **Pass:** over a representative pilot window, true CJI is matched and the false-positive rate is
   acceptable to stakeholders. **Fail:** high false-positive rate → tighten the SIT/thresholds and
   re-pilot; do **not** promote to enforce.

---
# Part C — Validate & expand

## Step 5 — Validate against pass/fail gates (Validate)
1. Run `DLPCJIS-Validation.ps1` (read-only). It checks:
   - The policy `CJIS CJI Protection – AllWorkloads – Pilot` exists and is in the expected mode.
   - It is scoped to the intended workloads (Exchange / SharePoint / OneDrive / Teams / Endpoint as
     designed).
   - The rule `CJI Detection Rule – Identifiers+CHRI – v1` is present and references the CJI classification
     with the intended action.
   **Pass:** all gates green and the simulation results were signed off by stakeholders.
   **Fail:** any gate red → fix in test mode and re-validate before enforcing.

## Step 6 — Promote to enforce (Expand)
1. With clean simulation results and change approval (Requirement 2.6, 2.8), preview the promotion:
   `DLPCJIS-Set-Policy.ps1 -PromoteToEnforce -WhatIf`.
2. In the change window, enforce:
   `DLPCJIS-Set-Policy.ps1 -PromoteToEnforce -Commit` — sets the policy `Mode = Enable` so the configured
   action (e.g. block / block-with-override / restrict-external) now applies. The change is stamped into
   `Change Record – CJIS DLP – ChangeControl`.
   **Pass:** `Get-DlpCompliancePolicy` shows `Mode = Enable`; a controlled test triggers the action and an
   alert. **Rollback:** `DLPCJIS-Set-Policy.ps1 -Disable -Commit` (or `-Mode TestWithNotifications -Commit`)
   returns it to non-enforcing immediately.
3. **Expand coverage** as licensing allows — add **Endpoint DLP** (USB/print/cloud-upload restrictions)
   once devices are onboarded and E5 is confirmed, or tighten from allow-with-override to block. Each
   expansion is piloted in simulation on the ring first, validated, then enforced. Re-baseline
   (`DLPCJIS-Discovery.ps1 -SaveBaseline`) after each approved change set.

## Step 7 — Operate the evidence cadence
1. Run `DLPCJIS-Report.ps1` on your evidence cadence to refresh `CJI DLP Evidence – CJIS – Report` — the
   artifact you show an assessor: policy in force, what it detects, matches and admin actions over time.
2. Run `DLPCJIS-Discovery.ps1 -CompareBaseline` periodically to detect **drift** — any unexpected mode
   change (e.g. the CJI policy silently moved to `Disable`) is a change-control event.

---
### Order of operations
`Assess estate + scope/licensing → design CJI detection → create policy in TEST (simulation) → pilot &
tune → validate gates → (approval) promote to ENFORCE → expand coverage → run the evidence cadence — every
change -WhatIf-first, reversible, and recorded; CJIS/records/legal determinations deferred to the owners.`
