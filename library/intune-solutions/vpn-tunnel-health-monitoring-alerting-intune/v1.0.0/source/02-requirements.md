# 2. Requirements — VPN Tunnel Health Monitoring & Alerting in Microsoft Intune (Scheduled Connectivity Health Checks, Telemetry & Alerts)

Confirm **every** requirement below before you begin. Each entry follows the same pattern:
**Description · Why required · How to verify · How to implement if missing.** Category-wide
prerequisites (tenant, Intune licensing, admin roles, device enrollment, supported OS, network) are
covered once in the **Global Requirements — Intune Solutions** document; the items here are specific
to deploying and operating an endpoint-side VPN tunnel health-monitoring practice.

> **Verify-with-Microsoft flag.** Proactive Remediations licensing and behavior, the data path from
> Proactive Remediations output into **Log Analytics**, Intune Data Collection/Reports, **Azure
> Monitor** alert wiring, and console navigation **change over time and differ by cloud (Commercial vs.
> GCC / GCC High / DoD)**. Where this document states a licensing SKU, a portal path, a data path, or a
> behavior, treat it as a starting point and **verify it against current Microsoft documentation for
> your tenant and cloud** before relying on it. Per-vendor VPN client detection specifics must be
> verified against the **vendor's** documentation. Facts you must not assume are called out inline.

## R1. Proactive Remediations (detection) entitlement — the scheduling engine
**Description:** A license/entitlement that lets the tenant create and assign **Endpoint Analytics
Proactive Remediations** (device health scripts), which this solution uses to run the read-only health
check on a schedule.
**Why:** The health check is delivered and scheduled as a Proactive Remediations **detection** script;
without the entitlement the **Remediations** experience is unavailable.
**Verify:** In Intune, open **Reports → Endpoint analytics → Remediations** (path may differ by tenant
— **verify against current Microsoft documentation**). If you can create a script package, the
entitlement is present.
**Implement:** Acquire/assign the licensing Microsoft currently requires for Endpoint Analytics
Proactive Remediations (**verify the exact SKU with Microsoft** — Commercial vs. GCC/GCC High/DoD may
differ). The mechanics of Proactive Remediations are covered by the **"Proactive Remediations at Scale
— Detection & Remediation Script Packs for Microsoft Intune"** product (referenced, not reproduced).

## R2. A VPN profile already deployed to the target devices (not built here)
**Description:** The devices you will monitor **already have a VPN profile** — Microsoft Tunnel,
Windows Always On VPN (device and/or user tunnel), or a third-party client VPN (e.g. Cisco Secure
Client) — assigned and functional.
**Why:** This product **monitors** an existing tunnel; it does not deploy one. With no VPN profile
present, every device correctly reports "adapter/profile missing" and the monitor has nothing to
watch.
**Verify:** On a target device, confirm the expected VPN profile/connection exists and can connect;
in Intune, confirm the VPN configuration profile is assigned to the device.
**Implement:** Deploy the VPN first using its owning product — **"Microsoft Tunnel Gateway —
Deployment, VPN Configuration & Ongoing Operations"**, the **Windows Always On VPN** product(s), or
**"Cisco Secure Client (AnyConnect) VPN Deployment via Microsoft Intune"** (referenced, not
reproduced). Return here once devices have a working VPN profile.

## R3. Log Analytics workspace (for telemetry — optional but recommended) — **verify data path**
**Description:** A Microsoft Azure **Log Analytics workspace** — **named `LA – Endpoint – VPNHealth`**
— to receive the health telemetry for KQL rollups and dashboards.
**Why:** Per-device results are visible in Intune's Remediations reporting without any extra plumbing;
the **cross-VPN fleet rollup by type and gateway** and the **threshold alerts** need the results in a
queryable store (Log Analytics), where the included KQL runs.
**Verify:** In the Azure portal, **Log Analytics workspaces** → `LA – Endpoint – VPNHealth` exists.
Then confirm the **data path** actually lands your health data there — **whether Proactive Remediations
output is natively queryable in Log Analytics, and by which table/connector, must be verified against
current Microsoft documentation.** If a native path is unavailable in your tenant/cloud, the health
check can ship a structured line that a Log Analytics data-collection path ingests (verify the
supported ingestion method for your environment).
**Implement:** Azure portal → **Create a resource → Log Analytics workspace**; name it
`LA – Endpoint – VPNHealth`. Wire the health-result data path per Microsoft's current guidance for your
cloud (**verify** — do not assume a specific table name). Without this workspace you still get
per-device Intune reporting; you lose the KQL fleet dashboard and alerts.

## R4. Azure Monitor (for alerting — optional but recommended) — **verify alert wiring**
**Description:** **Azure Monitor** enabled on the `LA – Endpoint – VPNHealth` workspace so a KQL result
can raise an alert.
**Why:** Alerting turns a degraded/expiring tunnel into a notification (cert nearing expiry, a cohort
failing to establish, a gateway unreachable). Azure Monitor **scheduled query (log) alert rules**
evaluate the telemetry on a cadence and fire when a threshold is crossed.
**Verify:** Azure portal → **Monitor → Alerts → Alert rules**; you can create a **log search alert**
scoped to `LA – Endpoint – VPNHealth`.
**Implement:** Create the alert rule in Implementation §Step 8 (**named `ALERT – VPN Tunnel Health –
Degraded`**). The exact alert-rule type, evaluation cadence, threshold options, and action-group wiring
**change over time and must be verified against current Microsoft documentation** for your cloud.

## R5. Windows devices enrolled and managed (for the detection delivery)
**Description:** The target devices are **Windows** devices enrolled in Intune (MDM-managed or
co-managed with the workload directed to Intune, per Microsoft's current support statement).
**Why:** The Proactive Remediations detection engine delivers the health-check script to enrolled
Windows endpoints via the Intune management extension. **Platform support for Proactive Remediations
must be verified against current Microsoft documentation.**
**Verify:** Intune → **Devices → All devices**; targets appear, are **Windows**, and are compliant.
**Implement:** Enroll the devices (per Global Requirements G4) and confirm they check in.

## R6. Intune Management Extension present on targets
**Description:** The **Intune Management Extension (IME)** agent is installed and healthy on the target
devices.
**Why:** IME is what actually runs the PowerShell detection health check on the device; if it is absent
or unhealthy, the check never runs and no health status returns.
**Verify:** On a target, confirm the **Microsoft Intune Management Extension** service is present and
running (IME installs automatically when a device receives a PowerShell script or Win32 app
assignment). **Exact service name/behavior — verify against current Microsoft documentation.**
**Implement:** Assign any Intune PowerShell script or Win32 app to trigger IME installation, then
re-check.

## R7. Device-side probe context and reachability
**Description:** The health check runs in the correct **run context** (typically **system**, machine
context, 64-bit) and the device can actually attempt the tunnel/route/DNS probes it performs.
**Why:** The probes read machine-level VPN state and attempt reachability to an internal test target
through the tunnel; run-context and the probe targets must be chosen so a *healthy* device passes and
an *unhealthy* one fails — not the reverse. A wrong run context can make the script read nothing and
falsely report a problem (or miss one).
**Verify:** Run the health check locally on one healthy pilot device in the intended context and
confirm it returns **Healthy**; run it on a device with the tunnel down and confirm it returns the
correct red signal. (See Testing.)
**Implement:** Package the detection to run as **system** unless a user-context VPN (e.g. an Always On
**user** tunnel) requires the **logged-on user's** context; set **Run this script using the logged-on
credentials** accordingly (Implementation §Step 4). **Confirm the current run-context options and their
exact behavior against Microsoft's documentation.**

## R8. A pilot device group
**Description:** A Microsoft Entra security group — **named `PILOT – VPN Health – Devices`** —
containing a small set of representative devices that already have a VPN profile.
**Why:** No monitor goes fleet-wide unproven; the pilot ring is where you confirm the health check
reports correctly (healthy passes, seeded failures go red) before you widen.
**Verify:** Entra → **Groups**; `PILOT – VPN Health – Devices` exists with a handful of pilot devices.
**Implement:** Entra → **Groups → New group → Security**; name it `PILOT – VPN Health – Devices` and add
the pilot devices (Implementation §Step 3).

## R9. A production target group
**Description:** A Microsoft Entra security group — **named `VPN Health – Windows – Production`** —
representing the broader fleet you will eventually monitor.
**Why:** After the pilot passes you widen to production in waves; a named production group is the
assignment target for that expansion.
**Verify:** Entra → **Groups**; `VPN Health – Windows – Production` exists (it may start empty and fill
in waves).
**Implement:** Entra → **Groups → New group → Security**; name it `VPN Health – Windows – Production`.

## R10. An admin workstation with the Microsoft Graph PowerShell SDK
**Description:** A workstation with the **Microsoft.Graph** PowerShell SDK for the included discovery,
validation, deploy, and reporting scripts.
**Why:** The discovery/validation/report scripts query Intune via Microsoft Graph (read-only); the one
deploy script creates/assigns the health-check package via Graph.
**Verify:** `Get-Module Microsoft.Graph -ListAvailable` returns the SDK; `Connect-MgGraph` succeeds.
**Implement:** `Install-Module Microsoft.Graph -Scope CurrentUser`. The scripts request read scopes
such as `DeviceManagementConfiguration.Read.All` (and `…ReadWrite.All` for the deploy script) and
consent on first connect. **Graph endpoints/scopes for Proactive Remediations (device health scripts)
are on the beta endpoint and may change — verify against current Microsoft documentation.**

## R11. Certificate visibility on the device (for the cert-expiry signal)
**Description:** The health check can read the **auth certificate** the VPN uses (subject/issuer and
`NotAfter`) from the device certificate store.
**Why:** The cert-expiry signal is one of the highest-value early warnings; it needs to locate the VPN
auth certificate and compute days-to-expiry against the warning window (default **30 days**).
**Verify:** On a pilot device, confirm the VPN's client-auth certificate is present in the expected
store (typically **LocalMachine\My** for device/system context) and readable.
**Implement:** Set the certificate **subject or issuer match** at the top of the health-check script
(Implementation §Step 1). For a **user**-context certificate, run the check in the user context
(R7). The exact store/location depends on how the VPN's certificate was provisioned (SCEP/PKCS) —
**verify against the deploying product's configuration.**
