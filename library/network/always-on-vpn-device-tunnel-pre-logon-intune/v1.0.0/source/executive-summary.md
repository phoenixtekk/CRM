# Executive Summary — Windows Always On VPN — Device Tunnel Before User Logon (IKEv2, Machine-Certificate Auth) via Intune

## The business problem
Remote and hybrid Windows devices need the corporate network **before a user signs in** — for a
brand-new employee's first logon with no cached credentials, for an off-network password change, for
group policy and logon scripts to process, and for a domain controller to be reachable at the logon
screen. Without it, remote onboarding stalls, off-network password resets fail, and organizations bolt
on third-party "Start Before Logon" add-ons that add cost and fragility.

## The solution
This is a complete, self-guided package that **deploys the Windows Always On VPN *device tunnel* to
your managed fleet through Microsoft Intune** — the Microsoft-native way to connect the **machine** to
the corporate network at **boot, before logon**. The device authenticates with its own **machine
certificate** over **IKEv2**, delivered from the cloud with no hands-on device touch. It uses a
disciplined **certificate-plus-ProfileXML** model (a device certificate *and* the VPNv2 ProfileXML,
deployed together to the same device group) and a proven rollout method:
**Assess → Configure → Pilot → Validate → Expand**, with explicit pass/fail gates and a tested
rollback.

## What you get
- **Step-by-step implementation** at click-by-click detail on the Intune/Entra/PKI side — the machine
  certificate lifecycle (Trusted Root CA + SCEP device certificate), authoring the ProfileXML, and
  deploying it as a **Custom OMA-URI** profile in **device context**.
- **Five PowerShell scripts** — readiness discovery, on-device validation, fleet coverage reporting,
  safe remediation (preview-by-default), and pilot **device**-group creation.
- **Requirements, testing, troubleshooting, and best-practice guides** so a competent Intune admin can
  implement it end to end and prove — with a **pre-logon** test — that it works.

## Business outcomes
- **Corporate network at the logon screen** — first-time logon, off-network password changes, GPO and
  logon-script processing, and domain-controller reachability all work before a user is present.
- **Microsoft-native, lower cost** — the built-in device tunnel replaces third-party Start-Before-Logon
  add-ons; hands-off cloud delivery replaces per-device configuration.
- **Lower risk** — piloted before fleet-wide rollout, validated against explicit gates (including the
  decisive pre-logon test), and reversible at any point, so a change never strands users at boot.
- **Continuous assurance** — coverage reporting shows exactly which devices have a working certificate
  and device tunnel and which do not, with a renewal threshold that keeps the tunnel authenticating
  over time.

## Scope and boundary
The solution is authored at full detail on the **Microsoft Intune, Entra ID, and Windows/PKI** side.
The **VPN gateway head-end** (Windows Server **RRAS** or **Azure VPN Gateway**) — its IKEv2
parameters, routes, CA trust, and server certificate — is the customer's existing gateway and follows
**Microsoft's official documentation**. This package consumes those outputs (gateway address/FQDN,
IKEv2 settings, CA trust) and delivers the certificate and ProfileXML reliably to every device.

## Bottom line
The corporate network reachable **before anyone signs in**, on every managed Windows device —
delivered from Intune with a Microsoft-native IKEv2 device tunnel and machine-certificate
authentication, proven on a pilot before you scale, and a fraction of the cost and time of a hands-on
consulting engagement or a third-party Start-Before-Logon add-on.
