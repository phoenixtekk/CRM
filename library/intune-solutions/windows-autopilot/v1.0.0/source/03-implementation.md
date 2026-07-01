# 3. Implementation Guide — Windows Autopilot

Follow these steps **in order**. All navigation is in the **Microsoft Intune admin center**
(`https://intune.microsoft.com`) unless stated otherwise.

> **Model:** User-driven, Microsoft Entra–joined Autopilot, assigned to a dynamic device group.

## Step 1 — Enable automatic MDM enrollment
1. Go to **Devices → Enrollment → Automatic Enrollment**.
2. Set **MDM user scope** to **All** (or your pilot group). Click **Save**.

## Step 2 — Configure company branding
1. Open `https://entra.microsoft.com` → **Company branding → Customize** (or **Add**).
2. Add your logo, background, and sign-in text. **Save**.

## Step 3 — Register the pilot device(s)
1. Run **`Get-AutopilotHash.ps1`** on each pilot device to export its hardware hash CSV.
2. In Intune go to **Devices → Enrollment → Devices** (Windows Autopilot devices) → **Import** → upload the CSV.
3. Wait for the device to appear (Sync if needed).

## Step 4 — Create a dynamic Autopilot device group
1. Open `https://entra.microsoft.com` → **Groups → New group**.
2. **Type:** Security. **Name:** `Autopilot-Devices`. **Membership type:** Dynamic Device.
3. **Add dynamic query:** `(device.devicePhysicalIDs -any (_ -contains "[ZTDId]"))`. **Save**, then **Create**.

## Step 5 — Create the deployment profile
1. Go to **Devices → Enrollment → Deployment Profiles → Create profile → Windows PC**.
2. **Name:** `Autopilot - User-Driven`. Click **Next**.
3. **Deployment mode:** User-driven. **Join type:** Microsoft Entra joined.
4. **Out-of-box experience:** hide EULA, hide privacy settings, hide change account options = **Yes**; **User account type:** Standard. Click **Next**.
5. **Assignments → Add groups →** `Autopilot-Devices`. **Next → Create**.

## Step 6 — Create the Enrollment Status Page (ESP)
1. Go to **Devices → Enrollment → Enrollment Status Page → Create**.
2. **Name:** `Autopilot - ESP`. **Show app and profile installation progress:** Yes.
3. Keep required apps minimal for the pilot. **Assignments → Add groups →** `Autopilot-Devices`. **Create**.

## Step 7 — Provision a pilot device
1. Factory-reset or use a new device. Connect to the internet at OOBE.
2. The Autopilot branding appears; the user signs in with their work account.
3. The device Entra-joins, MDM-enrolls, and the ESP runs until ready.

## Step 8 — Validate the pilot
1. Run **`Autopilot-Validation.ps1`** → confirms the device is Autopilot-registered, Entra-joined, and Intune-enrolled.
2. Run **`Autopilot-TenantReport.ps1`** → confirms profile assignment status across devices.
3. Complete the **Testing Guide** (Section 5) before expanding.

## Step 9 — Expand to production
1. Register production devices (OEM registration at purchase is ideal at scale).
2. They join `Autopilot-Devices` automatically (dynamic group) and inherit the profile + ESP.
3. Re-validate each wave with **`Autopilot-Validation.ps1`** / **`Autopilot-TenantReport.ps1`**.

---
### Order of operations
`Auto-enrollment → Branding → Register devices → Dynamic group → Deployment profile → ESP → Provision → Validate → Expand`
