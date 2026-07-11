# 7. Best Practices — Technical Blocker Mitigation: Defender for Identity

Field-proven guidance for diagnosing a stalled MDI rollout cleanly, fixing the *right* thing, and treating domain controllers with the care they deserve.

## Diagnose before you change a domain controller
- Run `TBMMDI-Discovery.ps1` and `TBMMDI-AuditPolicy.ps1` **first**. Read the signal chain top-down; the earliest broken link is the blocker. A DC is security-critical infrastructure — do not change audit policy or accounts on a hunch.
- A "healthy but detects nothing" sensor is almost always a **DSA, NNR, or event-collection** gap, not a broken sensor — confirm which link before reinstalling anything.

## Change one thing, on the affected sensor, in a change window, then verify
- Apply exactly **one** documented fix, to the DC in `MDI Blocker Triage – Affected Sensors – Diagnose`, inside a change window, then run `TBMMDI-Validate.ps1`. One change at a time keeps cause and effect clear.
- Never resume the DC-wide rollout until the affected sensor passes its test gate.

## Keep everything read-only until you deliberately fix
- Every script here is read-only, including the on-DC audit check. Treat the *fix* (audit policy, DSA, ports, sensor reinstall) as a separate, conscious change-window action.
- Never loosen an existing audit or account control beyond what MDI documents — over-permissioning the DSA is a security risk.

## Protect the DSA and the sensors
- Use a read-only **gMSA** for the DSA per current guidance; do not grant more than MDI needs. Keep sensors patched to the current version and monitor their health on a cadence — a silent sensor blinds MDI.

## Let health and tables warm up
- Sensor health, NNR, and the `Identity*` hunting tables populate over minutes to hours after a fix. Give it time before calling the fix a failure, then re-validate.

## Keep licensing and requirement facts current
- MDI is **plan-gated**, and DSA requirements, NNR ports, and supported sensor OS versions **change**. Before concluding "it's broken," *verify the current requirements and service endpoints in your tenant.*

## Escalate with evidence, not a description
- If the sensor survives a correct fix, attach `MDI Support Bundle – <case> – Escalate` plus the sensor's own log-collection output to the case. A complete bundle resolves cases far faster than a written symptom.

## Defer the security decisions to the owners
- Disable-user, force-password-reset, and confirm-compromised actions are **the SOC/security team's** decisions, kept approval-gated. This solution diagnoses and clears the *deployment* blocker; the response posture stays with the customer.

## Where to go next
Once the rollout is unblocked, natural next steps in the catalog:
- **Defender XDR Deployment & Unified Onboarding** to correlate identity alerts with endpoint, email, and cloud-app signal in one portal.
- **Entra ID Conditional Access / PIM / passwordless** solutions to harden the identity layer MDI protects.
- The **Sentinel** SOC/XDR integration to stream MDI signal into a SIEM for long-term hunting.
