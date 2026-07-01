# 3. Implementation — Workspace ONE to Microsoft Intune Migration Program (Windows, iOS/iPadOS, Android, macOS)

This is the **program runbook**. It follows the standard program model — **Discover → Assess → Plan → Configure → Pilot → Validate (pilot-wave gate) → Expand (coexistence → cutover → validate) → Decommission** — and contains a phase-by-phase methodology plus a self-contained runbook for each of the four platform workstreams.

> **Vendor boundary (read first):** the **Microsoft Intune / Entra / Apple Business Manager** side is given as exact navigation. The **Workspace ONE (VMware)** side is named by **action and control** only — exact Workspace ONE console menus are deferred to current VMware documentation. Target portals used below:
> - Microsoft Intune admin center: `https://intune.microsoft.com`
> - Microsoft Entra admin center: `https://entra.microsoft.com`
> - Apple Business Manager: `https://business.apple.com`
> - Managed Google Play / Google admin: reached through the Intune Android enrollment connector.

> **Naming convention (mandatory, reused verbatim):** every created object is `<Purpose> – <Scope> – <Stage>`. **Scope** = `Windows | iOS | Android | macOS | All | Identity`; **Stage** = `Source` (Workspace ONE) | `Target` (Intune) | `Program`. Canonical names introduced in a phase are reused later: `Wave 00 Devices – All – Pilot`, `Parity Policy Set – <Platform> – Target`, `Compliance Policy – <Platform> – Target`, `ADE Enrollment Profile – iOS – Target`, `ADE Enrollment Profile – macOS – Target`, `Wave NN Devices – <Scope> – Wave NN`.

---

## Phase 1 — Discover

**Goal:** produce the authoritative estate baseline for both sides.

1. **Source (Workspace ONE):** export the full device, profile, compliance, and app-assignment inventory from the Workspace ONE console / REST API for every in-scope organization group. (Action named; exact export deferred to VMware docs.) Capture per device: platform, ownership (corporate/BYOD), assigned user (UPN), OS version, and the profiles/apps assigned.
2. **Target (Intune/Entra):** run the read-only `scripts\WS1PROG-Discovery.ps1` to baseline the Intune side — existing managed devices, enrollment configuration (APNs/ADE/managed Google Play/Windows auto-enroll status), groups, and licensing readiness.
3. **Reconcile** the two: every in-scope Workspace ONE user must resolve to an Entra user (match on UPN); flag mismatches now (they break targeting later).
4. Record **counts per platform** (Windows / iOS-iPadOS / Android / macOS) and per ownership (corporate vs. BYOD) — these drive wave sizing and the per-platform cutover mechanics (reset vs. re-enroll).

**Exit gate:** a signed-off source inventory plus the Intune-side baseline CSV (`Estate-Inventory – Discovery – Source.csv` for the source export, plus the script's `Intune-Baseline – Discovery – Target.csv`), covering 100% of in-scope devices, with UPN reconciliation complete.

---

## Phase 2 — Assess

**Goal:** turn the inventory into a sized, risk-rated parity plan.

1. **Parity matrix (R6):** for each platform, list every in-scope Workspace ONE profile, compliance policy, and app → its Intune equivalent → owner → High/Med/Low complexity. Mark **certificate, Wi-Fi, and VPN** profiles High — they gate access and must be exact.
2. **App assessment (R7):** classify each app as managed-store (VPP / managed Google Play / new Store), Win32/PKG/MSI line-of-business (needs source media + silent command), or retire.
3. **Cutover mechanics per cohort:** corporate Apple (ADE) and fully managed/dedicated Android cohorts typically **reset**; Windows and BYOD cohorts typically **re-enroll without wipe**. Tag each cohort.
4. **Conditional Access impact (R8):** review current CA for anything that would lock out un-migrated devices during coexistence.

**Exit gate:** an approved parity matrix and app catalog with a complexity rating per object and a cutover-mechanic tag per cohort.

---

## Phase 3 — Plan

**Goal:** wave plan + per-platform sequencing + named objects.

1. **Generate the wave plan + groups** from Discovery:
   - `scripts\WS1PROG-Set-WaveTargeting.ps1 -InputCsv "Estate-Inventory – Discovery – Source.csv" -OutputCsv "Wave-Plan – Program – Program.csv"` groups devices/users into waves (`Wave 00 … Wave NN`), keeping departments/cohorts together, and (with `-Apply`) creates the Entra security groups `Wave 00 Devices – All – Pilot` and `Wave NN Devices – <Scope> – Wave NN`.
2. **Pilot wave:** designate `Wave 00 Devices – All – Pilot` — a small representative spread (e.g. 10–25 devices) **covering every in-scope platform and both ownership types**, so the pilot exercises every cutover mechanic.
3. **Per-platform sequencing (recommended within each wave):** Windows and BYOD cohorts first (lowest user disruption, no wipe), then corporate Apple/Android reset cohorts (highest disruption, most comms).
4. **Name every object** that will be created (parity policy sets, compliance policies, enrollment profiles, apps, groups) and record them in the program register.
5. **Schedule cutover windows and rollback owners** per wave (R12, R13).

**Exit gate:** approved `Wave-Plan – Program – Program.csv`, created wave groups, named objects, scheduled windows.

---

## Phase 4 — Configure the Intune target

**Goal:** stand up identity, enrollment, parity policy, and apps so devices have a known-good state to land in. **Prerequisites R1–R4 (and R3 per platform in scope) must be satisfied.**

### 4.1 Confirm enrollment plumbing (R3)
At `https://intune.microsoft.com` → **Devices → Enrollment**:
- **Apple → Apple MDM Push certificate:** **Active**, not near expiry (renew, never recreate).
- **Apple → Enrollment program tokens:** the ADE token is present and synced (corporate Apple). VPP token present under **Apple → VPP tokens** (R7).
- **Android → managed Google Play:** the connected Google account shows linked.
- **Windows → Automatic Enrollment:** MDM user scope set (mirror in `https://entra.microsoft.com` → **Mobility (MDM and MAM) → Microsoft Intune**).

### 4.2 Rebuild parity policy sets (R6) — per platform
For each platform create the configuration profiles that achieve parity with Workspace ONE, grouped under the named set `Parity Policy Set – <Platform> – Target`:
- `https://intune.microsoft.com` → **Devices → Configuration → Create → New policy** → select **Platform** and **Profile type**; re-author Wi-Fi, VPN, certificates (SCEP/PKCS — stand up the connector first if used), restrictions, and platform-specific settings to match the source.
- Assign each profile to the **wave groups** (start unassigned or pilot-only; production groups are added at expand).

### 4.3 Create compliance policies (R8) — per platform
`https://intune.microsoft.com` → **Devices → Compliance → Create policy** → per platform → author `Compliance Policy – <Platform> – Target` (OS minimums, encryption, jailbreak/root, etc.). Pair with the Conditional Access transition plan (do-no-harm during coexistence).

### 4.4 Rebuild apps (R7) — per platform
`https://intune.microsoft.com` → **Apps → All apps → Add**:
- **Windows:** Win32 app (`.intunewin` from the Win32 Content Prep Tool) with silent install/uninstall/detection; or Microsoft Store app (new); or line-of-business MSI.
- **iOS/iPadOS & macOS:** iOS/macOS store app (VPP-backed, identify by exact publisher + bundle ID), or line-of-business (`.ipa` / `.pkg`/`.dmg`), plus managed app configuration where the source had it.
- **Android:** managed Google Play app (approve in managed Google Play), with managed config.
- Name nothing ad hoc — record each app and its assignment in the parity matrix.

**Exit gate:** enrollment channels Active per platform; `Parity Policy Set – <Platform> – Target`, `Compliance Policy – <Platform> – Target`, and the app set built and ready to assign; Conditional Access staged report-only.

---

## Phase 5 — Pilot

Run **every** in-scope platform workstream end-to-end against `Wave 00 Devices – All – Pilot`. Assign the parity policy sets, compliance policies, and apps to the pilot group; execute each platform's cutover runbook (Phase 7) for the pilot devices only. Capture real timings per platform to refine the wave schedule. **No production wave starts until Phase 6 passes.**

---

## Phase 6 — Validate (the pilot-wave gate)

Run `scripts\WS1PROG-Validation.ps1` plus the manual gates in `05-testing.md` against the pilot devices. The pilot-wave gate is the program's go/no-go: it passes only when every platform's acceptance gate (enrollment, parity, compliance, app delivery, access) passes for the pilot wave. **Do not expand to production waves until this gate is green.** Record results in `Validation Results – Program – Wave 00`.

---

## Workstream Runbooks (Phase 7 — Expand: coexistence → cutover → validate, per platform)

Each runbook runs **per wave** after the pilot gate passes. The pattern per device is identical: ensure the target state is assigned → **un-enroll from Workspace ONE** → **enroll into Intune** → confirm parity/compliance/apps → validate. Both platforms coexist across the fleet during this phase, but each device is managed by exactly one.

> **Coexistence rule (all platforms):** target only **migrated** devices with the production assignment, via the wave group `Wave NN Devices – <Scope> – Wave NN`. Never assign the same device to both platforms at once; that is the failure mode the wave model prevents.

### WS-A — Windows

1. **Assign target state:** add `Wave NN Devices – Windows – Wave NN` to `Parity Policy Set – Windows – Target`, `Compliance Policy – Windows – Target`, and the Windows apps.
2. **Identity:** confirm each device will Entra-join or Entra-hybrid-join (R4). For hybrid, the SCP/Entra Connect config must already publish the join.
3. **Cutover (per device, usually no wipe):**
   - In Workspace ONE, **release / unenroll** the Windows device from source management (action named; deferred to VMware docs).
   - With Windows automatic enrollment configured (R3), the device **auto-enrolls into Intune** on the next Entra sign-in / MDM enrollment; or trigger enrollment via **Access work or school → Connect**. The `WS1PROG-Set-WaveTargeting.ps1` group membership pulls policy/apps.
4. **Confirm** profiles (Wi-Fi/VPN/cert), compliance, and apps land (see `05-testing.md` Windows gate).
5. **Remediate** failed devices with `WS1PROG-Remediation.ps1` (e.g. `-Mode RetryEnrollmentSync` / `-Mode AddToWaveGroup`).

**Named objects:** `Wave NN Devices – Windows – Wave NN`, `Parity Policy Set – Windows – Target`, `Compliance Policy – Windows – Target`.

### WS-B — iOS/iPadOS

1. **Assign target state:** add `Wave NN Devices – iOS – Wave NN` to `Parity Policy Set – iOS – Target`, `Compliance Policy – iOS – Target`, and the iOS apps (VPP-backed where managed).
2. **Corporate (ADE) devices:**
   - In **Apple Business Manager** (`https://business.apple.com`) → **Devices**, **re-assign** the device's MDM server from the Workspace ONE MDM server to the **Intune MDM server**. (ABM is the system of record for ADE assignment — a device's MDM server is changed here, then released from the source.)
   - In Workspace ONE, **release** the device (action named; deferred to VMware docs).
   - Create/confirm the Intune ADE enrollment profile: `https://intune.microsoft.com` → **Devices → Enrollment → Apple → Enrollment program tokens → (open the ADE token) → Profiles → Create profile → iOS/iPadOS** → name it `ADE Enrollment Profile – iOS – Target`; assign it to the synced devices. The device is then **wiped/reset** and re-enrolls into Intune through Setup Assistant.
3. **BYOD / user-enrollment devices:** user removes the Workspace ONE management profile (action named; deferred to VMware docs) and re-enrolls via the Intune Company Portal app.
4. **Confirm** APNs-delivered profiles, compliance, and managed apps install (see `05-testing.md` iOS gate).

**Named objects:** `Wave NN Devices – iOS – Wave NN`, `ADE Enrollment Profile – iOS – Target`, `Parity Policy Set – iOS – Target`, `Compliance Policy – iOS – Target`.

### WS-C — Android

1. **Assign target state:** add `Wave NN Devices – Android – Wave NN` to `Parity Policy Set – Android – Target`, `Compliance Policy – Android – Target`, and the managed Google Play apps.
2. **Pick the enrollment mode per ownership** (matches the source posture): work profile (BYOD), fully managed (corporate), or dedicated/kiosk. Confirm the corresponding Intune enrollment profile under **Devices → Enrollment → Android → (mode)**.
3. **Cutover (per device):**
   - **Work profile:** user removes the Workspace ONE work profile (action named; deferred to VMware docs) and re-enrolls via Company Portal.
   - **Fully managed / dedicated:** device is **factory reset** and enrolled into Intune via the corporate enrollment method (QR / NFC / zero-touch / token).
4. **Confirm** managed Google Play apps and policies land (see `05-testing.md` Android gate).

**Named objects:** `Wave NN Devices – Android – Wave NN`, `Parity Policy Set – Android – Target`, `Compliance Policy – Android – Target`.

### WS-D — macOS

1. **Assign target state:** add `Wave NN Devices – macOS – Wave NN` to `Parity Policy Set – macOS – Target`, `Compliance Policy – macOS – Target`, and the macOS apps (PKG/DMG/managed store, plus shell scripts where the source used custom config).
2. **Corporate (ADE) Macs:** in **Apple Business Manager** → **Devices**, re-assign the Mac's MDM server to the **Intune MDM server**; **release** the Mac from Workspace ONE (action named; deferred to VMware docs); create/confirm `https://intune.microsoft.com` → **Devices → Enrollment → Apple → Enrollment program tokens → (open the ADE token) → Profiles → Create profile → macOS** → `ADE Enrollment Profile – macOS – Target`. The Mac is **wiped/reset** and re-enrolls through Setup Assistant.
3. **Non-ADE Macs:** remove the Workspace ONE management profile (action named; deferred to VMware docs) and enroll via the Company Portal / enrollment profile download.
4. **Confirm** APNs-delivered profiles, FileVault/compliance, and apps land (see `05-testing.md` macOS gate).

**Named objects:** `Wave NN Devices – macOS – Wave NN`, `ADE Enrollment Profile – macOS – Target`, `Parity Policy Set – macOS – Target`, `Compliance Policy – macOS – Target`.

---

## Phase 8 — Validate (per wave)

After each wave's cutover, run `scripts\WS1PROG-Validation.ps1` and the manual gates in `05-testing.md` for every platform in the wave: enrollment state, parity profiles applied, compliance evaluated, apps installed, and access (Conditional Access) working. Track wave progress with `scripts\WS1PROG-Report.ps1`. **No Workspace ONE device or assignment is decommissioned until its wave passes.**

**Exit gate:** all platform acceptance gates PASS for the wave; report shows 100% migrated-and-compliant for the wave.

---

## Phase 9 — Tighten Conditional Access (per wave / at fleet completion)

As waves complete, move the staged Conditional Access from report-only to enforced so access requires Intune compliance — but only for cohorts that have cut over (R8, do-no-harm). At full fleet completion, the org requires Intune-managed, compliant devices everywhere.

---

## Phase 10 — Decommission Workspace ONE

**Goal:** retire the source under change control, only after validation.

1. **Confirm** all waves validated (`WS1PROG-Report.ps1` shows 100% migrated per platform and the grace period elapsed).
2. **Soft-retire first:** keep migrated devices read-only in Workspace ONE / disable assignments for a defined **grace period** so per-device rollback stays available (R13).
3. **Release devices and tokens:** release remaining devices from Workspace ONE; release the ADE/DEP token from the source so ABM assignment is fully owned by Intune (action named; deferred to VMware docs).
4. **Export retained records** (compliance/inventory history) per policy before teardown.
5. **Reclaim/cancel Workspace ONE licensing/tenant** last, with the platform owner (deferred to VMware docs for console steps).
6. **Document** final state and archive the program register as evidence.

**Exit gate:** Workspace ONE retired; ADE/DEP fully owned by Intune; evidence archived; program closed.
