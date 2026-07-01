# Executive Summary — BitLocker Drive Encryption (Microsoft Intune)

**Phoenixtekk Workplace Marketplace · Intune Solutions**

A laptop left in a taxi is only a breach if its drive is readable. **BitLocker** encrypts the
whole disk so a lost or stolen device exposes nothing — and managed through Microsoft Intune, it
turns on **silently** on TPM-equipped devices, with every **recovery key escrowed to Microsoft
Entra ID** so the help desk can always recover access.

This is a complete, **deploy-it-today** package for implementing BitLocker Drive Encryption with
Microsoft Intune, written for an administrator with no prior BitLocker-management experience.

## What you get
- A plain-language **Solution Overview** of how Intune-managed BitLocker works.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite.
- An **Implementation Guide** of precise, click-by-click Intune steps in the required order.
- Five **PowerShell scripts** for readiness discovery, encryption validation, tenant reporting, remediation, and recovery-key retrieval.
- **Testing** and **Troubleshooting** guides for confident rollout.

## What this delivers
An Intune **disk encryption policy** that requires **XTS-AES 256** encryption of the OS (and
fixed) drives, **silently** on TPM devices, with **recovery keys automatically saved to Entra ID**
and full encryption reporting.

## The Phoenixtekk deployment model
**Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Fleet-wide full-disk encryption with escrowed recovery keys — device-loss data protection and a
compliance cornerstone — deployable by a single administrator and validated before rollout.
