# 5. Testing Guide — Passwordless & Phishing-Resistant MFA with FIDO2 Security Keys

Run after the pilot is configured (Implementation Step 8) and again before expanding to all staff.

## Test 1 — Methods enabled
**Do:** Entra → **Protection → Authentication methods → Policies**; check FIDO2 and Windows Hello for Business; or run `FIDO2-Discovery.ps1`.
**Expected:** FIDO2 and Windows Hello for Business are **Enabled** and **Targeted** at the pilot group.

## Test 2 — User can register a FIDO2 key
**Do:** A pilot user goes to `https://aka.ms/mysecurityinfo` → **Add sign-in method → Security key** and registers a FIDO2 key.
**Expected:** The key registers without error and appears in the user's security info.

## Test 3 — Passwordless sign-in works
**Do:** The pilot user signs out and signs in using the FIDO2 key (or Windows Hello).
**Expected:** Sign-in succeeds **without a password**.

## Test 4 — Registration coverage
**Do:** Run `FIDO2-Validation.ps1 -UserId <pilot user>` and `FIDO2-Report.ps1`.
**Expected:** The pilot user has a phishing-resistant method registered; the report shows pilot coverage rising.

## Test 5 — Authentication strength exists
**Do:** Entra → **Protection → Authentication methods → Authentication strengths**.
**Expected:** `Phishing-Resistant – All Staff – Standard` (or the built-in Phishing-resistant MFA) lists FIDO2 / Windows Hello / (certificate-based).

## Test 6 — Conditional Access enforces the strength
**Do:** With `Phishing-Resistant – Pilot – Enforce` set to **On**, have a pilot user attempt password + SMS/push, then the phishing-resistant credential.
**Expected:** Weak methods are **blocked**; the phishing-resistant credential **succeeds**.

## Test 7 — Break-glass unaffected
**Do:** Confirm a break-glass account is excluded and can still sign in.
**Expected:** Break-glass accounts are not subject to the strength policy.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–6 pass for the pilot group; break-glass excluded (Test 7) |
| **Broad pass** | Coverage high for all staff (Test 4) before `Phishing-Resistant – All Staff – Enforce` is turned **On** |
