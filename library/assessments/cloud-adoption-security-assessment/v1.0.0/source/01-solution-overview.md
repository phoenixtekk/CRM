# 1. Solution Overview — Cloud Adoption Security Assessment

## What this assessment is
This solution is a **cross-cutting, whole-estate security maturity assessment** of your Microsoft cloud — Microsoft 365 (Entra ID, Defender, Purview) and Azure — measured against two well-known reference frames: the **Zero-Trust** model and the **Microsoft Cloud Adoption Framework (CAF)**. It **discovers** what you have, **scores** how mature each security pillar is, and **prioritizes** the gaps into a phased roadmap. It is not a deployment and not a remediation: every script is **read-only** and changes nothing. The output is evidence — a maturity score and a ranked findings report — that tells leadership where the risk is highest and what to fix first.

Two reference frames sit behind the score, and it helps to separate them:
- **Zero Trust** is a security *model*: never trust, always verify; assume breach; enforce least privilege. Microsoft expresses it across six **pillars** — **identity, endpoints (devices), data, applications, infrastructure, and network** — plus the visibility/automation/governance that ties them together. This assessment scores each pillar.
- The **Cloud Adoption Framework (CAF)** is Microsoft's *lifecycle* guidance for adopting cloud well, with a **Secure** methodology and a **governance** discipline (management groups, policy, landing zones). This assessment uses CAF's Secure/Govern lens to judge whether your foundation (subscriptions, policy, guardrails) is set up to keep the estate secure as it grows. *Both frameworks and Microsoft's baselines evolve — verify against current Microsoft guidance when you run the assessment.*

The point of scoring against a named baseline, rather than eyeballing settings, is that **a number is comparable and defensible**. A pillar maturity score you can re-run tells you whether you are getting better or worse; a ranked findings list tells a budget owner where a dollar buys the most risk reduction.

## The six pillars this assessment scores
- **Identity.** Are admins and users protected by phishing-resistant MFA? Is legacy authentication blocked? Are privileged roles minimized and just-in-time (PIM)? Is Conditional Access actually covering the tenant, with sane break-glass exclusions? Identity is the new perimeter — it is scored first and weighted heavily.
- **Endpoints (devices).** Are devices enrolled and compliant (Intune)? Is Defender for Endpoint deployed and reporting? Is a compliance signal feeding Conditional Access so unhealthy devices are kept out?
- **Data.** Is sensitive data labeled and protected (sensitivity labels, DLP)? Are the highest-impact data-loss paths (email, endpoint, cloud apps) covered? *Data-classification decisions themselves are the customer's — the assessment scores whether controls exist, not what should be labeled.*
- **Applications.** Are OAuth app registrations and consent governed? Is shadow IT visible (Defender for Cloud Apps)? Are app secrets and expirations under control?
- **Infrastructure.** Is Defender for Cloud enabled with a healthy Secure Score? Are Azure resources covered by security policy and workload-protection plans? Are the CAF governance guardrails (management groups, Azure Policy) present?
- **Network.** Are public exposure and open management ports minimized? Are private endpoints used for PaaS? Is segmentation in place? (Assessed at the posture level; deep network penetration testing is out of scope.)

## How the assessment works
- **Read-only discovery.** PowerShell using **Microsoft Graph** (including the **Security** endpoints), **Az** modules, and the **Defender** management APIs enumerates configuration across all six pillars. It authenticates as a **least-privilege read-only identity** (Security Reader / Global Reader / Azure Reader) and never holds write access — that is what proves it changes nothing.
- **Secure Score as an anchor.** Microsoft **Secure Score** is a first-class input: the assessment pulls your current score, the maximum, and the **control profiles** (identity, device, apps) so the highest-impact improvement actions surface automatically and feed the identity/endpoint/app pillar scores.
- **Conditional Access coverage.** A dedicated review enumerates every Conditional Access policy and tests for the coverage gaps that matter most — MFA for admins and all users, a legacy-auth block, device-compliance grants, and safe break-glass account exclusions — because a tenant can have many policies and still be exposed.
- **Defender posture.** Across the Defender products you own (Endpoint, Identity, Office 365, Cloud Apps, Cloud), the assessment records whether the plan is on, whether onboarding is healthy, and the headline posture — flagging *coverage gaps* (a product you own but haven't turned on) as findings.
- **KQL where it adds signal.** Where you have Microsoft Sentinel or Advanced Hunting, the guide supplies **read-only KQL** queries to corroborate posture (e.g. sign-ins still using legacy auth, devices not reporting) — evidence, never a change.
- **Scoring and ranking.** Findings roll up into a **per-pillar maturity score (0–100)** against the reference baseline, and each finding is tagged with a **risk rating** (impact × exposure) so the report can sequence a **phased roadmap**: quick wins, foundational, then strategic.

## What you can control
- **Scope** — which subscriptions, which products, and which user/device population are in the assessment.
- **Reference baseline** — which benchmark you score against (Microsoft security baselines + Secure Score, with CIS / Zero Trust as applicable). *Verify the current baseline version.*
- **Weighting** — how heavily each pillar counts toward the overall score, if your organization deviates from the default.
- **Output handling** — where the (sensitive) findings report is stored and who may see it.

## Scope — what's in
- A **read-only maturity assessment** across the six Zero-Trust pillars, using the CAF Secure/Govern lens for the foundation.
- **Secure Score** pull with control-profile detail and highest-impact actions.
- **Conditional Access** coverage/gap review.
- **Defender posture** summary across the products you own (coverage gaps flagged).
- A **risk-ranked findings report** and a **phased remediation roadmap**, plus an executive summary and technical findings.

## Scope — what's out (be honest with buyers)
- **This does not remediate.** It observes and scores. Closing the gaps is done with the dedicated catalog solutions (see below) — pilot-first and change-controlled. This assessment is the map, not the roadworks.
- **Not a product deep-dive.** Onboarding/tuning each Defender product, building DLP policy, and standing up the SOC each have their own solution; this assessment references them rather than repeating them.
- **Not a penetration test.** Network and app posture are assessed at the configuration level; authorized offensive testing is a separate discipline.
- **No risk-acceptance or regulatory determination.** The assessment states the gap and its risk; **whether to accept a risk, how to prioritize against business need, and any regulatory / records / legal mapping are the customer's decisions**, made by security, compliance, and leadership.

## Authentication and connections used
- **Microsoft Graph** (read scopes, including Security) signed in as **Security Reader / Global Reader** — for identity, Conditional Access, Secure Score, and Defender configuration (Global Requirements G2, G3).
- **Az PowerShell** signed in as **Reader** at the Azure scope — for Defender for Cloud, resource posture, and network exposure (G2, G3).
- **Microsoft Sentinel / Advanced Hunting** read access where present — for the corroborating KQL (optional).
- No write scopes are requested or used at any point — the read-only guarantee (G2).

## The standard deployment model
> **Assess the estate (discover configuration across all six pillars) → configure the scope, reference baseline, and pillar weighting → pilot the scoring on a representative subset (one business unit / subscription) → validate the findings against the live portals to remove false positives → expand to the full estate and produce the risk-ranked report and phased roadmap.** The repeatable pattern: **Assess → Configure → Pilot → Validate → Expand** — entirely read-only, re-runnable to trend the score, with remediation handed to the dedicated solutions under change control.
