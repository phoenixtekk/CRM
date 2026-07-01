# 2. Requirements Guide — SASE / SSE Architecture & Design Blueprint

Verify **every** requirement before configuring. Each entry is structured as **Description · Why ·
Verify · Implement-if-missing.** **Never assume a prerequisite exists.** Category-wide prerequisites
(Netskope tenant, Entra ID, Intune, admin roles, network/identity fundamentals, pilot group, change
control) are in `global-requirements-network.md`; this guide adds the requirements specific to a
SASE/SSE *architecture* engagement and numbers them R1–R12.

> **Naming convention (mandatory, reused verbatim throughout):** every artifact is named
> `<Purpose> – <Scope> – <Stage>`, e.g. `SASE Reference Architecture – Edge – Design`. The canonical
> names introduced here are reused in the Implementation, Testing, and Troubleshooting guides.

> **Vendor note:** exact Netskope console screens are **deferred to the official Netskope documentation
> and your tenant**. Requirements below name *what must exist*, not which menu to click.

> **Gating prerequisites:** R1 (Netskope tenant + licensed modules) and R2 (executive sponsorship)
> are **hard gates** — no architecture work proceeds past the Assess phase until both are satisfied.

---

## R1. Netskope tenant with the licensed modules for the in-scope capabilities  *(GATING)*

- **Description:** An active Netskope tenant licensed for the capability services this blueprint will
  adopt — at minimum SWG, plus ZTNA (Private Access), CASB, and SSL inspection as the roadmap dictates.
- **Why:** The tenant is the edge control plane (global requirement G1). Each roadmap phase needs the
  corresponding module licensed; an unlicensed module cannot be designed into a phase that ships.
- **Verify:** Sign in to the Netskope admin console as an administrator (G1); confirm the in-scope
  modules are licensed/entitled for the tenant. Run `SASE-Discovery.ps1` to record the current-state
  edge/identity inputs the design depends on.
- **Implement-if-missing:** Engage your Netskope account team / reseller to license the required
  modules sized to the roadmap; do not commit a phase to a module the tenant is not entitled to.

## R2. Executive sponsorship and a named program owner  *(GATING)*

- **Description:** An executive sponsor (`SASE Sponsor – Program – Run`) and a named architecture owner
  (`SASE Architecture Owner – Edge – Run`) accountable for the program.
- **Why:** A SASE/SSE move changes how every user reaches the internet and private apps and crosses
  network, identity, and endpoint teams. Without sponsorship and a single owner, phases stall and
  exceptions multiply. This is an architecture/operating-model requirement, not a technical one.
- **Verify:** Confirm a documented sponsor and architecture owner with authority over the roadmap and a
  budget/decision mandate.
- **Implement-if-missing:** Secure executive sponsorship and assign the architecture owner before any
  build; record both in the operating model (§03).

## R3. Microsoft Entra ID as the identity control plane (SSO + groups)

- **Description:** Entra ID configured as the identity source for SSO to the edge, with the security
  groups that will drive phase scope and policy targeting.
- **Why:** The whole design rests on **identity as the control plane** — policy and steering key off
  identity and group membership, not network location (global requirements G2, G5).
- **Verify:** Sign in to `https://entra.microsoft.com` (G2); confirm SSO/identity federation to the
  edge is configured and that users/groups are present. Run `SASE-Validation.ps1` to confirm the
  required targeting groups exist.
- **Implement-if-missing:** Configure SSO between Entra ID and the edge per the vendor's current
  guidance; create the targeting groups with `SASE-Set-PhaseScopeTargeting.ps1` (R8).

## R4. Endpoint management to deliver the client and certificates

- **Description:** Microsoft Intune (or equivalent) able to deploy the edge client, the
  root/decryption certificate(s), and the steering configuration to in-scope endpoints.
- **Why:** SSL inspection requires the decryption root certificate to be trusted on every steered
  endpoint; steering and the client must be delivered and kept current at scale (global requirement G3).
- **Verify:** `https://intune.microsoft.com` loads (G3); confirm target devices are enrolled/compliant
  and that a deployment channel for the client + certificate exists. `SASE-Discovery.ps1` reports
  enrolled/compliant device counts as a readiness input.
- **Implement-if-missing:** Stand up the deployment (Intune app + certificate profile + steering
  config) per the vendor's current packaging guidance; do not enable inline SSL inspection before the
  decryption certificate is trusted on the steered scope.

## R5. Network & egress design inputs (steering decision + exceptions)

- **Description:** Documented network inputs: how traffic will be steered (client-based vs.
  network-based), egress/proxy topology, and the initial **SSL-inspection exception** candidates
  (pinned-cert apps, regulated/privacy-sensitive categories).
- **Why:** Inline inspection and ZTNA change live traffic flow; the steering method and a governed
  exception list must be decided in design, not discovered in production (global requirements G5, G7).
- **Verify:** Confirm a written steering decision and a first-draft exception list captured in the
  reference architecture (`SASE Reference Architecture – Edge – Design`). Endpoints resolve DNS and
  reach the internet (G5).
- **Implement-if-missing:** Author the steering decision and the exception model as part of the Assess
  phase; record both in the reference architecture before any inline enforcement.

## R6. Current-state edge inventory (the design baseline)

- **Description:** An inventory of the existing edge controls and identity inputs the design must
  account for — current proxy/SWG, any VPN/remote-access, any cloud-app discovery/CASB, current SSL
  inspection state, and the Entra identity/groups picture.
- **Why:** You cannot design a *unified* edge without knowing what overlapping controls and paths
  already exist; the baseline drives the gap analysis and the roadmap sequencing.
- **Verify:** Confirm a baseline exists (output of `SASE-Discovery.ps1` — a read-only inventory of edge
  and identity current state) reviewed by the architecture owner.
- **Implement-if-missing:** Run `SASE-Discovery.ps1` (read-only) and capture any non-discoverable
  context (existing third-party SWG/VPN/CASB) manually into the baseline.

## R7. The named architecture artifacts exist (design deliverables)

- **Description:** The three core design artifacts are authored and version-controlled: the reference
  architecture, the policy model, and the adoption roadmap.
- **Why:** These are the deliverables the entire program executes against; without them, "SASE"
  degrades back into piecemeal tool config.
- **Verify:** Confirm `SASE Reference Architecture – Edge – Design`, `SASE Policy Model – Edge – Design`,
  and `SASE Adoption Roadmap – Edge – Program` exist and are approved.
- **Implement-if-missing:** Produce them in the Configure phase (§03) following the templates and the
  naming convention; have the architecture owner approve them.

## R8. Phase-scope targeting groups (Entra security groups)

- **Description:** Named Entra security groups that scope each roadmap phase and its pilot, e.g.
  `SASE Phase Scope – SWG – Pilot`, `SASE Phase Scope – SWG – Broad`, and equivalents per phase.
- **Why:** Phased adoption and the pilot gate depend on being able to target exactly the right users/
  devices per phase; identity-driven policy needs these groups to exist (global requirement G6).
- **Verify:** Entra → **Groups**; confirm the per-phase pilot/broad groups exist (or run
  `SASE-Validation.ps1`). The pilot group requirement is global requirement G6.
- **Implement-if-missing:** Build the groups with `SASE-Set-PhaseScopeTargeting.ps1` (defaults to
  `-WhatIf`; re-run with `-Apply` to create), named per the convention.

## R9. SSL-inspection trust + governed exception model

- **Description:** The decryption root certificate is trusted on every steered endpoint, and a
  governed, documented **exception list** exists for traffic that must not be inspected.
- **Why:** Inspection is the foundation the inline controls depend on; without trusted certificates
  users get TLS errors, and without a governed exception model you break pinned/regulated apps.
- **Verify:** On a steered endpoint, confirm the decryption root is in the trusted store (browsers/OS
  trust the edge certificate); confirm the exception list is recorded in the reference architecture.
  `SASE-Validation.ps1` checks certificate-trust readiness signals.
- **Implement-if-missing:** Deploy the root certificate via R4; author and approve the exception list as
  part of `SASE Reference Architecture – Edge – Design` before enabling inline inspection.

## R10. ZTNA private-app inputs (for the ZTNA phase)

- **Description:** A catalog of the private applications to publish via ZTNA — FQDNs/ports, the
  identity/groups that should reach each, and the connector/placement decision.
- **Why:** ZTNA replaces broad VPN access with per-app least-privilege access; you must know which apps,
  for whom, before publishing — and VPN displacement must be planned, not abrupt.
- **Verify:** Confirm a private-app catalog mapped to Entra groups exists for the ZTNA phase
  (`SASE Phase Scope – ZTNA – Pilot` / `– Broad`).
- **Implement-if-missing:** Inventory private apps and owners; map each to its access group; record in
  the roadmap's ZTNA phase. (Connector placement specifics are deferred to Netskope documentation.)

## R11. Change control, rollback, and a comms plan (per phase)

- **Description:** An approved change window, a documented rollback (disable steering / remove client /
  revert policy / re-enable VPN path), and a user-comms plan — for **each** phase cutover.
- **Why:** Every phase changes live traffic (inline enforcement, decryption, VPN displacement). CMMC-
  grade operational safety and global requirement G7 require approved windows and a tested back-out.
- **Verify:** Confirm an approved change record and a written rollback per planned phase, plus a comms
  template (global requirement G7).
- **Implement-if-missing:** Establish the change/comms process; author per-phase rollback runbooks
  (covered in Best Practices §07).

## R12. KPI baseline + operating-model owners (for the run phase)

- **Description:** A baseline of the operating-model KPIs (steering coverage, inspection coverage/
  exception rate, policy consistency, ZTNA/VPN displacement, mean time to policy change, user-impact
  rate) and the named operating-model roles assigned.
- **Why:** A design that nobody measures or owns decays; the operating model (`SASE Operating Model –
  Edge – Run`) needs a starting baseline and named owners to govern the estate over time.
- **Verify:** Confirm baseline KPI values (from `SASE-Report.ps1` plus manual inputs) and that the
  operating-model roles (§03) are assigned.
- **Implement-if-missing:** Capture the KPI baseline early (during Assess/Pilot) and assign the
  operating-model roles before the first phase expands.

---
## Checklist

- [ ] **(GATING)** Netskope tenant + licensed in-scope modules — `SASE-Discovery.ps1`
- [ ] **(GATING)** Executive sponsor + named architecture owner
- [ ] Entra ID SSO + targeting groups present — `SASE-Validation.ps1`
- [ ] Endpoint management delivers client + decryption certificate
- [ ] Steering decision + SSL-inspection exception list drafted
- [ ] Current-state edge/identity baseline captured — `SASE-Discovery.ps1`
- [ ] Reference architecture, policy model, adoption roadmap authored & approved
- [ ] Per-phase pilot/broad targeting groups — `SASE-Set-PhaseScopeTargeting.ps1`
- [ ] Decryption root trusted on steered endpoints + governed exception model
- [ ] ZTNA private-app catalog mapped to groups (for the ZTNA phase)
- [ ] Per-phase change control, rollback, comms plan
- [ ] KPI baseline captured + operating-model roles assigned — `SASE-Report.ps1`
