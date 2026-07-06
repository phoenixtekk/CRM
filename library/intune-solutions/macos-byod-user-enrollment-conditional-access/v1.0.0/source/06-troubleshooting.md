# 6. Troubleshooting — macOS BYOD Management: Account-Driven User Enrollment, App Protection & Conditional Access

Work top-down: confirm the **enrollment** (personal Mac onboards), then the **compliance signal**, then
the **Conditional Access gate**, and only then the **user experience**. Most failures are macOS blocked
by an enrollment restriction, an OS below the account-driven-enrollment floor, a compliance policy not
assigned, or a CA policy scoped/graded incorrectly. When in doubt, re-run `MACBYOD-Discovery.ps1` and
`MACBYOD-Validation.ps1` after each change.

## The "Sign in to Work or School account" option doesn't enrol / no managed scope appears
- **macOS not allowed.** Intune → **Devices → Enrollment → Enrollment device platform restrictions →
  macOS**; set **Personally owned devices = Allow** (R1).
- **OS below the floor.** Account-driven **user** enrollment needs a modern macOS; update the Mac (R2).
  If unsure of the exact minimum, **flag it and confirm** against Microsoft's current documentation —
  don't guess.
- **Account-driven user enrollment not enabled.** Confirm the enrollment type is configured for macOS and
  targets `BYOD-Mac-Pilot` (Implementation Step 4).
- **Managed Apple Account path missing.** The corporate scope needs a **managed Apple Account** (R3);
  coordinate with your Apple identity owner. Do **not** silently switch to device enrollment to force it.

## The whole Mac got managed / personal data looks managed
- **Wrong model.** This is the symptom of **device enrollment (Model B)**, not **account-driven user
  enrollment (Model A)**. Account-driven user enrollment manages only a **separate managed volume**.
  Remove the enrollment, correct **Implementation Step 4** to the account-driven **user** enrollment
  type, and re-onboard.

## Device enrolled but **no compliance state** / shows Not evaluated
- **Compliance policy not assigned.** Confirm `macOS BYOD Compliance - Pilot` is assigned to
  `BYOD-Mac-Pilot` (R4). Without assignment there is no signal, and Conditional Access can't require it.
- **Sync pending.** Give Intune time to evaluate, or force a sync; re-run
  `MACBYOD-Validation.ps1 -Serial the-device-serial`.

## Device shows **Noncompliant**
- **OS below the compliance floor** — update macOS (R2), or lower the floor if BYOD-appropriate.
- **A health setting is failing** (e.g. SIP/encryption) — review the failing setting in
  Intune → device → **Compliance** and address it; keep BYOD compliance **minimal** so you're not failing
  personal Macs on corporate-only controls.

## Conditional Access blocks a legitimate compliant Mac
- **Grant control mismatch.** The policy must grant on **Require device to be marked as compliant**
  (Implementation Step 8). If it also requires hybrid-join, a BYOD user-enrolled Mac will fail — hybrid
  join is not the BYOD control.
- **Platform condition too broad/narrow.** Ensure the **Device platforms** condition includes **macOS**
  and isn't accidentally excluding it.
- **Not actually compliant yet.** Confirm the Mac reports **Compliant** first (see above); the CA gate is
  only as good as the compliance signal beneath it.

## Conditional Access lets an **unmanaged** Mac through
- **Grant not enforcing compliance.** Confirm the grant is **Require compliant** and the policy is **On**
  (not report-only). Remember: an **unmanaged** Mac has **no compliance state**, so a require-compliance
  policy should block it — if it's getting through, the policy isn't applying (check user/app/platform
  scope).

## Locked out after enabling the CA policy
- **Use a break-glass account.** Sign in with one of your two excluded **emergency access** accounts
  (R6), set the policy back to **report-only**, fix the scope/exclusions, and re-test. This is exactly
  why break-glass accounts and report-only-first are mandatory.

## "But I expected App Protection Policies to cover the Mac apps"
- **They don't — this is expected, not a bug.** Intune **App Protection Policies (MAM)** cover iOS/Android
  apps, **not** arbitrary macOS apps. On macOS the protection boundary is **enrollment + compliance +
  Conditional Access**. Re-set the expectation (Solution Overview, honest note) and gate access with CA
  rather than looking for a macOS MAM container that doesn't exist.

## Off-boarding wiped the whole Mac / affected personal data
- **Wrong action or wrong model.** For account-driven user enrollment, removing the work account (or
  retiring the device) removes **only** the managed data. If a full wipe happened, a device-level
  retire/wipe action was used or the device was **device-enrolled** — avoid wipe actions on BYOD and
  confirm the enrollment model.

## Useful checkpoints
- **Intune:** Devices → macOS → (device) → **Hardware / Compliance / Configuration**; Enrollment →
  platform restrictions; Compliance policies → assignment.
- **Entra:** Protection → **Conditional Access** → policy state (report-only vs on) and user/exclusion
  scope; **Sign-in logs** → filter to the pilot user/macOS to see which policies applied and the result.
- **On the Mac:** **System Settings → General → Device Management / Profiles** (managed scope present);
  the user's **Work or School account** entry.
- **Scripts:** re-run `MACBYOD-Validation.ps1` after each change to confirm the gate; `MACBYOD-Report.ps1`
  for the fleet-wide posture.
