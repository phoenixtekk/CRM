# 5. Testing Guide — Passwordless & Phishing-Resistant MFA with FIDO2 Security Keys — Government (GCC High)

Run after the pilot is configured (Implementation Step 8) and again before expanding to all staff.
This is the Government (GCC High) edition — every portal is a `*.us` URL and every script runs with
`-Environment USGov` (or `USGovDoD` for DoD).

## Test 0 — Sovereign cloud confirmed
**Do:** Sign in at `https://entra.microsoft.us`; run `FIDO2G-Discovery.ps1` (connects `-Environment USGov`).
**Expected:** Portal is a `*.us` URL and resolves your GCC High tenant; the script connects to `graph.microsoft.us` (or `dod-graph.microsoft.us`) without an endpoint error. A `.com` portal or a Commercial-Graph connection is a **fail** — you are in the wrong cloud.

## Test 1 — Methods enabled
**Do:** Entra → **Protection → Authentication methods → Policies**; check FIDO2, Windows Hello for Business, and (for DoD/federal) certificate-based auth; or run `FIDO2G-Discovery.ps1`.
**Expected:** The intended methods are **Enabled** and **Targeted** at the pilot group.

## Test 2 — User can register a phishing-resistant credential
**Do:** A pilot user goes to `https://aka.ms/mysecurityinfo` → **Add sign-in method → Security key** and registers a FIDO2 key (or enrolls Windows Hello, or verifies their CAC/PIV sign-in).
**Expected:** The credential registers without error and appears in the user's security info.

## Test 3 — Passwordless sign-in works
**Do:** The pilot user signs out and signs in using the FIDO2 key, Windows Hello, or CAC/PIV smart card.
**Expected:** Sign-in succeeds **without a password**.

## Test 4 — Registration coverage
**Do:** Run `FIDO2G-Validation.ps1 -UserId <pilot user>` and `FIDO2G-Report.ps1`.
**Expected:** The pilot user has a phishing-resistant method registered; the report shows pilot coverage rising (data pulled from US Gov Graph).

## Test 5 — Authentication strength exists
**Do:** Entra → **Protection → Authentication methods → Authentication strengths**.
**Expected:** `Phishing-Resistant – All Staff – Standard` (or the built-in Phishing-resistant MFA) lists FIDO2 / Windows Hello / (certificate-based).

## Test 6 — Conditional Access enforces the strength
**Do:** With `Phishing-Resistant – Pilot – Enforce` set to **On**, have a pilot user attempt password + SMS/push, then the phishing-resistant credential.
**Expected:** Weak methods are **blocked**; the phishing-resistant credential **succeeds**.

## Test 7 — Break-glass unaffected
**Do:** Confirm a break-glass account is excluded and can still sign in.
**Expected:** Break-glass accounts are not subject to the strength policy.

## Test 8 — Certificate-based auth counts as MFA (if used)
**Do:** A CAC/PIV user signs in with the smart card against a resource protected by the phishing-resistant strength.
**Expected:** The smart-card sign-in satisfies the strength (the authentication-binding maps the hardware certificate policy to MFA). If it is treated as single-factor, revisit the CBA binding (see `gcc-high-parity-notes.md` §3 — **verify for GCC High**).

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Sovereign** | Test 0 passes — administering and scripting on the `*.us` plane |
| **Pilot pass** | Tests 1–6 (and Test 8 where CBA is used) pass for the pilot; break-glass excluded (Test 7) |
| **Broad pass** | Coverage high for all staff (Test 4) before `Phishing-Resistant – All Staff – Enforce` is turned **On** |
