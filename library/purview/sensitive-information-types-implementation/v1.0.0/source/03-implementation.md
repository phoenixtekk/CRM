# 3. Implementation Guide — Sensitive Information Types Implementation (Microsoft Purview)

This is the exact, ordered procedure to **select, test, and tune built-in sensitive information types
(SITs)** so the detection layer is accurate before it drives any policy. All measurement is done in the
portal **Test** experience or in a DLP policy run in **SIMULATION** — this solution introduces **no
enforcement**. Portal paths and cmdlets are from Microsoft's public documentation; **licensing-/plan-
dependent features and evolving portal paths are flagged "verify your licensing/tenant"** and are never
asserted for your tenant. Do the phases in order. Each phase names its artifacts (from the Overview naming
table), states a **pass/fail gate**, and gives a **rollback**.

> **Automation.** The five delivered PowerShell tools run through **Security & Compliance PowerShell**
> (`Connect-IPPSSession`) and **Microsoft Graph**. They are **read-only or `-WhatIf` by default**; the one
> tool that writes (the simulation measurement policy) requires an explicit `-Commit` and creates the
> policy **in simulation mode only — never enforce**. No credentials are stored in code.

> **Determinations deferred.** *Which* data categories are in scope, *which* SITs legally satisfy a
> regulation, and the *acceptable* false-positive threshold are **compliance/privacy/legal** decisions.
> Capture them before Phase 3.

---

## Phase 0 — Connect and baseline (Assess)

1. **Connect the toolchain** (GR-#3). On the admin workstation:
   ```powershell
   Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force   # provides Connect-IPPSSession
   Connect-IPPSSession -UserPrincipalName admin@contoso.com            # Security & Compliance PowerShell
   Connect-MgGraph -Scopes 'InformationProtectionPolicy.Read','Organization.Read.All' -NoWelcome
   ```
2. **Inventory the built-in SIT library** (delivered script #1, read-only):
   ```powershell
   .\CLSSIT-Discovery.ps1 -CsvPath .\CLSSIT-SIT-Inventory.csv
   ```
   It lists the built-in SITs available in your tenant, the **confidence levels** each publishes, and cross-
   references which existing DLP/auto-labeling policies already reference SITs — so you build on what exists.
3. **Confirm licensing and roles** (Req 2.1, 2.2): confirm the compliance plan and that you hold the
   **Content Explorer** viewer roles needed to inspect matched items during tuning.

**Pass/fail gate:** you have a written inventory of the built-in SITs available in your tenant, their
confidence levels, and confirmed Content Explorer access for tuning.
**Rollback:** none (read-only).

---

## Phase 1 — Select the built-in SITs (Design → `SIT Selection Register`)

Map each in-scope data category to the built-in SIT (or minimal set) that detects it. Reuse built-in
wherever it fits; flag only genuine gaps for the custom/EDM/trainable solutions.

4. **List the built-in candidates per category.** In **Purview portal → Data classification → Classifiers →
   Sensitive info types**, find the built-in SITs for each category — e.g. *Credit Card Number*,
   *U.S. Social Security Number (SSN)*, *ABA Routing Number*, *International Banking Account Number (IBAN)*,
   the relevant national-ID and health-identifier SITs. Read each SIT's definition (pattern elements,
   supporting keywords, and its **Low/Medium/High confidence levels**).
5. **Choose one primary SIT per category** (occasionally a small set) and record it in the
   **`SIT Selection Register`**: category → chosen built-in SIT → why → the SITs considered and rejected.
   Prefer the most specific built-in SIT (a country-specific national-ID SIT over a generic number pattern).
6. **Record the target settings** for each in the **`SIT Threshold Register`**: the starting **confidence
   level** (default **High**) and **instance count (min/max)** you will test at. These are the tuning dials,
   set per downstream use.
7. **Flag genuine gaps.** Any category with no fitting built-in SIT (an internal Employee ID; a conceptual
   category like source code) is **out of scope here** — note it for the custom-SIT / EDM / trainable-
   classifier solutions. Do **not** invent a built-in SIT that doesn't exist.

**Pass/fail gate:** every in-scope data category maps to a named built-in SIT with a starting confidence and
instance count recorded, or is explicitly flagged as a gap for another solution.
**Rollback:** none (documentation only — no tenant change yet).

---

## Phase 2 — Test each selected SIT against the corpus (Configure → prove accuracy)

Prove each SIT detects your **positive** samples and rejects your **negative / look-alike** samples, using
clearly-fake data (Req 2.4).

8. **Portal Test experience.** For each selected SIT: **Data classification → Classifiers → Sensitive info
   types → [SIT] → Test**, then upload a sample file from the `SIT Test Corpus – <Category>`. The portal
   reports whether the SIT matched and at **what confidence** — confirm positives match (ideally at High)
   and look-alike negatives do **not**.
9. **Test at scale from PowerShell** (delivered script #2, read-only):
   ```powershell
   .\CLSSIT-Test.ps1 -SensitiveType 'Credit Card Number' -Path .\corpus\payment-card\ -CsvPath .\CLSSIT-TestResults.csv
   ```
   It runs each corpus file through the SIT and reports match/no-match and confidence per file — so you can
   score the whole corpus in one pass. (Uses `Test-DataClassification` where available in your tenant;
   verify the cmdlet is present — the script degrades to guidance if not.)
10. **Score the corpus:** for each SIT, confirm **positives detected** (true-positive coverage) and
    **negatives rejected** (no look-alike matches) at the target confidence. Note any positive that only
    matches below High, or any negative that matches — these drive Phase 3 tuning.

**Pass/fail gate:** each selected SIT detects its positive corpus at the target confidence and rejects its
negative corpus, or the misses/false hits are captured for tuning.
**Rollback:** none (read-only testing).

---

## Phase 3 — Measure against real traffic in SIMULATION (Configure — no user impact)

The corpus proves the SIT in the lab; simulation proves it against production content, where the real
false-positive drivers appear. Capture the false-positive threshold (Req 2.6) before this phase.

11. **Create the measurement policy in simulation** (delivered script #3, `-WhatIf` by default):
    ```powershell
    # Preview:
    .\CLSSIT-BuildSimPolicy.ps1 -PolicyName 'SIT Measure - Payment Card - Simulation' `
        -SensitiveTypes 'Credit Card Number' -MinCount 10 -Confidence High -WhatIf
    # Create it (SIMULATION mode only — never enforce):
    .\CLSSIT-BuildSimPolicy.ps1 -PolicyName 'SIT Measure - Payment Card - Simulation' `
        -SensitiveTypes 'Credit Card Number' -MinCount 10 -Confidence High -Commit
    ```
    Portal equivalent: **Data loss prevention → Policies → Create policy** → custom → **all/needed
    locations** → rule condition *Content contains* the selected SIT at the chosen confidence/instance count
    → **Policy mode: Run the policy in simulation mode**.
12. **Scope the measurement** to `SIT Pilot Ring – Stage1` if you want to limit the sample (delivered script
    #5, `-WhatIf` by default):
    ```powershell
    .\CLSSIT-Set-Scope.ps1 -PolicyName 'SIT Measure - Payment Card - Simulation' -IncludeGroup 'SIT Pilot Ring - Stage1' -WhatIf
    ```
13. **Let it dwell** for the agreed dwell time (Req 2.6) to capture representative traffic. Simulation
    records what *would* have matched with **no** enforcement and **no** user impact.

**Pass/fail gate:** the measurement policy exists and is confirmed in **simulation** (script #1/#3 report a
`Test*` mode), scoped correctly, capturing matches.
**Rollback:** delete the simulation policy — simulation has no user impact, so removal is clean.

---

## Phase 4 — Tune the SIT usage (drive false positives down)

14. **Export and classify the matches** (delivered script #4, read-only):
    ```powershell
    .\CLSSIT-Report.ps1 -Days 14 -CsvPath .\CLSSIT-Matches.csv
    ```
    Cross-reference with **Data classification → Content explorer** (inspect the actual matched items — needs
    the Content Explorer viewer role, Req 2.2) and **Activity explorer**. Classify each match **true
    positive** or **false positive** and identify the driver.
15. **Tune the two dials first** (no SIT copy needed):
    - **Raise the confidence level** (e.g. Medium → High) so only strongly-corroborated matches count.
    - **Raise the instance count** (e.g. require ≥10 matches, not 1) to focus on bulk-leak-shaped events and
      suppress single-hit false positives.
    Update the **`SIT Threshold Register`** and re-measure.
16. **Only if the two dials aren't enough, create an editable copy of the built-in SIT.** Portal:
    **Sensitive info types → [built-in SIT] → Copy**, producing `<Built-in name> – Tuned Copy –
    Classification`; then adjust its **supporting keywords, character proximity, or confidence** to fit your
    data (e.g. require a nearby keyword your internal look-alikes lack). Test the copy against the corpus
    (Phase 2) and point the measurement policy at the copy. *The original built-in SIT is never modified —
    only the copy.*
17. **Re-measure after each change** and repeat until the false-positive rate meets the threshold. Change one
    thing at a time — don't stack changes blind.

**Pass/fail gate:** measured false-positive rate is at/under the agreed threshold on the simulation sample,
with true positives still detected.
**Rollback:** revert the threshold change in the register / delete the tuned copy — the built-in SIT and any
downstream policy are unaffected.

---

## Phase 5 — Validate and hand off to downstream controls (Expand)

18. **Run the full validation** (next section) and record the pass/fail evidence per category: positives
    detected, negatives rejected, false-positive rate ≤ threshold.
19. **Finalize the registers.** Lock the **`SIT Selection Register`** (category → SIT) and **`SIT Threshold
    Register`** (confidence + instance count per SIT) as the authoritative settings.
20. **Hand off to the downstream controls.** DLP, auto-labeling, and retention policies now reference the
    **validated** selection at the **registered** confidence/instance count — so every control inherits the
    same tuned detection. (Standing up those enforcement policies is the DLP / labeling / retention
    solutions' job; this solution delivers the accurate SIT layer they consume.)
21. **Decommission the measurement policy** once the selection is validated — delete the
    `SIT Measure – <Category> – Simulation` policies (they were measurement scaffolding, never enforcement).
    Schedule a periodic re-validation as data and the built-in library evolve.

**Pass/fail gate:** every in-scope category has a validated SIT at a registered confidence/instance count,
evidence captured, and the registers handed to the downstream controls.
**Rollback:** the registers are documentation; downstream policies own their own enforcement rollback. This
solution leaves no enforcement behind.

---

## Order-of-operations summary

| Phase | Do | Artifact(s) | Gate | Rollback |
|---|---|---|---|---|
| 0 Assess | Connect, inventory built-in SITs, confirm roles | SIT inventory CSV | Inventory + Content Explorer access | n/a (read-only) |
| 1 Select | Map category → built-in SIT, set target dials | Selection + Threshold registers | Every category → named SIT or flagged gap | n/a (docs only) |
| 2 Test | Prove SIT vs fake corpus (portal + script) | Test corpus, results CSV | Positives detected, negatives rejected | n/a (read-only) |
| 3 Measure | Build **simulation** policy, dwell | `SIT Measure – … – Simulation` | In simulation, capturing matches | Delete sim policy |
| 4 Tune | Raise confidence/instance; copy SIT if needed | Threshold register / tuned copy | FP rate ≤ threshold | Revert register / delete copy |
| 5 Validate | Validate, finalize registers, hand off | Locked registers + evidence | Validated selection handed off | Downstream owns enforcement |
