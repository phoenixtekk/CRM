# 1. Solution Overview — Cloud-First Autopilot Zero-Touch Provisioning

## What cloud-first provisioning is
Cloud-first provisioning means a Windows device is set up entirely from the cloud, with no on-premises
imaging and no Active Directory domain join. The device is Microsoft Entra joined (not Active
Directory domain joined, not Hybrid) and provisioned by Windows Autopilot through Microsoft Intune.
The moment a new or reset device is powered on and connected to the internet, it identifies itself to
Autopilot, applies your deployment profile, enrolls in Intune, and pulls down apps and policy — while
the Enrollment Status Page (ESP) holds the desktop until the device is ready. The result is a near
zero-touch experience: the technician unboxes the device, powers it on, and walks away.

## Why cloud-first beats hybrid-by-default
Hybrid Azure AD join (domain join plus Entra registration) made sense when apps and resources lived
on a domain controller. Today most identity, app, and policy needs are met by Entra and Intune, and
hybrid adds real cost: line-of-sight to a domain controller during provisioning, an on-prem Intune
Connector, VPN-at-OOBE complexity, and slower, more failure-prone builds. The modern guidance is to
go Entra-join-first and add domain join only for the specific device that genuinely needs an on-prem
resource. This solution is built around that principle: cloud-first by default, domain join later only
if a named app or resource requires it.

## How it works
1. Each device is registered to your tenant as an Autopilot device by its hardware hash (uploaded by
   you, or registered by the OEM/reseller at purchase).
2. A dynamic Autopilot device group automatically gathers all registered devices by their Autopilot
   ZTDID, so you never hand-add members.
3. A Windows Autopilot deployment profile (user-driven, Microsoft Entra joined) defines the
   out-of-box experience: branding, account type, and the cloud-only join.
4. An Enrollment Status Page blocks the desktop during provisioning until your required apps and
   policy install, so users never reach a half-configured machine.
5. Provisioning-time apps and a security baseline are assigned to the Autopilot group so they install
   during enrollment, not days later.
6. The user signs in once with their work account; the device Entra-joins, Intune-enrolls, and lands
   fully configured. Technician touch is effectively limited to powering it on.

## The near zero-touch experience
- Technician effort: unbox, connect power/network, power on. No imaging, no manual join, no per-app
  installs.
- User effort: connect to a network and sign in once with their work account.
- Everything else — join, enrollment, apps, policy, baseline — happens automatically behind the ESP.

## When (and how) domain join is added later
Domain join is the exception, not the default. Add it only when a specific, named requirement cannot
be met cloud-first — for example a legacy line-of-business app that authenticates only via Kerberos to
on-prem Active Directory, or a file share / print resource that cannot be reached with Microsoft Entra
Kerberos or Cloud Kerberos Trust. The decision criteria and the supported path (Microsoft Entra hybrid
join, or Microsoft Entra Kerberos for resource access without changing the join type) are detailed in
the Implementation Guide. Default everything to Entra join; carve out the rare exception deliberately
and document why.

## What you can control
- The join type and out-of-box experience via the Autopilot deployment profile.
- Which apps and policy block provisioning via the Enrollment Status Page.
- The provisioning-time app and baseline set assigned to the Autopilot group.
- Device registration (manual hash upload or OEM/reseller registration).
- A documented exception path to domain join for the rare on-prem dependency.

## Benefits
- Near zero technician touch — power on and walk away; no imaging or manual join.
- Faster, more consistent builds — every device provisions the same assigned set.
- Cloud-first identity — Entra join with no domain-controller line-of-sight at OOBE.
- Lower complexity and risk — no on-prem Intune Connector or VPN-at-OOBE unless an exception requires it.
- Provable readiness — the ESP guarantees apps and policy are present before the user reaches the desktop.
- A measurable touch report — see provisioning success rate and where any manual touch crept in.

## Limitations (be honest with buyers)
- Autopilot needs each device registered (hardware hash); at scale, OEM/reseller registration is
  strongly preferred over manual upload.
- The device must reach the internet at the out-of-box experience to provision.
- Pure cloud (Entra-join) does not natively authenticate to on-prem AD resources; those rare cases use
  Microsoft Entra Kerberos / Cloud Kerberos Trust, or the deliberate domain-join exception.
- Provisioning-time apps that are very large extend the ESP wait; keep the blocking set lean.
- White-glove / pre-provisioning is an advanced add-on and is not the focus of this solution.

## The standard Phoenixtekk deployment model
> Register devices → build the Autopilot profile (Entra join) → configure the ESP and provisioning-time
> apps → validate the zero-touch flow on a pilot → expand. Phoenixtekk pattern:
> Assess → Configure → Pilot → Validate → Expand.
