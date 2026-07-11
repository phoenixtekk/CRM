# 2. Requirements Guide — Onboarding Accelerator: Microsoft Defender for Cloud Apps

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify · Implement-if-missing.** Category-wide prerequisites (tenant, licensing, admin roles, onboarding reach, network access, pilot ring, workspace, response governance) are in `global-requirements-defender.md` — do not repeat them; the items below are **specific to onboarding Defender for Cloud Apps**. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

## 2.1 Defender for Cloud Apps activated
**Description:** MDCA initialized for the tenant under `security.microsoft.com` → **Cloud apps**.
**Why:** Connectors, discovery, app governance, and policies only appear after first-time activation.
**Verify:** Sign in as a Security Administrator and confirm **Cloud apps → Cloud discovery / Connected apps / Policies** load. Run `MCAONB-Discovery.ps1`.
**Implement-if-missing:** Complete the one-time MDCA activation (Global Administrator required for first-service activation only).

## 2.2 Priority SaaS apps and connector credentials
**Description:** The list of SaaS apps to connect first (Microsoft 365, then priority third-party apps) and the admin credentials/consent each connector needs.
**Why:** App connectors are API integrations; each requires an admin consent or API credential for that app.
**Verify:** A prioritized app list exists; `MCAONB-Discovery.ps1` reports which connectors are already added. 
**Implement-if-missing:** Add the connector for the top app(s) under **Cloud apps → Connected apps → App connectors** and complete each app's consent flow. Name the effort `MDCA App Connectors – Priority SaaS – Prod`.

## 2.3 Cloud Discovery log source
**Description:** A traffic-log source for Cloud Discovery — the built-in **Defender for Endpoint integration**, a **log collector**, or a secure web gateway feed.
**Why:** Without a log source there is no shadow-IT discovery; the MDE feed is the lowest-friction option if endpoints are onboarded to MDE.
**Verify:** `security.microsoft.com` → **Cloud apps → Cloud discovery → Settings**; confirm a source is configured. `MCAONB-Discovery.ps1` reports the discovery source. 
**Implement-if-missing:** Turn on the **Defender for Endpoint → Cloud Apps** integration (if devices are MDE-onboarded — see the adjacent MDE onboarding accelerator), or deploy a log collector for a SWG.

## 2.4 App governance enabled
**Description:** **App governance** (OAuth app monitoring and policy) turned on for the tenant.
**Why:** Risky third-party OAuth app consents are a major exfiltration path; app governance is what watches them.
**Verify:** `security.microsoft.com` → **Cloud apps → App governance**; confirm it is enabled. `MCAONB-Discovery.ps1` reports app-governance status. *App governance may require a specific plan — verify current availability.*
**Implement-if-missing:** Enable app governance and allow it to inventory the tenant's OAuth apps before creating policies.

## 2.5 Entra Conditional Access for App Control
**Description:** Entra Conditional Access (P1/P2) available to route pilot users' sessions to MDCA for **Conditional Access App Control**.
**Why:** Session and access policies are enforced by proxying sessions, triggered by a Conditional Access policy.
**Verify:** `entra.microsoft.com` → **Protection → Conditional Access**; confirm CA is available and a policy can target the pilot users. *Verify current App Control licensing and supported apps.*
**Implement-if-missing:** Confirm Entra ID P1/P2, then plan the CA policy `MDCA Session Control – Pilot Users – Report` (Step 5).

## 2.6 Pilot user group defined
**Description:** A named pilot user group `MDCA Pilot Users – Pilot Ring – Pilot` to scope monitor-first policies and session control.
**Why:** Policies (especially session/access) are validated on a pilot group before tenant-wide enforcement (per `global-requirements-defender.md` G6).
**Verify:** The group exists in Entra; `MCAONB-Validate.ps1 -Check Policy` checks the scope. 
**Implement-if-missing:** Create the group `MDCA Pilot Users – Pilot Ring – Pilot` before scoping any policy.

## 2.7 Policy posture and enforcement governance
**Description:** Agreement to start every policy in **monitor / report-only** and keep enforcing actions (block, revoke OAuth app, suspend session) approval-gated during the pilot.
**Why:** Enforcing policies can disrupt legitimate work; the organization decides the guardrails (per `global-requirements-defender.md` G8).
**Verify:** A documented policy posture exists; policies are report-only first. `MCAONB-Validate.ps1 -Check Policy` reports the posture. 
**Implement-if-missing:** Create policies in report-only mode; *enforcement and OAuth-revocation decisions are the security team's — this guide covers the technical configuration.*

---
## Checklist
- [ ] MDCA activated — `MCAONB-Discovery.ps1`
- [ ] Priority SaaS apps + connector credentials (`MDCA App Connectors – Priority SaaS – Prod`)
- [ ] Cloud Discovery log source (MDE integration / log collector / SWG)
- [ ] App governance enabled
- [ ] Entra Conditional Access available for App Control
- [ ] Pilot user group `MDCA Pilot Users – Pilot Ring – Pilot` defined
- [ ] Policy posture (report-only first, enforcement approval-gated) documented
