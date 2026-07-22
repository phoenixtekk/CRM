# 1. Solution Overview — VPN Tunnel Health Monitoring & Alerting in Microsoft Intune (Scheduled Connectivity Health Checks, Telemetry & Alerts)

## What this solution is
Most teams learn a VPN tunnel is unhealthy the same way every time: a wave of **"I can't connect"**
tickets. By then the outage is already live — a client certificate expired overnight, a gateway
stopped answering, a routing change quietly broke traffic to the one subnet that mattered, or DNS
stopped resolving through the tunnel. There was **no proactive signal**.

This solution builds that signal. It turns VPN tunnel health into a **proactive, ongoing,
fleet-wide monitoring practice deployed through Microsoft Intune**. It does four things:

1. **Defines "healthy"** for a VPN tunnel as concrete, checkable signals with pass/fail thresholds.
2. **Deploys scheduled, read-only health checks** to your managed devices using Intune's **Proactive
   Remediations detection model**, so every device reports its own tunnel health on a schedule.
3. **Rolls the results up into telemetry** — Intune reporting and (where available) a Log Analytics
   workspace you can query with KQL and dashboard by VPN type and gateway.
4. **Alerts** when a tunnel degrades — a certificate nearing expiry, a *cohort* of devices failing to
   establish, a gateway going unreachable — so you act **before** the ticket wave.

It is **VPN-technology-aware**: the same practice spans **Microsoft Tunnel**, **Windows Always On VPN**
(both the device tunnel and the user tunnel), and **third-party client VPNs** (for example Cisco
Secure Client / AnyConnect). The health-check script adapts what it probes per VPN type; the
telemetry and alerting sit *above* the VPN technology so one dashboard covers all of them.

## This is MONITORING — read-only by contract, never a fix
The single most important thing to understand about this package: **the health checks never touch the
tunnel.** They are **read-only probes**. They observe adapter state, connection state, reachability,
DNS, and certificate validity, and they **report** — they do not restart a service, reconnect an
adapter, renew a certificate, or re-push a profile. This is deliberate:

- A monitor that "fixes while it checks" hides the real failure rate and can itself cause harm at
  scale (imagine every device in a failing cohort simultaneously bouncing its adapter).
- Monitoring must be **safe to run everywhere, always** — the only way to guarantee that is to make it
  incapable of changing anything.

Fixes are **out of scope here and deferred, with explicit pointers**, to the deployment and
troubleshooting products (see "Where this sits" below). If you want automated *remediation* of a
condition this monitor detects, that is a separate, deliberately-authored remediation built with the
safety discipline of the **"Proactive Remediations at Scale — Detection & Remediation Script Packs for
Microsoft Intune"** product — never a side effect of the health check.

## What "healthy" means — the health signals
The health-check script evaluates a tunnel against these signals and returns a single **health
verdict** (Healthy / Degraded / Unhealthy) plus a per-signal breakdown. Each signal has a pass/fail
rule:

| Signal | Healthy (pass) | Not healthy (fail) |
|---|---|---|
| **VPN adapter / profile present** | The expected VPN profile/adapter for the device's VPN type exists. | Profile/adapter missing — the VPN was never provisioned or was removed. |
| **Tunnel established / connected** | The tunnel reports a connected/established state. | Disconnected, dialing, or error state. |
| **Gateway / endpoint reachable** | The VPN head-end/gateway endpoint responds. | Gateway unreachable (timeout / no route). |
| **Key routes reachable through the tunnel** | A defined internal test target is reachable *via the tunnel*. | The internal target is unreachable while the tunnel is up (routing/split-tunnel problem). |
| **DNS resolves through the tunnel** | An internal name resolves using the tunnel's DNS. | Internal name fails to resolve (DNS not flowing through the tunnel). |
| **Auth certificate valid & not near expiry** | The auth certificate is present, valid, and **more than the warning window** (default **30 days**) from expiry. | **Warn** inside 30 days; **Fail** if expired or missing. |

You set the concrete values — the internal **test route** (e.g. an internal host/IP), the internal
**DNS name** to resolve, the certificate **subject/issuer** to check, and the **cert-expiry warning
window** (default 30 days) — once, at the top of the health-check script (Implementation §Step 1).

> **VPN-type awareness (flag per-vendor specifics).** How each signal is *read* differs by VPN
> technology, and the exact detection surface is **vendor- and version-specific — verify against
> current Microsoft/vendor documentation**:
> - **Microsoft Tunnel** — profile/connection state surfaced through the Microsoft Defender for
>   Endpoint client on the supported platforms; the health check probes reachability, route, DNS, and
>   the auth certificate the profile uses.
> - **Windows Always On VPN (device tunnel + user tunnel)** — Windows exposes the VPN connection
>   objects and status natively (the script can enumerate the connection and its state); a device
>   tunnel and a user tunnel are checked as *separate* connections.
> - **Third-party client VPNs (e.g. Cisco Secure Client / AnyConnect)** — presence and state are read
>   from the vendor client's adapter/service and status surface; the exact service name, adapter name,
>   and status API are **vendor-specific and must be verified against the vendor's documentation.**

## Where this sits — the explicit boundaries (what this is NOT)
This product is intentionally narrow: it is the **endpoint-side health-monitoring layer**. It does
**not** deploy VPNs and it does **not** own gateway-server health. State these boundaries plainly so
buyers don't expect the wrong thing:

- **Microsoft Tunnel gateway-SERVER health belongs to another product.** The **"Microsoft Tunnel
  Gateway — Deployment, VPN Configuration & Ongoing Operations"** solution OWNS the **server-side**
  health and status of a Microsoft Tunnel gateway in Intune (the Linux host, the container/agent, the
  Site/Server Configuration, HA, and the server-side health blade). **This** product **defers all
  server-side health to it** and focuses on **endpoint-side** scheduled checks — "can this *device*
  reach and use its tunnel?" — plus **cross-VPN** telemetry and alerting that no single deployment
  product provides. (Referenced, not reproduced.)
- **VPN *deployment* belongs to the deployment products.** Standing up each VPN — the Microsoft Tunnel
  gateway and profiles, Windows **Always On VPN** (device + user tunnel), or **Cisco Secure Client
  (AnyConnect) VPN Deployment via Microsoft Intune** — is owned by those products. This product
  **assumes a VPN profile is already deployed** and monitors it. (Referenced, not reproduced.)
- **Reactive, deep break/fix belongs to the toolkit product.** When a red signal needs hands-on
  diagnosis, the **"Endpoint Network Connectivity Troubleshooting Toolkit (DNS, Proxy, VPN, IP/Port/URL
  Filtering)"** product is the reactive break/fix engine. This product's triage runbook **points to
  it** rather than reproducing it.
- **The Proactive Remediations *mechanics* belong to that product.** This package **uses** the
  Proactive Remediations *detection* model as its scheduling/reporting engine but does **not** re-teach
  how Proactive Remediations works, how to license it, or how to author remediation pairs — that is the
  **"Proactive Remediations at Scale — Detection & Remediation Script Packs for Microsoft Intune"**
  product (referenced as the engine, not reproduced). Here we deploy a **detection-only** health check
  — there is no remediation script.

## How it works — the monitoring model
1. **Define healthy.** You set the health signals and thresholds (test route, internal DNS name,
   certificate subject/issuer, expiry warning window) once at the top of the health-check script.
2. **Deploy the read-only check on a schedule.** You package the health-check script as a **Proactive
   Remediations detection script** (there is **no** remediation script — this is monitoring) and assign
   it to a device group with a recurrence (e.g. daily). Intune's management extension runs it on each
   device on that cadence.
3. **Each device reports its verdict.** The script writes a structured, human-readable health line and
   signals overall health through the **exit-code contract** (`exit 0` = healthy; `exit 1` = degraded/
   unhealthy) so the Intune console shows a per-device with-issue / without-issue split.
4. **Telemetry rolls it up.** Where a **Log Analytics** workspace is wired in, the health results are
   queryable with **KQL**, so you can build a **fleet health rollup by VPN type and gateway**. (Whether
   Proactive Remediations output is natively queryable in Log Analytics, and the exact data path,
   **must be verified against current Microsoft documentation** — see Requirements and Implementation.)
5. **Alerts fire on degradation.** An **Azure Monitor** alert rule on the telemetry (a KQL result
   crossing a threshold) turns a degraded/expiring tunnel into a notification — cert nearing expiry, a
   cohort failing to establish, a gateway unreachable. (Exact alert wiring is **verify-with-Microsoft**.)
6. **Triage points to the fix.** When a signal goes red, the triage runbook maps it to the responsible
   layer and **points to the product that owns the fix** — it never fixes the tunnel itself.

## The standard deployment model
This solution uses **one** repeatable model so the process is recognizable across the catalog:

> **Define the health signals and thresholds → author the read-only, VPN-type-aware detection health
> check → package it as a named Proactive Remediations detection (no remediation) → scope to a pilot
> ring → wire telemetry (Log Analytics/KQL) → build the fleet health dashboard → configure alert rules
> → validate against seeded failures → expand to the fleet in waves.**

Every step follows the repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**

## Benefits
- **Know before your users do** — a scheduled health signal replaces the ticket wave; you see a tunnel
  failing on a cadence, fleet-wide, instead of finding out from the help desk.
- **One practice across every VPN you run** — Microsoft Tunnel, Always On VPN (device + user tunnel),
  and third-party client VPNs roll up into one health view, by VPN type and gateway.
- **Catch certificate expiries early** — the cert-expiry warning window turns a silent, dated failure
  into an alert weeks ahead, not a Monday-morning outage.
- **Safe by construction** — the checks are **read-only**; they can run everywhere, always, without
  ever risking the tunnel they watch.
- **Fast, correct triage** — a red signal maps straight to the responsible layer and the product that
  owns the fix, so time-to-diagnosis drops.
- **Reuses tools you already have** — the Proactive Remediations detection engine, Intune reporting,
  and (optionally) Log Analytics/Azure Monitor; no new agent to deploy.

## Limitations (be honest with buyers)
- **It monitors; it does not fix.** By design, the health checks make **no** changes to the tunnel.
  Remediation is deferred to the deployment/troubleshooting products (with pointers). This is a
  feature, not a gap.
- **A VPN must already be deployed.** This package assumes each device already has its VPN profile;
  standing up the VPN belongs to the deployment products.
- **Licensing & feature availability gate the engine.** The Proactive Remediations detection model
  requires the licensing/enrollment that product documents — **verify current licensing and feature
  availability against Microsoft's documentation** (Requirements §R1).
- **Telemetry & alerting depend on optional Azure plumbing.** The fleet KQL rollup and Azure Monitor
  alerts require a **Log Analytics workspace** and **Azure Monitor**, and the exact data path from
  Proactive Remediations output into Log Analytics **must be verified against current Microsoft
  documentation** (Requirements §R3–R4). Without them you still get per-device Intune reporting; you
  lose the cross-VPN KQL dashboard and threshold alerts.
- **Scheduling is periodic, not instant** — detection runs on a recurrence, so a health signal is
  "eventually", not real-time. Exact cadence limits are **verify-with-Microsoft**.
- **Per-vendor detection specifics vary.** How each signal is read for a given VPN client (service
  name, adapter name, status surface) is **vendor- and version-specific and must be verified against
  the vendor's documentation** before you rely on it.
