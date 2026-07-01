# 1. Solution Overview — SSL/TLS Inspection & Decryption Rollout (Netskope)

## Why decryption matters
The large majority of web traffic is now TLS-encrypted. A secure web gateway that cannot see inside
that traffic cannot apply threat protection, data-loss prevention, or content/category controls to
it — it is effectively blind to most of what users actually do. SSL/TLS inspection (also called TLS
decryption) is what restores visibility: the gateway terminates the TLS session, inspects the
plaintext, then re-encrypts to the destination.

But decryption is the single most sensitive change you can make to a secure web gateway. Turned on
carelessly it breaks certificate-pinned applications, generates certificate warnings on every site,
and creates privacy and compliance exposure by exposing sensitive personal traffic (banking, health,
legal). The discipline that makes it safe is the same every time: establish trust for the inspection
certificate on every device first, decrypt selectively with the right do-not-decrypt bypasses, and
prove it on a pilot before you enforce broadly. That is the repeatable way this solution delivers.

## How SSL/TLS inspection works (the trust chain)
1. The gateway performs a man-in-the-middle on the TLS session: it presents a certificate it signs
   on the fly for each destination, signed by an inspection (forward-trust) certificate authority.
2. For the client to trust that re-signed certificate without warnings, the inspection certificate's
   root (and any intermediate) must be installed in the device's trusted root store.
3. That trust is what this solution deploys via Intune trusted-certificate profiles — assign once,
   trusted everywhere.
4. Some applications refuse any certificate they did not expect (certificate pinning); these cannot
   be decrypted and must be bypassed, not forced.

## Decryption policy and do-not-decrypt bypasses
A decryption policy decides, per request, whether to decrypt or pass through (do-not-decrypt). The
goal is to decrypt what you should and bypass what you must:

- Decrypt the broad web you want to inspect (general browsing, unknown/uncategorized destinations,
  the categories where threats and data loss actually occur).
- Do-not-decrypt the categories where decryption is inappropriate or impossible:
  - Banking and financial categories — privacy and regulatory sensitivity.
  - Health and medical categories — sensitive personal data and compliance exposure.
  - Certificate-pinned applications — they break when decrypted; pass them through.
  - Other sensitive personal categories per your privacy policy (legal, government, etc.).

The bypass list is a first-class artifact in this solution, named and reused, so the same exclusions
apply consistently as you expand from pilot to fleet.

## Privacy and compliance
Decryption exposes the contents of user traffic to the inspection system. Treat it as a governed
change: document what is decrypted and what is bypassed, exclude sensitive personal categories by
default, involve privacy/legal and works-council/HR where required, and notify users per policy.
A clear, documented do-not-decrypt posture is both a technical safeguard and a compliance artifact.

## What you control
- Which traffic is decrypted vs. passed through (the decryption policy and its rule order).
- The do-not-decrypt bypass list (categories, domains, and pinned applications).
- The inspection certificate trust on every device (deployed and verified via Intune).
- The scope of enforcement (pilot group first, then broad), and the rollback path.

## Limitations (be honest with buyers)
- Certificate-pinned applications cannot be decrypted — they must be bypassed, not forced.
- Decryption is privacy- and compliance-sensitive; sensitive personal categories should be bypassed.
- Inspection adds processing; sustained heavy traffic should be validated for user experience.
- This solution covers the inspection certificate trust chain plus Intune deployment, the decryption
  policy model, and the do-not-decrypt bypass posture. Exact Netskope console screens, menu paths,
  and tenant-specific options change over time and are deferred to the official Netskope
  documentation and your Netskope tenant.

## The standard deployment model
> Assess the estate and certificate trust, configure the inspection certificate plus decryption
> policy and bypass list, pilot on a small group, validate apps and user experience, then expand to
> the fleet. The repeatable model: Assess -> Configure -> Pilot -> Validate -> Expand.
