# 3. Implementation Guide — Microsoft Defender for Endpoint for macOS (Deployment & Onboarding via Intune)

Follow these steps **in order**, in the **Microsoft Intune admin center**
(`https://intune.microsoft.com`) and the **Microsoft Defender portal**
(`https://security.microsoft.com`). This delivers the five required Apple approval profiles **first**,
then the Microsoft Defender app and the onboarding package, then validates that the agent is genuinely
healthy — proven on a pilot, then expanded fleet-wide.

> **Model:** Assess → Configure → Pilot → Validate → Expand. A small `MDE macOS – Pilot Devices` group
> validates onboarding before the `MDE macOS – Production Devices` fleet receives it.
> **Do not deploy the onboarding profile or the app before the five capability profiles are applying —
> onboarding a Mac without them produces a silently degraded agent (Step 10 gate).**

> **Source note:** The Microsoft Defender **team identifier**, **extension bundle identifiers**,
> **network extension identifier**, **PPPC code requirement**, and the **onboarding package** are
> Microsoft-published, tenant-specific values. Obtain them from the current Microsoft *Deploy
> Microsoft Defender for Endpoint on macOS with Intune* documentation and your onboarding download —
> this guide gives the exact procedure and object names; it does not invent identifier values.

## Step 1 — Stage the deployment (Assess)
1. In the **Microsoft Defender portal** (`https://security.microsoft.com`) → **Settings → Endpoints → Onboarding**, select operating system **macOS** and deployment method **Mobile Device Management / Microsoft Intune**, and **download the onboarding package** (Requirement 2.5). Extract the onboarding configuration profile.
2. Obtain the current Microsoft Defender **extension identifiers** and **PPPC code requirement** (Requirement 2.6), or confirm the Intune Settings catalog exposes the Microsoft Defender presets.
3. Confirm you will tag every object with `MDE-macOS` in its description for auditability.

## Step 2 — Confirm Apple management prerequisites
1. Intune → **Devices → Enrollment → Apple → Apple MDM Push certificate**; confirm present and not expired (Requirement 2.2).
2. Confirm your target Macs are enrolled: Intune → **Devices → macOS → macOS devices** (Requirement 2.3). Supervised (ADE) Macs approve extensions and network filters most smoothly.
3. Run `MACMDE-Discovery.ps1` for a readiness snapshot (APNs, enrolled Macs, macOS versions, any existing Defender/security profiles that could conflict).

## Step 3 — Create the device groups
1. Entra → **Groups → New group → Security →** name `MDE macOS – Pilot Devices` → add a few representative Macs. **Create**.
2. Create `MDE macOS – Production Devices` for the rest of the fleet. **Create**.

## Step 4 — Build the System Extensions profile (capability profile 1 of 5)
1. Intune → **Devices → macOS → Configuration → Create → New Policy → Platform: macOS**.
2. **Profile type:** **Settings catalog** (search for **System Extensions**), or **Templates → Extensions** if your tenant surfaces the template. **Create**.
3. **Name:** `MDE macOS – System Extensions`. **Description:** include the tag `MDE-macOS`. **Next**.
4. Add an **allowed system extensions** entry: set the **team identifier** to the Microsoft Defender team identifier and add the **allowed system extension types / bundle identifiers** for the Microsoft Defender endpoint-security and network extensions (Requirement 2.6). This pre-approves the extensions so they load without a user prompt.
5. **Next → Assignments → Add groups →** `MDE macOS – Pilot Devices`. **Next → Create**.

## Step 5 — Build the Full Disk Access (PPPC / TCC) profile (capability profile 2 of 5)
1. Intune → **Devices → macOS → Configuration → Create → New Policy → Platform: macOS → Templates → Privacy Preferences Policy Control** (or **Settings catalog → Privacy**). **Create**.
2. **Name:** `MDE macOS – Full Disk Access`. **Description:** tag `MDE-macOS`. **Next**.
3. Add a PPPC entry that grants **SystemPolicyAllFiles (Full Disk Access) = Allow** to the Microsoft Defender app/extension, identified by its bundle identifier and **code requirement** string (Requirement 2.6). This grants MDE the whole-disk read access it needs at the MDM level, so no user prompt is required.
4. **Next → Assignments → Add groups →** `MDE macOS – Pilot Devices`. **Next → Create**.

## Step 6 — Build the Network filter profile (capability profile 3 of 5)
1. Intune → **Devices → macOS → Configuration → Create → New Policy → Platform: macOS → Templates → Web content filter** (or **Settings catalog → Content filter**). **Create**.
2. **Name:** `MDE macOS – Network Filter`. **Description:** tag `MDE-macOS`. **Next**.
3. Configure a **plug-in content filter** that names the Microsoft Defender **network extension** identifier and filter data-provider bundle identifier (Requirement 2.6). This pre-approves the network extension so MDE network protection/web filtering can attach.
4. **Next → Assignments → Add groups →** `MDE macOS – Pilot Devices`. **Next → Create**.

## Step 7 — Build the Background services and Notifications profiles (capability profiles 4 and 5 of 5)
1. **Background services:** Intune → **Devices → macOS → Configuration → Create → New Policy → Platform: macOS → Settings catalog → search Managed Login Items / Background Task Management**. **Name:** `MDE macOS – Background Services`. Add a **managed login item / allowed background service** rule for the Microsoft Defender team identifier so the user cannot disable MDE's background daemons. **Assign** to `MDE macOS – Pilot Devices`. **Create**.
2. **Notifications:** Intune → **Devices → macOS → Configuration → Create → New Policy → Platform: macOS → Templates → Notifications** (or **Settings catalog → Notifications**). **Name:** `MDE macOS – Notifications`. Add a notification-settings entry allowing the Microsoft Defender bundle identifier to post notifications (alerts enabled, banners/lock-screen as desired). **Assign** to `MDE macOS – Pilot Devices`. **Create**.

> **Gate before onboarding:** confirm all five profiles above show **Succeeded** on a pilot Mac
> (Intune → each profile → **Device status**) before proceeding. If any is not applying, fix it now —
> do **not** onboard first.

## Step 8 — Deploy the Microsoft Defender app
1. Intune → **Apps → macOS → Add**. Choose **Microsoft Defender** (the built-in app type) where available, or **macOS app (PKG/DMG)** with a packaged Defender installer.
2. **Name:** `MDE macOS – Defender App`. **Description:** tag `MDE-macOS`.
3. **Assignments → Required → Add group →** `MDE macOS – Pilot Devices`. **Next → Create**. The app installs on the pilot Macs (with the extensions already approved from Steps 4–7, it activates cleanly).

## Step 9 — Deploy the onboarding profile (after the app)
1. Intune → **Devices → macOS → Configuration → Create → New Policy → Platform: macOS → Templates → Custom**. **Create**.
2. **Name:** `MDE macOS – Onboarding`. **Description:** tag `MDE-macOS`.
3. Provide a **deployment channel = Device channel** and **upload the onboarding configuration profile** extracted from the Defender portal download (Requirement 2.5 / Step 1). This carries the `WindowsDefenderATPOnboarding` payload that points the agent at your tenant.
4. **Assignments → Add groups →** `MDE macOS – Pilot Devices`. **Next → Create**.

## Step 10 — Validate MDE health on the pilot, with pilot gate and rollback note
1. On a pilot Mac, force a sync: **Company Portal → ... → Check status** (or **System Settings → General → Device Management**), and allow the profiles, app, and onboarding to apply.
2. In Intune, confirm each of the five profiles + `MDE macOS – Onboarding` show **Succeeded** and `MDE macOS – Defender App` shows **Installed** (each object → **Device status**). Run `MACMDE-Validation.ps1 -DeviceName "MAC-001"` for the management-plane view and `MACMDE-Report.ps1` for pilot-wide state.
3. **On the Mac (Terminal), prove the agent is healthy** (this is the real finish line — the portal tick is not enough):
   - `mdatp health` — confirm `healthy : true`, `real_time_protection_enabled : true`, and the licensed/onboarded fields are true.
   - `systemextensionsctl list` — confirm the Microsoft Defender endpoint-security and network extensions are **activated enabled**.
   - `mdatp connectivity test` — confirm connectivity to the MDE cloud passes.
   - **System Settings → Privacy & Security → Full Disk Access** — confirm Microsoft Defender is granted (from the PPPC profile, no user action).
4. In the **Microsoft Defender portal** → **Assets → Devices**, confirm the pilot Mac appears **onboarded** with **Active** health status (allow up to ~15–30 minutes after first onboarding).
5. **Soak the pilot:** have pilot users work normally for several business days. Complete the **Testing Guide** (document 5).
6. **Gate:** do not expand until the pilot passes the Testing Guide gate AND `mdatp health` reports healthy with extensions running and real-time protection on — a green portal tick alone is **not** a pass.
7. **Rollback (if onboarding is wrong or the agent is degraded):** in Intune, **remove the assignment** of `MDE macOS – Onboarding` (and, if needed, the app) from the affected group, then sync — this offboards cleanly on the next cycle. Fix the missing approval (usually a capability profile from Steps 4–7 that was not applying), reconfirm the five profiles succeed, then reassign onboarding. Record what you rolled back and why.

## Step 11 — Expand to production
1. Add `MDE macOS – Production Devices` to each of the **five capability profiles** first, and confirm they apply across a production wave (re-run `MACMDE-Report.ps1`).
2. **Only then** add `MDE macOS – Production Devices` to `MDE macOS – Defender App` and finally to `MDE macOS – Onboarding` — preserving the profiles-before-onboarding order fleet-wide.
3. Roll out in waves if the fleet is large; after each wave re-run `MACMDE-Report.ps1` and spot-check `mdatp health` on a sample. Use `MACMDE-Set-ScopeTargeting.ps1` (default `-WhatIf`) to widen the target group membership safely.

---
### Order of operations
`Stage onboarding + identifiers → Confirm APNs/enrollment → Groups → System Extensions → Full Disk Access (PPPC) → Network Filter → Background Services + Notifications → [GATE: 5 profiles Succeeded] → Defender App → Onboarding profile → Validate mdatp health (pilot gate / rollback) → Expand (profiles first, then app, then onboarding)`
