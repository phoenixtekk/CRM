# 3. Implementation Guide — Microsoft Purview Data Security Posture Management (DSPM & DSPM for AI)

Follow these steps **in order**. Posture and reports are read in the **Microsoft Purview portal**
(`https://purview.microsoft.com`); inventory, exposure, and reduction are automated with Security &
Compliance PowerShell (`Connect-IPPSSession`) and Microsoft Graph. Artifact names follow the
`<Purpose> – <Scope> – <Stage>` convention from the Overview and are reused verbatim. **Every
high-impact reduction is piloted in simulation/test first** — the scripts default to `-WhatIf` and to
simulation/test mode.

> **Model:** Enable and read the posture, assess sensitive-data and AI/Copilot exposure, act on
> recommendations, pilot each reduction in simulation/test, validate, then expand to enforce, and review
> on a recurring cadence.
> Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce).**
>
> **Portal-path caveat.** The DSPM and DSPM-for-AI blades are evolving; the paths below are the current
> map. If a blade or policy name differs in your tenant, use the closest equivalent and **confirm before
> acting** — do not assume a path that is not present.

## Step 0 — Confirm scope, licensing, roles, and connections (Assess)
1. Run `PURVDSPM-ScopeConfig.ps1` (read-only). It confirms your `Connect-IPPSSession`/`Connect-MgGraph`
   sign-in, reports whether **auditing** is on, and enumerates the licensing-dependent features (labels,
   DLP, auto-labeling, Insider Risk presence) that will feed posture — resolving Requirements 2.1–2.3.
2. In the Purview portal confirm **Data Security Posture Management** and **DSPM for AI** are visible
   (Requirement 2.1). Note any capability that is absent so you scope around it.
3. Confirm the **pilot ring** and the change window (Requirement 2.7) before any configuration.

**Pass/fail:** Sign-in succeeds, auditing is on, DSPM and DSPM for AI are visible, pilot scope agreed.
**Rollback:** None — read-only.

## Step 1 — Inventory the controls that feed posture (Assess)
1. Run `PURVDSPM-Discovery.ps1` (read-only). It inventories **sensitivity labels**, **label policies**,
   **DLP policies/rules**, and **auto-labeling policies** via S&C PowerShell and writes the export
   `DSPM Posture – Estate – Discovery`.
2. Review the export against Requirement 2.4 — this is your baseline of the levers DSPM will recommend
   extending. A thin taxonomy or narrow DLP scope is itself the first finding.

**Pass/fail:** The export lists your labels, label policies, DLP policies, and auto-labeling policies.
**Rollback:** None — read-only.

## Step 2 — Read the DSPM posture and sensitive-data risk (Assess)
1. Purview portal → **Data Security Posture Management** → **Overview**. Read the posture summary and the
   **sensitive-data activity** trends. This is the estate-level "where is the risk" view.
2. Open **Recommendations**. Each recommendation (label-coverage gap, DLP-scope gap, risky activity,
   etc.) has a status — this is the queue you will work in Step 6.
3. Run `PURVDSPM-Discovery.ps1 -IncludeSensitiveTypes` to append the **sensitive information types**
   in scope to `Sensitive-Data Risk – Estate – Assess`, giving a portable record of what "sensitive"
   means in your tenant to accompany the portal view.

**Pass/fail:** Posture overview renders; a recommendations list is present; the risk export is written.
**Rollback:** None — read-only.

## Step 3 — Turn on / open DSPM for AI (Assess)
1. Purview portal → **DSPM for AI** → **Overview**. If prompted, complete the one-time **get-started /
   enablement** so AI reporting begins (this may enable audit collection for AI interactions — confirm it
   aligns with Requirement 2.3).
2. Confirm the AI in scope (Requirement 2.5) is reflected — Microsoft 365 Copilot and any other AI apps
   Purview can see. If Copilot is not yet deployed, you are in **pre-adoption** posture mode: the goal is
   to reduce oversharing *before* enabling Copilot.

**Pass/fail:** DSPM for AI overview loads; in-scope AI is reflected (or pre-adoption mode confirmed).
**Rollback:** Enablement is non-destructive; no policy is enforced by opening the blade.

## Step 4 — Assess AI/Copilot data-access and sensitive interactions (Assess)
1. In **DSPM for AI → Reports**, review the AI **data-access / oversharing** view (what AI can reach) and
   the **sensitive interactions** view (prompts/responses referencing sensitive data). These are the two
   exposure questions: *what can AI reach* and *what has AI actually touched*.
2. Run `PURVDSPM-AIExposure.ps1` (read-only). It reports the AI-interaction activity available from
   **Purview auditing** and the **SharePoint/OneDrive oversharing** signal, writing
   `AI Exposure – Copilot – Assess` and `Oversharing Report – Sites – Assess`.
3. Cross-read the two: broadly-shared sites holding **unlabeled sensitive** content are the priority
   oversharing targets, because Copilot can surface them to anyone with access.

**Pass/fail:** Both reports are written; you can name the top oversharing targets.
**Rollback:** None — read-only.

## Step 5 — Capture the recommendation/action baseline (Design)
1. Run `PURVDSPM-Tracker.ps1` (read-only) to snapshot the current DSPM recommendations and the DLP /
   auto-labeling policy states into `DSPM Recommendations – Estate – Tracker` — the before-state you will
   drive to completion and re-measure against.
2. With compliance/records/privacy/legal stakeholders (GR §5), agree which recommendations to act on and
   what an acceptable AI-exposure level is. **The determination is theirs**; you provide the evidence and
   will implement the agreed technical changes.

**Pass/fail:** Tracker baseline written; the agreed action set is recorded.
**Rollback:** None — read-only.

## Step 6 — Act on recommendations and pilot oversharing reduction (Configure → Pilot)
Work the agreed set. Every high-impact lever is piloted in **simulation/test** on the pilot ring first.

1. **Auto-labeling (simulation).** Run
   `PURVDSPM-Reduce-Oversharing.ps1 -Action AutoLabel -Scope "Oversharing Reduction – Pilot – Stage1"`
   (defaults to `-WhatIf`; add `-Commit` to create it). With `-Commit` it creates the auto-labeling
   policy `Auto-Label Sensitive – Pilot – Simulation` in **simulation mode** — it labels *nothing* yet,
   it only shows what it *would* label. This closes label-coverage recommendations without risk.
2. **DLP for AI (test).** Run
   `PURVDSPM-Reduce-Oversharing.ps1 -Action DlpForAI -Scope "Oversharing Reduction – Pilot – Stage1"`
   with `-Commit` to create the DLP policy `DLP for AI – Pilot – Test` in **test/disabled** mode, scoped
   to keep the agreed sensitivity-labeled content out of AI processing. **Verify the Copilot/AI DLP
   location name in your portal** — the script parameterizes it and does not assume it (see the script's
   notes).
3. **Sharing/site-access restriction.** Where the site-access controls are available (Requirement 2.6),
   restrict the top oversharing targets from `Oversharing Report – Sites – Assess` — do this on the
   pilot sites first via site owners / the portal, and record the change. The script's `-Action
   SharingReview` produces the prioritized site list to act on; it does **not** silently change sharing.

**Pass/fail:** Pilot auto-label policy is in **simulation**, DLP for AI is in **test/disabled**, and the
pilot sharing list is produced — nothing is enforced yet.
**Rollback:** Delete the pilot policies (they are simulation/test and enforce nothing); no content was
changed.

## Step 7 — Validate the pilot (Validate)
1. Let simulation/test run the agreed window. In the portal review the auto-labeling **simulation
   results** (what it would label) and the DLP **test** matches (what it would block/flag) for
   false positives.
2. Re-run `PURVDSPM-AIExposure.ps1` and `PURVDSPM-Tracker.ps1`; compare against
   `DSPM Recommendations – Estate – Tracker` — the actioned recommendations should show progress and the
   pilot oversharing signal should be lower.
3. Confirm with stakeholders that the simulated outcomes match intent (no legitimate collaboration
   broken). See Testing (doc 5) for the explicit gates.

**Pass/fail:** Simulation/test results reviewed, acceptable false-positive rate, recommendations show
movement. **Rollback:** If results are wrong, adjust the policy conditions and re-simulate — enforce
nothing until the gate passes.

## Step 8 — Expand and enforce (Expand)
1. Only after the pilot gate passes: turn the auto-labeling policy from **simulation** to **on**, and the
   DLP-for-AI policy from **test** to **enforce**, and widen scope to
   `Oversharing Reduction – Broad – Stage2`. Do this as a deliberate, change-controlled step —
   `PURVDSPM-Reduce-Oversharing.ps1 -Action Enforce -Commit` performs the mode change on the named
   policies (still gated behind `-Commit`).
2. Apply the broad sharing/site-access restrictions to the remaining oversharing targets under change
   control.
3. Stand up the recurring review: tag the cadence `DSPM Posture Review – Estate – Recurring` and schedule
   the read-only `ScopeConfig → Discovery → AIExposure → Tracker` chain (e.g. monthly) so posture stays
   measured as data and AI usage change.

**Pass/fail:** Policies enforced at broad scope, oversharing reduced on re-measure, recurring review
scheduled. **Rollback:** Return the enforced policy to simulation/test (or delete it) and restore prior
sharing on any site where enforcement caused an issue; the tracker export is the before-state to restore
toward.
