# Implementation — Deployment Strategy

The step-by-step plan: assess compatibility, design the target print path, build the Intune profile,
pilot and validate, migrate off legacy print servers, roll out in rings, and prevent regression. Portal
paths use the commercial hosts; for **GCC High / DoD** use the `*.microsoft.us` equivalents.

---

## Phase 1 — Compatibility assessment (do this first, always)

WPP **removes** incompatible printers and drivers, so the assessment is not optional — it is the safety
gate.

### Step 1.1 — Inventory drivers and printers
1. Run **`WPPRINT-Get-PrintDriverInventory.ps1`** across a representative device sample (via an Intune
   **platform script** or Proactive Remediation). It lists installed **print drivers** (V3/V4,
   third-party vs the **Microsoft IPP Class Driver**) and **printers**, flagging every printer that
   relies on a **third-party driver** — i.e., what WPP would remove.

### Step 1.2 — Test driverless (Mopria/IPP) readiness
1. Run **`WPPRINT-Test-MopriaReadiness.ps1`**. For each printer it checks reachability over **IPP/IPPS**
   and whether the **Microsoft IPP Class Driver** is present, classifying printers as **Ready-Print
   eligible** or **blocker**.

### Step 1.3 — Test scan (eSCL) readiness
1. Where multifunction **scanning** matters, run **`WPPRINT-Test-ScanCapability.ps1`** to flag scanners
   that may lose function under WPP unless they support **Mopria/eSCL**.

### Step 1.4 — Read current WPP state and OS eligibility
1. Run **`WPPRINT-Get-WPPState.ps1`** to record each device's **OS build** (24H2+?) and current WPP
   state (enabled / disabled / not configured).

**Output of Phase 1:** a compatibility matrix — for every printer population: *Ready-Print eligible*,
*needs Universal Print*, or *blocker (non-Mopria / legacy software / eSCL-less scanner)*.

---

## Phase 2 — Design the target print path

1. **Ready-Print-eligible printers** → keep, printed via the **Microsoft IPP Class Driver** (enable
   IPP/IPPS on the device where needed).
2. **Printers better served from the cloud** → **Universal Print** (confirm licensing/connector; confirm
   sovereign-cloud availability).
3. **Blockers** → decide per population: enable IPP/Mopria, replace hardware, keep the scanner's eSCL
   path, or **exclude those devices from WPP scope** and track them as exceptions.
4. **Legacy "software" printers** (vendor PDF/"print to" utilities) → identify replacements (e.g., the
   built-in *Microsoft Print to PDF*).

**Output of Phase 2:** the target design and the **WPP scope** (which device rings get WPP; which are
exceptions until remediated).

---

## Phase 3 — Build the Intune configuration profile (Custom OMA-URI)

Because `ConfigureWindowsProtectedPrint` is **not yet in the Settings Catalog**, use a **Custom**
profile.

### Step 3.1 — Create the profile
1. **Intune admin center → Devices → Configuration → Create → New Policy**.
2. **Platform:** Windows 10 and later. **Profile type:** **Templates → Custom**. Click **Create**.
3. **Name:** `WPP - Windows Protected Print (Pilot)`; add a description referencing this deployment.

### Step 3.2 — Add the OMA-URI setting
1. **Add** a row:
   - **Name:** `Configure Windows Protected Print`
   - **OMA-URI:** `./Device/Vendor/MSFT/Policy/Config/Printers/ConfigureWindowsProtectedPrint`
   - **Data type:** **String**
   - **Value:** `<enabled/>`  *(to turn WPP off later, use `<disabled/>`)*
2. Save the row.

### Step 3.3 — Scope to eligible devices only
1. **Assignments:** assign to the **pilot ring** group.
2. Add an **Intune filter** so it applies **only to Windows 11 24H2+** devices (filter on
   `osVersion`), so ineligible devices are never targeted.
3. Create. The setting writes `WindowsProtectedPrintGroupPolicyState` under
   `HKLM\Software\Policies\Microsoft\Windows NT\Printers\WPP`.

---

## Phase 4 — Pilot and validate

1. Deploy to the **pilot ring**. After the devices sync, run **`WPPRINT-Validate-Deployment.ps1`** on
   pilot devices — it confirms **WPP is enabled** (registry), that **no third-party drivers remain
   loadable**, and that a **test printer prints via the IPP class driver**.
2. **Manually validate** on at least one multifunction device: print **and scan**. Confirm the removed
   printers reinstall cleanly via Windows Ready Print.
3. Capture **what got removed** on pilot devices (from the Phase 1 inventory vs the post-deploy state) and
   confirm it matches the plan — no surprises.
4. Hold the pilot long enough to catch periodic workflows (month-end print jobs, label printers, etc.).

---

## Phase 5 — Migrate off legacy print servers

1. For printers still delivered by **print server + Point and Print + vendor driver**, cut them over to
   the **modern path** chosen in Phase 2 (direct IPP/Mopria or **Universal Print**).
2. Remove the **Point-and-Print / vendor-driver GPOs and mapped-printer logic** for migrated
   populations — WPP will block third-party Point-and-Print anyway, so leaving it in place only causes
   confusing failures.
3. Retire per-population, validating printing after each cutover. Keep the legacy path for un-migrated
   exceptions until they're remediated.

---

## Phase 6 — Roll out in rings

1. Expand WPP from pilot to production in **rings** (e.g., ring 1 → ring 2 → broad), each gated on the
   prior ring's validation.
2. Keep the **OS-version filter** on every assignment.
3. Keep **exception devices** (non-Mopria hardware, eSCL-less scanners not yet replaced) **out of WPP
   scope** until remediated; track them to closure.
4. Monitor the Intune profile's **deployment status** and help-desk tickets after each ring.

---

## Phase 7 — Validate and prevent regression

1. Re-run **`WPPRINT-Get-WPPState.ps1`** / **`WPPRINT-Validate-Deployment.ps1`** fleet-wide to confirm WPP
   is enabled where intended and printing works.
2. Document the **standard modern print path** so new printers are onboarded as **IPP/Mopria or Universal
   Print** — never a new third-party driver.
3. Keep the assessment scripts in rotation to catch a non-compliant printer/driver **before** it's
   deployed, so the fleet doesn't drift back toward third-party drivers.
