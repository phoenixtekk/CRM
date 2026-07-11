# 7. Best Practices — Proof-of-Concept Kit: Microsoft Defender for Endpoint

Field-proven guidance for running a clean, safe, conclusive MDE proof of concept.

## Keep the PoC scoped and reversible
- Onboard **test devices only** into `MDE PoC – Pilot Ring – Pilot`. Never point a PoC at production endpoints — the whole value is that you can tear it down with zero blast radius.
- Preview every change with `-WhatIf` first (`POCMDE-Enable.ps1`, `POCMDE-Teardown.ps1`). Confirm the plan before you apply it.

## Benign signal only — never real attacks
- Use **EICAR** and Microsoft's **built-in evaluation simulations** exclusively. They are designed for safe evaluation and are enough to prove the detection pipeline.
- **Do not** download live malware, run exploit frameworks, or disable a control to "see what happens." A PoC proves the product works; it is not a red-team exercise. Adversary emulation belongs in a separate, governed engagement.

## Set the bar before you run
- Agree the **evaluation criteria** in writing first (Requirement 2.5). A PoC that defines "pass" afterwards proves nothing. Feed those criteria into `POCMDE-Scorecard.ps1` so the result is objective.

## Keep automated response approval-gated
- Leave **AIR** at **Semi — require approval** for the entire PoC. You want to *see* the automated investigation start, not have it isolate a device unattended. Moving toward higher automation is a production decision for the SOC/security team.

## Allow warm-up before judging
- Advanced-hunting tables (`DeviceEvents`, `AlertInfo`, `AlertEvidence`) and Secure Score populate over **minutes to hours**. Give the pipeline time before scoring a "fail" — use `POCMDE-Validate.ps1` to check when signal has arrived.

## Tear down completely
- Run teardown and then **confirm** with `POCMDE-Validate.ps1` that nothing is left onboarded. Delete the EICAR file, resolve the `MDE-PoC-TESTSIGNAL` alerts, remove the Intune policy, and (optionally) the pilot group. Keep only the scorecard as your record.

## Keep licensing and preview facts current
- Defender for Endpoint **P1/P2** and **MDVM** features are license-gated, and Microsoft's simulation catalogue changes. **Verify current availability and plan requirements in your tenant** before assuming a capability is included.

## Defer the decisions to the owners
- Whether the PoC "passed," how to weight the criteria, and whether to proceed to production are **the customer's** decisions. Automated-response guardrails and incident-response runbooks are the **SOC/security team's**. This kit delivers the technical proof, not the verdict.

## Where to go next
Once the PoC proves MDE, natural next steps in the catalogue:
- The **Defender XDR Deployment & Unified Onboarding** solution to move from pilot to a real, correlated production rollout across all four Defender pillars.
- The **Defender for Endpoint onboarding accelerator / Intune endpoint-security** solutions to scale onboarding properly (not from the PoC ring).
- The **Defender for Office 365 (P2) — Threat Explorer, Attack Simulation & AIR** and **Threat Hunting** solutions to deepen detection and hunting.
- The **Sentinel SOC/XDR integration** solution to stream MDE into a SIEM for long-term hunting and SOAR.
