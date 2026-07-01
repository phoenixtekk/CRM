# 1. Solution Overview — Attack Surface Reduction (ASR) Rules

## What ASR rules are
Attack Surface Reduction rules are behavior-based protections in Microsoft Defender that block the
techniques malware commonly uses — regardless of the specific file. Rather than matching a known
signature, each rule stops a *behavior* (for example, "an Office application creating a child
process"). They are managed and reported through Microsoft Intune.

## How rule modes work
Each rule can be set to:
- **Not configured** — the rule is off.
- **Audit** — the rule does **not** block, but logs what it *would* have blocked.
- **Block** — the rule enforces (blocks the behavior).
- **Warn** — blocks but lets the user bypass once.

> **Method:** deploy in **Audit** first, review the events, then move proven rules to **Block** with
> any necessary exclusions. This is how you avoid breaking legitimate apps.

## High-value rules this solution deploys
- Block all Office applications from creating child processes.
- Block credential stealing from the Windows local security authority subsystem (**LSASS**).
- Block executable content from email client and webmail.
- Block execution of potentially obfuscated scripts.
- Block Office applications from injecting code into other processes.
- Block Win32 API calls from Office macros.
- Block process creations originating from PSExec and WMI commands.
- Use advanced protection against ransomware.

## How it works
1. An Intune **ASR policy** sets each chosen rule to Audit or Block.
2. Defender Antivirus (real-time protection) enforces/audits the rules.
3. **Audit events** are logged locally (Defender Operational log) and surfaced in the Defender/ASR reports.
4. You review audit events, add **exclusions** for legitimate apps, then switch rules to **Block**.

## Benefits
- **Behavior-based prevention** — stops whole classes of attack, not just known files.
- **Safe rollout** — Audit mode reveals impact before enforcement.
- **High ROI** — a few rules block the most common malware techniques.
- **Reportable** — audit/block events feed the ASR report and your SOC.

## Limitations (be honest with buyers)
- Requires **Microsoft Defender Antivirus** active (real-time protection on).
- Some rules can affect legitimate apps — **Audit-first + exclusions** are essential.
- Full reporting is richest with **Defender for Endpoint** onboarded.
- Exclusions must be maintained as your app landscape changes.

## The standard Phoenixtekk deployment model
> **Create the ASR policy in Audit → review events → add exclusions → switch to Block → expand.**
> Phoenixtekk pattern: **Assess → Configure → Pilot → Validate → Expand.**
