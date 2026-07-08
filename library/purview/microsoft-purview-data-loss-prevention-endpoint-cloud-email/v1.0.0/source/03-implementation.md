# 3. Implementation Guide — Microsoft Purview Data Loss Prevention (DLP)

This is the exact, ordered procedure to implement Purview DLP across **email, cloud, Teams, and
endpoint** — every policy built in **SIMULATION** first, tuned, then enforced in a ring, then expanded.
Portal paths and cmdlets are from Microsoft's public documentation; **licensing-/plan-dependent features
and evolving portal paths are flagged "verify your licensing/tenant"** and are never asserted for your
tenant. Do the phases in order. Each phase names its artifacts (from the Overview naming table), states a
**pass/fail gate**, and gives a **rollback**.

> **Automation.** The five delivered PowerShell tools run through **Security & Compliance PowerShell**
> (`Connect-IPPSSession`) and **Microsoft Graph**. They are **read-only or `-WhatIf` by default**; writes
> require an explicit `-Commit` switch. No credentials are stored in code.

> **Determinations deferred.** *Which* data categories are in scope, *which* classifiers legally apply, and
> the *enforced action* per category are **compliance/privacy/legal** decisions. This guide configures and
> proves the control; capture those decisions before Phase 3.

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
   .\PURVDLP-Discovery.ps1 -CsvPath .\PURVDLP-Posture.csv
   ```
   It reports existing DLP policies and their mode, built-in vs custom SIT coverage, and licensing/endpoint
   readiness signals.
3. **Confirm licensing and endpoint readiness** (Req 2.1, 2.3): confirm E5/E5-Compliance where endpoint or
   advanced classifiers are needed, and that target devices are **onboarded** (script #3 checks this).

**Pass/fail gate:** you have a written baseline (existing policies + modes), a SIT coverage map, and
confirmed licensing + endpoint onboarding for the locations you will target.
**Rollback:** none (read-only).

---

## Phase 1 — Design the classification layer (SITs & classifiers)

Decide, per in-scope data category, which detector applies. Do **not** invent SITs — use built-in where
they fit; build custom/EDM/trainable only for gaps.

4. **Map built-in SITs first.** In **Purview portal → Data classification → Classifiers → Sensitive info
   types**, confirm the built-in SITs for your categories (e.g. *Credit Card Number*, *U.S. Social Security
   Number (SSN)*, *ABA Routing Number*, national-ID SITs). Note each SIT's **confidence levels** and
   default **instance count**.
5. **Author custom SITs for gaps.** For a category with no built-in match (e.g. an internal Employee ID),
   create `Employee ID – Custom SIT – Classification` with a **regex primary pattern**, **supporting
   keywords**, a **confidence level**, and a **character proximity**. Portal: **Classifiers → Sensitive
   info types → Create sensitive info type**. Test it against sample text in the wizard's **Test** step.
6. **Configure EDM only where near-zero false positives are required** (Req 2.5). Define the schema
   (`Customer PII – EDM – Classification`), hash-and-upload the source table with the **EDM Upload Agent**,
   and set a **refresh cadence**. Portal: **Data classification → Exact data matches**. *Which fields are in
   scope is the data owner's determination.*
7. **Add trainable classifiers where a category is conceptual, not pattern-based** (e.g. source code,
   resumes) — use a built-in trainable classifier or train a custom one on sample content. Verify
   availability against your plan.

**Pass/fail gate:** every in-scope data category maps to a named, tested SIT/classifier at a chosen
confidence and instance count.
**Rollback:** delete unused custom SITs/EDM schemas (they have no effect until referenced by a policy).

---

## Phase 2 — Build the DLP policies in SIMULATION (Configure — no user impact)

Create **one policy per location group**, each in **simulation mode**. Simulation evaluates the policy
against real traffic and records what *would* match, with **no** enforcement and (optionally) with policy
tips shown.

8. **Email DLP policy — `DLP – Email PII – Simulation`.**
   Portal: **Data loss prevention → Policies → Create policy** → custom or a category template →
   **Locations: Exchange email only** → rule: condition *Content contains* the SITs from Phase 1 at the
   chosen confidence/instance count → action *Restrict access or encrypt* (kept inert by simulation) →
   **Policy mode: Run the policy in simulation mode** (optionally *with policy tips*). Finish.
9. **Cloud DLP policy — `DLP – SPO+OneDrive+Teams PII – Simulation`.**
   Same flow → **Locations: SharePoint sites, OneDrive accounts, Teams chat and channel messages** →
   conditions as above → action *Restrict access* (block external sharing on match) → **simulation mode**.
10. **Endpoint DLP policy — `DLP – Endpoint PII – Simulation`** (requires onboarded devices + licensing).
    Same flow → **Locations: Devices** → conditions as above → **endpoint activities to audit/restrict**:
    *copy to USB/removable media*, *copy to network share*, *print*, *upload to unallowed cloud
    apps/browser*, *copy to clipboard*, *paste to browser* → **simulation mode**. Confirm the Devices
    location is selectable (if not, revisit licensing/onboarding — Req 2.1/2.3).
11. **Set the user experience** consistently: define `DLP Notice – Standard – AllPolicies` policy-tip text
    and enable **allow override with justification** where compliance permits — but note tips/overrides only
    *appear* once a policy is enforced; in simulation they are captured, not shown to end users unless
    "simulation with policy tips" is selected.
12. **Verify with the config helper** (delivered script #2, `-WhatIf` by default):
    ```powershell
    .\PURVDLP-Config.ps1 -PolicyName 'DLP – Email PII – Simulation' -WhatIf
    ```
    Run with `-Commit` only to apply an intended change; the script never leaves a policy in enforce mode.

**Pass/fail gate:** all three policies exist and are confirmed in **simulation** (script #1/#2 report
`Mode = Enable → TestWithoutNotifications / TestWithNotifications`, i.e. simulation), scoped to the correct
locations and SITs.
**Rollback:** delete the simulation policy — simulation has no user impact, so removal is clean.

---

## Phase 3 — Measure and tune (drive false positives down)

Let each policy run in simulation for the agreed **dwell time** (Req 2.6) to capture representative traffic.

13. **Review what matched.** **Purview portal → Data loss prevention → Alerts** (simulation alerts) and
    **Data classification → Activity explorer** (filter to DLP activities) show every simulated match with
    the file/message, the SIT, and the confidence. Export with the reporting script:
    ```powershell
    .\PURVDLP-Report.ps1 -Days 14 -CsvPath .\PURVDLP-Matches.csv
    ```
14. **Classify each match** as true positive or **false positive** and identify the false-positive drivers
    (e.g. a built-in *Credit Card* SIT firing on internal reference numbers).
15. **Tune** to reduce false positives without losing true positives:
    - Raise the **confidence level** (e.g. medium → high) so only high-confidence matches count.
    - Raise the **instance count** (e.g. require ≥10 card numbers, not 1) for bulk-leak focus.
    - Add **supporting keywords / proximity** to custom SITs so context is required.
    - Introduce **EDM** for categories where pattern SITs over-match.
    - Add **exceptions** (e.g. exclude a specific internal sender/site) where justified.
16. **Re-simulate** after each tuning change and re-measure. Repeat until the false-positive rate meets the
    validation gate (see Testing).

**Pass/fail gate:** measured false-positive rate is at/under the agreed threshold on the simulation sample,
with true positives still detected.
**Rollback:** revert the last tuning change (script #2 `-WhatIf` shows the diff before `-Commit`).

---

## Phase 4 — Enforce in a pilot ring (Pilot)

17. **Scope to the pilot ring.** Add `DLP Pilot Ring – Stage1` (users) and pilot devices as the **included**
    scope on each policy (all other users/devices excluded for now).
18. **Move the ring to enforcement.** Change **Policy mode** from *simulation* to **Turn it on / Enforce**.
    Start with **policy tips + allow-override (justification)** rather than hard block, so the pilot can
    report false negatives/positives while retaining a business escape hatch.
19. **Confirm enforcement is live** for the ring only (script #1 reports mode `Enable` and the scoped
    identities). Confirm end users in the ring now see the `DLP Notice – Standard – AllPolicies` tip on a
    test match.
20. **Handle incidents.** Wire `DLP Alerts – Triage – Operations`: assign the alert owner/queue (Req 2.7),
    set severities, and (optionally) forward to SIEM/Sentinel. Triage a real simulated/pilot alert
    end-to-end to prove the workflow.

**Pass/fail gate:** the pilot ring is enforced (tips shown, overrides captured), matches raise alerts, and
the triage workflow produces a dispositioned incident. No enforcement outside the ring.
**Rollback:** set the policy back to **simulation mode** (single setting) — instantly removes enforcement
with no data change.

---

## Phase 5 — Expand and harden (Enforce → Operate)

21. **Expand scope** from the ring to the full intended population once the pilot gate passes, keeping
    documented exclusions.
22. **Escalate the action** per compliance's determination — e.g. move a category from *tip + override* to
    **block** where required — one category/location at a time, re-validating after each.
23. **Operationalize:** schedule the reporting script for a recurring false-positive/alert review, review
    **user overrides** (are people justifying legitimately or bypassing?), refresh **EDM** data on cadence,
    and re-tune as data and behavior change.
24. **Validate end-to-end** with the delivered testing procedure (next section) and record the pass/fail
    evidence.

**Pass/fail gate:** enforcement live across the intended scope with the compliance-mandated action per
category; false-positive rate steady/low; alerts triaged on cadence; overrides reviewed.
**Rollback:** any policy can be returned to **simulation** at any time as an immediate, non-destructive
safety switch; individual policies can be disabled without affecting others.

---

## Order-of-operations summary

| Phase | Do | Artifact(s) | Gate | Rollback |
|---|---|---|---|---|
| 0 Assess | Connect, baseline, confirm licensing/onboarding | Posture CSV | Baseline + readiness confirmed | n/a (read-only) |
| 1 Design | Map/build SITs, EDM, classifiers | Custom SIT / EDM schema | Every category → tested detector | Delete unused SIT/EDM |
| 2 Configure | Build 3 policies in **simulation** | Email/Cloud/Endpoint sim policies | All in simulation, correct scope | Delete sim policy |
| 3 Tune | Measure + reduce false positives | Matches CSV | FP rate ≤ threshold | Revert tuning change |
| 4 Pilot | Enforce to ring, wire alerts | Pilot ring, alert triage | Ring enforced, incident dispositioned | Back to simulation |
| 5 Expand | Broaden scope, escalate to block, operate | Enforced policies | Full-scope enforce, low FP, alerts triaged | Simulation / disable |
