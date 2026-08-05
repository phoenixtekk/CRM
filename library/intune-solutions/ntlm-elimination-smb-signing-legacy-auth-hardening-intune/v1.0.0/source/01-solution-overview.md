# 1. Solution Overview — NTLM Elimination & SMB Signing (Legacy Authentication Hardening)

## What this solution is
This solution **hardens the Windows authentication stack** on **Windows 10/11 endpoints** managed by
**Microsoft Intune**. Using a **Settings Catalog** configuration policy, it refuses the weakest NTLM
responses (LM and NTLMv1), enforces strong NTLM session security where NTLM is still used, requires
**SMB signing** on both client and server, disables **insecure guest logons**, and restricts
**unauthenticated RPC** — the legacy-authentication settings attackers rely on for credential theft,
NTLM relay, and lateral movement.

Crucially, it deploys **audit-first**. NTLM is still woven through many environments (legacy apps, NAS
appliances, scanners/MFPs, line-of-business services). Switching it off blind causes outages. So this
package first turns on Microsoft's **Restrict NTLM: Audit** settings to **discover where NTLM is
actually used**, then walks you into enforcement in waves once the breakage surface is understood.

> **Scope, stated plainly.** This solution delivers a **focused NTLM-elimination + SMB-signing**
> hardening policy for **Intune-managed Windows 10/11** endpoints. It resolves roughly **seven** common
> Windows Client assessment findings (below). It is **not** a full security baseline — it deliberately
> **cross-references** the CIS Windows 11 and DISA STIG solutions rather than rebuilding them. It does
> **not** cover domain-controller-side NTLM policy, Kerberos infrastructure design, or Credential Guard
> (adjacent, separate topics called out where relevant).

## Why this matters (the threat this closes)
- **LM / NTLMv1 responses** are cryptographically weak and trivially cracked or relayed. A domain that
  still *sends* LM/NTLMv1 hands attackers an easy credential path.
- **NTLM relay** — an attacker relays a coerced NTLM authentication to another service. **SMB signing**
  on both ends defeats SMB relay by making tampered/relayed sessions fail integrity checks.
- **Insecure guest logons** let a client fall back to unauthenticated SMB access to a rogue share — a
  known data-exfiltration and malware-delivery vector.
- **Unauthenticated RPC** widens the remote attack surface for the RPC runtime.
- **Microsoft's direction is NTLM deprecation and Kerberos-first.** Hardening now aligns the fleet with
  where Windows is going and shrinks the attack surface today.

## The findings this resolves (~7)
This product is built to clear these recurring Windows Client assessment findings:

1. **LAN Manager authentication level** too permissive → set to *Send NTLMv2 responses only. Refuse LM &
   NTLM* (`LmCompatibilityLevel = 5`).
2. **NTLM SSP minimum session security — clients** weak → *Require NTLMv2 session security* + *Require
   128-bit encryption* (`NtlmMinClientSec = 0x20080000`).
3. **NTLM SSP minimum session security — servers** weak → same two requirements
   (`NtlmMinServerSec = 0x20080000`).
4. **SMB signing — client** not required → *Microsoft network client: Digitally sign communications
   (always) = Enabled*.
5. **SMB signing — server** not required → *Microsoft network server: Digitally sign communications
   (always) = Enabled* (`RequireSecuritySignature`).
6. **Insecure guest logons** allowed → *Enable insecure guest logons = Disabled*
   (`AllowInsecureGuestAuth = 0`).
7. **Unauthenticated RPC clients** not restricted → *Restrict Unauthenticated RPC clients = Authenticated*
   (`RestrictRemoteClients = 1`).

Plus the enabling control: **Restrict NTLM: Audit** (in-domain + outgoing) so dependencies are found
before NTLM is refused.

## Where these settings live in Intune (Settings Catalog)
All settings are delivered through **Devices → Configuration → Settings Catalog** (platform **Windows
10 and later**). They come from three catalog areas backed by the
**LocalPoliciesSecurityOptions** and **ADMX-backed** CSP nodes:

- **Local Policies\Security Options** — LAN Manager authentication level; NTLM SSP minimum session
  security (client/server); SMB "Digitally sign communications (always)" for client and server; and the
  **Restrict NTLM: Audit** settings.
- **Administrative Templates → Network → Lanman Workstation** — *Enable insecure guest logons* =
  **Disabled**.
- **Administrative Templates → System → Remote Procedure Call** — *Restrict Unauthenticated RPC clients*
  = **Enabled → Authenticated**.

> **Verify exact catalog display strings in your tenant.** The Settings Catalog search box surfaces
> these by name (e.g. type *"LAN Manager authentication level"* or *"digitally sign communications"*).
> Microsoft occasionally revises the exact display text and CSP node casing; the **underlying registry
> values** (`LmCompatibilityLevel`, `NtlmMinClientSec`/`NtlmMinServerSec`, `RequireSecuritySignature`,
> `AllowInsecureGuestAuth`, `RestrictRemoteClients`) are the stable identity of each control — confirm
> the display string maps to the intended value before you enforce.

## How it works, step by step
1. **Assess.** Run `NTLMHARD-Discovery.ps1` to inventory the current posture across the tenant and
   confirm the device baseline; decide the pilot group.
2. **Audit NTLM.** Deploy the **`NTLM Audit - Pilot`** Settings Catalog policy (Restrict NTLM: *Audit*
   in-domain and outgoing). Let it run and collect the NTLM operational event logs to find every app,
   appliance, and service still using NTLM.
3. **Configure enforcement.** Build the **`NTLM-SMB Hardening - Pilot`** Settings Catalog policy with the
   seven settings above.
4. **Pilot.** Assign to the pilot group; validate that endpoints still reach shares, apps, and services
   and that SMB/NTLM behavior is correct.
5. **Validate & expand.** Confirm with `NTLMHARD-Validation.ps1` / `NTLMHARD-Report.ps1`, remediate gaps
   with `NTLMHARD-Remediation.ps1` (safe preview), then widen in waves.

## Benefits
- **Real attack-surface reduction** — refuses LM/NTLMv1, defeats SMB relay with signing, closes guest
  logons and unauthenticated RPC.
- **No blind breakage** — audit-first finds NTLM dependencies before you refuse them.
- **Focused and de-duplicated** — resolves the specific legacy-auth findings without re-shipping a whole
  CIS/STIG baseline.
- **Reversible** — a configuration policy only; unassign to revert. No re-imaging, no enrollment change.
- **Aligned with Microsoft's roadmap** — NTLM deprecation / Kerberos-first.

## Limitations (be honest with buyers)
- **Windows 10/11, Intune-managed, Pro/Enterprise/Education.** Some Local Security Options controls are
  not available on Home/Core editions.
- **NTLM elimination requires diligence.** If audit reveals a hard NTLM dependency you cannot yet remove
  (e.g. a legacy NAS), you may need to keep that service on Kerberos or replace it before refusing NTLM
  fleet-wide — the audit phase exists precisely to surface this.
- **Endpoint-scope only.** This hardens the **client/member** side. Domain-controller NTLM audit/block
  policy and Kerberos infrastructure are adjacent and out of scope.
- **Exact Settings Catalog strings can change.** Identifiers reflect current Microsoft documentation —
  **verify them in your tenant** before fleet rollout rather than assuming.

## The standard deployment model
This solution uses **one** repeatable model across our catalog:

> **Intune-managed Windows 10/11 endpoints receive a Settings Catalog policy that audits NTLM first,
> then refuses LM/NTLMv1, enforces strong NTLM session security and SMB signing on both ends, and closes
> insecure guest logons and unauthenticated RPC — deployed pilot-first and reversible.**

Every step follows the repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**
