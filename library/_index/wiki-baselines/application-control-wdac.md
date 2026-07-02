# Application Control (WDAC)

> **Version 1.0.0** · Category: Intune · Solution code: WDAC

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Application Control (WDAC) (Microsoft Intune)

**White-label · Intune Solutions**

Antivirus asks "is this file known-bad?" **Application Control** asks the stronger question: "is
this code explicitly trusted?" — and blocks everything else. **Windows Defender Application
Control (WDAC / App Control for Business)** is kernel-enforced allowlisting that stops untrusted
executables, scripts, and installers from running at all. Managed through Microsoft Intune and
rolled out **Audit-first**, it delivers powerful protection without locking your users out.

This is a complete, **deploy-it-today** package for implementing WDAC with Microsoft Intune,
written for an administrator with no prior application-control experience — including the
audit-first method and recovery steps that make a powerful control safe to deploy.

## What you get
- A plain-language **Solution Overview** of how allowlisting and trust models work.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite.
- An **Implementation Guide** of precise, click-by-click Intune steps in the required order.
- Five **PowerShell scripts** for policy discovery, validation, audit-event reporting, remediation/recovery, and tenant policy reporting.
- **Testing** and **Troubleshooting** guides for confident, lockout-free rollout.

## What this delivers
An Intune **App Control for Business** policy that trusts **Windows + Microsoft Store** apps (and,
optionally, reputable apps via the Intelligent Security Graph and **Intune-managed installers**),
deployed in **Audit mode first**, reviewed against Code Integrity events, then moved to **Enforce**.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Strong, kernel-enforced protection against untrusted code — deployed safely with audit-first
validation and a clear recovery path — by a single administrator.


---


# 1. Solution Overview — Application Control (WDAC)

## What WDAC is
Windows Defender Application Control (now **App Control for Business**) enforces an **allowlist**:
only code that is explicitly trusted is allowed to run; everything else is blocked. It is enforced
deep in Windows (kernel level), making it far harder to bypass than user-mode controls. This
solution manages it through Microsoft Intune.

## Trust models (how code gets allowed)
- **Windows components + Microsoft Store apps** — trusted by the built-in base policy.
- **Reputable apps (Intelligent Security Graph / ISG)** — optionally trust apps Microsoft's cloud reputation considers good.
- **Intune-managed installers** — optionally trust anything installed by Intune (your deployed apps become trusted automatically).
- **Custom rules** — publisher, path, or file-hash rules via custom policy XML for advanced needs.

## Modes
- **Audit only** — nothing is blocked; Windows **logs** what *would* have been blocked (Code Integrity events). This is how you roll out safely.
- **Enforced** — untrusted code is blocked.

> **Method:** deploy in **Audit** first, review Code Integrity events, add the legitimate apps to
> trust, then switch to **Enforce**.

## How it works
1. An Intune **App Control for Business** policy sets the trust model and mode.
2. In **Audit**, the device logs **Code Integrity** events for code that isn't trusted.
3. You review those events, add legitimate apps to trust (managed installer / ISG / supplemental policy).
4. You switch the policy to **Enforce**; untrusted code is now blocked.

## Benefits
- **Stops untrusted code** — including unknown malware, living-off-the-land binaries, and unsanctioned apps.
- **Kernel-enforced** — much harder to bypass than user-mode allowlisting.
- **Safe rollout** — Audit mode reveals impact before enforcement.
- **Low maintenance with managed installers** — apps you deploy via Intune are trusted automatically.

## Limitations (be honest with buyers)
- WDAC is **powerful** — a misconfigured enforced policy can block legitimate apps. Audit-first + a recovery path are essential.
- Highly dynamic environments (developers compiling code, frequent new unsigned tools) need careful trust design.
- Custom XML policies are advanced; this solution favors the **managed-installer + ISG** model for most fleets.
- Recovery from an over-strict enforced policy is via removing/replacing the policy (covered here).

## The standard deployment model
> **Create the App Control policy in Audit → review Code Integrity events → add trust → Enforce →
> expand.** repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**


---


# 2. Requirements Guide — Application Control (WDAC)

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

## 2.1 Licensing
**Description:** Intune (Plan 1). WDAC/App Control is a Windows feature (no separate license).
**Why:** Intune delivers and reports the App Control policy.
**Verify:** M365 admin center → **Billing → Licenses**.
**Implement:** Assign M365 E3/E5 or Business Premium (Intune included).

## 2.2 Supported Windows OS
**Description:** Windows 10 1903+ or Windows 11 (App Control for Business CSP).
**Why:** The Intune App Control policy and managed-installer trust require a supported build.
**Verify:** `winver`; run **`WDAC-Discovery.ps1`**.
**Implement:** Patch/upgrade to a supported build.

## 2.3 Device enrollment
**Description:** Devices enrolled in Intune.
**Why:** The policy applies only to enrolled devices.
**Verify:** Intune → **Devices → All devices**.
**Implement:** Enable automatic enrollment; enroll devices.

## 2.4 Application inventory
**Description:** Awareness of the apps users legitimately run, and how they are installed.
**Why:** Audit mode reveals untrusted apps; you must decide how each becomes trusted (managed installer, ISG, signature).
**Verify:** Review **`WDAC-AuditReport.ps1`** output during the audit phase.
**Implement:** Prefer deploying apps via **Intune (managed installer)** so they're trusted automatically; document any exceptions.

## 2.5 App deployment via Intune (recommended)
**Description:** Business apps deployed through Intune as managed installs.
**Why:** With the managed-installer trust option, Intune-deployed apps are automatically allowed.
**Verify:** Intune → **Apps → Windows**.
**Implement:** Move key app deployments into Intune before enforcing.

## 2.6 Recovery plan
**Description:** A way to remove/replace the policy if enforcement is too strict.
**Why:** WDAC is powerful; you need a safe rollback.
**Verify:** Confirm **`WDAC-Remediation.ps1`** (policy-removal path) and an Intune unassign procedure.
**Implement:** Document removing the assignment (and local policy clear) for recovery.

---
## Checklist
- [ ] Intune licensing assigned
- [ ] Windows 10 1903+/11 — `WDAC-Discovery.ps1`
- [ ] Devices enrolled
- [ ] App inventory + trust approach decided (prefer managed installer)
- [ ] Key apps deployed via Intune
- [ ] Recovery/rollback procedure confirmed
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


# 3. Implementation Guide — Application Control (WDAC)

Follow these steps **in order**, in the **Microsoft Intune admin center** (`https://intune.microsoft.com`).

> **Model:** App Control for Business policy trusting Windows + Store (+ managed installer + ISG),
> deployed **Audit-first**, reviewed, then **Enforced**.

## Step 1 — Create the pilot group
1. Entra → **Groups → New group** → Security → `WDAC-Pilot` → add a few pilot devices. **Create**.

## Step 2 — Create the App Control policy (Audit mode)
1. Intune → **Endpoint security → Application control** (App Control for Business) → **Create Policy**.
   *(If not present in your tenant, use **Devices → Configuration → Create → Settings catalog** and search **"App Control" / "Application Control"**.)*
2. **Platform:** Windows. **Profile:** **App Control for Business**. **Create**.
3. **Name:** `WDAC - Audit (Pilot)`. **Next**.

## Step 3 — Configure trust and mode
On **Configuration settings**:
1. **Application control code integrity policies** = **Enable**.
2. **Trust mode** / built-in policy = **Trust Windows components and Store apps**.
3. **Also trust apps with good reputation (ISG)** = **Enable** (recommended).
4. **Trust apps from managed installers** = **Enable** (so Intune-deployed apps are allowed).
5. **Enforcement** = **Audit only** for now.
Click **Next**.

## Step 4 — Assign and run the audit
1. **Assignments → Add groups →** `WDAC-Pilot`. **Next → Create**.
2. Let pilot devices run normally for **2+ weeks**, exercising all line-of-business apps.

## Step 5 — Review Code Integrity audit events
1. On pilot devices run **`WDAC-AuditReport.ps1`** (reads Code Integrity audit events 3076).
2. Identify legitimate apps that *would* have been blocked.

## Step 6 — Add trust for legitimate apps
1. Preferred: **deploy those apps via Intune** so the **managed installer** trust covers them.
2. For signed apps not from Intune, rely on **ISG** reputation or add a **supplemental/custom policy** (advanced).
3. Re-audit until the audit log is clean of legitimate blocks.

## Step 7 — Switch to Enforce
1. Duplicate the policy as `WDAC - Enforce (Pilot)` (or edit) and set **Enforcement = Enforced**. **Save**.
2. Re-validate with **`WDAC-Validation.ps1`** (confirms an enforced policy is active).
3. Confirm pilot users can run all required apps; untrusted code is blocked.

## Step 8 — Expand to production
1. Add a production group to the **Enforce** policy **Assignments**; roll out in waves.
2. Keep new apps flowing through Intune (managed installer) so they stay trusted.
3. Re-validate each wave with **`WDAC-Validation.ps1`** / **`WDAC-AuditReport.ps1`**.

> **Recovery:** if an enforced policy is too strict, **unassign** it in Intune (and run
> **`WDAC-Remediation.ps1`** to clear/refresh the local policy), then return to Audit, fix trust, re-enforce.

---
### Order of operations
`Pilot group → App Control policy (Audit) → Trust Windows/Store/ISG/managed-installer → Assign → Review audit → Add trust → Enforce → Expand`


---


# 5. Testing Guide — Application Control (WDAC)

Run during the audit phase (Implementation Step 5) and after switching to Enforce.

## Test 1 — Policy applied
**Do:** Intune → **Endpoint security → Application control →** policy → **Device status**.
**Expected:** Pilot devices show **Succeeded**.

## Test 2 — Policy active on device
**Do:** On a pilot device run `WDAC-Validation.ps1` (checks for an active App Control policy and its mode).
**Expected:** An App Control policy is active; mode reflects Audit (pilot) or Enforced (post-switch).

## Test 3 — Audit events generated
**Do:** Run an untrusted test binary (a benign unsigned EXE) on an Audit-mode device, then run `WDAC-AuditReport.ps1`.
**Expected:** A Code Integrity **audit** event (3076) is logged for the binary — proving the policy evaluates.

## Test 4 — Enforce blocks untrusted code
**Do:** With the policy **Enforced**, run the same untrusted test binary.
**Expected:** Execution is **blocked** (Code Integrity event 3077); the binary does not run.

## Test 5 — Trusted apps still run
**Do:** With Enforce on, launch all line-of-business apps (deployed via Intune / Store / signed).
**Expected:** All legitimate apps run normally; no false blocks.

## Test 6 — Managed-installer trust works
**Do:** Deploy a new app via Intune to an enforced device and run it.
**Expected:** The Intune-deployed app runs (trusted via managed installer) without manual rules.

## Test 7 — Recovery path works
**Do:** On a test device, unassign the policy in Intune and run `WDAC-Remediation.ps1`.
**Expected:** The enforced policy is removed/cleared and the device returns to normal — confirming rollback.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Audit pass** | Tests 1–3 pass; audit log clean of legitimate-app blocks after trust added |
| **Enforce pass** | Tests 4–6 pass (no false blocks); Test 7 recovery confirmed |


---


# 6. Troubleshooting Guide — Application Control (WDAC)

Use **`WDAC-Validation.ps1`** / **`WDAC-Discovery.ps1`** for policy state and
**`WDAC-AuditReport.ps1`** for events, **`WDAC-Remediation.ps1`** for recovery.

## A. Legitimate app blocked (enforced)
| Symptom | Cause | Remediation |
|---|---|---|
| A required app won't run after Enforce | It isn't trusted (not Intune-deployed, not ISG-reputable, unsigned) | Identify via `WDAC-AuditReport.ps1`; deploy it via Intune (managed installer), or add a supplemental/custom rule; if urgent, unassign the policy to recover |
| Whole app category blocked | Trust model too narrow | Enable **ISG** and **managed installer** trust; re-audit before re-enforcing |

## B. Recovery from an over-strict policy
1. **Unassign** the App Control policy from the device group in Intune.
2. Run **`WDAC-Remediation.ps1`** to clear/refresh the local policy and force a sync.
3. The device returns to its prior state; return the policy to **Audit**, fix trust, then re-enforce.
> WDAC policies persist until replaced/removed and may require a reboot to fully clear.

## C. Policy not applying
| Symptom | Cause | Remediation |
|---|---|---|
| No policy active on device | Not synced / not enrolled / unsupported OS | `WDAC-Remediation.ps1` (sync); confirm Windows 1903+/11 and group membership |
| Audit shows nothing | Users didn't run untrusted code, or wrong log | Run a benign unsigned test EXE; check the Code Integrity Operational log |

## D. Too many audit events
- Expected initially — every not-yet-trusted app logs. Triage by publisher/path with `WDAC-AuditReport.ps1`; move the common legitimate ones to managed-installer deployment first.

## E. Diagnostics quick reference
```powershell
# active policies (Windows 11):
citool.exe --list-policies
# Device Guard / code integrity status:
Get-CimInstance -Namespace root\Microsoft\Windows\DeviceGuard -ClassName Win32_DeviceGuard | Select CodeIntegrityPolicyEnforcementStatus
# Code Integrity events: 3076 (audit block), 3077 (enforced block), 3099 (policy loaded)
Get-WinEvent -LogName 'Microsoft-Windows-CodeIntegrity/Operational' | Where-Object Id -in 3076,3077,3099
```

## F. When to escalate
If a signed, Intune-deployed app is still blocked under Enforce with managed-installer trust enabled,
capture the 3077 event detail (file path, signing info) and open a Microsoft support case.


---


# 7. Best Practices — Application Control (WDAC)

- **Audit first, always.** WDAC is powerful — never deploy Enforced without a thorough audit phase. This is the #1 rule.
- **Have a recovery path ready.** Know how to unassign the policy and clear it locally before you enforce anything.
- **Prefer the managed-installer model.** Deploy apps via Intune so they're trusted automatically — far lower maintenance than custom XML rules.
- **Enable ISG reputation.** It trusts well-known good apps without per-app rules, reducing audit noise.
- **Pilot on representative devices.** Include devices that run your full app set so the audit reveals real blocks.
- **Triage audit events by publisher/path.** Trust whole trusted publishers rather than individual hashes where possible.
- **Keep new apps flowing through Intune.** That keeps them trusted automatically as your estate changes.
- **Avoid custom XML unless needed.** Reserve custom policies for genuine edge cases; they add maintenance burden.
- **Communicate to users.** Let pilot users report anything that "won't open" during audit so you catch edge cases.
- **Document the trust model.** Record what's trusted (Windows/Store/ISG/managed installer/custom) and the recovery procedure for audits.


---


# 8. Deliverables Summary — Application Control (WDAC)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What WDAC is, trust models, modes, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps — Audit-first, add trust, Enforce, with recovery |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and recovery from over-strict policies |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `WDAC-Discovery.ps1` | Reports OS support and current code-integrity/App Control status |
| `WDAC-Validation.ps1` | Confirms an App Control policy is active and its enforcement mode |
| `WDAC-AuditReport.ps1` | Parses Code Integrity events (3076/3077) to find blocked/would-block code |
| `WDAC-Remediation.ps1` | Recovery: clears/refreshes local policy and forces a sync |
| `WDAC-PolicyReport.ps1` | Tenant-wide App Control policy assignment report (Microsoft Graph) |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the repeatable model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Strong, kernel-enforced protection against untrusted code — deployed safely with audit-first validation and a clear recovery path.
