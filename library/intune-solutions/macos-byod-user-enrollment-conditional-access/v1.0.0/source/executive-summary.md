# Executive Summary — macOS BYOD Management: Account-Driven User Enrollment, App Protection & Conditional Access

Your people use their **own** Macs to reach company email, files, and apps. You need that data
protected — but you don't own the device, and heavy-handed management will (rightly) be rejected. This
solution builds a **macOS BYOD strategy** in **Microsoft Intune** and **Microsoft Entra ID** that gets
the balance right: **the lightest management footprint that still protects data, and an access gate that
turns away anything unmanaged or unhealthy.**

It is written so a single administrator can follow it end to end:

- **Right-sized enrollment.** We standardize on Apple's **account-driven user enrollment** — the user
  signs in with their Entra ID and macOS creates a **managed Apple Account** and an **isolated managed
  volume**. Corporate apps and data are protected there; the user's personal apps, data, and Apple ID are
  never touched. We also document the two alternatives (full **device enrollment**, and **unmanaged +
  Conditional Access**) so you choose the model deliberately.
- **Access gated on device health.** A named **Conditional Access** policy —
  `CA - Require Compliant Mac - Pilot` — allows Microsoft 365 access only from a **compliant, enrolled**
  Mac, and blocks the rest. Deployed **report-only first**, with break-glass accounts excluded, so no
  one gets locked out.
- **An honest app-protection model.** The most expensive mistake in macOS BYOD is assuming Intune **App
  Protection Policies (MAM)** work like they do on iOS/Android. **They do not** — there is no iOS-style
  per-app container for arbitrary Mac apps. On macOS, corporate-data protection comes from **MDM scope +
  compliance + Conditional Access**. We state this plainly and build the protection the way macOS
  actually supports it.

The package follows the standard repeatable shape — **Assess → Configure → Pilot → Validate → Expand** —
with exact, click-by-click Intune and Entra steps, a requirements guide that tells you how to verify
*and* fix each prerequisite, five ready-to-run PowerShell scripts (Microsoft Graph; discovery/validation/
report are read-only, remediation/scope-targeting default to `-WhatIf`), and testing/troubleshooting
guides with clear pass/fail gates.

**Outcome:** company data protected on personal Macs — the right enrollment model and a Conditional
Access gate, without over-managing the user's device — proven on a pilot before you scale, delivered by
your own team without a consulting engagement.
