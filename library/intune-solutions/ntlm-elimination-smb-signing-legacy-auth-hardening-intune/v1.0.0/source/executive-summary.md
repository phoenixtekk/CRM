# Executive Summary — NTLM Elimination & SMB Signing (Legacy Authentication Hardening)

Windows endpoints still accept and emit **legacy authentication** that attackers depend on: LM/NTLMv1
responses, NTLM relay, unsigned SMB traffic, insecure guest logons, and unauthenticated RPC. Every one
of these is a well-worn path for credential theft, man-in-the-middle relay, and lateral movement — and
most tenants have never turned them off. This solution **eliminates NTLM (v1 first, then NTLM overall)
and enforces SMB signing** on Windows 10/11 endpoints via a **Microsoft Intune Settings Catalog**
policy, using the exact **Local Policies\Security Options**, **MS Security Guide**, and **SMB** settings
that harden the authentication stack — deployed **audit-first**, pilot-first, and fully reversible.

**A deliberately scoped, distinct capability.** This is the **NTLM-elimination + SMB-signing** hardening
product. It resolves roughly **seven** recurring Windows Client assessment findings — LAN Manager
authentication level, NTLM SSP minimum session security (client **and** server), SMB signing (client
**and** server), insecure guest logons, and unauthenticated RPC restriction — as a **focused gap
product**. It **cross-references** the full CIS Windows 11 and DISA STIG baselines rather than
rebuilding them, so it complements those without duplication.

The defining move is **audit before enforce**. NTLM cannot be switched off blind — a domain that still
has an app, scanner, NAS, or line-of-business service relying on NTLM will break if you jump straight to
"Refuse". So this package puts you through Microsoft's **Restrict NTLM: Audit** settings first to
**discover** where NTLM is actually used, gives you a clear read of the breakage surface, and only then
walks you into enforcement in waves. This mirrors **Microsoft's own NTLM-deprecation direction** and a
**Kerberos-first** posture.

This package delivers the complete, field-tested method to stand it up in Intune — written so a single
administrator can follow it end to end:

- **One policy, one purpose.** A named Windows **Settings Catalog** policy — **`NTLM-SMB Hardening -
  Pilot`** — carrying the LAN Manager level, NTLM SSP client/server minimum session security, SMB
  signing (client/server), insecure-guest-logon disable, and unauthenticated-RPC restriction, deployed
  pilot-first.
- **Audit-first, breakage-aware.** A companion **`NTLM Audit - Pilot`** policy turns on NTLM auditing so
  you find dependencies before you refuse them — no blind enforcement.
- **Reversible by design.** Because this is a configuration policy, removing the assignment cleanly
  reverts to pre-hardening behavior — no re-imaging, no enrollment change.

The package follows the standard repeatable shape — **Assess → Configure → Pilot → Validate → Expand** —
with exact, click-by-click Intune steps, a requirements guide that tells you how to verify *and* fix each
prerequisite, five ready-to-run PowerShell scripts (Microsoft Graph), and testing/troubleshooting guides
with clear pass/fail gates.

**Outcome:** LM and NTLMv1 refused, NTLM usage audited then eliminated where safe, SMB signing required
on both ends, insecure guest logons and unauthenticated RPC shut down — a materially smaller
credential-theft and relay surface across your Windows fleet, proven on a pilot before you scale.
