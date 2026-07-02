# Troubleshooting

The Runbook Library covers the common single-category cases. This guide handles the **cross-cutting
edge cases** — tickets that span two runbooks, symptoms that mimic one cause but have another, and
the failure modes of the tooling itself. Use it when a ticket doesn't sit cleanly inside one
runbook.

## Symptoms that cross runbook boundaries

- **"Can't open the app" that is really sign-in.** An app launches but shows a login/authentication
  error. This is **Runbook 1 (sign-in)**, not Runbook 4. Tell: the app opens and its UI works, but
  it can't authenticate; check the sign-in log and PRT (`dsregcmd /status`) before touching the app.
- **"Can't open the app" that is really network.** The app opens but "can't reach server." This is
  **Runbook 5 (network)**. Tell: other apps to the same server also fail; `Test-NetConnection` to
  the app's host/port fails.
- **"Non-compliant device" that is really an update.** Compliance fails on "minimum OS version" or a
  missing update. Start in **Runbook 6** to identify the failing setting, then switch to **Runbook 2**
  to actually get the update installed, then re-evaluate compliance.
- **"Blocked from resources" — Conditional Access vs. compliance.** Being blocked can come from a
  non-compliant device (Runbook 6) *or* a Conditional Access policy (Runbook 1). The sign-in log's
  Conditional Access tab names which policy applied; that decides the runbook.
- **Peripheral works in one app but not another.** The hardware and driver are fine (Runbook 3
  isolation passes), so it's an **app** problem — the app lacks permission or the wrong device is
  selected in the app. Move to **Runbook 4** (and check Windows privacy settings for camera/mic).

## Confusing single-symptom cases

- **Repeated password/MFA prompts.** Could be clock skew (fix device time — token validation fails
  when the clock is wrong), a broken PRT (`dsregcmd /status` → `AzureAdPrt : NO`), or a Conditional
  Access session policy. Check time first (cheapest), then PRT, then sign-in logs.
- **169.254.x.x address.** The adapter has no DHCP lease — treat as **no connectivity** (Runbook 5
  C1), not a DNS or app issue, even if the user reports "a website won't load."
- **Update stuck at the same percentage.** Often low disk or a pending reboot, not a corrupt update.
  Clear disk and reboot before assuming corruption or escalating.
- **Device "missing" from Intune.** Confirm you're searching the right identifier (device name vs.
  serial vs. primary user) before concluding it's unenrolled — it may simply be named differently
  (Runbook 6 C1, and see Requirement R4 asset context).

## When scope changes the answer

- **One device vs. many.** If several devices show the same symptom at once, stop working the single
  device: it's almost certainly **policy/targeting** (wrong or missing Entra group assignment — use
  DESKSUP-Set-ScopeTargeting to inspect) or a **service outage** (Runbook 5 service-owner
  escalation). Working each device individually will not fix a fleet-wide cause.
- **New device vs. existing.** A brand-new enrollment failing differently from established devices
  usually points to the enrollment profile or Autopilot/join step (Runbook 6 escalation), not the
  everyday runbook paths.

## Tooling and script edge cases

- **`Connect-MgGraph` fails or lacks scopes.** Re-run with the explicit `-Scopes` the script header
  lists; if consent is required, an admin must grant it once (Requirement R2). `Get-MgContext`
  confirms the active scopes.
- **A script returns fewer devices than expected.** The signed-in account's Intune **scope (groups)**
  may limit what it can read (Requirement R1). Confirm the technician's role scope includes the
  target devices.
- **Remediation/Set-ScopeTargeting "did nothing."** By design — both default to `-WhatIf` and only
  print the planned change. Re-run without `-WhatIf` (on a pilot first) once you've reviewed the plan.
- **Portal and script disagree.** The portal can lag; trigger **Sync** on the device and re-run the
  read-only Validation script. Persistent disagreement is itself evidence — attach both and escalate.
- **Remote Help won't connect.** Confirm Remote Help is enabled and assigned (Requirement R3), the
  user is present to consent, and the device has connectivity (Runbook 5) before assuming a Remote
  Help fault.

## When nothing fits
If a ticket matches no runbook and no edge case above: capture the standard evidence (device
name/serial, exact symptom, scope, timestamps, any error codes), run DESKSUP-Discovery/Validation
for state, and escalate to endpoint engineering with that package. An unclassifiable-but-recurring
ticket is a signal to add a new runbook — feed it back into the library (see Best Practices).
