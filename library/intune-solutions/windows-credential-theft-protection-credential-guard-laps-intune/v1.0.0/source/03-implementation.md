# 3. Implementation — Windows Credential Theft Protection

Follow these steps **in order**. The *why* for each capability lives in the Solution Overview; the
steps below are deliberately short and exact so you can **click to implement**. Throughout, the
repeatable pattern applies: **Assess → Configure → Pilot → Validate → Expand.** Do everything against
the **`Credential Protection - Pilot`** group first.

All admin-center steps use the Microsoft Intune admin center at `https://intune.microsoft.com` and the
Microsoft Entra admin center at `https://entra.microsoft.com` unless noted.

> **This hardens the endpoint against credential theft only.** It does not harden RDP **hosts**
> (separate solution), is not a full CIS/STIG baseline, and makes no domain-controller changes. Deploy
> the VBS controls (Credential Guard, LSASS PPL) to **capable hardware** and **pilot-first**.

Objects you will create (named once, reused throughout testing and troubleshooting):

| Object | Type | Purpose |
|---|---|---|
| `Credential Protection - Pilot` | Entra security group | Pilot assignment target |
| `Credential Guard - Pilot` | Settings Catalog (Device Guard) | VBS + Credential Guard (UEFI lock) |
| `LSASS Protection (RunAsPPL) - Pilot` | Settings Catalog (Local Security Authority) | LSASS as protected process, audit-first |
| `WDigest Disabled - Baseline` | Settings Catalog | `UseLogonCredential = 0` |
| `Remote Credential Guard - Pilot` | Settings Catalog (Admin Templates → Credentials Delegation) | Restrict outbound credential delegation |
| `WinRM No RunAs Credentials - Baseline` | Settings Catalog (Admin Templates → WinRM Service) | `DisableRunAs = 1` |
| `Windows LAPS - Baseline` | Endpoint security → Account protection | Entra-backed local-admin password |

---

## Phase 1 — Assess (readiness first)

### Step 1. Confirm enrollment and hardware readiness
1. Go to **Devices → Windows → Windows devices** and confirm the pilot device is **managed** and
   **compliant**.
2. On a candidate device, run the readiness check:
   `powershell -ExecutionPolicy Bypass -File .\CREDGUARD-Discovery.ps1 -LocalReadiness`
   Confirm **TPM 2.0 present/ready**, **UEFI + Secure Boot On**, and **virtualization available**. (Or
   check manually per Requirements R2.)
3. Record which devices are **Credential-Guard-capable**; put those in a capable-device group (R6). The
   VBS controls (`Credential Guard - Pilot`, `LSASS Protection (RunAsPPL) - Pilot`) target that group;
   the low-risk controls (WDigest, WinRM) can target all pilot devices.

### Step 2. Create the pilot group
1. Entra → **Groups → New group**. **Group type** = **Security**; **Group name** =
   `Credential Protection - Pilot`. **Create**.
2. Add your pilot device(s)/user(s) as members.

---

## Phase 2 — Configure Credential Guard

### Step 3. Create the Credential Guard profile (Settings Catalog → Device Guard)
1. Go to **Devices → Configuration → Create → New policy**.
2. **Platform** = **Windows 10 and later**; **Profile type** = **Settings catalog**; **Create**.
3. **Basics → Name:** `Credential Guard - Pilot`. Description, e.g. *VBS + Windows Defender Credential
   Guard (UEFI lock) for credential-theft protection.* **Next**.
4. On **Configuration settings**, click **+ Add settings**. In the settings picker search **Device
   Guard** and select the **Device Guard** category. Add:
   - **Turn On Virtualization Based Security** → **Enabled**.
   - **Select Platform Security Level** → **Secure Boot** (or **Secure Boot and DMA Protection** on
     devices with kernel-DMA protection).
   - **Credential Guard Configuration** → **Enabled with UEFI lock** (production) *or* **Enabled without
     lock** (pilot / easy rollback — see Step 5).
   - *(Optional, recommended)* **Virtualization Based Protection of Code Integrity (HVCI)** → **Enabled
     with UEFI lock** — memory-integrity hardening that complements Credential Guard.
5. **Next** through **Scope tags**.

### Step 4. Assign the Credential Guard profile
1. **Assignments → Add groups** → add `Credential Protection - Pilot` (or the capable-device group).
   **Next**.
2. **Review + create → Create.**

### Step 5. Choose the lock mode deliberately (pilot vs production)
1. For the **pilot**, prefer **Enabled without lock** so you can disable Credential Guard by unassigning
   the profile if a driver/app breaks.
2. For **production waves**, switch the same setting to **Enabled with UEFI lock** so malware cannot
   silently disable it. Note (R9): with the UEFI lock, removal requires the documented VBS-removal
   procedure, not just a profile unassign.

> Prefer automation? `CREDGUARD-Remediation.ps1` can create this profile and assign it (defaults to
> **-WhatIf** — preview first, then re-run to apply), and `CREDGUARD-Discovery.ps1` confirms it is
> present and correctly configured.

---

## Phase 3 — Configure LSASS protection (audit-first)

### Step 6. Create the LSASS protection profile (RunAsPPL)
1. **Devices → Configuration → Create → New policy** → **Windows 10 and later** → **Settings catalog** →
   **Create**.
2. **Name:** `LSASS Protection (RunAsPPL) - Pilot`. **Next**.
3. **+ Add settings** → search **Local Security Authority** and select the **Local Security Authority
   (LSA)** category. Add **Configures LSASS to run as a protected process** and set it to **Enabled
   without UEFI lock** for the pilot (so you can back it out if an LSA plug-in is incompatible). Switch
   to **Enabled with UEFI lock** for production once clean.
   - *(If your tenant does not surface this setting, deliver the equivalent registry value
     `HKLM\SYSTEM\CurrentControlSet\Control\Lsa\RunAsPPL = 1` via a **Custom** OMA-URI / a proactive
     remediation. **Verify the exact setting name in your tenant** — LSA-protection surfacing varies by
     Windows/Intune release.)*
4. **Assign** to `Credential Protection - Pilot`. **Review + create → Create.**

### Step 7. Audit before enforcing
1. Leave `LSASS Protection (RunAsPPL) - Pilot` deployed for an observation window (e.g. one to two
   weeks) on the pilot.
2. On pilot devices, review **Event Viewer → Applications and Services Logs → Microsoft → Windows →
   CodeIntegrity → Operational** (and the LSA operational log) for **"would-block" LSA plug-in/driver**
   events (commonly **Event ID 3065** = would-block if enforced, **3066** = blocked). These name any
   incompatible module.
3. Update or remove the flagged module(s). Only when the audit window is clean, switch the setting to
   **Enabled with UEFI lock** for production waves. **Verify current event IDs in your build** — they
   evolve.

---

## Phase 4 — Configure WDigest, Remote Credential Guard, and WinRM

### Step 8. Disable WDigest (`WDigest Disabled - Baseline`)
1. **Devices → Configuration → Create → New policy** → **Windows 10 and later** → **Settings catalog** →
   **Create**. **Name:** `WDigest Disabled - Baseline`. **Next**.
2. **+ Add settings** → search **WDigest** / **UseLogonCredential**. Add the setting that maps to
   `HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest\UseLogonCredential` and set it to
   **0 / Disabled** (no plaintext caching).
   - *(If not surfaced in your tenant's Settings Catalog, deliver `UseLogonCredential = 0` via a
     **Custom** OMA-URI or proactive remediation. Modern Windows already defaults this to 0 — this
     profile **enforces and proves** it.)*
3. **Assign** to `Credential Protection - Pilot`. **Review + create → Create.**

### Step 9. Restrict credential delegation / Remote Credential Guard (`Remote Credential Guard - Pilot`)
1. **Devices → Configuration → Create → New policy** → **Windows 10 and later** → **Settings catalog** →
   **Create**. **Name:** `Remote Credential Guard - Pilot`. **Next**.
2. **+ Add settings** → search **Credentials Delegation** and select **Administrative Templates → System
   → Credentials Delegation**. Add **Restrict delegation of credentials to remote servers** → **Enabled**,
   and set **Use the following restricted mode** → **Require Remote Credential Guard** (this protects
   credentials when the device connects **outbound** over RDP). *(Choose **Restrict Credential
   Delegation** if you need the strictest mode and your targets support it.)*
3. **Assign** to `Credential Protection - Pilot`. **Review + create → Create.**

> **Host side is a different product.** The matching **RDP host** setting — *Remote host allows delegation
> of non-exportable credentials* (`AllowProtectedCreds = 1`) — plus Restricted Admin mode and NLA on the
> **target server** are covered by the separate **RDP hardening** solution. This profile is the
> **client/outbound** half only.

### Step 10. Disallow WinRM RunAs credential storage (`WinRM No RunAs Credentials - Baseline`)
1. **Devices → Configuration → Create → New policy** → **Windows 10 and later** → **Settings catalog** →
   **Create**. **Name:** `WinRM No RunAs Credentials - Baseline`. **Next**.
2. **+ Add settings** → search **Windows Remote Management** and select **Administrative Templates →
   Windows Components → Windows Remote Management (WinRM) → WinRM Service**. Add **Disallow WinRM from
   storing RunAs credentials** → **Enabled** (sets
   `HKLM\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service\DisableRunAs = 1`).
3. **Assign** to `Credential Protection - Pilot`. **Review + create → Create.**

> These three low-risk controls may be combined into a single Settings Catalog profile if you prefer
> fewer objects; the guide keeps them separate so each is named, reported, and rolled back independently.

---

## Phase 5 — Configure Windows LAPS

### Step 11. Enable the Entra LAPS tenant feature (prerequisite)
1. Entra → **Devices → Device settings** (or **All devices → Device settings**).
2. Set **Enable Microsoft Entra Local Administrator Password Solution (LAPS)** = **Yes**. **Save.**
   (Requires the appropriate role — R7.)

### Step 12. Create the Windows LAPS policy (Endpoint security → Account protection)
1. Go to **Endpoint security → Account protection → Create Policy**.
2. **Platform** = **Windows**; **Profile** = **Local admin password solution (Windows LAPS)**. **Create**.
3. **Name:** `Windows LAPS - Baseline`. **Next**.
4. **Configuration settings:**
   - **Backup Directory** → **Backup the password to Azure AD (Microsoft Entra ID) only**.
   - **Password Age (days)** → e.g. **30**.
   - **Administrator Account Name** → leave blank to manage the built-in Administrator, or specify a
     named local admin account you manage.
   - **Password Complexity** → large letters + small letters + numbers + special (strongest).
   - **Password Length** → e.g. **20**.
   - **Post Authentication Actions** → **Reset the password and logoff the managed account** after the
     configured grace period.
   - **Verify the exact field labels in your tenant** — Account-protection LAPS settings evolve.
5. **Assign** to `Credential Protection - Pilot`. **Review + create → Create.**

### Step 13. Confirm retrieval works
1. On a pilot device, force a sync (**Settings → Accounts → Access work or school → Info → Sync**) and
   wait for the policy to apply.
2. In Entra → **Devices → (the pilot device) → Local administrator password recovery**, confirm an
   authorized admin can **show** the current password (R8). This proves backup + retrieval end to end.

---

## Phase 6 — Pilot, Validate, Expand

### Step 14. Validate with the scripts
1. Run `CREDGUARD-Discovery.ps1` (tenant readiness: all six profiles present and, on a device,
   `-LocalReadiness` for TPM/UEFI/Secure Boot/VBS).
2. Run `CREDGUARD-Validation.ps1` to confirm each profile is **assigned** to `Credential Protection -
   Pilot` and pilot devices report **applied/Succeeded**.
3. Run `CREDGUARD-Report.ps1` to produce a coverage report (which Windows devices have the
   credential-protection controls applied, plus readiness/VBS-running state where available).

### Step 15. Confirm on the device
1. Credential Guard running:
   `(Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard).SecurityServicesRunning`
   should contain **1** (Credential Guard); or `msinfo32` → **Virtualization-based security Services
   Running: Credential Guard**.
2. LSASS protected: registry `HKLM\SYSTEM\CurrentControlSet\Control\Lsa\RunAsPPL = 1`.
3. WDigest: `HKLM\...\SecurityProviders\WDigest\UseLogonCredential = 0`.
4. WinRM: `HKLM\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service\DisableRunAs = 1`.
5. LAPS: **Microsoft-Windows-LAPS/Operational** log shows a successful backup; retrieval works (Step 13).

### Step 16. Remediate gaps (safe by default)
1. If a profile is missing or mis-scoped, run `CREDGUARD-Remediation.ps1 -GroupId <capable-or-pilot
   group>` — it **defaults to `-WhatIf`** and prints exactly what it would create/assign. Review, then
   re-run with `-WhatIf:$false` to apply.

### Step 17. Expand in waves
1. Once the pilot passes (Testing gate) and the LSA audit window is clean, switch the VBS controls to
   **Enabled with UEFI lock** and broaden assignment to the next wave via
   `CREDGUARD-Set-ScopeTargeting.ps1` (defaults to **-WhatIf**).
2. Keep Credential Guard / LSASS scoped to **capable** devices; let WDigest, WinRM, Remote Credential
   Guard, and LAPS ride out to all managed Windows devices.
3. Re-validate each wave with `CREDGUARD-Report.ps1` before widening.
