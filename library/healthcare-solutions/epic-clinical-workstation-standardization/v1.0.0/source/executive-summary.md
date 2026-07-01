# Executive Summary — Epic Clinical Workstation Standardization & Peripheral Configuration with Microsoft Intune

## The problem

Clinical Windows workstations that run Epic — nurse stations, exam-room PCs, medication-room and registration desks — drift apart over time. Each was imaged at a different point, joined by a different technician, and hand-configured with whatever printers and peripherals were near it that day. The result is a fleet where the same Epic workflow behaves differently from one room to the next: a wristband prints to the wrong tray, a script routes to a document printer three doors down, a signature pad is unrecognised at registration, and the workstation a float nurse sits at logs them out before they finish charting. Every inconsistency becomes a help-desk ticket, and in a clinical setting every ticket is a delay at the point of care.

This solution removes that drift. It defines a single, repeatable device baseline for clinical workstations and delivers it entirely through Microsoft Intune — configuration profiles, the settings catalog, power and display behaviour, and a documented reference to the organisation's Windows security baseline. On top of that baseline it builds the **clinical peripheral and printing layer** that Epic workflows depend on: context-aware printer deployment for wristband and label printers, prescription/script printers, and document printers; a correct **default printer per unit or department**; and the supporting peripherals — scanners, signature pads, and badge/proximity readers — installed and validated the same way on every device.

## The approach

The work follows a disciplined, six-phase model — **Assess → Standardize → Deploy Peripherals/Printing → Pilot → Validate → Expand** — so that nothing reaches a live clinical floor before it has been proven on a pilot group. Devices are governed through a single Entra ID group, `EPIC – Clinical Workstations`, and every configuration profile, printer-deployment policy, and printer queue is named to a fixed convention so the fleet is self-documenting. Printer delivery is deliberate about the trade-off between **Universal Print** (cloud-native, no print server, requires the documented licensing and a registered printer or connector) and **scripted printer installation** (works with existing print servers and direct-IP queues), and the solution explains exactly when each applies.

Epic-internal values — the Epic Print Service / EPS configuration, queue names, and workflow-specific print settings — are owned by the customer's Epic Technical Services team and sourced from Epic UserWeb. This solution does not invent those values; it provides the standardization, deployment, and validation mechanics that carry them onto every workstation correctly and prove they landed.

## What you get

A complete, white-label implementation package: a solution overview, a no-assumptions requirements specification (with a category-wide global-requirements companion), a step-by-step implementation guide with full Intune navigation paths, a testing and validation plan, a best-practices reference, a troubleshooting guide, and a deliverables summary. Five production-ready PowerShell scripts handle discovery, per-device validation, fleet reporting, safe remediation, and printer-deployment mapping — all read-only or `-WhatIf` by default, so nothing changes in a clinical environment without an explicit, deliberate action.

## The outcome

Every clinical workstation presents the same Epic environment: the same baseline, the same printers in the same order, the right default printer for the room, and working peripherals — verified, repeatable, and expandable unit by unit across the organisation.
