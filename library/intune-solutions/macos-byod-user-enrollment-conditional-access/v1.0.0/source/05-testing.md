# 5. Testing & Validation — macOS BYOD Management: Account-Driven User Enrollment, App Protection & Conditional Access

Validate against a **pilot Mac** and the **`BYOD-Mac-Pilot`** group before expanding. Each test has an
explicit **pass/fail gate**. Use the included PowerShell scripts (Microsoft Graph) for tenant-side
checks and the on-device steps for the user experience. Keep the Conditional Access policy in
**report-only** until Tests 1–6 pass.

## Test 1 — Tenant readiness
**Procedure:** Run `MACBYOD-Discovery.ps1`.
**Pass:** macOS enrollment **allowed**; account-driven user enrollment present/enabled (or clearly
flagged as not yet enabled); a macOS **compliance policy** (`macOS BYOD Compliance - Pilot`) exists; and
the CA policy state is reported. No blocking FAIL.
**Fail:** Any prerequisite missing → resolve using the Requirements guide before onboarding devices.

## Test 2 — Personal Mac enrolls (account-driven user enrollment)
**Procedure:** As a pilot user on their **own** Mac, add the **Work or School account** in **System
Settings** and complete sign-in.
**Pass:** The Mac appears in **Intune → Devices → macOS** as **personally owned**, enrollment type
**account-driven user enrollment**; a **managed Apple Account** and separate managed volume were
provisioned; the user's personal Apple ID/data are untouched.
**Fail:** No enrollment → confirm macOS is **Allowed** (R1), the OS floor is met (R2), and the managed
Apple Account path exists (R3). Do **not** substitute device enrollment to "make it work" — flag it.

## Test 3 — Managed scope is isolated (privacy)
**Procedure:** On the enrolled Mac, confirm corporate apps/data live in the managed scope while personal
apps/data remain separate.
**Pass:** Managed (corporate) data is present in the managed volume; personal data/apps are unaffected;
removing the work account would remove **only** managed data.
**Fail:** Personal data appears managed, or the whole device is under management → you likely used
**device enrollment** (Model B), not **account-driven user enrollment** (Model A). Re-check Step 4 of
Implementation.

## Test 4 — Compliance signal reports
**Procedure:** Intune → **Devices → macOS → (device) → Compliance**, or run
`MACBYOD-Validation.ps1 -Serial the-device-serial`.
**Pass:** The Mac evaluates against **`macOS BYOD Compliance - Pilot`** and reports **Compliant**.
**Fail:** No compliance state → the policy isn't assigned to `BYOD-Mac-Pilot` (R4); **Noncompliant** →
address the failing setting (usually OS version) and re-sync.

## Test 5 — Conditional Access (report-only) predicts the right outcome
**Procedure:** With `CA - Require Compliant Mac - Pilot` in **report-only**, have the pilot user sign in
to a gated app (e.g. `https://outlook.office.com`) from the enrolled Mac; then attempt from an
**unmanaged** Mac. Review Entra → **Sign-in logs** (or run `MACBYOD-Report.ps1`).
**Pass:** The log shows the policy **would allow** the **compliant, enrolled** Mac and **would block**
the **unmanaged/non-compliant** Mac. Break-glass accounts are excluded.
**Fail:** Would block a legitimate compliant Mac → check the grant control and platform condition
(Implementation Step 8); would allow an unmanaged Mac → confirm the grant is **Require compliant** and
the macOS platform condition is set.

## Test 6 — Enforce the gate for the pilot
**Procedure:** Set `CA - Require Compliant Mac - Pilot` to **On**. Re-test from a compliant enrolled Mac
and from an unmanaged Mac.
**Pass:** Compliant enrolled Mac → **access granted**; unmanaged/non-compliant Mac → **access blocked**;
break-glass account (excluded) → still able to sign in.
**Fail:** Legitimate user locked out → revert to report-only, correct scope/exclusions, and re-test.
Use a **break-glass** account if you lose admin access.

## Test 7 — App-protection expectation is correct (honesty check)
**Procedure:** Confirm your internal messaging and controls match how macOS actually protects data.
**Pass:** Protection for BYOD Macs is delivered by **enrollment + compliance + Conditional Access** — not
by an iOS-style App Protection Policy. No one is relying on macOS "MAM" that doesn't exist.
**Fail:** Someone expects per-app containerization/selective in-app wipe on arbitrary Mac apps → correct
the expectation (Solution Overview, honest note). Gate access via CA instead.

## Test 8 — Selective removal on off-boarding
**Procedure:** Have a pilot user remove the **Work or School account** (or retire the device in Intune).
**Pass:** Only the **managed** volume/data is removed; the personal Mac remains intact and usable; the
device drops out of the compliant set and the CA gate would block corporate access.
**Fail:** Whole device wiped or personal data affected → the wrong enrollment model was used; re-check
that this is **account-driven user enrollment** (Model A).

## Acceptance gate
Proceed to **Expand** only when Tests 1–8 pass on at least one pilot Mac, the CA policy enforces the
intended allow/block outcome with break-glass excluded, and a real pilot user confirms the privacy
boundary (personal data untouched, only managed data removable).
