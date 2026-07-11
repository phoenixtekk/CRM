# 1. Solution Overview — Security Optimization Assessment: Defender for Cloud Apps

## What Defender for Cloud Apps is
Microsoft Defender for Cloud Apps (formerly Microsoft Cloud App Security, "MCAS") is Microsoft's **cloud access security broker (CASB)**. It gives you four broad capabilities:

- **Cloud discovery** — ingests firewall/proxy/endpoint traffic logs (and signals from Defender for Endpoint) to surface **shadow IT** — the apps people actually use — and rank them by risk.
- **App connectors (API connectors)** — connect first- and third-party SaaS apps (Microsoft 365, Entra ID, and apps such as common file-sharing, CRM, and collaboration SaaS) over their APIs to pull activity, files, accounts, and OAuth grants.
- **App governance & OAuth-app policies** — monitor and govern the **OAuth applications** granted access to your data, flagging over-permissioned, unverified, or anomalous apps (app governance is an add-on capability within Defender for Cloud Apps).
- **Session & access policies (Conditional Access App Control)** — real-time controls that proxy sessions to **monitor or block** actions (download, copy, print, upload) inside SaaS apps, working with Entra Conditional Access.

On top of these it raises **alerts** (policy matches, anomaly detections, threat detections) that flow into the Microsoft Defender portal and Microsoft Defender XDR incidents.

## Why this assessment matters
Most tenants have Defender for Cloud Apps **on** but not **optimized**: discovery is fed by one manual log upload instead of continuous ingestion; only Microsoft 365 is API-connected while the risky third-party SaaS is not; app governance is unlicensed or unconfigured so risky OAuth consent goes unseen; session policies are absent so there is no real-time control; and alerts are either noisy (never tuned) or silent (nobody owns them). None of this is visible from a glance at the portal — you need to **enumerate the configuration, compare it to the recommended baseline, and score it**.

That is exactly what this assessment does. It is **read-only** — it changes nothing — and it produces a **prioritized, risk-ranked findings report** across the four domains so remediation effort goes to the highest-risk gaps first.

## The four assessment domains and how they are scored
1. **Connector & discovery coverage** — Are the core apps API-connected? Is cloud discovery fed **continuously** (automated log upload / Defender for Endpoint integration) rather than by one-off snapshots? Are sanctioned/unsanctioned tags applied?
2. **App-governance & OAuth policies** — Is app governance enabled? Are there policies flagging over-permissioned, unverified-publisher, or dormant/anomalous OAuth apps? Are highly privileged consented apps reviewed?
3. **Session & access policies** — Are Conditional Access App Control **session** and **access** policies in place for the apps that need real-time control (block download to unmanaged devices, block risky uploads)? Are they piloted before enforcement?
4. **Alert hygiene** — Are alert policies tuned (severity, scope, exclusions) so the signal is actionable? Is alert **resolution** happening (not a growing backlog of open alerts)? Are duplicate/legacy policies retired?

Each domain is scored against the **best-practice reference baseline** named in the Global Requirements (Microsoft security baseline / Secure Score guidance for Defender for Cloud Apps — *baselines evolve; verify against current Microsoft guidance*). The domain scores roll up into an overall posture score, and every gap becomes a finding with a **risk rank** (severity × exposure) so it can be prioritized.

## What is in scope
- **Reading** Defender for Cloud Apps configuration: connectors, discovery sources, policies (app-governance/OAuth, session, access, activity, file, anomaly), and alert state.
- **Scoring** that configuration against the recommended baseline across the four domains.
- **Producing** a prioritized, risk-ranked findings report with a saved baseline for trending.

## What is out of scope (and where it lives)
- **Making changes / closing the gaps** — that is the **Remediation Playbook for Defender Security Optimization Assessments** (pilot-first, `-WhatIf`-gated).
- **First-time onboarding** of Defender for Cloud Apps — see the *Onboarding Accelerator — Microsoft Defender for Cloud Apps* solution.
- **DLP for cloud apps / file policies design** — see the *Cloud App DLP with Defender for Cloud Apps* solution.
- **Cross-pillar (endpoint/identity/email/cloud) suite posture** — see the *Security Optimization Assessment — Microsoft Defender (Suite / XDR)* solution.
- **Regulatory, records, incident-response, and risk-acceptance decisions** — the customer's compliance/legal/SOC functions.

## Connections and authentication used
- The **Microsoft Defender portal** (`security.microsoft.com`) → **Cloud apps** for connectors, discovery, policies, and alerts; **App governance** where licensed.
- **Microsoft Graph** (read-only Security scopes such as `SecurityEvents.Read.All`, and directory read scopes for OAuth-app enumeration such as `Application.Read.All` / `Directory.Read.All`) for the discovery, validation, scoring, OAuth-audit, and reporting scripts. *Verify current scope names and availability in your tenant.*
- Least-privilege roles: **Security Reader** / **Global Reader** are sufficient for this read-only assessment (per Global Requirements G2).

## The standard deployment model
> **Assess** the current Defender for Cloud Apps configuration (connectors, discovery, policies, alerts) → **Configure** the assessment scope and baseline reference → **Pilot** the run on the defined scope and review the findings → **Validate** the score and findings with the security owner → **Expand** the scope (more apps/users) and re-run to trend. Repeatable pattern: **Assess → Configure → Pilot → Validate → Expand**, entirely **read-only**.
