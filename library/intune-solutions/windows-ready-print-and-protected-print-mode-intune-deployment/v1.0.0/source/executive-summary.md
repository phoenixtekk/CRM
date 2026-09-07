# Executive Summary

## The situation
Windows printing is changing. Microsoft's modern, **driverless** print platform — **Windows Ready Print**
— replaces vendor V3/V4 printer drivers with open standards (**IPP, Mopria, eSCL, Universal Print**), and
its hardened form, **Windows Protected Print mode (WPP)** on Windows 11 24H2, forces the PC to print
**only** through that platform and **blocks third-party drivers**. Microsoft has also announced
**end-of-servicing for legacy third-party drivers** — this is the strategic direction, not an optional
feature.

## Why it matters
Third-party print drivers and Point-and-Print are the attack surface behind the PrintNightmare class of
Windows Print Spooler vulnerabilities. WPP closes that surface and removes a recurring source of
Windows-Update breakage. But **enabling WPP removes incompatible printers and their drivers** — so done
blindly, fleet-wide, it breaks printing and scanning in production. Done right, it's a clean security and
reliability win that gets you ahead of Microsoft's driver retirement.

## The approach
This solution deploys and hardens Windows Ready Print through Intune, safely:

1. **Assess** — inventory every driver and printer; classify each as **Ready-Print eligible**, **needs
   Universal Print**, or **blocker** (non-Mopria, legacy software printer, eSCL-less scanner).
2. **Design** the target path — direct **IPP/Mopria** and/or **Universal Print** — and set the WPP scope.
3. **Configure** the Intune **Custom OMA-URI** profile (`ConfigureWindowsProtectedPrint = <enabled/>`),
   scoped to 24H2+ devices.
4. **Pilot and validate** — confirm WPP is on, printing works via the IPP class driver, and only the
   planned printers were removed.
5. **Migrate** off legacy print servers/Point-and-Print to the modern path.
6. **Roll out in rings**, keep non-compliant devices as tracked exceptions, and **prevent regression**.

## What you get
- A click-by-click **deployment runbook** (assessment → configure → pilot → migrate → roll out).
- **Five PowerShell tools** — driver inventory, Mopria/IPP readiness, scan (eSCL) readiness, WPP-state
  check, and post-deployment validation.
- **Testing, Troubleshooting, and Best-Practice** guidance, with GCC High notes inline.

## The outcome
A hardened, driverless print estate on Windows 11: reduced attack surface, fewer update-driven print
outages, and alignment with Microsoft's direction — deployed on evidence, with the printers WPP would
remove found **before** it removes them. One fixed price; re-run the assessment and validation as the
fleet and printer estate evolve.
