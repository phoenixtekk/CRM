# 7. Best Practices — Proof-of-Concept Kit: Microsoft Defender for Office 365

Field-proven guidance for running a clean, safe, conclusive MDO proof of concept.

## Keep the PoC scoped and reversible
- Scope the preset security policy to **pilot users only** (`MDO PoC – Pilot Users – Pilot`). Never widen it to the whole org during a PoC — the value is that you can roll the scope back without touching production mail flow.
- Preview every change with `-WhatIf` first (`POCMDO-Enable.ps1`, `POCMDO-Teardown.ps1`).

## Benign signal only — never real phishing or malware
- Use **Attack Simulation Training**, **GTUBE**, **EICAR**, and a benign **Safe Links** test URL exclusively. They are the sanctioned, harmless ways to exercise MDO.
- **Never** send real phishing, attach real malware, or embed a live malicious URL. Attack Simulation Training exists precisely so you don't have to.

## Tell the pilot users
- Coordinate with the pilot mailboxes before launching the simulation. A PoC is an evaluation, not a covert test of the users — that framing keeps trust and produces cleaner results.

## Set the bar before you run
- Agree the **evaluation criteria** in writing first (Requirement 2.5). Feed them into `POCMDO-Scorecard.ps1` so the verdict is objective, not a vibe.

## Allow for delivery, detonation, and ZAP timing
- Safe Attachments detonation, Safe Links time-of-click, and ZAP act at different moments. Give the pipeline a few minutes before scoring a "fail," and use `POCMDO-Validate.ps1` to see when signal has arrived.

## Mind the licensing gates
- Safe Links / Safe Attachments / anti-phish need **P1**; **Threat Explorer, Attack Simulation Training, and AIR need P2**. **Verify current plan availability in your tenant** before assuming a capability is included, and if P2 is absent, note the simulation/Explorer demos as unlicensed rather than "failed."

## Tear down completely
- Remove the pilot scope, end the simulation, and **purge** the `MDO-PoC-TESTSIGNAL` messages from quarantine and inboxes. Then confirm with `POCMDO-Validate.ps1`. Keep only the scorecard.

## Defer the decisions to the owners
- Whether the PoC "passed," how to weight criteria, and whether to proceed to org-wide hardening are **the customer's** decisions. Policy-hardening and incident-response runbooks are the **security team's**. This kit delivers the proof, not the verdict.

## Where to go next
Once the PoC proves MDO, natural next steps in the catalogue:
- The **Defender for Office 365 (P2) — Threat Explorer, Attack Simulation & AIR** solution to operationalise the email pillar org-wide.
- The **EOP / MDO email-hygiene hardening** solution for baseline anti-spam/anti-phish tuning.
- The **Defender XDR Deployment & Unified Onboarding** solution to correlate MDO with Endpoint, Identity, and Cloud Apps.
- The **Sentinel SOC/XDR integration** solution to stream MDO into a SIEM for long-term hunting.
