# 7. Best Practices — Proof-of-Concept Kit: Microsoft Defender for Identity

Field-proven guidance for running a clean, safe, conclusive MDI proof of concept.

## Keep the PoC scoped and reversible
- Install **one** sensor on a **non-critical or lab domain controller** (`MDI PoC Sensor – Pilot DC – Pilot`). The whole value is that you can uninstall it cleanly without touching the rest of the fleet.
- Preview every change with `-WhatIf` first (`POCMDI-Enable.ps1`, `POCMDI-Teardown.ps1`).

## Benign signal only — never real attacks
- Use **read-only directory enumeration** and a **honeytoken** decoy account exclusively. They exercise the detection pipeline without touching anything.
- **Never** run credential-dumping tools, exploitation frameworks, DCSync, or anything that modifies AD. MDI detects the *pattern* of enumeration from benign commands — you do not need a real attack to prove it. Adversary emulation belongs in a separate, governed engagement.

## Use a honeytoken for a clean, high-fidelity signal
- Tag a **dormant, unused** account as the honeytoken (`MDI PoC Honeytoken – Pilot`) — never a real, in-use identity. Because a honeytoken should never be touched, any activity against it is an unambiguous detection, which makes for a crisp PoC demonstration.

## Respect the domain controller
- The sensor runs on a DC — treat it as security-critical infrastructure. Install in an approved **change window**, confirm sensor health, and monitor resources. Uninstall cleanly at teardown.

## Set the bar before you run
- Agree the **evaluation criteria** in writing first (Requirement 2.7). Feed them into `POCMDI-Scorecard.ps1` so the verdict is objective.

## Allow warm-up before judging
- The identity timeline, hunting tables, and UEBA scoring populate over **minutes to hours** after sensor install. Give the pipeline time before scoring a "fail," and use `POCMDI-Validate.ps1` to check when signal has arrived.

## Keep response approval-gated
- Any response action stays in an **approval/simulate** posture for the PoC. The decision to enable automated response is a production decision for the SOC/security team.

## Tear down completely
- Untag the honeytoken, uninstall the sensor, remove the PoC-only DSA, and resolve the `MDI-PoC-TESTSIGNAL` alerts. Then confirm with `POCMDI-Validate.ps1`. Keep only the scorecard.

## Keep licensing and preview facts current
- MDI is license-gated, and sensor OS support and endpoint URLs change. **Verify current availability, sensor support, and the endpoint list in your tenant** before assuming.

## Where to go next
Once the PoC proves MDI, natural next steps in the catalogue:
- The **Defender XDR Deployment & Unified Onboarding** solution to deploy sensors fleet-wide and correlate MDI with Endpoint, Office, and Cloud Apps.
- **Active Directory hardening / tiered admin** solutions to reduce the attack surface MDI watches.
- The **Entra ID governance / Conditional Access** solutions to harden the identity layer end to end.
- The **Sentinel SOC/XDR integration** solution to stream MDI into a SIEM for long-term hunting.
