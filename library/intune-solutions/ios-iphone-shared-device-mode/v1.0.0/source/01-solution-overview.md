# 1. Solution Overview — iOS iPhone Shared Device Mode (Lockdown) with WebEx Calling

## What this solution is
This solution turns ordinary **iOS iPhones into locked-down, shared "appliance" phones** managed by
Microsoft Intune. The devices are **not assigned to one person** — they are pooled, shared handsets
(think a nurses' station, a warehouse floor, a hotel front desk, a fleet of loaner phones) that any
authorized staff member can pick up and use for a **single, controlled purpose: making and taking
calls in the Cisco Webex app**.

It delivers exactly the four constraints this deployment requires:

1. **Shared, no-user-affinity enrollment** via a **Device Enrollment Manager (DEM)** account — devices
   enroll under one management identity with **no primary user**, so they are owned by the
   organization, not a person, and can be handed between staff freely.
2. **Lock-down (kiosk) mode** — a supervised kiosk configuration restricts each iPhone to **only the
   Cisco Webex app** (plus the system essentials needed to place calls), hiding the rest of iOS so the
   device can't be repurposed, wandered off into Settings, or used for anything but its job.
3. **Organization accounts for login** — staff sign into Webex with a **shared organization account**
   (or their own org account at the app layer), so the *device* stays generic while the *app session*
   carries the corporate identity.
4. **Cisco Webex provisioned automatically** — the Webex app is pushed as a **required** app and is the
   single app the kiosk exposes, so a freshly enrolled iPhone comes up ready to call with nothing else
   to configure.

## How it works
1. **One DEM account enrolls the fleet.** An Intune **Device Enrollment Manager** account (a normal
   Entra user granted the DEM role) is allowed to enroll a large number of devices **without user
   affinity**. Every shared iPhone enrolls under this account, so none of them gets tied to an
   individual user.
2. **Supervised via Apple Business Manager.** The iPhones are added to **Apple Business Manager (ABM)**
   and enrolled through **Automated Device Enrollment (ADE)** as **supervised** devices — supervision
   is what unlocks true kiosk lock-down and the deeper restrictions.
3. **A device group gathers the shared phones.** All shared iPhones land in one Intune group, so every
   policy below is assigned once to that group and applies to the whole fleet.
4. **The kiosk profile locks the device to Webex.** A supervised **kiosk** configuration profile puts
   each iPhone into single-app (or multi-app) mode showing **only Cisco Webex**, and a device
   restrictions profile strips out everything the appliance shouldn't expose.
5. **Webex is deployed and ready.** The **Cisco Webex** app is assigned **Required** to the shared
   group so it installs automatically; staff sign in with the **shared organization account** to place
   calls.
6. **Compliance keeps the fleet healthy.** A compliance policy (OS minimum, passcode/lock behavior as
   appropriate for a shared device) reports the health of every shared iPhone.

## Authentication & login model
Because the devices are **shared and have no primary user**, identity lives at the **app layer**, not
the device layer:
- The **device** authenticates to Intune via the **DEM account** at enrollment — that is the only
  device-level identity.
- **Staff** authenticate to **Cisco Webex** with a **shared organization account** (an Entra account
  provisioned for the shared-phone role). This keeps the corporate calling identity consistent across
  the whole fleet while the hardware stays interchangeable.
- Optionally, the shared account's sign-in to Webex / Office 365 can be governed by Conditional Access.

## The standard deployment model
This solution uses **one** model so the process is repeatable across our catalog:

> **Shared iOS iPhones enrolled with no user affinity via a Device Enrollment Manager account,
> supervised through Apple Business Manager + ADE, locked to the Cisco Webex app with a kiosk profile,
> and signed into Webex with a shared organization account — assigned once to a single shared-device
> group and rolled out pilot-first.**

Every step follows the Phoenixtekk pattern: **Assess → Configure → Pilot → Validate → Expand.**

## Benefits
- **Interchangeable handsets** — no device belongs to anyone; any staff member can grab any phone and
  start calling.
- **Single-purpose lock-down** — the iPhone does one job (Webex calling) and nothing else; no
  wandering into Settings, the App Store, Safari, or unrelated apps.
- **Zero per-device setup** — DEM enrollment + required Webex + kiosk profile means a phone comes out
  of the box ready to call.
- **Consistent corporate calling identity** — a shared organization account keeps Webex calling under
  one managed identity across the fleet.
- **Fleet-scale management** — assign every policy once to the shared-device group; add a phone to the
  group and it inherits the whole configuration.
- **Auditable & healthy** — compliance and reporting scripts show enrollment, supervision, kiosk, and
  Webex install state across all shared phones.

## Limitations (be honest with buyers)
- **Kiosk lock-down requires supervised devices** — supervision (ABM + ADE, or Apple Configurator) is
  required; unsupervised iPhones cannot be fully locked to a single app.
- **DEM-enrolled devices have no primary user**, so user-affinity features (per-user app licensing
  tied to the device user, Company Portal self-service for that user) don't apply — by design for
  shared devices.
- **A DEM account has an enrollment cap** (a single DEM account can enroll a large but finite number
  of devices); very large fleets use additional DEM accounts.
- **Shared-account hygiene matters** — a shared Webex login means staff don't get individual identity
  on the device; treat the shared account's credentials and Conditional Access carefully.
- **Webex feature availability** depends on your Cisco Webex licensing/calling plan — this solution
  deploys and locks the app; the calling service is provided by Cisco.
