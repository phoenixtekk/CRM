# Endpoint Security Baselines

> **Version 1.0.0** · Category: Intune · Solution code: ESB

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Endpoint Security Baselines (Microsoft Intune)

**White-label · Intune Solutions**

Hardening Windows by hand means choosing among hundreds of security settings — and getting some
wrong. **Security Baselines** in Microsoft Intune apply Microsoft's own recommended, pre-configured
set of hardening settings in one move, giving you an expert-grade secure posture without the
guesswork, then letting you customize and keep it current as Microsoft updates the baseline.

This is a complete, **deploy-it-today** package for implementing Endpoint Security Baselines with
Microsoft Intune, written for an administrator with no prior baseline experience — including how
to detect and resolve the setting conflicts baselines can introduce.

## What you get
- A plain-language **Solution Overview** of what baselines are and how they apply.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite.
- An **Implementation Guide** of precise, click-by-click Intune steps in the required order.
- Five **PowerShell scripts** for posture discovery, baseline validation, tenant reporting, conflict checking, and remediation.
- **Testing** and **Troubleshooting** guides for confident rollout.

## What this delivers
A deployed **Security Baseline for Windows** (and optionally the **Microsoft Defender for Endpoint**
and **Microsoft Edge** baselines), assigned to a pilot, with a clear process to **review per-setting
status, detect conflicts, and version-update** the baseline over time.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand.**

## Outcome
An expert, consistent, Microsoft-recommended hardening posture across the fleet — without manual
setting-by-setting work — deployable by a single administrator and validated before rollout.


---


# 1. Solution Overview — Endpoint Security Baselines

## What Security Baselines are
A security baseline in Microsoft Intune is a pre-configured group of security settings, set to the
values Microsoft's security team recommends. Instead of configuring hundreds of individual policy
settings, you deploy a baseline and the device adopts a vetted, hardened configuration — which you
can then customize and keep current as Microsoft publishes new baseline versions.

## Available baselines
- **Security Baseline for Windows 10 and later** — the core OS hardening baseline.
- **Microsoft Defender for Endpoint Baseline** — security settings for MDE-managed devices.
- **Microsoft Edge Baseline** — browser security settings.

## How it works
1. You create a **profile from a baseline version**; it starts at Microsoft's recommended values.
2. You review and, where needed, **adjust** specific settings for your environment.
3. You **assign** the profile to a pilot group; Intune applies the settings.
4. Intune reports **per-setting status** and flags **conflicts** with other profiles.
5. When Microsoft releases a **new baseline version**, you update the profile to stay current.

## Benefits
- **Expert hardening, fast** — Microsoft's recommendations applied in one move.
- **Consistency** — every device adopts the same vetted posture; no drift.
- **Customizable** — adjust the few settings your environment requires.
- **Maintained** — version updates track Microsoft's evolving recommendations.

## Limitations (be honest with buyers)
- Baselines can **conflict** with existing configuration profiles/GPOs — conflict detection and resolution are essential (covered here).
- Some hardened settings may affect line-of-business apps — pilot before fleet.
- Baselines are **versioned**; staying current requires periodic profile updates.
- A baseline is a strong starting point, not a substitute for the specific solutions (BitLocker, ASR, Firewall) where you want explicit control.

## The standard deployment model
> **Pick the latest baseline version → create a profile → review/adjust → assign to a pilot →
> resolve conflicts → expand → keep current.** repeatable pattern: **Assess → Configure → Pilot →
> Validate → Expand.**


---


# 2. Requirements Guide — Endpoint Security Baselines

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

## 2.1 Licensing
**Description:** Intune (Plan 1). The Defender for Endpoint baseline needs MDE licensing.
**Why:** Intune delivers baselines; the MDE baseline only applies to MDE-licensed/onboarded devices.
**Verify:** M365 admin center → **Billing → Licenses**.
**Implement:** Assign M365 E3/E5 or Business Premium; add MDE licensing for the Defender baseline.

## 2.2 Device enrollment
**Description:** Targeted devices enrolled in Intune.
**Why:** Baselines apply only to enrolled devices.
**Verify:** Intune → **Devices → All devices**.
**Implement:** Enable automatic enrollment; enroll devices.

## 2.3 Supported Windows OS
**Description:** Windows 10/11 current build.
**Why:** Baseline settings map to OS capabilities; older builds may not honor all settings.
**Verify:** `winver`; run **`ESB-Discovery.ps1`** for the current posture.
**Implement:** Patch/upgrade to a supported build.

## 2.4 Inventory of existing configuration
**Description:** Awareness of existing config profiles, security policies, and any GPOs.
**Why:** Baselines can conflict with settings you already manage elsewhere.
**Verify:** Intune → **Devices → Configuration**; **Endpoint security** policies; run **`ESB-ConflictCheck.ps1`** after assignment.
**Implement:** Document current policies; plan to consolidate or scope to avoid conflicts.

## 2.5 (Optional) Defender for Endpoint onboarding
**Description:** Devices onboarded to MDE.
**Why:** Required for the Microsoft Defender for Endpoint baseline.
**Verify:** Intune → **Endpoint security → Microsoft Defender for Endpoint**.
**Implement:** Deploy the **Defender for Endpoint Integration** solution.

## 2.6 Pilot group
**Description:** A pilot security group.
**Why:** Baselines change many settings — pilot to catch app/usability impact.
**Verify:** Entra → **Groups**.
**Implement:** Create a `Baseline-Pilot` security group.

---
## Checklist
- [ ] Intune licensing assigned (MDE licensing for the Defender baseline)
- [ ] Devices enrolled
- [ ] Supported Windows build — `ESB-Discovery.ps1`
- [ ] Existing config/GPO inventory documented
- [ ] (Optional) Devices onboarded to MDE for the Defender baseline
- [ ] Pilot Entra group created


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


# 3. Implementation Guide — Endpoint Security Baselines

Follow these steps **in order**, in the **Microsoft Intune admin center** (`https://intune.microsoft.com`).

> **Model:** Deploy the latest Windows security baseline to a pilot, resolve conflicts, then expand
> and keep it version-current.

## Step 1 — Create the pilot group
1. Entra → **Groups → New group** → Security → `Baseline-Pilot` → add pilot devices. **Create**.

## Step 2 — Review available baselines
1. Intune → **Endpoint security → Security baselines**.
2. Note the available baselines and their **latest version** (e.g. **Security Baseline for Windows 10 and later**).

## Step 3 — Create a baseline profile
1. Select **Security Baseline for Windows 10 and later → Create profile**.
2. **Name:** `Baseline - Windows - Pilot`. **Next**.
3. Confirm the profile is created from the **latest version** shown.

## Step 4 — Review and adjust settings
1. On **Configuration settings**, the categories show Microsoft's recommended values.
2. Leave defaults unless a setting conflicts with a required app or another solution you manage explicitly (e.g. if you manage BitLocker/Firewall/ASR via their own solutions, decide which owns those settings to avoid conflicts).
3. Click **Next**.

## Step 5 — Scope tags (optional)
1. Add scope tags if used, else **Next**.

## Step 6 — Assign to the pilot group
1. **Assignments → Add groups →** `Baseline-Pilot`. **Next → Create**.

## Step 7 — Monitor application and conflicts
1. Intune → **Endpoint security → Security baselines →** profile → **View report** / **Per-setting status**.
2. Resolve **Conflicts** — a setting controlled by two policies. Run **`ESB-ConflictCheck.ps1`** to list overlapping policies; make one policy authoritative per setting.

## Step 8 — Validate the pilot
1. On a pilot device, run **`ESB-Validation.ps1`** → confirms representative baseline settings applied.
2. Run **`ESB-TenantReport.ps1`** → confirms assignment + per-setting success across the pilot. Complete the **Testing Guide**.

## Step 9 — Expand and keep current
1. Add a production group to the baseline **Assignments**; roll out in waves.
2. When Microsoft releases a **new baseline version**, select the profile → **Change version** → review changes → update.
3. Re-validate with **`ESB-Validation.ps1`** / **`ESB-TenantReport.ps1`**.

---
### Order of operations
`Pilot group → Review baselines → Create profile (latest version) → Adjust → Assign → Resolve conflicts → Validate → Expand → Version-update`


---


# 5. Testing Guide — Endpoint Security Baselines

Run after the pilot baseline applies (Implementation Step 8) and after each production wave or version update.

## Test 1 — Profile assigned and applying
**Do:** Intune → **Endpoint security → Security baselines →** profile → **Device status**.
**Expected:** Pilot devices show **Succeeded** (not Error).

## Test 2 — No unresolved conflicts
**Do:** Review **Per-setting status** for **Conflict**; run `ESB-ConflictCheck.ps1`.
**Expected:** No settings in **Conflict** (each contested setting has one authoritative owner).

## Test 3 — Representative settings applied
**Do:** On a pilot device run `ESB-Validation.ps1` (checks a sample of hardened settings).
**Expected:** Sampled baseline settings are at the expected hardened values.

## Test 4 — No critical app/usability breakage
**Do:** Have pilot users run their core line-of-business apps for a day or two.
**Expected:** No baseline-induced breakage; capture and adjust any setting that blocks a required app.

## Test 5 — Compliance intact
**Do:** Intune → **Devices → Compliance**.
**Expected:** Devices remain **Compliant**.

## Test 6 — Version update flows cleanly
**Do:** When testing a baseline version change, review the **change summary** before applying.
**Expected:** You can see what changed and apply it without unexpected conflicts.

## Test 7 — Tenant report
**Do:** Run **`ESB-TenantReport.ps1`**.
**Expected:** Assignment and per-setting success summary for the pilot group.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–4 pass; conflicts resolved; no critical app breakage |
| **Wave pass** | Tests 1–2, 5, 7 pass before the next wave |


---


# 6. Troubleshooting Guide — Endpoint Security Baselines

Use **`ESB-Validation.ps1`** / **`ESB-Discovery.ps1`** for device posture and
**`ESB-ConflictCheck.ps1`** for overlaps, **`ESB-Remediation.ps1`** to force a sync.

## A. Settings in conflict (most common)
| Symptom | Cause | Remediation |
|---|---|---|
| Per-setting status shows **Conflict** | Two policies set the same setting differently | Run `ESB-ConflictCheck.ps1`; pick one authoritative policy for that setting; remove/scope the other |
| Baseline fights a dedicated solution | BitLocker/Firewall/ASR managed both by baseline and its own solution | Decide one owner per area; exclude that area from the baseline or from the dedicated policy |
| Legacy GPO overrides baseline | On-prem GPO sets the same control | Disable/scope the GPO away from Intune-managed devices |

## B. Baseline not applying
| Symptom | Cause | Remediation |
|---|---|---|
| Profile "Error"/"Pending" | Device not synced / not enrolled | Run `ESB-Remediation.ps1` (forces sync); confirm device in `Baseline-Pilot` |
| Some settings "Not applicable" | OS build doesn't support the setting | Patch/upgrade Windows; expected for down-level builds |

## C. App or usability breakage
- A hardened setting blocks a required app → identify it via per-setting status / event logs, then **adjust that single setting** in the baseline profile (don't abandon the whole baseline).
- Pilot exists precisely to catch this before fleet rollout.

## D. Version update problems
- Unexpected changes after updating a baseline version → review the **change summary** first; test the new version on the pilot before production.
- A setting reverted → a newer version may have changed a default; re-apply your customization.

## E. Diagnostics quick reference
```powershell
# sample of hardened values the baseline sets:
Get-MpPreference | Select-Object PUAProtection, EnableNetworkProtection
(Get-NetFirewallProfile).Enabled
Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' -Name LimitBlankPasswordUse -EA SilentlyContinue
```
Intune → **Endpoint security → Security baselines → (profile) → Per-setting status** is the
authoritative view of what applied and what conflicted.

## F. When to escalate
If a setting shows **Error** (not Conflict) on a healthy, synced, supported device and persists
after remediation, capture the per-setting detail and open a Microsoft support case.


---


# 7. Best Practices — Endpoint Security Baselines

- **Always pilot.** Baselines change many settings at once; pilot to catch app/usability impact before fleet rollout.
- **Start from the latest version.** Create profiles from the newest baseline so you begin at current recommendations.
- **One owner per setting.** Decide whether the baseline or a dedicated solution (BitLocker, Firewall, ASR) owns a given control — never both — to avoid conflicts.
- **Resolve conflicts immediately.** A setting in Conflict is effectively unmanaged; use `ESB-ConflictCheck.ps1` and consolidate.
- **Change settings surgically.** When a baseline setting breaks an app, adjust that one setting — don't discard the whole baseline.
- **Retire overlapping GPOs.** Don't run a legacy GPO and an Intune baseline against the same control.
- **Track versions.** When Microsoft ships a new baseline version, review the change summary, pilot it, then update.
- **Layer, don't duplicate.** Use the baseline for broad hardening and the dedicated solutions for areas you want explicit, reportable control over.
- **Document deviations.** Record every setting you changed from Microsoft's recommendation and why — for audits and future updates.
- **Monitor continuously.** Use `ESB-TenantReport.ps1` to keep per-setting success high across the fleet.


---


# 8. Deliverables Summary — Endpoint Security Baselines

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What baselines are, available baselines, how they apply, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Intune steps including conflict resolution and version updates |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Conflicts and field issues |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `ESB-Discovery.ps1` | Snapshot of the device's current security posture (sample of baseline-relevant settings) |
| `ESB-Validation.ps1` | Confirms representative baseline settings are applied at hardened values |
| `ESB-TenantReport.ps1` | Tenant-wide baseline assignment + per-setting state (Microsoft Graph) |
| `ESB-ConflictCheck.ps1` | Lists security/config policies that may conflict with the baseline (Microsoft Graph) |
| `ESB-Remediation.ps1` | Forces an MDM sync so the baseline re-applies |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the repeatable model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
An expert, consistent, Microsoft-recommended hardening posture across the fleet — without manual setting-by-setting work.
