# 1. Solution Overview — Device Compliance Policies

## What Device Compliance Policies are
A device compliance policy is a set of health rules (encryption, OS version, password, antivirus,
threat level, and more) that Microsoft Intune evaluates on each enrolled device. The device is
marked **Compliant** or **Not compliant**, and that status becomes a signal Conditional Access
can use to allow or block access to Microsoft 365 and other apps.

## How it works
1. You define a compliance policy per platform with the rules a device must satisfy.
2. Intune evaluates the device against the rules on enrollment and on a recurring schedule.
3. The result (Compliant / Not compliant) is stored against the device in Entra ID.
4. **Actions for noncompliance** run on a schedule — notify the user, then mark the device noncompliant after a grace period.
5. **Conditional Access** can require "compliant device" to grant access, turning compliance into enforcement.

## What you can require (Windows)
- **Device health** — BitLocker, Secure Boot, Code integrity.
- **Device properties** — minimum/maximum OS version.
- **System security** — password required, length, complexity; encryption of data storage.
- **Microsoft Defender** — antivirus, antispyware, real-time protection, firewall on.
- **Defender for Endpoint** — require a machine risk score at or below a threshold (if integrated).

## Benefits
- **Provable device health** before access is granted.
- **Automated enforcement** — notify and mark noncompliant without manual effort.
- **Zero Trust foundation** — the compliance signal powers Conditional Access.
- **Visibility** — per-device and tenant-wide compliance reporting.

## Limitations (be honest with buyers)
- Compliance only **enforces** access when paired with Conditional Access (a companion solution).
- Threat-level rules require Microsoft Defender for Endpoint integration.
- A grace period means a freshly noncompliant device isn't blocked instantly (by design).
- Devices without any assigned policy are treated per your tenant default — set it deliberately.

## The standard deployment model
> **Set the no-policy default → create the compliance policy → configure actions → assign to a
> pilot group → (optionally) require compliance in Conditional Access.**
repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**
