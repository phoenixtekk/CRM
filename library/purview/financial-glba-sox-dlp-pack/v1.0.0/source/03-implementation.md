# 3. Implementation Guide — Financial (GLBA/SOX) DLP Pack (Microsoft Purview)

This is the exact, ordered procedure to implement GLBA/SOX-aligned DLP for **financial and NPI data**
across **email, cloud, Teams, and endpoint** — every policy built in **SIMULATION** first, tuned, then
enforced in a finance ring, then expanded. Portal paths, cmdlets, SIT names, and template names are from
Microsoft's public documentation; **licensing-/plan-dependent features, evolving portal paths, and
template names are flagged "verify your licensing/tenant"** and are never asserted for your tenant. Do the
phases in order. Each phase names its artifacts (from the Overview naming table), states a **pass/fail
gate**, and gives a **rollback**.

> **Automation.** The five delivered PowerShell tools run through **Security & Compliance PowerShell**
> (`Connect-IPPSSession`) and **Microsoft Graph**. They are **read-only or `-WhatIf` by default**; writes
> require an explicit `-Commit` switch and never leave a policy in enforce. No credentials are stored in
> code.

> **Determinations deferred.** *Which* data is NPI under GLBA, *which* records fall in SOX scope, *which*
> classifiers legally apply, the *enforced action* per category, and any *retention* obligation are
> **compliance/records/privacy/legal** decisions. This guide configures and proves the control; capture
> those decisions before Phase 4.

---

## Phase 0 — Connect and baseline (Assess)

1. **Connect the toolchain** (GR-#3). On the admin workstation:
   ```powershell
   Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force   # provides Connect-IPPSSession
   Connect-IPPSSession -UserPrincipalName admin@contoso.com            # Security & Compliance PowerShell
   Connect-MgGraph -Scopes 'Organization.Read.All','InformationProtectionPolicy.Read' -NoWelcome
   ```
2. **Run the posture assessment** (delivered script #1, read-only):
   ```powershell
   .\DLPFIN-Discovery.ps1 -CsvPath .\DLPFIN-Posture.csv
   ```
   It reports existing DLP policies and their mode, built-in **financial-SIT** coverage vs custom SITs,
   any EDM schemas, and licensing/endpoint readiness signals.
3. **Confirm licensing and endpoint readiness** (Req 2.1, 2.3): confirm E5/E5-Compliance where endpoint,
   EDM, fingerprinting, or trainable classifiers are needed, and that finance devices are **onboarded**
   (the health check in script #5 reports the endpoint signal).

**Pass/fail gate:** you have a written baseline (existing policies + modes), a financial-SIT coverage map,
and confirmed licensing + endpoint onboarding for the locations you will target.
**Rollback:** none (read-only).

---

## Phase 1 — Design the financial classification layer (SITs, EDM, fingerprints, classifiers)

Decide, per in-scope financial/NPI category, which detector applies. Do **not** invent SITs — use built-in
where they fit; build custom/EDM/fingerprint/trainable only for gaps.

4. **Map built-in financial SITs first.** In **Purview portal → Data classification → Classifiers →
   Sensitive info types**, confirm the built-in SITs for your categories — e.g. *Credit Card Number*,
   *ABA Routing Number*, *U.S. Bank Account Number*, *International Banking Account Number (IBAN)*,
   *SWIFT Code*, *U.S. Social Security Number (SSN)*, *U.S. Individual Taxpayer Identification Number
   (ITIN)*. Note each SIT's **confidence levels** and default **instance count**. Review the built-in
   **U.S. Gramm-Leach-Bliley Act (GLBA)** and **U.S. Financial Data** DLP **templates** to see the SIT
   bundles Microsoft groups for financial data (*verify the exact template names/membership in your
   tenant — templates evolve*).
5. **Author custom SITs for internal financial identifiers.** For categories with no built-in match:
   - `Account Number – Custom SIT – Financial` — internal customer/account number format (regex primary
     pattern + supporting keywords like *account*, *acct #* + confidence + character proximity).
   - `GL Account Code – Custom SIT – Financial` — general-ledger / cost-center code format.
   Portal: **Classifiers → Sensitive info types → Create sensitive info type**. Test each against sample
   text in the wizard's **Test** step. *Note: over-broad numeric patterns are the top false-positive
   source — require keywords/proximity.*
6. **Configure EDM for customer records where near-zero false positives are required** (Req 2.5). Define
   the schema `Customer NPI – EDM – Financial`, hash-and-upload the source table with the **EDM Upload
   Agent**, and set a **refresh cadence**. Portal: **Data classification → Exact data matches**. *Which
   fields are in scope is the data owner's determination.*
7. **Fingerprint financial-statement templates for SOX** (Req 2.5, plan-gated). Create
   `Financial Statement – Fingerprint – SOX` from your standard statement/reporting template(s) via
   **Document fingerprinting** so drafts based on those templates are detectable. Verify document
   fingerprinting is available in your plan.
8. **Add trainable classifiers where a category is conceptual, not pattern-based** (e.g. financial
   statements, MNPI-style content) — use a built-in trainable classifier or train a custom one on sample
   content. **Verify availability against your plan** before relying on it.

**Pass/fail gate:** every in-scope financial/NPI category maps to a named, tested SIT/EDM/fingerprint/
classifier at a chosen confidence and instance count.
**Rollback:** delete unused custom SITs/EDM schemas/fingerprints (they have no effect until referenced by
a policy).

---

## Phase 2 — Build the DLP policies in SIMULATION (Configure — no user impact)

Create **one policy per location group plus a SOX financial-records policy**, each in **simulation mode**.
Simulation evaluates against real traffic and records what *would* match, with **no** enforcement and
(optionally) with policy tips shown.

9. **Email NPI DLP policy — `DLP – Email NPI – Simulation`.**
   Portal: **Data loss prevention → Policies → Create policy** → the **GLBA / U.S. Financial Data**
   template or custom → **Locations: Exchange email only** → rule: condition *Content contains* the
   financial/NPI SITs from Phase 1 at the chosen confidence/instance count → action *Restrict access or
   encrypt* (kept inert by simulation) → **Policy mode: Run the policy in simulation mode** (optionally
   *with policy tips*). Finish.
10. **Cloud NPI DLP policy — `DLP – SPO+OneDrive+Teams NPI – Simulation`.**
    Same flow → **Locations: SharePoint sites, OneDrive accounts, Teams chat and channel messages** →
    conditions as above → action *Restrict access* (block external sharing on match) → **simulation mode**.
11. **Endpoint NPI DLP policy — `DLP – Endpoint NPI – Simulation`** (requires onboarded devices +
    licensing). Same flow → **Locations: Devices** → conditions as above → **endpoint activities to
    audit/restrict**: *copy to USB/removable media*, *copy to network share*, *print*, *upload to
    unallowed cloud apps/browser*, *copy to clipboard*, *paste to browser* → **simulation mode**. Confirm
    the Devices location is selectable (if not, revisit licensing/onboarding — Req 2.1/2.3).
12. **SOX financial-records DLP policy — `DLP – SOX Financial Records – Simulation`.**
    Same flow → **Locations: Exchange + SharePoint + OneDrive + Teams** → conditions: *Content contains*
    the `GL Account Code – Custom SIT – Financial`, the `Financial Statement – Fingerprint – SOX`, and/or
    the financial-statements trainable classifier → action *Restrict access* → **simulation mode**. This
    policy targets financial-reporting content/MNPI rather than customer NPI.
13. **Set the user experience** consistently: define `DLP Notice – GLBA NPI – AllPolicies` policy-tip text
    (business language: *this content appears to contain protected financial/customer information*) and
    enable **allow override with justification** where compliance permits — tips/overrides only *appear*
    once a policy is enforced; in simulation they are captured, not shown unless "simulation with policy
    tips" is selected.
14. **Verify with the config helper** (delivered script #2, `-WhatIf` by default):
    ```powershell
    .\DLPFIN-Config.ps1 -PolicyName 'DLP - Email NPI - Simulation' `
        -Locations Exchange -SensitiveTypes 'Credit Card Number','ABA Routing Number','U.S. Bank Account Number' `
        -MinCount 10 -Confidence High -WhatIf
    ```
    Run with `-Commit` only to apply an intended change; the script never leaves a policy in enforce mode.

**Pass/fail gate:** all four policies exist and are confirmed in **simulation** (script #1/#2 report
`Mode = TestWithNotifications / TestWithoutNotifications`), scoped to the correct locations and financial
SITs.
**Rollback:** delete the simulation policy — simulation has no user impact, so removal is clean.

---

## Phase 3 — Measure and tune (drive false positives down)

Let each policy run in simulation for the agreed **dwell time** (Req 2.6 — span at least one reporting/
month-end cycle) to capture representative finance traffic.

15. **Review what matched.** **Purview portal → Data loss prevention → Alerts** (simulation alerts) and
    **Data classification → Activity explorer** (filter to DLP activities) show every simulated match with
    the file/message, the SIT, and the confidence. Export with the reporting script:
    ```powershell
    .\DLPFIN-Report.ps1 -Days 30 -CsvPath .\DLPFIN-Matches.csv
    ```
16. **Classify each match** as true positive or **false positive** and identify the false-positive drivers
    (e.g. *ABA Routing Number* firing on internal reference numbers, *Credit Card* firing on GL codes, an
    over-broad `Account Number` custom SIT firing on invoice IDs).
17. **Tune** to reduce false positives without losing true positives:
    - Raise the **confidence level** (e.g. medium → high) so only high-confidence matches count.
    - Raise the **instance count** (e.g. require ≥10 account/card numbers, not 1) for bulk-leak focus.
    - Add **supporting keywords / proximity** to custom SITs so financial context is required.
    - Introduce **EDM** for customer NPI where pattern SITs over-match.
    - Add **exceptions** (e.g. exclude the payments-processor mailbox or the reconciliation site) where
      justified and documented.
18. **Re-simulate** after each tuning change and re-measure. Repeat until the false-positive rate meets the
    validation gate (see Testing).

**Pass/fail gate:** measured false-positive rate is at/under the agreed threshold on the simulation sample,
with true positives still detected.
**Rollback:** revert the last tuning change (script #2 `-WhatIf` shows the diff before `-Commit`).

---

## Phase 4 — Enforce in the finance pilot ring (Pilot)

*Capture the compliance/legal determinations (enforced action per category) before this phase.*

19. **Scope to the finance ring.** Add `DLP Pilot Ring – Finance Stage1` (Finance/Treasury/Accounting
    users) and their pilot devices as the **included** scope on each policy (all other users/devices
    excluded for now). Use the scope helper:
    ```powershell
    .\DLPFIN-Scope.ps1 -PolicyName 'DLP - Email NPI - Simulation' `
        -PilotRingGroup 'DLPFinancePilot@contoso.com' -Location Exchange -Commit
    ```
20. **Move the ring to enforcement.** Change **Policy mode** from *simulation* to **Turn it on / Enforce**.
    Start with **policy tips + allow-override (justification)** rather than hard block, so the finance
    pilot can report false negatives/positives while retaining a business escape hatch for legitimate
    workflows (statements, vendor payments).
21. **Confirm enforcement is live** for the ring only (script #1/#3 report mode `Enable` and the scoped
    identities). Confirm ring users now see the `DLP Notice – GLBA NPI – AllPolicies` tip on a test match.
22. **Handle incidents.** Wire `DLP Alerts – Financial – Operations`: assign the alert owner/queue
    (Req 2.7), set severities, control who may view NPI evidence, and (optionally) forward to SIEM/Sentinel.
    Triage a real simulated/pilot alert end-to-end to prove the workflow.

**Pass/fail gate:** the finance ring is enforced (tips shown, overrides captured), matches raise alerts,
and the triage workflow produces a dispositioned incident. No enforcement outside the ring.
**Rollback:** set the policy back to **simulation mode** (single setting) — instantly removes enforcement
with no data change.

---

## Phase 5 — Expand and harden (Enforce → Operate)

23. **Expand scope** from the finance ring to the full intended population once the pilot gate passes,
    keeping documented exclusions.
24. **Escalate the action** per compliance's determination — e.g. move customer-NPI email from *tip +
    override* to **block/encrypt** where required — one category/location at a time, re-validating after
    each.
25. **Operationalize:** schedule the reporting script for a recurring false-positive/alert review, review
    **user overrides** (are finance users justifying legitimately or bypassing?), refresh **EDM** data on
    cadence, re-fingerprint statement templates when they change, and re-tune as data and behavior drift.
26. **Validate end-to-end** with the delivered testing procedure (next section) and record the pass/fail
    evidence for the GLBA safeguards / SOX control record.

**Pass/fail gate:** enforcement live across the intended scope with the compliance-mandated action per
category; false-positive rate steady/low; alerts triaged on cadence; overrides reviewed; evidence retained.
**Rollback:** any policy can be returned to **simulation** at any time as an immediate, non-destructive
safety switch; individual policies can be disabled without affecting others.

---

## Order-of-operations summary

| Phase | Do | Artifact(s) | Gate | Rollback |
|---|---|---|---|---|
| 0 Assess | Connect, baseline, confirm licensing/onboarding | Posture CSV | Baseline + readiness confirmed | n/a (read-only) |
| 1 Design | Map/build financial SITs, EDM, fingerprints, classifiers | Custom SITs / EDM / fingerprint | Every category → tested detector | Delete unused SIT/EDM/fingerprint |
| 2 Configure | Build 4 policies in **simulation** | Email/Cloud/Endpoint NPI + SOX sim policies | All in simulation, correct scope | Delete sim policy |
| 3 Tune | Measure + reduce false positives | Matches CSV | FP rate ≤ threshold | Revert tuning change |
| 4 Pilot | Enforce to finance ring, wire alerts | Finance ring, alert triage | Ring enforced, incident dispositioned | Back to simulation |
| 5 Expand | Broaden scope, escalate to block, operate | Enforced policies | Full-scope enforce, low FP, alerts triaged | Simulation / disable |
