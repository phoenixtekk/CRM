# 6. Troubleshooting — Cloud Adoption Security Assessment

Common failures when running the assessment, as **symptom → cause → fix**. Everything here stays read-only —
no fix below changes tenant configuration.

## A pillar scores zero / discovery returns empty for one pillar
**Symptom:** `CLDSEC-Discovery.ps1` returns rows for some pillars but the Infrastructure (or Data, or App)
pillar is empty, and that pillar scores zero.
**Cause:** The read role or Graph scope for that pillar is missing — Infrastructure needs Azure **Reader**
(R2); Data/App need the Purview/directory Graph scopes (R3). A missing scope reads as "nothing there,"
which the score can't distinguish from "nothing configured."
**Fix:** Run `CLDSEC-Validate.ps1` and compare the granted scopes/roles against R1–R3. Assign the missing
**Reader** role or consent the missing read scope, then re-run discovery for that pillar. Never assume an
empty pillar means it's insecure *or* secure until access is confirmed.

## `Connect-MgGraph` fails or `Authorization_RequestDenied`
**Symptom:** Sign-in fails, or Secure Score / Conditional Access calls return `Authorization_RequestDenied`.
**Cause:** The required delegated read scopes weren't consented, or admin consent is required in your tenant.
**Fix:** Re-run `Connect-MgGraph -Scopes <list>` and accept consent; if the tenant blocks user consent, have
an admin grant admin consent for the **read-only** scope set (R3). `Get-MgContext` should then list the
scopes. Never substitute a write scope to "make it work."

## `Connect-AzAccount` succeeds but subscriptions are missing
**Symptom:** Azure connects, but in-scope subscriptions don't appear and the Infrastructure/Network pillars
under-report.
**Cause:** **Reader** isn't assigned at those subscriptions, or your context is set to a different tenant/sub.
**Fix:** `Get-AzSubscription` to list what you can see; assign **Reader** at the missing subscription or
management group (R2), then `Set-AzContext` and re-run. Confirm the tenant matches the M365 tenant.

## Secure Score in the script doesn't match the portal
**Symptom:** `CLDSEC-SecureScore.ps1` returns a different score than `security.microsoft.com`.
**Cause:** Portal refresh lag (Secure Score recalculates on its own cadence), or you're reading a different
tenant, or Secure Score isn't fully populated (R6).
**Fix:** Allow for the portal's refresh window; confirm the tenant; confirm Secure Score is populated. Small
differences are normal timing; large differences mean a tenant/scope mismatch — recheck and re-run.

## Conditional Access "gap" is actually covered
**Symptom:** `CLDSEC-ConditionalAccess.ps1` flags "no admin MFA" but you believe a policy covers it.
**Cause:** The control lives in a **report-only** policy (not yet enforced), a policy scoped by group the
script didn't expand, or a Security Defaults configuration.
**Fix:** Open the live CA policies and confirm the effective state. If it's genuinely covered, mark it a
**validated false positive** in the report with the reason (Testing Gate 4) — don't delete it silently. If
it's report-only, it is *not* yet enforced, so the finding stands until it's turned on (a separate,
pilot-first remediation).

## KQL query errors on table or column names
**Symptom:** The `CloudSecAssessment – LegacyAuth – Signal` query fails with an unknown table/column.
**Cause:** Schema differs between Sentinel workspaces and Advanced Hunting, and schemas evolve.
**Fix:** Adjust the table/column names to your workspace (*verify current schema*), or skip it — the KQL is
**optional** corroboration and does not gate the maturity score.

## Report scores aren't reproducible
**Symptom:** Re-running `CLDSEC-Report.ps1` on the "same" data yields different scores.
**Cause:** The input folder changed between runs (a discovery output was overwritten or partially written),
or two runs used different scope labels.
**Fix:** Ensure all Stage-2 outputs for the run label are present and complete in the input folder before
running the report; keep pilot and full-estate outputs in clearly labelled subfolders
(`... – Pilot` vs `... – Full`). Re-run.

## Script "does nothing" / silent exit
**Symptom:** A script runs and returns almost immediately with no output.
**Cause:** Module version drift (R4) or no matching resources in the current context.
**Fix:** Confirm PowerShell ≥ 7 and current **Microsoft.Graph** / **Az** modules; confirm you're connected
and in the right context. Run `CLDSEC-Validate.ps1` first — it catches the common environment problems
before the substantive scripts run.

## The assessment found a Defender product isn't turned on
**Symptom:** A product you're licensed for shows as not onboarded / plan off.
**Cause:** This is a **finding, not an error** — a coverage gap is exactly what the assessment exists to
surface.
**Fix:** Record it as a finding and map it to the remediation solution (Defender XDR onboarding / Defender
CSPM). Turning it on is separate, change-controlled work — not part of this read-only assessment.
