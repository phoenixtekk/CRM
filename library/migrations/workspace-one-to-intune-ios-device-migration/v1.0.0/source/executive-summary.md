# Executive Summary — Workspace ONE to Intune iOS/iPadOS Device Migration

Apple devices are the trickiest part of any Workspace ONE exit. Supervised, ADE-enrolled iPhones and iPads are
bound in Apple Business Manager to whatever MDM server they were set up with, and that binding only changes when an
administrator re-assigns the device in Apple Business Manager and the device re-enrolls through Setup Assistant —
which, for a supervised device, almost always means a wipe-and-re-enroll. Done ad hoc, that is how a migration
turns into a fleet of bricked, half-managed devices and a flood of tickets.

This is the repeatable way to migrate iPhones and iPads from Workspace ONE to Microsoft Intune: connect Apple
Business Manager to Intune, build Intune enrollment profiles and app/profile parity, re-assign devices in Apple
Business Manager from the Workspace ONE MDM server to Intune, re-enroll supervised by ring, and cut over with clear
user communications and a rollback path — proven on a pilot before the fleet.

It is written for an administrator with no prior Apple migration experience, and it is deliberately white-label:
Workspace ONE internals are deferred to the source vendor's documentation, while the Intune and Apple Business
Manager side is covered with exact navigation.

## What you get
- A plain-language Solution Overview of the Apple migration model and why supervised devices must be re-assigned and re-enrolled.
- A Requirements Guide with verify / implement-if-missing for every prerequisite (APNs, ABM/ADE, VPP, parity, rings, rollback).
- An Implementation Guide of precise, ordered steps in Intune and Apple Business Manager, with every artifact named.
- Five PowerShell scripts for readiness discovery, per-device validation, migration reporting, safe remediation, and ring-group targeting.
- Testing and Troubleshooting guides for confident rollout.

## What this delivers
A ringed iOS/iPadOS migration — Apple Business Manager MDM-server re-assignment, supervised ADE re-enrollment,
rebuilt app and configuration parity, and a pilot-gated cutover with user comms and a rollback to the source.

## The deployment model
**Assess to Configure to Pilot to Validate to Expand.**

## Outcome
iPhones and iPads moved cleanly from Workspace ONE to Intune — re-assigned in Apple Business Manager, re-enrolled
supervised with app and profile parity, cut over by ring with clear comms, and validated on a pilot before you scale.
