# 7. Best Practices — Technical Blocker Mitigation: Defender for Endpoint

Field-proven guidance for diagnosing a stalled MDE rollout cleanly, fixing the *right* thing, and not making it worse.

## Diagnose before you change anything
- Run `TBMMDE-Discovery.ps1` **first** and read the signal chain top-down. The earliest broken link is the blocker; fixing a later link while an earlier one is broken wastes time.
- Resist the urge to "re-onboard everything." Most stalls are one broken link (a disabled connector, a blocked endpoint) affecting many devices — fix the link, not the symptoms.

## Change one thing, on the affected subset, then verify
- Apply exactly **one** documented fix, to `MDE Blocker Triage – Affected Ring – Diagnose` only, then run `TBMMDE-Validate.ps1`. One change at a time keeps cause and effect clear.
- Never resume the fleet-wide rollout until the affected subset passes its test gate.

## Keep everything read-only until you deliberately fix
- Every script here is read-only by design. Treat the *fix* as a separate, conscious action taken in the portal/Intune — not something a script should ever do for you.
- Never disable an existing control (AV, an ASR rule, a policy) to "test" a blocker; that trades a rollout problem for a protection gap.

## Connectivity is the usual suspect for health blockers
- When sensors onboard but go **Inactive / Impaired communication**, test the service endpoints first (`TBMMDE-Connectivity.ps1`). A proxy/firewall block is the most common root cause and the fix belongs to networking. *Verify the current Defender endpoint list — it changes.*

## Let telemetry and health warm up
- Onboarding state, sensor health, and advanced-hunting tables populate over minutes to hours, not seconds. Give a fix time before calling it a failure, then re-validate.

## Keep licensing and preview facts current
- Defender for Endpoint features are **plan-gated** (P1/P2). Before concluding "it's broken," confirm the feature is even licensed and activated — *verify current availability and plan requirements in your tenant.*

## Escalate with evidence, not a description
- If the blocker survives a correct fix, it may be a service issue. Attach `MDE Support Bundle – <case> – Escalate` and the on-device client-analyzer output to the case. A complete bundle resolves cases far faster than a written symptom.

## Defer the security decisions to the owners
- Device isolation, investigation-package collection, and automated-response levels are **the SOC/security team's** decisions, kept approval-gated. This solution diagnoses and clears the *deployment* blocker; the response posture stays with the customer.

## Where to go next
Once the rollout is unblocked, natural next steps in the catalog:
- **Defender XDR Deployment & Unified Onboarding** to finish onboarding the remaining pillars and correlate incidents in one portal.
- **Microsoft Defender for Cloud — CSPM & Secure Score Remediation** to move from "onboarded" to "hardened."
- The endpoint-security **optimization** solutions (ASR, attack-surface reduction, EDR tuning) to raise protection once telemetry is flowing.
- The **Sentinel** SOC/XDR integration to stream MDE signal into a SIEM for long-term hunting.
