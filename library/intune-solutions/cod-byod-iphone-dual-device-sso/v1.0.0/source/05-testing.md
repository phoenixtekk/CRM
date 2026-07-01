# 5. Testing & Validation — Dual-Device iPhone (Personal + Corporate iOS) Management with Single Sign-On

Validate against a **pilot user with two iPhones** (one corporate, one personal) before expanding.
Each test has an explicit **pass/fail gate**. Use the included PowerShell scripts (Microsoft Graph)
for tenant-side checks and the on-device steps for the user experience.

## Test 1 — Tenant readiness
**Procedure:** Run `IOSDD-Discovery.ps1`.
**Pass:** The APNs certificate is **Active**, the ADE token is present, enrollment restrictions allow
the intended Personal/Corporate split, an App Protection policy exists, a compliance policy exists,
the `iPhone – Corporate`/`iPhone – Personal` **device filters** exist, Authenticator + Company Portal
are assigned, and a Conditional Access policy is present.
**Fail:** Any missing → resolve before piloting.

## Test 2 — Single identity, two iPhones
**Procedure:** Run `IOSDD-Validation.ps1 -User <upn>` for the pilot user.
**Pass:** The **same UPN** owns at least one **Corporate** iPhone and one **Personal** iPhone.
**Fail:** Devices split across different accounts → consolidate identity (Requirements R1).

## Test 3 — Corporate iPhone gets full MDM
**Procedure:** Inspect the pilot **corporate** iPhone in Intune.
**Pass:** Ownership = **Corporate**, **Supervised = Yes**; the **`iPhone – Compliance – COD – Pilot`**
and **`iPhone – Configuration – COD – Pilot`** policies (Corporate filter) are **applied**; device
reports **Compliant**.
**Fail:** Policies not applied → confirm the iPhone is tagged Corporate via ADE (R5) and the
`iPhone – Corporate` filter is set on the assignment (Implementation §§5, 8–9).

## Test 4 — Personal iPhone gets App Protection only
**Procedure:** On the pilot **personal** iPhone, sign into Outlook/Edge with the pilot account.
**Pass:** The `iPhone – App Protection – BYOD – Pilot` policy applies — **PIN prompt**, corporate data
confined to managed apps, **Save As**/paste to personal locations blocked. The iPhone is **not** fully
enrolled (or, if User-Enrolled, is tagged **Personal** and does **not** receive Corporate device
policies).
**Fail:** No PIN/containment → confirm the app is approved/managed and the App Protection policy is
assigned to the user (Implementation §10).

## Test 5 — Ownership filters route correctly
**Procedure:** Compare policy application across the two iPhones.
**Pass:** The **Corporate** iPhone receives device compliance/config and **not** the BYOD-only items;
the **Personal** iPhone receives app protection and **not** corporate device policies.
**Fail:** Cross-application → re-check the `deviceOwnership` filter rules and the Include/Exclude on
each assignment (Implementation §5).

## Test 6 — Single sign-on across both iPhones
**Procedure:** On the **corporate** iPhone, open a Microsoft 365 web app in **Safari**; on the
**personal** iPhone, after the first managed-app sign-in, open a second approved app (e.g. Teams).
**Pass:** The corporate iPhone gets **silent SSO** (no password prompt — the iOS Enterprise SSO
extension at work); the personal iPhone's second app opens **without** a fresh password (the
Authenticator broker at work) — one account, silent SSO on both.
**Fail:** Repeated prompts → confirm Microsoft Authenticator is installed on both iPhones and the
`iPhone – Enterprise SSO – COD – Pilot` profile is applied to the corporate iPhone (Implementation
§§12–13).

## Test 7 — One account reaches work from both iPhones
**Procedure:** With Conditional Access **report-only**, access a corporate web app from the corporate
iPhone and a managed app from the personal iPhone, signed in as the same user.
**Pass:** Both succeed — the corporate iPhone satisfies **compliant device**; the personal iPhone
satisfies **app protection policy** — under the **single** CA policy.
**Fail:** One path blocked → review CA grant controls ("require one of"), compliance state, and app
protection assignment (Implementation §15).

## Test 8 — Unmanaged path is blocked (data protection holds)
**Procedure:** On the personal iPhone, try to open corporate mail in the **built-in** (unmanaged) Mail
app or paste corporate data into a personal app.
**Pass:** Corporate data is **not** accessible in unmanaged apps; paste/Save-As to personal locations
is blocked.
**Fail:** Corporate data leaks to unmanaged apps → tighten App Protection data-relocation settings.

## Test 9 — Compliance & enforcement
**Procedure:** Review compliance for the corporate iPhone and the report-only CA results for the user.
**Pass:** Corporate iPhone **Compliant**; CA evaluates the user correctly from both iPhones.
**Fail:** Non-compliant or CA misfires → review the compliance policy and CA conditions.

## Acceptance gate
Proceed to **Expand** only when Tests 1–9 pass for a pilot user who has **both** a corporate and a
personal iPhone signed in with the **same account**, single sign-on works on both (Test 6), and the
data-protection checks (Test 8) hold.
