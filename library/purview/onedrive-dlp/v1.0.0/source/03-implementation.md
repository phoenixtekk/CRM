# 3. Implementation Guide — OneDrive for Business DLP (Microsoft Purview)

This is the exact, ordered procedure to implement Purview DLP for **OneDrive for Business** — the policy
built in **SIMULATION** first, tuned, then enforced in a pilot ring, then expanded. Portal paths and
cmdlets are from Microsoft's public documentation; **licensing-/plan-dependent features and evolving
portal paths are flagged "verify your licensing/tenant"** and are never asserted for your tenant. Do the
phases in order. Each phase names its artifacts (from the Overview naming table), states a **pass/fail
gate**, and gives a **rollback**.

> **Automation.** The five delivered PowerShell tools run through **Security & Compliance PowerShell**
> (`Connect-IPPSSession`) and **Microsoft Graph**. They are **read-only or `-WhatIf` by default**; writes
> require an explicit `-Commit` switch, and the config helper never leaves a policy in enforce mode. No
> credentials are stored in code.

> **Determinations deferred.** *Which* data categories are in scope, *which* classifiers legally apply,
> and the *enforced action* per category (e.g. remove external access vs. warn-and-override) are
> **compliance/privacy/legal** decisions. This guide configures and proves the control; capture those
> decisions before Phase 4.

---

## Phase 0 — Connect and baseline (Assess)

1. **Connect the toolchain** (GR-#3). On the admin workstation:
   ```powershell
   Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force   # provides Connect-IPPSSession
   Connect-IPPSSession -UserPrincipalName admin@contoso.com            # Security & Compliance PowerShell
   Connect-MgGraph -Scopes 'Organization.Read.All' -NoWelcome         # optional signals
   ```
2. **Run the posture assessment** (delivered script #1, read-only):
   ```powershell
   .\DLPOD-Discovery.ps1 -CsvPath .\DLPOD-Posture.csv
   ```
   It reports existing DLP policies that touch **OneDrive** and their mode, built-in vs. custom SIT
   coverage, and any EDM schemas — so you build on top of what exists rather than duplicating it.
3. **Understand the OneDrive sharing posture** (Req 2.3): run the scope/health helper to see the DLP-side
   OneDrive scope and, where readable, the tenant external-sharing signal:
   ```powershell
   .\DLPOD-Scope.ps1
   ```

**Pass/fail gate:** you have a written baseline (existing OneDrive-touching policies + modes), a SIT
coverage map, and an understanding of the current external-sharing posture.
**Rollback:** none (read-only).

---

## Phase 1 — Design the classification layer (SITs & classifiers)

Decide, per in-scope data category, which detector applies. Do **not** invent SITs — use built-in where
they fit; build custom/EDM/trainable only for gaps.

4. **Map built-in SITs first.** In **Purview portal → Data classification → Classifiers → Sensitive info
   types**, confirm the built-in SITs for your categories (e.g. *Credit Card Number*, *U.S. Social
   Security Number (SSN)*, *ABA Routing Number*, national-ID SITs). Note each SIT's **confidence levels**
   and default **instance count**.
5. **Author custom SITs for gaps.** For a category with no built-in match (e.g. an internal customer
   reference), create `Customer PII – Custom SIT – Classification` with a **regex primary pattern**,
   **supporting keywords**, a **confidence level**, and a **character proximity**. Portal:
   **Classifiers → Sensitive info types → Create sensitive info type**. Test it against sample text in
   the wizard's **Test** step.
6. **Configure EDM only where near-zero false positives are required** (Req 2.5). Define the schema
   (`Customer PII – EDM – Classification`), hash-and-upload the source table with the **EDM Upload
   Agent**, and set a **refresh cadence**. Portal: **Data classification → Exact data matches**. *Which
   fields are in scope is the data owner's determination.*
7. **Add trainable classifiers where a category is conceptual, not pattern-based** (e.g. source code,
   resumes) — use a built-in trainable classifier or train a custom one on sample content. Verify
   availability against your plan.

**Pass/fail gate:** every in-scope data category maps to a named, tested SIT/classifier at a chosen
confidence and instance count.
**Rollback:** delete unused custom SITs/EDM schemas (they have no effect until referenced by a policy).

---

## Phase 2 — Build the OneDrive DLP policy in SIMULATION (Configure — no user impact)

Create the OneDrive policy in **simulation mode**. Simulation evaluates the policy against real OneDrive
content and sharing activity and records what *would* match, with **no** enforcement and (optionally)
with policy tips shown. Build **two rules** (or two policies) so at-rest exposure and risky sharing are
handled distinctly.

8. **At-rest sensitive-content rule — policy `DLP – OneDrive Sensitive – Simulation`.**
   Portal: **Data loss prevention → Policies → Create policy** → custom or a category template →
   **Locations: OneDrive accounts only** → rule: condition *Content contains* the SITs from Phase 1 at
   the chosen **confidence** and **instance count** → action *Restrict access or encrypt the content*
   (kept inert by simulation) → **Policy mode: Run the policy in simulation mode** (optionally *with
   policy tips*). Finish. This surfaces sensitive data stored in OneDrive regardless of sharing.
9. **External-share rule — policy `DLP – OneDrive External Share – Simulation`.**
   Same flow → **Locations: OneDrive accounts** → rule conditions: *Content contains* the SITs **AND**
   *Content is shared from Microsoft 365* → **with people outside my organization** → action *Restrict
   access or encrypt* → set **Restrict access** to *Block only people who were given access to the
   content through the "Anyone with the link" option* (or *block external users*), per compliance's
   determination → **simulation mode**. This targets the high-severity over-share specifically, leaving
   internal collaboration untouched.
10. **Set the user experience** consistently: define `DLP Notice – OneDrive – Standard` policy-tip text
    and enable **allow override with justification** where compliance permits — but note tips/overrides
    only *appear* once a policy is enforced; in simulation they are captured, not shown to end users
    unless "simulation with policy tips" is selected.
11. **Verify/author with the config helper** (delivered script #2, `-WhatIf` by default):
    ```powershell
    .\DLPOD-Config.ps1 -PolicyName 'DLP – OneDrive Sensitive – Simulation' `
        -SensitiveTypes 'Credit Card Number' -MinCount 10 -Confidence High -WhatIf
    # external-share variant:
    .\DLPOD-Config.ps1 -PolicyName 'DLP – OneDrive External Share – Simulation' `
        -SensitiveTypes 'Credit Card Number' -MinCount 1 -Confidence High -ExternalShareOnly -WhatIf
    ```
    Run with `-Commit` only to apply an intended change; the script creates the policy in **simulation**
    and never leaves a policy in enforce mode.

**Pass/fail gate:** both policies exist and are confirmed in **simulation** (script #1/#2 report
`Mode = TestWithNotifications / TestWithoutNotifications`), scoped to **OneDrive accounts** with the
correct SITs and (for the external-share policy) the outside-org sharing condition.
**Rollback:** delete the simulation policy — simulation has no user impact, so removal is clean.

---

## Phase 3 — Measure and tune (drive false positives down)

Let each policy run in simulation for the agreed **dwell time** (Req 2.6) to capture representative
OneDrive content and sharing activity.

12. **Review what matched.** **Purview portal → Data loss prevention → Alerts** (simulation alerts) and
    **Data classification → Activity explorer** (filter to DLP activities, OneDrive workload) show every
    simulated match with the file, the SIT, the confidence, and the sharing state. Export with the
    reporting script:
    ```powershell
    .\DLPOD-Report.ps1 -Days 14 -CsvPath .\DLPOD-Matches.csv
    ```
13. **Classify each match** as true positive or **false positive** and identify the false-positive
    drivers (e.g. a built-in *Credit Card* SIT firing on internal reference numbers).
14. **Tune** to reduce false positives without losing true positives:
    - Raise the **confidence level** (e.g. medium → high) so only high-confidence matches count.
    - Raise the **instance count** for the at-rest rule (e.g. require ≥10 card numbers) for bulk-leak
      focus; keep the external-share rule sensitive (even a single instance shared externally matters).
    - Add **supporting keywords / proximity** to custom SITs so context is required.
    - Introduce **EDM** for categories where pattern SITs over-match.
    - Add **exceptions** (e.g. exclude a specific internal service account/site) where justified.
15. **Re-simulate** after each tuning change and re-measure. Repeat until the false-positive rate meets
    the validation gate (see Testing).

**Pass/fail gate:** measured false-positive rate is at/under the agreed threshold on the simulation
sample, with true positives (including external over-shares) still detected.
**Rollback:** revert the last tuning change (script #2 `-WhatIf` shows the intended change before
`-Commit`).

---

## Phase 4 — Enforce in a pilot ring (Pilot)

16. **Scope to the pilot ring.** Set `DLP OneDrive Pilot Ring – Stage1` as the **included** OneDrive
    scope on each policy (all other accounts excluded for now) using the scope helper:
    ```powershell
    .\DLPOD-Scope.ps1 -PolicyName 'DLP – OneDrive External Share – Simulation' `
        -PilotRingGroup 'DLPOneDrivePilotRing@contoso.com' -Commit
    ```
17. **Move the ring to enforcement.** In the portal, change **Policy mode** from *simulation* to **Turn
    it on / Enforce**. Start with **policy tips + allow-override (justification)** rather than hard
    restrict, so the pilot can report false negatives/positives while retaining a business escape hatch.
18. **Confirm enforcement is live** for the ring only (script #1 reports mode `Enable` and the scoped
    identities). Confirm a ring user sees the `DLP Notice – OneDrive – Standard` tip when they store or
    externally share a test match (use fake test data — see Testing).
19. **Handle incidents.** Wire `DLP Alerts – OneDrive – Triage`: assign the alert owner/queue (Req 2.7),
    set severities, and (optionally) forward to SIEM/Sentinel. Triage a real simulated/pilot alert
    end-to-end to prove the workflow.

**Pass/fail gate:** the pilot ring is enforced (tips shown, overrides captured, external over-shares
restricted), matches raise alerts, and the triage workflow produces a dispositioned incident. No
enforcement outside the ring.
**Rollback:** set the policy back to **simulation mode** (single setting) — instantly removes enforcement
with no data change.

---

## Phase 5 — Expand and harden (Enforce → Operate)

20. **Expand scope** from the ring to the full intended OneDrive population once the pilot gate passes,
    keeping documented exclusions.
21. **Escalate the action** per compliance's determination — e.g. move the external-share rule from *tip
    + override* to **block external access** (remove "anyone" links / external users), one step at a
    time, re-validating after each.
22. **Operationalize:** schedule the reporting script for a recurring false-positive/alert review, review
    **user overrides** (are people justifying legitimately or bypassing?), refresh **EDM** data on
    cadence, and re-tune as content and sharing behavior change. Consider tightening the tenant OneDrive
    external-sharing setting alongside DLP (Req 2.3) as a complementary, change-controlled action.
23. **Validate end-to-end** with the delivered testing procedure (next section) and record the pass/fail
    evidence:
    ```powershell
    .\DLPOD-Validate.ps1 -CsvPath .\DLPOD-Validation.csv
    ```

**Pass/fail gate:** enforcement live across the intended scope with the compliance-mandated action per
category; false-positive rate steady/low; alerts triaged on cadence; overrides reviewed.
**Rollback:** any policy can be returned to **simulation** at any time as an immediate, non-destructive
safety switch; the at-rest and external-share policies can be disabled independently.

---

## Order-of-operations summary

| Phase | Do | Artifact(s) | Gate | Rollback |
|---|---|---|---|---|
| 0 Assess | Connect, baseline, read sharing posture | Posture CSV | Baseline + posture understood | n/a (read-only) |
| 1 Design | Map/build SITs, EDM, classifiers | Custom SIT / EDM schema | Every category → tested detector | Delete unused SIT/EDM |
| 2 Configure | Build at-rest + external-share policies in **simulation** | Two OneDrive sim policies | Both in simulation, correct scope/conditions | Delete sim policy |
| 3 Tune | Measure + reduce false positives | Matches CSV | FP rate ≤ threshold, over-shares still caught | Revert tuning change |
| 4 Pilot | Enforce to ring, wire alerts | Pilot ring, alert triage | Ring enforced, incident dispositioned | Back to simulation |
| 5 Expand | Broaden scope, escalate to block, operate | Enforced policies | Full-scope enforce, low FP, alerts triaged | Simulation / disable |
