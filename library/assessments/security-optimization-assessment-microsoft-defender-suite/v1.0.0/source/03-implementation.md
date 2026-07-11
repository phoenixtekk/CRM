# 3. Implementation — Security Optimization Assessment: Microsoft Defender (Suite / XDR)

This is the exact, ordered procedure to run the suite assessment end to end. It is **read-only** — you enumerate configuration, score it, and produce a findings report; you change nothing in the tenant.

**Naming convention.** Every artifact you create uses `<Purpose> – <Scope> – <Stage>`. Use these exact names in the scripts, testing, and the report:
- Assessment scope record → **`SOA Scope – Defender Suite – Assess`**
- Baseline configuration snapshot → **`Posture Baseline – Defender Suite – Assess`**
- Posture score record → **`Posture Score – Defender Suite – Pilot`**
- Prioritized findings report → **`Findings Report – Defender Suite – Validate`**

> Placeholders use `contoso.onmicrosoft.com`. Substitute your tenant. Confirm the prerequisites in Section 2 and the Global Requirements before starting.

## Stage 1 — Assess (define scope and capture the baseline)

### Step 1.1 — Record the assessment scope
1. Open a working document named **`SOA Scope – Defender Suite – Assess`**.
2. Record: the tenant, which of the five pillars are in scope (and any marked not-applicable, e.g. no Azure → cloud pillar N/A), the **run date**, and the **best-practice reference baseline** (Global Requirements G6 — *verify current Microsoft guidance*).
3. Confirm your account has **Security Reader** / **Global Reader**, the Graph read scopes, and Az access (Section 2, R3/R4/R5).

### Step 1.2 — Sign in and confirm the suite
1. Browse to `https://security.microsoft.com`; confirm **Incidents**, **Secure score**, and **Settings** load (R1).
2. Note under **Settings → Permissions & roles** whether **Unified RBAC** is activated (R3).

### Step 1.3 — Capture the configuration baseline (read-only)
1. Open PowerShell in the `scripts/` folder.
2. Connect read-only:
   ```powershell
   Connect-MgGraph -Scopes "SecurityEvents.Read.All","RoleManagement.Read.Directory","Directory.Read.All"
   Connect-AzAccount
   ```
3. Run discovery and save the snapshot as the baseline:
   ```powershell
   .\SOAXDR-Discovery.ps1 -OutputPath ".\Posture Baseline - Defender Suite - Assess.json"
   ```
4. This enumerates per-pillar onboarding/licensing signal, unified-RBAC role assignments, incident/correlation evidence, and Microsoft Secure Score. It **makes no changes**. Keep the JSON as **`Posture Baseline – Defender Suite – Assess`**.

## Stage 2 — Configure (set the scoring reference)

### Step 2.1 — Confirm the four assessment domains and weights
1. The scoring model covers: **cross-pillar coverage**, **unified RBAC**, **incident correlation**, and **suite-wide Secure Score**.
2. Review the default weights in `SOAXDR-Score.ps1` (documented in its header). If the security owner wants a different emphasis, record it in **`SOA Scope – Defender Suite – Assess`** so runs stay comparable.

### Step 2.2 — Validate that best-practice controls are present (read-only)
1. Run the control validation, passing which pillars you confirmed onboarded and whether unified RBAC is on:
   ```powershell
   .\SOAXDR-Validate.ps1 -BaselinePath ".\Posture Baseline - Defender Suite - Assess.json" `
       -PillarsOnboarded @('endpoint','identity','email','cloudapps','cloud') `
       -UnifiedRbacActivated $true -OutputPath ".\SOAXDR-validation.json"
   ```
2. This checks, per domain, whether the recommended controls exist (all in-scope pillars onboarded; unified RBAC activated with least-privilege roles; incidents correlating cross-pillar; Secure Score above a floor). Each check returns **Pass / Gap** with evidence — it fixes nothing.

## Stage 3 — Pilot (score the posture)

### Step 3.1 — Audit unified RBAC
1. Run the RBAC audit (read-only):
   ```powershell
   .\SOAXDR-RBACAudit.ps1 -OutputPath ".\rbac-audit.json"
   ```
2. This enumerates privileged directory-role assignments relevant to the Defender suite and flags broad/over-privileged assignments — the evidence behind the unified-RBAC domain.

### Step 3.2 — Compute the posture score
1. Run the scorer against the validation output:
   ```powershell
   .\SOAXDR-Score.ps1 -ValidationPath ".\SOAXDR-validation.json" -OutputPath ".\Posture Score - Defender Suite - Pilot.json"
   ```
2. This produces per-domain scores and an overall suite posture score, saved as **`Posture Score – Defender Suite – Pilot`**. Scoring is deterministic. Record the run date.

## Stage 4 — Validate (produce and review the findings report)

### Step 4.1 — Generate the prioritized findings report
1. Run the report generator (add `-PriorReportPath` on re-runs for drift):
   ```powershell
   .\SOAXDR-Report.ps1 -ValidationPath ".\SOAXDR-validation.json" -ScorePath ".\Posture Score - Defender Suite - Pilot.json" -RBACAuditPath ".\rbac-audit.json" -OutputPath ".\Findings Report - Defender Suite - Validate.json"
   ```
2. The report lists every finding with its **domain**, **severity**, **risk rank**, **evidence**, and a **remediation pointer** to the Remediation Playbook (and, where a pillar needs a deep dive, a pointer to that pillar's assessment), plus **drift**.

### Step 4.2 — Review with the security owner
1. Walk through **`Findings Report – Defender Suite – Validate`** with the named security owner.
2. The owner confirms **risk-acceptance** and **remediation priority** (their decisions). Record accepted-risk items with justification and expiry.
3. Store the report securely (Global Requirements G7).

## Stage 5 — Expand (broaden scope and trend)

### Step 5.1 — Widen the scope and re-run
1. Expand **`SOA Scope – Defender Suite – Assess`** to additional pillars/roles/subscriptions as they onboard.
2. Re-run Steps 1.3 → 4.1. With the prior baseline retained, `SOAXDR-Report.ps1` shows the **drift** since the last run.

### Step 5.2 — Hand off and schedule
1. Hand **`Findings Report – Defender Suite – Validate`** to the **Remediation Playbook** to close the gaps pilot-first; use the per-pillar deep-dive assessments where a pillar needs its own review.
2. Schedule the assessment on a cadence (for example quarterly) so the suite Secure Score and coverage trend over time.

> Everything above is read-only. If any script attempts a write or requests a write scope/role, stop — it should not.
