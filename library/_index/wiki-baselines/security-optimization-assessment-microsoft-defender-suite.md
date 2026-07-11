# Security Optimization Assessment — Microsoft Defender (Suite / XDR)

> **Version 1.0.0** · Category: Assessments · Solution code: SOAXDR

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Security Optimization Assessment: Microsoft Defender (Suite / XDR)

**White-label · Assessments**

A deployed product is not an optimized one — and a *suite* multiplies the problem. Microsoft Defender XDR ties together five pillars — **endpoint, identity, email/collaboration, cloud apps, and cloud** — into one portal, one incident queue, and one unified role model. In most tenants some pillars are fully onboarded, others barely; **unified RBAC** is unconfigured so people over- or under-see; **incident correlation** is weak because a pillar isn't feeding signal; and the **suite-wide Secure Score** stagnates. This **Security Optimization Assessment** takes a **read-only** look across the whole suite, scores it against Microsoft's recommended baseline, and hands you a **prioritized, risk-ranked findings report** telling you what to fix, in what order.

This package is written for an administrator with no prior assessment experience. It is **read-only by design** — every script observes and reports via **Microsoft Graph (Security)** and **Az**; **none change your tenant**. The paired remediation work (closing the gaps) is a separate, pilot-first effort delivered by the **Remediation Playbook for Defender Security Optimization Assessments**.

## What you get
- A plain-language **Solution Overview** of Microsoft Defender XDR, the four assessment domains (cross-pillar coverage, unified RBAC, incident correlation, suite-wide Secure Score), and the scoring model.
- A **Requirements Guide** with verify / implement-if-missing for every solution-specific prerequisite (category-wide prerequisites live once in the Global Requirements).
- An **Implementation Guide** of exact, ordered steps to run the assessment end to end — enumerate, score, and report — following **Assess → Configure → Pilot → Validate → Expand**.
- Five **PowerShell scripts** (Graph / Security + Az) — all **read-only** — for discovery, control validation, suite-wide posture scoring, a unified-RBAC audit, and the prioritized findings report with drift versus a saved baseline.
- **Testing** and **Troubleshooting** guides so the run is repeatable and trustworthy.

## What this delivers
A **scored, evidence-backed picture** of your Defender suite posture: which of the five pillars are onboarded and licensed, whether unified RBAC is configured to least privilege, whether incidents are correlating across pillars, and where the suite-wide Secure Score leaks points. The output is a **prioritized remediation backlog** — highest-risk gaps first — ready to hand to the Remediation Playbook.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand** — assess the current suite configuration, produce and validate the findings, then expand scope (more pillars/roles) and re-run to trend the score.

## Boundary
This assessment supplies **the evidence and the technical score**, not the authorization. **Risk-acceptance** of any finding, **remediation priority** in your context, and any **regulatory / records / incident-response** determination are the customer's security, compliance, and SOC functions' decisions. Licensing, plan, and preview facts are flagged **verify** — confirm current availability in your tenant.

## Effort
A competent administrator can run the full suite assessment in a focused engagement. It is **repeatable** — re-run on a schedule to trend the posture score as pillars are onboarded and RBAC matures.


---


# 1. Solution Overview — Security Optimization Assessment: Microsoft Defender (Suite / XDR)

## What Microsoft Defender XDR is
Microsoft Defender XDR is the **unified security suite** in the Microsoft Defender portal (`security.microsoft.com`). It brings five protection pillars into one experience:

- **Endpoint** — Microsoft Defender for Endpoint (device onboarding, EDR, vulnerability management).
- **Identity** — Microsoft Defender for Identity (on-prem AD / Entra identity threat detection).
- **Email & collaboration** — Microsoft Defender for Office 365 (EOP + MDO: anti-phish, Safe Links/Attachments).
- **Cloud apps** — Microsoft Defender for Cloud Apps (CASB — connectors, session/OAuth policies).
- **Cloud** — Microsoft Defender for Cloud (Azure/multicloud workload and posture signal surfaced into XDR).

On top of the pillars, XDR provides:
- **Unified incidents** — alerts from all pillars are **correlated** into a single incident with an end-to-end attack story.
- **Unified RBAC** — one role model (the Microsoft Defender XDR Unified role-based access control) that governs who can see and act across the pillars, replacing per-product permission silos.
- **Suite-wide Microsoft Secure Score** — a single posture score spanning the identity, device, apps, and data controls across the suite.

## Why this assessment matters
A suite is only as strong as its weakest pillar and its glue. Common gaps: endpoint is onboarded but identity sensors are not, so lateral-movement detections never fire; email protection runs on default policies; cloud apps is on but unconnected; unified RBAC is left at legacy per-product roles so analysts either can't see across the incident or can see far too much; and the suite Secure Score plateaus because nobody works it. **None of this is visible from the incident queue** — you have to **enumerate onboarding/licensing per pillar, the RBAC model, incident-correlation settings, and the Secure Score, compare to the recommended baseline, and score it**.

That is what this assessment does. It is **read-only** — it changes nothing — and produces a **prioritized, risk-ranked findings report** across the four domains so remediation goes to the highest-risk gaps first. Because the sibling assessments (**Defender for Cloud Apps** and **Defender for Cloud**) go deep on their pillars, this suite assessment focuses on **cross-pillar coverage and the glue** and points to those deep-dive assessments where a pillar needs its own review.

## The four assessment domains and how they are scored
1. **Cross-pillar coverage** — Are all five pillars **onboarded and licensed**? Endpoint devices onboarded, identity sensors deployed, MDO policies present, cloud-apps connected, cloud plans on? Which pillars are dark?
2. **Unified RBAC** — Is Defender XDR Unified RBAC **activated** and are roles scoped to least privilege, or is the tenant still on legacy per-product permissions / broad Entra roles? *RBAC model availability — verify current.*
3. **Incident correlation** — Are the pillars feeding signal so incidents **correlate across products**? Are alert-to-incident and cross-pillar settings on? Is the incident queue producing multi-pillar incidents (evidence of correlation) rather than isolated single-product alerts?
4. **Suite-wide Secure Score** — What is the Microsoft Secure Score across the suite, and are high-impact improvement actions being worked or is there a stale backlog?

Each domain is scored against the **best-practice reference baseline** named in the Global Requirements (Microsoft security baseline / Secure Score / Zero-Trust guidance — *baselines evolve; verify against current Microsoft guidance*). Domain scores roll up into an overall posture score, and every gap becomes a finding with a **risk rank** (severity × exposure).

## What is in scope
- **Reading** the suite configuration: pillar onboarding/licensing, unified RBAC role assignments, incident/correlation settings, and Microsoft Secure Score — via Graph (Security) and Az.
- **Scoring** that configuration against the recommended baseline across the four domains.
- **Producing** a prioritized, risk-ranked findings report with a saved baseline for trending.

## What is out of scope (and where it lives)
- **Making changes / closing the gaps** — the **Remediation Playbook for Defender Security Optimization Assessments** (pilot-first, `-WhatIf`-gated).
- **Deep single-pillar review** — the **Security Optimization Assessment — Defender for Cloud Apps** and **— Defender for Cloud** solutions (and their onboarding/optimization siblings for endpoint/identity/email).
- **First-time unified onboarding** — the **Microsoft Defender XDR Deployment — Unified Onboarding** solution.
- **SOC operations on the correlated incidents** — the **SOC Onboarding (Sentinel + Defender XDR)** and **Threat Hunting (KQL)** solutions.
- **Regulatory, records, incident-response, and risk-acceptance decisions** — the customer's compliance/legal/SOC functions.

## Connections and authentication used
- The **Microsoft Defender portal** (`security.microsoft.com`) → **Settings** (per-pillar onboarding, Permissions & roles / Unified RBAC), **Incidents**, and **Secure Score** (for manual confirmation).
- **Microsoft Graph** (read-only Security scopes such as `SecurityEvents.Read.All`, and directory read scopes such as `RoleManagement.Read.Directory` / `Directory.Read.All` for the RBAC audit) and **Az** for the cloud pillar. *Verify current scope names and availability.*
- Least-privilege roles: **Security Reader** / **Global Reader** are sufficient for this read-only assessment (per Global Requirements G2).

## The standard deployment model
> **Assess** the current suite configuration (pillar onboarding, unified RBAC, incident correlation, Secure Score) → **Configure** the assessment scope and baseline reference → **Pilot** the run and review the findings → **Validate** the score and findings with the security owner → **Expand** scope (pillars/roles) and re-run to trend. Repeatable pattern: **Assess → Configure → Pilot → Validate → Expand**, entirely **read-only**.


---


# 2. Requirements — Security Optimization Assessment: Microsoft Defender (Suite / XDR)

The category-wide prerequisites (the target tenant, read-only assessor access, Graph/Az access, licensing, scope/baseline, output handling, remediation ownership) are documented once in **`global-requirements-assessments.md`** — read that first. This section lists only the prerequisites **specific to assessing the Defender suite**. Each item: **Description / Why required / How to verify / How to implement if missing.**

## R1. Microsoft Defender XDR portal is active
**Description:** The unified Microsoft Defender portal (`security.microsoft.com`) is active for the tenant, with at least one pillar onboarded.
**Why required:** The suite assessment reads unified incidents, Secure Score, and RBAC from this portal; there must be a suite to assess.
**How to verify:** Sign in to `security.microsoft.com`; confirm **Incidents**, **Secure score**, and **Settings** load.
**How to implement if missing:** Confirm licensing (R2) and onboard at least one pillar. First-time unified onboarding is out of scope — use the *Microsoft Defender XDR Deployment — Unified Onboarding* solution. Record a dark suite as a finding.

## R2. Licensing across the five pillars
**Description:** The licenses/plans for endpoint, identity, email/collaboration, cloud apps, and cloud (e.g. Defender for Endpoint P1/P2, Defender for Identity, Defender for Office 365 P1/P2, Defender for Cloud Apps, Defender for Cloud plans).
**Why required:** A pillar's posture is only assessable when its plan is licensed and enabled; unlicensed pillars are coverage findings.
**How to verify:** In the Microsoft 365 admin center / billing, confirm which pillar plans are assigned. *License-to-feature mapping changes — verify current entitlements.*
**How to implement if missing:** Record any unlicensed pillar as a **coverage-gap finding** ("license/onboard to gain this pillar"), not an omission.

## R3. Read-only Security Reader / Global Reader access (and RBAC read)
**Description:** A read-only role sufficient to enumerate per-pillar configuration, unified RBAC role assignments, incidents, and Secure Score.
**Why required:** The assessment must prove it changes nothing; read-only roles are sufficient for every script here.
**How to verify:** Entra → **Roles and administrators** for Security Reader / Global Reader. Confirm you can view (not edit) **Settings → Permissions & roles** and the incident queue.
**How to implement if missing:** Assign **Security Reader** and/or **Global Reader**. Do **not** grant write/admin roles for the assessment.

## R4. Microsoft Graph read scopes consented (Security + RoleManagement)
**Description:** Read-only Graph scopes — Security read (e.g. `SecurityEvents.Read.All`) and role/directory read (e.g. `RoleManagement.Read.Directory`, `RoleManagement.Read.All`, `Directory.Read.All`) for the unified-RBAC audit.
**Why required:** The discovery, validation, scoring, RBAC-audit, and reporting scripts collect configuration through Graph.
**How to verify:** `Connect-MgGraph -Scopes "SecurityEvents.Read.All","RoleManagement.Read.Directory","Directory.Read.All"` succeeds and `SOAXDR-Discovery.ps1` runs. *Verify current scope names.*
**How to implement if missing:** Have an administrator consent the read-only scopes. Never request write scopes for this assessment.

## R5. Az access for the cloud pillar
**Description:** Az PowerShell (`Az.Accounts`, `Az.Security`) reachable so the cloud pillar's plan/coverage signal can be read.
**Why required:** Cross-pillar coverage includes the cloud pillar (Defender for Cloud); reading it requires Az.
**How to verify:** `Connect-AzAccount` succeeds; the discovery script's cloud-pillar section returns without error.
**How to implement if missing:** `Install-Module Az -Scope CurrentUser`. If Azure is genuinely not in use, record the cloud pillar as "not applicable" rather than a gap — note it in the scope.

## R6. A defined assessment scope and a secure output location
**Description:** An agreed scope (which pillars, which role assignments, which subscriptions) and a secure place to store the findings report and the saved baseline.
**Why required:** Scope keeps the score comparable; the findings report is sensitive (Global Requirements G5, G7).
**How to verify:** The scope is documented; a restricted location exists for `SOAXDR-*.json` outputs and the report.
**How to implement if missing:** Agree the scope with the security owner before running; create a restricted output location and point the scripts at it.


---


# Global Requirements — Assessments (category-level)

These requirements apply to every solution in the Assessments category (Security Optimization
Assessments, remediation playbooks, and cross-cutting security assessments). Published once at the
category level so listings stay small. Confirm these before running any assessment. Each entry:
Description / Why / Verify / Implement-if-missing.

> An assessment observes and scores; it does not change your tenant. Every assessment script here is
> **read-only** (the paired remediation work is separate and pilot-first). Scope, risk-acceptance, and
> remediation-priority decisions belong to the customer's security/compliance owners — the assessment
> supplies the evidence, not the authorization.

## G1. The workload/tenant being assessed
Description: An active Microsoft 365 / Entra tenant and/or Azure subscription(s) hosting the products in scope.
Why: There is nothing to assess without the target environment.
Verify: Sign in to the relevant portal(s) (`security.microsoft.com`, `portal.azure.com`) as an administrator.
Implement: Ensure the target tenant/subscription exists and the products under assessment are deployed (even partially — assessing coverage gaps is the point).

## G2. Read-only assessor access (least privilege)
Description: A read-only role sufficient to enumerate configuration — e.g. Security Reader, Global Reader, and/or Reader at the Azure scope.
Why: An assessment must never require write access; read-only proves it changes nothing.
Verify: Entra -> `Roles and administrators`; confirm Security Reader / Global Reader (and Azure Reader where cloud resources are assessed).
Implement: Assign the read-only roles; do not grant write/admin roles for the assessment itself.

## G3. Microsoft Graph / Az / management API access
Description: Microsoft Graph (Security), Azure Resource Manager, and product-specific management APIs reachable with the assessor identity.
Why: The assessment scripts collect configuration and posture via these APIs.
Verify: `Connect-MgGraph` (read scopes) and `Connect-AzAccount` succeed; the assessment discovery script runs. *Verify current API/permission scopes.*
Implement: Consent the read-only Graph scopes; ensure network access to the Microsoft endpoints.

## G4. Licensing for the products in scope
Description: The licenses/plans for the products being assessed (e.g. Defender for Endpoint/Identity/Office 365/Cloud Apps plans, Defender for Cloud plans).
Why: Some posture/configuration is only present (and only assessable) when the plan is enabled; the assessment flags plan gaps too.
Verify: Confirm the relevant plans in the admin/billing portal. *Verify current plan/feature mapping.*
Implement: Note unlicensed products as findings (a coverage gap) rather than skipping them silently.

## G5. Scope definition and a point-in-time baseline
Description: A defined assessment scope (which products, subscriptions, and users) and the understanding that results are a point-in-time snapshot.
Why: Scope keeps the assessment bounded and the score comparable; posture drifts, so results are dated.
Verify: The scope is documented; the assessment records the run date.
Implement: Agree the scope before running; re-run periodically to trend the score.

## G6. Best-practice reference baseline
Description: The best-practice / benchmark the assessment scores against (Microsoft security baselines, Secure Score, CIS/Zero-Trust as applicable).
Why: A score is only meaningful against a reference; the assessment states which baseline it uses.
Verify: The reference baseline is named in the findings. *Baselines evolve — verify against current Microsoft guidance.*
Implement: Use the documented baseline; note where organizational policy intentionally deviates.

## G7. Output handling and confidentiality
Description: A place to store the findings report and an understanding that it may contain sensitive posture detail.
Why: Assessment output is a roadmap of your weaknesses; it must be handled as sensitive.
Verify: A secure destination for the report exists; access is restricted.
Implement: Store findings securely; share on a need-to-know basis. *Risk-acceptance of any finding is the customer's decision.*

## G8. Remediation ownership (for the paired remediation)
Description: Named owners for acting on findings (the remediation is separate, pilot-first work).
Why: An assessment only creates value when someone owns closing the gaps.
Verify: Remediation owners are identified; the Remediation Playbook solution is available for the fixes.
Implement: Assign owners; use the Remediation Playbook (pilot-first, -WhatIf-gated) to close findings and re-score.

---
The deployment model (all solutions): Assess -> Configure -> Pilot -> Validate -> Expand.


---


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


---


# 5. Testing — Security Optimization Assessment: Microsoft Defender (Suite / XDR)

These procedures validate that the suite assessment **ran correctly and completely** — that the enumeration is trustworthy, the scoring is reproducible, and the findings report is sound. The assessment is read-only, so "testing" proves the *evidence* is reliable. Each test has a **pass/fail gate**. Reference the scripts by the names used in Section 3.

## Test 1 — Read-only connection succeeds
**Procedure:** Run the `Connect-MgGraph`/`Connect-AzAccount` commands, then `.\SOAXDR-Discovery.ps1`.
**Pass:** The script completes and writes `Posture Baseline - Defender Suite - Assess.json`; no write scope/role was used.
**Fail:** A permissions error, or a prompt for a write scope — re-check R3/R4/R5.

## Test 2 — Discovery captured all four domains and five pillars
**Procedure:** Open the baseline JSON.
**Pass:** It contains sections for **cross-pillar coverage** (with a per-pillar entry for each of the five), **unified RBAC**, **incident correlation**, and **suite-wide Secure Score** — even where a pillar is dark or marked N/A (that is itself a finding/note).
**Fail:** A domain or pillar section is missing entirely. Re-run; confirm portal access.

## Test 3 — RBAC audit enumerates privileged assignments
**Procedure:** Run `.\SOAXDR-RBACAudit.ps1 -OutputPath ".\rbac-audit.json"`.
**Pass:** The output lists privileged directory-role assignments and flags broad/over-privileged ones (or notes none found).
**Fail:** The script cannot enumerate role assignments — confirm `RoleManagement.Read.Directory` / `Directory.Read.All` (R4).

## Test 4 — Control validation returns evidence, not just a verdict
**Procedure:** Run `.\SOAXDR-Validate.ps1 -BaselinePath ... -PillarsOnboarded ... -UnifiedRbacActivated ...`.
**Pass:** Each domain check returns **Pass** or **Gap** with evidence (e.g. "identity pillar: not onboarded", "unified RBAC: legacy per-product", "Secure Score = 55%").
**Fail:** A check returns a verdict with no evidence, or throws.

## Test 5 — Scoring is reproducible
**Procedure:** Run `.\SOAXDR-Score.ps1` twice against the **same** validation output.
**Pass:** Both runs produce the same per-domain and overall scores (deterministic).
**Fail:** Scores differ for identical input — a defect; do not trust the score until reproducible.

## Test 6 — Findings report is prioritized and traceable
**Procedure:** Run `.\SOAXDR-Report.ps1 ...` and open the report.
**Pass:** Findings are sorted by **risk rank**; each names its **domain**, **severity**, **evidence**, and a **remediation pointer** (to the Remediation Playbook, or to a per-pillar deep-dive assessment where relevant).
**Fail:** Findings are unsorted, or a finding lacks evidence or a remediation pointer.

## Test 7 — Drift is detected across runs
**Procedure:** After a second run, confirm `SOAXDR-Report.ps1` compares to the prior report/baseline.
**Pass:** The report shows **new**, **resolved**, and **unchanged** findings (or notes "no prior baseline" on the first run).
**Fail:** No drift comparison when a prior baseline exists — check `-PriorReportPath`.

## Test 8 — Output is stored securely
**Procedure:** Confirm the report and score/baseline JSON live in the restricted location agreed in R6.
**Pass:** Files are in the secure destination with restricted access.
**Fail:** The report is in an open location — move it (Global Requirements G7).

## Exit criteria
All eight tests pass, the security owner has reviewed **`Findings Report – Defender Suite – Validate`**, and risk-acceptance/priority decisions are recorded. The backlog is ready for the Remediation Playbook (and the per-pillar deep-dive assessments where needed).


---


# 6. Troubleshooting — Security Optimization Assessment: Microsoft Defender (Suite / XDR)

Common failures when running the suite assessment, in **symptom → cause → fix** form. All fixes stay read-only.

## `Connect-MgGraph` fails or needs admin consent
**Symptom:** The connect command errors, or a consent screen requires an administrator.
**Cause:** The read scopes (`SecurityEvents.Read.All`, `RoleManagement.Read.Directory`, `Directory.Read.All`) are not consented, or your account lacks them.
**Fix:** Have an administrator grant admin consent for the read-only scopes once. Confirm **Security Reader** / **Global Reader** (R3). *Verify current scope names.*

## A pillar shows "not onboarded" that you believe is live
**Symptom:** Discovery marks e.g. the identity pillar dark, but you think sensors are deployed.
**Cause 1:** The signal the script reads (licensing/onboarding indicator) is not visible to the read role.
**Cause 2:** The pillar is genuinely partially onboarded (some sensors, not all) — a real finding.
**Fix:** Cross-check in the Defender portal **Settings** for that pillar. If the portal shows it onboarded and the script does not, re-check scopes. Partial onboarding is a legitimate coverage finding.

## RBAC audit lists nothing / only a few roles
**Symptom:** `SOAXDR-RBACAudit.ps1` returns an empty or tiny set.
**Cause 1:** `RoleManagement.Read.Directory` / `Directory.Read.All` not consented.
**Cause 2:** The tenant genuinely has few privileged assignments (good).
**Fix:** Verify the scopes (R4). Cross-check in Entra → **Roles and administrators**. If the portal shows assignments the script does not, the scope is missing.

## Unified RBAC "not activated" but you use Defender roles
**Symptom:** Validation flags unified RBAC as not activated although people can act in the portal.
**Cause:** The tenant is on **legacy per-product permissions** or broad Entra roles rather than the Defender XDR Unified RBAC model.
**Fix:** Confirm under **Settings → Permissions & roles** whether Unified RBAC is activated. Legacy per-product permissions are a legitimate finding ("activate unified RBAC for least-privilege cross-pillar access"). *Verify current RBAC model availability.*

## Secure Score reads low or "not available"
**Symptom:** The Secure Score domain shows no score or a surprisingly low one.
**Cause:** A pillar was recently onboarded and the score is still populating, or improvement actions genuinely aren't worked.
**Fix:** Allow a warm-up window and re-run (Global Requirements G5). A genuinely low score with a stale backlog is a legitimate finding.

## Incident-correlation evidence is empty
**Symptom:** The incident-correlation domain shows no multi-pillar incidents.
**Cause 1:** Only one pillar is feeding signal, so there is nothing to correlate (a coverage problem upstream).
**Cause 2:** The tenant is quiet (few incidents in the sample window).
**Fix:** If pillars are dark, the correlation gap is downstream of the coverage gap — fix coverage first. If pillars are onboarded and the queue is simply quiet, note it and re-sample over a longer window.

## Az cloud-pillar section errors
**Symptom:** The cloud-pillar part of discovery throws.
**Cause:** `Az` not installed, or no Azure subscription in context.
**Fix:** `Install-Module Az -Scope CurrentUser`; `Connect-AzAccount`. If Azure is not in use, mark the cloud pillar **N/A** in the scope rather than a gap (R5).

## Findings contradict the live portal
**Symptom:** A finding disagrees with what the portal shows now.
**Cause:** Posture is a **point-in-time snapshot**; the baseline predates your view, or a change was made after the run.
**Fix:** Re-run discovery to refresh the baseline, then re-score. Trust the dated baseline over memory (Global Requirements G5).


---


# 7. Best Practices — Security Optimization Assessment: Microsoft Defender (Suite / XDR)

Field-proven guidance for running this suite assessment well and keeping the result trustworthy over time.

## Keep it read-only and provably so
- Run with **Security Reader / Global Reader** only. If a script ever requests a write scope or role, treat it as a defect and stop — this assessment must prove it changed nothing.
- Record the scopes/roles used alongside the findings report as evidence of read-only execution.

## Assess the glue, not just the pillars
- The value of this assessment over the single-pillar ones is the **cross-pillar coverage**, **unified RBAC**, and **incident correlation** — the glue that makes XDR more than five separate products. Give the glue domains real attention; a fully-onboarded pillar with broken correlation still leaves you blind.
- Where a pillar needs a deep review, point to its **dedicated assessment** (Cloud Apps / Cloud) rather than duplicating that depth here.

## Treat unlicensed / dark pillars honestly
- A dark or unlicensed pillar is a **coverage finding** ("license/onboard to gain this pillar"), and onboarding has a licensing cost the customer accepts. Mark genuinely not-applicable pillars (e.g. no Azure → cloud pillar) as **N/A** in the scope so they don't read as gaps forever.

## Least privilege is the point of unified RBAC
- Flag both **over-privileged** (analysts with broad Global/Security Admin) and **under-privileged** (analysts who can't see across an incident) as findings — unified RBAC exists to fix both. Broad standing privilege is a high-risk finding; prioritize it.

## Make the score comparable across runs
- Keep the **scoring weights** fixed between runs (in `SOAXDR-Score.ps1`). If the owner changes a weight, record it in `SOA Scope – Defender Suite – Assess`.
- Re-use the saved baseline so `SOAXDR-Report.ps1` can show **drift** — a rising suite Secure Score and pillars going from dark to onboarded is the real proof of progress.

## Allow warm-up and account for correlation latency
- Secure Score and incident correlation **take time to reflect changes**. If a pillar was recently onboarded, note the snapshot may be mid-warm-up and re-run later before trusting the correlation evidence.

## Respect the decision boundary
- **Risk-acceptance**, **remediation priority**, and any **regulatory / incident-response** call belong to the customer's security, compliance, and SOC functions. The assessment supplies evidence and a technical score.

## Handle the output as sensitive
- The findings report maps your suite-wide weaknesses and privileged-access exposure. Store it in the restricted location (R6 / Global Requirements G7) and share on a need-to-know basis.

## Where to go next (adjacent catalog areas)
- **Remediation Playbook for Defender Security Optimization Assessments** — closes the findings pilot-first, `-WhatIf`-gated, then re-scores. The natural next step.
- **Security Optimization Assessment — Defender for Cloud Apps** and **— Defender for Cloud** — the deep-dive assessments for those pillars.
- **Microsoft Defender XDR Deployment — Unified Onboarding** — if the assessment shows the suite is barely stitched together.
- **SOC Onboarding (Sentinel + Defender XDR)** and **Threat Hunting (KQL)** — to operationalize the correlated incidents once coverage is solid.


---


# 8. Deliverables Summary — Security Optimization Assessment: Microsoft Defender (Suite / XDR)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box — read-only suite assessment that scores posture and prioritizes gaps |
| 1. Solution Overview | What Microsoft Defender XDR is, the four assessment domains (cross-pillar coverage, unified RBAC, incident correlation, suite-wide Secure Score), the scoring model, scope, and connections used |
| 2. Requirements Guide | Solution-specific prerequisites with Verify / Implement-if-missing |
| Global Requirements (Assessments) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps to run the suite assessment end to end — Assess → Configure → Pilot → Validate → Expand — with every artifact named |
| 5. Testing Guide | Eight validation tests with pass/fail gates proving the evidence is reliable |
| 6. Troubleshooting Guide | Common run failures and fixes |
| 7. Best Practices | Field-proven guidance and where to go next |

## PowerShell scripts (Microsoft Graph / Security + Az — all read-only)
| Script | What it does |
|---|---|
| `SOAXDR-Discovery.ps1` | Read-only discovery — per-pillar onboarding/licensing signal (endpoint/identity/email/cloud-apps/cloud), unified-RBAC role assignments, incident-correlation evidence, and Microsoft Secure Score; saves the configuration baseline. Makes no changes. |
| `SOAXDR-Validate.ps1` | Checks, per domain, whether the recommended controls are present (all in-scope pillars onboarded, unified RBAC activated with least-privilege roles, incidents correlating cross-pillar, Secure Score above a floor), returning Pass/Gap with evidence. |
| `SOAXDR-Score.ps1` | Computes deterministic per-domain and overall suite posture scores against the reference baseline using documented weights. |
| `SOAXDR-RBACAudit.ps1` | Read-only audit of privileged directory-role assignments relevant to the Defender suite — flags broad/over-privileged assignments (the unified-RBAC evidence). |
| `SOAXDR-Report.ps1` | Produces the prioritized, risk-ranked findings report (domain, severity, evidence, remediation/deep-dive pointer) and shows drift versus a prior saved baseline. |

## What the buyer receives
- This solution as a **Word** document and **PDF**.
- All five **PowerShell scripts** (read-only, Microsoft Graph / Security + Az) in a single ZIP.
- A repeatable process following **Assess → Configure → Pilot → Validate → Expand** — read-only, scored, and traceable, with findings ready to hand to the Remediation Playbook and the per-pillar deep-dive assessments.

Delivered as a **Complete Solution Package (PDF + Word + scripts)**.

## Outcome
A scored, evidence-backed picture of your Microsoft Defender suite posture across cross-pillar coverage, unified RBAC, incident correlation, and suite-wide Secure Score — and a prioritized remediation backlog that tells you what to fix, in order. Read-only: it changes nothing, it tells you what to fix.
