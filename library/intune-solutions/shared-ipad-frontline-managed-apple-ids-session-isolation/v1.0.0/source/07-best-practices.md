# 7. Best Practices — Shared iPad for Frontline Teams

## Architecture

- **Fix the architecture, not the symptom.** Every hour spent tuning Outlook settings on a single-user
  iPad passed between shifts is an hour wasted. There is no app configuration that produces per-user
  data separation on a device that has no per-user boundary. Deploy Shared iPad, or accept a partial
  fix and say so.
- **Decide A vs B explicitly, in writing, with the customer.** Shared iPad (OS-level) and Microsoft 365
  Shared Device Mode (app-level) solve different amounts of the problem. Write the decision and its
  rationale down. A customer who thinks they bought OS-level isolation and got app-level isolation has
  a grievance you will be defending in six months.
- **Deploy Option A first, and validate it, before layering Option B.** Layering SDM on a broken Shared
  iPad deployment hides the real fault and makes the failure harder to diagnose. Get the session test
  passing on Shared iPad alone, then add SDM and re-run the test.
- **Never assert the Microsoft SDM supported-app list from memory.** It changes. Check Microsoft's
  current documentation each time you design around it. A design built on a stale list fails at
  validation, in front of the customer.
- **Never carry Apple's numbers forward from an old project.** The Shared iPad minimum iPadOS version,
  the storage minimums, and the maximum resident-user count change. Check Apple's current
  documentation every time. This is the single most common way an experienced engineer gets it wrong.

## The Apple ID reclamation campaign

- **Run the conflict discovery FIRST, before you promise a date.** The size of the conflict list
  determines the project timeline more than any technical task. Find out on day one, not week six.
- **Never let the technical team make the reclamation decision by default.** Asking staff to change a
  personal Apple ID reaches their personal iPhone, their family photos, and their App Store purchases.
  That is an HR, legal, and identity decision. Put the options in front of the customer's HR, legal,
  and identity owners, get the decision in writing, and then execute it. "The engineer ran a script and
  everyone got an email from Apple" is how a project becomes an incident.
- **Get executive sponsorship before the first notification goes out.** No sponsor, no comms plan, no
  agreed grace period → do not send anything. This is Requirement R18 and it is the one most often
  skipped.
- **Consider the subdomain option early.** Issuing Managed Apple IDs on a subdomain staff have never
  used personally (e.g. `staff.contoso.com`) may sidestep the conflict entirely and turn a
  personal-data confrontation into a non-event. **Verify with Apple** that it fits your ABM/federation
  design before proposing it — but raise it early, because it is much harder to switch to once the
  campaign has started.
- **Track the campaign in the CSV, not in someone's head.** `SHAREDIPAD-AppleIDConflict.ps1` emits
  tracking columns for a reason. A 40-person campaign with a tail of non-responders needs a list.
- **ABM is the truth; the script is the tracker.** Never present the script's candidate list to a
  customer as a conflict list. It is not one, and saying it is will cost you credibility when the
  numbers disagree with ABM.
- **Give staff a real support path, not just a deadline.** The people you are asking to change their
  Apple ID are field workers mid-shift. A deadline without help produces refusals.

## Devices and procurement

- **Establish ABM device eligibility before you scope the project.** Serials not in ABM cannot be
  ADE-enrolled and cannot run Shared iPad. On an inherited fleet bought piecemeal over years, this is
  frequently a procurement conversation, not a configuration one. Find out in the Assess phase.
- **Size storage for the resident-user count, and buy accordingly.** Under-specced iPads produce
  sign-in failures and user eviction at exactly the moment the fleet goes live. Storage is cheap at
  purchase and expensive at wave 4.
- **Set the maximum cached users to what the hardware can actually carry** — not to the number of staff
  on the roster. A device configured for more users than it can hold does not warn you; it fails.
- **Use VPP / ABM-licensed apps rather than store apps where you can.** A Shared iPad has no personal
  App Store identity; device-licensed apps sidestep a whole class of install failure.
- **Pilot the CMMS app before you commit the fleet.** Ask the vendor, in writing, whether the app
  supports Apple Shared iPad. If it does not honour the per-user boundary, you will find out at Test 5
  — and no Intune setting will fix it.

## Configuration

- **Use the allowlist, not a blocklist.** A blocklist of apps to hide is obsolete the moment a new app
  exists. Name what is permitted and hide the rest.
- **Do not lock to a single app.** Kiosk single-app mode is right for an appliance and wrong here — the
  field workload spans several apps and the user must be able to reach sign-out.
- **Block account modification.** It is the setting that stops a shift worker adding their personal
  Apple ID or personal mail to a field iPad, and it is the one people forget.
- **Block predictive keyboard and autofill.** Shared keyboard state leaks identity across shifts. It is
  a small setting and a real disclosure.
- **Keep Camera allowed.** It is part of the workload. Locking down the thing the field team actually
  needs is how a deployment gets worked around.
- **Confirm Safari with the field team before blocking it.** If the CMMS relies on the browser for SSO
  or for opening links, blocking Safari breaks the workload — and the failure will look like a CMMS
  problem.

## Naming and hygiene

- **Use the object names verbatim, everywhere.** `SHARED IPAD – FMD – Pilot`,
  `SHARED IPAD – FMD – Production`, `SHARED IPAD – ADE Profile – Shared`, `SHARED IPAD – Restrictions –
  Field Lockdown`, `SHARED IPAD – Compliance – iPadOS`, `SHARED IPAD – Apps – Field Allowlist`,
  `PILOT – Shared iPad Users`. The scripts match on exact display names, and the names use an **en dash
  (–)**, not a hyphen. A renamed object is an object the scripts cannot find and the next engineer
  cannot audit.
- **Keep Pilot and Production as separate groups permanently.** Do not collapse them after rollout.
  The next iPadOS change, the next app version, the next policy tweak all need somewhere safe to land
  first.
- **Use a company-owned Apple ID for the APNs certificate and record it.** A certificate created on a
  departed employee's personal Apple ID cannot be renewed, and the remedy is re-enrolling every managed
  device in the tenant.

## Operations

- **Calendar both annual expiries the day you create them** — the APNs certificate and the ADE token.
  An expired APNs certificate breaks the entire fleet's management silently. An expired ADE token stops
  every new enrollment.
- **Verify the Provisioning Client group owner before every wave.** It is one click to check and a lost
  afternoon to diagnose. The failure — an empty group and nothing deploying — looks exactly like a
  policy problem.
- **Stage in waves of 8–10, never in one weekend.** A shift without devices is a shift not working.
  Validate each wave before starting the next.
- **Spot-check the session-isolation test on one device per wave.** Not just wave 1. Configuration
  drifts, and the test is cheap.
- **Brief the field team before their devices are staged.** Shared iPad gives a clean device *after*
  sign-out. A user who does not know to sign out leaves an open session on the rack — the one
  operational gap the architecture does not close for you. Print the handover runbook (Testing §5) and
  put it on the rack.
- **Designate a handover station with known-good Wi-Fi.** Sign-in and sign-out are network operations.
  A sign-out attempted in a dead spot in the yard is a sign-out that may not complete.
- **Keep the `SHAREDIPAD-Report.ps1` CSV as the as-built record**, and re-run it periodically. It is
  your evidence that the fleet is still in the state you left it.

## Scripts

- **Run everything read-only first.** Four of the five scripts cannot change anything. The fifth
  defaults to `-WhatIf` and requires an explicit `-WhatIf:$false`. Read the dry-run output before you
  apply — that is what it is for.
- **Never present a script PASS as proof of session isolation.** `SHAREDIPAD-Validate.ps1` proves the
  architecture exists. Only the A/B test with two real humans proves the sessions are isolated. That
  distinction is the difference between a delivered project and a callback.
- **Scope `SHAREDIPAD-AppleIDConflict.ps1` to a group or domain.** An unscoped tenant-wide worklist is
  a list nobody can action.
