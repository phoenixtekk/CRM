# 1. Solution Overview — Microsoft Defender for Identity

## What Microsoft Defender for Identity is
Microsoft Defender for Identity (MDI) is the **identity threat detection & response (ITDR)** pillar of Microsoft Defender. It detects attacks against **on-premises Active Directory** — and the identity infrastructure around it (AD FS, AD CS, Entra Connect) — by installing a lightweight **sensor** directly on domain controllers and federation/certificate servers. The sensor inspects local authentication and directory traffic and behavior, streams signal to the cloud service, and surfaces alerts in the unified Defender portal at `https://security.microsoft.com` under **Identities**. MDI catches the identity phase of an intrusion:

- **Reconnaissance** — account/SPN/network enumeration (LDAP/SAMR/DNS recon), the classic first step of an attack (MITRE Discovery, TA0007).
- **Compromised credentials** — brute force and password spray (Credential Access, TA0006).
- **Lateral movement** — Pass-the-Hash, Pass-the-Ticket, overpass-the-hash, remote code execution (Lateral Movement, TA0008).
- **Domain dominance** — DCSync, DCShadow, Golden Ticket, skeleton key (Credential Access / Persistence).

Because the sensor runs *on* the domain controller, there is **no agentless option** for on-prem AD — deploying MDI is fundamentally a **sensor-deployment** exercise, done in a change window, one server at a time.

MDI also surfaces **Identity Security Posture Management (ISPM)** recommendations (exploitable misconfigurations such as unconstrained delegation, legacy protocols, printer-spooler on DCs, risky certificate templates), lets you plant **honeytokens** (decoy accounts that should never authenticate — any touch is high-fidelity evidence of an intruder), and feeds **Defender XDR**: MDI alerts correlate into unified incidents, enrich the **user/device entity pages** with a timeline and **UEBA / investigation-priority** scoring, and are queryable in **advanced hunting** (the `Identity*` tables).

## Why this matters
Almost every attack that reaches an enterprise passes through Active Directory. Attackers who land on one endpoint pivot to AD to escalate, and traditional endpoint or SIEM tooling barely sees that identity movement. MDI is designed exactly for it — but only if it is **fully deployed, operated by a capable team, and proven to work**:

- A tenant with one sensor on one DC has blind spots on every other DC.
- A tenant with no **honeytokens** loses the highest-signal, lowest-noise detection MDI produces.
- A tenant that never triages **ISPM** leaves exploitable posture gaps in place.
- A team that has never investigated an identity alert cannot act on one when it matters.
- A deployment nobody has ever *proven* is a hard sell to the business.

This solution closes all five gaps — the whole pillar deployed, the team enabled, and the value proven — rather than assumed-working.

## How it works — the three phases

### Phase 1 — Deploy (onboard the pillar)
1. **Directory Service Account (DSA)** — a read-only account (gMSA recommended), `MDI Directory Service Account – Tenant – Prod`, is prepared so sensors can query AD for extra context, and registered under **Settings → Identities → Directory Service accounts**.
2. **Sensors** are installed on **domain controllers** first (then AD FS / AD CS), each registered with an **access key** from the portal, and confirmed **Running / Healthy**.
3. **Sensitive entities** (Tier-0 — Domain/Enterprise Admins, DCs, AD FS/AD CS, PKI, backup, break-glass) are **tagged** as `MDI Sensitive Entities – Tier0 – Prod` so MDI weights alerts on them correctly.
4. **Honeytokens** — decoy accounts `MDI Honeytoken – Decoy Identity – Pilot` — are planted and tagged.
5. **ISPM** recommendations are enabled and triaged into a remediation shortlist.
6. **Detections are validated** — a benign, controlled test confirms an alert fires in the portal and in advanced hunting.

### Phase 2 — Enable the team (five hands-on labs)
Run against the pilot/lab scope, read-only or preview-first, each with a pass/fail gate:
- **Lab 1 — Identity attack paths & the entity page.** Read a user/device entity page; interpret investigation priority and lateral-movement paths.
- **Lab 2 — Recon & lateral-movement detections.** Recognize the detection families, map them to MITRE ATT&CK, triage an alert; run and save the recon/lateral-movement hunting queries.
- **Lab 3 — Honeytokens.** Choose, tag, and verify a honeytoken; understand and monitor its detection.
- **Lab 4 — ISPM posture.** Read and prioritize the recommendations into a shortlist (no enforcement).
- **Lab 5 — Investigation end-to-end.** Run a full identity investigation across the entity timeline and advanced hunting; document findings; rehearse the **approval-gated** response.

### Phase 3 — Prove the value (guided PoC)
1. **Generate benign signal** — harmless read-only enumeration (`net group` / `nltest` / LDAP reads — the same commands admins run daily) plus a honeytoken touch. **No real attack, exploit, credential theft, or malware, ever.**
2. **Demonstrate** the signal produces a real detection — an alert in the incident queue, an entry on the identity timeline, rows in advanced hunting, and UEBA scoring.
3. **Score** the observations against your written evaluation criteria.
4. **Tear down** the PoC-only scope cleanly (untag, resolve test alerts) — the production sensors remain.

## What you can control
- **Sensor coverage** — which DCs and AD FS/AD CS servers carry a sensor, and the order they onboard (pilot DC first).
- **Directory Service Account** — a read-only gMSA (recommended) versus a standard account.
- **Sensitive-entity tagging** and **honeytokens** — which entities are high-value and which decoys are tripwires.
- **ISPM triage** — which posture recommendations you remediate first.
- **Which capabilities to prove** in the PoC and the pass/fail bar.
- **Response posture** — approval-gated throughout; automation decisions stay with the SOC.

## Limitations (be honest with buyers)
- MDI is **license-gated** (Defender for Identity, commonly via M365 E5 / E5 Security or a standalone plan). Deployment without the plan fails — *verify current availability in your tenant.*
- **Sensors run on domain controllers** and need resources, network reach to the MDI service, and a **change window** — not a portal-only toggle, and not installable agentlessly.
- MDI protects **on-premises AD**; cloud-only (Entra ID) identity risk is covered by Entra ID Protection and adjacent solutions, not MDI.
- **Detections, tables, ISPM, and UEBA** populate over time — allow warm-up after each sensor comes online before judging coverage.
- PoC signal is **benign and simulated only** — it proves the detection pipeline, not resilience to a real adversary (that is a red-team engagement, out of scope).
- MDI improves identity detection; it does not replace AD hardening, patching, tiered administration, or the SOC's incident-response decisions.

## Connections and authentication used
- The **unified Defender portal** (`security.microsoft.com` → **Settings → Identities**) for activation, DSA, sensors, tags, honeytokens, ISPM, incidents, entity pages, and advanced hunting.
- **Microsoft Graph Security** and the advanced-hunting API (via the `Microsoft.Graph` PowerShell modules) for read-only discovery, validation, reporting, scoring, and hunting over `IdentityInfo`, `IdentityLogonEvents`, `IdentityDirectoryEvents`, `IdentityQueryEvents`, and `AlertInfo`. *Confirm exact scopes and availability in your tenant.*
- **On-premises Active Directory** read helpers (`Get-ADDomainController`, `Get-ADUser`, LDAP/`net`/`nltest`) for sensor-candidate/honeytoken discovery and benign PoC signal.
- Least-privilege roles: **Security Administrator** for configuration (and the honeytoken tag), **Security Reader** for read-only work, **Domain Admin** (change window) for sensor install, and **Global Administrator** only for one-time first-service activation.

## The standard deployment model
> **Assess readiness (license, roles, DCs, DSA) → configure the DSA and portal settings → pilot one DC (sensor, tags, honeytokens) and validate detections → enable the team with the labs and prove value with the PoC → expand to the remaining DCs and AD FS/AD CS.** Repeatable pattern: **Assess → Configure → Pilot → Validate → Expand**, with response actions kept approval-gated until trusted.

## What is out of scope (and where it lives)
- **Unified multi-pillar onboarding** (Endpoint, Office 365, Cloud Apps into one correlated portal) — the **Microsoft Defender XDR — Unified Onboarding** solution.
- **SIEM integration and SOC process design** — the **SOC Operations — Sentinel + Defender XDR** solution.
- **Broad cross-pillar KQL hunting** beyond the identity tables — the **Advanced Threat Hunting (KQL)** solution.
- **Incident-response, regulatory, and records decisions** — the customer's SOC/security/compliance functions.
