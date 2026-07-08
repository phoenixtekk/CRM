# 1. Solution Overview — Android Dedicated (COSU) / Kiosk Device Enrollment & Management in Intune

## What this solution is
This solution stands up **Android Enterprise dedicated devices** — Google's **COSU**
(Corporate-Owned, Single-Use) model — in **Microsoft Intune**. Dedicated devices are company-owned,
have **no user affinity**, and boot straight into a **kiosk**: either **one app** (single-app kiosk)
or a **curated set of apps** on a locked launcher (multi-app kiosk). This is the model for frontline,
warehouse, retail, logistics, and clinical devices that exist to do one job and nothing else.

It covers the whole path: choosing and building the **dedicated enrollment profile**, enrolling
devices by **token / QR code / NFC / zero-touch**, applying the **kiosk profile and device
restrictions**, delivering **managed Google Play** apps to devices that have no user signed in, and
**remotely managing** the fleet — validated on a pilot before you scale.

It is **vendor-neutral**. Samsung Knox and Zebra (and other rugged/kiosk OEMs) are covered at the
**pattern level** — where an OEM extension or OEMConfig app changes a step, this solution names the
action and defers the OEM console/agent specifics to the vendor's documentation.

## The dedicated (COSU) model in one paragraph
A dedicated device is enrolled as an Android Enterprise **device-owner** with **no user account**.
Because there is no user, everything is targeted at the **device**, not a person: enrollment is driven
by an **enrollment profile / token**, and policy and apps are assigned to a **device group** (typically
a **dynamic device group keyed on the enrollment profile name**). The device runs in **kiosk mode** —
Android's lock-task mode — so the user cannot leave the allowed app(s), reach settings, or use the
device personally.

## The four enrollment methods (pick per device fleet)
The dedicated enrollment profile produces a **token** (a string) plus a **QR code** that carry the
enrollment. From a factory-reset device you choose how that token is delivered:

- **QR code** — on the setup "Welcome" screen, tap the screen several times to launch the QR reader,
  then scan the profile's QR code. The most common method for dedicated devices; no Google account or
  typing needed.
- **Token / afw#setup (manual)** — enter `afw#setup` where the setup asks to sign in, then supply the
  enrollment token. Useful where a camera/QR is impractical.
- **NFC** — bump a factory-reset device against an NFC "programmer" device running an NFC-provisioning
  app that carries the token. A bulk method for identical hardware; the NFC bump payload is deferred to
  the OEM/tooling.
- **Zero-touch enrollment** — devices bought through a **zero-touch reseller** are pre-assigned an
  enrollment configuration, so they enroll automatically on first boot with no scanning. Requires the
  **Android zero-touch portal** (reseller-provisioned) linked to your EMM; the portal specifics are
  deferred to Google/reseller documentation.

All four land the device on the **same** dedicated enrollment profile and therefore the same kiosk and
restriction policy — the method only changes how the token reaches the device.

## Single-app vs multi-app kiosk
- **Single-app kiosk** — the device locks to **one** app (e.g. a scanning app, a survey app, a
  digital-signage player). The app launches on boot and the user cannot leave it. Configured on the
  Android Enterprise **device restrictions** profile by setting the kiosk to that one app.
- **Multi-app kiosk** — the device shows a **locked launcher** with a **curated set** of apps and
  nothing else. Intune delivers this using Microsoft's **Managed Home Screen** app
  (`com.microsoft.launcher.enterprise`) as the launcher, with the allowed apps listed in the kiosk
  configuration. You control the grid, whether the user can change Wi-Fi/Bluetooth/volume, a session
  PIN, screen-saver, and more.

Both are built on the **`androidDeviceOwnerGeneralDeviceConfiguration`** device-restrictions profile;
multi-app additionally requires the Managed Home Screen app deployed to the device group.

## Managed Google Play app delivery to devices with no user
Because a dedicated device has **no signed-in user**, apps are delivered to the **device**: managed
Google Play apps (`androidManagedStoreApp`) are assigned to the **dedicated device group** as
**Required**, so they install at/after enrollment without any user action. The kiosk allow-list must
reference apps that are actually **assigned and installed** — an app named in the kiosk but not
assigned to the group will not appear. Keeping the **app assignments and the kiosk allow-list in sync**
is a first-class validation in this solution.

## Remote management
Dedicated devices are managed remotely through Intune device actions — **restart, wipe, retire, sync,
remote-lock**, and (where supported) **remote assistance** — plus policy/app updates that flow to the
device group. The Reporting script surfaces fleet health (compliance, last check-in, OS version, OEM
model) so you can spot stale or drifted devices.

## What is authored exactly vs deferred
- **Exact navigation is given** for the **Intune admin center** (`intune.microsoft.com`) — the
  dedicated enrollment profile, the kiosk/device-restrictions profile, managed Google Play app
  assignment, enrollment restrictions, and device actions — and for **Microsoft Graph** automation.
- **The managed Google Play binding** (account enterprise vs Google Workspace) is a **category
  prerequisite** (global requirement G2) — confirm it is in place before enrolling.
- **OEM specifics** (Samsung Knox, Zebra) and the **zero-touch reseller portal** are integrated at the
  **pattern level**; their consoles/agents are deferred to the vendor's documentation.
- **The AMAPI transition and whether a policy change forces re-enrollment are actively evolving** —
  where behavior is version-dependent this solution flags **"verify against current Microsoft guidance
  / your tenant"** rather than asserting it.

## Benefits
- **Boots to the job** — devices power on straight into the allowed app(s); no personal use, no wandering.
- **Consistent at scale** — one enrollment profile + one kiosk policy applied to every device, the same way.
- **User-less by design** — no account to manage; policy and apps target the device group.
- **Choice of enrollment** — token, QR, NFC, or zero-touch, all landing on the same profile.
- **Managed + reversible** — remotely manageable, piloted first, with scripts to validate and report.

## Limitations (be honest with buyers)
- **Dedicated = corporate-owned, no user.** It is not for BYOD or personal-plus-work phones (those are
  other enrollment models). Choose dedicated only for purpose-built devices.
- **Re-enrollment sensitivity.** Changing the **enrollment model** of a device generally requires a
  **factory reset and re-enrollment**; some kiosk/restriction changes apply live while others may need a
  reboot. Whether a specific change forces re-enrollment is **version-dependent — verify against current
  Microsoft guidance / your tenant**, and treat enrollment-model changes as high-impact.
- **OEM/rugged features vary.** Barcode-scanner, OEMConfig, and firmware-update behavior differ by
  vendor (Zebra, Samsung) and are deferred to the OEM.
- **No managed Google Play binding = no dedicated devices.** The category binding (G2) is a hard
  prerequisite.

## The standard deployment model
> **Assess the fleet → design the profile + kiosk → configure the enrollment profile, kiosk, and app
> assignments → pilot-enroll a few devices → validate the locked-down experience → expand in waves.**
> Pattern: **Assess → Design → Configure → Pilot → Validate → Expand**, with explicit pass/fail gates
> and a documented rollback for production changes.
