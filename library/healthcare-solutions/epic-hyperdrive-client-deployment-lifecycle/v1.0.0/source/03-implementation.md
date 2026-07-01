# 3. Implementation Guide — Epic Hyperdrive & Hyperspace Client Deployment & Lifecycle Management with Microsoft Intune

Follow these steps **in order**. Each step must be complete before the next. Unless stated otherwise,
all navigation is in the **Microsoft Intune admin center** (`https://intune.microsoft.com`).

> **Model:** Intune-managed, Microsoft Entra–joined clinical Windows endpoints. We wrap the Epic
> client as a **Win32 app** (`.intunewin`), pin it to a version with a **detection rule**, gate it
> with a **requirement rule**, assign it to **`Epic Hyperdrive – Pilot Ring`** first, **validate**,
> then expand to **`Epic Hyperdrive – Broad Ring`**. Upgrades are delivered via **supersedence**;
> old versions are **retired** with a clean uninstall. Phases: **Assess → Package → Pilot → Validate
> → Broad Deploy → Lifecycle**, exactly like the standard deployment model.

> **Epic-specific values:** wherever you see `<EPIC_INSTALLER>`, `<EPIC_SILENT_ARGS>`,
> `<EPIC_VERSION>`, `<EPIC_INSTALL_DIR>`, `<EPIC_EXE>`, `<EPIC_UNINSTALL_CMD>`, substitute the **real**
> values from your **Epic build team / Epic UserWeb** (Requirements §R3). Do not invent them.

---

## Phase A — Assess

### Step 1 — Confirm requirements and decide Hyperdrive vs. Hyperspace
1. Work through the **Requirements Guide** (§R1–R11) and the
   **global-requirements-healthcare-solutions** checklist. Do not proceed past any unmet item.
2. Confirm with your Epic build team **which client** you are deploying — **Hyperdrive** (current,
   WebView2-based) and/or **Hyperspace** (legacy) — and the exact `<EPIC_VERSION>` your Epic
   environment expects.
3. If deploying **Hyperdrive**, confirm the **WebView2 runtime** plan (Requirements §R5) — you will
   wire it as a dependency in Step 6.
4. If devices are **co-managed**, confirm the **Client apps** workload authority (Requirements §R6).

### Step 2 — Manually install once on the test device (prove the silent command)
1. On the **test device** (in `Epic Hyperdrive – Pilot Ring`, not in patient care), run
   `<EPIC_INSTALLER> <EPIC_SILENT_ARGS>` by hand from an elevated prompt.
2. Confirm it installs **unattended** (no prompts) and that `<EPIC_EXE>` appears in
   `<EPIC_INSTALL_DIR>`.
3. Run **`EPICCLIENT-Discovery.ps1`** and note the **installed version**, install path, and registry
   uninstall key — these are your **detection** values (Requirements §R8).
4. Launch the client, confirm it loads and points at the correct Epic environment, then (if testing a
   clean package) uninstall with `<EPIC_UNINSTALL_CMD>` to return the device to a known state.

---

## Phase B — Package

### Step 3 — Build the `.intunewin` package
1. On your packaging workstation, create a clean **source folder** (e.g. `C:\EpicPkg\Source`) and place
   `<EPIC_INSTALLER>` and any required supporting files inside it.
2. Run the Win32 Content Prep Tool:
   ```
   IntuneWinAppUtil.exe -c "C:\EpicPkg\Source" -s "<EPIC_INSTALLER>" -o "C:\EpicPkg\Output"
   ```
3. Confirm `C:\EpicPkg\Output\<EPIC_INSTALLER>.intunewin` is produced.

### Step 4 — Create the Win32 app in Intune
1. Go to **Apps → Windows → Add**. For **App type**, select **Windows app (Win32)** → **Select**.
2. On **App information**:
   - **Select app package file** → upload `…\<EPIC_INSTALLER>.intunewin` → **OK**.
   - **Name:** `Epic Hyperdrive – <EPIC_VERSION>` (for the legacy client use
     `Epic Hyperspace – <EPIC_VERSION>`). Use this exact name in all later steps.
   - **Publisher:** your organization. Fill **Description** (note the Epic environment and version).
   - Click **Next**.

### Step 5 — Program (install / uninstall commands)
1. On **Program**:
   - **Install command:** `<EPIC_INSTALLER> <EPIC_SILENT_ARGS>` (the exact silent command proven in
     Step 2).
   - **Uninstall command:** `<EPIC_UNINSTALL_CMD>` (silent uninstall from your Epic build team).
   - **Install behavior:** **System** (clinical endpoints are shared / multi-user).
   - **Device restart behavior:** **No specific action** (do not force reboots on clinical devices;
     control restarts through the maintenance window).
2. Click **Next**.

### Step 6 — Requirements rule (and WebView2 dependency for Hyperdrive)
1. On **Requirements**:
   - **Operating system architecture:** **64-bit**.
   - **Minimum operating system:** the lowest supported build per Requirements §R4 (e.g. Windows 10
     21H2 / Windows 11).
   - Add any additional requirement your build team specifies (disk space, etc.).
2. Click **Next**.
3. **WebView2 dependency (Hyperdrive only):** if you deployed the **WebView2 runtime** as its own
   Win32 app (Requirements §R5), set it as a dependency after the app is created — open
   `Epic Hyperdrive – <EPIC_VERSION>` → **Dependencies → + Add**, select the WebView2 runtime app,
   set **Automatically install** = **Yes**, so WebView2 installs first. (Dependencies are configured
   on the saved app; you can complete the wizard first and add this immediately after Step 9.)

### Step 7 — Detection rule (pin the version)
1. On **Detection rules**, set **Rules format** to **Manually configure detection rules** → **+ Add**.
2. Choose the rule type that matches how `<EPIC_INSTALLER>` registers (Requirements §R8):
   - **File** (recommended): **Path** = `<EPIC_INSTALL_DIR>`, **File** = `<EPIC_EXE>`,
     **Detection method** = **String (version)**, **Operator** = **Greater than or equal to**,
     **Value** = `<EPIC_VERSION>`. Name it conceptually **`Epic Client – Version Detection`**.
   - **or MSI** (product code) / **Registry** (uninstall key + DisplayVersion) if that is how it
     registers.
3. Click **OK** → **Next**.

### Step 8 — (Optional) Detection / requirement scripts; Return codes; Scope tags
1. Leave **default return codes** unless your installer uses non-standard codes.
2. Add **Scope tags** if your org uses them, else **Next**.

### Step 9 — Create the app (assign in Phase C)
1. On **Assignments**, leave assignments empty for now → **Next**.
2. On **Review + create**, confirm everything → **Create**.
3. **Now wire the WebView2 dependency** (Step 6.3) if deploying Hyperdrive.

---

## Phase C — Pilot

### Step 10 — Ensure the ring groups exist
1. In `https://entra.microsoft.com` → **Groups → All groups**, confirm
   **`EPIC – Clinical Workstations`**, **`Epic Hyperdrive – Pilot Ring`**, and
   **`Epic Hyperdrive – Broad Ring`** exist (Requirements §R7).
2. If missing, create them (**New group → Security**) or run
   **`EPICCLIENT-Set-DeploymentRings.ps1`** to create the pilot/broad ring groups and (optionally)
   wire the assignment via Graph.
3. Add your **test device(s)** to **`Epic Hyperdrive – Pilot Ring`**.

### Step 11 — Assign the app to the Pilot Ring
1. Open **Apps → Windows → `Epic Hyperdrive – <EPIC_VERSION>` → Properties → Assignments → Edit**.
2. Under **Required**, click **+ Add group** → select **`Epic Hyperdrive – Pilot Ring`** → **Select**.
3. Expand the assignment's **Settings** and set an **Available** time aligned to your maintenance
   window if desired (for **Required**, the **End user notifications** and restart grace can be set
   here). Click **Review + save → Save**.

### Step 12 — Sync and install on a pilot device
1. On a pilot device, force a sync: **Settings → Accounts → Access work or school → (account) → Info
   → Sync**.
2. In Intune, watch **Apps → Windows → `Epic Hyperdrive – <EPIC_VERSION>` → Device install status**
   until the pilot device shows **Installed**.

---

## Phase D — Validate

### Step 13 — Validate the pilot device
1. On the pilot device, run **`EPICCLIENT-Validation.ps1`** — confirms the **target version**
   installed, install state, and (Hyperdrive) the **WebView2 runtime** present → expect overall
   **PASS**.
2. Launch the Epic client; confirm it **loads** and connects to the correct Epic environment.
3. If integrating Imprivata (Requirements §R11), perform a **badge tap** and confirm tap-to-launch
   into Epic still works.
4. Complete the **Testing Guide (Section 5)**. **Do not expand** until every pilot test passes.
5. Run **`EPICCLIENT-Report.ps1`** to capture the pilot's version spread as a baseline.

---

## Phase E — Broad Deploy

### Step 14 — Assign to the Broad Ring (in the change window)
1. Confirm the CAB-approved change window is open (Requirements §R10).
2. Open **Apps → Windows → `Epic Hyperdrive – <EPIC_VERSION>` → Properties → Assignments → Edit**.
3. Under **Required**, **+ Add group** → **`Epic Hyperdrive – Broad Ring`** → **Select** →
   **Review + save → Save**.
4. Monitor **Device install status** and re-run **`EPICCLIENT-Report.ps1`** to watch the version
   converge across the fleet. Re-run **`EPICCLIENT-Validation.ps1`** on a sample of broad devices.

---

## Phase F — Lifecycle (update / supersede / retire)

### Step 15 — Deliver an Epic client **upgrade** via supersedence
When Epic moves your environment to a new `<EPIC_VERSION_NEW>`:
1. Repeat **Steps 2–9** to build and create a **new** Win32 app
   **`Epic Hyperdrive – <EPIC_VERSION_NEW>`** with its own version-pinned detection rule.
2. On the **new** app, go to **Supersedence → + Add**.
3. Select the **previous** app **`Epic Hyperdrive – <EPIC_VERSION>`** as the app to supersede.
4. Set **Uninstall previous version** = **Yes** (Intune removes the old client, then installs the new
   one — the clean upgrade path). Name this relationship conceptually
   **`Epic Hyperdrive – Supersede <EPIC_VERSION>→<EPIC_VERSION_NEW>`**. Click **Add → Save**.
5. **Assign the new app to `Epic Hyperdrive – Pilot Ring` first** (Step 11), validate (Phase D), then
   expand to `Epic Hyperdrive – Broad Ring` (Phase E). Supersedence respects ring assignments —
   pilot upgrades before broad.
6. Re-run **`EPICCLIENT-Report.ps1`** until the fleet shows only `<EPIC_VERSION_NEW>`.

> **Note:** supersedence requires the **new** app to be assigned to devices for the replacement to
> occur. Assigning only the new app (not re-touching the old) and confirming **Uninstall previous
> version = Yes** is what produces an in-place upgrade rather than two coexisting versions.

### Step 16 — **Retire** an old client version cleanly
To remove a decommissioned version that is **not** being replaced by a superseding app:
1. Open the old app **`Epic Hyperdrive – <EPIC_VERSION>` → Properties → Assignments → Edit**.
2. Remove its **Required** assignments, and under **Uninstall** add the target group (e.g.
   **`EPIC – Clinical Workstations`** or the specific ring) → **Save**. Intune runs the app's
   **Uninstall command** (`<EPIC_UNINSTALL_CMD>`) on those devices.
3. After devices report the uninstall and **`EPICCLIENT-Discovery.ps1`** shows the version gone,
   you may delete the old Win32 app from **Apps → Windows** (keep a copy of its `.intunewin` and
   detection values for rollback per Requirements §R10 until the new version is fully proven).
4. Spot-check with **`EPICCLIENT-Validation.ps1`** that no leftover old version remains.

---

### Order of operations (summary)
`Assess + prove silent install → Build .intunewin → Create Win32 app (program, requirement, WebView2 dependency, version detection) → Ring groups → Assign Pilot Ring → Validate (version, launch, Imprivata tap) → Assign Broad Ring (in change window) → Lifecycle: supersede for upgrades (uninstall previous = Yes, pilot-then-broad) / retire via Uninstall assignment`
