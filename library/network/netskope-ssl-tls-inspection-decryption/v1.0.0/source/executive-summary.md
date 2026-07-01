# Executive Summary — SSL/TLS Inspection & Decryption Rollout (Netskope)

Almost all web traffic is encrypted, so a secure web gateway that cannot decrypt it is largely blind
— threat protection, data-loss prevention, and content controls simply do not see the traffic that
matters. SSL/TLS inspection restores that visibility. But turning on decryption carelessly breaks
certificate-pinned applications, throws certificate warnings on every site, and creates privacy and
compliance problems. This solution delivers a safe rollout: establish trust for the inspection
certificate on every device, decrypt selectively with the right do-not-decrypt bypasses, and prove it
on a pilot before enforcing.

This is a complete, deploy-it-the-repeatable-way package for rolling out Netskope SSL/TLS inspection,
written for an administrator with no prior decryption-rollout experience.

## What you get
- A plain-language Solution Overview of the inspection certificate trust chain, decryption policy, and
  do-not-decrypt bypass categories, plus the privacy/compliance considerations.
- A Requirements Guide with verify / implement-if-missing for every prerequisite.
- An Implementation Guide of precise, ordered steps — deploy the inspection certificate via Intune,
  build the decryption policy and bypass list, pilot, validate, and expand.
- Five PowerShell scripts for certificate/decryption-readiness discovery, certificate-trust
  validation, a coverage report, safe remediation, and scope-group targeting.
- Testing and Troubleshooting guides for a confident rollout.

## What this delivers
The inspection certificate trusted silently on every device (deployed via Intune trusted-certificate
profiles), a decryption policy that decrypts what you should while bypassing what you must — banking,
health, and certificate-pinned apps — and a pilot-gated rollout that validates apps and user
experience before the fleet is enforced.

## The deployment model
Assess -> Configure -> Pilot -> Validate -> Expand.

## Vendor note
Netskope console internals (exact screens and menu paths) change over time and are deferred to the
official Netskope documentation and your tenant; the Intune certificate steps and PowerShell scripts
are exact.

## Outcome
Encrypted traffic made inspectable — safely — without breaking the apps that cannot be decrypted and
without exposing the traffic that should stay private, validated on a pilot before you scale.
