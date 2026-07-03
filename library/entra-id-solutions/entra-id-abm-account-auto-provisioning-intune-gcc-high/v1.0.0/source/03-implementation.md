# Implementation Guide — Entra ID + ABM Managed Apple ID Auto-Provisioning (Government / GCC High)

Follow these steps in order, using the **US sovereign portals** (`*.us`) throughout. Each phase ends
with a **gate** — do not proceed until it is met. This guide implements the **supported GCC High
path** and flags the **unsupported Entra ⇄ ABM federation/SCIM** capability inline where a Commercial
guide would tell you to configure it.

> Parity reminder (read `gcc-high-parity-notes.md`): Apple states "Integration with national clouds
> isn't currently supported," so the Entra-driven federation + SCIM auto-provisioning of Managed
> Apple IDs **does not complete on a GCC High tenant today**. The device-management outcome is reached
> through **Intune Government**. Every "auto-provisioning" step below is therefore the **ABM-native +
> Intune** path, not the Commercial gallery/SCIM path.

---

## Phase 1 — Assess

### Step 1.1 — Record the parity decision (Gate R0)
Before touching any portal, read `gcc-high-parity-notes.md`, re-check the Apple federated
authentication page, and record — in writing, approved by the owner — whether your requirement is met
by the supported GCC High path or depends on the unsupported federation/SCIM link. If it depends on
federation/SCIM, **stop** and escalate the parity gap; do not attempt to force the Commercial flow
against `login.microsoftonline.us`.

### Step 1.2 — Confirm tenant, licensing, roles
1. Sign in to `https://portal.office365.us` → `Billing → Licenses`; confirm Government SKUs including
   Intune Government and Entra ID P1/P2.
2. Sign in to `https://entra.microsoft.us` → `Roles and administrators`; confirm the operator holds
   **Intune Administrator** and a **Global Administrator** is available for one-time consent.
3. Confirm two break-glass accounts exist (`entra.microsoft.us` → `Users`).

### Step 1.3 — Run discovery
On the admin workstation, run the read-only discovery script:

```
powershell -ExecutionPolicy Bypass -File .\ABMPROVG-Discovery.ps1
```

It connects with `Connect-MgGraph -Environment USGov` and reports tenant, licensing signals, Apple
enrollment configuration presence, and the pilot groups. Resolve any red items before configuring.

**Gate (Assess):** parity decision recorded; licensing/roles/break-glass confirmed; discovery shows
no blocking gaps.

---

## Phase 2 — Configure

### Step 2.1 — Establish the Apple MDM push certificate (APNs)
1. In `https://endpoint.microsoft.us` → `Devices → Enrollment → Apple`.
2. Under **Apple MDM Push certificate**, download the CSR, obtain the certificate from Apple's push
   portal, and upload it.
3. Record the **Apple ID** used (you must renew with the same Apple ID annually). Name your record
   consistently so the renewal owner can find it.

### Step 2.2 — Link Apple Business Manager to Intune Government (ADE token)
1. In `https://endpoint.microsoft.us` → `Devices → Enrollment → Apple → Enrollment program tokens →
   Add`.
2. Download the Intune **public key**.
3. In `https://business.apple.com` → `Preferences → MDM Servers → Add`, name the server
   **`Intune-Gov-MDM`**, and upload the Intune public key.
4. Download the ABM **server token** and upload it back into Intune to complete the link.
5. Set the token to **sync** on a schedule.

> This is the step where a Commercial guide would instead (or additionally) add the **"Apple Business
> Manager" provisioning gallery app** in Enterprise Applications and configure **SCIM** with a tenant
> URL + secret token from ABM to auto-provision Managed Apple IDs. **In GCC High, that gallery
> provisioning app is not offered for the US Government cloud (verify live in `entra.microsoft.us`),
> and Apple does not support the federation that underpins it.** Do not attempt it here — use the
> ABM-native Managed Apple ID approach in Step 2.4.

### Step 2.3 — Create the Automated Device Enrollment profile
1. In `endpoint.microsoft.us` → `Devices → Enrollment → Apple → Enrollment program tokens →` select
   your token → `Profiles → Create profile`.
2. Name it **`ABM-ADE-Profile-Gov`**, choose supervised/user-affinity settings per your policy, and
   assign it (initially unassigned or to a tiny test group; broaden in Pilot).

### Step 2.4 — Define the Managed Apple ID approach (ABM-native)
Because Entra federation/SCIM is unavailable in GCC High, create Managed Apple IDs with ABM's own
tooling per your documented **`ABM-Managed-AppleID-Standard`**:

- **Manual** — for small pilots, create Managed Apple IDs directly in `business.apple.com → Accounts`.
- **SFTP** — for bulk, use ABM's SFTP directory-sync feed (ABM-side, independent of Entra cloud).
- **ABM API** — for automation, use the Apple Business Manager API.

Record the naming convention and the create/suspend/delete lifecycle so it is auditable.

**Gate (Configure):** APNs certificate valid; ABM ⇄ Intune Government token valid and syncing;
`ABM-ADE-Profile-Gov` created; Managed Apple ID standard documented. Run:

```
powershell -ExecutionPolicy Bypass -File .\ABMPROVG-Validation.ps1
```

All configuration checks should pass before piloting.

---

## Phase 3 — Pilot

### Step 3.1 — Build the pilot scope
Review, then apply, the pilot scope group:

```
powershell -ExecutionPolicy Bypass -File .\ABMPROVG-Set-ScopeTargeting.ps1 -WhatIf
```

Inspect the planned membership of **`ABM-Apple-Pilot-Devices`** / **`ABM-Apple-Enroll-Users`**, then
re-run **without** `-WhatIf` to apply.

### Step 3.2 — Assign the ADE profile to the pilot
Assign **`ABM-ADE-Profile-Gov`** to **`ABM-Apple-Pilot-Devices`** in `endpoint.microsoft.us`.

### Step 3.3 — Enrol pilot devices
Wipe/prepare a small set of ABM-assigned Apple devices and run them through Setup Assistant. They
should appear as ADE-enrolled in Intune Government and receive the assigned profile/policy. If using
Managed Apple IDs, confirm sign-in with an ABM-created Managed Apple ID (not an Entra work account —
that federation path is unavailable in GCC High).

**Gate (Pilot):** pilot devices enrol via ADE, appear in `endpoint.microsoft.us`, and receive policy.

---

## Phase 4 — Validate

### Step 4.1 — Run validation and report
```
powershell -ExecutionPolicy Bypass -File .\ABMPROVG-Validation.ps1
powershell -ExecutionPolicy Bypass -File .\ABMPROVG-Report.ps1
```

Confirm: token valid and syncing; APNs valid; pilot devices enrolled; profile applied; Managed Apple
ID sign-in behaves per your standard. See `05-testing.md` for the pass/fail matrix.

### Step 4.2 — Remediate safely if needed
If validation flags a fixable drift (for example a missing group assignment), preview and apply the
safe remediation:

```
powershell -ExecutionPolicy Bypass -File .\ABMPROVG-Remediation.ps1 -WhatIf
```

Review the planned actions, then re-run without `-WhatIf`.

**Gate (Validate):** every check in `05-testing.md` is green.

---

## Phase 5 — Expand

### Step 5.1 — Widen in waves
Grow **`ABM-Apple-Pilot-Devices`** (or graduate to a production group) in controlled waves using
`ABMPROVG-Set-ScopeTargeting.ps1`. After each wave, re-run `ABMPROVG-Validation.ps1` and
`ABMPROVG-Report.ps1` and only proceed when green.

### Step 5.2 — Operationalize
- Calendar the **APNs certificate** and **ABM token** renewals (both expire annually).
- Keep the parity gap documented for stakeholders so no one expects Entra federation/SCIM
  auto-provisioning that GCC High does not offer today.
- Re-check the Apple federated-authentication page periodically — Apple's wording ("isn't
  *currently* supported") implies national-cloud support could be added later.

**Gate (Expand):** each wave green before the next; renewals scheduled; parity documented.

---

## GCC-High-specific caveats (inline summary)

- **Federation/SCIM:** not supported for national clouds (Apple) — do not configure the Commercial
  gallery/SCIM flow; it will not complete.
- **Portals:** every URL is `*.us`; a Commercial URL fails or targets the wrong tenant.
- **Graph:** every script/manual call uses `-Environment USGov` (`graph.microsoft.us`).
- **Licensing:** Government SKUs (Intune Government, Entra P1/P2).
- **ABM:** single global service; no `.us` variant — configure it as you would for Commercial, but
  only the Intune link (not Entra federation) applies.

_Re-verify the cited Apple and Microsoft pages (see `gcc-high-parity-notes.md`) before implementation;
sovereign-cloud capabilities change._
