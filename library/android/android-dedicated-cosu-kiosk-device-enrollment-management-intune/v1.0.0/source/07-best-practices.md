# 7. Best Practices — Android Dedicated (COSU) / Kiosk Device Enrollment & Management

Field-proven recommendations for a scalable, tamper-resistant dedicated-device fleet.

## Design
- **Pick dedicated for the right reason.** Dedicated = corporate-owned, **no user**, single-purpose.
  If a device needs a user or personal use, it is a different enrollment model — don't force it.
- **One profile per purpose, not per device.** A single `Android Dedicated - COSU - *` profile plus one
  kiosk policy should serve a whole class of identical devices. Split profiles only when the kiosk app
  set or hardware genuinely differs.
- **Target the device, never the (absent) user.** Assign everything — apps and kiosk — to a **dynamic
  device group keyed on the enrollment profile name**. This is the whole trick to managing user-less
  devices at scale and needs no manual grouping.
- **Prefer multi-app only when you need it.** Single-app kiosk is simpler and harder to escape; use
  multi-app (Managed Home Screen) when the job genuinely needs a curated set.

## Enrollment method
- **QR is the default; zero-touch is the endgame.** For existing stock, QR is fastest to pilot. For
  ongoing purchasing at scale, get the **reseller to assign your zero-touch configuration** so new
  devices enroll on first boot with no touch.
- **Watch the token expiry.** The enrollment profile token expires; **`COSU-Discovery.ps1`** reports it.
  Rotate/extend before it lapses or new enrollments fail.
- **Standardize the reset step.** Enrollment requires a **factory-reset** device; bake "reset →
  enroll → verify kiosk" into your provisioning runbook so staging is consistent.

## Apps and kiosk
- **Keep the kiosk allow-list and app assignments in lockstep.** Every app named in the kiosk must be
  **Required-to-device** on the group; every Required app that should be user-visible should be in the
  kiosk. Run **`COSU-Validation.ps1`** on every change — a drifted allow-list is the #1 "app is
  missing" cause.
- **Assign apps to the group before (or with) the kiosk.** If the kiosk deploys before the app installs,
  the tile is empty until the app catches up.
- **Harden with intent, not reflexively.** Block what defeats the purpose (add-accounts, factory reset
  by user, USB transfer, safe boot). Leave what the job needs (a specific input method, a scanner
  toggle). Over-blocking creates support tickets.

## OEM / rugged
- **Deliver OEM settings via OEMConfig, at the pattern level.** Zebra/Samsung scanner profiles, key
  remaps, and firmware control belong in the **OEM's OEMConfig app + app configuration**, assigned to
  the device group — not hand-set on devices. The schema is the OEM's; defer to their docs.
- **Control firmware/OS updates deliberately.** Frontline fleets hate surprise updates mid-shift; set
  the system-update policy to your maintenance window where the OEM/Android supports it.

## Operations
- **Pilot on a few, then wave.** Prove the profile + kiosk on a handful, pass all three testing gates,
  then expand in waves — validating each wave. Never flip the whole fleet at once.
- **Treat enrollment-model changes as high-impact.** Reversing dedicated needs a **wipe + factory reset**;
  some kiosk/restriction changes may need a reboot or (rarely) re-enrollment — **verify against current
  Microsoft guidance / your tenant** before a fleet-wide change.
- **Monitor for stale devices.** Run **`COSU-Report.ps1`** on a schedule; a device with an old
  last-check-in is likely powered off, off-network, or drifted — investigate before it fails silently.
- **Document rollback.** For any production kiosk change, know the revert: unassign the kiosk to relax,
  delete the token to stop new enrollments, wipe/retire to fully reset a device.

## Automation & security
- **Run the scripts read-only first.** `COSU-Discovery` / `COSU-Validation` / `COSU-Report` are
  read-only; the config helpers default to **`-WhatIf`** — preview before `-Apply`.
- **Least privilege, no secrets.** Connect with the **least Graph scopes** each task needs; never place
  credentials, tokens, or the enrollment token string in scripts or source control.
- **Keep the enrollment token secret-ish.** The QR/token enrolls any factory-reset device onto your
  tenant — treat it as sensitive; rotate it if it leaks.
