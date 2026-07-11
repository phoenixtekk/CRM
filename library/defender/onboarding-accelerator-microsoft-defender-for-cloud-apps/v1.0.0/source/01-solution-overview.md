# 1. Solution Overview — Onboarding Accelerator: Microsoft Defender for Cloud Apps

## What Microsoft Defender for Cloud Apps is
Microsoft Defender for Cloud Apps (MDCA) is Microsoft's **cloud access security broker (CASB)** and the SaaS-security pillar of Microsoft Defender. It gives four capabilities that together provide **cloud app security**:

- **App connectors (API-based)** — deep, out-of-band integrations with major SaaS apps (Microsoft 365, and third-party apps such as Salesforce, ServiceNow, Google Workspace, AWS, Box) that pull activity logs, files, accounts, and settings so MDCA can detect threats and apply file/governance policies.
- **Cloud Discovery** — analysis of traffic logs (from Defender for Endpoint's built-in feed, or a log collector / secure web gateway) to surface **shadow IT**: which cloud apps are in use, by whom, and at what risk.
- **App governance and OAuth app policies** — visibility and policy over the **third-party OAuth apps** users consent to in the tenant, catching over-privileged or malicious app grants.
- **Session and access policies (via Conditional Access App Control)** — real-time, in-line control of user sessions (block download, restrict copy/paste, require read-only) proxied through MDCA and triggered by Entra Conditional Access.

Most administration is in the unified Defender portal at `security.microsoft.com` under **Cloud apps**; Conditional Access App Control is wired in Entra.

## Why this matters
Organizational data has moved into SaaS, but the security controls often have not. Without **connectors**, MDCA cannot see what happens inside the apps that hold the data. Without **Cloud Discovery**, shadow IT — unsanctioned apps staff adopt on their own — stays invisible until it causes an incident. Without **app governance / OAuth policies**, a single malicious or over-permissioned OAuth grant can exfiltrate mail and files with no password ever stolen. Without **session/access policies**, there is no way to allow a risky sign-in but constrain what it can do. This accelerator turns the empty CASB into a working one — connected, discovering, governing OAuth apps, and controlling sessions — validated on a pilot scope before it can affect production access.

## How it works
1. **App connectors** are added for the priority SaaS apps under **Cloud apps → Connected apps → App connectors**; each connector pulls activity, files, and accounts via the app's API (out of band — no user impact).
2. **Cloud Discovery** is enabled — the simplest path is the built-in **Defender for Endpoint integration** so onboarded devices feed discovery automatically; a **log collector** or SWG feed is used where MDE is not the source.
3. **App governance** is turned on and **OAuth app policies** are created to flag/limit risky third-party app consents (over-privileged scopes, unverified publishers, unusual consent patterns).
4. **Policies** (activity, file, anomaly-detection, session, access) start **monitor / report-only**, scoped to a **pilot user group**, so behavior is observed before anything enforces.
5. **Session and access policies** are wired through **Conditional Access App Control** in Entra — a CA policy routes the pilot users' sessions to MDCA, which then applies the session controls (e.g. block download on unmanaged devices).
6. **Validation** confirms `CloudAppEvents` and discovery data stream and that a scoped monitor policy generates the expected alert.
7. Enforcing controls are only broadened from the pilot after they are validated.

## What you can control
- **Which apps are connected** and the order they onboard (Microsoft 365 first, then priority third-party apps).
- **Cloud Discovery source** — MDE integration, log collector, or SWG feed.
- **OAuth app governance** — which app consents are flagged, limited, or revoked (revocation approval-gated).
- **Policy posture** — monitor/report-only first, scoped to a pilot user group, before enforcing.
- **Session/access controls** — what a proxied session may do (download, copy, print, read-only) and for whom.

## Limitations (be honest with buyers)
- MDCA and app governance are **license-gated** (Defender for Cloud Apps; app governance may require a specific plan). Onboarding without the plan fails or limits features — *verify current availability in your tenant.*
- **Session/access policies require Conditional Access App Control**, which depends on Entra ID P1/P2 Conditional Access and reverse-proxy session routing — *verify current licensing and supported apps.*
- **Cloud Discovery** depends on a log source; without the MDE feed or a log collector there is no shadow-IT visibility.
- Discovery, connectors, and hunting tables **populate over time** — allow warm-up after onboarding.
- MDCA controls cloud-app access and data movement; it does not replace endpoint EDR, email protection, identity hardening, or the customer's DLP-classification and acceptable-use decisions.

## Connections and authentication used
- The **unified Defender portal** (`security.microsoft.com` → **Cloud apps**) for connectors, discovery, app governance, OAuth apps, and policies.
- **Entra** (`entra.microsoft.com`) for **Conditional Access App Control** that routes sessions to MDCA.
- **Microsoft Graph Security** and the **Microsoft 365 Defender** APIs (via the `Microsoft.Graph` PowerShell modules) for read-only discovery, validation, reporting, and advanced-hunting (`CloudAppEvents`, `OAuthAppInfo`, `AlertInfo`).
- Least-privilege roles: **Security Administrator** for configuration, **Security Reader** for read-only work, and **Global Administrator** only for one-time first-service activation and initial OAuth consent.

## The standard deployment model
> **Assess readiness (license, roles, apps, discovery source) → connect apps and enable discovery/app-governance → scope monitor-first policies to a pilot user group and wire Conditional Access App Control → validate signal and control on the pilot → expand tenant-wide.** Repeatable pattern: **Assess → Configure → Pilot → Validate → Expand**, with enforcing/revoke actions kept approval-gated until trusted.
