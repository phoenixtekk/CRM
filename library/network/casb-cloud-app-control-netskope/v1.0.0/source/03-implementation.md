# 3. Implementation Guide — CASB & Cloud App Control with Netskope

Follow these steps in order. Configuration is performed in your Netskope tenant; exact console
screens and menu paths change over time and are deferred to the official Netskope documentation —
follow the named step and confirm the precise control in your console. Identity and scoping use
Microsoft Entra ID.

> Model: Discover and risk-score apps, decide sanctioned vs unsanctioned, apply inline activity
> controls and API controls for sanctioned apps, then pilot, validate, and expand. Every named
> artifact below is reused verbatim in Testing, Troubleshooting, and the scripts.

## Step 1 — Build the scope groups (Assess)
1. Build the pilot scope group `CASB Pilot – Pilot users – Pilot` with `NSCASB-Set-ScopeTargeting.ps1`
   (a few representative users across roles).
2. Build the broad scope group `CASB Broad – All users – Expand` for the eventual fleet rollout.
3. Confirm both groups resolve in Entra -> Groups.

## Step 2 — Discover and risk-score cloud apps (Assess)
1. In Netskope, run cloud app discovery over recent traffic/logs to surface every app in use.
2. Collect the corroborating inventory signal: run `NSCASB-Discovery.ps1` to enumerate Entra
   enterprise applications (a sanctioned-app signal) and confirm Graph + group readiness.
3. Record the result as the app risk register — All cloud apps – Discovery stage: each app with its
   risk score and a draft disposition (sanction / restrict / coach / block).

## Step 3 — Decide sanctioned vs unsanctioned (Configure)
1. With the business, finalize each app's disposition in the app risk register.
2. Name the two policy artifacts you will build:
   - Sanctioned apps policy – In-scope apps – Configure (allow + governed controls).
   - Unsanctioned apps policy – Shadow IT – Configure (restrict / coach / block per risk score).

## Step 4 — Configure inline activity controls (Configure)
1. Build the activity controls — Inline – Configure profile: define which activities are controlled
   (upload, download, share, post, login) and the lever per activity (allow / restrict / coach /
   block).
2. For sensitive-data movement, attach a data-movement control (DLP-style profile) so sensitive
   content moving to an unsanctioned destination is restricted or blocked.
3. Apply the levers per the app risk register: coach users from a risky app toward the sanctioned
   alternative; restrict risky activities on tolerated apps; reserve block for the highest-risk apps.
4. Scope every inline policy to `CASB Pilot – Pilot users – Pilot` first. Confirm with
   `NSCASB-Validation.ps1`.

## Step 5 — Configure API controls for sanctioned apps (Configure)
1. Confirm the API connections — Sanctioned apps – Configure exist and are healthy for each
   API-governed sanctioned app (Requirement 2.5).
2. Build the at-rest governance policy on each connection: detect exposed/public shares, external
   collaborators, and risky files; choose the response (alert, restrict sharing, quarantine) per the
   register.
3. Begin in monitor/alert mode so you can see findings before any automated response acts.

## Step 6 — Apply on the pilot (Pilot)
1. Confirm the pilot scope group is the target of the inline policies and (where applicable) the API
   findings are reviewed for pilot users.
2. From a pilot endpoint, exercise representative activities (upload to sanctioned vs unsanctioned,
   share externally, download).
3. Confirm controls fire as expected; run `NSCASB-Validation.ps1`.

## Step 7 — Validate the pilot (Validate · gate)
1. Run `NSCASB-Validation.ps1` -> confirms steering/inspection readiness and that the named policies
   are scoped to the pilot group.
2. Run `NSCASB-Report.ps1` -> produces the cloud-app usage and risk report and confirms the app risk
   register is populated.
3. Complete the Testing Guide. Pilot gate: do not expand until the pilot pass gate is met.

## Step 8 — Remediate policy gaps (Validate)
1. If validation finds gaps (a sanctioned app with no policy, an unsanctioned high-risk app with no
   control, an unhealthy API connection, missing pilot scoping), run `NSCASB-Remediation.ps1`.
2. `NSCASB-Remediation.ps1` defaults to `-WhatIf` (reports the fix it would make); re-run with
   `-Execute` only after review.

## Step 9 — Expand to production (Expand)
1. After the pilot gate passes, re-scope the named policies from `CASB Pilot – Pilot users – Pilot`
   to `CASB Broad – All users – Expand` in stages.
2. Promote API at-rest policies from monitor mode to active response only after pilot validation.
3. Re-validate each cycle with `NSCASB-Report.ps1`; keep the app risk register current as discovery
   surfaces new apps.

> Rollback note: to reverse a control, scope the policy back to monitor-only or remove the pilot/broad
> group from its assignment, and (for API) revert the connection's response to alert-only. Inline
> enforcement affects live traffic — keep the rollback ready before enabling block.

---
### Order of operations
`Scope groups -> Discover & risk-score -> Sanctioned/unsanctioned decision -> Inline activity controls
-> API controls -> Apply on pilot -> Validate (gate) -> Remediate gaps -> Expand`
