# Executive Summary — iOS iPhone Shared Device Mode (Lockdown) with WebEx Calling

Many teams need **shared phones, not personal ones** — pooled iPhones at a nurses' station, a
warehouse floor, a front desk, or a fleet of loaners that **anyone on shift can pick up and use for
one job: making calls**. Handed out as ordinary phones, they drift — apps get installed, settings get
changed, devices get tied to whoever set them up, and nobody can tell which handset is healthy.

This solution makes those iPhones **locked-down, shared appliances** under **Microsoft Intune**:

- **Shared, no owner** → enrolled with **no user affinity** via a **Device Enrollment Manager (DEM)**
  account, so no phone belongs to a person and any staff member can use any device.
- **Locked to one job** → **supervised** via Apple Business Manager + ADE and put into **kiosk
  lock-down** that exposes **only the Cisco Webex app**; the rest of iOS (App Store, Safari, Settings)
  is stripped away.
- **Corporate calling identity** → staff sign into Webex with a **shared organization account**, so the
  device stays generic while the calling identity stays managed.
- **Ready out of the box** → **Cisco Webex** is pushed as a required app and is the app the kiosk
  shows, so an enrolled iPhone comes up ready to call with zero per-device setup.

Built the standard repeatable way — **Assess → Configure → Pilot → Validate → Expand** — with exact,
click-by-click Intune steps, a requirements guide that tells you how to verify *and* fix each
prerequisite, five ready-to-run PowerShell scripts (Microsoft Graph), and testing/troubleshooting
guides with clear pass/fail gates.

**Outcome:** a fleet of interchangeable, locked-down iPhones that do exactly one thing — Webex calling
under a managed organization account — enrolled hands-off and managed at fleet scale by your own team,
without a consulting engagement.
