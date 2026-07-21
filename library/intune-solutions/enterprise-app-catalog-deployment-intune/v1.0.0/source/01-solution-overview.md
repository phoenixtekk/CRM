# 1. Solution Overview — Enterprise App Catalog Deployment in Microsoft Intune

## What the Enterprise App Catalog is
The **Enterprise App Catalog** in Microsoft Intune is a Microsoft-curated set of **prepackaged
Windows (Win32) applications**. Each catalog app arrives with its **install logic and detection
rule already built** by Microsoft, so you do not wrap the installer, write the install/uninstall
command lines, or author a detection rule yourself. On top of that, catalog apps support **update
management**, so a deployed catalog app can be kept current as new versions are published — without
re-wrapping and re-uploading a fresh `.intunewin` each time.

In short: instead of hand-building a Win32 package for a common application, you **pick it from the
catalog**, choose how it installs and who gets it, turn on update management, and roll it out
pilot-first.

> **Not the same as "Enterprise Applications" in Entra.** This solution is about the **Intune
> Enterprise App *Catalog*** — curated, prepackaged Windows *apps you deploy to devices*. It is **not**
> the Entra ID **"Enterprise applications"** blade (app registrations, service principals, API
> permissions, SSO). Those govern *identity and OAuth access for SaaS/registered apps* — a completely
> different discipline covered by a separate governance product. If you came here for app
> registrations / service-principal governance, this is the wrong product.

## How it works
1. In the **Microsoft Intune admin center**, you add a new app and choose the **Enterprise App
   Catalog app** type (exact menu label — *verify against current Microsoft documentation*).
2. You **browse or search the catalog** and select the app (and, where offered, a specific version).
   *Which applications appear in the catalog, and which versions, is defined by Microsoft and changes
   over time — always confirm the app you want is present in your tenant's catalog (verify against
   current Microsoft documentation).*
3. Microsoft's **prebuilt package** supplies the install/uninstall behavior and the **detection
   rule** — you do not author them. You confirm the **install behavior** (system vs user context) and
   other supplied settings.
4. You enable **update management** so the catalog app is kept current as Microsoft publishes new
   versions (the exact toggle name, cadence, and update behavior are *verify-with-Microsoft*).
5. You **assign** the app — **Required**, **Available** (via Company Portal), or **Uninstall** —
   targeted to a **pilot ring** first, then to the broad fleet.
6. The **Intune Management Extension (IME)** on the enrolled device downloads the content, installs
   the app in the chosen context, evaluates the built-in detection rule, and reports **Installed /
   Failed / Not applicable** back to Intune. Update management then keeps it current on its cycle.

## Where it fits (three lanes for Windows apps)
Intune gives you more than one way to get a Windows app onto a device. Choose deliberately:

| Lane | Use it when | Who builds the package |
|---|---|---|
| **Enterprise App Catalog** (this product) | The app is a **common application present in the catalog** and you want Microsoft's prebuilt package + update management, no wrapping. | **Microsoft** (curated, prepackaged) |
| **Hand-packaged Win32 (`.intunewin`)** | The app is **not in the catalog**, or you need full control of install/uninstall/detection/requirements. | **You** (Win32 Content Prep Tool) |
| **Winget / Microsoft Store apps** | The app is available via **winget / the Microsoft Store** and you prefer that source. | **Microsoft Store / winget** |

> The **winget / Microsoft Store** lane is its own solution — see the sibling product **"Winget &
> Microsoft Store App Management with Microsoft Intune"** for that path. This product does **not**
> reproduce it; it points to it so you pick the right lane. When a catalog app fails to install or
> update, use the existing break/fix product **"Intune App Deployment Troubleshooting & Failure
> Remediation (Win32/LOB/Store)"** for deep diagnostics — the Troubleshooting section here covers the
> catalog-specific first steps and hands off there.

## Benefits
- **No hand-packaging** — Microsoft supplies the package, install logic, and detection for catalog
  apps, so you skip the Content Prep Tool and detection-rule authoring for those apps.
- **Stays current** — update management keeps deployed catalog apps up to date without re-wrapping.
- **Fewer false states** — Microsoft's built-in detection rule reduces the "installed but shows
  failed" and reinstall-loop problems that come from a hand-authored detection guess.
- **Consistent process** — the same **pilot ring → validate → expand** model as every other app
  deployment, so a bad rollout hits a pilot, never the whole fleet at once.
- **Faster to deploy common apps** — pick, assign, done — for the apps that are in the catalog.

## Limitations (be honest with buyers)
- **Only apps in the catalog qualify.** If the app you need is not curated by Microsoft, you must use
  hand-packaged Win32 or the winget/Store lane instead. *The catalog's contents are defined by
  Microsoft and change — verify availability.*
- **You don't control the package internals.** Install command, detection, and packaging are
  Microsoft's; for apps needing custom install behavior, hand-packaged Win32 is the right lane.
- **Update-management behavior is Microsoft-defined.** Cadence, version pinning, and how updates are
  applied are set by the service — *verify the current behavior and options against Microsoft docs*
  before you rely on a specific update guarantee.
- **The IME must be present and healthy** on the enrolled Windows device (it installs automatically
  when a Win32/catalog app or script is assigned).
- **Licensing and feature availability may differ by cloud** (Commercial vs GCC / GCC High / DoD) —
  *verify for your tenant and national cloud.*

## The standard deployment model
> **Assess** (confirm the app is in the catalog and pick it) **→ Configure** (install behavior +
> assignment, enable update management) **→ Pilot** (assign to a pilot ring) **→ Validate** (install,
> detection, and an update all succeed) **→ Expand** (wave to the broad ring). The pilot ring is the
> gate — a bad rollout is caught before it reaches production.
