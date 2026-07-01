# 3. Implementation Guide — Microsoft Defender for Endpoint Integration

Follow these steps **in order**. You use both the **Defender portal** (`security.microsoft.com`)
and the **Intune admin center** (`intune.microsoft.com`).

> **Model:** Enable the connector → EDR onboarding policy → assign to pilot → wire risk into compliance.

## Step 1 — Turn on the Intune connection (Defender portal)
1. Open `https://security.microsoft.com` → **Settings → Endpoints → Advanced features**.
2. Turn **Microsoft Intune connection** to **On**. **Save preferences**.

## Step 2 — Confirm the connector in Intune
1. Intune → **Endpoint security → Microsoft Defender for Endpoint**.
2. Confirm **Connection status: Available / Active** (wait a few minutes / **Refresh** if needed).
3. Set **Allow Microsoft Defender for Endpoint to enforce Endpoint Security Configurations** to **On** if you'll manage security config from Intune.

## Step 3 — Create the pilot group
1. Entra → **Groups → New group** → Security → `MDE-Pilot` → add pilot devices/users. **Create**.

## Step 4 — Create the EDR onboarding policy
1. Intune → **Endpoint security → Endpoint detection and response → Create Policy**.
2. **Platform:** Windows. **Profile:** Endpoint detection and response. **Create**.
3. **Name:** `MDE - EDR Onboarding - Pilot`. **Next**.
4. **Microsoft Defender for Endpoint client configuration package type:** **Auto from connector** (the onboarding blob is supplied by the connection). **Sample sharing:** as per policy. **Next**.

## Step 5 — Assign the onboarding policy
1. **Assignments → Add groups →** `MDE-Pilot`. **Next → Create**.

## Step 6 — Wire the risk score into compliance
1. Intune → **Devices → Compliance →** edit your Windows compliance policy (from the Device Compliance solution).
2. Under **Microsoft Defender for Endpoint**, set **Require the device to be at or under the machine risk score** to **Medium** (or **Low** for stricter scopes). **Save**.

## Step 7 — (Recommended) enforce with Conditional Access
1. Ensure a Conditional Access policy **requires a compliant device** (Conditional Access solution). A device exceeding the risk threshold becomes Not compliant and loses access.

## Step 8 — Validate the pilot
1. On a pilot device, run **`MDE-Discovery.ps1`** and **`MDE-Validation.ps1`** → confirm onboarded + sensor healthy.
2. Run **`MDE-ConnectorCheck.ps1`** → confirms the Intune↔MDE connector is Active.
3. Run **`MDE-TenantReport.ps1`** → confirms devices appear onboarded with a risk score. Complete the **Testing Guide**.

## Step 9 — Expand to production
1. Add a production group to the onboarding policy **Assignments**; roll out in waves.
2. Confirm risk-based compliance behaves as expected before broad Conditional Access enforcement.
3. Re-validate each wave with **`MDE-Validation.ps1`** / **`MDE-TenantReport.ps1`**.

---
### Order of operations
`Enable connector → Confirm in Intune → Pilot group → EDR onboarding policy → Assign → Risk into compliance → (CA require compliant) → Validate → Expand`
