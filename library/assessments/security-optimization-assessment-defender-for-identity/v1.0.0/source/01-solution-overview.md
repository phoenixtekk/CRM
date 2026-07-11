# 1. Solution Overview — Security Optimization Assessment: Defender for Identity

## What this assessment is
This solution is a **read-only Security Optimization Assessment** for **Microsoft Defender for Identity (MDI)**. It does not install a sensor or change any configuration. It **discovers** how MDI is set up, **scores** it against Microsoft best practice, and produces a **prioritized, risk-ranked findings report**. The deliverable is *evidence and a plan*; the fixes are a separate, pilot-first exercise (the paired **Remediation Playbook**).

The problem it solves is the illusion of coverage. MDI is only watching an identity surface where a **healthy sensor** is installed — so a single un-sensored domain controller (or an AD FS / AD CS server) is a blind spot an attacker can move through undetected. The assessment reconciles what *should* be covered (the real AD inventory) against what *is* covered (the sensor list), then evaluates the supporting posture: the directory-service account, honeytokens, ISPM, and detection tuning.

## How Defender for Identity fits together (what we score)
- **Sensors and coverage.** MDI sensors run on **domain controllers**, and (where present) **AD FS**, **AD CS**, and can monitor **Entra Connect** servers. Coverage is only complete when **every** such server has an **installed and healthy** sensor. *We reconcile the AD inventory against the sensor list — the single most important check.* Sensor **health** (running, up to date, not delayed) matters as much as presence.
- **Directory Service Account (DSA).** MDI uses a directory-service account to query Active Directory and enrich identity data (SAM-R, group membership, etc.). Best practice is a **group-managed service account (gMSA)** with least privilege. A missing, over-privileged, or password-based DSA is a hygiene finding. *DSA requirements evolve — verify current guidance.*
- **Honeytokens.** Decoy accounts/entities that no legitimate user should ever touch; **tagging** them in MDI means any authentication or query against them raises a high-fidelity alert. Absent or untagged honeytokens are a missed, cheap detection.
- **Identity Security Posture Management (ISPM).** MDI's posture **assessments/recommendations** (e.g. unsecure protocols, legacy configurations, risky delegations, exposed credentials) plus the identity-related **Microsoft Secure Score** recommendations quantify where the identity fabric is weak. *We read these and fold the top items into the ranked findings. Some assessments are preview — verify.*
- **Detections and tuning.** MDI raises detections across the attack kill-chain (reconnaissance, compromised credentials, lateral movement, domain dominance). Tuning matters: sensible **exclusions** (so it is not noisy) without over-excluding (so it is not blind), and correctly scoped **action accounts** for any response actions. *Response actions are write operations — out of scope here and SOC-gated.*
- **Alerts & integration signal.** Whether MDI alerts flow into Microsoft Defender XDR and are being triaged, and the volume/type of identity detections (via advanced hunting `IdentityDirectoryEvents`, `IdentityLogonEvents`, `IdentityInfo`), to rank findings by real exposure.

## How the score works
Each area yields **checks** with a best-practice expectation (from the baseline named in the report — Microsoft MDI guidance + identity Secure Score, *verify current guidance*). Every check is **Pass / Partial / Fail / N-A**, and every non-pass becomes a **finding** with a **severity** (High / Medium / Low — an un-sensored DC is High), the **evidence**, and a **remediation pointer**. Areas roll up into a **posture score (%)** you can trend. The score measures; **which findings to accept, defer, or fix, and in what order, is your security owners' decision.**

## What's in scope
- Read-only **discovery**: the AD inventory of domain controllers (and AD FS / AD CS / Entra Connect servers), the MDI **sensor** list and health, the **DSA** configuration signal, **honeytoken** tagging, **ISPM** recommendations, and detection/exclusion configuration where readable.
- **Sensor coverage** reconciliation — AD inventory vs. installed/healthy sensors, naming the blind DCs.
- **Scoring** against the named MDI + identity Secure Score baseline, per-check Pass/Partial/Fail.
- A **findings report** (HTML + CSV) with severities, evidence, and remediation pointers.

## What's out of scope (be honest with buyers)
- **No changes.** This never installs a sensor, changes the DSA, plants a honeytoken, or tunes a detection. Those are the paired **Remediation Playbook** (pilot-first).
- **No response actions.** Disabling a user, forcing password reset, etc. are write operations and **SOC-gated** — never part of an assessment.
- **Not an MDI deployment project.** Standing up MDI and rolling out sensors is deployment work (see **DEFXDR** for unified onboarding). This assesses what exists.
- **Not threat hunting or IR.** Live hunting and incident response are **THREATHUNT** / **SOCXDR**. *IR and detection-response determinations belong to the SOC.*
- **No risk-acceptance decision.** The assessment supplies the score and evidence; accepting or prioritizing risk is the customer's.

## Authentication and connections used
- **Active Directory read** (RSAT / the `ActiveDirectory` PowerShell module) as a normal **read-only** domain user — to enumerate domain controllers and locate AD FS / AD CS roles (the coverage denominator). No AD writes.
- **Microsoft Graph (read-only)** signed in as **Security Reader** / **Global Reader** — for identity **Secure Score** recommendations and **advanced hunting** (`IdentityInfo`, `IdentityDirectoryEvents`, `IdentityLogonEvents`) via `AdvancedHunting.Read.All`. *Verify current scope names.*
- **Defender portal read** for MDI sensor/health, DSA, and honeytoken state where no public read API exists — the scripts collect what is programmatically available and clearly flag portal-confirmation items as **verify**. No write scopes are ever requested.

## The standard deployment model
> **Assess the current MDI configuration and reconcile sensor coverage (discovery) → configure nothing; score and rank instead → pilot the read against one domain/site → validate read-only access and that the DC inventory reconciles with reality → expand to the whole forest, deliver the findings report, and re-run periodically to trend.** The repeatable pattern is **Assess → Configure → Pilot → Validate → Expand**; this product owns **Assess**, and the fixes are the Remediation Playbook's, pilot-first.
