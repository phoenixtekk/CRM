# 1. Solution Overview — Remote Desktop (RDP) Security Hardening for Windows Endpoints (Intune)

## What this solution is
This solution deploys a single, named **Microsoft Intune Settings Catalog** configuration profile
that **hardens the Remote Desktop Protocol (RDP)** on **Windows 10/11 endpoints**. It configures the
Windows **Remote Desktop Session Host (RDSH)** security settings, the **Remote Desktop Connection
Client** behavior, and **Remote Assistance** — the group of settings that vulnerability assessments,
CIS Benchmarks, and DISA STIGs repeatedly flag on ordinary workstations because Windows ships them at
insecure defaults.

The profile is built entirely from the Settings Catalog's **Administrative Templates** surface (the
same ADMX-backed settings you would see in Group Policy), so every setting maps to a well-known
registry value you can verify on the device. It is deployed **pilot-first** and is **reversible** by
unassigning it.

> **Scope, stated plainly.** This hardens the **endpoint** in both roles it can play in an RDP
> session: as a **host** (a machine that *accepts* incoming RDP — the RDSH settings) and as a
> **client** (a machine that *initiates* outbound RDP — saved-password and credential-delegation
> behavior). It is **not** a network or gateway control — no **RD Gateway**, no firewall/NSG rules,
> no VPN, no Just-in-Time VM access. The full **credential-theft** defense (Restricted Admin / Remote
> Credential Guard as a complete anti-lateral-movement program) is **cross-referenced** to the
> companion credential-theft hardening solution; this product points at the setting and explains its
> role, but the credential side is owned there to avoid duplication.

## Why RDP defaults are an assessment finding
Every Windows device can host or initiate RDP, and the out-of-box settings are permissive:

- **Encryption is negotiable down to weak levels.** Unless forced to **High (128-bit)**, an RDP host
  may accept a lower-strength session with a legacy client.
- **The host may not prompt for a password.** With saved or passed credentials, a session can start
  without an explicit password challenge.
- **Local drives are redirected into the session by default.** That is a data-movement and malware
  path between the client and the remote host.
- **Passwords can be saved in the RDP client.** A saved credential on a shared or stolen device is a
  standing risk.
- **Solicited Remote Assistance is available.** It lets a remote helper take control after a user
  invitation — useful, but an attack surface that most environments should disable.

Individually minor; together they are the classic "RDP is wide open" cluster that shows up on nearly
every Windows-client assessment.

## What this profile configures (the five findings + defense-in-depth)
Each setting below is presented by its **Administrative Templates** name (as it appears in the
Settings Catalog) and the **registry value** it sets, so you can verify it on the device. Exact
Settings Catalog wording is flagged **verify in your tenant** because Microsoft occasionally revises
category labels.

**The five recurring findings:**

1. **Set client connection encryption level = High Level** → `MinEncryptionLevel = 3` (128-bit).
   *Category:* Windows Components → Remote Desktop Services → Remote Desktop Session Host → **Security**.
2. **Always prompt for password upon connection = Enabled** → `fPromptForPassword = 1`.
   *Category:* …Remote Desktop Session Host → **Security**.
3. **Do not allow drive redirection = Enabled** → `fDisableCdm = 1`.
   *Category:* …Remote Desktop Session Host → **Device and Resource Redirection**.
4. **Do not allow passwords to be saved = Enabled** → `DisablePasswordSaving = 1`.
   *Category:* Windows Components → Remote Desktop Services → **Remote Desktop Connection Client**.
5. **Configure Solicited Remote Assistance = Disabled** → `fAllowToGetHelp = 0`; and **Configure
   Offer Remote Assistance = Disabled** → `fAllowUnsolicited = 0`.
   *Category:* System → **Remote Assistance**.

**Defense-in-depth carried in the same profile / cross-referenced:**

6. **Require user authentication for remote connections by using Network Level Authentication (NLA)
   = Enabled** → `UserAuthentication = 1`. NLA forces authentication *before* a full session is
   established, blunting pre-auth attacks on the RDSH.
7. **Restricted Admin / Remote Credential Guard for outbound RDP** — the *client*-side
   credential-delegation setting **Restrict delegation of credentials to remote servers**
   (`RestrictedRemoteAdministration`). This protects credentials when *this* device connects out to
   another host. It is the natural companion to endpoint RDP hardening but belongs to the
   **credential-theft hardening solution** — see the cross-reference note in Implementation. Enabling
   it has application-compatibility implications (single-sign-on to the remote host changes), so treat
   it as a deliberate, separately-piloted decision.
8. **Limit who can log on via RDP** — restrict the **Allow log on through Remote Desktop Services**
   user right (`SeRemoteInteractiveLogonRight`) to a controlled group rather than the broad default.
   This solution tells you where and how; the exact user-right surface in the Settings Catalog is
   flagged **verify in your tenant**.

## The one breaking change to respect
Forcing **High / 128-bit** encryption (`MinEncryptionLevel = 3`) means the RDP host will **refuse**
any client that cannot negotiate a 128-bit session — genuinely legacy or embedded RDP clients.
Modern Windows, macOS, and the current Microsoft Remote Desktop clients all negotiate 128-bit, so the
practical blast radius is small, **but it is real** — which is exactly why the whole package is
**pilot-first** with an explicit legacy-client test (Testing, Test 5) before you expand.

## How it works, step by step
1. **Assess** the environment: confirm which endpoints host or initiate RDP, and identify any legacy
   RDP clients before you force High encryption.
2. **Configure** one named Settings Catalog profile — **`RDP Hardening - Pilot`** — carrying the five
   findings plus NLA.
3. **Pilot** the profile against a small **pilot group** of Windows devices.
4. **Validate** with the included Microsoft Graph scripts (present, assigned, applied) and an on-device
   RDP connection test (including a legacy-client negative test).
5. **Expand** in waves once the pilot passes, or promote the profile to the standard Windows RDP
   hardening baseline.

## Benefits
- **Resolves ~5 assessment findings at once** — encryption, password prompt, drive redirection, saved
  passwords, and Remote Assistance, in one profile.
- **Maps to registry values you can verify** — every setting is an ADMX-backed value with a known
  registry anchor, so "did it apply?" has a definitive answer.
- **Complements CIS / STIG baselines** — a focused, explainable RDP overlay rather than a whole
  benchmark, so you can layer it cleanly.
- **Reversible and low-risk** — deploys a configuration profile only; unassigning it reverts behavior
  with no re-imaging or re-enrollment.
- **Pilot-first by design** — the one breaking change (High encryption vs legacy clients) is caught in
  the pilot, not in production.

## Limitations (be honest with buyers)
- **Endpoint-side, not network-side.** This does not deploy RD Gateway, firewall rules, VPN, or JIT VM
  access. Pair it with your network controls.
- **High encryption denies sub-128-bit legacy clients.** Verified modern clients are fine; genuinely
  old/embedded clients may be refused — test first.
- **Credential-delegation is cross-referenced, not owned here.** Restricted Admin / Remote Credential
  Guard is called out and explained, but its full deployment lives in the credential-theft hardening
  solution.
- **ADMX category wording can change.** The Settings Catalog labels reflect current Microsoft docs —
  **verify them in your tenant**; the registry anchors are the stable source of truth.
- **Servers vs workstations.** This targets managed **Windows 10/11 client** endpoints via Intune; RDSH
  session hosts on Windows Server are configured with the same settings but managed differently and are
  out of scope here.

## The standard deployment model
This solution uses **one** repeatable model across our catalog:

> **Managed Windows 10/11 endpoints receive a single named Settings Catalog profile that hardens RDP —
> High encryption, forced password prompt, no drive redirection, no saved passwords, Remote Assistance
> disabled, and NLA required — deployed pilot-first and reversible.**

Every step follows the repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**
