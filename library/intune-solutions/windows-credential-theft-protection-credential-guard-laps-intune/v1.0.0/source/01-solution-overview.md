# 1. Solution Overview — Windows Credential Theft Protection (Credential Guard, LSASS Protection & Windows LAPS)

## What this solution is
This solution hardens **Windows 10/11** endpoints against **credential theft and pass-the-hash /
lateral movement** using **Microsoft Intune** only — no on-premises Group Policy, no third-party agent.
It deploys six coordinated controls, each as a **named, reusable Intune profile** assigned to a single
pilot group, then expanded in waves:

1. **Windows Defender Credential Guard** (VBS + LSA isolation, **UEFI lock**) — profile
   `Credential Guard - Pilot`.
2. **LSASS protection / RunAsPPL** (LSASS as a protected process, **audit-first**) — profile
   `LSASS Protection (RunAsPPL) - Pilot`.
3. **Disable WDigest** (`UseLogonCredential = 0`) — profile `WDigest Disabled - Baseline`.
4. **Restrict credential delegation to remote servers / Remote Credential Guard** — profile
   `Remote Credential Guard - Pilot`.
5. **Disallow WinRM from storing RunAs credentials** (`DisableRunAs = 1`) — profile
   `WinRM No RunAs Credentials - Baseline`.
6. **Windows LAPS** (Entra ID backup, rotation, retrieval of the local-admin password) — profile
   `Windows LAPS - Baseline`.

Together they take **LSASS** — the Local Security Authority Subsystem Service, the process that holds
Windows credentials in memory — off the table as an easy source of reusable secrets, and remove the
static local-admin password that makes one stolen hash a whole-fleet problem.

> **Scope, stated plainly.** This is the **endpoint-side credential-theft defense** for Intune-managed
> Windows 10/11 devices. It is **not** a full CIS/STIG security baseline (see the baseline solutions),
> **not** RDP **host** hardening (Restricted Admin on the target server, NLA, RDP exposure — see the
> **RDP hardening** solution; this package covers only the **outbound**, client-side credential
> protection), and **not** identity-provider or Conditional Access work. Each of those is a separate
> solution and is cross-referenced, not duplicated.

## The attack this stops (why each control exists)
An intruder who gains local admin / SYSTEM on one Windows endpoint typically:

- **Dumps LSASS memory** (Mimikatz, `procdump`, `comsvcs.dll`, etc.) to read **NTLM hashes** and
  **Kerberos tickets**, then replays them (**pass-the-hash / pass-the-ticket**) against other systems.
  → **Credential Guard** moves those secrets into a **VBS-isolated** LSA process (LSAIso) the OS itself
  cannot read; **RunAsPPL** stops the dumper from opening LSASS in the first place.
- **Reads cached plaintext passwords** WDigest left in LSASS. → **WDigest disabled**
  (`UseLogonCredential = 0`) means there is no plaintext to read.
- **Harvests credentials delegated to a jump/RDP host** when an admin connects outbound. → **Remote
  Credential Guard / restricted delegation** keeps the credential on the originating device.
- **Recovers a machine-stored WinRM RunAs credential.** → **WinRM `DisableRunAs = 1`** removes it.
- **Reuses the identical local Administrator password** found on the first box to log into every other
  box. → **Windows LAPS** gives each device a **unique, rotated** local-admin password escrowed in Entra
  ID.

## How the pieces work
### Credential Guard (VBS + LSA isolation)
Credential Guard uses **virtualization-based security (VBS)** to run a trustlet (**LSAIso**) inside a
hardware-isolated environment. Derived credentials (NTLM hashes, Kerberos TGTs) live there instead of in
normal LSASS memory, so even code running as SYSTEM cannot extract them. It requires **TPM 2.0, UEFI
firmware, Secure Boot, and CPU virtualization** and is enabled via Intune's **Device Guard** settings
(or the Endpoint security **Account protection** profile). The **UEFI lock** persists the setting in
firmware so it cannot be silently disabled by malware. On **Windows 11 22H2 and later**, Credential Guard
is **on by default** on eligible, newly-installed devices — this solution makes it **explicit,
enforced, and reported** across the fleet.

### LSASS protection (RunAsPPL / PPL)
Running LSASS as a **Protected Process Light (PPL)** (`RunAsPPL = 1`) means only Microsoft-signed code
can open its process memory, blocking most credential-dumping tools. Because a mis-signed security
plug-in or SmartCard/driver can be incompatible, this is deployed **audit-first**: enable, watch for the
"would-block" events, remediate the offender, then enforce (with UEFI lock).

### WDigest, Remote Credential Guard, WinRM
These are small, well-understood registry/ADMX settings delivered through the Settings Catalog:
`UseLogonCredential = 0` (no plaintext caching), **Restrict delegation of credentials to remote servers →
Require Remote Credential Guard** on outbound RDP, and **Disallow WinRM from storing RunAs credentials**.
Low-risk and reversible.

### Windows LAPS
**Windows LAPS** (built into current Windows, no legacy MSI) rotates the local administrator password on
a schedule and **backs it up to Entra ID**, where an authorized admin retrieves it on demand. It replaces
the anti-pattern of a shared, static local-admin password baked into the image. Deployed through
Endpoint security **Account protection**.

## Benefits
- **Kills the pass-the-hash chain at the endpoint** — VBS isolation + PPL + no plaintext means the first
  compromised box no longer yields reusable fleet-wide credentials.
- **Resolves real assessment findings** — WinRM RunAs storage, unrestricted credential delegation, and
  WDigest plaintext caching are common audit hits this package closes directly.
- **Unique local-admin password per device** — LAPS removes the single most common lateral-movement
  shortcut with Entra-backed retrieval and rotation.
- **Readiness-gated and reversible** — Credential Guard lands only on TPM/UEFI/Secure-Boot-capable
  devices; every control rolls back by unassigning its profile (subject to the UEFI-lock note below).
- **Intune-native** — configuration profiles and Endpoint security policies only; no GPO, no extra agent.

## Limitations (be honest with buyers)
- **Credential Guard has hardware prerequisites.** TPM 2.0, UEFI, Secure Boot, and virtualization are
  required; older or misconfigured firmware won't qualify. The readiness assessment (and
  `CREDGUARD-Discovery.ps1 -LocalReadiness`) finds these before you deploy.
- **VBS can break some legacy drivers/apps.** Kernel-mode drivers that aren't HVCI-compatible, older VPN
  or endpoint agents, or nested-virtualization scenarios may misbehave — hence **pilot-first**.
- **UEFI lock is deliberately sticky.** With the UEFI lock set, disabling Credential Guard is not a
  simple profile-unassign — it requires the documented removal steps (and often physical/console access).
  This is a security feature; the guide covers the trade-off and the without-lock option for pilots.
- **Windows LAPS needs a capable Windows build and the Entra tenant switch enabled** (April 11 2023
  cumulative update or later; Entra local-admin-password feature turned on).
- **This is endpoint hardening, not the whole story.** Domain-side Protected Users, tiered
  administration, and RDP **host** hardening are complementary and out of scope here.
- **Verify identifiers/settings in your tenant.** Setting names and defaults evolve across Windows and
  Intune releases — the guide flags where to confirm rather than assume.

## The standard deployment model
This solution uses **one** repeatable model across our catalog:

> **Assess** device hardware readiness and the current state of each control → **Configure** the six
> named Intune profiles (Credential Guard + LSASS PPL audit-first + WDigest + Remote Credential Guard +
> WinRM + LAPS) → **Pilot** against `Credential Protection - Pilot` → **Validate** with the scripts and
> on-device checks → **Expand** in waves.

Every step follows the repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**
