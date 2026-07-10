# 3. Implementation Guide — Microsoft Defender for Cloud: CSPM & Secure Score Remediation

Follow these steps **in order**, in the **Azure portal** (`https://portal.azure.com`) under **Microsoft Defender for Cloud**. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

> **Model:** Enable CSPM and agentless scanning on the **pilot subscription** first, understand the recommendation picture, remediate in priority order, and validate that Secure Score moves — then expand to the rest of the estate and to AWS/GCP. Every change is preview/`-WhatIf` first, and remediation of real resources is done in a controlled window with a rollback. **Which regulatory standards and which exemptions are acceptable are the compliance/security team's decisions.**

## Naming (set once, reuse verbatim)
- Pilot scope (subscription): `CSPM Scope – Pilot Sub – Pilot`
- Governance rule (recommendation ownership): `Secure Score Remediation – Pilot Sub – Prod`
- Continuous export (to Log Analytics): `CSPM Continuous Export – Pilot Sub – Prod`
- Secure-Score trend workbook: `Secure Score Trend – Pilot Sub – Prod`
- Exemption (per justified exception): `CSPM Exemption – <recommendation> – Prod`

## Step 1 — Assess current posture
1. `portal.azure.com` → **Microsoft Defender for Cloud** → **Overview**. Note the current **Secure Score** for the pilot subscription.
2. Run `DEFCSPM-Discovery.ps1` to capture plan status per subscription, Secure Score, registered providers, available Log Analytics workspaces, and any existing AWS/GCP connectors.
3. Run `DEFCSPM-Report.ps1 -SaveBaseline` to record the starting posture as the pre-change baseline.

## Step 2 — Enable Defender CSPM on the pilot subscription
1. **Microsoft Defender for Cloud** → **Environment settings** → select `CSPM Scope – Pilot Sub – Pilot`.
2. On **Defender plans**, confirm **foundational CSPM** is on (free), then set **Defender CSPM** to **On**. *Verify current Defender CSPM pricing and availability in your tenant.*
3. Preview first: run `DEFCSPM-Enable-CSPM.ps1 -SubscriptionId <pilot>` (defaults to `-WhatIf`) to see the change, then re-run with `-Apply` (or complete it in the portal).
4. **Save.** Allow time for the plan to activate and assessments to begin.

## Step 3 — Turn on agentless scanning
1. Still in **Environment settings → `CSPM Scope – Pilot Sub – Pilot` → Defender CSPM → Settings**.
2. Enable **Agentless scanning for machines** (and data-aware/other toggles agreed in requirements). *Verify current agentless scanning requirements.*
3. **Save.** Agentless scans populate over time.
4. Run `DEFCSPM-Validate.ps1` → confirms Defender CSPM is on and agentless scanning is enabled.

## Step 4 — Enable the regulatory-compliance dashboard
1. **Microsoft Defender for Cloud** → **Regulatory compliance** → **Manage compliance policies** → select `CSPM Scope – Pilot Sub – Pilot`.
2. Confirm the **Microsoft cloud security benchmark** is assigned (default). Add any additional standard(s) **the compliance team specifies** — *the choice of standard is theirs, not this guide's.*
3. Return to **Regulatory compliance** and confirm the dashboard renders control pass/fail for the assigned standard(s).

## Step 5 — Work recommendations in priority order
1. **Microsoft Defender for Cloud** → **Recommendations**. Sort by **risk / impact**; work the highest-impact items first.
2. **Attack path analysis** (Defender CSPM) → open **Attack paths** and prioritize any path that chains exposure → identity → sensitive data. Remediate the choke points first.
3. Use the built-in **Fix** action where offered. For manual fixes, do them in a controlled window with a rollback.
4. Re-run `DEFCSPM-Report.ps1` after a remediation batch to confirm Secure Score is moving and to see the new top items.

## Step 6 — Set governance rules and exemptions
1. **Microsoft Defender for Cloud** → **Governance rules** → **Create governance rule** → name it `Secure Score Remediation – Pilot Sub – Prod`. Assign **owners** and a **due date / grace period** for recommendations so accountability is tracked.
2. For any legitimate exception, create a scoped **Exemption** on the specific recommendation, named `CSPM Exemption – <recommendation> – Prod`, with a **justification and expiry** — never silently suppress. *Whether an exemption is acceptable is the security/compliance team's decision.*
3. Run `DEFCSPM-Validate.ps1` → confirms the governance rule exists and exemptions are time-bound.

## Step 7 — Configure continuous export
1. **Microsoft Defender for Cloud** → **Environment settings → `CSPM Scope – Pilot Sub – Pilot` → Continuous export**.
2. Create the export `CSPM Continuous Export – Pilot Sub – Prod` → export **Security recommendations** and **Secure Score** to the Log Analytics workspace from requirements.
3. (Optional) Deploy the **Secure Score over time** workbook and save it as `Secure Score Trend – Pilot Sub – Prod`.
4. Run `DEFCSPM-Hunt.ps1` to confirm recommendations/attack-path data is queryable via Azure Resource Graph.

## Step 8 — Validate on the pilot
1. Run `DEFCSPM-Validate.ps1` → confirms Defender CSPM on, agentless scanning on, provider registered, governance rule present, continuous export configured.
2. Run `DEFCSPM-Report.ps1 -BaselinePath .\defcspm-baseline.json` → confirms Secure Score has moved versus the Step 1 baseline and shows remaining top recommendations/attack paths.
3. Complete the **Testing Guide** before expanding.

## Step 9 — Expand across the estate (and multicloud)
1. Enable Defender CSPM and agentless scanning on the remaining subscriptions (ideally at a **management-group** scope so new subscriptions inherit it).
2. Roll the governance rule, exemptions discipline, and continuous export out to those subscriptions.
3. (Optional) Add **AWS/GCP connectors** (**Environment settings → Add environment**) for high-level multicloud posture, after the Azure pilot is validated.
4. Re-baseline with `DEFCSPM-Report.ps1 -SaveBaseline` and track Secure-Score/recommendation drift each cycle.

---
### Order of operations
`Assess posture → enable Defender CSPM (pilot) → agentless scanning → compliance dashboard → remediate by priority → governance rules & exemptions → continuous export → validate Secure Score moved → expand (+ AWS/GCP)`
