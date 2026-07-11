# 1. Solution Overview — Enablement Kit: Microsoft Defender for Cloud Apps

## What this enablement kit is
This is an **enablement / training** deliverable, not a deployment project. It teaches your admins and SOC analysts to **operate Microsoft Defender for Cloud Apps (MDA)** confidently — through concept sessions, **five guided hands-on labs**, a **take-home runbook**, and a **knowledge-check**. The output is a skilled team and a reusable runbook. The labs are designed to run against a **pilot** scope and are **read-only or report-only / preview-first**, so learning never disrupts users.

## What Microsoft Defender for Cloud Apps is (the concept)
Microsoft Defender for Cloud Apps is Microsoft's **cloud access security broker (CASB)** — the cloud-app visibility and control pillar of Microsoft Defender XDR. It answers four questions:

- **What cloud apps are in use?** **Cloud Discovery** ingests traffic logs (from a network appliance, from Defender for Endpoint, or uploaded) and builds a catalog of **discovered apps** with a **risk score**, exposing **shadow IT**.
- **What is happening inside sanctioned apps?** **App connectors** (API-based, for apps like Microsoft 365, Salesforce, Box, ServiceNow, etc.) pull activity, files, and accounts so you can apply policies and detect anomalies.
- **Which OAuth apps have access, and are they risky?** **App governance** and the **OAuth apps** inventory show third-party apps granted access to your data, their permissions, and behavior, with risk indicators.
- **Can I control a session in real time?** **Conditional Access App Control** (session/access policies, integrated with Entra Conditional Access) can monitor or restrict actions like download, copy, and print inside a session.

On top of these, MDA runs **anomaly-detection** policies (impossible travel, mass download, unusual admin activity, ransomware-like activity) and **threat-detection** policies, surfacing alerts into Defender XDR incidents and the `CloudAppEvents` advanced-hunting table.

## How the operator uses it (the console and workflows)
1. **The unified portal** — `https://security.microsoft.com` → **Cloud apps** section. (Some deep MDA settings still route through the classic portal / are being consolidated — *verify current navigation in your tenant*.)
2. **Cloud Discovery** — dashboards, discovered apps, app risk scores, and the ability to tag apps **Sanctioned / Unsanctioned**.
3. **Connected apps & app governance** — the API connectors and the OAuth app inventory with risk and usage.
4. **Policies** — activity, file, session, access, anomaly-detection, and OAuth app policies. New policies are authored **report-only / monitor** first.
5. **Alerts & advanced hunting** — MDA alerts appear in **Incidents & alerts**; `CloudAppEvents` is queryable in **Advanced hunting**.

## The standard deployment model (how the enablement kit is run)
- **Assess** — confirm the pilot scope, MDA licensing, a discovery data source, and at least one connected app (Lab 0 readiness).
- **Configure** — set up the enablement kit objects: the Cloud Discovery review, the saved hunting queries, and a **report-only** session policy.
- **Pilot** — run the five labs against the pilot scope.
- **Validate** — each lab has a **pass/fail gate**; the enablement kit ends with a **knowledge-check**.
- **Expand** — apply the runbook and policies to the full environment through the customer's change process.

## The five labs (scope of the hands-on)
- **Lab 1 — Cloud Discovery & shadow IT.** Run/read a discovery report; rank apps by risk; tag Sanctioned/Unsanctioned.
- **Lab 2 — App governance & connected apps.** Explore a connected app's activity; use app governance to review app behavior and API usage.
- **Lab 3 — OAuth app risk.** Inventory OAuth apps, read permissions and risk, and rehearse the **approval-gated** disable/revoke of a risky app.
- **Lab 4 — Session & access policies (report-only first).** Author a Conditional Access App Control session policy in **monitor/report-only** mode; understand the enforce path.
- **Lab 5 — Anomaly detection & investigation.** Read anomaly-detection alerts, triage with the entity/activity log and advanced hunting, and rehearse response.

## What is in scope
- Concept enablement, five guided labs, the take-home runbook, and the knowledge-check for **operating** MDA.
- Read-only discovery/validation/reporting helpers and a KQL hunting pack for the labs.

## What is out of scope (and where it lives)
- **Connecting every app / building the full DLP program** — see the catalog's **Cloud App DLP** and onboarding solutions.
- **Conditional Access design** — see the **Identity / Zero Trust / Conditional Access** solutions; MDA session control integrates with CA.
- **Broad cross-pillar threat hunting and SOC process** — see the **Threat Hunting** and **SOC / XDR operations** solutions.
- **Acceptable-use, app-sanctioning, records, and data-classification decisions** — the customer's security/compliance/business functions'; the enablement kit teaches the technical workflow only.

## Connections and authentication used
- The **Microsoft Defender portal** (`https://security.microsoft.com` → Cloud apps) for discovery, connected apps, app governance, policies, alerts, and advanced hunting.
- **Microsoft Graph** (via the lab PowerShell helpers, delegated **read** scopes such as `SecurityAlert.Read.All`, `Application.Read.All`, `Directory.Read.All`) for read-only discovery, validation, and reporting.
- No lab enforces a policy; session/OAuth actions are **report-only / approval-gated**.
