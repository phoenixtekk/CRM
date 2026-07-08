# Executive Summary — GlobalProtect Connect Before Logon (PLAP) for Hybrid Azure AD Join Autopilot via Microsoft Intune

## The business problem
After a security incident, the organization moved off **Always On VPN** to a **user-initiated VPN** — but
it still provisions Windows with **Hybrid Azure AD Join Windows Autopilot**, which needs the device to
reach a **domain controller before the first user signs in** (for domain join, Group Policy, and a
first-time logon with no cached credentials). A user-initiated VPN breaks that pre-logon reachability
unless the tunnel can be raised **at the sign-in screen**. In practice the base **GlobalProtect** client
deploys fine from Intune, but the **Connect Before Logon (PLAP)** registration is fragile: it
intermittently fails with an **"unzipping" error** during Autopilot, reboot orchestration compounds it,
and the **Connect Before Logon control is not reliably visible** at sign-in. Testing was on Windows 10;
production is **Windows 11**. The rollout stalls, and every failure is hard to diagnose.

## The solution
This is a complete, self-guided package that makes GlobalProtect Connect Before Logon **deployable AND
diagnosable** for the hybrid-join Autopilot scenario. It delivers Connect Before Logon as a **single,
correctly sequenced Intune Win32 app** — install the GlobalProtect MSI (5.2+), write the registry that
enables Connect Before Logon and sets the portal, wait for the GlobalProtect service, register PLAP in the
SYSTEM context, and **return exit code 3010 so the Enrollment Status Page owns the reboot** (never a
scripted reboot). It makes the app a **blocking app** in the ESP, targets an **Assigned** Autopilot device
group **owned by the Intune Provisioning Client service principal** so it populates at enrollment, and
neutralizes the **"unzipping" 0x87D30067** error with an antivirus/IMECache exclusion and a clean re-wrap.
A **log-capture runbook** turns any failed provisioning into a diagnosed cause on a Windows 11 test device.

## What you get
- **Step-by-step implementation** at click-by-click detail on the Intune/Autopilot/Entra/Windows side —
  the single Win32 app, the ESP blocking app, the enrollment-time device group, and the AV exclusion,
  with explicit Gate A–E pass/fail gates.
- **Five PowerShell tools** — readiness discovery (incl. the group's service-principal owner check),
  on-device Windows 11 validation, a **log-capture collector** (IME + Autopilot + GlobalProtect logs),
  fleet coverage reporting, and an enrollment-time device-group builder that sets the SP owner.
- **Requirements, testing, troubleshooting, and best-practice guides** — including a failure-mode matrix
  covering the unzip error, the missing sign-in tile, reboot-loop and IME-state loss, ESP hangs, the
  Win10-vs-Win11 mismatch, and hybrid first-logon failures.

## Business outcomes
- **Hybrid Autopilot works over a user-initiated VPN** — the tunnel is up before logon, so domain join,
  Group Policy, and first-time logon succeed off-network, with no Always On dependency.
- **The fragile seams are removed** — one correctly sequenced app, ESP-owned reboot, and an AV exclusion
  end the intermittent unzip failures and the missing Connect Before Logon tile.
- **Faster diagnosis** — a repeatable log-capture runbook replaces guesswork in the test window.
- **Lower risk** — piloted on Windows 11 before fleet-wide rollout, validated against explicit gates, and
  reversible at any point.

## Scope and boundary
The solution is authored at full detail on the **Microsoft Intune, Autopilot, Entra ID, and Windows**
side. The **GlobalProtect portal / gateway configuration and the GlobalProtect app internals** are the
customer's existing Palo Alto environment and follow **Palo Alto Networks' official documentation** — this
package consumes those artifacts (the MSI, portal FQDN, and authentication method) and delivers Connect
Before Logon reliably during enrollment.

## Bottom line
GlobalProtect Connect Before Logon, installed and registered during Hybrid-Join Autopilot, with the sign-in
tile present at first logon — delivered as a single sequenced app that lets ESP own the reboot, made
diagnosable with a log-capture runbook, and proven on a Windows 11 pilot before you scale.
