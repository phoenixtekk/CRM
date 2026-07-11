# 2. Requirements Guide — Proof-of-Concept Kit: Microsoft Defender for Endpoint

Verify **every** requirement before enabling anything. Each entry: **Description · Why · Verify · Implement-if-missing.** Category-wide prerequisites (tenant, licensing, admin roles, onboarding reach, network access, pilot ring, workspace, response governance) are in `global-requirements-defender.md` — do not repeat them; the items below are **specific to running a scoped MDE proof of concept**. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

## 2.1 Defender for Endpoint plan available to activate
**Description:** A licensed **Defender for Endpoint P1 or P2** plan the tenant can activate for the PoC.
**Why:** EDR, AIR, and advanced hunting are the capabilities being proven; without the plan MDE cannot be initialized or will silently limit features.
**Verify:** Admin center → **Billing → Licenses** shows a Defender for Endpoint plan; `security.microsoft.com` → **Settings → Endpoints** loads. Run `POCMDE-Enable.ps1 -WhatIf`. *Verify current plan features (P1 vs P2, MDVM add-on) in your tenant.*
**Implement-if-missing:** Assign the Defender for Endpoint plan (often bundled in M365 E5 / E5 Security) before enabling.

## 2.2 Pilot device ring (test devices only)
**Description:** A small set of **non-production test devices** to onboard, grouped as `MDE PoC – Pilot Ring – Pilot`.
**Why:** The PoC must touch only disposable test devices so it can be torn down with zero production impact; benign signal is generated on these devices.
**Verify:** An Entra/Intune device group `MDE PoC – Pilot Ring – Pilot` exists with test devices; `POCMDE-Enable.ps1 -WhatIf` lists membership.
**Implement-if-missing:** Create the group and add one to three test devices (a spare laptop or a test VM is ideal).

## 2.3 Onboarding channel to the pilot devices
**Description:** A management channel that reaches the pilot devices — **Intune** (default), Configuration Manager, Group Policy, or the local onboarding script.
**Why:** MDE only collects EDR signal from onboarded devices; the channel must reach the pilot ring to enable, and to offboard at teardown.
**Verify:** Pilot devices are Intune-enrolled (or reachable by GPO/script); `POCMDE-Enable.ps1 -WhatIf` reports onboarding readiness.
**Implement-if-missing:** Enrol the test devices in Intune, or prepare the local onboarding/offboarding scripts from **Settings → Endpoints → Onboarding**.

## 2.4 A tester workstation for benign signal
**Description:** Interactive access to a pilot device where a tester can drop the **EICAR** test file and run a Microsoft built-in simulation.
**Why:** The benign signal must be generated **on** an onboarded device to produce the detection; this is done by hand or with the safe helper in `POCMDE-TestSignal.ps1`.
**Verify:** You can sign in interactively to a device in `MDE PoC – Pilot Ring – Pilot`.
**Implement-if-missing:** Ensure at least one pilot device is accessible (console, RDP, or physical) for the tester.

## 2.5 Evaluation criteria agreed up front
**Description:** A short, written list of what "pass" means — e.g. *detection fires within N minutes, appears on the device timeline, is queryable in advanced hunting, and triggers an automated investigation.*
**Why:** A PoC is only conclusive if the bar is set **before** you run it; the scorecard maps observations to these criteria.
**Verify:** A criteria list exists; `POCMDE-Scorecard.ps1` accepts it as input.
**Implement-if-missing:** Draft 5–8 criteria with the evaluating stakeholders before Step 1. *What counts as "good enough" is the customer's decision.*

## 2.6 Response governance for the PoC (approval-gated)
**Description:** Agreement that **automated investigation & response (AIR)** stays in an **approval/semi** posture for the duration of the PoC.
**Why:** Even in a pilot, AIR can take actions (isolate, quarantine); the PoC proves detection without letting automation act unattended (per `global-requirements-defender.md` G8).
**Verify:** AIR automation level for the pilot device group is **Semi — require approval**; `POCMDE-Validate.ps1` reports it.
**Implement-if-missing:** Set the pilot group's automation level to **Semi — require approval** before generating signal. *The automation-guardrail decision is the SOC/security team's.*

## 2.7 Advanced-hunting read access
**Description:** Permission to run advanced-hunting queries via the portal and the Graph Security API (`ThreatHunting.Read.All`).
**Why:** The validate and scorecard scripts confirm the detection landed in the hunting tables (`DeviceEvents`, `AlertInfo`, `AlertEvidence`).
**Verify:** `security.microsoft.com` → **Hunting → Advanced hunting** runs a query; `POCMDE-Validate.ps1` authenticates and returns rows.
**Implement-if-missing:** Grant the running account **Security Reader** (or higher) and consent to the read-only hunting scope.

---
## Checklist
- [ ] Defender for Endpoint plan available to activate — `POCMDE-Enable.ps1 -WhatIf`
- [ ] Pilot device ring `MDE PoC – Pilot Ring – Pilot` (test devices only)
- [ ] Onboarding channel reaches the pilot devices (Intune/GPO/script)
- [ ] A tester workstation for benign EICAR / simulation signal
- [ ] Evaluation criteria agreed and written down — `POCMDE-Scorecard.ps1`
- [ ] AIR kept approval-gated for the PoC — `POCMDE-Validate.ps1`
- [ ] Advanced-hunting read access (`ThreatHunting.Read.All`)
