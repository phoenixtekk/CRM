# Windows Autopilot

> **Version 1.0.0** · Category: Intune · Solution code: WAP

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Windows Autopilot (Microsoft Intune)

**White-label · Intune Solutions**

Manually imaging and configuring every new PC is slow, inconsistent, and requires a technician
to touch each device. **Windows Autopilot** replaces that with cloud-driven, zero-touch
provisioning: a new device is shipped straight to the user, who powers it on, signs in once, and
walks away with a fully managed, policy-compliant, app-loaded workstation.

This is a complete, **deploy-it-today** package for implementing Windows Autopilot with Microsoft
Intune, written for an administrator with no prior Autopilot experience. Every requirement is
verified before use, every step is exact and in order, and every result is testable.

## What you get
- A plain-language **Solution Overview** of how Autopilot works and when to use it.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite.
- An **Implementation Guide** of precise, click-by-click Intune steps in the required order.
- Five **PowerShell scripts** for hardware-hash collection, readiness discovery, validation, tenant reporting, and remediation.
- **Testing** and **Troubleshooting** guides for confident rollout.

## The model this delivers
**User-driven, Microsoft Entra–joined Autopilot** — the simplest, most repeatable deployment
mode: register device → assign deployment profile + Enrollment Status Page → user completes OOBE →
device auto-enrolls into Intune and applies policies and apps.

## The standard deployment model
Every Intune solution follows the same shape: **Assess → Configure → Pilot →
Validate → Expand.**

## Outcome
Zero-touch device provisioning — faster onboarding, consistent builds, and no technician
imaging — deployable by a single administrator and validated before fleet rollout.


---


# 1. Solution Overview — Windows Autopilot

## What Windows Autopilot is
Windows Autopilot is a cloud-driven service that provisions new (and reset) Windows devices into
a fully managed state with no manual imaging. The device registers itself to your tenant by its
hardware identity, receives a **deployment profile** from Intune, and configures itself during
the out-of-box experience (OOBE). The user signs in once and the device auto-enrolls into
Microsoft Entra ID and Intune, then applies your policies and apps.

## How it works
1. The device's **hardware hash** is registered as an Autopilot device (by OEM, CSV import, or `Get-WindowsAutopilotInfo`).
2. A dynamic Entra group collects Autopilot devices; an Intune **deployment profile** and **Enrollment Status Page (ESP)** are assigned to it.
3. The user powers on the new device, connects to the internet, and signs in with their work account.
4. OOBE applies the profile (branding, account type, skipped screens). The device **Entra-joins** and **MDM-enrolls** automatically.
5. The ESP tracks required policies/apps until the device is ready to use.

## Deployment modes (this solution standardizes on the first)
- **User-driven, Microsoft Entra joined** — the user drives OOBE; simplest and most common. **(Used here.)**
- Self-deploying (kiosk/shared, no user).
- Pre-provisioning ("white glove") for IT/partner staging.
- Autopilot Reset to return an existing device to a managed clean state.

## Benefits
- **Zero-touch** — ship devices straight to users; no technician imaging.
- **Consistent builds** — every device provisions identically from policy.
- **Faster onboarding** — ready in minutes, not hours.
- **Lower cost** — no imaging infrastructure or re-imaging labor.

## Limitations (be honest with buyers)
- Devices must be **registered** (hardware hash) before Autopilot applies.
- OOBE requires **internet** and reachable Entra/Intune endpoints.
- First-run app/policy delivery time depends on what you require in the ESP.
- Hybrid Entra join is supported but more complex (out of scope; this solution uses cloud Entra join).

## The standard deployment model
> **Register device → assign deployment profile + ESP to an Autopilot device group → user
> completes OOBE → device auto-enrolls → policies/apps apply.**
Every step follows the repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**


---


# 2. Requirements Guide — Windows Autopilot

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

## 2.1 Licensing
**Description:** Intune + Microsoft Entra ID P1 (or M365 E3/E5/Business Premium).
**Why:** Autopilot uses Intune for profiles/policy and Entra for join + automatic enrollment.
**Verify:** M365 admin center → **Billing → Licenses**.
**Implement:** Assign M365 E3/E5 or Business Premium to targeted users.

## 2.2 Automatic MDM enrollment
**Description:** Entra automatic enrollment scoped to your users.
**Why:** Autopilot relies on auto-enrollment to bring the device into Intune during OOBE.
**Verify:** Intune → **Devices → Enrollment → Automatic Enrollment** → MDM user scope = **All** (or a group).
**Implement:** Set MDM user scope to **All**; ensure MDM terms/discovery URLs are default.

## 2.3 Device registration (hardware hash)
**Description:** Each device's Autopilot hardware identity is uploaded to the tenant.
**Why:** Autopilot only applies to **registered** devices.
**Verify:** Intune → **Devices → Enrollment → Devices** (Windows Autopilot devices) — the device is listed.
**Implement:** Have the OEM/reseller register at purchase, or collect with **`Get-AutopilotHash.ps1`** and import the CSV.

## 2.4 Microsoft Entra company branding
**Description:** Company branding on the Entra sign-in experience.
**Why:** Confirms the user is signing into the right tenant during OOBE; required for a clean user-driven experience.
**Verify:** Entra → **Company branding**.
**Implement:** Entra → **Company branding → Customize** (add logo/text).

## 2.5 Windows operating system
**Description:** Windows 10 1809+ or Windows 11 (current build recommended).
**Why:** Autopilot OOBE features depend on a supported, patched Windows.
**Verify:** `winver`, or the device's factory image.
**Implement:** Use OEM Windows 10/11 Pro/Enterprise images.

## 2.6 Network (OOBE)
**Description:** Internet access during OOBE to Microsoft Autopilot/Entra/Intune endpoints.
**Why:** The device contacts the Autopilot service to fetch its profile.
**Verify:** A wired/Wi-Fi network reaches `https://login.microsoftonline.com` and the Autopilot endpoints.
**Implement:** Allow Microsoft 365/Autopilot URLs through proxy/firewall; provide OOBE network access (no 802.1X that blocks pre-logon, or use a provisioning network).

## 2.7 Certificates
**Description:** None required.
**Why (not):** Autopilot uses Entra identity + Intune policy.
**Implement:** N/A.

---
## Checklist
- [ ] Intune + Entra P1 licensing assigned
- [ ] Automatic MDM enrollment = All (or pilot group)
- [ ] Devices registered (hardware hash) — `Get-AutopilotHash.ps1`
- [ ] Entra company branding configured
- [ ] Windows 10 1809+/Windows 11
- [ ] OOBE network reaches Microsoft endpoints
- [ ] Pilot Entra group + dynamic Autopilot device group created


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


# 3. Implementation Guide — Windows Autopilot

Follow these steps **in order**. All navigation is in the **Microsoft Intune admin center**
(`https://intune.microsoft.com`) unless stated otherwise.

> **Model:** User-driven, Microsoft Entra–joined Autopilot, assigned to a dynamic device group.

## Step 1 — Enable automatic MDM enrollment
1. Go to **Devices → Enrollment → Automatic Enrollment**.
2. Set **MDM user scope** to **All** (or your pilot group). Click **Save**.

## Step 2 — Configure company branding
1. Open `https://entra.microsoft.com` → **Company branding → Customize** (or **Add**).
2. Add your logo, background, and sign-in text. **Save**.

## Step 3 — Register the pilot device(s)
1. Run **`Get-AutopilotHash.ps1`** on each pilot device to export its hardware hash CSV.
2. In Intune go to **Devices → Enrollment → Devices** (Windows Autopilot devices) → **Import** → upload the CSV.
3. Wait for the device to appear (Sync if needed).

## Step 4 — Create a dynamic Autopilot device group
1. Open `https://entra.microsoft.com` → **Groups → New group**.
2. **Type:** Security. **Name:** `Autopilot-Devices`. **Membership type:** Dynamic Device.
3. **Add dynamic query:** `(device.devicePhysicalIDs -any (_ -contains "[ZTDId]"))`. **Save**, then **Create**.

## Step 5 — Create the deployment profile
1. Go to **Devices → Enrollment → Deployment Profiles → Create profile → Windows PC**.
2. **Name:** `Autopilot - User-Driven`. Click **Next**.
3. **Deployment mode:** User-driven. **Join type:** Microsoft Entra joined.
4. **Out-of-box experience:** hide EULA, hide privacy settings, hide change account options = **Yes**; **User account type:** Standard. Click **Next**.
5. **Assignments → Add groups →** `Autopilot-Devices`. **Next → Create**.

## Step 6 — Create the Enrollment Status Page (ESP)
1. Go to **Devices → Enrollment → Enrollment Status Page → Create**.
2. **Name:** `Autopilot - ESP`. **Show app and profile installation progress:** Yes.
3. Keep required apps minimal for the pilot. **Assignments → Add groups →** `Autopilot-Devices`. **Create**.

## Step 7 — Provision a pilot device
1. Factory-reset or use a new device. Connect to the internet at OOBE.
2. The Autopilot branding appears; the user signs in with their work account.
3. The device Entra-joins, MDM-enrolls, and the ESP runs until ready.

## Step 8 — Validate the pilot
1. Run **`Autopilot-Validation.ps1`** → confirms the device is Autopilot-registered, Entra-joined, and Intune-enrolled.
2. Run **`Autopilot-TenantReport.ps1`** → confirms profile assignment status across devices.
3. Complete the **Testing Guide** (Section 5) before expanding.

## Step 9 — Expand to production
1. Register production devices (OEM registration at purchase is ideal at scale).
2. They join `Autopilot-Devices` automatically (dynamic group) and inherit the profile + ESP.
3. Re-validate each wave with **`Autopilot-Validation.ps1`** / **`Autopilot-TenantReport.ps1`**.

---
### Order of operations
`Auto-enrollment → Branding → Register devices → Dynamic group → Deployment profile → ESP → Provision → Validate → Expand`


---


# 5. Testing Guide — Windows Autopilot

Run after a pilot device completes OOBE (Implementation Step 8) and after each production wave.

## Test 1 — Profile assigned
**Do:** Intune → **Devices → Enrollment → Devices** → select the device → **Profile status**.
**Expected:** **Assigned** (not "Assigning"/"Not assigned").

## Test 2 — OOBE provisions end-to-end
**Do:** Power on the registered device, connect to the internet, sign in with a work account.
**Expected:** Autopilot branding shows; the device completes OOBE without manual configuration.

## Test 3 — Entra joined + Intune enrolled
**Do:** On the device run `dsregcmd /status`; in Intune check **Devices → All devices**.
**Expected:** `AzureAdJoined : YES`; the device is listed and **compliant** in Intune.

## Test 4 — Enrollment Status Page completes
**Do:** Watch the ESP during provisioning, or run `Autopilot-Validation.ps1` afterward.
**Expected:** ESP reaches "All done!"; required apps/policies installed.

## Test 5 — Policies and apps applied
**Do:** Intune → device → **Device configuration** / **Managed apps**.
**Expected:** Assigned policies show **Succeeded**; required apps installed.

## Test 6 — Compliance intact
**Do:** Intune → **Devices → Compliance**.
**Expected:** The device is **Compliant**.

## Test 7 — Tenant report
**Do:** Run **`Autopilot-TenantReport.ps1`**.
**Expected:** The device appears with profile **Assigned** and enrollment state OK.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–6 pass for 100% of pilot devices |
| **Wave pass** | Tests 1–5 pass for the wave before the next |


---


# 6. Troubleshooting Guide — Windows Autopilot

Use **`Autopilot-Validation.ps1`** to confirm state and **`Autopilot-Remediation.ps1`** for safe fixes.

## A. Device doesn't get the Autopilot experience
| Symptom | Cause | Remediation |
|---|---|---|
| OOBE looks generic (no branding) | Device not registered, or profile not assigned | Confirm the hardware hash is imported and **Profile status = Assigned**; re-image/reset and retry |
| Profile stuck "Assigning" | Dynamic group hasn't picked up the device | Wait for group processing; confirm the dynamic rule `[ZTDId]`; force a group refresh |
| Wrong tenant prompt | Company branding missing/incorrect | Configure Entra **Company branding** |

## B. OOBE / network failures
| Symptom | Cause | Remediation |
|---|---|---|
| "Something went wrong" at OOBE | No internet / blocked endpoints | Provide OOBE network; allow Autopilot/Entra/Intune URLs; avoid pre-logon 802.1X |
| Sign-in fails | Licensing or auto-enrollment not set | Confirm user license and **MDM user scope = All** |

## C. Enrollment Status Page issues
- **ESP times out** → too many/large required apps. Reduce required apps for the pilot; raise the timeout; mark non-critical apps as not blocking.
- **ESP blocks on a failing app** → fix or remove the failing required app from the ESP scope.

## D. Hardware hash / import
- **Import errors** → ensure the CSV is the unmodified `Get-AutopilotHash.ps1` output (correct columns); remove duplicates already registered.
- **Device not appearing** → Sync (**Devices → Enrollment → Devices → Sync**) and wait.

## E. Diagnostics quick reference
```powershell
dsregcmd /status                     # Entra join / MDM state
Get-WindowsAutopilotInfo -Online     # (admin) view/register this device's hash
```
OOBE diagnostics: press **Shift+F10** during OOBE for a command prompt; collect MDM diagnostics via **Settings → Accounts → Access work or school → Export**.

## F. When to escalate
If the device is registered, the profile shows **Assigned**, networking is open, and OOBE still
fails, collect the Autopilot/MDM diagnostic logs and open a Microsoft support case.


---


# 7. Best Practices — Windows Autopilot

- **Always pilot first.** Provision 2–3 devices end-to-end before fleet rollout.
- **Use a dynamic Autopilot device group.** Devices self-join on registration — no manual group management.
- **Keep the ESP minimal.** Only block on truly essential apps; large required-app sets cause timeouts and poor first-run experience.
- **Register at the source.** Have OEMs/resellers register devices at purchase so they're Autopilot-ready out of the box; use `Get-AutopilotHash.ps1` only for existing/one-off devices.
- **Configure company branding.** It reassures users they're joining the right tenant and looks professional.
- **Standard user accounts.** Set the OOBE user account type to Standard unless a role genuinely needs local admin.
- **Test the OOBE network.** Ensure the provisioning network has open internet and no pre-logon 802.1X that blocks Autopilot.
- **Use pre-provisioning for staging.** For IT-staged devices, "white glove" pre-provisioning front-loads app/policy install before handoff.
- **Document the process.** Record the registration method, profile settings, and ESP apps for repeatability and audits.


---


# 8. Deliverables Summary — Windows Autopilot

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What Autopilot is, how it works, modes, benefits, limitations, the deployment model |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered, click-by-click Intune steps |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `Get-AutopilotHash.ps1` | Collects the device hardware hash CSV for Autopilot registration |
| `Autopilot-Discovery.ps1` | Device readiness: OS, TPM, network, Entra state |
| `Autopilot-Validation.ps1` | Confirms Autopilot registration, Entra join, and Intune enrollment |
| `Autopilot-TenantReport.ps1` | Tenant-wide Autopilot device + profile status (Microsoft Graph) |
| `Autopilot-Remediation.ps1` | Safe remediation; re-sync and re-trigger enrollment |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the repeatable model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Zero-touch device provisioning — consistent builds, faster onboarding, and no technician imaging.
