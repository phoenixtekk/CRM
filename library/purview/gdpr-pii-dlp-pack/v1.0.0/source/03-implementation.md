# 3. Implementation Guide — GDPR / PII DLP Pack (Microsoft Purview)

This is the exact, ordered procedure to implement GDPR/PII-aligned personal-data DLP across **email, cloud,
Teams, and endpoint** — every policy built in **SIMULATION** first, tuned, then enforced in a ring, then
expanded. Portal paths and cmdlets are from Microsoft's public documentation; **licensing-/plan-dependent
features and evolving portal paths are flagged "verify your licensing/tenant"** and are never asserted for
your tenant. Do the phases in order. Each phase names its artifacts (from the Overview naming table), states
a **pass/fail gate**, and gives a **rollback**.

> **Automation.** The five delivered PowerShell tools run through **Security & Compliance PowerShell**
> (`Connect-IPPSSession`) and **Microsoft Graph**. They are **read-only or `-WhatIf` by default**; writes
> require an explicit `-Commit` switch. No credentials are stored in code.

> **Determinations deferred.** Lawful basis, **special-category (Article 9)** status, whether a transfer is a
> **restricted cross-border transfer**, the retention position, and the *enforced action* per category are
> **data-protection / privacy (DPO) / legal** decisions. This guide configures and proves the control;
> capture those decisions before Phase 3.

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
   .\DLPGDPR-Discovery.ps1 -CsvPath .\DLPGDPR-Posture.csv
   ```
   It reports existing DLP policies and their mode, built-in vs custom SIT coverage (including which of the
   **EU/GDPR built-in SITs** are present and whether a custom national-ID/data-subject SIT already exists),
   and licensing/endpoint readiness signals.
3. **Confirm licensing and endpoint readiness** (Req 2.1, 2.3): confirm E5/E5-Compliance where endpoint or
   advanced classifiers are needed, and that target staff devices are **onboarded**.

**Pass/fail gate:** you have a written baseline (existing policies + modes), a SIT coverage map for EU
personal data, and confirmed licensing + endpoint onboarding for the locations you will target.
**Rollback:** none (read-only).

---

## Phase 1 — Design the classification layer (SITs & classifiers for EU personal data)

Decide, per in-scope data category, which detector applies. Do **not** invent SITs — use built-in where they
fit; build custom/EDM/trainable only for gaps. *Whether a regulatory (e.g. GDPR-labeled) DLP policy template
is available is version-/licensing-dependent — check the template gallery, but do not rely on one existing.*

4. **Map the EU/GDPR built-in SITs first.** In **Purview portal → Data classification → Classifiers →
   Sensitive info types**, confirm the built-in SITs for your categories and the member states you operate
   in — e.g. *EU National Identification Number*, *EU Passport Number*, *EU Social Security Number or
   Equivalent ID*, *EU Tax Identification Number (TIN)*, *EU Driver's License Number*, *EU Debit Card
   Number*, *International Banking Account Number (IBAN)*, *All Full Names*, and the relevant per-country
   variants. Note each SIT's **confidence levels** and default **instance count**.
5. **Author a custom SIT for any bespoke identifier.** Where a national scheme isn't covered by a built-in
   SIT, or you protect an internal data-subject reference, create `EU National ID – Custom SIT – GDPR` with a
   **regex primary pattern** matched to the format, **supporting keywords** (e.g. "national ID", the
   member-state term, "customer ID"), a **confidence level**, and a **character proximity**. Portal:
   **Classifiers → Sensitive info types → Create sensitive info type**. Test it against sample text in the
   wizard's **Test** step with fabricated IDs.
6. **Configure EDM where near-zero false positives are required** (Req 2.5). Define the schema
   (`Data Subject Records – EDM – GDPR`), hash-and-upload the data-subject/CRM/HR export with the **EDM
   Upload Agent**, and set a **refresh cadence**. Portal: **Data classification → Exact data matches**.
   *Which fields are in scope is the DPO/data owner's determination.*
7. **Add trainable classifiers for special-category / conceptual data** (Article 9 — e.g. health,
   biometric-context content) where a pattern SIT can't fit — use a built-in trainable classifier where one
   fits, or train a custom one on sample content. Verify availability against your plan. *What counts as
   special-category data is a DPO/legal determination.*

**Pass/fail gate:** every in-scope data category maps to a named, tested SIT/classifier at a chosen
confidence and instance count; the custom SIT matches fabricated IDs and does not match unrelated numbers.
**Rollback:** delete unused custom SITs/EDM schemas (they have no effect until referenced by a policy).

---

## Phase 2 — Build the DLP policies in SIMULATION (Configure — no user impact)

Create **one policy per location group**, each in **simulation mode**. Simulation evaluates the policy
against real traffic and records what *would* match, with **no** enforcement and (optionally) with policy
tips shown.

8. **Email DLP policy — `DLP – Email EU Personal Data – Simulation`.**
   Portal: **Data loss prevention → Policies → Create policy** → custom (or a regulatory template if one
   applies in your tenant) → **Locations: Exchange email only** → rule: condition *Content contains* the
   EU-personal-data SITs from Phase 1 (national-ID SITs, TIN, IBAN, and/or the EDM SIT) at the chosen
   confidence/instance count; optionally add *Recipient is external* for cross-border/transfer awareness →
   action *Restrict access or encrypt* (kept inert by simulation) → **Policy mode: Run the policy in
   simulation mode** (optionally *with policy tips*). Finish.
9. **Cloud DLP policy — `DLP – SPO+OneDrive+Teams EU Personal Data – Simulation`.**
   Same flow → **Locations: SharePoint sites, OneDrive accounts, Teams chat and channel messages** →
   conditions as above → action *Restrict access* (block external sharing on match) → **simulation mode**.
10. **Endpoint DLP policy — `DLP – Endpoint EU Personal Data – Simulation`** (requires onboarded devices +
    licensing). Same flow → **Locations: Devices** → conditions as above → **endpoint activities to
    audit/restrict**: *copy to USB/removable media*, *copy to network share*, *print*, *upload to unallowed
    cloud apps/browser*, *copy to clipboard*, *paste to browser* → **simulation mode**. Confirm the Devices
    location is selectable (if not, revisit licensing/onboarding — Req 2.1/2.3).
11. **Set the user experience** consistently: define `GDPR DLP Notice – Standard – AllPolicies` policy-tip
    text (in plain business language — *why* this was flagged and *what to do*) and enable **allow override
    with justification** where the DPO/legal function permits — but note tips/overrides only *appear* once a
    policy is enforced; in simulation they are captured, not shown to end users unless "simulation with
    policy tips" is selected.
12. **Verify with the config helper** (delivered script #2, `-WhatIf` by default):
    ```powershell
    .\DLPGDPR-Config.ps1 -PolicyName 'DLP - Email EU Personal Data - Simulation' `
        -Locations Exchange -SensitiveTypes 'EU National Identification Number' -MinCount 5 -Confidence High -WhatIf
    ```
    Run with `-Commit` only to apply an intended change; the script never leaves a policy in enforce mode.

**Pass/fail gate:** all three policies exist and are confirmed in **simulation** (script #1/#3 report
`Mode = TestWithoutNotifications / TestWithNotifications`, i.e. simulation), scoped to the correct locations
and EU-personal-data SITs.
**Rollback:** delete the simulation policy — simulation has no user impact, so removal is clean.

---

## Phase 3 — Measure and tune (drive false positives down)

Let each policy run in simulation for the agreed **dwell time** (Req 2.6) to capture representative business
traffic (sales, HR, support, marketing).

13. **Review what matched.** **Purview portal → Data loss prevention → Alerts** (simulation alerts) and
    **Data classification → Activity explorer** (filter to DLP activities) show every simulated match with
    the file/message, the SIT, and the confidence. Export with the reporting script:
    ```powershell
    .\DLPGDPR-Report.ps1 -Days 14 -CsvPath .\DLPGDPR-Matches.csv
    ```
14. **Classify each match** as true positive or **false positive** and identify the false-positive drivers
    (e.g. a national-ID SIT firing on unrelated numbers of the same length, or an IBAN-shaped internal
    reference). Where a match is real personal data leaving the organisation, note whether it is an
    *external/cross-border* transfer — the *legal* treatment of that transfer is a DPO/legal call, not a
    detector fault.
15. **Tune** to reduce false positives without losing true positives:
    - Raise the **confidence level** (e.g. medium → high) so only high-confidence matches count.
    - Raise the **instance count** (e.g. require ≥5 identifiers, not 1) to focus on bulk data-subject leaks.
    - Add **supporting keywords / proximity** to the custom SIT so context is required.
    - Introduce **EDM** (`Data Subject Records – EDM – GDPR`) for categories where pattern SITs over-match.
    - Add **exceptions** (e.g. exclude a DPO/HR mailbox or site the privacy function has scoped out) where
      justified.
16. **Re-simulate** after each tuning change and re-measure. Repeat until the false-positive rate meets the
    validation gate (see Testing).

**Pass/fail gate:** measured false-positive rate is at/under the agreed threshold on the simulation sample,
with true positives (real personal-data leaks) still detected.
**Rollback:** revert the last tuning change (script #2 `-WhatIf` shows the diff before `-Commit`).

---

## Phase 4 — Enforce in a pilot ring (Pilot)

17. **Scope to the pilot ring.** Add `GDPR DLP Pilot Ring – Stage1` (users) and pilot devices as the
    **included** scope on each policy (all other users/devices excluded for now):
    ```powershell
    .\DLPGDPR-Set-Scope.ps1 -PolicyName 'DLP - Email EU Personal Data - Simulation' `
        -PilotRingGroup 'GDPRDLPPilotRing@contoso.com' -Location Exchange -Commit
    ```
18. **Move the ring to enforcement.** Change **Policy mode** from *simulation* to **Turn it on / Enforce**.
    Start with **policy tips + allow-override (justification)** rather than hard block, so pilot staff can
    report false negatives/positives while retaining a business escape hatch for legitimate personal-data
    handling.
19. **Confirm enforcement is live** for the ring only (script #3 reports mode `Enable` and the scoped
    identities). Confirm end users in the ring now see the `GDPR DLP Notice – Standard – AllPolicies` tip on
    a test match (fabricated data).
20. **Handle incidents.** Wire `GDPR DLP Alerts – Triage – Operations`: assign the alert owner/queue
    (Req 2.7), set severities, define the **DPO/breach hand-off** for real exposures, and (optionally)
    forward to SIEM/Sentinel. Triage a real simulated/pilot alert end-to-end to prove the workflow — and
    confirm alert evidence is only accessible to appropriately-roled staff (personal-data minimisation on the
    control's own records).

**Pass/fail gate:** the pilot ring is enforced (tips shown, overrides captured), matches raise alerts, and
the triage workflow produces a dispositioned incident with the DPO hand-off exercised. No enforcement outside
the ring.
**Rollback:** set the policy back to **simulation mode** (single setting) — instantly removes enforcement
with no data change.

---

## Phase 5 — Expand and harden (Enforce → Operate)

21. **Expand scope** from the ring to the full intended population once the pilot gate passes, keeping
    documented exclusions (e.g. the DPO/HR function if scoped differently by the privacy function).
22. **Escalate the action** per the DPO/legal determination — e.g. move a category from *tip + override* to
    **block** where required (external/cross-border sharing of national-ID or special-category data) — one
    category/location at a time, re-validating after each.
23. **Operationalize:** schedule the reporting script for a recurring false-positive/alert review, review
    **user overrides** (are staff justifying legitimately or bypassing?), refresh **EDM** data on cadence,
    and re-tune as data and behaviour change.
24. **Validate end-to-end** with the delivered testing procedure (next section) and record the pass/fail
    evidence.

**Pass/fail gate:** enforcement live across the intended scope with the DPO-mandated action per category;
false-positive rate steady/low; alerts triaged on cadence with breach hand-off; overrides reviewed.
**Rollback:** any policy can be returned to **simulation** at any time as an immediate, non-destructive
safety switch; individual policies can be disabled without affecting others.

---

## Order-of-operations summary

| Phase | Do | Artifact(s) | Gate | Rollback |
|---|---|---|---|---|
| 0 Assess | Connect, baseline, confirm licensing/onboarding | Posture CSV | Baseline + readiness confirmed | n/a (read-only) |
| 1 Design | Map EU built-in SITs, build custom SIT / EDM / classifiers | Custom SIT / EDM schema | Every category → tested detector | Delete unused SIT/EDM |
| 2 Configure | Build 3 policies in **simulation** | Email/Cloud/Endpoint sim policies | All in simulation, correct scope | Delete sim policy |
| 3 Tune | Measure + reduce false positives | Matches CSV | FP rate ≤ threshold | Revert tuning change |
| 4 Pilot | Enforce to ring, wire alerts + DPO hand-off | Pilot ring, alert triage | Ring enforced, incident dispositioned | Back to simulation |
| 5 Expand | Broaden scope, escalate to block, operate | Enforced policies | Full-scope enforce, low FP, alerts triaged | Simulation / disable |
