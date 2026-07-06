# 5. Testing Guide — Gemini Enterprise: Secure Adoption, Guardrails & Data-Access Boundaries

Run after the pilot is configured and Gemini is enabled for the pilot scope (Implementation Step 8),
and re-run after each expansion wave. The most important tests are the **exposure probes** — proving
Gemini cannot surface what it should not. Each guardrail below is a **validation gate**.

## Test 1 — Oversharing remediated on targeted content
**Do:** Run `GEMGOV-Discovery.ps1`; review the broad-sharing signals for the remediated files/shared drives.
**Expected:** Public "anyone with the link" and domain-wide grants are gone on the targeted content; remaining broad grants are only those owners explicitly approved.

## Test 2 — DLP / IRM protection present on sensitive content
**Do:** Admin console → **Security → Data protection**; confirm the DLP rules apply IRM to the sensitive scope. Run `GEMGOV-Validation.ps1`.
**Expected:** DLP rules are active; sensitive content carries IRM (prevent download/print/copy); CSE is applied where required.

## Test 3 — Gemini enablement and data-access scoped to the pilot
**Do:** Run `GEMGOV-Validation.ps1` (checks the pilot scope). In the Admin console, confirm **Service status** and the **data-access** setting are scoped to the pilot OU/group. *(Verify in your tenant.)*
**Expected:** Gemini is on and data-access is allowed **only** for `Gemini Adoption – Pilot Users – Pilot` — not the whole org.

## Test 4 — Exposure probe: restricted content is NOT surfaced
**Do:** As a **pilot user who should not have access**, ask Gemini for content in a restricted or non-shared location (e.g. "summarize the HR compensation files").
**Expected:** Gemini returns nothing from that content — it grounds only in what the user can access. No citations to content the user cannot open.

## Test 5 — Exposure probe: IRM-protected content is not retrieved
**Do:** As a pilot user, ask Gemini to summarize a file protected by a DLP/IRM rule (download/print/copy prevented).
**Expected:** Gemini does not retrieve the IRM-protected file to generate the response.

## Test 6 — Exposure probe: CSE content is not usable
**Do:** As a pilot user, ask Gemini to work with a **Client-Side Encrypted** document.
**Expected:** Gemini cannot use the CSE content — it is indecipherable to the assistant.

## Test 7 — Use-case-to-policy alignment holds
**Do:** For each approved pilot use case, confirm it grounds only in the data its policy permits (review the use-case-to-policy map against actual behavior).
**Expected:** Each use case stays within its permitted data; no approved use case grounds in out-of-scope content.

## Test 8 — Data-exposure numbers improved
**Do:** Run `GEMGOV-Report.ps1` and compare against the Step 1 baseline. Cross-check the **security investigation tool** for Gemini's Drive access.
**Expected:** Fewer broadly/externally shared items and more protected content than the pre-remediation baseline; Gemini access is confined to remediated, in-scope content.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–5 pass; the exposure probes (Tests 4–5) confirm restricted/IRM-protected content is not surfaced; enablement and data-access are pilot-only |
| **Expand pass** | Tests 1–3, 7, 8 pass for the newly remediated scope before the next enablement wave |
