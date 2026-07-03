# Executive Summary — Cloud-First Autopilot Zero-Touch Provisioning (Government / GCC High)

## The situation

Your organization operates on **GCC High** (or DoD) — the US sovereign cloud required for
regulated government and defense-industrial-base workloads (CMMC, ITAR, DFARS). You want the
same outcome commercial enterprises get from cloud-first provisioning: a new Windows 11
device is powered on, the user signs in, and it configures itself into a managed, compliant,
ready-to-work state with **no imaging and no technician touch**.

## The complication

**GCC High is not the commercial portal with a different sign-in.** It is a physically
separate cloud with `*.us` admin portals, sovereign service endpoints, and — decisively —
**a reduced feature set**. Most consequentially for this workload:

> **Classic Windows Autopilot is not available in GCC High, and Microsoft has no plan to
> bring it.** Teams that lift-and-shift a commercial Autopilot runbook build against a
> hardware-hash import and "Deployment Profiles" blade **that do not exist here** — wasting
> a project cycle before discovering the gap.

Additional gaps that quietly break commercial designs: **Windows Autopatch and the newer
update policies are unavailable**, **Microsoft Store for Business, Cloud PKI, Device Health
Attestation, DFCI, and Remote Help are unavailable**, and self-deploying/pre-provisioning
modes and OOBE device-rename are **not yet available**.

## The resolution

This solution delivers zero-touch provisioning on the **one supported path**: **Windows
Autopilot device preparation** (user-driven, Microsoft Entra join), which **is** supported
in GCC High/DoD. It provides:

- The correct **`*.us` portal navigation** end to end, with every commercial-vs-GCC-High
  difference called out at the step where it matters.
- A named, reusable object set (provisioning users group, **assigned** device group owned by
  the **Intune Provisioning Client** service principal, device preparation profile,
  enrollment status page, least-privilege RBAC role, update ring, compliance policy).
- **Five PowerShell scripts** that connect to **US Gov Graph** (`-Environment USGov`) for
  read-only discovery, validation, and reporting, plus **safe** remediation and scope
  targeting that default to **`-WhatIf`** (preview before change).
- A **cited GCC High parity reference** separating doc-confirmed facts from items flagged
  **"verify for GCC High,"** so nothing is taken on faith.
- Testing and troubleshooting with **pass/fail gates** and the GCC-High-specific failure
  modes (most notably: the empty-device-group symptom when the provisioning service
  principal is not the group owner).

## The outcome

Cloud-first Windows provisioning stood up **correctly on GCC High** — right portals, right
supported technology, parity gaps handled, servicing designed around update rings rather
than unavailable Autopatch — and **proven on a pilot** before you scale, using the standard
**Assess → Configure → Pilot → Validate → Expand** model.

## Bottom line

Self-guided, tested, sovereign-correct — at a fraction of the cost of a consulting
engagement, and without the failed first attempt that comes from running commercial steps on
a government tenant.

*All feature-availability claims are drawn from Microsoft US Government documentation; see
`gcc-high-parity-notes.md` for the full cited list and any "verify for GCC High" flags.*
