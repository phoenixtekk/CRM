# 2. Requirements Guide — Netskope Secure Web Gateway (SWG)

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-network.md` (a
Netskope tenant, Entra ID, Intune, admin roles, network/identity fundamentals, a pilot group, and
change control with a rollback path).

## 2.1 Netskope SWG module licensed
**Description:** The Netskope tenant has the Secure Web Gateway module (and SSL inspection) licensed.
**Why:** Web filtering, categorization, and threat controls are SWG features.
**Verify:** In the Netskope console, confirm the SWG / web policy and SSL decryption controls are
available to your admin; or run `NSSWG-Discovery.ps1` (queries tenant readiness via the REST API).
**Implement:** Engage your Netskope account team to enable the SWG and SSL inspection modules.

## 2.2 Identity-based steering ready
**Description:** Users/groups are present in Entra ID and the gateway can resolve user identity.
**Why:** Per-user/per-group web-filtering policy requires identified traffic.
**Verify:** Entra → **Users** / **Groups** show the target population; the Netskope tenant is
integrated with your identity provider (SSO / directory).
**Implement:** Sync directory to Entra ID; configure the Netskope tenant's identity integration per
Netskope's documentation (the exact integration screen is deferred to the vendor).

## 2.3 Steering-scope groups
**Description:** Entra security groups `Web Steering – Pilot – Stage 1` and
`Web Steering – Broad – Stage 2`.
**Why:** These scope who is steered into the gateway, staged pilot then broad.
**Verify:** Entra → **Groups**; both groups exist; or run `NSSWG-Validation.ps1`.
**Implement:** Create them with `NSSWG-Set-ScopeTargeting.ps1`, or Entra → **Groups → New group →
Security**.

## 2.4 Client deployment to managed devices
**Description:** The Netskope client (steering agent) deployed to target devices via Intune as
`SWG Client Deployment – Managed Devices – Production`.
**Why:** The client steers device web traffic into the gateway and applies the steering config.
**Verify:** Intune → **Apps → Windows**; the app exists and shows installs; or run
`NSSWG-Validation.ps1` (checks the client/service on the device).
**Implement:** Package the Netskope client per Netskope's deployment guidance and deploy it from
Intune (the client package and its tenant parameters are obtained from your Netskope tenant).

## 2.5 Decryption (root) certificate trusted on devices
**Description:** The Netskope SSL decryption certificate deployed via Intune as
`Decryption Certificate – Managed Devices – Production` and trusted in the device root store.
**Why:** HTTPS inspection fails (certificate errors) unless the decryption certificate is trusted.
**Verify:** On a device, the certificate is in **Trusted Root Certification Authorities**; or run
`NSSWG-Validation.ps1`.
**Implement:** Export the certificate from your Netskope tenant and deploy it as a Trusted Certificate
profile in Intune.

## 2.6 Network and egress allow the gateway
**Description:** Outbound HTTPS to the Netskope cloud is permitted; no upstream proxy strips/blocks it.
**Why:** Steered traffic must reach the gateway; an upstream proxy can break steering or double-proxy.
**Verify:** From a target device, the Netskope client connects (steering active); DNS resolves and the
internet is reachable.
**Implement:** Allow the Netskope cloud endpoints through firewall/proxy per Netskope's published
ranges; remove conflicting upstream proxy settings for steered devices.

## 2.7 SSL decryption bypass list prepared
**Description:** A list of sites/categories to **exclude** from decryption (certificate-pinned apps,
sensitive/regulated categories such as health or banking, per your policy).
**Why:** Some apps break under inspection, and some categories should not be decrypted for privacy.
**Why it matters at planning time:** decrypting everything on day one causes breakage and complaints.
**Verify:** A documented bypass list is approved before enabling decryption broadly.
**Implement:** Build the bypass list and apply it in the decryption policy (the exact control is named
in the Implementation Guide; the screen is deferred to Netskope's documentation).

## 2.8 Change control and rollback (inline traffic)
**Description:** A change window and a written rollback — remove the pilot scope from steering,
disable the filtering policy, or uninstall the client.
**Why:** Inline proxy and decryption affect live traffic; every stage must be reversible.
**Verify:** The rollback is written and approved before steering any production users (see G7).
**Implement:** Document the rollback and a user-comms plan; rehearse removing
`Web Steering – Pilot – Stage 1` from steering.

---
## Checklist
- [ ] Netskope SWG + SSL inspection licensed — `NSSWG-Discovery.ps1`
- [ ] Identity integration ready; users/groups in Entra ID
- [ ] Steering groups `Web Steering – Pilot – Stage 1` / `Web Steering – Broad – Stage 2`
- [ ] Client `SWG Client Deployment – Managed Devices – Production` deployed
- [ ] Certificate `Decryption Certificate – Managed Devices – Production` trusted
- [ ] Network/egress allows the Netskope cloud
- [ ] SSL decryption bypass list prepared and approved
- [ ] Change window + rollback approved
