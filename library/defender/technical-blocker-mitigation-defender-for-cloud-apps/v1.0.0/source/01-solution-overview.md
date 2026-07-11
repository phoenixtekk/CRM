# 1. Solution Overview — Technical Blocker Mitigation: Defender for Cloud Apps

## What this solution is
This is a **diagnostic and troubleshooting playbook** for a **stalled Microsoft Defender for Cloud Apps (MDCA) rollout**. It assumes you have started connecting apps, turning on discovery, or wiring session controls, and hit a wall — a connector that will not stay authenticated, a discovery dashboard with no data, or session policies that never engage. Its job is to answer three questions quickly and in order:

1. **Which blocker do I actually have?** (read-only discovery of connector, discovery, and session-control state — not guesswork)
2. **What is the exact, documented fix?** (a targeted manual step, applied deliberately)
3. **Is the connector / discovery / session control now working?** (verification before you resume)

It targets the four blocker classes that stall almost every MDCA deployment:

- **Connector authentication failures** — an **app connector** (Microsoft 365, AWS, Salesforce, ServiceNow, etc.) shows **error / disconnected** after a token expiry, a revoked app registration, or a changed permission.
- **Cloud Discovery no-data** — the discovery **dashboard is empty** because the discovery source is not feeding MDCA (the **Defender for Endpoint integration** is off, or log-collector / secure-web-gateway / manual log uploads are not arriving).
- **Session policy / Conditional Access App Control not engaging** — inline controls do nothing because sessions never route through the MDCA **reverse proxy**: the **Conditional Access App Control** policy is missing/misscoped, the app is not onboarded to session control, or the browser/session is not being redirected.
- **Licensing gap** — the MDCA plan (and, for CA App Control, the required Entra plan) is not assigned. *Verify current plan requirements in your tenant.*

## How Defender for Cloud Apps signal actually works (so you can find the break)
MDCA has a signal chain, and a blocker is always a break in one specific link:

1. **Licensing/activation** — the tenant has the MDCA plan and the portal is activated.
2. **App connectors** — API connectors to SaaS apps are **authenticated** and connected, pulling activity and enabling governance.
3. **Cloud Discovery** — a discovery source (the **MDE integration** for automatic device-based discovery, or uploaded logs) feeds the discovery dashboard so shadow-IT is visible.
4. **Session / Conditional Access App Control** — Entra **Conditional Access** routes selected sessions to the MDCA reverse proxy, the target app is **onboarded to session control**, and the session policy applies inline (monitor / restrict / block).
5. **Verification** — the connector shows **connected**, discovery shows data, session policies engage on a test session, and advanced-hunting `CloudAppEvents` streams.

Find the earliest broken link and you have found the blocker. Discovery reports the state of each link so you are not guessing.

## The standard deployment model (applied to a blocker)
> **Assess → Configure → Pilot → Validate → Expand.**
> **Assess** — run read-only discovery and the Conditional Access App Control analysis to pinpoint the earliest broken link. **Configure** — apply the single documented fix for that blocker (a manual portal step, not a script action). **Pilot** — re-test on the **affected app / policy subset** only, in monitor mode. **Validate** — confirm the connector / discovery / session control engages. **Expand** — resume the stalled rollout to the remaining apps/policies.

## Scope
- Diagnosing and clearing the four blocker classes above for a stalled MDCA rollout.
- Read-only discovery, Conditional Access App Control analysis, validation, status reporting, and a support-ready bundle.
- Documented manual fixes for each blocker, applied affected-app-first and monitor-first.
- Clear escalation criteria and the exact data to collect when the root cause is a Microsoft service issue.

## Out of scope
- **A full CASB / cloud-app DLP build** — that is the adjacent *Cloud App Security DLP* solution; this one unblocks a rollout already in progress.
- **Enforcing session controls in blocking mode** — block / restrict / quarantine stay **approval-gated** and are the SOC's decision; diagnostics run monitor-first.
- **Broader identity / Conditional Access design** — see the adjacent Entra Conditional Access solution; here CA is diagnosed only as it relates to App Control.
- **Licensing determinations** — the guide tells you *which* plan a feature needs and how to verify it; assigning it is the customer's licensing function.

## Connections and authentication used
- The **unified Defender portal** (`security.microsoft.com`) — **Cloud apps → App connectors / Cloud discovery / Policies**, and activity log.
- **Microsoft Graph** — read-only **Conditional Access policy** reads (to analyze App Control) and the **advanced-hunting** `CloudAppEvents` table.
- **Entra Conditional Access** (`entra.microsoft.com`) — the policy that routes sessions to the MDCA reverse proxy (read-only here).
- Least-privilege roles: **Security Reader** / **Global Reader** for all read-only diagnostics; **Security Administrator** (and Conditional Access Administrator for a CA fix) only to apply a fix.
