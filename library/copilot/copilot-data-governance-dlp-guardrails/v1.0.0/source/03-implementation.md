# 3. Implementation Guide — Microsoft 365 Copilot Data Governance & DLP Guardrails

Follow these steps **in order**. Discovery, validation, audit search, and reporting are automated with
read-only PowerShell (Microsoft Graph / Security & Compliance PowerShell); the guardrail policies are
created in the **Microsoft Purview portal** (`https://purview.microsoft.com`) and/or the bundled
`CPLTGOV-Guardrails.ps1`, which **defaults to `-WhatIf`/simulation** — nothing enforces without an
explicit `-Commit` and a passed pilot gate. Every object you create follows the `<Purpose> – <Scope> –
<Stage>` convention and is reused verbatim in Testing, Troubleshooting, and the scripts.

> **Model:** confirm scope → discover label coverage and sensitive content → design the controls with
> compliance stakeholders → configure and **pilot in simulation/test** → validate for false positives and
> audit capture → expand to enforce, record the governance report, review on a cadence.
> Pattern: **Assess → Configure → Pilot (simulate/test) → Validate → Expand (enforce).**
>
> **Portal-path caveat.** Purview blades evolve and several controls (DLP for Copilot especially) are
> licensing-gated or in preview. The paths below are the current map; if a blade, location, or cmdlet
> differs in your tenant, use the closest documented equivalent and **confirm before acting** — never
> assume a path that is not present.

## Objects you will create (naming reference)
| Object | Name | Where |
|---|---|---|
| Label-coverage inventory | `Copilot Label Coverage – Estate – Assess` | `CPLTGOV-Discovery.ps1` |
| Default label policy | `Default Labeling – Users – Pilot` | Purview / `CPLTGOV-Guardrails.ps1` |
| Auto-labeling (simulation) | `Auto-Label Sensitive – Pilot – Simulation` | Purview / `CPLTGOV-Guardrails.ps1` |
| DLP for Copilot (test) | `DLP for Copilot – Pilot – Test` | Purview / `CPLTGOV-Guardrails.ps1` |
| Copilot audit evidence | `Copilot Interaction Audit – Tenant – Validate` | `CPLTGOV-AuditSearch.ps1` |
| Governance evidence | `Copilot Governance Report – Tenant – Expand` | `CPLTGOV-Report.ps1` |
| Recurring cadence tag | `Copilot Governance Review – Tenant – Recurring` | scheduled script chain |

## Step 0 — Confirm scope, licensing, roles, and connections (Assess)
1. On the operator workstation, sign in for read-only work:
   - `Connect-IPPSSession` (Security & Compliance PowerShell).
   - `Connect-MgGraph -Scopes "AuditLog.Read.All","InformationProtectionPolicy.Read"` (Graph).
2. Run `CPLTGOV-Discovery.ps1 -ScopeOnly` (read-only). It confirms the sign-ins, enumerates the
   licensing-dependent levers available (labels, label policies, DLP policies, auto-labeling policies),
   checks whether the **Copilot DLP location** is offered, and confirms **auditing** is on
   (Requirements 2.1–2.5). Note anything absent so you scope around it.
3. Confirm the **pilot ring** and the **simulation window** (Requirement 2.6) and that compliance
   stakeholders are engaged (Requirement 2.7) before any configuration.

**Pass/fail:** Sign-ins succeed, levers enumerated, Copilot DLP location availability known, auditing on,
pilot ring and window agreed. **Rollback:** None — read-only.

## Step 1 — Discover label coverage & sensitive content (Assess)
1. Run `CPLTGOV-Discovery.ps1` (read-only). It reports the published **labels** and **sensitive
   information types**, and the **label-coverage** picture for the Copilot-accessible estate — which
   in-scope locations have little or no labeling — writing `Copilot Label Coverage – Estate – Assess`.
2. Where **DSPM for AI** is present, cross-read its data-access and sensitive-interactions views as
   corroborating telemetry — this solution *governs* what those views reveal.
3. Rank: locations with **unlabeled sensitive content** that Copilot can reach are the priority for
   labeling and for the "keep out of Copilot" DLP condition.

**Pass/fail:** The coverage export is written; the top unlabeled-sensitive locations can be named.
**Rollback:** None — read-only.

## Step 2 — Design the controls with compliance stakeholders (Configure)
1. With compliance/records/privacy/legal stakeholders (Requirement 2.7), agree, for the pilot ring:
   (a) the **default label** to apply; whether **mandatory labeling** is in scope; (b) which labels denote
   "**keep out of Copilot**" and therefore drive DLP-for-Copilot; (c) the **auto-labeling** conditions
   (which sensitive info types → which label); and (d) the **prompt/response guardrails** derived from the
   responsible-use policy (Requirement 2.8).
2. **Record this as the design baseline.** *The determinations (what is "sensitive," acceptable exposure,
   what must be blocked) are the stakeholders'* — you provide the method and will implement and pilot the
   agreed technical controls.

**Pass/fail:** The agreed control set and "keep out of Copilot" label list are recorded. **Rollback:**
None — design only.

## Step 3 — Configure & pilot labeling (Configure → Pilot)
1. **Default labeling (pilot).** In the Purview portal → **Information Protection → Label policies**,
   publish a policy scoped to the **pilot ring** that sets a **default label** (and mandatory labeling if
   agreed). Name it `Default Labeling – Users – Pilot`. *(Mandatory labeling availability is
   licensing-dependent — verify.)*
2. **Auto-labeling (simulation).** Run
   `CPLTGOV-Guardrails.ps1 -Action AutoLabel -Name "Auto-Label Sensitive – Pilot – Simulation"`
   (defaults to `-WhatIf`; add `-Commit` to create it). With `-Commit` it creates the auto-labeling policy
   in **simulation mode** — it labels *nothing* yet; it only shows what it *would* label against the
   agreed conditions, sizing the coverage gap without risk.

**Pass/fail:** The pilot label policy is published to the ring; the auto-labeling policy exists in
**simulation** (labels nothing yet). **Rollback:** Unpublish the label policy; delete the simulation
auto-labeling policy — no content was changed.

## Step 4 — Configure & pilot DLP for Copilot (Configure → Pilot)
1. Run `CPLTGOV-Guardrails.ps1 -Action DlpForCopilot -Name "DLP for Copilot – Pilot – Test"` with
   `-Commit` to create the DLP policy `DLP for Copilot – Pilot – Test` in **test/disabled** mode, scoped
   to the **Microsoft 365 Copilot** location and conditioned on the agreed "keep out of Copilot"
   sensitivity labels — so Copilot will not process/summarize that content **once enforced**.
2. **Verify the Copilot DLP location name in your portal** — the script parameterizes the location and
   does not assume it, because the Copilot DLP location is evolving/licensing-gated *(verify)*. If the
   location is not present in your tenant, keep the "keep out of Copilot" content controlled via label
   **encryption/usage rights** (which Copilot honors) and note DLP-for-Copilot as pending.

**Pass/fail:** The DLP-for-Copilot policy exists in **test/disabled** on the Copilot location — nothing is
enforced yet. **Rollback:** Delete the test policy; no interaction was blocked.

## Step 5 — Configure prompt/response guardrails & audit (Configure → Pilot)
1. **Guardrails.** Map the responsible-use policy to the technical controls: the "keep out of Copilot"
   labels (Step 4) plus any content-exclusion via labels/encryption define what Copilot may *use*; capture
   the agreed handling of generated content (e.g. labeling of Copilot outputs where supported) as part of
   the design baseline.
2. **Audit & eDiscovery.** Confirm Copilot interactions are recorded: run `CPLTGOV-AuditSearch.ps1`
   (read-only) to retrieve recent **Copilot interaction** audit events into
   `Copilot Interaction Audit – Tenant – Validate`, and confirm they are discoverable via **eDiscovery**
   (Purview portal → **eDiscovery**). This is the evidence trail the guardrails rely on.

**Pass/fail:** Guardrail mapping recorded; Copilot interaction audit events retrievable and
eDiscoverable. **Rollback:** None — read-only for the audit path.

## Step 6 — Validate the pilot (Validate)
1. Let simulation/test run the agreed window. In the portal review the auto-labeling **simulation
   results** (what it would label) and the DLP-for-Copilot **test** matches (what it would keep out of
   Copilot) for **false positives**.
2. Run `CPLTGOV-Validate.ps1` (read-only). It confirms the pilot label policy is published, the
   auto-labeling policy is in **simulation**, the DLP-for-Copilot policy is in **test/disabled**, and
   auditing is on. It writes a validation summary.
3. Confirm with stakeholders that the simulated outcomes match intent (no legitimate Copilot use
   over-blocked, sensitive content correctly matched). See Testing (doc 5) for the explicit gates.

**Pass/fail:** Simulation/test reviewed, acceptable false-positive rate, audit capture confirmed.
**Rollback:** If results are wrong, adjust the policy conditions and re-pilot — enforce nothing until the
gate passes.

## Step 7 — Expand, enforce, and record the governance evidence (Expand)
1. Only after the pilot gate passes: turn the auto-labeling policy from **simulation** to **on**, and the
   DLP-for-Copilot policy from **test** to **enforce**, and widen the label policy beyond the pilot ring —
   as a deliberate, change-controlled step. `CPLTGOV-Guardrails.ps1 -Action Enforce -Commit` performs the
   mode change on the named policies (still gated behind `-Commit`).
2. Run `CPLTGOV-Report.ps1` (read-only) to compile the **governance evidence record**
   `Copilot Governance Report – Tenant – Expand` — label coverage before/after, the controls applied and
   their state, the audit-capture confirmation, and the residual risk — for stakeholder sign-off. **The
   classification and acceptable-use determinations remain the stakeholders'**; the report is the evidence.
3. Stand up the recurring review: tag the cadence `Copilot Governance Review – Tenant – Recurring` and
   schedule the read-only `Discovery → AuditSearch → Validate → Report` chain (e.g. monthly) so governance
   stays measured as data, labels, and Copilot usage change.

**Pass/fail:** Controls enforced at agreed scope, coverage improved on re-measure, governance report
compiled and signed off, recurring review scheduled. **Rollback:** Return any enforced policy to
simulation/test (or delete it) if enforcement causes an issue; the discovery and report exports are the
before-state to restore toward.
