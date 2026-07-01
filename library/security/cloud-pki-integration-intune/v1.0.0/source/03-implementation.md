# 3. Implementation Guide — Cloud PKI Integration with Intune

Follow these steps **in order**, in the **Microsoft Intune admin center**
(`https://intune.microsoft.com`). The cloud-PKI **product** steps (connector install, issuing CA,
certificate template) are done in the **vendor's console per the vendor's documentation** and are
flagged below; everything else is the exact Intune-side procedure.

> **Model:** Connect the cloud PKI → deploy the trusted root/intermediate chain → create SCEP/PKCS
> certificate profiles → issue to a pilot → validate Wi-Fi/VPN/auth → migrate workloads off the
> legacy CA (coexist, then retire) → expand. Pattern: **Assess → Configure → Pilot → Validate →
> Expand**, with a pilot gate and rollback.

> **Naming — reuse these exact names throughout** (`<Purpose> – <Scope> – <Stage>`):
> connector `Cloud PKI Connector – Tenant – Integration`; trust profiles
> `Trusted Root – Cloud PKI – All Devices` and `Trusted Intermediate – Cloud PKI – All Devices`;
> device cert `SCEP Cert – Device Auth – Pilot` / `– Broad`; user cert
> `PKCS Cert – User Auth – Pilot` / `– Broad`; scope groups
> `Cloud PKI Cert – Devices – Pilot` / `– Broad` and `Cloud PKI Cert – Users – Pilot` / `– Broad`.

## Step 1 — Create the scope groups
1. Entra → **Groups → New group** → **Security** → `Cloud PKI Cert – Devices – Pilot` (a few
   representative devices). **Create**.
2. Repeat for `Cloud PKI Cert – Devices – Broad`, `Cloud PKI Cert – Users – Pilot`, and
   `Cloud PKI Cert – Users – Broad`. (Or build all four with `CPKI-Set-ScopeTargeting.ps1`.)

## Step 2 — Connect the cloud PKI to Intune (vendor console)
> **Vendor step — defer to the cloud PKI vendor's documentation.** Install/register the cloud PKI's
> **Intune connector or plugin** and grant it the Graph permissions the vendor specifies. Name the
> connector reference `Cloud PKI Connector – Tenant – Integration` where the vendor allows a label.
1. After the vendor steps, confirm the connector in Intune → **Tenant administration → Connectors and
   tokens → Certificate connectors**. It must show **Active/healthy** with a recent check-in.
2. Run `CPKI-Discovery.ps1` to confirm the certificate connector is present and healthy from the
   Graph side. An unhealthy connector cannot issue certificates — fix it before continuing
   (see Troubleshooting A).

## Step 3 — Deploy the trusted root/intermediate chain (do this before any issuance)
The leaf certificate is useless on the device without a trusted chain, so deploy the chain first.
1. Intune → **Devices → Configuration → Create → New policy**.
2. **Platform:** select your platform (e.g. Windows 10 and later / iOS/iPadOS / Android / macOS).
   **Profile type:** **Templates → Trusted certificate**. **Create**.
3. **Name:** `Trusted Root – Cloud PKI – All Devices`. **Next**.
4. **Configuration settings:** upload the cloud PKI **root** CA `.cer` (DER). For Windows, set the
   **Destination store** to **Computer certificate store – Root**. **Next**.
5. **Assignments → Add groups →** `Cloud PKI Cert – Devices – Pilot` (and the users pilot group if
   you will issue user certificates). **Next → Create**.
6. If the cloud PKI has an **intermediate** CA, create a second **Trusted certificate** profile named
   `Trusted Intermediate – Cloud PKI – All Devices` and upload the intermediate `.cer` (Windows
   destination store **Intermediate**). Assign to the same groups.

> Repeat Step 3 per platform you target — a Trusted certificate profile is platform-specific.

## Step 4 — Create the SCEP device certificate profile (pilot)
Use SCEP for device authentication (the private key is generated on the device).
1. Intune → **Devices → Configuration → Create → New policy**.
2. **Platform:** your device platform. **Profile type:** **Templates → SCEP certificate**. **Create**.
3. **Name:** `SCEP Cert – Device Auth – Pilot`. **Next**.
4. **Configuration settings:**
   - **Certificate type:** **Device**.
   - **Subject name format:** e.g. `CN={{DeviceName}}` (use the attributes your scenario requires).
   - **Subject alternative name:** add the SAN your scenario needs (e.g. DNS or the value the cloud
     PKI template expects).
   - **Certificate validity period:** match the cloud PKI template (e.g. 1 year).
   - **Key storage provider / Key usage / Key size:** per your standard (e.g. 2048).
   - **Extended key usage (EKU):** add **Client Authentication** (`1.3.6.1.5.5.7.3.2`) for Wi-Fi/VPN.
   - **Renewal threshold (%):** e.g. **20** (auto-renew before expiry).
   - **Root certificate:** select the `Trusted Root – Cloud PKI – All Devices` profile from Step 3.
   - **SCEP server URLs:** enter the **cloud PKI SCEP URL** from the vendor (Requirement 2.5).
   **Next.**
5. **Assignments → Add groups →** `Cloud PKI Cert – Devices – Pilot`. **Next → Create**.

> If the cloud PKI uses a challenge/connector mechanism other than a plain SCEP URL, follow the
> vendor's documentation for the exact value(s) to enter in **SCEP server URLs** — the Intune profile
> shape above is unchanged.

## Step 5 — (If issuing user certificates) Create the PKCS user certificate profile (pilot)
Use PKCS for user authentication where the cloud PKI's Intune integration supports PKCS issuance.
1. Intune → **Devices → Configuration → Create → New policy**.
2. **Platform:** your platform. **Profile type:** **Templates → PKCS certificate**. **Create**.
3. **Name:** `PKCS Cert – User Auth – Pilot`. **Next**.
4. **Configuration settings:**
   - **Certificate type:** **User**.
   - **Subject name format:** e.g. `CN={{UserName}}` ; **SAN:** **User principal name (UPN)** =
     `{{UserPrincipalName}}`.
   - **Certification authority / CA name / Certificate template name:** enter the **cloud PKI issuing
     CA and template** identifiers the vendor provides (Requirement 2.5).
   - **Validity / Key usage / EKU:** match the template; add **Client Authentication** EKU.
   - **Root certificate:** select `Trusted Root – Cloud PKI – All Devices`.
   **Next.**
5. **Assignments → Add groups →** `Cloud PKI Cert – Users – Pilot`. **Next → Create**.

> **PKCS support varies by cloud PKI.** If the vendor's Intune integration does not support PKCS,
> issue user certificates via SCEP (Certificate type **User**) instead, per the vendor's guidance.

## Step 6 — Point a certificate-backed scenario at the issued certificate (pilot)
Issuing a certificate proves issuance; the scenario must actually *use* it.
1. Intune → **Devices → Configuration → Create → New policy** → your platform → **Templates →
   Wi-Fi** (or **VPN**).
2. In the profile's **authentication** settings, select **certificate** authentication and choose the
   **client certificate** that references your SCEP/PKCS profile (`SCEP Cert – Device Auth – Pilot`
   or `PKCS Cert – User Auth – Pilot`) and the **root** = `Trusted Root – Cloud PKI – All Devices`.
3. Assign to `Cloud PKI Cert – Devices – Pilot` (Wi-Fi/VPN device auth) or the users pilot group.
   **Create**.

## Step 7 — Apply on a pilot device and validate
1. On a pilot device, force a sync (Windows: **Settings → Accounts → Access work or school → Info →
   Sync**; iOS/iPadOS: **Settings → General → VPN & Device Management →** management profile **→
   Sync**), or push **Sync** from Intune (**Devices → (device) → Sync**).
2. Confirm the **trust chain** and the **issued certificate** are present:
   - Windows: `certlm.msc` → **Personal → Certificates** shows the leaf; **Trusted Root** shows the
     cloud PKI root.
   - Or run `CPKI-Validation.ps1` for the device.
3. Confirm the certificate's **status** in Intune: open `SCEP Cert – Device Auth – Pilot` →
   **Device status** = **Succeeded**.
4. **Validate the scenario:** connect to the certificate-backed **Wi-Fi/VPN** (or perform the auth
   action) and confirm it succeeds **using the cloud-issued certificate**.

## Step 8 — Pilot gate
Do not expand or migrate until: the connector is healthy, the chain and certificate are present on
pilot devices (`CPKI-Validation.ps1`), the profile shows **Succeeded**, **and** the Wi-Fi/VPN/auth
scenario works with the cloud-issued certificate. Complete the **Testing Guide**.
**Rollback:** if the pilot fails, unassign the new SCEP/PKCS and scenario profiles from the pilot
groups — devices remove the certificate at next sync; the legacy CA chain remains trusted, so no
production scenario breaks.

## Step 9 — Migrate workloads off the legacy CA (coexistence → retire)
Migrate one scenario at a time; both chains stay trusted during coexistence.
1. **Coexist.** Keep the legacy root/intermediate trusted (leave the legacy Trusted certificate
   profiles assigned) while the cloud PKI chain is also deployed. Devices now trust **both** CAs.
2. **Re-issue.** For each scenario, assign the cloud PKI SCEP/PKCS profile to the broad scope group so
   devices receive a **new** cloud-issued certificate alongside the legacy one.
3. **Re-point the scenario.** Update each Wi-Fi/VPN/auth profile to use the **cloud PKI** client
   certificate + root (Step 6) instead of the legacy one. Validate per scenario before moving on.
4. **Drain the legacy CA.** Once a scenario validates on the cloud certificate fleet-wide, unassign
   the **legacy** SCEP/PKCS profile for that scenario; devices stop renewing from the legacy CA and
   the legacy certificates age out.
5. **Retire.** When `CPKI-Report.ps1` shows no devices depending on legacy-issued certificates and no
   scenario references the legacy CA, retire the legacy SCEP/PKCS profiles and (after a safety margin)
   remove the legacy Trusted certificate profiles and decommission the on-prem CA/connector per change
   control.

## Step 10 — Expand to production
1. Add the **broad** scope groups to the trust, SCEP/PKCS, and scenario profiles (or clone the pilot
   profiles to `– Broad` and assign the broad groups).
2. Re-validate with `CPKI-Validation.ps1` and run `CPKI-Report.ps1` for fleet coverage + expiry.

---
### Order of operations
`Scope groups → Connect cloud PKI (vendor) → Trusted chain → SCEP device profile → (PKCS user
profile) → Point Wi-Fi/VPN/auth at the cert → Apply → Validate → Pilot gate → Migrate off legacy CA
(coexist → re-point → drain → retire) → Expand`
