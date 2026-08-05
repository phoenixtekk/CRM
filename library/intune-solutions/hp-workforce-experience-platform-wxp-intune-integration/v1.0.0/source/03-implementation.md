# 3. Implementation — HP Workforce Experience Platform (WXP) Integration with Microsoft Intune

Follow these steps **in order**. The *why* for each capability lives in the Solution Overview; the
steps below are deliberately short and exact so you can **click to implement**. Throughout, the
repeatable pattern applies: **Assess → Configure → Pilot → Validate → Expand.** Do everything against a
**pilot group** first.

All Microsoft admin-center steps use the Microsoft Intune admin center at `https://intune.microsoft.com`
and Microsoft Entra at `https://entra.microsoft.com` unless noted. HP steps use the **HP WXP admin
console**.

> **HP renamed this platform repeatedly.** The **console menu names, agent installer filename,
> enrollment-code label, connector app display name, Graph scopes, and WXP network URLs vary by
> release.** Where a step says **"verify in the HP WXP admin console"** or **"verify in your tenant,"**
> confirm the current value rather than assuming — the surrounding Intune/Entra mechanics are stable
> even when HP's labels move.

---

## Phase 1 — Assess: gather WXP tenant details and prepare Intune

### Step 1. Confirm the HP WXP subscription and console access
1. Sign in to the **HP WXP admin console** as an administrator (R2).
2. Confirm an **active subscription** with available seats covering your target devices (R1). Confirm
   coverage for any **non-HP Windows** devices — **verify with HP**.

### Step 2. Obtain the agent installer and the enrollment code
1. In the WXP console, locate the **agent download** and download the current **HP WXP agent installer**
   (MSI/EXE). *(Exact menu location and installer filename — **verify in the console**.)*
2. Locate and copy your **company / enrollment code** — the value that binds an installed agent to your
   WXP tenant (R3). *(Its label and location — **verify in the console**.)*
3. Record the vendor's **exact install and uninstall command lines**, including **how the enrollment
   code is passed** on the install command (a property, switch, or config value). **Verify these against
   HP's current agent documentation — do not guess the parameter name.**

### Step 3. Create the pilot group
1. Go to **Entra → Groups → New group**.
2. **Group type:** Security. **Group name:** **`HP WXP - Pilot Devices`**. Create it.
3. Add your **pilot Windows device(s)** (or their users). This is the group the agent app is assigned to
   first (Global Requirement G5, R10).

### Step 4. Wrap the agent installer as an .intunewin package
1. On your packaging workstation, put the downloaded agent installer in a source folder.
2. Run the **Microsoft Win32 Content Prep Tool** (R5):
   `IntuneWinAppUtil.exe -c <sourceFolder> -s <agentInstaller.msi|.exe> -o <outputFolder>`
3. This produces an **`.intunewin`** package you will upload to Intune in Phase 2.
4. On a **reference device**, install the agent once and capture a **detection value** (R6): the MSI
   **product code**, or the agent's install-path file + version / registry key. **Record the exact
   value** for Step 6.

---

## Phase 2 — Configure: package the agent as an Intune Win32 app

### Step 5. Add the Win32 app
1. Go to **Apps → Windows → Add**.
2. **App type = Windows app (Win32)**, **Select**. Upload the **`.intunewin`** from Step 4.
3. **App information → Name:** **`HP WXP Agent - Pilot`**. Add publisher **HP** and a description, e.g.
   *HP Workforce Experience Platform agent, deployed via Intune and registered to our WXP tenant.* Click
   **Next**.

### Step 6. Program (install/uninstall) and detection
1. **Install command:** the vendor's exact silent install command **with your enrollment code injected**
   (from Step 2). For an MSI this is typically of the form
   `msiexec /i "<agent>.msi" /qn <ENROLLMENT_PROPERTY>=<your-code>` — **the property name and syntax
   must come from HP's agent documentation; verify it, do not assume `<ENROLLMENT_PROPERTY>`.**
2. **Uninstall command:** the vendor's exact uninstall command (e.g. `msiexec /x "<ProductCode>" /qn`).
3. **Install behavior:** **System**. **Device restart behavior:** as the vendor specifies (typically no
   forced restart).
4. **Next → Detection rules → Rules format = Manually configure detection rules → Add.** Use the value
   you captured in Step 4:
   - **MSI** product code (if the agent is an MSI), or
   - **File** (install path + a file, with version ≥ the shipped version), or
   - **Registry** key/value the agent writes.
   **Verify the detection value on your reference device** — a wrong product code makes the app loop.
5. **Next** through **Dependencies** and **Supersedence** (none required for a first deployment).

### Step 7. Assign the agent Required to the pilot group
1. On **Assignments**, under **Required**, **Add group** → select **`HP WXP - Pilot Devices`**.
2. Leave **Available** and **Uninstall** empty for the pilot. Click **Next**.
3. **Review + create → Create.** Intune will begin installing `HP WXP Agent - Pilot` on pilot devices at
   their next check-in.

> Prefer automation for the assignment? Use the included
> **`HPWXP-Set-ScopeTargeting.ps1`** (Microsoft Graph) to set or adjust the app's group assignment
> (defaults to **-WhatIf** — preview first, then re-run to apply), and **`HPWXP-Discovery.ps1`** to
> confirm the app is present and assigned.

---

## Phase 3 — Configure: connect HP WXP to the Entra/Intune tenant

### Step 8. Initiate the Microsoft/Intune connection from the WXP console
1. In the **HP WXP admin console**, open the **Microsoft / Intune integration** (sometimes labelled
   *Integrations*, *Connections*, or *Microsoft Endpoint Manager* — **verify the current label in the
   console**).
2. Start the **Connect to Microsoft / Intune** flow. This launches an **Entra sign-in and
   admin-consent** request. **Verify the flow name and the exact Graph permissions it requests in the
   console — do not assume specific scopes.**

### Step 9. Grant admin consent (Global Administrator)
1. When redirected to Microsoft, sign in as a **Global Administrator** (R7).
2. Review the **permissions requested** (WXP requests **read** access to your Intune/Entra device
   inventory via Microsoft Graph — **confirm the exact scopes shown on the consent screen**) and grant
   **admin consent** for the organization.
3. Consent creates an **enterprise application / service principal** in your tenant representing HP WXP —
   this package refers to it as **`HP Workforce Experience`**. **Confirm the actual display name in
   Entra → Enterprise applications** (R8); you will pass it to the scripts via `-ConnectorAppName`.

### Step 10. Confirm the connection in the WXP console
1. Back in the WXP console, confirm the Microsoft/Intune connection shows **connected/healthy** and that
   WXP begins listing your Intune-managed devices (initial sync can take time — **verify expected sync
   timing in HP's documentation**).

---

## Phase 4 — Pilot, validate, and expand

### Step 11. Confirm the agent installed on pilot devices
1. On a pilot device, force an Intune sync (**Settings → Accounts → Access work or school → Info →
   Sync**, or Company Portal → **Sync**).
2. In Intune → **Apps → Windows → `HP WXP Agent - Pilot` → Device install status**, confirm the pilot
   device shows **Installed**.
3. In the **HP WXP admin console**, confirm the pilot device **appears and is reporting telemetry**
   (hardware/experience data begins to populate — allow for first-report delay).

### Step 12. Validate with the scripts
1. Run **`HPWXP-Discovery.ps1`** (integration readiness: the `HP WXP Agent - Pilot` Win32 app exists and
   is assigned; the `HP Workforce Experience` connector service principal is present — pass
   `-ConnectorAppName` with the name from Step 9).
2. Run **`HPWXP-Validation.ps1`** to confirm the app is **assigned** to `HP WXP - Pilot Devices` and each
   pilot device reports **Installed**.
3. Run **`HPWXP-Report.ps1`** to produce an **agent-coverage report** (which Windows devices have the WXP
   agent installed).

### Step 13. Remediate gaps (safe by default)
1. If devices are missing the assignment or the app is mis-scoped, run **`HPWXP-Remediation.ps1`** — it
   **defaults to `-WhatIf`** and prints exactly what it would change (e.g. add the pilot group to the
   app's Required assignment). Review, then re-run with `-WhatIf:$false` to apply.

### Step 14. Expand in waves
1. Once the pilot passes (Testing gate), broaden the `HP WXP Agent - Pilot` assignment to the next group
   (or create a broader production group and assign the app to it) using **`HPWXP-Set-ScopeTargeting.ps1`**
   or the Intune UI.
2. Roll out in waves, validating each wave with **`HPWXP-Report.ps1`** before widening.
3. Keep **Microsoft Endpoint Analytics** enabled alongside WXP (R11) — run both for the full
   Microsoft-native + HP-hardware picture.
