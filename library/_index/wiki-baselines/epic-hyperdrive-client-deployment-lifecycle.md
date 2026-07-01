# Epic Hyperdrive & Hyperspace Client Deployment & Lifecycle Management with Microsoft Intune

> **Version 1.0.0** · Category: Healthcare Solutions · Solution code: EPICCLIENT

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Epic Hyperdrive & Hyperspace Client Deployment & Lifecycle Management with Microsoft Intune

The Epic clinical EHR client is the most important application on a clinical endpoint — and one of the
hardest to manage well at scale. It runs on shared, always-on devices used directly in patient care
(clinical workstations, workstations-on-wheels, exam-room PCs), it must stay version-coherent with the
organization's Epic environment, and a bad client build pushed to the floor is a patient-safety event,
not just an IT incident. This solution turns Epic client deployment from a manual, error-prone task
into a **repeatable, ring-based, fully auditable lifecycle** managed through **Microsoft Intune** (and
Microsoft Configuration Manager where devices are co-managed).

## What you get

- **A productized packaging and deployment method** for the Epic client — both the current
  **Hyperdrive** (Chromium / WebView2-based) and legacy **Hyperspace** — as an Intune **Win32 app**
  with **version-pinned detection**, requirement rules, and (for Hyperdrive) a **WebView2 runtime
  dependency**.
- **Ring-based rollout** using named Entra device groups (`Epic Hyperdrive – Pilot Ring`,
  `Epic Hyperdrive – Broad Ring`, `EPIC – Clinical Workstations`) so every release and upgrade is
  proven on a small, representative set of devices before reaching the clinical floor.
- **A validation gate** — documented tests plus PowerShell tooling — confirming the correct version
  installed, the client launches and loads, and **Imprivata badge-tap into Epic still works** before
  the rollout is allowed to expand.
- **A clean lifecycle** — upgrades delivered via Intune **supersedence** (the new version
  automatically uninstalls and replaces the old), and a deliberate **retire / uninstall** path so no
  stale Epic client is ever left behind on a shared device.
- **Five operational PowerShell tools** for discovery, validation, fleet reporting, safe remediation,
  and ring-group provisioning.

## Why it matters

- **Patient-safety containment:** ring-based rollout limits the blast radius of any defective client
  build to a handful of validated, non-care devices.
- **Version coherence with Epic:** version pinning and supersedence keep the entire fleet aligned to
  the exact client version the Epic environment expects, eliminating drift and coexisting-version
  problems on shared devices.
- **Auditable, compliant change:** every deploy, upgrade, and retire is change-controlled, windowed,
  reversible, and recorded — aligned to HIPAA / HITRUST expectations for a clinical setting.

## Approach

The work follows the **standard deployment model**: **Assess → Package → Pilot → Validate → Broad
Deploy → Lifecycle (update / supersede / retire)**. Epic-specific installer, version, and
configuration values are obtained from the organization's **Epic build team / Epic UserWeb** and
substituted into an otherwise exact, vendor-accurate Intune / ConfigMgr packaging and lifecycle
method — so the deployment mechanics are correct and the Epic specifics are always authoritative.


---


# 1. Solution Overview — Epic Hyperdrive & Hyperspace Client Deployment & Lifecycle Management with Microsoft Intune

This solution gives you a repeatable, auditable way to **package, deploy, validate, update, and
retire the Epic clinical EHR client** across a clinical endpoint fleet using **Microsoft Intune**
(and Microsoft Configuration Manager / SCCM where devices are co-managed). It covers both Epic's
current **Hyperdrive** client (the Chromium / WebView2-based client) and the legacy **Hyperspace**
client, and it treats the EHR client as a managed, versioned application with a defined lifecycle —
not a one-time install.

The work follows the **standard deployment model**: **Assess → Package → Pilot → Validate → Broad
Deploy → Lifecycle (update / supersede / retire)**.

---

## What this solution delivers

- A **Win32 app package** (`.intunewin`) of the Epic client, built with the Microsoft Win32 Content
  Prep Tool, with **named detection, requirement, and (for upgrades) supersedence rules** that pin
  the deployment to the exact Epic version your environment runs.
- **Deployment rings** as named Microsoft Entra device groups — `EPIC – Clinical Workstations`
  (the population), `Epic Hyperdrive – Pilot Ring`, and `Epic Hyperdrive – Broad Ring` — so every
  release is proven on a small, representative set of clinical endpoints before it reaches the floor.
- A **validation gate** (documented tests plus PowerShell scripts) that confirms the correct version
  installed, the client launches and loads, the WebView2 runtime is present (Hyperdrive), and the
  Imprivata badge-tap single sign-on still works before the rollout is allowed to expand.
- A **lifecycle process**: upgrades delivered via Intune **supersedence** (new version automatically
  replaces and uninstalls the old one), and a clean **retire / uninstall** path for decommissioned
  versions so no stale Epic client is left behind.
- Five PowerShell tools (discovery, validation, fleet reporting, safe remediation, and ring-group
  provisioning) to operate the deployment day to day.

## Devices in scope

- **Clinical workstations** (fixed exam-room and nursing-station PCs).
- **Workstations-on-wheels (WOWs)** / mobile carts.
- **Exam-room PCs** and other shared clinical endpoints.

These are typically **shared, multi-user, always-on** devices on a clinical network, which is why
ring-based rollout, tight version pinning, and validated update windows matter more here than on a
standard office fleet.

## What is in scope vs. referenced only

**In scope (this solution):** Intune / ConfigMgr **packaging, detection, requirement and
supersedence rules, ring assignment, validation, and the update / retire lifecycle** of the Epic
client.

**Referenced only (covered in depth by separate solutions):**
- **Imprivata** single sign-on / badge-tap / EPCS configuration on clinical endpoints — this
  solution only **validates that tap-to-launch into Epic still works** after a client change.
- **Clinical peripherals** (signature pads, label/wristband printers, document scanners, card
  readers) — referenced as validation touchpoints only.

## Critical accuracy note — get the Epic specifics from your Epic build team

Epic's installer package, command-line switches, the exact **client version string**, and the
**environment / connection configuration** (which Epic environment the client points to, e.g.
PRD) are defined in **Epic's customer-only documentation (UserWeb / Galaxy)** and by **your
organization's Epic Technical Services / client systems team**. This solution **does not invent**
Epic-internal installer flags or version numbers — and you should not either.

Throughout the Implementation Guide you will see placeholders such as
`<EPIC_INSTALLER>`, `<EPIC_VERSION>`, `<EPIC_INSTALL_DIR>`, and `<EPIC_EXE>`. **Obtain the real
values from your Epic build team / Epic UserWeb** and substitute them consistently. The Intune /
ConfigMgr mechanics around those values — packaging, detection, rings, supersedence, retire — are
documented here exactly and accurately.

## Why this approach

- **Patient-safety / clinical continuity:** the EHR client is mission-critical. Ring-based rollout
  contains the blast radius of a bad client build to a handful of validated devices, not the whole
  floor.
- **Version coherence with Epic:** Epic client versions are tied to your Epic environment's upgrade
  cadence. Pinning the deployed version (via detection) and upgrading via supersedence keeps the
  fleet aligned to the version Epic expects you to run.
- **Clean lifecycle:** supersedence and a defined retire path prevent the classic problem of
  multiple Epic client versions accreting on shared clinical devices.

## How to use this package

Read the documents in order:
1. **02 – Requirements** and **global-requirements-healthcare-solutions** — confirm everything is in
   place before you build anything.
2. **03 – Implementation** — package, pilot, validate, broad-deploy, then run the lifecycle.
3. **05 – Testing** — the acceptance gate that must pass before expansion.
4. **07 – Best Practices**, **08 – Deliverables Summary**, and **06 – Troubleshooting** as needed.


---


# 2. Requirements Guide — Epic Hyperdrive & Hyperspace Client Deployment & Lifecycle Management with Microsoft Intune

Verify **every** requirement below before you package or deploy anything. Each entry follows the same
pattern: **Description · Why required · How to verify · How to implement if missing.** Do **not**
assume any prerequisite already exists.

> Category-wide prerequisites (a tenant, Intune subscription, device enrollment, HIPAA / HITRUST
> change control, clinical maintenance windows, a test device, rollback posture, etc.) are documented
> once in **`global-requirements-healthcare-solutions.md`**. This guide lists what is **specific to**
> deploying the Epic client.

---

## R1. Microsoft Intune licensing and app-management rights
**Description:** An Intune subscription and an operator with rights to create and assign **Windows
apps** (Intune Administrator or Application Manager).
**Why required:** The Epic client is delivered as an Intune **Win32 app**; without app-management
rights you cannot create the package, detection rules, or assignments.
**How to verify:** `https://intune.microsoft.com` → **Apps → Windows** loads and **+ Add** is
available; Entra → **Roles and administrators** shows the operator's role.
**How to implement if missing:** Assign an Intune-bearing license and the **Intune Administrator** (or
**Application Manager**) role to the operator. See global requirement G1.

## R2. Microsoft Win32 Content Prep Tool
**Description:** The **Microsoft Win32 Content Prep Tool** (`IntuneWinAppUtil.exe`), used to wrap the
Epic installer and its files into a single `.intunewin` package.
**Why required:** Intune Win32 apps are deployed only as `.intunewin` packages; this is the only
supported way to wrap them.
**How to verify:** `IntuneWinAppUtil.exe -v` runs from your packaging workstation.
**How to implement if missing:** Download the Win32 Content Prep Tool from Microsoft's official
GitHub repository (`microsoft/Microsoft-Win32-Content-Prep-Tool`) onto a clean packaging
workstation. Keep it current.

## R3. The Epic installer — obtained from Epic Technical Services / UserWeb
**Description:** The exact **Epic client installer** (Hyperdrive and/or Hyperspace), its **silent
install / uninstall command lines**, the target **client version string**, the **install directory**,
the **launch executable**, and the **environment / connection configuration** for your Epic
environment.
**Why required:** These values drive the install command, the version-pinned detection rule, the
requirement rule, and the supersedence relationship. They are **Epic-specific and customer-only** —
they are not documented here and must not be guessed.
**How to verify:** Confirm with your **Epic build / Technical Services team** that you have the
correct installer and switches for your environment, sourced from **Epic UserWeb / Galaxy**. Run the
installer's silent command on the test device once, by hand, to confirm it installs cleanly and
unattended.
**How to implement if missing:** Request the installer package, silent switches, version string, and
environment configuration from your Epic build team / Epic UserWeb. Record them as the placeholder
values `<EPIC_INSTALLER>`, `<EPIC_SILENT_ARGS>`, `<EPIC_VERSION>`, `<EPIC_INSTALL_DIR>`,
`<EPIC_EXE>`, and `<EPIC_UNINSTALL_CMD>` used throughout the Implementation Guide.

## R4. Target operating system — Windows 10 / Windows 11
**Description:** Clinical endpoints run a supported, patched **Windows 10 (21H2+)** or **Windows 11**,
x64.
**Why required:** The Epic client and the WebView2 runtime (for Hyperdrive) require a current,
supported Windows build; the Win32 app **requirement rule** will target these OS versions.
**How to verify:** `winver` on a device, or Intune → device → **Hardware**.
**How to implement if missing:** Patch via Update rings or upgrade devices. See global requirement G2.

## R5. WebView2 runtime (Hyperdrive prerequisite)
**Description:** The **Microsoft Edge WebView2 Runtime** present on every device that will run
**Hyperdrive** (Hyperdrive is Chromium / WebView2-based).
**Why required:** Hyperdrive will not launch or render without the WebView2 runtime; this is the most
common Hyperdrive launch failure.
**How to verify:** Run **`EPICCLIENT-Validation.ps1`** (checks for the WebView2 runtime), or check
**Apps & features** / the registry for *Microsoft Edge WebView2 Runtime*.
**How to implement if missing:** Deploy the **Evergreen WebView2 Runtime** as its own Intune Win32 /
Microsoft Store app and set it as a **dependency** of the Epic Hyperdrive app (Implementation Step 6),
so WebView2 installs first. Modern Windows 11 includes WebView2, but **do not assume it** — verify.

## R6. Configuration Manager co-management (only if applicable)
**Description:** If clinical endpoints are **co-managed** with Microsoft Configuration Manager (SCCM),
confirm which authority owns **client apps** — Intune or ConfigMgr.
**Why required:** With co-management, the **Client apps** workload must be pointed at Intune (or at
ConfigMgr) so app assignments take effect from the expected authority and you do not deploy the same
client twice.
**How to verify:** Intune → **Devices → Configuration Manager → Co-management**, review the
**Client apps** workload slider; or in the ConfigMgr console, review co-management settings.
**How to implement if missing:** Decide the authority. To deploy via Intune, move the **Client apps**
workload to **Intune** (or **Pilot Intune** scoped to the pilot collection). If you keep apps in
ConfigMgr, deploy the same package as a ConfigMgr Application with equivalent detection / supersedence.

## R7. Entra device groups for deployment rings
**Description:** Microsoft Entra **device** groups for the population and the rings:
**`EPIC – Clinical Workstations`** (all in-scope clinical endpoints),
**`Epic Hyperdrive – Pilot Ring`**, and **`Epic Hyperdrive – Broad Ring`**.
**Why required:** Ring-based rollout is how a bad client build is contained to a few validated devices.
Assignments target these named groups.
**How to verify:** Entra → **Groups → All groups**; the three groups exist with intended membership.
**How to implement if missing:** Create them in Entra (or run
**`EPICCLIENT-Set-DeploymentRings.ps1`**), which creates `Epic Hyperdrive – Pilot Ring` and
`Epic Hyperdrive – Broad Ring` and can wire ring assignments via Microsoft Graph.

## R8. Detection / version strategy
**Description:** A decided, reliable way for Intune to detect "the target Epic version is installed" —
a **file version** of `<EPIC_EXE>` in `<EPIC_INSTALL_DIR>`, a **registry** uninstall key/version, or
an **MSI product code** — matching how `<EPIC_INSTALLER>` actually registers.
**Why required:** The detection rule is what tells Intune the app is installed and at the right
version; a wrong rule causes endless re-installs or false "installed" states.
**How to verify:** On the test device after a manual install, inspect the file version of
`<EPIC_EXE>` and the registry uninstall key; run **`EPICCLIENT-Discovery.ps1`** to read the installed
version. Confirm those values match what your detection rule will assert.
**How to implement if missing:** Choose the most stable signal (file version is usually best for the
Epic client), and record the exact detection values for the Implementation Guide.

## R9. A test clinical device (not in patient care)
**Description:** A representative, enrolled, non-production clinical device (ideally one fixed
workstation and one WOW) in **`Epic Hyperdrive – Pilot Ring`**.
**Why required:** Packaging, detection, launch, and Imprivata-tap validation must be proven before any
device in care receives the client.
**How to verify:** The device is enrolled, compliant, and a member of `Epic Hyperdrive – Pilot Ring`.
**How to implement if missing:** Set aside the device and add it to the pilot ring group. See global
requirement G7.

## R10. Approved clinical change window and rollback plan
**Description:** A change-control approval, an agreed **clinical maintenance window** for the broad
deployment, and a documented **rollback** (revert to the previously validated package/version).
**Why required:** Deploying or reverting the EHR client touches patient-care devices; it must be
change-managed, windowed, and reversible.
**How to verify:** A CAB-approved change ticket exists with window and back-out plan, naming the
previously validated package to revert to.
**How to implement if missing:** Route through your CAB; keep the prior validated `.intunewin` and its
detection values for rollback. See global requirements G4, G5, G8.

## R11. Imprivata present (only if integrating SSO / badge-tap)
**Description:** If your clinical endpoints use **Imprivata** for single sign-on / badge-tap into
Epic, confirm the Imprivata agent is installed and healthy on the test device **before** changing the
Epic client.
**Why required:** A new Epic client version can change launch behavior; you must confirm
tap-to-launch into Epic still works after the change. (Imprivata configuration itself is a separate
solution; here it is a **validation touchpoint** only.)
**How to verify:** On the test device, confirm the Imprivata agent service is running and a badge tap
launches into Epic prior to the change; re-test after (Testing §, Test 6).
**How to implement if missing:** Engage the separate Imprivata solution / your Imprivata
administrators. If you do **not** use Imprivata, this requirement is N/A — skip the related test.

---

## Requirements checklist (use before packaging)
- [ ] **R1** Intune app-management rights (Intune Administrator / Application Manager)
- [ ] **R2** Win32 Content Prep Tool (`IntuneWinAppUtil.exe`) available
- [ ] **R3** Epic installer + silent switches + version + install dir + exe + uninstall cmd from Epic TS/UserWeb
- [ ] **R4** Supported, patched Windows 10/11 (x64)
- [ ] **R5** WebView2 runtime present (Hyperdrive) — `EPICCLIENT-Validation.ps1`
- [ ] **R6** Co-management **Client apps** workload authority decided (if co-managed)
- [ ] **R7** Entra groups `EPIC – Clinical Workstations`, `Epic Hyperdrive – Pilot Ring`, `Epic Hyperdrive – Broad Ring`
- [ ] **R8** Detection / version strategy chosen and verified — `EPICCLIENT-Discovery.ps1`
- [ ] **R9** Test clinical device (fixed + WOW) in the pilot ring
- [ ] **R10** CAB-approved change window + rollback to prior validated package
- [ ] **R11** Imprivata agent healthy on test device (only if integrating badge-tap)


---


# Global Requirements — Healthcare Solutions (category-level)

These requirements apply to **every** solution in the **Healthcare Solutions** category. They are
published once at the category level so individual solution listings stay focused. Confirm all of
them are in place before deploying *any* Healthcare Solutions product into a clinical environment.

Each entry: **Description · Why required · How to verify · How to implement if missing.**

> Clinical environments carry obligations (HIPAA, often HITRUST) and uptime expectations that a
> standard office fleet does not. Treat every change as a controlled clinical change, not an ad-hoc
> IT task.

## G1. Microsoft 365 / Intune tenant with admin roles
**Description:** An active Microsoft Entra ID tenant with a Microsoft Intune subscription, and an
operator holding **Intune Administrator** (or **Application Manager** / **Endpoint Security Manager**
as appropriate).
**Why:** Intune is the delivery channel for every configuration and application in this category;
authoring apps and assignments requires elevated rights.
**Verify:** `https://intune.microsoft.com` loads; **Tenant administration → Tenant status** shows an
active subscription; Entra → **Roles and administrators** shows the operator's role.
**Implement:** Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1; assign the
operator **Intune Administrator**. Reserve Global Administrator for tenant-wide setup only.

## G2. Windows licensing for managed clinical endpoints
**Description:** Targeted devices run a supported, licensed **Windows 10 / Windows 11**
(Enterprise or Pro) with current cumulative updates.
**Why:** Modern Intune app-management and security features assume a patched, supported OS.
**Verify:** `winver` on a device, or Intune → device → **Hardware**.
**Implement:** Apply correct Windows licensing; deploy **Update rings**
(Intune → **Devices → Windows → Update rings**) or upgrade devices to a supported build.

## G3. Devices enrolled and identity-joined
**Description:** Clinical endpoints are **Intune-enrolled** and **Microsoft Entra joined** (or
**hybrid Entra joined** where co-managed with Configuration Manager).
**Why:** Policies and apps only reach enrolled, identity-bound devices, and assignments are scoped to
Entra device groups.
**Verify:** Intune → **Devices → All devices** (device present, compliant); on the device
`dsregcmd /status` shows `AzureAdJoined : YES` (or `DomainJoined : YES` + `AzureAdJoined : YES` for
hybrid).
**Implement:** Enroll via Autopilot or **Settings → Accounts → Access work or school**; for hybrid,
configure Entra Connect + group policy / co-management.

## G4. HIPAA / HITRUST data-handling and clinical change control
**Description:** A documented change-control process for clinical endpoints, and data-handling that
keeps **electronic protected health information (ePHI)** in-bounds — no ePHI in logs, exports, or
script output; least-privilege access; auditable changes.
**Why:** Clinical endpoints handle ePHI; uncontrolled changes risk both patient safety and
HIPAA / HITRUST compliance. Every deployment, update, and retire action must be change-managed and
auditable.
**Verify:** Confirm a change ticket / change-advisory-board (CAB) approval exists for the deployment;
confirm the scripts and reports in use do **not** capture patient data (the tools in this category
are read-only over device/app state, not over clinical content).
**Implement:** Route the change through your CAB; record the approved change window, rollback plan,
and back-out criteria; restrict who can run deployment actions; retain change records per your
compliance program.

## G5. Clinical maintenance windows
**Description:** Approved, low-acuity maintenance windows during which clinical endpoints may be
changed or rebooted, agreed with clinical operations.
**Why:** Pushing an app or reboot during patient care is unacceptable; shared clinical devices are
often in use around the clock.
**Verify:** A documented maintenance-window schedule exists and is referenced in the change ticket.
**Implement:** Agree windows with clinical operations / nursing leadership; align Intune assignment
**availability** and any restart behavior to those windows.

## G6. Network access to Microsoft and vendor service endpoints
**Description:** Outbound HTTPS from clinical endpoints to **Microsoft 365 / Entra / Intune** service
URLs, plus any **vendor endpoints** the solution requires (for this category, the Epic environment
and Microsoft content-delivery endpoints for app payloads and the WebView2 runtime).
**Why:** Enrollment, policy sync, app delivery, and authentication all depend on these endpoints.
**Verify:** From a device, reach `https://login.microsoftonline.com` and
`https://enrollment.manage.microsoft.com`; confirm app installs report **Succeeded** in Intune.
**Implement:** Allow Microsoft's published Office 365 / Intune URL & IP ranges, plus the vendor
endpoints your build team specifies, through proxy / firewall.

## G7. A non-production / test clinical device
**Description:** At least one **dedicated test device** representative of the clinical fleet (ideally
one of each form factor — fixed workstation and a WOW) that is **not in live patient care**.
**Why:** Every change is proven on a test device before any pilot or broad assignment touches a
device used for care.
**Verify:** The test device is enrolled, in the pilot ring group, and flagged as non-production.
**Implement:** Set aside a representative device; add it to the pilot ring group used by the solution.

## G8. Rollback posture
**Description:** A defined back-out plan for every change: how to revert the app, how to restore the
previously known-good client version, and the criteria that trigger a rollback.
**Why:** In a clinical setting a failed change must be reversible quickly to protect care delivery.
**Verify:** The change ticket includes a rollback plan and a named previously-validated version /
package to revert to.
**Implement:** Keep the prior validated `.intunewin` package and its detection values; document the
revert steps (re-assign prior version / remove the new assignment) before deploying the new one.

---
**The standard deployment model (all solutions): Assess → Configure → Pilot → Validate → Expand.**
For application-lifecycle solutions in this category this is realized as
**Assess → Package → Pilot → Validate → Broad Deploy → Lifecycle (update / supersede / retire)**.


---


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


---


# 5. Testing Guide — Epic Hyperdrive & Hyperspace Client Deployment & Lifecycle Management with Microsoft Intune

Run these validations after the pilot is deployed (Implementation Phase D) and again after the broad
deployment and after every lifecycle change (upgrade / retire). Each test states **what to do** and
the **expected (PASS) result**. **Do not expand the rollout until every pilot test passes.**

> Run on a device in **`Epic Hyperdrive – Pilot Ring`** first. Use the scripts where named; capture
> results in your change log for the clinical change record.

## Test 1 — The Epic client installed
**Do:** On a pilot device run **`EPICCLIENT-Discovery.ps1`**, or check `<EPIC_INSTALL_DIR>` for
`<EPIC_EXE>`.
**PASS:** The Epic client is present in `<EPIC_INSTALL_DIR>`; Discovery reports an installed version.
**FAIL:** Not installed — see Troubleshooting §6 (install failures) and `EPICCLIENT-Remediation.ps1`.

## Test 2 — The installed version is the target version
**Do:** Run **`EPICCLIENT-Validation.ps1`** (compares the installed version to the target), or read
the file version of `<EPIC_EXE>`.
**PASS:** Installed version **equals** `<EPIC_VERSION>` (the value pinned in the detection rule).
**FAIL:** Version mismatch — detection rule or supersedence issue (Troubleshooting §6, version drift).

## Test 3 — Intune reports the app Installed (no errors)
**Do:** Intune → **Apps → Windows → `Epic Hyperdrive – <EPIC_VERSION>` → Device install status**.
**PASS:** Pilot devices show **Installed**; no **Failed** or detection-mismatch states.
**FAIL:** Failed / "Not installed" despite the binary present → detection-rule mismatch
(Troubleshooting §6).

## Test 4 — The client launches and loads
**Do:** On the pilot device, launch the Epic client (Hyperdrive or Hyperspace) as a clinical user.
**PASS:** The client opens, renders fully, and connects to the **correct Epic environment**. For
**Hyperdrive**, the WebView2 surface renders (no blank / white window).
**FAIL:** Crash, blank window, or wrong environment → Troubleshooting §6 (WebView2 / launch issues).

## Test 5 — WebView2 runtime present (Hyperdrive)
**Do:** Run **`EPICCLIENT-Validation.ps1`** (checks the WebView2 runtime).
**PASS:** The **Microsoft Edge WebView2 Runtime** is present and reported.
**FAIL:** Missing → deploy/repair WebView2 (Requirements §R5, Implementation Step 6).
*(N/A for Hyperspace-only deployments.)*

## Test 6 — Imprivata badge-tap into Epic still works (if integrating)
**Do:** On the pilot device, perform a **badge tap** and confirm tap-to-launch / SSO into the Epic
client.
**PASS:** The tap launches and authenticates into Epic as before the client change.
**FAIL:** Tap no longer launches Epic → confirm the Imprivata agent is healthy and engage the
separate Imprivata solution / administrators (this solution does not configure Imprivata).
*(N/A if you do not use Imprivata — Requirements §R11.)*

## Test 7 — No leftover old version after an upgrade / retire
**Do:** After a supersedence upgrade (Step 15) or a retire (Step 16), run
**`EPICCLIENT-Discovery.ps1`** / **`EPICCLIENT-Validation.ps1`**.
**PASS:** Only the **intended** version is present (or, for a retire, **no** Epic client remains); no
second/old version coexists in `Apps & features` or `<EPIC_INSTALL_DIR>`.
**FAIL:** Old version still present → Troubleshooting §6 (supersedence not upgrading / retire
leftovers).

## Test 8 — Ring rollout is healthy
**Do:** Run **`EPICCLIENT-Report.ps1`** and review Intune **Device install status** per ring.
**PASS:** `Epic Hyperdrive – Pilot Ring` is fully Installed at the target version **before** broad;
after broad, `Epic Hyperdrive – Broad Ring` converges to the target version with an acceptable
failure rate.
**FAIL:** Stuck installs / mixed versions in a ring → Troubleshooting §6 (ring / assignment
problems).

## Test 9 — Device compliance and clinical function intact
**Do:** Intune → **Devices → Compliance** for the pilot/broad devices; confirm clinical peripherals
relied on at launch (badge reader, etc.) still function.
**PASS:** Devices remain **Compliant**; no new failures introduced by the client change.
**FAIL:** New compliance failures or broken clinical function → roll back per Requirements §R10.

---

## Acceptance gate

| Gate | Requirement |
|---|---|
| **Pilot pass (required before broad deploy)** | Tests **1, 2, 3, 4, 8, 9** pass for **100%** of `Epic Hyperdrive – Pilot Ring`; **Test 5** passes for Hyperdrive; **Test 6** passes if Imprivata is integrated |
| **Broad pass** | Tests **1, 2, 3, 4, 8** pass across `Epic Hyperdrive – Broad Ring` at an agreed success threshold; **Test 9** shows no new compliance failures |
| **Lifecycle pass (after upgrade / retire)** | **Test 7** passes (no leftover old version), plus Tests 2, 4, 8 for the new state |

Record results in the clinical change log. If any test fails, use the **Troubleshooting Guide
(Section 6)** and **`EPICCLIENT-Remediation.ps1`** before proceeding, and trigger the rollback plan
if the failure affects patient-care devices.


---


# 6. Troubleshooting Guide — Epic Hyperdrive & Hyperspace Client Deployment & Lifecycle Management with Microsoft Intune

Work top-down: confirm the requirement, reproduce on the **test device** first, and only then act on
patient-care devices. Where a script helps, it is named. For Epic-installer specifics (switches,
version strings, environment config), confirm with your **Epic build team / Epic UserWeb** —
this guide covers the **Intune / ConfigMgr** mechanics.

---

## A. Install fails or never starts

**Symptom:** Intune → **Apps → Windows → `Epic Hyperdrive – <EPIC_VERSION>` → Device install status**
shows **Failed**, or the install never runs.

1. **Silent command not actually silent.** Re-run `<EPIC_INSTALLER> <EPIC_SILENT_ARGS>` by hand on the
   test device (Implementation Step 2). If it prompts, the Intune **Install command** is wrong — get
   the correct silent switches from your Epic build team and update **Program → Install command**.
2. **Requirement rule excludes the device.** Check **Properties → Requirements** — wrong minimum OS /
   architecture will leave the app **Not applicable**. Confirm the device meets it (`winver`).
3. **WebView2 dependency failing (Hyperdrive).** If the WebView2 dependency app is failing, the Epic
   app won't proceed. Check the WebView2 app's own install status; fix it first (Section D).
4. **Install behavior wrong.** Shared clinical devices need **Install behavior = System**. A
   per-user install on a shared device misbehaves — set it to **System**.
5. **Non-standard return codes.** If `<EPIC_INSTALLER>` returns a code Intune treats as failure,
   map it under **Program → Return codes** (e.g. add the installer's success/soft-reboot codes).
6. **Nudge the device:** run **`EPICCLIENT-Remediation.ps1 -AppName "Epic Hyperdrive - <EPIC_VERSION>" -Apply`**
   to force an MDM sync, wait, then re-check.

## B. Detection mismatch (installs but Intune says "Not installed", or re-installs in a loop)

**Symptom:** The Epic client is clearly on the device, but Intune reports **Not installed** (or
keeps reinstalling).

1. **Detection value doesn't match reality.** On the test device run **`EPICCLIENT-Discovery.ps1`** and
   compare the **actual** version / path / registry key to the **detection rule** (Implementation
   Step 7). They must match exactly.
2. **Wrong detection type.** If the installer registers an MSI product code, a **File version** rule
   on the wrong path won't detect it (and vice-versa). Switch the rule type to match how
   `<EPIC_INSTALLER>` actually registers (Requirements §R8).
3. **Operator too strict/loose.** A **String (version) – Greater than or equal to** rule against
   `<EPIC_VERSION>` is usually right. An **Equals** on a version that the installer formats slightly
   differently will read as "not installed."
4. **Path with environment specifics.** Ensure `<EPIC_INSTALL_DIR>` / `<EPIC_EXE>` in the rule are the
   real installed path/name, not a guess.

## C. Version drift (devices stuck on an old version)

**Symptom:** **`EPICCLIENT-Report.ps1`** shows a mix of versions; some devices never moved to
`<EPIC_VERSION>`.

1. **Device not in the assigned ring.** Confirm the device is a member of `Epic Hyperdrive – Pilot
   Ring` / `Epic Hyperdrive – Broad Ring` (whichever the new app is assigned to). Add it if missing
   (or run **`EPICCLIENT-Set-DeploymentRings.ps1`**).
2. **Superseding app not assigned.** Supersedence only acts where the **new** app is assigned — see
   Section E.
3. **Device not syncing.** Force a sync (**Access work or school → Sync**) or run
   **`EPICCLIENT-Remediation.ps1 … -Apply`**.
4. **Stale install failure** on those devices — drill into **Device install status** for the error and
   apply Section A.

## D. Hyperdrive won't launch (blank/white window, crash) — WebView2

**Symptom:** Hyperdrive installs but shows a blank/white window, fails to render, or crashes at launch.

1. **WebView2 runtime missing.** This is the most common cause. Run **`EPICCLIENT-Validation.ps1`**;
   if **WebView2 runtime present = FAIL**, deploy/repair the **Evergreen WebView2 Runtime** and set it
   as a **dependency** (auto-install = Yes) of the Hyperdrive app (Requirements §R5, Implementation
   Step 6).
2. **WebView2 present but broken.** Repair/reinstall the WebView2 runtime app via Intune, then relaunch.
3. **Wrong Epic environment / config.** If it launches but connects to the wrong environment, the
   client configuration is off — confirm the environment/connection values with your Epic build team
   (out of scope for packaging, but a common "looks broken" report).
4. **Hyperspace, not Hyperdrive.** If you are deploying legacy **Hyperspace**, WebView2 is N/A — don't
   chase a WebView2 fix for a Hyperspace launch issue.

## E. Supersedence not upgrading (old version stays)

**Symptom:** You created a new app and a supersedence relationship, but devices keep the old version.

1. **New app not assigned to the devices.** Supersedence requires the **new** app to be **assigned**
   (Required) to the ring (Implementation Step 15.5). Assign `Epic Hyperdrive – <EPIC_VERSION_NEW>` to
   the pilot ring first, then broad.
2. **"Uninstall previous version" not set.** On the new app → **Supersedence**, confirm the relationship
   to `Epic Hyperdrive – <EPIC_VERSION>` has **Uninstall previous version = Yes** for a clean replace.
3. **Old app's detection still satisfied / old app still required.** If the **old** app is still
   assigned **Required** to the same devices, the two assignments fight. Remove the old app's Required
   assignment once supersedence is in place.
4. **Not synced yet.** Allow time and force a sync; supersedence evaluation isn't instant.
5. **Detection on the new app wrong.** If the new app's version-pinned detection is wrong, Intune
   thinks the upgrade failed — re-check per Section B.

## F. Retire leftovers (old client remains after retire)

**Symptom:** After retiring a version (Implementation Step 16), the old client is still present.

1. **Uninstall command wrong.** The app's **Program → Uninstall command** (`<EPIC_UNINSTALL_CMD>`) must
   silently remove the client. Test it by hand on the test device; correct it with your Epic build
   team's switches.
2. **Uninstall assignment missing the device.** Confirm you added the device's group to the app's
   **Uninstall** assignment, and removed any **Required** assignment that would reinstall it.
3. **Verify and finish.** Run **`EPICCLIENT-Discovery.ps1`** / **`EPICCLIENT-Validation.ps1`**; only
   delete the old Win32 app after devices report the uninstall (keep the prior `.intunewin` for
   rollback per Requirements §R10).

## G. Ring / assignment problems

**Symptom:** The wrong devices got the app, or a ring is mixed/stuck.

1. **Group membership.** Confirm `EPIC – Clinical Workstations`, `Epic Hyperdrive – Pilot Ring`, and
   `Epic Hyperdrive – Broad Ring` contain the intended **devices** (these are device groups). Fix
   membership in Entra or via **`EPICCLIENT-Set-DeploymentRings.ps1`**.
2. **Assigned too broadly too soon.** If broad got it before pilot was validated, remove the broad
   **Required** assignment, re-validate pilot, then re-add broad in the change window.
3. **Overlapping/contradictory assignments.** Avoid assigning both **Required** and **Uninstall** for
   the same app to overlapping groups — they conflict. Keep one intent per group.
4. **Co-management authority.** If devices are co-managed and the **Client apps** workload points at
   ConfigMgr, Intune app assignments won't apply — set the workload authority correctly
   (Requirements §R6).

## H. Imprivata badge-tap no longer launches Epic after a client change

**Symptom:** Tap-to-launch / SSO into Epic stopped working after deploying/upgrading the client.

1. **Confirm Imprivata agent health** on the device (service running). Imprivata configuration is a
   **separate solution** — this solution only validates the tap.
2. **Launch target changed.** A new client version can change the launch executable/path Imprivata
   targets; engage your Imprivata administrators / the Imprivata solution to update the profile.
3. **Re-test** with Testing §6 once corrected. If you don't use Imprivata, this is N/A.

---

## Escalation / rollback
If a failure affects **patient-care** devices and a quick fix isn't in hand, **invoke the rollback
plan** (Requirements §R10): re-assign the previously validated package/version (or remove the new
assignment), confirm with **`EPICCLIENT-Validation.ps1`**, and record the back-out in the clinical
change log. For Epic-installer behavior beyond packaging (switches, version strings, environment
config), escalate to your **Epic build team / Epic Technical Services**.


---


# 7. Best Practices — Epic Hyperdrive & Hyperspace Client Deployment & Lifecycle Management with Microsoft Intune

These practices keep the Epic client deployment safe, version-coherent with Epic, and clean over its
lifecycle on shared clinical endpoints.

## Source of truth: Epic owns the installer, you own the delivery
- **Always** take the installer, silent switches, version string, and environment configuration from
  your **Epic build team / Epic UserWeb** — never guess Epic-internal flags or version numbers.
- Re-confirm these values **each Epic upgrade**; they can change between Epic versions.
- Keep a small internal record (not in this package) mapping each `<EPIC_VERSION>` to the Epic
  environment, installer, and switches you packaged.

## Pin the version with detection — and keep detection honest
- Use a **version-pinned detection rule** (file version of `<EPIC_EXE>` is usually the most stable).
- After every package, **verify the detection value against a real install** on the test device
  (`EPICCLIENT-Discovery.ps1`) before assigning — a wrong rule causes endless re-installs or false
  "installed" states.
- Prefer **file version** over a registry DisplayVersion if the installer's registry value is
  inconsistent across builds.

## Always pilot before broad — and let supersedence respect rings
- Every release and every **upgrade** goes to **`Epic Hyperdrive – Pilot Ring`** and is fully
  validated (Testing §) **before** **`Epic Hyperdrive – Broad Ring`**.
- For upgrades, assign the **new** superseding app to the pilot ring first; supersedence respects
  assignment scope, so the broad fleet only upgrades once pilot is proven.
- Keep the pilot ring **representative** — include at least one fixed clinical workstation and one
  **WOW**, since form factors behave differently (battery, dock, network).

## Treat the WebView2 runtime as a first-class dependency (Hyperdrive)
- Deploy the **Evergreen WebView2 Runtime** as its own app and set it as a **dependency** (auto-install
  = Yes) of the Hyperdrive app, so it is present **before** Hyperdrive installs/launches.
- Do **not** assume Windows 11 already has WebView2 — verify with `EPICCLIENT-Validation.ps1`.

## Upgrade cleanly with supersedence; retire deliberately
- For upgrades, use **supersedence with "Uninstall previous version = Yes"** so the old client is
  removed before the new one installs — this prevents multiple Epic versions accreting on shared
  devices.
- For decommissioned versions not being superseded, retire via an **Uninstall assignment**, then
  verify nothing is left behind (`EPICCLIENT-Discovery.ps1`).
- Keep the **previous validated `.intunewin`** and its detection values until the new version is fully
  proven, so rollback is one assignment away.

## Respect the clinical environment
- **Install behavior = System**, **device restart behavior = No specific action** — never force a
  reboot on a shared clinical device; control restarts through the approved **maintenance window**.
- Align assignment **availability** to the maintenance window; communicate changes to clinical
  operations in advance.
- Every deploy / upgrade / retire is a **change-controlled** action with an approved window and a
  documented **rollback** (global requirements G4, G5, G8).

## Co-management clarity
- If devices are co-managed, decide **one** authority for **client apps** (Intune **or** ConfigMgr)
  and stick to it, so the Epic client is never deployed twice from two systems.

## Protect ePHI in operations
- The tools in this package are **read-only over device/app state** and must **never** capture
  patient data. Keep logs and CSV reports limited to device, version, and install-state fields.
- Restrict who can run deployment/uninstall actions; retain change records per your compliance program.

## Operate on a cadence
- Run **`EPICCLIENT-Report.ps1`** on a schedule to watch for **version drift** (devices that fell
  behind) and to confirm each ring is converged.
- After any change, sample devices with **`EPICCLIENT-Validation.ps1`**; use
  **`EPICCLIENT-Remediation.ps1`** (`-WhatIf` first, then `-Apply`) for one-off recoveries rather than
  re-broadcasting to a whole ring.


---


# 8. Deliverables Summary — Epic Hyperdrive & Hyperspace Client Deployment & Lifecycle Management with Microsoft Intune

This solution is delivered as a complete, click-to-implement package: implementation documentation, an
operational PowerShell toolkit, and a hero image.

## Documentation

| Document | Purpose |
|---|---|
| **executive-summary.md** | Business-level overview, value, and approach for decision-makers. |
| **01-solution-overview.md** | What the solution delivers, devices in scope, scope boundaries, and how to use the package. |
| **02-requirements.md** | Epic-deployment-specific requirements (R1–R11), each with Description / Why / Verify / Implement, plus a checklist. |
| **global-requirements-healthcare-solutions.md** | Category-wide prerequisites: tenant + roles, Windows licensing, HIPAA/HITRUST change control, clinical maintenance windows, network, test device, rollback. |
| **03-implementation.md** | Ordered, full-navigation steps: package the Win32 `.intunewin`, version-pinned detection, ring groups, pilot assign, validate, broad deploy, then lifecycle (supersede / retire). |
| **05-testing.md** | Numbered tests with PASS/FAIL gates and the acceptance gate that must pass before expansion. |
| **07-best-practices.md** | Operating practices for version pinning, ring discipline, WebView2, supersedence/retire, and clinical-environment safety. |
| **06-troubleshooting.md** | Fixes for install failures, detection mismatch, version drift, Hyperdrive/WebView2 launch issues, supersedence not upgrading, retire leftovers, and ring/assignment problems. |

## PowerShell toolkit (`scripts\`)

| Script | What it does |
|---|---|
| **EPICCLIENT-Discovery.ps1** | Inventories the installed Epic client version and basic health across managed devices. Read-only. |
| **EPICCLIENT-Validation.ps1** | Verifies a device has the **target version**, the app install state, and launch prerequisites (WebView2 for Hyperdrive); emits PASS/FAIL and an overall verdict. |
| **EPICCLIENT-Report.ps1** | Produces a fleet rollout / version report (per-ring counts, version spread) to **CSV**. |
| **EPICCLIENT-Remediation.ps1** | Safely re-triggers install or uninstall of a **named** Win32 app for a device (MDM sync / install-state nudge). Read-only / `-WhatIf` by default; `-Apply` to act. |
| **EPICCLIENT-Set-DeploymentRings.ps1** | Creates the **`Epic Hyperdrive – Pilot Ring`** and **`Epic Hyperdrive – Broad Ring`** Entra device groups and (optionally) wires ring assignments via Microsoft Graph. Supports `-WhatIf`. |

Each script carries a `.SYNOPSIS` plus **PURPOSE / HOW TO RUN / EXPECTED RESULTS** in its header.

## Visual asset

| Asset | Purpose |
|---|---|
| **EPICCLIENT-hero.png** | Hero image for the solution listing. |

## Named objects you create (reused verbatim across the docs and scripts)

- **Win32 app:** `Epic Hyperdrive – <EPIC_VERSION>` (legacy: `Epic Hyperspace – <EPIC_VERSION>`)
- **Detection rule:** `Epic Client – Version Detection`
- **Supersedence relationship:** `Epic Hyperdrive – Supersede <EPIC_VERSION>→<EPIC_VERSION_NEW>`
- **Entra device groups / rings:** `EPIC – Clinical Workstations`, `Epic Hyperdrive – Pilot Ring`,
  `Epic Hyperdrive – Broad Ring`

> Epic-specific values (`<EPIC_INSTALLER>`, `<EPIC_VERSION>`, `<EPIC_INSTALL_DIR>`, `<EPIC_EXE>`,
> `<EPIC_SILENT_ARGS>`, `<EPIC_UNINSTALL_CMD>`) come from your **Epic build team / Epic UserWeb** and
> are substituted consistently throughout.
