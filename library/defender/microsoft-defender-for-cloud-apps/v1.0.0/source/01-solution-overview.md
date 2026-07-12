# 1. Solution Overview — Microsoft Defender for Cloud Apps

## What Microsoft Defender for Cloud Apps is
Microsoft Defender for Cloud Apps (MDCA) is Microsoft's **cloud access security broker (CASB)** and the SaaS-security pillar of Microsoft Defender. It gives four capabilities that together provide **cloud app security**:

- **App connectors (API-based)** — deep, out-of-band integrations with major SaaS apps (Microsoft 365, and third-party apps such as Salesforce, ServiceNow, Google Workspace, AWS, Box) that pull activity logs, files, accounts, and settings so MDCA can detect threats and apply file/governance policies.
- **Cloud Discovery** — analysis of traffic logs (from Defender for Endpoint's built-in feed, a log collector, a secure web gateway, or an uploaded snapshot log) to surface **shadow IT**: which cloud apps are in use, by whom, and at what risk.
- **App governance and OAuth app policies** — visibility and policy over the **third-party OAuth apps** users consent to in the tenant, catching over-privileged or malicious app grants.
- **Session and access policies (via Conditional Access App Control)** — real-time, in-line control of user sessions (block download, restrict copy/paste, require read-only) proxied through MDCA and triggered by Entra Conditional Access.

On top of these, MDCA runs **anomaly-detection** policies (impossible travel, mass download, unusual admin activity, ransomware-like activity) that surface alerts into Defender XDR **Incidents & alerts** and the `CloudAppEvents` advanced-hunting table. Most administration is in the unified Defender portal at `security.microsoft.com` under **Cloud apps**; Conditional Access App Control is wired in Entra.

## Why this matters
Organizational data has moved into SaaS, but the security controls often have not. Without **connectors**, MDCA cannot see what happens inside the apps that hold the data. Without **Cloud Discovery**, shadow IT stays invisible until it causes an incident. Without **app governance / OAuth policies**, a single malicious or over-permissioned OAuth grant can exfiltrate mail and files with no password ever stolen. Without **session/access policies**, there is no way to allow a risky sign-in but constrain what it can do. And even a fully wired MDCA delivers nothing if the team cannot drive it or if the value was never proven to the budget owner. This solution turns the empty (or half-configured) CASB into a working, team-operated, value-proven one — validated on a pilot scope before it can affect production access.

## What this solution covers — the three phases

This is a **complete lifecycle** product. It delivers the whole arc in one package:

### Phase A — Connect & Govern (onboarding)
Onboard MDCA end to end: add **app connectors** for the priority SaaS apps, turn on **Cloud Discovery**, enable **app governance** and an **OAuth app policy** (report-only), and create **session/access policies** via **Conditional Access App Control** — every enforcing policy starts monitor / report-only, scoped to a **pilot user group**, and is validated before it enforces or expands.

### Phase B — Enable the team (hands-on labs)
Upskill your admins and SOC analysts with **five guided labs**, a take-home runbook, and a knowledge-check — all run against the same pilot scope, **read-only or report-only**:
- **Lab 1 — Cloud Discovery & shadow IT.** Run/read a discovery report, rank apps by risk, tag Sanctioned/Unsanctioned.
- **Lab 2 — App governance & connected apps.** Explore a connected app's activity; use app governance to review app behavior and API usage.
- **Lab 3 — OAuth app risk.** Inventory OAuth apps, read permissions and risk, rehearse the **approval-gated** disable/revoke.
- **Lab 4 — Session & access policies.** Author a Conditional Access App Control session policy in **monitor/report-only**; understand the enforce path.
- **Lab 5 — Anomaly detection & investigation.** Read anomaly-detection alerts, triage with the entity/activity log and advanced hunting, rehearse response.

### Phase C — Prove value (guided proof-of-concept)
Run a **scoped, safe** PoC on the pilot users: enable an **audit-mode** activity policy, generate **benign** test signal (Microsoft's own **sample Cloud Discovery log** plus benign, policy-matching activity by a test account — never real exfiltration or attacks), demonstrate the detections, **score** the result against your evaluation criteria, and **cleanly tear the PoC back down**.

## How it works (the end-to-end flow)
1. **App connectors** are added under **Cloud apps → Connected apps → App connectors** (Microsoft 365 first, then priority third-party apps); each pulls activity, files, and accounts via the app's API (out of band — no user impact).
2. **Cloud Discovery** is enabled — the simplest path is the built-in **Defender for Endpoint integration** so onboarded devices feed discovery automatically; a **log collector**, SWG feed, or uploaded snapshot log is used where MDE is not the source.
3. **App governance** is turned on and an **OAuth app policy** is created to flag/limit risky third-party app consents (over-privileged scopes, unverified publishers, unusual consent patterns).
4. **Policies** (activity, file, anomaly-detection, session, access) start **monitor / report-only**, scoped to a **pilot user group**, so behavior is observed before anything enforces.
5. **Session and access policies** are wired through **Conditional Access App Control** in Entra — a CA policy routes the pilot users' sessions to MDCA, which then applies the session controls.
6. **The team is enabled** on that same pilot with the five labs and a knowledge-check.
7. **Value is proven** with a benign, audit-mode PoC and a scorecard.
8. **Validation** confirms `CloudAppEvents` and discovery data stream and that scoped monitor policies generate the expected alerts — then enforcing controls are broadened from the pilot only after they are validated.

## What you can control
- **Which apps are connected** and the order they onboard (Microsoft 365 first, then priority third-party apps).
- **Cloud Discovery source** — MDE integration, log collector, SWG feed, or an uploaded snapshot log.
- **OAuth app governance** — which app consents are flagged, limited, or revoked (revocation approval-gated).
- **Policy posture** — monitor/report-only first, scoped to a pilot user group, before enforcing.
- **Session/access controls** — what a proxied session may do (download, copy, print, read-only) and for whom.
- **PoC scope, benign signal, and scorecard criteria** — exactly which pilot users, which capabilities to prove, and the pass/fail bar.

## Limitations (be honest with buyers)
- MDCA and app governance are **license-gated** (Defender for Cloud Apps; app governance may require a specific plan). Onboarding without the plan fails or limits features — *verify current availability in your tenant.*
- **Session/access policies require Conditional Access App Control**, which depends on Entra ID P1/P2 Conditional Access and reverse-proxy session routing — *verify current licensing and supported apps.*
- **Cloud Discovery** depends on a log source; without the MDE feed, a log collector, or an uploaded log there is no shadow-IT visibility.
- Discovery, connectors, and hunting tables **populate over time** — allow warm-up after onboarding and after generating signal.
- All PoC test signal is **benign and simulated** (sample log + benign policy-matching activity) — it proves the visibility/policy pipeline, not resilience to a real exfiltration.
- MDCA controls cloud-app access and data movement; it does not replace endpoint EDR, email protection, identity hardening, or the customer's DLP-classification and acceptable-use decisions.

## Connections and authentication used
- The **unified Defender portal** (`security.microsoft.com` → **Cloud apps**) for connectors, discovery, app governance, OAuth apps, policies, alerts, and advanced hunting. *Some MDCA settings are still consolidating from the classic portal — verify current navigation in your tenant.*
- **Entra** (`entra.microsoft.com`) for **Conditional Access App Control** that routes sessions to MDCA.
- **Microsoft Graph Security** and the **Microsoft 365 Defender** APIs (via the `Microsoft.Graph` PowerShell modules) for read-only discovery, validation, reporting, and advanced-hunting (`CloudAppEvents`, `OAuthAppInfo`, `AlertInfo`) with delegated **read** scopes.
- Least-privilege roles: **Security Administrator** for configuration and the PoC enable/teardown, **Security Reader** for read-only work and lab attendees, and **Global Administrator** only for one-time first-service activation and initial OAuth consent.

## The standard deployment model
> **Assess readiness (license, roles, apps, discovery source) → connect apps and enable discovery/app-governance → scope monitor-first policies to a pilot user group and wire Conditional Access App Control → enable the team on the pilot → prove value with a benign, audit-mode PoC and a scorecard → validate signal and control → expand tenant-wide.** Repeatable pattern: **Assess → Configure → Pilot → Validate → Expand**, with enforcing/revoke/teardown actions kept `-WhatIf`- or approval-gated until trusted.
