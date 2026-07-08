# 3. Implementation Guide — Microsoft 365 Copilot Data-Protection Readiness (Microsoft Purview)

Follow these steps **in order**. Discovery, remediation, and validation are automated with Security &
Compliance PowerShell (`Connect-IPPSSession`) and Microsoft Graph; portal steps are done in the
**Microsoft Purview portal** (`https://purview.microsoft.com`), the **Microsoft 365 admin center**, and
the **SharePoint admin center**. Artifact names follow the `<Purpose> – <Scope> – <Stage>` convention
from the Overview and are reused verbatim. **Every high-impact change is piloted in
simulation/test/disabled first** — the scripts default to `-WhatIf` and to simulation/test mode, and no
write happens without `-Commit`.

> **Model:** confirm scope, discover the oversharing and unlabeled sensitive content, design the controls
> with stakeholders, configure and **pilot each control in simulation/test**, validate against gates,
> then expand to enforce, record the go/no-go, and review on a recurring cadence.
> Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce).**
>
> **Portal-path caveat.** Purview and SharePoint blades evolve and several controls are licensing-gated
> or in preview; the paths and policy locations below are the current map. If a blade, location, or
> cmdlet differs in your tenant, use the closest documented equivalent and **confirm before acting** —
> do not assume a path that is not present.

## Step 0 — Confirm scope, licensing, roles, and connections (Assess)
1. Run `AICOPILOT-ReadinessScope.ps1` (read-only). It confirms your `Connect-IPPSSession` /
   `Connect-MgGraph` sign-in, reports whether **auditing** is on, and enumerates the licensing-dependent
   levers available (sensitivity labels, label policies, DLP policies, auto-labeling policies) — resolving
   Requirements 2.1–2.4. It writes `Copilot Readiness – Tenant – Scope`.
2. In the Purview portal confirm **Information Protection**, **Data Loss Prevention**, and (if present)
   **DSPM for AI** render; in the SharePoint admin center confirm the SAM data-access-governance reports
   and controls are visible (Requirement 2.6). Note any capability that is absent so you scope around it.
3. Confirm the **Copilot rollout ring / pilot scope** and the change window (Requirements 2.5, 2.7)
   before any configuration.

**Pass/fail:** Sign-in succeeds, auditing is on, the levers are enumerated, pilot ring and change window
agreed. **Rollback:** None — read-only.

## Step 1 — Discover SharePoint/OneDrive oversharing (Assess)
1. Run `AICOPILOT-OversharingDiscovery.ps1` (read-only, Microsoft Graph). It inventories the in-scope
   SharePoint sites and surfaces the **oversharing signals** that make content reachable by Copilot:
   sites/items shared with **"Everyone Except External Users" (EEEU)** or organization-wide, broad
   **sharing links**, and large-audience access. It writes `Oversharing – Estate – Discovery`.
2. Where **SharePoint Advanced Management** is licensed (Requirement 2.6), also run the **Data Access
   Governance** reports in the SharePoint admin center (sharing links, EEEU, sensitivity labels applied)
   and reconcile them with the script output — the DAG reports are the authoritative tenant view; the
   script gives you a portable, filterable export.
3. Rank the results: broadly-shared sites are the priority targets, especially those that (per Step 2)
   also hold unlabeled sensitive content.

**Pass/fail:** The discovery export lists in-scope sites with their oversharing signal; top targets can
be named. **Rollback:** None — read-only.

## Step 2 — Assess unlabeled sensitive content (Assess)
1. Run `AICOPILOT-OversharingDiscovery.ps1 -IncludeSensitive` (read-only). It appends the **sensitive
   information types** in scope and the **label-coverage** picture (which in-scope locations have little
   or no labeling) into `Unlabeled Sensitive – Estate – Assess`, giving a portable record of where
   sensitive-but-unlabeled content is most likely concentrated.
2. Where **DSPM for AI** is present, cross-read its **data-access** and **sensitive-interactions** views
   as corroborating telemetry — this solution *remediates* what those views reveal.
3. Cross-read Steps 1–2: **broadly-shared sites holding unlabeled sensitive content are the top Copilot
   oversharing risk** and drive the remediation order.

**Pass/fail:** The unlabeled-sensitive export is written; the top "broad + sensitive" targets are named.
**Rollback:** None — read-only.

## Step 3 — Design the controls and agree the plan (Design)
1. With compliance/records/privacy/legal stakeholders (GR §5, Requirement 2.8), agree, for the pilot
   ring: (a) the **default label** to apply, and whether **mandatory labeling** is in scope; (b) which
   labels denote "**keep out of Copilot**" and therefore drive DLP for Copilot; (c) the **auto-labeling**
   conditions (which sensitive info types → which label); and (d) the **site access-reduction** list and
   whether interim **RSS/RCD** containment is warranted while cleanup proceeds.
2. Record this as the design baseline. **The determinations (what is "sensitive," acceptable exposure,
   what must be restricted) are the stakeholders'**; you provide the method and will implement the agreed
   technical changes and pilot them.

**Pass/fail:** The agreed control set and access-reduction list are recorded. **Rollback:** None — design
only.

## Step 4 — Configure & pilot labeling (Configure → Pilot)
1. **Default labeling (pilot).** In the Purview portal → **Information Protection → Label policies**,
   publish a label policy scoped to the **pilot ring** that sets a **default label** (and mandatory
   labeling if agreed). Name it `Default Labeling – Users – Pilot`. This ensures new/edited content is
   classified for the pilot population. *(Mandatory labeling availability is licensing-dependent —
   verify.)*
2. **Auto-labeling (simulation).** Run
   `AICOPILOT-Remediation.ps1 -Action AutoLabel -Scope "Auto-Label Sensitive – Pilot – Simulation"`
   (defaults to `-WhatIf`; add `-Commit` to create it). With `-Commit` it creates the auto-labeling
   policy `Auto-Label Sensitive – Pilot – Simulation` in **simulation mode** — it labels *nothing* yet,
   it only shows what it *would* label against the agreed conditions. This closes label-coverage gaps
   without risk.

**Pass/fail:** The pilot label policy is published to the ring; the auto-labeling policy exists in
**simulation** (labels nothing yet). **Rollback:** Unpublish the label policy and delete the simulation
auto-labeling policy — no content was changed.

## Step 5 — Configure & pilot DLP for Copilot (Configure → Pilot)
1. Run `AICOPILOT-Remediation.ps1 -Action DlpForCopilot -Scope "DLP for Copilot – Pilot – Test"` with
   `-Commit` to create the DLP policy `DLP for Copilot – Pilot – Test` in **test/disabled** mode, scoped
   to the **Microsoft 365 Copilot** location and conditioned on the agreed "keep out of Copilot"
   sensitivity labels — so Copilot will not process/summarize that content once enforced.
2. **Verify the Copilot DLP location name in your portal** — the script parameterizes the location and
   does not assume it, because the Copilot DLP location is evolving/licensing-gated *(verify)*. If the
   location is not present in your tenant, keep the "keep out of Copilot" content controlled via label
   **encryption/usage rights** (which Copilot honors) plus site access reduction (Step 6) as the
   available equivalent, and note DLP-for-Copilot as pending.

**Pass/fail:** The DLP-for-Copilot policy exists in **test/disabled** on the Copilot location — nothing
is enforced yet. **Rollback:** Delete the test policy; no interaction was blocked.

## Step 6 — Reduce SharePoint access & apply interim containment (Configure → Pilot)
1. Run `AICOPILOT-Remediation.ps1 -Action SiteAccessList -Scope "Site Access Reduction – Sites – Pilot"`
   (read-only by design). It produces the **prioritized site access-reduction list** from
   `Oversharing – Estate – Discovery` — the sites to tighten first. It does **not** silently change
   sharing.
2. For each pilot target, reduce access via the **documented SharePoint methods** (run under SharePoint
   Administrator): remove broad **EEEU**/org-wide grants and over-broad sharing links; where SAM is
   licensed, apply **Restricted Access Control (RAC)** to limit a site to a named group, and use **site
   access reviews** to drive owner cleanup.
3. **Interim containment while you clean up.** Where not-yet-remediated sites must be fenced off from
   Copilot immediately, apply the documented SharePoint controls: **Restricted Content Discovery (RCD)**
   on specific sites (excludes their content from Copilot and org-wide search), or tenant-wide
   **Restricted SharePoint Search (RSS)** — an interim allow-list of up to 100 sites — via the
   SharePoint Online Management Shell (`Set-SPOTenantRestrictedSearchMode`,
   `Add-SPOTenantRestrictedSearchAllowedListUrls`). Treat RSS/RCD as **temporary stopgaps**, not the
   end state — the goal remains fixing the underlying access. *(RSS/RCD availability is SAM/tenant
   dependent — verify.)*

**Pass/fail:** The access-reduction list is produced; pilot-site access is tightened and/or interim
RCD/RSS containment is applied and recorded. **Rollback:** Restore the prior sharing on any site where a
change broke legitimate access; turn RSS off (`Set-SPOTenantRestrictedSearchMode -Mode Disabled`) or
remove RCD to revert containment.

## Step 7 — Validate the pilot (Validate)
1. Let simulation/test run the agreed window. In the portal review the auto-labeling **simulation
   results** (what it would label) and the DLP-for-Copilot **test** matches (what it would keep out of
   Copilot) for false positives.
2. Run `AICOPILOT-Validation.ps1` (read-only). It confirms the pilot label policy is published, the
   auto-labeling policy is in **simulation**, the DLP-for-Copilot policy is in **test/disabled**, and
   re-reads the oversharing signal for the pilot sites to confirm it is lower after Step 6.
3. Confirm with stakeholders that the simulated outcomes match intent (no legitimate collaboration
   broken, no over-blocking of Copilot on appropriate content). See Testing (doc 5) for the explicit
   gates.

**Pass/fail:** Simulation/test results reviewed, acceptable false-positive rate, pilot oversharing
reduced. **Rollback:** If results are wrong, adjust the policy conditions / access changes and
re-pilot — enforce nothing until the gate passes.

## Step 8 — Expand, enforce, and record the go/no-go (Expand)
1. Only after the pilot gate passes: turn the auto-labeling policy from **simulation** to **on**, and the
   DLP-for-Copilot policy from **test** to **enforce**, and widen the label policy and access reduction
   beyond the pilot ring — as a deliberate, change-controlled step.
   `AICOPILOT-Remediation.ps1 -Action Enforce -Commit` performs the mode change on the named policies
   (still gated behind `-Commit`).
2. Complete the broad **SharePoint access reduction** on the remaining oversharing targets under change
   control, and remove any interim **RSS/RCD** containment once the underlying access is fixed.
3. Run `AICOPILOT-ReadinessReport.ps1` (read-only) to compile the **go/no-go readiness record**
   `Copilot Readiness – Tenant – GoNoGo` — the before/after oversharing, the controls applied and their
   state, and the residual risk — for stakeholder sign-off (Requirement 2.8). **The go/no-go decision is
   theirs**; the report is the evidence.
4. Stand up the recurring review: tag the cadence `Copilot Readiness Review – Tenant – Recurring` and
   schedule the read-only `ReadinessScope → OversharingDiscovery → Validation → ReadinessReport` chain
   (e.g. monthly) so readiness stays measured as data, sharing, and Copilot usage change.

**Pass/fail:** Controls enforced at broad scope, oversharing reduced on re-measure, go/no-go recorded and
signed off, recurring review scheduled. **Rollback:** Return any enforced policy to simulation/test (or
delete it) and restore prior sharing on any site where enforcement caused an issue; re-apply RSS/RCD
containment if broad rollout must pause. The discovery and go/no-go exports are the before-state to
restore toward.
