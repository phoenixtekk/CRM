# 3. Implementation Guide — WSUS to Windows Update for Business Migration

Follow these steps **in order**, in the **Microsoft Intune admin center**
(`https://intune.microsoft.com`). This is a cutover: you build the cloud rings first, then remove
the WSUS authority on a pilot, validate, expand, and only then decommission WSUS.

> **Model:** A fast **Pilot** migration ring and a slower **Broad** ring, plus a feature update
> policy that pins the target Windows version. The pilot validates the cutover before the fleet —
> and **before any WSUS server is decommissioned**.

> **Naming convention used throughout (reuse verbatim):** `<Purpose> – <Scope> – <Stage>`.
> Objects created: groups `WUfB – Ring – Pilot` and `WUfB – Ring – Broad`; update ring policies
> `WUfB – Update Ring – Pilot` and `WUfB – Update Ring – Broad`; feature update policy
> `WUfB – Feature Update – Target`; Delivery Optimization profile `WUfB – Delivery Opt – Fleet`.

## Step 1 — Inventory the current WSUS state
1. Run `WSUSM-Discovery.ps1` on representative devices to capture the WSUS server pointer
   (`WUServer`), `UseWUServer`, and `DoNotConnectToWindowsUpdateInternetLocations`.
2. In the WSUS console, record the existing computer groups and approvals — they inform your ring
   design. Do not change WSUS yet.

## Step 2 — Create the migration ring groups
1. Entra → **Groups → New group** → Security → `WUfB – Ring – Pilot` (a few representative devices,
   ideally drawn from a current WSUS group). **Create**.
2. Create `WUfB – Ring – Broad` (the rest of the fleet). **Create**.

## Step 3 — Create the Pilot update ring
1. Intune → **Devices → Manage updates → Windows updates → Update rings → Create profile**.
2. **Name:** `WUfB – Update Ring – Pilot`. **Next**.
3. **Update settings:**
   - **Quality update deferral period (days):** **0**.
   - **Feature update deferral period (days):** **0**.
   - **Automatic update behavior:** Auto install and restart at a scheduled time (or at maintenance
     time).
   - **Active hours:** 8:00–18:00 (adjust to your org).
   - **Deadline for quality updates:** **2 days**; **feature updates:** **3 days**; **grace
     period:** **2 days**.
   - **User experience:** allow the user to pause = your policy.
4. **Next → Assignments → Add groups →** `WUfB – Ring – Pilot`. **Next → Create**.

## Step 4 — Create the Broad update ring
1. **Create profile** again. **Name:** `WUfB – Update Ring – Broad`.
2. **Update settings:** **Quality deferral 7 days**, **Feature deferral 14 days**, deadlines as
   above.
3. **Assignments → Add groups →** `WUfB – Ring – Broad`. **Create**.

## Step 5 — Create the feature update policy (pin the version)
1. Intune → **Devices → Manage updates → Windows updates → Feature updates → Create profile**.
2. **Name:** `WUfB – Feature Update – Target`. **Feature update version:** select your target (e.g.
   **Windows 11, version 23H2**).
3. **Rollout options:** Make update available as soon as possible (or schedule a gradual rollout).
4. **Assignments → Add groups →** `WUfB – Ring – Pilot` and `WUfB – Ring – Broad`. **Create**.

## Step 6 — Configure Delivery Optimization (replaces the WSUS local cache)
1. **Devices → Configuration → Create → Settings catalog →** search **Delivery Optimization**.
2. **Name:** `WUfB – Delivery Opt – Fleet`. Set **Download Mode** to **HTTP blended with peering
   behind same NAT (1)** or **LAN (1)**; set max bandwidth as needed. Assign to `WUfB – Ring – Pilot`
   and `WUfB – Ring – Broad`. **Create**.

## Step 7 — Remove the conflicting WSUS/GPO update policy on the pilot
This is the gating cutover step — until the WSUS pointer is gone, pilot devices keep scanning WSUS.
1. In Group Policy (the GPO that targets the pilot OU/devices), set to **Not Configured** (or remove
   the OU link):
   - **Specify intranet Microsoft update service location** (writes `WUServer`/`WUStatusServer` and
     `UseWUServer`).
   - **Do not connect to any Windows Update Internet locations** (writes
     `DoNotConnectToWindowsUpdateInternetLocations`).
2. On pilot devices, run `gpupdate /force`, then clear any residual registry pointers with
   `WSUSM-Remediation.ps1 -WhatIf` to preview, then `WSUSM-Remediation.ps1 -Confirm` to apply.
3. The pilot devices should now have no `WUServer`/`UseWUServer` value and scan Microsoft.

## Step 8 — Apply and sync on a pilot device
1. On a pilot device, sync policy (**Settings → Accounts → Access work or school → Info → Sync**).
2. Confirm the ring's deferral/deadline settings applied (**Settings → Windows Update →
   … managed by your organization**), or run `WSUSM-Validation.ps1`.

## Step 9 — Validate the pilot (gate before decommission)
1. Run `WSUSM-Validation.ps1` → confirms the device scans **Microsoft/WUfB**, not WSUS (no
   `WUServer`; online scan reachable), and the ring policy applied.
2. Run `WSUSM-Report.ps1` → confirms pilot devices' update status, OS build, and ring assignment.
3. Let the next quality update install on the pilot from Microsoft and confirm a healthy result.
   Complete the **Testing Guide**. **Do not decommission WSUS until this gate passes.**

## Step 10 — Expand to the broad ring
1. Remove the **Specify intranet Microsoft update service location** and **Do not connect to any
   Windows Update Internet locations** GPO settings fleet-wide; run `gpupdate /force` (or let it
   refresh) and use `WSUSM-Remediation.ps1` to clear residual pointers.
2. The `WUfB – Update Ring – Broad` ring already covers the fleet; confirm it is healthy each cycle.
3. Re-validate each cycle with `WSUSM-Validation.ps1` and `WSUSM-Report.ps1`.

## Step 11 — Decommission WSUS
1. With the fleet validated on WUfB (devices scanning Microsoft, patching on schedule), in the WSUS
   console stop approving updates and confirm no devices are still reporting in.
2. Uninstall the **Windows Server Update Services** role (and remove the WID/SUSDB and content
   store), or decommission the server.
3. Remove any remaining WSUS-related GPOs from Active Directory.

---
### Order of operations
`Inventory WSUS → ring groups → Pilot ring → Broad ring → Feature update policy → Delivery
Optimization → remove WSUS/GPO on pilot → apply → validate (gate) → expand → decommission WSUS`
