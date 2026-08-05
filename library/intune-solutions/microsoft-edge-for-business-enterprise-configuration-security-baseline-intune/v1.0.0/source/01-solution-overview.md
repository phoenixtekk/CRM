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
