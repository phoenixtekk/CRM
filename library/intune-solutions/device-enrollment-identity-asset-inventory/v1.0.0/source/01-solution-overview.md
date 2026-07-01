# 1. Solution Overview — Device Enrollment, Identity Association & Asset Inventory

## What this is
Device enrollment is how a device becomes managed by Microsoft Intune; identity association is the
link between that device and the person who uses it (its **primary user**); and asset inventory is
the record Intune keeps of every managed device. Together they answer the three questions a service
desk asks on every ticket: *Is this device managed? Who owns it? Is it the device we think it is?*
This solution establishes all three so Intune becomes the **reconciled source of truth** for the
fleet.

## Why it matters
- **You can only support what is enrolled.** Policies, compliance, and remote actions reach managed
  devices only. An unenrolled device is invisible to the service desk.
- **The primary user is how tickets find the device.** When a user calls, the desk searches by name;
  the right **primary user** association is what surfaces the correct device, its compliance, and its
  apps. A wrong or missing primary user means every call starts with guesswork.
- **An inventory you cannot trust is worse than none.** Stale records (devices long since retired),
  duplicates (re-enrolled hardware), and devices that never enrolled all corrupt the count. A
  reconciled inventory is what lets you spot the gaps — and the missing assets.

## The enrollment methods (what to use, when)
1. **Windows Autopilot** — the device ships, the user signs in, and it provisions itself
   (Entra-joined, Intune-enrolled, with the apps and policies pre-staged). Best for new corporate
   Windows hardware. The **enrollment status page** can block the desktop until setup completes.
2. **Entra join + automatic enrollment** — a user (or IT) joins the device to Entra ID and, because
   automatic enrollment is on, it enrolls in Intune in the same step. Best for existing corporate
   Windows devices joining directly.
3. **Bulk enrollment / Device Enrollment Manager (DEM)** — a single provisioning package or a
   special DEM account enrolls many shared/kiosk devices that are not tied to one user. Best for
   shared hardware where a per-user primary association is not wanted.
4. **BYOD (personal devices)** — users enroll their own devices through the Company Portal under a
   personal-device enrollment profile, typically with lighter management. Best when staff use
   personal hardware to reach work resources.

## Enrollment restrictions (the gate)
**Enrollment restrictions** decide which platforms and which kinds of devices (personal vs.
corporate) are even allowed to enroll, and how many devices a user may enroll. They are the gate that
keeps the inventory clean: if you only support corporate Windows, restrictions stop personal phones
and unsupported platforms from cluttering the fleet.

## Primary user / device-identity association
Every Intune-managed device has a **primary user** — the account Intune treats as the device's owner
for licensing, app targeting, and service-desk lookup. Autopilot and user-driven enrollment set it
automatically to the enrolling user; shared/DEM devices have **no** primary user by design. When the
primary user is wrong (device reassigned, enrolled by a technician, imported from another system),
the service desk searches by the user and finds nothing — so correcting and maintaining this
association is central to a trustworthy inventory.

## Intune inventory as the source of truth
Intune records each managed device with its name, owner (primary user), platform, compliance, serial
number, and last check-in. Reconciliation compares that record against reality — flagging stale
records (no check-in for weeks), duplicates (same serial, multiple records), missing primary users,
and devices that should be enrolled but are not. The reconciled result is what the service desk
trusts.

## What you can control
- **Which enrollment methods are enabled** and how each is configured (Autopilot profile, automatic
  enrollment, BYOD profile, DEM accounts).
- **Enrollment restrictions** — allowed platforms, personal vs. corporate, and the per-user device
  limit.
- **The enrollment status page** — what the user sees during Autopilot and whether the desktop is
  blocked until setup completes.
- **Primary-user association** — read, correct, or clear it per device.
- **Inventory reconciliation** — which records are stale, duplicate, or missing an owner.

## Limitations (be honest with buyers)
- Intune inventory covers **enrolled** devices; truly off-grid hardware that never enrolled won't
  appear until it does — reconciliation surfaces the gap but cannot conjure the device.
- Some hardware/asset fields (purchase date, cost, location) live in a procurement/CMDB system, not
  Intune; reconciliation can compare against an exported list but Intune is not a full ITAM tool.
- Shared/DEM devices intentionally have **no** primary user — don't "fix" them to one.
- Apple/Android enrollment methods exist but each needs its own connector/credentials; this solution
  centers on the cross-platform model with Windows as the worked example.

## The standard Phoenixtekk deployment model
> **Enable the enrollment methods you support → set enrollment restrictions and automatic enrollment
> → establish the primary-user rules → enroll/import a pilot → reconcile and validate the inventory →
> expand to the fleet.** Phoenixtekk pattern: **Assess → Configure → Pilot → Validate → Expand.**
