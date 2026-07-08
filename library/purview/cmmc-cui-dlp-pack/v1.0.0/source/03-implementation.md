# 3. Implementation Guide — CMMC / CUI DLP Pack (Microsoft Purview)

This is the exact, ordered procedure to implement **CUI-tuned Purview DLP** across **email, cloud, Teams,
and endpoint** — every policy keyed on the **CUI sensitivity label** and **CUI markings**, built in
**SIMULATION** first, tuned, then enforced to a ring, then expanded. Portal paths and cmdlets are from
Microsoft's public documentation; **licensing-/plan-dependent features and evolving portal paths (and any
GCC High differences) are flagged "verify your licensing/tenant"** and are never asserted for your tenant.
Do the phases in order. Each phase names its artifacts (from the Overview naming table), states a
**pass/fail gate**, and gives a **rollback**.

> **Automation.** The five delivered PowerShell tools run through **Security & Compliance PowerShell**
> (`Connect-IPPSSession`) and **Microsoft Graph**. They are **read-only or `-WhatIf` by default**; writes
> require an explicit `-Commit` switch, and the config helper never leaves a policy in enforce. No
> credentials are stored in code.

> **Determinations deferred.** *Which* data is CUI, *which* markings/categories apply, the *enforced action*
> per condition, and **whether a CMMC / NIST SP 800-171 practice is satisfied** are compliance / contracts /
> legal / C3PAO decisions. This guide configures and proves a supporting control and produces evidence;
> capture those determinations before Phase 3.

---

## Phase 0 — Connect, confirm tenant, and baseline (Assess)

1. **Connect the toolchain** (GR-#3). On the admin workstation:
   ```powershell
   Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force   # provides Connect-IPPSSession
   Connect-IPPSSession -UserPrincipalName admin@contoso.com            # Security & Compliance PowerShell
   Connect-MgGraph -Scopes 'Organization.Read.All','InformationProtectionPolicy.Read' -NoWelcome
   ```
   **GCC High:** use the environment-specific connection parameters per Microsoft's GCC High docs and the
   correct portal endpoint — **verify in your tenant**.
2. **Confirm the CUI label exists and is published** (Req 2.1) and **run the posture assessment** (delivered
   script #1, read-only):
   ```powershell
   .\DLPCMMC-Discovery.ps1 -CsvPath .\DLPCMMC-Posture.csv
   ```
   It reports existing DLP policies and their mode, whether a **`CUI` sensitivity label** and marking SIT are
   present, and licensing/endpoint readiness signals.
3. **Confirm licensing, tenant type, and endpoint readiness** (Req 2.2/2.3/2.5): E5/E5-Compliance where
   endpoint or label-based conditions are needed, the tenant environment (Commercial/GCC/**GCC High**), and
   that CUI-handling devices are **onboarded**.

**Pass/fail gate:** you have a written baseline (existing policies + modes), confirmation the `CUI` label is
published, a confirmed tenant type, and confirmed licensing + endpoint onboarding for the locations you will
target.
**Rollback:** none (read-only).

---

## Phase 1 — Confirm the CUI detection layer (label + markings)

Do **not** invent CUI markings or a CUI SIT. Use the **label** as the primary signal and build the
**marking keyword SIT** only from the strings compliance supplies.

4. **Confirm the CUI sensitivity label** (Req 2.1). In **Purview portal → Information protection →
   Sensitivity labels**, confirm the **`CUI`** label (and any sub-labels, e.g. `CUI//SP-CTI`,
   `CUI//SP-EXPT`) exists, applies the **content marking** (header/footer banner `CUI`), applies
   **encryption** where the CUI category requires it, and is **published** to the CUI-handling users. *If the
   label does not exist, that is a labeling-program task (a separate solution) — DLP cannot proceed without
   it.*
5. **Build the CUI marking keyword SIT** (Req 2.6). In **Purview portal → Data classification → Classifiers →
   Sensitive info types → Create sensitive info type**, create
   `CUI Banner Marking – Custom SIT – Classification` using the **exact banner/portion-marking strings**
   compliance supplied (as a keyword list / regex with proximity). Test it in the wizard's **Test** step
   against known-marked sample text. Add category keyword lists (CTI, export-control) only if supplied.
6. **Decide the primary DLP condition.** Prefer **"content contains sensitivity label = `CUI`"** (most
   reliable — follows the marking decision) with the **marking SIT** as a secondary/OR condition to catch
   marked-but-unlabeled CUI. *Which conditions and thresholds legally suffice is a compliance determination.*

**Pass/fail gate:** the `CUI` label is confirmed published, and the marking SIT is created and tested to
match your real CUI markings without matching ordinary text.
**Rollback:** delete the unused custom SIT (it has no effect until referenced by a policy). Do **not** delete
the label (managed by the labeling program).

---

## Phase 2 — Build the CUI DLP policies in SIMULATION (Configure — no user impact)

Create **one policy per location group**, each in **simulation mode**, each keyed on **label = CUI** (and the
marking SIT). Simulation evaluates against real traffic and records what *would* match, with **no**
enforcement.

7. **Email DLP policy — `DLP – CUI Email – Simulation`.**
   Portal: **Data loss prevention → Policies → Create policy** (custom) → **Locations: Exchange email only**
   → rule: condition *Content contains → Sensitivity labels → `CUI`* (OR *Content contains → Sensitive info
   types → CUI Banner Marking SIT*), plus *Recipient is external* → action *Restrict access or encrypt*
   (kept inert by simulation) → **Policy mode: Run the policy in simulation mode** (optionally *with policy
   tips*). Scope to the **CUI enclave** (Req 2.4). Finish.
8. **Cloud DLP policy — `DLP – CUI SPO+OneDrive+Teams – Simulation`.**
   Same flow → **Locations: SharePoint sites, OneDrive accounts, Teams chat and channel messages** (scope to
   the CUI sites/enclave) → same label/marking conditions → action *Restrict access* (block external sharing
   on match) → **simulation mode**.
9. **Endpoint DLP policy — `DLP – CUI Endpoint – Simulation`** (requires onboarded devices + licensing).
   Same flow → **Locations: Devices** (enclave devices) → same label/marking conditions → **endpoint
   activities to audit/restrict**: *copy to USB/removable media*, *copy to network share*, *print*, *upload
   to unallowed cloud apps/browser*, *copy to clipboard* → **simulation mode**. If the Devices location is
   not selectable, revisit licensing/onboarding (Req 2.2/2.5).
10. **Set the user experience** consistently: define `CUI Notice – Standard – AllPolicies` policy-tip text
    (plain-language: this content is marked CUI; sending it externally is restricted) and enable **allow
    override with justification** where compliance permits.
11. **Verify with the config helper** (delivered script #2, `-WhatIf` by default):
    ```powershell
    .\DLPCMMC-Config.ps1 -PolicyName 'DLP - CUI Email - Simulation' -Locations Exchange `
        -SensitivityLabel 'CUI' -MarkingSit 'CUI Banner Marking - Custom SIT - Classification' -WhatIf
    ```
    Run with `-Commit` only to apply an intended change; the script creates in **simulation** and never
    leaves a policy in enforce.

**Pass/fail gate:** all three policies exist and are confirmed in **simulation** (script #1/#3 report a
`Test*` mode), scoped to the CUI enclave and keyed on the `CUI` label + marking SIT.
**Rollback:** delete the simulation policy — simulation has no user impact, so removal is clean.

---

## Phase 3 — Measure and tune (drive false positives down)

Let each policy run in simulation for the agreed **dwell time** (Req 2.7) to capture representative CUI
traffic.

12. **Review what matched.** **Purview → Data loss prevention → Alerts** (simulation alerts) and
    **Data classification → Activity explorer** (filter to DLP activities) show every simulated match with
    the file/message, the label/SIT, and the confidence. Export with the reporting script:
    ```powershell
    .\DLPCMMC-Report.ps1 -Days 14 -CsvPath .\DLPCMMC-Matches.csv
    ```
13. **Classify each match** as true positive or **false positive** and identify the drivers (e.g. the marking
    SIT firing on a document that merely *quotes* the word "CUI" in guidance text).
14. **Tune** to reduce false positives without losing true positives:
    - **Prefer the label condition** — label-based matching is far more precise than keyword marking.
    - Add **proximity/keyword context** to the marking SIT so a stray "CUI" mention doesn't fire.
    - Add **exceptions** (e.g. a known compliance-training library that discusses CUI) where justified.
    - Tighten the **external-recipient / sharing** condition so internal enclave movement isn't flagged.
15. **Re-simulate** after each tuning change and re-measure. Repeat until the false-positive rate meets the
    validation gate (see Testing).

**Pass/fail gate:** measured false-positive rate is at/under the agreed threshold on the simulation sample,
with true positives (real marked/labeled CUI) still detected.
**Rollback:** revert the last tuning change (script #2 `-WhatIf` shows the diff before `-Commit`).

---

## Phase 4 — Enforce in a pilot ring (Pilot)

16. **Scope to the pilot ring.** Set `CUI DLP Pilot Ring – Stage1` (users) and pilot enclave devices as the
    **included** scope on each policy (all others excluded for now) — the scope helper reports/sets this:
    ```powershell
    .\DLPCMMC-Set-Scope.ps1 -PolicyName 'DLP - CUI Email - Simulation' -IncludeGroup 'CUI DLP Pilot Ring - Stage1' -WhatIf
    ```
17. **Move the ring to enforcement.** Change **Policy mode** from *simulation* to **Turn it on / Enforce**.
    Start with **policy tips + allow-override (justification)** rather than hard block, so the pilot can
    report false negatives/positives while retaining a business escape hatch (unless compliance mandates
    immediate block/encrypt for a category).
18. **Confirm enforcement is live** for the ring only (script #1/#3 report mode `Enable` and the scoped
    identities). Confirm ring users now see the `CUI Notice – Standard – AllPolicies` tip on a test match
    with fake CUI-marked content.
19. **Handle incidents + capture evidence.** Wire `CUI DLP Alerts – Triage – Operations`: assign the alert
    owner/queue (Req 2.8), set severities, retain evidence, and (optionally) forward to SIEM/Sentinel. Triage
    a real simulated/pilot alert end-to-end to prove the workflow and the evidence trail.

**Pass/fail gate:** the pilot ring is enforced (tips shown, overrides captured), CUI matches raise alerts,
and the triage workflow produces a **dispositioned, evidenced** incident. No enforcement outside the ring.
**Rollback:** set the policy back to **simulation mode** (single setting) — instantly removes enforcement
with no data change.

---

## Phase 5 — Expand, enforce, and evidence (Enforce → Operate)

20. **Expand scope** from the ring to the full **CUI-handling population/enclave** once the pilot gate
    passes, keeping documented exclusions.
21. **Escalate the action** per compliance's determination — e.g. move CUI-to-external from *tip + override*
    to **block/encrypt** — one condition/location at a time, re-validating after each.
22. **Operationalize:** schedule the reporting script for a recurring false-positive/alert review, review
    **user overrides**, retain the **evidence trail** (alerts, Activity Explorer exports) for assessment/
    audit, and re-tune as data and behavior change.
23. **Validate end-to-end** with the delivered testing procedure (next section) and record the pass/fail
    **evidence** — this is what supports the CMMC/DFARS/NIST SP 800-171 control narrative (satisfaction
    determination remains with compliance/C3PAO).

**Pass/fail gate:** enforcement live across the CUI population with the compliance-mandated action per
condition; false-positive rate steady/low; alerts triaged and **evidenced** on cadence; overrides reviewed.
**Rollback:** any policy can be returned to **simulation** at any time as an immediate, non-destructive
safety switch; individual policies can be disabled without affecting others.

---

## Order-of-operations summary

| Phase | Do | Artifact(s) | Gate | Rollback |
|---|---|---|---|---|
| 0 Assess | Connect, confirm label/tenant/licensing, baseline | Posture CSV | Baseline + `CUI` label + readiness confirmed | n/a (read-only) |
| 1 Detection | Confirm CUI label, build marking SIT | Marking SIT | Label published + SIT tested | Delete unused SIT |
| 2 Configure | Build 3 policies keyed on label+marking in **simulation** | Email/Cloud/Endpoint sim policies | All in simulation, enclave-scoped | Delete sim policy |
| 3 Tune | Measure + reduce false positives | Matches CSV | FP rate ≤ threshold | Revert tuning change |
| 4 Pilot | Enforce to ring, wire alerts + evidence | Pilot ring, alert triage | Ring enforced, incident evidenced | Back to simulation |
| 5 Expand | Broaden to CUI population, escalate to block/encrypt, evidence | Enforced policies | Full-scope enforce, low FP, evidenced | Simulation / disable |
