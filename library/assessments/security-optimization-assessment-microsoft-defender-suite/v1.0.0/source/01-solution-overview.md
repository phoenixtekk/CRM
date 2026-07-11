# 1. Solution Overview — Security Optimization Assessment: Microsoft Defender (Suite / XDR)

## What Microsoft Defender XDR is
Microsoft Defender XDR is the **unified security suite** in the Microsoft Defender portal (`security.microsoft.com`). It brings five protection pillars into one experience:

- **Endpoint** — Microsoft Defender for Endpoint (device onboarding, EDR, vulnerability management).
- **Identity** — Microsoft Defender for Identity (on-prem AD / Entra identity threat detection).
- **Email & collaboration** — Microsoft Defender for Office 365 (EOP + MDO: anti-phish, Safe Links/Attachments).
- **Cloud apps** — Microsoft Defender for Cloud Apps (CASB — connectors, session/OAuth policies).
- **Cloud** — Microsoft Defender for Cloud (Azure/multicloud workload and posture signal surfaced into XDR).

On top of the pillars, XDR provides:
- **Unified incidents** — alerts from all pillars are **correlated** into a single incident with an end-to-end attack story.
- **Unified RBAC** — one role model (the Microsoft Defender XDR Unified role-based access control) that governs who can see and act across the pillars, replacing per-product permission silos.
- **Suite-wide Microsoft Secure Score** — a single posture score spanning the identity, device, apps, and data controls across the suite.

## Why this assessment matters
A suite is only as strong as its weakest pillar and its glue. Common gaps: endpoint is onboarded but identity sensors are not, so lateral-movement detections never fire; email protection runs on default policies; cloud apps is on but unconnected; unified RBAC is left at legacy per-product roles so analysts either can't see across the incident or can see far too much; and the suite Secure Score plateaus because nobody works it. **None of this is visible from the incident queue** — you have to **enumerate onboarding/licensing per pillar, the RBAC model, incident-correlation settings, and the Secure Score, compare to the recommended baseline, and score it**.

That is what this assessment does. It is **read-only** — it changes nothing — and produces a **prioritized, risk-ranked findings report** across the four domains so remediation goes to the highest-risk gaps first. Because the sibling assessments (**Defender for Cloud Apps** and **Defender for Cloud**) go deep on their pillars, this suite assessment focuses on **cross-pillar coverage and the glue** and points to those deep-dive assessments where a pillar needs its own review.

## The four assessment domains and how they are scored
1. **Cross-pillar coverage** — Are all five pillars **onboarded and licensed**? Endpoint devices onboarded, identity sensors deployed, MDO policies present, cloud-apps connected, cloud plans on? Which pillars are dark?
2. **Unified RBAC** — Is Defender XDR Unified RBAC **activated** and are roles scoped to least privilege, or is the tenant still on legacy per-product permissions / broad Entra roles? *RBAC model availability — verify current.*
3. **Incident correlation** — Are the pillars feeding signal so incidents **correlate across products**? Are alert-to-incident and cross-pillar settings on? Is the incident queue producing multi-pillar incidents (evidence of correlation) rather than isolated single-product alerts?
4. **Suite-wide Secure Score** — What is the Microsoft Secure Score across the suite, and are high-impact improvement actions being worked or is there a stale backlog?

Each domain is scored against the **best-practice reference baseline** named in the Global Requirements (Microsoft security baseline / Secure Score / Zero-Trust guidance — *baselines evolve; verify against current Microsoft guidance*). Domain scores roll up into an overall posture score, and every gap becomes a finding with a **risk rank** (severity × exposure).

## What is in scope
- **Reading** the suite configuration: pillar onboarding/licensing, unified RBAC role assignments, incident/correlation settings, and Microsoft Secure Score — via Graph (Security) and Az.
- **Scoring** that configuration against the recommended baseline across the four domains.
- **Producing** a prioritized, risk-ranked findings report with a saved baseline for trending.

## What is out of scope (and where it lives)
- **Making changes / closing the gaps** — the **Remediation Playbook for Defender Security Optimization Assessments** (pilot-first, `-WhatIf`-gated).
- **Deep single-pillar review** — the **Security Optimization Assessment — Defender for Cloud Apps** and **— Defender for Cloud** solutions (and their onboarding/optimization siblings for endpoint/identity/email).
- **First-time unified onboarding** — the **Microsoft Defender XDR Deployment — Unified Onboarding** solution.
- **SOC operations on the correlated incidents** — the **SOC Onboarding (Sentinel + Defender XDR)** and **Threat Hunting (KQL)** solutions.
- **Regulatory, records, incident-response, and risk-acceptance decisions** — the customer's compliance/legal/SOC functions.

## Connections and authentication used
- The **Microsoft Defender portal** (`security.microsoft.com`) → **Settings** (per-pillar onboarding, Permissions & roles / Unified RBAC), **Incidents**, and **Secure Score** (for manual confirmation).
- **Microsoft Graph** (read-only Security scopes such as `SecurityEvents.Read.All`, and directory read scopes such as `RoleManagement.Read.Directory` / `Directory.Read.All` for the RBAC audit) and **Az** for the cloud pillar. *Verify current scope names and availability.*
- Least-privilege roles: **Security Reader** / **Global Reader** are sufficient for this read-only assessment (per Global Requirements G2).

## The standard deployment model
> **Assess** the current suite configuration (pillar onboarding, unified RBAC, incident correlation, Secure Score) → **Configure** the assessment scope and baseline reference → **Pilot** the run and review the findings → **Validate** the score and findings with the security owner → **Expand** scope (pillars/roles) and re-run to trend. Repeatable pattern: **Assess → Configure → Pilot → Validate → Expand**, entirely **read-only**.
