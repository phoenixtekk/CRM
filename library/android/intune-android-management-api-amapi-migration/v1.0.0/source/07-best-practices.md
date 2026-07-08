# Best Practices

Durable practices for migrating Intune Android Enterprise management to the **Android Management
API (AMAPI)** with the least disruption.

## Verify, never assume (the cardinal rule)

- **Read the current Microsoft guidance every time you plan or expand.** The AMAPI rollout,
  enrollment-method options, web/account-driven availability, and re-enrollment behavior change
  over time. Treat "verify against current Microsoft guidance / your tenant" as a hard gate, not a
  disclaimer.
- **Never promise an end-user outcome you have not observed.** Do not tell users "no
  re-enrollment" (or "you must re-enroll") until a pilot device of that exact enrollment model has
  shown you the behavior and Microsoft's current docs confirm it.
- **Determine legacy-vs-AMAPI from Microsoft's status surface, not from an inferred property.**
  There is no single documented Graph field that labels a device AMAPI-managed; read the
  authoritative status in the admin center / current guidance.

## Estate and wave design

- **Assess before you plan.** Inventory by enrollment model, ownership, OS, OEM, and check-in
  first — waves and communications flow from the real population.
- **Pilot each enrollment model separately.** Work profile (BYOD), fully managed, corporate-owned
  work profile, and dedicated/COSU can each behave differently on migration; prove each on its own
  before mixing.
- **Sequence lowest-visibility first.** Migrate the cohorts with the least user-facing risk early;
  stage BYOD work-profile and dedicated/COSU (which can reset a kiosk) deliberately and late.
- **Keep wave groups Assigned, scoped, and single-purpose.** One Assigned security group per
  model/stage; don't reuse a group that also drives unrelated licensing or assignments.

## Protect the managed Google Play binding

- **Confirm binding health first and after each wave.** AMAPI does not remove managed Google Play;
  a degraded binding shows up as app-delivery and account-add failures that masquerade as
  migration bugs.
- **Do not let the enterprise token/account lapse mid-migration.** Watch `lastAppSyncDateTime`
  and connection state throughout.

## End-user communication

- **Communicate the verified impact, per model, before each wave migrates** — what will happen,
  when, and what (if anything) the user must do. A wave should never be surprised.
- **For dedicated/COSU, coordinate as a maintenance action.** If a re-provision/reset is possible,
  stage the device offline, not in front of a user or customer.

## Change control, validation, and rollback

- **Pilot-first with pass/fail gates.** Prove *manage under AMAPI → accounts add → apps deliver →
  compliant* on the pilot before any production wave.
- **Halt-and-hold is the rollback.** If a wave fails or the impact is unacceptable, stop promoting
  and hold remaining devices on the current path — already-validated devices are unaffected. There
  is no "un-migrate" button; the safeguard is small waves and a working pilot.
- **Validate with a real device, not just a successful admin action.** Confirm an actual managed
  app install and account presence, not merely that the console accepted the change.

## Tooling and least privilege

- **Run read-only by default.** The assessment, readiness, and validation tools request read
  scopes; grant `Group.ReadWrite.All` only for the brief window you create wave groups with
  `-Commit`.
- **No secrets in automation.** All scripts use interactive/delegated `Connect-MgGraph`; store no
  app secrets or credentials.

## Documentation and evidence

- **Record the verified impact statement, the current-guidance references, and the tenant-verified
  control paths** in your own runbook — labels and behavior are version-dependent.
- **Keep the assessment and validation output as a baseline** so a later regression is a
  one-command diff, and cross-reference the **Android enrollment troubleshooting (Google account /
  AMAPI)** solution for device-level failures.
