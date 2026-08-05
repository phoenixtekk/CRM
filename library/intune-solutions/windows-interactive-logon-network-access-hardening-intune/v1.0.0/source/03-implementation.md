# 3. Implementation — Windows Interactive Logon & Network-Access Security Options Hardening

Follow these steps **in order**. The *why* for each capability lives in the Solution Overview; the
steps below are deliberately short and exact so you can **click to implement**. Throughout, the
repeatable pattern applies: **Assess → Configure → Pilot → Validate → Expand.** Do everything against a
**pilot group** first.

All admin-center steps use the Microsoft Intune admin center at `https://intune.microsoft.com` unless
noted.

> **This deploys the four Security-Options / logon controls only** on **enrolled Windows 10/11**
> clients, via a single **Settings Catalog** profile. It does not enroll or image devices and does not
> configure NTLM/SMB, RDP, or credential-theft hardening.

---

## Phase 1 — Assess and prepare

### Step 1. Confirm enrollment and the Windows baseline
1. Go to **Devices → Windows → Windows devices** and confirm the pilot device is **managed** (Entra
   joined or Entra hybrid joined).
2. Open the device → **Hardware** and confirm **Windows 10 21H2+** or **Windows 11** with current
   updates.

### Step 2. Check for existing owners of these four settings (avoid conflicts)
1. Go to **Devices → Configuration** and review your existing **security baselines** and hardening
   profiles.
2. Confirm that **none** of them already sets: *Windows Connection Manager* non-domain block,
   *Interactive logon: Smart card removal behavior*, *automatic restart sign-on*, or *Do not display
   network selection UI*. If one does, decide a single owner for that setting before continuing
   (Requirements R3).

### Step 3. Create (or confirm) the pilot group
1. Go to **Groups → New group** (or Entra → **Groups**).
2. **Group type = Security**; **Group name = `SEC - Interactive Logon Hardening Pilot`**.
3. Add the pilot device (for device-targeted assignment) or pilot user, then **Create**.

---

## Phase 2 — Create the Settings Catalog profile

### Step 4. Create the profile
1. Go to **Devices → Configuration → Create → New policy**.
2. **Platform = Windows 10 and later**; **Profile type = Settings catalog**; click **Create**.
3. **Basics → Name:** **`Interactive Logon & Network-Access Hardening - Pilot`**. **Description:**
   *Closes the leftover interactive-logon and network-access Security Options findings (Windows
   Connection Manager non-domain block, smart-card removal = Lock Workstation, disable automatic
   restart sign-on, hide network selection UI).* Click **Next**.

### Step 5. Add setting #1 — Prohibit connection to non-domain networks
1. On **Configuration settings**, click **+ Add settings**.
2. In the settings picker, search **`Windows Connection Manager`** and select that category.
3. Tick **Prohibit connection to non-domain networks when connected to domain authenticated network**.
   Close the picker.
4. Set the setting's toggle to **Enabled**.
   - *Underlying value:* `fBlockNonDomain = 1` (policy CSP
     `WindowsConnectionManager/ProhibitConnectionToNonDomainNetworksWhenConnectedToDomainAuthenticatedNetwork`).
     **Verify the exact display name in your tenant** — Microsoft occasionally revises catalog labels.

### Step 6. Add setting #2 — Interactive logon: Smart card removal behavior
1. Click **+ Add settings** again. Search **`Smart Card Removal Behavior`** (category **Local Policies
   Security Options**).
2. Tick **Interactive Logon Smart Card Removal Behavior**. Close the picker.
3. Set its value to **Lock Workstation**.
   - *Underlying value:* `scremoveoption = 1` (policy CSP
     `LocalPoliciesSecurityOptions/InteractiveLogon_SmartCardRemovalBehavior`). Options are *No Action
     (0)*, **Lock Workstation (1)**, *Force Logoff (2)*, *Disconnect (3)* — choose **Lock Workstation**.

### Step 7. Add setting #3 — Disable automatic restart sign-on
1. Click **+ Add settings**. Search **`Sign-in and lock last interactive user automatically after a
   restart`** (category **Administrative Templates\Windows Components\Windows Logon Options**).
2. Tick the setting. Close the picker.
3. Set the toggle to **Disabled**. *(Disabling this GPO turns automatic restart sign-on OFF.)*
   - *Underlying value:* `DisableAutomaticRestartSignOn = 1` (policy CSP
     `WindowsLogon/DisableAutomaticRestartSignOn` — **verify the catalog wording in your tenant**; the
     ADMX-backed label and the CSP name differ, and setting the ADMX policy to **Disabled** is what
     yields `DisableAutomaticRestartSignOn = 1`).

### Step 8. Add setting #4 — Do not display network selection UI
1. Click **+ Add settings**. Search **`Do not display network selection UI`** (category
   **Administrative Templates\System\Logon**).
2. Tick the setting. Close the picker.
3. Set the toggle to **Enabled**.
   - *Underlying value:* `DontDisplayNetworkSelectionUI = 1` (policy CSP
     `WindowsLogon/DontDisplayNetworkSelectionUI`).

> After Steps 5–8 the profile carries **four** settings. Click **Next**.

### Step 9. Scope tags, assignment, review
1. **Next** through **Scope tags** (set if you use them).
2. **Assignments:** add the **`SEC - Interactive Logon Hardening Pilot`** group. Do **not** assign to
   *All devices* yet. Click **Next**.
3. **Review + create** → **Create**.

> Prefer automation? Run the included **`WINSECOPT-Remediation.ps1`** (Microsoft Graph) to create the
> profile with all four settings if it is missing (defaults to **-WhatIf** — preview first, then re-run
> to apply), **`WINSECOPT-Set-ScopeTargeting.ps1`** to set/adjust the group assignment (also
> **-WhatIf** by default), and **`WINSECOPT-Discovery.ps1`** to confirm the profile is present and
> correctly configured.

---

## Phase 3 — Pilot

### Step 10. Push and confirm the profile
1. On the pilot device, force an MDM sync: **Settings → Accounts → Access work or school →
   (your account) → Info → Sync**.
2. In Intune → **Devices → Configuration → `Interactive Logon & Network-Access Hardening - Pilot` →
   Device status**, confirm the pilot device shows **Succeeded**.

### Step 11. Spot-check the applied values on the device
1. On the pilot device, confirm the four registry values are set (read-only check):
   - `HKLM\SOFTWARE\Policies\Microsoft\Windows\WcmSvc\GroupPolicy\fBlockNonDomain = 1`
   - `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\scremoveoption = 1`
   - `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\DisableAutomaticRestartSignOn = 1`
   - `HKLM\SOFTWARE\Policies\Microsoft\Windows\System\DontDisplayNetworkSelectionUI = 1`
   - **Verify these exact registry paths in your build** — they reflect current Windows behavior but
     can differ across releases.

### Step 12. Validate the user-visible behavior
1. At the **sign-in screen**, confirm the **network-selection button is gone** (setting #4).
2. If smart cards are in use, **remove the card** from a signed-in pilot device and confirm the
   **session locks** (setting #2).
3. Trigger (or simulate) a **Windows Update reboot** and confirm the device returns to the **sign-in
   screen** rather than auto-signing the last user back in (setting #3). Tell the pilot user this is
   expected (Requirements R6).
4. While connected to the corporate network, confirm the device does **not** auto-join a second,
   non-domain network (setting #1).

---

## Phase 4 — Validate and expand

### Step 13. Validate with the scripts
1. Run **`WINSECOPT-Discovery.ps1`** (tenant readiness: the Settings Catalog profile exists with the
   four settings present).
2. Run **`WINSECOPT-Validation.ps1`** to confirm the profile is **assigned** to the intended group and
   the pilot device shows the profile **applied** (Succeeded).
3. Run **`WINSECOPT-Report.ps1`** to produce a coverage report (which Windows devices have the
   hardening profile applied).

### Step 14. Remediate gaps (safe by default)
1. If the profile is missing or mis-scoped, run **`WINSECOPT-Remediation.ps1`** — it **defaults to
   `-WhatIf`** and prints exactly what it would create/assign. Review, then re-run with
   `-WhatIf:$false` to apply.

### Step 15. Expand in waves
1. Once the pilot passes (Testing gate), broaden the assignment to the next group with
   **`WINSECOPT-Set-ScopeTargeting.ps1`** (or make it the standard hardening profile for corporate
   Windows devices).
2. Re-confirm with **`WINSECOPT-Report.ps1`** after each wave before widening further, and re-check
   that no other baseline has started to co-own one of the four settings (Requirements R3).
