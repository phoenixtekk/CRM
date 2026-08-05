# 2. Requirements Guide — Application Packaging & Deployment Standards

Verify **every** requirement before you publish the standard to your packaging team. Each entry:
**Description · Why required · How to verify · How to implement if missing.** Category-wide
prerequisites are in `global-requirements-intune-solutions.md`.

Throughout this solution we use a **worked example application** so every rule is concrete:

> **`Acme Invoice Client`**, version **7.3.1**, from publisher **`Acme Software Ltd.`**, shipped as an
> MSI (`AcmeInvoiceClient.msi`), business-owned by the Finance department, requested for the Finance
> and Accounts Payable teams.

Replace the vendor, product, version, and owner with your own. The **names** of the tenant objects
you create (groups, scope tags, categories, roles) are part of the standard — use them **verbatim**
so that the scripts, the templates, and the audit all agree.

---

## 2.1 Intune licensing for every targeted user or device

**Description:** An Intune-bearing licence plan (Intune Plan 1, Microsoft 365 E3/E5, or Business
Premium) assigned to every user or device that will receive a managed application.
**Why required:** App deployment, app assignment, and the Intune Management Extension are Intune
capabilities. Unlicensed users silently fail to receive Required assignments, which looks like a
packaging fault and wastes triage time.
**How to verify:** Microsoft 365 admin center (`https://admin.microsoft.com`) → **Billing** →
**Licenses** → confirm an Intune-bearing SKU with available seats. Then Microsoft Intune admin center
(`https://intune.microsoft.com`) → **Tenant administration** → **Tenant status** → confirm the tenant
is active and note the **Account status**.
**How to implement if missing:** Purchase and assign Microsoft 365 E3/E5, Business Premium, or
standalone Intune Plan 1 to the target users, then re-check **Tenant status**.

## 2.2 A named owner for the packaging standard

**Description:** One accountable person (with a named deputy) who owns this specification: approves
changes to it, arbitrates format decisions, and chairs the exceptions register.
**Why required:** A standard without an owner is a document. Every rule below has edge cases; someone
must be able to say "yes, this exception is approved, here is why, review it in six months." Without
this role the standard decays within two quarters.
**How to verify:** The owner and deputy are named on the front page of your published copy of this
specification, and both appear as **Owners** of the Entra group
`ROLE – Package Approvers` (created in Implementation Step 2).
**How to implement if missing:** Nominate the senior endpoint engineer as **Packaging Standard Owner**
and one peer as deputy. Record both names in your published copy of the standard and add them as
Owners of `ROLE – Package Approvers`.

## 2.3 At least two people who can package and review

**Description:** A minimum of two staff competent to build a package **and** to review someone else's.
**Why required:** The peer review gate (Implementation Step 8) requires that the reviewer is **not**
the packager. With one person, sign-off is self-certification and the gate is theatre. Two is the
minimum; three removes the single point of failure when one is on leave.
**How to verify:** Entra admin center (`https://entra.microsoft.com`) → **Groups** → **All groups** →
open `ROLE – Package Approvers` → **Members** → confirm at least two members.
**How to implement if missing:** Train a second administrator on the per-app packaging mechanics
(that is a separate discipline — see the companion Win32 packaging solution) and add them to
`ROLE – Package Approvers`. Until you have two, record it as an open risk in the exceptions register
and have a manager counter-sign releases.

## 2.4 Microsoft Graph PowerShell SDK on the auditor's workstation

**Description:** The Microsoft Graph PowerShell SDK installed on the workstation that runs the five
audit and remediation scripts in this package.
**Why required:** Every script in this solution reads (and, for the remediation script, writes) app
objects, assignments, and detection rules through Microsoft Graph. There is no portal report that
answers "which apps violate the naming standard".
**How to verify:** Open PowerShell and run:
```powershell
Get-Module -ListAvailable -Name Microsoft.Graph.Authentication
```
A version is returned. Then run `.\APPSTD-Invoke-PackageStandardAudit.ps1 -WhatIfOnlySummary` and
confirm it connects without error.
**How to implement if missing:**
```powershell
Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
```
Use PowerShell 7.x where possible. All five scripts install the SDK automatically if it is absent,
but pre-installing avoids a long first run.

## 2.5 Graph permissions for the audit account

**Description:** The account running the scripts must consent to `DeviceManagementApps.Read.All` (all
five scripts) and additionally `DeviceManagementApps.ReadWrite.All` for the metadata remediation
script, plus `Group.Read.All` for the assignment hygiene report.
**Why required:** Read scopes let the auditor enumerate apps, assignments, and detection rules.
The write scope is needed **only** by `APPSTD-Set-AppMetadataStandard.ps1`, which is `-WhatIf` by
default and changes nothing until you explicitly pass `-Apply`.
**How to verify:** Run any audit script; on first run PowerShell opens a consent prompt listing the
scopes. If consent has already been granted, run:
```powershell
Connect-MgGraph -Scopes 'DeviceManagementApps.Read.All','Group.Read.All' -NoWelcome
(Get-MgContext).Scopes
```
and confirm the scopes are listed.
**How to implement if missing:** Sign in as a user holding the **Intune Administrator** role and
accept the consent prompt. If your tenant blocks user consent, have a Global Administrator grant
admin consent for the Microsoft Graph PowerShell enterprise application for those scopes.

## 2.6 Intune RBAC roles separating packagers from approvers

**Description:** Distinct Intune role assignments so that the people who build packages and the
people who approve releases are visibly different sets, and neither group has more rights than the
job needs.
**Why required:** The sign-off gate has integrity only if it is enforced by permissions as well as by
process. It also limits blast radius: a packager should not be able to assign an app to All Devices.
**How to verify:** Intune admin center → **Tenant administration** → **Roles** → **All roles** →
confirm a custom role named `Application Packager (Standard)` exists, and open **Assignments** to
confirm it is assigned to your packagers and scoped by the scope tag
`SCOPE – Application Packaging`.
**How to implement if missing:** Create the role and scope tag in Implementation Step 2. If your
organisation is too small to separate the duties, document that as an approved exception in the
exceptions register and rely on the peer-review signature instead — but say so explicitly rather than
leaving the gap undeclared.

## 2.7 A document store for retained package evidence

**Description:** A durable, access-controlled location (a SharePoint document library, a Teams files
tab, or a version-controlled repository) that holds one folder per application containing the intake
form, the acceptance checklist, the sign-off record, and the test evidence.
**Why required:** The standard's audit answer — "who approved this, when, against what evidence" —
depends on the evidence still existing in two years. Evidence in a packager's `C:\Temp` is not
evidence.
**How to verify:** The library exists, is named `Application Package Records`, is readable by
`ROLE – Package Approvers` and your audit function, and contains at least one folder using the
convention `<Vendor> <Product>\<Version>\` (for the worked example,
`Acme Software Ltd Acme Invoice Client\7.3.1\`).
**How to implement if missing:** Create a SharePoint document library named
`Application Package Records`. Turn on **version history**. Grant **Contribute** to your packaging
team and **Read** to audit/compliance. Do not allow deletion by contributors.

## 2.8 A defined pilot population that is real

**Description:** A pilot ring of genuine, representative end users — not only the IT team — who
receive every package before broad release. Aim for 3–5% of the fleet, minimum 10 devices, spanning
your main hardware models and at least two business units.
**Why required:** A pilot made of engineers proves only that the package installs for engineers. Real
users find the conflicts: the app that clashes with a line-of-business plug-in, the machine with 4 GB
of free disk, the profile that lacks a mapped drive.
**How to verify:** Entra → **Groups** → `APP – Ring 1 Pilot Devices` exists, has ≥ 10 members, and its
membership spans more than one department and more than one hardware model.
**How to implement if missing:** Recruit pilot users with their managers' agreement — a named group
who understand they receive software first and report problems. Create the group in Implementation
Step 2 and populate it before the first release runs through the process.

## 2.9 A confirmed position on Microsoft Store (new) availability in your cloud

**Description:** A written, verified statement of whether the **Microsoft Store (new)** app type is
available in the Microsoft cloud environment your tenant runs in — Commercial, GCC, GCC High, or DoD
— because the format decision matrix branches on the answer.
**Why required:** The matrix prefers the Microsoft Store (new) app type where it is available, since
it removes packaging effort entirely. **Microsoft Store app availability and feature parity differ
between the Commercial cloud and the US Government clouds**, and Government tenants have
historically had reduced or absent Store integration alongside delayed feature rollout. If your
tenant cannot use the Store type, that branch of the matrix must be struck out and those apps fall
through to Win32 — which materially changes your packaging workload. Getting this wrong means a
decision tree that recommends an option your admins cannot select.
**How to verify:** Sign in to your Intune admin center — `https://intune.microsoft.com` for
Commercial, `https://intune.microsoft.us` for GCC High/DoD (portal URLs differ across US Government
clouds; **verify the exact URL for your cloud** in Microsoft's US-sovereign-cloud documentation) —
then go to **Apps** → **All apps** → **Add** and inspect the **App type** dropdown. Confirm whether
**Microsoft Store app (new)** appears and, if it does, whether a search returns results. Cross-check
against Microsoft's current service-description and Government feature-parity documentation for your
cloud before writing the answer down.
**How to implement if missing / if the Store type is unavailable:** Record the finding in your
published copy of the standard as *"Microsoft Store (new): NOT AVAILABLE in this cloud — verified
<date> by <name>"*, strike the Store branch from your local copy of the format decision matrix, and
default those applications to **Win32**. Do not assume a parity gap is permanent; re-verify at each
annual review of the standard. **Do not assume the Commercial answer applies to a Government tenant,
and do not invent Government specifics — verify for GCC High against Microsoft's documentation.**

## 2.10 An agreed application catalog taxonomy

**Description:** The finite list of **Intune app categories** you will allow, agreed before packaging
starts, so that Company Portal is browsable and reporting groups sensibly.
**Why required:** App categories are free text in practice. Without an agreed list you get
`Finance`, `finance`, `Fin Apps`, and `Accounting` as four separate categories within a year, and
Company Portal becomes unusable.
**How to verify:** Intune admin center → **Apps** → **Categories** (under **Monitor** and setup) → the
list matches your agreed taxonomy exactly and contains no near-duplicates.
**How to implement if missing:** Agree a short list — this specification ships with a default of
six: `Business – Finance`, `Business – Operations`, `Productivity`, `Engineering & Technical`,
`Security & Compliance`, `Utilities & Runtimes` — and create them in Implementation Step 2. Fewer is
better; you can add a category later, but merging two is manual.

## 2.11 A record of which existing apps are in scope for retrofit

**Description:** A baseline inventory of the apps already in your tenant, with their current
compliance state against this standard, produced **before** you announce the standard.
**Why required:** You cannot mandate a standard without knowing the size of the existing gap. The
baseline also becomes the "before" number that proves the standard is working.
**How to verify:** Run `.\APPSTD-Invoke-PackageStandardAudit.ps1 -CsvPath C:\Temp\baseline.csv` and
confirm the CSV lists every app with a per-rule pass/fail. Keep this file — it is your baseline.
**How to implement if missing:** Run the audit script before Implementation Step 10 (enforcement) and
file the CSV in `Application Package Records\_Standard\Baseline\`. Decide, per non-compliant app,
whether it is **remediate**, **rebuild at next version**, or **accepted exception**.

---

## Checklist

- [ ] Intune licensing assigned to all targeted users/devices (2.1)
- [ ] Packaging Standard Owner and deputy named (2.2)
- [ ] At least two people can package **and** review (2.3)
- [ ] Microsoft Graph PowerShell SDK installed on the auditor's workstation (2.4)
- [ ] Graph scopes consented for the audit account (2.5)
- [ ] `Application Packager (Standard)` role + `SCOPE – Application Packaging` scope tag exist (2.6)
- [ ] `Application Package Records` document store created with version history (2.7)
- [ ] `APP – Ring 1 Pilot Devices` populated with ≥ 10 real, representative users (2.8)
- [ ] Microsoft Store (new) availability **verified in writing** for your cloud (2.9)
- [ ] App category taxonomy agreed and created (2.10)
- [ ] Baseline audit CSV produced and filed (2.11) — `APPSTD-Invoke-PackageStandardAudit.ps1`
