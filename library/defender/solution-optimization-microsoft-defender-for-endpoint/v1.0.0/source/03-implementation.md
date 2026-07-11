# 3. Implementation Guide — Solution Optimization: Microsoft Defender for Endpoint

Follow these steps **in order**. Policy is authored in the **authoritative surface** identified in Requirements 2.5 — steps below show the **Microsoft Defender portal** (`https://security.microsoft.com`) and the **Intune admin center** (`https://intune.microsoft.com`) paths; use whichever owns your target devices. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

> **Model:** Baseline the current deployment, tune on the **pilot ring** `MDE Optimize – Pilot Ring – Pilot` first, **measure the before/after delta**, then expand ring by ring. Every disruptive change starts in **audit / `-WhatIf`**, and every step names a rollback. **Which detections are true incidents, and whether a suppression or ASR block is acceptable for a business-critical app, are the SOC/security team's decisions.**

## Naming (set once, reuse verbatim)
- Pilot device group / Entra group: `MDE Optimize – Pilot Ring – Pilot`
- ASR block policy (pilot): `ASR Hardening – Pilot Ring – Pilot`
- ASR block policy (production, on expand): `ASR Hardening – All Devices – Prod`
- Tamper/EDR/AV hardening policy: `Endpoint Hardening – Pilot Ring – Pilot`
- Web content filtering policy: `Web Filtering – All Devices – Prod`
- Noisy-detection suppression (per detection): `FP Suppression – <detection> – Prod`
- Allow indicator (per justified allow): `Allow Indicator – <object> – Prod`

## Step 1 — Baseline the current deployment (measure "before")
1. `security.microsoft.com` → **Reports → Attack surface reduction rules** and **Assets → Devices**. Note the current ASR rule states, onboarded/active device counts, and open-alert volume.
2. Run `SOPMDE-Discovery.ps1` to capture, read-only: onboarded devices and sensor health, device groups/tags, ASR rule states, tamper-protection and EDR-block-mode state, web-content-filtering state, and Intune endpoint-security policies.
3. Run `SOPMDE-Report.ps1 -SaveBaseline` to record the **before** metrics — alert volume, false-positive proportion, ASR block coverage, and onboarding/sensor-health coverage — to `sopmde-baseline.json`.
4. Run `SOPMDE-Hunt.ps1 -Mode ASRAudit` to list which ASR rules have audit hits and on which devices (your evidence for safe block decisions).

## Step 2 — Move ASR rules audit → block on the pilot ring
1. Review the ASR audit evidence from Step 1: any rule with **only benign** audited events across the pilot ring is a safe **Block** candidate; any rule blocking a real line-of-business app needs an **allow/exclusion** or stays in audit. *Whether a given app is business-critical is the app owner's call.*
2. Create the ASR block policy: **Intune → Endpoint security → Attack surface reduction → Create policy** (Windows → ASR rules), name it **`ASR Hardening – Pilot Ring – Pilot`**. Set the vetted rules to **Block**; keep unproven rules at **Audit**.
   - *(Defender-portal-managed devices: `security.microsoft.com` → **Configuration management → Endpoint security policies → Create new policy** → **Attack surface reduction**.)*
3. **Preview the flip first:** run `SOPMDE-Set-ASRBlock.ps1 -PolicyName 'ASR Hardening – Pilot Ring – Pilot' -Rules <ids>` (defaults to `-WhatIf`) to see exactly which rules would change to Block; re-run with `-Apply` (or complete it in the portal).
4. **Assign** the policy to `MDE Optimize – Pilot Ring – Pilot` only. **Save.**
5. Add any required exception as a scoped ASR **file/folder exclusion** on the same policy, documented with a justification — never disable the whole rule to fix one app.

## Step 3 — Reduce alert noise and false positives (pilot)
1. `security.microsoft.com` → **Incidents & alerts → Alerts**. Identify the **repeating, benign** detections (sort by title/count) — the ones analysts already dismiss.
2. For a confirmed benign, recurring detection, create a **suppression rule** (Alert → **Create a suppression rule**), scoped as tightly as possible (specific process/path/device group), named **`FP Suppression – <detection> – Prod`**, with a **justification and review date**.
3. For a known-good file/cert/IP/URL, add an **allow indicator**: **Settings → Endpoints → Indicators → Add**, named **`Allow Indicator – <object> – Prod`** — prefer a precise indicator over a broad AV exclusion.
4. Only where truly required, add a narrow antivirus **exclusion** in the AV policy — the last resort, because exclusions are blind spots.
5. Re-run `SOPMDE-Hunt.ps1 -Mode Noise` to confirm the tuned detections drop in volume. **Do not over-suppress** — every suppression is justified and time-bound.

## Step 4 — Expand coverage and standardize tags/groups
1. Run `SOPMDE-Hunt.ps1 -Mode Coverage` (and `SOPMDE-Discovery.ps1`) to find devices that are **not onboarded** or whose **sensor health** is Inactive/Misconfigured.
2. Onboard the stragglers through the authoritative channel (Intune EDR onboarding policy / CM / script). *Truly unmanaged devices must be brought under management first.*
3. Apply a consistent **device tag** scheme (e.g. by role/site) — **Assets → Devices → (device) → Manage tags**, or a dynamic rule — and confirm **device groups** target correctly for policy and RBAC.
4. Run `SOPMDE-Validate.ps1` → confirms sensor health improved and tags/groups resolve.

## Step 5 — Harden tamper protection, EDR block mode, and web filtering (pilot)
1. Create **`Endpoint Hardening – Pilot Ring – Pilot`**: **Intune → Endpoint security → Antivirus / Endpoint detection and response** — enable **Tamper Protection**, confirm **EDR in block mode** is on, and set the AV settings (cloud-delivered protection, PUA, real-time) to best practice.
   - *(Defender-managed: **Settings → Endpoints → Advanced features** for Tamper Protection / EDR in block mode.)*
2. Preview the tamper/EDR state with `SOPMDE-Set-ASRBlock.ps1 -Mode Hardening -WhatIf` (reports current vs intended tamper/EDR state; still changes nothing by default).
3. Create **`Web Filtering – All Devices – Prod`**: `security.microsoft.com` → **Settings → Endpoints → Web content filtering → Add policy** — block the risk categories the security team specifies. *Web content filtering availability/plan — verify current.* **Choice of blocked categories is the security team's.**
4. **Assign** the hardening policy to `MDE Optimize – Pilot Ring – Pilot` only; **Save.**

## Step 6 — Validate the pilot (measure "after")
1. Run `SOPMDE-Validate.ps1` → confirms ASR block rules applied to the pilot, tamper protection on, EDR block mode on, web filtering active, and sensor health healthy.
2. Run `SOPMDE-Report.ps1 -BaselinePath .\sopmde-baseline.json` → shows the **before/after delta**: lower alert/false-positive volume, higher ASR block coverage, higher onboarding/sensor-health coverage.
3. Confirm no legitimate application broke on the pilot ring (check ASR block events for false positives). Complete the **Testing Guide** before expanding.

## Step 7 — Expand ring by ring across the estate
1. Clone the validated pilot policies to production scope: **`ASR Hardening – All Devices – Prod`** and the hardening/web-filtering policies, assigned to the next ring, then the estate (prefer assignment at a broad device group so new devices inherit it).
2. Roll the suppression/indicator discipline and the tag/group scheme out estate-wide.
3. Re-baseline with `SOPMDE-Report.ps1 -SaveBaseline` after each wave and track the drift each cycle — noise should stay down and coverage complete as new devices appear.

---
### Order of operations
`Baseline (before) → ASR audit→block (pilot) → tune noise/FPs → expand coverage + tags → harden tamper/EDR/web-filter (pilot) → validate the before/after delta → expand ring by ring`
