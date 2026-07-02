# Requirements Guide

Confirm every requirement below before you build or change an allow-list. These are **in addition to**
the category-level prerequisites in `global-requirements-network.md` (Entra tenant, Intune, admin
roles, DNS/egress fundamentals, a pilot group, and change control) — this guide covers the
prerequisites specific to **egress allow-list / required-endpoint management**.

Each requirement is written as **Description / Why / Verify / Implement if missing.**

---

## R1. A proxy or firewall you administer, with a default-deny egress posture

**Description:** An outbound proxy, secure web gateway, or firewall through which managed devices
reach the internet, where you (the operator) can create and edit allow-list rules / URL categories /
address objects. The device enforces default-deny egress (only allowed destinations pass).

**Why:** The entire solution operates by adding **explicit allow entries** for Microsoft's required
endpoints on this device. If you cannot edit its rules, you cannot implement the allow-list. If the
device is not actually default-deny, the allow-list is not what is letting traffic through and your
validation results will be misleading.

**Verify:**
- Sign in to the proxy/firewall management console with an account that can create/edit outbound
  rules or URL allow categories.
- Confirm the default outbound action for the managed-device network is **deny/block** (not allow).
- Confirm you can create a test allow rule and see it take effect.

**Implement if missing:**
- Obtain an administrator role on the device from whoever owns it. The **exact menus and object types
  differ by vendor — defer those to the vendor's official documentation**; this solution specifies
  *what* to allow and *how to name it*, not the vendor-specific clicks.
- If egress is not currently default-deny and it is supposed to be, that is a separate hardening
  project — but note that this solution is only necessary *because* egress is filtered; on a fully
  open network no allow-list is required.

---

## R2. The Microsoft required-endpoints source (endpoints web service reachable)

**Description:** Access to the **Microsoft 365 IP Address and URL web service** so you can pull the
current required IP/Port/URL set, plus access to Microsoft's documented **Intune network endpoints**,
**Autopilot dependencies**, and **Defender endpoints** references.

**Why:** The allow-list must be **derived from Microsoft's live published set**, never hardcoded. The
web service is the authoritative, versioned, machine-readable source; the documentation pages cover
the Intune/Autopilot/Defender endpoints that complete the required set.

**Verify:**
- From the workstation where you will run the Discovery script, confirm you can reach the Microsoft
  365 endpoints web service (the scripts call its `endpoints` and `version` operations for your
  instance — Worldwide for most tenants).
- Confirm you know your tenant's **instance** (Worldwide, or a sovereign/government instance) — the
  wrong instance returns the wrong addresses.

**Implement if missing:**
- Allow the management workstation (or the host that runs the scheduled keep-current job) to reach the
  Microsoft 365 endpoints web service. This is a read-only HTTPS call and can be permitted from an
  admin subnet.
- Identify your instance from your tenant type; if you are unsure, default to **Worldwide** and
  confirm against your tenant.

---

## R3. Change control and a documented rollback

**Description:** An approved change window and a written rollback for allow-list changes (which entries
were added, and how to remove or revert them).

**Why:** Allow-list changes alter what live devices can and cannot reach. A wrong or overly broad entry
can either break connectivity or open unintended egress. Every change must be reversible and recorded.

**Verify:**
- A change record exists for the planned allow-list build/update, listing the named objects to be
  created (see the Implementation Guide) and the rollback (delete those named objects / revert to the
  prior ruleset snapshot).
- The prior ruleset is snapshotted/exported before any change.

**Implement if missing:**
- Export the current ruleset from the proxy/firewall as a rollback baseline.
- Write the change record using the object names this solution specifies (so add and rollback both
  reference the same names). Get it approved before the change window.

---

## R4. A pilot scope (small, representative device set)

**Description:** A small set of devices — behind the same filter — used to validate the allow-list
before fleet rollout, plus a named **Entra security group** that targets them (`SG-EGRESS-Pilot`).

**Why:** Reachability and real-workflow success (enrollment, sync, update) must be proven on a
controlled scope before the allow-list affects every device. The pilot is where the pass/fail gate
lives.

**Verify:**
- Entra → **Groups** → confirm `SG-EGRESS-Pilot` exists (or will be created by the
  `EGRESS-Set-ScopeTargeting.ps1` script) and contains representative pilot devices/users.
- The pilot devices sit behind the same proxy/firewall as production (same egress path).

**Implement if missing:**
- Create the pilot group with `EGRESS-Set-ScopeTargeting.ps1` (defaults to preview / `-WhatIf`; run
  with `-Commit` to create), or manually via Entra → **Groups → New group → Security** named
  `SG-EGRESS-Pilot`. Add a handful of representative devices that traverse the filtered egress path.

---

## R5. Entra / Intune reachability from the management workstation

**Description:** The workstation you run the scripts from can reach Microsoft Entra and Intune (the
Microsoft Graph endpoints) with an admin account, and has the Microsoft Graph PowerShell modules
available for the scripts that read tenant scope.

**Why:** `EGRESS-Set-ScopeTargeting.ps1` reads/writes the pilot group in Entra, and validation cross-
checks against the tenant. Without Graph reachability and rights, the scope/targeting steps cannot run.

**Verify:**
- `https://entra.microsoft.com` and `https://intune.microsoft.com` load from the workstation with your
  admin account.
- `Connect-MgGraph` succeeds with the scopes the scripts request (`Group.ReadWrite.All`,
  `GroupMember.ReadWrite.All`, `Device.Read.All`).

**Implement if missing:**
- Install the Microsoft Graph PowerShell SDK: `Install-Module Microsoft.Graph -Scope CurrentUser`.
- Ensure the admin account holds a role that can manage groups (for example Groups Administrator or
  Intune Administrator) and that the management workstation's own egress permits the Graph endpoints
  (these are themselves part of the required set — see the Implementation Guide).
