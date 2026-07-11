# 3. Implementation Guide — Onboarding Accelerator: Microsoft Defender for Identity

Follow these steps **in order**. Most configuration is in the **unified Defender portal** (`https://security.microsoft.com` → **Settings → Identities**); sensor install runs on the domain controllers themselves. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

> **Model:** Prepare the DSA, install the sensor on **one pilot domain controller** first, tag entities and plant honeytokens, **validate that a detection actually fires**, and only then expand to the remaining DCs and AD FS/AD CS. Keep **response actions** approval-gated throughout. Never remove an existing AD control to "test."

## Naming (set once, reuse verbatim)
- Directory Service Account (gMSA): `MDI Directory Service Account – Tenant – Prod`
- Pilot sensor host: `MDI Sensor Host – Pilot DC – Pilot`
- Honeytoken decoy account(s): `MDI Honeytoken – Decoy Identity – Pilot`
- Sensitive-entity tag scope: `MDI Sensitive Entities – Tier0 – Prod`
- Advanced-hunting saved query: `MDI Detection Validation – Tenant – Validate`

## Step 1 — Assess readiness
1. Sign in to `security.microsoft.com` as a **Security Administrator**.
2. Run `MDIONB-Discovery.ps1` to capture the current state: MDI activation/workspace, licensed plan hints, admin roles, every domain controller and its OS, DSA readiness, and existing sensor status.
3. Choose the pilot DC and record it as `MDI Sensor Host – Pilot DC – Pilot`. Reserve a change window.

## Step 2 — Activate MDI and prepare the Directory Service Account
1. `security.microsoft.com` → **Settings → Identities**. If MDI is not initialized, complete the one-time activation and note the **workspace** name.
2. Create the read-only gMSA `MDI Directory Service Account – Tenant – Prod` in AD, and grant the sensor host computer accounts permission to retrieve its password.
3. **Settings → Identities → Directory Service accounts → Add credentials** — register `MDI Directory Service Account – Tenant – Prod` (gMSA). *Verify current MDI DSA requirements.*
4. Run `MDIONB-Validate.ps1 -Check DSA` to confirm the DSA is registered.

## Step 3 — Install the pilot sensor (pilot DC)
1. `security.microsoft.com` → **Settings → Identities → Sensors → Add sensor** — download the sensor package and copy the **access key**.
2. During the approved change window, copy the package to `MDI Sensor Host – Pilot DC – Pilot`, run the installer, and supply the **access key** when prompted.
3. Confirm outbound HTTPS from the DC to the MDI service URLs (per `global-requirements-defender.md` G5). *Verify current endpoint list.*
4. **Settings → Identities → Sensors** — confirm `MDI Sensor Host – Pilot DC – Pilot` shows **Running / Healthy**.
5. Run `MDIONB-Validate.ps1 -Check Sensor` to confirm the pilot sensor is healthy and identity signal is flowing.

## Step 4 — Tag sensitive entities (Tier-0)
1. `security.microsoft.com` → **Settings → Identities → Entity tags → Sensitive**.
2. Add the Tier-0 accounts, groups, and servers as `MDI Sensitive Entities – Tier0 – Prod` (Domain/Enterprise Admins, DCs, AD FS/AD CS, PKI, backup, break-glass).
3. Preview the change first with `MDIONB-Honeytoken.ps1 -Mode SensitiveTag` (safe preview by default); apply only with `-Apply`.
4. Run `MDIONB-Validate.ps1 -Check Sensitive` to confirm the entities are tagged.

## Step 5 — Plant and tag honeytokens
1. In AD, create the idle decoy account(s) `MDI Honeytoken – Decoy Identity – Pilot` with believable names; confirm **nothing legitimate uses them** (no logon scripts, services, or scheduled tasks).
2. `security.microsoft.com` → **Settings → Identities → Entity tags → Honeytoken** — add the decoy account(s).
3. Preview with `MDIONB-Honeytoken.ps1 -Mode Honeytoken` (safe preview); apply with `-Apply`.
4. Run `MDIONB-Validate.ps1 -Check Honeytoken` to confirm the accounts are tagged as honeytokens.

## Step 6 — Enable and triage identity posture (ISPM)
1. After the pilot sensor is healthy, `security.microsoft.com` → **Secure Score → Recommended actions**, filter to **Identity** — MDI ISPM recommendations appear (unconstrained delegation, spooler on DCs, legacy protocols, risky certificate templates). *Verify current ISPM availability.*
2. Record the starting posture with `MDIONB-Report.ps1 -SaveBaseline` and assign owners to the top recommendations.
3. *Which posture items are "must-fix" and the remediation change-approval are the security/AD team's decisions — this guide surfaces the recommendations and the technical fix path.*

## Step 7 — Keep response actions approval-gated
1. `security.microsoft.com` → **Settings → Identities → Response actions** (where available) — confirm response actions (disable user, force password reset) require approval, not automatic execution, during the pilot. *Verify current response-action availability in your tenant.*
2. Record the current configuration with `MDIONB-Report.ps1`.
3. *The decision to enable any automatic response is the SOC/security team's — this guide leaves it approval-gated.*

## Step 8 — Validate detections on the pilot
1. Run `MDIONB-Hunt.ps1` to execute `MDI Detection Validation – Tenant – Validate` — it confirms the identity tables (`IdentityInfo`, `IdentityLogonEvents`, `IdentityDirectoryEvents`, `IdentityQueryEvents`) are streaming from the pilot sensor.
2. Trigger a **benign, controlled** detection: authenticate against or query the honeytoken `MDI Honeytoken – Decoy Identity – Pilot`, or run a Microsoft-documented safe simulation. Confirm an alert appears in `security.microsoft.com` → **Incidents & alerts**.
3. Complete the **Testing Guide** before expanding.

## Step 9 — Expand to remaining DCs and AD FS/AD CS
1. **Sensors:** install the sensor on each remaining domain controller in change windows until all show **Running / Healthy**; then AD FS / AD CS servers.
2. **Tags/honeytokens:** extend sensitive tagging and add honeytokens across additional forests/domains as needed.
3. **ISPM:** re-run `MDIONB-Report.ps1 -SaveBaseline` after full sensor coverage — posture recommendations get more complete as more DCs report.
4. **Response:** only after coverage and detections are trusted, review response-action automation with the SOC (still their decision).
5. Track sensor-health and posture drift each cycle with `MDIONB-Report.ps1`.

---
### Order of operations
`Assess → activate MDI + DSA → install pilot-DC sensor → tag sensitive entities → plant honeytokens → enable/triage ISPM → keep response approval-gated → validate detections → expand to all DCs + AD FS/AD CS`
