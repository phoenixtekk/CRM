# 3. Implementation Guide — OneDrive for Business

Follow these steps **in order**. Each step must be complete before the next. All navigation is
in the **Microsoft Intune admin center** (`https://intune.microsoft.com`) unless stated otherwise.

> **Model:** Windows devices, Intune-managed, OneDrive configured via the **Settings Catalog**
> (Silent Sign-In + Known Folder Move + Files On-Demand), assigned to a pilot group first.

---

## Step 1 — Get your Microsoft Entra Tenant ID
Known Folder Move requires this value.

1. Open `https://entra.microsoft.com` → **Overview**.
2. Copy the **Tenant ID** (a GUID).
3. (Or run **`Get-TenantId.ps1`** from this package.) Record it for Step 5.

## Step 2 — Create the pilot security group
1. Open `https://entra.microsoft.com` → **Groups → All groups → New group**.
2. **Group type:** Security. **Group name:** `ODFB-Pilot`.
3. Add 3–5 pilot users. Click **Create**.

## Step 3 — Create the OneDrive configuration profile
1. Go to **Devices → Windows → Configuration**.
2. Click **+ Create → New Policy**.
3. **Platform:** Windows 10 and later. **Profile type:** **Settings catalog**.
4. Click **Create**.
5. **Name:** `OneDrive - Pilot - Silent + KFM`. Click **Next**.

## Step 4 — Add the OneDrive settings
1. On **Configuration settings**, click **+ Add settings**.
2. In the picker search box, type **OneDrive**. Select the **OneDrive** category.
3. Add these settings (select each checkbox):
   - **Silently sign in users to the OneDrive sync app with their Windows credentials**
   - **Silently move Windows known folders to OneDrive**
   - **Use OneDrive Files On-Demand**
   - (Optional) **Prevent users from syncing personal OneDrive accounts**
4. Close the picker.

## Step 5 — Configure the setting values (in this order)
1. **Silently sign in users to the OneDrive sync app with their Windows credentials:** **Enabled**.
2. **Use OneDrive Files On-Demand:** **Enabled**.
3. **Silently move Windows known folders to OneDrive:** **Enabled**.
   - **Tenant ID:** paste the GUID from Step 1.
   - **Show notification to users after folders have been redirected:** **Disabled** (silent) or **Enabled** (inform users) — your choice.
4. (Optional) **Prevent users from syncing personal OneDrive accounts:** **Enabled**.
5. Click **Next**.

## Step 6 — Scope tags (optional)
1. On **Scope tags**, add tags if your org uses them, else click **Next**.

## Step 7 — Assign to the pilot group
1. On **Assignments**, under **Included groups**, click **Add groups**.
2. Select **`ODFB-Pilot`**. Click **Select**, then **Next**.

## Step 8 — Review and create
1. On **Review + create**, confirm every setting (especially the Tenant ID).
2. Click **Create**.

## Step 9 — (If OneDrive client is missing) deploy the sync client
Skip if OneDrive is already present (default on Windows 10/11).

1. Go to **Apps → Windows → Add → Microsoft Store app (new)** (or Win32) and add **OneDrive**.
2. Assign to **`ODFB-Pilot`** as **Required**.

## Step 10 — Sync and apply on a pilot device
1. On a pilot device, open **Settings → Accounts → Access work or school**, select the account, click **Info → Sync**.
2. Sign out and back in (or wait for the next policy cycle). OneDrive signs in silently and begins Known Folder Move.
3. Open **File Explorer** and confirm **Desktop, Documents, and Pictures** now appear under the OneDrive folder.

## Step 11 — Validate the pilot
1. Run **`ODFB-Validation.ps1`** on the pilot device → confirms Silent Sign-In, KFM, and Files On-Demand are applied.
2. Run **`ODFB-TenantReport.ps1`** → confirms pilot users have OneDrive provisioned and syncing.
3. Complete the **Testing Guide** (Section 5) before expanding.

## Step 12 — Expand to production
1. Once the pilot passes, add **`ODFB-Production`** (or broaden `ODFB-Pilot`) to the profile **Assignments**.
2. Roll out in waves (e.g. by department). Re-validate each wave with **`ODFB-Validation.ps1`** / **`ODFB-TenantReport.ps1`**.
3. Allow time for first-sync uploads on devices with large Desktop/Documents/Pictures folders.

---
### Order of operations (summary)
`Tenant ID → Pilot group → Create Settings Catalog profile → Add OneDrive settings → Set values (Silent → Files On-Demand → KFM+Tenant ID) → Assign → Apply on device → Validate → Expand`
