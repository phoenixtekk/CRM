# 1. Solution Overview — Security Optimization Assessment: Defender for Office 365

## What this assessment is
This solution is a **read-only Security Optimization Assessment** for **Microsoft Defender for Office 365 (MDO)** and the underlying **Exchange Online Protection (EOP)**. It does not change any policy. It **discovers** how email protection is configured, **scores** it against Microsoft best practice, and produces a **prioritized, risk-ranked findings report**. The deliverable is *evidence and a plan*; the fixes are a separate, pilot-first exercise (the paired **Remediation Playbook**).

The problem it solves is the gap between *licensed* and *tuned*. MDO applies useful defaults, but defaults are not a tuned posture — and, crucially, protection can be **silently weakened** over time by allow-list entries, mail-flow (transport) rules that skip filtering, and disabled controls that no one revisits. This assessment reads all of it and tells you where you actually stand.

## How Defender for Office 365 fits together (what we score)
- **Anti-spam (hosted content filter).** Spam/bulk/phish confidence thresholds, allowed/blocked senders and domains, and the outbound spam policy. Over-broad allow lists here are a classic self-inflicted gap.
- **Anti-malware.** The common-attachments filter and zero-hour auto purge (ZAP) for malware.
- **Anti-phishing.** Spoof intelligence, **user and domain impersonation protection**, mailbox intelligence, and the action taken on detected phish. *Impersonation protection (protected users/domains) is a Defender for Office 365 Plan feature — verify your plan.*
- **Safe Links.** Time-of-click URL rewriting and detonation, including coverage **inside Office apps, Teams, and email**, and whether users can click through warnings. Off or partial Safe Links is a coverage finding.
- **Safe Attachments.** Detonation of attachments in a sandbox, the **action** (Block / Monitor / Dynamic Delivery), and Safe Attachments for SharePoint/OneDrive/Teams. **Monitor** (not Block) is a common false-comfort setting.
- **Preset security policies.** Microsoft's **Standard** and **Strict** preset policies apply recommended settings that Microsoft keeps current. Using presets vs. a sprawl of custom policies is itself a hygiene signal; *preset scope and behavior evolve — verify current guidance.*
- **Policy precedence & effective policy.** When several policies of a type exist, **priority** and recipient scope decide which one actually applies to a given user. "A strict policy exists" means nothing if it does not cover the right recipients or is outranked.
- **Override & bypass hygiene.** The **Tenant Allow/Block List**, per-policy allowed senders/domains, **transport rules** that set SCL -1 or skip filtering, IP allow lists in the connection filter, and any disabled protection. *These are the highest-value findings because they are invisible in day-to-day use.*
- **Threat coverage signals.** Post-delivery events and the volume of mail that bypassed filtering (via advanced hunting `EmailEvents`), plus MDO-related Secure Score recommendations, to rank findings by real risk.

## How the score works
Each area yields **checks** with a best-practice expectation (from the baseline named in the report — Microsoft **preset Standard/Strict** and Secure Score, *verify current guidance*). Every check is **Pass / Partial / Fail / N-A**, and every non-pass becomes a **finding** with a **severity** (High / Medium / Low), the **evidence**, and a **remediation pointer**. Areas roll up into a **posture score (%)** you can trend. The score measures; **which findings to accept, defer, or fix, and in what order, is your security owners' decision.**

## What's in scope
- Read-only **discovery** of every EOP/MDO policy and rule: anti-spam, anti-malware, anti-phish, Safe Links, Safe Attachments, preset policies, connection filter, outbound spam, and DKIM.
- **Recipient coverage** analysis — which users each policy actually covers, and who is covered by nothing / by weak policy.
- **Override & bypass** enumeration — Tenant Allow/Block List, per-policy allow lists, transport-rule filtering bypasses, IP allow lists, disabled protections.
- **Scoring** against preset Standard/Strict + Secure Score, producing per-check Pass/Partial/Fail.
- A **findings report** (HTML + CSV) with severities, evidence, and remediation pointers.

## What's out of scope (be honest with buyers)
- **No changes.** This never edits a policy, removes an allow-list entry, or disables a transport rule. Fixing findings is the paired **Remediation Playbook** (pilot-first).
- **Not an EOP/MDO build or hardening project.** Standing up and hardening email protection is the **DEFMDOP2** area. This assesses what exists.
- **Not threat hunting or IR.** Live hunting and incident response are **THREATHUNT** / **SOCXDR**. This reads posture, not live threats. *IR determinations belong to the SOC.*
- **Not a licensing purchase.** We *read* plan state and flag gaps as findings; buying/mapping plans is separate. *Plan/feature mapping changes — verify.*
- **No risk-acceptance decision.** The assessment supplies the score and evidence; accepting or prioritizing risk is the customer's.

## Authentication and connections used
- **Exchange Online PowerShell** (`Connect-ExchangeOnline`) and **Security & Compliance PowerShell** (`Connect-IPPSSession`) signed in as **Global Reader** / **Security Reader** / **View-Only Configuration** — all MDO/EOP policy reads use `Get-` cmdlets only (per Global Requirements G2). *Verify current read-role coverage for these cmdlets.*
- **Microsoft Graph (read-only)** for **Secure Score** MDO recommendations and **advanced hunting** (`EmailEvents`, `EmailPostDeliveryEvents`) via `AdvancedHunting.Read.All`. *Verify current scope names.*
- No write scopes are ever requested; `SOAMDO-Validate.ps1` fails if any are present.

## The standard deployment model
> **Assess the current email-protection configuration (discovery) → configure nothing; score and rank instead → pilot the read against a representative recipient scope → validate read-only access and that the effective-policy math reconciles with the portal's configuration analyzer → expand to the whole tenant, deliver the findings report, and re-run periodically to trend.** The repeatable pattern is **Assess → Configure → Pilot → Validate → Expand**; this product owns **Assess**, and the fixes are the Remediation Playbook's, pilot-first.
