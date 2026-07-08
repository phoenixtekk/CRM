# 3. Implementation Guide — FERPA DLP Pack (Microsoft Purview)

This is the exact, ordered procedure to implement FERPA-aligned education-record DLP across **email, cloud,
Teams, and endpoint** — every policy built in **SIMULATION** first, tuned, then enforced in a ring, then
expanded. Portal paths and cmdlets are from Microsoft's public documentation; **licensing-/plan-dependent
features and evolving portal paths are flagged "verify your licensing/tenant"** and are never asserted for
your tenant. Do the phases in order. Each phase names its artifacts (from the Overview naming table), states
a **pass/fail gate**, and gives a **rollback**.

> **Automation.** The five delivered PowerShell tools run through **Security & Compliance PowerShell**
> (`Connect-IPPSSession`) and **Microsoft Graph**. They are **read-only or `-WhatIf` by default**; writes
> require an explicit `-Commit` switch. No credentials are stored in code.

> **Determinations deferred.** *Which* records are FERPA-protected, **directory vs non-directory** treatment,
> which disclosures are permitted, and the *enforced action* per category are **FERPA-compliance / registrar
> / privacy / legal** decisions. This guide configures and proves the control; capture those decisions
> before Phase 3.

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
   .\DLPFERPA-Discovery.ps1 -CsvPath .\DLPFERPA-Posture.csv
   ```
   It reports existing DLP policies and their mode, built-in vs custom SIT coverage (including whether a
   student-identifier custom SIT already exists), and licensing/endpoint readiness signals.
3. **Confirm licensing and endpoint readiness** (Req 2.1, 2.3): confirm E5/E5-Compliance/A5 where endpoint or
   advanced classifiers are needed, and that target faculty/staff devices are **onboarded**.

**Pass/fail gate:** you have a written baseline (existing policies + modes), a SIT coverage map for education
records, and confirmed licensing + endpoint onboarding for the locations you will target.
**Rollback:** none (read-only).

---

## Phase 1 — Design the classification layer (SITs & classifiers for education records)

Decide, per in-scope record category, which detector applies. Do **not** invent SITs — use built-in where
they fit; build custom/EDM/trainable only for gaps. *Whether a regulatory (e.g. FERPA-labeled) DLP policy
template is available is version-/licensing-dependent — check the template gallery, but do not rely on one
existing.*

4. **Map built-in SITs first.** In **Purview portal → Data classification → Classifiers → Sensitive info
   types**, confirm the built-in SITs for your categories — e.g. *U.S. Social Security Number (SSN)*, *All
   Full Names*, *U.S. Physical Addresses*, *U.S. Bank Account Number* (for financial-aid data). Note each
   SIT's **confidence levels** and default **instance count**.
5. **Author a custom SIT for the student identifier.** Student IDs are institution-specific, so create
   `Student ID – Custom SIT – FERPA` with a **regex primary pattern** matched to your ID format, **supporting
   keywords** (e.g. "student ID", "student number", "SIS ID"), a **confidence level**, and a **character
   proximity**. Portal: **Classifiers → Sensitive info types → Create sensitive info type**. Test it against
   sample text in the wizard's **Test** step with fabricated IDs.
6. **Configure EDM where near-zero false positives are required** (Req 2.5). Define the schema
   (`Student Records – EDM – FERPA`), hash-and-upload the SIS/records export with the **EDM Upload Agent**,
   and set a **refresh cadence** tied to enrollment changes. Portal: **Data classification → Exact data
   matches**. *Which fields are in scope is the registrar/data owner's determination.*
7. **Add trainable classifiers where a category is conceptual, not pattern-based** (e.g. transcripts,
   disciplinary letters) — use a built-in trainable classifier where one fits, or train a custom one on
   sample content. Verify availability against your plan.

**Pass/fail gate:** every in-scope record category maps to a named, tested SIT/classifier at a chosen
confidence and instance count; the student-ID custom SIT matches fabricated IDs and does not match unrelated
numbers.
**Rollback:** delete unused custom SITs/EDM schemas (they have no effect until referenced by a policy).

---

## Phase 2 — Build the DLP policies in SIMULATION (Configure — no user impact)

Create **one policy per location group**, each in **simulation mode**. Simulation evaluates the policy
against real traffic and records what *would* match, with **no** enforcement and (optionally) with policy
tips shown.

8. **Email DLP policy — `DLP – Email Education Records – Simulation`.**
   Portal: **Data loss prevention → Policies → Create policy** → custom (or a regulatory template if one
   applies in your tenant) → **Locations: Exchange email only** → rule: condition *Content contains* the
   education-record SITs from Phase 1 (Student ID SIT, SSN, and/or the EDM SIT) at the chosen
   confidence/instance count → action *Restrict access or encrypt* (kept inert by simulation) → **Policy
   mode: Run the policy in simulation mode** (optionally *with policy tips*). Finish.
9. **Cloud DLP policy — `DLP – SPO+OneDrive+Teams Education Records – Simulation`.**
   Same flow → **Locations: SharePoint sites, OneDrive accounts, Teams chat and channel messages** →
   conditions as above → action *Restrict access* (block external sharing on match) → **simulation mode**.
10. **Endpoint DLP policy — `DLP – Endpoint Education Records – Simulation`** (requires onboarded devices +
    licensing). Same flow → **Locations: Devices** → conditions as above → **endpoint activities to
    audit/restrict**: *copy to USB/removable media*, *copy to network share*, *print*, *upload to unallowed
    cloud apps/browser*, *copy to clipboard*, *paste to browser* → **simulation mode**. Confirm the Devices
    location is selectable (if not, revisit licensing/onboarding — Req 2.1/2.3).
11. **Set the user experience** consistently: define `FERPA DLP Notice – Standard – AllPolicies` policy-tip
    text (in plain academic language — *why* this was flagged and *what to do*) and enable **allow override
    with justification** where the FERPA/registrar function permits — but note tips/overrides only *appear*
    once a policy is enforced; in simulation they are captured, not shown to end users unless "simulation
    with policy tips" is selected.
12. **Verify with the config helper** (delivered script #2, `-WhatIf` by default):
    ```powershell
    .\DLPFERPA-Config.ps1 -PolicyName 'DLP - Email Education Records - Simulation' `
        -Locations Exchange -SensitiveTypes 'Student ID - Custom SIT - FERPA' -MinCount 5 -Confidence High -WhatIf
    ```
    Run with `-Commit` only to apply an intended change; the script never leaves a policy in enforce mode.

**Pass/fail gate:** all three policies exist and are confirmed in **simulation** (script #1/#2 report
`Mode = TestWithoutNotifications / TestWithNotifications`, i.e. simulation), scoped to the correct locations
and education-record SITs.
**Rollback:** delete the simulation policy — simulation has no user impact, so removal is clean.

---

## Phase 3 — Measure and tune (drive false positives down)

Let each policy run in simulation for the agreed **dwell time** (Req 2.6) to capture representative academic
traffic (grading, admissions, registrar operations).

13. **Review what matched.** **Purview portal → Data loss prevention → Alerts** (simulation alerts) and
    **Data classification → Activity explorer** (filter to DLP activities) show every simulated match with
    the file/message, the SIT, and the confidence. Export with the reporting script:
    ```powershell
    .\DLPFERPA-Report.ps1 -Days 14 -CsvPath .\DLPFERPA-Matches.csv
    ```
14. **Classify each match** as true positive or **false positive** and identify the false-positive drivers
    (e.g. the Student ID SIT firing on unrelated 8-digit numbers, or a name-and-address match on **directory
    information** the registrar has deemed disclosable — a treatment decision, not a detector fault).
15. **Tune** to reduce false positives without losing true positives:
    - Raise the **confidence level** (e.g. medium → high) so only high-confidence matches count.
    - Raise the **instance count** (e.g. require ≥5 student IDs, not 1) to focus on bulk-roster leaks.
    - Add **supporting keywords / proximity** to the Student ID custom SIT so context is required.
    - Introduce **EDM** (`Student Records – EDM – FERPA`) for categories where pattern SITs over-match.
    - Add **exceptions** (e.g. exclude a registrar mailbox/site the FERPA function has scoped out) where
      justified.
16. **Re-simulate** after each tuning change and re-measure. Repeat until the false-positive rate meets the
    validation gate (see Testing).

**Pass/fail gate:** measured false-positive rate is at/under the agreed threshold on the simulation sample,
with true positives (real education-record leaks) still detected.
**Rollback:** revert the last tuning change (script #2 `-WhatIf` shows the diff before `-Commit`).

---

## Phase 4 — Enforce in a pilot ring (Pilot)

17. **Scope to the pilot ring.** Add `FERPA DLP Pilot Ring – Stage1` (users) and pilot devices as the
    **included** scope on each policy (all other users/devices excluded for now):
    ```powershell
    .\DLPFERPA-Set-Scope.ps1 -PolicyName 'DLP - Email Education Records - Simulation' `
        -PilotRingGroup 'FERPADLPPilotRing@contoso.com' -Location Exchange -Commit
    ```
18. **Move the ring to enforcement.** Change **Policy mode** from *simulation* to **Turn it on / Enforce**.
    Start with **policy tips + allow-override (justification)** rather than hard block, so pilot staff can
    report false negatives/positives while retaining a business escape hatch for legitimate record handling.
19. **Confirm enforcement is live** for the ring only (script #1 reports mode `Enable` and the scoped
    identities). Confirm end users in the ring now see the `FERPA DLP Notice – Standard – AllPolicies` tip on
    a test match (fabricated data).
20. **Handle incidents.** Wire `FERPA DLP Alerts – Triage – Operations`: assign the alert owner/queue
    (Req 2.7), set severities, and (optionally) forward to SIEM/Sentinel. Triage a real simulated/pilot alert
    end-to-end to prove the workflow — and confirm alert evidence is only accessible to appropriately-roled
    staff.

**Pass/fail gate:** the pilot ring is enforced (tips shown, overrides captured), matches raise alerts, and
the triage workflow produces a dispositioned incident. No enforcement outside the ring.
**Rollback:** set the policy back to **simulation mode** (single setting) — instantly removes enforcement
with no data change.

---

## Phase 5 — Expand and harden (Enforce → Operate)

21. **Expand scope** from the ring to the full intended population once the pilot gate passes, keeping
    documented exclusions (e.g. the registrar's office if scoped differently by the FERPA function).
22. **Escalate the action** per the FERPA/registrar determination — e.g. move a category from *tip + override*
    to **block** where required (external sharing of non-directory records) — one category/location at a time,
    re-validating after each.
23. **Operationalize:** schedule the reporting script for a recurring false-positive/alert review, review
    **user overrides** (are staff justifying legitimately or bypassing?), refresh **EDM** data on cadence as
    enrollment changes, and re-tune as data and behavior change.
24. **Validate end-to-end** with the delivered testing procedure (next section) and record the pass/fail
    evidence.

**Pass/fail gate:** enforcement live across the intended scope with the FERPA-mandated action per category;
false-positive rate steady/low; alerts triaged on cadence; overrides reviewed.
**Rollback:** any policy can be returned to **simulation** at any time as an immediate, non-destructive
safety switch; individual policies can be disabled without affecting others.

---

## Order-of-operations summary

| Phase | Do | Artifact(s) | Gate | Rollback |
|---|---|---|---|---|
| 0 Assess | Connect, baseline, confirm licensing/onboarding | Posture CSV | Baseline + readiness confirmed | n/a (read-only) |
| 1 Design | Map built-in SITs, build Student ID SIT / EDM / classifiers | Custom SIT / EDM schema | Every category → tested detector | Delete unused SIT/EDM |
| 2 Configure | Build 3 policies in **simulation** | Email/Cloud/Endpoint sim policies | All in simulation, correct scope | Delete sim policy |
| 3 Tune | Measure + reduce false positives | Matches CSV | FP rate ≤ threshold | Revert tuning change |
| 4 Pilot | Enforce to ring, wire alerts | Pilot ring, alert triage | Ring enforced, incident dispositioned | Back to simulation |
| 5 Expand | Broaden scope, escalate to block, operate | Enforced policies | Full-scope enforce, low FP, alerts triaged | Simulation / disable |
