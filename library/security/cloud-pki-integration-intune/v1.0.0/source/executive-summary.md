# Executive Summary — Cloud PKI Integration with Intune (Certificate Management Modernization)

Certificates are everywhere in a modern fleet — Wi-Fi, VPN, and user/device authentication all
depend on them — yet many organizations still issue them from an aging on-prem certification
authority (CA) chained to Intune through a fragile connector. That model is hard to scale, hard to
make highly available, and a single point of failure for network access. A **cloud PKI with an
Intune integration** modernizes this: certificates are issued to Intune-managed devices through the
cloud PKI's Intune connector/plugin, the trust chain is deployed by Intune, and the on-prem CA
dependency is reduced or retired.

This is a complete, deploy-it-today package for integrating a cloud PKI with Microsoft Intune,
written for an administrator with no prior PKI-modernization experience. It is **vendor-neutral** —
the specific cloud-PKI product's console and connector internals are deferred to that vendor's
documentation, while this solution gives the correct, repeatable Intune-side procedure that applies
to any cloud PKI with an Intune integration.

## What you get
- A plain-language **Solution Overview** of how a cloud PKI integrates with Intune (connector/plugin, trust chain, SCEP vs PKCS issuance) and what migrating off an on-prem CA looks like.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite.
- An **Implementation Guide** of precise, ordered Intune steps: connect the cloud PKI, deploy the trusted root/intermediate chain, create SCEP/PKCS certificate profiles, issue to a pilot, validate certificate-backed scenarios, then migrate workloads off the legacy CA.
- Five **PowerShell scripts** for connector/profile readiness discovery, per-device issuance validation, certificate coverage + expiry reporting, safe remediation of failed issuance, and certificate-scope group building.
- **Testing** and **Troubleshooting** guides with explicit pass/fail gates.

## What this delivers
A working **cloud PKI ↔ Intune integration**: the connector connected, the trusted root/intermediate
chain deployed, SCEP and/or PKCS certificate profiles issuing certificates to a validated pilot, the
certificate-backed scenarios (Wi-Fi, VPN, authentication) confirmed, and certificate workloads
migrated off the legacy on-prem CA through a coexistence-then-retire path.

## The deployment model
**Assess → Configure → Pilot → Validate → Expand**, with a mandatory pilot gate and a documented
rollback before any production assignment.

## Outcome
Certificates issued to Intune-managed devices from a cloud PKI — trust chain deployed, Wi-Fi/VPN/auth
validated, and the on-prem CA dependency reduced or retired — proven on a pilot before you scale.
