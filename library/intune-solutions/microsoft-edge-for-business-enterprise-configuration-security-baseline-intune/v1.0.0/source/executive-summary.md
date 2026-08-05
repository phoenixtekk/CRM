# Executive Summary — Microsoft Edge for Business: Enterprise Configuration & Security Baseline (Intune)

Most organizations deploy Microsoft Edge and then leave it at its out-of-the-box defaults: the
built-in password manager is on and quietly competing with the corporate password vault, browser
SmartScreen and PUA protection are unmanaged, extensions install freely, sync and sign-in are
uncontrolled, and there is no Enterprise Mode Site List so legacy line-of-business web apps limp along
in a modern engine. Security assessments repeatedly surface two of these as explicit findings — the
**Edge password manager is enabled** and **Edge is not enforced as the primary browser** — but the real
exposure is broader: an unmanaged browser is the single most-used piece of software on every endpoint.

This solution turns Microsoft Edge into a **managed, hardened, standardized browser** across the Windows
fleet using **Microsoft Intune** — the **Settings Catalog → Microsoft Edge (ADMX-backed)** policies for
configuration and the **Microsoft Edge security baseline** in **Endpoint security** for the hardening
floor. It is delivered so a single administrator can follow it end to end.

**What it does, concretely:**

- **Makes Edge the default browser org-wide** via Intune (a Windows default-associations configuration),
  and configures **IE mode** with an **Enterprise Mode Site List** so legacy IE-dependent line-of-business
  apps keep working inside Edge — no second browser, no compatibility limbo.
- **Turns off the built-in password manager** (`PasswordManagerEnabled` = **Disabled**) so users are
  steered to the enterprise password solution instead of scattering credentials in the browser.
- **Applies a pragmatic security/config baseline** — SmartScreen + PUA protection on, an extension
  allow/block model that controls sideloading, sync and work-profile sign-in controls, website
  typo-protection (typosquatting), a defined update channel and cadence, and managed startup/home pages —
  then layers the **Microsoft Edge security baseline** on top as the enforced hardening floor.

Every object you create is **named once and reused** — the pilot baseline profile is
`Edge for Business - Baseline - Pilot`, assigned to the `Edge for Business - Pilot Devices` group — so
the same names carry through implementation, testing, and troubleshooting.

The package follows the standard repeatable shape — **Assess → Configure → Pilot → Validate → Expand** —
with exact, click-by-click Intune steps, a requirements guide that tells you how to **verify** *and*
**fix** each prerequisite, five ready-to-run PowerShell scripts (Microsoft Graph), and testing and
troubleshooting guides with clear pass/fail gates. Read-only discovery, validation, and reporting scripts
tell you where you stand; the remediation and targeting scripts **default to a safe preview** and change
nothing until you re-run them to apply.

**Outcome:** a browser that is default, standardized, and hardened on every Windows endpoint — the two
assessment findings resolved directly, the broader browser attack surface reduced, and legacy web apps
kept alive through IE mode — proven on a pilot before you scale, without a consulting engagement.
