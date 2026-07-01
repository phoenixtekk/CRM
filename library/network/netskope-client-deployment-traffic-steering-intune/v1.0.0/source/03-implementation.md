# 3. Implementation Guide — Netskope Client Deployment & Traffic Steering at Scale (Intune)

Follow these steps in order, in the Microsoft Intune admin center (`https://intune.microsoft.com`).
Netskope tenant-side configuration (the steering profile, exception objects, enrollment method, and
SSL/decryption certificate) is authored in the Netskope console and is deferred to the official
Netskope documentation; this guide wires the Intune delivery, validation, and ringed rollout around it.

> Model: Assess the fleet, configure the client app and steering/exception delivery, deploy to a small
> pilot ring, validate health and steering, then expand ring by ring. A pilot gate sits before every
> expansion, and a rollback path is ready before steering touches live traffic.

## Step 1 — Assess readiness
1. Run `NSCLIENT-Discovery.ps1` on representative devices to confirm OS, enrollment, and that no
   prior/partial Netskope client is present.
2. Run `NSCLIENT-Set-RolloutRingTargeting.ps1 -WhatIf` to preview the ring groups and membership.
3. Confirm the Netskope tenant has `Steering Profile – Corporate – Production` and
   `Steering Exceptions – Business Apps – Production` ready (Requirements 2.2-2.3).

## Step 2 — Create the ring groups
1. Go to Entra -> Groups -> New group -> Security -> name `Device Group – Pilot – Stage1` (a few
   representative devices across your hardware/app profiles). Select Create.
2. Repeat for `Device Group – Early – Stage2` (a larger cross-section) and
   `Device Group – Broad – Stage3` (the remaining fleet).
3. Alternatively, build these groups with `NSCLIENT-Set-RolloutRingTargeting.ps1` (run with -WhatIf
   first, then re-run without it to apply).

## Step 3 — Package the Netskope client as an Intune app
1. Wrap the Netskope client installer using the Microsoft Win32 Content Prep Tool to produce a
   `.intunewin` package (use the silent-install and tenant-enrollment switches from the Netskope
   documentation — deferred to Netskope docs).
2. Go to Intune -> Apps -> Windows -> Add -> app type Windows app (Win32) -> select the `.intunewin`.
3. Name the app `Netskope Client – Windows – Production`. Complete the publisher/description fields.
4. Program: enter the silent install command and the uninstall command from the Netskope
   documentation; set the install behavior to System.
5. Detection rules: add a rule that reliably detects the installed client (for example the client
   service or install path/version per the Netskope documentation).
6. Select Next through Requirements/Dependencies; do not assign yet. Select Create.

## Step 4 — Deliver the SSL/decryption certificate (if inspecting SSL)
1. Go to Intune -> Devices -> Configuration -> Create -> New policy -> Windows -> profile type
   Templates -> Trusted certificate.
2. Name it `Netskope Decryption Cert – Trusted Root – Production`, upload the Netskope root/decryption
   certificate (source deferred to Netskope docs), and set the destination store to Trusted Root.
3. Assignments: assign to `Device Group – Pilot – Stage1` for now (you will widen it with each ring).
   Select Create.

## Step 5 — Confirm steering and exception configuration (Netskope tenant)
1. In the Netskope tenant, confirm `Steering Profile – Corporate – Production` defines the traffic to
   steer and is scoped to your pilot users/devices (console path deferred to Netskope docs).
2. Confirm `Steering Exceptions – Business Apps – Production` lists each sensitive business app and is
   active on the steering profile.
3. Record which exception protects which app, so the list stays auditable.

## Step 6 — Deploy to the pilot ring
1. Go to Intune -> Apps -> Windows -> open `Netskope Client – Windows – Production` -> Properties ->
   Assignments -> Edit.
2. Under Required, add group `Device Group – Pilot – Stage1`. Save.
3. On a pilot device, sync policy (Settings -> Accounts -> Access work or school -> Info -> Sync), or
   wait for the next Intune check-in.

## Step 7 — Validate the pilot ring (pilot gate)
1. On pilot devices, run `NSCLIENT-Validation.ps1` -> confirms the client is installed, running,
   enrolled to your tenant, and steering is active.
2. Run `NSCLIENT-Report.ps1` -> confirms the `Netskope Client – Windows – Production` deployment
   status across `Device Group – Pilot – Stage1` (installed/failed/pending) and certificate coverage.
3. On a pilot device, confirm each business app on the exception list still works and that inspected
   HTTPS sites load without certificate errors.
4. Complete the Testing Guide. Pilot gate: do not proceed to Step 8 until the pilot ring passes its
   pass/fail gate. If it fails, use `NSCLIENT-Remediation.ps1` (default -WhatIf) and the rollback path.

## Step 8 — Expand to the early ring
1. Add `Device Group – Early – Stage2` to the Required assignment of
   `Netskope Client – Windows – Production`, and to the certificate profile from Step 4.
2. Widen the Netskope steering profile scope to the early-ring users/devices (Netskope docs).
3. Re-validate with `NSCLIENT-Validation.ps1` and `NSCLIENT-Report.ps1`; confirm exceptions still hold.

## Step 9 — Expand to broad (production)
1. Add `Device Group – Broad – Stage3` to the app assignment and the certificate profile.
2. Widen the steering profile scope to the broad ring (Netskope docs).
3. Re-run `NSCLIENT-Report.ps1` each wave; chase failed/unhealthy clients with
   `NSCLIENT-Remediation.ps1`. Keep the rollback path available until broad is healthy.

## Step 10 — Steady-state operations
1. Re-run `NSCLIENT-Report.ps1` on a schedule to catch new/failed/unhealthy clients.
2. Add new devices to the appropriate ring group (or to broad) so coverage stays complete.
3. Manage steering and exception changes through the same pilot-first ring path and change control.

---
### Order of operations
`Assess -> Ring groups -> Package client app -> Certificate (if SSL) -> Confirm steering + exceptions -> Deploy pilot -> Validate (pilot gate) -> Expand early -> Expand broad -> Operate`
