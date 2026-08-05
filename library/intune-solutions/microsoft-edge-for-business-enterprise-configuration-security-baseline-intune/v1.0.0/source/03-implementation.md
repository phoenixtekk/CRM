# 3. Implementation — Microsoft Edge for Business: Enterprise Configuration & Security Baseline (Intune)

Follow these steps **in order**. The *why* for each capability lives in the Solution Overview; the steps
below are deliberately short and exact so you can **click to implement**. Throughout, the repeatable
pattern applies: **Assess → Configure → Pilot → Validate → Expand.** Do everything against the
**`Edge for Business - Pilot Devices`** group first.

All admin-center steps use the Microsoft Intune admin center at `https://intune.microsoft.com` unless
noted.

> **Policy names & CSP keys.** Each setting is given with its **Edge policy name** (as it appears in the
> Settings Catalog search) and its **policy CSP key** where confident. Edge adds/renames policies often —
> anything flagged **verify in your tenant** should be confirmed for your Edge version before fleet
> rollout rather than assumed.

---

## Phase 1 — Assess and prepare

### Step 1. Confirm scope and the pilot group
1. Go to **Groups** (in Entra) and confirm **`Edge for Business - Pilot Devices`** exists with your pilot
   device(s)/user(s) (Requirement R8). If not, create it: **Groups → New group → Security**, name it
   exactly **`Edge for Business - Pilot Devices`**, add members.
2. In Intune → **Devices → Windows → Windows devices**, confirm the pilot device is **managed** and
   **compliant** (R7).
3. On the pilot device, open **`edge://version`** and record the **Edge version and channel** (R1) — you
   will confirm certain policies exist for that version.

### Step 2. Baseline the current state (the two findings)
1. On the pilot device, open **`edge://policy`** — this lists every Edge policy currently applied. Before
   you deploy anything, note that **`PasswordManagerEnabled`** is absent or `true`, and that Edge is not
   forced as default. This is your "before" evidence for the two assessment findings.
2. *(Optional, tenant-side)* Run **`EDGEBIZ-Discovery.ps1`** to confirm no conflicting Edge configuration
   profile already exists.

### Step 3. Author the Enterprise Mode Site List (for IE mode)
1. Download and open the **Enterprise Mode Site List Manager** (Microsoft's free tool).
2. **Add** each legacy line-of-business site that must use IE: enter the URL, set **Open in = IE11**
   (this is IE mode inside Edge), and set the **Compat Mode** if the app needs a specific document mode.
3. **File → Save to XML** as **`EdgeForBusiness-EMSiteList.xml`** (schema **version 2**).
4. Host the file at an internal URL reachable by the pilot devices (R9) — for example
   `https://intranet.corp.example/edge/EdgeForBusiness-EMSiteList.xml`. Record that URL; you will paste it
   into the IE-mode policy in Step 9.

### Step 4. Produce the default-associations XML (for default-browser)
1. On a reference Windows device where **Edge is already the default** browser, open an **elevated**
   command prompt and run:
   `dism /online /Export-DefaultAppAssociations:C:\AppAssociations.xml`
2. Open `C:\AppAssociations.xml` and keep the association lines you want to enforce — at minimum the
   `http`, `https`, `.htm`, `.html` entries whose `ProgId` points at Edge (e.g. `MSEdgeHTM`). Remove
   unrelated entries so you enforce **only** the browser associations.
3. Save this file; you will Base64-encode and deploy it in Step 10.

---

## Phase 2 — Configure Edge (Settings Catalog baseline)

### Step 5. Create the Edge configuration baseline profile
1. Go to **Devices → Configuration → Create → New policy**.
2. **Platform** = **Windows 10 and later**; **Profile type** = **Settings catalog**. Click **Create**.
3. **Basics → Name:** **`Edge for Business - Baseline - Pilot`**. **Description:** *Microsoft Edge for
   Business enterprise configuration baseline — password manager off, SmartScreen/PUA, extension control,
   sync/sign-in, typosquatting, startup/home, IE mode.* Click **Next**.
4. On **Configuration settings**, click **+ Add settings** to open the settings picker, then add the
   settings in Steps 6–9. In the picker, search the **category** (e.g. *Microsoft Edge*), tick the
   setting, then set its value in the profile.

### Step 6. Turn off the built-in password manager (Finding #1)
1. In **+ Add settings**, search **Microsoft Edge** and select **"Enable saving passwords to the password
   manager"** (policy CSP **`PasswordManagerEnabled`**).
2. Set it to **Disabled**. This prevents Edge from offering to save passwords and steers users to the
   enterprise password solution (R3).

### Step 7. Apply the security/config hardening settings
Still under **+ Add settings** in `Edge for Business - Baseline - Pilot`, add each of the following. Names
are the Settings Catalog labels; the CSP key is in parentheses. Set the value shown.

**SmartScreen + PUA:**
- **"Configure Microsoft Defender SmartScreen"** (`SmartScreenEnabled`) → **Enabled**.
- **"Configure Microsoft Defender SmartScreen to block potentially unwanted apps"**
  (`SmartScreenPuaEnabled`) → **Enabled**.
- **"Prevent bypassing Microsoft Defender SmartScreen prompts for sites"**
  (`PreventSmartScreenPromptOverride`) → **Enabled**.
- **"Prevent bypassing of Microsoft Defender SmartScreen warnings about downloads"**
  (`PreventSmartScreenPromptOverrideForFiles`) → **Enabled**.

**Extension control (sideloading):**
- **"Control which extensions cannot be installed"** (`ExtensionInstallBlocklist`) → add one entry with
  value **`*`** (block everything by default).
- **"Allow specific extensions to be installed"** (`ExtensionInstallAllowlist`) → add the **extension IDs**
  your organization approves (leave empty to allow none).
- *(Optional)* **"Control which extensions are installed silently"** (`ExtensionInstallForcelist`) → add
  IDs of extensions you want auto-deployed.
- **"Blocks external extensions from being installed"** (`BlockExternalExtensions`) → **Enabled** (stops
  out-of-store sideloading).

**Sync & work-profile sign-in:**
- **"Browser sign-in settings"** (`BrowserSignin`) → **Force users to sign in to use the browser** (forces
  the managed **work profile**). *(Choose **Enable** rather than **Force** if you want optional sign-in —
  decide per your identity posture.)*
- **"Disable synchronization of data using Microsoft sync services"** (`SyncDisabled`) → **Enabled** to
  stop consumer sync of browser data (or leave unmanaged if you use Edge enterprise sync — **decide per
  policy**).

**Website typo protection (typosquatting):**
- **"Configure Edge TyposquattingChecker" / "Website typo protection"** (`TyposquattingCheckerEnabled`) →
  **Enabled**. *(Newer Edge policy — **verify in your tenant** it exists for your version; if absent, skip
  and note it.)*

**Startup & home pages:**
- **"Action to take on startup"** (`RestoreOnStartup`) → **Open a list of URLs** (value 4).
- **"Sites to open when the browser starts"** (`RestoreOnStartupURLs`) → add your portal URL(s), e.g.
  `https://portal.office.com`.
- **"Configure the home page URL"** (`HomepageLocation`) → your intranet/portal URL.
- **"Configure the new tab page URL"** (`NewTabPageLocation`) → your chosen new-tab URL (optional).

### Step 8. Configure the update channel & cadence
1. In **+ Add settings**, search **Microsoft Edge Update** (a separate ADMX group from *Microsoft Edge*).
2. Add **"Target Channel override"** (or the equivalently named per-app channel override) and set the
   channel to **Stable** so the fleet stays on the supported channel. **Verify the exact policy name** for
   your version.
3. *(Optional)* Add **"Auto-update check period override"** and set a cadence (e.g. every 10 hours /
   remain within a supported window) so devices update predictably. Leave at default if you have no
   specific cadence requirement.

### Step 9. Configure IE mode + the Enterprise Mode Site List
1. In **+ Add settings**, search **Microsoft Edge** and select **"Configure Internet Explorer
   integration"** (`InternetExplorerIntegrationLevel`).
2. Set it to **Internet Explorer mode** — this enables IE mode inside Edge.
3. Add **"Configure the Enterprise Mode Site List"** (`InternetExplorerIntegrationSiteList`) and set its
   value to the URL of **`EdgeForBusiness-EMSiteList.xml`** from Step 3 (e.g.
   `https://intranet.corp.example/edge/EdgeForBusiness-EMSiteList.xml`).
4. *(Optional but recommended)* Add **"Send all intranet sites to Internet Explorer mode"**
   (`InternetExplorerIntegrationReloadInIEModeAllowed` / the "reload in IE mode" allowance) per your
   compatibility needs — **verify the exact policy name** for your version and use only if your legacy
   apps require it.

### Step 10. Scope tags, assignment, review — the baseline profile
1. Click **Next** to **Scope tags** (set if you use them), then **Next**.
2. **Assignments:** under **Included groups → Add groups**, select **`Edge for Business - Pilot Devices`**.
   Do **not** assign to "All devices" yet. Click **Next**.
3. **Review + create** → **Create**.

> Prefer automation? **`EDGEBIZ-Set-ScopeTargeting.ps1`** sets/adjusts the assignment for
> `Edge for Business - Baseline - Pilot` (defaults to **-WhatIf** — preview first, then re-run to apply),
> and **`EDGEBIZ-Remediation.ps1`** creates the baseline with the core settings if it is missing (also
> **-WhatIf** by default).

---

## Phase 2 (continued) — Make Edge the default browser

### Step 11. Create the default-browser associations profile
1. Base64-encode the default-associations XML from Step 4. On any Windows/PowerShell prompt:
   `[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\AppAssociations.xml"))` — copy the output.
2. Go to **Devices → Configuration → Create → New policy** → Platform **Windows 10 and later**,
   Profile type **Templates → Custom**. Click **Create**.
3. **Name:** **`Edge for Business - Default Browser - Pilot`**. **Description:** *Enforces Microsoft Edge as
   the default browser via DefaultAssociationsConfiguration.* Click **Next**.
4. **Configuration settings → Add** an OMA-URI row:
   - **Name:** `Default App Associations - Edge`
   - **OMA-URI:** `./Vendor/MSFT/Policy/Config/ApplicationDefaults/DefaultAssociationsConfiguration`
   - **Data type:** **String**
   - **Value:** paste the **Base64** string from step 1.
5. Click **Next** through **Scope tags**, then **Assignments** → add **`Edge for Business - Pilot
   Devices`** → **Next** → **Review + create** → **Create**.

> Once applied, `http`/`https`/`.htm`/`.html` open in Edge fleet-wide and users cannot silently change the
> default. This is reversible by unassigning the profile.

---

## Phase 2 (continued) — Apply the Microsoft Edge security baseline

### Step 12. Create the Edge security baseline instance
1. Go to **Endpoint security → Security baselines → Microsoft Edge Baseline**.
2. Click **+ Create profile**. Note the **baseline version** offered (record it for change control).
3. **Basics → Name:** **`Edge for Business - Security Baseline - Pilot`**. Click **Next**.
4. **Configuration settings:** accept the Microsoft-recommended defaults for the first pilot (you can
   customize later). Review the settings so you know which ones overlap your Settings Catalog baseline
   (Best Practices — conflicts). Click **Next**.
5. **Scope tags** → **Next**. **Assignments:** add **`Edge for Business - Pilot Devices`** → **Next**.
6. **Review + create** → **Create**.

> **Conflict awareness:** if the same policy is set by both `Edge for Business - Baseline - Pilot` and
> `Edge for Business - Security Baseline - Pilot`, make the values agree. A mismatch shows as a **conflict**
> in Device status. See Troubleshooting.

---

## Phase 3 — Pilot

### Step 13. Sync and confirm the profiles land
1. On the pilot device, force a sync: **Settings → Accounts → Access work or school → (your account) →
   Info → Sync**, or Company Portal → **Check status**.
2. In Intune, confirm each object reports success against the pilot device:
   - **Devices → Configuration → `Edge for Business - Baseline - Pilot` → Device status** → **Succeeded**.
   - **Devices → Configuration → `Edge for Business - Default Browser - Pilot` → Device status** →
     **Succeeded**.
   - **Endpoint security → Security baselines → `Edge for Business - Security Baseline - Pilot` → Device
     status** → **Succeeded**.

### Step 14. Confirm the policies on the device
1. On the pilot device open **`edge://policy`** and confirm the applied policies include
   **`PasswordManagerEnabled = false`**, **`SmartScreenEnabled = true`**, the extension block/allow lists,
   the sign-in/sync settings, the IE-mode policies, and the startup/home URLs. Use **Reload policies** if
   needed.
2. Confirm Edge is the default: open a `.html` file or an `http(s)` link from outside a browser and confirm
   it opens in **Edge**.
3. Confirm IE mode: browse to one of the sites in `EdgeForBusiness-EMSiteList.xml` and confirm the **IE
   mode** indicator appears (the IE logo in the address bar) and the legacy app renders correctly.

---

## Phase 4 — Validate and expand

### Step 15. Validate with the scripts
1. Run **`EDGEBIZ-Discovery.ps1`** (tenant readiness: the baseline profile, default-browser profile, and
   Edge security baseline exist with the expected core settings).
2. Run **`EDGEBIZ-Validation.ps1`** to confirm each object is **assigned** to `Edge for Business - Pilot
   Devices` and the pilot device reports the policies **applied**.
3. Run **`EDGEBIZ-Report.ps1`** to produce a coverage report (which Windows devices have the Edge baseline
   applied).

### Step 16. Remediate gaps (safe by default)
1. If the baseline profile is missing or mis-scoped, run **`EDGEBIZ-Remediation.ps1`** — it **defaults to
   `-WhatIf`** and prints exactly what it would create/assign. Review, then re-run with `-WhatIf:$false`
   to apply.
2. To (re)point the assignment at a different group, run **`EDGEBIZ-Set-ScopeTargeting.ps1 -GroupId
   <id>`** (also **-WhatIf** by default).

### Step 17. Expand in waves
1. Once the pilot passes the Testing gate, broaden each object's assignment to the next group, or make the
   Edge baseline, default-browser profile, and security baseline the standard for all corporate Windows
   devices.
2. Grow **`EdgeForBusiness-EMSiteList.xml`** as you discover additional legacy apps, re-host it, and
   re-validate IE mode — the site-list URL policy does not change, only the file behind it.
3. Roll out in waves, validating each wave with `EDGEBIZ-Report.ps1` before widening, and keep the
   Settings Catalog and security baseline values in agreement as you go.
