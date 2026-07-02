# Microsoft Defender for Endpoint Integration

> **Version 1.0.0** · Category: Intune · Solution code: MDE

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Microsoft Defender for Endpoint Integration (Microsoft Intune)

**White-label · Intune Solutions**

Antivirus alone doesn't stop a modern attacker. **Microsoft Defender for Endpoint (MDE)** adds
endpoint detection and response (EDR), behavioral protection, and a live device **risk score** —
and when integrated with Microsoft Intune, devices onboard automatically and that risk score
flows straight into compliance and Conditional Access.

This is a complete, **deploy-it-today** package for integrating Microsoft Defender for Endpoint
with Microsoft Intune, written for an administrator with no prior MDE experience.

## What you get
- A plain-language **Solution Overview** of how the Intune ⇄ MDE integration works.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite.
- An **Implementation Guide** of precise, click-by-click steps in the required order.
- Five **PowerShell scripts** for onboarding discovery, sensor validation, tenant reporting, remediation, and connector status.
- **Testing** and **Troubleshooting** guides for confident rollout.

## What this delivers
The **service-to-service connector** between Intune and MDE, an **EDR onboarding policy** that
silently onboards enrolled devices, and the **machine-risk-score signal** wired into device
compliance — so a compromised device automatically loses access.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Full EDR coverage with automatic onboarding and a risk score that powers Zero Trust enforcement —
deployable by a single administrator and validated before fleet rollout.


---


# 1. Solution Overview — Microsoft Defender for Endpoint Integration

## What this integration is
Microsoft Defender for Endpoint (MDE) is Microsoft's enterprise endpoint security platform —
next-generation antivirus, **endpoint detection and response (EDR)**, attack surface reduction,
and threat/vulnerability management. This solution connects MDE to **Microsoft Intune** so Intune
**onboards** devices to MDE automatically and consumes MDE's **device risk score** as a
compliance and Conditional Access signal.

## How it works
1. You enable the **service-to-service connection** between Intune and the Defender portal.
2. An Intune **EDR onboarding policy** carries the onboarding configuration to enrolled devices, which begin reporting to MDE.
3. MDE continuously evaluates each device and assigns a **machine risk score** (Low/Medium/High).
4. Intune **device compliance** can require a risk score at or below a threshold; a risky device becomes **Not compliant**.
5. **Conditional Access** (require compliant device) then blocks the risky device until it's remediated.

## What you can manage through the integration
- **EDR onboarding** of Windows devices via Intune (no manual onboarding scripts at scale).
- **Risk-based compliance** — fail compliance when MDE risk exceeds your threshold.
- A foundation for managing **Defender Antivirus**, **Attack Surface Reduction**, and **firewall** policy from Intune (companion solutions).

## Benefits
- **Automatic onboarding** — enrolled devices join MDE with no per-device scripting.
- **Risk-driven access** — compromised devices automatically lose access via compliance + CA.
- **Single pane** — manage endpoint security policy from Intune.
- **Faster response** — EDR detection, investigation, and automated remediation.

## Limitations (be honest with buyers)
- Requires **Defender for Endpoint licensing** (P1/P2, M365 E5/E5 Security, or Defender for Business).
- The risk-score → access flow needs the **Device Compliance** and **Conditional Access** solutions.
- Onboarding takes effect after policy sync and a device check-in to the Defender service.
- Down-level/unsupported OSes have reduced capability.

## The standard deployment model
> **Enable the connector → create the EDR onboarding policy → assign to a pilot → wire risk score
> into compliance → validate → expand.** repeatable pattern: **Assess → Configure → Pilot →
> Validate → Expand.**


---


# 2. Requirements Guide — Microsoft Defender for Endpoint Integration

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

## 2.1 Defender for Endpoint licensing
**Description:** Microsoft Defender for Endpoint P1/P2, Microsoft 365 E5 / E5 Security, or Defender for Business.
**Why:** MDE onboarding and EDR require an MDE plan.
**Verify:** M365 admin center → **Billing → Licenses**; the Defender portal (`security.microsoft.com`) loads.
**Implement:** Assign M365 E5/E5 Security, standalone Defender for Endpoint, or Defender for Business (with Business Premium).

## 2.2 Intune + enrollment
**Description:** Intune subscription with target devices enrolled.
**Why:** Intune delivers the onboarding policy and reads the risk score.
**Verify:** Intune → **Devices → All devices**.
**Implement:** Enable automatic enrollment; enroll devices.

## 2.3 Access to the Defender portal
**Description:** Security Administrator access to `https://security.microsoft.com`.
**Why:** The Intune connection is enabled from the Defender portal settings.
**Verify:** The portal loads; **Settings → Endpoints → Advanced features** is accessible.
**Implement:** Assign **Security Administrator** (or Global Admin for setup).

## 2.4 Supported Windows OS
**Description:** Windows 10/11 (Defender sensor built in).
**Why:** Onboarding and EDR require a supported, patched Windows.
**Verify:** `winver`; the **Sense** service exists (`Get-Service Sense`).
**Implement:** Patch/upgrade to a supported build.

## 2.5 Network (Defender endpoints)
**Description:** Outbound HTTPS to Defender for Endpoint service URLs.
**Why:** The sensor reports telemetry and receives configuration from the service.
**Verify:** From a device, the MDE connectivity test passes (or run **`MDE-Validation.ps1`**).
**Implement:** Allow Microsoft Defender for Endpoint URLs/IPs through proxy/firewall; do not SSL-inspect MDE traffic.

## 2.6 Compliance + Conditional Access (for risk enforcement)
**Description:** Device compliance and Conditional Access in place.
**Why:** To turn the MDE risk score into access enforcement.
**Verify:** Intune → **Devices → Compliance**; Entra → **Conditional Access**.
**Implement:** Deploy the **Device Compliance** and **Conditional Access** solutions.

---
## Checklist
- [ ] Defender for Endpoint licensing assigned
- [ ] Devices enrolled in Intune
- [ ] Defender portal access (Security Administrator)
- [ ] Windows 10/11 with the Sense service — `MDE-Discovery.ps1`
- [ ] Network allows MDE endpoints (no SSL inspection)
- [ ] (For enforcement) Compliance + Conditional Access solutions in place
- [ ] Pilot Entra group created


---


# Global Requirements — Intune Solutions (category-level)

These requirements apply to **every** solution in the **Intune Solutions**
category. They are published once at the category level so individual listings stay small.
Confirm these before deploying *any* Intune solution. Each entry: **Description · Why · Verify · Implement-if-missing.**

## G1. Microsoft Entra ID tenant
**Description:** An active Microsoft Entra ID (Azure AD) tenant.
**Why:** It is the identity backbone for every cloud and Intune-managed resource.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create a Microsoft 365/Azure subscription, which provisions a tenant.

## G2. Microsoft Intune subscription
**Description:** An Intune-bearing license plan.
**Why:** Intune delivers all configuration, compliance, and security policies.
**Verify:** `https://intune.microsoft.com` loads; **Tenant administration → Tenant status** shows active.
**Implement:** Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1.

## G3. Administrative roles
**Description:** Appropriate Entra/Intune admin roles for the operator.
**Why:** Creating policies and enrollment settings requires elevated rights.
**Verify:** Entra → **Roles and administrators**; confirm **Intune Administrator**.
**Implement:** Assign **Intune Administrator**; reserve Global Administrator for tenant-wide changes.

## G4. Device enrollment in Intune
**Description:** Targeted Windows devices are enrolled and manageable.
**Why:** Policies only reach enrolled devices.
**Verify:** Intune → **Devices → All devices**; the device appears and is **compliant**.
**Implement:** Enable **Automatic Enrollment** and join devices to Entra ID.

## G5. Pilot security group
**Description:** A Microsoft Entra security group for pilot/targeted users or devices.
**Why:** Every solution is piloted before fleet rollout.
**Verify:** Entra → **Groups**; the pilot group exists.
**Implement:** Entra → **Groups → New group** → **Security** → add members.

## G6. Supported Windows baseline
**Description:** Windows 10 21H2+ or Windows 11 with current updates.
**Why:** Modern Intune features assume a patched, supported OS.
**Verify:** `winver`, or Intune → device → **Hardware**.
**Implement:** Deploy **Update rings** or upgrade to Windows 11.

## G7. Network access to Microsoft cloud endpoints
**Description:** Outbound HTTPS to Microsoft 365, Entra, and Intune service URLs.
**Why:** Enrollment, policy sync, and authentication depend on these endpoints.
**Verify:** From a device, reach `https://login.microsoftonline.com` and `https://enrollment.manage.microsoft.com`.
**Implement:** Allow Microsoft's published Office 365/Intune URL & IP ranges through proxy/firewall.

---
**The standard deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


# 3. Implementation Guide — Microsoft Defender for Endpoint Integration

Follow these steps **in order**. You use both the **Defender portal** (`security.microsoft.com`)
and the **Intune admin center** (`intune.microsoft.com`).

> **Model:** Enable the connector → EDR onboarding policy → assign to pilot → wire risk into compliance.

## Step 1 — Turn on the Intune connection (Defender portal)
1. Open `https://security.microsoft.com` → **Settings → Endpoints → Advanced features**.
2. Turn **Microsoft Intune connection** to **On**. **Save preferences**.

## Step 2 — Confirm the connector in Intune
1. Intune → **Endpoint security → Microsoft Defender for Endpoint**.
2. Confirm **Connection status: Available / Active** (wait a few minutes / **Refresh** if needed).
3. Set **Allow Microsoft Defender for Endpoint to enforce Endpoint Security Configurations** to **On** if you'll manage security config from Intune.

## Step 3 — Create the pilot group
1. Entra → **Groups → New group** → Security → `MDE-Pilot` → add pilot devices/users. **Create**.

## Step 4 — Create the EDR onboarding policy
1. Intune → **Endpoint security → Endpoint detection and response → Create Policy**.
2. **Platform:** Windows. **Profile:** Endpoint detection and response. **Create**.
3. **Name:** `MDE - EDR Onboarding - Pilot`. **Next**.
4. **Microsoft Defender for Endpoint client configuration package type:** **Auto from connector** (the onboarding blob is supplied by the connection). **Sample sharing:** as per policy. **Next**.

## Step 5 — Assign the onboarding policy
1. **Assignments → Add groups →** `MDE-Pilot`. **Next → Create**.

## Step 6 — Wire the risk score into compliance
1. Intune → **Devices → Compliance →** edit your Windows compliance policy (from the Device Compliance solution).
2. Under **Microsoft Defender for Endpoint**, set **Require the device to be at or under the machine risk score** to **Medium** (or **Low** for stricter scopes). **Save**.

## Step 7 — (Recommended) enforce with Conditional Access
1. Ensure a Conditional Access policy **requires a compliant device** (Conditional Access solution). A device exceeding the risk threshold becomes Not compliant and loses access.

## Step 8 — Validate the pilot
1. On a pilot device, run **`MDE-Discovery.ps1`** and **`MDE-Validation.ps1`** → confirm onboarded + sensor healthy.
2. Run **`MDE-ConnectorCheck.ps1`** → confirms the Intune↔MDE connector is Active.
3. Run **`MDE-TenantReport.ps1`** → confirms devices appear onboarded with a risk score. Complete the **Testing Guide**.

## Step 9 — Expand to production
1. Add a production group to the onboarding policy **Assignments**; roll out in waves.
2. Confirm risk-based compliance behaves as expected before broad Conditional Access enforcement.
3. Re-validate each wave with **`MDE-Validation.ps1`** / **`MDE-TenantReport.ps1`**.

---
### Order of operations
`Enable connector → Confirm in Intune → Pilot group → EDR onboarding policy → Assign → Risk into compliance → (CA require compliant) → Validate → Expand`


---


# 5. Testing Guide — Microsoft Defender for Endpoint Integration

Run after the pilot onboarding policy applies (Implementation Step 8) and after each production wave.

## Test 1 — Connector active
**Do:** Intune → **Endpoint security → Microsoft Defender for Endpoint**; or run `MDE-ConnectorCheck.ps1`.
**Expected:** Connection status **Active / Available**.

## Test 2 — Onboarding policy applied
**Do:** Intune → **Endpoint security → Endpoint detection and response →** policy → **Device status**.
**Expected:** Pilot devices show **Succeeded**.

## Test 3 — Device onboarded (local)
**Do:** On a pilot device run `MDE-Validation.ps1` (checks the Sense service + onboarding state).
**Expected:** Sense service **Running**; `OnboardingState = 1`.

## Test 4 — Device appears in the Defender portal
**Do:** `https://security.microsoft.com` → **Assets → Devices**.
**Expected:** The pilot device is listed with health **Active** and a risk level.

## Test 5 — Risk score feeds compliance
**Do:** Intune → device → **Compliance**; review the Defender risk requirement.
**Expected:** A device under the threshold is **Compliant**; a higher-risk device would be **Not compliant**.

## Test 6 — EDR detection (optional, safe simulation)
**Do:** Run Microsoft's official EDR detection test (from the Defender portal device page) on a test device.
**Expected:** An alert appears in the Defender portal, confirming EDR telemetry.

## Test 7 — Tenant report
**Do:** Run **`MDE-TenantReport.ps1`**.
**Expected:** Onboarded devices with health + risk score listed.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–5 pass for the pilot group |
| **Wave pass** | Tests 2–3, 5, 7 pass before the next wave |


---


# 6. Troubleshooting Guide — Microsoft Defender for Endpoint Integration

Use **`MDE-Validation.ps1`** / **`MDE-Discovery.ps1`** for local onboarding state and
**`MDE-ConnectorCheck.ps1`** for the connector, **`MDE-Remediation.ps1`** for safe fixes.

## A. Connector problems
| Symptom | Cause | Remediation |
|---|---|---|
| Connector "Unavailable" in Intune | Intune connection not turned on in Defender portal | Defender portal → **Settings → Endpoints → Advanced features → Microsoft Intune connection = On** |
| Connector active but no onboarding | No onboarding policy / wrong package type | Create the EDR onboarding policy with **Auto from connector** |

## B. Device not onboarding
| Symptom | Cause | Remediation |
|---|---|---|
| Policy "Succeeded" but device absent in Defender | Sensor not reporting yet, or network blocked | Run `MDE-Validation.ps1`; allow MDE URLs; reboot; wait for first check-in |
| `OnboardingState = 0` | Onboarding not applied | Sync policy (`MDE-Remediation.ps1`); confirm device in `MDE-Pilot` group |
| Sense service stopped | Service disabled/crashed | `MDE-Remediation.ps1` restarts Sense; check Event Viewer (SENSE) |

## C. Risk score not affecting compliance
- Compliance unchanged by risk → the compliance policy's Defender risk requirement isn't set, or the connector isn't active. Set **Require risk at or under <level>** in the compliance policy.
- Device risk "Unknown" → not yet onboarded/reporting; wait for first telemetry.

## D. Network / connectivity
- Sensor unhealthy → run the MDE connectivity analyzer; ensure MDE service URLs are allowed and **not SSL-inspected**.
- Proxy issues → configure the sensor proxy (static or WinHTTP) per Microsoft guidance.

## E. Diagnostics quick reference
```powershell
Get-Service Sense                                  # Defender for Endpoint sensor service
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows Advanced Threat Protection\Status'  # OnboardingState
Get-MpComputerStatus                               # Defender AV health
```
Sensor logs/connectivity: the **MDEClientAnalyzer** tool from Microsoft.

## F. When to escalate
If the device shows `OnboardingState = 1`, Sense is Running, and connectivity passes but the
device never appears in the Defender portal, capture the device ID and open a Microsoft Defender support case.


---


# 7. Best Practices — Microsoft Defender for Endpoint Integration

- **Enable the connector first.** Nothing onboards through Intune until the Defender↔Intune connection is On and Active.
- **Use Auto-from-connector onboarding.** Let the connector supply the onboarding blob — no manual scripts to manage at scale.
- **Pilot before fleet.** Confirm onboarding, sensor health, and portal visibility on a small group first.
- **Start the risk threshold at Medium.** It catches real risk without over-blocking; tighten to Low for sensitive scopes.
- **Layer compliance + Conditional Access.** The risk score only enforces access when wired into compliance and a CA "require compliant device" policy.
- **Don't SSL-inspect MDE traffic.** It breaks the sensor; exclude Defender URLs from inspection.
- **Watch sensor health.** Track onboarded/health/risk with `MDE-TenantReport.ps1`; chase inactive sensors.
- **Run the EDR detection test.** Validate telemetry end-to-end with Microsoft's official detection test on a pilot device.
- **Manage AV/ASR/firewall through Intune** once onboarded (companion solutions) for a single policy plane.
- **Document the risk policy.** Record the threshold and rationale for audits.


---


# 8. Deliverables Summary — Microsoft Defender for Endpoint Integration

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What the Intune ⇄ MDE integration is, how it works, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps across the Defender portal and Intune |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `MDE-Discovery.ps1` | Local onboarding readiness: Sense service, OS, network to MDE |
| `MDE-Validation.ps1` | Confirms the device is onboarded (OnboardingState=1) and the sensor is healthy |
| `MDE-TenantReport.ps1` | Tenant-wide onboarded devices with health + risk score (Microsoft Graph) |
| `MDE-Remediation.ps1` | Safe remediation; restarts Sense, forces sync, runs a quick scan |
| `MDE-ConnectorCheck.ps1` | Confirms the Intune ↔ Defender connector is Active (Microsoft Graph) |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the repeatable model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Full EDR coverage with automatic onboarding and a risk score that powers Zero Trust enforcement.
