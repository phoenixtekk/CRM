# Executive Summary

## The situation
A user enrolling an iPhone or iPad into Microsoft Intune hits an **"Access Denied — you are not
authorized to view this page"** screen, with a block of **Diagnostic information for IT** (Activity Id,
Session Id, Timestamp). Enrollment stops. This is **not** a device fault — it is a **tenant-side
authorization gate** (licensing, MDM scope, an enrollment restriction, or Conditional Access) refusing
the enrollment.

## Why it matters
Blocked enrollment means the device can't be managed, secured, or brought into compliance — and the
user can't reach corporate resources that require a managed device. Guessing at the cause wastes hours in
trial-and-error re-enrollment and can leave a security gap open. The good news: the IDs on the screen make
this a **deterministic** diagnosis, not guesswork.

## The approach
This solution turns the on-screen diagnostic IDs into an exact root cause and a scoped fix:

1. **Capture** the Activity Id / Session Id / Timestamp / UPN from the failure screen.
2. **Read** the failed enrollment sign-in in the Entra sign-in logs — its failure reason and Conditional
   Access result name the gate.
3. **Confirm** the gate — license, MDM user scope, enrollment restriction, or Conditional Access — with a
   dedicated PowerShell check that turns each into a yes/no answer.
4. **Remediate** the single blocking gate, then **re-enroll and validate** that the same sign-in now
   succeeds and the device appears in Intune.
5. **Prevent** recurrence by fixing the class problem (scope group, restriction assignment, CA pattern).

## What you get
- A click-by-click **root-cause-and-remediation runbook** covering every common gate in likelihood order.
- **Five PowerShell tools** — the failed enrollment sign-in reader, plus license, MDM-scope,
  enrollment-restriction, and Conditional-Access checks.
- **Testing, Troubleshooting/FAQ, and Best-Practice** guidance, with GCC High notes inline.

## The outcome
A two-minute root cause from evidence instead of trial-and-error, a surgical fix that doesn't weaken your
other controls, the device enrolled and managed, and a prevention step so the next user doesn't hit the
same wall. One fixed price; re-run the method for every future "Access Denied" enrollment.
