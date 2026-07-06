# 5. Testing Guide — macOS Compliance & Conditional Access for Zero-Trust Access

Run these during Report-only (Implementation Step 6) and again after enabling enforcement (Step 8).
Core proof: **compliant Mac → allowed; non-compliant Mac → denied.**

## Test 1 — Compliance policy evaluates each signal
**Do:** Intune → **Devices → Compliance → `macOS - Zero-Trust Compliance` → Device status**. Run
**`MACCA-Validation.ps1`**.
**Expected:** Pilot Macs show **Compliant**, or the exact failing signal (encryption / OS / firewall /
machine-risk) is named.

## Test 2 — CA policy evaluates in Report-only
**Do:** Entra → **Monitoring → Sign-in logs →** open a pilot Mac sign-in → **Report-only** tab.
**Expected:** `CA - macOS - Require Compliant Device` shows a result — proving the policy evaluates
macOS sign-ins.

## Test 3 — Compliant Mac is allowed
**Do:** From a **Compliant** pilot Mac, sign in to `https://outlook.office.com`. Run
**`MACCA-Report.ps1`**.
**Expected:** Access granted; the report maps this Mac to **Compliant → allow**.

## Test 4 — Non-compliant Mac is denied
**Do:** On a test Mac, fail one signal (FileVault off, below the OS floor, firewall off, or elevated
Defender risk). After Intune marks it **Not compliant**, attempt the same sign-in.
**Expected:** Report-only logs **would block**; after enforcement the sign-in is **blocked**.
`MACCA-Report.ps1` maps this Mac to **Not compliant → deny**.

## Test 5 — Each signal independently trips compliance
**Do:** One at a time on a test Mac: disable FileVault; drop below the OS floor; disable the firewall;
(if Defender in use) raise machine risk.
**Expected:** Each single failure flips the Mac **Not compliant** on its own — confirming all four
signals are wired in, not just one.

## Test 6 — Policy scoping is macOS-only
**Do:** From a Windows or mobile device (same pilot user), sign in to the same resource.
**Expected:** `CA - macOS - Require Compliant Device` does **not** apply (Device platforms = macOS) —
proving this policy touches only Macs.

## Test 7 — Break-glass / exclusions are exempt
**Do:** Sign in with a break-glass account (or an account in `macOS-ZeroTrust-Exclusions`).
**Expected:** The macOS compliant-device policy does **not** apply — the account is excluded and is
never locked out.

## Test 8 — Grace period behaves as configured
**Do:** With a grace period set, make a Compliant Mac non-compliant and watch the status over the
grace window.
**Expected:** The Mac shows **In grace period** (still allowed) until the window expires, then flips to
**Not compliant** and is blocked — confirming users get a warning window, not an instant lockout.

## Test 9 — Access-decision report
**Do:** Run **`MACCA-Report.ps1`** across the pilot.
**Expected:** A clear per-Mac list of compliance state and allow/deny decision, with counts — the
artifact you use to sign off each rollout wave.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass (Report-only)** | Tests 1–7 behave as expected; compliant Macs would be allowed, non-compliant would be blocked, **no unexpected** would-blocks for healthy Macs |
| **Enforcement pass** | After enabling On: compliant Macs work, a non-compliant Mac is actually blocked, break-glass verified, grace period behaves (Test 8), no unintended lockouts |
