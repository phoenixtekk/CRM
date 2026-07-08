# 2. Requirements Guide — Microsoft Purview Communication Compliance

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites (tenant licensing, Purview roles, the
PowerShell/Graph toolchain, in-scope data sources, compliance/privacy/legal stakeholders, and a pilot
scope with change control) are in `global-requirements-purview.md` — this guide adds the
Communication-Compliance-specific detail. **Licensing and portal paths are plan-dependent and the
portal evolves — verify each against your own licensing and tenant.**

## 2.1 Microsoft 365 E5 / E5 Compliance licensing for Communication Compliance
**Description:** Communication Compliance requires **Microsoft 365 E5**, the **E5 Compliance** add-on,
or an equivalent (e.g. **Insider Risk Management** / Microsoft 365 E5 Insider Risk Management) SKU that
includes it. Some classifiers, connected sources, and channels have additional or preview requirements.
**Why:** The capability and its classifiers will not appear (or will be limited) without the entitling
plan; this is the most common blocker.
**Verify:** Microsoft 365 admin center → `Billing → Licenses` shows the E5 / E5 Compliance / Insider
Risk entitlement; the **Communication Compliance** area is visible in the Purview portal
(`https://purview.microsoft.com`). Run `PURVCC-Discovery.ps1`, which reports the readiness signals it
can see. **Confirm exact entitlement with Microsoft licensing — do not assume.**
**Implement:** Assign/purchase the required licensing before starting; re-check the portal.

## 2.2 Communication Compliance role groups populated with SEPARATION (with HR/legal)
**Description:** The four built-in role groups — **Communication Compliance Admin**,
**Communication Compliance Analysts**, **Communication Compliance Investigators**, and
**Communication Compliance Viewers** — populated so **policy-builders are separated from
content-reviewers from escalation-investigators**, agreed with HR, privacy, and legal. (There is also a
combined **Communication Compliance** role group that grants all of the above — avoid it for anything
but a tiny pilot precisely because it collapses the separation.)
**Why:** Role separation is the core privacy guardrail and the auditable evidence that oversight is
governed. Reviewers should be the agreed HR/compliance function, not whoever configured the policy.
**Verify:** Purview portal → `Settings → Roles & scopes → Permissions` (or
`Get-RoleGroupMember 'Communication Compliance Analysts'` etc. via `Connect-IPPSSession`) shows the
intended, separated membership. `PURVCC-Discovery.ps1` prints the membership of each group as the
separation snapshot.
**Implement:** With HR/legal, decide who occupies each group; assign membership under change control;
**do not** place the same person in Admin *and* Analysts/Investigators unless HR/legal explicitly
accept it for a stated reason.

## 2.3 Named HR / privacy / legal stakeholders and a documented lawful basis
**Description:** Named owners in **HR, privacy, and legal** who approve the monitoring, the
**supervised population**, the reviewers, and the **lawful basis / notice / works-council agreement**
required in your jurisdiction(s).
**Why:** Monitoring communications is privacy-sensitive and, in some jurisdictions, requires employee
notice, works-council/union agreement, or a documented lawful basis **before** it is enabled. Outcomes
of any alert are an HR/legal determination.
**Verify:** Written approval of scope + reviewers + lawful basis on file; named approvers recorded.
**Implement:** Engage HR/privacy/legal, capture the lawful basis and notice obligations, and get scope +
reviewer sign-off before configuring. This is a gating prerequisite, not a formality.

## 2.4 Privacy controls decision (pseudonymization / minimum scope)
**Description:** A decision, with privacy, on the **privacy settings** for the review experience — in
particular whether **usernames are pseudonymized/anonymized** in Communication Compliance, and the
principle that the **in-scope population is the minimum the obligation requires**, not "everyone".
**Why:** Pseudonymization and minimized scope are data-minimization controls that reduce the privacy
footprint of monitoring; several regimes expect them.
**Verify:** Purview portal → `Settings → Communication Compliance` (Privacy) reflects the agreed
setting; the supervised population matches the approved scope. `PURVCC-Discovery.ps1` reports the
current privacy/scope signals it can read and flags an over-broad scope.
**Implement:** Set the agreed privacy option; scope policies to the approved population and an
**exclusion group** (`Comms Excluded – Privacy`) for anyone who must not be monitored.

## 2.5 In-scope communication channels enabled and connected
**Description:** The **channels** to inspect — **Teams** chats/channels, **Exchange** email, **Viva
Engage** — and any **connected sources** (third-party data brought in via Microsoft 365 data
connectors, e.g. Bloomberg, Instant Bloomberg) that are in scope and licensed.
**Why:** A policy only inspects the channels it covers and only what has been ingested; connected
sources require their connector to be configured first.
**Verify:** Confirm Teams/Exchange/Viva Engage are in use; for connected sources, the relevant **data
connector** is configured in the Purview portal and ingesting. **Connector availability and licensing
vary — verify against your tenant.**
**Implement:** Enable/confirm the native channels; stand up any required data connector before scoping a
policy to that source.

## 2.6 Trainable classifiers, sensitive info types, and keyword lexicons identified
**Description:** The **detection content** the policy will use — the built-in **trainable classifiers**
(offensive: threat, harassment, discrimination, profanity, adult/racy; regulatory: money-laundering,
stock manipulation, unauthorized disclosure, regulatory collusion, gifts & entertainment), the
**sensitive information types** for data-leak detection, and any **custom keyword dictionaries** the
compliance function requires.
**Why:** These are what the policy actually detects; the wrong or unavailable classifier means no (or
wrong) detections. Classifier availability is plan/tenant-dependent.
**Verify:** Purview portal → `Data classification → Classifiers` (trainable classifiers) and
`→ Sensitive info types` show the intended items as available. **Verify each is present in your
tenant** before relying on it.
**Implement:** Confirm the required classifiers/SITs exist; where a custom lexicon is needed, create the
**keyword dictionary** with the compliance function's approved terms.

## 2.7 Security & Compliance PowerShell (Connect-IPPSSession)
**Description:** A workstation with the **ExchangeOnlineManagement** module (providing
`Connect-IPPSSession`) and, for Graph-based reporting, **Microsoft Graph PowerShell**, used with a
modern-auth / MFA-capable admin that holds the appropriate Communication Compliance role.
**Why:** All five provided scripts run through Security & Compliance PowerShell and/or Graph; the
`SupervisoryReview*` cmdlets that back Communication Compliance are only available after
`Connect-IPPSSession`.
**Verify:** `Connect-IPPSSession` succeeds; `Get-SupervisoryReviewPolicyV2` returns without error
(empty is fine). `PURVCC-Discovery.ps1` performs this check.
**Implement:** `Install-Module ExchangeOnlineManagement`; sign in with the role-holding admin.

## 2.8 A pilot / simulation scope and change control
**Description:** A named **pilot population** (`Comms In-Scope – Pilot`) and a change-control path, so
the first policy runs **narrow and validated** before any broad rollout — consistent with the category
model (`global-requirements-purview.md` §6).
**Why:** Monitoring is high-impact and privacy-sensitive; policies must be tuned on a small, approved
group before expanding.
**Verify:** A named pilot group exists and is approved by HR/legal; a change window/approval path is
defined.
**Implement:** Define and approve the pilot group and change control before building the first policy.
