# Executive Summary — Windows Always On VPN: User Tunnel with Conditional Access (IKEv2/SSTP) via Microsoft Intune

## The business problem
Remote workers need a VPN that just works — always on, no manual reconnecting — and access to corporate
resources over that VPN must be limited to trusted, healthy devices. Done by hand, teams end up with users
clicking "connect" every session, inconsistent tunnel settings across the fleet, split-tunnel drift, and
an always-on tunnel that is effectively always-open because nothing checks the device. The result is
help-desk load, configuration drift, and a remote-access surface that identity alone doesn't secure.

## The solution
This is a complete, self-guided package that **deploys the Windows Always On VPN user tunnel to every
enrolled Windows device through Microsoft Intune** and **gates access over it with Microsoft Entra
Conditional Access**. The tunnel auto-connects when the user signs in (IKEv2 with SSTP fallback,
authenticated by a user certificate), and Conditional Access requires a **compliant or Entra
hybrid-joined device plus MFA** before the user reaches corporate resources. It uses a disciplined
**profile-plus-certificate-plus-policy** model and a proven rollout method:
**Assess → Configure → Pilot → Validate → Expand**, with explicit pass/fail gates and an instant rollback
(unassign / Conditional Access report-only).

## What you get
- **Step-by-step implementation** at click-by-click detail on the Intune/Entra side — the trusted root,
  the user SCEP certificate (built leanly), the VPN template profile, and the Conditional Access policy.
- **Five PowerShell scripts** — readiness discovery, on-device validation, fleet coverage reporting, safe
  remediation (preview-by-default), and pilot-group creation.
- **Requirements, testing, troubleshooting, and best-practice guides** so a competent Intune admin can
  implement it end to end and know it worked.

## Business outcomes
- **Sign in, auto-connect, stay compliant** — the tunnel comes up automatically and only compliant,
  trusted devices reach corporate resources through it.
- **Consistent remote access on every device** — the same gateway, tunnel type, trusted-network rules, and
  authentication everywhere; configuration drift eliminated.
- **Lower risk** — piloted before fleet-wide rollout, Conditional Access proven in report-only first, and
  reversible at any point, so a change never strands users.
- **Continuous assurance** — coverage reporting shows exactly who has a working tunnel and user certificate
  and who does not.

## Scope and boundary
The solution is authored at full detail on the **Microsoft Intune and Entra** side (the **user tunnel**
plus Conditional Access). The **VPN gateway / head-end (RRAS or Azure VPN Gateway)** follows **Microsoft's
official documentation**, and the **device tunnel** plus the **full certificate lifecycle** are the
**companion device-tunnel product** — this package configures the user certificate leanly and consumes the
head-end and PKI values as inputs.

## Bottom line
An always-on, compliance-gated VPN user tunnel on **every managed Windows device** — delivered from
Intune, consistent across the fleet, enforced by Conditional Access, proven on a pilot before you scale,
and a fraction of the cost and time of a hands-on consulting engagement.
