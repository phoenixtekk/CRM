# 3. Implementation Guide — Onboarding Accelerator: Microsoft Defender for Endpoint

Follow these steps **in order**. Configuration spans the **unified Defender portal** (`https://security.microsoft.com`) and the **Intune admin center** (`https://intune.microsoft.com`) as the default onboarding/policy channel. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

> **Model:** Onboard a **pilot ring** first, bring the disruptive controls (**ASR**, **EDR block mode**) up **audit → block**, validate coverage and detections, then enforce and expand across the fleet. Keep **automated response (AIR)** approval-gated throughout. Never remove an existing control to "test."

## Naming (set once, reuse verbatim)
- Pilot device group: `MDE Device Group – Pilot Ring – Pilot`
- Onboarding profile (Intune, Windows): `MDE Onboarding – Pilot Ring – Pilot`
- ASR policy (audit): `MDE ASR Rules – Pilot Ring – Audit`
- ASR policy (block): `MDE ASR Rules – Pilot Ring – Block`
- AV/next-gen policy: `MDE Next-Gen AV – Pilot Ring – Prod`
- Web content filtering policy: `MDE Web Content Filtering – Tenant – Prod`
- RBAC roles: `MDE Security Reader – Tenant – Prod`, `MDE Security Operator – Tenant – Prod`
- Advanced-hunting saved query: `MDE Onboarding Coverage – Tenant – Validate`

## Step 1 — Assess readiness
1. Sign in to `security.microsoft.com` as a **Security Administrator**.
2. Run `MDEONB-Discovery.ps1` to capture the current state: MDE activation, licensed plan (P1/P2) hints, admin roles, platform mix, onboarding coverage, and the Intune MDE connector status.
3. In **Intune/Entra** → **Groups**, create `MDE Device Group – Pilot Ring – Pilot` with a representative Windows/macOS/Linux mix.

## Step 2 — Onboard the pilot ring
1. `security.microsoft.com` → **Settings → Endpoints → Onboarding**. If MDE is not initialized, complete the one-time activation.
2. **Windows via Intune (default):** confirm `intune.microsoft.com` → **Endpoint security → Microsoft Defender for Endpoint → Connection status: Enabled**. Create the EDR onboarding profile `MDE Onboarding – Pilot Ring – Pilot` and assign it only to `MDE Device Group – Pilot Ring – Pilot`. (GPO/local-script channels use the package from **Settings → Endpoints → Onboarding** against the pilot OU.)
3. **macOS:** deploy the MDM onboarding profile + package to the pilot Macs (*cross-reference the macOS onboarding solution*). **Linux:** onboard via the documented repo + package method on the pilot Linux hosts. *Verify current macOS/Linux onboarding steps and support.*
4. On pilot devices, confirm onboarding in **Assets → Devices**.
5. Run `MDEONB-Validate.ps1 -Check Onboarding` to confirm each pilot device reports EDR signal.

## Step 3 — Next-gen AV and EDR in block mode
1. In Intune → **Endpoint security → Antivirus**, create `MDE Next-Gen AV – Pilot Ring – Prod` (real-time protection, cloud-delivered protection, PUA) assigned to the pilot ring.
2. `security.microsoft.com` → **Settings → Endpoints → Advanced features** — enable **EDR in block mode** (lets EDR block artifacts behind a third-party AV).
3. Run `MDEONB-Validate.ps1 -Check EDR` to confirm block mode and AV posture.

## Step 4 — Attack surface reduction (audit first)
1. In Intune → **Endpoint security → Attack surface reduction**, create `MDE ASR Rules – Pilot Ring – Audit` with the chosen ASR rules set to **Audit**, assigned to the pilot ring.
2. Let it run, then review what the rules *would* block with `MDEONB-Report.ps1 -Section ASR` and the advanced-hunting `DeviceEvents` for `Asr*Audited`. Add exclusions for legitimate line-of-business behavior.
3. Only after review, create `MDE ASR Rules – Pilot Ring – Block` with the validated rules set to **Block**, assigned to the pilot ring.
4. Run `MDEONB-Validate.ps1 -Check ASR` to confirm rule states. Promotion from audit to block can be previewed with `MDEONB-PromoteASR.ps1` (safe preview by default).

## Step 5 — Tamper protection and web content filtering
1. `security.microsoft.com` → **Settings → Endpoints → Advanced features → Tamper Protection** — enforce it (protects the stack from being disabled).
2. **Settings → Endpoints → Web content filtering** — create `MDE Web Content Filtering – Tenant – Prod` for the categories to control (P2). *Web content filtering requires P2 — verify current availability.*
3. Run `MDEONB-Validate.ps1 -Check Config` to confirm tamper protection and web filtering.

## Step 6 — Device groups and RBAC
1. `security.microsoft.com` → **Settings → Endpoints → Permissions → Device groups** — define `MDE Device Group – Pilot Ring – Pilot` with the pilot ring and set its **automation level** to **Semi — require approval** during the pilot.
2. **Settings → Endpoints → Permissions → Roles** — create `MDE Security Reader – Tenant – Prod` (read-only) and `MDE Security Operator – Tenant – Prod` (read + response); assign least privilege.
3. Run `MDEONB-Validate.ps1 -Check RBAC` to confirm device groups and roles.

## Step 7 — Live response and automated response (approval-gated)
1. `security.microsoft.com` → **Settings → Endpoints → Advanced features → Live Response** — enable it, and require **live response for servers** / approval per your policy. Live response is powerful — restrict who can run it via the RBAC roles above.
2. Confirm the pilot device group's AIR **automation level** remains **Semi — require approval** (Step 6). Record it with `MDEONB-Report.ps1`.
3. *The decision to raise automation or broaden live response is the SOC/security team's — this guide leaves it approval-gated.*

## Step 8 — Validate coverage and detections on the ring
1. Run `MDEONB-Hunt.ps1` to execute `MDE Onboarding Coverage – Tenant – Validate` — it confirms `DeviceInfo` shows the pilot devices onboarded and healthy, and that `DeviceEvents`/`DeviceTvmSoftwareVulnerabilities` are populating.
2. Run the Microsoft-provided **EDR detection test** (safe, documented) on a pilot device and confirm the alert appears in **Incidents & alerts**. Confirm an ASR-block event on a device once block mode is on.
3. `security.microsoft.com` → **Vulnerability management → Dashboard** — record the exposure baseline with `MDEONB-Report.ps1 -SaveBaseline`.
4. Complete the **Testing Guide** before expanding.

## Step 9 — Expand across the fleet
1. **Onboarding:** broaden the Intune assignment (or create the next ring) to cover remaining Windows devices in waves; extend the macOS/Linux onboarding to the rest of those fleets.
2. **ASR/block mode:** promote `MDE ASR Rules – Pilot Ring – Block` (and block mode) to production rings after each ring validates clean.
3. **Web filtering / tamper protection:** confirm tenant-wide.
4. **RBAC / automation:** review AIR automation levels with the SOC only after coverage and detections are trusted (still their decision).
5. Re-baseline exposure with `MDEONB-Report.ps1 -SaveBaseline` and track coverage/exposure drift each cycle.

---
### Order of operations
`Assess → onboard pilot ring (Win/macOS/Linux) → next-gen AV + EDR block mode → ASR audit → ASR block → tamper protection + web filtering → device groups + RBAC → live response + AIR approval-gated → validate coverage + detections → expand across the fleet`
