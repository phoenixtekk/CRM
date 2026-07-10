# Executive Summary — Microsoft Defender for Cloud: CSPM & Secure Score Remediation

**White-label · Defender · Government (GCC High) edition**

This is the **Government (GCC High)** edition for US public-sector and defense-industrial-base tenants operating in **Microsoft Azure Government / GCC High**. It mirrors the commercial method exactly, adapted for the sovereign cloud — the Azure Government portal (`portal.azure.us`), the GCC High security portal (`security.microsoft.us`), Azure Government sign-in (`login.microsoftonline.us`), and PowerShell targeting the US Gov cloud (`Connect-AzAccount -Environment AzureUSGovernment`). Because feature, plan, and preview parity in GCC High/DoD can **lag commercial**, every availability and pricing claim is flagged to **verify against current Microsoft Government documentation** (see the included `gcc-high-parity-notes.md`).

Cloud misconfiguration is the leading cause of cloud breaches, and most teams have **no continuous view** of it — they find out at audit time, or after an incident. This solution turns on **Microsoft Defender for Cloud** (foundational CSPM plus **Defender CSPM**), enables **agentless machine scanning** and the **regulatory-compliance dashboard**, and — most importantly — gives you a **prioritized remediation program** that measurably raises **Secure Score** across Azure, with **AWS/GCP connectors** extending posture to a multicloud estate.

This is a complete, **deploy-it-today** package written for an administrator with no prior Defender for Cloud experience. It enables posture management on a **pilot subscription first**, keeps every change **preview/`-WhatIf` first**, and defers regulatory determinations to the compliance function.

## What you get
- A plain-language **Solution Overview** of Defender for Cloud, foundational vs Defender CSPM, Secure Score, agentless scanning, attack paths, and multicloud connectors.
- A **Requirements Guide** with verify / implement-if-missing for every solution-specific prerequisite.
- An **Implementation Guide** of exact, ordered portal steps — enable CSPM, turn on agentless scanning and the compliance dashboard, work the prioritized recommendations, and set governance rules and continuous export, pilot-first.
- Five **PowerShell scripts** (Az) plus **KQL/Azure Resource Graph** queries for posture discovery, CSPM validation, a Secure-Score + attack-path report with drift, a `-WhatIf`-gated CSPM-enable helper, and a recommendation/attack-path hunt.
- **Testing** and **Troubleshooting** guides for a confident rollout.

## What this delivers
**Microsoft Defender for Cloud** enabled (foundational CSPM free tier and the paid **Defender CSPM** plan), **agentless scanning** and the **regulatory-compliance dashboard** turned on, a **prioritized remediation cadence** driven by risk (attack paths, recommendation impact) that raises **Secure Score**, **governance rules and exemptions** so ownership and exceptions are tracked, **continuous export** to a Log Analytics workspace/workbook for trending, and **AWS/GCP connectors** for high-level multicloud posture — all proven on a pilot subscription first.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand** — enable and validate on a pilot subscription, then expand across the estate.

## Boundary
This solution delivers the **technical posture-management configuration and remediation cadence**. Which regulatory standards apply, which records/legal obligations must be met, and whether a given exemption is acceptable are **the customer's compliance, legal, and security functions'** determinations — this guide provides the controls and the evidence, not the decision. Some plans/features are **paid** and version-dependent — licensing facts are flagged **verify**.

## Effort
A competent administrator can enable CSPM and establish the remediation cadence on a pilot subscription in a focused engagement, then expand per subscription. Multicloud connectors and agentless scanning scale with estate size.
