# Requirements

Confirm each prerequisite below **before** you begin the implementation. These are specific to
the ISE ↔ Intune posture integration and are **in addition to** the category-level Network
global requirements (see `global-requirements-network.md`, especially an Entra tenant, Intune,
admin roles, a pilot group, and change control).

Each requirement is written as **Description / Why / Verify / Implement if missing.** Work
through them top to bottom; do not start Configure until all are green.

---

## R1. Microsoft Intune with enrolled devices

**Description:** An active Intune tenant with the target devices already enrolled (MDM-managed).

**Why:** ISE reads *Intune's* view of each device. A device Intune does not manage has no
enrollment or compliance state for ISE to query, so it can only ever be treated as unmanaged.

**Verify:** Sign in to `https://intune.microsoft.com` → **Devices → All devices** and confirm
your target devices appear with a **Managed by = Intune (MDM)** and a recent check-in time.

**Implement if missing:** Assign an Intune-bearing license to the users, then enroll the
devices (Windows: Entra join + Intune enrollment; iOS/Android: Company Portal; macOS: ADE or
Company Portal). Do not proceed until at least the pilot devices are enrolled.

---

## R2. Intune device compliance policies in place

**Description:** At least one **compliance policy** per target platform, defining what
"compliant" means (encryption, OS floor, jailbreak/root block, password/PIN).

**Why:** ISE's access decision is only as meaningful as the compliance rules behind it. With no
compliance policy, every enrolled device is trivially "compliant" and the posture gate enforces
nothing. This solution creates the named baseline policies in the Implementation guide.

**Verify:** Intune → **Devices → Compliance → Policies**. Confirm a policy exists for each
platform you will gate. If you are starting fresh, this will be empty — that is expected; you
will create them.

**Implement if missing:** Create the named baseline policies during Implementation:
`Compliance – Windows – Baseline`, `Compliance – iOS – Baseline`,
`Compliance – Android – Baseline`, `Compliance – macOS – Baseline`.

---

## R3. An Entra app registration with the right Graph permissions

**Description:** A dedicated Microsoft Entra **app registration**, `ISE-Intune-Compliance-Connector`,
with a client secret and **application** Microsoft Graph permissions that let ISE read managed
device / compliance state — at minimum `DeviceManagementManagedDevices.Read.All` and
`DeviceManagementConfiguration.Read.All` — admin-consented.

**Why:** ISE authenticates to your tenant *as this app* and calls Graph with its permissions.
Without the app registration and consented permissions, ISE cannot read device state and the
connector will fail to report.

**Verify:** Entra → **App registrations** → look for `ISE-Intune-Compliance-Connector`. On
**API permissions**, confirm the Graph permissions are present and show **"Granted for
&lt;tenant&gt;"** (green check). Confirm a valid (unexpired) client secret exists.

**Implement if missing:** Create it during Implementation (register the app, add the Graph
application permissions, grant admin consent, generate a client secret). The
`ISEPOST-Discovery.ps1` script reports on this app's readiness.

---

## R4. Cisco ISE licensed and versioned for MDM integration

**Description:** A running Cisco ISE deployment on a release that supports the **MDM / External
MDM (Intune)** integration, with the appropriate licensing (the tier that includes MDM/posture).

**Why:** The External MDM server feature and its authorization dictionary attributes are only
present on supported ISE releases and license tiers. This is the enforcement engine — without
it there is nothing to consume the compliance signal.

**Verify:** In the ISE admin console, confirm the running version and installed licenses.
**Follow Cisco's official documentation** for the exact menu path and the minimum version /
license that supports Intune MDM integration for your release — do not assume from this guide.

**Implement if missing:** Upgrade ISE and/or apply the required license per Cisco's
documentation and your Cisco account team. This is a Cisco-side action.

---

## R5. Network reachability and trust: ISE → Microsoft Graph

**Description:** ISE must be able to reach Microsoft Graph / Entra login endpoints over HTTPS
(443), with correct DNS resolution, egress, and a trusted certificate chain to Microsoft.

**Why:** The connector is an outbound API call from ISE to Microsoft's cloud. Blocked egress, a
proxy that intercepts TLS, or a missing root CA in ISE's trust store breaks the connection and
ISE cannot read compliance state.

**Verify:** From the ISE deployment's egress path, confirm HTTPS reachability to Microsoft
Graph and Entra login endpoints and that the Microsoft server certificate chain is trusted by
ISE. (In the ISE console, the External MDM server **test connection** is the authoritative
check — see Cisco's documentation.)

**Implement if missing:** Open outbound 443 to the Microsoft Graph / Entra endpoints, fix DNS,
and import the required Microsoft root/intermediate CA certificates into the ISE trusted
certificate store per Cisco's documentation.

---

## R6. A pilot group

**Description:** A Microsoft Entra security group, `PILOT – ISE Posture Devices`, containing
only the initial pilot devices (or their users).

**Why:** Compliance policies and the posture gate are rolled out pilot-first so a mistake denies
access to a handful of test devices, not the fleet. This is the safety valve for a live-access
change.

**Verify:** Entra → **Groups** → confirm `PILOT – ISE Posture Devices` exists and contains the
intended pilot members.

**Implement if missing:** Create it in Entra (**Groups → New group → Security**) or run the
`ISEPOST-Set-ScopeTargeting.ps1` script in this solution, which creates and populates it.

---

## R7. Change control and a documented rollback

**Description:** An approved change window and a written rollback for the posture gate
(loosen the ISE authorization rule to permit, or unassign the compliance policy) before you
enable enforcement.

**Why:** This change gates live network and VPN access. A misconfigured rule can lock out
legitimate users. You must be able to revert quickly.

**Verify:** A rollback procedure is written and approved: how to set the ISE authorization rule
back to permit, and how to unassign / scope out the compliance policy, with who approves and how
users are notified.

**Implement if missing:** Document the rollback (ISE rule revert + compliance policy unassign +
comms plan) and get it approved before Pilot.
