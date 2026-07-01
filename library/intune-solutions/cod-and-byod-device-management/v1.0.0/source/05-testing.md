# 5. Testing & Validation — Corporate-Owned (COD) & BYOD Device Management

Validate against a **pilot user with two devices** (one corporate, one personal) before expanding.
Each test has an explicit **pass/fail gate**. Use the included PowerShell scripts (Microsoft Graph)
for tenant-side checks and the on-device steps for the user experience.

## Test 1 — Tenant readiness
**Procedure:** Run `CODBYOD-Discovery.ps1`.
**Pass:** Enrollment restrictions allow the intended Personal/Corporate split, an App Protection
policy exists, a compliance policy exists, Corporate/Personal **device filters** exist, Company Portal
is assigned, and a Conditional Access policy is present.
**Fail:** Any missing → resolve before piloting.

## Test 2 — Single identity, two devices
**Procedure:** Run `CODBYOD-Validation.ps1 -User <upn>` for the pilot user.
**Pass:** The **same UPN** owns at least one **Corporate** device and one **Personal** device.
**Fail:** Devices split across different accounts → consolidate identity (Requirements R1).

## Test 3 — Corporate device gets full MDM
**Procedure:** Inspect the pilot **corporate** device in Intune.
**Pass:** Ownership = **Corporate**; the **compliance** and **configuration** policies (Corporate
filter) are **applied**; device reports **Compliant**.
**Fail:** Policies not applied → confirm the device is tagged Corporate (R5) and the Corporate filter
is set on the assignment (Implementation §5–6).

## Test 4 — Personal device gets App Protection only
**Procedure:** On the pilot **personal** device, sign into Outlook/Edge with the pilot account.
**Pass:** The App Protection policy applies — **PIN prompt**, corporate data confined to managed apps,
**Save As**/paste to personal locations blocked. The device is **not** fully enrolled (or, if
personally enrolled, is tagged **Personal** and does **not** receive Corporate device policies).
**Fail:** No PIN/containment → confirm the app is approved/managed and the App Protection policy is
assigned to the user (Implementation §7).

## Test 5 — Ownership filters route correctly
**Procedure:** Compare policy application across the two devices.
**Pass:** The **Corporate** device receives device compliance/config and **not** the BYOD-only items;
the **Personal** device receives app protection and **not** corporate device policies.
**Fail:** Cross-application → re-check the `deviceOwnership` filter rules and the Include/Exclude on
each assignment (Implementation §4).

## Test 6 — One account reaches work from both devices
**Procedure:** With Conditional Access **report-only**, access a corporate web app from the corporate
device and a managed app from the personal device, signed in as the same user.
**Pass:** Both succeed — the corporate device satisfies **compliant device**; the personal device
satisfies **app protection policy** — under the **single** CA policy.
**Fail:** One path blocked → review CA grant controls ("require one of"), compliance state, and app
protection assignment (Implementation §9).

## Test 7 — Unmanaged path is blocked (data protection holds)
**Procedure:** On the personal device, try to open corporate mail in the **built-in** (unmanaged) mail
app or paste corporate data into a personal app.
**Pass:** Corporate data is **not** accessible in unmanaged apps; paste/Save-As to personal locations
is blocked.
**Fail:** Corporate data leaks to unmanaged apps → tighten App Protection data-relocation settings.

## Test 8 — Compliance & enforcement
**Procedure:** Review compliance for the corporate device and the report-only CA results for the user.
**Pass:** Corporate device **Compliant**; CA evaluates the user correctly from both devices.
**Fail:** Non-compliant or CA misfires → review the compliance policy and CA conditions.

## Acceptance gate
Proceed to **Expand** only when Tests 1–8 pass for a pilot user who has **both** a corporate and a
personal device signed in with the **same account**, and the data-protection checks (Test 7) hold.
