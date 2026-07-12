# 2. Requirements Guide — Microsoft Defender for Cloud Apps

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify · Implement-if-missing.** Category-wide prerequisites (tenant, licensing, admin roles, onboarding reach, network access, pilot ring, Log Analytics workspace, response governance) are in `global-requirements-defender.md` — do not repeat them; the items below are **specific to this solution**. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

## 2.1 Defender for Cloud Apps activated
**Description:** MDCA initialized for the tenant under `security.microsoft.com` → **Cloud apps**.
**Why:** Connectors, discovery, app governance, and policies only appear after first-time activation.
**Verify:** Sign in as a Security Administrator and confirm **Cloud apps → Cloud discovery / Connected apps / Policies** load. Run `MDCAFULL-Discovery.ps1`.
**Implement-if-missing:** Complete the one-time MDCA activation (Global Administrator required for first-service activation only). *Confirm the exact plan — verify current availability (references `global-requirements-defender.md` G2).*

## 2.2 Priority SaaS apps and connector credentials
**Description:** The list of SaaS apps to connect first (Microsoft 365, then priority third-party apps) and the admin credentials/consent each connector needs.
**Why:** App connectors are API integrations; each requires an admin consent or API credential for that app.
**Verify:** A prioritized app list exists; `MDCAFULL-Discovery.ps1` reports which connectors are already added.
**Implement-if-missing:** Add the connector for the top app(s) under **Cloud apps → Connected apps → App connectors** and complete each app's consent flow. Name the effort `MDCA App Connectors – Priority SaaS – Prod`.

## 2.3 Cloud Discovery log source
**Description:** A traffic-log source for Cloud Discovery — the built-in **Defender for Endpoint integration**, a **log collector**, a secure web gateway feed, or (for the PoC) an uploaded **sample log**.
**Why:** Without a log source there is no shadow-IT discovery; the MDE feed is the lowest-friction option if endpoints are onboarded to MDE.
**Verify:** `security.microsoft.com` → **Cloud apps → Cloud discovery → Settings**; confirm a source is configured. `MDCAFULL-Discovery.ps1` reports the discovery source.
**Implement-if-missing:** Turn on the **Defender for Endpoint → Cloud Apps** integration (if devices are MDE-onboarded — see the adjacent MDE onboarding accelerator), deploy a log collector for a SWG, or upload a snapshot log for the PoC/labs.

## 2.4 App governance enabled
**Description:** **App governance** (OAuth app monitoring and policy) turned on for the tenant.
**Why:** Risky third-party OAuth app consents are a major exfiltration path; app governance is what watches them, and Labs 2/3 use it.
**Verify:** `security.microsoft.com` → **Cloud apps → App governance**; confirm it is enabled. `MDCAFULL-Discovery.ps1` reports app-governance status. *App governance may require a specific plan — verify current availability.*
**Implement-if-missing:** Enable app governance and allow it to inventory the tenant's OAuth apps before creating policies. If it cannot be enabled, Lab 3 can still use the **OAuth apps** inventory read-only.

## 2.5 Entra Conditional Access for App Control
**Description:** Entra Conditional Access (P1/P2) available to route pilot users' sessions to MDCA for **Conditional Access App Control**.
**Why:** Session and access policies are enforced by proxying sessions, triggered by a Conditional Access policy (Phase A Step 5 and Lab 4).
**Verify:** `entra.microsoft.com` → **Protection → Conditional Access**; confirm CA is available and a policy can target the pilot users. *Verify current App Control licensing and supported apps.*
**Implement-if-missing:** Confirm Entra ID P1/P2, then plan the CA policy `MDCA Session Control – Pilot Users – Report`.

## 2.6 Pilot user group defined
**Description:** A named pilot user group `MDCA Pilot Users – Pilot Ring – Pilot` to scope monitor-first policies, session control, the enablement labs, and the PoC.
**Why:** Policies (especially session/access) are validated on a pilot group before tenant-wide enforcement (per `global-requirements-defender.md` G6); the labs and PoC also run against this scope.
**Verify:** The group exists in Entra; `MDCAFULL-Validate.ps1 -Check Policy` checks the scope.
**Implement-if-missing:** Create the group `MDCA Pilot Users – Pilot Ring – Pilot` (include the test account used to generate benign PoC activity) before scoping any policy.

## 2.7 Advanced hunting access (CloudAppEvents)
**Description:** The team can open **Advanced hunting** and query the `CloudAppEvents` table.
**Why:** Validation, several labs, and the PoC run the KQL pack (`MDCAFULL-LabQueries.kql`) against `CloudAppEvents` and related tables.
**Verify:** Open **Hunting → Advanced hunting**; run `CloudAppEvents | take 5`; confirm rows return.
**Implement-if-missing:** Grant the team a role including advanced-hunting read (e.g. **Security Reader** plus hunting). *Confirm role mapping in your tenant.*

## 2.8 Read-only Graph permissions for the scripts
**Description:** The PowerShell deliverables authenticate to Microsoft Graph with **read-only** scopes (e.g. `Organization.Read.All`, `Directory.Read.All`, `Application.Read.All`, `SecurityEvents.Read.All`, `Policy.Read.All`).
**Why:** `MDCAFULL-Discovery.ps1`, `MDCAFULL-Validate.ps1`, `MDCAFULL-Report.ps1`, and `MDCAFULL-OAuthRisk.ps1` read licensing, roles, connectors, alerts, service principals, and OAuth grants — they change nothing.
**Verify:** `Connect-MgGraph -Scopes "SecurityEvents.Read.All","Application.Read.All","Directory.Read.All"` consents successfully.
**Implement-if-missing:** Have a Global Administrator consent the delegated read scopes once, or register a read-only app. Never grant write/consent-management scopes for the read-only work.

## 2.9 Roles: configurator, facilitator, and read-only attendees
**Description:** A **Security Administrator** for Phase A configuration and the PoC enable/teardown; a **facilitator** with an MDCA admin role for the single report-only lab policy; **attendees** with **Security Reader** (plus hunting) to follow along read-only.
**Why:** Least privilege — only the admin/facilitator authors policies; everyone else learns and validates read-only and rehearses enforce/revoke in **simulate/approval-gated** mode.
**Verify:** Confirm the roles are held by the right people before starting.
**Implement-if-missing:** Assign roles before the engagement; reserve enforce/revoke/teardown for the approval-gated / `-WhatIf`-gated steps.

## 2.10 Policy posture and enforcement governance
**Description:** Agreement to start every policy in **monitor / report-only**, keep the PoC in **audit mode**, and keep enforcing/destructive actions (block, revoke OAuth app, suspend session, PoC teardown) approval-gated or `-WhatIf`-gated.
**Why:** Enforcing policies and destructive actions can disrupt legitimate work; the organization decides the guardrails (per `global-requirements-defender.md` G8).
**Verify:** A documented policy posture exists; policies are report-only first. `MDCAFULL-Validate.ps1 -Check Policy` reports the posture.
**Implement-if-missing:** Create policies in report-only mode; *enforcement, OAuth-revocation, and teardown decisions are the security team's — this guide covers the technical configuration.*

## 2.11 PoC evaluation criteria (Phase C)
**Description:** A written set of pass/fail evaluation criteria for the proof-of-concept.
**Why:** The PoC scorecard (`MDCAFULL-PoC.ps1 -Action Score`) maps each observation to your criteria — agreeing them first keeps the verdict objective.
**Verify:** A `criteria.json` (or equivalent) exists listing the capabilities to prove (discovery populated, policy matched, alert surfaced, activity visible).
**Implement-if-missing:** Draft the criteria with stakeholders before running the PoC.

---
## Checklist
- [ ] MDCA activated — `MDCAFULL-Discovery.ps1`
- [ ] Priority SaaS apps + connector credentials (`MDCA App Connectors – Priority SaaS – Prod`)
- [ ] Cloud Discovery log source (MDE integration / log collector / SWG / sample log)
- [ ] App governance enabled
- [ ] Entra Conditional Access available for App Control
- [ ] Pilot user group `MDCA Pilot Users – Pilot Ring – Pilot` defined (with a test account)
- [ ] Advanced hunting access to `CloudAppEvents`
- [ ] Read-only Graph scopes consented
- [ ] Roles: Security Administrator / facilitator / read-only attendees
- [ ] Policy posture (report-only first, enforce/revoke/teardown gated) documented
- [ ] PoC evaluation criteria written
