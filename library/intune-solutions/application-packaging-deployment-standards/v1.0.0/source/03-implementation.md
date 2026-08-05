# 3. Implementation Guide — Application Packaging & Deployment Standards

Follow these steps **in order**. Steps 1–2 create the tenant objects the standard depends on. Steps
3–7 are the specification itself — the rules your packagers follow for every application. Steps 8–10
are the process that makes the rules stick: review, release, and audit.

Unless stated otherwise, every navigation path starts in the **Microsoft Intune admin center** at
`https://intune.microsoft.com`. Government-cloud tenants use a different portal host — see
Requirement 2.9 and the note at the end of Step 3.

> **Model:** Intake against the spec form → decide the format from the matrix → build to the
> packaging specification → pass the acceptance checklist → peer review and sign-off → release to
> Ring 1 pilot → validate → expand to Ring 2 broad → audit quarterly. **Assess → Configure → Pilot →
> Validate → Expand.**

---

## Named objects (reuse these names verbatim everywhere)

Every object below is created in Step 1 or Step 2 and is referenced by name in the later steps, in
the Testing Guide, in the Troubleshooting Guide, and by the five PowerShell scripts. Do not
improvise names — the scripts match on these patterns.

| Object | Exact name to create | Where |
|---|---|---|
| Packaging lab ring group | `APP – Ring 0 Packaging Lab` | Entra security group (Assigned, devices) |
| Pilot ring group | `APP – Ring 1 Pilot Devices` | Entra security group (Assigned, devices) |
| Broad ring group | `APP – Ring 2 Broad Devices` | Entra security group (Dynamic, devices) |
| Global exclusion group | `APP – Exclusions – Do Not Deploy` | Entra security group (Assigned, devices) |
| Approvers group | `ROLE – Package Approvers` | Entra security group (Assigned, users) |
| Packagers group | `ROLE – Application Packagers` | Entra security group (Assigned, users) |
| Intune scope tag | `SCOPE – Application Packaging` | Intune scope tag |
| Intune custom role | `Application Packager (Standard)` | Intune custom RBAC role |
| App categories (6) | `Business – Finance`, `Business – Operations`, `Productivity`, `Engineering & Technical`, `Security & Compliance`, `Utilities & Runtimes` | Intune app categories |
| Evidence library | `Application Package Records` | SharePoint document library |
| Worked-example app | `Acme Software Ltd. Acme Invoice Client – Win32 – v7.3.1` | Intune Win32 app |

---

## Step 1 — Create the evidence store

The standard's outputs must land somewhere permanent before you create anything in Intune.

1. Open SharePoint (`https://<yourtenant>.sharepoint.com`) and navigate to your IT team site.
2. Click **+ New** → **Document library**. Name it exactly `Application Package Records`. Click
   **Create**.
3. Open the library → **Settings** (gear icon) → **Library settings** → **Versioning settings** →
   set **Create a version each time you edit a file in this document library** to **Yes**. Click
   **OK**.
4. In the library, click **+ New** → **Folder** and create `_Standard`. Inside `_Standard`, create
   three folders: `Baseline`, `Exceptions`, and `Audit Reports`.
5. Click **Settings** → **Library settings** → **Permissions for this document library** → **Stop
   Inheriting Permissions**. Grant **Contribute** to `ROLE – Application Packagers`, **Contribute**
   to `ROLE – Package Approvers`, and **Read** to your audit/compliance group. Remove broad
   Everyone/Members access.
6. Upload your published copy of this specification to `_Standard\` so the rules and the evidence
   live together.

Per-application evidence goes in a folder named `<Vendor> <Product>\<Version>\` — for the worked
example, `Acme Software Ltd Acme Invoice Client\7.3.1\`.

## Step 2 — Create the tenant objects the standard depends on

### 2a. The four ring and exclusion groups

1. Go to the Microsoft Entra admin center (`https://entra.microsoft.com`) → **Identity** → **Groups**
   → **All groups** → **+ New group**.
2. **Group type:** **Security**. **Group name:** `APP – Ring 0 Packaging Lab`. **Group description:**
   "Packaging lab devices. First install target for every new package. Never real users."
   **Membership type:** **Assigned**. Add your packaging VMs/test devices as members. Click
   **Create**.
3. Repeat for `APP – Ring 1 Pilot Devices` — description "Representative pilot devices. Every package
   installs here and passes the Testing Guide before Ring 2." **Membership type: Assigned.** Add the
   real pilot devices identified in Requirement 2.8.
4. Repeat for `APP – Ring 2 Broad Devices` — description "The remainder of the managed Windows fleet."
   Set **Membership type:** **Dynamic Device**, then click **Add dynamic query** and enter this rule
   in the **Rule syntax** box:
   ```
   (device.deviceOSType -eq "Windows") and (device.deviceTrustType -eq "AzureAD")
   ```
   Click **Save**, then **Create**. Adjust the rule to your own trust type if you are hybrid-joined.
5. Repeat for `APP – Exclusions – Do Not Deploy` — description "Devices excluded from all standard app
   assignments. Kiosks, lab rigs, and executive-approved exclusions only." **Membership type:
   Assigned.** Leave it empty for now; it is populated as exclusions are approved.

### 2b. The two role groups

1. Still in **Entra** → **Groups** → **All groups** → **+ New group**. **Security**, name
   `ROLE – Application Packagers`, **Assigned**, members = the staff who build packages. **Create**.
2. Create `ROLE – Package Approvers`, **Security**, **Assigned**, members = the staff permitted to
   sign off a release (Requirement 2.3). Open the group → **Owners** → **+ Add owners** → add the
   Packaging Standard Owner and deputy (Requirement 2.2). **Create**.

### 2c. The scope tag

1. Intune admin center → **Tenant administration** → **Roles** → **Scope (Tags)** → **+ Create**.
2. **Name:** `SCOPE – Application Packaging`. **Description:** "Objects owned by the application
   packaging function." Click **Next**.
3. On **Assignments**, click **+ Select groups to include** → select `ROLE – Application Packagers`
   and `ROLE – Package Approvers`. Click **Next** → **Create**.

### 2d. The custom packaging role

1. Intune admin center → **Tenant administration** → **Roles** → **All roles** → **+ Create** →
   **Windows 10 and later** is not what you want here; choose **+ Create** → **Custom role**.
2. **Name:** `Application Packager (Standard)`. **Description:** "Build and edit applications; cannot
   assign to Ring 2 Broad." Click **Next**.
3. On **Permissions**, expand **Mobile apps** and set **Create**, **Read**, **Update**, and **Delete**
   to **Yes**. Set **Assign** to **Yes**. Expand **Organization** and set **Read** to **Yes**. Leave
   everything else **No**. Click **Next**.
4. On **Scope tags**, select `SCOPE – Application Packaging`. Click **Next** → **Create**.
5. Open the new role → **Assignments** → **+ Assign**. **Assignment name:** `Packagers – Standard`.
   **Members (groups):** `ROLE – Application Packagers`. **Scope (Groups):** select
   `APP – Ring 0 Packaging Lab` and `APP – Ring 1 Pilot Devices` **only** — this is what prevents a
   packager from self-releasing to the whole fleet. **Scope (Tags):**
   `SCOPE – Application Packaging`. Click **Create**.

### 2e. The app categories

1. Intune admin center → **Apps** → **Categories** → **+ Create**.
2. Enter `Business – Finance` and click **Create**.
3. Repeat for exactly these five more: `Business – Operations`, `Productivity`,
   `Engineering & Technical`, `Security & Compliance`, `Utilities & Runtimes`.
4. Review the existing list and delete or merge any near-duplicates left over from before the
   standard (Requirement 2.10). Deleting a category does not delete the apps; you must re-categorise
   them.

---

## Step 3 — The format decision matrix (THE decision tree)

**Rule:** every application entering the catalog is assigned exactly one format at intake, by working
the decision tree top to bottom and stopping at the first match. The decision and the reason are
recorded on the intake form (Step 6). A packager may not change format after sign-off without a new
intake.

### The decision tree — work it in order

**Question 1 — Is the app published in the Microsoft Store and is automatic vendor updating
acceptable to the business owner?**
→ **YES:** use **Microsoft Store app (new)**. Stop.
→ **NO or Store unavailable in your cloud (Requirement 2.9):** continue.

**Question 2 — Does the vendor ship a supported MSIX/`.msixbundle`, and does the app need no
system-context install, no custom install logic, and no legacy driver/service?**
→ **YES:** use **MSIX**. Stop.
→ **NO:** continue.

**Question 3 — Does the app require a system-context install, custom pre/post logic, a specific
install sequence, dependencies, supersedence of a prior version, or a vendor EXE installer?**
→ **YES:** use **Win32**. Stop.

**Question 4 — Anything remaining.**
→ Use **Win32**. Win32 is the default; there is no fall-through case that lands on LOB/MSI.

**Banned:** the **Line-of-business app (`.msi`)** type is **not permitted for new packages**. It
offers no control over the install command, no requirement rules, no dependencies, and no
supersedence. Existing LOB apps are tracked for migration to Win32 at their next version.

### The matrix in full

| Criterion | Microsoft Store (new) | MSIX | Win32 (`.intunewin`) | LOB / MSI (legacy) |
|---|---|---|---|---|
| Packaging effort | None | Low (if vendor ships MSIX) | Moderate — wrap + author rules | Low |
| Who installs it | Store/OS | OS | Intune Management Extension | MDM client |
| Custom install command | No | No | **Yes** | No |
| Custom uninstall command | No | No | **Yes** | No |
| Detection rules you author | No (managed) | No (managed) | **Yes — required** | No |
| Requirement rules | Limited | Limited | **Yes** | No |
| Dependencies | No | No | **Yes** | No |
| Supersedence | No | No | **Yes** | No |
| System-context install | Varies | Limited | **Yes** | Yes |
| Automatic vendor updates | **Yes** | Vendor-dependent | No — you republish | No |
| Clean uninstall guaranteed | Yes | **Yes** (containerised) | Depends on your command | Usually |
| Permitted for new packages | **Yes (preferred where available)** | **Yes** | **Yes (default)** | **No** |

### How to record the decision

On the intake form (Step 6), field **Format decision** must read as a sentence naming the question
that decided it, e.g.:

> *Format: **Win32**. Decision tree Q3 — vendor ships an EXE bootstrapper, requires system-context
> install and a VC++ runtime dependency. Not in Microsoft Store; no vendor MSIX available. Decided by
> J. Okafor, 2026-07-20.*

### Government-cloud note

The decision tree's **Question 1** assumes the **Microsoft Store app (new)** type is selectable in
your tenant. Microsoft Store integration and broader app-feature parity **differ between the
Commercial cloud and the US Government clouds (GCC, GCC High, DoD)**, and Government portal hosts
differ as well — Government tenants use hosts such as `intune.microsoft.us` / `portal.azure.us`
rather than `intune.microsoft.com` (**verify the exact host for your cloud** against Microsoft's
US-sovereign-cloud documentation). If Requirement 2.9 established that the Store type is unavailable
in your cloud, **strike Question 1 from your local copy of this tree**; those applications fall
through to Question 2 and then to **Win32**, which increases packaging workload and should be
reflected in your team's capacity planning. Do not assume the Commercial answer applies — **verify
for GCC High** before publishing your local matrix.

---

## Step 4 — The packaging specification (naming, versioning, metadata, documentation)

This is the specification proper. Every package must satisfy all four sub-sections.

### 4a. Naming convention — applications

**Format:** `<Publisher> <Product> – <Format> – v<Version>`

- `<Publisher>` — the legal vendor name as the vendor writes it, e.g. `Acme Software Ltd.`
- `<Product>` — the product name without marketing suffixes, e.g. `Acme Invoice Client`
- `<Format>` — exactly one of `Win32`, `MSIX`, `Store`
- `v<Version>` — the vendor's own version string, prefixed `v`, e.g. `v7.3.1`

**Worked example:** `Acme Software Ltd. Acme Invoice Client – Win32 – v7.3.1`

Rules:
- Use an **en dash surrounded by single spaces** (` – `) as the separator, consistently. The audit
  script matches on this.
- **No** dates, ticket numbers, initials, or the words `Test`, `New`, `Copy`, `Final`, `DO NOT USE`,
  `TEMP`, or `v2 (real)` in a production app name. If a package is a trial, it lives in Ring 0 only
  and is deleted, not renamed.
- Never reuse an app object for a new version. A new version is a **new app object** with a new
  version in the name, superseding the old one.

### 4b. Naming convention — assignment groups and scope tags

**Format:** `APP – <Purpose> – <Stage>` for rings and app-specific groups; `ROLE – <Function>` for
people; `SCOPE – <Function>` for scope tags.

- Ring groups: `APP – Ring 0 Packaging Lab`, `APP – Ring 1 Pilot Devices`, `APP – Ring 2 Broad Devices`
- Exclusions: `APP – Exclusions – Do Not Deploy`
- App-specific targeting group (when an app is not fleet-wide):
  `APP – <Product> – Licensed Users` — worked example: `APP – Acme Invoice Client – Licensed Users`
- Never target an app at a group whose name does not begin `APP – `. If you find yourself assigning
  to `Finance Team (old)`, create a purpose-named `APP – ` group instead.

### 4c. Version stamping

Every package carries its version in **three** places, and all three must agree:

1. The **app name** — `… – v7.3.1` (§4a).
2. The **detection rule** — the rule must assert the version, not merely the presence of the app
   (Step 5). For the worked example: MSI product code plus a product-version check of `7.3.1`, or a
   file-version rule of `>= 7.3.1`.
3. The **evidence folder** — `Application Package Records\Acme Software Ltd Acme Invoice Client\7.3.1\`.

A version mismatch between name and detection rule is a **hard fail** of the acceptance checklist. It
is the single most common cause of an app that reports Installed while the fleet is on an old build.

### 4d. Publisher, category, description, and owner metadata

Every app object must have all four populated before release. These are the fields the audit script
(`APPSTD-Get-PackageMetadataCompleteness.ps1`) scores.

| Field | Rule | Worked example |
|---|---|---|
| **Publisher** | The legal vendor name, identical to the `<Publisher>` token in the app name. Never blank, never "IT", never your own company. | `Acme Software Ltd.` |
| **Category** | Exactly one of the six agreed categories (Step 2e). Never blank. | `Business – Finance` |
| **Description** | Three mandatory lines, in this order (see below). | *(see below)* |
| **Owner** | The business owner's name and department — Intune's **Owner** field on the app. Never a person who has left. | `M. Reyes, Finance` |

The **Description** field must contain exactly these three lines, in this order:

```
Business purpose: Submits and approves supplier invoices for the Finance and AP teams.
Business owner: M. Reyes, Finance.
Package record: Application Package Records > Acme Software Ltd Acme Invoice Client > 7.3.1
```

Also set **Developer** to the packager's name and **Information URL** to the vendor's product page.
Set **Show this as a featured app in the Company Portal** only for apps the business has asked to
promote — it is not a default.

---

## Step 5 — Detection-rule standards

A detection rule is the tenant's only source of truth about whether an app is installed. A weak rule
does not "mostly work"; it silently corrupts every install report you will ever run. These rules
apply to **Win32** packages (Store and MSIX apps are detected by the platform and have no rule to
author).

### 5a. What makes a detection rule acceptable

A rule is acceptable if it satisfies **all five** tests. The reviewer checks each one at sign-off.

1. **Deterministic** — it returns the same answer on the same machine state every time. No time
   dependency, no network dependency, no dependency on a user being logged in.
2. **Specific to this app** — it cannot be satisfied by a different application, a different vendor's
   file, or a shared runtime.
3. **Version-asserting** — it distinguishes v7.3.1 from v7.3.0. Presence-only rules are permitted
   **only** for apps with no meaningful version (see the exception below) and must be justified on the
   intake form.
4. **Written by the installer, not by you** — the artefact checked must be something the vendor's
   installer creates. A registry key your own wrapper script writes is a marker, not detection, and
   fails if the wrapper succeeds while the install does not.
5. **Verified on a clean machine and on an upgrade** — proven to return *not installed* on a clean
   Ring 0 VM before install, *installed* after install, and *not installed* when the previous version
   is present.

### 5b. The permitted rule types, in order of preference

| Preference | Rule type | Use when | Worked example |
|---|---|---|---|
| **1 (best)** | **MSI product code** + product version | The installer is an MSI | Product code `{A1B2C3D4-…}`, version check **equals** `7.3.1` |
| **2** | **File** — path + filename, method **Version**, operator **greater than or equal to** | EXE installers with a versioned binary | `C:\Program Files\Acme\Invoice Client\`, `AcmeInvoice.exe`, version `>= 7.3.1` |
| **3** | **Registry** — the vendor's own uninstall key, method **String comparison** on `DisplayVersion` | No reliable versioned file | `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{A1B2C3D4-…}`, value `DisplayVersion`, **equals** `7.3.1` |
| **4 (last resort)** | **Custom detection script** | Nothing above can express the truth | Must be ≤ 40 lines, exit `0` with STDOUT on detect, exit `0` with no output on not-detected |

**Exception — presence-only detection.** Permitted only when the app genuinely has no version to
assert (a certificate, a font pack, a configuration payload). Must be recorded on the intake form as
*"Presence-only detection, justified: <reason>"* and countersigned at review.

### 5c. Banned detection patterns — automatic rejection

A package matching any of these is rejected at review. `APPSTD-Test-DetectionRuleQuality.ps1` flags
them.

| # | Banned pattern | Why it is banned |
|---|---|---|
| B1 | **File-exists with no version check** on a versioned app | Reports v7.3.0 as v7.3.1; the fleet never upgrades and the report says everything is fine |
| B2 | **Detecting a folder** rather than a file | Uninstallers routinely leave the folder behind → permanent false "installed" |
| B3 | **Detecting the installer source** (e.g. the `.msi` in a cache path) | Proves you copied a file, not that the app installed |
| B4 | **A registry key your own wrapper writes** | Decouples detection from reality; the wrapper can succeed when the install fails |
| B5 | **A shared runtime or shared DLL** (e.g. `vcruntime140.dll`) | Satisfied by any of a dozen other apps |
| B6 | **Detection on a per-user path (`HKCU`, `%AppData%`) for a system-context install** | Evaluated in SYSTEM context, so it checks the wrong hive/profile and never matches |
| B7 | **More than one rule type combined without a documented reason** | Ambiguous failure; nobody can tell which clause failed. One authoritative rule per app |
| B8 | **A detection script that writes, installs, repairs, or restarts anything** | Detection must observe, never act. Runs on every evaluation cycle |
| B9 | **A detection script with no explicit exit path** or that relies on `Write-Host` | The IME reads STDOUT and the exit code; `Write-Host` does not reach STDOUT |
| B10 | **`Get-CimInstance Win32_Product`** in a detection script | Triggers an MSI self-repair consistency check on every call; slow and destructive at scale |

### 5d. Detection rule review evidence

The reviewer records, on the acceptance checklist, the rule type, the exact value, and the three
observed results (clean = not detected, post-install = detected, prior-version = not detected).

---

## Step 6 — Install / uninstall command, return-code, and reboot standards

### 6a. Install and uninstall command standard

Applies to Win32 packages. Every rule is checkable by reading the command line.

1. **Fully silent, no user interaction.** MSI: `/qn`. EXE: the vendor's documented silent switch —
   found in the vendor's deployment guide, never guessed from a forum post.
2. **Explicitly suppress the installer's own reboot.** MSI: `/norestart`. EXE: the vendor's
   equivalent. Reboots are decided by the reboot standard (§6c), not by the vendor's installer.
3. **Quote every path containing a space**, and use paths relative to the package root. Never
   hard-code a path under `C:\Users\` or a mapped drive letter.
4. **Log to a fixed location.** MSI: append `/l*v "%ProgramData%\PackageLogs\<Product>-install.log"`.
   Create `C:\ProgramData\PackageLogs\` as part of your build standard. Without a log, triage is
   guesswork.
5. **Provide a real uninstall command.** MSI: `msiexec /x {PRODUCT-GUID} /qn /norestart`. EXE: the
   vendor's uninstall string, taken from the uninstall registry key after a test install. An
   uninstall command of `cmd /c exit 0` is a **hard fail** — it makes Uninstall assignments and
   supersedence silently lie.
6. **Test both commands on a clean Ring 0 VM** and record the observed exit code on the checklist.

**Worked example — `Acme Invoice Client` 7.3.1:**

```
Install:    msiexec /i "AcmeInvoiceClient.msi" /qn /norestart /l*v "%ProgramData%\PackageLogs\AcmeInvoiceClient-install.log"
Uninstall:  msiexec /x {A1B2C3D4-1111-2222-3333-444455556666} /qn /norestart /l*v "%ProgramData%\PackageLogs\AcmeInvoiceClient-uninstall.log"
```

### 6b. Return-code standard

Every Win32 app must declare its return codes explicitly on the **Program** tab. The defaults are the
starting point, not the finished job.

| Code | Mapping | Rule |
|---|---|---|
| `0` | **Success** | Always present |
| `1707` | **Success** | Always present (MSI success variant) |
| `3010` | **Soft reboot** | Always present. Never map to Success — that hides a pending reboot |
| `1641` | **Hard reboot** | Always present |
| `1618` | **Retry** | Always present (another install in progress) |
| Vendor-specific | As documented | Added **only** with a citation to the vendor's documentation, recorded on the intake form |

**Banned:** mapping a non-zero code to **Success** to "make the report green". If an installer returns
`1603` and you map it to success, you have not fixed a deployment — you have deleted your only signal.
This is a hard fail at review.

### 6c. Reboot behaviour standard

Set **Device restart behavior** on the **Program** tab according to this table. The default is
**No specific action**; anything else needs a reason on the intake form.

| Setting | When to use | Notes |
|---|---|---|
| **No specific action** | **Default for all apps.** The `/norestart` switch suppresses the vendor reboot; your update/reboot policy handles restarts. | Use unless there is a documented reason not to |
| **App install may force a device restart** | Only when the vendor's installer genuinely cannot be prevented from restarting | Requires a note on the intake form and pilot confirmation |
| **Determine behavior based on return codes** | When the vendor documents `3010`/`1641` and you want Intune to honour them | The preferred choice for drivers, agents, and shell extensions |
| **Intune will force a mandatory device restart** | **Banned for user-facing apps.** | Permitted only for unattended Ring 0/kiosk devices with the owner's written agreement |

Never schedule a Required assignment of a reboot-forcing app to land during business hours.

### 6d. Install behaviour

**System** context is the default for line-of-business applications. **User** context is used only
when the vendor supports no system install, and it must be noted on the intake form — because
per-user installs report per logged-on user and make fleet reporting materially harder.

---

## Step 7 — The Package Intake & Specification Template

This is the reusable form the requester and packager complete **per application, per version**,
before any packaging work begins. Copy it into
`Application Package Records\<Vendor> <Product>\<Version>\01-Intake.md`.

```
=========================================================================
PACKAGE INTAKE & SPECIFICATION
=========================================================================
SECTION A — REQUEST (completed by the requester)
  A1  Application name (vendor's own)      : Acme Invoice Client
  A2  Publisher (legal vendor name)        : Acme Software Ltd.
  A3  Version requested                    : 7.3.1
  A4  Business owner (name, department)    : M. Reyes, Finance
  A5  Business purpose (one sentence)      : Submits and approves supplier invoices.
  A6  Who needs it (group / headcount)     : Finance + Accounts Payable, ~85 users
  A7  Licensed? Licence count / evidence   : Yes — 100 seats, PO #44190
  A8  Required by (date) and why           : 2026-09-01, month-end close
  A9  Replaces which existing app?         : Acme Invoice Client v7.2.4
  A10 Data classification handled          : Confidential (supplier bank data)

SECTION B — FORMAT DECISION (completed by the packager)
  B1  In the Microsoft Store? (Q1)         : No
  B2  Vendor MSIX available? (Q2)          : No
  B3  Needs system context / custom logic? : Yes — system context + VC++ runtime
  B4  FORMAT DECIDED                       : Win32
  B5  Decision-tree question that decided  : Q3
  B6  Decided by / date                    : J. Okafor / 2026-07-20

SECTION C — PACKAGE SPECIFICATION (completed by the packager)
  C1  Intune app name (per §4a)            : Acme Software Ltd. Acme Invoice Client – Win32 – v7.3.1
  C2  Category (one of the six)            : Business – Finance
  C3  Source installer + SHA-256           : AcmeInvoiceClient.msi / 9f2c...e10a
  C4  Install command                      : msiexec /i "AcmeInvoiceClient.msi" /qn /norestart /l*v ...
  C5  Uninstall command                    : msiexec /x {A1B2C3D4-...} /qn /norestart /l*v ...
  C6  Install behaviour (System/User)      : System
  C7  Detection rule type + exact value    : MSI product code {A1B2C3D4-...}, version equals 7.3.1
  C8  Detection preference level (1-4)     : 1
  C9  Presence-only? Justification         : No
  C10 Requirement rules                    : 64-bit; minimum Windows 11 22H2
  C11 Dependencies                         : VC++ Redistributable x64 – Win32 – Dependency
  C12 Supersedes                           : Acme Software Ltd. Acme Invoice Client – Win32 – v7.2.4
  C13 Uninstall previous version?          : Yes
  C14 Return codes (non-default + source)  : None beyond standard set
  C15 Reboot behaviour + reason            : No specific action (default)
  C16 Known conflicts / caveats            : Conflicts with Acme Invoice Client 6.x — must be removed

SECTION D — TARGETING
  D1  Ring 0 group                         : APP – Ring 0 Packaging Lab
  D2  Ring 1 group                         : APP – Ring 1 Pilot Devices
  D3  Ring 2 group                         : APP – Acme Invoice Client – Licensed Users
  D4  Exclusions applied                   : APP – Exclusions – Do Not Deploy
  D5  Assignment intent (Required/Avail.)  : Required
=========================================================================
```

A package with an incomplete intake form is not reviewed. That is the point of the form.

---

## Step 8 — The package quality gates (acceptance checklist)

Every package must pass **all** of these before it may be assigned beyond `APP – Ring 0 Packaging Lab`.
Any single **FAIL** blocks release. Copy this into
`Application Package Records\<Vendor> <Product>\<Version>\02-Acceptance-Checklist.md` and complete it.

### Gate 1 — Identity and metadata

| # | Check | Pass criteria |
|---|---|---|
| 1.1 | App name matches `<Publisher> <Product> – <Format> – v<Version>` | Exact match, en-dash separators |
| 1.2 | No banned words in the name | No `Test`, `New`, `Copy`, `TEMP`, `DO NOT USE`, dates, initials |
| 1.3 | Publisher field populated with the legal vendor name | Matches the name token |
| 1.4 | Category set to one of the six agreed values | Exact match |
| 1.5 | Description contains the three mandatory lines | Business purpose / Business owner / Package record |
| 1.6 | Owner and Developer fields populated | Named individuals, currently employed |
| 1.7 | Version appears identically in name, detection rule, and evidence folder | All three agree |

### Gate 2 — Build correctness

| # | Check | Pass criteria |
|---|---|---|
| 2.1 | Format matches the intake decision (B4) | Identical |
| 2.2 | Source installer hash recorded and matches the file packaged | SHA-256 equal |
| 2.3 | Install command fully silent, `/norestart` (or equivalent), logging enabled | Verified on Ring 0 |
| 2.4 | Uninstall command is real and removes the app | Verified on Ring 0; not a stub |
| 2.5 | Install behaviour is System, or User with a documented reason | Matches intake C6 |
| 2.6 | Return codes declared; no non-zero code mapped to Success | Standard set present |
| 2.7 | Reboot behaviour per §6c; forced restart only with owner's agreement | Matches intake C15 |

### Gate 3 — Detection quality

| # | Check | Pass criteria |
|---|---|---|
| 3.1 | Rule satisfies all five acceptability tests (§5a) | Reviewer initials each |
| 3.2 | Rule matches **no** banned pattern B1–B10 (§5c) | `APPSTD-Test-DetectionRuleQuality.ps1` returns clean |
| 3.3 | Exactly one authoritative rule type, unless documented | One rule |
| 3.4 | Version asserted, or presence-only justified and countersigned | Evidence recorded |
| 3.5 | Three-state proof recorded: clean / post-install / prior-version | All three observed on Ring 0 |

### Gate 4 — Targeting and safety

| # | Check | Pass criteria |
|---|---|---|
| 4.1 | Assigned to Ring 0 only at review time | No Ring 1/2 assignment yet |
| 4.2 | `APP – Exclusions – Do Not Deploy` is applied as an **Excluded** group | Present on the assignment |
| 4.3 | No assignment to **All Devices** or **All Users** | Zero |
| 4.4 | Supersedence configured if this replaces a prior version | Matches intake C12/C13 |
| 4.5 | Dependencies declared with **Automatically install = Yes** | Matches intake C11 |
| 4.6 | Requirement rules set (architecture, minimum OS) | Matches intake C10 |

### Gate 5 — Evidence

| # | Check | Pass criteria |
|---|---|---|
| 5.1 | Intake form complete, all sections | No blanks |
| 5.2 | This checklist complete with reviewer name and date | Signed |
| 5.3 | Ring 0 install/uninstall test evidence filed | Screenshots or log excerpts |
| 5.4 | Source installer and any transforms archived in the evidence folder | Present |

---

## Step 9 — Peer review, sign-off, and the release process

### 9a. The rule

**The reviewer must not be the packager.** Sign-off is performed by a member of
`ROLE – Package Approvers` who did not build the package. If your organisation cannot separate these
roles today, that is an entry in the exceptions register with a manager's counter-signature
(Requirement 2.3) — not a silent omission.

### 9b. The review meeting (15 minutes, not a committee)

1. The packager presents the completed intake form and the acceptance checklist.
2. The reviewer opens the app in Intune → **Apps** → **All apps** → the app → and independently
   confirms Gates 1, 2, and 4 against what is actually configured, not against what the form claims.
3. The reviewer runs `.\APPSTD-Test-DetectionRuleQuality.ps1 -AppName "<the app name>"` and confirms a
   clean result for Gate 3.
4. Any FAIL ends the review. The package returns to the packager; there is no conditional pass.

### 9c. The sign-off record

On a clean review, the reviewer completes and files
`Application Package Records\<Vendor> <Product>\<Version>\03-Signoff.md`:

```
PACKAGE SIGN-OFF
  Application      : Acme Software Ltd. Acme Invoice Client – Win32 – v7.3.1
  Packaged by      : J. Okafor           Date packaged : 2026-07-20
  Reviewed by      : P. Lindqvist        Date reviewed : 2026-07-21
  Gates 1-5        : PASS (all)
  Detection result : APPSTD-Test-DetectionRuleQuality.ps1 — 0 findings
  Exceptions       : None
  Released to      : APP – Ring 1 Pilot Devices
  Ring 2 approval  : Pending pilot validation (Testing Guide)
```

### 9d. Release to Ring 1

1. Intune admin center → **Apps** → **All apps** → open
   `Acme Software Ltd. Acme Invoice Client – Win32 – v7.3.1` → **Properties** → **Assignments** →
   **Edit**.
2. Under **Required**, click **+ Add group** and select `APP – Ring 1 Pilot Devices`.
3. Under **Excluded**, click **+ Add group** and select `APP – Exclusions – Do Not Deploy`.
4. Click **Review + save** → **Save**.
5. Run the **Testing Guide**. Do not proceed until every gate in it passes.

### 9e. Release to Ring 2

1. Only after the Testing Guide's pilot gate passes, return to **Assignments** → **Edit**.
2. Under **Required**, click **+ Add group** and select the Ring 2 target from intake field D3 —
   for the worked example, `APP – Acme Invoice Client – Licensed Users` (not the whole fleet: this app
   is licensed for 100 seats).
3. Confirm `APP – Exclusions – Do Not Deploy` is still under **Excluded**. Click **Review + save** →
   **Save**.
4. Update the sign-off record's **Ring 2 approval** line with the approver's name and date.

### 9f. Ring and assignment hygiene rules

These are standing rules, checked by `APPSTD-Get-AssignmentHygieneReport.ps1` at every audit.

1. **No app is assigned to All Devices or All Users.** Ever. These are not rings; they are a way to
   turn a mistake into an outage.
2. **Every Required assignment carries the `APP – Exclusions – Do Not Deploy` exclusion.** One
   exclusion group, applied everywhere, so an emergency exclusion is a single membership change.
3. **No app is both Required and Uninstall for overlapping groups.** The result is a device that
   installs and uninstalls the app on alternating cycles.
4. **No app is assigned to more than one group with the same intent.** Two Required groups covering
   the same devices makes reporting ambiguous; use one purpose-named group.
5. **Every app has at least one assignment or is deleted.** An unassigned app is either an oversight
   or debris. Ring 0-only apps older than 30 days are debris.
6. **Ring order is never skipped.** Ring 0 → Ring 1 → Ring 2, with the Testing Guide between 1 and 2.
7. **Superseded apps keep their assignment until supersedence has fully drained**, then are
   unassigned and deleted at the next quarterly audit.
8. **App-specific groups are named `APP – <Product> – <Purpose>`** and are owned by a named person.

---

## Step 10 — Enforcement and audit over time

A standard that is not measured is a suggestion. Run this cycle from the day the standard is
published.

### 10a. Baseline (once, before announcing the standard)

```powershell
.\APPSTD-Invoke-PackageStandardAudit.ps1 -CsvPath "C:\Temp\baseline-2026-07.csv"
```
File the CSV in `Application Package Records\_Standard\Baseline\`. This is the number you improve
against. Announce the standard **with** the baseline — "we have 62 apps, 41 are non-compliant, here is
the plan" lands far better than a policy document with no context.

### 10b. Per-release enforcement (every package)

The acceptance checklist (Step 8) and peer sign-off (Step 9) are the gate. No package is assigned
beyond Ring 0 without a filed sign-off record. The reviewer's signature is the enforcement.

### 10c. Monthly — new-app conformance

On the first working day of each month, run:

```powershell
.\APPSTD-Invoke-PackageStandardAudit.ps1 -CreatedSinceDays 31 -CsvPath "C:\Temp\newapps.csv"
.\APPSTD-Get-PackageMetadataCompleteness.ps1 -MinimumScore 100
```

Any app created in the last month that fails is chased with its packager that week, while the context
is fresh. This is the cheapest possible enforcement and it is where the standard actually holds.

### 10d. Quarterly — full catalog audit

Run all four read-only scripts and file the outputs in
`Application Package Records\_Standard\Audit Reports\<YYYY-Qn>\`:

```powershell
.\APPSTD-Invoke-PackageStandardAudit.ps1        -CsvPath ".\Q3-standard.csv"
.\APPSTD-Test-DetectionRuleQuality.ps1          -CsvPath ".\Q3-detection.csv"
.\APPSTD-Get-AssignmentHygieneReport.ps1        -CsvPath ".\Q3-assignments.csv"
.\APPSTD-Get-PackageMetadataCompleteness.ps1    -CsvPath ".\Q3-metadata.csv"
```

Review the four reports with the Packaging Standard Owner. For each finding, decide: **fix now**,
**fix at next version**, or **accepted exception**. Then remediate the mechanical findings:

```powershell
# Preview only — this is the default; nothing is changed
.\APPSTD-Set-AppMetadataStandard.ps1 -CsvPath ".\Q3-metadata.csv"

# Apply, after the preview has been reviewed and approved
.\APPSTD-Set-AppMetadataStandard.ps1 -CsvPath ".\Q3-metadata.csv" -Apply
```

### 10e. The exceptions register

Not every finding will be fixed, and pretending otherwise is how standards lose credibility. Keep
`Application Package Records\_Standard\Exceptions\Exceptions-Register.md` with one row per accepted
exception:

| App | Rule waived | Reason | Approved by | Approved | Review by |
|---|---|---|---|---|---|
| `Legacy Payroll Client – Win32 – v3.0` | §5a.3 version-asserting detection | Vendor writes no version anywhere; presence-only is the only option | Packaging Standard Owner | 2026-07-21 | 2027-01-21 |

Every exception has an expiry date. An exception with no review date is a permanent hole.

### 10f. Annual review of the standard itself

Once a year the Packaging Standard Owner reviews this specification against reality: re-verify the
Microsoft Store availability position (Requirement 2.9), re-check the format decision tree against
current Microsoft capabilities, confirm the category taxonomy is still right, and close or renew every
exception. Record the review date on the front page of your published copy.

---

### Order of operations

`Evidence store → Tenant objects (groups, scope tag, role, categories) → Format decision matrix →
Packaging specification (naming, versioning, metadata) → Detection standards → Command / return-code /
reboot standards → Intake template → Acceptance checklist → Peer review + sign-off → Ring 1 →
validate → Ring 2 → monthly + quarterly audit → annual standard review`
