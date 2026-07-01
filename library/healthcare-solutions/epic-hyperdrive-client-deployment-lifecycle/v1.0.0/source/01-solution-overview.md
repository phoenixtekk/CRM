# 1. Solution Overview — Epic Hyperdrive & Hyperspace Client Deployment & Lifecycle Management with Microsoft Intune

This solution gives you a repeatable, auditable way to **package, deploy, validate, update, and
retire the Epic clinical EHR client** across a clinical endpoint fleet using **Microsoft Intune**
(and Microsoft Configuration Manager / SCCM where devices are co-managed). It covers both Epic's
current **Hyperdrive** client (the Chromium / WebView2-based client) and the legacy **Hyperspace**
client, and it treats the EHR client as a managed, versioned application with a defined lifecycle —
not a one-time install.

The work follows the **standard deployment model**: **Assess → Package → Pilot → Validate → Broad
Deploy → Lifecycle (update / supersede / retire)**.

---

## What this solution delivers

- A **Win32 app package** (`.intunewin`) of the Epic client, built with the Microsoft Win32 Content
  Prep Tool, with **named detection, requirement, and (for upgrades) supersedence rules** that pin
  the deployment to the exact Epic version your environment runs.
- **Deployment rings** as named Microsoft Entra device groups — `EPIC – Clinical Workstations`
  (the population), `Epic Hyperdrive – Pilot Ring`, and `Epic Hyperdrive – Broad Ring` — so every
  release is proven on a small, representative set of clinical endpoints before it reaches the floor.
- A **validation gate** (documented tests plus PowerShell scripts) that confirms the correct version
  installed, the client launches and loads, the WebView2 runtime is present (Hyperdrive), and the
  Imprivata badge-tap single sign-on still works before the rollout is allowed to expand.
- A **lifecycle process**: upgrades delivered via Intune **supersedence** (new version automatically
  replaces and uninstalls the old one), and a clean **retire / uninstall** path for decommissioned
  versions so no stale Epic client is left behind.
- Five PowerShell tools (discovery, validation, fleet reporting, safe remediation, and ring-group
  provisioning) to operate the deployment day to day.

## Devices in scope

- **Clinical workstations** (fixed exam-room and nursing-station PCs).
- **Workstations-on-wheels (WOWs)** / mobile carts.
- **Exam-room PCs** and other shared clinical endpoints.

These are typically **shared, multi-user, always-on** devices on a clinical network, which is why
ring-based rollout, tight version pinning, and validated update windows matter more here than on a
standard office fleet.

## What is in scope vs. referenced only

**In scope (this solution):** Intune / ConfigMgr **packaging, detection, requirement and
supersedence rules, ring assignment, validation, and the update / retire lifecycle** of the Epic
client.

**Referenced only (covered in depth by separate solutions):**
- **Imprivata** single sign-on / badge-tap / EPCS configuration on clinical endpoints — this
  solution only **validates that tap-to-launch into Epic still works** after a client change.
- **Clinical peripherals** (signature pads, label/wristband printers, document scanners, card
  readers) — referenced as validation touchpoints only.

## Critical accuracy note — get the Epic specifics from your Epic build team

Epic's installer package, command-line switches, the exact **client version string**, and the
**environment / connection configuration** (which Epic environment the client points to, e.g.
PRD) are defined in **Epic's customer-only documentation (UserWeb / Galaxy)** and by **your
organization's Epic Technical Services / client systems team**. This solution **does not invent**
Epic-internal installer flags or version numbers — and you should not either.

Throughout the Implementation Guide you will see placeholders such as
`<EPIC_INSTALLER>`, `<EPIC_VERSION>`, `<EPIC_INSTALL_DIR>`, and `<EPIC_EXE>`. **Obtain the real
values from your Epic build team / Epic UserWeb** and substitute them consistently. The Intune /
ConfigMgr mechanics around those values — packaging, detection, rings, supersedence, retire — are
documented here exactly and accurately.

## Why this approach

- **Patient-safety / clinical continuity:** the EHR client is mission-critical. Ring-based rollout
  contains the blast radius of a bad client build to a handful of validated devices, not the whole
  floor.
- **Version coherence with Epic:** Epic client versions are tied to your Epic environment's upgrade
  cadence. Pinning the deployed version (via detection) and upgrading via supersedence keeps the
  fleet aligned to the version Epic expects you to run.
- **Clean lifecycle:** supersedence and a defined retire path prevent the classic problem of
  multiple Epic client versions accreting on shared clinical devices.

## How to use this package

Read the documents in order:
1. **02 – Requirements** and **global-requirements-healthcare-solutions** — confirm everything is in
   place before you build anything.
2. **03 – Implementation** — package, pilot, validate, broad-deploy, then run the lifecycle.
3. **05 – Testing** — the acceptance gate that must pass before expansion.
4. **07 – Best Practices**, **08 – Deliverables Summary**, and **06 – Troubleshooting** as needed.
