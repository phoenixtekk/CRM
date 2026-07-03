# Implementation — Cloud PKI Integration with Intune (Government / GCC High)

Follow these steps **in order**. Every navigation path uses the **GCC High** portals — sign in at
**`https://login.microsoftonline.us`** and work in **`https://intune.microsoft.us`** (the Microsoft
Intune admin center for the US government cloud). If a portal loads at a `.com` host, stop — you are
in the Commercial cloud.

> **Cloud PKI is not available in GCC High (planned) and not planned for DoD.** This implementation
> therefore builds the **supported** path — **trusted-root + SCEP/PKCS certificate profiles via the
> Intune Certificate Connector**, anchored to your **AD CS** CA. If Cloud PKI has since shipped to
> your GCC High tenant (verify in `intune.microsoft.us` and `gcc-high-parity-notes.md` §2), you may
> substitute a Cloud PKI *issuing CA* for the AD CS/NDES/connector back-end — the **profile** steps
> below (trusted root + SCEP) still apply.

**Naming — use these object names verbatim** (reuse them exactly in later steps and in the scripts):

| Object | Name to create and reuse |
| --- | --- |
| Pilot Entra security group | `SG-CPKI-Pilot` |
| Trusted certificate profile (root/intermediate) | `Trust-Root-CA` |
| SCEP certificate profile (Wi-Fi/VPN client auth) | `SCEP-Device-ClientAuth` |
| PKCS certificate profile (alternative / user certs) | `PKCS-User-ClientAuth` |
| Certificate Connector (server name reference) | `CertConnector-01` |

**GCC High parity reminders are inlined at the step where they matter.** Full detail:
`gcc-high-parity-notes.md`.

---

## Phase 0 — Assess (gate before you build)

1. Sign in at **`https://login.microsoftonline.us`**; open **`https://intune.microsoft.us`**.
   Confirm **Devices → Configuration** and **Tenant administration → Connectors and tokens →
   Certificate connectors** are present.
2. **Confirm Cloud PKI is out of scope (R0).** In `intune.microsoft.us`, confirm there is **no**
   supported Cloud PKI CA creation blade for your tenant (Cloud PKI is planned, not GA in GCC High).
   Record the connector-based scope decision. (`gcc-high-parity-notes.md` §2.)
3. Confirm licensing (R2) at **`https://portal.office365.us` → Billing → Licenses** — G3/G5 / Intune
   Plan 1 present.
4. Confirm roles (R3) at **`entra.microsoft.us` → Roles and administrators** — **Intune
   Administrator**.
5. Confirm the **CA + NDES + connector** back-end (R4–R6): AD CS issuing CA online, NDES published,
   and the **Certificate Connector** shows **Active/Healthy** under **Tenant administration →
   Connectors and tokens → Certificate connectors**.
6. Confirm **`SG-CPKI-Pilot`** exists at **`entra.microsoft.us` → Groups**. If not: **Groups → New
   group → Security**, name it `SG-CPKI-Pilot`, add pilot users/devices.
7. **Run the parity check (R10)** for partner-CA / derived-credential dependencies.

**Gate:** portal loads at `.us`; Cloud PKI confirmed out-of-scope; licensing/roles present; CA +
NDES + connector healthy; pilot group exists. Do not proceed until all pass.

---

## Phase 1 — Publish the trust chain (trusted certificate profile)

### Step 1.1 — Export the CA chain

1. From your **AD CS** issuing CA, export the **root** (and any **intermediate**) CA certificate as
   **DER (.cer)** — public certificate only, **no private key**.

### Step 1.2 — Create the trusted certificate profile

1. In **`intune.microsoft.us`** go to **Devices → Configuration → + Create → New policy**.
2. Choose the target **platform** (create one per platform you manage — Windows, iOS/iPadOS, macOS,
   Android) and **Profile type = Templates → Trusted certificate**.
3. Upload the **root** `.cer`. For an intermediate, create a **second** trusted certificate profile
   with the intermediate `.cer` (and, on Windows, set the destination store appropriately).
4. **Name the profile `Trust-Root-CA`** (append the platform, e.g. `Trust-Root-CA-Windows`).
5. **Assignments:** assign to **`SG-CPKI-Pilot`** only.

**Gate:** on a pilot device, the root/intermediate appears in the device's trusted store after sync.
If not, see `06-troubleshooting.md`.

---

## Phase 2 — SCEP certificate profile (dynamic per-device issuance)

> **GCC High note:** SCEP profiles are a **standard MDM device-configuration** feature and **are
> available** in GCC High. Leaf certificates are signed by **your AD CS CA** (Cloud PKI is not
> available), so SCEP here **requires NDES + the Certificate Connector** (R5/R6). The SCEP URL you
> enter must be your **published Gov NDES URL**. (`gcc-high-parity-notes.md` §3.)

### Step 2.1 — Confirm the SCEP back-end is healthy

1. `intune.microsoft.us` → **Tenant administration → Connectors and tokens → Certificate
   connectors** — **`CertConnector-01`** is **Active** with the **SCEP** feature enabled.
2. Your **NDES** endpoint is reachable from a managed device (test the published SCEP URL).

### Step 2.2 — Create the SCEP profile

1. **Devices → Configuration → + Create → New policy** → platform → **Templates → SCEP certificate**.
2. Configure:
   - **Certificate type:** Device (or User, per scenario).
   - **Subject name format / SAN:** per your template (e.g. `CN={{DeviceName}}`, SAN =
     `{{AAD_Device_ID}}` or UPN for user certs).
   - **Certificate validity period / key storage / key usage / EKU:** match the **AD CS template**
     (e.g. **Client Authentication** EKU for Wi-Fi/VPN).
   - **Root certificate:** select the **`Trust-Root-CA`** trusted profile from Phase 1.
   - **SCEP Server URLs:** your **published Gov NDES SCEP URL**.
3. **Keep certificate extensions standard.** The SCEP validation service **blocks unknown extension
   OIDs** (connector v6.2510.3.2002+); only the allow-listed extensions (Basic Constraints, Subject
   Key Identifier, CA Version, Certificate Template Name, etc.) are honored — do not add custom OIDs.
   (`gcc-high-parity-notes.md` §3.)
4. **Name the profile `SCEP-Device-ClientAuth`**; **assign to `SG-CPKI-Pilot`** only.

**Gate:** a pilot device receives and installs a SCEP-issued certificate (visible in the device cert
store / Intune device certificate report). Connector **Event ID 4006** = SCEP issued success.

---

## Phase 3 — PKCS certificate profile (alternative / user certificates)

> **GCC High note:** PKCS profiles and imported PKCS (PFX) are **available** in GCC High (standard
> MDM). PKCS certificates are requested from **AD CS by the connector** (no NDES needed for PKCS).

### Step 3.1 — Confirm the connector PKCS feature

1. `intune.microsoft.us` → **Certificate connectors** — **`CertConnector-01`** has the **PKCS**
   feature enabled and the service account can enroll the AD CS template.

### Step 3.2 — Create the PKCS profile

1. **Devices → Configuration → + Create → New policy** → platform → **Templates → PKCS certificate**.
2. Configure **Certification authority** (the AD CS CA FQDN), **CA name**, **Certificate template
   name** (exact AD CS template), **Subject/SAN**, **key usage/EKU**, and select **`Trust-Root-CA`**
   as the root.
3. **Name the profile `PKCS-User-ClientAuth`**; **assign to `SG-CPKI-Pilot`** only.

**Gate:** a pilot user/device receives the PKCS certificate; connector **Event ID 1050** = PKCS
issued success. (For **S/MIME**, use **imported PKCS/PFX** per-user instead.)

---

## Phase 4 — Consume the certificate (Wi-Fi / VPN) and prove renewal/revocation

### Step 4.1 — Bind the certificate to a Wi-Fi or VPN profile

1. **Devices → Configuration → + Create → New policy** → platform → **Templates → Wi-Fi** (or
   **VPN**).
2. For **802.1X / EAP-TLS Wi-Fi** or **certificate-based VPN**, set authentication to use a
   **client certificate** and select **`SCEP-Device-ClientAuth`** (or `PKCS-User-ClientAuth`) as the
   client certificate source, and **`Trust-Root-CA`** as the trusted root.
3. **Name and assign to `SG-CPKI-Pilot`.**

**Gate:** a pilot device authenticates to the certificate-protected Wi-Fi/VPN.

### Step 4.2 — Renewal and revocation

1. **Renewal:** confirm the SCEP/PKCS profile's **renewal threshold** (e.g. renew at 20% remaining)
   so certificates auto-renew before expiry.
2. **Revocation:** revoke a test certificate (retire/wipe the pilot device, or revoke on the CA) and
   confirm the connector processes the revocation (**Event ID 3050** = revoke success) and the
   certificate is no longer trusted.

**Gate:** renewal fires before expiry; revocation removes trust. Both go through change control (G8).

---

## Phase 5 — Pilot → Validate → Expand

1. **Pilot** is already scoped to **`SG-CPKI-Pilot`** across the trust profile and SCEP/PKCS profiles.
2. **Validate** using the pass/fail gates in `05-testing.md`. Run **`CPKIG-Validation.ps1`** and
   **`CPKIG-Report.ps1`** (US Gov Graph) to confirm profile presence, assignment, and issued-cert
   coverage.
3. **Expand** only after gates pass: widen assignments group-by-group using
   **`CPKIG-Set-ScopeTargeting.ps1`** (defaults to `-WhatIf`). Do not assign certificate/Wi-Fi/VPN
   profiles tenant-wide on day one.

> **Future migration to Cloud PKI (when it reaches GCC High):** re-check the parity table. If Cloud
> PKI becomes GA in your GCC High tenant, create a Cloud PKI **root/issuing CA**, re-point the
> **trusted-root** and **SCEP** profiles at the Cloud PKI issuing CA / its SCEP registration
> authority URL, validate on the pilot, then retire NDES + the connector. Plan it as its own
> Assess→…→Expand cycle. (`gcc-high-parity-notes.md` §2.)

---

**The deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**

> **Sources:** Microsoft Learn — *Microsoft Intune Government Service overview* (Cloud PKI planned;
> standard MDM available); *Overview of Certificate Connector for Microsoft Intune* (SCEP/PKCS,
> NDES, OID allow-list, auto-update); *Microsoft Cloud PKI for Microsoft Intune* (future model).
> Portals: `intune.microsoft.us`, `portal.office365.us`, `entra.microsoft.us`,
> `login.microsoftonline.us`. Full citations in `gcc-high-parity-notes.md`.
