# Executive Summary — Pre-Logon VPN Connectivity with Cisco Secure Client Start Before Logon (SBL/PLAP) via Microsoft Intune

## The business problem
A normal VPN can only connect *after* a user has already signed in to Windows — which is exactly the
wrong order for remote workers. A user who has **never logged on to a device** has no cached
credentials to sign in with off-network; an **off-network password change or reset** can't reach a
domain controller; **Group Policy and logon scripts** don't process; and hybrid-joined machines can't
see a domain controller at logon. The help desk ends up couriering laptops, running users through
manual VPN dances, or relying on cached passwords that drift out of date.

## The solution
This is a complete, self-guided package that deploys the **Cisco Secure Client (AnyConnect)** with its
**Start Before Logon (SBL)** capability to **Windows** devices through **Microsoft Intune**, so the VPN
tunnel comes up **at the logon screen, before Windows sign-in.** Start Before Logon is delivered as the
**Pre-Login Access Provider (PLAP)** — a "Network sign-in" option on the logon screen — and it only
works when three things are true, all of which this solution automates from the cloud: the **Start
Before Logon module** is installed (after the Core module), the VPN profile has
**`UseStartBeforeLogon` set to true**, and a **device certificate** is present so the tunnel can
authenticate with no user signed in. It uses a proven rollout method:
**Assess → Configure → Pilot → Validate → Expand**, with explicit pass/fail gates and a one-click
rollback.

## What you get
- **Step-by-step implementation** at click-by-click detail on the Intune/Entra/Windows side —
  deploying the trusted root and **device** certificate, packaging the Win32 app that installs **Core
  then SBL** and drops the SBL-enabled profile, building the Windows VPN profile, and assigning to a
  named pilot group.
- **A folded-in certificate-lifecycle section** — why pre-logon needs a machine certificate, how to
  issue it via SCEP/PKCS, and how to keep it renewed so pre-logon never silently breaks.
- **Five PowerShell scripts** — readiness discovery, on-device validation (checks the client, the
  **PLAP/SBL** component, `UseStartBeforeLogon`, and the device cert), fleet coverage reporting, safe
  remediation (preview-by-default), and pilot-group creation.
- **Requirements, testing, troubleshooting, and best-practice guides** so a competent Intune admin can
  implement it end to end — including the decisive test: connect at the logon screen, then log on with
  the tunnel already up.

## Business outcomes
- **First remote logon just works** — a brand-new user on a brand-new device signs in from anywhere,
  no cached credentials required.
- **Off-network password resets and GPO/logon scripts succeed** — the domain controller is reachable
  before Windows logon.
- **Silent and hands-off** — a device certificate authenticates the pre-logon tunnel with no user
  interaction; the whole build is delivered from Intune with no per-device touch.
- **Lower risk** — piloted before fleet-wide rollout, validated against explicit gates, and reversible
  at any point, so a change never strands users at the logon screen.

## Scope and boundary
The solution is authored at full detail on the **Microsoft Intune, Entra ID, and Windows** side and is
**Windows-only** (Start Before Logon is a Windows credential-provider feature). The **Cisco Secure
Client console, the VPN Profile Editor XML internals, head-end CA trust, and the VPN head-end (ASA /
Firepower / ISE)** are the customer's existing Cisco environment and follow **Cisco's official
documentation** — this package consumes those artifacts (Core + SBL modules, the SBL-enabled VPN
profile, gateway details, auth method) and delivers them reliably to every device.

## Bottom line
The VPN tunnel up **before** Windows logon, on every managed Windows device — first remote logon,
off-network password resets, and GPO all working from anywhere, delivered from Intune, proven on a
pilot before you scale, and a fraction of the cost and time of a hands-on consulting engagement.
