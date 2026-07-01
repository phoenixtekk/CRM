# 3. Implementation — Certificate-Based VPN Authentication for Cisco ISE with Intune

This is the ordered, click-by-click procedure. Follow the steps in order — the **trust chain must be
deployed before the certificate profile**, and everything is **piloted before it is expanded**.
Deployment model: **Assess → Configure → Pilot → Validate → Expand.**

**Object names used here (reuse verbatim):**
`Cisco VPN – Trusted Root` · `Cisco VPN – SCEP Device Cert` · `Cisco VPN – SCEP User Cert` ·
`Cisco VPN – PKCS User Cert` · `PILOT – Cisco Cert VPN Users` · `BROAD – Cisco Cert VPN Users`

**Vendor boundary:** Steps 1–6 (Intune/Entra/certificate) are exact. Step 7 (Cisco ISE + head-end)
is described at the architectural level and points to Cisco's documentation for exact console steps —
do not expect ISE menu paths here.

---

## Step 0 — Assess and decide (before you touch Intune)
1. Confirm all requirements in **`02-requirements.md`** and the category
   **`global-requirements-security.md`**.
2. **Decide the identity ISE will key on.** This drives everything:
   - **Device identity** (machine authenticates the tunnel) → use a **SCEP device** certificate
     (`Cisco VPN – SCEP Device Cert`). Typical Subject/SAN: device name / hardware identifier.
   - **User identity** (user authenticates) → use a **SCEP user** or **PKCS user** certificate
     (`Cisco VPN – SCEP User Cert` / `Cisco VPN – PKCS User Cert`). Typical SAN: **UPN**.
3. Choose **SCEP vs PKCS** (see `01-solution-overview.md`). Default to **SCEP** unless you need a
   directory-attribute Subject/SAN that your connector only produces via **PKCS**.
4. **Record the exact Subject/SAN format** you will issue — you must hand ISE the same identity to
   key on (coordinate with whoever configures ISE).
5. Ensure a change ticket exists with an approver, a maintenance window, and a rollback step
   (global R8).

**Gate 0 (pass/fail):** Identity model, profile type (SCEP/PKCS), and Subject/SAN format are decided
and written down. **Fail** = stop; do not build profiles until the identity is agreed with ISE.

---

## Step 1 — Create the scope groups
Create the pilot and broad groups first so profiles can be assigned to them.

**Option A — portal:**
1. Go to **`https://entra.microsoft.com`** → **Groups → All groups → New group**.
2. **Group type:** Security. **Group name:** `PILOT – Cisco Cert VPN Users`. Create.
3. Repeat for `BROAD – Cisco Cert VPN Users`.
4. Add a few **pilot** members (the test users, or their devices if you chose device certs) to
   `PILOT – Cisco Cert VPN Users`. Leave `BROAD` empty for now.

**Option B — script:** run **`CISECERT-Set-ScopeTargeting.ps1 -Apply`** to create both groups
idempotently, then add pilot members.

**Gate 1:** Both groups exist; pilot group has test members. 

---

## Step 2 — Build the Trusted certificate profile (`Cisco VPN – Trusted Root`)
The chain must be on the device **before** the leaf.

1. In **`https://intune.microsoft.com`**, go to **Devices → Manage devices → Configuration →
   Policies → Create → New Policy**.
2. **Platform:** choose your target platform (e.g. **Windows 10 and later**). **Profile type:**
   **Templates → Trusted certificate**. Click **Create**.
3. **Name:** `Cisco VPN – Trusted Root`. **Description:** "Root CA for Cisco EAP-TLS VPN — deploys
   the trust chain the leaf certificate must chain to." **Next.**
4. **Configuration settings:** **Certificate file** → upload the **root** CA `.cer` (from R3).
   For Windows, set **Destination store** = **Computer certificate store – Root**.
5. **Next** through Scope tags (optional).
6. **Assignments:** add group **`PILOT – Cisco Cert VPN Users`** to **Included groups**. **Next.**
7. **Review + create.**
8. **If you have an intermediate CA:** repeat Steps 2.1–2.7 with the intermediate `.cer`, naming it
   **`Cisco VPN – Trusted Root (Intermediate)`** and destination store
   **Computer certificate store – Intermediate**. Assign the same pilot group.

> **Do the equivalent import on Cisco ISE (Step 7):** ISE needs the **same** root/intermediate in its
> own trust store. Deploying to devices alone is not sufficient.

**Gate 2:** `Cisco VPN – Trusted Root` (and intermediate, if any) exists and is assigned to
`PILOT – Cisco Cert VPN Users`.

---

## Step 3 — Build the SCEP or PKCS certificate profile
Do **3A** for SCEP **or** **3B** for PKCS — matching the choice from Step 0.

### 3A — SCEP certificate profile (`Cisco VPN – SCEP Device Cert` or `… SCEP User Cert`)
1. **Devices → Manage devices → Configuration → Policies → Create → New Policy.**
2. **Platform:** your platform. **Profile type: Templates → SCEP certificate.** **Create.**
3. **Name:** `Cisco VPN – SCEP Device Cert` (device) **or** `Cisco VPN – SCEP User Cert` (user).
   **Next.**
4. **Configuration settings:**
   - **Certificate type:** **Device** or **User** (match your identity decision).
   - **Subject name format:** set to the identity you agreed with ISE (e.g. `CN={{DeviceName}}` for
     device, or `CN={{UserPrincipalName}}` for user).
   - **Subject alternative name:** add the SAN ISE keys on — commonly **UPN** =
     `{{UserPrincipalName}}` for user certs. **This must match the ISE Certificate Authentication
     Profile.**
   - **Certificate validity period:** e.g. **1 year**.
   - **Key storage provider (KSP):** Enroll to TPM if present, otherwise Software KSP (Windows).
   - **Key usage:** Digital signature + Key encipherment.
   - **Extended key usage (EKU):** add **Client Authentication** (`1.3.6.1.5.5.7.3.2`). **Required
     for EAP-TLS.**
   - **Renewal threshold (%):** e.g. **20%** (auto-renew before expiry).
   - **Root Certificate:** select the **`Cisco VPN – Trusted Root`** profile from Step 2.
   - **SCEP Server URLs:** the NDES/SCEP URL from your Certificate Connector (or the Cloud PKI SCEP
     URL).
5. **Next** → Scope tags (optional) → **Assignments:** include **`PILOT – Cisco Cert VPN Users`**.
6. **Review + create.**

### 3B — PKCS certificate profile (`Cisco VPN – PKCS User Cert`)
1. **Devices → Manage devices → Configuration → Policies → Create → New Policy.**
2. **Platform:** your platform. **Profile type: Templates → PKCS certificate.** **Create.**
3. **Name:** `Cisco VPN – PKCS User Cert`. **Next.**
4. **Configuration settings:**
   - **Certification authority:** the FQDN of your issuing CA.
   - **Certification authority name:** the CA common name.
   - **Certificate template name:** the client-auth template published on the CA (R1).
   - **Certificate type:** **User** (typical for PKCS).
   - **Subject name format / SAN:** the identity ISE keys on (e.g. SAN **UPN** =
     `{{UserPrincipalName}}`).
   - **Extended key usage:** include **Client Authentication** (`1.3.6.1.5.5.7.3.2`).
   - **Root Certificate:** select **`Cisco VPN – Trusted Root`** from Step 2.
   - **Renewal threshold (%):** e.g. **20%**.
5. **Next** → Scope tags (optional) → **Assignments:** include **`PILOT – Cisco Cert VPN Users`**.
6. **Review + create.**

**Gate 3:** The SCEP or PKCS profile exists, includes the **Client Authentication** EKU, references
`Cisco VPN – Trusted Root`, issues the agreed Subject/SAN, and is assigned to the pilot group.

---

## Step 4 — Confirm the certificate lands on a pilot device
1. On a pilot device (a member of `PILOT – Cisco Cert VPN Users`), force an Intune sync
   (**Settings → Accounts → Access work or school → Info → Sync**, or wait for check-in).
2. Run **`CISECERT-Validation.ps1 -IssuingCaName "your-issuing-ca-name"`** on the device
   (elevated). It confirms: root trusted, leaf present and issued by your CA, chain valid, **Client
   Authentication** EKU present, and within validity.
3. Alternatively check manually: `certlm.msc` → **Personal → Certificates** shows the leaf; **Trusted
   Root** / **Intermediate** shows the CA chain.

**Gate 4 (device-side):** Validation reports **PASS** on all checks — cert present, chain valid, EKU
present. **Fail** = go to Troubleshooting **A (no cert)** / **B (chain incomplete)** before
proceeding to ISE. **Do not test ISE until this gate passes.**

---

## Step 5 — Validate ISE accepts the EAP-TLS handshake (vendor boundary)
This step happens on the **Cisco** side. It is described here architecturally; **exact ISE / head-end
console steps are Cisco's** — follow Cisco's official documentation.

1. **Ensure ISE trusts the CA:** the same **root/intermediate** from Step 2 is imported into ISE's
   trusted-certificate store. *(Cisco docs — ISE trusted certificates import.)*
2. **Ensure a Certificate Authentication Profile** in ISE reads the identity from the **same
   Subject/SAN** you issued in Step 3 (e.g. SAN UPN). *(Cisco docs — Certificate Authentication
   Profile.)*
3. **Ensure the VPN policy set** allows **EAP-TLS** and authorizes the pilot identity for VPN.
   *(Cisco docs — policy sets / authorization.)*
4. **Ensure the head-end** (ASA / Secure Firewall) points its VPN connection profile at ISE for
   RADIUS with certificate/EAP-TLS auth. *(Cisco docs — VPN connection profile / RADIUS.)*
5. **Connect the VPN** from the pilot device using the certificate identity (no password).
6. **Confirm in ISE Live Logs** that the authentication is **EAP-TLS** and the result is
   **Access-Accept** / success. *(Cisco docs — RADIUS Live Logs.)*

**Gate 5 (end-to-end):** ISE Live Logs show a successful **EAP-TLS Access-Accept** for the pilot
identity and the VPN session establishes **without a password**. **Fail** = Troubleshooting **C (ISE
rejects EAP-TLS)**.

---

## Step 6 — Pilot soak
1. Keep the pilot group live for your agreed soak window (e.g. 3–5 business days).
2. Run **`CISECERT-Report.ps1`** to confirm the pilot devices show **Succeeded** on the certificate
   profile and no `Error`/`Pending` laggards.
3. Watch for renewal behavior and any ISE rejections in Live Logs.

**Gate 6:** Pilot is stable for the full window — certs issued and renewing, ISE consistently
accepting EAP-TLS, zero password fallbacks. **Fail** = fix before expanding.

---

## Step 7 — Expand to broad
1. Add production members to **`BROAD – Cisco Cert VPN Users`** (or convert it to a dynamic group).
2. Add **`BROAD – Cisco Cert VPN Users`** to the **Included groups** of `Cisco VPN – Trusted Root`
   (and intermediate) **and** the SCEP/PKCS profile — the **same profiles** you piloted.
3. Expand in waves; after each wave run **`CISECERT-Report.ps1`** to confirm coverage and chase
   laggards, and spot-check ISE Live Logs.
4. Once broad coverage is confirmed and stable, plan removal of password-based VPN fallback per your
   change process.

**Gate 7:** Target fleet shows certificate coverage, ISE accepts EAP-TLS across the fleet, and the
report shows no unresolved `Error`/`Pending`. Rollout complete.

---

## Rollback (any gate fails)
- **Unassign** the SCEP/PKCS profile (and Trusted Root if needed) from the affected group — this
  stops new issuance; existing tunnels using passwords remain available if you have not yet removed
  the password fallback.
- **Do not** delete issued certificates from devices reactively; unassigning the profile and letting
  ISE fall back to the prior VPN auth method is the safe path.
- Keep the password/legacy VPN auth method enabled on the head-end until broad certificate auth is
  proven (Gate 6+), so a failure never locks users out of VPN.
