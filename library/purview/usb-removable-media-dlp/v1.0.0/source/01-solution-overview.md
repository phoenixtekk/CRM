# Solution Overview — USB & Removable-Media DLP in Microsoft Purview

## What this solution delivers

Removable media is the classic exfiltration path. A file copied to a **USB stick**, an SD card, or an
external drive walks out the door in a pocket — and server-side DLP (Exchange, SharePoint, OneDrive,
Teams) never sees it, because the copy happens entirely on the endpoint. This solution governs data
to **USB and removable media** end to end in Microsoft Purview, using **two complementary control
layers** on onboarded devices:

1. **Endpoint DLP — removable-media rules (content-aware).** Once a device is **onboarded** to
   Microsoft Purview, an Endpoint DLP policy can **see and control** the on-device activity *copy a
   matching file to removable media* — **Audit**, **Warn with override**, or **Block** — keyed to your
   **sensitive content** (sensitivity labels and/or sensitive information types), with an allow-list
   for **corporate-issued** media.
2. **Device control — removable-storage access control (device-aware).** Independently of content, a
   **device-control** policy can **allow / audit / block read, write, or execute** on removable
   storage **by device group** — so unapproved USB devices can be blocked (or made read-only)
   regardless of what is on them.

The two layers answer different questions. Endpoint DLP asks *"is this **content** sensitive?"* and
acts on the file; device control asks *"is this **device** approved?"* and acts on the medium. Used
together they deliver *block/audit/allow **by policy*** for USB and removable media — configured,
**piloted in simulation/test** where the capability supports it, validated, and defensible.

This solution walks a competent-but-novice administrator through the complete, repeatable
deployment:

1. **Confirm onboarding & prerequisites** — the device must be **onboarded to Microsoft Purview**
   before any removable-media activity is visible or controllable, and the licensing/roles must be in
   place.
2. **Define the removable-media vocabulary** — the **removable-storage device group(s)** that
   distinguish corporate/allowed media from everything else, plus file-path exclusions where needed.
3. **Author the controls in the safe mode first** — the Endpoint DLP removable-media rule(s) in
   **simulation/test mode** (nothing blocked), and the device-control policy in an **audit-first**
   posture — each keyed to the design.
4. **Validate, then enforce and expand** — prove, on a small pilot device ring, that the activity is
   *seen* and *would* act; then move rules from simulation to **enforce** (and device control from
   audit to block) deliberately, with an explicit pass/fail gate and a documented rollback at every
   step.

## The two control layers (how they differ)

| Layer | What it keys on | What it controls | Configured where |
|---|---|---|---|
| **Endpoint DLP — removable media** | **Content** (sensitivity label and/or sensitive info type) | The on-device activity *copy a matching file to a removable/USB device* — Audit / Warn / Block, **except** the corporate device group. | **Microsoft Purview → Data Loss Prevention** (a DLP policy on the **Devices** location, with the removable-media endpoint restriction). |
| **Device control — removable-storage access control** | **Device** (a removable-storage device group / device properties) | **Read / Write / Execute** on removable storage — Allow / Audit / Block by device group, **regardless of content**. | **Device-control policy** deployed to onboarded devices via your management tooling (e.g. Intune / Group Policy / OMA-URI) — **verify the exact surface and availability for your tenant**. |

> **Both require onboarding.** A device must be **onboarded to Microsoft Purview** (the onboarding
> surface shared with **Microsoft Defender for Endpoint**) before removable-media activity is visible
> or controllable. **No onboarding, no control.**

## Endpoint DLP removable-media control — what it is (and is not)

- **It is** the extension of Purview Data Loss Prevention to the **Devices** location for the
  **removable-media** activity — detecting and acting on *copy a matching file to a USB / removable
  storage device*, with an allow-list of **corporate** removable-media device groups so approved
  media is exempt.
- **It is not** a whole-of-endpoint DLP rollout. This solution is **focused on removable media / USB
  and device control**; other endpoint egress channels (print, clipboard, network share, cloud/browser
  upload) are out of scope here and are a separate, broader Endpoint DLP engagement.
- **It is licensing-dependent.** Endpoint DLP is a premium capability (typically **Microsoft 365 E5**,
  the **E5 Compliance**, or the **E5 Information Protection & Governance** add-on) and in-scope users
  must be licensed. Device-control availability and the exact deployment surface likewise depend on
  your licensing and management tooling. Some settings are newer or in preview and the portal evolves
  — **verify capability availability and exact portal paths against your licensing/tenant** rather
  than assuming (see `global-requirements-purview.md` §1).

## Simulate / audit first — these are high-impact controls

A **Block** on removable media stops real work at the moment someone tries to copy a file or plug in a
device. A mis-scoped rule can block a legitimate user mid-task. Therefore:

- The Endpoint DLP removable-media policy is deployed in **simulation / test mode first** (the DLP
  policy modes *Test with notifications* / *Test without notifications*; in the portal, *"Run the
  policy in simulation mode"*) — it **evaluates and records what it *would* do without blocking
  anyone** — validated on a small pilot device group, and only then moved to **enforce**.
- The device-control policy is deployed **audit-first** (allow + audit) before any **block**, on the
  same pilot ring.

**Verify the exact simulation/test terminology and the device-control audit/enforce settings in your
tenant** (the wording evolves).

> **Determinations are not yours to make.** *Which* data is sensitive, *which* devices are approved,
> and *whether* a given copy is a policy violation are **compliance / records / security / HR-legal**
> determinations — this solution delivers the technical configuration and the evidence, not the
> determination (see `global-requirements-purview.md` §5).

## The standard deployment model

Every step follows the same repeatable model, with an explicit **pass/fail gate** between phases:

**Assess → Design → Configure → Pilot (simulation/audit) → Validate → Expand (enforce).**

- **Assess** — confirm licensing, least-privilege roles, device-onboarding readiness, the in-scope
  sensitive content, the pilot device group, and compliance/security stakeholder sign-off.
- **Design** — decide the removable-media action (audit / warn / block) and the device-control posture
  (read-only vs block for unapproved media), define the corporate device group(s), name every object,
  and set the pilot scope.
- **Configure** — set the removable-media device group(s), then build the Endpoint DLP policy + rule(s)
  in **simulation** and the device-control policy in **audit-first**.
- **Pilot** — run in simulation/audit on the pilot devices; confirm the activity is seen and *would*
  act without blocking anyone.
- **Validate** — run the pass/fail gates in `05-testing.md`.
- **Expand** — move rules to enforce and device control to block, widen device scope **only** after the
  gate passes; roll back per `03-implementation.md` if a gate fails.

## What's in the box

- This overview, a **Requirements** guide, an ordered **Implementation** guide, **Testing**
  (pass/fail gates), **Troubleshooting**, **Best Practices**, and a **Deliverables Summary** +
  **Executive Summary**.
- **Five PowerShell tools** (Security & Compliance PowerShell / Microsoft Graph): a **Discovery**
  inventory of onboarding readiness, removable-media settings, and existing config; a
  **Configure/Remediation** helper that builds the removable-media DLP policy + rule(s) in
  **simulation (`-WhatIf` first)**; a **Validation** checker; a **Reporting** rollup of removable-media
  configuration and activity; and a **scope/health** helper — **read-only or `-WhatIf` by default; no
  credentials in code.** (Device-control *policy deployment* is a management-tool action — the scripts
  report on it and DLP but do **not** invent a cmdlet to push a device-control policy.)

> **Sources.** Microsoft Learn — *Learn about Microsoft Purview Endpoint data loss prevention*,
> *Get started with / Onboard Windows devices into Microsoft Purview*, *Configure endpoint DLP
> settings* (removable-storage device groups), *Create and deploy data loss prevention policies*
> (conditions, actions, simulation mode), and *Device control / Removable storage access control*.
> These capabilities are **licensing-dependent** and the Purview portal is **evolving** — **verify
> capability availability, portal paths, and cmdlet parameters against your licensing/tenant** rather
> than assuming.
