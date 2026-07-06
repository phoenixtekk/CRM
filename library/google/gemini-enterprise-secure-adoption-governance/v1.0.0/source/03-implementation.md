# 3. Implementation Guide — Gemini Enterprise: Secure Adoption, Guardrails & Data-Access Boundaries

Follow these steps **in order**, primarily in the **Google Workspace Admin console**
(`https://admin.google.com`), with checks in the **Drive audit log** / **security investigation
tool** and **Google Vault**.

> **Model:** Assess and remediate the data estate **first**, set the guardrails and data-access
> boundaries Gemini honors, align use cases to policy, govern AI use, then enable Gemini for a small
> curated pilot OU/group, validate exposure, and only then expand. Gemini exposure equals what the
> user can access — so access is fixed before Gemini is on.

> **Verify in your tenant.** Gemini Enterprise admin pages, edition sub-pages, and connector
> availability are evolving / partly preview. The paths below reflect Google's current public
> documentation; confirm the exact toggles for your edition before relying on them, and defer volatile
> specifics to Google's documentation. Never assume a control exists that you have not confirmed.

Name every object exactly as shown, in the form `<Purpose> – <Scope> – <Stage>`, and reuse the names
verbatim across scripts, assignments, and reports.

## Step 1 — Assess oversharing and access (read-only)
1. Run `GEMGOV-Discovery.ps1` to enumerate broad Drive sharing and Gemini-readiness signals:
   files/folders shared "anyone with the link" (public) or domain-wide, external (guest) shares,
   shared-drive membership breadth, and whether DLP/IRM protection is in place.
2. Run `GEMGOV-Report.ps1` to produce the data-exposure and readiness summary (how much content is
   broadly shared, externally shared, and unprotected).
3. In the Admin console → **Apps → Google Workspace → Drive and Docs → Sharing settings**, note the
   tenant external-sharing posture. Use the **Drive audit log** / **security investigation tool** to
   find the widest-shared content.
4. Record the highest-risk files/shared drives as the remediation worklist. **Do not enable Gemini
   yet.**

## Step 2 — Remediate oversharing (restrict broad access)
1. Review the remediation worklist from Step 1 with the content/shared-drive owners (do not silently
   remove access people rely on).
2. Run `GEMGOV-Remediation.ps1` in its default `-WhatIf` mode to preview the changes it would make
   (removing public/"anyone with the link" and domain-wide link grants, and flagging broad shares).
   Review the preview with owners.
3. Re-run `GEMGOV-Remediation.ps1 -Apply` to remove public/anyone-with-the-link and domain-wide grants
   on the targeted scope. Broad group / shared-drive grants are **reported for owner action**, not
   silently deleted.
4. In the Admin console → **Drive and Docs → Sharing settings**, tighten the tenant default (e.g.
   restrict sharing outside the organization, disable "anyone with the link", set the default link to
   "restricted"/specific people) where policy allows. Apply **Trust rules in Drive** to bound
   internal/external sharing.
5. Clean up stale external/guest access via the sharing reports and shared-drive membership.

## Step 3 — Configure the guardrails Gemini honors (DLP / IRM / CSE / trust rules)
1. In the Admin console → **Security → Data protection**, create or confirm **DLP rules** that apply
   **IRM** (prevent download, print, copy) to your most sensitive content. Files protected this way
   are **not retrieved by Gemini** to generate a response.
2. Where required, confirm **Client-Side Encryption (CSE)** on the most sensitive content — CSE data
   is indecipherable to Gemini.
3. Confirm **Trust rules in Drive** restrict internal/external sharing consistently with policy.
4. (Optional, edition-dependent) Apply **Context-Aware Access** so the Gemini surface is only
   reachable from compliant devices/locations. *(Verify availability in your tenant.)*
5. Confirm intent: Gemini will not retrieve IRM/CSE-protected content, and its grounding is bounded by
   sharing + trust rules.

## Step 4 — Set the data-access boundary (ground only in the right data)
1. In the Admin console → **Generative AI → Gemini Enterprise**, open the sub-page for your edition
   (e.g. **Business edition**, or **Standard / Plus / Frontline**) and review
   **"Allow Gemini Enterprise to access Google Workspace data"**. Scope the decision to the pilot OU
   or configuration group only — leave it off for everyone else. *(Exact edition sub-page varies —
   verify in your tenant.)*
2. Where present, set **conversation sharing** options (Off / allowlisted domains / On) to the
   conservative pilot posture. *(Business edition; verify in your tenant.)*
3. Do **not** turn the Gemini service on for the org yet — service enablement is Step 7.

## Step 5 — Create the pilot scope
1. Run `GEMGOV-Set-ScopeTargeting.ps1` (default `-WhatIf`) to preview, then `-Apply` to create the
   `Gemini Adoption – Pilot Users – Pilot` group (reused if it already exists).
2. Add a few representative pilot users (mix of roles). Do not add the whole org. If you prefer to
   scope by OU, place the pilot users in the pilot OU instead and target settings there.

## Step 6 — Govern AI use (acceptable use + use-case-to-policy alignment)
1. Publish the **acceptable-use policy** for Gemini to the pilot users: permitted uses, the
   requirement to review AI-generated output before trusting/sharing it, and data-handling
   expectations. Name the governance owners.
2. Build the **use-case-to-policy map**: for each approved use case, record the data it may ground in
   and the governance policy that permits it — so what Gemini is used for aligns to what data
   governance allows.
3. Confirm the **security & legal** partnership has signed off on data handling, retention, and how
   Google processes Gemini data (see Solution Overview) for the pilot scope.

## Step 7 — Enable Gemini for the pilot
1. In the Admin console → **Generative AI → Gemini Enterprise → Service status**, turn Gemini
   **on for the pilot OU / configuration group only** (not "On for everyone"). *(Verify the exact
   toggle in your tenant.)*
2. Confirm the data-access boundary (Step 4), DLP/IRM/CSE guardrails (Step 3), and trust rules are
   active for the pilot scope.

## Step 8 — Validate the pilot
1. Run `GEMGOV-Validation.ps1` to confirm, per scope: broad-sharing links removed on the targeted
   content, DLP/IRM protection present, and Gemini enabled/data-access scoped to the pilot only.
2. Run `GEMGOV-Report.ps1` to confirm the data-exposure numbers moved in the right direction (fewer
   broadly/externally shared items, more protected content).
3. Perform the **exposure probes** in the Testing Guide (as a pilot user, ask Gemini for content it
   should **not** be able to surface, and confirm it cannot). Use the **security investigation tool**
   to review Gemini's Drive access. Complete the pilot gate.

## Step 9 — Expand to production
1. Only after the pilot passes: widen the remediated scope, extend the data-access boundary and DLP/IRM
   from the pilot to broader scopes, and turn Gemini on for additional OUs/groups in controlled waves.
2. Re-run `GEMGOV-Report.ps1` after each wave; grow the pilot scope (or add production groups).
3. Stand up recurring **access reviews** and re-run `GEMGOV-Discovery.ps1` on a schedule (and monitor
   the security investigation tool) so oversharing does not drift back after Gemini is live.

---
### Order of operations
`Assess oversharing → Remediate sharing → DLP/IRM/CSE + trust rules → Data-access boundary → Pilot
scope → AI governance (acceptable use + use-case-to-policy) → Enable Gemini (pilot) → Validate →
Expand`
