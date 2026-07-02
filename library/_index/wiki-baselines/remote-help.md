# Remote Help

> **Version 1.0.0** · Category: Intune · Solution code: RHELP

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Remote Help (Microsoft Intune)

**White-label · Intune Solutions**

Ad-hoc remote-support tools are a security liability: unverified helpers, no role controls, no
audit trail, and third-party software you don't fully trust. **Remote Help** is Microsoft's
cloud remote-assistance solution built into the Intune ecosystem — helpers are authenticated with
Microsoft Entra, gated by **role-based access control**, shown the device's **compliance** state,
and every session is **audited**.

This is a complete, **deploy-it-today** package for implementing Remote Help with Microsoft Intune,
written for an administrator with no prior Remote Help experience.

## What you get
- A plain-language **Solution Overview** of how Remote Help works and its security model.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite (including licensing).
- An **Implementation Guide** of precise, click-by-click Intune steps in the required order.
- Five **PowerShell scripts** for app discovery, validation, tenant settings/assignment checks, remediation, and a session/usage report.
- **Testing** and **Troubleshooting** guides for confident rollout.

## What this delivers
Remote Help **enabled** in your tenant, the Remote Help **app deployed** to devices via Intune,
**RBAC roles** assigned to your help desk, and the security options (require Entra auth, RBAC,
compliance warnings) configured — piloted, then expanded.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Secure, audited, role-controlled remote assistance for your help desk — replacing risky ad-hoc
tools — deployable by a single administrator and validated before rollout.


---


# 1. Solution Overview — Remote Help

## What Remote Help is
Remote Help is Microsoft's cloud-based remote-assistance application, integrated with Microsoft
Intune. A help-desk technician (the **helper**) can securely view and, with consent, control an
enrolled user's device (the **sharer**) — authenticated through Microsoft Entra, governed by
**role-based access control (RBAC)**, shown the device's **compliance** status, and recorded in
an **audit** trail.

## How it works
1. Remote Help is **enabled** in the Intune tenant settings (license required).
2. The **Remote Help app** is deployed to devices through Intune.
3. **RBAC roles** determine who can help, who can request help, and whether full control is allowed.
4. A session starts with both parties signing in with **Entra** credentials; the sharer grants consent; the helper sees the device's **compliance** state before assisting.
5. The session is **audited** (who helped whom, when).

## Security model
- **Entra-authenticated** helpers and sharers — no anonymous access.
- **RBAC** — least-privilege roles (e.g. Help Desk Operator) control capabilities.
- **Compliance visibility** — helpers see if the device is compliant before connecting.
- **Conditional control** — view-only vs full control configurable; elevation prompts respected.
- **Audited** — sessions are logged for accountability.

## Benefits
- **Secure** — replaces risky third-party/ad-hoc tools with an Entra-governed, audited service.
- **Least privilege** — RBAC ensures only authorized staff assist, with the right capabilities.
- **Trust signals** — compliance state surfaces device risk to the helper.
- **Integrated** — managed and reported within the Intune ecosystem you already run.

## Limitations (be honest with buyers)
- Requires a **Remote Help license** (Intune Suite or the Remote Help standalone add-on).
- The **Remote Help app** must be deployed to participating devices.
- Network access to the Remote Help service endpoints is required.
- Cross-tenant / unenrolled-device assistance has specific settings and limits.

## The standard deployment model
> **Enable Remote Help → deploy the app via Intune → assign RBAC roles → configure security
> options → pilot a session → expand.** repeatable pattern: **Assess → Configure → Pilot →
> Validate → Expand.**


---


# 2. Requirements Guide — Remote Help

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

## 2.1 Remote Help licensing
**Description:** A Remote Help license — the **Intune Suite** or the standalone **Remote Help add-on**.
**Why:** Remote Help is an add-on capability; it won't enable without the license.
**Verify:** M365 admin center → **Billing → Licenses** (look for Intune Suite / Remote Help); Intune → **Tenant administration → Remote Help**.
**Implement:** Purchase the Intune Suite or Remote Help add-on and assign to helpers (and sharers as required).

## 2.2 Intune + enrollment
**Description:** Intune subscription with target devices enrolled.
**Why:** Remote Help is deployed and governed through Intune.
**Verify:** Intune → **Devices → All devices**.
**Implement:** Enable automatic enrollment; enroll devices.

## 2.3 The Remote Help app
**Description:** The Remote Help application installed on participating devices.
**Why:** Both helper and sharer run the app to connect.
**Verify:** App present at `C:\Program Files\Remote help\` (or run **`RHELP-Discovery.ps1`**).
**Implement:** Deploy the Remote Help app via Intune (Win32/Store) as **Required** to the relevant groups.

## 2.4 RBAC roles
**Description:** Intune RBAC roles defining who can help and with what capabilities.
**Why:** Least-privilege control over remote assistance.
**Verify:** Intune → **Tenant administration → Roles**.
**Implement:** Assign **Help Desk Operator** (or a custom role with Remote Help permissions) to your support staff.

## 2.5 Network access
**Description:** Outbound HTTPS to the Remote Help / Intune service endpoints.
**Why:** Sessions are brokered through the cloud service.
**Verify:** Helpers and sharers can reach the Remote Help endpoints (the app connects).
**Implement:** Allow the Remote Help service URLs through proxy/firewall.

## 2.6 Supported OS
**Description:** Windows 10/11 (Remote Help also supports certain macOS/Android scenarios).
**Why:** The app and features require supported platforms.
**Verify:** `winver`.
**Implement:** Patch/upgrade as needed.

---
## Checklist
- [ ] Remote Help license (Intune Suite / add-on) assigned
- [ ] Devices enrolled in Intune
- [ ] Remote Help app deployed — `RHELP-Discovery.ps1`
- [ ] RBAC roles assigned to help-desk staff
- [ ] Network allows Remote Help endpoints
- [ ] Supported OS
- [ ] Pilot Entra group (helpers + sharers) created


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


# 3. Implementation Guide — Remote Help

Follow these steps **in order**, in the **Microsoft Intune admin center** (`https://intune.microsoft.com`).

> **Model:** Enable Remote Help → deploy the app → assign RBAC → configure security → pilot a session → expand.

## Step 1 — Create the pilot groups
1. Entra → **Groups → New group** → Security → `RemoteHelp-Helpers` (add help-desk staff). **Create**.
2. Create `RemoteHelp-Sharers` (add pilot end-user devices/users). **Create**.

## Step 2 — Enable Remote Help
1. Intune → **Tenant administration → Remote Help**.
2. Set **Enable Remote Help** to **Enabled**. Review and accept the terms.
3. Configure options:
   - **Allow Remote Help to unenrolled devices** = your policy (default **No** for tighter control).
   - **Allow remote control** = **Yes** (or view-only if preferred).
   - **Disable chat** = as preferred.
4. **Save**.

## Step 3 — Deploy the Remote Help app
1. Intune → **Apps → Windows → Add**.
2. Add **Remote Help** (Microsoft Store app / Win32 per your packaging).
3. **Assignments → Required →** `RemoteHelp-Helpers` and `RemoteHelp-Sharers`. **Create**.

## Step 4 — Assign RBAC roles
1. Intune → **Tenant administration → Roles → Help Desk Operator** (or a custom role with Remote Help permissions).
2. **Assignments → Assign →** scope to `RemoteHelp-Helpers`; set the member/scope groups. **Save**.
3. Confirm the role grants the Remote Help capabilities you intend (view vs full control, elevation).

## Step 5 — Verify app delivery on pilot devices
1. On a pilot helper and a pilot sharer device, confirm the **Remote Help** app installed (Step 3) — run **`RHELP-Validation.ps1`**.

## Step 6 — Run a pilot session
1. On the **sharer** device, open **Remote Help → Get help** (or the helper sends a request).
2. On the **helper** device, open **Remote Help → Give help**, sign in with Entra, enter the session.
3. Confirm the helper sees the device **compliance** state, the sharer **consents**, and (if enabled) control works.

## Step 7 — Validate
1. Run **`RHELP-SettingsCheck.ps1`** → confirms Remote Help is enabled with the chosen options.
2. Run **`RHELP-SessionReport.ps1`** → confirms the pilot session appears in the audit/usage data.
3. Complete the **Testing Guide** (Section 5).

## Step 8 — Expand to production
1. Add production helper and sharer groups to the app assignment and RBAC scope.
2. Roll out in waves; confirm app delivery and a successful session per wave.
3. Re-validate with **`RHELP-Validation.ps1`** / **`RHELP-SessionReport.ps1`**.

---
### Order of operations
`Pilot groups → Enable Remote Help → Deploy app → Assign RBAC → Verify app → Pilot session → Validate → Expand`


---


# 5. Testing Guide — Remote Help

Run after the pilot setup (Implementation Step 7) and after each production wave.

## Test 1 — Remote Help enabled
**Do:** Intune → **Tenant administration → Remote Help**; or run `RHELP-SettingsCheck.ps1`.
**Expected:** Remote Help is **Enabled** with your chosen options (remote control, unenrolled policy).

## Test 2 — App deployed
**Do:** On pilot helper and sharer devices run `RHELP-Validation.ps1` (checks the app is installed).
**Expected:** The Remote Help app is present (and the assignment shows Succeeded in Intune → Apps).

## Test 3 — RBAC gates access
**Do:** Have a non-help-desk account attempt to give help.
**Expected:** Only members of the help-desk role can initiate a "Give help" session.

## Test 4 — Session connects with consent
**Do:** Run a session: sharer requests help, helper joins, sharer consents.
**Expected:** The session connects; the helper sees the device, and control works if enabled.

## Test 5 — Compliance is surfaced
**Do:** During the session, observe the device compliance indicator shown to the helper.
**Expected:** The helper sees whether the device is compliant before assisting.

## Test 6 — Session is audited
**Do:** Run `RHELP-SessionReport.ps1` (or review Intune audit/Remote Help usage).
**Expected:** The session appears with helper, sharer, and timestamp.

## Test 7 — Unenrolled-device policy honored
**Do:** If "allow unenrolled" is **No**, attempt to help an unenrolled device.
**Expected:** The session is not permitted, per policy.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–6 pass for the pilot helpers/sharers |
| **Wave pass** | Tests 2, 4, 6 pass before the next wave |


---


# 6. Troubleshooting Guide — Remote Help

Use **`RHELP-Validation.ps1`** / **`RHELP-Discovery.ps1`** for app state and
**`RHELP-SettingsCheck.ps1`** for tenant settings, **`RHELP-Remediation.ps1`** for safe fixes.

## A. Remote Help won't enable
| Symptom | Cause | Remediation |
|---|---|---|
| "Enable" greyed out / error | No Remote Help license | Confirm Intune Suite / Remote Help add-on is purchased and assigned; `RHELP-SettingsCheck.ps1` |
| Enabled but options missing | Tenant not refreshed | Wait/refresh; re-open Tenant administration → Remote Help |

## B. App not present
| Symptom | Cause | Remediation |
|---|---|---|
| `RHELP-Validation.ps1` says not installed | App not deployed/assigned, or not synced | Confirm the app assignment (Required) to the device's group; `RHELP-Remediation.ps1` forces a sync; check Intune → Apps install status |
| Old app version | Auto-update off | Redeploy the current Remote Help app via Intune |

## C. Can't start a session
| Symptom | Cause | Remediation |
|---|---|---|
| Helper can't "Give help" | Missing RBAC role | Assign Help Desk Operator (or a role with Remote Help permissions) to the helper |
| Connection fails | Network/endpoints blocked | Allow Remote Help service URLs through proxy/firewall; avoid SSL inspection of those endpoints |
| Unenrolled device refused | Policy disallows unenrolled | Expected if "allow unenrolled" = No; change the setting or enroll the device |

## D. Control/compliance issues
- Helper can view but not control → "Allow remote control" is off, or the role/role-scope doesn't grant control. Adjust the Remote Help setting and the RBAC role.
- Compliance shows unknown → the device hasn't reported compliance; ensure it's enrolled and evaluated (Device Compliance solution).

## E. Diagnostics quick reference
```powershell
Get-Process remotehelp -ErrorAction SilentlyContinue        # is the app running?
Test-Path 'C:\Program Files\Remote help\remotehelp.exe'      # is it installed?
dsregcmd /status                                             # Entra state (auth for sessions)
```
Tenant setting + usage: Intune → **Tenant administration → Remote Help** (status + usage report).

## F. When to escalate
If the license is assigned, Remote Help is enabled, the app is installed, RBAC is correct, and
sessions still fail to connect, capture the app version and a session error and open a Microsoft Intune support case.


---


# 7. Best Practices — Remote Help

- **Assign least-privilege RBAC.** Give help-desk staff the minimum role needed; reserve full control for roles that truly require it.
- **Decide the unenrolled-device policy deliberately.** Default to **not** allowing assistance to unenrolled devices unless you have a clear need.
- **Deploy the app as Required.** Push Remote Help to helper and sharer groups via Intune so it's always present when needed.
- **Pilot a real session.** Validate helper + sharer + consent + control end-to-end before broad rollout.
- **Use compliance signals.** Train helpers to check the device compliance indicator before assisting.
- **Keep the app current.** Ensure the Remote Help app updates so features and fixes stay in place.
- **Don't SSL-inspect Remote Help traffic.** Exclude the service endpoints from inspection to avoid broken sessions.
- **Review the audit/usage data.** Periodically run `RHELP-SessionReport.ps1` to monitor who is assisting whom.
- **Communicate consent.** Make sure end users know sessions require their consent and are audited — it builds trust.
- **Document the role model.** Record which roles can help, control, and assist unenrolled devices for audits.


---


# 8. Deliverables Summary — Remote Help

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What Remote Help is, the security model, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing (incl. licensing) |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Intune steps (enable, deploy app, RBAC, session) |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `RHELP-Discovery.ps1` | Reports OS, network reachability, and whether the Remote Help app is present |
| `RHELP-Validation.ps1` | Confirms the Remote Help app is installed and ready on the device |
| `RHELP-SettingsCheck.ps1` | Confirms Remote Help is enabled tenant-wide with the chosen options (Microsoft Graph) |
| `RHELP-Remediation.ps1` | Safe remediation; forces an app/policy sync to (re)install the app |
| `RHELP-SessionReport.ps1` | Reports Remote Help session/usage activity for auditing (Microsoft Graph) |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the repeatable model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Secure, audited, role-controlled remote assistance for your help desk — replacing risky ad-hoc tools.
