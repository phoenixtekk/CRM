# 1. Solution Overview — Winget & Microsoft Store App Management with Microsoft Intune

## What this is
Most of the apps your users ask for every day — a PDF reader, a media player, a browser, common
utilities — are mainstream, publicly available Windows apps. You should not have to hand-package each
one. Microsoft Intune deploys these two ways, and this solution stands both up end to end:

- **Microsoft Store apps (the "new" Store app type)** — Intune's modern Store app type is
  **winget-backed**: it installs apps from the Microsoft Store catalog, which draws on the public
  **Windows Package Manager (winget)** community catalog. You search for the app by name, add it, and
  Intune handles install and update. This gives you a **large public catalog** of Windows apps without
  building a single `.intunewin`.
- **Winget for the long tail** — apps beyond what you deploy from the Store are covered by winget:
  either they surface in the new Store app search (add them the same way), or, for winget-community
  apps that are not exposed through the Store, you wrap the winget command as a Win32 app (see the
  cross-reference below). The exact set of apps available through each path, and how each updates, is a
  moving target — **verify against current Microsoft documentation** for your tenant.

On top of both, Intune adds **assignment** (who gets the app), **self-service** (users install
on-demand from **Company Portal**), and **updates** (keeping installed apps current).

## How it works
1. In the **Microsoft Intune admin center**, you add a **Microsoft Store app (new)** by searching the
   catalog for the app by name; Intune records the app's package identifier and its metadata.
2. You **assign** the app. **Required** assignments install automatically on the targeted users'
   devices; **Available for enrolled devices** publishes the app in **Company Portal** so users
   install it themselves (self-service). An **Uninstall** assignment removes it.
3. For an app you cannot or do not want to source from the Store, you deploy it with **winget** — the
   supported route for winget-community-only apps is a **Win32 app** that runs the `winget` install
   command (packaging is covered by the sibling *Intune Win32 Application Packaging & Deployment*
   product). Whether a given app is available directly as a new-Store app is **verify-with-Microsoft**.
4. **Updates:** the new Store (winget-backed) app type is designed to keep apps current automatically
   as the publisher ships new versions; a winget-wrapped Win32 app updates when you deploy a new
   version or run a winget upgrade. **The exact update cadence and which path auto-updates vs. needs
   management is verify-with-Microsoft** — do not assume; confirm for your tenant.
5. You **pilot** every app on a small ring, validate install + self-service + update, then **expand**
   to the fleet.

## Required vs. Available (the distinction that matters)
- **Required** — Intune installs the app automatically on the assigned users' or devices' machines.
  Use it for baseline apps everyone must have (e.g. the corporate PDF reader).
- **Available for enrolled devices** — the app appears in **Company Portal** and the user installs it
  **on demand**. Use it for the long tail of apps some people want and others do not — this is
  **self-service**, and it removes the "please install X for me" ticket.
- **Uninstall** — Intune removes the app from the assigned targets.

## Choose the right lane
| You need… | Use | Why |
|---|---|---|
| A mainstream public app (reader, browser, media player) | **Microsoft Store app (new)** — this product | Winget-backed, large public catalog, no packaging, auto-update |
| A **curated, prepackaged** enterprise app with vendor-maintained detection/update | **Enterprise App Catalog** — see *Enterprise App Catalog Deployment in Microsoft Intune* | Microsoft-curated prepackaged Win32 apps with managed updates |
| A **winget-community-only** app not in the Store, or any in-house / custom installer | **Custom Win32** — see *Intune Win32 Application Packaging & Deployment* | Full control of a `.intunewin`, install/uninstall, detection |
| A deployment that is **failing** (install error, wrong state, detection) | **Break/fix** — see *Intune App Deployment Troubleshooting & Failure Remediation (Win32/LOB/Store)* | Structured diagnosis and remediation |

This product covers the **Store + winget public-catalog + self-service** lane. It **cross-references**
and does **not** duplicate the Enterprise App Catalog (curated, prepackaged) or the custom Win32
packaging products.

## Benefits
- **No packaging for mainstream apps** — add from a public catalog by name; no `.intunewin` build.
- **Self-service** — Company Portal turns "install X for me" tickets into one user click.
- **Automatic updates** for Store/winget apps (confirm cadence per tenant — verify-with-Microsoft).
- **One assignment model** — Required, Available, Uninstall, targeted by ring, same as every app.
- **Safe rollout** — pilot ring first, so a bad assignment never hits the whole fleet at once.

## Limitations (be honest with buyers)
- **Catalog coverage varies.** Not every app is in the Store/winget public catalog, and which apps are
  is a moving target — **verify-with-Microsoft** before promising an app to users.
- **Update behavior is not something you fully control.** Auto-update timing for Store/winget apps is
  service-managed; the precise cadence and any per-app exceptions are **verify-with-Microsoft**.
- **Winget-community-only apps** may need a Win32 wrapper (a small packaging step) rather than a direct
  Store add — see the custom Win32 product.
- **Self-service needs Company Portal** installed and the user signed in; without it, Available apps
  have nowhere to appear.
- **Version pinning is limited.** The Store/winget model favors "latest"; when you must hold a specific
  version, a custom Win32 package gives you that control.

## The standard deployment model
> **Add a Microsoft Store (winget-backed) app → assign it Required for baseline / Available for
> self-service → cover the long tail with winget → confirm updates → pilot on a ring → validate →
> expand to broad.** This is the repeatable way: **Assess → Configure → Pilot → Validate → Expand.** A
> bad assignment never reaches production because the pilot ring is the gate.
