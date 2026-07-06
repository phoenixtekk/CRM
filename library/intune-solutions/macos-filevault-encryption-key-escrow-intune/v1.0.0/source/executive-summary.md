# Executive Summary — FileVault Full-Disk Encryption & Key Escrow for macOS (Microsoft Intune)

**White-label · Intune Solutions**

A MacBook left in a taxi is only a breach if its drive is readable. **FileVault** encrypts the
whole disk so a lost or stolen Mac exposes nothing — but only if it is **enforced, escrowed, and
recoverable**. Managed through Microsoft Intune, this solution turns FileVault on by policy,
**escrows every personal recovery key to Intune** (and rotates it), and handles the **SecureToken /
bootstrap-token** enablement that FileVault depends on — so data is protected and the help desk can
always recover a locked-out Mac.

This is a complete, **deploy-it-today** package for implementing FileVault encryption and
recovery-key escrow with Microsoft Intune, written for an administrator with no prior FileVault- or
SecureToken-management experience.

## What you get
- A plain-language **Solution Overview** of how FileVault + SecureToken work on Apple Silicon/T2, personal vs institutional recovery keys, Intune escrow, and the recovery model.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite (enrollment, disk-encryption policy, SecureToken/bootstrap token, Entra groups, a pilot).
- An **Implementation Guide** of precise, click-by-click Intune steps in the required order.
- Five **PowerShell scripts** for readiness discovery, per-device validation, fleet + recovery-key reporting, safe remediation, and pilot/target group building.
- **Testing** and **Troubleshooting** guides for confident rollout, plus **Best Practices** for key rotation and recovery.

## What this delivers
An Intune **FileVault disk-encryption policy** that enables FileVault on the target Macs, **escrows
the personal recovery key to Intune**, **hides the key from the user**, and **rotates** it — with
full encryption reporting and a proven recovery workflow.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Fleet-wide FileVault encryption with escrowed, rotatable recovery keys — device-loss data
protection and a compliance cornerstone — deployable by a single administrator and validated before
rollout.
