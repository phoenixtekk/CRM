# 1. Solution Overview — Onboarding Accelerator: Microsoft Defender for Identity

## What Microsoft Defender for Identity is
Microsoft Defender for Identity (MDI) is the **identity threat detection & response (ITDR)** pillar of Microsoft Defender. It detects attacks against **on-premises Active Directory** — and the identity infrastructure around it (AD FS, AD CS) — by installing a lightweight **sensor** directly on domain controllers and federation/certificate servers. The sensor inspects local traffic and events, sends signal to the cloud service, and surfaces alerts in the unified Defender portal at `security.microsoft.com` under **Identities**. MDI catches the identity phase of an intrusion: reconnaissance (LDAP/SMB enumeration), credential theft (Kerberoasting, DCSync, Pass-the-Hash/Ticket), lateral movement, and domain-dominance techniques (Golden Ticket, skeleton key).

Because the sensor runs *on* the domain controller, there is **no agentless option** for on-prem AD — onboarding MDI is fundamentally a **sensor-deployment** exercise, done in a change window, one server at a time.

## Why this matters
Almost every attack that reaches an enterprise passes through Active Directory. Attackers who land on one endpoint pivot to AD to escalate, and traditional endpoint or SIEM tooling barely sees that identity movement. MDI is designed exactly for it — but only if it is **fully onboarded**. A tenant with one sensor on one domain controller has blind spots on every other DC; a tenant with no **honeytokens** loses the highest-signal, lowest-noise detections (any touch of a decoy account is suspicious by definition); a tenant that never triages **ISPM** leaves exploitable posture gaps (unconstrained delegation, legacy protocols, weak certificate templates) in place. This accelerator gets the whole pillar onboarded and *validated* — proven that a detection actually fires — rather than assumed-working.

## How it works
1. **Directory Service Account (DSA)** — a read-only account (gMSA recommended) is prepared so sensors can query AD for extra context. It is configured under **Settings → Identities → Directory Service accounts** before sensors are deployed.
2. **Sensors** are installed on **domain controllers** first (then AD FS / AD CS servers). Each sensor is registered with an **access key** from the portal, starts inspecting local traffic, and reports **Running / Healthy**.
3. **Sensitive entities** (Domain Admins, Tier-0 servers, high-value accounts) are **tagged** so MDI weights alerts on them correctly.
4. **Honeytokens** — decoy user/computer accounts that no legitimate process ever touches — are planted and tagged as honeytokens; any authentication or query against them raises a high-confidence alert.
5. **Identity posture (ISPM)** recommendations are enabled and triaged — MDI reports exploitable AD/identity misconfigurations (unconstrained delegation, printer spooler on DCs, legacy protocols, risky certificate templates) that reduce attack surface when fixed.
6. **Detections are validated** — a benign, controlled test (a Microsoft-documented safe simulation or a honeytoken touch) confirms an alert fires in the portal and in advanced hunting.
7. **Response actions** (disable user, force password reset via the connected identity workloads) stay **approval-gated** during the pilot.

## What you can control
- **Sensor coverage** — which domain controllers and AD FS/AD CS servers carry a sensor, and the order they onboard (pilot DC first).
- **Directory Service Account** — a read-only gMSA (recommended) versus a standard account.
- **Sensitive-entity tagging** — which accounts, groups, and servers are marked high-value.
- **Honeytokens** — the decoy accounts you plant and tag as tripwires.
- **ISPM triage** — which posture recommendations you remediate first.
- **Response posture** — approval-gated during pilot; automation decisions stay with the SOC.

## Limitations (be honest with buyers)
- MDI is **license-gated** (Defender for Identity, commonly via M365 E5 / E5 Security or a standalone plan). Onboarding without the plan fails — *verify current availability in your tenant.*
- **Sensors run on domain controllers** and need resources, network reach to the MDI service, and a **change window**; they are not a portal-only toggle.
- MDI protects **on-premises AD**; cloud-only (Entra ID) identity risk is covered by Entra ID Protection and adjacent solutions, not MDI.
- **Detections, tables, and ISPM** populate over time — allow warm-up after each sensor comes online before judging coverage.
- MDI improves identity detection; it does not replace AD hardening, patching, tiered administration, or the SOC's incident-response decisions.

## Connections and authentication used
- The **unified Defender portal** (`security.microsoft.com` → **Settings → Identities**) for activation, DSA, sensors, tags, honeytokens, and ISPM.
- **Microsoft Graph Security** and the **Microsoft 365 Defender** APIs (via the `Microsoft.Graph` PowerShell modules) for read-only discovery, validation, reporting, and advanced-hunting (`IdentityInfo`, `IdentityLogonEvents`, `IdentityDirectoryEvents`, `IdentityQueryEvents`, `AlertInfo`).
- **On-premises Active Directory** read helpers (`Get-ADDomainController`, `Get-ADUser`) for local sensor-candidate and honeytoken discovery.
- Least-privilege roles: **Security Administrator** for configuration, **Security Reader** for read-only work, and **Global Administrator** only for one-time first-service activation.

## The standard deployment model
> **Assess readiness (license, roles, DCs, DSA) → configure the DSA and portal settings → install a pilot-DC sensor and plant honeytokens → validate sensor health and that a detection fires → expand to the remaining DCs and AD FS/AD CS.** Repeatable pattern: **Assess → Configure → Pilot → Validate → Expand**, with response actions kept approval-gated until trusted.
