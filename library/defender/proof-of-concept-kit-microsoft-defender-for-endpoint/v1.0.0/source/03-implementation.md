# 3. Implementation Guide — Proof-of-Concept Kit: Microsoft Defender for Endpoint

Follow these steps **in order**. Most work is in the **unified Defender portal** (`https://security.microsoft.com`); pilot onboarding uses the **Intune admin center** (`https://intune.microsoft.com`) as the default channel. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

> **Model (run as a PoC):** Assess readiness, enable MDE on a **pilot ring** of test devices only, generate **benign** test signal, validate the detections and score them, then **tear down**. All test signal is EICAR or a Microsoft built-in simulation — **never real malware or attacks**. Keep **AIR approval-gated** throughout. Nothing production is changed.

## Naming (set once, reuse verbatim)
- Pilot device group (Entra/Intune): `MDE PoC – Pilot Ring – Pilot`
- Intune EDR onboarding policy: `MDE PoC EDR Onboarding – Pilot Ring – Pilot`
- Scorecard output file: `MDE PoC Scorecard – Pilot Ring – Validate`
- Test-signal run tag (used in notes/hunting): `MDE-PoC-TESTSIGNAL`

## Step 1 — Assess readiness (read-only)
1. Sign in to `security.microsoft.com` as a **Security Administrator**.
2. Run `POCMDE-Enable.ps1 -WhatIf` — it previews (changes nothing): the licensed MDE plan, admin roles, whether MDE is already activated, the onboarding channel, and whether `MDE PoC – Pilot Ring – Pilot` exists.
3. In **Entra** (`entra.microsoft.com`) → **Groups**, create the device group `MDE PoC – Pilot Ring – Pilot` and add one to three **test** devices only.

## Step 2 — Enable MDE on the pilot ring
1. `security.microsoft.com` → **Settings → Endpoints → Onboarding**. If MDE is not yet initialized, complete the one-time activation (Global Administrator, first time only).
2. `intune.microsoft.com` → **Endpoint security → Microsoft Defender for Endpoint** — confirm **Connection status: Enabled**.
3. **Endpoint security → Endpoint detection and response → Create Policy** (platform: Windows). Name it `MDE PoC EDR Onboarding – Pilot Ring – Pilot`. Set **client configuration package type = Auto from connector**. **Assignments:** assign **only** to `MDE PoC – Pilot Ring – Pilot`. **Review + create.**
4. Alternatively, run `POCMDE-Enable.ps1` (without `-WhatIf`) to assign the EDR policy to the pilot ring — it is `-WhatIf`-gated and shows exactly what it will do before you confirm.
5. On a pilot device, confirm onboarding: `security.microsoft.com` → **Assets → Devices** shows the device as **Onboarded**.
6. `security.microsoft.com` → **Settings → Endpoints → Advanced features** — confirm **Automated Investigation** is on and set the pilot group's **automation level** to **Semi — require approval**.

## Step 3 — Generate benign test signal
1. Run `POCMDE-TestSignal.ps1` from an onboarded pilot device (or follow its printed manual steps). It performs only **benign, documented** actions and tags them `MDE-PoC-TESTSIGNAL`:
   - Drops the **EICAR** anti-malware test file (the standard 68-byte harmless string) to trigger a Microsoft Defender Antivirus detection.
   - Prints the exact portal path to launch a **Microsoft built-in EDR simulation**: `security.microsoft.com` → **Endpoints → Evaluation & tutorials → Tutorials & simulations** → run a **"Do-it-yourself" / tutorial** scenario against the pilot device. *These simulations are provided by Microsoft specifically for safe evaluation — verify the current catalogue in your tenant.*
2. **Do not** download real malware, run exploit tools, or disable any control to "test." EICAR and the built-in simulations are sufficient and safe.
3. Note the time you generated each signal — you will compare against detection time in the scorecard.

## Step 4 — Validate and demonstrate the detections
1. Run `POCMDE-Validate.ps1` — it confirms (read-only) that the benign signal produced: an **alert** (`security.microsoft.com` → **Incidents & alerts**), a **device timeline** entry, rows in advanced hunting (`DeviceEvents`, `AlertInfo`, `AlertEvidence`), and that an **automated investigation** started (kept approval-gated).
2. In the portal, walk the demonstration: open the incident → view the **alert story** → open the **device page → Timeline** → open **Automated investigations** → run an **Advanced hunting** query on the pilot device. This is the headline-capability demo for stakeholders.
3. Confirm AIR did **not** auto-act (it is Semi — require approval).

## Step 5 — Score against your criteria
1. Run `POCMDE-Scorecard.ps1 -CriteriaPath .\criteria.json -OutFile "MDE PoC Scorecard – Pilot Ring – Validate.json"`. It maps each observation (detection fired, latency, timeline present, hunting visible, AIR started) to your agreed pass/fail criteria and writes the scorecard.
2. Review the scorecard with stakeholders. This is the decision artefact — proof on real-but-safe signal, scored against the bar you set in requirements.

## Step 6 — Tear down (clean rollback)
1. Run `POCMDE-Teardown.ps1 -WhatIf` first to preview every removal, then run it for real to confirm.
2. Teardown: **offboard** the pilot devices (`security.microsoft.com` → **Settings → Endpoints → Offboarding**, or the Intune offboarding policy), **remove** the Intune policy `MDE PoC EDR Onboarding – Pilot Ring – Pilot`, **delete** the EICAR test file from the pilot devices, and **resolve** the test alerts (annotate them `MDE-PoC-TESTSIGNAL`).
3. Optionally delete the pilot group `MDE PoC – Pilot Ring – Pilot`. Keep the scorecard file as your record.

## Step 7 — Decide: expand or stop
1. If the PoC passed and you choose to proceed, move to a **production onboarding** — that is a separate, adjacent solution (see *Where to go next* in Best Practices); do **not** scale from the PoC ring.
2. If not proceeding, confirm teardown is complete with `POCMDE-Validate.ps1` (it should now report no onboarded pilot devices).

---
### Order of operations
`Assess (-WhatIf) → enable MDE on pilot ring → generate benign EICAR/simulation signal → validate + demonstrate → score vs criteria → teardown (-WhatIf then real) → decide expand or stop`
