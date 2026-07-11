# Onboarding Accelerator — Microsoft Defender for Endpoint

> **Version 1.0.0** · Category: Defender · Solution code: MDEONB

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Onboarding Accelerator: Microsoft Defender for Endpoint

**White-label · Defender**

Most tenants that own Microsoft Defender for Endpoint (MDE) have devices "onboarded" but the protection stack half-configured: **EDR in block mode** is off, **attack surface reduction (ASR)** rules are unset or in audit forever, **tamper protection** is not enforced, **web content filtering** is empty, **device groups and RBAC** are flat, **live response** is unconfigured, and **vulnerability management** is un-triaged. The result is an **endpoint detection & response (EDR)** capability that reports telemetry but blocks little and is hard to operate. This accelerator onboards MDE **end to end** across **Windows, macOS, and Linux**: it onboards devices to a pilot ring, turns on EDR in block mode, deploys ASR rules (audit → block), enforces tamper protection, configures web content filtering, builds device groups and role-based access, enables live response, and stands up threat & vulnerability management — piloted first, validated, then expanded.

This is a complete, **deploy-it-today** package written for an administrator with no prior MDE experience. It onboards a **pilot device ring first**, brings disruptive controls (ASR, block mode) up through **audit before block**, keeps automated response **approval-gated**, and never removes an existing control to "test."

## What you get
- A plain-language **Solution Overview** of onboarding channels, EDR block mode, ASR, tamper protection, web content filtering, device groups/RBAC, live response, and TVM.
- A **Requirements Guide** with verify / implement-if-missing for every solution-specific prerequisite.
- An **Implementation Guide** of exact, ordered steps — onboard the ring, block mode, ASR audit→block, tamper protection, web filtering, device groups/RBAC, live response, TVM — pilot-first.
- Five **PowerShell scripts** (Microsoft Graph Security + Defender APIs) plus **KQL advanced-hunting** queries for readiness discovery, configuration validation, coverage & exposure reporting, a `-WhatIf`-gated ASR audit→block promotion helper, and a `DeviceInfo` onboarding-coverage hunt.
- **Testing** and **Troubleshooting** guides for a confident rollout.

## What this delivers
A validated, monitored Defender for Endpoint deployment delivering **EDR** — devices onboarded across Windows/macOS/Linux, EDR in block mode, ASR rules enforced, tamper protection on, web content filtering live, device groups and RBAC in place, live response ready, and vulnerability exposure triaged — onboarded in a ring and expanded with confidence, not a half-configured console.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand** — onboard a pilot ring, bring ASR/block mode up via audit-first, validate coverage and detections, then expand across the fleet.

## Boundary
This solution is the **full standalone onboarding of the Defender for Endpoint pillar**. It is deliberately **distinct** from — and cross-references, rather than duplicates — the catalog's **"Defender for Endpoint Integration"** (which focuses on the Intune connector wiring) and the **"Defender for Endpoint macOS Onboarding via Intune"** solution (a macOS-specific onboarding). Use those where their narrower scope fits; this accelerator is the end-to-end MDE stand-up across all platforms. Incident-response decisions, automated-response guardrails, and licensing determinations remain the customer's security, operations, and licensing functions; this guide provides the technical configuration.

## Effort
A competent administrator can complete the pilot-ring onboarding and configuration validation in a focused engagement, then expand across the fleet on a controlled cadence. Rollout scales with device count and the mix of Windows/macOS/Linux onboarding channels.


---


# 1. Solution Overview — Onboarding Accelerator: Microsoft Defender for Endpoint

## What Microsoft Defender for Endpoint is
Microsoft Defender for Endpoint (MDE) is the **endpoint detection & response (EDR)** pillar of Microsoft Defender. It combines next-generation antivirus, behavioral EDR, attack surface reduction, threat & vulnerability management, and live response into one agent that runs on **Windows, macOS, and Linux** (and mobile) and reports to the unified Defender portal at `security.microsoft.com` under **Assets → Devices** and **Endpoints**. Fully onboarded, MDE detects and blocks endpoint attacks, reduces the exploitable surface before an attack lands, shows which devices are vulnerable, and lets analysts remotely investigate a compromised host.

The building blocks this accelerator configures:
- **Onboarding** — getting each device reporting via the right channel (Intune, Group Policy, local script, or the platform-specific method for macOS/Linux).
- **EDR in block mode** — lets EDR block malicious artifacts even when a non-Microsoft AV is primary.
- **Attack surface reduction (ASR) rules** — pre-attack hardening (block credential theft, Office child-process abuse, script/macro tricks), brought up **audit → block**.
- **Tamper protection** — prevents attackers (and misconfigurations) from disabling the protection stack.
- **Web content filtering** — category-based web control from the endpoint.
- **Device groups and RBAC** — scope devices for automation levels and analyst permissions.
- **Live response** — remote shell to investigate/contain a device.
- **Threat & vulnerability management (TVM)** — exposure score and remediation of vulnerable software/configs.

## Why this matters
Onboarding a device is only the first 20% of MDE. A tenant that stops there gets telemetry but little protection: EDR isn't blocking, the attack surface is wide open (ASR unset), the agent can be silently disabled (no tamper protection), and analysts have flat permissions and no live-response path. The high-value, disruptive controls — **ASR** and **block mode** — are exactly the ones that need an **audit-first, ring-based** rollout so they don't break line-of-business apps. This accelerator brings the whole stack up safely: onboard a ring, audit the disruptive controls, validate, then enforce and expand — so EDR is genuinely detecting, blocking, and operable, not just "green in the portal."

## How it works
1. **Onboarding** — the pilot ring is onboarded through the right channel per platform: **Intune** (default for Windows/macOS), **Group Policy / local script** for Windows where Intune isn't present, and the documented **macOS** (MDM profile + package) and **Linux** (repo + package) methods. *Cross-reference the catalog's Intune-integration and macOS-onboarding solutions for those channels; this accelerator drives the end-to-end stand-up.*
2. **EDR in block mode** is enabled so EDR blocks malicious artifacts post-breach even behind a third-party AV.
3. **ASR rules** are deployed in **audit** first (to see what they would block), reviewed, then moved to **block** for the ring.
4. **Tamper protection** is turned on so the stack can't be disabled by an attacker.
5. **Web content filtering** policies are created for the categories the org wants controlled.
6. **Device groups** are defined (`MDE Device Group – Pilot Ring – Pilot`, then production rings) with per-group **automation levels**, and **RBAC** roles scope analyst permissions.
7. **Live response** is enabled (with approval controls) so responders can investigate a device remotely.
8. **TVM** exposure is baselined and the top remediations triaged.
9. **Automated response (AIR)** is kept in an **approval/simulate** posture during the pilot.

## What you can control
- **Onboarding channel per platform** — Intune / GPO / script for Windows; MDM profile + package for macOS; repo + package for Linux.
- **Ring membership** — which devices onboard and enforce first.
- **ASR posture** — audit vs block, per rule, per ring.
- **Web content filtering** — which categories are blocked/audited.
- **Device groups + automation levels** — how much AIR each group may do (approval-gated first).
- **RBAC** — which analysts get read vs response permissions; **live response** approval controls.
- **TVM focus** — which vulnerabilities to remediate first.

## Limitations (be honest with buyers)
- MDE is **license-gated** (Defender for Endpoint P1/P2; some features — EDR, TVM, web content filtering — need **P2**). Onboarding without the plan fails or limits features — *verify current availability in your tenant.*
- **ASR and block mode are disruptive** if enforced blind — they must go **audit → block** on a ring first; a bad ASR rule can break a business app.
- **macOS and Linux** onboarding uses platform-specific packages/channels and has feature differences from Windows — *verify current platform support and feature parity.*
- **Coverage, TVM exposure, and hunting tables** populate over time — allow warm-up after onboarding.
- MDE improves endpoint detection and response; it does not replace patching, backup, identity hardening, network controls, or the SOC's incident-response decisions.

## Connections and authentication used
- The **unified Defender portal** (`security.microsoft.com` → **Settings → Endpoints**, **Assets → Devices**) for onboarding, ASR/AV/tamper policy, web filtering, device groups, RBAC, live response, and TVM.
- **Intune / Microsoft Endpoint Manager** (`intune.microsoft.com`) as the default onboarding and policy channel (GPO/script/MDM/Linux repo where used).
- **Microsoft Graph Security** and the **Microsoft 365 Defender / Defender for Endpoint** APIs (via the `Microsoft.Graph` PowerShell modules) for read-only discovery, validation, reporting, and advanced-hunting (`DeviceInfo`, `DeviceTvmSoftwareVulnerabilities`, `DeviceEvents`, `AlertInfo`).
- Least-privilege roles: **Security Administrator** for configuration, **Security Reader** for read-only work, and **Global Administrator** only for one-time first-service activation.

## The standard deployment model
> **Assess readiness (license, roles, onboarding channels per platform) → configure the protection stack → onboard a pilot ring and bring ASR/block mode up audit-first → validate coverage, detections, and configuration on the ring → expand across the fleet.** Repeatable pattern: **Assess → Configure → Pilot → Validate → Expand**, with ASR/block audited before enforce and automated response kept approval-gated until trusted.


---


# 2. Requirements Guide — Onboarding Accelerator: Microsoft Defender for Endpoint

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify · Implement-if-missing.** Category-wide prerequisites (tenant, licensing, admin roles, onboarding reach, network access, pilot ring, workspace, response governance) are in `global-requirements-defender.md` — do not repeat them; the items below are **specific to onboarding Defender for Endpoint end to end**. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

## 2.1 Defender for Endpoint activated
**Description:** MDE initialized for the tenant under `security.microsoft.com` → **Settings → Endpoints**.
**Why:** Onboarding packages, ASR/AV policy, device groups, and RBAC only appear after first-time activation.
**Verify:** Sign in as a Security Administrator and confirm **Settings → Endpoints → Onboarding** loads. Run `MDEONB-Discovery.ps1`.
**Implement-if-missing:** Complete the one-time MDE activation (Global Administrator required for first-service activation only).

## 2.2 Onboarding channel per platform
**Description:** A working onboarding channel for each platform in scope — **Intune** (default for Windows/macOS), **Group Policy / local script** for Windows, the **macOS** MDM profile + package, and the **Linux** repo + package.
**Why:** MDE collects EDR signal only from onboarded devices; each platform onboards through its own channel.
**Verify:** `MDEONB-Discovery.ps1` reports the platform mix and current onboarding coverage; confirm the Intune MDE connector is **Enabled**. 
**Implement-if-missing:** Establish the channel per platform — *cross-reference the catalog's "Defender for Endpoint Integration" (Intune connector) and "Defender for Endpoint macOS Onboarding via Intune" solutions* — and target the pilot ring first.

## 2.3 Pilot device ring defined
**Description:** A named pilot device group `MDE Device Group – Pilot Ring – Pilot` (Entra/Intune) covering a representative mix of Windows/macOS/Linux.
**Why:** Onboarding and the disruptive controls (ASR, block mode) are validated on a ring before the fleet (per `global-requirements-defender.md` G6).
**Verify:** The group exists; `MDEONB-Validate.ps1 -Check Onboarding` checks membership/coverage. 
**Implement-if-missing:** Create `MDE Device Group – Pilot Ring – Pilot` before onboarding anything that enforces.

## 2.4 EDR / next-gen AV baseline decision
**Description:** A decision on **EDR in block mode** and the antivirus posture (Defender AV primary, or third-party AV with EDR block mode).
**Why:** Block mode is what lets EDR block artifacts behind a non-Microsoft AV; the posture must be agreed.
**Verify:** `security.microsoft.com` → **Settings → Endpoints → Advanced features → EDR in block mode**; `MDEONB-Validate.ps1 -Check EDR` reports it. 
**Implement-if-missing:** Decide the AV posture and plan to enable EDR in block mode after pilot onboarding.

## 2.5 ASR rollout scope (audit-first)
**Description:** The **attack surface reduction** rules to deploy and the plan to run them **audit → block** on the ring.
**Why:** ASR rules can break line-of-business apps if enforced blind; audit-first surfaces the impact.
**Verify:** `MDEONB-Validate.ps1 -Check ASR` reports current ASR rule states; a rule list and exclusions are drafted. 
**Implement-if-missing:** Draft the ASR rule set and exclusions, create the policy `MDE ASR Rules – Pilot Ring – Audit`, and only later promote to `MDE ASR Rules – Pilot Ring – Block`.

## 2.6 Tamper protection and web content filtering scope
**Description:** Intent to enforce **tamper protection** tenant-wide and to configure **web content filtering** categories (P2). 
**Why:** Tamper protection stops the stack being disabled; web content filtering adds endpoint web control. *Web content filtering requires P2 — verify current availability.*
**Verify:** `security.microsoft.com` → **Settings → Endpoints → Advanced features** (tamper protection) and **Web content filtering**; `MDEONB-Validate.ps1 -Check Config` reports both. 
**Implement-if-missing:** Plan tamper protection enforcement and draft the web content filtering categories/policy.

## 2.7 Device groups, RBAC, and live response controls
**Description:** The **device group** structure (with per-group AIR automation levels), the **RBAC** role model (reader / operator), and **live response** approval controls.
**Why:** Device groups drive automation scope; RBAC scopes analyst permissions; live response is powerful and must be gated.
**Verify:** `security.microsoft.com` → **Settings → Endpoints → Permissions** (Roles, Device groups) and **Advanced features → Live Response**; `MDEONB-Validate.ps1 -Check RBAC` reports them. 
**Implement-if-missing:** Plan `MDE Device Group – Pilot Ring – Pilot`, roles `MDE Security Reader – Tenant – Prod` / `MDE Security Operator – Tenant – Prod`, and live-response approval settings (Step 7).

## 2.8 Response governance
**Description:** An agreed position on **automated investigation and response (AIR)** automation levels, kept approval-gated during the pilot.
**Why:** AIR can isolate devices and remediate files; the organization decides the guardrails (per `global-requirements-defender.md` G8).
**Verify:** A documented response policy exists; the pilot group's automation level is approval-gated. `MDEONB-Report.ps1` reports it. 
**Implement-if-missing:** Keep AIR approval-gated at first; *incident-response and automation guardrail decisions are the SOC/security team's — this guide covers the technical configuration.*

---
## Checklist
- [ ] MDE activated — `MDEONB-Discovery.ps1`
- [ ] Onboarding channel per platform (Intune/GPO/script/macOS/Linux)
- [ ] Pilot device ring `MDE Device Group – Pilot Ring – Pilot` defined
- [ ] EDR block mode / AV posture decided
- [ ] ASR rollout scope (audit-first) drafted — `MDE ASR Rules – Pilot Ring – Audit`
- [ ] Tamper protection + web content filtering scope planned
- [ ] Device groups, RBAC, live-response controls planned
- [ ] Response governance (AIR approval-gated) documented


---


# Global Requirements — Defender (category-level)

These requirements apply to every solution in the Defender category (Microsoft Defender XDR and Defender
for Cloud). Published once at the category level so listings stay small. Confirm before deploying any
Defender solution. Each entry: Description / Why / Verify / Implement-if-missing.

> Defender changes touch detection and response for the whole tenant. Onboard in a ring (pilot devices/
> users first), keep automated response in an approval/simulate posture until trusted, and never disable
> an existing control to "test."

## G1. Microsoft 365 / Entra tenant
Description: An active Microsoft 365 tenant with Entra ID.
Why: Defender XDR services and the unified portal (security.microsoft.com) are tenant workloads.
Verify: Sign in to `https://security.microsoft.com` as an administrator.
Implement: Provision a Microsoft 365 tenant and confirm Entra ID identities exist.

## G2. Defender licensing
Description: The Defender plans for the pillars in scope — e.g. Defender for Endpoint P1/P2, Defender for Identity, Defender for Office 365 P1/P2, Defender for Cloud Apps, and Defender for Cloud plans.
Why: Each pillar/feature is license-gated; onboarding without the plan fails or silently limits features.
Verify: Admin center -> `Billing -> Licenses` (or the Defender portal). *Confirm the exact plan each feature needs — verify current availability in your tenant.*
Implement: Assign the required plans (often bundled in M365 E5 / E5 Security) before onboarding.

## G3. Administrative roles (least privilege)
Description: Security Administrator (and Global Administrator for first-time service activation).
Why: Onboarding, RBAC, and policy changes in the Defender portal require these roles.
Verify: Entra -> `Roles and administrators`; confirm Security Administrator.
Implement: Assign Security Administrator; reserve Global Administrator for one-time activations.

## G4. Onboarding reach to endpoints / identity / workloads
Description: A management channel to onboard the pillars — Intune/Configuration Manager/GPO/script for endpoints, domain controllers/AD FS for Identity sensors, and cloud connectors for Defender for Cloud.
Why: Each pillar collects signal from a source that must be reachable and instrumented.
Verify: Endpoints are managed (Intune/CM); DCs are reachable; cloud subscriptions are connected. Run the solution's discovery script.
Implement: Establish the onboarding channel per pillar (see the relevant catalog endpoint/identity solutions).

## G5. Network access to Defender service endpoints
Description: Outbound HTTPS to the Microsoft Defender / Microsoft 365 service URLs from onboarded assets.
Why: Sensors and agents report to the cloud service; blocked endpoints break onboarding and detections.
Verify: Confirm the documented Defender endpoint URLs/IP ranges are allowed. *Verify current endpoint list.*
Implement: Allow the Defender/M365 endpoints through proxy/firewall.

## G6. A pilot ring
Description: A defined set of pilot devices/users/subscriptions to onboard first.
Why: XDR onboarding and automated response are validated on a ring before tenant-wide rollout.
Verify: A pilot group exists in Entra/Intune.
Implement: Create the pilot ring before enabling anything that acts automatically.

## G7. Log Analytics workspace (where required)
Description: A Log Analytics workspace for Defender for Cloud / advanced hunting export where used.
Why: Some Defender data and continuous export land in a workspace.
Verify: A workspace exists and is access-controlled. Run the discovery script.
Implement: Provision a workspace (or reuse the SIEM/observability one) with least-privilege access.

## G8. Response governance
Description: An agreed position on automated response (auto-remediation levels, approval requirements).
Why: XDR/AIR can take disruptive actions (isolate, delete, disable); the organization must decide the guardrails.
Verify: A documented response policy exists; automation is in an approval/simulate posture until trusted.
Implement: Define response guardrails; keep AIR/automation approval-gated at first. *Incident-response decisions are the SOC/security team's; this guide covers the technical configuration.*

---
The deployment model (all solutions): Assess -> Configure -> Pilot -> Validate -> Expand.


---


# 3. Implementation Guide — Onboarding Accelerator: Microsoft Defender for Endpoint

Follow these steps **in order**. Configuration spans the **unified Defender portal** (`https://security.microsoft.com`) and the **Intune admin center** (`https://intune.microsoft.com`) as the default onboarding/policy channel. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

> **Model:** Onboard a **pilot ring** first, bring the disruptive controls (**ASR**, **EDR block mode**) up **audit → block**, validate coverage and detections, then enforce and expand across the fleet. Keep **automated response (AIR)** approval-gated throughout. Never remove an existing control to "test."

## Naming (set once, reuse verbatim)
- Pilot device group: `MDE Device Group – Pilot Ring – Pilot`
- Onboarding profile (Intune, Windows): `MDE Onboarding – Pilot Ring – Pilot`
- ASR policy (audit): `MDE ASR Rules – Pilot Ring – Audit`
- ASR policy (block): `MDE ASR Rules – Pilot Ring – Block`
- AV/next-gen policy: `MDE Next-Gen AV – Pilot Ring – Prod`
- Web content filtering policy: `MDE Web Content Filtering – Tenant – Prod`
- RBAC roles: `MDE Security Reader – Tenant – Prod`, `MDE Security Operator – Tenant – Prod`
- Advanced-hunting saved query: `MDE Onboarding Coverage – Tenant – Validate`

## Step 1 — Assess readiness
1. Sign in to `security.microsoft.com` as a **Security Administrator**.
2. Run `MDEONB-Discovery.ps1` to capture the current state: MDE activation, licensed plan (P1/P2) hints, admin roles, platform mix, onboarding coverage, and the Intune MDE connector status.
3. In **Intune/Entra** → **Groups**, create `MDE Device Group – Pilot Ring – Pilot` with a representative Windows/macOS/Linux mix.

## Step 2 — Onboard the pilot ring
1. `security.microsoft.com` → **Settings → Endpoints → Onboarding**. If MDE is not initialized, complete the one-time activation.
2. **Windows via Intune (default):** confirm `intune.microsoft.com` → **Endpoint security → Microsoft Defender for Endpoint → Connection status: Enabled**. Create the EDR onboarding profile `MDE Onboarding – Pilot Ring – Pilot` and assign it only to `MDE Device Group – Pilot Ring – Pilot`. (GPO/local-script channels use the package from **Settings → Endpoints → Onboarding** against the pilot OU.)
3. **macOS:** deploy the MDM onboarding profile + package to the pilot Macs (*cross-reference the macOS onboarding solution*). **Linux:** onboard via the documented repo + package method on the pilot Linux hosts. *Verify current macOS/Linux onboarding steps and support.*
4. On pilot devices, confirm onboarding in **Assets → Devices**.
5. Run `MDEONB-Validate.ps1 -Check Onboarding` to confirm each pilot device reports EDR signal.

## Step 3 — Next-gen AV and EDR in block mode
1. In Intune → **Endpoint security → Antivirus**, create `MDE Next-Gen AV – Pilot Ring – Prod` (real-time protection, cloud-delivered protection, PUA) assigned to the pilot ring.
2. `security.microsoft.com` → **Settings → Endpoints → Advanced features** — enable **EDR in block mode** (lets EDR block artifacts behind a third-party AV).
3. Run `MDEONB-Validate.ps1 -Check EDR` to confirm block mode and AV posture.

## Step 4 — Attack surface reduction (audit first)
1. In Intune → **Endpoint security → Attack surface reduction**, create `MDE ASR Rules – Pilot Ring – Audit` with the chosen ASR rules set to **Audit**, assigned to the pilot ring.
2. Let it run, then review what the rules *would* block with `MDEONB-Report.ps1 -Section ASR` and the advanced-hunting `DeviceEvents` for `Asr*Audited`. Add exclusions for legitimate line-of-business behavior.
3. Only after review, create `MDE ASR Rules – Pilot Ring – Block` with the validated rules set to **Block**, assigned to the pilot ring.
4. Run `MDEONB-Validate.ps1 -Check ASR` to confirm rule states. Promotion from audit to block can be previewed with `MDEONB-PromoteASR.ps1` (safe preview by default).

## Step 5 — Tamper protection and web content filtering
1. `security.microsoft.com` → **Settings → Endpoints → Advanced features → Tamper Protection** — enforce it (protects the stack from being disabled).
2. **Settings → Endpoints → Web content filtering** — create `MDE Web Content Filtering – Tenant – Prod` for the categories to control (P2). *Web content filtering requires P2 — verify current availability.*
3. Run `MDEONB-Validate.ps1 -Check Config` to confirm tamper protection and web filtering.

## Step 6 — Device groups and RBAC
1. `security.microsoft.com` → **Settings → Endpoints → Permissions → Device groups** — define `MDE Device Group – Pilot Ring – Pilot` with the pilot ring and set its **automation level** to **Semi — require approval** during the pilot.
2. **Settings → Endpoints → Permissions → Roles** — create `MDE Security Reader – Tenant – Prod` (read-only) and `MDE Security Operator – Tenant – Prod` (read + response); assign least privilege.
3. Run `MDEONB-Validate.ps1 -Check RBAC` to confirm device groups and roles.

## Step 7 — Live response and automated response (approval-gated)
1. `security.microsoft.com` → **Settings → Endpoints → Advanced features → Live Response** — enable it, and require **live response for servers** / approval per your policy. Live response is powerful — restrict who can run it via the RBAC roles above.
2. Confirm the pilot device group's AIR **automation level** remains **Semi — require approval** (Step 6). Record it with `MDEONB-Report.ps1`.
3. *The decision to raise automation or broaden live response is the SOC/security team's — this guide leaves it approval-gated.*

## Step 8 — Validate coverage and detections on the ring
1. Run `MDEONB-Hunt.ps1` to execute `MDE Onboarding Coverage – Tenant – Validate` — it confirms `DeviceInfo` shows the pilot devices onboarded and healthy, and that `DeviceEvents`/`DeviceTvmSoftwareVulnerabilities` are populating.
2. Run the Microsoft-provided **EDR detection test** (safe, documented) on a pilot device and confirm the alert appears in **Incidents & alerts**. Confirm an ASR-block event on a device once block mode is on.
3. `security.microsoft.com` → **Vulnerability management → Dashboard** — record the exposure baseline with `MDEONB-Report.ps1 -SaveBaseline`.
4. Complete the **Testing Guide** before expanding.

## Step 9 — Expand across the fleet
1. **Onboarding:** broaden the Intune assignment (or create the next ring) to cover remaining Windows devices in waves; extend the macOS/Linux onboarding to the rest of those fleets.
2. **ASR/block mode:** promote `MDE ASR Rules – Pilot Ring – Block` (and block mode) to production rings after each ring validates clean.
3. **Web filtering / tamper protection:** confirm tenant-wide.
4. **RBAC / automation:** review AIR automation levels with the SOC only after coverage and detections are trusted (still their decision).
5. Re-baseline exposure with `MDEONB-Report.ps1 -SaveBaseline` and track coverage/exposure drift each cycle.

---
### Order of operations
`Assess → onboard pilot ring (Win/macOS/Linux) → next-gen AV + EDR block mode → ASR audit → ASR block → tamper protection + web filtering → device groups + RBAC → live response + AIR approval-gated → validate coverage + detections → expand across the fleet`


---


# 5. Testing Guide — Onboarding Accelerator: Microsoft Defender for Endpoint

Run these checks after the pilot onboarding (Steps 2–8) and again after each expansion wave. Each test has a **pass/fail gate**; do not enforce ASR/block mode more widely or expand until the pilot passes. Objects are referenced by the exact names from the Implementation Guide.

## Test 1 — Pilot ring onboarded (all platforms)
**Procedure:** Run `MDEONB-Validate.ps1 -Check Onboarding`. In `security.microsoft.com` → **Assets → Devices**, confirm each pilot device from `MDE Device Group – Pilot Ring – Pilot` (Windows/macOS/Linux) is **Onboarded**.
**Pass:** Every pilot device is onboarded and reporting EDR signal.
**Fail:** A device stays "Can be onboarded" — see Troubleshooting *Device not onboarding*.

## Test 2 — Next-gen AV + EDR block mode
**Procedure:** Run `MDEONB-Validate.ps1 -Check EDR`. Confirm `MDE Next-Gen AV – Pilot Ring – Prod` is applied and **EDR in block mode** is on.
**Pass:** AV policy applied to the ring and block mode enabled.
**Fail:** Block mode off or AV policy not applied — see Troubleshooting *EDR/AV not applied*.

## Test 3 — ASR in audit, then block
**Procedure:** Run `MDEONB-Validate.ps1 -Check ASR` and `MDEONB-Report.ps1 -Section ASR`. Confirm `MDE ASR Rules – Pilot Ring – Audit` produced audit events, exclusions were reviewed, and `MDE ASR Rules – Pilot Ring – Block` is now blocking on the ring.
**Pass:** ASR ran in audit, exclusions were tuned, and block is enforced on the ring with no legitimate-app breakage.
**Fail:** ASR blocking before audit review, or breaking apps — revert to audit per Implementation Step 4.

## Test 4 — Tamper protection + web content filtering
**Procedure:** Run `MDEONB-Validate.ps1 -Check Config`. Confirm **Tamper Protection** is enforced and `MDE Web Content Filtering – Tenant – Prod` is active.
**Pass:** Tamper protection on; web content filtering categories enforced (P2).
**Fail:** Either off — re-apply per Implementation Step 5; *verify P2 for web content filtering.*

## Test 5 — Device groups + RBAC
**Procedure:** Run `MDEONB-Validate.ps1 -Check RBAC`. Confirm `MDE Device Group – Pilot Ring – Pilot` exists with automation **Semi — require approval**, and roles `MDE Security Reader – Tenant – Prod` / `MDE Security Operator – Tenant – Prod` are assigned.
**Pass:** Device group and roles exist; reader cannot take response actions, operator can; automation is approval-gated.
**Fail:** Flat permissions or wrong automation — re-apply per Implementation Step 6.

## Test 6 — Onboarding coverage + telemetry streaming
**Procedure:** Run `MDEONB-Hunt.ps1` to execute `MDE Onboarding Coverage – Tenant – Validate`. Confirm `DeviceInfo` shows pilot devices onboarded/healthy and `DeviceEvents` / `DeviceTvmSoftwareVulnerabilities` return rows.
**Pass:** Coverage and telemetry tables stream for the pilot ring.
**Fail:** A table empty — see Troubleshooting *No device telemetry*.

## Test 7 — A detection actually fires
**Procedure:** Run the Microsoft-provided safe **EDR detection test** on a pilot device; confirm the alert appears in **Incidents & alerts**. With block mode on, confirm an ASR-block event on a device.
**Pass:** The controlled test produces a visible MDE alert; ASR blocks the tested behavior.
**Fail:** No alert/block — see Troubleshooting *Detection does not fire*.

## Test 8 — TVM exposure baseline + AIR approval-gated
**Procedure:** Run `MDEONB-Report.ps1 -SaveBaseline`. Confirm a TVM exposure score/baseline is recorded and the pilot group's AIR automation level is **Semi — require approval**.
**Pass:** Exposure baseline captured; AIR approval-gated on the pilot.
**Fail:** No exposure data (allow warm-up) or automation higher than agreed — reset per Implementation Step 7 and confirm with the SOC.

---
### Exit gate
All eight tests pass on the pilot ring **before** you promote ASR/block mode more widely or expand onboarding (Implementation Step 9). Re-run Tests 1, 3, 6, 7, and 8 after each expansion wave and compare against the saved exposure baseline.


---


# 6. Troubleshooting Guide — Onboarding Accelerator: Microsoft Defender for Endpoint

Common field issues, in **symptom → cause → fix** form. Run `MDEONB-Discovery.ps1` and `MDEONB-Validate.ps1` first — most causes surface there.

## Device not onboarding
**Symptom:** Test 1 fails — a pilot device stays "Can be onboarded" in **Assets → Devices** and reports no EDR signal.
**Cause:** The onboarding profile is not assigned, the Intune MDE connector is off, the device cannot reach the Defender service endpoints, or the platform channel (macOS profile / Linux package) did not complete.
**Fix:** Confirm the device is in `MDE Device Group – Pilot Ring – Pilot` and `MDE Onboarding – Pilot Ring – Pilot` is assigned; confirm **Endpoint security → Microsoft Defender for Endpoint → Connection status: Enabled**; verify outbound HTTPS to the Defender endpoints (per `global-requirements-defender.md` G5); for macOS/Linux confirm the MDM profile/package installed. Force a sync and re-run `MDEONB-Validate.ps1 -Check Onboarding`.

## EDR/AV not applied
**Symptom:** Test 2 fails — **EDR in block mode** is off or `MDE Next-Gen AV – Pilot Ring – Prod` is not applied.
**Cause:** Block mode not enabled in Advanced features, the AV policy is not assigned to the ring, or a third-party AV is conflicting.
**Fix:** Enable **Settings → Endpoints → Advanced features → EDR in block mode**; confirm the AV policy is assigned to `MDE Device Group – Pilot Ring – Pilot`; confirm the AV posture (Defender primary or passive behind third-party). Re-run `MDEONB-Validate.ps1 -Check EDR`.

## ASR breaking a business app
**Symptom:** After moving to block, a line-of-business app fails.
**Cause:** An ASR rule in `MDE ASR Rules – Pilot Ring – Block` blocks a legitimate behavior with no exclusion.
**Fix:** Identify the rule from the block event (`MDEONB-Report.ps1 -Section ASR` / `DeviceEvents`), revert that rule to **audit**, add a scoped exclusion, validate in audit, then re-promote. This is exactly why ASR goes **audit → block** first (Implementation Step 4).

## No device telemetry
**Symptom:** Test 6 fails — `DeviceInfo`, `DeviceEvents`, or `DeviceTvmSoftwareVulnerabilities` return no rows.
**Cause:** Devices newly onboarded and still warming up, or a device is unhealthy/not reporting.
**Fix:** Confirm devices are onboarded and healthy (Test 1); allow warm-up (tables populate over hours); check device health in **Assets → Devices**. Re-run `MDEONB-Hunt.ps1`.

## Detection does not fire
**Symptom:** Test 7 fails — the safe EDR detection test produces no alert.
**Cause:** The device is not fully onboarded, block mode/AV is off, or not enough time has passed for the alert.
**Fix:** Confirm onboarding (Test 1) and AV/block mode (Test 2); run the Microsoft-documented EDR test exactly; allow the alert to surface in **Incidents & alerts**. Re-check with `MDEONB-Hunt.ps1`.

## Web content filtering not enforcing
**Symptom:** Test 4 fails — categories in `MDE Web Content Filtering – Tenant – Prod` are not blocked.
**Cause:** Web content filtering requires **P2** and network protection in block mode; the plan or dependency is missing.
**Fix:** *Verify P2 availability in your tenant*; confirm network protection is enabled (web content filtering depends on it); allow policy propagation. Re-run `MDEONB-Validate.ps1 -Check Config`.

## RBAC / device group not effective
**Symptom:** Test 5 fails — analysts have inconsistent access or the automation level is wrong.
**Cause:** Roles not assigned, device group scope wrong, or RBAC not yet propagated.
**Fix:** Confirm `MDE Security Reader – Tenant – Prod` / `MDE Security Operator – Tenant – Prod` assignments and the `MDE Device Group – Pilot Ring – Pilot` scope/automation level under **Settings → Endpoints → Permissions**; allow propagation and re-test. Re-run `MDEONB-Validate.ps1 -Check RBAC`.

## Automated response acted without approval
**Symptom:** A pilot device was isolated or a file remediated automatically.
**Cause:** The device group's AIR **automation level** is higher than **Semi — require approval**.
**Fix:** Reset the automation level to **Semi — require approval** (Implementation Step 7), confirm with the SOC, and record it with `MDEONB-Report.ps1`. *The automation-guardrail decision is the security team's.*

## Script cannot authenticate
**Symptom:** `MDEONB-*.ps1` fails on connect or returns access-denied.
**Cause:** The Microsoft Graph modules are missing, consent to the required read scopes was not granted, or the account lacks Security Reader.
**Fix:** Let the script install the modules (it checks on run); sign in with `Connect-MgGraph` and consent to the read-only scopes; confirm Security Reader (or higher). Re-run the script.


---


# 7. Best Practices — Onboarding Accelerator: Microsoft Defender for Endpoint

Field-proven guidance for keeping the Defender for Endpoint deployment protective, operable, and low-risk.

## Onboard in rings, never all at once
- Onboard `MDE Device Group – Pilot Ring – Pilot` first — a representative Windows/macOS/Linux mix — validate, then expand in waves. Sequencing catches platform-specific issues before they hit the fleet.
- Onboard **every** platform in scope; a Linux or macOS fleet left un-onboarded is a blind spot.

## Bring ASR and block mode up audit-first
- Always run **ASR** in `MDE ASR Rules – Pilot Ring – Audit` first, review what it *would* block (`MDEONB-Report.ps1 -Section ASR`), add exclusions for legitimate line-of-business behavior, then promote to `MDE ASR Rules – Pilot Ring – Block`. An ASR rule enforced blind can break a business app.
- Promote block mode and ASR ring-by-ring, validating each ring clean before the next.

## Enforce tamper protection early
- Turn on **tamper protection** so an attacker (or a well-meaning misconfiguration) cannot disable the protection stack. It is one of the highest-value, lowest-friction controls.

## Structure device groups and RBAC deliberately
- Use **device groups** to scope AIR automation levels and analyst access; keep the pilot at **Semi — require approval**. Grant least privilege via `MDE Security Reader – Tenant – Prod` and `MDE Security Operator – Tenant – Prod` — only responders get response permissions.
- **Live response** is powerful (remote shell to a device) — restrict who can run it and gate it per policy.

## Keep automated response approval-gated until trusted
- Leave **AIR** at **Semi — require approval** during the pilot and early expansion. Raising automation is the SOC/security team's decision, made only after coverage and detections are proven.

## Work TVM exposure as a trend
- Capture the **exposure baseline** (`MDEONB-Report.ps1 -SaveBaseline`), triage the highest-impact vulnerabilities first, and track the delta each cycle. Re-baseline after each expansion so the trend reflects real coverage.

## Mind platform and licensing differences
- **macOS/Linux** onboard through platform-specific channels and have feature differences from Windows; **web content filtering, TVM, and some features need P2**. Before relying on a capability, **verify current platform support and plan requirements in your tenant.**

## Where to go next
Once MDE is onboarded and validated, natural next steps in the catalog:
- The **Defender for Endpoint Integration** solution for deeper Intune-connector configuration, and the **macOS Onboarding via Intune** solution for a macOS-specific rollout — cross-reference rather than re-do.
- The **Microsoft Defender XDR — Unified Onboarding** accelerator to correlate MDE with Identity, Office 365, and Cloud Apps.
- The **Onboarding Accelerator — Microsoft Defender for Cloud Apps** — MDE's discovery feed powers Cloud Discovery.
- The **SOC onboarding — Sentinel + Defender XDR** and **advanced KQL threat-hunting** solutions to hunt endpoint attacks in a SIEM.


---


# 8. Deliverables Summary — Onboarding Accelerator: Microsoft Defender for Endpoint

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What MDE is — onboarding (Win/macOS/Linux), EDR block mode, ASR, tamper protection, web filtering, device groups/RBAC, live response, TVM; benefits, limitations |
| 2. Requirements Guide | Solution-specific prerequisites with Verify / Implement-if-missing |
| Global Requirements (Defender) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps — onboard the ring, AV + block mode, ASR audit→block, tamper protection, web filtering, device groups/RBAC, live response, TVM, expand |
| 5. Testing Guide | Eight validation tests with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations and where to go next |

## PowerShell scripts (Microsoft Graph Security / Defender APIs + KQL)
| Script | What it does |
|---|---|
| `MDEONB-Discovery.ps1` | Read-only readiness — MDE activation, plan (P1/P2) hints, admin roles, platform mix, onboarding coverage, Intune MDE connector status |
| `MDEONB-Validate.ps1` | Targeted validation (`-Check Onboarding\|EDR\|ASR\|Config\|RBAC`) — confirms onboarding, block mode/AV, ASR rule states, tamper/web filtering, device groups/roles |
| `MDEONB-Report.ps1` | Coverage + TVM exposure report by section (`-Section ASR\|Exposure\|All`) with top vulnerabilities and drift versus a saved baseline; reports AIR automation level |
| `MDEONB-PromoteASR.ps1` | `-WhatIf`-gated helper that promotes ASR rules from audit to block for the pilot ring (safe preview by default) |
| `MDEONB-Hunt.ps1` | Runs the KQL advanced-hunting query `MDE Onboarding Coverage` via Graph Security to confirm `DeviceInfo`/`DeviceEvents`/TVM tables stream (read-only) |

## What the buyer receives
- This solution as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** (with embedded KQL) in a single ZIP.
- A repeatable process following the model **Assess → Configure → Pilot → Validate → Expand** — pilot-ring onboarding with ASR/block mode audited before enforce and automated response kept approval-gated until trusted.

Delivered as a **Complete Solution Package (PDF + Word + scripts)**.

## Outcome
A validated, monitored Defender for Endpoint deployment delivering EDR — devices onboarded across Windows/macOS/Linux, EDR in block mode, ASR enforced, tamper protection on, web content filtering live, device groups and RBAC in place, live response ready, and vulnerability exposure triaged — proven on a pilot ring before you scale.
