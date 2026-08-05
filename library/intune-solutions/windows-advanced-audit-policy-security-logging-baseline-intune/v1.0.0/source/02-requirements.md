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
