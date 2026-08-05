# Executive Summary — Remote Desktop (RDP) Security Hardening for Windows Endpoints (Intune)

Remote Desktop (RDP) is enabled far more widely than most organizations realize, and it ships with
defaults that assessments flag every time: weak connection encryption, no forced password prompt,
open drive redirection, saved-password convenience, and Solicited Remote Assistance left on. Each is
a small door left ajar on every Windows endpoint that can host or initiate an RDP session — and
together they are a favorite path for lateral movement and credential exposure. This solution closes
those doors with a single, named **Intune Settings Catalog** configuration profile, deployed
**pilot-first** and fully reversible.

**A deliberately scoped, distinct capability.** This is **endpoint-side RDP hardening** for Windows
10/11 devices managed by Intune — it hardens the machine acting as an RDP **host** and, where it
initiates outbound RDP, as an RDP **client**. It configures the Remote Desktop Session Host security
settings, client-side connection behavior, and Remote Assistance via the Settings Catalog's
**Administrative Templates** surface. It is **not** a network/gateway control (no RD Gateway, no
firewall rules, no VPN), and the deep **credential-delegation** side (Restricted Admin / Remote
Credential Guard as a full credential-theft defense) is cross-referenced to the companion
credential-theft hardening solution rather than duplicated here.

This package resolves roughly **five recurring Windows-client assessment findings** in one profile:

- **Client connection encryption level = High (128-bit)** — `MinEncryptionLevel = 3`.
- **Always prompt for password upon connection** — `fPromptForPassword = 1`.
- **Do not allow drive redirection** — `fDisableCdm = 1`.
- **Do not allow passwords to be saved** — `DisablePasswordSaving = 1`.
- **Solicited Remote Assistance = Disabled** — `fAllowToGetHelp = 0` (with Offer Remote Assistance
  disabled alongside).

Plus defense-in-depth the same profile carries: **require Network Level Authentication (NLA)**
(`UserAuthentication = 1`), a pointer to **Restricted Admin / Remote Credential Guard** for outbound
RDP, and guidance to **limit who may log on via RDP**.

This package delivers the complete, field-tested method to stand it up in Intune — written so a
single administrator can follow it end to end:

- **One profile, one purpose.** A named **`RDP Hardening - Pilot`** Settings Catalog profile carrying
  the five findings plus NLA, deployed to a pilot group before the fleet.
- **Honest about the one breaking change.** High/128-bit encryption **refuses** legacy clients that
  cannot negotiate 128-bit RDP — which is exactly why this is piloted first, with a clear test for
  legacy-client impact before you expand.
- **Reversible by design.** It only adds a configuration profile; unassigning it cleanly reverts the
  endpoints to their prior RDP behavior — no re-imaging, no re-enrollment.

The package follows the standard repeatable shape — **Assess → Configure → Pilot → Validate →
Expand** — with exact, click-by-click Intune steps, a requirements guide that tells you how to verify
*and* fix each prerequisite, five ready-to-run PowerShell scripts (Microsoft Graph), and
testing/troubleshooting guides with clear pass/fail gates.

**Outcome:** every managed Windows endpoint enforces hardened RDP — strong encryption, forced
password prompts, no drive redirection, no saved passwords, and Remote Assistance closed —
complementing CIS and DISA STIG baselines and proven on a pilot before you scale, without a
consulting engagement.
