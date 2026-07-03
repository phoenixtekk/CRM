# Best Practices — Windows Autopilot (Government / GCC High)

Operating guidance for running Windows Autopilot **device preparation** correctly on a **GCC
High / DoD** tenant. These are the habits that keep a sovereign deployment stable and keep you
from accidentally designing against Commercial-only features.

> **Portal reminder:** operate in the `*.us` portals (`https://intune.microsoft.us`,
> `https://entra.microsoft.us` *(verify for GCC High)*). Connect PowerShell with
> **`-Environment USGov`** and confirm the environment prints as **USGov** before acting.

---

## 1. Design for the supported path only — never for classic Autopilot

Classic Windows Autopilot (hardware-hash import, deployment profiles, self-deploying and
pre-provisioning modes, Hybrid Entra join) is **not available in GCC High**. Do not scope,
budget, or document a rollout around it. Everything is **device preparation**, **user-driven**,
**Entra join**. If a stakeholder asks for white-glove/self-deploying kiosks, set expectations
early: those modes are **planned**, not available today.

## 2. Treat the Provisioning Client owner as the linchpin

The most common — and most confusing — failure is a device that Entra-joins and enrolls but
receives **no apps/scripts** because the **Intune Provisioning Client** service principal does
not **own** the assigned device group. Make ownership an explicit, verified step:

- The device group (`WAPG-Autopilot-Devices`) is **Assigned**, never Dynamic.
- The Provisioning Client (**AppId `f1346770-5b25-470b-88bd-d5744ab7952c`**, possibly named
  *Intune Autopilot ConfidentialClient*) is an **Owner**.
- Confirm it programmatically with `WAPG-Validation.ps1` (US Gov Graph) before every pilot.

## 3. Keep the OOBE app/script list short

Microsoft deliberately limits how many apps run during device-preparation OOBE for stability
and success rate. Select only the **essential** apps/scripts inside
`WAPG-DevicePrep-UserDriven-EntraJoin`; assign everything else to `WAPG-Autopilot-Devices` for
**post-provisioning** install. Keep the ESP blocking list short so users reach the desktop
quickly.

## 4. Service Windows through update rings, not Autopatch

Windows Autopatch and the newer Feature/Quality/Expedite/Driver update policies are **not
available in GCC High**. Standardize on **Update rings for Windows 10 and later**
(`WAPG-UpdateRing-Pilot` for the pilot, then wider rings). Do not design a servicing plan that
assumes Autopatch, update-policy reports, or Windows Subscription Activation.

## 5. Build compliance on locally evaluated signals

**Device Health Attestation is not available in GCC High.** Base `WAPG-Compliance-Win11` on
rules that evaluate on the device — **BitLocker, Secure Boot, minimum OS build, firewall,
Defender status** — not attestation results, so devices are not stuck non-compliant.

## 6. Plan the gaps that touch day-2 support

- **Remote Help** is unavailable — pre-select and document an approved alternative
  remote-assist tool for post-provisioning support.
- **Cloud PKI** is unavailable — deliver certificates via **SCEP/PKCS** with your own PKI/NDES.
- **Windows Hello for Business** works, but the **hosted PIN reset service is unavailable in
  Azure Government** — configure PIN recovery via allowed sign-in URLs (Intune/CSP/GPO).
- **Microsoft Store for Business** is unavailable — package apps as Win32/line-of-business.

## 7. Get the network right before the first device

Allow the **US Government** URL/IP ranges and **exempt `*.manage.microsoft.us` from SSL
inspection**. Device preparation also contacts `login.live.com` for its deployment service and
needs NTP (UDP 123). One misconfigured proxy will fail every OOBE identically — validate T3
before piloting a single device.

## 8. Use the scripts the way they are designed

- **Read-only first:** `WAPG-Discovery.ps1` and `WAPG-Validation.ps1` before any change.
- **Report for evidence:** `WAPG-Report.ps1` for deployment status you can attach to a change
  record or support case.
- **Remediate safely:** `WAPG-Remediation.ps1` and `WAPG-Set-ScopeTargeting.ps1` default to
  **`-WhatIf`** — preview, review, then re-run with `-WhatIf:$false`. Every script refuses to
  change anything when the connected environment is not **US Gov**.

## 9. Respect the gates — pilot before you expand

Follow **Assess → Configure → Pilot → Validate → Expand**. Widen scope only after the
`05-testing.md` gates pass, and widen **one group at a time** with `WAPG-Set-ScopeTargeting.ps1`
(preview first). A device that was fine in the pilot can still surface a network or licensing
gap in a new business unit — expand deliberately.

## 10. Keep a "verify for GCC High" watchlist

A few details in `gcc-high-parity-notes.md` are flagged **"verify for GCC High"** because
Microsoft's public docs did not confirm them verbatim at authoring time (e.g. the standalone
`entra.microsoft.us` host, exact WHfB behavior under device-preparation OOBE). Validate those
against your live tenant and update your internal runbook — never assume.

## Sources

- Microsoft, *Overview / requirements of Windows Autopilot device preparation* (OOBE app
  limit, Assigned group + Provisioning Client owner, Entra-join only).
- Microsoft, *Intune Government Service overview* (unavailable/planned features: classic
  Autopilot, Autopatch/update policies, DHA, Cloud PKI, Store for Business, Remote Help).
- Microsoft, *Network endpoints for US government deployments* (sovereign endpoints, no SSL
  inspection).
- Microsoft, *Microsoft Graph national cloud deployments* (`-Environment USGov`).
