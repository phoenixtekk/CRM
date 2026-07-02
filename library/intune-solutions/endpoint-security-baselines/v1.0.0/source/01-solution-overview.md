# 1. Solution Overview — Endpoint Security Baselines

## What Security Baselines are
A security baseline in Microsoft Intune is a pre-configured group of security settings, set to the
values Microsoft's security team recommends. Instead of configuring hundreds of individual policy
settings, you deploy a baseline and the device adopts a vetted, hardened configuration — which you
can then customize and keep current as Microsoft publishes new baseline versions.

## Available baselines
- **Security Baseline for Windows 10 and later** — the core OS hardening baseline.
- **Microsoft Defender for Endpoint Baseline** — security settings for MDE-managed devices.
- **Microsoft Edge Baseline** — browser security settings.

## How it works
1. You create a **profile from a baseline version**; it starts at Microsoft's recommended values.
2. You review and, where needed, **adjust** specific settings for your environment.
3. You **assign** the profile to a pilot group; Intune applies the settings.
4. Intune reports **per-setting status** and flags **conflicts** with other profiles.
5. When Microsoft releases a **new baseline version**, you update the profile to stay current.

## Benefits
- **Expert hardening, fast** — Microsoft's recommendations applied in one move.
- **Consistency** — every device adopts the same vetted posture; no drift.
- **Customizable** — adjust the few settings your environment requires.
- **Maintained** — version updates track Microsoft's evolving recommendations.

## Limitations (be honest with buyers)
- Baselines can **conflict** with existing configuration profiles/GPOs — conflict detection and resolution are essential (covered here).
- Some hardened settings may affect line-of-business apps — pilot before fleet.
- Baselines are **versioned**; staying current requires periodic profile updates.
- A baseline is a strong starting point, not a substitute for the specific solutions (BitLocker, ASR, Firewall) where you want explicit control.

## The standard deployment model
> **Pick the latest baseline version → create a profile → review/adjust → assign to a pilot →
> resolve conflicts → expand → keep current.** repeatable pattern: **Assess → Configure → Pilot →
> Validate → Expand.**
