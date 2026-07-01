# 2. Requirements Guide — SSL/TLS Inspection & Decryption Rollout (Netskope)

Verify every requirement before configuring. Each entry: Description · Why · Verify ·
Implement-if-missing. Category-wide prerequisites are in `global-requirements-network.md`.

Named artifacts used throughout this solution (create with these exact names and reuse verbatim):

- Trusted cert profile: `Netskope Inspection Root – All Managed Devices – Pilot`
- Trusted cert profile: `Netskope Inspection Root – All Managed Devices – Production`
- Decryption policy: `SSL Inspection – Pilot Group – Pilot`
- Decryption policy: `SSL Inspection – All Users – Production`
- Bypass list: `Do-Not-Decrypt – Sensitive & Pinned – All Stages`
- Pilot group: `SSL Inspection – Pilot Users – Pilot`
- Broad group: `SSL Inspection – All Users – Production`

## 2.1 Netskope tenant with SSL inspection licensed
Description: An active Netskope tenant with the secure web gateway and SSL/TLS inspection capability.
Why: It is the control plane that terminates and inspects TLS and enforces decryption policy.
Verify: Sign in to the Netskope tenant admin console as an administrator; confirm SSL inspection is
available in your subscription.
Implement: Engage your Netskope account team / reseller to enable the required modules.

## 2.2 The inspection (forward-trust) certificate
Description: The certificate authority that signs the on-the-fly certificates the gateway presents
during decryption, including its root (and any intermediate) for client trust.
Why: Without the device trusting this certificate, every decrypted site throws a certificate warning.
Verify: Confirm the inspection certificate exists in your Netskope tenant and you can export its
root/intermediate certificate(s) for deployment. Exact export location is deferred to Netskope docs.
Implement: Use the Netskope tenant's inspection certificate (default or your own enterprise-signed
certificate); export the root/intermediate for Intune deployment.

## 2.3 Intune able to deploy certificates to endpoints
Description: Microsoft Intune managing the target devices, able to push trusted-certificate profiles.
Why: The inspection certificate root must land in each device's trusted root store for silent trust.
Verify: `https://intune.microsoft.com` loads; target devices are enrolled and compliant.
Implement: Assign an Intune-bearing license; enroll the target devices; confirm device compliance.

## 2.4 A do-not-decrypt bypass source
Description: A defined set of categories, domains, and pinned applications that must NOT be decrypted
(banking, health, certificate-pinned apps, and other sensitive personal categories per policy).
Why: Decrypting these breaks apps or creates privacy/compliance exposure.
Verify: A written do-not-decrypt list exists and is approved by privacy/security stakeholders.
Implement: Build the list `Do-Not-Decrypt – Sensitive & Pinned – All Stages` from category mappings
(finance, health, legal, government) plus known pinned applications; have privacy/legal review it.

## 2.5 A pilot group
Description: A Microsoft Entra security group of pilot users/devices for staged rollout.
Why: Decryption affects live traffic and must be validated on a small group before the fleet.
Verify: Entra -> Groups; `SSL Inspection – Pilot Users – Pilot` exists with representative members.
Implement: Entra -> Groups -> New group -> Security; add representative pilot members; run
`NSSSL-Set-ScopeTargeting.ps1` to populate it.

## 2.6 Privacy / compliance sign-off
Description: Documented approval that the do-not-decrypt posture and user notification meet policy.
Why: Decryption exposes user traffic; sensitive personal categories and notification are governed.
Verify: A privacy/compliance review of the decryption scope and bypass list is recorded.
Implement: Review the decryption scope with privacy/legal and works-council/HR where required;
record the approved do-not-decrypt categories and the user-notification approach.

## 2.7 Change control and a rollback path
Description: A change window and a documented rollback (disable the decryption policy / revert scope).
Why: Inline decryption affects live traffic and must be reversible if an app or user impact appears.
Verify: A rollback procedure is written and approved before enabling enforcement.
Implement: Define the rollback (disable `SSL Inspection – Pilot Group – Pilot`, or remove pilot
members) and a user-comms plan before enforcing.

---
## Checklist
- [ ] Netskope tenant with SSL inspection licensed
- [ ] Inspection certificate identified and root/intermediate exportable
- [ ] Intune deploying trusted-certificate profiles to enrolled devices
- [ ] Do-not-decrypt bypass source defined (banking, health, pinned, sensitive)
- [ ] Pilot group `SSL Inspection – Pilot Users – Pilot` created
- [ ] Privacy / compliance sign-off recorded
- [ ] Change control + rollback path written and approved
