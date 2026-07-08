# 3. Implementation Guide — Document Fingerprinting (Microsoft Purview)

This is the exact, ordered procedure to fingerprint standard forms and wire them to DLP — the DLP policy
carrying the fingerprint built in **SIMULATION** first, measured, then enforced to a ring, then expanded.
Portal paths and cmdlets are from Microsoft's public documentation; **licensing-/plan-dependent features
and evolving portal paths are flagged "verify your licensing/tenant"** and are never asserted for your
tenant. Do the phases in order. Each phase names its artifacts (from the Overview naming table), states a
**pass/fail gate**, and gives a **rollback**.

> **Automation.** The five delivered PowerShell tools run through **Security & Compliance PowerShell**
> (`Connect-IPPSSession`). They are **read-only or `-WhatIf` by default**; writes require an explicit
> `-Commit` switch. No credentials are stored in code.

> **Determinations deferred.** *Which* forms are in scope, *which* legal/regulatory obligation applies to
> each, and the *enforced action* per form are **compliance/privacy/legal** decisions. This guide
> configures and proves the control; capture those decisions before Phase 4.

---

## Phase 0 — Connect and baseline (Assess)

1. **Connect the toolchain** (GR-#3). On the admin workstation:
   ```powershell
   Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force   # provides Connect-IPPSSession
   Connect-IPPSSession -UserPrincipalName admin@contoso.com            # Security & Compliance PowerShell
   ```
2. **Run the posture assessment** (delivered script #1, read-only):
   ```powershell
   .\CLSFINGER-Discovery.ps1 -CsvPath .\CLSFINGER-Posture.csv
   ```
   It reports existing **fingerprint SITs**, the DLP policies that reference them and their **mode**, and
   readiness signals.
3. **Confirm licensing and roles** (Req 2.1, 2.2): confirm you can create a **Document fingerprint** SIT
   and target the DLP locations you intend to use, and that your account holds the DLP roles.

**Pass/fail gate:** you have a written baseline (existing fingerprint SITs + any DLP referencing them),
confirmed licensing, and the roles to author SITs and policies.
**Rollback:** none (read-only).

---

## Phase 1 — Assemble and validate the source forms (Design)

Decide, per in-scope form, that fingerprinting is the right technique (the *form structure* is the
signal). Do **not** fingerprint image-only or password-protected files — they have no extractable text.

4. **Build the form inventory** (Req 2.4): for each form, record name, owner, version, sensitivity, and
   the workloads it travels through. Group related forms (e.g. all HR onboarding forms) into one planned
   fingerprint SIT where it makes sense.
5. **Collect a blank/representative template per form** (Req 2.3) in a supported text-based format
   (`.docx`, `.dotx`, `.pdf`, `.txt`, …). Open each and confirm the **boilerplate text is selectable**
   (not a flattened image), and that the file is within Microsoft's supported **type/size** limits
   (**verify current limits for your tenant**).
6. **Name each source and its SIT** from the Overview table — e.g. source `Onboarding Form – Fingerprint
   – Source`, SIT `Standard Forms – Fingerprint SIT – Classification`.

**Pass/fail gate:** every in-scope form has a text-based template in hand, is confirmed fingerprintable,
and is assigned to a named planned SIT.
**Rollback:** none (no tenant change yet).

---

## Phase 2 — Create the fingerprints and the SIT (Configure)

Create the fingerprint(s), then wrap them in a named SIT. **Portal path:** *Purview portal → Data
classification → Classifiers → Sensitive info types → Create sensitive info type → Document fingerprint*
(verify availability in your tenant). Equivalent PowerShell (used by the delivered script #2):

7. **Create a fingerprint from each template** with `New-DlpFingerprint`. In PowerShell 5.1:
   ```powershell
   $formBytes = Get-Content ".\Onboarding-Template.docx" -Encoding Byte -ReadCount 0
   $fp = New-DlpFingerprint -FileData $formBytes -Description "Onboarding Form – Fingerprint – Source"
   ```
   *(PowerShell 7 replaces `-Encoding Byte` with `-AsByteStream`; the delivered script #2 handles both.)*
   `New-DlpFingerprint` computes the fingerprint object; **the document itself is not stored.**
8. **Wrap one or more fingerprints in a SIT** with `New-DlpSensitiveInformationType`:
   ```powershell
   New-DlpSensitiveInformationType -Name "Standard Forms – Fingerprint SIT – Classification" `
     -Fingerprints $fp -Description "Detects our standard onboarding/intake forms"
   ```
   To add more forms into the same SIT, pass an array: `-Fingerprints @($fp1,$fp2,$fp3)`.
9. **Do it safely with the delivered helper** (script #2, `-WhatIf` by default):
   ```powershell
   .\CLSFINGER-CreateFingerprint.ps1 -TemplatePath .\Onboarding-Template.docx `
     -SitName "Standard Forms – Fingerprint SIT – Classification" -WhatIf
   ```
   Run with `-Commit` only to actually create/update the SIT. The script never touches a DLP policy's
   enforce state.
10. **Confirm the SIT exists**: `Get-DlpSensitiveInformationType -Identity "Standard Forms – Fingerprint
    SIT – Classification"` (or script #1). Note its **GUID/Publisher** for reference.

**Pass/fail gate:** the fingerprint SIT exists, carries the intended form fingerprint(s), and is visible
in **Data classification → Classifiers → Sensitive info types**.
**Rollback:** `Remove-DlpSensitiveInformationType -Identity "..."` — a SIT not yet referenced by any
policy has no runtime effect, so removal is clean.

---

## Phase 3 — Build the DLP policy in SIMULATION (Configure — no user impact)

Reference the fingerprint SIT from a DLP policy in **simulation mode**. Simulation evaluates the policy
against real traffic and records what *would* match, with **no** enforcement.

11. **Create the policy — `DLP – Fingerprinted Forms – Simulation`.**
    Portal: **Data loss prevention → Policies → Create policy** → *Custom* → **Locations:** start with
    **Exchange email, SharePoint sites, OneDrive accounts, Teams chat and channel messages** (add
    **Devices/Endpoint** only if licensed and onboarded) → **Rule `Rule – Fingerprinted Forms –
    ContentContains`:** condition *Content contains → Sensitive info types →* select `Standard Forms –
    Fingerprint SIT – Classification` → action *Restrict access or encrypt* (kept inert by simulation) →
    **Policy mode: Run the policy in simulation mode** (optionally *with policy tips*). Finish.
12. **Set the user experience** (applies once enforced): define `Fingerprint Notice – Standard –
    AllPolicies` policy-tip text and enable **allow override with justification** where compliance
    permits.
13. **Verify the wiring** (delivered script #3, read-only):
    ```powershell
    .\CLSFINGER-Validation.ps1 -SitName "Standard Forms – Fingerprint SIT – Classification"
    ```
    It confirms the SIT exists, that `DLP – Fingerprinted Forms – Simulation` references it, and that the
    policy is in simulation mode.

**Pass/fail gate:** the policy exists, is confirmed in **simulation**, references the fingerprint SIT,
and is scoped to the correct locations.
**Rollback:** delete the simulation policy — simulation has no user impact, so removal is clean.

---

## Phase 4 — Measure and confirm detection (Pilot — simulate)

Let the policy run in simulation for the agreed **dwell time** (Req 2.6) to capture representative form
traffic, and prove the fingerprint actually detects the live forms.

14. **Positive detection test.** Take a **filled** copy of a fingerprinted form (with **clearly-fake**
    data — never real personal data) and move it through a covered channel (e.g. email it internally).
    Confirm it appears as a **simulated match**.
15. **Review what matched.** **Purview portal → Data loss prevention → Alerts** (simulation) and **Data
    classification → Activity explorer** (filter to DLP) show every simulated match — file/message, SIT,
    action. Export with the reporting script:
    ```powershell
    .\CLSFINGER-Report.ps1 -Days 14 -CsvPath .\CLSFINGER-Matches.csv
    ```
16. **Classify each match** as true positive or **false positive**. Fingerprints are high-precision, but
    watch for over-broad matches where the fingerprinted boilerplate also appears in unrelated documents
    (e.g. a common letterhead). If false positives appear:
    - **Re-source a cleaner template** (more form-specific boilerplate, less generic letterhead).
    - **Split** an over-broad SIT so each form is detected on its own distinctive text.
    - Add a targeted **exception** where justified (specific sender/site), narrowly and documented.
17. **Confirm the negative case.** Move an **unrelated** document through the same channel and confirm it
    is **not** matched — verifying the fingerprint is specific to the form.

**Pass/fail gate:** the filled form is detected in simulation; unrelated content is not; false positives
are understood and at/under the agreed threshold.
**Rollback:** re-source/re-create the fingerprint (Phase 2) or delete the simulation policy — no user
impact.

---

## Phase 5 — Enforce in a pilot ring, then expand (Pilot → Enforce)

18. **Scope to the pilot ring.** Add `Fingerprint Pilot Ring – Stage1` as the **included** scope on the
    policy (all other users excluded for now). The delivered scope helper does this safely:
    ```powershell
    .\CLSFINGER-Set-Scope.ps1 -PolicyName "DLP – Fingerprinted Forms – Simulation" `
      -IncludeGroup "Fingerprint Pilot Ring – Stage1" -WhatIf
    ```
    Run with `-Commit` to apply.
19. **Move the ring to enforcement.** Change **Policy mode** from *simulation* to **Turn it on / Enforce**
    (rename the intent to `DLP – Fingerprinted Forms – Enforce Pilot`). Start with **policy tips +
    allow-override (justification)** rather than hard block, so the pilot can report issues while keeping
    a business escape hatch.
20. **Confirm enforcement is live for the ring only** (script #3 reports mode + scope). Confirm a ring
    user sees the `Fingerprint Notice – Standard – AllPolicies` tip on a test match.
21. **Wire incident handling.** Set up `Fingerprint Alerts – Triage – Operations`: assign the alert
    owner/queue (Req 2.7), set severities, and (optionally) forward to SIEM/Sentinel. Triage a real
    pilot alert end-to-end to prove the workflow.
22. **Expand and harden.** Once the pilot gate passes, expand scope from the ring to the full intended
    population, keeping documented exclusions; **escalate the action** per compliance's determination
    (e.g. tip+override → **block**) one form/location at a time, re-validating after each. Schedule the
    reporting script for a recurring review, and **refresh fingerprints** when a form template changes
    (Req 2.5) by adding the new template's fingerprint to the SIT.

**Pass/fail gate:** the ring is enforced (tips shown, overrides captured), matches raise alerts, the
triage workflow produces a dispositioned incident, and scope then expands with the compliance-mandated
action per form. No enforcement outside the ring during pilot.
**Rollback:** set the policy back to **simulation mode** (single setting) — instantly removes enforcement
with no data change; the policy or SIT can be disabled/removed without affecting other DLP policies.

---

## Order-of-operations summary

| Phase | Do | Artifact(s) | Gate | Rollback |
|---|---|---|---|---|
| 0 Assess | Connect, baseline, confirm licensing/roles | Posture CSV | Baseline + readiness confirmed | n/a (read-only) |
| 1 Design | Inventory forms, collect text templates | Form inventory | Every form → fingerprintable template | none (no change) |
| 2 Configure | Create fingerprint(s) + SIT | Fingerprint SIT | SIT exists with form fingerprints | Remove SIT |
| 3 Configure | Build DLP policy in **simulation** | Sim policy + rule | In simulation, references SIT, scoped | Delete sim policy |
| 4 Pilot(sim) | Prove detection, measure FPs | Matches CSV | Form detected, unrelated not, FP ≤ threshold | Re-fingerprint / delete policy |
| 5 Enforce | Ring → tips/override → expand → block | Pilot ring, alert triage | Ring enforced, incident dispositioned, expanded | Back to simulation |
