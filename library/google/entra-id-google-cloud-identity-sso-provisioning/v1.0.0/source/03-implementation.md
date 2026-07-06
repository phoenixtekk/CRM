# 3. Implementation Guide — Configure Entra→Google SSO Federation & Provisioning

This guide configures the identity foundation in the right order: **assess and pick the source of
truth → configure SSO federation (Entra IdP → Google) → configure provisioning (SCIM push or GCDS
pull) → pilot both on a named OU/group → validate sign-in and provisioning → expand.** Every change is
staged, validated on the pilot, and reversible.

> **Vendor boundary.** The **Entra** side is authored from Microsoft's current public docs (the
> "Google Cloud / G Suite Connector by Microsoft" gallery app); the **Google Admin console / Cloud
> Identity** side from Google's public docs. **GCDS** internals are Google's tool; its detailed
> field-by-field configuration is deferred to Google's own documentation where noted. Menu names and
> URLs change — treat any exact label as "verify in your current console."

> **Order matters.** Provision (or verify accounts already exist) **before** enforcing SSO org-wide —
> SSO federates a sign-in into an account that must already exist. Always keep a break-glass Google
> super-admin **outside** the SSO profile (Requirement 2.10).

---

## Step 0 — Assess and decide (do this first)
1. Run `GWSSO-Discovery.ps1` to inventory the **Entra side**: whether the "Google Cloud / G Suite
   Connector by Microsoft" app exists, its SSO mode (SAML / none), whether a SCIM provisioning
   (synchronization) job is present, how many users/groups are assigned, and the tenant's verified
   custom domains.
2. Confirm the **source of truth** (Requirement 2.3): **Entra → SCIM push**, **AD → GCDS pull**, or
   **JIT** (convenience only). Write it down; the rest of the guide branches on it.
3. Confirm the **custom domain is verified in both Entra and Google** and that no in-scope user has a
   `*.onmicrosoft.com` UPN (Requirement 2.4).
4. Build the pilot scope with `GWSSO-Set-ScopeTargeting.ps1` and identify the matching Google pilot
   **OU/group**.

---

## Step 1 — Add the gallery app (Entra)
1. Sign in to **entra.microsoft.com** as at least a **Cloud Application Administrator**.
2. Browse to **Entra ID → Enterprise apps → New application**.
3. In **Add from the gallery**, search **"Google Cloud / G Suite Connector by Microsoft"**, select it,
   and add it. (If you already use this app for SSO, you can reuse it for provisioning; when first
   testing, a separate app instance is fine.)

---

## Step 2 — Configure SSO federation (Entra IdP → Google, SAML 2.0)

### 2a. Entra side — SAML SSO
1. In the app, open **Single sign-on** and select **SAML**.
2. Edit **Basic SAML Configuration**. Use one of the documented patterns (verify against your console):
   - **Identifier (Entity ID):** `google.com` (no domain-specific issuer) **or**
     `google.com/a/your-domain-com` (domain-specific issuer). This must **match** the domain-specific
     issuer choice you make on the Google side in 2b.
   - **Reply URL (ACS):** for Workspace/Gmail `https://www.google.com`; for Google Cloud Platform
     `https://www.google.com/acs` (or the `/a/your-domain-com` variants).
   - **Sign on URL:**
     `https://www.google.com/a/your-domain-com/ServiceLogin?continue=https://mail.google.com`.
3. **Attribute / NameID:** the **Unique User Identifier (NameID)** must be the user's **email address**
   that matches their Google account — map it to **user.mail** (not the default
   `user.userprincipalname`). This is the single most common cause of "cannot sign in."
4. In **SAML Signing Certificate**, download **Certificate (Base64)**.
5. In **Set up ...**, copy the **Login URL** and **Logout URL** for the Google side. (Note: Microsoft
   documents the correct sign-out URL as
   `https://login.microsoftonline.com/common/wsfederation?wa=wsignout1.0`.)

### 2b. Google side — accept the SAML SSO profile
1. Sign in to **admin.google.com** as a **super-admin**.
2. Go to **Menu → Security → Authentication → SSO with third-party IdP**.
3. On the **Third-party SSO profile for your organization** tab:
   - **Sign-in page URL** ← Entra **Login URL**.
   - **Sign-out page URL** ← Entra **Logout URL**.
   - **Verification certificate** ← upload the Base64 certificate from 2a.
   - **Use a domain-specific issuer** ← check/uncheck to match your Entra Identifier choice in 2a.
   - **Change password URL** ← `https://mysignins.microsoft.com/security-info/password/change`.
   - **Save.**
4. **Scope the SSO profile to the pilot first.** Google supports assigning the SSO profile per **user,
   OU, or group**. Assign the profile to the **pilot OU/group** and set it to **none** for everyone
   else (and for the break-glass super-admin) so only the pilot federates until you validate.

> **What SSO does and does not do.** The SAML assertion **authenticates**; it does not create the
> Google account and does not grant Google admin. The account must already exist (Step 3), and Google
> decides authorization by OU/group/admin role.

---

## Step 3 — Configure provisioning (one source of truth)

Do **one** of the following, per the decision in Step 0.

### Path A — SCIM push (Entra ID is the source of truth)
1. **Google prerequisites** (Requirement 2.5): **Security → Access and data control → API Controls →
   "Trust internal, domain-owned apps" → SAVE**; and a Google admin account whose **Admin role**
   (**Account → Admin roles**) has **all Admin API privileges** enabled.
2. In Entra, open the app → **Provisioning** tab → **Get started** → **+ New configuration**.
3. Under **Admin Credentials**, select **Authorize** → in the Google dialog, **Accept** to grant Entra
   permission to manage the Google tenant → **Test Connection** → **Create**.
4. On **Overview → Properties**, enable **notification emails**, set a **quarantine** address, and
   enable **accidental-deletion prevention**; **Apply**.
5. **Attribute Mapping → users:** review mappings; **primaryEmail** is the matching attribute (and must
   equal the SSO NameID). **Attribute Mapping → groups:** review group mappings (email, name,
   description, members) so **groups and memberships** provision too.
6. **Scope who provisions:** either **assign** users/groups to the app (Enterprise app → Users and
   groups) or set an **attribute-based scoping filter**. **Start with the pilot OU/group only.**
7. Use **on-demand provisioning** to validate a couple of pilot users, then **Start provisioning** from
   **Overview**.
   - **De-provisioning:** removing a user from scope (or disabling in Entra) **suspends** them in
     Google — it does **not** hard-delete the Google object. That is the intended leaver path.

### Path B — GCDS pull (on-prem Active Directory is the source of truth)
1. Install **Google Cloud Directory Sync** on the prepared host with LDAP access to AD (Requirement
   2.6) — best on a **separate machine**, not the domain controller.
2. In **GCDS Configuration Manager**, connect to **Active Directory** (LDAP) and to **Google (Cloud
   Identity / Workspace)** with a Google admin.
3. Under **General Settings**, select **User Accounts** (and **Groups** if syncing groups). Configure
   **User Accounts → Additional User Attributes** and the OU/attribute mapping rules that decide which
   objects flow. (Field-by-field mapping is per Google's GCDS docs.)
4. **Simulate** a sync — GCDS reports the changes it *would* make without applying them; review the
   simulation against expectations.
5. Run a real sync for the **pilot OU** only, then **schedule** GCDS for continuous provisioning.
   - **De-provisioning:** removing/disabling the AD object flows through GCDS to suspend the Google
     account on the next run.

### JIT note
SAML **just-in-time** creation makes a Google user on first SSO. It is a **convenience, not the source
of truth** — for lifecycle, and especially **de-provisioning leavers**, use Path A or Path B so
removals actually propagate. Do not rely on JIT alone.

> **Never run both Path A and Path B against the same objects.** SCIM push (Entra) and GCDS pull (AD)
> mastering the same users is two sources of truth — they conflict and drift. Pick one per object.

---

## Step 4 — Pilot: validate sign-in AND provisioning on the named OU/group
1. Confirm the **pilot users exist in Google** (provisioned via Path A/B, or created for the test).
2. A pilot user **signs in** via Entra SSO (use **Test this application** in Entra, or the Google
   sign-on URL). Expected: redirect to Entra, authenticate, land in Google — no second password.
3. **Provisioning check:** add a pilot user to a source group; confirm the user **and group membership**
   appear in Google. Remove the user; confirm they are **de-provisioned (suspended)** in Google.
4. Run `GWSSO-Validation.ps1` to confirm the Entra side: SSO mode is SAML, a provisioning job exists
   and is running, and the pilot users are assigned/in scope.
5. Confirm the **break-glass Google super-admin** (SSO profile = none) can still sign in outside SSO.

**Gate:** do not proceed to expand until sign-in works, provisioning creates and de-provisions
correctly, and break-glass is confirmed (see the Testing Guide gates).

---

## Step 5 — Expand
1. Widen the **Google SSO profile** assignment from the pilot OU/group to the next batches of OUs/groups
   (leaving break-glass at **none**).
2. Widen **provisioning scope** (SCIM assignment/filter, or GCDS OU rules) in the same batches.
3. Re-run `GWSSO-Discovery.ps1`, `GWSSO-Validation.ps1`, and `GWSSO-Report.ps1` on a cadence so
   coverage and exceptions stay visible as the rollout grows.
4. Record every deliberate exception (e.g. service accounts intentionally not federated) with an owner.

---

### Order of operations
`Assess + pick source of truth → add gallery app → configure SAML SSO (Entra + Google) → configure
provisioning (SCIM push OR GCDS pull) → pilot (sign-in + provisioning on named OU/group) → validate →
expand in batches, tracking exceptions`

### Rollback
- **SSO:** set the Google SSO profile to **none** for the affected OU/group (or turn the Entra SSO app
  off) — sign-in reverts to Google-native or the prior IdP. The break-glass super-admin is always
  outside SSO.
- **Provisioning (SCIM):** **Stop provisioning** in the Entra app — existing Google objects remain; no
  new writes. Re-scoping to fewer users is non-destructive.
- **Provisioning (GCDS):** disable the scheduled task / narrow the OU rules — existing objects remain.
- Every change is piloted on a named OU/group and reversible before org-wide enforcement.
