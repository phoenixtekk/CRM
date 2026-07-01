# 2. Requirements Guide — Cloud PKI Integration with Intune

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-security.md`.

> **Vendor note:** the cloud-PKI product's own subscription, console, connector install, and CA
> configuration are deferred to **the vendor's documentation**. The requirements below cover what
> must be true on the **Intune/Entra** side and the integration touch-points.

## 2.1 Licensing
**Description:** Intune (Plan 1 or via M365 E3/E5 / Business Premium) plus a **cloud PKI subscription with an Intune integration**.
**Why:** Intune delivers the certificate profiles and trust chain; the cloud PKI is the issuing CA.
**Verify:** M365 admin center → **Billing → Licenses** (Intune); the cloud PKI vendor's portal shows an active subscription with the Intune connector/plugin feature.
**Implement:** Assign Intune licensing; procure the cloud PKI subscription tier that includes its Intune integration (per vendor docs).

## 2.2 Device enrollment
**Description:** Targeted devices enrolled in Intune.
**Why:** Certificate profiles apply only to enrolled devices.
**Verify:** Intune → **Devices → All devices**; run `CPKI-Discovery.ps1`.
**Implement:** Enable automatic enrollment; enroll the target devices.

## 2.3 Cloud PKI Intune connector / plugin connected
**Description:** The cloud PKI's Intune connector or plugin is registered and connected to your tenant.
**Why:** Without the connector, Intune cannot request certificates from the cloud PKI's issuing CA.
**Verify:** Intune → **Tenant administration → Connectors and tokens → Certificate connectors** (and the cloud PKI's portal); run `CPKI-Discovery.ps1` (lists certificate connectors). Confirm the connector shows **Active/healthy** with a recent check-in.
**Implement:** Follow the **vendor's documentation** to install/register the connector or plugin and grant it the required Graph permissions; confirm it appears healthy in Intune.

## 2.4 Trust chain available (root + any intermediate)
**Description:** The cloud PKI's **root** CA certificate and any **intermediate** CA certificate(s), exported as `.cer` (DER) files.
**Why:** A leaf certificate is useless on the device without a trusted chain; the chain must be deployed before issuance.
**Verify:** You have the root (and intermediate) `.cer` from the cloud PKI portal; `certutil -dump <file>.cer` shows the expected subject/issuer.
**Implement:** Export the root and intermediate CA certificates from the cloud PKI (per vendor docs) as DER `.cer` files for upload to Intune Trusted certificate profiles.

## 2.5 Issuing CA / certificate template ready in the cloud PKI
**Description:** An issuing CA (and its certificate template/profile) configured in the cloud PKI for the certificates you will issue (device auth, user auth).
**Why:** Intune SCEP/PKCS profiles request from a specific issuing CA/template; it must exist and allow the intended subject/SAN, key usage, and validity.
**Verify:** The cloud PKI portal shows the issuing CA and template with the intended EKU (e.g. Client Authentication), key size, and validity; note the **SCEP URL** / connector identifier the vendor provides.
**Implement:** Create/confirm the issuing CA and template in the cloud PKI (per vendor docs); record the SCEP URL / template name for the Intune profile.

## 2.6 Certificate scope groups (pilot + broad)
**Description:** Entra security groups that scope certificate issuance — at minimum a pilot and a broad group, split by device vs user as needed.
**Why:** Issuance is piloted first; user vs device certificates assign to different group types.
**Verify:** Entra → **Groups**; the scope groups exist; or build them with `CPKI-Set-ScopeTargeting.ps1`.
**Implement:** Create `Cloud PKI Cert – Devices – Pilot` / `– Broad` and `Cloud PKI Cert – Users – Pilot` / `– Broad` (use `CPKI-Set-ScopeTargeting.ps1`).

## 2.7 Certificate-backed scenario targets (Wi-Fi / VPN / auth)
**Description:** The Wi-Fi/VPN/authentication scenario(s) the certificate will serve, and their existing profiles.
**Why:** Validation confirms the *scenario* works, not just that a certificate installed; the certificate profile must match what the scenario expects (EKU, SAN).
**Verify:** Intune → **Devices → Configuration**; existing Wi-Fi/VPN profiles (or the auth scenario) are identified and reference a certificate.
**Implement:** Identify (or create) the Wi-Fi/VPN/auth profile that will consume the issued certificate; note the required certificate properties.

## 2.8 Legacy CA inventory (for migration)
**Description:** An inventory of what the existing on-prem CA currently issues (which profiles, which scenarios, which devices) and its connector.
**Why:** You cannot safely migrate or retire the legacy CA without knowing what depends on it.
**Verify:** Intune → existing SCEP/PKCS and Trusted certificate profiles; the existing certificate connector; run `CPKI-Report.ps1` for current coverage.
**Implement:** Document the legacy SCEP/PKCS profiles, the scenarios they back, and the connector — this is the migration checklist.

## 2.9 Change control / rollback (authentication-impacting)
**Description:** A change ticket, maintenance window, approver, and documented rollback for the issuance and migration changes.
**Why:** Certificate and Wi-Fi/VPN changes can lock users out of the network; a pilot gate and rollback are mandatory (see global G8).
**Verify:** The change record exists with an approver and a rollback step.
**Implement:** Record the change, name the pilot group, define rollback (unassign new profiles; legacy chain remains trusted), and get approval.

---
## Checklist
- [ ] Intune licensing + cloud PKI subscription with Intune integration
- [ ] Devices enrolled — `CPKI-Discovery.ps1`
- [ ] Cloud PKI Intune connector/plugin connected and healthy — `CPKI-Discovery.ps1`
- [ ] Trust chain (root + intermediate) exported as `.cer`
- [ ] Issuing CA / template ready in the cloud PKI; SCEP URL / template recorded
- [ ] Scope groups created (devices + users, pilot + broad) — `CPKI-Set-ScopeTargeting.ps1`
- [ ] Wi-Fi/VPN/auth scenario target identified
- [ ] Legacy CA inventory documented — `CPKI-Report.ps1`
- [ ] Change control + rollback approved
