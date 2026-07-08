# 6. Troubleshooting Guide — Business Glossary & Stewardship Program (Microsoft Purview)

Symptom → cause → resolution for the common issues when standing up and running the glossary and
stewardship program. Because Purview Data Governance is **evolving**, several fixes end in "verify the
current path / API version for your tenant" — that is expected, not a defect.

---

## Sign-in, endpoint, and token

**`DGGLOSS-Discovery.ps1` reports the endpoint as GAP / not reachable.**
- *Cause:* wrong account name, no role on the account, or a moved account API version.
- *Resolution:* confirm the short `-PurviewAccount` name resolves to
  `https://<name>.purview.azure.com`; confirm you hold at least **Data reader** on the target domain;
  and **verify the current Atlas glossary / account API version for your tenant** — the example
  versions in the scripts are illustrative.

**"Not signed in. Run Connect-AzAccount first." / token acquisition fails.**
- *Cause:* no Azure context, or the `Az.Accounts` module is missing.
- *Resolution:* `Install-Module Az.Accounts -Scope CurrentUser`, then `Connect-AzAccount` with a
  modern-auth/MFA-capable admin. Confirm `Get-AzAccessToken -ResourceUrl https://purview.azure.net`
  returns a token. The scripts never store a secret — they acquire the token from your sign-in.

**A write returns 401/403 even though sign-in works.**
- *Cause:* the account can read but lacks the **governance role** to write (data steward / governance
  domain owner) on the domain.
- *Resolution:* assign the least-privilege write role at the **domain scope** (Requirements R2), then
  re-run `-Commit`. Do not escalate to tenant admin to "make it work".

## Domains, glossaries, and API surface

**`DGGLOSS-Discovery.ps1` shows "Governance domns: GAP/verify".**
- *Cause:* the Unified Catalog governance-domain API path/version has moved, or Data Governance is not
  enabled for the tenant.
- *Resolution:* confirm the **Unified Catalog** loads in the portal (Requirements R1) and **verify the
  current governance-domain API version** for your tenant; update the `api-version` in the script to
  match. Glossary operations can still proceed via the Atlas glossary API even while the newer
  governance-domain API differs.

**`DGGLOSS-Configure-Glossary.ps1 -SeedTerms` says "No glossary found".**
- *Cause:* there is no glossary to anchor terms to yet.
- *Resolution:* create the glossary/governance domain in the Unified Catalog first (portal), then
  re-run; or pass `-GlossaryGuid` explicitly. Verify the current create path for your tenant.

## Scope and seeding

**Configure refuses to seed: "Scope has N incomplete term(s)".**
- *Cause:* one or more candidate rows is missing name, definition, owner, or steward.
- *Resolution:* this is the intended gate — complete the rows with the data owner and re-run
  `DGGLOSS-Set-Scope.ps1`, then seed. A term without an owner and definition must not be created.

**Terms were created but are not visible to the business.**
- *Cause:* correct behavior — new terms are created in **Draft**, which is not business-visible.
- *Resolution:* have the owner approve and move them to **Published** (Implementation Step 7). Do not
  bypass the approval gate to make them visible.

## Workflow and publishing

**A steward was able to Publish a term without approval.**
- *Cause:* the term-approval workflow is not configured (or the tenant lacks the built-in workflow) and
  the manual gate was skipped.
- *Resolution:* configure the approval workflow for the domain, or enforce the documented manual
  approval step in the RACI (Implementation Step 5). **Verify approval-workflow availability for your
  tenant** — where it is unavailable, the manual gate is mandatory. Return the wrongly-Published term
  to Draft, correct, re-approve.

**`DGGLOSS-Validate.ps1` reports GATE: FAIL — Published-incomplete > 0.**
- *Cause:* a Published term is missing a definition, owner, or steward — it should never have reached
  Published.
- *Resolution:* set the term back to **Draft** (`-SetStatus Draft -Commit`), fix the missing property,
  re-approve, and re-Publish. Re-run `DGGLOSS-Validate.ps1` until the gate is PASS.

## Upkeep and reporting

**`DGGLOSS-Report.ps1` shows unowned Published terms (> 0).**
- *Cause:* a term was Published without an owner recorded, or an owner left and was not reassigned.
- *Resolution:* assign a data owner immediately — treat this as a defect, not a nuance. The target is
  **zero** unowned Published terms.

**Report shows many "stale Published terms".**
- *Cause:* Published definitions have not been re-certified within the interval.
- *Resolution:* run the steward cadence — re-certify current terms, retire superseded ones to
  **Expired** (`-SetStatus Expired -Commit`). Consider shortening the cadence if staleness recurs.

**Stale detection looks wrong / timestamps missing.**
- *Cause:* the term's `updateTime` field is absent or in a different shape than expected in your
  tenant's API response.
- *Resolution:* the report degrades safely (a term with no timestamp is simply not flagged stale);
  **verify the current term schema / API version for your tenant** and adjust the timestamp field if
  Microsoft has changed it.

## When a term's *meaning* is disputed
- *Cause:* two teams disagree on the authoritative definition.
- *Resolution:* this is a **business determination, not a tooling problem**. Keep the term in
  **Draft/Review**, escalate to the data owner (and compliance/records where a regulated element is
  involved) to set the authoritative meaning, then approve and Publish. The solution records the
  decision; it does not adjudicate it.
