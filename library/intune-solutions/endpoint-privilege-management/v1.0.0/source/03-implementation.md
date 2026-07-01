# 3. Implementation Guide — Endpoint Privilege Management (EPM)

Follow these steps **in order**. Each step must be complete before the next. All navigation is
in the **Microsoft Intune admin center** (`https://intune.microsoft.com`) unless stated otherwise.

> **Model:** Intune-managed, Microsoft Entra–joined Windows devices. We deploy an **Elevation
> settings (base) policy** plus **Elevation rules policies** to a pilot group, default elevation
> type **User confirmed**, and we **observe with reporting first** before removing local admin rights.
> **Approach:** Pilot → Validate → Expand, exactly like every Phoenixtekk solution.

---

## Step 1 — Confirm the EPM license is assigned
Before anything else, confirm your pilot users hold the **Intune Suite** or **Endpoint Privilege
Management** license (Requirements §2.1). Without it, the policies below will not apply.

1. In **M365 admin center → Billing → Licenses**, confirm the license is owned and assigned to pilot users.
2. In Intune, open **Endpoint security → Endpoint Privilege Management** and confirm it is available
   (not showing only a purchase/trial prompt).

## Step 2 — Create the pilot security group
1. Open `https://entra.microsoft.com` → **Groups → All groups → New group**.
2. **Group type:** Security. **Group name:** `EPM-Pilot`.
3. Add 3–5 pilot users (or devices) as **Members**.
4. Click **Create**.

## Step 3 — Create the Elevation settings (base) policy
1. Go to **Endpoint security → Endpoint Privilege Management**.
2. Select the **Policies** tab → **+ Create Policy**.
3. **Platform:** Windows. **Profile:** **Elevation settings policy**. Click **Create**.
4. **Name:** `EPM - Base - Pilot`. Click **Next**.
5. On **Configuration settings**:
   - **Endpoint Privilege Management:** **Enabled**.
   - **Default elevation response:** **Deny all requests** *(recommended)* — only rules you author
     will elevate. (Choosing **Require user confirmation** as the default is broader; keep it
     denied for the pilot.)
   - **Send elevation data for reporting:** **Yes**, and set **Reporting scope** to **All elevations**
     (so you observe everything during the pilot).
6. Click **Next**.

## Step 4 — Assign the base policy to the pilot
1. On **Scope tags**, add tags if your org uses them, else click **Next**.
2. On **Assignments**, under **Included groups**, click **Add groups** → select **`EPM-Pilot`** → **Select** → **Next**.
3. On **Review + create**, confirm settings → **Create**.
4. On a pilot device, sync (**Settings → Accounts → Access work or school → Info → Sync**) and confirm
   the **EPM client** installs (see Testing §). The base policy is what triggers the client install.

## Step 5 — Gather the applications that need elevation
1. Let the pilot run for a short observation period with reporting on, **or** identify the target
   applications up front.
2. For each target executable, run **`New-EpmElevationRule.ps1 -Path "C:\Path\app.exe"`** to read the
   file name, **publisher certificate**, and **SHA-256 hash** you'll enter in the rule.
3. Prefer a **certificate** match for signed apps (rules survive app updates); use **hash** for
   unsigned, fixed binaries.

## Step 6 — Create an Elevation rules policy
1. Go to **Endpoint security → Endpoint Privilege Management → Policies → + Create Policy**.
2. **Platform:** Windows. **Profile:** **Elevation rules policy**. Click **Create**.
3. **Name:** `EPM - Rules - Pilot`. Click **Next**.
4. Click **+ Add** to create a rule, then set:
   - **Rule name** and (optional) **Description**.
   - **Elevation type:** **User confirmed** *(recommended default)*.
   - Under **User confirmation**, require **Business justification** and/or **Windows authentication**
     for a stronger record (recommended).
   - **File name:** the exact executable name (e.g. `setup.exe`).
   - **File hash** *or* add a **Certificate** (upload the signer cert and choose **Certificate** as
     the validation) — use the values from `New-EpmElevationRule.ps1`.
   - Optionally set the **child process behavior** (deny by default unless the app legitimately spawns
     installers).
5. Add additional rules as needed, then click **Next**.

## Step 7 — Assign the rules policy to the pilot
1. **Scope tags** → **Next**.
2. **Assignments → Included groups → Add groups → `EPM-Pilot` → Select → Next**.
3. **Review + create → Create**.

## Step 8 — Sync and test an elevation on a pilot device
1. On a pilot device, force a sync (**Access work or school → Info → Sync**).
2. As a **standard user**, right-click an approved application → **Run with elevated access**.
3. Confirm the **User confirmed** prompt appears, supply justification/authentication, and the app
   runs elevated. Confirm a **non-approved** app does **not** elevate.

## Step 9 — Review reporting
1. Go to **Endpoint security → Endpoint Privilege Management → Reports**.
2. Confirm elevations from the pilot appear (managed elevations, and unmanaged/denied attempts).
3. Use this data to refine rules — add the legitimate apps users tried to elevate.

## Step 10 — Remove standing local-admin rights from pilot users
Once rules cover real usage, realize EPM's value by making pilot users standard users.

1. Communicate the change to pilot users (what changes, how to elevate approved apps, who to contact).
2. Remove the pilot users from the device **Administrators** group (e.g. via an Intune **Account
   protection → Local user group membership** policy targeting `EPM-Pilot`). Keep a
   **support-approved** safety valve for edge cases.
3. Re-validate with **`EPM-Validation.ps1`** and the Testing Guide.

## Step 11 — Validate the pilot
1. Run **`EPM-Validation.ps1`** on a pilot device → confirms the client is healthy and the base
   policy applied.
2. Run **`EPM-ElevationReport.ps1`** → confirms tenant-wide elevation reporting for the pilot.
3. Complete the **Testing Guide** (Section 5) before expanding.

## Step 12 — Expand to production
1. Create **`EPM-Production`**, add it to the **base** policy and the **rules** policy **Assignments**.
2. Roll out in waves (by department). Re-validate each wave with **`EPM-Validation.ps1`** /
   **`EPM-ElevationReport.ps1`** and tighten the default response to **Deny all** everywhere.
3. Keep rules certificate-based where possible and review the elevation report on a schedule.

---
### Order of operations (summary)
`Confirm license → Pilot group → Base policy (enable + reporting) → Assign → Discover apps → Rules policy (User confirmed) → Assign → Test elevation → Review reports → Remove local admin → Validate → Expand`
