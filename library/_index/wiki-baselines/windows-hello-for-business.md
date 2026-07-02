# Windows Hello for Business

> **Version 1.0.0** · Category: Intune · Solution code: WHFB

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Windows Hello for Business (Microsoft Intune)

**White-label · Intune Solutions**

Passwords are the single largest attack surface in most organizations. They are phished,
reused, sprayed, and stolen. **Windows Hello for Business (WHfB)** removes the password from
the sign-in equation entirely, replacing it with a strong, hardware-bound credential that
never leaves the device and is unlocked by a PIN or biometric.

This solution is a complete, **deploy-it-today** package for enabling Windows Hello for
Business on Microsoft Entra–joined Windows devices using Microsoft Intune. It is written for
an administrator with little or no prior WHfB experience: every requirement is verified before
it is used, every configuration step is exact and in order, and every result is testable.

## What you get
- A plain-language **Solution Overview** so you understand what you are turning on and why.
- A **Requirements Guide** that tells you exactly what must be true before you start — and how to fix anything that isn't.
- An **Implementation Guide** of precise, click-by-click Intune steps in the required order.
- Five **PowerShell scripts** for device readiness discovery, validation, tenant reporting, safe remediation, and (hybrid only) enabling Microsoft Entra Kerberos.
- A **Testing Guide** that proves the rollout worked.
- A **Troubleshooting Guide** for the issues that actually occur in the field.

## The standard deployment model
Every Intune solution follows the same shape: **Assess → Configure → Pilot →
Validate → Expand.** You will recognize this pattern in every solution you buy from us, so
each new deployment feels familiar and low-risk.

## Outcome
A measurable move toward **phishing-resistant, passwordless authentication** on your Windows
fleet — reduced help-desk password resets, stronger compliance posture, and a better sign-in
experience for users — achievable by a single administrator in a controlled pilot within a day.


---


# 1. Solution Overview — Windows Hello for Business

## What Windows Hello for Business is
Windows Hello for Business (WHfB) is a passwordless, two-factor authentication method built
into Windows 10 and Windows 11. It replaces the user's password with a credential made of two
parts:

1. **Something the user has** — a private cryptographic key bound to the specific device and
   protected by the device's **TPM** (Trusted Platform Module).
2. **Something the user is or knows** — a **biometric** (face or fingerprint) or a **PIN** that
   unlocks the key locally.

The PIN and biometric never travel across the network and are not stored centrally. They only
unlock the private key, which stays on the device hardware. There is no password to phish,
spray, or replay.

## How it works
1. When a user enrolls, Windows generates an asymmetric key pair. The **private key** is created
   inside the **TPM** and cannot be exported.
2. The **public key** is registered with Microsoft Entra ID against the user's account.
3. To sign in, the user presents their gesture (face/fingerprint/PIN). This unlocks the TPM,
   which signs an authentication request with the private key.
4. Microsoft Entra ID validates the signature against the registered public key and issues the
   sign-in token. Access to on-premises resources (hybrid) is brokered via **Microsoft Entra
   Kerberos** (Cloud Kerberos Trust).

Because the private key is hardware-bound and unlocked only locally, WHfB is **phishing-resistant**:
an attacker who tricks a user on a fake website gains nothing — there is no shared secret to steal.

## Authentication methods supported
- **PIN** — a device-local code (digits, optionally letters/symbols). Always available as the baseline.
- **Facial recognition** — requires a Windows Hello–compatible **infrared (IR) camera**.
- **Fingerprint** — requires a compatible fingerprint reader.

All three unlock the same underlying hardware-bound key; biometrics are a convenience layer over the PIN.

## Benefits
- **Phishing-resistant, passwordless** sign-in — removes the most-attacked credential.
- **Hardware-bound** — the credential is useless on any other device.
- **Fewer password resets** — lower help-desk cost.
- **Better user experience** — a glance or a tap instead of a typed password.
- **Compliance** — supports modern Zero Trust and passwordless mandates; integrates with Conditional Access.

## Limitations (be honest with buyers)
- Requires a **TPM** (2.0 strongly recommended) and modern Windows.
- Biometrics need supported hardware (IR camera / fingerprint reader); without it, users still get PIN.
- The credential is **per-device** — a user signing in on a new device enrolls again there.
- Hybrid (on-premises AD) access to file shares/printers requires **Microsoft Entra Kerberos** to be enabled.
- Shared/kiosk multi-user scenarios need extra planning (not covered by the base solution).

## The standard deployment model
This solution uses **one** model so the process is repeatable across our catalog:

> **Microsoft Entra–joined devices, managed by Intune, using Cloud Kerberos Trust.**

- **Cloud-only organizations:** WHfB works against Microsoft Entra ID with no on-premises components.
- **Hybrid organizations:** the same model applies; you additionally enable **Microsoft Entra
  Kerberos** once (a single script in this package) so WHfB users can reach on-premises resources.

This avoids the complexity of the legacy **Certificate Trust** model (no PKI, NDES, or
per-user certificates required). Every step follows the repeatable pattern:
**Assess → Configure → Pilot → Validate → Expand.**


---


# 2. Requirements Guide — Windows Hello for Business

Verify **every** requirement below before you configure anything. Each entry follows the same
pattern: **Description · Why required · How to verify · How to implement if missing.** Do not
assume any prerequisite already exists.

> Category-wide prerequisites (a tenant, an Intune subscription, MDM enrollment, etc.) are
> documented once in **`global-requirements-intune-solutions.md`**. This guide lists only what
> is specific to or especially important for WHfB.

---

## 2.1 Microsoft licensing
**Description:** Licenses that cover Intune device management and Microsoft Entra ID.
**Why required:** Intune delivers the WHfB policy; Entra ID stores the registered credential.
**How to verify:** Microsoft 365 admin center → **Billing → Licenses**. Confirm an Intune-bearing
plan (Intune Plan 1, Microsoft 365 E3/E5, or Business Premium) and at least Entra ID P1 if you
will gate access with Conditional Access.
**How to implement if missing:** Purchase/assign Microsoft 365 E3/E5 or Business Premium (Intune
included), or standalone Intune Plan 1, to every targeted user.

> **Note:** WHfB itself is a free Windows feature. Licensing is required for the *management*
> (Intune) and *identity* (Entra ID) layers, not for WHfB.

## 2.2 Microsoft Entra ID
**Description:** Devices must be **Microsoft Entra joined** (cloud) or **Microsoft Entra hybrid joined** (hybrid).
**Why required:** WHfB registers the public key against the device's Entra identity.
**How to verify:** On a device run `dsregcmd /status` → under **Device State**, `AzureAdJoined : YES`.
**How to implement if missing:** Cloud — join during OOBE or **Settings → Accounts → Access work or
school → Connect → Join this device to Microsoft Entra**. Hybrid — configure Entra Connect device
sync and the hybrid-join process.

## 2.3 Microsoft Intune (MDM)
**Description:** Targeted devices are enrolled in Intune.
**Why required:** Intune is how the WHfB policy reaches the device.
**How to verify:** Intune admin center → **Devices → All devices**; the device is listed and compliant.
For Entra-joined devices, MDM auto-enrollment should be on.
**How to implement if missing:** Entra admin center → **Devices → Device settings**, and Intune →
**Devices → Enrollment → Automatic Enrollment**: set **MDM user scope** to **All** (or a pilot group).

## 2.4 Windows operating system
**Description:** Windows 10 version 1709 or later; **Windows 11 recommended**.
**Why required:** WHfB and Cloud Kerberos Trust depend on modern Windows components.
**How to verify:** `winver` on the device, or Intune → device → **Hardware**. For Cloud Kerberos
Trust, use Windows 10 21H2+/Windows 11 21H2+ with current cumulative updates.
**How to implement if missing:** Patch via Windows Update / Update rings, or upgrade to Windows 11.

## 2.5 Hardware
**Description:** A business-class PC; optional biometric sensors.
**Why required:** WHfB binds keys to hardware; biometrics need specific sensors.
**How to verify:** For facial recognition confirm a **Windows Hello IR camera**; for fingerprint a
compatible reader (Device Manager → **Biometric devices**).
**How to implement if missing:** Users without biometric hardware still use a **PIN** — no blocker.
Add external IR cameras/fingerprint readers only where biometrics are desired.

## 2.6 TPM (Trusted Platform Module)
**Description:** A TPM chip, **version 2.0 recommended** (1.2 supported).
**Why required:** The TPM creates and protects the non-exportable private key. Without a TPM,
keys fall back to software protection (weaker) unless policy forbids it.
**How to verify:** Run `tpm.msc` → **Status: The TPM is ready for use**, and **Specification
Version 2.0**. Or `Get-Tpm` in PowerShell (`TpmPresent : True`, `TpmReady : True`).
**How to implement if missing:** Enable TPM in UEFI/BIOS (often labeled *PTT* on Intel, *fTPM* on
AMD). Replace hardware that has no TPM. The **WHfB-Discovery.ps1** script reports TPM status fleet-wide.

## 2.7 Cloud-only vs hybrid considerations
**Description:** Decide whether targeted devices are cloud-only or hybrid.
**Why required:** Hybrid devices need **Microsoft Entra Kerberos** to reach on-premises resources with WHfB.
**How to verify:** `dsregcmd /status` — cloud-only shows `AzureAdJoined : YES` and `DomainJoined : NO`;
hybrid shows both `YES`.
**How to implement if missing:** Cloud-only — nothing extra. Hybrid — run **Enable-EntraKerberos.ps1**
(in this package) once per domain to enable Microsoft Entra Kerberos (Cloud Kerberos Trust).

## 2.8 Network
**Description:** Outbound HTTPS to Microsoft Entra ID and Intune service endpoints; hybrid devices
need line-of-sight to a domain controller for Kerberos.
**Why required:** Enrollment and credential registration call cloud endpoints; hybrid resource
access requires DC connectivity.
**How to verify:** From a device, browse to `https://login.microsoftonline.com`; for hybrid run
`nltest /dsgetdc:<yourdomain>`.
**How to implement if missing:** Allow Microsoft 365/Entra/Intune endpoints through proxy/firewall
(Microsoft's published URL/IP list). Ensure VPN/network gives hybrid devices DC reachability.

## 2.9 Certificates
**Description:** None required for this solution.
**Why required (not):** We use **Cloud Kerberos Trust**, which does **not** require per-user
certificates, PKI, or NDES. This is deliberate — it removes the hardest part of legacy WHfB.
**How to verify:** N/A.
**How to implement if missing:** N/A. (Certificate Trust is explicitly out of scope.)

---

## Requirements checklist (use before configuring)
- [ ] Intune + Entra ID licensing assigned to pilot users
- [ ] Devices Microsoft Entra joined (or hybrid joined) — `dsregcmd /status`
- [ ] Devices enrolled in Intune and compliant
- [ ] Windows 10 21H2+/Windows 11 with current updates
- [ ] TPM present and ready (2.0) — `Get-Tpm` / `WHfB-Discovery.ps1`
- [ ] (Hybrid only) Microsoft Entra Kerberos enabled — `Enable-EntraKerberos.ps1`
- [ ] Network/proxy allows Microsoft cloud endpoints; hybrid has DC line-of-sight
- [ ] Pilot Entra security group created


---


# Global Requirements — Intune Solutions (category-level)

These requirements apply to **every** solution in the **Intune Solutions**
category. They are published once at the category level on the marketplace so individual
solution listings stay small. Confirm these are in place before deploying *any* Intune solution.

Each entry: **Description · Why required · How to verify · How to implement if missing.**

## G1. Microsoft Entra ID tenant
**Description:** An active Microsoft Entra ID (Azure AD) tenant.
**Why:** It is the identity backbone for every cloud and Intune-managed resource.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create a Microsoft 365/Azure subscription, which provisions a tenant.

## G2. Microsoft Intune subscription
**Description:** An Intune-bearing license plan.
**Why:** Intune delivers all configuration, compliance, and security policies.
**Verify:** `https://intune.microsoft.com` loads and **Tenant administration → Tenant status** shows an active subscription.
**Implement:** Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1.

## G3. Administrative roles
**Description:** Appropriate Entra/Intune admin roles for the operator.
**Why:** Creating policies and enrollment settings requires elevated rights.
**Verify:** Entra → **Roles and administrators**; confirm **Intune Administrator** (or Global Administrator for setup).
**Implement:** Assign **Intune Administrator** to the operator; reserve Global Administrator for tenant-wide changes.

## G4. Device enrollment in Intune
**Description:** Targeted Windows devices are enrolled and manageable.
**Why:** Policies only reach enrolled devices.
**Verify:** Intune → **Devices → All devices**; the device appears and is **compliant**.
**Implement:** Enable **Automatic Enrollment** (Intune → Devices → Enrollment) and join devices to Entra ID.

## G5. Pilot security group
**Description:** A Microsoft Entra security group for pilot/targeted users or devices.
**Why:** Every solution is piloted to a small group before fleet rollout.
**Verify:** Entra → **Groups**; the pilot group exists with intended members.
**Implement:** Entra → **Groups → New group** → type **Security** → add pilot members.

## G6. Supported Windows baseline
**Description:** Windows 10 21H2+ or Windows 11 with current cumulative updates.
**Why:** Modern Intune features and security settings assume a patched, supported OS.
**Verify:** `winver`, or Intune → device → **Hardware**.
**Implement:** Deploy **Update rings** (Intune → Devices → Windows → Update rings) or upgrade to Windows 11.

## G7. Network access to Microsoft cloud endpoints
**Description:** Outbound HTTPS to Microsoft 365, Entra, and Intune service URLs.
**Why:** Enrollment, policy sync, and authentication depend on these endpoints.
**Verify:** From a device, reach `https://login.microsoftonline.com` and `https://enrollment.manage.microsoft.com`.
**Implement:** Allow Microsoft's published Office 365/Intune URL & IP ranges through proxy/firewall.

---
**The standard deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


# 3. Implementation Guide — Windows Hello for Business

Follow these steps **in order**. Each step must be complete before the next. All navigation is
in the **Microsoft Intune admin center** (`https://intune.microsoft.com`) unless stated otherwise.

> **Model:** Microsoft Entra–joined devices, Intune-managed, Cloud Kerberos Trust.
> **Approach:** We leave the tenant-wide enrollment setting **off** and deploy WHfB as a
> **targeted Account protection policy** to a pilot group. This gives you precise control and a
> clean pilot → production path.

---

## Step 1 — Turn the tenant-wide WHfB enrollment setting to "Not configured"
This prevents an uncontrolled, everyone-at-once rollout so your targeted policy governs the pilot.

1. Go to **Devices → Windows → Windows enrollment**.
2. Click **Windows Hello for Business**.
3. Set **Configure Windows Hello for Business** to **Not configured**.
4. Click **Save**.

## Step 2 — Create the pilot security group
1. Open `https://entra.microsoft.com` → **Groups → All groups → New group**.
2. **Group type:** Security. **Group name:** `WHfB-Pilot`.
3. Add 3–5 pilot users (or devices) as **Members**.
4. Click **Create**.

## Step 3 — (Hybrid only) Enable Microsoft Entra Kerberos
Skip if you are cloud-only.

1. On an admin workstation with the on-premises AD module, run **`Enable-EntraKerberos.ps1`** (in this package), signing in with a Domain Administrator and a Global/Cloud Device Administrator.
2. Confirm the script reports the **Azure AD Kerberos server object** was created for your domain.

## Step 4 — Create the WHfB Account protection policy
1. Go to **Endpoint security → Account protection**.
2. Click **+ Create Policy**.
3. **Platform:** Windows. **Profile:** **Account protection** (Windows Hello for Business).
4. Click **Create**.
5. **Name:** `WHfB - Pilot - Entra Joined`. Click **Next**.

## Step 5 — Configure the WHfB settings
On the **Configuration settings** page, set:

1. **Configure Windows Hello for Business:** **Enabled**.
2. **Use a Trusted Platform Module (TPM):** **Yes** (required — blocks weak software keys).
3. **Minimum PIN length:** **6**.
4. **Maximum PIN length:** **127** (or your standard).
5. **Lowercase letters in PIN / Uppercase letters in PIN / Special characters:** **Not allowed** (PIN stays simple unless you require complexity).
6. **Enable enhanced anti-spoofing for facial features:** **Yes**.
7. **Use Windows Hello for Business certificates / Use security keys for sign-in:** leave **Not configured** (Cloud Kerberos Trust needs neither).
8. **Use cloud trust for on-premises authentication (Cloud Kerberos Trust):** **Enabled**.
9. Click **Next**.

## Step 6 — Configure scope tags (optional)
1. On **Scope tags**, add tags if your org uses them, else click **Next**.

## Step 7 — Assign to the pilot group
1. On **Assignments**, under **Included groups**, click **Add groups**.
2. Select **`WHfB-Pilot`**. Click **Select**.
3. Click **Next**.

## Step 8 — Review and create
1. On **Review + create**, confirm every setting.
2. Click **Create**.

## Step 9 — Configure PIN/biometric experience (already set above)
PIN policy and anti-spoofing were set in Step 5. No separate profile is needed for the base solution.
(If you require additional biometric controls, add a **Settings catalog** profile under
**Devices → Configuration → Create → Settings catalog** and search **"Windows Hello"**.)

## Step 10 — Sync and provision a pilot device
1. On a pilot device, open **Settings → Accounts → Access work or school**, select the account, click **Info**, then **Sync**.
2. Sign the user out and back in. At sign-in Windows prompts **"Set up a PIN"** — complete the WHfB enrollment.
3. (Biometric hardware) **Settings → Accounts → Sign-in options → Facial recognition / Fingerprint → Set up**.

## Step 11 — Validate the pilot
1. Run **`WHfB-Validation.ps1`** on the pilot device → confirm the WHfB credential is provisioned.
2. Run **`WHfB-TenantReport.ps1`** → confirm the pilot users show registered WHfB methods in the tenant.
3. Complete the **Testing Guide** (Section 5) before expanding.

## Step 12 — Expand to production
1. Once the pilot passes, edit the **`WHfB-Pilot`** group membership or create **`WHfB-Production`** and add it to the policy **Assignments**.
2. Roll out in waves (e.g. by department). Re-validate each wave with **`WHfB-Validation.ps1`** / **`WHfB-TenantReport.ps1`**.
3. Keep the tenant-wide enrollment setting **Not configured**; the targeted policy remains the single source of truth.

---
### Order of operations (summary)
`Tenant setting off → Pilot group → (Hybrid: Entra Kerberos) → Create policy → Settings → Assign → Provision device → Validate → Expand`


---


# 5. Testing Guide — Windows Hello for Business

Run these validations after the pilot is provisioned (Implementation Step 11) and again after
each production wave. Each test states **what to do** and the **expected result**. Do not expand
the rollout until every test passes for the pilot group.

## Test 1 — WHfB is enabled on the device
**Do:** On a pilot device run `dsregcmd /status`. Review the **NgcSet** value under SSO State.
**Expected:** `NgcSet : YES` (the Next Generation Credential — the WHfB key — is set).

## Test 2 — The policy applied
**Do:** Intune admin center → **Endpoint security → Account protection →** `WHfB - Pilot - Entra Joined` **→ Device/User check-in status**.
**Expected:** Pilot devices/users show **Succeeded**. No **Error** or **Conflict**.

## Test 3 — PIN enrollment works
**Do:** Sign out and sign in as a pilot user. When prompted, complete **Set up a PIN**.
**Expected:** The PIN is accepted (min length 6), and subsequent sign-ins accept the PIN with no password.

## Test 4 — Biometric enrollment works (if hardware present)
**Do:** **Settings → Accounts → Sign-in options → Facial recognition / Fingerprint → Set up.**
**Expected:** Enrollment completes; signing out and back in succeeds with face/fingerprint.

## Test 5 — Authentication succeeds (cloud)
**Do:** Lock the device (Win+L) and unlock with the PIN/biometric. Open a browser to `https://myapps.microsoft.com`.
**Expected:** Unlock succeeds and Microsoft 365 apps authenticate with no password prompt.

## Test 6 — On-premises resource access (hybrid only)
**Do:** From a WHfB-signed-in hybrid device, open a mapped **file share** and a **print queue** on-premises.
**Expected:** Access is granted without a credential prompt (Microsoft Entra Kerberos issued the ticket). Confirm with `klist` showing a TGT.

## Test 7 — Compliance remains intact
**Do:** Intune → **Devices → Compliance**; review the pilot devices after WHfB provisioning.
**Expected:** Devices remain **Compliant**; no new compliance failures were introduced.

## Test 8 — Tenant-wide registration report
**Do:** Run **`WHfB-TenantReport.ps1`** (Microsoft Graph).
**Expected:** Pilot users appear with **Windows Hello for Business** listed among their registered authentication methods.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–5 (and 6 if hybrid, 7–8) all pass for **100%** of the pilot group |
| **Wave pass** | Tests 1–3, 5, 7 pass for the wave before starting the next |

Record results in your change log. If any test fails, use the **Troubleshooting Guide** (Section 6)
and the **`WHfB-Remediation.ps1`** script before proceeding.


---


# 6. Troubleshooting Guide — Windows Hello for Business

Work top to bottom. Most field issues are an unsynced policy, a TPM that isn't ready, or a
hybrid device missing Microsoft Entra Kerberos. Use **`WHfB-Validation.ps1`** to confirm state
and **`WHfB-Remediation.ps1`** for the safe fixes.

## A. Common deployment issues
| Symptom | Likely cause | Remediation |
|---|---|---|
| Policy shows **Conflict** in Intune | The tenant-wide enrollment setting **and** the Account protection policy both configure WHfB | Set **Devices → Windows enrollment → Windows Hello for Business** to **Not configured**; keep only the targeted policy |
| Policy never reaches device | Device not synced / not enrolled | Run **`WHfB-Remediation.ps1`** (forces MDM sync); confirm device in **Devices → All devices** |
| Settings apply to nobody | Wrong assignment | Confirm the pilot group is under the policy's **Included groups** and users/devices are members |

## B. Enrollment failures
| Symptom | Cause | Remediation |
|---|---|---|
| No "Set up a PIN" prompt at sign-in | Policy not yet applied, or user already enrolled | Sync (**`WHfB-Remediation.ps1`**), then sign out/in; check `NgcSet : YES` via `dsregcmd /status` |
| "Something went wrong" during PIN setup | TPM not ready, or transient | Run **`WHfB-Discovery.ps1`** to confirm TPM ready; reboot; retry |
| Error code **0x801c03ed** | MFA not satisfied / registration blocked | Ensure the user has completed MFA registration; check Conditional Access isn't blocking device registration |

## C. PIN provisioning failures
- Confirm **Minimum PIN length** policy matches what the user is typing (this solution sets 6).
- If PIN setup loops, run **`WHfB-Remediation.ps1 -ResetContainer`** to clear the local Hello container, then sign out/in.
- Verify the user has a valid Intune + Entra license assigned.

## D. TPM issues
- **`Get-Tpm`** shows `TpmReady : False` → enable/clear TPM in UEFI (Intel **PTT** / AMD **fTPM**); allow it to initialize.
- TPM "in a reduced functionality state" → in `tpm.msc` choose **Clear TPM** (warns it will reset TPM-protected keys; coordinate with BitLocker — have the recovery key first).
- No TPM at all → policy requires TPM (we set **Use TPM: Yes**), so the device will not provision; remediate hardware or exclude the device.

## E. Policy conflicts
- Only **one** WHfB source should be authoritative. Do not mix the tenant-wide enrollment setting, a legacy GPO, and the Intune Account protection policy.
- Legacy on-prem **GPO** "Use Windows Hello for Business" can override Intune on hybrid devices — disable the GPO or scope it away from Intune-managed devices.

## F. Hybrid identity issues (Cloud Kerberos Trust)
| Symptom | Cause | Remediation |
|---|---|---|
| WHfB sign-in works, but **on-prem shares/printers prompt** or fail | Microsoft Entra Kerberos not enabled for the domain | Run **`Enable-EntraKerberos.ps1`** once per domain; confirm with `Get-AzureADKerberosServer` |
| `klist` shows no TGT after resource access | Device has no line-of-sight to a DC | Connect to corporate network/VPN; verify `nltest /dsgetdc:<domain>` |
| Cloud Kerberos Trust setting not applied | Policy/OS build too old | Ensure Win10 21H2+/Win11 with current updates and the **Cloud Kerberos Trust** setting **Enabled** |

## G. Diagnostics quick reference
```powershell
dsregcmd /status            # Device State + NgcSet (WHfB key) + SSO state
Get-Tpm                     # TPM presence/readiness
certutil -deletehellocontainer   # clear local Hello container (forces re-enroll)
klist                       # Kerberos tickets (hybrid)
```
Event logs: **Applications and Services Logs → Microsoft → Windows → User Device Registration**
and **… → HelloForBusiness**.

## H. When to escalate
If a device passes **`WHfB-Discovery.ps1`** (TPM ready, supported OS, Entra joined), the policy
shows **Succeeded**, and enrollment still fails after a container reset, collect the
**HelloForBusiness** and **User Device Registration** event logs and open a Microsoft support case.


---


# 7. Best Practices — Windows Hello for Business

- **Always pilot first.** Deploy to `WHfB-Pilot` (3–5 users), validate fully, then expand in waves. Never flip a tenant-wide switch on day one.
- **One authoritative source.** Govern WHfB only through the Intune Account protection policy. Keep the tenant-wide enrollment setting **Not configured** and retire legacy GPOs.
- **Require the TPM.** Keep **Use TPM: Yes** so credentials are always hardware-bound; exclude (don't downgrade) devices without a TPM.
- **Prefer Cloud Kerberos Trust.** It avoids PKI/NDES and per-user certificates — fewer moving parts, fewer failures. Reserve Certificate Trust for narrow legacy cases (out of scope here).
- **Standardize the PIN policy.** A 6-digit minimum balances security and usability; only add complexity where a compliance mandate requires it.
- **Pair with Conditional Access.** Once WHfB is broad, use Conditional Access to require phishing-resistant authentication for sensitive apps, completing the passwordless story.
- **Coordinate with BitLocker.** Any TPM clear/reset affects BitLocker — always have the BitLocker recovery key before touching the TPM.
- **Measure coverage.** Run **`WHfB-TenantReport.ps1`** on a schedule to track registration percentage and catch stalled users.
- **Document each wave.** Record which group, which date, and validation results in your change log for auditability.
- **Communicate to users.** A one-paragraph heads-up ("you'll be asked to set up a PIN — here's why") dramatically reduces help-desk tickets.
- **Keep Windows current.** WHfB and Cloud Kerberos Trust depend on recent cumulative updates; enforce Update rings.


---


# 8. Deliverables Summary — Windows Hello for Business

Everything included in this solution package.

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What WHfB is, how it works, benefits, limitations, the deployment model |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered, click-by-click Intune steps |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `WHfB-Discovery.ps1` | Device readiness: OS, TPM, Entra join, biometrics |
| `WHfB-Validation.ps1` | Confirms WHfB is provisioned for the signed-in user |
| `WHfB-TenantReport.ps1` | Tenant-wide WHfB registration coverage (Microsoft Graph) |
| `WHfB-Remediation.ps1` | Safe remediation; `-ResetContainer` forces clean re-enrollment |
| `Enable-EntraKerberos.ps1` | Hybrid only — enables Microsoft Entra Kerberos (Cloud Kerberos Trust) |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process that follows the repeatable model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Phishing-resistant, passwordless sign-in on Microsoft Entra–joined Windows devices, deployable
by a single administrator, validated before every expansion.
