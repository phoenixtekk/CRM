# 3. Implementation Guide — Microsoft Defender for Endpoint Integration (Government / GCC High)

Follow these steps **in order**. You use both the **GCC High Defender portal**
(**`security.microsoft.us`**) and the **GCC High Intune admin center**
(**`intune.microsoft.us`**). Group and Conditional Access work happens in the **GCC High Entra admin
center** (**`entra.microsoft.us`**). **Do not** use the `.com` portals — they are Commercial.

> **Model:** Enable the connector → EDR onboarding policy → assign to pilot → wire risk into
> compliance → (optional) require compliant device with Conditional Access → validate → expand.

> **GCC High caveat (read first):** every screen below is the *same* as Commercial in layout, but
> lives at a `.us` host and acts on your sovereign tenant. If a step sends you to a portal that shows
> a different tenant, you are on the wrong cloud — check the URL ends in `.us`.

---

## Step 1 — Turn on the Intune connection (GCC High Defender portal)
1. Open **`https://security.microsoft.us`** and sign in (authority `login.microsoftonline.us`).
2. Go to **Settings → Endpoints → Advanced features**.
3. Set **Microsoft Intune connection** to **On**.
4. Select **Save preferences**.

> **GCC High note:** this is the sovereign Defender portal. The toggle name is identical to
> Commercial, but it establishes the service-to-service link *within* the US Gov environment. Cited:
> Microsoft — Portal URLs (GCC High = `security.microsoft.us`); Intune/Defender integration
> (enable the connection).

## Step 2 — Confirm the connector in Intune (GCC High)
1. Open **`https://intune.microsoft.us`**.
2. Go to **Endpoint security → Microsoft Defender for Endpoint**.
3. Confirm **Connection status: Available / Active**. If it still shows *Unavailable*, wait a few
   minutes and select **Refresh** — the service-to-service handshake can take a short time.
4. If you plan to manage security configuration from Intune, set **Allow Microsoft Defender for
   Endpoint to enforce Endpoint Security Configurations** to **On**.

> **GCC High caveat:** the connector is Gov-to-Gov. If status never becomes *Active*, the most common
> causes are (a) you toggled the connection in the Commercial Defender portal by mistake, or (b) the
> `*.microsoft.us` endpoints are blocked by filtering (see `02-requirements.md` R6). Validate with
> **`MDEG-Validation.ps1`** (connector check).

## Step 3 — Create the pilot group (GCC High Entra)
1. Open **`https://entra.microsoft.us`** → **Groups → New group**.
2. **Group type:** Security. **Group name:** **`SG-MDE-Pilot`**.
3. Add your pilot devices (or pilot users) as members. Select **Create**.

> Reuse this exact group name in the assignment steps. Build the production wave group
> **`SG-MDE-Prod-Wave1`** the same way now or at expansion time.

## Step 4 — Create the EDR onboarding policy (GCC High Intune)
1. In **`intune.microsoft.us`** → **Endpoint security → Endpoint detection and response → Create
   Policy**.
2. **Platform:** **Windows**. **Profile:** **Endpoint detection and response**. Select **Create**.
3. **Name:** **`MDE - EDR Onboarding - Pilot`**. Select **Next**.
4. On **Configuration settings**:
   - **Microsoft Defender for Endpoint client configuration package type:** **Auto from connector**
     — the onboarding blob is supplied by the *GCC High* connection you enabled in Step 1, so the
     sensor registers to the **US Government** environment automatically. **Do not** paste a manually
     downloaded Commercial onboarding package.
   - **Sample sharing** and telemetry options: set per your organization's data-handling policy.
   Select **Next**.
5. **Scope tags:** apply if you use RBAC scoping (see `MDEG-Set-ScopeTargeting.ps1`). Select **Next**.

> **GCC High caveat:** because the package is **Auto from connector**, the correct **Gov** onboarding
> endpoints are baked in — this is the safest way to guarantee devices point at `*.microsoft.us`
> service URLs and not the Commercial endpoints. Cited: Microsoft — onboarding via Intune; Endpoint
> versions (correct-environment onboarding).

## Step 5 — Assign the onboarding policy to the pilot
1. On **Assignments**, select **Add groups** and add **`SG-MDE-Pilot`**. Select **Next**.
2. Review and select **Create**.

> **Gate — Pilot:** assign to **`SG-MDE-Pilot` only**. Do not add production groups yet.

## Step 6 — Wire the machine risk score into device compliance (GCC High Intune)
1. In **`intune.microsoft.us`** → **Devices → Compliance**.
2. Edit your Windows compliance policy, or create **`CP-Windows-MDE-Risk`** (**Create policy →
   Platform: Windows 10 and later**).
3. Under **Microsoft Defender for Endpoint**, set **Require the device to be at or under the machine
   risk score** to **Medium** (use **Low** for stricter scopes; **High** is the most permissive).
4. On **Actions for noncompliance**, keep the default *Mark device noncompliant* (tune grace period
   to your policy). Select **Save**.
5. On **Assignments**, assign to **`SG-MDE-Pilot`** (same population as onboarding). Select **Save**.

> This is the step that turns an MDE risk signal into an Intune compliance state. Cited: Microsoft —
> Intune/Defender integration (create a compliance policy to set the device risk level).

## Step 7 — (Recommended) Enforce with Conditional Access (GCC High Entra)
1. Open **`https://entra.microsoft.us`** → **Protection → Conditional Access → New policy**.
2. **Name:** **`CA-Require-Compliant-MDE`**.
3. **Users:** your pilot users. **Target resources:** the apps you want to protect.
4. **Grant:** **Require device to be marked as compliant**. Enable the policy (start in *Report-only*
   if you want to observe first).

> A device whose MDE risk exceeds your threshold (Step 6) becomes **Not compliant**, and this policy
> then blocks its access until it is remediated. Conditional Access lives in Entra and needs the
> **Conditional Access Administrator** role. Cited: Microsoft — configure Conditional Access to block
> noncompliant devices.

## Step 8 — Validate the pilot
1. On a pilot device, run **`MDEG-Discovery.ps1`** then **`MDEG-Validation.ps1`** — confirm the
   device is onboarded to the **US Gov** MDE service and the sensor is healthy.
2. Run **`MDEG-Validation.ps1`** connector check — confirms the Intune ↔ MDE connector is **Active**.
3. Run **`MDEG-Report.ps1`** — confirms devices appear onboarded and a **risk score** is flowing into
   Intune compliance.
4. Complete the **Testing Guide** (`05-testing.md`) and pass every gate.

> **Gate — Validate:** do not expand until onboarding, sensor health, connector status, risk flow,
> and compliance reaction all pass on the pilot.

## Step 9 — Expand to production (in waves)
1. Create **`SG-MDE-Prod-Wave1`** (if not already) in `entra.microsoft.us`.
2. Add **`SG-MDE-Prod-Wave1`** to the **Assignments** of both **`MDE - EDR Onboarding - Pilot`**
   (onboarding) and **`CP-Windows-MDE-Risk`** (compliance). Roll out one wave at a time.
3. Confirm risk-based compliance behaves as expected on the wave **before** broadening Conditional
   Access enforcement out of Report-only.
4. Re-validate each wave with **`MDEG-Validation.ps1`** and **`MDEG-Report.ps1`**.

> **GCC High expansion caveat:** before you lean on any **analytics/reporting/response** feature
> (e.g. automated investigation & response, advanced hunting integrations), confirm it is actually
> present in *your* GCC High/DoD tenant — several such surfaces lag Commercial. See
> `gcc-high-parity-notes.md` and **verify for GCC High/DoD** in your tenant.

---
### Order of operations
`Enable connector (security.microsoft.us) → Confirm in Intune (intune.microsoft.us) → Pilot group
(entra.microsoft.us) → EDR onboarding policy (Auto from connector) → Assign to SG-MDE-Pilot → Risk
into CP-Windows-MDE-Risk → (CA require compliant) → Validate with MDEG-* scripts → Expand in waves`

*Sources: Microsoft Learn — "Integrate Microsoft Defender for Endpoint with Intune for Device
Compliance"; "Configure Microsoft Defender for Endpoint in Intune"; "Onboard devices to Microsoft
Defender for Endpoint using Intune"; "Microsoft Defender for Endpoint for US Government customers"
(portal URLs, onboarding environment, connectivity). Verify GCC High / DoD specifics in your tenant.*
