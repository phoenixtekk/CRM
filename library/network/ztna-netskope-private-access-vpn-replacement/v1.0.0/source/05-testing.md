# 5. Testing Guide — Zero Trust Network Access (ZTNA) with Netskope Private Access

Run after the pilot is steered (Implementation Step 6) and again after each expansion wave and before
each VPN cutover. Netskope console specifics are deferred to the official Netskope documentation;
these tests confirm observable behavior.

## Test 1 — Publisher healthy
Do: In the Netskope console, confirm `Publisher – <Site> – Pilot` shows connected/healthy.
Expected: The `publisher` is online and reachable by the Netskope cloud (no inbound ports opened).

## Test 2 — Client steering on the endpoint
Do: On a pilot device run `NSZTNA-Validation.ps1` (also confirm the Netskope client is enrolled).
Expected: The client is installed, enrolled, and steering private-app traffic.

## Test 3 — Entitled app is reachable
Do: As a pilot user entitled to an app, resolve and connect to `Private App – <App> – Pilot`; run
`NSZTNA-Validation.ps1` to test resolution/reachability.
Expected: The app resolves through the ZTNA path and the session connects.

## Test 4 — Least privilege enforced (non-entitled app denied)
Do: As the same user, attempt to reach an app they are not entitled to.
Expected: Access is denied — there is no broad network route; only explicitly granted apps work.

## Test 5 — Posture gate enforced
Do: Attempt access from a non-compliant / unmanaged device (or simulate the posture failing).
Expected: Access is denied or restricted per `Access Policy – <App or Role> – Pilot`; a healthy,
compliant device succeeds.

## Test 6 — Identity/group binding correct
Do: Run `NSZTNA-Validation.ps1` to confirm the user is in the expected `Access Group – <App or Role> – Pilot`,
then confirm only that app set is reachable.
Expected: Reachable apps match the user's entitlement groups exactly.

## Test 7 — VPN coexistence and fall-back
Do: With the VPN still active, disable ZTNA access for a test user and confirm the VPN still serves
the app; re-enable ZTNA.
Expected: Coexistence works — the VPN is a valid fall-back until cutover.

## Test 8 — Access and usage report
Do: Run `NSZTNA-Report.ps1`.
Expected: A clear report of who is entitled to which apps, device posture, and which apps are being
used through ZTNA.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1 to 6 pass for every pilot user/app; Test 7 confirms fall-back |
| Wave pass (before cutover) | Tests 1 to 6 and 8 pass for the wave's users and apps |
| Cutover ready | The wave passes and no app still depends on the VPN |
