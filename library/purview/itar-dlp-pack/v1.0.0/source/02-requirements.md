# 2. Requirements Guide — ITAR DLP Pack (Microsoft Purview)

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
**Why:** Technical data moves through endpoints (USB, print, cloud upload) as well as mail and
collaboration; how far your ITAR DLP coverage can reach depends on the plan. Scope the pack to what you
can actually enforce.
**Verify:** Microsoft 365 admin center → `Billing → Licenses` for subscriptions/add-ons;
`DLPITAR-Scope-Health.ps1` reports which DLP surfaces (workloads / endpoints) are licensed and onboarded.
Confirm DLP is visible in the Purview portal → `Data loss prevention` (verify path in your tenant).
**Implement:** Assign/purchase the required licensing before relying on a surface that needs it. Where a
surface is unlicensed (e.g. Endpoint DLP without E5), record it as a coverage gap rather than assuming it
is protected.

> **Sovereignty note (verify).** Defense programs frequently require a U.S. sovereign cloud
> (**GCC High** or **DoD**). Purview capability availability, portal paths, and Graph/PowerShell
> endpoints differ across **Commercial / GCC / GCC High / DoD** — the scripts accept a
> `-ConnectionUri` / Graph environment for this reason. **Which cloud your ITAR data must reside in is
> an export/legal determination** (see Requirement 2.6), not a technical default; confirm your tenant's
> environment before relying on any path below.

## 2.2 Least-privilege DLP administration roles
**Description:** An account holding the least-privilege Purview role to author DLP — **Compliance
Administrator** or **Compliance Data Administrator**, or the **DLP Compliance Management** role for policy
authoring; **Information Protection** roles for reviewing matched content — with Global Administrator
reserved only for one-time consent actions (Global Requirement 2).
**Why:** DLP policies and matched-content review can expose controlled technical data; the fine-grained
role model limits who can see and change them. Over-granting Global Admin undermines the control you are
building. For ITAR, the administrator and matched-content reviewer should themselves be **U.S. persons**
where your program's TCP requires it — an access determination for your export authority, not this
solution.
**Verify:** Purview portal → `Settings → Roles & scopes → Role groups` (verify path) — confirm your
account is in **Compliance Administrator** (or a role group containing **DLP Compliance Management**).
`Connect-IPPSSession` succeeds and `Get-DlpCompliancePolicy` returns.
**Implement:** Add the account to the least-privilege compliance role group under change control; keep who
**administers** DLP separate from who **reviews** matched technical-data content.

## 2.3 Security & Compliance PowerShell + Microsoft Graph toolchain
**Description:** A workstation with the **ExchangeOnlineManagement** module (provides `Connect-IPPSSession`
for the DLP cmdlets) and the **Microsoft Graph PowerShell SDK** (for reading DLP alerts), with a
modern-auth / MFA admin account (Global Requirement 3).
**Why:** Every script in this pack runs through S&C PowerShell (`*-DlpCompliancePolicy` /
`*-DlpComplianceRule`) and/or Graph (`/security/alerts_v2`).
**Verify:** `Get-Module -ListAvailable ExchangeOnlineManagement, Microsoft.Graph.Authentication`;
`Connect-IPPSSession` and `Connect-MgGraph` both succeed. `DLPITAR-Discovery.ps1` reports connectivity.
**Implement:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser` and
`Install-Module Microsoft.Graph -Scope CurrentUser`; confirm modern-auth sign-in. For a sovereign cloud,
pass the matching `-ConnectionUri` and Graph environment (GCC High / DoD).

## 2.4 A defined technical-data detection approach (classification method)
**Description:** An agreed way to **detect ITAR technical data** in your content — a **custom sensitive
information type** (regex + keyword evidence) and/or a **keyword dictionary** for export-control markings
and controlled drawing/part conventions, ideally combined with a **sensitivity label** (e.g.
`Export Controlled // ITAR`) so labeled content is protected directly, and — where licensed — **EDM**
against a known controlled-item identifier set for high precision (Global Requirement 4). Typical
building blocks: the **Arms Export Control Act / ITAR warning legend**, **distribution statement** markers
(e.g. Distribution Statement B–F), **USML category** references, `22 CFR 120–130` citations, and your
program's controlled drawing-/part-number formats.
**Why:** Detection accuracy is most of a DLP program. Generic PII SITs do not identify technical data;
marking- and context-driven classification with the right confidence/instance thresholds is what makes
the policy usable.
**Verify:** `DLPITAR-Discovery.ps1` lists existing SITs and any technical-data custom type; confirm with
your export-compliance authority which markings, terms, and identifiers define in-scope technical data.
**Implement:** Author the custom SIT / keyword dictionary in the Purview portal → `Data classification →
Classifiers → Sensitive info types` (verify path), and/or the label in `Information protection → Labels`,
before authoring the DLP rule.
*(What data **is** ITAR technical data — and who is a foreign person — is a determination for your
Empowered Official / export-compliance authority. This requirement is the detection method, not the
export classification.)*

## 2.5 In-scope workloads and endpoint onboarding status
**Description:** The **workloads in scope** for technical-data control — Exchange Online, SharePoint
Online, OneDrive, Teams, and (licensing permitting) **onboarded endpoints/devices** — and the user/site
scope the policy will target (Global Requirement 4).
**Why:** DLP keys off the in-scope workloads; endpoints must be explicitly onboarded before Endpoint DLP
can restrict USB/print/cloud-upload, and a mail-only policy leaves collaboration and removable-media
channels open — a common ITAR egress path.
**Verify:** `DLPITAR-Scope-Health.ps1` reports M365 workload availability and endpoint device-onboarding
status from the Purview device-onboarding surface. Confirm the in-scope list with stakeholders.
**Implement:** Define the scope; plan endpoint onboarding (Purview portal → `Settings → Device
onboarding`, verify path) if Endpoint DLP is in scope and licensed.

## 2.6 Export-compliance / legal / records stakeholders (the determination owners)
**Description:** Engagement with the **Empowered Official, export-compliance officer, and the legal,
records, security, and privacy** stakeholders whose policy the configuration must satisfy — including the
egress action (block external vs allow-with-justification), the **foreign-person / U.S.-person**
determination that drives any access restriction, the notification wording, the required cloud
environment (Commercial vs GCC High / DoD), and the technical-data retention/records position
(Global Requirement 5).
**Why:** DLP enforcement affects engineering collaboration and must align to the ITAR program and its
**Technology Control Plan**, not technical defaults. Export classification, foreign-person status,
licensing/authorization, and records determinations are theirs to make — this solution provides the
control and the evidence, never the determination.
**Verify:** Named approvers recorded; the egress action, override policy, foreign-person access position,
and evidence requirements agreed in writing.
**Implement:** Identify the owners and capture the requirements before enforcing anything.

## 2.7 Graph read scope for DLP evidence (read-only)
**Description:** The delegated Graph scope needed for the evidence report to read DLP alerts:
`SecurityEvents.Read.All` (and `SecurityAlert.Read.All` where required for `alerts_v2`). No write scopes
are required.
**Why:** `DLPITAR-Report.ps1` reads triggered DLP alerts via Graph `/security/alerts_v2` to build the
evidence artifact; keeping to read scopes matches the safe-by-default posture.
**Verify:** `DLPITAR-Report.ps1` connects and reports if consent is missing.
**Implement:** Consent at first `Connect-MgGraph`; if admin consent is required, a Global Administrator
approves the read scope once in Entra (`Identity → Applications → Enterprise applications`). Use the Graph
environment that matches your cloud (Global / USGov / USGovDoD).

## 2.8 A pilot scope, simulation mode, and change control
**Description:** A named **pilot scope** (`ITAR Pilot Ring – Stage1` — a limited set of users/sites) run
in **simulation/test** mode first, and a **change-control** process for promoting to enforce, per Global
Requirement 6. DLP supports `TestWithNotifications` / `TestWithoutNotifications` — this MUST be used
before enforcement.
**Why:** DLP egress-block actions are high-impact in a defense-program tenant; the policy is validated in
simulation on the ring before any content is blocked, and enforcement is a reviewed, reversible promotion.
**Verify:** The ring is defined, simulation mode confirmed available, and a change window / approval path
exists.
**Implement:** Define the ring and agree change control before promoting any policy to enforce.

---
## Checklist
- [ ] DLP-capable licensing inventoried; endpoint/EDM/trainable-classifier availability recorded (E3 vs E5 / E5 Compliance)
- [ ] Cloud environment confirmed (Commercial / GCC High / DoD) per export/legal determination
- [ ] Least-privilege DLP role confirmed; admin vs matched-content reviewer separated
- [ ] ExchangeOnlineManagement + Microsoft Graph SDK installed; `Connect-IPPSSession` / `Connect-MgGraph` succeed
- [ ] Technical-data detection approach agreed (markings / distribution statements / drawing-part patterns / label / EDM where licensed)
- [ ] In-scope workloads agreed; endpoint onboarding status assessed
- [ ] Empowered Official + export-compliance/legal/records stakeholders named; egress action + foreign-person position + evidence requirements captured
- [ ] Graph read scope (`SecurityEvents.Read.All`) consented for the evidence report
- [ ] `ITAR Pilot Ring – Stage1` defined; simulation mode confirmed; change control agreed
