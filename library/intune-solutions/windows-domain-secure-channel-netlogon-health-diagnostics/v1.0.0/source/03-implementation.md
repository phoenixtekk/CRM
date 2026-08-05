# 3. Implementation — Windows Domain Secure-Channel & Netlogon Health Diagnostics Toolkit

Follow these steps **in order**. The *why* for each check lives in the Solution Overview; the steps
below are deliberately short and exact so you can **click (or run) to implement**. Throughout, the
repeatable pattern applies: **Assess → Diagnose → Repair → Validate → Prevent.** Prove everything on a
**pilot device** (and the **`NETLOGONDX-Pilot`** group) before you widen.

All scripts write to **`C:\ProgramData\NETLOGONDX`** and use **only in-box Windows commands** — nothing
to install on endpoints. Run them **elevated** locally, or as **SYSTEM** via Intune Proactive
Remediations. The Intune admin center is `https://intune.microsoft.com`.

> **This is a diagnostics toolkit**, not a configuration baseline. Only `NETLOGONDX-Remediation.ps1`
> changes anything, and it **defaults to `-WhatIf`** (preview). Resolve the two findings — **Event ID
> 5719 (Netlogon)** and **IPv6 recommended configuration** — the same way every time.

---

## Phase 1 — Assess (get the scripts onto the device)

### Step 1. Stage the toolkit
1. Copy the `NETLOGONDX-Scripts.zip` contents to the device (or a share), e.g. to `C:\Temp\NETLOGONDX`.
2. Open **Windows PowerShell as administrator** (Start → type *PowerShell* → **Run as administrator**).
3. `cd C:\Temp\NETLOGONDX`.

### Step 2. Confirm the device is in scope
1. Run `(Get-CimInstance Win32_ComputerSystem).PartOfDomain` — it must return **True** (R1).
2. Confirm you are elevated (R2) and `where.exe nltest w32tm` both resolve (R4).

---

## Phase 2 — Diagnose (collect every signal, read-only)

### Step 3. Run Discovery
1. Run:
   `powershell -ExecutionPolicy Bypass -File .\NETLOGONDX-Discovery.ps1`
2. Read the PASS/FAIL/INFO table. It reports, in one pass: recent **Event ID 5719** (and related 5722 /
   5723 / 3210 events), **secure channel** (`Test-ComputerSecureChannel`), **DC locator**
   (`nltest /sc_query`, `/dsgetdc`), **DNS SRV** resolution of `_ldap._tcp.dc._msdcs.<domain>`, **time
   sync** (`w32tm`), **DC ports 88/135/389/445**, and **IPv6 `DisabledComponents`**.
3. The full detail is saved to **`C:\ProgramData\NETLOGONDX\NETLOGONDX-Discovery.json`** and
   `…\NETLOGONDX-Discovery.txt`.

### Step 4. Read the root cause off the table
Map the failing signal to the cause (Solution Overview has the full tree):
- **DNS SRV = FAIL** → wrong/unreachable DNS or missing SRV records (R6).
- **Secure channel = FAIL** → machine-account/trust password out of sync (snapshot/clone/offline).
- **Time = FAIL** → Kerberos clock skew > 5 minutes.
- **DC ports = FAIL** → firewall/VLAN blocking 88/135/389/445, or no DC reachable (R5).
- **IPv6 = FAIL** → invalid `DisabledComponents` (e.g. `0xffffffff`).
- **5719 present but everything else PASS** → likely the **boot-time NIC/power race** (see Phase 5).

---

## Phase 3 — Repair (preview first, then apply)

### Step 5. Preview the remediation
1. Run the remediation in its **default preview** mode (changes nothing):
   `powershell -ExecutionPolicy Bypass -File .\NETLOGONDX-Remediation.ps1`
2. Read exactly what it **would** do: repair the secure channel
   (`Test-ComputerSecureChannel -Repair`, falling back to `nltest /sc_reset:<domain>`), start Windows
   Time and `w32tm /resync /force`, and — **only if the IPv6 value is invalid** — reset
   `DisabledComponents` to **`0x0`**. It **never disables IPv6**.

### Step 6. Apply the remediation
1. When the preview looks right, apply:
   `powershell -ExecutionPolicy Bypass -File .\NETLOGONDX-Remediation.ps1 -WhatIf:$false`
2. If the secure-channel repair needs domain credentials, pass them:
   `.\NETLOGONDX-Remediation.ps1 -WhatIf:$false -Credential (Get-Credential)`
3. If **IPv6 was corrected**, note that a **restart** is required for the change to take effect.

> **DNS / ports first when they are the cause.** If Discovery showed **DNS SRV** or **DC ports**
> failing, fix those at the network/NIC layer (R5/R6) *before* re-running repair — a secure-channel
> reset cannot succeed with no DC path. Correct the NIC DNS, then
> `ipconfig /flushdns; ipconfig /registerdns`, and re-run Discovery.

---

## Phase 4 — Validate

### Step 7. Confirm healthy
1. Run:
   `powershell -ExecutionPolicy Bypass -File .\NETLOGONDX-Validation.ps1`
2. Confirm **OVERALL: HEALTHY** (exit code **0**): secure channel healthy, time in sync, DNS resolves
   DCs, IPv6 not invalidly disabled.
3. Produce the summary for the record:
   `powershell -ExecutionPolicy Bypass -File .\NETLOGONDX-Report.ps1`
   — reads `C:\ProgramData\NETLOGONDX\NETLOGONDX-Report.csv` / `.txt`.

### Step 8. Escalate if still failing
1. If a signal still fails, bundle everything for support:
   `powershell -ExecutionPolicy Bypass -File .\NETLOGONDX-Collect.ps1`
2. Attach the resulting **`NETLOGONDX-Collect-<host>-<timestamp>.zip`** to your ticket (it contains no
   credentials or secrets).

---

## Phase 5 — Deploy at scale via Intune Proactive Remediations (and Prevent)

### Step 9. Create the script package
1. In the Intune admin center, go to **Reports → Endpoint analytics → Proactive remediations →
   Create script package**.
2. **Basics → Name:** **`NETLOGONDX – Secure-Channel & Netlogon Health`**; add a description, e.g.
   *Detects Netlogon 5719 / broken secure channel, clock skew, DC-locator DNS failures, and invalid
   IPv6 config; repairs safely.* Click **Next**.
3. **Settings:**
   - **Detection script file:** upload **`NETLOGONDX-Validation.ps1`** (exits `1` when unhealthy).
   - **Remediation script file:** upload **`NETLOGONDX-Remediation.ps1`**. In the packaged remediation
     copy, ensure it will **apply** under SYSTEM (either leave the default so it applies, or add
     `-Force`/`$WhatIfPreference=$false` at the top of the packaged copy — the shipped script previews
     by default for safe manual runs).
   - **Run this script using the logged-on credentials:** **No** (runs as SYSTEM).
   - **Enforce script signature check:** **No** (unless you sign the scripts).
   - **Run script in 64-bit PowerShell:** **Yes**.
   Click **Next**.
4. **Scope tags** (set if you use them) → **Next**.

### Step 10. Assign to the pilot group first
1. On **Assignments**, add the **`NETLOGONDX-Pilot`** group (Global Requirement **G5** / R9).
2. Set a **daily** schedule (Endpoint analytics → the package → **Properties → Assignments →
   schedule**) so detection re-runs and confirms devices stay healthy.
3. **Review + create → Create.**

### Step 11. Read results and expand
1. Open **Reports → Endpoint analytics → Proactive remediations → `NETLOGONDX – Secure-Channel &
   Netlogon Health`** and review **Device status**: *Without issues* vs *Issues detected* /
   *Issues remediated*.
2. Once the pilot passes (Testing gate), broaden the assignment in waves to the next group.
3. **Prevent recurrence** (the boot-time NIC/power race and drift) — apply the standing controls in
   Best Practices: disable NIC **"Allow the computer to turn off this device to save power,"** set
   **"Always wait for the network at computer startup and logon,"** keep domain members on **internal
   AD DNS** and a valid **time hierarchy**, and keep **IPv6 enabled** (`0x0`). Re-run the package each
   wave and confirm **Without issues** matches the assigned devices before widening.
