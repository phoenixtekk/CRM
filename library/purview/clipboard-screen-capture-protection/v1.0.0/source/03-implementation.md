# 3. Implementation Guide — Clipboard & Screen-Capture Protection (Microsoft Purview)

This is the exact, ordered procedure to configure **clipboard** and **screen-capture** restrictions for
sensitive content on **onboarded endpoints** — built in **SIMULATION / audit** mode first, tuned, then
enforced in a ring, then expanded. Portal paths and cmdlets are from Microsoft's public documentation;
**licensing-/plan-dependent features and evolving/preview portal paths are flagged "verify your
licensing/tenant"** and are never asserted for your tenant. Do the phases in order. Each phase names its
artifacts (from the Overview naming table), states a **pass/fail gate**, and gives a **rollback**.

> **Automation.** The five delivered PowerShell tools run through **Security & Compliance PowerShell**
> (`Connect-IPPSSession`) and **Microsoft Graph**. They are **read-only or `-WhatIf` by default**; writes
> require an explicit `-Commit` switch, and the config helper is **simulation-only** — it never leaves a
> policy in enforce. No credentials are stored in code.

> **Determinations deferred.** *Which* content categories are in scope, *which* classifiers/labels legally
> apply, and the *enforced action* per category are **compliance/privacy/legal** decisions. This guide
> configures and proves the control; capture those decisions before Phase 4.

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
   .\DLPCLIP-Discovery.ps1 -CsvPath .\DLPCLIP-Posture.csv
   ```
   It reports existing DLP policies and their mode, which ones scope the **Devices/Endpoint** location, any
   **clipboard/screen-capture** restrictions already configured on their rules, and built-in vs custom SIT
   coverage.
3. **Confirm licensing and endpoint readiness** (Req 2.1, 2.3): confirm E5 / E5 Compliance, that target
   devices are **onboarded** and meet the **minimum OS build**, and that the **copy to clipboard** and
   **screen capture** activities are selectable in a rule (script #3 surfaces the readiness signals). If
   screen capture is not available in your tenant, note it and deliver clipboard first.

**Pass/fail gate:** you have a written baseline (existing policies + modes + any endpoint restrictions), a SIT/label
coverage map, and confirmed licensing + onboarding for the Devices location.
**Rollback:** none (read-only).

---

## Phase 1 — Design the classification layer (what counts as "sensitive")

Decide which detector marks content that must not be copied/screenshotted. Do **not** invent SITs — use
built-in where they fit; build custom/EDM/trainable only for gaps; use a **sensitivity-label condition**
where content is already labelled.

4. **Map built-in SITs first.** In **Purview portal → Data classification → Classifiers → Sensitive info
   types**, confirm the built-in SITs for your categories (e.g. *Credit Card Number*, *U.S. Social Security
   Number (SSN)*, national-ID / health-identifier SITs). Note each SIT's **confidence levels** and default
   **instance count**.
5. **Author custom SITs for gaps.** For a category with no built-in match (e.g. an internal case or record
   number), create a custom SIT with a **regex primary pattern**, **supporting keywords**, a **confidence
   level**, and a **character proximity**. Portal: **Classifiers → Sensitive info types → Create sensitive
   info type**. Test it against sample text in the wizard's **Test** step.
6. **Use a sensitivity-label condition where content is labelled.** If the organization already applies a
   label such as *Confidential*, the rule can trigger on **"content contains → Sensitivity labels"** instead
   of (or in addition to) SITs — a precise, low-false-positive signal. Confirm the labels exist with the
   information-protection owner.
7. **(Optional) EDM / trainable classifiers** for categories where pattern SITs over-match or the category is
   conceptual. Verify availability against your plan; *which fields are in scope is the data owner's
   determination.*

**Pass/fail gate:** every in-scope "do not copy/screenshot" category maps to a named, tested detector
(built-in SIT, custom SIT, EDM, trainable classifier, or sensitivity label) at a chosen confidence/instance
count.
**Rollback:** delete unused custom SITs (they have no effect until referenced by a policy).

---

## Phase 2 — Configure the endpoint restriction in SIMULATION (Configure — no user impact)

Create **one Endpoint DLP policy** with a rule that covers the **clipboard** and **screen-capture**
activities, in **simulation / audit** mode. Simulation/audit records what *would* be restricted against real
device activity, with **no** enforcement and (optionally) with policy tips shown.

8. **Set the Endpoint DLP settings first** (Req 2.5). Portal: **Data loss prevention → Endpoint DLP settings**
   → configure the **unallowed / restricted apps and browsers**, **service-domain**, and **network** lists so
   your **sanctioned** apps/browsers are represented (either as allowed, or clearly out of the unallowed
   list). This is what keeps legitimate internal copy-paste and screenshots from being caught.
9. **Create the policy — `DLP – Endpoint Clipboard+Screen – Simulation`.**
   Portal: **Data loss prevention → Policies → Create policy** → custom (or a category template) →
   **Locations: Devices only** (all other locations off for this solution). Confirm the Devices location is
   selectable; if not, revisit licensing/onboarding (Req 2.1/2.3).
10. **Author the rule — `DLP – Endpoint Clipboard+Screen – Rule`.**
    - **Condition:** *Content contains* → the SITs from Phase 1 at the chosen confidence/instance count, and/or
      *Sensitivity labels* from Phase 1.
    - **Actions → "Audit or restrict activities on devices":** set **Copy to clipboard** and **Screen capture**
      (labelled per your tenant's current portal) to **Audit** (the simulation-phase action). Leave the other
      endpoint activities (USB, print, network share, etc.) untouched — they are out of scope for this
      solution.
    - **User experience:** define `DLP Notice – Clipboard/Screen – Standard` policy-tip text and enable
      **allow override with justification** where compliance permits — note tips/overrides only *appear* once
      the policy is enforced; in audit they are captured, not shown, unless "simulation with policy tips" is
      selected.
11. **Set the policy mode to simulation.** Choose **"Run the policy in simulation mode"** (optionally *with
    policy tips*). Finish. In S&C PowerShell this corresponds to `Mode = TestWithNotifications` /
    `TestWithoutNotifications`.
12. **Verify with the config helper** (delivered script #2, `-WhatIf` by default):
    ```powershell
    .\DLPCLIP-Config.ps1 -PolicyName 'DLP - Endpoint Clipboard+Screen - Simulation' `
        -SensitiveTypes 'Credit Card Number' -MinCount 1 -Confidence High -WhatIf
    ```
    The helper previews the `New-DlpCompliancePolicy` / `New-DlpComplianceRule` calls (Devices location,
    simulation mode, clipboard+screen-capture restrictions). Because the exact **endpoint-restriction setting
    names evolve/preview**, the recommended pattern is: build the rule **once in the portal**, then read its
    restriction property with script #1 to confirm the exact names before ever committing with the helper.
    Run with `-Commit` only to apply an intended change; the helper never leaves a policy in enforce mode.

**Pass/fail gate:** the policy exists, is scoped to **Devices only**, covers **clipboard + screen-capture**,
and is confirmed in **simulation** (script #1/#2 report a `Test*` mode).
**Rollback:** delete the simulation policy — simulation has no user impact, so removal is clean.

---

## Phase 3 — Measure and tune (drive false positives down)

Let the policy run in simulation for the agreed **dwell time** (Req 2.6) to capture representative device
activity.

13. **Review what would have been restricted.** **Purview portal → Data loss prevention → Alerts**
    (simulation alerts) and **Data classification → Activity explorer** (filter to endpoint DLP activities —
    *copy to clipboard*, *screen capture*) show every simulated match with the app/browser, the SIT/label, and
    the confidence. Export with the reporting script:
    ```powershell
    .\DLPCLIP-Report.ps1 -Days 14 -CsvPath .\DLPCLIP-Activity.csv
    ```
14. **Classify each match** as true positive or **false positive** and identify the false-positive drivers
    (e.g. legitimate copy-paste between two sanctioned internal apps, a screenshot of a normal page that
    happens to contain a low-confidence pattern).
15. **Tune** to reduce false positives without losing true positives:
    - Raise the **confidence level** (e.g. medium → high) and/or the **instance count** so incidental matches
      don't fire.
    - Prefer a **sensitivity-label condition** over broad SITs where content is labelled — far fewer false
      positives.
    - Add **allowed-app / browser / network exceptions** (Endpoint DLP settings) so sanctioned tools aren't
      caught.
    - Introduce **EDM** for categories where pattern SITs over-match.
    - Add **supporting keywords / proximity** to custom SITs so context is required.
16. **Re-simulate** after each tuning change and re-measure. Repeat until the false-positive rate meets the
    validation gate (see Testing).

**Pass/fail gate:** measured false-positive rate is at/under the agreed threshold on the simulation sample,
with true positives (sensitive-content copy/screenshot) still detected.
**Rollback:** revert the last tuning change (script #2 `-WhatIf` shows the diff before `-Commit`).

---

## Phase 4 — Enforce in a pilot ring (Pilot)

17. **Scope to the pilot ring.** Set `DLP Pilot Ring – Stage1` (users) and the pilot devices as the
    **included** scope on the policy (all other users/devices excluded for now):
    ```powershell
    .\DLPCLIP-Set-Scope.ps1 -PolicyName 'DLP - Endpoint Clipboard+Screen - Simulation' `
        -IncludeGroup 'DLP Pilot Ring - Stage1' -WhatIf
    ```
18. **Move the ring to enforcement.** Change **Policy mode** from *simulation* to **Turn it on / Enforce**.
    Start the clipboard and screen-capture activities at **Block with override (justification)** rather than
    hard block, so the pilot can report false negatives/positives while retaining a business escape hatch.
    (Rename to `DLP – Endpoint Clipboard+Screen – Enforce Pilot` if your change process tracks the transition.)
19. **Confirm enforcement is live** for the ring only (script #1 reports mode `Enable` and the scoped
    identities). On a ring device, confirm a test copy/screenshot of clearly-fake sensitive content now shows
    the `DLP Notice – Clipboard/Screen – Standard` tip and requires justification.
20. **Handle incidents.** Wire `DLP Alerts – Clipboard/Screen – Operations`: assign the alert owner/queue
    (Req 2.7), set severities, and (optionally) forward to SIEM/Sentinel. Triage a real pilot alert end-to-end
    to prove the workflow.

**Pass/fail gate:** the pilot ring is enforced (clipboard/screenshot of sensitive content restricted, tips
shown, overrides captured), matches raise alerts, and the triage workflow produces a dispositioned incident.
No enforcement outside the ring.
**Rollback:** set the policy back to **simulation mode** (single setting) — instantly removes enforcement with
no data change.

---

## Phase 5 — Expand and harden (Enforce → Operate)

21. **Expand scope** from the ring to the full intended population once the pilot gate passes, keeping
    documented exclusions.
22. **Escalate the action** per compliance's determination — e.g. move clipboard/screen-capture from *block
    with override* to **hard block** where required — one activity at a time, re-validating after each.
23. **Operationalize:** schedule the reporting script for a recurring false-positive/alert review, review
    **user overrides** (are people justifying legitimately or bypassing?), refresh **EDM** data on cadence
    (if used), and re-tune the allowed-app/browser lists as tools change.
24. **Validate end-to-end** with the delivered testing procedure (next section) and record the pass/fail
    evidence.

**Pass/fail gate:** enforcement live across the intended scope with the compliance-mandated action for
clipboard and screen capture; false-positive rate steady/low; alerts triaged on cadence; overrides reviewed.
**Rollback:** the policy can be returned to **simulation** at any time as an immediate, non-destructive safety
switch; the clipboard and screen-capture activities can be relaxed independently.

---

## Order-of-operations summary

| Phase | Do | Artifact(s) | Gate | Rollback |
|---|---|---|---|---|
| 0 Assess | Connect, baseline, confirm licensing/onboarding | Posture CSV | Baseline + readiness confirmed | n/a (read-only) |
| 1 Design | Map/build SITs / label condition | Custom SIT / label condition | Every category → tested detector | Delete unused SIT |
| 2 Configure | Build the Devices policy (clipboard+screen) **in simulation** | `…– Simulation` policy + rule | Simulation, Devices-only, both activities | Delete sim policy |
| 3 Tune | Measure + reduce false positives | Activity CSV | FP rate ≤ threshold | Revert tuning change |
| 4 Pilot | Enforce to ring, wire alerts | Pilot ring, alert triage | Ring enforced, incident dispositioned | Back to simulation |
| 5 Expand | Broaden scope, escalate to block, operate | Enforced policy | Full-scope enforce, low FP, alerts triaged | Simulation / relax activity |
