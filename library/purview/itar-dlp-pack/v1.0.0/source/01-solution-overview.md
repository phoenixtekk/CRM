# 1. Solution Overview — ITAR DLP Pack (Microsoft Purview)

## What this solution is
ITAR **technical data** — the drawings, models, specifications, schematics, source code, test data, and
documentation associated with defense articles on the **U.S. Munitions List (USML)** — must not be
disclosed to a **foreign person** or transmitted out of the United States without authorization. In a
Microsoft 365 tenant that means export-controlled technical data cannot be allowed to leak out through
email, SharePoint/OneDrive sharing, Teams, or endpoint channels (USB, print, cloud upload), and every
attempt must leave an **audit trail** you can show an export-compliance authority or auditor.
This solution is the **Data Loss Prevention (DLP) pack** for ITAR technical data in **Microsoft Purview**:
a technical-data detection classification set, a DLP policy that controls egress across the M365
workloads, and the **evidence** (alerts, activity, reports) that demonstrates the control is live and
working — configured, **piloted in simulation/test first**, validated against pass/fail gates, and then
enforced.

It is built entirely from the **Microsoft Purview portal**, **Security & Compliance PowerShell**
(`Connect-IPPSSession`), and **Microsoft Graph** — no third-party tooling. Five PowerShell scripts do the
discovery, the simulation-first configuration, the validation, the evidence reporting, and a scope/health
check.

## Why this matters
- **Uncontrolled egress of technical data is the exact ITAR risk.** A single controlled drawing forwarded
  to a personal mailbox, shared to "Anyone with the link," posted where a foreign-person colleague can
  read it, or copied to a thumb drive can be an unauthorized export or **deemed export**. DLP is the
  technical control that detects that movement and stops or restricts it.
- **Detection must be tuned to technical data, not generic PII.** Export-controlled technical data is not
  identified by an SSN or a credit-card number — it is identified by **export-control markings**
  (ITAR/USML references, distribution statements, the Arms Export Control Act warning legend), controlled
  drawing/part-number conventions, and program context. That is a custom classification, not an
  off-the-shelf template. Getting detection right is most of the work.
- **Enforcing blind breaks engineering work.** Flip a block policy on across a defense-program tenant with
  no tuning and you will block legitimate collaboration and generate a flood of false positives. Every
  policy here is **piloted in simulation/test** so you see what *would* have matched, tune it, and only
  then enforce.
- **"We have DLP" is not evidence.** An export-compliance reviewer asks *show me*: which policy, what it
  detects, what it restricts, and the record of matches and admin actions. This pack produces that
  evidence as an artifact, not a claim.
- **Coverage gaps are silent.** Technical data moves through email, collaboration, and endpoints. A policy
  scoped to Exchange only leaves SharePoint, Teams, and USB wide open. The scope/health check makes
  coverage explicit and licensing-aware.

## How it works
1. **Assess.** `DLPITAR-Discovery.ps1` (read-only) inventories existing DLP policies and rules, the
   sensitive-information-types available in the tenant, and whether any technical-data classification
   already exists — so you build on what's there and avoid duplicate/overlapping policies.
2. **Design the technical-data classification.** Define how ITAR technical data is detected in *your*
   environment: a **custom sensitive information type** and/or **keyword dictionary** for export-control
   markings and controlled drawing/part conventions, optionally combined with **sensitivity labels**
   (e.g. an "Export Controlled // ITAR" label) so labeled content is protected directly. *(What data is
   ITAR-controlled technical data — and who is a foreign person — is a determination for your
   export-control / legal authority, not this solution; the pack provides the detection and egress
   method, not the export classification.)*
3. **Configure in simulation/test.** `DLPITAR-Set-Policy.ps1` creates the ITAR DLP policy and its
   detection rule across the in-scope workloads in **test mode** (`TestWithNotifications` /
   `TestWithoutNotifications`) — `-WhatIf` by default, writing only with `-Commit`. Nothing blocks yet.
4. **Pilot & tune.** Let the policy run in simulation over the pilot period; review what it matched with
   `DLPITAR-Report.ps1`. Tune the classification and rule confidence/instance thresholds until the match
   set is right — real technical data caught, routine work not flagged.
5. **Validate.** `DLPITAR-Validation.ps1` (read-only) checks the deployed policy against explicit
   pass/fail gates: correct workload scope, the detection rule present with the intended egress action,
   and the policy in the expected mode.
6. **Enforce & expand.** Once simulation is clean, promote the policy to **enforce** (block/restrict
   external send and sharing) in a change window with `DLPITAR-Set-Policy.ps1 -PromoteToEnforce -Commit`,
   then extend scope (e.g. Endpoint DLP for USB/print/cloud upload) as licensing allows. Rollback is a
   single command back to test/disabled.
7. **Evidence, continuously.** `DLPITAR-Report.ps1` produces the ongoing evidence artifact — matches,
   actions, and DLP alerts (via Graph) — for export-compliance audit and internal review.

## What you can control
- The technical-data detection definition — which markings, keywords, drawing/part patterns, and
  supporting labels/SITs, and the confidence / instance-count thresholds that decide a match.
- The in-scope workloads (Exchange, SharePoint, OneDrive, Teams, and — licensing permitting — endpoints)
  and the policy's user/site scope.
- The egress action (block external send/share, block-with-override, restrict to internal/authorized
  recipients only, notify) and the policy tip / notification wording.
- The pilot scope and duration, and the change-control path for promoting to enforce.
- The evidence cadence and what the report captures for your reviewer.

## What stays with your export-control / legal authority (be explicit)
This solution delivers the **technical DLP control and the evidence** — not the **ITAR determinations**.
Whether a given item *is* ITAR-controlled technical data, whether a person is a **U.S. person** or a
**foreign person**, USML categorization, jurisdiction/classification (ITAR vs EAR), licensing and
authorization decisions, **deemed-export** access authorization, and Technology Control Plan (TCP)
obligations are the responsibility of your **Empowered Official, export-compliance officer, and legal**
functions. DLP is one control in a broader ITAR compliance program; this pack implements and evidences
that one control well and defers the export determinations to the accountable owners. In particular, DLP
controls **egress out of the tenant**; controlling **internal access by foreign persons** (the classic
deemed-export problem) is primarily an access-control / sensitivity-label / Conditional Access design
driven by a legal foreign-person determination — this pack flags where that boundary sits and does not
make the determination.

## Licensing reality (verify for your tenant)
Purview DLP is **licensing- and plan-dependent** and the portal **evolves**. DLP for Exchange Online,
SharePoint, OneDrive, and Teams is broadly available; **Endpoint DLP**, **Exact Data Match (EDM)**, and
**trainable classifiers** generally require **Microsoft 365 E5** or the **E5 Compliance** add-on, and some
capabilities are in preview. Custom sensitive information types and keyword dictionaries are widely
available but confirm for your plan. Every step below is flagged where availability depends on licensing —
**confirm capability and portal paths for your own tenant** before relying on them.

## The standard deployment model
> Assess → Design (technical-data detection) → Configure (in **simulation/test**) → Pilot & tune →
> Validate → Expand (**enforce**). High-impact DLP changes are **always piloted in simulation/test before
> enforcement**, every change is `-WhatIf`-previewed and reversible, and ITAR/export/legal determinations
> are deferred to the accountable owners.
