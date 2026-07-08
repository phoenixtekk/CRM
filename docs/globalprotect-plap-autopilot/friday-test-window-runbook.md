# GlobalProtect Connect Before Logon (PLAP) — Test-Window Diagnostic Runbook

**Goal of the session:** on a clean **Windows 11** Autopilot test VM, reproduce the failure, confirm
whether the **Connect Before Logon (CBL/PLAP)** tile appears at the sign-in screen, and **capture the
IME + Autopilot + GlobalProtect logs before the VM is wiped.** One-pass, evidence-first.

> Read-only/collection tools only — nothing here changes configuration. Vendor portal/gateway and
> GlobalProtect app internals are per Palo Alto's documentation.

---

## 0. Before the window (have these ready)
- A fresh **Windows 11** VM enrolled through the **Hybrid Azure AD Join** Autopilot profile (not Win10).
- The GlobalProtect **MSI ≥ 5.2**, the **portal FQDN**, and the auth method (basic / cert / SAML).
- The five `GPPLAP-*.ps1` scripts on the VM (or reachable share).
- Confirm the Win32 app **`GlobalProtect – Connect Before Logon (PLAP) – Win32`** is assigned to
  **`PILOT – GlobalProtect PLAP – Autopilot Devices`** and is an **ESP blocking app**.

## 1. Run provisioning and watch it fail (or pass)
- Start the Autopilot user-driven provisioning; watch the **ESP** app phase.
- If it hangs/red-X's on the GlobalProtect app, **do not reset yet** — go straight to step 2.

## 2. Capture everything (the critical step — evidence first)
```
powershell -ExecutionPolicy Bypass -File .\GPPLAP-Collect-Logs.ps1 -OutFolder C:\Temp\gpplap
```
Run **elevated**. Produces `C:\Temp\gpplap\GPPLAP-Logs-<host>-<timestamp>.zip` with: IME logs
(`IntuneManagementExtension.log`, `AgentExecutor.log`, `AppWorkload.log`), the `MdmDiagnosticsTool`
Autopilot ZIP, GlobalProtect PanGPS/PanGPA logs, exported Event channels, and `summary.txt` (app exit
codes + PanSetup state). **Copy this ZIP off the VM now.**

## 3. Confirm the PLAP state on the box
```
powershell -ExecutionPolicy Bypass -File .\GPPLAP-Validation.ps1
```
PASS requires **GP ≥ 5.2 AND `Prelogon = 1` AND PLAP registered**. It also prints the dsregcmd join
type (**DomainJoined + AzureAdJoined = Hybrid**).

## 4. Confirm the sign-in tile (ground truth)
Lock the VM / sign out → at the sign-in screen click the **network sign-in / Connect Before Logon**
tile. If the tile is **absent**, PLAP is not registered — jump to the decision tree.

---

## Decision tree — read `summary.txt` first

| What you see | Most likely cause | Fix |
|---|---|---|
| **"Unzipping" / exit `0x87D30067`** in IME log | IME can't extract `.intunewin` into IMECache — **AV/Defender lock**, low disk, or a bad/nested re-wrap | Exclude the IME **Content/IMECache** path from AV during provisioning; free disk; **re-wrap cleanly** with the current Win32 Content Prep Tool (don't nest an already-wrapped payload) |
| App install **loops / IME state lost after a reboot** | A **forced `Restart-Computer`** inside the install script | Remove the scripted reboot; **return `3010`** and let ESP own the reboot; ensure `Start-Process … -Wait`; return-code map `0/1707=ok, 3010=soft reboot, 1618=retry` |
| **No CBL tile** at sign-in, but app "installed" | GP **< 5.2**, `Prelogon` reg not set, or `PanGPS.exe -registerplap` **didn't run in SYSTEM** / ran before the PanGPS service was ready | Verify GP ≥ 5.2; set `HKLM\SOFTWARE\Palo Alto Networks\GlobalProtect\PanSetup\Prelogon = 1` + Portal; run `-registerplap` as **SYSTEM** after a **service-readiness wait** |
| Worked on a **Win10** test, fails now | **Target OS mismatch** | Re-test on **Windows 11** (production target) |
| **Tile shows, tunnel up, hybrid first-logon fails** | DC not reachable through the gateway / ODJ / **time skew** | Confirm gateway → DC line-of-sight, Offline Domain Join blob, and VM clock |
| ESP never waits for the app | App **not marked ESP blocking** | Add the app to the **ESP blocking apps** list |
| Enrollment-time device group **empty** | Assigned group missing the **Provisioning Client SP** owner | Set SP **AppId `f1346770-5b25-470b-88bd-d5744ab7952c`** as an **owner** of the Assigned device group |

---

## Enable reference (for the fix, per Palo Alto docs)
1. Install GlobalProtect (**≥ 5.2**).
2. Registry — `HKLM\SOFTWARE\Palo Alto Networks\GlobalProtect\PanSetup\` → `Prelogon = 1`, set `Portal`.
3. Wait for the **PanGPS** service to be ready, then (as **SYSTEM**):
   `"C:\Program Files\Palo Alto Networks\GlobalProtect\PanGPS.exe" -registerplap`
4. Package all of the above as **one** Win32 app that **returns `3010`** for reboot (no scripted restart).

> **Exit criterion for the session:** the log ZIP is captured off-box, `GPPLAP-Validation.ps1` shows
> the exact failing precondition, and you know which decision-tree row you're in. That is enough to
> stabilise the next build without another full test window.
