# 2. Requirements Guide — Microsoft Defender XDR Deployment & Unified Onboarding

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify · Implement-if-missing.** Category-wide prerequisites (tenant, licensing, admin roles, onboarding reach, network access, pilot ring, workspace, response governance) are in `global-requirements-defender.md` — do not repeat them; the items below are **specific to onboarding the four XDR pillars into the unified portal**. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

## 2.1 Unified Defender portal reachable and initialized
**Description:** Access to `https://security.microsoft.com` with the unified portal experience available for the tenant.
**Why:** Every pillar is activated, correlated, and governed from this single portal; onboarding starts here.
**Verify:** Sign in to `security.microsoft.com` as a Security Administrator and confirm **Incidents**, **Assets**, **Settings**, and **System → Permissions and roles** load. Run `DEFXDR-Discovery.ps1`.
**Implement-if-missing:** Confirm the tenant is provisioned and the required admin role is assigned; the portal initializes on first admin sign-in.

## 2.2 Endpoint onboarding channel (Intune / GPO / script)
**Description:** A working management channel to onboard devices to Defender for Endpoint — Intune (or Configuration Manager), Group Policy, or the local onboarding script — targeting a **pilot ring** first.
**Why:** MDE collects EDR signal only from onboarded devices; the channel must reach the pilot devices before any expansion.
**Verify:** Intune enrolled devices exist (or GPO reaches the pilot OU); `DEFXDR-Discovery.ps1` reports onboarding coverage.
**Implement-if-missing:** Establish the onboarding channel (see the adjacent Intune *Defender for Endpoint Integration* solution) and create the pilot device group `MDE Onboarding – Pilot Ring – Pilot`.

## 2.3 Domain controllers reachable for Defender for Identity sensors
**Description:** Domain controllers (and AD FS / AD CS servers where present) that can host the **Defender for Identity sensor**, with outbound reach to the MDI service and a change window to install.
**Why:** MDI detects on-prem identity attacks from sensors installed directly on these servers; there is no agentless option for AD.
**Verify:** Confirm DC OS version support, resources, and network reach to the MDI service URLs; `DEFXDR-Discovery.ps1` lists candidate DCs and sensor status. *Verify current sensor OS support and endpoint list.*
**Implement-if-missing:** Schedule a change window, confirm sensor prerequisites, and plan the sensor install per DC (Step 3 of the Implementation Guide).

## 2.4 Directory Service account for MDI (where required)
**Description:** A read-only **Directory Service Account (DSA)** for Defender for Identity, per current MDI guidance (gMSA recommended).
**Why:** The sensor uses the DSA to query AD for additional context; without it, some detections are limited.
**Verify:** Confirm a gMSA (or standard read-only account) is created and configured in MDI settings; `DEFXDR-Discovery.ps1` notes DSA configuration. *Verify current MDI DSA requirements.*
**Implement-if-missing:** Create the gMSA and register it under **Settings → Identities → Directory Service accounts** in the portal.

## 2.5 Exchange Online / collaboration workloads for MDO
**Description:** Exchange Online mail flow (and Teams/SharePoint/OneDrive where MDO covers collaboration) in the tenant.
**Why:** Defender for Office 365 policies (Safe Links, Safe Attachments, anti-phishing) apply to these workloads; without them there is nothing to protect.
**Verify:** `security.microsoft.com` → **Email & collaboration → Policies & rules**; confirm the tenant routes mail through Exchange Online.
**Implement-if-missing:** Confirm Exchange Online is the mail path and the MDO plan (P1/P2) is licensed. *Verify current MDO plan features in your tenant.*

## 2.6 Cloud Apps activation and (optional) app connectors for MDCA
**Description:** Defender for Cloud Apps enabled, with the automatic **Defender for Endpoint integration** for discovery and any **app connectors** for the SaaS apps you intend to govern.
**Why:** MDCA discovers and controls cloud-app usage; connectors and the MDE integration are what feed it signal.
**Verify:** `security.microsoft.com` → **Cloud apps → Cloud discovery / App connectors**; `DEFXDR-Discovery.ps1` reports MDCA status.
**Implement-if-missing:** Turn on Cloud Apps, enable the MDE-to-MDCA discovery integration, and add connectors for priority SaaS apps (monitor-first).

## 2.7 Pilot ring defined (devices, users, sensors)
**Description:** A named pilot ring: pilot **devices** (`MDE Onboarding – Pilot Ring – Pilot`), pilot **users** (`XDR Pilot Users – Pilot Ring – Pilot`), and the first **domain controller(s)** to carry a sensor.
**Why:** XDR onboarding and any automated response are validated on a ring before tenant-wide rollout (per `global-requirements-defender.md` G6).
**Verify:** The groups exist in Entra/Intune and the pilot DC is chosen; `DEFXDR-Validate.ps1` checks membership.
**Implement-if-missing:** Create the two groups and select the pilot DC before onboarding anything that acts automatically.

## 2.8 Unified RBAC role decision
**Description:** A decision to adopt the Defender portal's **unified role-based access control** and the roles to grant (reader / operator / admin) across all pillars.
**Why:** Unified RBAC replaces four separate per-pillar permission systems with one; the role model must be agreed before granting access.
**Verify:** `security.microsoft.com` → **System → Permissions and roles**; confirm unified RBAC is available and note current per-pillar permissions. *Verify current unified RBAC activation steps in your tenant.*
**Implement-if-missing:** Plan the role assignments `XDR Security Reader – Tenant – Prod` and `XDR Security Operator – Tenant – Prod` (Step 6).

## 2.9 Response governance position
**Description:** An agreed position on **automated investigation and response (AIR)** — approval-required vs automatic remediation levels — kept approval-gated during the pilot.
**Why:** AIR can take disruptive actions (isolate device, delete mail, disable user); the organization must decide the guardrails (per `global-requirements-defender.md` G8).
**Verify:** A documented response policy exists; automation is in an approval/simulate posture. `DEFXDR-Validate.ps1` reports the current AIR automation level.
**Implement-if-missing:** Keep AIR approval-gated at first; *incident-response and automation guardrail decisions are the SOC/security team's — this guide covers the technical configuration.*

---
## Checklist
- [ ] Unified Defender portal reachable and initialized — `DEFXDR-Discovery.ps1`
- [ ] Endpoint onboarding channel (Intune/GPO/script) + pilot device group
- [ ] Domain controllers reachable for MDI sensors + change window
- [ ] MDI Directory Service Account (gMSA) prepared
- [ ] Exchange Online / collaboration workloads present for MDO
- [ ] Cloud Apps enabled + MDE discovery integration / connectors
- [ ] Pilot ring defined (devices, users, sensor DC) — `DEFXDR-Validate.ps1`
- [ ] Unified RBAC role decision made
- [ ] Response governance (AIR approval-gated) documented
