# Solution Overview

## What this solution is

A complete, Intune-managed **deployment strategy for Windows Ready Print and Windows Protected Print
mode (WPP)** on Windows 11 — the move from legacy, vendor-driver printing to Microsoft's modern,
driverless print architecture, and then hardening it with Windows Protected Print mode. It takes you
from a **printer/driver compatibility assessment**, through the **Intune configuration**, a **pilot**,
and a **migration off legacy print servers**, to **broad rollout, validation, and prevention of
regression** — with the risk of enabling WPP fleet-wide managed deliberately rather than discovered in
production.

## The two things, and why they're different

| Term | What it is |
|---|---|
| **Windows Ready Print** | Microsoft's modern **driverless** print platform. Windows talks to printers over open standards — **IPP** (Internet Printing Protocol), **Mopria**-certified printing, **eSCL** for scanning, and **Universal Print** for cloud printing — using the built-in **Microsoft IPP Class Driver** instead of a vendor `.INF`/V3/V4 driver package. |
| **Windows Protected Print mode (WPP)** | A **Windows 11 security mode** that forces the PC to use Windows Ready Print **exclusively** and **blocks third-party print drivers** from loading. It's the *hardened* form of the modern platform. |

Windows Ready Print is the platform; **WPP is the switch that enforces it and shuts the door on
third-party drivers** — the attack surface behind PrintNightmare-class Print Spooler and Point-and-Print
vulnerabilities.

## Why Microsoft is moving here (and why it matters to you)

Microsoft has announced an **end-of-servicing strategy for legacy V3/V4 third-party Windows printer
drivers**. Windows Ready Print isn't just another feature — it's Microsoft's **strategic direction** for
Windows printing. The payoff is threefold: **security** (no arbitrary third-party drivers), **reliability**
(Windows Updates are far less likely to break a vendor driver), and **architecture independence** (the
same model works on x64 and ARM). For an Intune-managed fleet, adopting it now is getting ahead of a
transition that is coming regardless.

## The architecture, three ways

```
Legacy
  Print Server -> Point and Print -> Vendor V3/V4 Driver -> Windows Client

Modern
  IPP / Mopria Printer  or  Universal Print -> Windows Ready Print -> Windows Client

Hardened Modern
  IPP / Mopria Printer  or  Universal Print -> Windows Ready Print + Windows Protected Print
      -> Intune-managed Windows 11 Client
```

## What happens when you enable WPP — the part to respect

Enabling Windows Protected Print mode is **not** a silent, cosmetic change. On an enabled device:

- Printers using **unsupported third-party drivers are removed**, and their drivers are **removed from
  the usable driver store**.
- A **Mopria-certified** printer can normally be **reinstalled** via Windows Ready Print (IPP class
  driver) instead.
- **Point and Print can no longer install third-party drivers.**
- **Some legacy "software" printers** (vendor PDF/"print to" utilities) may be removed.
- **Some multifunction scanning may stop working** unless the scanner supports the required
  **Mopria/eSCL** standards.

WPP is a **device-scoped** setting (Computer Configuration) — it affects **every user** on the PC, which
matters for shared/kiosk devices. **This is why WPP is never enabled fleet-wide without a compatibility
assessment first** — that assessment is the heart of this solution.

## How it's delivered through Intune

Microsoft exposes WPP through the **Policy CSP**:

```
./Device/Vendor/MSFT/Policy/Config/Printers/ConfigureWindowsProtectedPrint
```

It applies to **Windows 11 24H2 and later** (Pro, Enterprise, Education, IoT Enterprise) and maps to the
GPO **Computer Configuration → Printers → Configure Windows protected print**, backing the registry value
`WindowsProtectedPrintGroupPolicyState` under
`HKLM\Software\Policies\Microsoft\Windows NT\Printers\WPP`. As of this writing the setting is **not yet in
the Intune Settings Catalog**, so it is deployed with a **Custom OMA-URI** configuration profile — this
guide gives the exact profile.

## The deployment model

**Assess (drivers, printers, Mopria/IPP + scan readiness) → Design the target (Ready Print / Universal
Print; identify blockers) → Configure the Intune Custom OMA-URI profile → Pilot on a ring and validate →
Migrate off legacy print servers → Roll out in rings → Validate and prevent regression.** Every step is
evidence-led, and the included scripts turn compatibility and validation into yes/no answers.

## Benefits

- **Security** — closes the third-party driver / Point-and-Print attack surface on hardened devices.
- **Reliability** — driverless printing that Windows Updates don't break.
- **A safe path** — the compatibility assessment finds what WPP would remove *before* it removes it.
- **Strategic alignment** — ahead of Microsoft's V3/V4 driver end-of-servicing.

## Limitations & scope

- Scope is **deploying and hardening Windows Ready Print / WPP through Intune** on **Windows 11 24H2+**.
  Printer-side enablement (turning on IPP/IPPS, Mopria certification) is vendor-specific and referenced,
  not rebuilt.
- **Sovereign clouds:** the CSP and method are identical in GCC / GCC High / DoD (portal
  `intune.microsoft.us`); **Universal Print availability differs by sovereign cloud** — confirm for yours.
  Called out inline; a single deliverable covers both.
