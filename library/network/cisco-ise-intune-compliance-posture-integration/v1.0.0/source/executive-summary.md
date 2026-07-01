# Executive Summary

## The problem

A device can present a valid network certificate and still be unsafe — unencrypted, unpatched,
jailbroken, or no longer managed. A certificate proves *who* a device is; it says nothing about
whether the device is *healthy*. Networks that authorize on certificates alone are letting
compromised-but-credentialed devices onto VPN and internal segments.

## The solution

This solution wires **Cisco ISE** to **Microsoft Intune** through the **MDM compliance
connection** so that ISE asks Intune, in real time, whether each connecting device is **enrolled
and compliant**, and gates network / VPN access on the answer. Compliance policy becomes
enforced access: compliant devices are granted, non-compliant and unmanaged devices are denied
or quarantined.

ISE authenticates to your Microsoft Entra tenant using a dedicated app registration and reads
device state over Microsoft Graph. This is the posture / NAC layer that turns Intune's
compliance verdict into a network access decision.

## Scope and vendor boundary

The **Intune, Entra, and Microsoft Graph** side is delivered at exact, click-by-click detail:
the app registration ISE uses, the Graph permissions, the named compliance policies, the pilot
scoping, and the pass/fail validation. The **Cisco ISE console** internals (External MDM server
setup and authorization policy editing) are described at the architectural level and **deferred
to Cisco's official documentation** — ISE menus change by release and are followed from the
vendor, not fabricated here.

## How it's deployed

The standard staged model with explicit pass/fail gates:
**Assess → Configure → Pilot → Validate → Expand.** The gate that matters most is proven on the
pilot before any expansion: **compliant devices are granted access; non-compliant devices are
denied.** The change is rollback-ready throughout.

## What you get

Full documentation (Overview, Requirements, Implementation, Testing, Troubleshooting, Best
Practices) plus **five PowerShell scripts** — connector-readiness discovery, per-device
compliance/enrollment validation, a fleet coverage and access-decision report, safe remediation
(default `-WhatIf`), and a pilot-group builder. All scripts are read-only against Microsoft
Graph.

## The bottom line

Network and VPN access granted only to devices Intune says are compliant and enrolled —
enforced by Cisco ISE, and proven on a pilot before you scale. Self-guided, tested, at a
fraction of consulting cost.
