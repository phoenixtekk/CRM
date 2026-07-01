# Dynamic Device Targeting in Intune — Dynamic Groups & Filters

> **Version 1.0.0** · Category: Intune · Solution code: DYNTGT

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Dynamic Device Targeting in Intune (Dynamic Groups & Filters)

Phoenixtekk Workplace Marketplace · Intune Solutions

As a fleet grows, assigning policies and apps to hand-built static groups stops scaling: new
devices miss policy, membership drifts, and admins burn hours maintaining lists. The modern answer
is dynamic targeting — dynamic security groups whose membership rules auto-include the right
devices, and assignment filters that scope a single assignment to exactly the devices that match
(OS, ownership, model, enrollment profile).

This is a complete, deploy-it-today package for building a repeatable dynamic device targeting model
in Intune, written for an administrator with no prior experience in membership-rule or filter-rule
syntax.

## What you get
- A plain-language Solution Overview of dynamic security groups vs. assignment filters, when to use
  each, precedence and evaluation, and a scalable targeting taxonomy.
- A Requirements Guide with verify / implement-if-missing for every prerequisite, including
  Entra dynamic-group licensing and a device attribute/naming convention.
- An Implementation Guide of precise, click-by-click steps in the required order — define the
  taxonomy, build dynamic groups, create filters, apply filters to assignments, validate, expand.
- Five PowerShell scripts for dynamic-group/filter discovery, membership and effective-targeting
  validation, targeting-coverage and drift reporting, safe remediation of mis-scoped assignments,
  and a dynamic-group/filter builder.
- Testing and Troubleshooting guides for a confident rollout.

## What this delivers
A scalable targeting model — a named taxonomy of dynamic security groups (membership rules that
auto-include devices by attribute) and assignment filters (include/exclude by OS, ownership, model,
or enrollment profile at assignment time) — so policies and apps reach exactly the right devices
automatically and stay correct as the fleet changes, validated on a pilot before broad use.

## The Phoenixtekk deployment model
Assess -> Configure -> Pilot -> Validate -> Expand.

## Outcome
Policies and apps that reach exactly the right devices automatically — dynamic groups and assignment
filters replacing hand-maintained static lists, staying correct as the fleet changes — deployable by
a single administrator and validated before broad rollout.


---


# 1. Solution Overview — Dynamic Device Targeting in Intune

## Why dynamic targeting
Static security groups with hand-picked members do not scale. Every new device must be added by
hand, membership drifts as devices are retired or repurposed, and no one can easily prove which
devices a policy actually reaches. The result is missed policy on new devices, wasted admin hours,
and audit gaps. Dynamic targeting fixes this at the source: devices are targeted by rule, not by
name, so the right devices are included automatically and stay correct as the fleet changes.

## The two mechanisms

### Dynamic security groups (membership rules)
A dynamic security group in Microsoft Entra ID has a membership rule — a query over device
attributes — instead of a static member list. Entra continuously evaluates the rule and adds or
removes devices automatically. You assign policies and apps to the group; membership is maintained
for you. Rules are written in the membership-rule syntax and reference device properties such as
`deviceOSType`, `deviceOSVersion`, `deviceManufacturer`, `deviceModel`, `deviceCategory`,
`enrollmentProfileName`, and `deviceOwnership`.

Worked membership-rule examples:
- All Windows devices: `(device.deviceOSType -eq "Windows")`
- Corporate-owned Windows only: `(device.deviceOSType -eq "Windows") and (device.deviceOwnership -eq "Company")`
- Devices from a specific autopilot/enrollment profile: `(device.enrollmentProfileName -eq "Corp – Windows – Autopilot")`
- A device model family: `(device.deviceModel -startsWith "Surface")`
- Devices tagged to a category: `(device.deviceCategory -eq "Kiosk")`

### Assignment filters (filter rules, applied at assignment time)
An assignment filter is a reusable rule you attach to an individual policy or app assignment, set to
either include or exclude the matching devices. The group answers who is broadly in scope; the
filter narrows that single assignment to exactly the devices that match, without creating another
group. Filters are defined once under Intune and reused across many assignments. Filter rules use
the filter-rule syntax over managed-device properties such as `operatingSystem`, `osVersion`,
`deviceOwnership`, `model`, `manufacturer`, `enrollmentProfileName`, and `deviceCategory`.

Worked filter-rule examples:
- Only Windows 11 devices: `(device.osVersion -startsWith "10.0.2")`
- Personal (BYOD) devices, to exclude: `(device.deviceOwnership -eq "Personal")`
- A specific model, to include: `(device.model -eq "Surface Pro 9")`
- A specific enrollment profile: `(device.enrollmentProfileName -eq "Corp – Windows – Autopilot")`

## When to use each
- Use a dynamic security group when a population is broad, stable, and reused by many assignments
  (for example, all corporate Windows devices) — it becomes the durable audience.
- Use an assignment filter when you need to narrow or carve out a specific assignment (for example,
  send this one app only to a device model, or exclude BYOD from this one policy) without minting a
  new group for every variation.
- Rule of thumb: group for the broad audience, filter for the per-assignment exception. Fewer groups
  plus reusable filters is easier to maintain than a group for every combination.

## Precedence and evaluation
- Entra evaluates a group's membership rule and materializes the members; the group is the audience.
- At assignment time, Intune evaluates the attached filter against each in-scope device: an include
  filter keeps only matching devices; an exclude filter drops matching devices.
- Across assignments, Intune's assignment rules still apply: an exclude assignment beats an include
  assignment. A filter narrows within an assignment; a group exclusion removes an audience entirely.
- Effective targeting is therefore group membership, then filter include/exclude, then any
  include/exclude assignment precedence. Always validate the effective result, not the intent.

## The scalable targeting taxonomy
Name every dynamic group, filter, and taxonomy artifact with the pattern
`<Purpose> – <Scope> – <Stage>` and reuse the names verbatim wherever they appear. Examples used
throughout this solution:
- Dynamic group `Corp Devices – Windows – All`
- Dynamic group `Corp Devices – Windows – Pilot`
- Assignment filter `OS Version – Windows 11 – Include`
- Assignment filter `Ownership – Personal – Exclude`
- Assignment filter `Model – Surface – Include`

## Benefits
- Scale — new matching devices are included automatically; no hand-maintained lists.
- Accuracy — membership tracks the fleet, so policy reaches exactly the intended devices.
- Fewer objects — reusable filters replace a proliferation of near-duplicate groups.
- Auditability — a named taxonomy makes coverage and intent obvious for reviews.
- Speed — assign once, reuse the same groups and filters everywhere.

## Limitations (be honest with buyers)
- Dynamic device groups require Entra ID P1 licensing.
- Membership-rule evaluation is not instant; new devices take time to appear in a dynamic group.
- Attribute quality matters — rules are only as good as `deviceModel`, `deviceCategory`, ownership,
  and `enrollmentProfileName` being populated correctly.
- Overlapping filters and exclusions can produce non-obvious effective targeting; always validate.

## The standard Phoenixtekk deployment model
> Define the taxonomy -> build dynamic groups with membership rules -> create assignment filters ->
> apply filters to policy/app assignments -> validate effective targeting on a pilot -> expand.
> Phoenixtekk pattern: Assess -> Configure -> Pilot -> Validate -> Expand.


---


# 2. Requirements Guide — Dynamic Device Targeting in Intune

Verify every requirement before configuring. Each entry: Description · Why · Verify ·
Implement-if-missing. Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

## 2.1 Entra ID P1 licensing (dynamic groups)
Description: Microsoft Entra ID P1 (included in M365 E3/E5 and Business Premium).
Why: Dynamic membership rules on security groups require Entra ID P1; without it groups can only be
static.
Verify: Entra admin center -> `Overview` shows the licence, or `Billing -> Licenses` lists Entra ID
P1 / an E3/E5 / Business Premium plan.
Implement: Assign an Entra ID P1-bearing plan to the tenant/administrator.

## 2.2 Devices enrolled in Intune
Description: Targeted devices are enrolled and appear as managed devices.
Why: Assignment filters evaluate managed-device properties; membership rules read Entra device
attributes populated at enrollment.
Verify: Intune -> `Devices -> All devices`; run `DYNTGT-Discovery.ps1`.
Implement: Enable automatic enrollment and enroll the devices.

## 2.3 A device attribute / naming convention
Description: A consistent set of device attributes to target on — ownership, category, model, and a
device-naming or enrollment-profile convention.
Why: Membership and filter rules are only as accurate as the attributes they read; inconsistent data
produces mis-scoped targeting.
Verify: Intune -> `Devices -> All devices`; confirm ownership, category, and model are populated;
run `DYNTGT-Discovery.ps1` (reports attribute coverage).
Implement: Set device categories and ownership; standardize device naming and enrollment profiles so
attributes are populated at enrollment.

## 2.4 Enrollment profile names
Description: Named enrollment profiles (for example Autopilot / ADE / enrollment configuration
profiles) whose `enrollmentProfileName` can be targeted.
Why: `enrollmentProfileName` is one of the most reliable attributes for dynamic targeting of
corporate devices.
Verify: Intune -> `Devices -> Enrollment`; confirm the profiles exist and are named; run
`DYNTGT-Discovery.ps1`.
Implement: Create and name the enrollment profiles before building rules that reference them.

## 2.5 Assignment-filter management access
Description: The operator can create and manage assignment filters.
Why: Filters are created under Intune tenant administration and reused across assignments.
Verify: Intune -> `Tenant administration -> Filters` loads and allows `Create`.
Implement: Assign the Intune Administrator role (see global requirements G3).

## 2.6 A pilot group
Description: A small pilot audience to validate effective targeting before broad use.
Why: Every Phoenixtekk solution is piloted before fleet rollout; targeting must be validated on a
few devices first.
Verify: Entra -> `Groups`; the pilot group exists.
Implement: Create dynamic group `Corp Devices – Windows – Pilot` (see Implementation Step 2).

---
## Checklist
- [ ] Entra ID P1 licensing for dynamic groups
- [ ] Devices enrolled in Intune — `DYNTGT-Discovery.ps1`
- [ ] Device attributes / naming convention populated (ownership, category, model)
- [ ] Enrollment profiles created and named
- [ ] Assignment-filter management access (Intune Administrator)
- [ ] Pilot dynamic group created


---


# Global Requirements — Intune Solutions (category-level)

These requirements apply to **every** Phoenixtekk solution in the **Intune Solutions**
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
**Why:** Every Phoenixtekk solution is piloted before fleet rollout.
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
**The Phoenixtekk deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


# 3. Implementation Guide — Dynamic Device Targeting in Intune

Follow these steps in order. Group work is done in the Entra admin center
(`https://entra.microsoft.com`); filter and assignment work is done in the Microsoft Intune admin
center (`https://intune.microsoft.com`).

> Model: define a named targeting taxonomy, build dynamic security groups for the broad audiences,
> create reusable assignment filters for per-assignment narrowing, apply them, validate effective
> targeting on a pilot, then expand.

## Step 1 — Define the targeting taxonomy
1. Decide the broad audiences that many assignments will reuse (for example all corporate Windows
   devices) — these become dynamic groups.
2. Decide the per-assignment narrowings (for example OS version, model, ownership) — these become
   reusable filters.
3. Name every artifact with the pattern `<Purpose> – <Scope> – <Stage>` and record the names; reuse
   them verbatim everywhere. This solution uses: dynamic groups `Corp Devices – Windows – All` and
   `Corp Devices – Windows – Pilot`; filters `OS Version – Windows 11 – Include`,
   `Ownership – Personal – Exclude`, and `Model – Surface – Include`.

## Step 2 — Create the dynamic security groups
1. Entra -> `Groups -> New group`.
2. Group type `Security`; Group name `Corp Devices – Windows – Pilot`.
3. Membership type: select `Dynamic Device`.
4. Under `Dynamic device` click `Edit dynamic query`, switch to the rule syntax editor, and enter the
   membership rule. For the pilot, target a small set — for example devices from the pilot
   enrollment profile: `(device.enrollmentProfileName -eq "Corp – Windows – Pilot")`. `Save`.
5. `Create`.
6. Repeat for `Corp Devices – Windows – All` with the broad rule
   `(device.deviceOSType -eq "Windows") and (device.deviceOwnership -eq "Company")`. `Create`.
7. Wait for Entra to evaluate the rules, then confirm membership populated (see Step 6 / Testing).

## Step 3 — Create the assignment filters
1. Intune -> `Tenant administration -> Filters -> Create`.
2. Filter name `OS Version – Windows 11 – Include`; Platform `Windows 10 and later`. `Next`.
3. Build the rule in the rule editor (or the syntax box): `(device.osVersion -startsWith "10.0.2")`.
   `Next -> Create`.
4. Repeat to create `Ownership – Personal – Exclude` with rule
   `(device.deviceOwnership -eq "Personal")` and `Model – Surface – Include` with rule
   `(device.model -startsWith "Surface")`. Filters are direction-neutral here; include vs. exclude is
   chosen when the filter is attached to an assignment (Step 4).

## Step 4 — Apply filters to policy / app assignments
1. Open the policy or app to target (for example `Devices -> Configuration`, open a profile, or
   `Apps -> All apps`, open an app).
2. Go to the `Assignments` blade.
3. Under `Included groups`, add `Corp Devices – Windows – All`.
4. On that assignment row, click `Edit filter`, select the filter (for example
   `OS Version – Windows 11 – Include`), and set the mode to `Include` (only matching devices) or
   `Exclude` (all but matching devices). Use `Ownership – Personal – Exclude` in `Exclude` mode to
   carve BYOD out of a corporate assignment.
5. `Save` (or `Review + save`).

## Step 5 — Apply on the pilot
1. Assign the pilot policy/app to `Corp Devices – Windows – Pilot` with the intended filter.
2. On a pilot device, sync policy (`Settings -> Accounts -> Access work or school -> Info -> Sync`).
3. Confirm the assignment reached the device (Intune -> device -> the policy shows applied), or run
   `DYNTGT-Validation.ps1`.

## Step 6 — Validate effective targeting (pilot gate)
1. Run `DYNTGT-Validation.ps1` -> confirms a device's group membership and the filter include/exclude
   result for the assignment.
2. Run `DYNTGT-Report.ps1` -> targeting-coverage summary and any drift (devices in scope but missing
   the assignment, or matched by no group).
3. Confirm the effective targeting matches intent for the pilot before expanding. Complete the
   Testing Guide.

## Step 7 — Expand to production
1. Switch the assignment audience from `Corp Devices – Windows – Pilot` to
   `Corp Devices – Windows – All`, keeping the same filters.
2. Re-run `DYNTGT-Report.ps1` to confirm coverage and no drift across the fleet.
3. Reuse the same named groups and filters for the next policy/app — assign once, repeat everywhere.

---
### Order of operations
`Taxonomy -> Dynamic groups -> Filters -> Apply to assignments -> Apply on pilot -> Validate effective targeting -> Expand`


---


# 5. Testing Guide — Dynamic Device Targeting in Intune

Run after the pilot assignment applies (Implementation Step 6) and after any taxonomy, group, or
filter change.

## Test 1 — Dynamic group membership evaluated
Do: Entra -> `Groups` -> open `Corp Devices – Windows – Pilot` -> `Members`; or run
`DYNTGT-Discovery.ps1`.
Expected: The expected pilot devices are present; the membership rule shows the intended query.

## Test 2 — Membership rule accuracy
Do: Confirm a device that should match is a member and a device that should not is absent (change an
attribute on a test device and re-check after evaluation).
Expected: Membership tracks the rule — matching devices in, non-matching devices out.

## Test 3 — Filter defined and valid
Do: Intune -> `Tenant administration -> Filters`; open `OS Version – Windows 11 – Include`.
Expected: The filter exists, targets the correct platform, and its rule syntax validates.

## Test 4 — Effective targeting on the assignment
Do: Open the policy/app `Assignments`, confirm the group and filter (include/exclude) are set; run
`DYNTGT-Validation.ps1` for a pilot device.
Expected: The device's group membership and filter result produce the intended effective targeting;
the policy/app shows applied on matching devices only.

## Test 5 — Exclusion carve-out works
Do: Apply a corporate assignment with `Ownership – Personal – Exclude` in Exclude mode; check a BYOD
device.
Expected: The BYOD device is excluded from that assignment; corporate devices still receive it.

## Test 6 — Coverage and drift
Do: Run `DYNTGT-Report.ps1`.
Expected: A per-audience coverage summary and a drift list (in-scope devices missing the assignment,
or devices matched by no targeting group).

## Test 7 — Reuse across a second assignment
Do: Attach the same group + filter to a second policy/app; confirm it targets identically.
Expected: Assign-once behavior — the same effective audience with no new group created.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1-5 pass; effective targeting on the pilot matches intent |
| Broad pass | Tests 4, 6, 7 pass for the broad audience before wider reuse |


---


# 6. Troubleshooting Guide — Dynamic Device Targeting in Intune

Use `DYNTGT-Discovery.ps1` for the group/filter inventory, `DYNTGT-Validation.ps1` for a device's
membership and effective targeting, `DYNTGT-Report.ps1` for fleet coverage and drift, and
`DYNTGT-Remediation.ps1` (default `-WhatIf`) for safe fixes to mis-scoped assignments.

## A. Device not in the expected dynamic group
| Symptom | Cause | Remediation |
|---|---|---|
| New device missing from a dynamic group | Membership rule not yet evaluated, or attribute not populated | Wait for evaluation; confirm the attribute (ownership, category, `enrollmentProfileName`) is set; run `DYNTGT-Discovery.ps1` |
| Device should match but does not | Rule syntax or attribute value mismatch | Re-check the rule against the device's actual attribute value; correct the rule or the attribute |
| Device stays after it should leave | Attribute still set, or evaluation lag | Update the attribute; allow re-evaluation |

## B. Policy/app reaching the wrong devices
| Symptom | Cause | Remediation |
|---|---|---|
| Devices outside intent receive the assignment | Group too broad and no filter applied | Attach an include filter (for example `OS Version – Windows 11 – Include`) to the assignment |
| BYOD receiving a corporate assignment | No ownership exclusion | Attach `Ownership – Personal – Exclude` in Exclude mode |
| Include filter drops everyone | Filter rule matches nothing on this platform | Validate the filter rule and platform; run `DYNTGT-Validation.ps1` |

## C. Effective targeting not what was intended
- Remember precedence: group membership, then filter include/exclude on the assignment, then any
  exclude-assignment beating an include-assignment. Validate the effective result with
  `DYNTGT-Validation.ps1` rather than assuming from intent.
- Overlapping filters or an exclude group can silently remove devices; check for a competing exclude
  assignment on the same policy/app.

## D. Filter cannot be applied to an assignment
- Confirm the filter's platform matches the assignment's platform; a mismatched-platform filter will
  not be selectable. Recreate the filter for the correct platform if needed.

## E. Coverage gaps / drift
- Devices matched by no targeting group appear in `DYNTGT-Report.ps1` drift output; add or broaden a
  dynamic group rule to cover them, or correct their attributes so an existing rule matches.

## F. Diagnostics quick reference
```powershell
Connect-MgGraph -Scopes 'Group.Read.All','DeviceManagementConfiguration.Read.All','DeviceManagementManagedDevices.Read.All'
# Dynamic groups with their membership rules
Invoke-MgGraphRequest -Method GET -Uri "/v1.0/groups?`$filter=groupTypes/any(c:c eq 'DynamicMembership')&`$select=displayName,membershipRule"
# Assignment filters
Invoke-MgGraphRequest -Method GET -Uri "/beta/deviceManagement/assignmentFilters"
```

## G. When to escalate
If the membership rule and device attributes are correct, the filter validates on the right platform,
no competing exclude assignment exists, and effective targeting is still wrong after re-evaluation,
capture `DYNTGT-Report.ps1` and `DYNTGT-Validation.ps1` output and open a Microsoft support case.


---


# 7. Best Practices — Dynamic Device Targeting in Intune

- Group for the broad audience, filter for the exception. Use a dynamic group for stable populations
  reused by many assignments; use a reusable filter to narrow or carve out a single assignment — the
  single most important practice for keeping object counts low.
- Name everything with `<Purpose> – <Scope> – <Stage>` and reuse the names verbatim. A consistent
  taxonomy makes coverage, intent, and audits obvious.
- Prefer stable attributes. Target on `enrollmentProfileName`, `deviceOwnership`, and
  `deviceCategory` over free-form device names; they are more reliable and less prone to drift.
- Keep attribute data clean. Membership and filter rules are only as accurate as ownership,
  category, model, and enrollment-profile values — populate them at enrollment.
- Validate effective targeting, not intent. Overlapping filters and exclusions produce non-obvious
  results; confirm the real audience on a pilot with `DYNTGT-Validation.ps1` before expanding.
- Pilot before broad. Target a small pilot group first; expand only after the effective targeting
  passes the gate.
- Reuse filters instead of minting groups. One filter attached to many assignments beats a new group
  for every OS/model/ownership combination.
- Mind evaluation lag. Dynamic membership is not instant; allow time after enrollment or an attribute
  change before expecting a device to appear.
- Watch for drift. Run `DYNTGT-Report.ps1` on a cadence to catch in-scope devices missing an
  assignment or devices matched by no group.
- Document the taxonomy. Record every group name, filter name, and rule for audits and repeatability.


---


# 8. Deliverables Summary — Dynamic Device Targeting in Intune

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | Dynamic groups vs. filters, when to use each, precedence, targeting taxonomy |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps (taxonomy, groups, filters, assignments, validate) |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `DYNTGT-Discovery.ps1` | Inventories dynamic groups (membership rules) and assignment filters (Microsoft Graph) |
| `DYNTGT-Validation.ps1` | Validates a device's group membership and effective filter targeting (Graph) |
| `DYNTGT-Report.ps1` | Targeting-coverage summary and drift across the fleet (Graph) |
| `DYNTGT-Remediation.ps1` | Safe remediation of mis-scoped assignments; default `-WhatIf` (Graph) |
| `DYNTGT-Set-DynamicGroupFilter.ps1` | Creates dynamic security groups and assignment filters from the taxonomy (Graph) |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process following the Phoenixtekk model: Assess -> Configure -> Pilot -> Validate -> Expand.

## Outcome
Policies and apps that reach exactly the right devices automatically — a named taxonomy of dynamic
groups and assignment filters that replaces hand-maintained static lists and stays correct as the
fleet changes.
