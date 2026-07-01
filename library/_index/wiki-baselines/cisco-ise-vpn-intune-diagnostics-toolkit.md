# Cisco ISE VPN + Intune Troubleshooting & Diagnostics Toolkit

> **Version 1.0.0** · Category: Network · Solution code: CISEDIAG

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary

## The problem

When a certificate-based VPN or ISE posture check stops working, the failure is genuinely hard to place. The Cisco Secure Client + Cisco ISE + Microsoft Intune stack spans **four cooperating layers** — the Intune certificate/profile, client connect, the EAP-TLS chain, and ISE posture/authorization — and a break in any one layer *looks identical to* a break in every layer below it. Teams burn hours per incident guessing, and escalate to Cisco blind, without the evidence that would resolve the case in one round.

## What this toolkit delivers

A **structured, layered root-cause tree** entered by symptom, plus **five read-only PowerShell diagnostic scripts**, that together isolate the failing layer in minutes instead of hours. It is a **troubleshooting/diagnostics** product — a self-guided playbook you keep and reuse on every incident — not a fresh deployment guide.

The toolkit includes:

- **Solution Overview** — the full signal path (cert issuance → profile apply → client connect → EAP-TLS → posture/authorization) and the four-layer model behind the tree.
- **Requirements Guide** — the read access, logs, and vantage points to have ready, each with how to verify it.
- **Diagnostic Playbook** — the decision tree by symptom (no cert; cert but no chain; client won't connect; EAP-TLS fails; connected but denied by posture; nobody connects), each branch naming the layer it isolates, the exact checks, and the typical fix.
- **Five PowerShell scripts** — end-to-end collection, certificate + chain validation, compliance/enrollment check (as ISE reads it), VPN client + profile check, and a consolidated cross-layer report. All **read-only**.
- **Testing & Troubleshooting guides** — pass/fail gates mapping each fix back to the tree, plus edge cases and a Cisco escalation evidence checklist. Best-practice triage for repeatable, auditable diagnosis.

## How it isolates the failure fast

The tree is worked **top-down**: prove each layer healthy before descending, so an L1 certificate fault can't masquerade as an L3 authentication failure. Most EAP-TLS and posture symptoms resolve back to a certificate/trust fact or a compliance-connector fact — the tree is built to send you straight there.

## The vendor boundary (by design)

The **Intune, Entra, and certificate side is authored at exact, click-by-click detail** — that's where the scripts and precision live. **Cisco ISE live logs and Secure Client DART collection are deferred to Cisco's official documentation**: the toolkit tells you exactly *what evidence to read* (the EAP-TLS failure reason, the matched authorization rule) and hands you to the vendor doc for the exact console clicks, so you never chase a fabricated menu path.

## The bottom line

The failing layer of a Cisco VPN + ISE + Intune stack, isolated in minutes — a structured playbook and read-only scripts you keep and reuse on every incident, at a fraction of the cost of consulting on each outage.


---


# Solution Overview

## What this toolkit is

This is a **diagnostics toolkit**, not a deployment guide. It assumes you already run — or are supposed to run — certificate-based VPN with a **Cisco Secure Client** connecting through **Cisco Identity Services Engine (ISE)**, where the client certificate is issued and the device is managed by **Microsoft Intune**. Something in that stack has stopped working, and the failure is hiding somewhere across four cooperating layers. This document explains the full signal path and the layered model so the root-cause tree in the **Diagnostic Playbook** (`03-implementation.md`) makes sense.

The core idea: **a VPN + posture failure is almost never "the VPN is broken."** It is one specific layer failing and cascading downstream. If you can name the layer, you can name the fix. The whole toolkit exists to help you name the layer fast.

## The four layers (the layered model)

The stack has four layers. Signal flows top-to-bottom on every connection attempt; a break at any layer looks like a failure at every layer below it.

| Layer | Name | Owner plane | What it does | Primary evidence source |
|-------|------|-------------|--------------|--------------------------|
| L1 | **Certificate / Profile** | Intune / Entra | Issues the client certificate and pushes the VPN + trusted-root profiles to the device | Intune portal, Graph, device certificate store |
| L2 | **Client Connect** | Cisco Secure Client (device) | Reads its profile, presents the certificate, opens the tunnel transport | Secure Client UI + DART logs (Cisco) |
| L3 | **EAP-TLS Chain** | ISE ⇄ device (network) | Mutually authenticates: device proves its cert, trusts the ISE/server cert, chain validates to a common root | ISE live logs (Cisco) + device cert chain |
| L4 | **Posture / Authorization** | Cisco ISE | After authentication succeeds, evaluates compliance/posture and applies an authorization result (permit, quarantine, deny) | ISE live logs (Cisco) + Intune compliance state (Graph) |

**The rule of the layered model:** diagnose **top-down**. A missing certificate (L1) makes L2, L3, and L4 all fail — but only L1 is the real fault. Always confirm the layer above is healthy before blaming the layer below. The root-cause tree enforces exactly this order.

## The full signal path (happy path, end to end)

When everything works, a single successful connection walks through these stages in order:

1. **Cert issuance (L1).** Intune delivers a certificate configuration profile (SCEP or PKCS) to the enrolled device. The device generates a key, requests a certificate, and the issuing CA returns a client authentication certificate into the device's certificate store. A matching **trusted-root / intermediate certificate profile** is also delivered so the device will trust the ISE server certificate later.
2. **Profile apply (L1 → L2).** Intune delivers the **VPN configuration profile** naming the Cisco Secure Client, the head-end/gateway address, and which certificate to use for authentication. The Secure Client on the device reads this profile.
3. **Client connect (L2).** The user (or an always-on rule) triggers the tunnel. Cisco Secure Client resolves the gateway, establishes transport, and begins the authentication handshake, presenting the L1 certificate as its identity.
4. **EAP-TLS (L3).** The device and ISE perform mutual TLS authentication. The **device** presents its client certificate and validates the **ISE server certificate** against the trusted roots from step 1; **ISE** validates the device certificate against its own trusted CA store and any certificate-authentication policy (revocation, template, SAN/CN identity mapping). Both sides must chain to a root each trusts. Success here means "we know who this device is."
5. **Posture / authorization (L4).** Authentication answers *who*; authorization answers *what they're allowed*. ISE evaluates its authorization policy — which can include a **posture/compliance signal**. In an Intune-integrated design, ISE reads the device's **Intune compliance state** (via the Entra/Graph connector) and grants full access only to a *compliant, enrolled* device; a non-compliant or unknown device is quarantined, redirected, or denied.

Only when **all four** succeed does the user get a working, authorized tunnel. The toolkit's job is to tell you **which stage stopped**.

## Where the vendor boundary sits

This toolkit authors the **Intune, Entra, and certificate side (L1, and the Intune-compliance half of L4)** at exact, click-by-click detail — that is where your read-only Graph scripts and portal checks live.

The **Cisco side is deferred to Cisco's official documentation.** Specifically:

- **Cisco Secure Client (AnyConnect) UI, profile editor, and DART log collection (L2)** — we tell you *what* evidence to gather and *what it means*, but exact menu paths belong to Cisco docs and your Secure Client version.
- **Cisco ISE live logs, RADIUS/EAP-TLS detail, certificate-auth policy, posture policy, and authorization results (L3, L4)** — we tell you *what to look for* in the ISE authentication detail (e.g. "EAP-TLS failed on certificate chain validation," "authorization matched the quarantine rule"), but ISE console navigation and posture-module specifics are Cisco's domain.

This boundary is deliberate: Cisco console layouts and ISE versions change, and fabricating menu paths would send you down wrong turns. So the tree always tells you **which ISE/Secure Client screen to open and which field to read**, then hands you to the vendor doc for the exact clicks.

## How to use the rest of this toolkit

- **`02-requirements.md`** — the read access, logs, and vantage points you need before you can diagnose. Confirm these first; a blind diagnosis wastes an incident.
- **`03-implementation.md` (Diagnostic Playbook)** — the root-cause decision tree, entered by **symptom**. This is the core deliverable. Start here during an incident.
- **`05-testing.md`** — pass/fail gates to confirm a fix actually cleared the failing layer (and didn't just move it).
- **`06-troubleshooting.md`** — deeper edge cases and the evidence checklist to hand Cisco if the fault proves to be L2/L3/L4 inside their stack.
- **`07-best-practices.md`** — repeatable triage habits, evidence collection, and clean escalation.
- **The 5 PowerShell scripts** — read-only collectors that snapshot the L1/L4-Intune evidence for you, so you spend the incident reasoning, not gathering.

**Standing constraint for the whole toolkit:** every script and check here is **read-only**. Diagnostics observe; they never remediate. You decide the fix; the toolkit only tells you where it is.


---


# Requirements

Before you can diagnose the Cisco Secure Client + ISE + Intune stack, you need read access to each plane that holds evidence, and the vantage points where each layer's failure shows up. This section lists what to have ready. Each item follows **Description / Why / Verify / Implement if missing**.

Gather these *before* an incident where possible — assembling access mid-incident wastes the outage. Everything here is **read-only**; you never need write/remediation rights to run this toolkit.

> Naming convention used throughout this toolkit (reuse these names verbatim):
> - Entra application registration for compliance reads: **CISEDIAG-Compliance-Reader**
> - Pilot / test device security group in Entra: **CISEDIAG-Pilot-Devices**
> - The certificate the VPN uses for authentication: the **VPN client-authentication certificate**
> - The Intune profiles in scope: the **VPN configuration profile**, the **certificate configuration profile** (SCEP/PKCS), and the **trusted-root certificate profile**

---

## R1. Intune (Microsoft Intune admin center) read access

**Description:** Sign-in to the Microsoft Intune admin center (`https://intune.microsoft.com`) with at least a read-only role that can view devices, configuration profiles, and compliance policies.

**Why:** Layer 1 (certificate/profile) and the Intune half of Layer 4 (compliance) live here. You need to see whether the certificate, trusted-root, and VPN profiles are **assigned** and **applied (succeeded)** on the failing device, and whether the device is **compliant** and **enrolled**.

**Verify:** Browse to `https://intune.microsoft.com` → **Devices → All devices** and open the failing device; confirm you can read its **Configuration** (profile status) and **Compliance** tabs.

**Implement if missing:** In Entra (`https://entra.microsoft.com`) → **Roles & admins**, assign the operator the built-in **Intune Administrator** role, or for least privilege a custom role / the **Global Reader** role, which grants tenant-wide read without change rights. Prefer read-only.

---

## R2. Microsoft Graph read access (for the diagnostic scripts)

**Description:** The ability to run the toolkit's PowerShell scripts against Microsoft Graph with the read-only scopes `DeviceManagementManagedDevices.Read.All`, `DeviceManagementConfiguration.Read.All`, and `Directory.Read.All`.

**Why:** The scripts (`CISEDIAG-Check-Compliance.ps1`, `CISEDIAG-Collect.ps1`) read the same managed-device and profile state ISE would evaluate — compliance, enrollment, ownership, and profile-assignment — so you can compare "what Intune says" against "what the device shows" without clicking through the portal per device.

**Verify:** Run `Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All","DeviceManagementConfiguration.Read.All","Directory.Read.All"` (interactive) and confirm consent succeeds; `Get-MgContext` shows the scopes granted.

**Implement if missing:** Install the Microsoft Graph PowerShell SDK (`Install-Module Microsoft.Graph -Scope CurrentUser`). Consent to the delegated scopes above at first connect, or use the app-only path in R4. All three scopes are **read** scopes — no write consent is required or requested.

---

## R3. Access to the failing device (or its logs)

**Description:** Local (or remote-management) access to the enrolled Windows device that fails to connect — enough to run the device-side scripts and read its certificate store and Secure Client state.

**Why:** Layers 1 and 2 have a device-side truth that the cloud cannot see: whether the **VPN client-authentication certificate** is actually present with a private key and a valid chain, and whether Cisco Secure Client actually has the **VPN configuration profile** it needs. The scripts `CISEDIAG-Validate-Certificate.ps1` and `CISEDIAG-Check-VpnClient.ps1` run **on this device**.

**Verify:** You can open a PowerShell session on the device and run `Get-ChildItem Cert:\CurrentUser\My` (and `Cert:\LocalMachine\My`) and see certificates listed.

**Implement if missing:** Arrange local admin (or standard-user) access, a remote session (RDP / remote PowerShell), or have the end user run the read-only collection script and return the bundle. No changes are made to the device.

---

## R4. An Entra application for compliance reads (app-only, optional but recommended)

**Description:** A dedicated Entra application registration — **CISEDIAG-Compliance-Reader** — with application (app-only) Microsoft Graph permissions `DeviceManagementManagedDevices.Read.All` and `Directory.Read.All`, used for unattended/repeatable compliance reads.

**Why:** For repeatable triage (scheduled collection, or reading compliance for a device you're not signed in on), an app-only identity is cleaner than interactive delegated sign-in and mirrors how ISE itself reads compliance through its own service connection. It keeps the diagnostic reads consistent and auditable.

**Verify:** Entra → **App registrations → CISEDIAG-Compliance-Reader → API permissions**; the two application permissions above show **Granted** (green check). Test: `Connect-MgGraph -ClientId your-app-id -TenantId your-tenant-id -CertificateThumbprint your-cert-thumbprint` connects and `Get-MgContext` reports `AuthType: AppOnly`.

**Implement if missing:** Entra → **App registrations → New registration**, name it **CISEDIAG-Compliance-Reader**. Under **API permissions → Add a permission → Microsoft Graph → Application permissions**, add `DeviceManagementManagedDevices.Read.All` and `Directory.Read.All`, then **Grant admin consent**. Add a **certificate** (preferred) or client secret under **Certificates & secrets**. Record the application (client) ID, tenant ID, and certificate thumbprint for the scripts — never hard-code a secret into a script; pass it at runtime or store it in a secret vault.

---

## R5. Cisco Secure Client vantage point (device side, evidence-only)

**Description:** The ability to view Cisco Secure Client's connection status on the failing device and to collect its **DART** (Diagnostic and Reporting Tool) log bundle.

**Why:** Layer 2 (client connect) failures — profile not loaded, gateway unreachable, transport blocked, certificate-selection failure — surface in the Secure Client UI and DART logs. This is where you confirm the client even *tried* the right head-end with the right certificate.

**Verify:** The Secure Client shows a connection status/message on the failing device, and you can locate its diagnostic/DART tool to produce a log bundle.

**Implement if missing:** Ensure Cisco Secure Client with the DART module is installed on the device. **Exact DART collection steps and log locations are deferred to Cisco's official documentation** and your Secure Client version — this toolkit tells you *what* the log should show; Cisco tells you *how* to collect it.

---

## R6. Cisco ISE live-log vantage point (network side, evidence-only)

**Description:** Read access to the Cisco ISE authentication **live logs** and the detailed authentication report for a connection attempt, held by whoever administers ISE.

**Why:** Layers 3 (EAP-TLS) and 4 (posture/authorization) are only fully visible from ISE. The ISE authentication detail report tells you whether the attempt **reached** ISE, whether **EAP-TLS** passed or failed (and why — chain, revocation, identity mapping), and which **authorization rule** matched (permit vs. quarantine vs. deny). Without this, L3/L4 diagnosis is guesswork.

**Verify:** You (or the ISE administrator on the call) can open the ISE live logs and pull the **detailed authentication report** for a specific failing attempt, matched by username/MAC/timestamp.

**Implement if missing:** Arrange ISE read access, or an agreed hand-off where the ISE administrator pulls the detail report for a timestamp you provide. **Exact ISE console navigation, live-log fields, and posture policy are deferred to Cisco's official documentation** — this toolkit names the field to read (e.g. the EAP-TLS failure reason, the matched authorization rule); Cisco docs cover where it lives in your ISE version.

---

## R7. A known-good reference (baseline)

**Description:** At least one device on which the VPN + ISE posture flow **currently works**, and the expected names/values: the VPN gateway/head-end address, the issuing CA, the trusted-root subject, and the expected **VPN configuration profile** name.

**Why:** Diagnosis is comparison. A working reference device turns "is this certificate right?" into "does this certificate match the working one's issuer and template?" and turns "is the profile correct?" into a diff. It also proves the *service* is up, isolating the fault to the failing device.

**Verify:** Confirm one device connects and is authorized right now; record its certificate issuer/template, its VPN profile name, and the gateway it uses.

**Implement if missing:** Use a pilot device from the **CISEDIAG-Pilot-Devices** group as the known-good reference. If nothing currently works, the fault is likely a shared/service-level break (CA, ISE, connector) rather than a single device — note that and start the tree at the top layer.


---


# Global Requirements — Network (category-level)

These requirements apply to **every** solution in the **Network** category (SASE/SSE, secure web
gateway, Zero Trust network access, and related network-security work — Netskope-centric). They are
published once at the category level so individual listings stay small. Confirm these before deploying
*any* Network solution. Each entry: **Description · Why · Verify · Implement-if-missing.**

> **Vendor note:** these solutions are authored at the correct architectural and procedural level.
> Exact, current **Netskope console** screens, menu paths, and tenant-specific options change over
> time and are **deferred to the official Netskope documentation and your Netskope tenant** — follow
> the named step and confirm the precise control in your console.

## G1. A Netskope tenant
**Description:** An active, licensed Netskope tenant with admin access.
**Why:** It is the control plane for SWG, ZTNA, SSL inspection, and policy.
**Verify:** Sign in to your Netskope tenant admin console as an administrator.
**Implement:** Engage your Netskope account team / reseller to provision a tenant and the required modules.

## G2. Microsoft Entra ID tenant
**Description:** An active Microsoft Entra ID (Azure AD) tenant.
**Why:** Identity is the backbone for SSO, identity-based policy, and user/group steering.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create a Microsoft 365 / Azure subscription, which provisions a tenant.

## G3. Endpoint management (Intune)
**Description:** Microsoft Intune (or an equivalent) able to deploy the client and certificates to endpoints.
**Why:** The Netskope client, root/decryption certificates, and steering config are delivered to managed devices.
**Verify:** `https://intune.microsoft.com` loads and target devices are enrolled and compliant.
**Implement:** Assign an Intune-bearing license plan and enroll the target devices.

## G4. Administrative roles
**Description:** Appropriate admin roles in Netskope, Entra ID, and Intune for the operator.
**Why:** Creating policies, app definitions, and deployments requires elevated rights in each plane.
**Verify:** Confirm an admin role in each console (Netskope admin; Entra/Intune admin).
**Implement:** Assign least-privilege admin roles; reserve Global Administrator for tenant-wide changes.

## G5. Network and identity fundamentals in place
**Description:** Working DNS, routing/egress, and an identity source (Entra ID / Active Directory) for users and groups.
**Why:** Traffic steering, SSL inspection, and identity-based policy depend on resolvable, routable, identified traffic.
**Verify:** Endpoints resolve DNS and reach the internet; users/groups are present in Entra ID.
**Implement:** Remediate DNS/egress; sync Active Directory to Entra ID if hybrid.

## G6. A pilot group
**Description:** A Microsoft Entra security group of pilot users/devices for staged rollout.
**Why:** Every solution is piloted before fleet rollout to validate steering, policy, and performance.
**Verify:** Entra → **Groups**; the pilot group exists.
**Implement:** Entra → **Groups → New group → Security** → add members.

## G7. Change control and a rollback path
**Description:** A change window and a documented rollback (disable steering / remove client / revert policy).
**Why:** Inline proxy, decryption, and ZTNA changes affect live traffic and must be reversible.
**Verify:** A rollback procedure is written and approved before enabling inline enforcement.
**Implement:** Define the rollback (e.g. steering exception, client uninstall, policy disable) and a comms plan.

---
**The standard deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


# Diagnostic Playbook

This is the core deliverable: a **root-cause decision tree entered by symptom**. During an incident, start here. Each branch tells you the **layer it isolates**, the **exact checks to run** (Intune/Graph at click level; Cisco side pointed to vendor evidence), and the **typical fix**.

Work the tree **top-down**. The layered model (`01-solution-overview.md`) guarantees that a break high in the stack fakes failures below it — so always confirm the layer above is healthy before descending. Confirm each fix with the matching gate in `05-testing.md`.

> Names used verbatim (from `02-requirements.md`): **VPN client-authentication certificate**, **VPN configuration profile**, **certificate configuration profile**, **trusted-root certificate profile**, **CISEDIAG-Compliance-Reader**, **CISEDIAG-Pilot-Devices**.

---

## Step 0 — Triage entry (always start here)

Before picking a branch, answer two questions; they cut the tree in half.

1. **Does anyone connect right now?** Test the known-good reference device (R7).
   - **No one connects** → suspect a **shared/service break** (issuing CA down, ISE unreachable, the Entra↔ISE compliance connector broken, an expired ISE server certificate). Skip the per-device branches and go to **Branch F**.
   - **Others connect, this device doesn't** → it is a **device-specific** fault. Continue.
2. **Run the collector once** to snapshot all layers at the device:
   ```
   powershell -ExecutionPolicy Bypass -File .\CISEDIAG-Collect.ps1
   ```
   It writes a bundle (cert state, VPN client/profile state, and — if you connect Graph — compliance/enrollment). Then pick the branch matching the **symptom** below.

**Symptom → branch:**

| Symptom | Branch | Layer it starts at |
|---------|--------|--------------------|
| No VPN certificate on the device at all | **A** | L1 Certificate/Profile |
| Certificate present, but chain/trust is broken | **B** | L1 Certificate/Profile |
| Client won't even try / can't reach the gateway | **C** | L2 Client Connect |
| EAP-TLS authentication fails | **D** | L3 EAP-TLS Chain |
| Authenticates, but is denied / quarantined by posture | **E** | L4 Posture/Authorization |
| No device connects (service-wide) | **F** | Shared/service |

---

## Branch A — No VPN certificate on the device (isolates L1)

**Symptom:** Cisco Secure Client has no certificate to present, or the certificate picker is empty. The **VPN client-authentication certificate** is missing from the device store.

**Checks:**

1. **Device store (device side).** Run:
   ```
   powershell -ExecutionPolicy Bypass -File .\CISEDIAG-Validate-Certificate.ps1
   ```
   Confirm whether any client-authentication certificate from the expected issuer exists in `Cert:\CurrentUser\My` or `Cert:\LocalMachine\My`. If **none**, this is a delivery failure — continue.
2. **Profile assignment (Intune).** In `https://intune.microsoft.com` → **Devices → All devices →** the failing device **→ Configuration**. Find the **certificate configuration profile** (SCEP or PKCS). Read its per-device status.
   - Status **Not applicable** → the device isn't in the profile's assignment scope. Check group membership (is it in the intended group / **CISEDIAG-Pilot-Devices**?).
   - Status **Error / Failed** → open the status detail; note the error (common: SCEP challenge/NDES connectivity, template permissions, key-storage-provider mismatch).
   - Status **Pending** → the device hasn't checked in / applied yet. Confirm the device is **enrolled** and syncing.
3. **Enrollment/compliance (Graph).** Run:
   ```
   powershell -ExecutionPolicy Bypass -File .\CISEDIAG-Check-Compliance.ps1
   ```
   Confirm the device is actually **enrolled and managed**. A device Intune doesn't manage will never receive the certificate.

**Layer isolated:** L1 — certificate delivery from Intune.

**Typical fix:** Correct the assignment (add device to the target group), remediate the SCEP/PKCS profile error (NDES/connector, template ACL, KSP), or fix enrollment. Force a sync and re-run `CISEDIAG-Validate-Certificate.ps1`. Confirm with **Gate A** in `05-testing.md`.

---

## Branch B — Certificate present, but the chain/trust is broken (isolates L1)

**Symptom:** A certificate exists, but it won't be accepted — wrong issuer, missing intermediate, expired, revoked, no private key, or the device doesn't trust the **ISE server certificate**.

**Checks:**

1. **Full chain (device side).** Run:
   ```
   powershell -ExecutionPolicy Bypass -File .\CISEDIAG-Validate-Certificate.ps1
   ```
   It reports, for each candidate certificate: **has private key**, **not expired**, **Client Authentication EKU present**, **chains to a trusted root**, and any **chain error status**. Look for:
   - **No private key** → the cert was imported without its key (PKCS export issue) or the SCEP key generation failed.
   - **Chain incomplete / untrusted root** → the issuing CA's **intermediate/root** isn't in the device's trusted stores. This is delivered by the **trusted-root certificate profile**.
   - **Expired / not-yet-valid** → clock or renewal problem.
2. **Trusted-root profile (Intune).** In Intune → the failing device → **Configuration**, confirm the **trusted-root certificate profile** shows **Succeeded**. If it's missing/failed, the device can't validate the ISE server cert (this later shows as an L3 EAP-TLS failure — but the root cause is here at L1).
3. **Issuer match to reference (R7).** Compare the certificate's **issuer** and **template** to the known-good reference device. A mismatch means the wrong CA/template issued it.
4. **Revocation.** The script flags a revoked status if reachable. If CRL/OCSP is unreachable from the device, note it — ISE may still reject on revocation-check failure at L3.

**Layer isolated:** L1 — certificate validity and trust chain on the device.

**Typical fix:** Deploy/repair the **trusted-root certificate profile**; reissue the certificate from the correct template with an exportable-key/SCEP config that produces a private key; fix time sync; resolve CRL/OCSP reachability. Re-run the validator. Confirm with **Gate B**.

---

## Branch C — Client won't try, or can't reach the gateway (isolates L2)

**Symptom:** Cisco Secure Client shows no profile, the wrong head-end, "unable to contact," or never launches the authentication handshake. The certificate (L1) checked out in Branch A/B.

**Checks:**

1. **VPN profile on the device (device side).** Run:
   ```
   powershell -ExecutionPolicy Bypass -File .\CISEDIAG-Check-VpnClient.ps1
   ```
   It reports: is a **Cisco Secure Client / VPN service** present and running, is there a **VPN configuration profile** on the device, and what **gateway/head-end** and connection state it reports. Look for a **missing profile** or the **wrong gateway**.
2. **VPN profile delivery (Intune).** In Intune → the failing device → **Configuration**, find the **VPN configuration profile** and confirm **Succeeded**. If it's **Error/Not applicable**, the client is running on stale/absent config — fix the assignment, exactly as in Branch A step 2.
3. **Client presence & reachability (device side + Cisco).** Confirm Secure Client is installed and can resolve/reach the gateway address (name resolution + basic reachability from the device). If the client launches but reports a transport/connection error to the head-end, that is a **network path** problem (DNS, firewall, egress), not Intune.
4. **Cisco Secure Client evidence (vendor-deferred).** Open the Secure Client status and, if needed, collect the **DART** bundle (R5). Read whether the client **loaded the expected profile** and **which certificate it selected**. **Exact DART collection and the profile-editor menus are deferred to Cisco's official documentation** — this toolkit only tells you the log should show the right profile name and a certificate being presented.

**Layer isolated:** L2 — client configuration and transport to the head-end.

**Typical fix:** Repair the **VPN configuration profile** assignment/delivery in Intune; correct the gateway address; resolve DNS/egress/firewall to the head-end; reinstall/repair Secure Client. For client-internal faults, escalate to Cisco with the DART bundle (see `06-troubleshooting.md`). Confirm with **Gate C**.

---

## Branch D — EAP-TLS authentication fails (isolates L3)

**Symptom:** The client reaches ISE and tries to authenticate, but authentication **fails** — the tunnel drops at login. L1 (Branch A/B) and L2 (Branch C) already checked out clean.

**Checks:**

1. **Confirm the attempt reached ISE (vendor evidence).** In the ISE authentication **live logs**, locate the failing attempt by username/MAC/timestamp. If **no event appears**, the request never arrived — drop back to **Branch C** (transport) or a network/RADIUS path issue. If an event **does** appear with an EAP-TLS failure, continue.
2. **Read the EAP-TLS failure reason (vendor evidence).** Open the **detailed authentication report** for that attempt and read the failure reason. **Exact ISE navigation is deferred to Cisco docs**, but the reason typically points squarely back to an L1 fact:
   - *"Certificate chain validation failed" / "unable to build chain"* → an **intermediate/root** ISE needs isn't trusted, or the device cert's chain is incomplete → return to **Branch B** (trusted-root profile) and confirm ISE's CA trust store on the Cisco side.
   - *"Revocation check failed" / "certificate revoked"* → CRL/OCSP problem or a genuinely revoked cert → **Branch B** step 4.
   - *"Unknown CA" / device cert issuer not trusted by ISE* → ISE isn't configured to trust your issuing CA (Cisco-side trust store) → escalate to ISE admin with the issuer name.
   - *"Identity not found" / subject-to-identity mapping failed* → the cert's SAN/CN doesn't map to a known identity in ISE's certificate-authentication profile → confirm the **template's subject/SAN** matches what ISE expects (compare to R7 reference).
3. **Device-side corroboration.** Re-run `CISEDIAG-Validate-Certificate.ps1` and confirm the chain the device builds matches what ISE expects (same root, complete intermediates, valid dates, private key present).

**Layer isolated:** L3 — mutual certificate authentication between device and ISE.

**Typical fix:** Almost always a chain/trust correction that lives at L1 (deploy the right **trusted-root certificate profile**, reissue from the right template with the right SAN/CN) **or** an ISE-side trust/identity-mapping correction (Cisco). Fix, reconnect, and read the ISE log again. Confirm with **Gate D**.

---

## Branch E — Authenticates, but is denied or quarantined by posture (isolates L4)

**Symptom:** Authentication **succeeds** (Branch D is clean) but the user gets **no access, limited access, a quarantine/redirect, or a remediation page.** ISE authorized the session to a restricted result.

**Checks:**

1. **Read the matched authorization result (vendor evidence).** In the ISE detailed authentication report, read **which authorization rule/profile matched** — e.g. a "compliant → permit" rule vs. a "non-compliant/unknown → quarantine" rule. **Exact ISE posture navigation is deferred to Cisco docs**; you only need which result matched and on what condition (typically the compliance/posture signal).
2. **Read Intune's compliance verdict (Graph — this is your side).** Run:
   ```
   powershell -ExecutionPolicy Bypass -File .\CISEDIAG-Check-Compliance.ps1
   ```
   It reports the device's **compliance state**, **enrollment state**, **ownership**, and **management** as Intune holds them — i.e. the exact signal ISE reads through the Entra↔ISE connector. Compare:
   - **Intune says Compliant, ISE quarantined it** → the **compliance signal isn't reaching ISE**: the Entra↔ISE compliance connector is broken, or ISE is matching on a stale/absent value → **Branch F** connector checks, and confirm on the Cisco side that ISE received a compliance status.
   - **Intune says Non-compliant** → posture is working correctly; the device genuinely fails a compliance policy. Read *which* compliance policy failed in Intune (**Devices → the device → Compliance**) and remediate the policy setting (encryption, OS version, defender, etc.).
   - **Intune says Not enrolled / Unknown** → ISE can't get a compliant verdict for a device it doesn't see as managed → return to enrollment (**Branch A** step 3).
3. **Identity match.** Confirm the device object ISE is asking Entra about is the **same** object that's compliant in Intune (device ID / Entra device match). A mismatched or duplicate device record makes a compliant device look unknown to ISE.

**Layer isolated:** L4 — posture/authorization, split between the Intune compliance verdict (your side) and the ISE authorization policy + connector (Cisco side).

**Typical fix:** If genuinely non-compliant, remediate the failing Intune compliance policy on the device. If Intune says compliant but ISE disagrees, repair the **Entra↔ISE compliance connector** (Branch F) and the device-identity match. Confirm with **Gate E**.

---

## Branch F — No device connects (isolates a shared/service break)

**Symptom:** From Step 0, **nobody** connects — not the known-good reference. The fault is shared, not per-device.

**Checks (top-down, mostly vendor-side evidence):**

1. **Certificate issuance service.** Are *new* certificates being issued at all? A new pilot device from **CISEDIAG-Pilot-Devices** that gets no cert points at the issuing CA / SCEP (NDES) / connector. Check the **certificate configuration profile** status across several devices in Intune — a fleet-wide **Error** implies the issuing pipeline, not the device.
2. **ISE reachability & server certificate (vendor evidence).** With the ISE admin, confirm ISE is up and its **server certificate is valid (not expired)**. An expired ISE server certificate breaks EAP-TLS for **everyone** at L3 simultaneously — a classic fleet-wide outage. **Exact ISE checks are deferred to Cisco docs.**
3. **Entra↔ISE compliance connector.** If everyone authenticates but everyone is quarantined, the **compliance connector** between Entra and ISE is likely down — ISE sees every device as unknown/non-compliant. Confirm the connector/service health on both sides. Run `CISEDIAG-Check-Compliance.ps1` against several devices: if Intune reports them **compliant** but all are quarantined, the break is the connector, not compliance.
4. **Network/RADIUS path.** If no authentication events reach ISE at all, suspect the network/RADIUS path or the head-end itself (Cisco side).

**Layer isolated:** shared service — issuing CA, ISE availability/server cert, or the Entra↔ISE connector.

**Typical fix:** Restore the affected shared service (renew the ISE server certificate, repair NDES/connector, restore the compliance connector). Because these are outward-facing production services, coordinate change control before touching them. Confirm the reference device recovers, then re-run the per-device branches for any stragglers. Confirm with **Gate F**.

---

## Fast reference — the tree at a glance

```
Step 0: Does anyone connect?
  ├─ No one  ───────────────────────────────────► Branch F (shared/service)
  └─ Only this device fails → run Collect → symptom:
        No cert at all ............................ Branch A  (L1)
        Cert present, chain/trust broken ......... Branch B  (L1)
        Client won't try / no gateway ............ Branch C  (L2)
        EAP-TLS fails ............................ Branch D  (L3)  ── usually loops back to B
        Authenticated but quarantined ............ Branch E  (L4)  ── splits Intune vs. connector
```

Every descent obeys the rule: **prove the layer above is healthy first.** Most L3/L4 failures resolve to an L1 certificate/trust fact or an L4 connector fact — the tree is built to send you back there instead of chasing symptoms.


---


# Testing — Confirming the Fix

A fix is only real when the layer it targeted passes its gate **and** the layers below it come back healthy. Each gate below maps one-to-one to a branch in the Diagnostic Playbook (`03-implementation.md`). Run the gate for the branch you worked; if it passes, walk the remaining layers down to a live, authorized connection.

All confirmation checks here are **read-only** — you observe recovery, you don't force it. Use `CISEDIAG-Report.ps1` at the end to produce a single consolidated pass/fail view across all layers.

> Reuse names verbatim: **VPN client-authentication certificate**, **VPN configuration profile**, **certificate configuration profile**, **trusted-root certificate profile**, **CISEDIAG-Pilot-Devices**.

---

## Gate A — Certificate now present (L1)

**Confirms:** Branch A fix (certificate delivery).

**Pass when:**
- `CISEDIAG-Validate-Certificate.ps1` lists a **VPN client-authentication certificate** from the expected issuer in the device store, **with a private key**.
- In Intune → the device → **Configuration**, the **certificate configuration profile** shows **Succeeded**.

**Fail when:** still no certificate, or profile status is Error/Not applicable/Pending → return to Branch A.

---

## Gate B — Chain and trust valid (L1)

**Confirms:** Branch B fix (chain/trust).

**Pass when:**
- `CISEDIAG-Validate-Certificate.ps1` reports, for the VPN certificate: **not expired**, **Client Authentication EKU present**, **chains to a trusted root**, **no chain error**, **not revoked** (or revocation reachable and good).
- The **trusted-root certificate profile** shows **Succeeded** in Intune.
- Issuer/template match the known-good reference (R7).

**Fail when:** any chain error, missing private key, untrusted root, or expiry remains → return to Branch B.

---

## Gate C — Client configured and reaching the head-end (L2)

**Confirms:** Branch C fix (client/profile/transport).

**Pass when:**
- `CISEDIAG-Check-VpnClient.ps1` shows the **Cisco Secure Client/VPN service present**, the **VPN configuration profile** present, and the **correct gateway/head-end**.
- The **VPN configuration profile** shows **Succeeded** in Intune.
- The client can resolve and reach the gateway, and (Cisco-side evidence) the Secure Client loads the expected profile and presents a certificate.

**Fail when:** wrong/absent profile, wrong gateway, or the client cannot reach the head-end → return to Branch C (or escalate to Cisco with a DART bundle).

---

## Gate D — EAP-TLS authenticates (L3)

**Confirms:** Branch D fix (mutual authentication).

**Pass when (vendor evidence):**
- In the ISE authentication live log, the attempt now shows **authentication success** (EAP-TLS passed) for the device.
- No chain/revocation/unknown-CA/identity-mapping failure reason remains in the detailed report.
- `CISEDIAG-Validate-Certificate.ps1` still confirms a clean chain device-side.

**Fail when:** ISE still logs an EAP-TLS failure → read the reason and loop back (usually Branch B for chain/trust, or ISE-side trust on the Cisco side).

---

## Gate E — Authorized by posture (L4)

**Confirms:** Branch E fix (posture/authorization).

**Pass when:**
- `CISEDIAG-Check-Compliance.ps1` reports the device **Compliant**, **Enrolled/Managed**, with the expected ownership.
- In the ISE detailed report (vendor evidence), the session now matches the **permit/compliant** authorization rule — not quarantine/redirect.
- The user gets the intended full access on the tunnel.

**Fail when:** Intune says compliant but ISE still quarantines → connector/identity-match problem (Branch F / Branch E step 3). Intune says non-compliant → the genuine compliance policy still fails; remediate it and re-test.

---

## Gate F — Service restored (shared)

**Confirms:** Branch F fix (shared/service break).

**Pass when:**
- The **known-good reference device (R7)** connects and is authorized again.
- Fleet-wide **certificate configuration profile** status is no longer erroring across devices.
- (Vendor evidence) ISE is up with a **valid, unexpired server certificate**; the Entra↔ISE compliance connector reports healthy.
- `CISEDIAG-Check-Compliance.ps1` against several devices shows compliant devices being authorized (not universally quarantined).

**Fail when:** the reference device still fails → the shared service isn't fully restored; keep working Branch F.

---

## End-to-end confirmation (all layers)

After any single-layer gate passes, prove the **whole path** end to end on the device:

1. Run the consolidated report:
   ```
   powershell -ExecutionPolicy Bypass -File .\CISEDIAG-Report.ps1
   ```
   Expect **PASS** on: certificate present + valid chain (L1), VPN client/profile correct (L2), compliance/enrollment good (L4-Intune).
2. **Connect the tunnel** and confirm the user reaches intended resources.
3. **Read the ISE live log** for that fresh attempt (vendor evidence): authentication **success** (L3) and a **permit** authorization result (L4).

A fix is **done** only when the report is green, the tunnel is up, and ISE shows success + permit for that exact connection — not before.


---


# Troubleshooting — Edge Cases and Escalation to Cisco

The Diagnostic Playbook (`03-implementation.md`) resolves the common failures. This section covers the **edge cases** that don't fall cleanly onto a branch, and the **evidence checklist** to hand Cisco when the fault proves to live inside Cisco Secure Client or ISE. Everything here stays **read-only**.

> Reuse names verbatim: **VPN client-authentication certificate**, **VPN configuration profile**, **certificate configuration profile**, **trusted-root certificate profile**, **CISEDIAG-Compliance-Reader**, **CISEDIAG-Pilot-Devices**.

## Edge cases

### 1. Two certificates, wrong one selected
The device has more than one client-authentication certificate (e.g. an old and a renewed one, or a user and a device cert). Secure Client presents the wrong one, and ISE rejects it at L3. `CISEDIAG-Validate-Certificate.ps1` will list **multiple PASS certs** — that's the tell. Compare issuer/template/validity to the R7 reference to identify the intended cert. The selection rule (which cert Secure Client presents) is Cisco-side profile logic — deferred to Cisco docs — but the presence of a stale duplicate is your L1 evidence.

### 2. Certificate valid on the device but revoked/unknown at ISE
`CISEDIAG-Validate-Certificate.ps1` shows a clean chain locally, yet ISE logs *"revocation check failed"* or *"unknown CA."* Two distinct causes: (a) **CRL/OCSP reachable from the device but not from ISE**, or vice-versa — revocation is checked at *both* ends; (b) ISE's own **CA trust store** doesn't include your issuing CA. Both are resolved on the ISE/network side; your evidence is the local clean chain plus the issuer name to give the ISE admin.

### 3. Clock skew
A device whose clock is off makes an in-date certificate appear **not-yet-valid** or **expired**, and breaks TLS. The validator flags `NotYetValid`/`Expired`; if the cert dates look fine but validation still fails on time, check device time sync. This masquerades as an L1 cert fault and an L3 EAP-TLS fault simultaneously.

### 4. Compliant device, still quarantined (grace / staleness)
Intune reports **compliant** (confirmed by `CISEDIAG-Check-Compliance.ps1`) but ISE quarantines. Beyond a broken connector (Branch F), the compliance signal ISE holds can be **stale** — the device just became compliant and ISE hasn't received the update, or a compliance **grace period** is in play. Check `LastSyncDateTime` in the compliance output; a device that hasn't synced recently may be compliant locally but not yet reflected to ISE. Force a device check-in (user-initiated, not a script action) and re-read.

### 5. Duplicate / mismatched device identity
A device re-enrolled or re-imaged can leave a **duplicate object**; ISE may query Entra for a device ID that maps to the stale, non-compliant record. `CISEDIAG-Check-Compliance.ps1` returning **more than one device** for the name is the tell. Confirm the `AzureAdDeviceId` ISE is asking about matches the *compliant* record.

### 6. Always-on / trusted-network detection
If Secure Client is configured always-on or with trusted-network detection, it may **decline to connect** on a network it considers "trusted," which looks like an L2 failure but is expected behavior. This is Cisco-side profile logic (deferred to Cisco docs); rule it out before deep-diving L2.

### 7. Per-user vs. per-device certificate/profile scope
A **certificate configuration profile** or **VPN configuration profile** assigned to a *user* group won't apply when the failing context is the *device* (or vice-versa). In Intune, confirm the profile's **assignment target** matches how the device is used (user-affinity vs. shared device). Status **Not applicable** with correct group membership often means a scope/target mismatch.

### 8. NDES / SCEP connector intermittent
Fleet-wide but *intermittent* certificate failures (some devices get a cert, some error) point at an overloaded or flapping SCEP/NDES connector rather than a single-device fault. Check the **certificate configuration profile** status across several devices in Intune; a scattered mix of Succeeded/Error implies the issuing pipeline. This is Branch F territory even though not everyone fails.

## Escalation to Cisco — evidence checklist

When L2 (Secure Client) or L3/L4 (ISE) internals are the fault, escalate **once, complete**. Cisco console navigation and DART/live-log specifics are **deferred to Cisco's official documentation**; your job is to hand over a package that proves your side is clean and pinpoints the Cisco-side symptom. Include:

- [ ] **`CISEDIAG-Report.ps1` output** — proves L1, L2, and L4-Intune are healthy on your side (or names exactly what isn't).
- [ ] **`CISEDIAG-Validate-Certificate.ps1` output** — the device certificate chain, **issuer, template, EKU, validity, private-key presence, revocation status**.
- [ ] **`CISEDIAG-Check-VpnClient.ps1` output** — the **VPN configuration profile** present on the device and the **gateway** it names.
- [ ] **`CISEDIAG-Check-Compliance.ps1` output** — the Intune **compliance/enrollment** verdict ISE should be reading, with `AzureAdDeviceId` and `LastSyncDateTime`.
- [ ] **Cisco Secure Client DART bundle** — collected per Cisco docs (L2 evidence: profile loaded, certificate selected, transport result).
- [ ] **ISE detailed authentication report** — for the **exact failing attempt** (timestamp / username / MAC), with the **EAP-TLS failure reason** or **matched authorization rule** highlighted.
- [ ] **Known-good reference facts (R7)** — the working device's issuer/template/gateway, so Cisco can diff working vs. failing.
- [ ] **A one-line statement of the isolated layer** — e.g. "L1/L2/L4-Intune confirmed healthy; ISE logs EAP-TLS 'unknown CA' for issuer *your-issuing-ca-name* — requesting ISE CA trust-store review."

A package like this turns a multi-round Cisco case into a single decisive one — the whole point of isolating the layer before you escalate.

## When to stop diagnosing and change something

Diagnosis is read-only by design, but the *fix* changes state. Escalate to a change window (and the owning admin) before:
- Touching any **shared/outward-facing** service (issuing CA, ISE server certificate, the Entra↔ISE connector, RADIUS/network path) — these affect every user at once.
- Reissuing or revoking certificates fleet-wide.
- Modifying a **VPN configuration profile** or **compliance policy** that's assigned broadly.

Confirm any change with the matching gate in `05-testing.md`, then re-run `CISEDIAG-Report.ps1` to prove the layer cleared without opening a new one.


---


# Best Practices — Repeatable Triage, Evidence, and Escalation

The Diagnostic Playbook isolates a failing layer in one incident. These practices make that repeatable across incidents and across the team, so every triage is faster and cleaner than the last. Everything here stays **read-only** and vendor-boundary-aware.

> Reuse names verbatim: **VPN client-authentication certificate**, **VPN configuration profile**, **certificate configuration profile**, **trusted-root certificate profile**, **CISEDIAG-Compliance-Reader**, **CISEDIAG-Pilot-Devices**.

## 1. Triage in a fixed order — top-down, every time

- Always start at **Step 0** (does anyone connect?) before touching a device. It's the single biggest time-saver: it splits shared-service breaks from per-device faults in one check.
- Descend the layers **L1 → L2 → L3 → L4**, never skipping. A confirmed-healthy layer above is a fact you can bank; guessing at L3 while L1 is unverified wastes the incident.
- Treat **L3/L4 symptoms as pointers, not causes.** EAP-TLS failures almost always resolve to an L1 chain/trust fact; posture quarantines resolve to an L4 compliance or connector fact. Let the tree send you back.

## 2. Keep a known-good baseline current

- Maintain at least one working reference device (R7), ideally from **CISEDIAG-Pilot-Devices**, and record its **issuer, template, VPN profile name, and gateway**. Diagnosis is comparison; a baseline turns open questions into diffs.
- Refresh the baseline whenever the CA, ISE server certificate, trusted roots, or VPN profile change. A stale baseline lies.

## 3. Collect evidence first, reason second

- Run `CISEDIAG-Collect.ps1` **once, early** — snapshot the whole device state before you start changing anything, so you have a before/after and don't lose the failing state.
- Prefer the scripts over click-by-click portal checks for anything you'll do more than once: they're consistent, timestamped, and produce a bundle you can attach to the ticket.
- Snapshot **all layers** even when you think you know the branch. The consolidated `CISEDIAG-Report.ps1` frequently reveals a second, quieter fault (e.g. a trusted-root profile that's also failing) that would have caused a repeat incident.

## 4. Read-only discipline

- Diagnostics **observe; they never remediate.** No script here changes device, tenant, or ISE state. This keeps triage safe to run in production, on a user's device, mid-incident, without a change window.
- When you *do* remediate, do it in the owning plane (Intune profile fix, compliance-policy fix, or a Cisco-side change by the ISE admin) — deliberately, under change control for anything shared or outward-facing.

## 5. Respect the vendor boundary

- For **Cisco Secure Client (L2)** and **Cisco ISE (L3/L4)** internals, gather the **evidence the tree names** (the EAP-TLS failure reason, the matched authorization rule, the DART bundle) and read it — but follow **Cisco's official documentation** for exact console navigation and posture-module specifics. Don't invent menu paths; ISE versions differ.
- Author every check on the **Intune/Entra/certificate side** at exact click level — that's where your leverage and precision are.

## 6. Least-privilege, auditable access

- Use **read-only** roles (Global Reader / a custom read role) for portal work, and **read scopes only** for Graph. The toolkit never needs write access.
- For repeatable/unattended reads, use the dedicated **CISEDIAG-Compliance-Reader** app with a **certificate** credential (not a secret in a script). Never hard-code credentials; pass IDs/thumbprints at runtime or from a vault.

## 7. Escalate to Cisco with a complete evidence package

When the fault proves to live inside Cisco Secure Client or ISE, escalate **once, with everything** — don't hand over a symptom. Attach:

- The consolidated `CISEDIAG-Report.ps1` output (proves L1/L2/L4-Intune are healthy on your side).
- The `CISEDIAG-Validate-Certificate.ps1` output (device cert chain, issuer, template, EKU, validity).
- The **Cisco Secure Client DART** bundle (L2 evidence), collected per Cisco docs.
- The **ISE detailed authentication report** for the exact failing attempt (timestamp/username/MAC), with the EAP-TLS failure reason or matched authorization rule highlighted.
- Your known-good reference facts (issuer/template/gateway) so Cisco can compare working vs. failing.

The full escalation checklist lives in `06-troubleshooting.md`. A complete package turns a multi-round Cisco case into a single, decisive one.

## 8. Close the loop

- After every incident, confirm with the matching **gate in `05-testing.md`** and the end-to-end check — a fix isn't done until the report is green and ISE shows success + permit.
- Record the **root-cause layer** on the ticket (L1/L2/L3/L4/shared). Patterns emerge: repeated L1 chain failures mean the trusted-root profile needs attention; repeated L4 quarantines mean the connector needs monitoring. Fix the pattern, not just the incident.


---


# Deliverables Summary

Everything included in the **Cisco ISE VPN + Intune Troubleshooting & Diagnostics Toolkit**, and how each piece is used. This is a diagnostics product: a reusable, self-guided playbook plus read-only scripts you keep and run on every incident.

## Documentation

| Document | What it gives you | When you use it |
|----------|-------------------|-----------------|
| **Solution Overview** (`01-solution-overview.md`) | The full Cisco-ISE-VPN + Intune signal path and the four-layer model behind the root-cause tree | Read once to understand the stack; refer back when a branch mentions a layer |
| **Requirements** (`02-requirements.md`) | The read access, logs, and vantage points to diagnose, each with Description / Why / Verify / Implement-if-missing | Before an incident — assemble access so you're not gathering it mid-outage |
| **Diagnostic Playbook** (`03-implementation.md`) | The root-cause decision tree by symptom; each branch names the layer it isolates, the exact checks, and the typical fix | The core deliverable — start here during an incident |
| **Testing** (`05-testing.md`) | Pass/fail gates mapping one-to-one to the tree's branches, plus an end-to-end confirmation | After a fix — prove the layer cleared and the whole path is healthy |
| **Troubleshooting** (`06-troubleshooting.md`) | Deeper edge cases and the Cisco escalation evidence checklist | When a branch doesn't resolve cleanly, or the fault is inside Cisco's stack |
| **Best Practices** (`07-best-practices.md`) | Repeatable triage order, evidence collection, least-privilege access, clean escalation, closing the loop | To standardize triage across the team and across incidents |
| **Executive Summary** (`executive-summary.md`) | The problem, what's inside, and the value, for a decision-maker | To brief a stakeholder or justify the toolkit |
| **Global Requirements — Network** (`global-requirements-network.md`) | Category-level prerequisites shared by all Network solutions | Confirm alongside the solution-specific requirements |

## PowerShell scripts (all read-only)

| Script | What it does | Layer(s) it covers |
|--------|--------------|--------------------|
| **CISEDIAG-Collect.ps1** | End-to-end diagnostic collection — device certificate/VPN state plus Intune/Graph compliance state — written to a timestamped bundle | L1, L2, L4 (Intune side) |
| **CISEDIAG-Validate-Certificate.ps1** | Validates the VPN client-authentication certificate and its full chain on *this* device (private key, EKU, expiry, chain, revocation) | L1 |
| **CISEDIAG-Check-Compliance.ps1** | Reads the device's compliance/enrollment state via Graph — the same signal ISE reads through the Entra↔ISE connector | L4 (Intune side) |
| **CISEDIAG-Check-VpnClient.ps1** | Checks the Cisco Secure Client / VPN client and profile state on *this* device (service present, profile present, gateway, connection state) | L2 |
| **CISEDIAG-Report.ps1** | Consolidates the other checks into a single cross-layer pass/fail diagnostics report | L1, L2, L4 (Intune side) |

Every script begins with a standard PURPOSE / HOW TO RUN / EXPECTED RESULTS header and requires only **read** access (read-only Graph scopes on the Intune side). None change device, tenant, or ISE state.

## What is intentionally deferred to Cisco

Cisco ISE live-log navigation, EAP-TLS/RADIUS console detail, posture/authorization policy internals, and Cisco Secure Client (AnyConnect) UI / profile-editor / DART collection steps are **deferred to Cisco's official documentation**. The toolkit names the exact evidence to read on the Cisco side (the EAP-TLS failure reason, the matched authorization rule, the DART bundle) and provides the escalation checklist to hand Cisco a complete package — but does not fabricate Cisco menu paths.

## How the pieces fit together

1. **Prepare** with `02-requirements.md`.
2. **Diagnose** with `03-implementation.md`, using the scripts to snapshot evidence.
3. **Confirm** with `05-testing.md`.
4. **Escalate or refine** with `06-troubleshooting.md`.
5. **Standardize** with `07-best-practices.md`.
