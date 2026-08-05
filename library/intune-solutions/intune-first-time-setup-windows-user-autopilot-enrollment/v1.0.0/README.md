# Microsoft Intune First-Time Setup for Windows — User & Autopilot Enrollment (Entra-Joined) — v1.0.0

| | |
|---|---|
| Category | Intune Solutions |
| Solution code | INTBASE |
| Model | **Two variants of one solution** (Self-Deploy / We-Deploy) — NOT audience tiers |
| Essentials (Self-Deploy) | **$795.00** — `PTK-INTBASE-ESS-001` — docs only (`INTBASE-Essentials.zip`) |
| Plus (We-Deploy) | **$2,495.00** — `PTK-INTBASE-PLUS-001` — docs + scripts + templates + done-for-you deployment (`INTBASE-Complete-Solution.zip`) |
| Branding | off (white-label) |
| Gov variant | false (US Gov differences documented inline; `intune.microsoft.us` / `USGov`) |

The beginner on-ramp for managing **Windows** with Intune: get your **first Windows devices enrolled two
ways** — **user-driven** (Entra join → auto-enroll) and **basic Windows Autopilot (Entra-ID joined)** —
landing both managed and compliant. Windows only, Entra-joined only, pilot-first.

## Two ways to buy
- **Essentials (Self-Deploy) — $795:** the complete click-by-click documentation, do it yourself.
  Deliverable = `INTBASE-Essentials.zip` (PDF + Word only).
- **Plus (We-Deploy) — $2,495:** docs + 5 PowerShell scripts + 4 config templates **and** a done-for-you
  deployment (after checkout we reach out within one business day to schedule and run the basic Intune
  stand-up + first Windows enrollments). Deliverable = `INTBASE-Complete-Solution.zip`.

## What's included
- 8 source docs (exec summary, overview, requirements, implementation, testing, troubleshooting, best
  practices, deliverables summary) + Intune category global-requirements.
- 5 read-only PowerShell scripts: `INTBASE-Preflight`, `INTBASE-Get-AutopilotHash`,
  `INTBASE-Validate-Enrollment`, `INTBASE-Report-Enrollment`, `INTBASE-Remediation`.
- 4 config templates: Autopilot deployment profile, Enrollment Status Page, Windows enrollment
  restriction, hardware-hash CSV.

## Objects created (named, reused verbatim)
`INTBASE - Windows Users - Pilot` · `INTBASE - Autopilot Devices` (Assigned; owned by the Intune
Provisioning Client, AppId `f1346770-5b25-470b-88bd-d5744ab7952c`) · `INTBASE - Autopilot - Pilot` ·
`INTBASE - ESP - Pilot` · `INTBASE - Windows Enrollment - Pilot` · `INTBASE - Compliance - Windows Pilot`

## Scope boundary
FREE **ITSTART** (enable Intune) → **THIS** (first Windows devices enrolled two ways) → **WAP**
(`windows-autopilot`) / **CFAPG** (`cloud-first-autopilot-zero-touch`) for depth. Out of scope here:
Hybrid Entra join, advanced/multi-profile Autopilot, deep ESP tuning, dynamic-group strategy,
co-management, app packaging, Conditional Access.

## Shaping notes
Deliberate 2-variant (Self-Deploy / We-Deploy) model, not the Commercial/NPO/Gov ladder — the
publish-time price validator must treat `essentials`/`plus` as variants, not tiers (no NPO/GOV price
relationship). Plus's deployment is a manual post-purchase service (modeled on the support add-on
products).

Next: build already done (hero + deliverables). Then `/publish-solution
intune-first-time-setup-windows-user-autopilot-enrollment`.
