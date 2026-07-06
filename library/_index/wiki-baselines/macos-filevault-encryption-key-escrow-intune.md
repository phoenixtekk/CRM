# FileVault Full-Disk Encryption & Key Escrow/Recovery for macOS (Intune)

> **Version 1.0.0** · Category: Intune · Solution code: MACFV

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — FileVault Full-Disk Encryption & Key Escrow for macOS (Microsoft Intune)

**White-label · Intune Solutions**

A MacBook left in a taxi is only a breach if its drive is readable. **FileVault** encrypts the
whole disk so a lost or stolen Mac exposes nothing — but only if it is **enforced, escrowed, and
recoverable**. Managed through Microsoft Intune, this solution turns FileVault on by policy,
**escrows every personal recovery key to Intune** (and rotates it), and handles the **SecureToken /
bootstrap-token** enablement that FileVault depends on — so data is protected and the help desk can
always recover a locked-out Mac.

This is a complete, **deploy-it-today** package for implementing FileVault encryption and
recovery-key escrow with Microsoft Intune, written for an administrator with no prior FileVault- or
SecureToken-management experience.

## What you get
- A plain-language **Solution Overview** of how FileVault + SecureToken work on Apple Silicon/T2, personal vs institutional recovery keys, Intune escrow, and the recovery model.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite (enrollment, disk-encryption policy, SecureToken/bootstrap token, Entra groups, a pilot).
- An **Implementation Guide** of precise, click-by-click Intune steps in the required order.
- Five **PowerShell scripts** for readiness discovery, per-device validation, fleet + recovery-key reporting, safe remediation, and pilot/target group building.
- **Testing** and **Troubleshooting** guides for confident rollout, plus **Best Practices** for key rotation and recovery.

## What this delivers
An Intune **FileVault disk-encryption policy** that enables FileVault on the target Macs, **escrows
the personal recovery key to Intune**, **hides the key from the user**, and **rotates** it — with
full encryption reporting and a proven recovery workflow.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Fleet-wide FileVault encryption with escrowed, rotatable recovery keys — device-loss data
protection and a compliance cornerstone — deployable by a single administrator and validated before
rollout.


---


# 1. Solution Overview — FileVault Full-Disk Encryption & Key Escrow for macOS (Microsoft Intune)

## What FileVault is
FileVault is Apple's built-in full-disk (whole-volume) encryption for macOS. When enabled, the
data on the Mac's internal drive is encrypted with **XTS-AES 128** and is unreadable without a
credential that can unlock it. Managed through Microsoft Intune, FileVault is **enforced by
policy**, and every **personal recovery key is escrowed to Intune** so an authorized admin can
recover a locked-out Mac.

## How it works on modern Macs (Apple Silicon and Intel T2)
On **Apple Silicon** Macs and **Intel Macs with the Apple T2 Security Chip**, the internal storage
is *always* hardware-encrypted at the controller level. FileVault adds the crucial second layer:
it ties decryption of the volume to a **user credential**, so the data is not readable simply by
having the hardware. Turning FileVault on is therefore what makes the built-in encryption
meaningful for device-loss protection — without it, the drive can be unlocked without a password.

FileVault depends on a macOS feature called **SecureToken**:

1. A **SecureToken** is a wrapped cryptographic key granted to a user account. Only a user who
   holds a SecureToken can be enabled for FileVault (added to the list of users allowed to unlock
   the disk at boot).
2. On **Automated Device Enrollment (ADE/DEP)** Macs, Intune deploys a **bootstrap token** — a
   token escrowed to MDM that lets the management channel grant SecureToken to accounts (including
   mobile/Entra accounts) without an existing SecureToken admin present. **This is why the bootstrap
   token matters: without it, a freshly provisioned ADE Mac may have no SecureToken user, and
   FileVault cannot be enabled.**
3. With a SecureToken-enabled user present, the Intune **FileVault disk-encryption policy** turns
   FileVault on. On next login the user is prompted (or, where supported, enablement is deferred to
   the next sign-in) and encryption begins.

## Personal vs institutional recovery keys
FileVault supports two recovery-key models. Intune uses the **personal recovery key** model:

- **Personal recovery key (what Intune manages):** a unique 24-character key is generated **per
  device** during enablement and **escrowed to Intune**. It is visible to admins in the Intune
  admin center under the device's **Recovery keys**, and retrievable through Microsoft Graph. Intune
  can also **rotate** the personal recovery key after it has been used or on a schedule.
- **Institutional recovery key:** a single organization-wide key backed by a certificate/keychain
  that unlocks any Mac. Intune's FileVault profile is built around the **personal** key model;
  institutional keys are a legacy, higher-risk pattern (one key unlocks the whole fleet) and are not
  the recommended Intune approach. This solution uses **personal keys escrowed and rotated by
  Intune**.

## The recovery model
When a user forgets their password or a Mac is locked out:

1. The admin looks up the device in Intune → device → **Recovery keys** (or retrieves it through
   Microsoft Graph — see `MACFV-Report.ps1`).
2. At the FileVault login/recovery screen, the personal recovery key unlocks the volume.
3. The user resets their password; Intune **rotates** the personal recovery key so the used key is
   retired and a fresh one is escrowed.

## What you can require through Intune
- **Enable FileVault** on the target Macs (disk-encryption policy, platform macOS, profile
  **FileVault**).
- **Escrow the personal recovery key to Intune** and **hide the recovery key from the user**.
- **Rotate** the personal recovery key (after use / on a schedule).
- **Defer enablement** until the user next logs out/in, with an optional prompt limit.
- Deploy the **bootstrap token** (via ADE enrollment) so SecureToken can be granted.

## Benefits
- **Device-loss protection** — a lost or stolen Mac exposes no readable data.
- **Always recoverable** — personal keys escrowed to Intune; the help desk can always unlock a Mac.
- **Rotatable keys** — a used recovery key can be retired automatically.
- **Compliance cornerstone** — satisfies "require encryption" in device compliance / Conditional Access.

## Limitations (be honest with buyers)
- **FileVault needs a SecureToken-enabled user.** On non-ADE (manually enrolled) Macs there may be
  no bootstrap token, so SecureToken must be granted by an existing SecureToken user — plan for this.
- **Enablement often requires the user to sign in** (FileVault is enabled at login on the personal
  key model); it is not always fully silent.
- The **first full encryption takes time**; plan pilot timing.
- FileVault's encryption method is **XTS-AES 128** (Apple's implementation) — this is expected and
  is not the same knob as Windows BitLocker's selectable method.

## The standard deployment model
> **Confirm SecureToken/bootstrap-token → create the FileVault disk-encryption policy (escrow +
> rotate) → assign to a pilot → validate encryption + key escrow + recovery → expand.** The
> repeatable pattern is: **Assess → Configure → Pilot → Validate → Expand.**


---


# 2. Requirements Guide — FileVault Full-Disk Encryption & Key Escrow for macOS (Microsoft Intune)

Verify **every** requirement before configuring. Each entry: **Description · Why required · How to
verify · How to implement if missing.** Category-wide prerequisites are in
`global-requirements-intune-solutions.md`.

Object names used throughout this solution (reuse them verbatim in Intune):
- Disk-encryption policy: `FileVault – Pilot` (and later `FileVault – Production`)
- Pilot device group: `FileVault – Pilot Devices`
- Production device group: `FileVault – Production Devices`
- (If used) macOS enrollment profile / bootstrap-token source: your Automated Device Enrollment profile

## 2.1 Intune licensing
**Description:** An Intune-bearing license (Plan 1 is sufficient for the macOS disk-encryption policy).
**Why required:** Intune delivers the FileVault disk-encryption policy, escrows the recovery key, and reports encryption status.
**How to verify:** Microsoft 365 admin center → **Billing → Licenses**.
**How to implement if missing:** Assign M365 E3/E5 or Business Premium (Intune included), or standalone Intune Plan 1.

## 2.2 Apple MDM Push (APNs) certificate
**Description:** A valid Apple Push Notification service (APNs) certificate configured in Intune.
**Why required:** No Apple device — including a Mac — can be managed by Intune without an APNs certificate; no policy reaches the Mac until it exists.
**How to verify:** Intune → **Devices → Enrollment → Apple → Apple MDM Push certificate**; confirm it is present and **not expired**. Run `MACFV-Discovery.ps1`.
**How to implement if missing:** Intune → **Devices → Enrollment → Apple → Apple MDM Push certificate → download the CSR**, create the certificate at `https://identity.apple.com` with a long-lived Apple ID, upload it back, and record the renewal date.

## 2.3 macOS enrollment configured (and enrolled Macs)
**Description:** A working macOS enrollment method so target Macs are enrolled and manageable — Automated Device Enrollment (ADE/DEP), Account-driven enrollment, or Company Portal.
**Why required:** The FileVault policy and its escrow/reporting apply only to enrolled Macs.
**How to verify:** Intune → **Devices → macOS → macOS devices**; the Mac appears as managed. Run `MACFV-Discovery.ps1`.
**How to implement if missing:** Configure **Automated Device Enrollment** (Apple Business/School Manager token + an enrollment profile) for corporate Macs, or **Account-driven**/Company Portal enrollment for user-owned Macs; then enrol the devices.

## 2.4 Supported hardware — Apple Silicon or Intel T2
**Description:** Target Macs are **Apple Silicon** or **Intel Macs with the Apple T2 Security Chip** (older Intel Macs still support FileVault but lack the hardware layer and bootstrap-token behaviour).
**Why required:** SecureToken/bootstrap-token behaviour and the always-on hardware encryption described in the Overview depend on Apple Silicon / T2.
**How to verify:** On a Mac, **Apple menu → About This Mac** (Apple Silicon shows a "Chip"; Intel T2 Macs list the T2 under **System Report → Controller**). Or Intune → device → **Hardware**.
**How to implement if missing:** For unsupported older hardware, FileVault still encrypts but plan SecureToken enablement manually and expect no bootstrap-token flow.

## 2.5 SecureToken / bootstrap token available
**Description:** At least one account on each Mac can be granted **SecureToken**, and (on ADE Macs) a **bootstrap token** is escrowed to Intune.
**Why required:** FileVault **cannot be enabled** for a user without a SecureToken. On ADE Macs the bootstrap token lets Intune grant SecureToken to accounts; without it a fresh ADE Mac may have no SecureToken user.
**How to verify:** On a Mac, `sysadminctl -secureTokenStatus <username>` shows **ENABLED** for the target user; `profiles status -type bootstraptoken` shows the bootstrap token is escrowed to the server. Run `MACFV-Discovery.ps1` for the tenant/enrollment signals.
**How to implement if missing:** Enroll corporate Macs via **Automated Device Enrollment** so the bootstrap token is generated and escrowed at setup. For already-enrolled Macs, run `sudo profiles install -type bootstraptoken` from a SecureToken-enabled admin, or grant SecureToken with `sysadminctl -secureTokenOn` from an existing SecureToken admin.

## 2.6 Microsoft Entra ID groups (pilot and production)
**Description:** Two Entra ID security groups: `FileVault – Pilot Devices` (a small representative sample of Macs) and `FileVault – Production Devices` (the rest of the Mac fleet).
**Why required:** FileVault is piloted before fleet rollout because enablement affects user login and the first encryption takes time.
**How to verify:** Entra → **Groups**; both groups exist. Use `MACFV-Set-ScopeTargeting.ps1` to stage membership.
**How to implement if missing:** Entra → **Groups → New group → Security**; add representative pilot Macs to one and the remaining Macs to the other.

## 2.7 A pilot (change control)
**Description:** A documented approval step and a small pilot of representative Macs before fleet rollout, with a rollback plan.
**Why required:** Enabling FileVault is a production change that touches user login; validate escrow and recovery on a pilot before scaling.
**How to verify:** You have a change record (who approved, what changed, rollback step) and a populated `FileVault – Pilot Devices` group.
**How to implement if missing:** Adopt a simple change record and populate the pilot group with a representative sample.

---
## Checklist
- [ ] Intune licensing assigned
- [ ] Apple MDM Push (APNs) certificate present and not expired — `MACFV-Discovery.ps1`
- [ ] macOS enrollment configured (ADE / Account-driven / Company Portal); Macs enrolled
- [ ] Target Macs are Apple Silicon or Intel T2
- [ ] SecureToken available / bootstrap token escrowed (ADE) — `MACFV-Discovery.ps1`
- [ ] `FileVault – Pilot Devices` and `FileVault – Production Devices` groups created
- [ ] Pilot + change-control/approval process agreed


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


# 3. Implementation Guide — FileVault Full-Disk Encryption & Key Escrow for macOS (Microsoft Intune)

Follow these steps **in order**, in the **Microsoft Intune admin center** (`https://intune.microsoft.com`).

> **Model:** A macOS **FileVault** disk-encryption policy that enables FileVault, **escrows the
> personal recovery key to Intune**, **hides the key from the user**, and **rotates** it — assigned
> to a pilot group first, then expanded. FileVault depends on **SecureToken**, so confirm the
> bootstrap token first.

## Step 1 — Create the device groups
1. In the Intune admin center go to **Groups → New group** (this opens Microsoft Entra).
2. **Group type:** Security. **Group name:** `FileVault – Pilot Devices`. Add a small,
   representative set of pilot Macs. **Create**.
3. Repeat to create `FileVault – Production Devices` for the rest of the Mac fleet (populate it
   later, at Step 8).

## Step 2 — Confirm SecureToken / bootstrap token
1. For **ADE (Automated Device Enrollment)** Macs, the bootstrap token is generated and escrowed at
   setup. Confirm on a pilot Mac: `profiles status -type bootstraptoken` (should report the token
   escrowed to the server), and `sysadminctl -secureTokenStatus <username>` shows **ENABLED** for
   the account that will use FileVault.
2. Run **`MACFV-Discovery.ps1`** to confirm APNs, enrollment, and readiness at the tenant level.
3. **Gate:** Do not proceed until at least one account on each pilot Mac is SecureToken-enabled (see
   Requirements 2.5). Without SecureToken, FileVault will not enable.

## Step 3 — Create the FileVault disk-encryption policy
1. Intune → **Endpoint security → Disk encryption → Create policy**.
2. **Platform:** **macOS**. **Profile:** **FileVault**. **Create**.
3. **Name:** `FileVault – Pilot`. (Optional) Description: note the pilot scope. **Next**.

## Step 4 — Configure FileVault settings (escrow + hide + rotate)
On **Configuration settings**, set FileVault to enable, escrow the personal key, hide it from the
user, and rotate it:
1. **Enable FileVault** = **Yes**.
2. **Escrow location description of personal recovery key** = a short message the user sees, e.g.
   `Your recovery key is stored securely by IT. Contact the Help Desk if you are locked out.`
3. **Hide recovery key from user** = **Yes** (the personal recovery key is escrowed to Intune, not
   shown on screen).
4. **Personal recovery key rotation** = **Enabled** — set a rotation period (for example every
   **6 months**) so keys refresh over time.
5. **Number of times user can bypass** (deferral) = choose a small number (for example **3**) so
   enablement is enforced after a few logins rather than deferred indefinitely.
6. **Disable prompt at sign out** / defer-until-logout options = leave at the defaults unless you
   have a reason to change them. Click **Next**.

> **Note:** Intune's FileVault profile uses the **personal recovery key** model (per-device key
> escrowed to Intune). It does not configure an institutional key — that legacy model is out of
> scope by design (see Overview).

## Step 5 — Scope tags (optional) and Assign to the pilot
1. **Scope tags** — add if you use RBAC scoping. **Next**.
2. **Assignments → Add groups →** `FileVault – Pilot Devices`. **Next → Review + create → Create**.

## Step 6 — Apply on a pilot Mac
1. On a pilot Mac, sync policy (**System Settings → Privacy & Security → Profiles**, or force a
   check-in from Company Portal).
2. At the next **log out / log in**, the SecureToken-enabled user is prompted to enable FileVault
   (up to the bypass count you set). After the user signs in, **encryption begins**.

## Step 7 — Validate the pilot (escrow + recovery)
1. Run **`MACFV-Validation.ps1 -DeviceName "MAC-001"`** → confirms Intune sees the device as
   **encrypted** and that a **personal recovery key is escrowed**.
2. In Intune → **Devices → macOS → <device> → Recovery keys**, confirm the **personal recovery key
   is present**.
3. **Recovery workflow test:** on the pilot Mac, at the login screen choose the "reset password /
   recovery key" path, enter the escrowed personal recovery key retrieved from Intune (or via
   `MACFV-Report.ps1`), and confirm the volume unlocks. Then confirm Intune **rotates** the key
   (a new key appears; the used one is retired).
4. Run **`MACFV-Report.ps1`** → confirms encryption + escrow coverage across the pilot group.
   Complete the **Testing Guide** (document 5).

> **Pilot pass gate:** every pilot Mac is **encrypted**, has an **escrowed personal recovery key**,
> and the **recovery-key unlock + rotation** worked. Do not expand until this passes.

## Step 8 — Expand to production
1. Populate `FileVault – Production Devices` and add it to the `FileVault – Pilot` policy's
   **Assignments** (or clone the policy as `FileVault – Production`); roll out in waves.
2. For each wave, confirm **escrow for every device** — a Mac that encrypts without an escrowed key
   is a recovery risk. Use `MACFV-Report.ps1`.
3. If any Mac is encrypted but **not escrowed** or FileVault did not enable, run
   **`MACFV-Remediation.ps1`** (preview first; it defaults to `-WhatIf`).

---
### Order of operations
`Device groups → Confirm SecureToken/bootstrap token → FileVault policy (enable + escrow + hide +
rotate) → Assign to pilot → Apply at login → Validate encryption + escrow + recovery → Expand`


---


# 5. Testing Guide — FileVault Full-Disk Encryption & Key Escrow for macOS (Microsoft Intune)

Run after the pilot policy applies (Implementation Step 7) and after each production wave. Use
`MACFV-Validation.ps1` for a single Mac and `MACFV-Report.ps1` for the fleet.

## Test 1 — Policy applied
**Do:** Intune → **Endpoint security → Disk encryption →** `FileVault – Pilot` **→ Device status**.
**Expected:** Pilot devices show **Succeeded** (no Error/Conflict).

## Test 2 — FileVault is on and the volume is encrypted
**Do:** On a pilot Mac run `fdesetup status` (expect `FileVault is On`) and
`diskutil apfs list` (the data volume shows FileVault/encryption). Or run `MACFV-Validation.ps1 -DeviceName "MAC-001"`.
**Expected:** FileVault **On**; the internal volume is encrypted.

## Test 3 — SecureToken confirmed for the FileVault user
**Do:** On the pilot Mac run `sysadminctl -secureTokenStatus <username>`.
**Expected:** The user is **ENABLED** for SecureToken (and appears in `fdesetup list`).

## Test 4 — Personal recovery key escrowed to Intune
**Do:** Intune → **Devices → macOS → <device> → Recovery keys**; or run `MACFV-Validation.ps1`.
**Expected:** A **personal recovery key** is present for the device in Intune.

## Test 5 — Recovery-key retrieval works (Graph)
**Do:** Run **`MACFV-Report.ps1 -DeviceName "MAC-001"`** (retrieves the escrowed personal recovery key for that Mac through Microsoft Graph).
**Expected:** The personal recovery key is returned for an authorized admin.

## Test 6 — Recovery unlock + rotation
**Do:** At the pilot Mac's login/recovery screen, use the escrowed personal recovery key to unlock, reset the password, then re-check Intune → **Recovery keys**.
**Expected:** The key unlocks the volume; Intune **rotates** the key (a new key is escrowed, the used one retired).

## Test 7 — Compliance reflects encryption
**Do:** Intune → device → **Compliance** (with a "require encryption / FileVault" compliance rule for macOS).
**Expected:** The encrypted Mac is **Compliant** for the encryption requirement.

## Test 8 — Fleet report
**Do:** Run **`MACFV-Report.ps1`** (no `-DeviceName`).
**Expected:** A breakdown of encrypted / not-encrypted Macs and a flag for any encrypted Mac **without an escrowed key**.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–6 pass for the pilot group (escrow confirmed and recovery/rotation verified for every device) |
| **Wave pass** | Tests 2, 4, 8 pass before the next wave (encrypted + escrowed, no unescrowed devices) |


---


# 6. Troubleshooting Guide — FileVault Full-Disk Encryption & Key Escrow for macOS (Microsoft Intune)

Use **`MACFV-Validation.ps1`** / **`MACFV-Discovery.ps1`** for state and
**`MACFV-Remediation.ps1`** for safe fixes (it defaults to `-WhatIf`).

## A. FileVault won't enable
| Symptom | Cause | Remediation |
|---|---|---|
| Policy "Succeeded" but FileVault stays Off | No SecureToken-enabled user on the Mac | Check `sysadminctl -secureTokenStatus <username>`; grant SecureToken from an existing SecureToken admin (`sysadminctl -secureTokenOn`), or use the bootstrap token on ADE Macs |
| ADE Mac has no SecureToken user | Bootstrap token not escrowed | Confirm `profiles status -type bootstraptoken`; install with `sudo profiles install -type bootstraptoken`; re-enroll via ADE if needed |
| User never prompted to enable | Deferral bypass count exhausted or not reached | Confirm the FileVault policy's bypass/deferral count; have the user log out/in |

## B. Recovery key not escrowed (critical)
| Symptom | Cause | Remediation |
|---|---|---|
| FileVault On but no key in Intune → Recovery keys | Escrow/hide-key not configured, or the Mac encrypted before the policy | Confirm the policy sets **Hide recovery key from user = Yes**; run `MACFV-Remediation.ps1` to re-apply the policy (device sync) so Intune escrows a fresh key |
| Key missing for pre-existing FileVault Macs | Encrypted before Intune managed it | Re-apply the FileVault policy so a new personal recovery key is generated and escrowed (rotation); verify with `MACFV-Report.ps1` |

## C. SecureToken / bootstrap-token problems
- `sysadminctl -secureTokenStatus <user>` shows **DISABLED** → grant from a SecureToken admin
  (`sysadminctl -secureTokenOn <user> -password - -adminUser <admin> -adminPassword -`).
- `profiles status -type bootstraptoken` shows not escrowed → run `sudo profiles install -type bootstraptoken`
  from a SecureToken-enabled account (ADE Macs generate this at setup).
- Mobile/Entra account can't be FileVault-enabled → it lacks SecureToken; grant it via the bootstrap
  token or from an existing SecureToken admin.

## D. Recovery key won't unlock / rotation issues
- Escrowed key does not unlock at the login screen → confirm you retrieved the **current** key
  (rotation may have replaced it); re-check Intune → **Recovery keys** or `MACFV-Report.ps1`.
- Key not rotating after use → confirm **Personal recovery key rotation** is enabled in the policy;
  force a device sync so the policy re-evaluates.

## E. Diagnostics quick reference (run on the Mac)
```bash
fdesetup status                              # FileVault On/Off, deferral state
fdesetup list                                # users enabled for FileVault
sysadminctl -secureTokenStatus <username>    # SecureToken ENABLED/DISABLED for a user
profiles status -type bootstraptoken         # bootstrap token escrowed to server?
diskutil apfs list                           # volume encryption state
```
From the management side, `MACFV-Report.ps1` retrieves the escrowed personal recovery key and
reports fleet encryption + escrow coverage.

## F. When to escalate
If a Mac is Apple Silicon/T2, is enrolled, has a SecureToken-enabled user and an escrowed bootstrap
token, the FileVault policy shows **Succeeded**, and FileVault still won't enable or the key won't
escrow after remediation, collect `fdesetup status`, `sysadminctl -secureTokenStatus`, and
`profiles status -type bootstraptoken` output and open a Microsoft support case.


---


# 7. Best Practices — FileVault Full-Disk Encryption & Key Escrow for macOS (Microsoft Intune)

- **Confirm SecureToken before you enable FileVault.** FileVault cannot turn on for a user without
  a SecureToken. On ADE Macs, make sure the **bootstrap token** is escrowed so Intune can grant it.
- **Enroll corporate Macs via Automated Device Enrollment.** ADE generates and escrows the
  bootstrap token automatically, which is the cleanest path to SecureToken and FileVault.
- **Escrow the personal recovery key — always.** Set **Hide recovery key from user = Yes** so the
  key is escrowed to Intune, not left on screen. A Mac that encrypts without an escrowed key is a
  recovery disaster waiting to happen.
- **Use the personal recovery key model, not institutional.** A per-device key escrowed to Intune
  limits blast radius; an institutional key is one key that unlocks the entire fleet — avoid it.
- **Turn on key rotation.** Enable **personal recovery key rotation** so a key that has been used
  (e.g. during a recovery) is retired and a fresh one is escrowed. Rotate on a schedule too.
- **Pilot first.** Confirm enablement, escrow, and the recovery-key unlock on a small group before
  fleet rollout — enablement touches user login and the first encryption takes time.
- **Plan enablement timing.** FileVault enables at login on the personal-key model; set a small
  deferral/bypass count so it is enforced after a few sign-ins rather than deferred forever.
- **Pair with compliance.** Use a macOS "require encryption / FileVault" compliance rule so
  unencrypted Macs are flagged (and blocked via Conditional Access).
- **Document the recovery procedure.** Make sure the help desk knows how to retrieve a personal
  recovery key (Intune device → **Recovery keys**, or `MACFV-Report.ps1`) and how the login-screen
  recovery flow works.
- **Report continuously.** Track encryption + escrow coverage with `MACFV-Report.ps1`; investigate
  any Mac that is encrypted but not escrowed.
- **Mind SecureToken on account changes.** Deleting or migrating the SecureToken-enabled account can
  strand FileVault — have a recovery key in hand before making account changes.


---


# 8. Deliverables Summary — FileVault Full-Disk Encryption & Key Escrow for macOS (Microsoft Intune)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | FileVault + SecureToken on Apple Silicon/T2, personal vs institutional keys, Intune escrow, recovery model |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered, click-by-click Intune steps |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation (SecureToken / FileVault) |
| 7. Best Practices | Field-proven recommendations (key rotation, recovery) |

## PowerShell scripts
| Script | What it does |
|---|---|
| `MACFV-Discovery.ps1` | Tenant/device readiness: APNs certificate, enrolled Macs, macOS-version spread, existing FileVault/disk-encryption policies (Graph, read-only) |
| `MACFV-Validation.ps1` | Per-device check: Intune sees the Mac as encrypted and a personal recovery key is escrowed (Graph, read-only) |
| `MACFV-Report.ps1` | Fleet encryption + escrow coverage, and retrieval of a device's escrowed personal recovery key (Graph, read-only) |
| `MACFV-Remediation.ps1` | Safe remediation of unencrypted/unescrowed Macs — re-applies the FileVault policy via device sync (defaults to -WhatIf) |
| `MACFV-Set-ScopeTargeting.ps1` | Builds/adjusts pilot or production group membership for staged rollout (defaults to -WhatIf) |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Every Mac encrypted with FileVault and every **personal recovery key escrowed and rotatable** in
Intune — device-loss protection with no lock-out you can't recover, proven on a pilot before you scale.
