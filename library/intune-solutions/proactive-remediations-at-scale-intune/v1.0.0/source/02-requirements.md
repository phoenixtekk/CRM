# 2. Requirements — Proactive Remediations at Scale (Detection & Remediation Script Packs for Microsoft Intune)

Confirm **every** requirement below before you begin. Each entry follows the same pattern:
**Description · Why required · How to verify · How to implement if missing.** Category-wide
prerequisites (tenant, Intune licensing, admin roles, device enrollment, supported OS, network) are
covered once in the **Global Requirements — Intune Solutions** document; the items here are specific
to authoring, deploying, and operating Proactive Remediations script packs.

> **Verify-with-Microsoft flag.** Proactive Remediations licensing, feature availability, run-context
> behavior, scheduling limits, and console navigation **change over time and differ by cloud
> (Commercial vs. GCC / GCC High / DoD)**. Where this document states a licensing SKU, a portal path,
> or a behavior, treat it as a starting point and **verify it against current Microsoft documentation
> for your tenant and cloud** before relying on it. Facts you must not assume are called out inline.

## R1. Proactive Remediations licensing entitlement
**Description:** A license that entitles the tenant to **Endpoint Analytics Proactive Remediations**.
**Why:** Proactive Remediations is a licensed Endpoint Analytics capability; without the entitlement
the **Devices → Remediations** experience is unavailable or blocked.
**Verify:** In Intune, open **Reports → Endpoint analytics → Remediations** (path may differ by
tenant — **verify against current Microsoft documentation**). If you can create a remediation, the
entitlement is present. **Do not assume a specific SKU grants this — confirm the current licensing
requirement with Microsoft's documentation** for your subscription and cloud (Commercial vs.
GCC/GCC High/DoD may differ).
**Implement:** Acquire/assign the licensing Microsoft currently requires for Endpoint Analytics
Proactive Remediations (verify the exact SKU with Microsoft), then re-check the console.

## R2. Endpoint Analytics enabled (the parent solution)
**Description:** Endpoint Analytics is **onboarded/enabled** in the tenant.
**Why:** Proactive Remediations is a component of Endpoint Analytics; the remediation reporting
surface lives inside it. This package is the **remediation engine**, not the onboarding.
**Verify:** Intune → **Reports → Endpoint analytics** shows an active dashboard (scores are
populating), not an "enable" prompt.
**Implement:** Complete Endpoint Analytics onboarding first — see the companion solution
**"Endpoint Analytics Deployment & Optimization in Microsoft Intune"** (referenced here, not
reproduced). Return to this guide once analytics is live.

## R3. Windows devices enrolled and managed
**Description:** The target devices are **Windows** devices enrolled in Intune (MDM-managed or
co-managed with the workload directed to Intune, per Microsoft's current support statement).
**Why:** Remediation script pairs are delivered to enrolled Windows endpoints via the Intune
management extension; unenrolled devices cannot receive them. **Platform support and the exact
co-management requirement should be verified against current Microsoft documentation.**
**Verify:** Intune → **Devices → All devices**; targets appear, are **Windows**, and are compliant.
**Implement:** Enroll the devices (per Global Requirements G4) and confirm they check in.

## R4. Intune Management Extension present
**Description:** The **Intune Management Extension (IME)** agent is installed and healthy on targets.
**Why:** IME is what actually runs PowerShell scripts and remediation script pairs on the device; if
it is absent or unhealthy, detection/remediation never runs.
**Verify:** On a target, confirm the **Microsoft Intune Management Extension** service is present and
running; IME installs automatically when a device receives a PowerShell script or Win32 app
assignment. (**Exact service name/behavior — verify against current Microsoft documentation.**)
**Implement:** Assign any Intune PowerShell script or Win32 app to the device to trigger IME
installation, then re-check.

## R5. PowerShell execution and script-signing posture
**Description:** A decision on whether your remediation scripts are **signed**, and an execution
policy posture that lets IME run them.
**Why:** IME runs remediation scripts in a defined execution context; organizations that enforce
script signing must sign their detect/remediate scripts or the run fails. **The exact signing/
execution behavior is set by Intune and your environment — verify against current Microsoft
documentation.**
**Verify:** Author a trivial detection that `exit 0`, deploy to one pilot device, and confirm it
runs (status reports back). If it fails to run, signing/execution policy is the likely cause.
**Implement:** Establish a code-signing process for your script packs (recommended for governance),
or configure the remediation to run in the context Microsoft documents as not requiring signing —
**verify current behavior before relying on either.**

## R6. Run-context permissions (system vs. user)
**Description:** Clarity on whether each script pair must run as **system** (machine context, 64-bit,
no signed-in user needed) or in the **logged-on user's** context.
**Why:** A remediation that edits the machine registry/services must run as **system**; one that
edits the current user's profile/HKCU must run in the **user** context. Choosing wrong means the
script runs but **silently does nothing** to the intended target — a top cause of "it says success
but nothing changed."
**Verify:** For each pair, identify what it reads/writes (HKLM/service/machine file → system;
HKCU/user profile → user) and match the remediation's **run context** setting to it.
**Implement:** Set the correct **Run this script using the logged-on credentials** choice when you
create the remediation (Implementation §5). Test on a device with a signed-in user for user-context
pairs. **Confirm the current run-context options and their exact behavior against Microsoft's
documentation.**

## R7. A pilot device group
**Description:** A Microsoft Entra security group — **named `PILOT – Remediations – Devices`** —
containing a small set of representative Windows devices.
**Why:** No remediation goes fleet-wide unproven; the pilot ring is where you catch a bad pair before
it can do harm at scale.
**Verify:** Entra → **Groups**; `PILOT – Remediations – Devices` exists with a handful of pilot
devices.
**Implement:** Entra → **Groups → New group → Security**; name it `PILOT – Remediations – Devices`
and add the pilot devices (Implementation §4).

## R8. A production target group
**Description:** A Microsoft Entra security group — **named `Remediations – Windows – Production`** —
representing the broader fleet you will eventually target.
**Why:** After the pilot passes you widen to production in waves; a named production group is the
assignment target for that expansion.
**Verify:** Entra → **Groups**; `Remediations – Windows – Production` exists (it may start empty and
fill in waves).
**Implement:** Entra → **Groups → New group → Security**; name it `Remediations – Windows –
Production`.

## R9. An admin workstation with the Microsoft Graph PowerShell SDK
**Description:** A workstation with the **Microsoft.Graph** PowerShell SDK for the discovery,
validation, and reporting scripts in this package.
**Why:** The included read-only scripts query Intune via Microsoft Graph to inventory remediations,
their assignments, and run status.
**Verify:** `Get-Module Microsoft.Graph -ListAvailable` returns the SDK; `Connect-MgGraph` succeeds.
**Implement:** `Install-Module Microsoft.Graph -Scope CurrentUser`. The scripts request read scopes
such as `DeviceManagementConfiguration.Read.All` and consent on first connect. (**Graph endpoints/
scopes for remediations may change — verify against current Microsoft documentation.**)

## R10. A script-pack library location (governance)
**Description:** A version-controlled location (a repository or a controlled share) — referred to as
**`Remediations Pack Library`** — where the source of every detect/remediate pair is stored,
versioned, and reviewed before deployment.
**Why:** The console alone is not a source of truth; governed packs (naming, versioning, approval)
are what keep the practice safe and auditable over time.
**Verify:** The `Remediations Pack Library` location exists and holds the current pair sources with
version history.
**Implement:** Create the repository/share (Implementation §11), adopt the naming and versioning
convention, and require a second-admin review before a remediation is approved to act.
