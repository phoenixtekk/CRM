# 1. Solution Overview — Privileged Access Workstation (PAW) for Cloud Administration

## What a PAW is
A Privileged Access Workstation (PAW) is a dedicated, hardened, Intune-managed Windows device used
**only** for administrative work. It has no general-purpose email client and no open web browsing; it
runs a locked-down configuration (security baselines, Attack Surface Reduction, application control),
and it is the *only* device from which privileged roles are allowed to sign in. The principle is
**clean source**: a high-value credential (a cloud admin role) must only be used from an equally
high-trust device — never from the same laptop that reads email and browses the web.

This solution assembles the PAW model from Microsoft capabilities you may already license:
**Microsoft Intune** builds and enforces the hardened device; **Conditional Access device filters**
require a compliant PAW for privileged sign-ins; and **Privileged Identity Management (PIM)** grants
the admin role just-in-time from that clean device. It is the device-and-enforcement layer of a
privileged-access program — it complements, and does not replace, PIM, the Conditional Access
baseline, and Intune endpoint security, each of which has its own solution.

## How it works
1. **Build the PAW.** Intune enrols a dedicated Windows device and applies a hardened configuration: a security baseline, Attack Surface Reduction (ASR) rules, application control (allow-listing so only approved admin tooling runs), and device restrictions that remove or block general-purpose email and open web browsing. The device is standard-user by default — no local admin for the day-to-day operator.
2. **Prove the device is a PAW.** A device compliance policy defines what "a healthy PAW" means, and the device is **marked** (a device category, a device group, or an extension attribute) so Conditional Access can recognise it. Only marked, compliant devices count as PAWs.
3. **Enforce with Conditional Access device filters.** A Conditional Access policy targets privileged sign-ins (by directory role or by the sensitive admin apps such as the Microsoft Azure Management and Entra/Graph endpoints) and, using a **device filter**, grants access only when the device matches the PAW marker AND is compliant. Anything else is blocked. This is piloted **report-only first**.
4. **Grant admin just-in-time with PIM.** Admin roles are held **eligible**, not standing. The operator signs in from the PAW and activates the role in PIM for a limited window with approval and MFA — so privilege is time-bound and only ever exercised from the clean device.
5. **Break-glass stays safe.** Break-glass emergency accounts are excluded from the device-filter enforcement policy, so a marking or compliance mistake can never lock every administrator out of the tenant.
6. **Operate and monitor.** Sign-in and Intune logs show any attempt to use privileged access from a non-PAW device; the included report/hunt tooling surfaces those attempts so you can close gaps.

## What you can control
- The PAW hardened configuration: which security baseline, which ASR rules, the application-control (allow-list) policy, and the web/email isolation restrictions.
- The compliance definition of a PAW and how devices are marked (category / group / extension attribute).
- The Conditional Access device-filter policy: which roles/apps it protects, the device-filter rule, report-only vs enforced state, and break-glass exclusions.
- The PIM eligibility and activation policy for the roles operated from the PAW (approval, MFA, duration).
- The pilot scope and the staged expansion to all privileged operators.

## Benefits
- Clean source — high-value admin credentials are only ever used from a high-trust, isolated device.
- Blast-radius reduction — a compromised general-purpose laptop cannot reach privileged access at all.
- Token-theft resistance — no email/web on the PAW removes the most common initial-access and token-theft paths for admin sessions.
- Enforced, not advisory — Conditional Access device filters make "use a PAW" a hard control, not a policy document.
- Just-in-time — PIM keeps privilege time-bound and activated only from the clean device.

## Limitations (be honest with buyers)
- Requires **Microsoft Intune** to build and enforce the device, and **Entra ID P2** for PIM and for the risk-aware parts of Conditional Access. *Verify current licensing availability in your tenant.*
- A PAW is a **dedicated** device — admins need a separate device (or a well-separated profile/VDI approach) for general productivity. Plan for that operational cost.
- Application control (allow-listing) and web/email isolation change the admin's daily experience; they need a short tuning period on the pilot before expansion.
- This governs the device and the enforcement; it does not replace PIM governance, a Conditional Access baseline, or endpoint protection — it depends on them.

## Auth / connections used
- Interactive administration in the Microsoft Intune admin center (`https://intune.microsoft.com`) and the Entra admin center (`https://entra.microsoft.com`).
- The included scripts use the **Microsoft Graph PowerShell SDK** (read-only scopes for discovery/validation/report; a scoped read-write scope only for the gated Conditional Access state change and the device-tagging script) and optionally **Az** / a Log Analytics workspace for KQL hunting of privileged sign-ins from non-PAW devices.

## The standard deployment model
> Assess admins, roles, and current devices -> Configure the hardened PAW (baseline, ASR, app control,
> isolation), the compliance/marking, the Conditional Access device-filter policy in report-only, and
> PIM eligibility -> Pilot on a small set of admins/devices -> Validate report-only results and flip
> the device-filter policy to enforce -> Expand to all privileged operators. Break-glass stays excluded
> throughout.
> pattern: Assess -> Configure -> Pilot -> Validate -> Expand.
