# BitLocker Drive Encryption

> **Version 1.0.0** · Category: Intune · Solution code: BITLK

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — BitLocker Drive Encryption (Microsoft Intune)

**White-label · Intune Solutions**

A laptop left in a taxi is only a breach if its drive is readable. **BitLocker** encrypts the
whole disk so a lost or stolen device exposes nothing — and managed through Microsoft Intune, it
turns on **silently** on TPM-equipped devices, with every **recovery key escrowed to Microsoft
Entra ID** so the help desk can always recover access.

This is a complete, **deploy-it-today** package for implementing BitLocker Drive Encryption with
Microsoft Intune, written for an administrator with no prior BitLocker-management experience.

## What you get
- A plain-language **Solution Overview** of how Intune-managed BitLocker works.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite.
- An **Implementation Guide** of precise, click-by-click Intune steps in the required order.
- Five **PowerShell scripts** for readiness discovery, encryption validation, tenant reporting, remediation, and recovery-key retrieval.
- **Testing** and **Troubleshooting** guides for confident rollout.

## What this delivers
An Intune **disk encryption policy** that requires **XTS-AES 256** encryption of the OS (and
fixed) drives, **silently** on TPM devices, with **recovery keys automatically saved to Entra ID**
and full encryption reporting.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Fleet-wide full-disk encryption with escrowed recovery keys — device-loss data protection and a
compliance cornerstone — deployable by a single administrator and validated before rollout.


---


# 1. Solution Overview — BitLocker Drive Encryption

## What BitLocker is
BitLocker is the full-volume encryption built into Windows. It encrypts the operating-system
drive (and optionally fixed data drives) so the data is unreadable without the correct key.
Managed through Microsoft Intune, encryption is enforced by policy, enabled **silently** on
devices with a TPM, and every **recovery key is escrowed to Microsoft Entra ID**.

## How it works
1. An Intune **disk encryption policy** defines the encryption requirements (method, drives, protectors).
2. On a targeted device, BitLocker enables — **silently** when a TPM is present and the user has no action to take.
3. The OS drive is protected by the **TPM** (optionally plus a startup PIN); the encryption uses **XTS-AES 256**.
4. The **recovery key is automatically backed up to Entra ID**, visible to admins in Intune (device → Recovery keys) and Entra (device → BitLocker keys).
5. Intune reports each device's encryption status for compliance and audits.

## What you can require
- **OS drive** encryption with TPM protector (and optional startup PIN), XTS-AES 256.
- **Fixed data drive** encryption with auto-unlock.
- **Recovery options** — store recovery key in Entra ID, hide recovery options from the user, client-driven recovery password rotation.
- **Silent enablement** for standard users on TPM devices.

## Benefits
- **Device-loss protection** — a lost/stolen device exposes no readable data.
- **Silent and zero-touch** — no user action on TPM hardware.
- **Always recoverable** — keys escrowed to Entra ID; the help desk can recover access.
- **Compliance cornerstone** — satisfies "require encryption" in device compliance.

## Limitations (be honest with buyers)
- **Silent** enablement requires a **TPM** and a supported, properly configured device.
- Devices without a TPM can encrypt but require a startup PIN/USB key (not silent).
- The first full encryption takes time (used-space-only is faster); plan pilot timing.
- Self-encrypting drives / certain firmware quirks may need hardware-specific handling.

## The standard deployment model
> **Create the disk encryption policy → require XTS-AES 256 + Entra key escrow + silent enablement
> → assign to a pilot → validate encryption + key escrow → expand.** repeatable pattern:
> **Assess → Configure → Pilot → Validate → Expand.**


---


# 2. Requirements Guide — BitLocker Drive Encryption

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

## 2.1 Licensing
**Description:** Intune (Plan 1); BitLocker is a Windows feature (no separate license).
**Why:** Intune delivers and reports the disk encryption policy.
**Verify:** M365 admin center → **Billing → Licenses**.
**Implement:** Assign M365 E3/E5 or Business Premium (Intune included).

## 2.2 Windows edition
**Description:** Windows 10/11 **Pro, Enterprise, or Education**.
**Why:** BitLocker is not available on Windows Home.
**Verify:** `winver` / **Settings → System → About → Edition**.
**Implement:** Upgrade Home editions to Pro/Enterprise.

## 2.3 TPM (for silent enablement)
**Description:** TPM 1.2+ (2.0 recommended), enabled in UEFI.
**Why:** Silent BitLocker enablement and the strongest protection require a TPM.
**Verify:** `Get-Tpm` (`TpmPresent : True`, `TpmReady : True`); or run **`BITLK-Discovery.ps1`**.
**Implement:** Enable TPM/PTT/fTPM in UEFI. Devices without TPM can still encrypt with a startup PIN/USB key (not silent).

## 2.4 UEFI / Secure Boot (recommended)
**Description:** UEFI firmware with Secure Boot.
**Why:** Modern boot integrity improves BitLocker protection and pairs with health attestation.
**Verify:** `Confirm-SecureBootUEFI`.
**Implement:** Switch firmware to UEFI and enable Secure Boot (may require reinstall if legacy BIOS/MBR).

## 2.5 Microsoft Entra ID (key escrow)
**Description:** Devices Microsoft Entra joined (or hybrid joined).
**Why:** Recovery keys are escrowed to the device's Entra object.
**Verify:** `dsregcmd /status` → `AzureAdJoined : YES`.
**Implement:** Join devices to Microsoft Entra.

## 2.6 Device enrollment
**Description:** Devices enrolled in Intune.
**Why:** The policy and reporting require enrollment.
**Verify:** Intune → **Devices → All devices**.
**Implement:** Enable automatic enrollment; enroll devices.

---
## Checklist
- [ ] Intune licensing assigned
- [ ] Windows Pro/Enterprise/Education
- [ ] TPM present + ready (for silent) — `BITLK-Discovery.ps1`
- [ ] UEFI + Secure Boot (recommended)
- [ ] Devices Microsoft Entra joined (key escrow)
- [ ] Devices enrolled in Intune
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


# 3. Implementation Guide — BitLocker Drive Encryption

Follow these steps **in order**, in the **Microsoft Intune admin center** (`https://intune.microsoft.com`).

> **Model:** A disk encryption policy requiring XTS-AES 256, Entra key escrow, and silent
> enablement, assigned to a pilot group.

## Step 1 — Create the pilot group
1. Entra → **Groups → New group** → Security → `BitLocker-Pilot` → add pilot devices/users. **Create**.

## Step 2 — Create the disk encryption policy
1. Intune → **Endpoint security → Disk encryption → Create policy**.
2. **Platform:** Windows. **Profile:** **BitLocker**. **Create**.
3. **Name:** `BitLocker - Pilot`. **Next**.

## Step 3 — Configure BitLocker settings
On **Configuration settings**:
1. **BitLocker – Base Settings**
   - **Enable full disk encryption for OS and fixed data drives** = **Yes**.
   - **Require storage cards to be encrypted (mobile only)** = not applicable.
   - **Hide prompt about third-party encryption** = **Yes**.
   - **Allow standard users to enable encryption during Autopilot** = **Yes**.
   - **Configure client-driven recovery password rotation** = **Enabled for Microsoft Entra joined devices**.
2. **BitLocker – Fixed Drive Settings**
   - **Fixed drive recovery** = **Configure** → **Save BitLocker recovery information to Microsoft Entra ID** = **Yes**; **Store recovery information before enabling** = **Yes**.
   - **Block write access to fixed drives not protected by BitLocker** = optional.
3. **BitLocker – OS Drive Settings**
   - **Encryption for OS drives** = **Require**.
   - **BitLocker with non-compatible TPM chip** = block (or allow PIN if you support non-TPM).
   - **OS drive recovery** = **Configure** → **Save BitLocker recovery information to Microsoft Entra ID** = **Yes**; **Store recovery information before enabling** = **Yes**; **Hide recovery options during BitLocker setup** = **Yes**.
   - **Encryption method** = **XTS-AES 256-bit**.
4. **BitLocker – Removable Drive Settings** = as required. Click **Next**.

## Step 4 — Assign to the pilot group
1. **Assignments → Add groups →** `BitLocker-Pilot`. **Next → Create**.

## Step 5 — Apply on a pilot device
1. On a pilot device, sync policy (**Settings → Accounts → Access work or school → Info → Sync**).
2. On TPM devices encryption begins **silently**; otherwise the user is prompted for a startup PIN.

## Step 6 — Validate the pilot
1. Run **`BITLK-Validation.ps1`** → confirms the OS drive is encrypting/encrypted with the right method and a recovery protector exists.
2. In Intune → device → **Recovery keys**, confirm the **recovery key is escrowed**.
3. Run **`BITLK-TenantReport.ps1`** → confirms encryption status across the pilot group. Complete the **Testing Guide**.

## Step 7 — Expand to production
1. Add a production group to the policy **Assignments**; roll out in waves.
2. Confirm key escrow for each wave (a device that encrypts without an escrowed key is a recovery risk).
3. Re-validate with **`BITLK-Validation.ps1`** / **`BITLK-TenantReport.ps1`**.

---
### Order of operations
`Pilot group → Disk encryption policy → Base/Fixed/OS settings (XTS-AES 256 + Entra escrow + silent) → Assign → Apply → Validate encryption + escrow → Expand`


---


# 5. Testing Guide — BitLocker Drive Encryption

Run after the pilot policy applies (Implementation Step 6) and after each production wave.

## Test 1 — Policy applied
**Do:** Intune → **Endpoint security → Disk encryption →** `BitLocker - Pilot` **→ Device status**.
**Expected:** Pilot devices show **Succeeded** (no Error).

## Test 2 — OS drive is encrypted
**Do:** On a pilot device run `BITLK-Validation.ps1` or `manage-bde -status`.
**Expected:** OS drive **Protection On**, **Percentage Encrypted = 100%**, **Encryption Method = XTS-AES 256**.

## Test 3 — Silent enablement (TPM devices)
**Do:** Observe a TPM device after policy sync — no user prompt.
**Expected:** Encryption begins automatically with no user interaction.

## Test 4 — Recovery key escrowed to Entra
**Do:** Intune → device → **Recovery keys** (or Entra → device → **BitLocker keys**).
**Expected:** A recovery key is present for the device.

## Test 5 — Recovery key retrieval works
**Do:** Run **`BITLK-Get-RecoveryKey.ps1 -DeviceName <name>`** (Graph).
**Expected:** The recovery password is returned for an authorized admin.

## Test 6 — Compliance reflects encryption
**Do:** Intune → device → **Compliance** (with a "require encryption" compliance rule).
**Expected:** The encrypted device is **Compliant** for the encryption requirement.

## Test 7 — Tenant report
**Do:** Run **`BITLK-TenantReport.ps1`**.
**Expected:** A breakdown of encrypted / encrypting / not-encrypted devices.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–5 pass for the pilot group (escrow confirmed for every device) |
| **Wave pass** | Tests 2, 4, 7 pass before the next wave |


---


# 6. Troubleshooting Guide — BitLocker Drive Encryption

Use **`BITLK-Validation.ps1`** / **`BITLK-Discovery.ps1`** for device state and
**`BITLK-Remediation.ps1`** for safe fixes.

## A. Encryption doesn't start
| Symptom | Cause | Remediation |
|---|---|---|
| Policy "Succeeded" but not encrypting | No TPM, or TPM not ready | Run `BITLK-Discovery.ps1`; enable TPM in UEFI; for non-TPM, configure a startup PIN |
| "Encryptable volume" error | Secure Boot/UEFI or pre-provisioning state | Ensure UEFI + Secure Boot; reboot; re-sync policy |
| Standard user can't enable | "Allow standard users to enable during Autopilot" not set | Enable that base setting |

## B. Recovery key not escrowed (critical)
| Symptom | Cause | Remediation |
|---|---|---|
| Encrypted but no key in Entra | "Store recovery info before enabling" off, or device not Entra joined | Set escrow-before-enable; confirm `AzureAdJoined : YES`; run `BITLK-Remediation.ps1` to back up the key |
| Key missing for older devices | Encrypted before policy | `BITLK-Remediation.ps1` backs up the existing recovery password to Entra |

## C. Wrong encryption method
- Device shows AES-128 / different method → it was encrypted before the policy. Decrypt and re-encrypt with XTS-AES 256, or accept per risk; new devices follow the policy.

## D. TPM problems
- `Get-Tpm` shows not ready → enable/clear TPM in UEFI (coordinate: clearing TPM affects existing keys — have the recovery key first).
- TPM "reduced functionality" → clear via `tpm.msc` (with recovery key in hand).

## E. Diagnostics quick reference
```powershell
manage-bde -status                       # encryption %, method, protection state
(Get-BitLockerVolume -MountPoint C:).KeyProtector   # protectors (TPM, RecoveryPassword)
Get-Tpm                                  # TPM readiness
manage-bde -protectors -get C:           # view recovery password ID
```
Back up an existing key to Entra: `BackupToAAD-BitLockerKeyProtector -MountPoint C: -KeyProtectorId <id>`.

## F. When to escalate
If a device has a TPM ready, is Entra joined, the policy shows Succeeded, and encryption still
won't start or the key won't escrow after remediation, collect `manage-bde -status` output and the
BitLocker event logs and open a Microsoft support case.


---


# 7. Best Practices — BitLocker Drive Encryption

- **Escrow the key before enabling.** Always set "Store recovery information before enabling" — a device that encrypts without an escrowed key is a recovery disaster waiting to happen.
- **Pilot first.** Confirm silent enablement and key escrow on a small group before fleet rollout.
- **Require XTS-AES 256.** The modern, strong method for fixed internal drives.
- **Prefer silent enablement on TPM devices.** No user friction; reserve startup PINs for high-security scopes or non-TPM hardware.
- **Enable client-driven key rotation** for Entra-joined devices so recovery passwords refresh after use.
- **Pair with compliance.** Use a "require encryption" compliance rule so unencrypted devices are flagged (and blocked via Conditional Access).
- **Mind the TPM before clearing it.** Clearing/resetting a TPM can invalidate keys — always have the recovery key first.
- **Encrypt fixed data drives too**, with auto-unlock, for full coverage.
- **Report continuously.** Track encryption coverage and escrow with `BITLK-TenantReport.ps1`.
- **Document recovery procedure.** Make sure the help desk knows how to retrieve a recovery key (`BITLK-Get-RecoveryKey.ps1` / Intune device → Recovery keys).


---


# 8. Deliverables Summary — BitLocker Drive Encryption

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What Intune-managed BitLocker is, how it works, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered, click-by-click Intune steps |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `BITLK-Discovery.ps1` | Readiness: TPM, Windows edition, UEFI/Secure Boot, current encryption state |
| `BITLK-Validation.ps1` | Confirms the OS drive is encrypted (XTS-AES 256) with a recovery protector |
| `BITLK-TenantReport.ps1` | Tenant-wide encryption status + recovery-key presence (Microsoft Graph) |
| `BITLK-Remediation.ps1` | Safe remediation; enables encryption and backs up the recovery key to Entra |
| `BITLK-Get-RecoveryKey.ps1` | Retrieves a device's BitLocker recovery key for authorized admins (Microsoft Graph) |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the repeatable model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Fleet-wide full-disk encryption with escrowed recovery keys — device-loss protection and a compliance cornerstone.
