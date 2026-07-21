# 7. Best Practices — Winget & Microsoft Store App Management with Microsoft Intune

- **Pilot every app first, always.** A small `Store & Winget Apps – Pilot – Ring 1` catches a bad
  assignment or a wrong app before it reaches `Store & Winget Apps – Broad – Ring 2` — the single most
  important practice. The pilot is the gate.
- **Match Required vs. Available to the app.** Make baseline apps everyone needs **Required**; make the
  long tail **Available** in Company Portal (self-service). This kills "install X for me" tickets while
  keeping the mandatory set installed automatically.
- **Confirm the exact publisher before you add an app.** Public-catalog search returns look-alikes; add
  the app whose publisher matches (e.g. **Adobe Inc.**, **VideoLAN**), and record its package
  identifier. A wrong listing deploys the wrong software.
- **Prefer the Store (winget-backed) lane for mainstream apps.** No packaging, auto-update — use it
  before reaching for a custom Win32 package. Reserve custom Win32 for winget-only, in-house, or
  version-pinned apps (see the *Intune Win32 Application Packaging & Deployment* product).
- **Use the Enterprise App Catalog for curated prepackaged apps.** When you need vendor-maintained
  detection and managed updates for a prepackaged Win32 app, that is the *Enterprise App Catalog
  Deployment* product's lane — not this one. Don't rebuild it here.
- **Know each app's update path.** Record whether an app auto-updates (Store/winget, service-managed) or
  is version-controlled by you (a pinned Win32 wrapper). Do not assume auto-update timing — **confirm
  the cadence with Microsoft** for your tenant.
- **Deploy Company Portal before relying on self-service.** Available assignments only appear inside
  Company Portal; without it, on-demand installs have nowhere to surface.
- **Name everything with `<Purpose> – <Platform> – <Stage/Type>`.** Self-describing names (apps, groups)
  keep a growing app list auditable and searchable, and let scripts reference objects reliably.
- **Target self-service apps to user groups.** Available apps follow the user into Company Portal; user
  scoping is the natural fit for opt-in apps.
- **Watch the report and chase laggards.** Track Installed / Failed / Not applicable with
  `WINGETSTORE-Report.ps1`; for failures, use the *Intune App Deployment Troubleshooting & Failure
  Remediation (Win32/LOB/Store)* product's structured break/fix.
- **Verify catalog and behavior specifics against Microsoft, don't assume.** App availability, the new
  Store app type's name, update cadence, and Government-cloud differences all change — confirm current
  facts for your tenant before promising them to users.
