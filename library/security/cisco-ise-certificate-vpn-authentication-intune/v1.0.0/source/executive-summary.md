# Executive Summary — Certificate-Based VPN Authentication for Cisco ISE with Intune

## The problem
Password-based VPN is the weak link Cisco ISE was built to remove. Passwords are phishable, shared,
and reused; they give no proof that the connecting device is trusted. The fix — issuing the right
device or user certificate to every endpoint, with a trust chain ISE will validate — defeats most
teams because it spans three moving parts (a certificate authority, Intune delivery, and the Cisco
head-end) that must line up exactly.

## The solution
This package stands up **certificate-based VPN authentication end to end**. You issue a device or
user certificate from **Microsoft Intune** — via **SCEP** (Certificate Connector / NDES or a Cloud
PKI) or **PKCS** — deploy the **trusted-root** and certificate profiles so the chain is complete on
each device, and hand **Cisco ISE** a clean **EAP-TLS identity** to authenticate. The result is
passwordless VPN: the endpoint proves itself with a certificate instead of a secret.

It is delivered **pilot-first and rollback-ready**, following a disciplined **Assess → Configure →
Pilot → Validate → Expand** model with explicit pass/fail gates — cert present, chain valid, ISE
EAP-TLS authentication success — so a misconfiguration is caught on a handful of pilot devices, never
on the fleet.

## What you get
- A **Solution Overview** explaining EAP-TLS with ISE as the RADIUS authority, the SCEP-vs-PKCS
  choice, and the trust chain ISE must validate.
- A **Requirements Guide** covering every prerequisite with how to verify and implement each.
- A click-by-click **Implementation Guide** for the Intune/Entra/certificate side.
- **Five PowerShell scripts** for readiness discovery, per-device certificate + chain validation,
  fleet coverage/expiry reporting, safe remediation, and pilot-group targeting.
- **Testing, Troubleshooting, and Best-Practices** guides with real pass/fail gates and field-proven
  renewal, revocation, and key-protection guidance.

## Scope and boundary
The **Intune, Entra, and certificate** side is authored at exact, click-by-click detail. **Cisco ISE
and VPN head-end console internals** (trust-store import, Certificate Authentication Profile, policy
sets, identity sources, RADIUS/VPN connection profiles) are **deferred to Cisco's official
documentation** — this solution guarantees ISE receives a correct, complete, chain-valid certificate
to authenticate.

## The bottom line
Every VPN user authenticated by a certificate Cisco ISE trusts — no passwords, delivered from Intune,
and proven on a pilot before you scale. Self-guided and tested, at a fraction of the cost of a
consulting engagement.
