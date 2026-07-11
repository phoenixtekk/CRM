# 3. Implementation — Remediation Playbook for Defender Security Optimization Assessments

This is the exact, ordered procedure to remediate an assessment finding end to end — **pilot-first, preview-gated, verified, re-scored**. Unlike the assessments, this playbook **makes changes**; every change is previewed with `-WhatIf` / simulation, applied to a pilot scope first, and carries a rollback.

**Naming convention.** Every artifact you create uses `<Purpose> – <Scope> – <Stage>`. Use these exact names in the scripts, testing, and the evidence report:
- Remediation plan record → **`Remediation Plan – Defender SOA – Assess`**
- Pilot scope definition → **`Pilot Scope – Defender SOA – Pilot`**
- Pre-change score baseline → **`Rescore Baseline – Defender SOA – Assess`**
- Post-change re-score → **`Rescore Result – Defender SOA – Validate`**
- Remediation evidence report → **`Evidence Report – Defender SOA – Validate`**

> Placeholders use `contoso.onmicrosoft.com` and a pilot group. Substitute yours. Confirm the prerequisites in Section 2 (including change-approval R2 and pilot/rollback R3) before applying anything.

## The finding-to-remediation map
Each finding category maps to a remediation and its gating. **All are pilot-first and preview-gated; disruptive/response actions are additionally approval-gated.**

| Product | Finding category | Remediation (pilot-first, `-WhatIf`/simulate first) | Extra gate |
|---|---|---|---|
| Cloud Apps | Connector/discovery coverage | Connect the missing app / enable continuous log upload or MDE integration | — |
| Cloud Apps | App-governance/OAuth | Enable app governance; create OAuth-app policy for risky consent | approval (may block apps) |
| Cloud Apps | Session/access policies | Create Conditional Access App Control session/access policy in **monitor** first | approval (can block users) |
| Cloud Apps | Alert hygiene | Tune alert policy severity/scope/exclusions; retire duplicates | — |
| Cloud | Secure Score recommendations | Apply the recommendation's Fix on the pilot subscription | — |
| Cloud | Plan coverage | Enable the workload plan on the pilot subscription | approval (has cost) |
| Cloud | Regulatory compliance | Map the required standard to the compliance dashboard | — |
| Cloud | Agent/agentless coverage | Enable agentless scanning / onboard the agent on the pilot scope | approval (has cost) |
| Endpoint | Onboarding/ASR/EDR | Onboard pilot devices; enable ASR rules in **audit** first | approval (audit→block) |
| Identity | Sensor/health/detections | Deploy/repair sensors on a pilot DC; resolve health alerts | — |
| Office 365 | Anti-phish/Safe Links/Attachments | Apply preset security policy / tighten policy on a pilot group | approval (mail impact) |
| Suite/XDR | Cross-pillar coverage | Onboard the dark pillar (points to its onboarding solution) | approval |
| Suite/XDR | Unified RBAC | Activate unified RBAC; assign least-privilege roles to a pilot | approval (access change) |
| Suite/XDR | Incident correlation | Ensure pillars feed signal (downstream of coverage) | — |

## Stage 1 — Assess (ingest the finding and record the plan)

### Step 1.1 — Ingest the findings (read-only)
1. Open PowerShell in `scripts/`. Connect read-only:
   ```powershell
   Connect-MgGraph -Scopes "SecurityEvents.Read.All","Directory.Read.All"
   ```
2. Ingest the assessment's findings report:
   ```powershell
   .\SOAREM-Discovery.ps1 -FindingsReportPath ".\Findings Report - Cloud Apps - Validate.json" -OutputPath ".\Remediation Plan - Defender SOA - Assess.json"
   ```
3. This reads the ranked findings, maps each to its remediation (per the map above), and writes **`Remediation Plan – Defender SOA – Assess`**. Read-only.

### Step 1.2 — Capture the pre-change score baseline
1. Re-run the relevant assessment score (or copy its last score) and save it as **`Rescore Baseline – Defender SOA – Assess`** — this is the "before" you will prove you improved.

## Stage 2 — Configure (plan the fix and the pilot)

### Step 2.1 — Define the pilot scope
1. Record the pilot scope in **`Pilot Scope – Defender SOA – Pilot`**: the pilot group/subscription/policy, the break-glass exclusion, the change window, and the rollback step for this finding (R3).
2. Confirm change-approval (R2) covers this finding and scope.

### Step 2.2 — Preview the change (`-WhatIf` — touches nothing)
1. Run the remediation in **preview** mode (the default — no `-Apply`):
   ```powershell
   .\SOAREM-Remediate.ps1 -RemediationPlanPath ".\Remediation Plan - Defender SOA - Assess.json" -FindingId "<finding id>" -PilotScope "Pilot Group - Defender SOA" -WhatIf
   ```
2. Read exactly what *would* change. Nothing is applied. If it looks wrong, stop and adjust the plan.

## Stage 3 — Pilot (apply to the pilot scope, gated)

### Step 3.1 — Apply to the pilot only
1. With approval in hand and the preview reviewed, apply to the **pilot scope**:
   ```powershell
   .\SOAREM-Remediate.ps1 -RemediationPlanPath ".\Remediation Plan - Defender SOA - Assess.json" -FindingId "<finding id>" -PilotScope "Pilot Group - Defender SOA" -Apply
   ```
2. The script requires the explicit `-Apply` switch and, for **approval-gated** categories (blocking policies, response actions, paid plans), an additional `-ConfirmDisruptive` acknowledgement. For monitor-capable controls (session/access, ASR), it applies in **monitor/audit** mode first.
3. Keep the break-glass account excluded (R3).

## Stage 4 — Validate (verify the control, then re-score)

### Step 4.1 — Verify the specific control
1. Run the post-change validation:
   ```powershell
   .\SOAREM-Validate.ps1 -RemediationPlanPath ".\Remediation Plan - Defender SOA - Assess.json" -FindingId "<finding id>" -OutputPath ".\SOAREM-validation.json"
   ```
2. This confirms the specific control is now correct on the pilot scope (e.g. the OAuth policy exists, the plan is on, the session policy is in monitor). Read-only.

### Step 4.2 — Re-score to prove closure
1. Re-run the relevant assessment score and compare to the pre-change baseline:
   ```powershell
   .\SOAREM-Rescore.ps1 -BaselinePath ".\Rescore Baseline - Defender SOA - Assess.json" -OutputPath ".\Rescore Result - Defender SOA - Validate.json"
   ```
2. The re-score is the **objective proof** the finding closed — the domain/overall score should rise. If it did not move, the fix did not take (see Troubleshooting).

## Stage 5 — Expand (stage the rollout and evidence it)

### Step 5.1 — Expand the change in stages
1. With the pilot verified and re-scored, expand the change across scope in stages — for monitor-capable controls, move from **monitor/audit** to **enforce** only after the pilot is clean.
2. Keep the rollback ready at each stage; keep break-glass excluded.

### Step 5.2 — Produce the evidence report
1. Generate the change-tracked evidence report:
   ```powershell
   .\SOAREM-Report.ps1 -RemediationPlanPath ".\Remediation Plan - Defender SOA - Assess.json" -ValidationPath ".\SOAREM-validation.json" -RescorePath ".\Rescore Result - Defender SOA - Validate.json" -OutputPath ".\Evidence Report - Defender SOA - Validate.json"
   ```
2. **`Evidence Report – Defender SOA – Validate`** records each finding, what changed, when, by whom, the pilot→enforce stage, and the before/after score — the auditable proof the backlog closed. Store it securely (R7).

> Every change above is preview/`-WhatIf` first, pilot-first, and reversible. If any remediation cannot be previewed, do not apply it — stop and review.
