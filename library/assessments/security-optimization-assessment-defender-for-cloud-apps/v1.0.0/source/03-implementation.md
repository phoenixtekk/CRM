# 3. Implementation — Security Optimization Assessment: Defender for Cloud Apps

This is the exact, ordered procedure to run the assessment end to end. It is **read-only** — you enumerate configuration, score it, and produce a findings report; you change nothing in the tenant.

**Naming convention.** Every artifact you create in this run uses `<Purpose> – <Scope> – <Stage>`. Use these exact names in the scripts, testing, and the findings report:
- Assessment scope record → **`SOA Scope – Cloud Apps – Assess`**
- Baseline configuration snapshot → **`Posture Baseline – Cloud Apps – Assess`**
- Posture score record → **`Posture Score – Cloud Apps – Pilot`**
- Prioritized findings report → **`Findings Report – Cloud Apps – Validate`**

> Placeholders use `contoso.onmicrosoft.com`. Substitute your tenant. Confirm the prerequisites in Section 2 and the Global Requirements before starting.

## Stage 1 — Assess (define scope and capture the baseline)

### Step 1.1 — Record the assessment scope
1. Open a working document named **`SOA Scope – Cloud Apps – Assess`**.
2. Record: the tenant (`contoso.onmicrosoft.com`), which apps/connectors are in scope, which user population, the **run date**, and the **best-practice reference baseline** you will score against (per Global Requirements G6 — *verify against current Microsoft guidance*).
3. Confirm your account has **Security Reader**/**Global Reader** and the Graph read scopes (Section 2, R3/R4).

### Step 1.2 — Sign in and confirm the service
1. Browse to `https://security.microsoft.com` and sign in.
2. Go to **Cloud apps → Cloud discovery**. Confirm the dashboard loads (service is provisioned — R1).
3. Note whether **App governance** appears under **Cloud apps** (licensing — R2).

### Step 1.3 — Capture the configuration baseline (read-only)
1. Open PowerShell in the `scripts/` folder.
2. Connect read-only:
   ```powershell
   Connect-MgGraph -Scopes "SecurityEvents.Read.All","Application.Read.All","Directory.Read.All"
   ```
3. Run discovery and save the snapshot as the baseline:
   ```powershell
   .\SOAMCA-Discovery.ps1 -OutputPath ".\Posture Baseline - Cloud Apps - Assess.json"
   ```
4. This enumerates connectors, discovery data sources, the policy inventory (app-governance/OAuth, session, access, activity, file, anomaly), and alert state. It **makes no changes**. Keep the JSON as **`Posture Baseline – Cloud Apps – Assess`**.

## Stage 2 — Configure (set the scoring reference)

### Step 2.1 — Confirm the four assessment domains and weights
1. The scoring model covers: **connector & discovery coverage**, **app-governance & OAuth policies**, **session & access policies**, and **alert hygiene**.
2. Review the default weights in `SOAMCA-Score.ps1` (documented in its header). If your security owner wants a different emphasis (for example, weighting OAuth risk higher), record the change in **`SOA Scope – Cloud Apps – Assess`** so runs stay comparable.

### Step 2.2 — Validate that best-practice controls are present (read-only)
1. Run the control validation, supplying the values you confirmed in the portal for the manual checks (app governance on/off, policy counts, discovery ingestion method, alert tuning):
   ```powershell
   .\SOAMCA-Validate.ps1 -BaselinePath ".\Posture Baseline - Cloud Apps - Assess.json" `
       -AppGovernanceEnabled $true -OAuthPolicyCount 2 -SessionPolicyCount 1 -AccessPolicyCount 1 `
       -DiscoveryIngestion continuous -AlertPoliciesTuned $true -OutputPath ".\SOAMCA-validation.json"
   ```
2. This checks, for each domain, whether the recommended controls exist (core apps connected; continuous discovery ingestion; app governance enabled with OAuth policies; at least one session and one access policy; alert policies tuned and being resolved). Each check returns **Pass / Gap** with the evidence — it does not fix anything. It writes `SOAMCA-validation.json`.

## Stage 3 — Pilot (score the posture on the defined scope)

### Step 3.1 — Deep-audit OAuth / app governance
1. Run the OAuth app audit:
   ```powershell
   .\SOAMCA-OAuthAudit.ps1 -OutputPath ".\oauth-audit.json"
   ```
2. This enumerates OAuth application grants and flags over-permissioned scopes, unverified publishers, and dormant high-privilege apps — the evidence behind the app-governance domain. Read-only.

### Step 3.2 — Compute the posture score
1. Run the scorer against the validation output:
   ```powershell
   .\SOAMCA-Score.ps1 -ValidationPath ".\SOAMCA-validation.json" -OutputPath ".\Posture Score - Cloud Apps - Pilot.json"
   ```
2. This produces per-domain scores and an overall posture score, saved as **`Posture Score – Cloud Apps – Pilot`**. Record the run date. (Scoring is deterministic — the same input always yields the same score.)

## Stage 4 — Validate (produce and review the findings report)

### Step 4.1 — Generate the prioritized findings report
1. Run the report generator (add `-PriorReportPath` on re-runs to show drift):
   ```powershell
   .\SOAMCA-Report.ps1 -ValidationPath ".\SOAMCA-validation.json" -ScorePath ".\Posture Score - Cloud Apps - Pilot.json" -OAuthAuditPath ".\oauth-audit.json" -OutputPath ".\Findings Report - Cloud Apps - Validate.json"
   ```
2. The report lists every finding with its **domain**, **severity**, **risk rank** (severity × exposure), the **evidence**, and a **pointer to the remediation** (which Remediation Playbook section closes it). It also compares to any prior saved baseline to show **drift**.

### Step 4.2 — Review with the security owner
1. Walk through **`Findings Report – Cloud Apps – Validate`** with the named security owner.
2. The owner confirms **risk-acceptance** and **remediation priority** — these are their decisions, not the assessment's. Record any accepted-risk items with justification and expiry.
3. Store the report securely (Global Requirements G7) — it is sensitive.

## Stage 5 — Expand (broaden scope and trend)

### Step 5.1 — Widen the scope and re-run
1. Expand **`SOA Scope – Cloud Apps – Assess`** to include additional apps/users.
2. Re-run Steps 1.3 → 4.1. Because you kept the prior baseline, `SOAMCA-Report.ps1` will show the **drift** (improvement or regression) since the last run.

### Step 5.2 — Hand off to remediation and schedule the re-run
1. Hand **`Findings Report – Cloud Apps – Validate`** to the **Remediation Playbook for Defender Security Optimization Assessments** to close the gaps pilot-first.
2. Schedule the assessment to re-run on a cadence (for example quarterly) so the posture score trends over time.

> Everything above is read-only. If any script reports a write attempt or requests a write scope, stop — it should not, and that would be a defect.
