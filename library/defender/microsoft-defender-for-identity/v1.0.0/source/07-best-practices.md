# 7. Best Practices — Microsoft Defender for Identity

Field-proven guidance for keeping the Defender for Identity deployment healthy, high-signal, low-risk — and for enabling the team and proving the value well.

## Deploy in a ring, never all at once
- Install the sensor on **one pilot domain controller** (`MDI Sensor Host – Pilot DC – Pilot`) first, health-check it, validate a detection, then expand DC-by-DC in change windows. A bad rollout on every DC simultaneously is avoidable.
- Cover **every** domain controller eventually — a single un-sensored DC is a blind spot attackers can use. Extend sensors to **AD FS and AD CS** servers; they are prime attacker targets and MDI has detections specific to them.

## Protect and monitor the sensors
- Domain-controller sensors are security-critical infrastructure. Keep them healthy, patched, and monitored; a silent sensor blinds MDI. Review sensor health on a cadence with `MDIFULL-Report.ps1`.

## Use a gMSA for the Directory Service Account
- Prefer a **group Managed Service Account** for `MDI Directory Service Account – Tenant – Prod` so there is no static password to rotate or leak. Grant only the read access MDI needs. *Verify current MDI DSA requirements.*

## Honeytokens are your highest-signal detection
- Plant decoy accounts (`MDI Honeytoken – Decoy Identity – Pilot`) that **nothing legitimate ever touches**, tag them, and treat any hit as high-confidence. Give them believable names and place them where an attacker enumerating AD would find them. Keep them genuinely idle — a honeytoken used by a real process becomes noise. **Never test a honeytoken in production** — only in a lab.

## Tag Tier-0 so alerts are weighted correctly
- Tag Domain/Enterprise Admins, DCs, AD FS/AD CS, PKI, backup, and break-glass as sensitive (`MDI Sensitive Entities – Tier0 – Prod`). MDI weights alerts on tagged entities; untagged Tier-0 dilutes the signal that matters most.

## Work ISPM as a trend, not a one-off
- Triage the **identity posture** recommendations by exploitability (unconstrained delegation, spooler on DCs, legacy protocols, risky certificate templates) and track the delta each cycle with `MDIFULL-Report.ps1 -SaveBaseline`. Re-baseline after full sensor coverage. Keep a short shortlist (`MDI ISPM Shortlist – Tier0 – Prod`) rather than trying to fix everything at once.

## Enable the team on a pilot, read-only by default
- Teach against a **pilot/lab, not production privileged identities**. The only configuration action in the labs is tagging the honeytoken (facilitator); everything else is discovery, hunting, and reading. Use consistent object names so the take-home artefacts are findable, and make sure every attendee leaves with the saved queries, the honeytoken tag, the ISPM shortlist, and the investigation doc.
- Instill the habits: **work the entity page first** (investigation priority + timeline + lateral-movement path answers most triage before advanced hunting); **treat honeytoken activity as real until disproven**; **hunt with saved queries** to make investigation repeatable; **respect the approval gate** — a clean, evidenced hand-off, not a unilateral action.

## Prove value with benign signal only — never real attacks
- Use **read-only directory enumeration** and a **honeytoken** touch exclusively for the PoC. MDI detects the *pattern* of enumeration from benign commands — you do not need a real attack to prove it. **Never** run credential-dumping tools, exploitation frameworks, DCSync, or anything that modifies AD; adversary emulation belongs in a separate, governed engagement.
- Set the **evaluation criteria in writing first** and feed them to `MDIFULL-Report.ps1 -Scorecard` so the verdict is objective. Allow **warm-up** (timeline, hunting tables, and UEBA populate over minutes to hours) before scoring a "fail." Tear down the PoC-only scope completely and keep only the scorecard.

## Keep response actions approval-gated until trusted
- Leave MDI response actions (disable user, force password reset) approval-gated during the pilot and early expansion. Moving toward automatic response is the SOC/security team's decision, made only after coverage and detections are proven. MDI also feeds XDR **automatic attack disruption** — factor that into the playbook.

## Keep licensing and preview facts current
- MDI and some features are **license-** or **preview-gated** and evolve, and sensor OS support and endpoint URLs change. Before relying on a capability, **verify current availability, sensor support, and the endpoint list in your tenant** — do not assume a feature is included.

## Common anti-patterns to avoid
- Standing up one sensor and calling MDI "deployed."
- Using an active account as a honeytoken (false positives destroy trust in the signal).
- Enforcing ISPM changes mid-enablement without change approval.
- Executing a response action against a production identity "to see what happens."
- Running attack tooling in the PoC instead of benign signal.

## Where to go next
Once MDI is deployed, the team is enabled, and the value is proven, natural next steps in the catalog:
- **Microsoft Defender XDR — Unified Onboarding** to bring MDI together with Endpoint, Office 365, and Cloud Apps into one correlated portal.
- **SOC Operations — Sentinel + Defender XDR** to stream MDI into a SIEM for long-term hunting and SOC process design.
- **Advanced Threat Hunting (KQL)** to go deeper on cross-pillar hunting beyond the identity tables.
- **Entra ID governance / Conditional Access / PIM** and **Active Directory hardening / tiered admin** solutions to harden the identity layer end to end alongside on-prem AD.
