# Windows Firewall Management

> **Version 1.0.0** · Category: Intune · Solution code: WFM

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Windows Firewall Management (Microsoft Intune)

**White-label · Intune Solutions**

The host firewall is the last line of defense on every endpoint — but on unmanaged fleets it's
often disabled, inconsistently configured, or full of stale rules. **Windows Firewall Management**
through Microsoft Intune enforces the firewall on across every network profile, sets a sane
**default-deny inbound** posture, deploys standardized rules, and reports the firewall state of
every device.

This is a complete, **deploy-it-today** package for managing Windows Defender Firewall with
Microsoft Intune, written for an administrator with no prior firewall-management experience.

## What you get
- A plain-language **Solution Overview** of Intune-managed firewall policy.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite.
- An **Implementation Guide** of precise, click-by-click Intune steps in the required order.
- Five **PowerShell scripts** for firewall discovery, validation, rule reporting, remediation, and conflict checking.
- **Testing** and **Troubleshooting** guides for confident rollout.

## What this delivers
An Intune **firewall policy** that enables the firewall for **Domain, Private, and Public**
profiles, sets **default inbound = Block / outbound = Allow**, configures logging and stealth mode,
and (optionally) deploys a standardized **firewall rules** set — assigned to a pilot, then expanded.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand.**

## Outcome
A consistently enforced host firewall across the fleet with default-deny inbound and centralized
rules — deployable by a single administrator and validated before rollout.


---


# 1. Solution Overview — Windows Firewall Management

## What this is
Windows Defender Firewall is the built-in host firewall on every Windows device. This solution
manages it centrally through Microsoft Intune: enforcing it **on** for all network profiles,
setting default inbound/outbound behavior, deploying standardized firewall **rules**, and reporting
each device's firewall state — so the host firewall is consistent and auditable across the fleet.

## How it works
1. An Intune **firewall policy** (Endpoint security → Firewall) sets the firewall **on** for the
   **Domain, Private, and Public** profiles.
2. It defines **default actions** — typically **inbound = Block**, **outbound = Allow** — plus
   logging, stealth mode, and unicast-response behavior.
3. An optional **firewall rules** policy deploys specific allow/block rules (ports, apps, IP scopes).
4. Intune applies and **reports** the firewall state; devices that drift are visible.

## What you can manage
- **Firewall enabled** per profile (Domain/Private/Public).
- **Default inbound/outbound** actions.
- **Logging** (dropped packets, successful connections) and log size/path.
- **Stealth mode**, **shielded** mode, unicast response to multicast/broadcast.
- **Custom firewall rules** (allow/block by port, program, protocol, or address).

## Benefits
- **Consistent enforcement** — the firewall is on everywhere, no exceptions.
- **Default-deny inbound** — reduces exposure to lateral movement and scanning.
- **Centralized rules** — one managed rule set instead of per-device drift.
- **Visibility** — fleet-wide firewall-state reporting for compliance and audits.

## Limitations (be honest with buyers)
- Firewall settings can **conflict** with a legacy GPO firewall or the security baseline — manage in one place.
- Overly strict rules can block legitimate apps — pilot and validate first.
- Custom rules must be maintained as your app/port landscape changes.
- Some specialized scenarios (server roles, IPsec connection security rules) need extra design beyond this baseline.

## The standard deployment model
> **Create the firewall policy (on + default-deny inbound) → (optional) deploy rules → assign to a
> pilot → validate → expand.** repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**


---


# 2. Requirements Guide — Windows Firewall Management

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

## 2.1 Licensing
**Description:** Intune (Plan 1).
**Why:** Intune delivers and reports the firewall policy.
**Verify:** M365 admin center → **Billing → Licenses**.
**Implement:** Assign M365 E3/E5 or Business Premium (Intune included).

## 2.2 Device enrollment
**Description:** Devices enrolled in Intune.
**Why:** The firewall policy applies only to enrolled devices.
**Verify:** Intune → **Devices → All devices**.
**Implement:** Enable automatic enrollment; enroll devices.

## 2.3 Supported Windows OS
**Description:** Windows 10/11.
**Why:** The firewall CSP settings require a supported Windows build.
**Verify:** `winver`; run **`WFM-Discovery.ps1`**.
**Implement:** Patch/upgrade to a supported build.

## 2.4 Inventory of legitimate inbound needs
**Description:** Awareness of apps/services that require inbound connections.
**Why:** Default-deny inbound can block legitimate listeners (e.g. Remote Help, remote management, line-of-business servers).
**Verify:** Review current inbound rules (`WFM-Discovery.ps1` lists rule counts; export details as needed).
**Implement:** Plan explicit allow rules for required inbound services.

## 2.5 No conflicting firewall management
**Description:** No legacy GPO firewall or baseline managing the same settings.
**Why:** Two policies setting the firewall fight each other.
**Verify:** Run **`WFM-ConflictCheck.ps1`**; check the security baseline for firewall settings.
**Implement:** Make Intune the single firewall authority; disable/scope away the GPO and baseline firewall settings.

---
## Checklist
- [ ] Intune licensing assigned
- [ ] Devices enrolled
- [ ] Supported Windows build — `WFM-Discovery.ps1`
- [ ] Legitimate inbound needs documented (allow rules planned)
- [ ] No conflicting GPO/baseline firewall management — `WFM-ConflictCheck.ps1`
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


# 3. Implementation Guide — Windows Firewall Management

Follow these steps **in order**, in the **Microsoft Intune admin center** (`https://intune.microsoft.com`).

> **Model:** A firewall policy enabling all profiles with default-deny inbound, plus an optional
> rules policy, assigned to a pilot group.

## Step 1 — Create the pilot group
1. Entra → **Groups → New group** → Security → `Firewall-Pilot` → add pilot devices. **Create**.

## Step 2 — Create the firewall policy
1. Intune → **Endpoint security → Firewall → Create Policy**.
2. **Platform:** Windows. **Profile:** **Windows Firewall**. **Create**.
3. **Name:** `Firewall - Pilot`. **Next**.

## Step 3 — Configure the firewall settings
On **Configuration settings**, for **Domain**, **Private**, and **Public** profiles set:
1. **Firewall enabled** = **Allowed** (turns the firewall on for that profile).
2. **Default inbound action** = **Block**.
3. **Default outbound action** = **Allow**.
4. **Stealth mode** = **Block** (not configured to disable) — keeps the device from responding to probes.
5. **Inbound notifications** = **Block** (suppress per-app prompts to users) or as your policy prefers.
6. **Unicast responses to multicast broadcast** = **Block** (recommended).
7. **Log file path / size**, **Log dropped packets** = **Enable**, **Log successful connections** = optional.
Click **Next**.

## Step 4 — Assign to the pilot group
1. **Assignments → Add groups →** `Firewall-Pilot`. **Next → Create**.

## Step 5 — (Optional) create a firewall rules policy
Only if you need explicit allow/block rules (e.g. allow Remote Help inbound, allow a LOB app).

1. **Endpoint security → Firewall → Create Policy → Windows → Windows Firewall Rules**. **Create**.
2. **Name:** `Firewall Rules - Pilot`. Add each rule: **Name**, **Direction** (In/Out), **Action** (Allow/Block), **Protocol/Ports**, **Program**, **Local/Remote address** scope.
3. **Assignments → Add groups →** `Firewall-Pilot`. **Create**.

## Step 6 — Apply on a pilot device
1. On a pilot device, sync policy (**Settings → Accounts → Access work or school → Info → Sync**).
2. Confirm the firewall is on for all profiles and the default inbound action is Block.

## Step 7 — Validate the pilot
1. Run **`WFM-Validation.ps1`** → confirms all profiles enabled with default-deny inbound.
2. Run **`WFM-RuleReport.ps1`** → lists effective firewall rules.
3. Run **`WFM-ConflictCheck.ps1`** → flags GPO/baseline firewall conflicts. Complete the **Testing Guide**.

## Step 8 — Expand to production
1. Add a production group to the firewall policy **Assignments**; roll out in waves.
2. Verify required inbound services still work (add explicit allow rules as needed) before broad rollout.
3. Re-validate each wave with **`WFM-Validation.ps1`**.

---
### Order of operations
`Pilot group → Firewall policy (profiles on + default-deny inbound) → (optional) rules policy → Assign → Apply → Validate → Expand`


---


# 5. Testing Guide — Windows Firewall Management

Run after the pilot policy applies (Implementation Step 7) and after each production wave.

## Test 1 — Policy applied
**Do:** Intune → **Endpoint security → Firewall →** `Firewall - Pilot` **→ Device status**.
**Expected:** Pilot devices show **Succeeded**.

## Test 2 — All profiles enabled
**Do:** On a pilot device run `WFM-Validation.ps1` or `Get-NetFirewallProfile`.
**Expected:** Domain, Private, and Public profiles all **Enabled = True**.

## Test 3 — Default inbound is Block
**Do:** `Get-NetFirewallProfile | Select Name, DefaultInboundAction, DefaultOutboundAction`.
**Expected:** **DefaultInboundAction = Block**, **DefaultOutboundAction = Allow** for all profiles.

## Test 4 — Legitimate inbound still works
**Do:** Exercise required inbound services (e.g. Remote Help, remote management) on a pilot device.
**Expected:** Allowed services still work (via explicit allow rules); everything else inbound is blocked.

## Test 5 — Rules applied (if a rules policy is used)
**Do:** Run `WFM-RuleReport.ps1`.
**Expected:** The deployed allow/block rules are present and effective.

## Test 6 — No conflicts
**Do:** Run `WFM-ConflictCheck.ps1`; review Intune device → firewall policy status.
**Expected:** No GPO/baseline policy contesting the firewall settings.

## Test 7 — Compliance intact
**Do:** Intune → **Devices → Compliance** (with a firewall compliance rule, if used).
**Expected:** Devices remain **Compliant**; the firewall requirement passes.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–4 pass; required inbound services confirmed working |
| **Wave pass** | Tests 2–3, 7 pass before the next wave |


---


# 6. Troubleshooting Guide — Windows Firewall Management

Use **`WFM-Validation.ps1`** / **`WFM-Discovery.ps1`** for firewall state and
**`WFM-RuleReport.ps1`** / **`WFM-ConflictCheck.ps1`** to inspect rules and conflicts,
**`WFM-Remediation.ps1`** for safe fixes.

## A. Firewall not enabled / profiles off
| Symptom | Cause | Remediation |
|---|---|---|
| A profile shows Disabled | Policy not applied / synced, or a conflicting policy disabled it | Run `WFM-Remediation.ps1` (re-enables + syncs); resolve conflicts (`WFM-ConflictCheck.ps1`) |
| Policy "Error" | Device not synced/enrolled | Sync; confirm device in `Firewall-Pilot` |

## B. Legitimate inbound blocked
| Symptom | Cause | Remediation |
|---|---|---|
| Remote Help / remote mgmt / LOB app can't connect inbound | Default-deny inbound with no allow rule | Add an explicit **allow inbound** rule (rules policy) for the required port/program; re-test |
| App worked before, now blocked | Default inbound flipped to Block | Expected — create the allow rule for it; this is the point of default-deny |

## C. Conflicts
- A legacy **GPO firewall** or the **security baseline** also sets firewall state → they fight Intune. Make Intune the single authority; disable/scope the GPO and remove firewall settings from the baseline. Use `WFM-ConflictCheck.ps1`.
- "Merge" behavior: local rules may still apply unless you disable local rule merge — decide whether local admins can add rules.

## D. Rules not taking effect
- Rule present but not working → check direction/protocol/port/scope; confirm the profile the rule applies to matches the active network profile.
- Use `WFM-RuleReport.ps1` to see effective rules and their enabled state.

## E. Diagnostics quick reference
```powershell
Get-NetFirewallProfile | Select Name, Enabled, DefaultInboundAction, DefaultOutboundAction
Get-NetFirewallRule -Enabled True | Select DisplayName, Direction, Action | Sort Direction
netsh advfirewall show allprofiles
```
Firewall log (if enabled): `%systemroot%\system32\LogFiles\Firewall\pfirewall.log`.

## F. When to escalate
If profiles are enabled, the policy shows Succeeded, no conflicts are reported, and a required
service is still blocked with an allow rule in place, capture `Get-NetFirewallRule` output and the
firewall log and open a Microsoft support case.


---


# 7. Best Practices — Windows Firewall Management

- **Enable all three profiles.** Domain, Private, and Public should all have the firewall on — no exceptions.
- **Default-deny inbound, allow outbound.** The single highest-value posture; add explicit allow rules only for required inbound services.
- **Pilot before fleet.** Default-deny inbound can block legitimate listeners — confirm required services work on a pilot first.
- **Inventory inbound needs first.** Know what must accept inbound (Remote Help, remote management, LOB servers) and pre-build those allow rules.
- **One firewall authority.** Manage the firewall via Intune only — retire the GPO firewall and remove firewall settings from the security baseline to avoid conflicts.
- **Decide on local rule merge.** Choose whether local admins can add rules; for locked-down fleets, disable local merge.
- **Enable logging.** Log dropped packets to diagnose blocked legitimate traffic quickly.
- **Use stealth mode.** Keep devices from responding to unsolicited probes.
- **Name rules clearly.** `Allow-Inbound-<service>-<port>` so intent is obvious in audits.
- **Report regularly.** Track firewall state across the fleet with `WFM-RuleReport.ps1` / Intune reporting.


---


# 8. Deliverables Summary — Windows Firewall Management

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What Intune-managed firewall is, how it works, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Intune steps (profiles, defaults, rules) |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and rule handling |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `WFM-Discovery.ps1` | Reports firewall profile state and rule counts on the device |
| `WFM-Validation.ps1` | Confirms all profiles enabled with default-deny inbound |
| `WFM-RuleReport.ps1` | Lists effective firewall rules (direction/action/port) |
| `WFM-Remediation.ps1` | Safe remediation; re-enables firewall profiles and forces a sync |
| `WFM-ConflictCheck.ps1` | Lists Intune firewall policies/assignments to spot conflicts (Microsoft Graph) |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the repeatable model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
A consistently enforced host firewall across the fleet with default-deny inbound and centralized rules.
