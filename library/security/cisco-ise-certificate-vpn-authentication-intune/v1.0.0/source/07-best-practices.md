# 7. Best Practices — Certificate-Based VPN Authentication for Cisco ISE with Intune

Field-proven practices for running certificate-based EAP-TLS VPN authentication safely over time.
Focus areas: **renewal, revocation, and key protection.**

## Renewal
- **Set a renewal threshold** on every SCEP/PKCS profile (e.g. **20%** of validity). Auto-renewal
  before expiry is what keeps users from silently losing VPN access.
- **Keep validity periods sane.** Shorter validity (e.g. 1 year) limits exposure but means renewal
  must be reliable; do not set validity so short that renewal churn becomes a support burden.
- **Monitor upcoming expiry** with `CISECERT-Report.ps1` on a schedule; chase devices that miss a
  renewal window before their leaf expires.
- **Confirm the device checks in.** Renewal only fires when the device syncs with Intune — devices
  offline past their threshold will not renew. Track stale check-ins.
- **Test renewal in the pilot**, not in production. Verify a device near threshold actually receives
  a fresh certificate and that ISE accepts the renewed cert (same Subject/SAN).

## Revocation
- **Decide who enforces revocation.** In this design **Cisco ISE** performs revocation checking
  (CRL/OCSP) during EAP-TLS. Make that policy explicit with whoever owns ISE.
- **Ensure CRL/OCSP reachability from ISE** (R9). A valid certificate is rejected if ISE cannot
  complete a required revocation check — keep the CA's CRL distribution point / OCSP responder
  published and reachable.
- **Have a revocation runbook.** When a device is lost/retired, revoke its certificate at the CA (or
  via the Cloud PKI / connector) **and** retire the device in Intune. Revocation on the CA is what
  makes ISE deny a compromised certificate; removing the Intune assignment alone does not revoke an
  already-issued cert.
- **Keep CRL publication frequent enough** that revocation takes effect within your risk tolerance;
  prefer **OCSP** where low-latency revocation matters.

## Key protection
- **Prefer SCEP for device certs** so the **private key is generated on the device and never
  leaves it**.
- **Use the TPM** as the key storage provider where available (Windows) so the private key is
  hardware-protected and non-exportable.
- **Mark keys non-exportable.** Do not issue exportable private keys for VPN authentication unless a
  specific, documented reason exists.
- **For PKCS**, understand the key is generated at the connector/CA and delivered — protect the
  connector server accordingly and restrict who can issue against the client-auth template.

## Identity and trust hygiene
- **One agreed identity attribute.** Fix the Subject/SAN Intune issues and the attribute ISE keys on
  as a single documented decision; changing one without the other silently breaks authentication.
- **Import the chain into ISE deliberately.** Track which root/intermediate ISE trusts; rotate ISE's
  trust when the CA rotates. Deploying a new chain to devices without updating ISE breaks EAP-TLS.
- **Least-privilege EKU.** Issue leaf certificates with **Client Authentication** only unless another
  EKU is genuinely required.

## Rollout and operations
- **Always pilot first**, with a documented rollback and the password/legacy VPN path kept available
  until certificate auth is proven (Gate 6+). Never remove the fallback before broad success.
- **Expand in waves**, validating coverage with `CISECERT-Report.ps1` and spot-checking ISE Live
  Logs each wave.
- **Name every object per convention** (`Cisco VPN – …`, `PILOT – …`, `BROAD – …`) so the Intune,
  Entra, and ISE sides stay legible to the next operator.
- **Keep change control** on anything touching certificates or VPN auth (global R8) — these changes
  can lock users out of the network.
- **Respect the vendor boundary.** Own the Intune/Entra/certificate side precisely; follow Cisco's
  official documentation for ISE and head-end configuration and keep those steps in your ISE runbook.
