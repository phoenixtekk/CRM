# Executive Summary — Workshop: Microsoft Defender for Cloud

**White-label · Defender · Enablement / Training deliverable**

A licensed tool only pays off when the team can drive it. Many organizations enable **Microsoft Defender for Cloud (MDC)** — Azure's cloud-security-posture-management (CSPM) and cloud-workload-protection (CWPP) service — then leave most of its value on the table because no one is confident reading Secure Score, working recommendations, triaging workload-protection alerts, or connecting a second cloud. This is a **structured enablement workshop** that takes your admins and SOC/cloud engineers from "we have it" to "we operate it" — through concepts, **guided hands-on labs**, a **take-home runbook**, and a **knowledge-check**.

This is a training deliverable, not a deployment project. It assumes Defender for Cloud is (or is being) enabled on a pilot subscription — the *turn-it-on-and-remediate-at-scale* program lives in the catalog's **Defender for Cloud CSPM / Secure Score** solution — and focuses on the **operating skills**: reading **Secure Score & recommendations** and driving them up, triaging **workload-protection alerts**, using the **regulatory-compliance** dashboard, and understanding **multicloud connectors** (AWS/GCP). Every lab is **read-only or preview-first / `-WhatIf`**, so a team can learn safely on a pilot subscription without changing production posture.

## What you get
- A plain-language **Solution Overview** of Defender for Cloud — CSPM vs CWPP, Secure Score, recommendations, workload-protection plans, compliance, and connectors — and the console/workflows an operator uses daily.
- A **Requirements Guide** covering the workshop-specific prerequisites (a pilot subscription, at least one Defender plan on, Secure Score data, reader access) with verify / implement-if-missing for each.
- An **Implementation Guide** that is the **facilitator + student runbook** — five guided labs, each with named objects, exact portal navigation, and explicit pass/fail checks.
- Five **lab-helper assets**: read-only PowerShell discovery/validation/report scripts (Az modules) plus an **Azure Resource Graph / KQL query pack** for posture and alert hunting.
- A **Testing / knowledge-check** guide and a **Troubleshooting** guide.
- A **Best-Practices + where-to-go-next** guide pointing to the adjacent catalog areas (CSPM/Secure Score program, Sentinel, threat hunting).

## What this delivers
A team that can **confidently operate Microsoft Defender for Cloud**: they can read Secure Score and prioritize recommendations by real risk, triage a workload-protection alert, read the regulatory-compliance dashboard, and explain how a multicloud connector extends posture — with a **runbook they keep** and reuse.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand** — delivered against a **pilot subscription**, each skill validated with a pass/fail gate, then the team expands the practices across the estate through the customer's change process.

## Boundary
This workshop delivers the **technical enablement and the operating runbook**. Which regulatory standards apply, which recommendations to remediate, and whether an exemption is acceptable are the customer's **compliance / security / cloud-ops** functions' determinations — the workshop teaches the controls and the reading, not the decision. Any change (enabling a plan, applying a Fix) is taught **preview / `-WhatIf` first** and is approval-gated. Several MDC plans/features are **paid** and version-dependent; those facts are flagged **verify current availability in your tenant**.

## Effort
A competent facilitator can run the full workshop in a focused one- to two-day engagement against a pilot subscription; the labs and runbook are then reusable to onboard new cloud/SOC engineers. No production posture change is required to complete the workshop — the labs are read-only / preview-first.
