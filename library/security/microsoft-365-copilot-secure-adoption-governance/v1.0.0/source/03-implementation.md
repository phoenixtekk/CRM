# 3. Implementation Guide — Microsoft 365 Copilot Secure Adoption & Governance

Follow these steps **in order**, across three portals: the **Microsoft 365 admin center**
(`https://admin.microsoft.com`), **Microsoft Purview** (`https://purview.microsoft.com`), and the
**SharePoint admin center** (`https://<tenant>-admin.sharepoint.com`).

> **Model:** Assess and remediate the data estate **first**, configure the protection Copilot honors,
> govern AI use, then enable Copilot for a small curated pilot, validate exposure, and only then
> expand. Copilot exposure equals what the user can access — so access is fixed before Copilot is on.

Name every object exactly as shown, in the form `<Purpose> – <Scope> – <Stage>`, and reuse the names
verbatim across scripts, assignments, and reports.

## Step 1 — Assess oversharing and access (read-only)
1. Run `COPILOT-Discovery.ps1` to enumerate broad sharing and Copilot-readiness signals: sites and
   OneDrive with org-wide / "Everyone except external users" links, anonymous/anyone links, external
   (guest) access, and whether sensitivity labels exist.
2. Run `COPILOT-Report.ps1` to produce the data-exposure and readiness summary (how much content is
   broadly shared, externally shared, and unlabeled).
3. In the SharePoint admin center → **Policies → Sharing**, note the tenant and per-site external
   sharing posture. In **Sites → Active sites**, sort by external sharing to find the widest sites.
4. Record the highest-risk sites/links as the remediation worklist. **Do not enable Copilot yet.**

## Step 2 — Remediate oversharing (restrict broad access)
1. Review the remediation worklist from Step 1 with the site/content owners (do not silently remove
   access people rely on).
2. Run `COPILOT-Remediation.ps1` in its default `-WhatIf` mode to preview the changes it would make
   (removing anonymous/org-wide links and flagging broad grants). Review the preview with owners.
3. Re-run `COPILOT-Remediation.ps1 -Apply` to remove anonymous/"anyone" links and org-wide links on
   the targeted scope. Broad group grants (e.g. "Everyone except external users") are **reported for
   owner action**, not silently deleted.
4. In the SharePoint admin center → **Policies → Sharing**, tighten the tenant default (e.g. move
   from "Anyone" to "New and existing guests" or "Only people in your organization" where policy
   allows) and set a default link type of "Specific people".
5. Clean up stale guest access via Entra → **Identity governance → Access reviews** for guests, and
   via the site-level **Site permissions**.

## Step 3 — Publish sensitivity labels (protection Copilot honors)
1. In Microsoft Purview → **Information Protection → Labels**, create the taxonomy, for example:
   `Public`, `Internal`, `Confidential`, and `Highly Confidential`. Apply **encryption and usage
   rights** on the protected labels so only entitled users can open the content.
2. Go to **Information Protection → Label policies → Publish labels**, publish to your users
   (start with the pilot scope), and set a **default label** and mandatory-labeling behavior per policy.
3. Where available, configure **auto-labeling** (service-side) to classify sensitive content at scale
   so protection does not depend on every user labeling by hand.
4. Confirm intent: Copilot will not surface encrypted content to users who lack rights, and
   Copilot-generated output **inherits** the most restrictive source label.

## Step 4 — Configure DLP and Copilot data controls
1. In Purview → **Data Loss Prevention → Policies → Create policy**, scope a policy that targets the
   **Microsoft 365 Copilot** location (where available) and configure it to **exclude labeled
   content** (e.g. `Highly Confidential`) from being processed/summarized by Copilot. Name it
   `Copilot Data Exclusion – Highly Confidential – Pilot`.
2. Start the DLP policy in **test / simulation mode**, review matches, then turn it on for the pilot scope.
3. Apply **Restricted SharePoint Search** (or the current Copilot data-control equivalent) as a
   temporary containment: limit Copilot and org-wide search to a curated **allowed list of sites**
   while remaining oversharing is being remediated. Note this narrows legitimate search too — treat it
   as temporary and lift it as remediation completes. Portal-specific toggles for these controls are
   volatile; defer exact navigation to Microsoft's documentation.

## Step 5 — Create the Copilot pilot group
1. Run `COPILOT-Set-ScopeTargeting.ps1` (default `-WhatIf`) to preview, then `-Apply` to create
   `Copilot Adoption – Pilot Users – Pilot` (reused if it already exists).
2. Add a few representative pilot users (mix of roles) to the group. Do not add the whole org.

## Step 6 — Set AI-governance guardrails (acceptable use + admin controls)
1. Publish the **acceptable-use policy** for Copilot to the pilot users: permitted uses, the
   requirement to review AI-generated output before trusting/sharing it, and data-handling
   expectations. Name the governance owners.
2. In the Microsoft 365 admin center → **Copilot** admin experience, review the available
   organization controls (licensed users, and where available web-grounding and plugin/agent
   settings). Set them to the conservative pilot posture. Defer volatile portal specifics to Microsoft
   documentation.

## Step 7 — Enable Copilot for the pilot
1. In the Microsoft 365 admin center → **Billing → Licenses → Microsoft 365 Copilot**, assign Copilot
   licenses **only** to the members of `Copilot Adoption – Pilot Users – Pilot` (group-based licensing
   is preferred so scope stays tied to the group).
2. Confirm the DLP-for-Copilot policy, labels, and restricted-search scope are active for the pilot.

## Step 8 — Validate the pilot
1. Run `COPILOT-Validation.ps1` to confirm, per scope: broad-sharing links removed on the targeted
   sites, labels published/applied, and Copilot licenses limited to the pilot group.
2. Run `COPILOT-Report.ps1` to confirm the data-exposure numbers moved in the right direction
   (fewer broadly/externally shared items, more labeled content).
3. Perform the exposure probes in the **Testing Guide** (ask Copilot, as a pilot user, for content it
   should **not** be able to surface, and confirm it cannot). Complete the pilot gate.

## Step 9 — Expand to production
1. Only after the pilot passes: widen the remediated scope, lift **Restricted SharePoint Search**
   containment as sites are cleaned, and expand label/DLP policies from the pilot scope to broader
   scopes.
2. Grow the pilot group (or add production groups) and assign Copilot licenses in controlled waves,
   re-running `COPILOT-Report.ps1` after each wave.
3. Stand up recurring **access reviews** and re-run `COPILOT-Discovery.ps1` on a schedule so
   oversharing does not drift back after Copilot is live.

---
### Order of operations
`Assess oversharing → Remediate sharing → Publish labels → DLP + search controls → Pilot group → AI
governance → Enable Copilot (pilot) → Validate → Expand`
