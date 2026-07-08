# 1. Solution Overview — CJIS DLP Pack (Microsoft Purview)

## What this solution is
Criminal Justice Information (CJI) — criminal history record information, identity-history and
biometric references, NCIC/III query returns, and the case and incident data derived from them — must
be protected to the FBI **CJIS Security Policy**. In a Microsoft 365 tenant that means CJI cannot be
allowed to leak out through email, SharePoint/OneDrive sharing, Teams, or endpoint channels
(USB, print, cloud upload), and every attempt must leave an **audit trail** you can show an assessor.
This solution is the **Data Loss Prevention (DLP) pack** for CJI in **Microsoft Purview**: a
CJI-detection classification set, a DLP policy that protects CJI across the M365 workloads, and the
**evidence** (alerts, activity, reports) that demonstrates the control is live and working — configured,
**piloted in simulation/test first**, validated against pass/fail gates, and then enforced.

It is built entirely from the **Microsoft Purview portal**, **Security & Compliance PowerShell**
(`Connect-IPPSSession`), and **Microsoft Graph** — no third-party tooling. Five PowerShell scripts do the
discovery, the simulation-first configuration, the validation, the evidence reporting, and a scope/health
check.

## Why this matters
- **CJI egress is the risk CJIS is written to stop.** A single CJI record forwarded to a personal
  mailbox, shared to "Anyone with the link," or copied to a thumb drive is exactly the disclosure the
  CJIS Security Policy exists to prevent. DLP is the technical control that detects and blocks it.
- **Detection has to be tuned to CJI, not generic PII.** An SSN match alone is not "CJI." CJI detection
  keys off criminal-justice identifiers and context (III/NCIC references, CHRI markers, agency case
  numbers) — a custom classification, not an off-the-shelf template. Getting detection right is most of
  the work.
- **Enforcing blind breaks the mission.** Flip a block policy on across a law-enforcement tenant with no
  tuning and you will block legitimate case work and generate a flood of false positives. Every CJIS
  DLP policy here is **piloted in simulation/test** so you see what *would* have matched, tune it, and
  only then enforce.
- **"We have DLP" is not evidence.** An assessor asks *show me*: which policy, what it detects, what it
  blocks, and the record of matches and admin actions. This pack produces that evidence as an artifact,
  not a claim.
- **Coverage gaps are silent.** CJI moves through email, collaboration, and endpoints. A policy scoped
  to Exchange only leaves SharePoint, Teams, and USB wide open. The scope/health check makes coverage
  explicit and licensing-aware.

## How it works
1. **Assess.** `DLPCJIS-Discovery.ps1` (read-only) inventories existing DLP policies and rules, the
   sensitive-information-types available in the tenant, and whether any CJI-specific classification
   already exists — so you build on what's there and avoid duplicate/overlapping policies.
2. **Design the CJI classification.** Define how CJI is detected in *your* environment: a **custom
   sensitive information type** and/or **keyword dictionary** for criminal-justice identifiers and CHRI
   context, optionally combined with built-in identity SITs (e.g. SSN, driver's-license number) as
   supporting evidence. *(What actually constitutes CJI in a given record is a determination for your
   CJIS/compliance authority — this solution provides the detection method, not the legal classification.)*
3. **Configure in simulation/test.** `DLPCJIS-Set-Policy.ps1` creates the CJIS DLP policy and its
   detection rule across the in-scope workloads in **test mode** (`TestWithNotifications` /
   `TestWithoutNotifications`) — `-WhatIf` by default, writing only with `-Commit`. Nothing blocks yet.
4. **Pilot & tune.** Let the policy run in simulation over the pilot period; review what it matched with
   `DLPCJIS-Report.ps1`. Tune the classification and rule confidence/instance thresholds until the match
   set is right — real CJI caught, routine work not flagged.
5. **Validate.** `DLPCJIS-Validation.ps1` (read-only) checks the deployed policy against explicit
   pass/fail gates: correct workload scope, the detection rule present with the intended action, and the
   policy in the expected mode.
6. **Enforce & expand.** Once simulation is clean, promote the policy to **enforce** (block/restrict) in
   a change window with `DLPCJIS-Set-Policy.ps1 -PromoteToEnforce -Commit`, then extend scope
   (e.g. endpoint DLP) as licensing allows. Rollback is a single command back to test/disabled.
7. **Evidence, continuously.** `DLPCJIS-Report.ps1` produces the ongoing evidence artifact — matches,
   actions, and DLP alerts (via Graph) — for CJIS audit and internal review.

## What you can control
- The CJI detection definition — which identifiers, keywords, and supporting SITs, and the confidence /
  instance-count thresholds that decide a match.
- The in-scope workloads (Exchange, SharePoint, OneDrive, Teams, and — licensing permitting — endpoints)
  and the policy's user/site scope.
- The enforcement action (block, block-with-override, restrict-external-only, notify) and the policy tip
  / notification wording.
- The pilot scope and duration, and the change-control path for promoting to enforce.
- The evidence cadence and what the report captures for your assessor.

## What stays with your CJIS / compliance / legal authority (be explicit)
This solution delivers the **technical DLP control and the evidence** — not the **CJIS determinations**.
Whether a given data element *is* CJI, the CJI retention schedule, the CJIS audit conclusions, personnel
screening / access authorization, and the FIPS-validated encryption and physical-media controls required
elsewhere in the CJIS Security Policy are the responsibility of your **CJIS Systems Officer (CSO) /
Terminal Agency Coordinator (TAC), compliance, and legal** functions. DLP is one control in a broader
CJIS program; this pack implements and evidences that one control well and defers the rest to the
accountable owners.

## Licensing reality (verify for your tenant)
Purview DLP is **licensing- and plan-dependent** and the portal **evolves**. DLP for Exchange Online,
SharePoint, OneDrive, and Teams is broadly available; **Endpoint DLP**, **Exact Data Match (EDM)**, and
**trainable classifiers** generally require **Microsoft 365 E5** or the **E5 Compliance** add-on, and
some capabilities are in preview. Custom sensitive information types and keyword dictionaries are widely
available but confirm for your plan. Every step below is flagged where availability depends on licensing —
**confirm capability and portal paths for your own tenant** before relying on them.

## The standard deployment model
> Assess → Design (CJI detection) → Configure (in **simulation/test**) → Pilot & tune → Validate →
> Expand (**enforce**). High-impact DLP changes are **always piloted in simulation/test before
> enforcement**, every change is `-WhatIf`-previewed and reversible, and CJIS/records/legal
> determinations are deferred to the accountable owners.
