# Solution Overview

## What this solution does

You configure a **device group** on a Windows Autopilot **device preparation** policy, or on
an **Apple Automated Device Enrollment (ADE)** enrollment policy, so that devices land in a
known security group the moment they enroll — ready for the compliance, configuration, and app
assignments targeted at that group. You save the policy… and it fails:

> **"Unable to save device group for `<name>`. You cannot update this configuration because we
> could not find the security group you selected or the Intune Provisioning Client application
> is not an owner."**

The group looks correct. The policy is valid. Yet **Enrollment-Time Grouping** will not commit.
And while you dig, the Azure portal buries you in unrelated `AuthorizationFailed` /
`microsoft.insights/eventtypes/values/read` errors in the Activity Log that send you chasing the
wrong thing entirely.

This solution is the definitive **prerequisites, setup, and diagnostic playbook** for
Enrollment-Time Device Grouping across **both platforms**. It explains the mechanism that trips
everyone up, gives you the exact group specification, walks the setup end-to-end for Windows and
Apple, and hands you a **symptom → root-cause decision tree** that maps every error string to its
real cause — plus five PowerShell (Microsoft Graph) tools to assess, remediate, validate, and
diagnose.

## What Enrollment-Time Grouping is

Historically, a device only landed in an Entra security group **after** it enrolled and Entra
re-evaluated dynamic-group rules — a delay of minutes to hours during which nothing targeted at
that group applied. **Enrollment-Time Grouping** closes that gap: Intune adds the device to a
**specific, pre-chosen Assigned security group at the moment of enrollment**, so the first policy
sync already sees the device as a group member. That is what makes true zero-touch provisioning
work — apps and configuration are present before the user reaches the desktop or home screen.

This capability appears in two places:

- **Windows Autopilot device preparation** — the newer, simplified Autopilot experience. The
  enrollment policy has a **Device group** setting where you name the group devices join at
  enrollment. Microsoft documents the requirement here.
- **Apple Automated Device Enrollment (ADE)** — the enrollment profile attached to an Apple
  enrollment program token exposes the **same Device Group option** and uses the **same backend
  mechanism**. This solution targets **shared / no-user-affinity** Apple deployments (kiosk,
  shared iPad, front-line device pools).

> **Documentation reality (state this to stakeholders).** Microsoft documents Enrollment-Time
> Grouping primarily for **Windows Autopilot device preparation**. **Apple ADE** exposes the same
> Device Group control and relies on the same service backend, but Microsoft publishes **little
> Apple-specific guidance** for it. This playbook applies the documented Windows requirement to
> the Apple flow because the backend is shared — it does **not** invent Apple-specific Microsoft
> documentation that does not exist. Because the feature is relatively new and partly
> preview-gated, **verify the exact control names and availability in your own tenant.**

## The mechanism that trips everyone up

To add a device to a group **on your behalf, at enrollment time**, Intune acts through a
Microsoft first-party service principal called the **Intune Provisioning Client**. Entra will
only let that service principal write membership into a group if it is an **Owner** of that group.

- **The service principal must be an OWNER of the target group.** AppId
  **`f1346770-5b25-470b-88bd-d5744ab7952c`** — a fixed Microsoft first-party identifier.
- **The display name varies by tenant.** In some tenants it shows as **Intune Provisioning
  Client**; in others as **Intune Autopilot ConfidentialClient**. **Always match by AppId, never
  by name.**
- **The failure happens only *after* Save.** Adding the group to the policy in the UI succeeds;
  the relationship Intune establishes when you **Save** is what fails if the owner is missing.
  That is why the error feels like it comes from nowhere.

When the owner is present, correct, and propagated, Save commits and devices populate the group at
enrollment. When it is missing, you get the "not an owner" error — every time, on both platforms.

## Reference design

| Artifact | Windows | Apple |
|----------|---------|-------|
| Target device group | `Autopilot – Devices – Prod` | `iOS – Shared Devices – Prod` |
| Pilot device group | `Autopilot – Devices – Pilot` | `iOS – Shared Devices – Pilot` |
| Group owner (required) | Intune Provisioning Client SP (AppId `f1346770-…`) | same SP, same AppId |
| Enrollment policy | `Autopilot DevicePrep – Shared – Prod` | `ADE Enrollment – Shared iOS – Prod` |
| Enrollment token | (Autopilot uses device-prep policy) | `ADE Token – Corporate – Prod` |

Every target group in this design is the same shape: **Security**, **Assigned** membership,
**cloud-only**, **not mail-enabled**, **not role-assignable**, ideally **empty at creation**, and
**owned by the Intune Provisioning Client**. The full matrix and the *why* behind each attribute
are in **02 — Requirements**.

## Benefits

- **Zero-touch that actually works** — devices are group members at first sync, so apps and
  configuration apply during provisioning, not hours later.
- **One method, both platforms** — the same prerequisite and the same fix cover Windows Autopilot
  device preparation and Apple ADE.
- **No more wrong turns** — the Azure Activity Log `AuthorizationFailed` noise is called out as an
  unrelated red herring so you stop chasing it.
- **Repeatable and evidenced** — PowerShell/Graph tools prove readiness before you touch a policy
  and map any error you hit to its cause.

## Limitations and boundaries

- **Group membership must be Assigned, not Dynamic.** Intune manages membership at enrollment; a
  Dynamic group's rule engine owns membership and conflicts with that — Dynamic groups are not
  supported for this purpose.
- **The group must be cloud-only.** A group synced from on-premises AD cannot have its membership
  written by the service principal.
- **Preview / version dependence.** Control names, availability, and behavior for Enrollment-Time
  Grouping (especially on Apple) may differ by tenant and change over time — **verify in your
  tenant**.
- **Not a licensing or MDM-authority fix.** This solution assumes Intune is the MDM authority and
  the category prerequisites (see the Global Requirements) are already met.

## Deployment model

This solution follows the standard house model — **Assess → Configure → Pilot → Validate →
Expand** — with explicit pass/fail gates and a documented rollback at each step:

1. **Assess** — confirm the group specification and whether the Intune Provisioning Client is
   already an owner (`ETDG-Assess-GroupReadiness.ps1`, `ETDG-Test-EnrollmentGroupPrereqs.ps1`).
2. **Configure** — create the group to spec and add the service principal as Owner
   (`ETDG-Set-ProvisioningClientOwner.ps1`, `-WhatIf` by default).
3. **Pilot** — wire the **pilot** group to a pilot enrollment policy on each platform, enroll a
   test device, confirm it joins the group.
4. **Validate** — the policy Saves, the device populates the group at enrollment, and the group's
   assignments (apps/config) apply (`05 — Testing`).
5. **Expand** — promote to the **Prod** groups and policies; keep the diagnostic report tool
   (`ETDG-Get-DiagnosticReport.ps1`) on hand for any recurrence.
