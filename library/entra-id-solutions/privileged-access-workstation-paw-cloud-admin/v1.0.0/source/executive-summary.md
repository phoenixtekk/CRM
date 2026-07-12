# Executive Summary — Privileged Access Workstation (PAW) for Cloud Administration

White-label · Entra ID Solutions

The fastest way to lose a tenant is to let an administrator read email and browse the web on the same
device they use to administer the cloud. One phishing link or one drive-by on that device, and the
attacker is one token-theft away from Global Administrator. A Privileged Access Workstation (PAW)
breaks that chain: administration happens only from a dedicated, hardened, Intune-managed Windows
device that cannot read email or browse the open web — and Conditional Access refuses privileged
sign-ins from anything else.

This solution delivers the whole PAW model end to end. It builds the hardened device (security
baselines, Attack Surface Reduction, application control, and web/email isolation), it marks those
devices so Conditional Access can recognise them, it enforces via **Conditional Access device
filters** that privileged roles can sign in **only** from a compliant PAW, and it integrates
**Privileged Identity Management (PIM)** so admin rights are activated just-in-time *from the clean
device*. Every enforcement step is piloted before it blocks anyone, and break-glass emergency accounts
are kept safe throughout.

This is a complete, deploy-it-today package written for an administrator with no prior PAW experience.
It is the device-and-enforcement layer of a privileged-access program; it references — and does not
re-teach — PIM, the Conditional Access baseline, and Intune endpoint security, which it builds on.

## What you get
- A plain-language Solution Overview of the PAW model: what a PAW is, how hardening, isolation, device filters, and PIM fit together, and the clean-source principle behind it.
- A Requirements Guide with verify / implement-if-missing for every solution-specific prerequisite (Intune, Entra ID P2 for PIM/device filters — flagged to verify).
- An Implementation Guide of precise, ordered steps to build the PAW, mark it, enforce with Conditional Access device filters (report-only first), and wire PIM — with break-glass kept safe.
- Five PowerShell scripts (Microsoft Graph / Az) plus KQL for discovery, pilot validation, a privileged-access-from-non-PAW report, a safe Conditional Access state flip, and PAW device tagging.
- Testing and Troubleshooting guides for a confident rollout.

## What this delivers
A clean administrative plane: admins operate from hardened, isolated, Intune-managed PAWs; Conditional
Access device filters make privileged sign-in impossible from a general-purpose or compromised device;
and PIM grants admin rights just-in-time, only from the PAW. Break-glass emergency accounts are
excluded from the enforcement policy so a device-filter mistake can never lock every administrator
out.

## The standard deployment model
Assess -> Configure -> Pilot -> Validate -> Expand.

## Outcome
Administrators working from clean, isolated, hardened workstations — with privileged access
impossible from a general-purpose or compromised device — proven on a pilot before you enforce.
