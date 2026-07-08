# 7. Best Practices — Google Workspace ↔ Intune Third-Party EMM Integration

Field-tested principles for integrating Google Workspace / Cloud Identity with Intune as a third-party
EMM for managed Google Play — with the re-enrollment question treated honestly throughout.

## Model & identity
- **Confirm the model before anything else.** Verify you have a Google Workspace / Cloud Identity managed
  domain and therefore need the **third-party EMM** integration, not the account-enterprise bind
  (`ANDROIDENT`). Never run both — one model per tenant (GR 2).
- **Reconcile identities up front.** Line up Entra UPNs and Google primary emails for the pilot users
  before you touch either console; unmatched domains/identities are the top cause of "can't add
  account" in the Workspace model.
- **Document the sign-in account.** Record exactly which account users add on devices, so support can
  reproduce and triage.

## Re-enrollment discipline (the heart of this solution)
- **Never assert re-enrollment behavior — observe it.** Whether a binding change re-enrols existing
  devices is state- and version-dependent and **actively evolving** (including the AMAPI transition).
  Measure it on a pilot; verify against current Microsoft/Google guidance; then decide.
- **Baseline before you touch anything.** Capture the binding posture and full device inventory
  *before* the Google Admin console change — it is the only way to prove what changed.
- **Pilot every enrollment model you actually run.** Work profile BYOD, fully managed, corporate-owned
  work profile, and dedicated/COSU can behave differently; include a representative of each in
  `MGP Pilot – Android – Stage1`.
- **Diff, don't eyeball.** Compare the post-change device report to the baseline per device (enrollment
  type, management state, enrolled/last-check-in dates) rather than trusting a glance at the console.

## Cross-console change control
- **Two owners, one change window.** The Google super-admin and the Intune admin act in a coordinated,
  change-controlled window — not ad hoc, and not by two people independently.
- **Write the rollback first.** Know exactly how the Google super-admin reverses the third-party EMM
  enablement and how the Intune side reverts, and verify that procedure against current guidance —
  before you enable anything.
- **Record the token/identifiers.** Capture anything the Google Admin console generates during
  enablement so the Intune side and any rollback are reproducible.

## Verify-against-current-guidance habit
- **Treat every console path as perishable.** Google relocates the third-party integration setting and
  Microsoft evolves the Intune connection flow; follow **live** documentation for both, not remembered
  paths.
- **Flag beta surfaces.** Some binding-state Graph resources (e.g.
  `androidManagedStoreAccountEnterpriseSettings`, Android enrollment profiles) are on the Graph **beta**
  endpoint — verify their shape in your tenant and expect change.

## Scope, safety, and automation
- **Contain the pilot with scope.** Assign apps and enrollment restrictions to the pilot group so the
  change is bounded; expand only in stages.
- **Keep automation read-only by default.** Discovery, readiness, validation, and device-impact scripts
  are read-only; only the scope helper writes, and only with `-Commit`. Request least Graph scopes; keep
  no credentials in code.
- **Re-run health as you expand.** Refresh `MGP Sync Health – Android – Report` at each expansion stage;
  a regression is a signal to pause.

## Operations
- **Communicate to users before the cutover.** Even if your verified expectation is "no impact," tell
  pilot users what to expect and how to report anything odd — it turns surprises into fast signal.
- **Watch app sync continuously.** A stale or failed managed Google Play sync silently breaks app
  delivery; alert on it.
- **Re-baseline after big changes.** After the fleet is stable, capture a fresh binding + device
  baseline so future changes (including AMAPI-driven ones) have a current reference.

## OEM & third-party (pattern level)
- **Defer OEM consoles to the vendor.** Samsung Knox, Zebra, and other rugged/kiosk specifics are
  integrated at the pattern level; follow the vendor's current docs for their console.
- **Test OEM/kiosk devices explicitly in the pilot.** Dedicated/COSU and rugged devices are the most
  sensitive to enrollment changes — do not infer their behavior from a phone.
