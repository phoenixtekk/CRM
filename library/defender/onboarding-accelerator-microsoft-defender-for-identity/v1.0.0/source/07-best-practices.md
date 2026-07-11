# 7. Best Practices — Onboarding Accelerator: Microsoft Defender for Identity

Field-proven guidance for keeping the Defender for Identity deployment healthy, high-signal, and low-risk.

## Onboard sensors in a ring, never all at once
- Install the sensor on **one pilot domain controller** (`MDI Sensor Host – Pilot DC – Pilot`) first, health-check it, validate a detection, then expand DC-by-DC in change windows. A bad rollout on every DC simultaneously is avoidable.
- Cover **every** domain controller eventually — a single un-sensored DC is a blind spot attackers can use.

## Protect and monitor the sensors
- Domain-controller sensors are security-critical infrastructure. Keep them healthy, patched, and monitored; a silent sensor blinds MDI. Review sensor health on a cadence with `MDIONB-Report.ps1`.
- Extend sensors to **AD FS and AD CS** servers — federation and certificate services are prime attacker targets and MDI has detections specific to them.

## Use a gMSA for the Directory Service Account
- Prefer a **group Managed Service Account** for `MDI Directory Service Account – Tenant – Prod` so there is no static password to rotate or leak. Grant only the read access MDI needs. *Verify current MDI DSA requirements.*

## Honeytokens are your highest-signal detection
- Plant decoy accounts (`MDI Honeytoken – Decoy Identity – Pilot`) that **nothing legitimate ever touches**, tag them, and treat any hit as high-confidence. Give them believable names and place them where an attacker enumerating AD would find them.
- Keep them genuinely idle — a honeytoken used by a real process becomes noise.

## Tag Tier-0 so alerts are weighted correctly
- Tag Domain/Enterprise Admins, DCs, AD FS/AD CS, PKI, backup, and break-glass as sensitive (`MDI Sensitive Entities – Tier0 – Prod`). MDI weights alerts on tagged entities; untagged Tier-0 dilutes the signal that matters most.

## Work ISPM as a trend, not a one-off
- Triage the **identity posture** recommendations by exploitability (unconstrained delegation, spooler on DCs, legacy protocols, risky certificate templates) and track the delta each cycle with `MDIONB-Report.ps1 -SaveBaseline`. Re-baseline after full sensor coverage.

## Keep response actions approval-gated until trusted
- Leave MDI response actions (disable user, force password reset) approval-gated during the pilot and early expansion. Moving toward automatic response is the SOC/security team's decision, made only after coverage and detections are proven.

## Keep licensing and preview facts current
- MDI and some features are **license-gated** and evolve. Before relying on a capability, **verify current availability and plan requirements in your tenant** — do not assume a feature is included.

## Where to go next
Once MDI is onboarded and validated, natural next steps in the catalog:
- The **Microsoft Defender XDR — Unified Onboarding** accelerator to bring MDI together with Endpoint, Office 365, and Cloud Apps into one correlated portal.
- The **Onboarding Accelerator — Microsoft Defender for Endpoint** to add the endpoint pillar an identity attack usually pivots through.
- The **SOC onboarding — Sentinel + Defender XDR** and **advanced KQL threat-hunting** solutions to hunt identity attacks in a SIEM.
- **Entra ID governance / Conditional Access / PIM** solutions to harden the cloud identity layer alongside on-prem AD.
