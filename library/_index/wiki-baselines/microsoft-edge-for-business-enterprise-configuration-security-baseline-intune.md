# Microsoft Edge for Business — Enterprise Configuration & Security Baseline (Intune)

> **Version 1.0.0** · Category: Intune · Solution code: EDGEBIZ

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Microsoft Edge for Business: Enterprise Configuration & Security Baseline (Intune)

Most organizations deploy Microsoft Edge and then leave it at its out-of-the-box defaults: the
built-in password manager is on and quietly competing with the corporate password vault, browser
SmartScreen and PUA protection are unmanaged, extensions install freely, sync and sign-in are
uncontrolled, and there is no Enterprise Mode Site List so legacy line-of-business web apps limp along
in a modern engine. Security assessments repeatedly surface two of these as explicit findings — the
**Edge password manager is enabled** and **Edge is not enforced as the primary browser** — but the real
exposure is broader: an unmanaged browser is the single most-used piece of software on every endpoint.

This solution turns Microsoft Edge into a **managed, hardened, standardized browser** across the Windows
fleet using **Microsoft Intune** — the **Settings Catalog → Microsoft Edge (ADMX-backed)** policies for
configuration and the **Microsoft Edge security baseline** in **Endpoint security** for the hardening
floor. It is delivered so a single administrator can follow it end to end.

**What it does, concretely:**

- **Makes Edge the default browser org-wide** via Intune (a Windows default-associations configuration),
  and configures **IE mode** with an **Enterprise Mode Site List** so legacy IE-dependent line-of-business
  apps keep working inside Edge — no second browser, no compatibility limbo.
- **Turns off the built-in password manager** (`PasswordManagerEnabled` = **Disabled**) so users are
  steered to the enterprise password solution instead of scattering credentials in the browser.
- **Applies a pragmatic security/config baseline** — SmartScreen + PUA protection on, an extension
  allow/block model that controls sideloading, sync and work-profile sign-in controls, website
  typo-protection (typosquatting), a defined update channel and cadence, and managed startup/home pages —
  then layers the **Microsoft Edge security baseline** on top as the enforced hardening floor.

Every object you create is **named once and reused** — the pilot baseline profile is
`Edge for Business - Baseline - Pilot`, assigned to the `Edge for Business - Pilot Devices` group — so
the same names carry through implementation, testing, and troubleshooting.

The package follows the standard repeatable shape — **Assess → Configure → Pilot → Validate → Expand** —
with exact, click-by-click Intune steps, a requirements guide that tells you how to **verify** *and*
**fix** each prerequisite, five ready-to-run PowerShell scripts (Microsoft Graph), and testing and
troubleshooting guides with clear pass/fail gates. Read-only discovery, validation, and reporting scripts
tell you where you stand; the remediation and targeting scripts **default to a safe preview** and change
nothing until you re-run them to apply.

**Outcome:** a browser that is default, standardized, and hardened on every Windows endpoint — the two
assessment findings resolved directly, the broader browser attack surface reduced, and legacy web apps
kept alive through IE mode — proven on a pilot before you scale, without a consulting engagement.


---


# 1. Solution Overview — Microsoft Edge for Business: Enterprise Configuration & Security Baseline (Intune)

## What this solution is
This solution configures and hardens **Microsoft Edge for Business** on **Windows** devices managed by
**Microsoft Intune**. It combines two Intune surfaces that together turn Edge from an unmanaged default
install into a **managed, standardized, hardened** browser:

- **Settings Catalog → Microsoft Edge (ADMX-backed)** — the full set of Edge browser policies
  (password manager, SmartScreen, extensions, sync/sign-in, IE mode, startup/home, update channel, and
  more), delivered as one or more configuration profiles.
- **Endpoint security → Security baselines → Microsoft Edge security baseline** — Microsoft's
  pre-hardened set of Edge settings, applied as the enforced security floor on top of your configuration.

Plus a Windows **default-application-associations** configuration that makes Edge the **default browser
org-wide**, and an **Enterprise Mode Site List** that lets legacy IE-dependent apps run in **IE mode**
inside Edge.

## Why this exists (the findings, and the bigger picture)
Two items show up as explicit findings in most browser/security assessments:

1. **The Edge built-in password manager is enabled.** Users save work credentials into the browser
   instead of the sanctioned enterprise password solution, scattering secrets and undermining the vault.
2. **Edge is not enforced as the primary browser.** Without a default-browser policy, links open in
   whatever browser a user last set, so managed-browser protections (SmartScreen, extension control,
   Conditional Access via the work profile) are inconsistently applied.

Resolving those two is the immediate win. But an unmanaged browser is the most-used app on every
endpoint, so this solution also delivers the **broader browser-hardening value**: SmartScreen + PUA,
extension sideloading control, sync/sign-in governance, typosquatting protection, a defined update
cadence, managed startup pages, and the Microsoft-authored security baseline.

## The named objects you will build (and reuse everywhere)
This solution creates a small, deliberately named set of objects. **These exact names are reused across
the Implementation, Testing, and Troubleshooting guides** — do not rename them mid-stream.

| Object | Type / where | Name used throughout |
|--------|--------------|----------------------|
| Pilot target group | Entra security group | **`Edge for Business - Pilot Devices`** |
| Edge configuration baseline | Settings Catalog (Windows, Microsoft Edge ADMX-backed) | **`Edge for Business - Baseline - Pilot`** |
| Default-browser associations | Windows config profile (default app associations) | **`Edge for Business - Default Browser - Pilot`** |
| Microsoft Edge security baseline | Endpoint security → Security baselines | **`Edge for Business - Security Baseline - Pilot`** |
| Enterprise Mode Site List file | XML hosted at an internal URL | **`EdgeForBusiness-EMSiteList.xml`** |

> **One baseline profile, or several?** The Settings Catalog lets you put every Edge setting in one
> profile. This guide keeps **all browser policy in `Edge for Business - Baseline - Pilot`** for
> simplicity and treats the **default-browser associations** and the **Microsoft Edge security baseline**
> as their own objects because they live on different Intune surfaces. Split the Settings Catalog profile
> later only if your change-control process needs finer ownership.

## What the baseline configures
`Edge for Business - Baseline - Pilot` sets the following (each is detailed click-by-click in the
Implementation guide, with the Edge policy name and its underlying policy CSP key where confident;
anything version-sensitive is flagged **verify in your tenant**):

- **Password manager OFF** — `PasswordManagerEnabled` = **Disabled**. Steers users to the enterprise
  password solution.
- **SmartScreen + PUA** — Microsoft Defender SmartScreen **Enabled** (`SmartScreenEnabled`), block
  potentially unwanted apps **Enabled** (`SmartScreenPuaEnabled`), and prevent users bypassing SmartScreen
  warnings (`PreventSmartScreenPromptOverride`, `PreventSmartScreenPromptOverrideForFiles`).
- **Extension control (sideloading)** — block-all-then-allow model using `ExtensionInstallBlocklist`
  (`*`), `ExtensionInstallAllowlist` (approved extension IDs), optional `ExtensionInstallForcelist`
  (auto-deploy), and `BlockExternalExtensions` = **Enabled** to stop out-of-store sideloading.
- **Sync & work-profile sign-in** — `BrowserSignin` (force sign-in with the work account),
  `SyncDisabled` to control what syncs to Microsoft consumer sync. This is how you get a governed **work
  profile** rather than a personal one.
- **Website typo protection (typosquatting)** — `TyposquattingCheckerEnabled` = **Enabled** (Edge
  "Website typo protection"; a newer policy — **verify availability** for your Edge version).
- **Update channel & cadence** — the **Microsoft Edge Update** ADMX policies (target channel, e.g.
  **Stable**, and auto-update check cadence) so the fleet stays on a known, patched channel.
- **Startup & home pages** — `RestoreOnStartup` / `RestoreOnStartupURLs`, `HomepageLocation`, and
  `NewTabPageLocation` so Edge opens to your portal rather than an arbitrary page.
- **IE mode + Enterprise Mode Site List** — `InternetExplorerIntegrationLevel` = **Internet Explorer
  mode** and `InternetExplorerIntegrationSiteList` pointed at `EdgeForBusiness-EMSiteList.xml`, so listed
  legacy sites render in the Trident (IE) engine inside Edge.

## How default-browser enforcement works on Windows via Intune
Windows does not expose a single "make Edge default" switch to MDM. The supported, fleet-wide method is a
**default application associations** configuration: you export a default-associations XML (which maps
`http`, `https`, `.htm`, `.html`, `.pdf`, etc. to Edge), then deliver it through Intune using the
`ApplicationDefaults/DefaultAssociationsConfiguration` policy CSP. Once applied, those file/URL types open
in Edge and users cannot silently change them. The Implementation guide gives the exact export → encode →
deploy steps in the profile named `Edge for Business - Default Browser - Pilot`.

> **Honest limitation.** Default-associations enforcement applies at user profile creation / policy
> refresh and is a fleet default, not a per-click lock. Communicate the change; it is reversible by
> removing the profile.

## How IE mode works (for legacy line-of-business apps)
**IE mode** renders specific sites using the Internet Explorer (Trident) engine *inside* Edge, so legacy
web apps that require IE keep working after IE itself is retired. You control which sites use IE mode with
an **Enterprise Mode Site List** — an XML file (authored in the free **Enterprise Mode Site List
Manager**) that lists each legacy URL and the engine to use. You host that XML at an internal URL and
point Edge at it with the `InternetExplorerIntegrationSiteList` policy. Only listed sites use IE mode;
everything else uses the modern engine.

## The Microsoft Edge security baseline (the hardening floor)
Intune's **Endpoint security → Security baselines → Microsoft Edge security baseline** is a
Microsoft-curated, versioned set of recommended Edge security settings. Applied as
`Edge for Business - Security Baseline - Pilot`, it enforces a known-good floor. Where a baseline setting
and your Settings Catalog profile both set the same policy, **plan for the interaction** (see Best
Practices — conflicts) so they agree rather than fight.

## Benefits
- **Two findings resolved directly** — password manager off; Edge enforced as the default browser.
- **Reduced browser attack surface** — SmartScreen/PUA, extension sideloading control, and the Microsoft
  security baseline harden the most-used app on every endpoint.
- **Legacy apps preserved** — IE mode + Enterprise Mode Site List keep IE-dependent line-of-business apps
  alive without a second browser.
- **Standardized experience** — every managed Windows device gets the same governed Edge: same startup,
  same work-profile sign-in, same update channel.
- **Pilot-first and reversible** — everything deploys as Intune profiles to a pilot group first and is
  removed by unassignment; no re-imaging.

## Limitations (be honest with buyers)
- **Windows-focused.** This solution targets **Microsoft Edge on Windows** via Intune. macOS/iOS/Android
  Edge management uses different surfaces and is out of scope here.
- **Policy names drift.** Edge ships new policies frequently and Microsoft occasionally renames settings.
  Every policy is given with its Edge name and CSP key where confident, and version-sensitive items are
  flagged **verify in your tenant** — do not assume, confirm in the Settings Catalog for your Edge version.
- **Default-browser enforcement is a fleet default**, not a per-action lock (see above).
- **IE mode depends on a maintained site list.** IE mode only helps for sites you add to
  `EdgeForBusiness-EMSiteList.xml`; the list is a living document you must keep current.
- **Security baseline versioning.** Microsoft periodically releases new baseline versions; you must review
  and migrate to new versions deliberately rather than auto-adopting.

## The standard deployment model
This solution uses **one** repeatable model across our catalog:

> **Windows devices receive a named Microsoft Edge configuration baseline (Settings Catalog, ADMX-backed),
> a default-browser associations profile, and the Microsoft Edge security baseline — plus an Enterprise
> Mode Site List for IE mode — deployed pilot-first to `Edge for Business - Pilot Devices` and reversible
> by unassignment.**

Every step follows the repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**


---


# 2. Requirements — Microsoft Edge for Business: Enterprise Configuration & Security Baseline (Intune)

Confirm **every** requirement below before you begin. Each entry follows the same pattern:
**Description · Why required · How to verify · How to implement if missing.** Category-wide prerequisites
(tenant, Intune licensing, admin roles, device enrollment, pilot group, supported Windows baseline,
network) are covered once in the **Global Requirements — Intune Solutions** document; the items here are
specific to configuring and hardening **Microsoft Edge for Business on Windows** via Intune.

> **Scope reminder.** These requirements are for **Microsoft Edge on Windows** managed by Intune —
> Settings Catalog (Microsoft Edge ADMX-backed) configuration plus the Microsoft Edge security baseline,
> default-browser enforcement, and IE mode. macOS/iOS/Android Edge management is out of scope.

## R1. Microsoft Edge (Chromium) installed on target Windows devices
**Description:** A current channel of **Microsoft Edge for Business** (the Chromium-based Edge) is
installed on the target Windows devices.
**Why:** Policies and the security baseline apply to the installed browser; ADMX-backed settings only take
effect where Edge is present.
**Verify:** On a device, open `edge://version` (shows the version and channel); or Intune →
**Apps → Windows** to confirm any managed Edge deployment. On Windows 11 and current Windows 10, Edge is
in-box.
**Implement:** Edge ships in-box with supported Windows. If you manage the channel explicitly, deploy
**Microsoft Edge for Business (Stable)** from Intune → **Apps → Windows → Add → Microsoft Edge for
Business**, or rely on the in-box browser and manage its channel with the **Microsoft Edge Update**
policies (Implementation, Step 8).

## R2. Edge policies visible in the Intune Settings Catalog
**Description:** The **Microsoft Edge** ADMX-backed policy category is available in Intune's **Settings
Catalog**.
**Why:** This solution configures Edge through the Settings Catalog (not a legacy custom ADMX import).
**Verify:** Intune (`https://intune.microsoft.com`) → **Devices → Configuration → Create → New policy** →
Platform **Windows 10 and later**, Profile type **Settings catalog** → **Add settings** → search
**Microsoft Edge**; you should see the **Microsoft Edge** and **Microsoft Edge Update** setting groups.
**Implement:** The Edge settings are built in; no import is needed. If a specific setting is missing, your
Edge/Settings-Catalog version may predate it — **verify the exact policy name** for your version and use
the equivalent, or import the Edge ADMX as a fallback.

## R3. Enterprise password solution in place (for the password-manager finding)
**Description:** A sanctioned enterprise password solution (corporate password manager / vault) users can
use instead of the Edge built-in password manager.
**Why:** Turning off `PasswordManagerEnabled` steers users **to** the enterprise solution; disabling the
browser manager without an alternative causes support tickets.
**Verify:** Confirm the organization's approved password manager is deployed/available to the pilot users.
**Implement:** Deploy or confirm the enterprise password solution and brief users before enabling the
policy. (Selecting or deploying that product is out of scope for this solution.)

## R4. Enterprise Mode Site List authored (for IE mode)
**Description:** An **Enterprise Mode Site List** XML (`EdgeForBusiness-EMSiteList.xml`) listing the
legacy line-of-business URLs that must render in **IE mode**.
**Why:** IE mode only applies to sites in this list; without it, `InternetExplorerIntegrationLevel` has
nothing to act on.
**Verify:** You have a valid site-list XML (schema version 2), and it is (or will be) reachable at an
internal URL the devices can reach.
**Implement:** Author it with the free **Enterprise Mode Site List Manager** (add each legacy site with
open-in = **IE11** / engine = IE mode), export the XML as `EdgeForBusiness-EMSiteList.xml`, and host it at
an internal HTTPS URL (or a `file://` share) reachable by the pilot devices. Only the sites you list use
IE mode. **Start with a short, verified list.**

## R5. Default application associations XML (for default-browser enforcement)
**Description:** A Windows **default associations** XML that maps `http`, `https`, `.htm`, `.html` (and
optionally `.pdf`, `.svg`) to Microsoft Edge.
**Why:** Fleet-wide default-browser enforcement on Windows via Intune uses the
`ApplicationDefaults/DefaultAssociationsConfiguration` policy CSP, which takes this XML.
**Verify:** You have an `AppAssociations.xml` produced from a reference device where Edge is already the
default for the relevant types.
**Implement:** On a reference Windows device with Edge set as default, run (elevated)
`dism /online /Export-DefaultAppAssociations:C:\AppAssociations.xml`, then keep only the http/https/html
(and any additional) entries you want to enforce. This XML is deployed in
`Edge for Business - Default Browser - Pilot` (Implementation, Phase 2).

## R6. Microsoft Edge security baseline available in Endpoint security
**Description:** The **Microsoft Edge security baseline** is available under **Endpoint security →
Security baselines**.
**Why:** It is the enforced hardening floor applied as `Edge for Business - Security Baseline - Pilot`.
**Verify:** Intune → **Endpoint security → Security baselines**; a **Microsoft Edge Baseline** entry with a
version is listed.
**Implement:** It is provided by Intune; no import needed. Note the **baseline version** shown — you will
reference it in change control (Best Practices).

## R7. Windows devices enrolled and in scope
**Description:** The target Windows devices are Intune-enrolled and manageable (Global Requirement G4).
**Why:** Configuration profiles and baselines only reach enrolled devices.
**Verify:** Intune → **Devices → Windows → Windows devices**; the pilot device is listed and **compliant**.
**Implement:** Enroll via Entra join + automatic enrollment, or Autopilot (covered by the enrollment
solutions).

## R8. Pilot target group
**Description:** An Entra security group named **`Edge for Business - Pilot Devices`** containing the pilot
device(s) or user(s).
**Why:** Every solution is piloted before fleet rollout; all four objects assign to this group first.
**Why:** Consistent naming keeps the assignment, testing, and reporting steps unambiguous.
**Verify:** Entra → **Groups**; `Edge for Business - Pilot Devices` exists and contains the pilot members.
**Implement:** Entra → **Groups → New group → Security**, name it **`Edge for Business - Pilot Devices`**,
add the pilot device(s)/user(s). (This is the solution-specific instance of Global Requirement G5.)

## R9. Internal hosting reachable for the site list (IE mode)
**Description:** The devices can reach the URL that hosts `EdgeForBusiness-EMSiteList.xml`.
**Why:** Edge fetches the site list from `InternetExplorerIntegrationSiteList`; an unreachable URL means
IE mode never applies.
**Verify:** From a pilot device, browse to the site-list URL and confirm the XML loads.
**Implement:** Host the XML on an internal web server / SharePoint / file share reachable by the fleet, and
allow it through any proxy. Use HTTPS where possible.

## R10. Change-control awareness for browser policy
**Description:** Acknowledgement that browser policy changes affect every user's daily tool, and a plan to
communicate them.
**Why:** Disabling the password manager, forcing a default browser, and controlling extensions are
user-visible; unannounced changes generate tickets.
**Verify:** You have a comms plan and a rollback owner for the pilot.
**Implement:** Draft a short user notice (what changes, when, why, where to store passwords now), and keep
the rollback plan (unassign the profiles) documented before you pilot.


---


# Global Requirements — Intune Solutions (category-level)

These requirements apply to **every** solution in the **Intune Solutions**
category. They are published once at the category level so individual listings stay small.
Confirm these before deploying *any* Intune solution. Each entry: **Description · Why · Verify · Implement-if-missing.**

## G1. Microsoft Entra ID tenant
**Description:** An active Microsoft Entra ID (Azure AD) tenant.
**Why:** It is the identity backbone for every cloud and Intune-managed resource.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create a Microsoft 365/Azure subscription, which provisions a tenant.

## G2. Microsoft Intune subscription
**Description:** An Intune-bearing license plan.
**Why:** Intune delivers all configuration, compliance, and security policies.
**Verify:** `https://intune.microsoft.com` loads; **Tenant administration → Tenant status** shows active.
**Implement:** Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1.

## G3. Administrative roles
**Description:** Appropriate Entra/Intune admin roles for the operator.
**Why:** Creating policies and enrollment settings requires elevated rights.
**Verify:** Entra → **Roles and administrators**; confirm **Intune Administrator**.
**Implement:** Assign **Intune Administrator**; reserve Global Administrator for tenant-wide changes.

## G4. Device enrollment in Intune
**Description:** Targeted Windows devices are enrolled and manageable.
**Why:** Policies only reach enrolled devices.
**Verify:** Intune → **Devices → All devices**; the device appears and is **compliant**.
**Implement:** Enable **Automatic Enrollment** and join devices to Entra ID.

## G5. Pilot security group
**Description:** A Microsoft Entra security group for pilot/targeted users or devices.
**Why:** Every solution is piloted before fleet rollout.
**Verify:** Entra → **Groups**; the pilot group exists.
**Implement:** Entra → **Groups → New group** → **Security** → add members.

## G6. Supported Windows baseline
**Description:** Windows 10 21H2+ or Windows 11 with current updates.
**Why:** Modern Intune features assume a patched, supported OS.
**Verify:** `winver`, or Intune → device → **Hardware**.
**Implement:** Deploy **Update rings** or upgrade to Windows 11.

## G7. Network access to Microsoft cloud endpoints
**Description:** Outbound HTTPS to Microsoft 365, Entra, and Intune service URLs.
**Why:** Enrollment, policy sync, and authentication depend on these endpoints.
**Verify:** From a device, reach `https://login.microsoftonline.com` and `https://enrollment.manage.microsoft.com`.
**Implement:** Allow Microsoft's published Office 365/Intune URL & IP ranges through proxy/firewall.

---
**The standard deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


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


---


# 5. Testing & Validation — Microsoft Edge for Business Enterprise Configuration & Security Baseline

Validate against a **pilot device** in **`Edge for Business - Pilot Devices`** before expanding. Each test
has an explicit **pass/fail gate**. Use the included PowerShell scripts (Microsoft Graph) for tenant-side
checks and the on-device steps for the user experience.

> **What "pass" means here:** on a managed Windows device, Edge is the **default browser**, the built-in
> **password manager is off**, the **security/config baseline** (SmartScreen/PUA, extensions, sync/sign-in,
> typosquatting, startup) is applied, the **Microsoft Edge security baseline** reports Succeeded, and
> listed legacy sites open in **IE mode**.

## Test 1 — Tenant readiness
**Procedure:** Run `EDGEBIZ-Discovery.ps1`.
**Pass:** The **`Edge for Business - Baseline - Pilot`** Settings Catalog profile exists with
`PasswordManagerEnabled = disabled` and SmartScreen enabled; the **`Edge for Business - Default Browser -
Pilot`** custom profile exists; the **`Edge for Business - Security Baseline - Pilot`** Edge security
baseline exists.
**Fail:** Any of the three objects missing, or the baseline lacks the password-manager/SmartScreen
settings → create/fix before piloting (Implementation Steps 5–12 / `EDGEBIZ-Remediation.ps1`).

## Test 2 — Assignment
**Procedure:** Run `EDGEBIZ-Validation.ps1` (or check each object's **Assignments** tab).
**Pass:** All three objects are assigned to **`Edge for Business - Pilot Devices`** and to no unintended
broad group.
**Fail:** Not assigned, or assigned to "All devices" prematurely → correct with Implementation Step 10/11/12
or `EDGEBIZ-Set-ScopeTargeting.ps1`.

## Test 3 — Profiles applied on the device
**Procedure:** Intune → Device status for each object; and on the device open **`edge://policy`**.
**Pass:** `Edge for Business - Baseline - Pilot`, `Edge for Business - Default Browser - Pilot`, and
`Edge for Business - Security Baseline - Pilot` all show **Succeeded**; `edge://policy` lists the expected
policies.
**Fail:** Not applied / error → force a sync and re-check; if it shows **Conflict**, resolve the
overlapping setting (Troubleshooting).

## Test 4 — Password manager is off (Finding #1)
**Procedure:** On the device, open `edge://policy` and confirm **`PasswordManagerEnabled = false`**; then in
Edge go to **Settings → Profiles → Passwords** and attempt to enable "Offer to save passwords".
**Pass:** `PasswordManagerEnabled` shows **false**; the "Offer to save passwords" toggle is **managed/greyed
out (off)** and Edge does not prompt to save a password on a test sign-in.
**Fail:** Toggle still user-controllable or Edge prompts to save → confirm the setting value and that the
baseline applied (Test 3).

## Test 5 — Edge is the default browser (Finding #2)
**Procedure:** From outside a browser (e.g. a link in Notepad or an email client) open an `https://` link
and open a local `.html` file.
**Pass:** Both open in **Microsoft Edge**; **Settings → Apps → Default apps** shows Edge for the web/HTML
associations and they are **managed** (not freely changeable).
**Fail:** Opens in another browser, or the default is user-changeable → verify the Base64
`DefaultAssociationsConfiguration` value and that `Edge for Business - Default Browser - Pilot` applied.

## Test 6 — Security/config baseline behaves
**Procedure:** Confirm the hardening settings: SmartScreen blocks a known test-warning page; try to install
an extension outside the allow-list; confirm the browser opens to the configured **startup/home** page and
the **work-profile sign-in** behavior matches policy.
**Pass:** SmartScreen warns as configured (and cannot be bypassed where set); a non-allow-listed extension
is **blocked**; startup/home pages match; sign-in/work-profile behaves per `BrowserSignin`.
**Fail:** Any control not behaving → check the specific policy in `edge://policy` and its value in the
baseline profile (Implementation Step 7).

## Test 7 — IE mode renders a legacy site
**Procedure:** Browse to a site listed in `EdgeForBusiness-EMSiteList.xml`.
**Pass:** The **IE mode indicator** (IE logo) appears in the address bar and the legacy app renders/works;
a site **not** on the list uses the modern engine.
**Fail:** No IE-mode indicator → confirm `InternetExplorerIntegrationLevel = IEMode`, that the site-list URL
is reachable (R9), and that the site is actually in the list.

## Test 8 — Microsoft Edge security baseline applied
**Procedure:** Run `EDGEBIZ-Report.ps1`, and check **Endpoint security → Security baselines →
`Edge for Business - Security Baseline - Pilot` → Device status**.
**Pass:** The pilot device reports the Edge security baseline **Succeeded**; the coverage report lists it as
applied.
**Fail:** Missing/error/conflict → resolve overlapping settings between the security baseline and the
Settings Catalog baseline so they agree (Best Practices — conflicts).

## Test 9 — No unintended breakage (negative test)
**Procedure:** With a real pilot user, use Edge for a normal workday: internal apps, SSO/sign-in, an
IE-mode app, and saving a password (should route to the enterprise solution, not the browser).
**Pass:** Normal browsing works; the only *intended* changes are visible (no browser password save, Edge is
default, extensions controlled); no legacy app is broken that IE mode should cover.
**Fail:** A legacy app breaks → add it to `EdgeForBusiness-EMSiteList.xml`; unexpected block → adjust the
specific policy.

## Test 10 — Coverage report
**Procedure:** Run `EDGEBIZ-Report.ps1`.
**Pass:** The report lists the pilot device(s) as **baseline applied**; counts match the assigned group.
**Fail:** Devices missing → run `EDGEBIZ-Remediation.ps1` (`-WhatIf` first) to fix assignment/scoping and
re-sync.

## Acceptance gate
Proceed to **Expand** only when Tests 1–8 and Test 10 pass on at least one pilot device, Test 9 confirms no
unintended breakage, and a real pilot user confirms the two findings are resolved (no browser password save;
Edge is the default) and that IE-mode legacy apps still work.


---


# 6. Troubleshooting — Microsoft Edge for Business Enterprise Configuration & Security Baseline

Work top-down: confirm the **profiles applied** (Intune Device status + `edge://policy` on the device),
then check **conflicts** between the Settings Catalog baseline and the Edge security baseline, then the
**specific policy** in question. Most issues are an unassigned/unsynced device, a policy-name mismatch for
your Edge version, or two objects setting the same policy to different values. Each symptom below gives the
**likely cause** and the **fix**.

> **Before you start:** open **`edge://policy`** on the affected device — it shows exactly which Edge
> policies applied and their values. This is faster ground truth than Intune reporting, which can lag.

## Symptom: A profile never appears / policies not in `edge://policy`
**Likely cause:** Device not synced, not assigned, or not enrolled.
**Fix:**
1. Confirm the device is in **`Edge for Business - Pilot Devices`** and each object is **assigned**
   (`EDGEBIZ-Validation.ps1`).
2. Force a sync (**Settings → Accounts → Access work or school → Sync**, or Company Portal → **Check
   status**).
3. Check **Devices → Configuration → (profile) → Device status** (and **Endpoint security → Security
   baselines → …** for the baseline) for an error.
4. On the device, open `edge://policy` and click **Reload policies**.

## Symptom: Device status shows "Conflict"
**Likely cause:** The same Edge policy is set to **different values** by `Edge for Business - Baseline -
Pilot` and `Edge for Business - Security Baseline - Pilot` (or a duplicate profile).
**Fix:**
1. Run `EDGEBIZ-Discovery.ps1` to list the Edge configuration objects.
2. Identify the overlapping setting (e.g. SmartScreen) and make the values **agree**, or unset it in one
   object so a single owner remains (Best Practices — conflicts).
3. Remove any duplicate Edge profile targeting the same device.

## Symptom: Edge still offers to save passwords (Finding #1 not resolved)
**Likely cause:** `PasswordManagerEnabled` not applied, or set to Enabled somewhere.
**Fix:**
1. In `edge://policy`, confirm **`PasswordManagerEnabled = false`**. If absent, the baseline did not apply
   (see the first symptom).
2. Confirm no other profile / security baseline sets `PasswordManagerEnabled = true` (conflict).
3. Confirm the setting in `Edge for Business - Baseline - Pilot` is **Disabled** (Implementation Step 6),
   then re-sync.

## Symptom: Edge is not the default browser (Finding #2 not resolved)
**Likely cause:** The `DefaultAssociationsConfiguration` value is wrong/empty, or the associations XML does
not point at Edge.
**Fix:**
1. Confirm `Edge for Business - Default Browser - Pilot` shows **Succeeded** in Device status.
2. Re-check the **Base64** value in the custom OMA-URI row — decode it and confirm the XML maps
   `http`/`https`/`.htm`/`.html` to an Edge ProgId (e.g. `MSEdgeHTM`).
3. Rebuild the XML from a reference device where Edge is default (Implementation Step 4), re-encode, update
   the profile, and re-sync. Note associations apply at policy refresh / profile creation.

## Symptom: A legacy site does not open in IE mode
**Likely cause:** IE mode not enabled, the site not in the list, or the site-list URL unreachable.
**Fix:**
1. In `edge://policy`, confirm **`InternetExplorerIntegrationLevel`** = IE mode and
   **`InternetExplorerIntegrationSiteList`** points at your `EdgeForBusiness-EMSiteList.xml` URL.
2. From the device, browse to the **site-list URL** and confirm the XML loads (R9). Fix hosting/proxy if it
   does not.
3. Confirm the exact site URL is in `EdgeForBusiness-EMSiteList.xml` with **Open in = IE11**; check
   `edge://compat/enterprise` to see the parsed site list on the device.

## Symptom: An approved extension is blocked (or a bad one installs)
**Likely cause:** Allow-list missing the extension ID, or block-list not set to `*`.
**Fix:**
1. Confirm **`ExtensionInstallBlocklist`** contains **`*`** and the approved extension **ID** is in
   **`ExtensionInstallAllowlist`** (Implementation Step 7). Extension IDs are case-sensitive — copy from
   `edge://extensions`.
2. If out-of-store extensions still install, confirm **`BlockExternalExtensions = Enabled`**.
3. Re-sync and re-check `edge://policy`.

## Symptom: A policy from the guide is not in the Settings Catalog
**Likely cause:** Your Edge / Settings-Catalog version predates that policy, or Microsoft renamed it.
**Fix:**
1. Confirm the pilot device's Edge version (`edge://version`). Newer policies (e.g.
   `TyposquattingCheckerEnabled`) require a recent Edge.
2. Search the Settings Catalog for the **current** name; if renamed, use the equivalent and note it.
3. If truly unavailable, skip that single setting and document it — do not block the rest of the baseline.

## Symptom: The Microsoft Edge security baseline shows "Error"/"Not applicable"
**Likely cause:** Device not fully enrolled/compliant, or a baseline-version/setting not applicable to the
device's Edge/Windows version.
**Fix:**
1. Confirm the device is enrolled and compliant (R7, G4) and synced.
2. Check the baseline **version** — if you created it on an older version, review and consider migrating to
   the current version (Best Practices — change control).
3. Reconcile any setting the baseline reports can't apply against the device's Edge/Windows level.

## Symptom: Works for some devices, not others
**Likely cause:** Group membership, sync timing, or Edge version differences.
**Fix:**
1. Confirm affected devices are in the assigned group (`EDGEBIZ-Report.ps1`).
2. Re-sync stragglers; confirm enrollment (R7).
3. Confirm the affected devices run an Edge version that supports the missing policy (`edge://version`).

## Symptom: Coverage report shows fewer devices than the group
**Likely cause:** Some devices not synced, not enrolled, or on an unsupported Edge/Windows level.
**Fix:**
1. Run `EDGEBIZ-Report.ps1` to list which devices lack the applied baseline.
2. Run `EDGEBIZ-Remediation.ps1` **(`-WhatIf` first)** to correct assignment/scoping.
3. Re-sync stragglers and confirm enrollment (R7) and Edge version (R1).

## Escalation checklist
Before opening a Microsoft support case, collect: the `EDGEBIZ-Discovery.ps1` output, each object's Device
status export, the on-device `edge://policy` export, `edge://version` and `edge://compat/enterprise`
output, the exact policy name/value in dispute, the assignment groups, and whether the issue reproduces on
a freshly synced device (isolates policy from device state).


---


# 7. Best Practices — Microsoft Edge for Business Enterprise Configuration & Security Baseline

These practices keep the managed Edge configuration precise, predictable, and reversible on corporate
Windows devices. They assume the deployment model in the Solution Overview: a named Settings Catalog
baseline (`Edge for Business - Baseline - Pilot`), a default-browser associations profile
(`Edge for Business - Default Browser - Pilot`), and the Microsoft Edge security baseline
(`Edge for Business - Security Baseline - Pilot`), deployed via Intune, pilot-first.

## Resolve Settings Catalog ↔ security baseline conflicts deliberately
- **Decide who owns each overlapping setting.** SmartScreen, extension controls, and password-manager
  settings can be set by *both* the Settings Catalog baseline and the Microsoft Edge security baseline. If
  both set the same policy to **different** values, the device reports a **conflict** and the setting may
  not apply. Choose one owner per setting and make the other agree (or leave it unset there).
- **Prefer the security baseline for the hardening floor, the Settings Catalog for org specifics.** Let
  the Edge security baseline carry Microsoft's recommended hardening; use `Edge for Business - Baseline -
  Pilot` for organization-specific choices (startup pages, IE mode, extension allow-list, update channel).
- **Document the ownership map.** Keep a short table of "setting → which object sets it → value" so the
  next admin does not reintroduce a conflict.

## Password manager: pair the "off" with an alternative
- **Never disable the browser password manager without the enterprise solution in place** (R3). Turning off
  `PasswordManagerEnabled` is only half the change; users need somewhere sanctioned to store credentials, or
  you generate tickets and shadow IT.
- **Communicate before you enforce.** A one-line notice ("Edge will no longer save passwords; use
  <enterprise vault>") prevents most confusion.

## Extension control: block-all, then allow
- **Start from `ExtensionInstallBlocklist = *` and allow-list explicitly.** A block-everything default with a
  short `ExtensionInstallAllowlist` is far safer than trying to enumerate bad extensions. Add
  `BlockExternalExtensions = Enabled` to stop out-of-store sideloading.
- **Record every allow-listed extension ID** (extension → ID → why approved) so the list stays auditable.
- **Use `ExtensionInstallForcelist` sparingly** — only for extensions the org genuinely wants everywhere.

## Default browser: enforce, but set expectations
- **Enforce with `DefaultAssociationsConfiguration`**, and know it is a **fleet default** applied at policy
  refresh, not a per-click lock. Communicate the change and keep the associations XML minimal (browser/HTML
  types only) so you do not accidentally reassign unrelated file types.
- **Rebuild the XML from a clean reference device** whenever Windows/Edge progIDs change across major
  releases, and re-deploy.

## IE mode: keep the site list short, current, and reachable
- **List only what genuinely needs IE**, with `Open in = IE11`. Every site you add is a legacy dependency
  you are choosing to keep alive — treat the list as a retirement backlog, not a dumping ground.
- **Host the site list reliably** (R9) and monitor that the URL stays reachable; an unreachable list
  silently disables IE mode.
- **Version the site list.** The policy points at a stable URL; change the file behind it and note the date
  and reason for each addition/removal.

## Sync & work-profile sign-in
- **Choose your sign-in posture explicitly.** `BrowserSignin = Force` gives a governed work profile and is
  the cleanest for Conditional Access; `Enable` leaves it optional. Decide once and apply consistently.
- **Be intentional about sync.** `SyncDisabled = Enabled` stops consumer sync of browser data; if you use
  Edge enterprise sync, leave it unmanaged and govern via profile instead. Do not half-configure both.

## Update channel & cadence
- **Pin the fleet to a supported channel (usually Stable)** with the Microsoft Edge Update policies, and set
  a predictable auto-update cadence so security fixes land without manual effort. Review after major Edge
  releases.

## Deploy pilot-first and reversibly
- **Assign every object to `Edge for Business - Pilot Devices`, never "All devices" first.** Expand in waves
  after each gate passes.
- **Rollback is unassignment.** Because these are Intune profiles/baselines, removing the assignment reverts
  behavior; keep the objects so you can re-target quickly.

## Operate and monitor
- **Report before you widen.** Run `EDGEBIZ-Report.ps1` each wave; only broaden when coverage matches the
  assigned group.
- **Remediate with `-WhatIf` first.** `EDGEBIZ-Remediation.ps1` and `EDGEBIZ-Set-ScopeTargeting.ps1` preview
  by default — read the plan, then apply.
- **Verify policy on the device with `edge://policy`.** It is the fastest ground truth for what actually
  applied, independent of Intune's reporting lag.

## Change control
- **Version the security baseline migration.** Microsoft periodically releases new **Edge security baseline
  versions** — review the diff and migrate `Edge for Business - Security Baseline - Pilot` deliberately
  rather than auto-adopting.
- **Confirm policy names after Edge upgrades.** Edge adds/renames policies frequently. After a major Edge
  release, re-run Discovery and spot-check `edge://policy` before expanding.


---


# 8. Deliverables Summary — Microsoft Edge for Business Enterprise Configuration & Security Baseline

Everything included in this solution package, and what each piece is for.

## Documentation (this guide)
- **Executive Summary** — the business case and outcome in one page: the two assessment findings resolved
  (password manager off; Edge enforced as default) plus the broader browser-hardening value.
- **Solution Overview** — the two Intune surfaces used (Settings Catalog Microsoft Edge ADMX-backed +
  Endpoint security Microsoft Edge security baseline), how default-browser enforcement and IE mode work,
  and the named objects you build and reuse.
- **Requirements Guide** — every Intune/Entra/Edge prerequisite with how to **verify** and how to
  **implement if missing**, plus the category-level Global Requirements.
- **Implementation Guide** — exact, ordered, click-by-click steps across four phases: assess and prepare
  (site list + associations XML), configure the named Settings Catalog baseline (password manager off,
  SmartScreen/PUA, extensions, sync/sign-in, typosquatting, startup, update channel, IE mode), enforce the
  default browser, apply the Microsoft Edge security baseline, pilot, then validate and expand.
- **Testing & Validation** — ten tests with explicit pass/fail gates (including confirming both findings
  are resolved and a negative test for unintended breakage) and an acceptance gate.
- **Troubleshooting** — top-down diagnosis using `edge://policy`: profiles not applying, conflicts, the two
  findings, IE mode, extension control, and missing/renamed policies.
- **Best Practices** — resolving Settings-Catalog ↔ security-baseline conflicts, block-all-then-allow
  extensions, IE-mode site-list hygiene, sign-in/sync posture, update cadence, and reversible pilot-first
  rollout.

## PowerShell scripts (Microsoft Graph) — `EDGEBIZ-Scripts.zip`
All scripts are tenant-side (run from an admin workstation with the Microsoft Graph PowerShell SDK); each
has a header explaining **Purpose · How to run · Expected results**. Discovery, Validation, and Report are
**read-only**; Remediation and Set-ScopeTargeting **default to `-WhatIf`** (preview first, then apply).

1. **`EDGEBIZ-Discovery.ps1`** — tenant readiness: the `Edge for Business - Baseline - Pilot` Settings
   Catalog profile exists with the core settings (`PasswordManagerEnabled = disabled`, SmartScreen), the
   `Edge for Business - Default Browser - Pilot` custom profile exists, and the Microsoft Edge security
   baseline is created.
2. **`EDGEBIZ-Validation.ps1`** — validates each object's **assignment** and per-device **applied** state,
   with a clear PASS/FAIL summary.
3. **`EDGEBIZ-Report.ps1`** — tenant-wide CSV report of Windows devices and whether the Edge configuration
   baseline is applied — the Edge coverage report.
4. **`EDGEBIZ-Remediation.ps1`** — safe remediation: creates the Settings Catalog Edge baseline with the
   core settings if missing and assigns it to a target group. **`-WhatIf` by default**; applies only when
   re-run with `-WhatIf:$false`.
5. **`EDGEBIZ-Set-ScopeTargeting.ps1`** — sets/adjusts the baseline profile's group assignment (target-group
   builder). **`-WhatIf` by default.**

## Hero image
- **`EDGEBIZ-hero.png`** — the product image used on the marketplace listing.

## How it's delivered
A **Word** document and **PDF** (cover, table of contents, page numbers, and a scripts appendix), plus all
five PowerShell scripts in a single **ZIP** — yours to keep and reuse across **unlimited devices**.
