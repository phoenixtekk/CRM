# Executive Summary — macOS Identity-Threat & Account-Lockout Hardening

**White-label · Security**

Macs are a quiet source of identity trouble. When a user's Entra password changes, the Mac's keychain,
mail profile, and Wi-Fi often keep re-submitting the **old** password automatically — a steady stream
of **failed sign-ins** that Entra reads as a **password-spray** attack and that triggers **account
lockouts** blocking the legitimate user. Sometimes it is tangled up with SecureToken and local-account
state that has drifted out of sync with the cloud. This solution hardens the **identity posture of the
Mac fleet**: it finds the Mac-originated failures, enforces the tenant controls that stop them from
locking real users out, and cleans up the Mac-side credential state that causes the failures in the
first place — under Zero-Trust and least-privilege.

This is a complete, deploy-it-today package written for an administrator with no prior identity-hardening
experience.

## What you get
- A plain-language Solution Overview of how macOS authentication, saved credentials, keychain, and
  SecureToken contribute to failed sign-ins, lockouts, and password-spray noise — and the hardening
  model that fixes it.
- A Requirements Guide with verify / implement-if-missing for every prerequisite (Entra sign-in logs /
  Identity Protection, Smart Lockout, MFA via Conditional Access, Intune, a pilot).
- An Implementation Guide of precise, ordered steps: identify Mac-originated lockout/spray sources from
  the sign-in logs, enforce Smart Lockout + MFA, remediate stale Mac credentials/keychain/SecureToken,
  validate the reduction, then expand.
- Five PowerShell scripts for sign-in-failure/lockout discovery by device/OS, Smart-Lockout-and-MFA
  validation, a before/after exposure report, safe remediation, and a Mac scope-group builder.
- Testing and Troubleshooting guides plus Best Practices for identity protection on Macs.

## What this delivers
A Mac fleet that stops driving account lockouts and password-spray detections: the sources identified
from Entra sign-in logs, Smart Lockout and MFA enforced so a burst of Mac failures no longer locks a
real user out, and the stale Mac credential state cleaned up — proven on a pilot before you expand.

## The standard deployment model
Assess → Configure → Pilot → Validate → Expand.

## Outcome
Fewer lockouts, less spray noise, and a hardened Mac identity posture — deployable by a single
administrator and repeatable on a review cadence.
