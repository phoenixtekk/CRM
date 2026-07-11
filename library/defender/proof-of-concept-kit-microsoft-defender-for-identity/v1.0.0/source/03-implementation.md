# 3. Implementation Guide — Proof-of-Concept Kit: Microsoft Defender for Identity

Follow these steps **in order**. Configuration is in the **unified Defender portal** (`https://security.microsoft.com` → **Settings → Identities**); the sensor installs on the pilot **domain controller** in a change window. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

> **Model (run as a PoC):** Assess readiness, install **one** sensor on a pilot DC, generate **benign** test signal, validate the detections and score them, then **tear down**. All test signal is harmless read-only enumeration and a honeytoken decoy — **never a real attack, exploit, or credential theft**. The rest of AD is untouched.

## Naming (set once, reuse verbatim)
- Pilot sensor / DC: `MDI PoC Sensor – Pilot DC – Pilot`
- Directory Service Account: `MDI PoC – DSA – Pilot`
- Honeytoken decoy account: `MDI PoC Honeytoken – Pilot`
- Scorecard output file: `MDI PoC Scorecard – Pilot DC – Validate`
- Test-signal tag (used in notes/hunting): `MDI-PoC-TESTSIGNAL`

## Step 1 — Assess readiness (read-only)
1. Sign in to `security.microsoft.com` as a **Security Administrator**.
2. Run `POCMDI-Enable.ps1 -WhatIf` — previews (changes nothing): the MDI plan, admin roles, whether MDI is activated, candidate DCs, the DSA, and the honeytoken account.
3. Choose the pilot DC and confirm the change window, DSA (`MDI PoC – DSA – Pilot`), and a dormant honeytoken account (`MDI PoC Honeytoken – Pilot`).

## Step 2 — Enable MDI and install the pilot sensor
1. `security.microsoft.com` → **Settings → Identities**. If MDI is not initialized, complete the one-time activation (Global Administrator, first time only).
2. **Settings → Identities → Directory Service accounts** → add `MDI PoC – DSA – Pilot` (gMSA recommended).
3. **Settings → Identities → Sensors → Add sensor** → download the sensor package and copy the **access key**.
4. In the approved change window, install the sensor on the pilot DC, supplying the access key. Name/label it `MDI PoC Sensor – Pilot DC – Pilot`.
5. **Settings → Identities → Sensors** — confirm the sensor shows **Running / Healthy**.
6. **Settings → Identities → Entity tags → Honeytoken** → tag `MDI PoC Honeytoken – Pilot`. (Or run `POCMDI-Enable.ps1` without `-WhatIf` — it is `-WhatIf`-gated and can tag the honeytoken via Graph.)

## Step 3 — Generate benign test signal
1. From the **test workstation**, signed in as the **test account**, run `POCMDI-TestSignal.ps1` (or its printed manual commands). It performs only **benign, read-only** actions tagged `MDI-PoC-TESTSIGNAL`:
   - **Reconnaissance signal:** harmless directory enumeration — `net group "Domain Admins" /domain`, `net user /domain`, `nltest /domain_trusts`, and a read-only LDAP query for users/groups. These are the same commands admins run daily; MDI flags the *pattern* as reconnaissance.
   - **Honeytoken signal:** a benign authentication or directory query touching `MDI PoC Honeytoken – Pilot` — because the decoy should never be used, any touch is a clean detection.
2. **Do not** run attack tools, credential-dumping utilities, exploitation frameworks, or anything that changes AD. Read-only enumeration and touching a decoy account are sufficient and safe.
3. Note the time of each signal for the scorecard latency comparison.

## Step 4 — Validate and demonstrate the detections
1. Run `POCMDI-Validate.ps1` — it confirms (read-only): the **reconnaissance** and **honeytoken** alerts reached the portal (`AlertInfo`), the activity appears in `IdentityQueryEvents` / `IdentityLogonEvents` / `IdentityDirectoryEvents`, and the identity timeline populated.
2. In the portal, walk the demo: open the incident → the **alert story** → the **identity page → Timeline** → the **UEBA / investigation-priority** view. This is the headline-capability demo for stakeholders.
3. Confirm any response remains **approval-gated** (nothing auto-acted).

## Step 5 — Score against your criteria
1. Run `POCMDI-Scorecard.ps1 -CriteriaPath .\criteria.json -OutFile "MDI PoC Scorecard – Pilot DC – Validate.json"`. It maps each observation (recon alert fired, honeytoken flagged, timeline present, hunting visible, UEBA scored) to your pass/fail criteria and writes the scorecard.
2. Review the scorecard with stakeholders — the decision artefact.

## Step 6 — Tear down (clean rollback)
1. Run `POCMDI-Teardown.ps1 -WhatIf` first to preview, then for real.
2. Teardown: **untag** the honeytoken `MDI PoC Honeytoken – Pilot`, **uninstall** the sensor from the pilot DC (`security.microsoft.com` → **Settings → Identities → Sensors** → delete, then remove the sensor service on the DC), **remove** the DSA `MDI PoC – DSA – Pilot` if it was created only for the PoC, and **resolve** the `MDI-PoC-TESTSIGNAL` test alerts.
3. Keep the scorecard as your record.

## Step 7 — Decide: expand or stop
1. If the PoC passed and you choose to proceed, move to a **fleet-wide MDI sensor deployment / AD hardening** engagement — a separate, adjacent solution (see *Where to go next*).
2. If not proceeding, confirm the sensor is uninstalled and healthy-count is zero with `POCMDI-Validate.ps1`.

---
### Order of operations
`Assess (-WhatIf) → activate MDI + DSA + install one pilot sensor + tag honeytoken → generate benign recon/honeytoken signal → validate + demonstrate (timeline, UEBA) → score vs criteria → teardown (-WhatIf then real) → decide expand or stop`
