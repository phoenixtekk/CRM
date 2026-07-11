# 3. Implementation — Security Optimization Assessment: Defender for Cloud

This is the exact, ordered procedure to run the assessment end to end. It is **read-only** — you enumerate configuration, score it, and produce a findings report; you change nothing in the environment.

**Naming convention.** Every artifact you create uses `<Purpose> – <Scope> – <Stage>`. Use these exact names in the scripts, testing, and the report:
- Assessment scope record → **`SOA Scope – Defender for Cloud – Assess`**
- Baseline configuration snapshot → **`Posture Baseline – Defender for Cloud – Assess`**
- Posture score record → **`Posture Score – Defender for Cloud – Pilot`**
- Prioritized findings report → **`Findings Report – Defender for Cloud – Validate`**

> Placeholders use `contoso.onmicrosoft.com` and a pilot subscription id. Substitute yours. Confirm the prerequisites in Section 2 and the Global Requirements before starting.

## Stage 1 — Assess (define scope and capture the baseline)

### Step 1.1 — Record the assessment scope
1. Open a working document named **`SOA Scope – Defender for Cloud – Assess`**.
2. Record: the tenant, the **pilot subscription** and any others in scope, the required compliance standard(s) (per R5), the **run date**, and the **best-practice reference baseline** (Global Requirements G6 — *verify current Microsoft guidance*).
3. Confirm your account has **Security Reader** + **Reader** and the Az modules (Section 2, R2/R3).

### Step 1.2 — Sign in and confirm the service
1. Run `Connect-AzAccount` and `Set-AzContext -Subscription '<pilot subscription id>'`.
2. In the portal, open **Microsoft Defender for Cloud → Environment settings** and confirm the pilot subscription appears (service registered — R1).

### Step 1.3 — Capture the configuration baseline (read-only)
1. Open PowerShell in the `scripts/` folder.
2. Run discovery and save the snapshot as the baseline:
   ```powershell
   .\SOAMDC-Discovery.ps1 -SubscriptionId '<pilot subscription id>' -OutputPath ".\Posture Baseline - Defender for Cloud - Assess.json"
   ```
3. This enumerates plan tiers, Secure Score, registered providers, Log Analytics workspaces, agentless-scanning state, and any AWS/GCP connectors. It **makes no changes**. Keep the JSON as **`Posture Baseline – Defender for Cloud – Assess`**.

## Stage 2 — Configure (set the scoring reference)

### Step 2.1 — Confirm the four assessment domains and weights
1. The scoring model covers: **Secure Score & recommendations**, **plan coverage**, **regulatory compliance posture**, and **agent/agentless coverage**.
2. Review the default weights in `SOAMDC-Score.ps1` (documented in its header). If the security owner wants a different emphasis, record it in **`SOA Scope – Defender for Cloud – Assess`** so runs stay comparable.

### Step 2.2 — Validate that best-practice controls are present (read-only)
1. Run the control validation:
   ```powershell
   .\SOAMDC-Validate.ps1 -BaselinePath ".\Posture Baseline - Defender for Cloud - Assess.json" -RequiredStandard "Microsoft cloud security benchmark" -OutputPath ".\SOAMDC-validation.json"
   ```
2. This checks, per domain, whether the recommended controls exist (Secure Score above a floor with recommendations being worked; the workload plans on for the subscription; the required compliance standard mapped; agentless scanning enabled). Each check returns **Pass / Gap** with evidence — it fixes nothing.

## Stage 3 — Pilot (score the posture on the pilot subscription)

### Step 3.1 — Analyze plan and agent/agentless coverage
1. Run the coverage analysis (Azure Resource Graph KQL, read-only):
   ```powershell
   .\SOAMDC-Coverage.ps1 -SubscriptionId '<pilot subscription id>' -OutputPath ".\coverage.json"
   ```
2. This reports which resource types have a matching plan enabled and which machines are/are not covered by agentless scanning — the evidence behind the plan-coverage and agent/agentless domains.

### Step 3.2 — Compute the posture score
1. Run the scorer against the validation output:
   ```powershell
   .\SOAMDC-Score.ps1 -ValidationPath ".\SOAMDC-validation.json" -OutputPath ".\Posture Score - Defender for Cloud - Pilot.json"
   ```
2. This produces per-domain scores and an overall posture score, saved as **`Posture Score – Defender for Cloud – Pilot`**. Scoring is deterministic. Record the run date.

## Stage 4 — Validate (produce and review the findings report)

### Step 4.1 — Generate the prioritized findings report
1. Run the report generator (add `-PriorReportPath` on re-runs for drift):
   ```powershell
   .\SOAMDC-Report.ps1 -ValidationPath ".\SOAMDC-validation.json" -ScorePath ".\Posture Score - Defender for Cloud - Pilot.json" -CoveragePath ".\coverage.json" -OutputPath ".\Findings Report - Defender for Cloud - Validate.json"
   ```
2. The report lists every finding with its **domain**, **severity**, **risk rank**, **evidence**, and a **remediation pointer** to the Remediation Playbook, plus **drift** versus any prior baseline.

### Step 4.2 — Review with the security owner
1. Walk through **`Findings Report – Defender for Cloud – Validate`** with the named security owner.
2. The owner confirms **risk-acceptance** and **remediation priority** (their decisions). Record accepted-risk items with justification and expiry. Note that enabling paid plans has a cost the customer accepts.
3. Store the report securely (Global Requirements G7).

## Stage 5 — Expand (broaden scope and trend)

### Step 5.1 — Widen the scope and re-run
1. Expand **`SOA Scope – Defender for Cloud – Assess`** to additional subscriptions/management groups and AWS/GCP connectors.
2. Re-run Steps 1.3 → 4.1. With the prior baseline retained, `SOAMDC-Report.ps1` shows the **drift** since the last run.

### Step 5.2 — Hand off to remediation and schedule the re-run
1. Hand **`Findings Report – Defender for Cloud – Validate`** to the **Remediation Playbook** to close the gaps pilot-first.
2. Schedule the assessment on a cadence (for example quarterly) so the Secure Score and coverage trend over time.

> Everything above is read-only. If any script attempts a write or requests a write role, stop — it should not.
