# 1. Solution Overview — macOS App Deployment & Apple VPP with Microsoft Intune

## What this solution is
This solution delivers a repeatable way to get the **right applications onto managed Macs** —
licensed, assigned, and kept current — entirely from **Microsoft Intune**, without touching the
device. It combines two things:

1. **Apple Volume Purchase Program (VPP)** — the licensing side of **Apple Business Manager (ABM)**.
   Your organization acquires app licenses in ABM (free or paid) against a **location**, exports that
   location's **VPP token** (a server token, `.vpptoken`), and connects it to Intune. Intune then
   **syncs the licenses** and can install **App Store** apps and assign their licenses automatically.
2. **macOS app deployment in Intune** — the delivery side. Intune installs **App Store (VPP) apps**,
   **line-of-business (LOB) apps** you package yourself (`.pkg` / signed `.dmg`), and **unmanaged
   PKG** installers, targeting Entra security groups and reporting install and licensing status.

Together they give you licensed, hands-off app delivery to the Mac fleet — deployed pilot-first and
rollback-ready.

## The macOS app types in Intune (know which to use)
Intune → **Apps → macOS → Add** offers several app types. This solution uses these:

- **macOS app (App Store — VPP).** A public App Store app whose **licenses come from VPP**. Intune
  installs it and consumes a VPP license per install. *Requires a VPP token.* Best for anything on
  the App Store (e.g. a productivity or reader app).
- **macOS line-of-business app (LOB).** A **signed `.pkg`** you upload to Intune. Intune installs it
  as a managed app and can update it by uploading a newer package. Best for in-house or vendor apps
  not on the App Store.
- **macOS app (DMG).** A vendor-provided **signed `.dmg`** containing a `.app`. Intune installs and
  can report/uninstall it. Best for common third-party apps shipped as DMG.
- **macOS app (PKG) — unmanaged.** A **PKG installer** run once on the device (no license tracking,
  no automatic uninstall). Best for installers that must run scripts or place files outside `/
  Applications`. Least managed; use when the managed types don't fit.

> **Rule of thumb:** if it's on the App Store, use **VPP**; if you have a **signed `.pkg`/`.dmg`**,
> use the matching **managed** type; only fall back to **unmanaged PKG** when the others can't.

## VPP licensing: device vs. user (choose deliberately)
When you assign a VPP (App Store) app, Intune offers two license types:

- **Device licensing (recommended default).** The license is bound to the **device**, not to an
  Apple ID. The app installs **silently**, the user needs **no Apple ID and no App Store sign-in**,
  and the license returns to the pool when the device retires. Best for company-owned, managed Macs.
- **User licensing.** The license is bound to a **user's Managed Apple ID / Apple ID**. The user must
  be **invited and accept** VPP terms and be signed in to the App Store. More friction; use only when
  a specific app genuinely requires user-based licensing.

This solution standardizes on **device licensing** for company Macs, with notes for user licensing.

## How it works
1. **Acquire licenses in ABM.** In Apple Business Manager, an admin buys (or adds free) app licenses
   under a **location**. Each location has its **own** VPP token.
2. **Connect the token to Intune.** You upload the location's `.vpptoken` in Intune as a **VPP
   token**. Intune establishes the trust and begins syncing.
3. **Sync licenses.** Intune pulls the purchased apps and license counts from ABM. Synced apps become
   available to add as **App Store** apps in Intune.
4. **Add & assign apps.** You add the store app (or upload a LOB/DMG/PKG), pick **device** or **user**
   licensing, and assign it **Required** (or **Available**) to a **pilot** Entra group.
5. **Install & license, hands-off.** Managed Macs install the app on the next check-in; Intune
   **consumes and reports** a VPP license per device. Updates flow as new versions publish (store) or
   as you upload newer packages (LOB).
6. **Renew the token.** VPP tokens **expire (annually)**; a lapsed token stops license sync and new
   installs, so renewal is a scheduled operational task.

## Named objects this solution creates (and reuses)
To keep the deployment repeatable, this solution creates and **reuses** these named objects:

- **VPP token:** **`VPP – Corporate (Location A)`** — the connected Apple VPP location token in Intune.
- **Pilot group:** **`PILOT – macOS App Deployment`** — an Entra security group of pilot devices/users.
- **Store app assignment:** a chosen App Store app (e.g. a reader/productivity app) assigned
  **Required**, **device-licensed**, to the pilot group.
- **Enterprise (LOB) app:** a signed **`.pkg`** you package, added as a **macOS LOB app** and assigned
  **Required** to the pilot group.

Broader waves and the production rollout **reuse the same objects** (renaming *Pilot* → the wave/all
target as you expand).

## Benefits
- **No-touch delivery.** Apps install silently on managed Macs — no Apple ID, no App Store sign-in
  (device licensing), no hands on the device.
- **Licensed correctly.** VPP tracks each license; Intune reports consumption and reclaims on retire.
- **Store + enterprise, one pane.** App Store apps and your own `.pkg`/`.dmg` deploy and report from
  the same Intune console.
- **Kept current.** Store apps update as new versions publish; LOB updates by uploading a new package.
- **Pilot-first, rollback-ready.** Everything is validated on a named pilot before fleet rollout.

## Limitations (be honest with buyers)
- **VPP requires Apple Business Manager** and a **location** with acquired licenses; a Mac not
  managed by Intune can't receive managed apps.
- **App Store apps require a VPP token**; the token **expires annually** and must be renewed or license
  sync and new installs stop.
- **Device licensing** needs a **supervised / managed** Mac; **user licensing** requires the user to
  accept VPP terms and sign in to the App Store.
- **LOB `.pkg`/`.dmg` must be signed** (and, where required, notarized) to install cleanly on modern
  macOS; **unmanaged PKG** is install-once with no license tracking or managed uninstall.
- **Free apps still consume a VPP "license"** entry in ABM (count is effectively unlimited but the app
  must be acquired in ABM first).
- Personally-owned (BYO) Macs and per-user App Store purchases outside VPP are **out of scope**.

## The standard deployment model
This solution uses **one** model so the process is repeatable across our catalog:

> **Company-owned, Intune-managed Macs receiving VPP-licensed App Store apps (device-licensed) and
> signed enterprise LOB apps, assigned to a named pilot group first, then expanded in waves.**

Every step follows the repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**
