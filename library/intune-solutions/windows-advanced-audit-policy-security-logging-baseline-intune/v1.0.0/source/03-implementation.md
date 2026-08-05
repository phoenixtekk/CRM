# 3. Implementation — Windows Advanced Audit Policy & Security Event Logging Baseline (Intune)

Follow these steps **in order**. The *why* for each capability lives in the Solution Overview; the
steps below are deliberately short and exact so you can **click to implement**. Throughout, the
repeatable pattern applies: **Assess → Configure → Pilot → Validate → Expand.** Do everything against a
**pilot group** first.

All admin-center steps use the Microsoft Intune admin center at `https://intune.microsoft.com` unless
noted. (For US sovereign clouds — GCC High / DoD — use `https://intune.microsoft.us`; the Settings
Catalog paths are the same, but **verify in your tenant**.)

> **This deploys the audit-policy configuration baseline only** on **enrolled Windows 10/11** devices.
> It does not forward logs to a SIEM and does not apply a broad CIS/STIG hardening baseline. Every
> setting below is delivered through a single **Settings Catalog** profile.

---

## Phase 1 — Prepare

### Step 1. Confirm enrollment and Windows build
1. Go to **Devices → Windows → Windows devices** and confirm the pilot device is **managed**.
2. Open the device → **Hardware** (or run `winver` on the device) and confirm **Windows 10 21H2+** or
   **Windows 11**.

### Step 2. Create (or confirm) the pilot security group
1. Go to `https://entra.microsoft.com` → **Groups → All groups → New group**.
2. **Group type** = **Security**; **Group name** = **`Win Audit Policy - Pilot Devices`**;
   **Membership type** = **Assigned**.
3. Add your pilot device(s) (or pilot users) as members → **Create**. You will assign the profile to
   this group in Step 7.

### Step 3. Check for a conflicting legacy audit policy (R4/R5)
1. On the pilot device, open an elevated Command Prompt and run **`auditpol /get /category:*`** and
   note the current state (baseline for comparison after deployment).
2. Confirm no co-managing GPO still sets the **basic** *Audit Policy* (the nine categories under
   **Local Policies → Audit Policy**). If one does, set those entries to **Not Defined** so only the
   Advanced Audit Policy applies.

---

## Phase 2 — Build the Settings Catalog audit profile

### Step 4. Create the profile
1. Go to **Devices → Configuration → Create → New policy**.
2. **Platform** = **Windows 10 and later**; **Profile type** = **Settings catalog** → **Create**.
3. **Basics → Name:** **`Win Audit Policy - Baseline - Pilot`**. **Description:** *Advanced Audit Policy
   baseline (CIS / Microsoft-aligned) + command-line process auditing + Security log sizing for
   Windows 10/11.* Click **Next**.

### Step 5. Open the settings picker
1. On **Configuration settings**, click **+ Add settings**.
2. In the **Settings picker**, browse or search the categories below. In current Settings Catalog the
   audit subcategories appear under the **Auditing** category (each maps 1:1 to the **Audit** policy
   CSP); the override and log-size settings appear under **Administrative Templates** and **Local
   Policies Security Options**. **Search by the subcategory name** (e.g. *Audit Credential Validation*)
   if the tree layout differs — **verify the exact category tree in your tenant**.

### Step 6. Select and set every setting

#### 6a. The force-subcategory override (set this first — R4)
Search **Local Policies Security Options** → **Audit** and add:
- **`Audit: Force audit policy subcategory settings (Windows Vista or later) to override audit policy
  category settings`** → **Enabled**.
  *(Policy CSP: `LocalPoliciesSecurityOptions/Audit_ForceAuditPolicySubcategorySettingsToOverrideAuditPolicyCategorySettings`;
  registry `SCENoApplyLegacyAuditPolicy = 1`.)* Without this, nothing below takes effect.

#### 6b. The audit subcategories (recommended Success/Failure)
Search the **Auditing** category and add each subcategory below, setting the value to the recommended
level. Values map to the **Audit** CSP: `0` = No Auditing, `1` = Success, `2` = Failure,
`3` = Success and Failure. Recommendations are aligned to the **CIS Windows 10/11 Enterprise Benchmark
(Level 1)** and the **Microsoft security baseline**; **verify against the exact benchmark version you
must meet**.

| # | Category → Subcategory | Recommended | Notes / signal |
|---|------------------------|-------------|----------------|
| 1 | Account Logon → **Audit Credential Validation** | Success and Failure | Auth attempts against local SAM (4776) |
| 2 | Account Management → **Audit User Account Management** | Success and Failure | Account create/enable/delete/reset (4720–4726) |
| 3 | Account Management → **Audit Security Group Management** | Success and Failure | Group add/remove, privilege changes (4728/4732/4756) |
| 4 | Logon/Logoff → **Audit Logon** | Success and Failure | Interactive/network logons, failures (4624/4625) |
| 5 | Logon/Logoff → **Audit Account Lockout** | Failure | Lockouts (4740) |
| 6 | Logon/Logoff → **Audit Group Membership** | Success | Groups in the logon token (4627) |
| 7 | Logon/Logoff → **Audit Special Logon** | Success | Admin/special-privilege logons (4672) |
| 8 | Logon/Logoff → **Audit Other Logon/Logoff Events** | Success and Failure | RDP session connect/disconnect, lock/unlock |
| 9 | Object Access → **Audit File Share** | Success and Failure | Share access (5140) — **higher volume** |
| 10 | Object Access → **Audit Detailed File Share** | Failure | Per-file share access (5145) — **very high volume**; Failure only on workstations |
| 11 | Object Access → **Audit Removable Storage** | Success and Failure | USB storage read/write (4663) — insider/exfil |
| 12 | Object Access → **Audit Filtering Platform Connection** | *Optional* — see note | WFP allow/block (5156/5157) — **very high volume**; enable only when investigating |
| 13 | Object Access → **Audit Other Object Access Events** | Success and Failure | Scheduled-task/COM+ object events |
| 14 | Detailed Tracking → **Audit Process Creation** | Success | Process launch (4688) — **highest value, high volume**; pair with 6c |
| 15 | Detailed Tracking → **Audit PNP Activity** | Success | Plug-and-play device connect (6416) |
| 16 | Privilege Use → **Audit Sensitive Privilege Use** | Success and Failure | Use of sensitive rights (4672/4673/4674) — **high volume** |
| 17 | Policy Change → **Audit Audit Policy Change** | Success and Failure | Tampering with the audit policy itself (4719) |
| 18 | Policy Change → **Audit Authentication Policy Change** | Success | Trust/Kerberos/logon-right changes (4713/4717) |
| 19 | Policy Change → **Audit MPSSVC Rule-Level Policy Change** | Success and Failure | Windows Firewall rule changes (4946–4948) |
| 20 | Policy Change → **Audit Other Policy Change Events** | Failure | Crypto/boot-config policy failures |
| 21 | System → **Audit Security State Change** | Success and Failure | Startup/shutdown, system time (4608/4616) |
| 22 | System → **Audit Security System Extension** | Success and Failure | Service/driver/LSA extension load (4610/4697) |
| 23 | System → **Audit System Integrity** | Success and Failure | RPC/integrity violations, audit-log gaps (4612/4618) |
| 24 | System → **Audit Other System Events** | Success and Failure | Firewall service state, misc. system events |

> **Row 12 (Filtering Platform Connection):** the baseline leaves this **No Auditing** on workstations
> because 5156/5157 are extremely high volume; turn it to **Success and Failure** only on hosts you are
> actively investigating, and only if your SIEM can absorb it. The remediation script exposes it as an
> opt-in.

#### 6c. Command-line process auditing (pairs with row 14)
Search **Administrative Templates → System → Audit Process Creation** and add:
- **`Include command line in process creation events`** → **Enabled**.
  *(Policy CSP: `ProcessCreationIncludeCmdLine_Enabled`.)* This adds the full command line to Event ID
  **4688** — the difference between "`powershell.exe` ran" and "`powershell.exe -enc <base64>` ran".

#### 6d. Security event log size (R6)
Search **Administrative Templates → Windows Components → Event Log Service → Security** and add:
- **`Specify the maximum log file size (KB)`** → **Enabled**, value **`196608`** (≈ 192 MB).
  This is the Microsoft security baseline recommendation; the CIS minimum is **32768** (32 MB). Size it
  larger if you forward on a schedule rather than continuously. **Verify the field accepts your value in
  your tenant.**
- *(Optional)* set the retention behavior to **Overwrite events as needed (oldest first)** if your build
  exposes it, so a full log never blocks new events.

### Step 7. Scope tags, assignment, review
1. **Next** through **Scope tags** (set if you use them).
2. **Assignments:** add the **`Win Audit Policy - Pilot Devices`** group. Click **Next**.
3. **Review + create** → **Create**.

> Prefer automation? Run the included **`WINAUDIT-Set-ScopeTargeting.ps1`** (Microsoft Graph) to set or
> adjust the assignment (defaults to **-WhatIf** — preview first, then re-run to apply), and
> **`WINAUDIT-Discovery.ps1`** to confirm the profile is present and correctly configured. To create the
> whole profile from scratch, **`WINAUDIT-Remediation.ps1`** scaffolds it (also **-WhatIf** by default).

---

## Phase 3 — Pilot

### Step 8. Push and confirm the profile
1. On the pilot device, open **Settings → Accounts → Access work or school → (your account) → Info →
   Sync**, or wait for the next MDM check-in.
2. In Intune → **Devices → Configuration → `Win Audit Policy - Baseline - Pilot` → Device status**,
   confirm the pilot device shows **Succeeded**.

### Step 9. Confirm auditing is actually applied on the device
1. On the pilot device, open an elevated Command Prompt and run **`auditpol /get /category:*`**.
2. Confirm the subcategories from Step 6b reflect the recommended Success/Failure state (compare against
   your Step 3 baseline). For example, *Process Creation* should show **Success**.
3. Confirm the override: `reg query "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v
   SCENoApplyLegacyAuditPolicy` returns **`0x1`**.

### Step 10. Confirm events are being written (and the log is sized)
1. Perform a couple of auditable actions on the pilot device: sign out and back in (Logon), and launch
   `cmd.exe` then `powershell.exe` (Process Creation).
2. Open **Event Viewer → Windows Logs → Security** and confirm **4624** (logon) and **4688** (process
   creation) events appear — and that the **4688** events include a **Process Command Line** field.
3. Right-click **Security → Properties** and confirm **Maximum log size** is **196608 KB** (Step 6d).

---

## Phase 4 — Validate and expand

### Step 11. Validate with the scripts
1. Run **`WINAUDIT-Discovery.ps1`** (tenant readiness: the Settings Catalog audit profile exists with
   the force-subcategory override and the audit subcategories present).
2. Run **`WINAUDIT-Validation.ps1`** to confirm the profile is **assigned** to the intended group and the
   pilot device shows the profile **applied** (Succeeded).
3. Run **`WINAUDIT-Report.ps1`** to produce a coverage report (which Windows devices have the audit
   baseline applied).

### Step 12. Remediate gaps (safe by default)
1. If the profile is missing or mis-scoped, run **`WINAUDIT-Remediation.ps1`** — it **defaults to
   `-WhatIf`** and prints exactly what it would create/assign (the full subcategory set, the override,
   command-line auditing, and log size). Review, then re-run with `-WhatIf:$false` to apply.

### Step 13. Expand in waves (and split workstation vs server)
1. Once the pilot passes (Testing gate), broaden the assignment to the next group, or make
   `Win Audit Policy - Baseline - Pilot` the standard audit profile for corporate Windows devices
   (consider renaming to drop "- Pilot" once fleet-wide).
2. For **servers**, clone the profile as **`Win Audit Policy - Baseline - Servers`** and adjust the
   high-volume subcategories (rows 9, 10, 12, 16) per your server role and SIEM capacity, then assign it
   to a server group instead of the workstation baseline.
3. **Forwarding:** once the baseline is applied fleet-wide, deploy the separate *Entra ID & Intune Audit
   Telemetry to Microsoft Sentinel* solution to collect these events into your SIEM — this audit baseline
   is the source, that solution is the transport.
4. Roll out in waves, validating each wave with `WINAUDIT-Report.ps1` before widening.
