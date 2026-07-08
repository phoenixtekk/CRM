# 3. Implementation Guide — HIPAA / PHI DLP Pack (Microsoft Purview)

This is the exact, ordered procedure to implement PHI-focused Purview DLP across **email, cloud, Teams,
and endpoint** — every policy built in **SIMULATION** first, tuned, then enforced in a ring, then
expanded. Portal paths and cmdlets are from Microsoft's public documentation; **licensing-/plan-
dependent features, the evolving SIT library, and portal paths are flagged "verify your
licensing/tenant"** and are never asserted for your tenant. Do the phases in order. Each phase names its
artifacts (from the Overview naming table), states a **pass/fail gate**, and gives a **rollback**.

> **Automation.** The five delivered PowerShell tools run through **Security & Compliance PowerShell**
> (`Connect-IPPSSession`) and **Microsoft Graph**. They are **read-only or `-WhatIf` by default**;
> writes require an explicit `-Commit` switch, and the config helper is **simulation-only** — it never
> creates or leaves a policy in enforce. No credentials are stored in code.

> **Determinations deferred.** *Which* data is PHI, *which* HIPAA identifiers/classifiers legally apply,
> the *enforced action* per category, and whether any event is a **reportable breach** are
> compliance/privacy/legal decisions. This guide configures and proves the control; capture the
> in-scope-PHI and enforced-action decisions before Phase 4.

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
   .\PHIDLP-Discovery.ps1 -CsvPath .\PHIDLP-Posture.csv
   ```
   It reports existing DLP policies and their mode, the presence of the **HIPAA-relevant built-in SITs**
   (SSN, ICD-9-CM, ICD-10-CM, DEA Number), custom-SIT coverage, and licensing/endpoint readiness
   signals.
3. **Confirm licensing and endpoint readiness** (Req 2.1, 2.3): confirm E5/E5-Compliance where endpoint
   or advanced classifiers are needed, and that target clinician/billing devices are **onboarded**
   (script #5 checks this).

**Pass/fail gate:** you have a written baseline (existing policies + modes), a HIPAA-SIT coverage map,
and confirmed licensing + endpoint onboarding for the locations you will target.
**Rollback:** none (read-only).

---

## Phase 1 — Design the PHI classification layer (SITs & classifiers)

Decide, per in-scope PHI category, which detector applies. Do **not** invent SITs — use the built-in
HIPAA-relevant SITs where they fit; build custom/EDM/trainable only for gaps.

4. **Map the built-in HIPAA SITs first.** In **Purview portal → Data classification → Classifiers →
   Sensitive info types**, confirm the built-in SITs the **"U.S. Health Insurance Act (HIPAA)"** DLP
   template uses and related PHI detectors: **U.S. Social Security Number (SSN)**, **International
   Classification of Diseases (ICD-9-CM)**, **International Classification of Diseases (ICD-10-CM)**, and
   **Drug Enforcement Agency (DEA) Number**. Note each SIT's **confidence levels** and default
   **instance count**. *Verify availability in your tenant — the SIT library evolves.*
5. **Author custom SITs for gaps** — most commonly your **medical record number (MRN)**. Create
   `MRN – Custom SIT – PHI` with a **regex primary pattern** for your MRN format, **supporting keywords**
   (e.g. "MRN", "medical record", "patient ID"), a **confidence level**, and a **character proximity**.
   Portal: **Classifiers → Sensitive info types → Create sensitive info type**. Test it against sample
   (fake) text in the wizard's **Test** step.
6. **Configure EDM only where near-zero false positives are required** (Req 2.5). Define the schema
   (`Patient Identifiers – EDM – PHI`), hash-and-upload the roster with the **EDM Upload Agent**, and set
   a **refresh cadence**. Portal: **Data classification → Exact data matches**. *Which fields are in
   scope is the data owner's/Privacy Officer's determination; handle the roster export as PHI.*
7. **Add trainable classifiers where a category is conceptual, not pattern-based** (e.g. a medical/health
   trainable classifier if one is available for your plan) — verify availability against your plan before
   relying on it.

**Pass/fail gate:** every in-scope PHI category maps to a named, tested SIT/classifier at a chosen
confidence and instance count.
**Rollback:** delete unused custom SITs/EDM schemas (they have no effect until referenced by a policy).

---

## Phase 2 — Build the DLP policies in SIMULATION (Configure — no user impact)

Create **one policy per location group**, each in **simulation mode**. Simulation evaluates the policy
against real traffic and records what *would* match, with **no** enforcement and (optionally) with policy
tips shown. You can start from the built-in **"U.S. Health Insurance Act (HIPAA)"** template and adjust,
or build custom policies with the SITs from Phase 1.

8. **Email DLP policy — `DLP – PHI Email – Simulation`.**
   Portal: **Data loss prevention → Policies → Create policy** → **Medical and health records → U.S.
   Health Insurance Act (HIPAA)** template (or custom) → **Locations: Exchange email only** → rule:
   condition *Content contains* the PHI SITs from Phase 1 at the chosen confidence/instance count →
   action *Restrict access or encrypt* (kept inert by simulation; the enforced flavour will **encrypt**
   outbound PHI mail) → **Policy mode: Run the policy in simulation mode** (optionally *with policy
   tips*). Finish.
9. **Cloud DLP policy — `DLP – PHI SPO+OneDrive+Teams – Simulation`.**
   Same flow → **Locations: SharePoint sites, OneDrive accounts, Teams chat and channel messages** →
   conditions as above → action *Restrict access* (block external sharing on match) → **simulation
   mode**.
10. **Endpoint DLP policy — `DLP – PHI Endpoint – Simulation`** (requires onboarded devices + licensing).
    Same flow → **Locations: Devices** → conditions as above → **endpoint activities to audit/restrict**:
    *copy to USB/removable media*, *copy to network share*, *print*, *upload to unallowed cloud
    apps/browser*, *copy to clipboard*, *paste to browser* → **simulation mode**. Confirm the Devices
    location is selectable (if not, revisit licensing/onboarding — Req 2.1/2.3).
11. **Set the user experience** consistently: define `PHI DLP Notice – Standard – AllPolicies` policy-tip
    text (plain clinical/business language — *why* it was flagged and *what to do*) and enable **allow
    override with justification** where compliance permits — but note tips/overrides only *appear* once a
    policy is enforced; in simulation they are captured, not shown to end users unless "simulation with
    policy tips" is selected.
12. **Verify with the config helper** (delivered script #2, `-WhatIf` by default):
    ```powershell
    .\PHIDLP-Config.ps1 -PolicyName 'DLP - PHI Email - Simulation' -Locations Exchange `
        -SensitiveTypes 'U.S. Social Security Number (SSN)','International Classification of Diseases (ICD-10-CM)' `
        -MinCount 1 -Confidence Medium -WhatIf
    ```
    Run with `-Commit` only to apply an intended change; the script creates in **simulation** and never
    leaves a policy in enforce.

**Pass/fail gate:** all three policies exist and are confirmed in **simulation** (scripts #1/#3 report
`Mode = TestWithNotifications / TestWithoutNotifications`), scoped to the correct locations and PHI SITs.
**Rollback:** delete the simulation policy — simulation has no user impact, so removal is clean.

---

## Phase 3 — Measure and tune (drive PHI false positives down)

Let each policy run in simulation for the agreed **dwell time** (Req 2.6) to capture representative
clinical/billing traffic.

13. **Review what matched.** **Purview portal → Data loss prevention → Alerts** (simulation alerts) and
    **Data classification → Activity explorer** (filter to DLP activities) show every simulated match
    with the file/message, the SIT, and the confidence. Export with the reporting script:
    ```powershell
    .\PHIDLP-Report.ps1 -Days 14 -CsvPath .\PHIDLP-Matches.csv
    ```
14. **Classify each match** as true positive or **false positive** and identify the false-positive
    drivers (e.g. an **SSN** SIT firing on a 9-digit account number, or an **ICD** code matching an
    unrelated reference number).
15. **Tune** to reduce false positives without losing true positives — remember **PHI is a
    combination**:
    - Require **co-occurrence** — configure the rule so a match needs *both* an identifier (SSN/MRN) and
      a clinical detector (ICD-9/ICD-10) present, not either alone.
    - Raise the **confidence level** (e.g. medium → high) so only high-confidence matches count.
    - Raise the **instance count** for bulk-leak focus (e.g. a roster export), while keeping a low count
      where a single-record disclosure matters — tune per category with compliance.
    - Add **supporting keywords / proximity** to custom SITs (MRN) so context is required.
    - Introduce **EDM** for categories where pattern SITs over-match your identifiers.
    - Add **exceptions** (e.g. a sanctioned claims-clearinghouse address) where justified.
16. **Re-simulate** after each tuning change and re-measure. Repeat until the false-positive rate meets
    the validation gate (see Testing).

**Pass/fail gate:** measured false-positive rate is at/under the agreed threshold on the simulation
sample, with true PHI positives still detected.
**Rollback:** revert the last tuning change (script #2 `-WhatIf` shows the diff before `-Commit`).

---

## Phase 4 — Enforce in a pilot ring (Pilot)

17. **Scope to the pilot ring.** Add `PHI DLP Pilot Ring – Stage1` (users — e.g. one clinical/billing
    department) and pilot devices as the **included** scope on each policy (all other users/devices
    excluded for now). Use script #5 (`-WhatIf` then `-Commit`) or the portal.
18. **Move the ring to enforcement.** Change **Policy mode** from *simulation* to **Turn it on / Enforce**.
    Start with **policy tips + allow-override (justification)** and **encrypt** (rather than hard block)
    for outbound PHI email, so the pilot can report false negatives/positives while retaining a business
    escape hatch.
19. **Confirm enforcement is live** for the ring only (script #1 reports mode `Enable` and the scoped
    identities). Confirm end users in the ring now see the `PHI DLP Notice – Standard – AllPolicies` tip
    on a test match (use fake PHI — see Testing).
20. **Handle incidents.** Wire `PHI DLP Alerts – Triage – Operations`: assign the alert owner/queue
    (Req 2.7), set severities, wire the **escalation to the Privacy/Security Officer** for possible
    reportable disclosures, and (optionally) forward to SIEM/Sentinel. Triage a real simulated/pilot
    alert end-to-end to prove the workflow.

**Pass/fail gate:** the pilot ring is enforced (tips shown, overrides captured, PHI mail encrypted),
matches raise alerts, and the triage workflow produces a dispositioned incident with a Privacy/Security
escalation path exercised. No enforcement outside the ring.
**Rollback:** set the policy back to **simulation mode** (single setting) — instantly removes
enforcement with no data change.

---

## Phase 5 — Expand and harden (Enforce → Operate)

21. **Expand scope** from the ring to the full intended population once the pilot gate passes, keeping
    documented exclusions.
22. **Escalate the action** per compliance's determination — e.g. move a category from *tip + override /
    encrypt* to **block** where required — one category/location at a time, re-validating after each.
23. **Operationalize:** schedule the reporting script for a recurring false-positive/alert review, review
    **user overrides** (are people justifying legitimate care coordination or bypassing?), refresh
    **EDM** roster data on cadence, and re-tune as clinical/billing behavior changes.
24. **Validate end-to-end** with the delivered testing procedure (next section) and record the pass/fail
    evidence for the HIPAA control record.

**Pass/fail gate:** enforcement live across the intended scope with the compliance-mandated action per
category; false-positive rate steady/low; alerts triaged and escalated on cadence; overrides reviewed.
**Rollback:** any policy can be returned to **simulation** at any time as an immediate, non-destructive
safety switch; individual policies can be disabled without affecting others.

---

## Order-of-operations summary

| Phase | Do | Artifact(s) | Gate | Rollback |
|---|---|---|---|---|
| 0 Assess | Connect, baseline, confirm licensing/onboarding | Posture CSV | Baseline + HIPAA-SIT map + readiness | n/a (read-only) |
| 1 Design | Map HIPAA SITs, build MRN/EDM, classifiers | Custom SIT / EDM schema | Every PHI category → tested detector | Delete unused SIT/EDM |
| 2 Configure | Build 3 policies in **simulation** | Email/Cloud/Endpoint sim policies | All in simulation, correct scope | Delete sim policy |
| 3 Tune | Measure + reduce PHI false positives (co-occurrence) | Matches CSV | FP rate ≤ threshold | Revert tuning change |
| 4 Pilot | Enforce to ring, encrypt PHI mail, wire alerts + escalation | Pilot ring, alert triage | Ring enforced, incident dispositioned | Back to simulation |
| 5 Expand | Broaden scope, escalate to block, operate | Enforced policies | Full-scope enforce, low FP, alerts triaged | Simulation / disable |
