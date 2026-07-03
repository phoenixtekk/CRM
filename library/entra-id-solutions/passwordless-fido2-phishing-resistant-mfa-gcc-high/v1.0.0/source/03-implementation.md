# 3. Implementation Guide — Passwordless & Phishing-Resistant MFA with FIDO2 Security Keys — Government (GCC High)

Follow these steps **in order**, in the **sovereign** Microsoft Entra admin center
(`https://entra.microsoft.us`). This is the Government (GCC High) edition — every portal is a `*.us`
URL and every script uses `-Environment USGov` (or `USGovDoD` for DoD).

> **Model:** Enable the methods, get a **pilot** registered, create a phishing-resistant
> authentication strength, require it via Conditional Access on the pilot, validate, then expand to
> all staff. Registration always leads enforcement so no one is locked out.
>
> **Naming convention** — every object uses `<Purpose> – <Scope> – <Stage>`. Create these and reuse the names verbatim:
> - Groups: `Phishing-Resistant – Pilot – Users`, `Phishing-Resistant – All Staff – Users`
> - Authentication strength: `Phishing-Resistant – All Staff – Standard`
> - Conditional Access (pilot): `Phishing-Resistant – Pilot – Enforce`
> - Conditional Access (broad): `Phishing-Resistant – All Staff – Enforce`
>
> **GCC High caveat (read first):** the core methods (FIDO2, Windows Hello for Business,
> certificate-based auth) and Conditional Access authentication strengths are **GA in US Gov**.
> **Authenticator passkeys, cross-device/QR passkeys, synced passkeys, Temporary Access Pass, and the
> registration campaign are "verify for GCC High"** — confirm each is present in *your* sovereign
> tenant before relying on it (see `gcc-high-parity-notes.md`). Where a feature is absent, use the
> stated fallback.

## Step 1 — Create the groups
1. Entra (`entra.microsoft.us`) → **Groups → New group** → **Security** → name `Phishing-Resistant – Pilot – Users` (a few representative users + admins). **Create**.
2. Create `Phishing-Resistant – All Staff – Users` (everyone in scope). **Create**.
   *(Or build both with `FIDO2G-Set-ScopeTargeting.ps1` — default `-WhatIf`.)*

## Step 2 — Enable FIDO2 security keys
1. Entra → **Protection → Authentication methods → Policies → FIDO2 security key** (or *Passkey (FIDO2)*).
2. Set **Enable** to **Yes**; **Target** to `Phishing-Resistant – Pilot – Users` (expand later).
3. Under **Configure**: leave **Allow self-service set up** = Yes; optionally **restrict by AAGUID** to allow-list your FIPS-validated key models. **Save**.
   > **GCC High:** hardware FIDO2 keys are the GA, sovereign-safe choice. Do **not** design around **synced/phone passkeys or Authenticator passkeys** — those are *verify for GCC High*.

## Step 3 — Enable Windows Hello for Business
1. Entra → **Protection → Authentication methods → Policies → Windows Hello for Business** (or manage via Intune at `https://endpoint.microsoft.us`).
2. **Enable** and **Target** `Phishing-Resistant – Pilot – Users`. **Save**.

## Step 4 — Enable certificate-based authentication (CAC / PIV) — primary for DoD/federal
1. Entra → **Protection → Show more → Certificate-based authentication** — confirm the **CA chain** is uploaded to the certificate-authorities store and **username binding** is set (e.g. `PrincipalName` / `RFC822Name`, or `certificateUserIds`).
2. Set the **authentication-binding** so a hardware-smart-card (CAC/PIV) certificate policy counts as **MFA** (single- vs multi-factor by certificate policy OID).
3. Then **Protection → Authentication methods → Policies → Certificate-based authentication** → **Enable**, **Target** the pilot. **Save**.
   > **GCC High:** CBA is **✅ GA** in US Gov and is usually the *primary* phishing-resistant method where CAC/PIV already exist. **Verify the current binding requirements for GCC High/DoD** before you rely on the MFA/high-affinity binding (`gcc-high-parity-notes.md` §3).

## Step 5 — Decide the onboarding bootstrap (verify TAP for GCC High)
1. Entra → **Protection → Authentication methods → Policies → Temporary Access Pass**. If **present**, set **Enable = Yes**, **Target** `Phishing-Resistant – Pilot – Users`; use a short lifetime. **Save**.
2. If TAP is **not available** in your sovereign tenant, use **in-person supervised enrollment** (hand out and register the FIDO2 key with the user present) or **CAC/PIV issuance** as the bootstrap.
   > **GCC High:** TAP is *verify for GCC High* — do not assume it exists. Have the supervised-enrollment fallback ready.

## Step 6 — Register the pilot
1. If the **Registration campaign** is present (Entra → **Protection → Authentication methods → Registration campaign**), set **State = Enabled**, **Include** `Phishing-Resistant – Pilot – Users`, choose the passwordless methods to nudge. **Save**.
2. Direct pilot users to the sovereign security-info portal **`https://aka.ms/mysecurityinfo`** to register a FIDO2 key or enroll Windows Hello now (or issue/verify their CAC/PIV).
   > **GCC High:** the registration campaign is *verify for GCC High*. If absent, drive registration by direct communication plus supervised enrollment — do not let this block the rollout.

## Step 7 — Create the phishing-resistant authentication strength
1. Entra → **Protection → Authentication methods → Authentication strengths**.
2. Use the built-in **Phishing-resistant MFA** strength, or **New authentication strength** named `Phishing-Resistant – All Staff – Standard` and select **FIDO2**, **Windows Hello for Business**, and (where used) **certificate-based auth**. **Save**.

## Step 8 — Enforce on the pilot via Conditional Access
1. Entra → **Protection → Conditional Access → Create new policy**. **Name:** `Phishing-Resistant – Pilot – Enforce`.
2. **Users:** include `Phishing-Resistant – Pilot – Users`; **exclude** the two break-glass accounts.
3. **Target resources:** All cloud apps (or a pilot app first).
4. **Grant:** **Require authentication strength** → select `Phishing-Resistant – All Staff – Standard` (or built-in Phishing-resistant MFA).
5. **Enable policy:** **Report-only** first. **Create**.

## Step 9 — Validate the pilot
1. Have a pilot user sign in; confirm a phishing-resistant credential is requested (or, in Report-only, that it *would* be required).
2. Run `FIDO2G-Validation.ps1` for a pilot user → confirms a phishing-resistant method is registered as default (US Gov Graph).
3. Run `FIDO2G-Report.ps1` → confirms pilot coverage. Complete the **Testing Guide**. Then switch the pilot policy from **Report-only** to **On**.

## Step 10 — Expand to all staff
1. Confirm registration coverage with `FIDO2G-Report.ps1` for `Phishing-Resistant – All Staff – Users` (do not enforce ahead of registration).
2. Widen the method-policy **Target** (and the registration campaign, if used) to `Phishing-Resistant – All Staff – Users`.
3. Create `Phishing-Resistant – All Staff – Enforce` (same grant), scope to all staff, exclude break-glass, run **Report-only**, then turn **On** once coverage is high. Use `FIDO2G-Remediation.ps1` (default `-WhatIf`) to help laggards.

---
### Order of operations
`Groups → enable FIDO2 → enable Windows Hello → certificate-based auth (CAC/PIV) → bootstrap (TAP/verify or supervised) → register pilot → authentication strength → CA enforce on pilot → validate → expand to all staff`

> Every step above runs on the **sovereign `*.us`** plane. If a portal shows `.com`, you are in the
> wrong cloud — a GCC High account will not authenticate there.
