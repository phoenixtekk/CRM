# 5. Testing Guide — Microsoft 365 Copilot Secure Adoption & Governance

Run after the pilot is configured and Copilot is enabled for the pilot group (Implementation Step 8),
and re-run after each expansion wave. The most important tests are the **exposure probes** — proving
Copilot cannot surface what it should not.

## Test 1 — Oversharing remediated on targeted sites
**Do:** Run `COPILOT-Discovery.ps1`; review the broad-sharing signals for the remediated sites.
**Expected:** Anonymous/"anyone" and org-wide links are gone on the targeted sites; remaining broad grants are only those owners explicitly approved.

## Test 2 — Sensitivity labels published and applied
**Do:** Purview → **Information Protection → Label policies**; confirm the taxonomy is published to the pilot. Run `COPILOT-Validation.ps1`.
**Expected:** Labels are published; protected labels carry encryption/usage rights; auto-labeling (if configured) is applying to sample content.

## Test 3 — Copilot licensing limited to the pilot
**Do:** Run `COPILOT-Validation.ps1` (checks Copilot license assignment against the pilot group).
**Expected:** Copilot licenses are assigned only to members of `Copilot Adoption – Pilot Users – Pilot` — not the whole org.

## Test 4 — Exposure probe: restricted content is NOT surfaced
**Do:** As a **pilot user who should not have access**, ask Copilot for content in a restricted/labeled or non-shared site (e.g. "summarize the HR compensation files").
**Expected:** Copilot returns nothing from that content — it honors permissions and label-based access. No citations to content the user cannot open.

## Test 5 — Exposure probe: label protection is honored in output
**Do:** As a pilot user, ask Copilot to summarize a document carrying a protected label the user *can* open, then attempt to reuse the output.
**Expected:** Copilot-generated output inherits the most restrictive source label; protected content is not stripped of its label.

## Test 6 — DLP-for-Copilot exclusion works
**Do:** As a pilot user, ask Copilot to summarize content that the `Copilot Data Exclusion – Highly Confidential – Pilot` policy excludes.
**Expected:** The excluded content is not processed/summarized by Copilot for that request.

## Test 7 — Data-exposure numbers improved
**Do:** Run `COPILOT-Report.ps1` and compare against the Step 1 baseline.
**Expected:** Fewer broadly/externally shared items and more labeled content than the pre-remediation baseline.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–4 pass; the exposure probe (Test 4) confirms restricted content is not surfaced; licensing is pilot-only |
| **Expand pass** | Tests 1–3, 6, 7 pass for the newly remediated scope before the next license wave |
