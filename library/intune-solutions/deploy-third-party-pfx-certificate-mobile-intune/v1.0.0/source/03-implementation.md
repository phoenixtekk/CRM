# 3. Implementation Guide — Deploy a Third-Party PFX Certificate to Mobile Devices for App Use

Follow these steps **in order**, in the **Microsoft Intune admin center**
(`https://intune.microsoft.com`). This is the resolution: it stops the SCEP/PKCS-template dead end and
delivers the static third-party PFX the correct way.

> **Model:** Confirm/import the PFX → deliver the trusted chain → assign the imported-PFX profile
> (Path A) **or** the custom PKCS12 profile (Path B) → validate the app can use it → pilot → expand.
> Choose Path A *or* Path B per the decision guide in the Overview; do both the shared steps (1, 2, 5)
> plus the path you chose.

> **Do NOT use a SCEP profile or a PKCS *certificate* (CA-issued) profile here.** Those issue new
> certificates from your CA and cannot deliver a pre-existing third-party PFX. If a SCEP/PKCS template
> is already assigned for this purpose, unassign it.

## Step 1 — Create the device groups (shared)
1. Entra → **Groups → New group** → **Security** → name `iOS App Cert – Pilot` (a few representative
   iOS devices). **Create**.
2. Create `iOS App Cert – Broad` (the rest of the iOS fleet). **Create**.

## Step 2 — Deliver the trusted root/intermediate chain (shared — do this first)
The leaf identity is useless on the device without a trusted chain, so deploy the chain before the
identity.
1. Intune → **Devices → Configuration → Create → New policy**.
2. **Platform:** iOS/iPadOS. **Profile type:** **Templates → Trusted certificate**. **Create**.
3. **Name:** `Trusted Root – Org CA – iOS`. **Next**.
4. **Configuration settings:** upload the **root** CA `.cer`. (If there is an intermediate, create a
   second `Trusted certificate` profile for it, named `Trusted Intermediate – Org CA – iOS`.) **Next**.
5. **Assignments → Add groups →** `iOS App Cert – Pilot`. **Next → Create**.

---

## PATH A — PKCS imported certificate (Certificate Connector + Graph import)
Use this when you want Intune to manage the imported PFX object and the Certificate Connector is
healthy. See the decision guide in the Overview.

### Step A1 — Confirm the Certificate Connector is healthy
1. Intune → **Tenant administration → Connectors and tokens → Certificate connectors**.
2. Confirm the connector shows **Active/Healthy** with a recent check-in. If not, repair it before
   continuing (see Troubleshooting A) — an unhealthy connector cannot decrypt the imported PFX, so the
   profile will never deliver.

### Step A2 — Import the third-party PFX into Intune via Microsoft Graph
The PFX is imported (encrypted to the connector's public key) and uploaded as an imported/user PFX
certificate object. Use the helper script:
1. On the admin workstation, run `PFXMOB-Import-Pfx.ps1`, supplying the `.pfx` path, its password
   (secure input — never hardcoded), the target user UPN placeholder
   (`Intune.Cert.<service>@<your-domain>`), and the intended purpose.
2. The script connects to Graph, retrieves the Certificate Connector's public key, encrypts the PFX,
   sets the certificate **thumbprint** and **intended purpose**, and uploads the object.
   > **Intended-purpose note:** the imported-PFX intended-purpose options are **S/MIME-oriented**
   > (signing/encryption). For a non-S/MIME app certificate, set the value the app expects and be aware
   > this framing may not match a plain app identity — if it doesn't fit, use Path B instead.
3. Confirm the object exists: run `PFXMOB-Discovery.ps1` (it lists imported PFX objects) — this is the
   "PFX object exists in Graph" state. **The object alone does NOT reach a device; you must assign a
   profile (next step).**

### Step A3 — Create and assign the PKCS imported certificate profile
This is the missing piece in the stalled scenario.
1. Intune → **Devices → Configuration → Create → New policy**.
2. **Platform:** iOS/iPadOS. **Profile type:** **Templates → PKCS imported certificate**. **Create**.
3. **Name:** `PFX Imported – iOS App Cert – Pilot`. **Next**.
4. **Configuration settings:**
   - **Intended purpose:** match what you set on import (S/MIME signing / S/MIME encryption — see the
     note above for a non-S/MIME app cert).
   - Leave the remaining settings at the documented defaults unless the app vendor specifies otherwise.
   **Next.**
5. **Assignments → Add groups →** `iOS App Cert – Pilot`. **Next → Create**.

> The Certificate Connector decrypts the imported PFX and the identity is installed on assigned
> devices at their next sync. Proceed to Step 5 (validate the app).

---

## PATH B — Custom iOS/iPadOS configuration profile carrying a PKCS12 payload
Use this when you control the `.pfx` + password and need the most direct delivery for an app identity
(often the cleanest for a non-S/MIME app cert). No Certificate Connector or Graph import required.

### Step B1 — Build the .mobileconfig with a PKCS12 payload
1. Create a `.mobileconfig` containing a **PKCS12** payload that embeds the `.p12`/`.pfx` and its
   password. (Apple Configurator or a known-good `.mobileconfig` template produces this; keep the
   password handling secure.)
2. Validate the `.mobileconfig` opens/parses correctly before uploading.

### Step B2 — Create and assign the Custom profile
1. Intune → **Devices → Configuration → Create → New policy**.
2. **Platform:** iOS/iPadOS. **Profile type:** **Templates → Custom**. **Create**.
3. **Name:** `Custom PKCS12 – iOS App Cert – Pilot`. **Next**.
4. **Configuration settings:** **Custom configuration profile name** = `iOS App Cert PKCS12`; upload
   the `.mobileconfig` from Step B1. **Next**.
5. **Assignments → Add groups →** `iOS App Cert – Pilot`. **Next → Create**.

---

## Step 5 — Apply on a pilot device and validate the app can use the certificate (shared)
1. On a pilot iOS device, force a sync: **Settings → General → VPN & Device Management →** (management
   profile) **→ Sync**, or push a sync from Intune (**Devices → (device) → Sync**).
2. Confirm the trusted chain and the identity are present: **Settings → General → VPN & Device
   Management →** open the installed profile(s) and confirm the certificate(s) appear. Or run
   `PFXMOB-Validation.ps1` for the device.
3. **Open the target app and confirm it can use the certificate.** If the app cannot see the identity:
   - Re-check the app vendor's required delivery method (keychain access group / App Configuration).
   - If the vendor requires the identity in the app's own keychain access group, a plain custom PKCS12
     may not be directly accessible — follow the vendor's method, or add an Intune **App Configuration
     policy** for the app (**Apps → App configuration policies → Add → Managed devices →** select the
     app → supply the vendor's keys).
   - App-internal specifics are deferred to the app vendor; the Intune delivery above is correct.

## Step 6 — Pilot gate
Do not expand until: the chain and identity are present on pilot devices (`PFXMOB-Validation.ps1`),
the profile shows **Succeeded**, and the **app successfully uses the certificate**. Complete the
**Testing Guide**. **Rollback:** if the pilot fails, unassign the profile(s) from
`iOS App Cert – Pilot` (and remove the imported PFX object via Graph if Path A) — devices remove the
certificate at next sync; no fleet impact.

## Step 7 — Expand to production
1. Add `iOS App Cert – Broad` to the **Trusted certificate** profile and to your chosen delivery
   profile (`PFX Imported – iOS App Cert – Pilot` or `Custom PKCS12 – iOS App Cert – Pilot`); rename
   to `– Broad` if you prefer a separate broad profile.
2. Re-validate with `PFXMOB-Validation.ps1` and run `PFXMOB-Report.ps1` for fleet status.

---
### Order of operations
`Groups → Trusted chain → (Path A: Connector healthy → Graph import → imported-PFX profile) OR
(Path B: build .mobileconfig → custom profile) → Apply → Validate app → Pilot gate → Expand`
