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
