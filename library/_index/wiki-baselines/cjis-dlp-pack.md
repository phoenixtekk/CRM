# CJIS DLP Pack — Microsoft Purview

> **Version 1.0.0** · Category: Purview · Solution code: DLPCJIS

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — CJIS DLP Pack (Microsoft Purview)

Criminal Justice Information — criminal history record information, identity-history and biometric
references, NCIC/III query returns, and the case data derived from them — must be protected to the FBI
**CJIS Security Policy**. In a Microsoft 365 tenant, the control that stops CJI from leaking out through
email, SharePoint/OneDrive sharing, Teams, and endpoints (USB, print, cloud upload) is **Data Loss
Prevention**. Most organizations either have no CJI DLP at all, or a generic policy that over-matches and
gets ignored — and, either way, no **evidence** to show a CJIS assessor. This solution delivers CJI DLP in
**Microsoft Purview** the right way: detection tuned to CJI, a policy piloted in **simulation/test** before
it ever blocks, validated against pass/fail gates, and backed by continuous evidence.

It gives you a repeatable way to define a **CJI detection** set (a custom sensitive information type /
keyword dictionary, supporting identity SITs, and — where licensed — Exact Data Match), author a **DLP
policy** across the in-scope M365 workloads, **pilot it in simulation** so you can tune it without
disrupting case work, **validate** it, then **enforce** it — using only the Microsoft Purview portal,
Security & Compliance PowerShell, and Microsoft Graph.

This is a complete, deploy-it-today package for the CJI DLP control, written for a competent
M365/compliance administrator working under a CJIS program.

## What you get
- A plain-language Solution Overview of CJI DLP in Purview, the detection approach, coverage, and the
  phased simulate-first model.
- A Requirements Guide with verify / implement-if-missing for every prerequisite, including which DLP
  surfaces your licensing actually unlocks.
- An Implementation Guide of precise, ordered portal + PowerShell + Graph steps, with the policy piloted
  in simulation first and every policy, rule, and classification named.
- Five PowerShell scripts: a read-only assessment/baseline, a simulation-first policy tool (`-WhatIf` by
  default, `-Commit` to write, `-PromoteToEnforce` to enforce, `-Disable` to roll back), a validation
  gate-check, a Graph-based evidence report, and a scope/health helper.
- Testing and Troubleshooting guides for a confident, safe rollout.

## What this delivers
CJI detection tuned to catch real criminal-justice information without flagging routine work; a DLP policy
protecting CJI across Exchange, SharePoint, OneDrive, and Teams (and endpoints where licensed); a clean
simulation pilot before any enforcement; validated pass/fail gates; and a continuously refreshed evidence
artifact — policy in force, what it detects, matches and admin actions — that stands up in a CJIS audit.

## The deployment model
Assess → Design → Configure (**simulate**) → Pilot & tune → Validate → Expand (**enforce**).

## Scope boundary
This solution delivers and evidences the **DLP control** — one control within the broader CJIS Security
Policy. Whether a given data element *is* CJI, the CJI retention schedule, the CJIS audit conclusions,
personnel screening / access authorization, and the FIPS-validated encryption and physical-media controls
required elsewhere are **deferred to your CJIS Systems Officer / Terminal Agency Coordinator, compliance,
records, and legal** functions. This pack provides the technical method and evidence, not the CJIS
determination.

## Outcome
CJI Data Loss Prevention stood up the right way in Microsoft Purview — detection tuned, policy piloted in
simulation and validated, enforcement reversible and recorded, and the evidence to prove the control is
live and defensible.


---


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


---


# 2. Requirements Guide — CJIS DLP Pack (Microsoft Purview)

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-purview.md` (the six
shared requirements: compliance licensing, least-privilege Purview roles, the S&C PowerShell + Graph
toolchain, in-scope data sources, compliance/records/privacy/legal stakeholders, and a pilot scope with
change control) — those are referenced here, not repeated.

## 2.1 DLP-capable compliance licensing (and what it unlocks)
**Description:** A confirmed inventory of the tenant's **compliance licensing** for DLP. DLP for
Exchange Online, SharePoint, OneDrive, and Teams is broadly available; **Endpoint DLP**, **Exact Data
Match (EDM)**, and **trainable classifiers** generally require **Microsoft 365 E5** or the **E5
Compliance** add-on (Global Requirement 1).
**Why:** CJI moves through endpoints (USB, print, cloud upload) as well as mail and collaboration; how
far your CJI DLP coverage can reach depends on the plan. Scope the pack to what you can actually enforce.
**Verify:** Microsoft 365 admin center → `Billing → Licenses` for subscriptions/add-ons;
`DLPCJIS-Scope-Health.ps1` reports which DLP surfaces (workloads / endpoints) are licensed and onboarded.
Confirm DLP is visible in the Purview portal → `Data loss prevention` (verify path in your tenant).
**Implement:** Assign/purchase the required licensing before relying on a surface that needs it. Where a
surface is unlicensed (e.g. Endpoint DLP without E5), record it as a coverage gap rather than assuming
it is protected.

## 2.2 Least-privilege DLP administration roles
**Description:** An account holding the least-privilege Purview role to author DLP — **Compliance
Administrator** or **Compliance Data Administrator**, or the **DLP Compliance Management** role for
policy authoring; **Information Protection** roles for reviewing matched content — with Global
Administrator reserved only for one-time consent actions (Global Requirement 2).
**Why:** DLP policies and matched-content review expose sensitive CJI; the fine-grained role model
limits who can see and change them. Over-granting Global Admin undermines the control you are building.
**Verify:** Purview portal → `Settings → Roles & scopes → Role groups` (verify path) — confirm your
account is in **Compliance Administrator** (or a role group containing **DLP Compliance Management**).
`Connect-IPPSSession` succeeds and `Get-DlpCompliancePolicy` returns.
**Implement:** Add the account to the least-privilege compliance role group under change control; keep
who **administers** DLP separate from who **reviews** matched CJI content.

## 2.3 Security & Compliance PowerShell + Microsoft Graph toolchain
**Description:** A workstation with the **ExchangeOnlineManagement** module (provides
`Connect-IPPSSession` for the DLP cmdlets) and the **Microsoft Graph PowerShell SDK** (for reading DLP
alerts), with a modern-auth / MFA admin account (Global Requirement 3).
**Why:** Every script in this pack runs through S&C PowerShell (`*-DlpCompliancePolicy` /
`*-DlpComplianceRule`) and/or Graph (`/security/alerts_v2`).
**Verify:** `Get-Module -ListAvailable ExchangeOnlineManagement, Microsoft.Graph.Authentication`;
`Connect-IPPSSession` and `Connect-MgGraph` both succeed. `DLPCJIS-Discovery.ps1` reports connectivity.
**Implement:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser` and
`Install-Module Microsoft.Graph -Scope CurrentUser`; confirm modern-auth sign-in.

## 2.4 A defined CJI detection approach (classification method)
**Description:** An agreed way to **detect CJI** in your content — a **custom sensitive information type**
(regex + keyword evidence) and/or a **keyword dictionary** for criminal-justice identifiers and CHRI
context, optionally combined with built-in identity SITs (e.g. U.S. SSN, U.S. driver's-license number)
as supporting evidence, and — where licensed — **EDM** against a known CJI identifier set for high
precision (Global Requirement 4).
**Why:** Detection accuracy is most of a DLP program. Generic PII SITs alone over-match; CJI-specific
classification with the right confidence/instance thresholds is what makes the policy usable.
**Verify:** `DLPCJIS-Discovery.ps1` lists existing SITs and any CJI-related custom type; confirm with
your CJIS authority which identifiers and terms define CJI in scope.
**Implement:** Author the custom SIT / keyword dictionary in the Purview portal → `Data classification →
Classifiers → Sensitive info types` (verify path) before authoring the DLP rule.
*(What data **is** CJI is a determination for your CJIS Systems Officer / compliance authority — this
requirement is the detection method, not the legal classification.)*

## 2.5 In-scope workloads and endpoint onboarding status
**Description:** The **workloads in scope** for CJI protection — Exchange Online, SharePoint Online,
OneDrive, Teams, and (licensing permitting) **onboarded endpoints/devices** — and the user/site scope
the policy will target (Global Requirement 4).
**Why:** DLP keys off the in-scope workloads; endpoints must be explicitly onboarded before Endpoint DLP
can see them, and a mail-only policy leaves collaboration and USB channels open.
**Verify:** `DLPCJIS-Scope-Health.ps1` reports M365 workload availability and endpoint device-onboarding
status from the Purview device-onboarding surface. Confirm the in-scope list with stakeholders.
**Implement:** Define the scope; plan endpoint onboarding (Purview portal → `Settings → Device
onboarding`, verify path) if Endpoint DLP is in scope and licensed.

## 2.6 CJIS / compliance / records / legal stakeholders
**Description:** Engagement with the **CJIS Systems Officer (CSO) / Terminal Agency Coordinator (TAC)**,
and the **compliance, records, privacy, security, and legal** stakeholders whose policy the configuration
must satisfy — including the enforcement action (block vs allow-with-justification), notification wording,
and the CJI retention/records position (Global Requirement 5).
**Why:** DLP enforcement affects operational case work and must align to CJIS program policy, not
technical defaults. Retention/records and the CJIS determinations are theirs to make.
**Verify:** Named approvers recorded; the enforcement action, override policy, and evidence requirements
agreed in writing.
**Implement:** Identify the owners and capture the requirements before enforcing anything.

## 2.7 Graph read scope for DLP evidence (read-only)
**Description:** The delegated Graph scope needed for the evidence report to read DLP alerts:
`SecurityEvents.Read.All` (and `SecurityAlert.Read.All` where required for `alerts_v2`). No write scopes
are required.
**Why:** `DLPCJIS-Report.ps1` reads triggered DLP alerts via Graph `/security/alerts_v2` to build the
evidence artifact; keeping to read scopes matches the safe-by-default posture.
**Verify:** `DLPCJIS-Report.ps1` connects and reports if consent is missing.
**Implement:** Consent at first `Connect-MgGraph`; if admin consent is required, a Global Administrator
approves the read scope once in Entra (`Identity → Applications → Enterprise applications`).

## 2.8 A pilot scope, simulation mode, and change control
**Description:** A named **pilot scope** (`CJIS Pilot Ring – Stage1` — a limited set of users/sites) run
in **simulation/test** mode first, and a **change-control** process for promoting to enforce, per Global
Requirement 6. DLP supports `TestWithNotifications` / `TestWithoutNotifications` — this MUST be used
before enforcement.
**Why:** DLP block actions are high-impact in a law-enforcement tenant; the policy is validated in
simulation on the ring before any content is blocked, and enforcement is a reviewed, reversible
promotion.
**Verify:** The ring is defined, simulation mode confirmed available, and a change window / approval path
exists.
**Implement:** Define the ring and agree change control before promoting any policy to enforce.

---
## Checklist
- [ ] DLP-capable licensing inventoried; endpoint/EDM/trainable-classifier availability recorded (E3 vs E5 / E5 Compliance)
- [ ] Least-privilege DLP role confirmed; admin vs matched-content reviewer separated
- [ ] ExchangeOnlineManagement + Microsoft Graph SDK installed; `Connect-IPPSSession` / `Connect-MgGraph` succeed
- [ ] CJI detection approach agreed (custom SIT / keyword dictionary / supporting SITs / EDM where licensed)
- [ ] In-scope workloads agreed; endpoint onboarding status assessed
- [ ] CSO/TAC + compliance/records/legal stakeholders named; enforcement action + evidence requirements captured
- [ ] Graph read scope (`SecurityEvents.Read.All`) consented for the evidence report
- [ ] `CJIS Pilot Ring – Stage1` defined; simulation mode confirmed; change control agreed


---


# Global Requirements — Microsoft Purview Solutions

These requirements apply to **every** solution in the **Purview** category (implementing and managing
Microsoft Purview, sensitivity & retention labels, DLP, data lifecycle & records, insider risk,
communication compliance, audit, data security posture management, and data governance). Verify each
before starting a solution's implementation steps.

> **Vendor boundary (applies to every Purview solution).** The **Microsoft Purview portal**
> (purview.microsoft.com), the **Microsoft 365 admin center**, **Security & Compliance PowerShell**
> (`Connect-IPPSSession`), and **Microsoft Graph** are authored at exact, current click-by-click /
> cmdlet detail from Microsoft's public documentation. Microsoft Purview features are heavily
> **licensing-/plan-dependent** (many require **Microsoft 365 E5** or the **E5 Compliance** add-on;
> some are in preview) and the portal is **actively evolving** — capability availability and portal
> paths are **cited or flagged "verify your licensing/tenant"**, never asserted or invented.
> **Regulatory, records-retention, and legal determinations** (retention schedules, records file plans,
> legal holds, insider-risk case actions, regulatory applicability) are **deferred to the organization's
> compliance, records, privacy, and legal functions** — the solutions provide the technical
> configuration method and evidence, not the determination. Automation is **PowerShell** (Security &
> Compliance PowerShell / Graph) — never with hardcoded credentials or secrets.

## 1. Microsoft 365 tenant with the required Purview/compliance licensing
- **Description:** A Microsoft 365 tenant with the **compliance licensing** the capability requires
  (E3 for baseline; **E5 / E5 Compliance** for advanced DLP, auto-labeling, insider risk, communication
  compliance, Audit Premium, DSPM, etc.).
- **Why required:** Most Purview capabilities are plan-gated; the feature won't be available without the
  right plan.
- **How to verify:** In the M365 admin center confirm the subscription/add-ons; check the feature is
  visible in the Purview portal.
- **How to implement if missing:** Assign/purchase the required licensing before starting.

## 2. Purview roles (least-privilege) and portal access
- **Description:** Access with the least-privilege **Purview / compliance role** the solution names
  (e.g. Compliance Administrator, Compliance Data Administrator, Information Protection, Records
  Management, Insider Risk, eDiscovery, Audit roles), with Global Administrator only where required.
- **Why required:** Purview uses fine-grained role groups; configuration requires the matching role.
- **How to verify:** Purview portal → **Roles & scopes / Permissions** — confirm the role membership.
- **How to implement if missing:** Assign the least-privilege role group under change control.

## 3. Security & Compliance PowerShell + Graph toolchain
- **Description:** A workstation with **Security & Compliance PowerShell** (`Connect-IPPSSession` via the
  ExchangeOnlineManagement module) and **Microsoft Graph PowerShell**, modern-auth / MFA-capable admin.
- **Why required:** Configuration, automation, and the provided scripts run through these.
- **How to verify:** `Connect-IPPSSession` and `Connect-MgGraph` succeed with the admin account.
- **How to implement if missing:** Install the modules and confirm modern-auth sign-in before running steps.

## 4. Data sources & scope in scope
- **Description:** The **workloads and data sources** in scope (Exchange, SharePoint, OneDrive, Teams,
  endpoints/devices, and — for data governance — the broader data estate) and a **data-classification /
  sensitivity** intent to drive labels, DLP, and retention.
- **Why required:** Purview policies key off the in-scope workloads and the classification scheme.
- **How to verify:** Confirm the in-scope workloads and the classification/sensitivity approach with
  stakeholders.
- **How to implement if missing:** Define the scope and classification intent before authoring policies.

## 5. Compliance, records, privacy & legal stakeholders
- **Description:** Engagement with the **compliance, records-management, privacy, security, and legal**
  stakeholders whose policies the configuration must satisfy (retention schedules, records file plans,
  regulatory obligations, insider-risk and communication-compliance policy, legal hold).
- **Why required:** Purview configuration must align to enterprise policy and legal/records requirements,
  not technical defaults; several capabilities have HR/legal sensitivity.
- **How to verify:** Confirm the applicable policies, the records schedule, and named approvers.
- **How to implement if missing:** Identify the owners and capture the requirements before configuring.

## 6. A pilot scope and change control
- **Description:** A **pilot scope** (users/sites/policies in simulation or a limited ring) to validate
  on before tenant-wide enforcement, and a **change-control** process — most Purview policies support a
  **simulation / test / disabled** mode that MUST be used before enforcement.
- **Why required:** Every solution follows an **Assess → Design → Configure → Pilot (simulate) → Validate
  → Expand (enforce)** model; DLP, labels, retention, and insider-risk changes are high-impact.
- **How to verify:** Confirm a named pilot scope, that simulation/test mode is available, and a change
  window/approval path.
- **How to implement if missing:** Define the pilot and agree change control before enforcing anything.

*The deployment model across every Purview solution is the same: **Assess → Design → Configure → Pilot
(simulate/test) → Validate → Expand (enforce)**, with explicit pass/fail gates and a documented rollback.
Automation is delivered as **PowerShell** (Security & Compliance PowerShell / Graph) — never with
hardcoded credentials or secrets. Regulatory/records/legal determinations are deferred to the relevant
governance functions.*


---


# 3. Implementation Guide — CJIS DLP Pack (Microsoft Purview)

This is the **build** guide: how to stand up CJI Data Loss Prevention across the M365 workloads, pilot it
in **simulation/test**, validate it, and only then enforce. Work **Part A** to assess and design, **Part
B** to configure and pilot, **Part C** to validate and expand. Detection and policy come from the
**Microsoft Purview portal** and **Security & Compliance PowerShell** (`Connect-IPPSSession`); DLP alerts
for evidence come from **Microsoft Graph**. Every config change is run **`-WhatIf` first** and only
committed with `-Commit` under change control. Artifact names follow the
`<Purpose> – <Scope> – <Stage>` convention and are reused verbatim across docs, scripts, and the portal.

> **Model:** Assess → Design (CJI detection) → Configure (in **simulation/test**) → Pilot & tune →
> Validate → Expand (**enforce**). High-impact DLP changes are **always piloted in simulation/test before
> enforcement**; every change is reversible and recorded. Whether data *is* CJI, the CJI retention
> schedule, and the CJIS audit conclusions are **deferred to your CSO/TAC, compliance, and legal**.

## Named artifacts
| Artifact | Name |
|---|---|
| CJI custom sensitive info type | `CJI Sensitive Info Type – CHRI – Custom` |
| CJI keyword dictionary | `CJI Keyword Dictionary – CJIS – Terms` |
| DLP policy (pilot / simulation) | `CJIS CJI Protection – AllWorkloads – Pilot` |
| DLP detection rule | `CJI Detection Rule – Identifiers+CHRI – v1` |
| Policy baseline (drift reference) | `Policy Baseline – CJIS DLP – <date>` |
| Evidence report | `CJI DLP Evidence – CJIS – Report` |
| Workload scope map | `Workload Scope – CJIS DLP – Map` |
| Change record | `Change Record – CJIS DLP – ChangeControl` |
| Pilot ring | `CJIS Pilot Ring – Stage1` |

---
# Part A — Assess & design

## Step 1 — Assess the estate (read-only)
1. Confirm least-privilege DLP administration is in place (Requirement 2.2) and connect:
   `Connect-IPPSSession`.
2. Run `DLPCJIS-Discovery.ps1` to inventory existing DLP policies and rules, the available
   sensitive-information-types, and any CJI-related custom classification already present. It writes the
   policy register and confirms toolchain connectivity.
3. Run `DLPCJIS-Scope-Health.ps1` to produce `Workload Scope – CJIS DLP – Map`: which workloads are
   available, endpoint onboarding status, and which DLP surfaces your licensing unlocks (Requirement 2.1,
   2.5). **Pass:** you have a written inventory of existing DLP, available SITs, and the licensed coverage.
4. Once the current state is agreed as known-good, run `DLPCJIS-Discovery.ps1 -SaveBaseline` to write
   `Policy Baseline – CJIS DLP – <date>` — the reference future drift checks diff against.

## Step 2 — Design the CJI detection (Design)
1. With your CSO/TAC and compliance stakeholders (Requirement 2.6), agree **how CJI is detected** in your
   content (Requirement 2.4). Typical building blocks:
   - A **custom sensitive information type** `CJI Sensitive Info Type – CHRI – Custom` — regex for the
     criminal-justice identifiers in scope (e.g. agency case/incident number formats, III/NCIC reference
     patterns) with **keyword evidence** to raise precision.
   - A **keyword dictionary** `CJI Keyword Dictionary – CJIS – Terms` — CHRI/criminal-justice context
     terms your authority confirms (record type names, disposition terms, source-system labels).
   - **Supporting built-in SITs** (e.g. U.S. SSN, U.S. driver's-license number) used *in combination*
     with the CJI context — not alone — so an SSN in a routine HR file does not match.
   - Where **EDM** is licensed (E5), an **Exact Data Match** schema against a known CJI identifier export
     for high-precision matching of specific records.
2. Author the custom SIT / keyword dictionary in the portal → `Data classification → Classifiers →
   Sensitive info types` (verify path). Set an initial **confidence level** (start Medium) and
   **instance count** (e.g. 1+) for the pilot; these are the primary tuning knobs.
   **Pass:** the CJI classification exists and test-matches sample CJI content but not routine documents.
   *(What identifiers/terms define CJI is your authority's determination; this step implements it.)*

---
# Part B — Configure in simulation & pilot

## Step 3 — Create the DLP policy in simulation/test (Configure)
1. Confirm `DLPCJIS-Set-Policy.ps1` is safe by default: with no `-Commit` it **previews** and writes
   nothing. Preview the intended policy:
   `DLPCJIS-Set-Policy.ps1 -SitName "CJI Sensitive Info Type – CHRI – Custom" -WhatIf`.
2. Create the policy and rule in **test mode** with `-Commit`:
   `DLPCJIS-Set-Policy.ps1 -SitName "CJI Sensitive Info Type – CHRI – Custom" -Mode TestWithNotifications
   -Commit`. This creates:
   - Policy `CJIS CJI Protection – AllWorkloads – Pilot` scoped to Exchange, SharePoint, OneDrive, and
     Teams (and Endpoint where licensed), targeting `CJIS Pilot Ring – Stage1`.
   - Rule `CJI Detection Rule – Identifiers+CHRI – v1` matching the CJI classification, with the intended
     **action staged but not blocking** (test mode surfaces matches and policy tips without enforcing).
   **Pass:** `Get-DlpCompliancePolicy` shows the policy `Mode = TestWithNotifications`; the rule exists.
   **Rollback:** `DLPCJIS-Set-Policy.ps1 -Disable -Commit` sets the policy to `Disable` (no effect on users).
3. Confirm nothing is blocking: in test mode, users are not restricted — the policy only records what it
   *would* have done.

## Step 4 — Pilot & tune (Pilot)
1. Let the policy run in simulation over the agreed pilot period on `CJIS Pilot Ring – Stage1`.
2. Review matches with `DLPCJIS-Report.ps1` — it reads DLP alerts (Graph, Requirement 2.7) and produces
   `CJI DLP Evidence – CJIS – Report`: what matched, on which workload, and the (simulated) action.
3. **Tune** the CJI classification and the rule's confidence/instance thresholds until the match set is
   right — real CJI caught, routine case/admin work not flagged. Each tuning edit is previewed (`-WhatIf`)
   and applied (`-Commit`) and recorded in `Change Record – CJIS DLP – ChangeControl`.
   **Pass:** over a representative pilot window, true CJI is matched and the false-positive rate is
   acceptable to stakeholders. **Fail:** high false-positive rate → tighten the SIT/thresholds and
   re-pilot; do **not** promote to enforce.

---
# Part C — Validate & expand

## Step 5 — Validate against pass/fail gates (Validate)
1. Run `DLPCJIS-Validation.ps1` (read-only). It checks:
   - The policy `CJIS CJI Protection – AllWorkloads – Pilot` exists and is in the expected mode.
   - It is scoped to the intended workloads (Exchange / SharePoint / OneDrive / Teams / Endpoint as
     designed).
   - The rule `CJI Detection Rule – Identifiers+CHRI – v1` is present and references the CJI classification
     with the intended action.
   **Pass:** all gates green and the simulation results were signed off by stakeholders.
   **Fail:** any gate red → fix in test mode and re-validate before enforcing.

## Step 6 — Promote to enforce (Expand)
1. With clean simulation results and change approval (Requirement 2.6, 2.8), preview the promotion:
   `DLPCJIS-Set-Policy.ps1 -PromoteToEnforce -WhatIf`.
2. In the change window, enforce:
   `DLPCJIS-Set-Policy.ps1 -PromoteToEnforce -Commit` — sets the policy `Mode = Enable` so the configured
   action (e.g. block / block-with-override / restrict-external) now applies. The change is stamped into
   `Change Record – CJIS DLP – ChangeControl`.
   **Pass:** `Get-DlpCompliancePolicy` shows `Mode = Enable`; a controlled test triggers the action and an
   alert. **Rollback:** `DLPCJIS-Set-Policy.ps1 -Disable -Commit` (or `-Mode TestWithNotifications -Commit`)
   returns it to non-enforcing immediately.
3. **Expand coverage** as licensing allows — add **Endpoint DLP** (USB/print/cloud-upload restrictions)
   once devices are onboarded and E5 is confirmed, or tighten from allow-with-override to block. Each
   expansion is piloted in simulation on the ring first, validated, then enforced. Re-baseline
   (`DLPCJIS-Discovery.ps1 -SaveBaseline`) after each approved change set.

## Step 7 — Operate the evidence cadence
1. Run `DLPCJIS-Report.ps1` on your evidence cadence to refresh `CJI DLP Evidence – CJIS – Report` — the
   artifact you show an assessor: policy in force, what it detects, matches and admin actions over time.
2. Run `DLPCJIS-Discovery.ps1 -CompareBaseline` periodically to detect **drift** — any unexpected mode
   change (e.g. the CJI policy silently moved to `Disable`) is a change-control event.

---
### Order of operations
`Assess estate + scope/licensing → design CJI detection → create policy in TEST (simulation) → pilot &
tune → validate gates → (approval) promote to ENFORCE → expand coverage → run the evidence cadence — every
change -WhatIf-first, reversible, and recorded; CJIS/records/legal determinations deferred to the owners.`


---


# 5. Testing & Validation Guide — CJIS DLP Pack (Microsoft Purview)

Test in order. Every gate is **pass/fail** with a defined remediation. The golden rule: **prove detection
and behavior in simulation/test before you enforce**, and re-validate after every change. Use a
**synthetic CJI test document** (fabricated identifiers that match your CJI classification — never real
CJI) for match tests.

> Deploy model: Assess → Design → Configure (**simulate**) → Pilot & tune → Validate → Expand
> (**enforce**). Do not promote a policy to enforce with a failing gate.

## Test 1 — Toolchain & permissions
- **How:** `Connect-IPPSSession`; run `DLPCJIS-Discovery.ps1`.
- **Pass:** the script connects, `Get-DlpCompliancePolicy` returns, and the existing-DLP/SIT inventory
  prints.
- **Fail:** "not connected" → install `ExchangeOnlineManagement` and re-run `Connect-IPPSSession`
  (Requirement 2.3); access denied → confirm the least-privilege DLP role (Requirement 2.2).

## Test 2 — Coverage & licensing (scope map)
- **How:** run `DLPCJIS-Scope-Health.ps1`.
- **Pass:** `Workload Scope – CJIS DLP – Map` lists the available workloads, endpoint onboarding status,
  and the DLP surfaces your licensing unlocks — with no *unexpected* gaps.
- **Fail:** a required surface (e.g. Endpoint DLP) shows unlicensed/not-onboarded → record it as a
  coverage gap and either license/onboard it or de-scope it explicitly (Requirement 2.1, 2.5). Do not
  assume an un-onboarded surface is protected.

## Test 3 — CJI detection accuracy (the important one)
- **How:** with the CJI classification authored (Step 2), test it against (a) a **synthetic CJI
  document** and (b) a set of **routine documents** (HR, general admin, public records) that should NOT
  match. Use the portal SIT test pane and/or the pilot simulation results in `DLPCJIS-Report.ps1`.
- **Pass:** the synthetic CJI document matches at the configured confidence/instance threshold; the
  routine documents do **not** match.
- **Fail:** routine documents match (over-matching) → raise confidence, add required keyword evidence, or
  increase instance count; CJI document does not match (under-matching) → broaden the regex/dictionary or
  lower the threshold. Re-test until both hold. **Tuning detection is expected — budget pilot time for it.**

## Test 4 — Policy created in simulation (non-blocking)
- **How:** after `DLPCJIS-Set-Policy.ps1 -Mode TestWithNotifications -Commit`, run
  `DLPCJIS-Validation.ps1`.
- **Pass:** the policy `CJIS CJI Protection – AllWorkloads – Pilot` exists with `Mode =
  TestWithNotifications`; the rule `CJI Detection Rule – Identifiers+CHRI – v1` is present; users are
  **not** blocked (send/share of the synthetic CJI doc succeeds while an alert/tip is recorded).
- **Fail:** policy missing → re-run the create with `-Commit`; users blocked in "test" → confirm the mode
  is a `Test*` mode, not `Enable` (rollback with `-Disable -Commit`).

## Test 5 — Simulation evidence is produced
- **How:** trigger a match with the synthetic CJI document on each in-scope workload (email it, share it,
  post it in Teams), then run `DLPCJIS-Report.ps1`.
- **Pass:** `CJI DLP Evidence – CJIS – Report` shows the simulated matches by workload and the action that
  *would* have been taken.
- **Fail:** no matches recorded → detection is under-matching (see Test 3) or the workload is out of scope
  (see Test 2) or DLP alert latency (allow time; DLP events can take minutes to surface).

## Test 6 — Validation gates green before enforce
- **How:** run `DLPCJIS-Validation.ps1` immediately before promoting.
- **Pass:** scope, rule presence, rule action, and mode all match the design; stakeholders have signed off
  the simulation results (Requirement 2.6).
- **Fail:** any gate red → do not promote; fix in test mode and re-validate.

## Test 7 — Enforcement behaves as designed
- **How:** after `DLPCJIS-Set-Policy.ps1 -PromoteToEnforce -Commit`, attempt the same synthetic-CJI
  actions from a pilot-ring account.
- **Pass:** the configured action applies (e.g. external send blocked / share restricted / override
  prompt shown), an alert is generated, and `DLPCJIS-Report.ps1` records the enforced action.
- **Fail:** action not applied → confirm `Mode = Enable` and the rule action; action too broad (blocks
  legitimate work) → **rollback immediately** (`-Mode TestWithNotifications -Commit`) and re-tune.

## Test 8 — Rollback works
- **How:** run `DLPCJIS-Set-Policy.ps1 -Disable -Commit` (or `-Mode TestWithNotifications -Commit`).
- **Pass:** the policy stops enforcing within the DLP propagation window; the synthetic-CJI action
  succeeds again; the change is stamped in `Change Record – CJIS DLP – ChangeControl`.
- **Fail:** still enforcing → confirm the command committed and allow propagation time; verify with
  `Get-DlpCompliancePolicy`.

## Test 9 — Drift detection
- **How:** run `DLPCJIS-Discovery.ps1 -CompareBaseline` after establishing the baseline.
- **Pass:** no unexpected drift; any mode change on the CJI policy is explained by a recorded change.
- **Fail:** an unexplained `ModeChanged` (e.g. policy moved to `Disable`) → treat as a change-control
  incident and investigate.

---
## Acceptance checklist
- [ ] Toolchain connects; least-privilege DLP role confirmed (Test 1)
- [ ] Scope map produced; coverage gaps recorded, not assumed (Test 2)
- [ ] CJI detection matches synthetic CJI, not routine docs (Test 3)
- [ ] Policy created in **simulation/test**; users not blocked (Test 4)
- [ ] Simulation evidence produced across in-scope workloads (Test 5)
- [ ] Validation gates green + stakeholder sign-off before enforce (Test 6)
- [ ] Enforcement behaves as designed (Test 7)
- [ ] Rollback verified and recorded (Test 8)
- [ ] Drift detection running against the baseline (Test 9)


---


# 6. Troubleshooting Guide — CJIS DLP Pack (Microsoft Purview)

Field issues and fixes, in the order you'll hit them. Symptom → likely cause → remediation. When in
doubt, stay in **simulation/test** and re-tune rather than enforcing.

## Connection & permissions

**"Not connected to Security & Compliance PowerShell" / `Get-DlpCompliancePolicy` not found.**
- Cause: no `Connect-IPPSSession`, or the `ExchangeOnlineManagement` module isn't installed.
- Fix: `Install-Module ExchangeOnlineManagement -Scope CurrentUser`; `Connect-IPPSSession` with a
  modern-auth/MFA admin (Requirement 2.3). The DLP cmdlets exist only inside that session.

**"Access denied" reading or creating DLP policies.**
- Cause: the account lacks a DLP-capable role.
- Fix: add it to **Compliance Administrator** / **Compliance Data Administrator** or a role group with
  **DLP Compliance Management** (Requirement 2.2). Keep DLP admin separate from matched-content reviewer.

**Graph evidence report: "Not connected to Graph" / consent error.**
- Cause: no `Connect-MgGraph`, or `SecurityEvents.Read.All` not consented.
- Fix: `Connect-MgGraph -Scopes 'SecurityEvents.Read.All'` (or `SecurityAlert.Read.All`); a Global Admin
  grants admin consent once if required (Requirement 2.7).

## Detection (the most common tuning problem)

**Policy matches routine documents (false positives / over-matching).**
- Cause: detection too broad — a generic SIT (e.g. SSN) matching without CJI context, confidence too low,
  or instance count too low.
- Fix: raise the SIT **confidence** (Medium→High), increase **MinCount**, and require **keyword evidence**
  (`CJI Keyword Dictionary – CJIS – Terms`) so an identifier only matches in CJI context. Re-test against
  the routine-document set (Testing Test 3). This is expected tuning — do it in simulation, not enforce.

**Real CJI is not matched (false negatives / under-matching).**
- Cause: detection too narrow — regex doesn't cover the identifier format, dictionary missing terms, or
  threshold too high.
- Fix: broaden the custom SIT regex / keyword dictionary, or lower confidence/instance count; verify the
  synthetic-CJI test document matches. Where licensed, use **EDM** against a known CJI export for
  high-precision matching of specific records.

**`DLPCJIS-Report.ps1` shows zero matches during an active simulation.**
- Cause: under-matching detection (above), the workload is out of scope, or DLP alert latency.
- Fix: confirm detection with the synthetic-CJI doc; confirm scope with `DLPCJIS-Validation.ps1`; allow
  time — DLP events/alerts can take several minutes to surface. Zero matches does **not** prove no CJI
  moved; verify detection first.

## Policy creation & mode

**`DLPCJIS-Set-Policy.ps1` printed a WHATIF message and made no change.**
- Cause: working as designed — no `-Commit`. Safe-by-default forces `-WhatIf` unless you pass `-Commit`.
- Fix: re-run with `-Commit` (in a change window for enforce).

**"Create must use a TEST mode (simulation-first)."**
- Cause: you passed a non-test `-Mode` to the create path.
- Fix: create with `-Mode TestWithNotifications` (or `TestWithoutNotifications`), pilot, then
  `-PromoteToEnforce` to enable. The tool intentionally will not create straight to enforce.

**Policy already exists warning on create.**
- Cause: the pilot policy is already there.
- Fix: don't recreate — change mode with `-PromoteToEnforce` / `-Disable`, or tune the rule in the portal.
  Use `DLPCJIS-Discovery.ps1` to see the current state.

**Users are blocked while the policy is supposedly "in test."**
- Cause: the policy is actually in `Enable`, not a `Test*` mode.
- Fix: `Get-DlpCompliancePolicy` to confirm the mode; roll back immediately with
  `DLPCJIS-Set-Policy.ps1 -Disable -Commit` (or `-Mode TestWithNotifications` via the portal), then
  re-pilot.

## Scope & coverage

**Endpoint DLP shows unavailable / devices not protected.**
- Cause: Endpoint DLP requires **E5 / E5 Compliance** *and* onboarded devices; onboarding is separate.
- Fix: confirm licensing (`DLPCJIS-Scope-Health.ps1`), onboard devices (Purview → `Settings → Device
  onboarding`, verify path), then add `-IncludeEndpoint`. Until then, record endpoints as a **coverage
  gap** — do not assume USB/print/upload is protected.

**A workload isn't being protected even though the policy exists.**
- Cause: the workload isn't in the policy's scope, or content hasn't been re-evaluated yet.
- Fix: confirm scope with `DLPCJIS-Validation.ps1`; SharePoint/OneDrive DLP evaluates on crawl/change and
  can lag; test with a fresh upload of the synthetic-CJI doc.

## Enforcement & change control

**Enforcement blocks legitimate case work.**
- Cause: promoted before detection was tuned, or the action is too aggressive.
- Fix: **roll back now** — `DLPCJIS-Set-Policy.ps1 -Disable -Commit` (or `-Mode TestWithNotifications`) —
  then re-tune in simulation. Consider **block-with-override + justification** before hard block for
  borderline actions (Best Practices).

**Drift check reports an unexpected mode change on the CJI policy.**
- Cause: someone changed the policy outside change control (e.g. it silently moved to `Disable`).
- Fix: treat as a change-control incident; reconcile with `Change Record – CJIS DLP – ChangeControl`,
  restore the intended mode, and re-baseline (`DLPCJIS-Discovery.ps1 -SaveBaseline`) only after approval.

## Licensing & portal drift

**A cmdlet, SIT, or portal path in the guide isn't present in your tenant.**
- Cause: the capability is plan-gated or in preview, or the portal changed.
- Fix: this is expected — Purview features are **licensing-dependent** and the portal **evolves**. Confirm
  capability and the current portal path for **your** tenant; where a surface isn't licensed, scope the
  program to what you can enforce and record the gap.

## When to stop and escalate (defer, don't guess)
- **Is this data actually CJI?** → your **CSO/TAC / compliance authority**, not DLP tuning.
- **CJI retention / records / legal hold?** → **records / legal**.
- **CJIS audit conclusion, personnel screening, FIPS encryption, physical media?** → the broader **CJIS
  program owners**. This pack delivers and evidences the DLP control; the determinations are theirs.


---


# 7. Best Practices — CJIS DLP Pack (Microsoft Purview)

Field-proven guidance for running CJI Data Loss Prevention in Microsoft Purview so it protects criminal
justice information without breaking case work — and so it holds up in a CJIS audit.

## Simulate first, always
- **Never create a CJI DLP policy straight to enforce.** Start in `TestWithNotifications` /
  `TestWithoutNotifications`, watch what it matches, tune, and promote only after a clean pilot. In a
  law-enforcement tenant an over-broad block on day one blocks live case work.
- **Pilot on a ring, not the tenant.** Scope the pilot to `CJIS Pilot Ring – Stage1` first; expand scope
  only after the ring is clean.
- **`-WhatIf` before `-Commit`, every time.** Preview the change, then apply it in a change window with a
  recorded rollback.

## Detection is 80% of the work
- **Tune for precision, then recall.** CJI-specific classification (custom SIT + keyword evidence, or EDM
  where licensed) beats generic PII SITs. An SSN alone is not CJI — require CJI context so routine HR/admin
  files don't match.
- **Use confidence and instance count as your primary knobs.** Start Medium confidence / low instance
  count in simulation, then tighten until false positives are acceptable.
- **Prefer EDM for known record sets (E5).** Exact Data Match against a controlled CJI identifier export
  gives high precision for specific records — far fewer false positives than pattern matching alone.
- **Re-test detection whenever you change it.** Every SIT/threshold edit is a new simulation cycle with the
  synthetic-CJI and routine-document test sets.

## Cover the channels CJI actually uses
- **Don't stop at email.** CJI leaks through SharePoint/OneDrive sharing, Teams, and endpoints (USB,
  print, cloud upload). Scope the policy to all in-scope workloads; add **Endpoint DLP** once devices are
  onboarded and E5 is confirmed.
- **Make coverage gaps explicit.** If a surface is unlicensed or un-onboarded, record it as a known gap —
  never let "we have DLP" imply coverage you don't have.
- **Watch external sharing specifically.** "Anyone with the link" and external guest access are common CJI
  egress paths; align the DLP action with your sharing controls.

## Enforcement that people can live with
- **Consider block-with-override + justification before hard block.** For borderline scenarios, an
  override with a captured business justification protects data while preserving the audit trail and case
  work; reserve hard block for the highest-risk actions (external send of confirmed CJI).
- **Write policy tips your users understand.** Reference the CJI handling rule in plain language so a match
  educates rather than just frustrates.
- **Tune down false positives fast.** A noisy CJI policy trains users to click through tips; keep the
  false-positive rate low so alerts stay meaningful.

## Separation of duties & privacy
- **Separate who administers DLP from who reviews matched CJI content.** Matched-content review exposes
  the very data you're protecting — restrict it to the least-privilege reviewer role, distinct from the
  policy author.
- **Minimize who can see matched CJI.** Use the Information Protection review roles narrowly; log access.

## Evidence and audit-readiness
- **Produce evidence continuously, not at audit time.** Run `DLPCJIS-Report.ps1` on a cadence so the CJI
  evidence artifact (policy in force, what it detects, matches, actions) is always current.
- **Baseline and watch for drift.** Keep `Policy Baseline – CJIS DLP – <date>` current and run
  `-CompareBaseline` regularly; an unexplained mode change on the CJI policy is a control failure to
  investigate.
- **Record every change.** `Change Record – CJIS DLP – ChangeControl` — who/when/what/from/to — is part of
  the evidence an assessor expects.

## Stay in your lane (defer determinations)
- **DLP is one CJIS control, not the whole program.** FIPS-validated encryption, physical media
  protection, personnel screening/access authorization, and the CJIS audit conclusions live elsewhere in
  the CJIS Security Policy — this pack implements and evidences the DLP control and defers the rest.
- **CJIS/records/legal determinations are not yours to make.** Whether data *is* CJI, the CJI retention
  schedule, and regulatory applicability belong to your CSO/TAC, compliance, records, and legal owners.
  Provide the technical method and evidence; let them make the call.

## Licensing discipline
- **Confirm the plan before you rely on a feature.** Endpoint DLP, EDM, and trainable classifiers are
  E5 / E5 Compliance; some capabilities are preview and the portal evolves. Verify capability and portal
  paths for *your* tenant, and scope the program to what you can actually enforce.


---


# 8. Deliverables Summary — CJIS DLP Pack (Microsoft Purview)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | CJI DLP in Purview — what it delivers, the CJI detection approach, the Assess→Design→Configure(simulate)→Pilot→Validate→Expand(enforce) model, coverage, limitations, and the naming convention |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Purview) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered portal + S&C PowerShell + Graph steps: assess estate/scope, design CJI detection, create the policy in **simulation/test**, pilot & tune, validate gates, promote to **enforce**, expand, and run the evidence cadence — each policy/rule/classification named, with pass/fail gates and rollback |
| 5. Testing Guide | Validation procedures with pass/fail gates (detection accuracy, simulation, enforcement, rollback, drift) |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `DLPCJIS-Discovery.ps1` | Read-only assessment: inventories existing DLP policies + rules and the available sensitive-info-types, flags any CJI-related classification, and confirms toolchain connectivity. Optional `-SaveBaseline` / `-CompareBaseline` for drift. Writes `Policy Baseline – CJIS DLP – <date>` |
| `DLPCJIS-Set-Policy.ps1` | The one write-capable tool, **simulation-first & `-WhatIf` by default**: creates the CJI DLP policy + rule in a **test** mode (`TestWithNotifications`/`TestWithoutNotifications`); `-PromoteToEnforce` moves it to `Enable`; `-Disable` rolls back. Writes only with `-Commit` and stamps `Change Record – CJIS DLP – ChangeControl` |
| `DLPCJIS-Validation.ps1` | Read-only pass/fail validation: confirms the policy exists, is in the expected mode, is scoped to the intended workloads, and the CJI detection rule is present with the intended action |
| `DLPCJIS-Report.ps1` | Read-only evidence report: reads DLP alerts via Microsoft Graph (`/security/alerts_v2`) and summarizes matches/actions by workload. Writes `CJI DLP Evidence – CJIS – Report` |
| `DLPCJIS-Scope-Health.ps1` | Read-only scope/health helper: reports available workloads, endpoint device-onboarding status, and which DLP surfaces the licensing unlocks. Writes `Workload Scope – CJIS DLP – Map` |

All scripts are **safe by default** — read-only, or a `-WhatIf` preview requiring an explicit `-Commit`
to change anything, and simulation/test before enforce. No credentials or secrets are stored in code;
every script uses interactive modern-auth (`Connect-IPPSSession` / `Connect-MgGraph`).

## What the buyer receives
- This implementation guide as a **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the model: **Assess → Design → Configure (simulate) → Pilot → Validate →
  Expand (enforce).**

## Outcome
CJI Data Loss Prevention stood up the right way in Microsoft Purview — a CJI-tuned detection set, a DLP
policy protecting CJI across the M365 workloads, piloted in simulation and validated before enforcement,
with the ongoing evidence to prove the control is live and working. The CJIS determinations, retention,
and the rest of the CJIS Security Policy remain with your CSO/TAC, compliance, records, and legal owners —
this pack delivers and evidences the DLP control.
