# 1. Solution Overview — Application Control (WDAC)

## What WDAC is
Windows Defender Application Control (now **App Control for Business**) enforces an **allowlist**:
only code that is explicitly trusted is allowed to run; everything else is blocked. It is enforced
deep in Windows (kernel level), making it far harder to bypass than user-mode controls. This
solution manages it through Microsoft Intune.

## Trust models (how code gets allowed)
- **Windows components + Microsoft Store apps** — trusted by the built-in base policy.
- **Reputable apps (Intelligent Security Graph / ISG)** — optionally trust apps Microsoft's cloud reputation considers good.
- **Intune-managed installers** — optionally trust anything installed by Intune (your deployed apps become trusted automatically).
- **Custom rules** — publisher, path, or file-hash rules via custom policy XML for advanced needs.

## Modes
- **Audit only** — nothing is blocked; Windows **logs** what *would* have been blocked (Code Integrity events). This is how you roll out safely.
- **Enforced** — untrusted code is blocked.

> **Method:** deploy in **Audit** first, review Code Integrity events, add the legitimate apps to
> trust, then switch to **Enforce**.

## How it works
1. An Intune **App Control for Business** policy sets the trust model and mode.
2. In **Audit**, the device logs **Code Integrity** events for code that isn't trusted.
3. You review those events, add legitimate apps to trust (managed installer / ISG / supplemental policy).
4. You switch the policy to **Enforce**; untrusted code is now blocked.

## Benefits
- **Stops untrusted code** — including unknown malware, living-off-the-land binaries, and unsanctioned apps.
- **Kernel-enforced** — much harder to bypass than user-mode allowlisting.
- **Safe rollout** — Audit mode reveals impact before enforcement.
- **Low maintenance with managed installers** — apps you deploy via Intune are trusted automatically.

## Limitations (be honest with buyers)
- WDAC is **powerful** — a misconfigured enforced policy can block legitimate apps. Audit-first + a recovery path are essential.
- Highly dynamic environments (developers compiling code, frequent new unsigned tools) need careful trust design.
- Custom XML policies are advanced; this solution favors the **managed-installer + ISG** model for most fleets.
- Recovery from an over-strict enforced policy is via removing/replacing the policy (covered here).

## The standard Phoenixtekk deployment model
> **Create the App Control policy in Audit → review Code Integrity events → add trust → Enforce →
> expand.** Phoenixtekk pattern: **Assess → Configure → Pilot → Validate → Expand.**
