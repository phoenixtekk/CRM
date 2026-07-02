# 2. Requirements Guide — Intune Device Configuration & Policy Troubleshooting

Confirm **every** requirement before you diagnose — a missing prerequisite is itself a common
cause of "the policy isn't applying." Each entry follows **Description · Why required · How to
verify · How to implement if missing.** Category-wide prerequisites are in
`global-requirements-intune-solutions.md`.

> **Naming convention (used verbatim throughout this toolkit).** Create and reuse these exact object
> names so the scripts and steps line up:
> - Pilot device group: **`INTCFG-Pilot-Devices`**
> - Pilot user group: **`INTCFG-Pilot-Users`**
> - Diagnostic assignment filter: **`INTCFG-Filter-Windows-Corporate`**

## 2.1 Intune administrator role (or Policy & Profile manager)
**Description:** An Entra/Intune role able to **read and edit** device configuration policies and
their assignments — **Intune Administrator**, or the built-in **Policy and Profile Manager** role.
**Why required:** You must be able to open every assigned policy, read its assignments/filters, and
(for fixes) edit targeting. Read-only roles can diagnose but not remediate.
**How to verify:** `https://entra.microsoft.com` → **Roles and administrators** → confirm your
account holds **Intune Administrator** (or **Policy and Profile Manager**).
**How to implement if missing:** Entra → **Roles and administrators** → assign **Intune
Administrator**. Reserve Global Administrator for tenant-wide changes only.

## 2.2 Microsoft Graph read access (for the scripts)
**Description:** Delegated Microsoft Graph read scopes so the discovery/validation/report scripts can
enumerate policies, assignments, filters, groups, and per-device state.
**Why required:** The read-only scripts call Graph to build the assignment + conflict picture the
console shows one policy at a time. Without these scopes the scripts cannot sign in.
**How to verify:** Run **`INTCFG-Discovery.ps1`** — on first run it prompts for consent to
`DeviceManagementConfiguration.Read.All`. Successful sign-in confirms access.
**How to implement if missing:** Sign in as an admin who can consent, or have a Global Administrator
grant admin consent for `DeviceManagementConfiguration.Read.All`, `DeviceManagementManagedDevices.Read.All`,
and `Group.Read.All`. Install the SDK with `Install-Module Microsoft.Graph -Scope CurrentUser`.

## 2.3 Graph scopes for targeting fixes
**Description:** Write scopes needed **only** when you create/populate pilot groups with
**`INTCFG-Set-ScopeTargeting.ps1`** (`Group.ReadWrite.All`).
**Why required:** Building a scoped pilot group writes to Entra; the read scripts never need this.
**How to verify:** The script previews actions under `-WhatIf` (its default) without needing write
consent; the write scope is requested only when you re-run with `-WhatIf:$false`.
**How to implement if missing:** Have a Global Administrator grant admin consent for
`Group.ReadWrite.All` before you run the builder without `-WhatIf`.

## 2.4 Device access for local logs
**Description:** Administrative (or remote-help) access to at least one **affected device** to read
the local MDM diagnostic logs.
**Why required:** When the report says a setting errored at the **CSP apply** layer, the device's
local MDM logs carry the CSP node and error detail that the console does not.
**How to verify:** On an affected device you can open **Settings → Accounts → Access work or school →
Info → Create report**, or run **`INTCFG-Validation.ps1`** locally.
**How to implement if missing:** Arrange local admin, Intune **Remote Help**, or a remote session to
one representative device in the failing group.

## 2.5 A reproducing (affected) device and a known-good device
**Description:** One device that shows the problem **and** one comparable device where the same
policy applies correctly.
**Why required:** Comparing applied state between the two isolates whether the cause is the *policy*
(fails everywhere) or the *device/scope* (fails only on some).
**How to verify:** Intune → policy → **Device status** shows at least one **Error/Not applicable**
device and at least one **Succeeded** device.
**How to implement if missing:** Assign the policy to the **`INTCFG-Pilot-Devices`** group (see 2.6)
containing both a failing and a healthy device.

## 2.6 Pilot / diagnostic scope group
**Description:** An Entra security group used to reproduce and test targeting safely, named
**`INTCFG-Pilot-Devices`** (device-context) and/or **`INTCFG-Pilot-Users`** (user-context).
**Why required:** You test targeting and filter changes against a small, named scope before touching
production assignments.
**How to verify:** Entra → **Groups** → the group(s) exist; or run **`INTCFG-Set-ScopeTargeting.ps1`**
(default `-WhatIf`) to preview creation.
**How to implement if missing:** Entra → **Groups → New group → Security** → name it exactly as above
and add members, **or** run **`INTCFG-Set-ScopeTargeting.ps1 -WhatIf:$false`** to build and populate it.

---
## Checklist
- [ ] Intune Administrator / Policy & Profile Manager role — Entra Roles
- [ ] Graph read scopes consented — `INTCFG-Discovery.ps1` signs in
- [ ] Graph write scope available for targeting fixes (`Group.ReadWrite.All`)
- [ ] Local device access for MDM diagnostic logs
- [ ] One affected device **and** one known-good device identified
- [ ] `INTCFG-Pilot-Devices` / `INTCFG-Pilot-Users` group exists
- [ ] Naming convention adopted (groups + filter named exactly as above)
