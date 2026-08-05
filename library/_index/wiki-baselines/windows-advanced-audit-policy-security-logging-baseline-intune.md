# Windows Advanced Audit Policy & Security Event Logging Baseline (Intune)

> **Version 1.0.0** · Category: Intune · Solution code: WINAUDIT

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Windows Advanced Audit Policy & Security Logging Baseline (Intune)

Most Windows fleets are under-audited without anyone realizing it: the default audit policy captures too
little to investigate an incident, it drifts from machine to machine, and — worst of all — the modern
**Advanced Audit Policy** subcategories are often silently ignored because a single override switch is
off. When a breach or insider event happens, the events you needed were never written. This solution
fixes that at the source. It configures the full **Windows Advanced Audit Policy Configuration** on
**Windows 10/11** endpoints via **Microsoft Intune** — a consistent, **CIS / Microsoft security
baseline-aligned** audit trail on every device, deployed pilot-first and fully reversible.

**A deliberately scoped, distinct capability.** This is the audit **configuration** baseline — which
subcategories to audit, at what Success/Failure level, plus **command-line process auditing** and a
right-sized Security log. It is **not** SIEM forwarding (getting those events into Microsoft Sentinel is
the separate *Entra ID & Intune Audit Telemetry to Microsoft Sentinel* solution), and it is **not** a
broad CIS/STIG hardening baseline (that is a separate, wider product). It deploys a single Settings
Catalog profile and is reversible by unassigning it — no re-enrollment, no re-imaging.

Two things this package makes explicit that teams routinely miss:

- **The override that makes everything work.** Windows only honors the advanced subcategories when
  **"Force audit policy subcategory settings to override audit policy category settings"** is enabled
  (`SCENoApplyLegacyAuditPolicy = 1`). The baseline sets it explicitly and the scripts verify it — so
  your audit settings can't be silently voided by a leftover legacy policy.
- **The event that catches attackers.** **Process Creation with the full command line** (Event ID 4688)
  is the highest-value detection for living-off-the-land activity. The baseline turns it on, sizes the
  log for it, and hands the volume decision to your SIEM instead of turning it off.

This package delivers the complete, field-tested method to stand it up in Intune — written so a single
administrator can follow it end to end:

- **One profile, one purpose.** A `Win Audit Policy - Baseline - Pilot` Settings Catalog profile
  carrying the force-subcategory override, all ~24 recommended audit subcategories, command-line process
  auditing, and the Security-log size — deployed pilot-first.
- **Baseline-aligned and role-aware.** Recommended Success/Failure values cited to CIS / Microsoft, tuned
  for workstations, with explicit guidance to clone a server variant for high-volume roles.
- **Honest about volume.** The loud subcategories (Process Creation, File Share, Filtering Platform
  Connection) are flagged, tuned, and paired with the forwarding solution so auditing is never turned
  off for the wrong reason.

The package follows the standard repeatable shape — **Assess → Configure → Pilot → Validate → Expand** —
with exact, click-by-click Intune steps, a requirements guide that tells you how to verify *and* fix each
prerequisite, five ready-to-run PowerShell scripts (Microsoft Graph), and testing/troubleshooting guides
with clear pass/fail gates.

**Outcome:** a consistent, baseline-aligned Windows audit trail — with command-line process auditing and
a right-sized log — on every corporate endpoint, deployed and proven on a pilot before you scale, without
a consulting engagement and without touching how the device is enrolled. This one product resolves the
cluster of "Configure Auditing for …" and "Audit Logon" findings a typical Windows client security
assessment raises.


---


# 1. Solution Overview — Windows Advanced Audit Policy & Security Event Logging Baseline (Intune)

## What this solution is
This solution configures the full **Windows Advanced Audit Policy Configuration** on **Windows 10/11**
endpoints managed by **Microsoft Intune**, using a single **Settings Catalog** configuration profile.
Once deployed, every domain- and Entra-joined Windows device writes a **consistent, security-relevant
audit trail** to the local **Security** event log — sign-ins, account and group changes, process
creation (with the full command line), removable-storage use, privilege use, and audit/policy changes
— aligned to the **CIS Benchmark / Microsoft security baseline** recommendations for what to audit and
whether to capture **Success**, **Failure**, or both.

Windows has two layers of auditing. The legacy **basic audit policy** (nine broad categories) and the
modern **Advanced Audit Policy Configuration** (~60 fine-grained subcategories). Modern security
baselines are written entirely against the **advanced** subcategories, because they let you turn on
exactly the events you need without the noise of a whole category. This solution deploys the advanced
subcategories via Intune and — critically — sets the switch that makes Windows honor them.

> **The one switch everything depends on.** Windows only applies the advanced subcategory settings when
> **"Audit: Force audit policy subcategory settings (Windows Vista or later) to override audit policy
> category settings"** is **Enabled** (the registry value `SCENoApplyLegacyAuditPolicy = 1`). Modern
> Windows defaults this on, but a leftover basic-audit GPO, an image, or a third-party tool can flip it
> off — silently discarding every subcategory setting you push. This solution sets it **explicitly** so
> the baseline is deterministic, and the validation scripts check it.

## What this solution is (and is not)
- **It IS** the audit-policy **configuration baseline** — which subcategories to audit, at what
  Success/Failure level, plus command-line process auditing and a right-sized Security log — deployed
  and validated via Intune, pilot-first and reversible.
- **It is NOT** a broad security-configuration baseline. If you want the full CIS/STIG hardening baseline
  (hundreds of settings across firewall, BitLocker, account policy, etc.), that is a **separate, broader
  product** — this one is the focused *audit* slice and complements it without duplication.
- **It is NOT** log forwarding to a SIEM. This solution makes each endpoint **generate and retain** the
  right events locally. **Getting those logs off the box into Microsoft Sentinel** (Azure Monitor Agent
  + Data Collection Rules, Windows Security Events connector) is handled by the separate
  **Entra ID & Intune Audit Telemetry to Microsoft Sentinel** solution — cross-reference it, don't
  rebuild it here. Endpoint auditing is the *source*; forwarding is the *transport*.

## How it works, step by step
1. **One Settings Catalog profile carries the baseline.** A single Windows Settings Catalog
   configuration profile named **`Win Audit Policy - Baseline - Pilot`** contains all ~24 audit
   subcategory settings, the "force subcategory" override, command-line process auditing, and the
   Security-log maximum size.
2. **Intune delivers it to enrolled devices.** The profile is assigned to a **pilot** Entra security
   group (`Win Audit Policy - Pilot Devices`), then widened in waves.
3. **Windows applies the advanced subcategories.** With the force-subcategory override enabled, each
   device begins writing the specified Success/Failure events to the **Security** log.
4. **Events accumulate with room to breathe.** The Security log maximum size is raised so higher-volume
   subcategories (Process Creation, File Share) don't roll over and lose evidence within hours.
5. **Validate, then expand.** Read-only scripts confirm the profile is present, correctly scoped, and
   applied; then the baseline widens to the rest of the fleet.

## What the baseline audits (and why)
The baseline turns on the subcategories that detect the attacker behaviors defenders actually hunt for:

- **Account Logon / Logon-Logoff** — who authenticated, from where, failed sign-ins, lockouts, and the
  privileged/special logons that indicate admin activity or token theft.
- **Account & Security Group Management** — creation, deletion, and privilege changes to accounts and
  groups (a classic persistence and privilege-escalation signal).
- **Detailed Tracking → Process Creation with command line** — every process launch *with its full
  command line* (Event ID 4688). This is one of the single most valuable detections for
  living-off-the-land attacks (PowerShell, `rundll32`, `mshta`, etc.).
- **Object Access → File Share / Removable Storage** — access to shares and USB storage, for
  data-exfiltration and insider investigations.
- **Privilege Use, Policy Change, System** — use of sensitive privileges, tampering with audit/policy,
  and security-subsystem state changes.

The exact **Success/Failure** recommendation per subcategory is given in the Implementation Guide and
is cited to the **CIS Benchmark / Microsoft security baseline**.

## The event-volume trade-off (be honest with yourself)
More auditing means more events, more disk, and more to forward. Two subcategories are notably
high-volume:

- **Detailed Tracking → Process Creation** — on a busy workstation this is the loudest single source.
  It is also the most useful; keep it **Success**, size the log accordingly, and forward it.
- **Object Access → File Share / Detailed File Share / Filtering Platform Connection** — file-share and
  network-connection auditing can be very chatty on file servers and heavily networked hosts.

The baseline is tuned for **workstations**; the Implementation Guide flags where to dial specific
subcategories down (or up) for **servers** and for high-volume environments, and points you to the
forwarding solution so volume is a SIEM-ingestion decision, not a reason to stop auditing.

## Benefits
- **A consistent, baseline-aligned audit trail** on every Windows endpoint — no more per-machine drift
  in what is (or isn't) being logged.
- **Detection-ready by default** — command-line process auditing and the logon/account/privilege events
  that SOC playbooks and SIEM rules expect.
- **Deterministic** — the force-subcategory override is set explicitly, so the baseline can't be
  silently voided by a legacy audit setting.
- **No re-enrollment, fully reversible** — it deploys a configuration profile only; unassigning it
  cleanly reverts the device to its prior audit state.
- **Right-sized retention** — a larger Security log so evidence survives long enough to be collected or
  forwarded.

## Limitations (be honest with buyers)
- **Endpoint auditing only.** This makes devices *generate and keep* events; it does **not** forward
  them to a SIEM (see the Sentinel forwarding solution).
- **Windows 10/11 enrolled devices.** It targets Intune-managed Windows 10/11; it is not a macOS/iOS or
  a Linux capability, and it is not a Group Policy deliverable (though the same subcategories map 1:1 to
  GPO if you also manage domain controllers that way).
- **Settings-Catalog setting IDs can change.** The setting definition names below reflect current
  Microsoft documentation — **verify them in your tenant** before fleet rollout rather than assuming.
- **Volume is real.** High-value subcategories are high-volume; size logs and plan SIEM ingest
  accordingly.

## The standard deployment model
This solution uses **one** repeatable model across our catalog:

> **Windows 10/11 endpoints receive the Advanced Audit Policy baseline (CIS / Microsoft-aligned
> Success/Failure subcategories + command-line process auditing + a right-sized Security log) as a
> single Intune Settings Catalog profile, with the force-subcategory override set explicitly, deployed
> pilot-first and reversible.**

Every step follows the repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**


---


# 2. Requirements — Windows Advanced Audit Policy & Security Event Logging Baseline (Intune)

Confirm **every** requirement below before you begin. Each entry follows the same pattern:
**Description · Why required · How to verify · How to implement if missing.** Category-wide
prerequisites (tenant, Intune licensing, admin roles, pilot group, network) are covered once in the
**Global Requirements — Intune Solutions** document; the items here are specific to configuring the
**Windows Advanced Audit Policy** baseline via Intune Settings Catalog.

> **Scope reminder.** These requirements are for the audit-policy **configuration baseline** on
> **enrolled Windows 10/11** devices. They deliberately do **not** include forwarding logs to a SIEM
> (that is the separate *Entra ID & Intune Audit Telemetry to Microsoft Sentinel* solution) or a broad
> CIS/STIG security-hardening baseline.

## R1. Windows 10/11 devices enrolled in Intune
**Description:** The target devices are Intune-enrolled Windows 10 (21H2+) or Windows 11 endpoints.
**Why:** The Settings Catalog audit profile is delivered by Intune MDM; it only reaches enrolled,
managed devices.
**Verify:** Intune admin center (`https://intune.microsoft.com`) → **Devices → Windows → Windows
devices**; the device is listed and **managed**.
**Implement:** Enroll the device via **Automatic Enrollment** (Entra join + MDM auto-enroll) or
Autopilot so it appears under **Devices → Windows**. (Enrollment itself is covered by the enrollment
solutions and Global Requirement G4.)

## R2. Supported, patched Windows baseline
**Description:** Windows 10 **21H2 or later** or Windows 11, with current cumulative updates.
**Why:** The Advanced Audit Policy subcategories and the Settings Catalog audit setting definitions
assume a modern, patched OS; older builds may lack specific subcategories (e.g. Group Membership,
PNP Activity).
**Verify:** On the device run **`winver`**, or Intune → device → **Hardware**.
**Implement:** Deploy **Update rings** / **Feature update** policy, or upgrade to Windows 11
(Global Requirement G6).

## R3. Settings Catalog audit profile
**Description:** A Windows **Settings Catalog** configuration profile named
**`Win Audit Policy - Baseline - Pilot`** carrying the audit subcategory settings, the force-subcategory
override, command-line process auditing, and the Security-log maximum size.
**Why:** This single profile is what applies and scopes the entire baseline.
**Verify:** Intune → **Devices → Configuration**; a profile named `Win Audit Policy - Baseline - Pilot`
(Platform **Windows 10 and later**, profile type **Settings catalog**) exists and is assigned to your
pilot group.
**Implement:** Create it during deployment (Implementation Guide, Phase 2), or scaffold/assign it with
the included `WINAUDIT-Remediation.ps1` / `WINAUDIT-Set-ScopeTargeting.ps1`.

## R4. "Force audit policy subcategory settings" is (or will be) enabled
**Description:** The security option **"Audit: Force audit policy subcategory settings (Windows Vista or
later) to override audit policy category settings"** must be **Enabled** (registry
`SCENoApplyLegacyAuditPolicy = 1`).
**Why:** Windows only honors the *advanced* subcategory settings when this override is on. If a legacy
basic-audit policy or image left it off, every subcategory you push is silently ignored.
**Verify:** On a device, `auditpol /get /category:*` should reflect your subcategory settings (not a
blanket category state); or check `HKLM\SYSTEM\CurrentControlSet\Control\Lsa\SCENoApplyLegacyAuditPolicy
= 1`.
**Implement:** The baseline profile sets this override **Enabled** explicitly (Implementation Step 6a),
so deploying the profile satisfies this. Remove any conflicting legacy **basic** audit GPO/policy.

## R5. No conflicting basic (legacy) audit policy
**Description:** No Group Policy or third-party tool is still setting the **basic** nine-category audit
policy (or the force-subcategory override to Disabled).
**Why:** A legacy basic-audit policy can override or fight the advanced subcategories and produce
inconsistent results across the fleet.
**Verify:** In any co-managing GPO, confirm **Computer Configuration → Policies → Windows Settings →
Security Settings → Local Policies → Audit Policy** (the *basic* nine) is **Not Defined**; only
**Advanced Audit Policy Configuration** is used.
**Implement:** Set the basic **Audit Policy** entries back to *Not Defined* in any GPO, and standardize
on the Intune advanced baseline. Confirm with `auditpol` after the next sync.

## R6. Security event log sized for retention
**Description:** The **Security** event log maximum size raised from the small default so higher-volume
subcategories don't overwrite evidence quickly.
**Why:** With Process Creation and File Share auditing on, the default log can wrap in hours on a busy
host, losing the events you turned on to capture.
**Verify:** On a device, **Event Viewer → Windows Logs → Security → (right-click) Properties → Maximum
log size**; or `wevtutil gl Security`.
**Implement:** The baseline sets a recommended maximum (Implementation Step 6d). Size it to your
retention/forwarding window — larger if you forward on a schedule rather than continuously.

## R7. Decision on the Success/Failure profile per subcategory
**Description:** A decision on which subcategories audit **Success**, **Failure**, or **both**, aligned
to the **CIS Benchmark / Microsoft security baseline** and adjusted for **workstation vs server**.
**Why:** The recommended level differs by subcategory and by device role; over-auditing the wrong
subcategory (e.g. Filtering Platform Connection on a busy server) creates noise with little value.
**Verify:** Use the recommended table in the Implementation Guide (Step 6b) as your default; confirm the
values match your compliance requirement (CIS L1/L2, STIG, or your own standard).
**Implement:** Start from the workstation-tuned table in Step 6b; create a **server** variant of the
profile where the guide flags a different value.

## R8. (For forwarding) awareness of the SIEM solution — not built here
**Description:** Awareness that getting these events into a SIEM is a **separate** capability.
**Why:** This baseline makes endpoints *generate and retain* events; it does not forward them. Buyers
sometimes expect "auditing" to include SIEM ingestion.
**Verify:** Confirm whether you already forward Windows Security events (Azure Monitor Agent + Data
Collection Rule to Microsoft Sentinel, or WEF/WEC).
**Implement:** Deploy the **Entra ID & Intune Audit Telemetry to Microsoft Sentinel** solution (or your
existing WEF/AMA pipeline) to collect the events this baseline produces. Do not attempt to solve
forwarding inside this audit profile.

## R9. Pilot device
**Description:** At least one enrolled Windows 10/11 pilot device in the pilot security group.
**Why:** Every solution is validated on a pilot before fleet rollout.
**Verify:** The pilot device is enrolled (R1), on a supported build (R2), and is a member of
`Win Audit Policy - Pilot Devices`.
**Implement:** Add the pilot device (or its user) to the **pilot security group** (Global Requirement
G5) used for the profile assignment.


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


---


# 5. Testing & Validation — Windows Advanced Audit Policy & Security Logging Baseline

Validate against a **pilot device** before expanding. Each test has an explicit **pass/fail gate**. Use
the included PowerShell scripts (Microsoft Graph) for tenant-side checks and the on-device steps for the
actual audit behavior.

> **What "pass" means here:** enrolled Windows 10/11 devices apply the `Win Audit Policy - Baseline -
> Pilot` profile, the advanced subcategories are actually in effect on the device (force-subcategory
> override on), and auditable actions produce the expected Security-log events — including command-line
> in 4688. This solution does **not** forward events to a SIEM.

## Test 1 — Tenant readiness
**Procedure:** Run `WINAUDIT-Discovery.ps1`.
**Pass:** A **Settings Catalog** profile named `Win Audit Policy - Baseline - Pilot` exists
(Platform Windows 10 and later), contains the force-subcategory override and audit subcategory settings,
and includes command-line process auditing.
**Fail:** Missing profile, missing override, or no audit settings → resolve before piloting
(`WINAUDIT-Remediation.ps1`).

## Test 2 — Profile assignment
**Procedure:** Run `WINAUDIT-Validation.ps1` (or check **Devices → Configuration → `Win Audit Policy -
Baseline - Pilot` → Assignments**).
**Pass:** The profile is assigned to **`Win Audit Policy - Pilot Devices`** and to no unintended broad
group.
**Fail:** Not assigned, or assigned to "All devices" prematurely → correct the assignment (Implement
Step 7 / `WINAUDIT-Set-ScopeTargeting.ps1`).

## Test 3 — Profile applied on the device
**Procedure:** On the pilot device, sync; then Intune → profile → **Device status**.
**Pass:** The `Win Audit Policy - Baseline - Pilot` profile shows **Succeeded** on the pilot device.
**Fail:** Not applied / error → force a sync, check for a conflicting profile, and review Device status
detail.

## Test 4 — The force-subcategory override is active (the gate everything depends on)
**Procedure:** On the pilot device (elevated): `reg query
"HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v SCENoApplyLegacyAuditPolicy`.
**Pass:** Returns **`0x1`** — advanced subcategory settings will be honored.
**Fail:** Returns `0x0` or missing → a legacy basic-audit policy is overriding; remove it (R5) and
re-sync. Until this is `1`, every subcategory below is ignored.

## Test 5 — Subcategories are set as intended
**Procedure:** On the pilot device (elevated): `auditpol /get /category:*`.
**Pass:** The 24 subcategories from Implementation Step 6b show the recommended Success/Failure state —
e.g. *Process Creation* = **Success**, *Credential Validation* = **Success and Failure**, *Account
Lockout* = **Failure**.
**Fail:** Any subcategory shows an unexpected state → confirm Test 4 passed, then re-check the profile
values (Step 6b) and re-sync.

## Test 6 — Events are actually generated (including command line)
**Procedure:** On the pilot device, sign out and back in, then launch `cmd.exe` and `powershell.exe`.
In **Event Viewer → Windows Logs → Security**, find the resulting events.
**Pass:** **4624** (logon) and **4688** (process creation) events appear, and the **4688** events
include a populated **Process Command Line** field.
**Fail (no 4688 command line):** Command-line auditing not applied → confirm Step 6c
(`ProcessCreationIncludeCmdLine_Enabled = Enabled`) and re-sync.

## Test 7 — Security log is sized for retention
**Procedure:** **Event Viewer → Security → Properties** (or `wevtutil gl Security`).
**Pass:** **Maximum log size** is **196608 KB** (or your chosen value ≥ CIS minimum 32768 KB), and
retention is *overwrite as needed*.
**Fail:** Still at the small default → confirm Step 6d applied and re-sync.

## Test 8 — Coverage report
**Procedure:** Run `WINAUDIT-Report.ps1`.
**Pass:** The report lists the pilot device(s) as **applied**; counts match the assigned group.
**Fail:** Devices missing → run `WINAUDIT-Remediation.ps1` (`-WhatIf` first) to fix assignment/scoping,
re-sync stragglers.

## Test 9 — Reversibility / no unintended change (negative test)
**Procedure:** Note the device is otherwise unchanged (no enrollment change, no other policy applied by
this profile). Optionally unassign the profile from a spare pilot device and re-run `auditpol`.
**Pass:** This solution only adds the `Win Audit Policy - Baseline - Pilot` configuration profile;
unassigning it cleanly reverts the audit state — no re-enrollment or cleanup needed.
**Fail:** If enrollment or unrelated settings changed, an unintended policy is also present — confirm
this solution deployed the **audit Settings Catalog profile** only.

## Acceptance gate
Proceed to **Expand** only when Tests 1–8 pass on at least one pilot device (Test 4 is mandatory — the
override must be `0x1`), Test 9 confirms the change is isolated and reversible, and Event Viewer shows
the expected 4624/4688 events with command line.


---


# 6. Troubleshooting — Windows Advanced Audit Policy & Security Logging Baseline

Work top-down: confirm the **profile is applied**, then the **force-subcategory override is on**, then
the **individual subcategories**, then the **log**. The overwhelming majority of "it says applied but
nothing is audited" cases are the override being off (`SCENoApplyLegacyAuditPolicy = 0`) or a legacy
basic-audit policy fighting the advanced one. Each symptom below gives the **likely cause** and the
**fix**.

> **Before you start:** decide which problem you have. "Nothing is being audited" is an *override /
> conflict* problem. "Events are audited but I can't find them in my SIEM" is a *forwarding* problem —
> that is the separate *Entra ID & Intune Audit Telemetry to Microsoft Sentinel* solution, not this
> baseline.

## Symptom: The profile never appears / shows no status on the device
**Likely cause:** Device not synced, not assigned, or not enrolled.
**Fix:**
1. Confirm the device is in **`Win Audit Policy - Pilot Devices`** and the profile is **assigned**
   (`WINAUDIT-Validation.ps1`).
2. Force a sync (**Settings → Accounts → Access work or school → Info → Sync**) and wait a check-in.
3. Check **Devices → Configuration → `Win Audit Policy - Baseline - Pilot` → Device status** for an
   error.

## Symptom: Device status is "Succeeded" but `auditpol` shows nothing changed
**Likely cause:** The **force-subcategory override is off** — advanced subcategories are being ignored.
**This is the most common failure.**
**Fix:**
1. On the device (elevated): `reg query "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v
   SCENoApplyLegacyAuditPolicy`. If it is `0x0` or missing, the override is off.
2. Confirm the profile sets **"Audit: Force audit policy subcategory settings … to override audit
   policy category settings" = Enabled** (Implementation Step 6a).
3. Find and remove any **legacy basic Audit Policy** (the nine categories) still applied by GPO or a
   third-party tool (R5) — a basic policy re-disables the override. Re-sync and re-check.

## Symptom: Profile shows "Error" / "Conflict" in Device status
**Likely cause:** A second configuration profile sets the same audit settings or the override to a
different value.
**Fix:**
1. Run `WINAUDIT-Discovery.ps1` and review **Devices → Configuration** for other profiles touching
   auditing or `SCENoApplyLegacyAuditPolicy`.
2. Ensure only **one** profile owns the audit baseline for a given device; remove or re-scope the
   duplicate so a device is not targeted by two.

## Symptom: 4688 Process Creation events appear but have no command line
**Likely cause:** Command-line process auditing not applied.
**Fix:**
1. Confirm the profile includes **Administrative Templates → System → Audit Process Creation → Include
   command line in process creation events = Enabled** (Step 6c).
2. Re-sync; new 4688 events (created *after* the setting applies) will carry the **Process Command
   Line** field — existing events are not retroactively updated.

## Symptom: A specific subcategory isn't auditing what you expect
**Likely cause:** Wrong value in the profile, the override is off (see above), or the subcategory
doesn't exist on that Windows build.
**Fix:**
1. On the device: `auditpol /get /category:*` and compare against the recommended table (Step 6b).
2. If one subcategory is wrong, correct its value in `Win Audit Policy - Baseline - Pilot` and re-sync.
3. If the subcategory is missing entirely (e.g. Group Membership / PNP Activity on an old build),
   confirm the device meets the supported baseline (R2).

## Symptom: The Security log fills up / events disappear within hours
**Likely cause:** Log too small for the enabled volume, or retention set to "do not overwrite."
**Fix:**
1. Confirm **Specify the maximum log file size (KB)** is set (Step 6d) — 196608 KB baseline, larger if
   you forward on a schedule.
2. Set retention to **overwrite events as needed (oldest first)** so a full log never blocks new
   auditing.
3. If a specific host is still overrun, it is likely a high-volume subcategory (Detailed File Share,
   Filtering Platform Connection, Process Creation on a build host) — dial that subcategory down on a
   **server** variant of the profile (Best Practices) and forward to a SIEM rather than retaining
   locally.

## Symptom: Too many events / SIEM ingestion cost spiked after rollout
**Likely cause:** A high-volume subcategory enabled fleet-wide (often Filtering Platform Connection or
Detailed File Share at Success).
**Fix:**
1. Identify the noisy Event IDs (5156/5157 = Filtering Platform Connection; 5145 = Detailed File Share).
2. Set those subcategories back to the baseline default (Filtering Platform Connection = **No
   Auditing** on workstations; Detailed File Share = **Failure**) in the profile, and re-sync.
3. Keep the high-value, lower-volume subcategories on; only enable the loud ones where you are actively
   investigating.

## Symptom: Works on some devices, not others
**Likely cause:** Group membership, unsupported build, or a per-device legacy audit conflict.
**Fix:**
1. Confirm affected devices are in the assigned group (`WINAUDIT-Report.ps1`).
2. Confirm each device meets the supported build (R2) and shows `SCENoApplyLegacyAuditPolicy = 1`.
3. Re-run `WINAUDIT-Remediation.ps1` **(`-WhatIf` first)** to correct assignment/scoping, then re-sync
   the stragglers.

## Symptom: Coverage report shows fewer devices than the group
**Likely cause:** Some devices not synced, not enrolled, or on an unsupported build.
**Fix:**
1. Run `WINAUDIT-Report.ps1` to list which devices lack the applied baseline.
2. Run `WINAUDIT-Remediation.ps1` **(`-WhatIf` first)** to correct assignment/scoping.
3. Re-sync stragglers and confirm enrollment (R1) and build (R2).

## Escalation checklist
Before opening a Microsoft support case, collect: the `WINAUDIT-Discovery.ps1` output, the profile's
Device status export, the on-device `auditpol /get /category:*` output, the `SCENoApplyLegacyAuditPolicy`
registry value, a sample of the expected Security events (4624/4688 with command line), the Windows
build, and whether any legacy basic-audit GPO is still applied (isolates a policy conflict from a
device-side issue).


---


# 7. Best Practices — Windows Advanced Audit Policy & Security Logging Baseline

These practices keep the audit baseline consistent, useful, and reversible across Windows 10/11
endpoints. They assume the deployment model in the Solution Overview: a single Intune **Settings
Catalog** profile carrying CIS/Microsoft-aligned subcategories, the force-subcategory override,
command-line process auditing, and a right-sized Security log, deployed pilot-first.

## Set the override first, and prove it
- **Enable "Force audit policy subcategory settings" explicitly.** Never rely on the default. Put it in
  the same `Win Audit Policy - Baseline - Pilot` profile (Step 6a) so the baseline is deterministic, and
  confirm `SCENoApplyLegacyAuditPolicy = 1` on-device (Test 4) before trusting any subcategory result.
- **Kill legacy basic audit policy.** If any GPO still sets the nine basic **Audit Policy** categories,
  set them to *Not Defined*. Basic and advanced audit fighting each other is the top cause of
  "the setting shows applied but nothing is audited."

## Audit for detection, not for volume
- **Start from the workstation-tuned table (Step 6b).** It is CIS/Microsoft-aligned and captures the
  events SOC playbooks expect without drowning the log.
- **Keep Process Creation with command line.** Row 14 + Step 6c (Event ID 4688 with the command line) is
  the single most valuable pairing for detecting living-off-the-land attacks. Size the log for it rather
  than turning it off.
- **Treat the loud subcategories deliberately.** *Detailed File Share* (5145) and *Filtering Platform
  Connection* (5156/5157) are very high volume. Leave Filtering Platform Connection off on workstations
  (baseline default); enable it only on hosts under active investigation and only if the SIEM can absorb
  it.

## Split workstation and server baselines
- **Clone, don't overload.** Create `Win Audit Policy - Baseline - Servers` for server roles and adjust
  the high-volume subcategories (File Share, Detailed File Share, Filtering Platform Connection,
  Sensitive Privilege Use) to match the role. A file server and a laptop have very different noise
  profiles.
- **Assign by group, not by "All devices."** Keep workstations and servers in separate Entra groups so
  each gets the right variant.

## Size and forward the logs
- **Right-size the Security log (Step 6d).** 196608 KB (192 MB) is the Microsoft baseline; go larger if
  you forward on a schedule rather than continuously, so evidence survives between collections.
- **Overwrite oldest, never block.** Set the Security log to *overwrite events as needed* so a full log
  can't stop new auditing.
- **Auditing is the source; forwarding is separate.** This baseline makes devices *generate and keep*
  events. Pair it with the **Entra ID & Intune Audit Telemetry to Microsoft Sentinel** solution (Azure
  Monitor Agent + Data Collection Rule / Windows Security Events) to get them into your SIEM. Don't try
  to solve forwarding inside this profile.

## Deploy pilot-first and reversibly
- **Assign to `Win Audit Policy - Pilot Devices`, never "All devices" first.** Expand in waves after
  each gate passes.
- **Rollback is unassignment.** Because this only adds a configuration profile, removing the assignment
  cleanly reverts to the prior audit state — no re-enrollment or cleanup. Keep the profile so you can
  re-target quickly.

## Operate and monitor
- **Report before you widen.** Run `WINAUDIT-Report.ps1` each wave; only broaden when coverage matches
  the assigned group.
- **Remediate with `-WhatIf` first.** `WINAUDIT-Remediation.ps1` and `WINAUDIT-Set-ScopeTargeting.ps1`
  preview by default — read the plan, then apply.
- **Re-run `auditpol` after major Windows upgrades.** A feature update or a new co-managing policy can
  reintroduce a legacy audit setting; confirm the override is still `1` and subcategories still match.

## Change control
- **Version scope changes.** When you change a subcategory level or the log size, note the date and
  reason, and re-run Discovery + Report to confirm no regressions.
- **Map to your compliance requirement.** Record which benchmark (CIS L1/L2, a STIG, or your own
  standard) and which version the baseline targets, so an auditor can trace each subcategory value back
  to its source.


---


# 8. Deliverables Summary — Windows Advanced Audit Policy & Security Logging Baseline

Everything included in this solution package, and what each piece is for.

## Documentation (this guide)
- **Executive Summary** — the business case and outcome in one page, and the explicit scope: the audit
  *configuration* baseline for Windows 10/11 via Intune — not SIEM forwarding and not a broad CIS/STIG
  hardening baseline.
- **Solution Overview** — how Windows advanced (subcategory) auditing works, the all-important
  force-subcategory override (`SCENoApplyLegacyAuditPolicy`), what the baseline audits and why, the
  event-volume trade-offs, and how this relates to the Sentinel forwarding solution.
- **Requirements Guide** — every Intune/Windows prerequisite with how to **verify** and how to
  **implement if missing**, plus the category-level Global Requirements.
- **Implementation Guide** — exact, ordered, click-by-click steps to build one Settings Catalog profile
  (`Win Audit Policy - Baseline - Pilot`): the override, all ~24 audit subcategories with recommended
  Success/Failure values (CIS / Microsoft-aligned), command-line process auditing, and the Security-log
  size — then pilot, validate, and expand (including a server variant).
- **Testing & Validation** — nine tests with explicit pass/fail gates, including the mandatory
  override check and an on-device `auditpol` / Event Viewer verification, plus an acceptance gate.
- **Troubleshooting** — top-down diagnosis for "settings applied but nothing audited," missing 4688
  command line, log rollover, conflicts, and per-device gaps.
- **Best Practices** — override-first discipline, detection-over-volume tuning, workstation vs server
  split, log sizing/forwarding, and reversible pilot-first rollout.

## PowerShell scripts (Microsoft Graph) — `WINAUDIT-Scripts.zip`
All scripts are tenant-side (run from an admin workstation with the Microsoft Graph PowerShell SDK);
each has a header explaining **Purpose · How to run · Expected results**. Discovery, Validation, and
Report are **read-only**; Remediation and Set-ScopeTargeting **default to `-WhatIf`** (preview first,
then apply).

1. **`WINAUDIT-Discovery.ps1`** — tenant readiness: the `Win Audit Policy - Baseline - Pilot` Settings
   Catalog profile is present with the force-subcategory override and the audit subcategory settings.
2. **`WINAUDIT-Validation.ps1`** — validates the profile's **assignment** and per-device **applied**
   state, with a clear PASS/FAIL summary.
3. **`WINAUDIT-Report.ps1`** — tenant-wide CSV report of Windows 10/11 devices and whether the audit
   baseline profile is applied — the audit-coverage report.
4. **`WINAUDIT-Remediation.ps1`** — scaffolds the full Settings Catalog audit profile if missing (the
   override, all subcategories at their recommended values, command-line auditing, log size) and assigns
   it to a target group. **`-WhatIf` by default**; applies only when re-run to commit.
5. **`WINAUDIT-Set-ScopeTargeting.ps1`** — sets/adjusts the profile's group assignment (target-group
   builder, with optional exclusion group). **`-WhatIf` by default.**

## Hero image
- **`WINAUDIT-hero.png`** — the product image used on the marketplace listing.

## How it's delivered
A **Word** document and **PDF** (cover, table of contents, page numbers, and a scripts appendix), plus
all five PowerShell scripts in a single **ZIP** — yours to keep and reuse across **unlimited devices**.

## Related solutions (not included here)
- **Entra ID & Intune Audit Telemetry to Microsoft Sentinel** — forwards the Windows Security events
  this baseline produces into your SIEM (Azure Monitor Agent + Data Collection Rules). This solution is
  the *source*; that one is the *transport*.
- **CIS / STIG Windows Security Baseline** — the broad hardening baseline; this audit baseline is the
  focused auditing slice and complements it without duplication.
