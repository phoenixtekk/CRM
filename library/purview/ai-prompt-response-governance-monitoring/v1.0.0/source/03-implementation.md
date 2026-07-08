# 3. Implementation Guide — AI Prompt/Response Governance & Usage Monitoring (Microsoft Purview)

Follow these steps **in order**. Monitoring is read in the **Microsoft Purview portal**
(`https://purview.microsoft.com`) and via Security & Compliance PowerShell (`Connect-IPPSSession`) /
Exchange Online (`Connect-ExchangeOnline`, for `Search-UnifiedAuditLog`) / Microsoft Graph. Governance
policy (Communication Compliance + DLP for AI) is created and piloted before it is expanded. Artifact names
follow the `<Purpose> – <Scope> – <Stage>` convention from the Overview and are reused verbatim. **Every
high-impact policy is piloted in a limited/test scope first** — the scripts default to `-WhatIf` and create
DLP for AI in **test** mode.

> **Model:** Baseline AI usage and governance config → assess sensitive prompts/responses → design the
> Communication-Compliance + DLP-for-AI policy with privacy-by-design → pilot each in a limited/test scope →
> validate → expand/enforce → recurring review.
> Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce).**
>
> **Portal-path caveat.** The Copilot/AI monitoring source in Communication Compliance, the DLP **Copilot**
> location, and the DSPM-for-AI blades are evolving; paths below are the current map. If a blade, source, or
> policy location differs in your tenant, use the closest equivalent and **confirm before acting** — do not
> assume a path that is not present.
>
> **Privacy gate.** Communication Compliance monitors people's prompts and responses. **Enable
> anonymization first, keep Analyst/Investigator roles separate, and get HR/privacy/legal sign-off on the
> pilot before it runs.**

## Step 0 — Confirm scope, licensing, roles, auditing, and connections (Assess)
1. Run `AIPROMPT-ScopeConfig.ps1` (read-only). It confirms your `Connect-IPPSSession` /
   `Connect-ExchangeOnline` / `Connect-MgGraph` sign-in, reports whether **auditing** is on
   (`UnifiedAuditLogIngestionEnabled`), and enumerates the AI-governance features present (Communication
   Compliance policies, DLP, sensitivity labels, DSPM-for-AI/Copilot audit signal) — resolving Requirements
   2.1–2.6.
2. In the Purview portal confirm **Communication Compliance**, **Data Loss Prevention**, and **DSPM for AI**
   are visible (Requirements 2.4–2.6). Note any capability absent so you scope around it.
3. Confirm the **pilot ring** `AI Governance – Pilot – Ring1`, the change window, and **HR/privacy/legal
   sign-off** (Requirement 2.8) before any configuration.

**Pass/fail:** Sign-in succeeds; auditing is on; Communication Compliance, DLP, and DSPM for AI are visible;
pilot ring and privacy sign-off agreed.
**Rollback:** None — read-only.

## Step 1 — Inventory existing AI-governance config (Assess)
1. Run `AIPROMPT-Discovery.ps1` (read-only). It inventories **sensitivity labels**, **sensitive information
   types**, **DLP policies/rules** (flagging any already scoped to a Copilot/AI location), and existing
   **Communication Compliance policies** (`Get-SupervisoryReviewPolicyV2`), writing the export
   `AI Governance Config – Estate – Discovery`.
2. Review against Requirements 2.4–2.5 — this is your baseline of the levers (labels, SITs, DLP) the
   governance policy will match on and confirms whether any AI governance already exists.

**Pass/fail:** The export lists your labels, SITs, DLP policies, and Communication Compliance policies.
**Rollback:** None — read-only.

## Step 2 — Baseline AI prompt/response usage (Assess / Monitor)
1. Run `AIPROMPT-Monitor.ps1` (read-only). It pulls **`CopilotInteraction`** (and any additional configured
   AI record types) from the unified audit log for the window, summarizes **who used AI, which app, and
   which interactions referenced sensitive/labeled resources**, and writes `AI Usage – Copilot – Monitor`
   and `Sensitive AI Interactions – Estate – Assess`.
2. In the portal, open **DSPM for AI → Reports** and cross-read the **sensitive interactions per AI app**
   view against the export. This is the evidence baseline of *what AI has actually touched*.
3. If the export is empty, confirm auditing is on (Requirement 2.3) and that Copilot/AI has been used — with
   no AI activity there is nothing to monitor yet (pre-adoption; stage the policy so it is live on day one).

**Pass/fail:** `AI Usage – Copilot – Monitor` and `Sensitive AI Interactions – Estate – Assess` are written;
you can name the AI apps in use and the interactions touching sensitive data.
**Rollback:** None — read-only.

## Step 3 — Design the governance policy set with stakeholders (Design)
1. With **HR, compliance, privacy, and legal** (GR §5), agree: which **sensitive information types /
   sensitivity labels** define a governed prompt/response; whether the Communication-Compliance policy
   monitors for **sensitive-info / data-leak / offensive-language** classifiers; the **in-scope population**;
   the **anonymization** requirement; and what a DLP-for-AI policy should do with labeled content (audit vs
   restrict). **The determination is theirs**; you provide the technical method and will implement the
   agreed set.
2. Record the agreed policy definitions and the two artifact names to be created:
   `AI Interactions – Copilot – CommCompliance` and `AI Prompt DLP – Copilot – Test`.

**Pass/fail:** Agreed policy definitions, in-scope population, classifiers, and anonymization recorded and
signed off. **Rollback:** None — design only.

## Step 4 — Create the Communication-Compliance AI policy (Configure → Pilot, limited scope)
1. **Privacy-by-design first.** Purview portal → **Communication Compliance → Settings → Privacy** — confirm
   **anonymization** is **on** so reviewers see pseudonymized aliases.
2. **Communication Compliance → Policies → Create policy.** Create `AI Interactions – Copilot – CommCompliance`
   scoped **only to the pilot ring** `AI Governance – Pilot – Ring1`, with **Microsoft 365 Copilot / AI
   interactions** as the monitored source (**verify this source exists in your tenant** — if absent, monitor
   via Step 2 audit signal only), the agreed classifiers/sensitive-info conditions, and the agreed reviewers.
3. `AIPROMPT-Configure-Governance.ps1 -Action CommComplianceReview` (read-only) prints the recommended
   scope/reviewer/anonymization checklist to confirm the portal policy matches the Step 3 design. **The
   policy is created in the portal** (Communication Compliance policy creation is privacy-sensitive and its
   parameters vary — the script does not silently create it).

**Pass/fail:** `AI Interactions – Copilot – CommCompliance` exists, scoped to the pilot ring only, with
anonymization on and reviewers assigned. **Rollback:** Delete the policy — it only routes matches to review,
it changes no content.

## Step 5 — Create the DLP-for-AI (Copilot) policy in test mode (Configure → Pilot)
1. Run `AIPROMPT-Configure-Governance.ps1 -Action DlpForAI -Scope "AI Governance – Pilot – Ring1"
   -DlpAiLocation "<your-Copilot-location>"` (defaults to `-WhatIf`; add `-Commit` to create it). With
   `-Commit` it creates the DLP policy `AI Prompt DLP – Copilot – Test` in **test/disabled** mode, scoped to
   the pilot ring, matching the agreed labels/SITs on the **Copilot/AI location**. **The Copilot location
   name is licensing-dependent and evolving — the script requires you to pass it (`-DlpAiLocation`) and does
   not assume it.**
2. If DLP does not expose a Copilot location in your tenant, use the portal's **DSPM for AI** one-click
   "protect sensitive data from Copilot" policy where present, and record it under the same artifact name.

**Pass/fail:** `AI Prompt DLP – Copilot – Test` exists in **test** mode on the pilot ring; nothing is
enforced. **Rollback:** Delete the test policy — it enforces nothing.

## Step 6 — (Optional, verify) Stage the risky-AI-usage insider-risk signal (Configure)
1. **If Insider Risk Management and its risky-AI-usage template/indicators are available and licensed in your
   tenant** (verify — this is preview and evolving), create `Risky AI Usage – Pilot – Monitor` scoped to the
   pilot ring in the portal, to surface anomalous AI use. Keep it in a **monitor/analytics** posture, not
   action. `AIPROMPT-Configure-Governance.ps1 -Action InsiderRiskCheck` (read-only) reports whether the
   insider-risk surface is present.
2. If unavailable, skip — the Communication-Compliance policy and monitoring cover the core scope.

**Pass/fail:** Either the monitor policy exists (pilot scope) or the capability is confirmed absent and
noted. **Rollback:** Delete the policy — it only surfaces analytics.

## Step 7 — Validate the pilot (Validate)
1. Run `AIPROMPT-Validate.ps1` (read-only). It confirms `AI Prompt DLP – Copilot – Test` is in **test** mode
   (not enforcing), confirms `AI Interactions – Copilot – CommCompliance` exists and is scoped to the pilot
   ring, and re-checks that AI interactions are being captured — writing `AI Governance Validation – Estate –
   Evidence`.
2. In the portal, review **Communication Compliance → Policies →** the AI policy's **pending items** and the
   **DLP test** matches for **false positives**, with the assigned (pseudonymized) reviewers. Confirm with
   HR/privacy that reviewer workflow and anonymization behave as designed.
3. Re-run `AIPROMPT-Monitor.ps1` and confirm the monitoring signal aligns with the policy matches (the
   sensitive interactions being flagged are the ones the policy is meant to catch).

**Pass/fail:** DLP policy is in test, Communication-Compliance policy scoped to the pilot ring with
anonymization working, matches reviewed with an acceptable false-positive rate, monitoring aligns. See
Testing (doc 5) for the explicit gates.
**Rollback:** Adjust conditions and re-validate; enforce/expand nothing until the gate passes.

## Step 8 — Expand and enforce (Expand)
1. **Only after the pilot gate passes** and with change-control + HR/privacy/legal approval: widen the
   **Communication-Compliance** policy scope from `AI Governance – Pilot – Ring1` to `AI Governance – Broad
   – Stage2`, and flip the **DLP-for-AI** policy from **test** to **enforce** —
   `AIPROMPT-Configure-Governance.ps1 -Action Enforce -Commit` performs the mode change on the named DLP
   policy (still gated behind `-Commit`), or expand in the portal.
2. Confirm reviewer capacity and retention settings scale to the broad population before widening
   Communication Compliance.
3. Stand up the recurring review: tag the cadence `AI Usage Review – Estate – Recurring` and schedule the
   read-only `ScopeConfig → Discovery → Monitor → Validate` chain (e.g. monthly) so AI usage and governance
   stay measured as adoption grows.

**Pass/fail:** DLP for AI enforced at broad scope, Communication-Compliance policy at broad scope with
capacity confirmed, recurring review scheduled. **Rollback:** Return the DLP policy to **test** (or delete)
and narrow the Communication-Compliance scope back to the pilot ring; the validation evidence export is the
before-state to restore toward.
