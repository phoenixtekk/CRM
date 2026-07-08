# 3. Implementation Guide — ITAR DLP Pack (Microsoft Purview)

This is the **build** guide: how to stand up ITAR technical-data Data Loss Prevention across the M365
workloads, pilot it in **simulation/test**, validate it, and only then enforce. Work **Part A** to assess
and design, **Part B** to configure and pilot, **Part C** to validate and expand. Detection and policy
come from the **Microsoft Purview portal** and **Security & Compliance PowerShell**
(`Connect-IPPSSession`); DLP alerts for evidence come from **Microsoft Graph**. Every config change is run
**`-WhatIf` first** and only committed with `-Commit` under change control. Artifact names follow the
`<Purpose> – <Scope> – <Stage>` convention and are reused verbatim across docs, scripts, and the portal.

> **Model:** Assess → Design (technical-data detection) → Configure (in **simulation/test**) → Pilot &
> tune → Validate → Expand (**enforce**). High-impact DLP changes are **always piloted in simulation/test
> before enforcement**; every change is reversible and recorded. Whether data *is* ITAR technical data,
> who is a **foreign person**, the required cloud environment, licensing/authorization, and the
> technical-data retention schedule are **deferred to your Empowered Official, export-compliance, and
> legal** functions.

## Named artifacts
| Artifact | Name |
|---|---|
| Technical-data custom sensitive info type | `Technical Data SIT – Export Markings – Custom` |
| Technical-data keyword dictionary | `Technical Data Dictionary – ITAR Markings – Terms` |
| Export-controlled sensitivity label (optional) | `Export Controlled // ITAR` |
| DLP policy (pilot / simulation) | `ITAR Technical-Data Egress – AllWorkloads – Pilot` |
| DLP detection rule | `Technical-Data Egress Rule – Markings+Label – v1` |
| Policy baseline (drift reference) | `Policy Baseline – ITAR DLP – <date>` |
| Evidence report | `ITAR DLP Evidence – Egress – Report` |
| Workload scope map | `Workload Scope – ITAR DLP – Map` |
| Change record | `Change Record – ITAR DLP – ChangeControl` |
| Pilot ring | `ITAR Pilot Ring – Stage1` |

---
# Part A — Assess & design

## Step 1 — Assess the estate (read-only)
1. Confirm least-privilege DLP administration is in place (Requirement 2.2) and connect:
   `Connect-IPPSSession` (use the `-ConnectionUri` for your cloud — Commercial / GCC High / DoD).
2. Run `DLPITAR-Discovery.ps1` to inventory existing DLP policies and rules, the available
   sensitive-information-types, and any technical-data / export-controlled classification already present.
   It writes the policy register and confirms toolchain connectivity.
3. Run `DLPITAR-Scope-Health.ps1` to produce `Workload Scope – ITAR DLP – Map`: which workloads are
   available, endpoint onboarding status, and which DLP surfaces your licensing unlocks (Requirement 2.1,
   2.5). **Pass:** you have a written inventory of existing DLP, available SITs, and the licensed coverage.
4. Once the current state is agreed as known-good, run `DLPITAR-Discovery.ps1 -SaveBaseline` to write
   `Policy Baseline – ITAR DLP – <date>` — the reference future drift checks diff against.

## Step 2 — Design the technical-data detection (Design)
1. With your Empowered Official / export-compliance stakeholders (Requirement 2.6), agree **how ITAR
   technical data is detected** in your content (Requirement 2.4). Typical building blocks:
   - A **custom sensitive information type** `Technical Data SIT – Export Markings – Custom` — regex for
     the export-control markings and legends in scope (the **Arms Export Control Act / ITAR warning
     legend**, **Distribution Statement B–F** markers, **USML category** references, `22 CFR 120–130`
     citations) plus your program's controlled **drawing-/part-number** formats, with **keyword evidence**
     to raise precision.
   - A **keyword dictionary** `Technical Data Dictionary – ITAR Markings – Terms` — the export-control
     terms your authority confirms (e.g. "Export Controlled", "ITAR Controlled", program/source-system
     labels).
   - An **`Export Controlled // ITAR` sensitivity label** applied to controlled content (manually,
     recommended, or — where licensed — auto-applied). A DLP rule condition **"content has label
     `Export Controlled // ITAR`"** is the most precise and durable signal, because it protects the item
     even after it is copied or renamed. Labeling drives the strongest DLP.
   - Where **EDM** is licensed (E5), an **Exact Data Match** schema against a known controlled-item /
     drawing identifier export for high-precision matching of specific records.
2. Author the custom SIT / keyword dictionary in the portal → `Data classification → Classifiers →
   Sensitive info types` (verify path), and the label in `Information protection → Labels`. Set an initial
   **confidence level** (start Medium) and **instance count** (e.g. 1+) for the pilot; these are the
   primary tuning knobs.
   **Pass:** the technical-data classification exists and test-matches sample marked/labeled technical data
   but not routine documents.
   *(What markings/identifiers define ITAR technical data, and who is a foreign person, are your
   authority's determinations; this step implements the detection.)*

---
# Part B — Configure in simulation & pilot

## Step 3 — Create the DLP policy in simulation/test (Configure)
1. Confirm `DLPITAR-Set-Policy.ps1` is safe by default: with no `-Commit` it **previews** and writes
   nothing. Preview the intended policy:
   `DLPITAR-Set-Policy.ps1 -SitName "Technical Data SIT – Export Markings – Custom" -WhatIf`.
2. Create the policy and rule in **test mode** with `-Commit`:
   `DLPITAR-Set-Policy.ps1 -SitName "Technical Data SIT – Export Markings – Custom" -Mode
   TestWithNotifications -Commit`. This creates:
   - Policy `ITAR Technical-Data Egress – AllWorkloads – Pilot` scoped to Exchange, SharePoint, OneDrive,
     and Teams (and Endpoint where licensed), targeting `ITAR Pilot Ring – Stage1`.
   - Rule `Technical-Data Egress Rule – Markings+Label – v1` matching the technical-data classification
     (SIT and/or the `Export Controlled // ITAR` label), with the intended **egress action staged but not
     blocking** — the ITAR-relevant conditions are **recipient is external** / **content is shared with
     people outside the organization** (test mode surfaces matches and policy tips without enforcing).
   **Pass:** `Get-DlpCompliancePolicy` shows the policy `Mode = TestWithNotifications`; the rule exists.
   **Rollback:** `DLPITAR-Set-Policy.ps1 -Disable -Commit` sets the policy to `Disable` (no effect on users).
3. Confirm nothing is blocking: in test mode, users are not restricted — the policy only records what it
   *would* have done.

## Step 4 — Pilot & tune (Pilot)
1. Let the policy run in simulation over the agreed pilot period on `ITAR Pilot Ring – Stage1`.
2. Review matches with `DLPITAR-Report.ps1` — it reads DLP alerts (Graph, Requirement 2.7) and produces
   `ITAR DLP Evidence – Egress – Report`: what matched, on which workload, the recipient/scope, and the
   (simulated) action.
3. **Tune** the technical-data classification and the rule's confidence/instance thresholds until the
   match set is right — real technical-data egress caught, routine internal engineering work not flagged.
   Each tuning edit is previewed (`-WhatIf`) and applied (`-Commit`) and recorded in
   `Change Record – ITAR DLP – ChangeControl`.
   **Pass:** over a representative pilot window, true controlled-data egress is matched and the
   false-positive rate is acceptable to stakeholders. **Fail:** high false-positive rate → tighten the
   SIT/thresholds, prefer the label condition, and re-pilot; do **not** promote to enforce.

---
# Part C — Validate & expand

## Step 5 — Validate against pass/fail gates (Validate)
1. Run `DLPITAR-Validation.ps1` (read-only). It checks:
   - The policy `ITAR Technical-Data Egress – AllWorkloads – Pilot` exists and is in the expected mode.
   - It is scoped to the intended workloads (Exchange / SharePoint / OneDrive / Teams / Endpoint as
     designed).
   - The rule `Technical-Data Egress Rule – Markings+Label – v1` is present and references the
     technical-data classification with the intended egress action (external send/share restriction).
   **Pass:** all gates green and the simulation results were signed off by stakeholders.
   **Fail:** any gate red → fix in test mode and re-validate before enforcing.

## Step 6 — Promote to enforce (Expand)
1. With clean simulation results and change approval (Requirement 2.6, 2.8), preview the promotion:
   `DLPITAR-Set-Policy.ps1 -PromoteToEnforce -WhatIf`.
2. In the change window, enforce:
   `DLPITAR-Set-Policy.ps1 -PromoteToEnforce -Commit` — sets the policy `Mode = Enable` so the configured
   action (e.g. block external send / restrict external sharing / block-with-override) now applies. The
   change is stamped into `Change Record – ITAR DLP – ChangeControl`.
   **Pass:** `Get-DlpCompliancePolicy` shows `Mode = Enable`; a controlled test triggers the action and an
   alert. **Rollback:** `DLPITAR-Set-Policy.ps1 -Disable -Commit` (or `-Mode TestWithNotifications
   -Commit`) returns it to non-enforcing immediately.
3. **Expand coverage** as licensing allows — add **Endpoint DLP** (USB/print/cloud-upload restrictions on
   labeled/matched technical data) once devices are onboarded and E5 is confirmed, or tighten from
   allow-with-override to block. Each expansion is piloted in simulation on the ring first, validated, then
   enforced. Re-baseline (`DLPITAR-Discovery.ps1 -SaveBaseline`) after each approved change set.
   *(Controlling **internal access by foreign persons** — the deemed-export problem — is an
   access-control / sensitivity-label / Conditional Access design driven by a legal foreign-person
   determination, not a DLP egress rule. Note it as a program dependency and route it to your export
   authority; this pack does not make that determination.)*

## Step 7 — Operate the evidence cadence
1. Run `DLPITAR-Report.ps1` on your evidence cadence to refresh `ITAR DLP Evidence – Egress – Report` —
   the artifact you show a reviewer: policy in force, what it detects, matches and admin actions over time.
2. Run `DLPITAR-Discovery.ps1 -CompareBaseline` periodically to detect **drift** — any unexpected mode
   change (e.g. the ITAR policy silently moved to `Disable`) is a change-control event.

---
### Order of operations
`Assess estate + scope/licensing → design technical-data detection (prefer label) → create policy in TEST
(simulation) → pilot & tune → validate gates → (approval) promote to ENFORCE → expand coverage → run the
evidence cadence — every change -WhatIf-first, reversible, and recorded; ITAR/export/legal determinations
(including foreign-person status and deemed-export access) deferred to the owners.`
