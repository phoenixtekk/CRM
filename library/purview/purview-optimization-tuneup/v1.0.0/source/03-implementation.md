# 3. Implementation Guide — Microsoft Purview Optimization & Tune-Up

Follow these steps **in order**. Portal navigation is given for the **new Microsoft Purview portal**
(`https://purview.microsoft.com`) and, where a surface still lives there, the **classic compliance
portal** (`https://compliance.microsoft.com`) — surfaces are **actively moving**, so where a path is
version-dependent both are named and you **verify against your current portal**. PowerShell is
**Security & Compliance PowerShell** (`Connect-IPPSSession`) plus **Exchange Online PowerShell**
(`Search-UnifiedAuditLog`, `Get-AdminAuditLogConfig`).

Consoles used:
- **Microsoft Purview portal** — `https://purview.microsoft.com`
- **Classic compliance portal** — `https://compliance.microsoft.com` (fallback for a surface not moved)
- **Security & Compliance PowerShell** — `Connect-IPPSSession`
- **Exchange Online PowerShell** — `Connect-ExchangeOnline` (audit config + unified audit log)

> **Model:** Baseline the noise; design the target thresholds/exceptions/aggregation; move each policy
> **into simulation/test**; tune; **pilot** on `Purview Tuning - Pilot`; validate false positives
> dropped **and** no real detection was lost; then **re-enforce** and schedule health checks.
> **Assess → Design → Configure → Pilot (simulate) → Validate → Expand (enforce).**

> **Artifact names (use verbatim):** pilot scope group `Purview Tuning - Pilot`; evidence/change folder
> `.\OPSOPT-out`; change record label `OPSOPT Tuning Change`. No new policies are created — you tune
> the tenant's existing named objects (substitute your real names for the illustrative
> `PII - Exchange DLP` etc.).

> **Risk + rollback (read first):** Tuning changes are **high-impact** — a wrong threshold can let a
> real leak through, a wrong exception can open a gap, a wrong label can misclassify. Therefore **every**
> change lands in **simulation/test first** (never straight to enforce), is piloted on
> `Purview Tuning - Pilot`, and is validated against the pass/fail gates below. **Rollback:** each script
> records the **prior value** of every setting it changes to `.\OPSOPT-out\rollback-<policy>.json`;
> reverting is re-applying that recorded value (`OPSOPT-Tune.ps1 -Rollback`). Re-enforce
> (`Set-DlpCompliancePolicy -Mode Enable`) is a **separate, approved** step, never bundled with the
> tuning edit. Insider-risk case *outcomes* are HR/legal's — this solution never actions a case.

---

## Phase 1 — Assess (read-only, no changes)

### Step 1 — Baseline the current policy set and its mode
1. Connect: `Connect-IPPSSession` and `Connect-ExchangeOnline`.
2. Run **`OPSOPT-Discovery.ps1`**. It reports, read-only:
   - every **DLP policy** and its **Mode** (`Enable` / `TestWithNotifications` /
     `TestWithoutNotifications` / `Disable`), and each policy's **rules** with their
     sensitive-information-type conditions, **confidence level**, and **instance-count** settings;
   - every **auto-labeling policy** and whether it is in **simulation**;
   - every **alert policy** (`Get-ProtectionAlert`) with its **threshold**, **aggregation type**, and
     notification recipients;
   - the **insider-risk** role/state signals it can read (portal-owned — see Step 9);
   - **`UnifiedAuditLogIngestionEnabled`** state.
3. **Pass/fail gate:** you have a written inventory of every policy, its mode, and its tunable settings.
   If audit ingestion is **False**, resolve it (Requirement 2.4) before expecting meaningful noise data.

### Step 2 — Baseline the noise (the evidence you'll tune against)
1. Run **`OPSOPT-Report.ps1 -Days 30 -OutputFolder .\OPSOPT-out`**. It writes:
   - `dlp-noise-by-rule.csv` — from `Get-DlpDetailReport`: matches per rule, **user overrides**, and
     **reported false positives**, ranked so the noisiest rules surface first;
   - `alert-volume.csv` — from `Search-UnifiedAuditLog` + `Get-ProtectionAlert`: alert counts by policy
     over the window.
2. **Pass/fail gate:** a ranked list of the **top noisy rules/alert policies** exists, with a
   false-positive/override rate per rule — the tuning target set. If the window is empty, enable/await
   audit ingestion (Requirement 2.4) — an empty window is a data gap, not "no noise."

---

## Phase 2 — Design

### Step 3 — Design the target thresholds, exceptions, and aggregation
1. For each **noisy DLP rule**, decide the change from the evidence, **with the data owner** (Req 2.8):
   - raise the **confidence level** (e.g. Medium → High) where low-confidence matches dominate the FPs;
   - raise the **min instance count** where single-instance matches are the noise (e.g. require ≥ 10
     card numbers, not 1);
   - add a justified **`ExceptIf`** condition for a legitimate workflow (sender/recipient/site) — each
     with a named owner and written justification captured in `.\OPSOPT-out`.
2. For each **noisy auto-labeling policy**, decide the tightened SIT conditions to test in simulation.
3. For each **noisy alert policy**, decide the new **threshold** and whether to switch to **aggregated**
   alerting and trim notification recipients.
4. **Do not** design an insider-risk *outcome* — only the indicator/threshold **noise** to reduce
   (Step 9), leaving case verdicts to HR/legal.

### Step 4 — Record the change set and rollback baseline
1. Run **`OPSOPT-Scope-Health.ps1 -OutputFolder .\OPSOPT-out`** to snapshot the **current** value of
   every setting you intend to change (mode, confidence, instance count, threshold, aggregation) into
   `.\OPSOPT-out\rollback-<policy>.json`.
2. **Pass/fail gate:** a rollback baseline exists for every policy in the change set, and the pilot scope
   group `Purview Tuning - Pilot` is populated (Requirement 2.6).

---

## Phase 3 — Configure (governed; simulation first)

### Step 5 — Move each targeted DLP policy into simulation
1. Preview: **`OPSOPT-Tune.ps1 -Policy "PII - Exchange DLP" -ToSimulation -WhatIf`** — shows the mode
   change it *would* make (`Set-DlpCompliancePolicy -Mode TestWithoutNotifications`).
2. When approved under change control: re-run with **`-Commit`**. `TestWithoutNotifications` gathers
   match data **silently** (no user tips/emails) so tuning does not alarm users.
3. **Pass/fail gate:** `Get-DlpCompliancePolicy "PII - Exchange DLP" | Select Mode` shows a **Test**
   mode — the policy is no longer enforcing while you tune.

### Step 6 — Apply the DLP rule tuning (in simulation)
1. Preview: **`OPSOPT-Tune.ps1 -Policy "PII - Exchange DLP" -Rule "PII - High Volume" -MinConfidence
   High -MinCount 10 -WhatIf`** — shows the intended `Set-DlpComplianceRule` change to the
   sensitive-information-type condition.
2. To add a justified exception: **`... -ExceptIfFrom "finance-ap@contoso.com" -Justification "AP mailbox
   handles supplier card refs — owner: Finance Controller" -WhatIf`**.
3. When approved: re-run with **`-Commit`**. The prior values are written to
   `.\OPSOPT-out\rollback-<policy>.json` first.
4. **Pass/fail gate:** `Get-DlpComplianceRule` reflects the new confidence/instance/exception, and the
   rollback file records the prior values.

### Step 7 — Put noisy auto-labeling into simulation and tighten
1. Preview then commit: **`OPSOPT-Tune.ps1 -AutoLabelPolicy "Auto - Confidential" -ToSimulation
   -WhatIf`** → `-Commit` (`Set-AutoSensitivityLabelPolicy -Mode TestWithoutNotifications`).
2. In the portal, open **Purview portal → Information Protection → Auto-labeling → <policy> →
   Simulation** and review **what would be labeled** with the tightened conditions — **verify against
   your current portal** if the menu differs. Nothing is labeled while in simulation.
3. **Pass/fail gate:** the auto-labeling policy is in **simulation** and the simulation preview shows
   the over-labeling reduced (fewer wrong candidates) without dropping the content that *should* be
   labeled.

### Step 8 — Tune noisy alert policies
1. Preview: **`OPSOPT-Tune.ps1 -AlertPolicy "Elevated DLP activity" -Threshold 25 -Aggregation
   SimpleAggregation -WhatIf`** — shows the intended `Set-ProtectionAlert` change.
2. When approved: re-run with **`-Commit`** (records prior threshold/aggregation for rollback).
3. **Pass/fail gate:** `Get-ProtectionAlert "Elevated DLP activity"` shows the raised threshold /
   aggregated mode; recipient list trimmed to those who act on it.

### Step 9 — Tune insider-risk noise in the portal (role-separated, privacy-by-design)
1. As the **separate Insider Risk Management** role holder (Requirement 2.3), open **Purview portal →
   Insider Risk Management → Policies → <policy>** — **verify against your current portal**.
2. Reduce noise by the portal-supported levers only: **de-select low-value indicators**, **raise the
   triggering-event threshold / lengthen the window**, and confirm **privacy settings**
   (**pseudonymization / anonymization on** where available) so tuning does not expose identities.
3. **This is portal-driven — no IRM configuration cmdlets are invented here.** Capture the before/after
   settings as evidence in `.\OPSOPT-out`.
4. **Pass/fail gate:** the policy's noisy indicators are trimmed, privacy settings confirmed, and role
   separation intact. **Any case outcome is HR/legal's** — this step tunes signal only, never a verdict.

---

## Phase 4 — Pilot & Validate

### Step 10 — Pilot the tuned policies on `Purview Tuning - Pilot`
1. Ensure the tuned DLP/label policies are scoped to include `Purview Tuning - Pilot` (locations/users).
2. Let the simulation run over an agreed observation window so fresh match data accrues under the new
   settings.
3. Re-run **`OPSOPT-Report.ps1 -Days <window> -OutputFolder .\OPSOPT-out`** and compare
   `dlp-noise-by-rule.csv` before vs after.

### Step 11 — Validate the reduction against pass/fail gates
1. Run **`OPSOPT-Validation.ps1 -OutputFolder .\OPSOPT-out`**. It checks and reports PASS/FAIL for:
   - each tuned policy is currently in a **Test/simulation** mode (nothing was enforced blind);
   - the **false-positive / override rate** for each tuned rule **dropped** vs the Step 2 baseline;
   - a **known-true-positive probe** (a seeded/known-sensitive sample, or a labeled prior true match)
     **still matches** — proving tuning removed noise, **not** signal;
   - alert-policy thresholds/aggregation are applied; rollback baselines exist.
2. **Gate:** false positives **down** **and** the true-positive probe **still fires** for every tuned
   policy, or the change is **rolled back** (`OPSOPT-Tune.ps1 -Rollback`). Never re-enforce a policy that
   failed the true-positive probe.

---

## Phase 5 — Expand (enforce) & Operate

### Step 12 — Re-enforce the validated policies (separate, approved step)
1. For each policy that **passed** Step 11, under change control: **`OPSOPT-Tune.ps1 -Policy "PII -
   Exchange DLP" -Enforce -WhatIf`** → **`-Commit`** (`Set-DlpCompliancePolicy -Mode Enable`); take
   auto-labeling out of simulation to **On** in the portal.
2. **Pass/fail gate:** `Get-DlpCompliancePolicy | Select Name,Mode` shows the tuned policies back at
   **Enable**, now with the noise removed; alert policies notifying only on the raised thresholds.

### Step 13 — Schedule recurring health checks
1. Schedule **`OPSOPT-Report.ps1`** (e.g. weekly) to track the false-positive/noise trend over time.
2. Schedule **`OPSOPT-Scope-Health.ps1`** (e.g. weekly) to catch **drift** — a policy re-enforced
   without pilot, a threshold reverted, a new noisy rule, or simulation left on too long.
3. Review the trend with compliance/security/HR on a cadence. **Determinations** arising (a new
   exception's acceptability, whether an insider-risk pattern is real) are **routed to the owning
   governance function** — this solution reduces the noise and evidences it; it does not rule.
