# 3. Implementation Guide — Custom Sensitive Information Types (Microsoft Purview)

Follow these steps **in order**. Configuration is done in the **Microsoft Purview portal**
(`https://purview.microsoft.com` → **Data classification → Classifiers → Sensitive info types**) and,
where automated, via **Security & Compliance PowerShell** (`Connect-IPPSSession`; the
`DlpSensitiveInformationType*` and **`Test-DataClassification`** cmdlets). Artifact names follow the
`<Purpose> – <Scope> – <Stage>` convention from the Overview and are reused verbatim. **Portal paths,
the rule-package XML schema, and cmdlets are plan-dependent and evolve — verify against your tenant.**

> **Model:** Design the detector, build it, **validate it against known positive/negative samples**,
> pilot it inside a consuming policy in **simulation/test**, tune for precision, then enforce and expand.
> Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce)** — with
> pass/fail gates and rollback. **A SIT only detects — every enforcement action lives in the consuming
> policy, and that policy is piloted in simulation first.** Regulatory/records/legal determinations are
> deferred to the relevant governance functions.

---

## Step 1 — Confirm readiness and inventory existing SITs (Assess)
1. Confirm the role (Requirement 2.3) and that the **Create sensitive info type** option is visible in
   the portal. **Verify entitlement for any downstream consuming capability with Microsoft licensing —
   do not assume.**
2. Run `CLSCUSTOM-Discovery.ps1` (read-only). It confirms `Connect-IPPSSession` + the SIT cmdlets +
   `Test-DataClassification` work, inventories existing **custom** SITs and rule packages (vs built-ins),
   and writes the `Custom SIT Inventory – Evidence` snapshot — so you don't duplicate an existing SIT.
3. **Pass/fail gate:** cmdlets succeed, the role is present, and you have the current SIT inventory and
   the identifier format spec + positive/negative samples (Requirements 2.1, 2.2). Fail → resolve before
   building.

## Step 2 — Design the SIT (Design)
1. With the **data owner** (Requirement 2.6), finalize the design for the running example
   `Custom SIT – Employee ID – Pilot`:
   - **Primary element:** a **regex** for the identifier's structure — e.g. an Employee ID of the form
     `EMP-######` → `\bEMP-\d{6}\b`. (Use a **keyword list** instead for a small fixed vocabulary, or a
     **keyword dictionary** for a large term set — Requirement 2.5.)
   - **Supporting elements:** corroborating keywords that appear near the ID in real documents — e.g.
     `Employee ID`, `Emp ID`, `Emp #`, `Personnel No`.
   - **Character proximity:** the window supporting evidence must fall within (default **300**).
   - **Confidence levels:** define **High (85)** = primary regex **plus** a supporting keyword within
     proximity; **Medium (75)** = the regex plus weaker/looser evidence; optionally **Low (65)** = the
     regex alone. Set the **recommended** confidence to whatever validation proves precise (usually
     High).
2. Record the design; it drives both the portal build and the rule-package XML.

## Step 3 — Create the SIT (Configure — build the detector)
**Option A — Portal (recommended for a first SIT):**
1. Portal → `Data classification → Classifiers → Sensitive info types → Create sensitive info type`.
2. **Name/description:** `Custom SIT – Employee ID – Pilot`, with a clear description.
3. **Add a pattern** at **High** confidence: set the **primary element** (the regex from Step 2), add a
   **supporting element** (the keyword list), and set the **character proximity**. Add a second pattern
   at **Medium** confidence with looser evidence if your design calls for it.
4. Set the **recommended confidence level**, then **Test** (Step 4), review, and **Create**.

**Option B — PowerShell (rule-package XML):**
1. Author the SIT as a **rule package XML** (Entity with `<Pattern confidenceLevel="85">`, an
   `<IdMatch idRef="Regex_EmployeeID"/>`, a supporting `<Match idRef="Keyword_EmployeeID"/>`, the
   `<Regex>` and `<Keyword>` definitions, and a `patternsProximity`). Keep the XML in source control.
2. Import it with `CLSCUSTOM-Configuration.ps1` — it **validates the XML**, prints the planned
   `New-DlpSensitiveInformationTypeRulePackage` (or `Set-…` to update `Custom SIT Rule Package – Pilot`)
   and runs **`-WhatIf` by default**. Add **`-Commit`** to import.
3. **Publishing latency:** a new/updated SIT can take time to become fully available to policies and
   classification — allow for it before concluding a pattern "doesn't work".
4. **Pass/fail gate:** the SIT `Custom SIT – Employee ID – Pilot` exists (portal list or
   `Get-DlpSensitiveInformationType`) with the intended patterns/confidence. **Rollback:** delete the
   SIT / remove the rule package (`Remove-DlpSensitiveInformationTypeRulePackage`) — nothing consumes it
   yet, so blast radius is zero.

## Step 4 — Validate against positive/negative samples (Validate — the precision gate)
1. Run `CLSCUSTOM-Validation.ps1` (read-only). It runs **`Test-DataClassification`** for the SIT against
   every item in `Custom SIT Test – Positive` and `Custom SIT Test – Negative`, comparing the returned
   match/confidence to each item's **expected** result, and writes `Custom SIT Validation – Report`
   (true positives, false positives, false negatives, and the confidence each item returned).
2. Read the report:
   - **False positives** (negatives that matched) → the regex/evidence is too broad → tighten (Step 5).
   - **False negatives** (positives that didn't match) → the regex/proximity/evidence is too tight → loosen.
3. **Pass/fail gate:** positives match at the intended confidence and negatives do **not** match, at a
   rate the data owner accepts. Fail → tune (Step 5) and re-validate. **Do not proceed to a consuming
   policy until this gate passes** — a noisy SIT poisons every policy that later uses it.

## Step 5 — Tune for precision (Validate — iterate)
1. Adjust the **regex** (anchors, character classes, length), the **supporting keywords**, the
   **character proximity**, or the **confidence** design. In PowerShell, edit the rule-package XML and
   re-import with `CLSCUSTOM-Configuration.ps1` (`-WhatIf` then `-Commit`); use
   `CLSCUSTOM-Set-Scope.ps1 -Export` first to **back up** the current rule package XML before changing it.
2. Re-run `CLSCUSTOM-Validation.ps1` after **every** change.
3. **Pass/fail gate:** false positives and negatives are both at a level the data owner accepts. Iterate
   until Step 4's gate passes.

## Step 6 — Pilot inside a consuming policy in SIMULATION/TEST (Pilot)
1. Reference the validated SIT from a **consuming policy** run **without enforcement**:
   - **DLP:** create a DLP policy `Custom SIT DLP – Simulation` whose rule condition is *content contains*
     `Custom SIT – Employee ID – Pilot` at the **recommended** confidence, over a **limited scope**, in
     **test/simulation (policy tips off / no actions)** mode. **Verify simulation/test mode availability
     against your licensing.**
   - **or Auto-labeling:** create an auto-labeling policy in **simulation mode** using the SIT.
2. Let it run over real content and review what it **would** have matched — without blocking, labeling,
   or alerting anyone. Use `CLSCUSTOM-Report.ps1` to list which policies now reference the SIT and the
   simulation results signals available.
3. **Pass/fail gate:** on real traffic the SIT's matches are overwhelmingly true positives and it isn't
   flagging look-alikes. Fail → return to Step 5 (tune the SIT) and/or adjust the policy's confidence
   threshold. **Rollback:** the consuming policy stays in simulation — nothing is enforced; delete or
   leave it disabled at any time.

## Step 7 — Enforce and expand (Expand — enforce)
1. With data-owner and compliance sign-off, promote the consuming policy from simulation to **enforce**
   (`Custom SIT DLP – Enforce`) and **widen scope deliberately** (in rings if large). Use the portal or
   your DLP tooling; the SIT itself is unchanged.
2. **Reuse the SIT** across other capabilities that need it — additional DLP locations (endpoint, email,
   SharePoint/OneDrive, Teams, cloud), **auto-labeling**, **retention** (records/legal *determinations*
   deferred to those functions), **Insider Risk**, **Communication Compliance**, **DSPM** — each new
   consuming policy piloted in **simulation/test first**.
3. Stand up the **maintenance cadence**: review the identifier format as it evolves (new prefixes,
   length changes), re-validate against refreshed samples, and re-run `CLSCUSTOM-Report.ps1` to keep the
   inventory and "where-used" evidence current.
4. **Pass/fail gate:** the consuming policy is enforcing on validated true positives, the SIT is reused
   correctly, and a re-validation/maintenance cadence is scheduled. **Rollback:** revert the consuming
   policy to simulation or disable it; the SIT can stay in place for other (still-simulated) uses.

---

### What this guide does NOT decide
- **Whether the detected data triggers retention, records disposition, or legal hold**, and any
  regulatory applicability — an **records/compliance/legal determination**. This guide builds and
  validates the **detector** and pilots a consuming policy; which governance actions the classification
  drives is decided by those functions.
- **What a DLP/auto-label/Insider-Risk policy *does* on a match** (block, label, retain, alert) — that
  is configured and owned in the consuming policy, not the SIT.
