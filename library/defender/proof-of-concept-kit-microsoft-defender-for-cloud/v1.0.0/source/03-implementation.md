# 3. Implementation Guide — Proof-of-Concept Kit: Microsoft Defender for Cloud

Follow these steps **in order**. Work is in the **Azure portal** (`https://portal.azure.com` → **Microsoft Defender for Cloud**) with **Az PowerShell** helpers; alerts also surface in the unified Defender portal (`security.microsoft.com`). Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

> **Model (run as a PoC):** Assess readiness, enable Defender for Cloud on **one pilot subscription**, generate **benign** posture + threat signal, validate the detections and score them, then **tear down** (including disabling the plan to stop billing). All test signal is sample alerts, a benign misconfiguration, and EICAR — **never a real attack or malware**. No other subscription is touched.

## Naming (set once, reuse verbatim)
- Pilot resource group: `MDC PoC – Pilot RG – Pilot`
- Benign misconfigured test resource: `MDC PoC Test Resource – Pilot RG – Pilot` (e.g. a storage account with public access)
- Scorecard output file: `MDC PoC Scorecard – Pilot Sub – Validate`
- Test-signal tag (Azure tag / notes): `MDC-PoC-TESTSIGNAL`

## Step 1 — Assess readiness (read-only)
1. Sign in with `Connect-AzAccount` and select the pilot subscription.
2. Run `POCMDC-Enable.ps1 -WhatIf` — previews (changes nothing): your Azure roles, the pilot subscription, current Defender-for-Cloud plan state, candidate resources, and any workspace.
3. Create the pilot resource group `MDC PoC – Pilot RG – Pilot` (or confirm one to use). **Confirm the cost owner accepts the short Defender-plan billing window.**

## Step 2 — Enable Defender for Cloud on the pilot subscription
1. `portal.azure.com` → **Microsoft Defender for Cloud → Environment settings → (pilot subscription) → Defender plans**.
2. Turn on **CSPM** (foundational is free; **Defender CSPM** is a paid tier — *verify current pricing/availability*) and **one workload plan** (e.g. **Defender for Servers** or **Defender for Storage**) for the pilot subscription only.
3. Alternatively run `POCMDC-Enable.ps1` (without `-WhatIf`) — it is `-WhatIf`-gated and enables CSPM + the chosen plan on the pilot subscription via `Az.Security`, showing the plan before it applies.
4. Confirm the plans show **On** for the pilot subscription.

## Step 3 — Generate benign test signal
1. Run `POCMDC-TestSignal.ps1` (or follow its printed steps). It performs only **benign, documented** actions tagged `MDC-PoC-TESTSIGNAL`:
   - **Sample security alerts:** trigger Defender for Cloud's built-in **sample alerts** — `portal.azure.com` → **Microsoft Defender for Cloud → Security alerts → Sample alerts** → select the pilot subscription and create. *These are Microsoft-provided benign sample alerts for evaluation.*
   - **Benign misconfiguration (CSPM):** deploy `MDC PoC Test Resource – Pilot RG – Pilot` — a deliberately-misconfigured **test** resource (e.g. a storage account with public blob access) so Defender for Cloud raises a **recommendation** and Secure Score reflects it. It holds **no real data**.
   - **Workload threat (optional):** on a pilot VM covered by Defender for Servers, drop the **EICAR** test file to raise a benign Defender-for-Servers alert.
2. **Do not** attack real resources, deploy real malware, or expose real data. A benign test resource and sample alerts are sufficient.
3. Note the time of each signal for the scorecard latency comparison.

## Step 4 — Validate and demonstrate the detections
1. Run `POCMDC-Validate.ps1` — it confirms (read-only): the **recommendation** from the misconfiguration, the **Secure Score**, the **security alerts** (sample + EICAR), and **regulatory-compliance** data.
2. In the portal, walk the demo: **Microsoft Defender for Cloud → Recommendations** (the misconfig), **→ Secure Score**, **→ Security alerts** (sample + EICAR), **→ Regulatory compliance**. This is the headline-capability demo for stakeholders.
3. Confirm nothing outside the pilot subscription was affected.

## Step 5 — Score against your criteria
1. Run `POCMDC-Scorecard.ps1 -CriteriaPath .\criteria.json -OutFile "MDC PoC Scorecard – Pilot Sub – Validate.json"`. It maps each observation (recommendation raised, Secure Score present, alert fired, compliance populated) to your pass/fail criteria and writes the scorecard.
2. Review the scorecard with stakeholders — the decision artefact.

## Step 6 — Tear down (clean rollback + stop billing)
1. Run `POCMDC-Teardown.ps1 -WhatIf` first to preview, then for real.
2. Teardown: **delete** the test resource `MDC PoC Test Resource – Pilot RG – Pilot` (and optionally the pilot RG), **disable** the Defender workload plan (and Defender CSPM) on the pilot subscription **to stop billing**, and **resolve/dismiss** the `MDC-PoC-TESTSIGNAL` sample alerts.
3. Keep the scorecard as your record.

## Step 7 — Decide: expand or stop
1. If the PoC passed and you choose to proceed, move to a **multi-subscription / multi-cloud onboarding + CSPM remediation** engagement — a separate, adjacent solution (see *Where to go next*).
2. If not proceeding, confirm the plan is **Off** and the test resource is gone with `POCMDC-Validate.ps1`.

---
### Order of operations
`Assess (-WhatIf) → enable CSPM + one workload plan (pilot sub) → sample alerts + benign misconfig + optional EICAR → validate + demonstrate (recommendations, Secure Score, alerts, compliance) → score vs criteria → teardown (-WhatIf then real, disable plan) → decide expand or stop`
