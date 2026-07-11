# 3. Implementation — Cloud Adoption Security Assessment

This is the exact, ordered procedure. It is **read-only** end to end — you enumerate and score, you never
change the tenant. Follow the standard model: **Assess → Configure → Pilot → Validate → Expand**. Run the
**pilot** on one representative scope first, confirm the findings are real, then expand to the whole estate.

**Naming convention.** Every artifact you create uses `<Purpose> – <Scope> – <Stage>`. Reuse the exact
names in later steps, testing, and the report:
- Scope document: **`CloudSecAssessment – Estate – Scope`**
- Output folder: **`CloudSecAssessment – Estate – Findings`**
- Pilot run label: **`CloudSecAssessment – FinancePilot – Pilot`**
- Full run label: **`CloudSecAssessment – Estate – Full`**
- Roadmap deliverable: **`CloudSecAssessment – Estate – Roadmap`**
- Saved KQL query: **`CloudSecAssessment – LegacyAuth – Signal`**

---

## Stage 0 — Assess: prepare and validate access (read-only)

### Step 0.1 — Write the scope document
1. Create **`CloudSecAssessment – Estate – Scope`** (a short doc). Record: the subscriptions in scope, the
   M365/Defender products in scope, the user/device population, the **reference baseline** you will score
   against (Microsoft security baselines + Secure Score; add CIS / Zero Trust if your org uses them —
   *verify the current baseline version*), and any non-default **pillar weighting**.
2. Note the **run date** — the score is a point-in-time snapshot (Global Requirements G5).

### Step 0.2 — Create the output folder
1. Create a restricted folder named **`CloudSecAssessment – Estate – Findings`** in your secure destination
   (R8). All exports land here.

### Step 0.3 — Install modules and validate read-only access
1. In **PowerShell 7+**: `Install-Module Microsoft.Graph -Scope CurrentUser` and
   `Install-Module Az -Scope CurrentUser` if not present (R4).
2. Connect read-only:
   - `Connect-MgGraph -Scopes "SecurityEvents.Read.All","Policy.Read.All","Directory.Read.All","DeviceManagementConfiguration.Read.All"` *(verify the current least-privilege scope set for your tenant)*.
   - `Connect-AzAccount` and, if needed, `Set-AzContext -SubscriptionId <sub>`.
3. Run **`CLDSEC-Validate.ps1`**. It confirms: PowerShell version, required modules present, the Graph
   scopes granted, that your identity is **read-only** (Security/Global Reader, Azure Reader), and lists the
   in-scope subscriptions. **Do not proceed until Validate passes** — a missing scope means a pillar will
   silently score zero.

---

## Stage 1 — Configure: choose the baseline and pilot scope

1. In **`CloudSecAssessment – Estate – Scope`**, confirm the **reference baseline** and record it — the
   report must name what it scored against (G6).
2. Pick a **representative pilot scope** — one business unit or one subscription — and label it
   **`CloudSecAssessment – FinancePilot – Pilot`** (rename to your BU). The pilot proves the method and
   surfaces false positives before you run the whole estate.
3. Confirm the **pillar weighting** (default: identity and endpoints weighted highest). Record any deviation.

---

## Stage 2 — Pilot: discover and score the pilot scope (read-only)

### Step 2.1 — Estate discovery across the six pillars
1. Run **`CLDSEC-Discovery.ps1 -Scope "CloudSecAssessment – FinancePilot – Pilot" -OutputFolder "<...>\CloudSecAssessment – Estate – Findings"`**.
   For the pilot, point it at the pilot subscription/BU. It enumerates, read-only:
   - **Identity** — MFA registration coverage, legacy-auth exposure, privileged role counts and PIM usage,
     risky-user/sign-in signals.
   - **Endpoints** — device enrollment and compliance counts (Intune), Defender for Endpoint onboarding state.
   - **Data** — sensitivity-label and DLP policy presence and scope.
   - **Applications** — OAuth app registrations, risky/consented permissions, secret/expiry status; Cloud
     Apps (shadow IT) visibility state.
   - **Infrastructure** — Defender for Cloud plan state and Secure Score, Azure Policy assignments, CAF
     governance guardrails (management groups) presence.
   - **Network** — public IP / open management-port exposure, private-endpoint usage on PaaS.
2. It writes a per-pillar posture CSV/JSON into the output folder.

### Step 2.2 — Pull Secure Score and control profiles
1. Run **`CLDSEC-SecureScore.ps1 -OutputFolder "<...>\CloudSecAssessment – Estate – Findings"`**. It returns
   your current Secure Score, the maximum, the per-category control profiles (identity/device/apps), and the
   **highest-impact improvement actions** — which feed the pillar scores and the roadmap.

### Step 2.3 — Review Conditional Access coverage
1. Run **`CLDSEC-ConditionalAccess.ps1 -OutputFolder "<...>\CloudSecAssessment – Estate – Findings"`**. It
   enumerates every CA policy (enabled + report-only) and flags the coverage gaps that matter most:
   - No **phishing-resistant MFA** for admins / all users.
   - **Legacy authentication** not blocked.
   - No **device-compliance** grant.
   - **Break-glass** account exclusions missing or mis-scoped (an emergency-access account must be excluded).
2. *Note: the assessment reports gaps; it does not create or change any CA policy. Building/enforcing CA
   policy is a separate, pilot-first remediation — see Best Practices for the pointer.*

### Step 2.4 — (Optional) corroborate with KQL
1. If you have Advanced Hunting / Sentinel (R7), run the read-only query saved as
   **`CloudSecAssessment – LegacyAuth – Signal`** (supplied in Testing) to confirm whether legacy-auth
   sign-ins are still happening in the pilot scope — live evidence behind the config finding.

### Step 2.5 — Score and rank the pilot
1. Run **`CLDSEC-Report.ps1 -InputFolder "<...>\CloudSecAssessment – Estate – Findings" -Label "CloudSecAssessment – FinancePilot – Pilot"`**.
   It rolls the discovery + Secure Score + CA outputs into a **per-pillar maturity score (0–100)** against
   the recorded baseline, tags each finding with a **risk rating** (impact × exposure), and emits a draft
   risk-ranked findings report.

---

## Stage 3 — Validate: confirm the pilot findings are real

1. Open the draft report. For each **High/Critical** finding, open the corresponding live portal blade and
   confirm it is genuine — this removes false positives before anyone sees the numbers:
   - Identity/CA → Entra admin center → **Conditional Access** and **Users → Authentication methods**.
   - Endpoints → `intune.microsoft.com` → **Devices** compliance; `security.microsoft.com` → device inventory.
   - Data → Microsoft Purview → **Information Protection** / **DLP**.
   - Infra → `portal.azure.com` → **Microsoft Defender for Cloud** → Secure Score / Recommendations.
2. Mark any confirmed false positive in the report and note why (e.g. a compensating control the script
   can't see). **Do not silently delete findings** — record the reasoning.
3. Sanity-check the pilot pillar scores against your own expectation. If a pillar scored zero, re-check that
   the matching Graph scope / Azure Reader role was present (a common cause — see Troubleshooting).

---

## Stage 4 — Expand: run the whole estate and produce the roadmap

1. Re-run **Steps 2.1–2.5** with the full scope, labelled **`CloudSecAssessment – Estate – Full`** — point
   `CLDSEC-Discovery.ps1` at all in-scope subscriptions and the full user/device population.
2. Run **`CLDSEC-Report.ps1 ... -Label "CloudSecAssessment – Estate – Full"`** to produce the final
   **risk-ranked findings report** with per-pillar maturity scores and an **overall maturity rating**.
3. Build the phased roadmap **`CloudSecAssessment – Estate – Roadmap`** from the ranked findings, in three
   phases:
   - **Phase 1 — Quick wins:** high-impact, low-effort (e.g. block legacy auth, exclude break-glass from
     enforcement gaps, turn on a Defender plan you already own).
   - **Phase 2 — Foundational:** MFA/CA coverage, device compliance gates, DLP baseline, Defender for Cloud
     plan enablement.
   - **Phase 3 — Strategic:** PIM/least-privilege program, data-classification program, network segmentation,
     landing-zone governance.
4. Map each roadmap item to the **dedicated catalog solution** that remediates it (Defender XDR onboarding,
   Defender CSPM, Cloud App / DLP, SOC & XDR, Threat Hunting) — the assessment hands the fix off; it does not
   perform it.
5. Store the report and roadmap in **`CloudSecAssessment – Estate – Findings`** (restricted). Present the
   executive summary (overall score + top risks) to leadership and the technical findings to the owners.

> **Determinations that are NOT yours to make in this guide:** whether to *accept* any given risk, how to
> prioritize against business need and budget, and any **regulatory / records / legal** mapping of a finding
> belong to your security, compliance, and leadership functions. The assessment supplies the evidence and a
> recommended sequence; the decisions are the customer's.

## Re-run to trend
The whole assessment is re-runnable. Re-run quarterly (or after a remediation wave) with the same scope and
baseline to **trend the maturity score** and prove risk reduction over time.
