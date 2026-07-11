# 1. Solution Overview — Security Optimization Assessment: Defender for Endpoint

## What this assessment is
This solution is a **read-only Security Optimization Assessment** for **Microsoft Defender for Endpoint (MDE)**. It does not deploy, tune, or change anything. It **discovers** how MDE is configured across your fleet, **scores** that configuration against Microsoft best practice, and produces a **prioritized, risk-ranked findings report**. The deliverable is *evidence and a plan*, not a change — the changes are a separate, pilot-first exercise (the paired **Remediation Playbook**).

The problem it solves is the difference between *deployed* and *optimized*. MDE licensed and partially onboarded still leaves the questions that decide whether it actually works: are all in-scope devices onboarded and healthy; is **EDR in block mode** on; are the **ASR rules** enforcing (block) or merely watching (audit); is **tamper protection** on everywhere; where is exposure concentrated. This assessment answers each with data.

## How Defender for Endpoint fits together (what we score)
- **Onboarding & sensor health.** A device is only protected once it is **onboarded** and its sensor is **reporting** ("Active"). Devices that are unonboarded, inactive, or "impaired communication" are blind spots. *We score onboarding coverage and sensor health across the in-scope device population.*
- **Next-generation protection (antivirus) configuration.** Real-time protection, cloud-delivered protection (**MAPS**), **PUA** protection, and signature currency determine whether the AV engine is actually catching things. Misconfigured or passive-mode AV is a common silent gap.
- **EDR in block mode.** When a non-Microsoft AV is primary, **EDR in block mode** lets Defender remediate post-breach malicious artifacts the primary AV missed. It is off by default. *We flag it as a coverage finding when it is not enabled.*
- **Attack surface reduction (ASR) rules.** A set of rules that block common attack techniques (e.g. Office child-process creation, credential theft from LSASS, script/executable behaviors). Their value is only realized in **Block** mode — rules left in **Audit** generate telemetry but stop nothing. *We score how many rules are in Block vs Audit vs Not-configured, and whether they are applied consistently.*
- **Tamper protection.** Prevents attackers (and local admins/malware) from disabling Defender's protections. It is a foundational control; **off** or **inconsistent** tamper protection is a high-severity finding.
- **Web & network protection.** Network protection (block connections to malicious domains/IPs) and web-content filtering. Network protection in audit-only is a partial control.
- **Policy hygiene.** How the above are delivered — Intune endpoint security policies, security baselines, and (legacy) GPO/Configuration Manager. **Conflicting, overlapping, or orphaned** policies produce unpredictable enforcement. *We surface duplication and conflict as hygiene findings.*
- **Exposure & Secure Score.** MDE's **Exposure Score** (from Threat & Vulnerability Management) and the endpoint-related **Microsoft Secure Score** recommendations quantify where risk is concentrated. *We read these signals and fold the top exposure drivers into the ranked findings.*

## How the score works
Each assessed area yields **checks** with a defined best-practice expectation (from the baseline named in the report — Microsoft security baselines / Secure Score, *verify against current Microsoft guidance*). Every check is **Pass / Partial / Fail / Not-applicable**, and every non-pass becomes a **finding** with a **severity** (High / Medium / Low), the **evidence** behind it, and a **pointer to the remediation**. The areas roll up into a **posture score** (a percentage of weighted checks passed) so you can trend it over time. The score is a *measurement*, not a verdict — **which findings to accept, defer, or fix, and in what order, is your security owners' decision.**

## What's in scope
- Read-only **discovery** of MDE configuration: onboarding & sensor health, AV/next-gen protection settings, EDR block mode, ASR rules, tamper protection, web/network protection, and delivery policies.
- **Scoring** those areas against a named best-practice baseline, producing per-check Pass/Partial/Fail.
- A **per-area coverage** view (which devices/policies are covered vs. gaps).
- Reading **Exposure Score** and endpoint **Secure Score** recommendations to rank findings by risk.
- A **findings report** (HTML + CSV) with severities, evidence, and remediation pointers.

## What's out of scope (be honest with buyers)
- **No changes.** This assessment never enables a rule, onboards a device, or edits a policy. Fixing findings is the paired **Remediation Playbook** (pilot-first, `-WhatIf`-gated).
- **Not an MDE deployment / onboarding project.** Standing up MDE and onboarding devices — including unified onboarding across Defender workloads — is the **DEFXDR** area. This assesses what already exists.
- **Not threat hunting or incident response.** Hunting queries and IR live in the **THREATHUNT** and **SOCXDR** areas. This assessment reads posture, not live threats. *Any live-threat or IR determination is the SOC's decision.*
- **Not a licensing purchase or plan design.** We *read* license/plan state and flag gaps as findings; buying and mapping plans is separate. *Plan/feature mapping changes — verify.*
- **No risk-acceptance decision.** The assessment supplies the score and evidence; accepting or prioritizing risk is the customer's.

## Authentication and connections used
- **Microsoft Graph (read-only)** signed in as **Security Reader** / **Global Reader** — for security posture, Secure Score, and (where used) device management configuration. Read scopes such as `SecurityEvents.Read.All`, `SecurityActions.Read.All`, `DeviceManagementConfiguration.Read.All`, `DeviceManagementManagedDevices.Read.All` (per Global Requirements G2/G3). *Verify current scope names.*
- **Microsoft Defender for Endpoint API** (Security Center / `WindowsDefenderATP`) with read roles — machines, recommendations, exposure, and **advanced hunting** (KQL) via `AdvancedHunting.Read.All`. *Verify current API host and permission names.*
- **Az PowerShell / Azure Reader** only where an Azure-scoped signal is read. No write scopes are ever requested.

## The standard deployment model
> **Assess the current MDE configuration (discovery) → configure nothing yet; instead score and rank → pilot the read by running against a representative device scope first → validate the assessor truly has read-only access and the numbers reconcile with the portal → expand to the full fleet, deliver the findings report, and re-run periodically to trend.** The repeatable pattern is **Assess → Configure → Pilot → Validate → Expand**; this product owns **Assess**, and the **Configure** onward stages are the Remediation Playbook's, done pilot-first.
