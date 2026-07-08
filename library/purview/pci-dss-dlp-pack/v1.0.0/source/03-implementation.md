# 3. Implementation Guide — PCI-DSS DLP Pack (Microsoft Purview)

This is the exact, ordered procedure to implement cardholder-data DLP across **email, cloud, Teams, and
endpoint** — every policy built in **SIMULATION** first, tuned, then enforced in a ring, then expanded.
Portal paths and cmdlets are from Microsoft's public documentation; **licensing-/plan-dependent features
and evolving portal paths are flagged "verify your licensing/tenant"** and are never asserted for your
tenant. Do the phases in order. Each phase names its artifacts (from the Overview naming table), states a
**pass/fail gate**, and gives a **rollback**.

> **Automation.** The five delivered PowerShell tools run through **Security & Compliance PowerShell**
> (`Connect-IPPSSession`) and **Microsoft Graph**. They are **read-only or `-WhatIf` by default**; writes
> require an explicit `-Commit` switch. No credentials are stored in code.

> **Determinations deferred.** The **CDE boundary and PCI scope**, *which* card-data flows are in scope,
> and the *enforced action* per flow are **compliance/PCI/QSA** decisions. This guide configures and
> proves the control and produces evidence; capture those decisions before Phase 4 (enforcement).

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
   .\PURVPCI-Discovery.ps1 -CsvPath .\PURVPCI-Posture.csv
   ```
   It reports existing DLP policies and their mode, confirms the built-in **Credit Card Number** SIT and
   any EDM schemas, and surfaces licensing/endpoint readiness signals.
3. **Confirm licensing and endpoint readiness** (Req 2.1, 2.3): confirm E5/E5-Compliance where endpoint or
   EDM are needed, and that target devices are **onboarded** (script #3 checks this).

**Pass/fail gate:** you have a written baseline (existing policies + modes), confirmation that the Credit
Card Number SIT is present, and confirmed licensing + endpoint onboarding for the locations you will
target.
**Rollback:** none (read-only).

---

## Phase 1 — Confirm the PAN detector (SITs & EDM)

Anchor detection on the built-in PAN SIT; add EDM only where near-zero false positives on *your* card
numbers are required. Do **not** invent SITs.

4. **Confirm the built-in Credit Card Number SIT.** In **Purview portal → Data classification →
   Classifiers → Sensitive info types**, open **Credit Card Number** and review its **confidence levels**
   (it combines a card-brand pattern, the **Luhn checksum**, and supporting keywords such as card-brand
   names and "credit card") and its default **instance count**. This one SIT covers the major brands
   (Visa, Mastercard, Amex, Discover, JCB, Diners) — do not recreate it.
5. **(Optional) Configure EDM for your real PANs** (Req 2.5) where pattern matching over-fires. Define the
   schema `Cardholder PAN – EDM – PCI`, hash-and-upload the source PAN table with the **EDM Upload Agent**
   under card-data handling controls, and set a **refresh cadence**. Portal: **Data classification →
   Exact data matches**. *Which fields are in scope is the data owner's determination.*
6. **(Optional) Add SAD signals with caution.** If you want an early-warning signal for **Sensitive
   Authentication Data** (track data, CVV) in storage, pair the PAN SIT with **supporting keywords**
   (e.g. "CVV", "CVC", "track data") rather than relying on a standalone 3–4-digit detector — and treat
   any SAD hit as *investigate*, not *proven violation*.

**Pass/fail gate:** the Credit Card Number SIT is confirmed at a chosen confidence and instance count, and
(if used) the EDM schema is uploaded and shows as configured.
**Rollback:** delete unused EDM schemas (they have no effect until referenced by a policy); the built-in
SIT is unchanged.

---

## Phase 2 — Build the DLP policies in SIMULATION (Configure — no user impact)

Create **one policy per location group**, each in **simulation mode**. Simulation evaluates the policy
against real traffic and records what *would* match, with **no** enforcement and (optionally) with policy
tips shown.

7. **Email DLP policy — `DLP – Email PAN – Simulation`.**
   Portal: **Data loss prevention → Policies → Create policy** → use the **PCI-DSS** category template or
   a custom policy → **Locations: Exchange email only** → rule: condition *Content contains* the
   **Credit Card Number** SIT (and `Cardholder PAN – EDM – PCI` if used) at the chosen confidence/instance
   count → action *Restrict access or encrypt* (kept inert by simulation) → **Policy mode: Run the policy
   in simulation mode** (optionally *with policy tips*). Finish.
8. **Cloud DLP policy — `DLP – SPO+OneDrive+Teams PAN – Simulation`.**
   Same flow → **Locations: SharePoint sites, OneDrive accounts, Teams chat and channel messages** →
   condition *Content contains* Credit Card Number → action *Restrict access* (block external sharing on
   match) → **simulation mode**.
9. **Endpoint DLP policy — `DLP – Endpoint PAN – Simulation`** (requires onboarded devices + licensing).
   Same flow → **Locations: Devices** → condition *Content contains* Credit Card Number → **endpoint
   activities to audit/restrict**: *copy to USB/removable media*, *copy to network share*, *print*,
   *upload to unallowed cloud apps/browser*, *copy to clipboard*, *paste to browser* → **simulation
   mode**. Confirm the Devices location is selectable (if not, revisit licensing/onboarding — Req 2.1/2.3).
10. **Set the user experience** consistently: define `PCI DLP Notice – Standard – AllPolicies` policy-tip
    text (business language: *"This looks like a payment card number. Sending it this way may violate PCI
    policy — remove it or use the approved process."*) and enable **allow override with justification**
    where compliance permits — but note tips/overrides only *appear* once a policy is enforced; in
    simulation they are captured, not shown to end users unless "simulation with policy tips" is selected.
11. **Verify with the config helper** (delivered script #2, `-WhatIf` by default):
    ```powershell
    .\PURVPCI-Config.ps1 -PolicyName 'DLP - Email PAN - Simulation' -Locations Exchange `
        -SensitiveTypes 'Credit Card Number' -MinCount 1 -Confidence High -WhatIf
    ```
    Run with `-Commit` only to apply an intended change; the script never leaves a policy in enforce mode.

**Pass/fail gate:** all three policies exist and are confirmed in **simulation** (script #1/#2 report
`Mode = TestWithNotifications / TestWithoutNotifications`), scoped to the correct locations and the Credit
Card Number SIT.
**Rollback:** delete the simulation policy — simulation has no user impact, so removal is clean.

---

## Phase 3 — Measure and tune (drive false positives down)

Let each policy run in simulation for the agreed **dwell time** (Req 2.6) to capture representative
card-data traffic.

12. **Review what matched.** **Purview portal → Data loss prevention → Alerts** (simulation alerts) and
    **Data classification → Activity explorer** (filter to DLP activities) show every simulated match with
    the file/message, the SIT, and the confidence. Export with the reporting script:
    ```powershell
    .\PURVPCI-Report.ps1 -Days 14 -CsvPath .\PURVPCI-Matches.csv
    ```
13. **Classify each match** as true positive (real PAN) or **false positive** and identify the false-
    positive drivers — the classic being the Credit Card SIT firing on a Luhn-valid **internal reference
    or order number**.
14. **Tune** to reduce false positives without losing true positives:
    - Raise the **confidence level** so only high-confidence (keyword-supported) PAN matches count.
    - Raise the **instance count** for a bulk-leak focus (e.g. require ≥10 PANs to flag a spreadsheet
      export) — but keep a **single-PAN** policy where a lone card number in an email is the concern.
    - Introduce **EDM** (`Cardholder PAN – EDM – PCI`) for storage where the built-in pattern over-matches.
    - Add **exceptions** (e.g. exclude the sanctioned in-CDE payment application's mailbox/site) where
      justified and documented.
15. **Re-simulate** after each tuning change and re-measure. Repeat until the false-positive rate meets the
    validation gate (see Testing).

**Pass/fail gate:** measured false-positive rate is at/under the agreed threshold on the simulation sample,
with real PANs still detected.
**Rollback:** revert the last tuning change (script #2 `-WhatIf` shows the diff before `-Commit`).

---

## Phase 4 — Enforce in a pilot ring (Pilot)

16. **Scope to the pilot ring.** Add `PCI DLP Pilot Ring – Stage1` (users) and pilot devices as the
    **included** scope on each policy (all other users/devices excluded for now) — script #5 helps set the
    member-of scope.
17. **Move the ring to enforcement.** Change **Policy mode** from *simulation* to **Turn it on / Enforce**.
    Start with **policy tips + allow-override (justification)** rather than hard block, so the pilot can
    report false negatives/positives while retaining a business escape hatch for legitimate card-handling
    workflows.
18. **Confirm enforcement is live** for the ring only (script #1 reports mode `Enable` and the scoped
    identities). Confirm ring users now see the `PCI DLP Notice – Standard – AllPolicies` tip on a test
    match with a **fake** test PAN.
19. **Handle incidents.** Wire `PCI DLP Alerts – Triage – Operations`: assign the alert owner/queue
    (Req 2.7), set severities aligned to your incident-response plan, and (optionally) forward to
    SIEM/Sentinel. Triage a real simulated/pilot PAN alert end-to-end to prove the workflow.

**Pass/fail gate:** the pilot ring is enforced (tips shown, overrides captured), PAN matches raise alerts,
and the triage workflow produces a dispositioned incident. No enforcement outside the ring.
**Rollback:** set the policy back to **simulation mode** (single setting) — instantly removes enforcement
with no data change.

---

## Phase 5 — Expand and harden (Enforce → Operate)

20. **Expand scope** from the ring to the full intended population once the pilot gate passes, keeping
    documented exclusions (e.g. the sanctioned in-CDE application).
21. **Escalate the action** per compliance's determination — e.g. move email PAN from *tip + override* to
    **block/encrypt** where required — one flow/location at a time, re-validating after each.
22. **Operationalize:** schedule the reporting script for a recurring false-positive/alert review, review
    **user overrides** (are people justifying legitimately or routinely bypassing?), refresh **EDM** data
    on cadence, and re-tune as data and behavior change.
23. **Validate end-to-end** with the delivered testing procedure (next section) and record the pass/fail
    evidence for the assessor.

**Pass/fail gate:** enforcement live across the intended scope with the compliance-mandated action per
flow; false-positive rate steady/low; alerts triaged on cadence; overrides reviewed; evidence captured.
**Rollback:** any policy can be returned to **simulation** at any time as an immediate, non-destructive
safety switch; individual policies can be disabled without affecting others.

---

## Order-of-operations summary

| Phase | Do | Artifact(s) | Gate | Rollback |
|---|---|---|---|---|
| 0 Assess | Connect, baseline, confirm licensing/onboarding + PAN SIT | Posture CSV | Baseline + readiness confirmed | n/a (read-only) |
| 1 Detector | Confirm Credit Card SIT; optional EDM | `Cardholder PAN – EDM – PCI` | PAN detector confirmed/tested | Delete unused EDM |
| 2 Configure | Build 3 policies in **simulation** | Email/Cloud/Endpoint PAN sim policies | All in simulation, correct scope | Delete sim policy |
| 3 Tune | Measure + reduce false positives | Matches CSV | FP rate ≤ threshold, PANs still caught | Revert tuning change |
| 4 Pilot | Enforce to ring, wire alerts | Pilot ring, alert triage | Ring enforced, PAN incident dispositioned | Back to simulation |
| 5 Expand | Broaden scope, escalate to block, operate | Enforced policies | Full-scope enforce, low FP, alerts triaged | Simulation / disable |
