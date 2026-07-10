# 5. Testing Guide — Passwordless & Passkey (FIDO2) Rollout for Microsoft Entra — Government (GCC High)

Run after the pilot configuration applies (Implementation Step 7) and again before each enforce step.
Scripts are referenced by name; all reads are read-only. This is the **Government (GCC High)** edition —
portals are the GCC High endpoints and scripts target the US Gov cloud (`-Environment USGov`). Where a
passkey/FIDO2 method appears unavailable, *verify GCC High/DoD availability against current Microsoft
Government documentation* (see `gcc-high-parity-notes.md`).

## Test 1 — Methods policy is correct
Do: Run `ENTPASSKEYG-Discovery.ps1`.
Expected: FIDO2 security key and Passkey (Authenticator) are **enabled** and targeted at the pilot
groups; Temporary Access Pass is **enabled** and scoped to recovery operators; SMS and Voice are
**still enabled** (retirement is later). No method is enabled for `All users` prematurely.

## Test 2 — Temporary Access Pass can be issued and used
Do: An `Authentication Administrator` issues a TAP for a test pilot user (`Users ->` user `->
Authentication methods -> Add -> Temporary Access Pass`); the user signs in with it and registers a
passkey.
Expected: The TAP works once (or per its setting), lets the user register a passwordless credential,
and does not linger past its lifetime.

## Test 3 — FIDO2 security key registration and sign-in
Do: A pilot admin registers a FIDO2 key at the GCC High security-info portal
(`https://mysignins.microsoft.us/security-info`), signs out, and signs back in with the key. *Verify the
current GCC High URL.*
Expected: Registration completes (attestation/key-restriction rules honored if set); sign-in succeeds
with the key and a local gesture — no password entered.

## Test 4 — Passkey (Authenticator) registration and sign-in
Do: A pilot user registers a passkey in Microsoft Authenticator (prompted by the campaign), then
signs in passwordless.
Expected: The passkey registers and sign-in completes with the phone gesture. *If the passkey option
is absent, verify the method's availability/preview status in your tenant and Authenticator version.*

## Test 5 — Registration campaign nudges the pilot
Do: A pilot user in `Passwordless Registration Campaign - Pilot - Pilot` signs in interactively.
Expected: They are prompted to set up the passkey/Authenticator method (with the configured snooze),
and can complete it inline.

## Test 6 — Phishing-resistant CA policy evaluates (report-only)
Do: Run `ENTPASSKEYG-Validate.ps1`; review `Conditional Access -> Insights and reporting` and
`ENTPASSKEYG-Report.ps1` for the report-only result of `Require Phishing-Resistant MFA - Admins -
Report-Only`.
Expected: For a pilot admin the policy shows it **would require** phishing-resistant MFA; for the
break-glass accounts it shows **not applied / excluded**. No user is actually blocked yet.

## Test 7 — Enforcement requires phishing-resistant MFA
Do: After flipping the admins policy to `Enforce`, have a pilot admin attempt sign-in with only a
weak method (for example password + SMS) to a targeted app.
Expected: Access is blocked until they use the FIDO2 key or passkey; the same admin succeeds with the
phishing-resistant credential.

## Test 8 — Break-glass is never blocked
Do: Sign in with a break-glass account against the enforced policy scope (in a controlled test).
Expected: The break-glass account is excluded and signs in — confirming the rollout cannot lock out
emergency access.

## Test 9 — Adoption is measurable
Do: Run `ENTPASSKEYG-Report.ps1`.
Expected: A per-group breakdown of who has registered a phishing-resistant method versus who is still
on password + weak MFA — the number you gate weak-method retirement on.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1-6 and 8 pass; pilot admins and users sign in passwordless; the CA policy is clean in report-only and excludes break-glass |
| Enforce pass | Test 7 passes for admins; Test 8 still passes; sensitive-apps policy report-only is clean |
| Expand/retire pass | Test 9 shows high adoption for a wave before SMS/Voice are scoped out for that wave; no lock-outs after retirement |
