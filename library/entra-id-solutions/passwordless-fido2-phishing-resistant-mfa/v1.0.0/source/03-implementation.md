# 3. Implementation Guide — Passwordless & Phishing-Resistant MFA with FIDO2 Security Keys

Follow these steps **in order**, in the **Microsoft Entra admin center** (`https://entra.microsoft.com`).

> **Model:** Enable the methods, get a **pilot** registered, create a phishing-resistant
> authentication strength, require it via Conditional Access on the pilot, validate, then expand to
> all staff. Registration always leads enforcement so no one is locked out.
>
> **Naming convention** — every object uses `<Purpose> – <Scope> – <Stage>`. Create these and reuse the names verbatim:
> - Groups: `Phishing-Resistant – Pilot – Users`, `Phishing-Resistant – All Staff – Users`
> - Authentication strength: `Phishing-Resistant – All Staff – Standard`
> - Conditional Access (pilot): `Phishing-Resistant – Pilot – Enforce`
> - Conditional Access (broad): `Phishing-Resistant – All Staff – Enforce`

## Step 1 — Create the groups
1. Entra → **Groups → New group** → **Security** → name `Phishing-Resistant – Pilot – Users` (a few representative users + admins). **Create**.
2. Create `Phishing-Resistant – All Staff – Users` (everyone in scope). **Create**.

## Step 2 — Enable FIDO2 security keys
1. Entra → **Protection → Authentication methods → Policies → FIDO2 security key**.
2. Set **Enable** to **Yes**; **Target** to `Phishing-Resistant – Pilot – Users` (expand later).
3. Under **Configure**: leave **Allow self-service set up** = Yes; optionally restrict key models by AAGUID. **Save**.

## Step 3 — Enable Windows Hello for Business
1. Entra → **Protection → Authentication methods → Policies → Windows Hello for Business** (or via Intune if you manage it there).
2. **Enable** and **Target** `Phishing-Resistant – Pilot – Users`. **Save**.

## Step 4 — (Optional) Enable certificate-based authentication
1. Entra → **Protection → Show more → Certificate-based authentication**; confirm the CA chain is uploaded and username binding is set.
2. Then **Protection → Authentication methods → Policies → Certificate-based authentication** → **Enable**, **Target** the pilot. **Save**.

## Step 5 — Launch the registration campaign
1. Entra → **Protection → Authentication methods → Registration campaign**.
2. Set **State** = **Enabled**; **Include** `Phishing-Resistant – Pilot – Users`; choose the methods to nudge (authenticator/passwordless). **Save**.
3. Direct pilot users to `https://aka.ms/mysecurityinfo` to register a FIDO2 key or Windows Hello now.

## Step 6 — Create the phishing-resistant authentication strength
1. Entra → **Protection → Authentication methods → Authentication strengths**.
2. Use the built-in **Phishing-resistant MFA** strength, or **New authentication strength** named `Phishing-Resistant – All Staff – Standard` and select FIDO2, Windows Hello for Business, and (if used) certificate-based auth. **Save**.

## Step 7 — Enforce on the pilot via Conditional Access
1. Entra → **Protection → Conditional Access → Create new policy**. **Name:** `Phishing-Resistant – Pilot – Enforce`.
2. **Users:** include `Phishing-Resistant – Pilot – Users`; **exclude** the two break-glass accounts.
3. **Target resources:** All cloud apps (or a pilot app first).
4. **Grant:** **Require authentication strength** → select `Phishing-Resistant – All Staff – Standard` (or built-in Phishing-resistant MFA).
5. **Enable policy:** **Report-only** first. **Create**.

## Step 8 — Validate the pilot
1. Have a pilot user sign in; confirm a phishing-resistant credential is requested (or, in Report-only, that it *would* be required).
2. Run `FIDO2-Validation.ps1` for a pilot user → confirms a phishing-resistant method is registered as default.
3. Run `FIDO2-Report.ps1` → confirms pilot coverage. Complete the **Testing Guide**. Then switch the pilot policy from **Report-only** to **On**.

## Step 9 — Expand to all staff
1. Confirm registration coverage with `FIDO2-Report.ps1` for `Phishing-Resistant – All Staff – Users` (do not enforce ahead of registration).
2. Widen the method-policy **Target** and the registration campaign to `Phishing-Resistant – All Staff – Users`.
3. Create `Phishing-Resistant – All Staff – Enforce` (same grant), scope to all staff, exclude break-glass, run **Report-only**, then turn **On** once coverage is high. Use `FIDO2-Remediation.ps1` (default `-WhatIf`) to help laggards.

---
### Order of operations
`Groups → enable FIDO2 → enable Windows Hello → (certificate-based) → registration campaign → authentication strength → CA enforce on pilot → validate → expand to all staff`
