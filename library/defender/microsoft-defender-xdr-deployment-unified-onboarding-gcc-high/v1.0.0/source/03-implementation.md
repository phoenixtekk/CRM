# 3. Implementation Guide — Microsoft Defender XDR Deployment & Unified Onboarding

Follow these steps **in order**. Most work is in the **unified Defender portal** (`https://security.microsoft.us` — GCC High); endpoint onboarding uses the **GCC High Intune admin center** (`https://intune.microsoft.us` — *verify current GCC High portal URL*) as the default channel. Sign-in is `login.microsoftonline.us`; Entra/Azure are in **Azure Government** (`portal.azure.us`). Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

> **National-cloud note (GCC High).** All portal URLs below are the US Gov equivalents; the delivered scripts default to the US Gov cloud (`Connect-MgGraph -Environment USGov` / `Connect-AzAccount -Environment AzureUSGovernment`; DoD: `-Environment USGovDoD`). **Whether a given pillar/feature/connector is available in GCC High/DoD — verify against current Microsoft Government documentation before enabling it.**

> **Model:** Activate each pillar, onboard a **pilot ring** first (a few devices, one or two DCs, a pilot user group), validate that all four pillars stream signal and correlate, and only then expand. Keep **automated response (AIR)** in an **approval/simulate** posture throughout the pilot. Never disable an existing control to "test."

## Naming (set once, reuse verbatim)
- Pilot device group (Entra/Intune): `MDE Onboarding – Pilot Ring – Pilot`
- Pilot user group (Entra): `XDR Pilot Users – Pilot Ring – Pilot`
- Intune EDR onboarding profile: `MDE Onboarding – Pilot Ring – Pilot`
- Unified RBAC role assignment (read-only): `XDR Security Reader – Tenant – Prod`
- Unified RBAC role assignment (operator): `XDR Security Operator – Tenant – Prod`
- Advanced-hunting saved query: `XDR Cross-Pillar Correlation Check – Tenant – Validate`

## Step 1 — Assess readiness
1. Sign in to `security.microsoft.us` as a **Security Administrator**.
2. Run `DEFXDRG-Discovery.ps1` to capture the current state: licensed Defender plans, admin roles, which pillars are already active, device onboarding coverage, candidate domain controllers for MDI, and MDO/MDCA status.
3. In **Entra** (via the Azure Government portal `portal.azure.us` → **Microsoft Entra ID**; the Entra admin center national-cloud URL — *verify current GCC High portal URL*) → **Groups**, create the two pilot groups: `MDE Onboarding – Pilot Ring – Pilot` (pilot devices) and `XDR Pilot Users – Pilot Ring – Pilot` (pilot users). Choose one or two domain controllers as the pilot sensor host(s).

## Step 2 — Onboard Defender for Endpoint (pilot ring)
1. `security.microsoft.us` → **Settings → Endpoints → Onboarding**. If MDE is not yet initialized, complete the one-time activation.
2. Choose the deployment method **Intune** (default). Confirm the **Microsoft Defender for Endpoint connector** is turned on: `intune.microsoft.us` (GCC High Intune admin center — *verify current GCC High portal URL*) → **Endpoint security → Microsoft Defender for Endpoint** → **Connection status: Enabled**.
3. In Intune → **Endpoint security → Endpoint detection and response** → **Create Policy** (platform: Windows). Name it `MDE Onboarding – Pilot Ring – Pilot`. Set **Microsoft Defender for Endpoint client configuration package type = Auto from connector**.
4. **Assignments:** assign only to `MDE Onboarding – Pilot Ring – Pilot`. **Review + create.**
5. On a pilot device, confirm onboarding: `security.microsoft.us` → **Assets → Devices** shows the device as onboarded. (For GPO/script channels, use the onboarding package from **Settings → Endpoints → Onboarding** against the pilot OU instead.)
6. Run `DEFXDRG-Validate.ps1 -Pillar Endpoint` to confirm pilot devices report EDR signal.

## Step 3 — Deploy Defender for Identity sensors (pilot DC)
1. `security.microsoft.us` → **Settings → Identities**. If MDI is not initialized, complete the one-time activation.
2. **Settings → Identities → Directory Service accounts** → add the read-only **DSA** (gMSA recommended) prepared in requirements.
3. **Settings → Identities → Sensors** → **Add sensor** → download the sensor package and copy the **access key**.
4. During the approved change window, install the sensor on the **pilot domain controller**, supplying the access key. Repeat for AD FS / AD CS servers only after the DC sensor is healthy.
5. **Settings → Identities → Sensors** — confirm the pilot sensor shows **Running / Healthy**.
6. Run `DEFXDRG-Validate.ps1 -Pillar Identity` to confirm the sensor is healthy and identity signal is flowing.

## Step 4 — Activate Defender for Office 365 (monitor-first)
1. `security.microsoft.us` → **Email & collaboration → Policies & rules → Threat policies**.
2. Enable **Safe Attachments** and **Safe Links** using **Preset security policies** (Standard or Strict) — scope the preset to the pilot users `XDR Pilot Users – Pilot Ring – Pilot` first, so mail flow for the wider org is unchanged.
3. Confirm **anti-phishing** is on for the pilot scope. Leave org-wide expansion for Step 8.
4. Run `DEFXDRG-Validate.ps1 -Pillar Office365` to confirm MDO policies are active and `EmailEvents` signal appears in advanced hunting.

## Step 5 — Activate Defender for Cloud Apps (discovery-first)
1. `security.microsoft.us` → **Cloud apps → Cloud discovery → Settings** → enable the **Microsoft Defender for Endpoint integration** so onboarded pilot devices feed cloud-app discovery automatically.
2. **Cloud apps → App connectors** → add connectors for priority SaaS apps in **monitor** mode (no session/blocking policy yet).
3. Confirm discovery data appears under **Cloud apps → Cloud discovery → Dashboard**.
4. Run `DEFXDRG-Validate.ps1 -Pillar CloudApps` to confirm MDCA is active and `CloudAppEvents` signal appears.

## Step 6 — Configure unified RBAC
1. `security.microsoft.us` → **System → Permissions and roles → Roles** (Microsoft Defender XDR unified RBAC). If unified RBAC is not yet activated, complete the one-time activation. *Verify current unified RBAC activation steps in your tenant.*
2. Create/assign a read-only role assignment `XDR Security Reader – Tenant – Prod` granting **Security data → Read** across all data sources, assigned to your read-only analysts.
3. Create/assign an operator role assignment `XDR Security Operator – Tenant – Prod` granting read plus **response** permissions (device isolation, mail remediation) — but keep AIR approval-gated (Step 7).
4. Run `DEFXDRG-Validate.ps1 -Pillar RBAC` to confirm the unified role assignments exist and per-pillar permissions are consolidated.

## Step 7 — Keep automated response approval-gated
1. `security.microsoft.us` → **Settings → Endpoints → Advanced features** — confirm **Automated Investigation** is on but the device group's **automation level** is set to **Semi — require approval** (not full automation) during the pilot.
2. Confirm no response playbook auto-isolates or auto-disables without approval. Record the current AIR level with `DEFXDRG-Report.ps1`.
3. *Automation guardrails and the decision to move toward full automation are the SOC/security team's — this guide leaves AIR approval-gated.*

## Step 8 — Validate correlation and Secure Score on the pilot
1. Run `DEFXDRG-Hunt.ps1` to execute the advanced-hunting query `XDR Cross-Pillar Correlation Check – Tenant – Validate` — it confirms every pillar's tables (`DeviceInfo`, `IdentityInfo`, `EmailEvents`, `CloudAppEvents`) are streaming.
2. `security.microsoft.us` → **Incidents** — confirm alerts from multiple pillars group into single incidents (use the correlation test in the Testing Guide).
3. `security.microsoft.us` → **Secure Score** — record the starting score with `DEFXDRG-Report.ps1 -SaveBaseline` and triage the top recommendations.
4. Complete the **Testing Guide** before expanding.

## Step 9 — Expand tenant-wide
1. **Endpoint:** broaden the Intune assignment of `MDE Onboarding – Pilot Ring – Pilot` (or create the next ring) to cover remaining devices in waves.
2. **Identity:** install sensors on the remaining domain controllers (and AD FS / AD CS) in change windows until all are healthy.
3. **Office 365 / Cloud Apps:** expand the MDO preset policy scope and MDCA connectors/policies from pilot users to the full tenant.
4. **Response:** only after correlation and coverage are trusted, review AIR automation levels with the SOC (still their decision).
5. Re-baseline with `DEFXDRG-Report.ps1 -SaveBaseline` and track coverage/Secure-Score drift each cycle.

---
### Order of operations
`Assess → onboard Endpoint (pilot) → deploy Identity sensor (pilot DC) → activate Office 365 (pilot users) → activate Cloud Apps (discovery) → configure unified RBAC → keep AIR approval-gated → validate correlation + Secure Score → expand`
