# Executive Summary

## The problem

Application deployment is where Intune most often fails visibly. A required Win32 app stalls at
"Waiting for install status," reports "Not applicable," or fails with a raw error code — and the team
cannot tell whether the cause is a requirement rule, a detection rule, a dependency, a supersedence
chain, a download problem, the installer's own exit code, or the Enrollment Status Page. The usual
response — retry, re-sync, re-create the app — burns hours, blocks users at first sign-on, and never
identifies the real cause, so the failure returns.

## The solution

This is a **root-cause method plus tooling** for Intune app deployment failures across Win32, LOB,
and Store apps. It models every install as an ordered **pipeline** (assign → requirement → download →
install → detection → report), provides a **symptom-driven diagnostic tree** that maps each observed
symptom to the exact pipeline stage that owns it, and shows precisely where to read the
**Intune Management Extension logs** for the definitive evidence at each stage. Five PowerShell
scripts read the pipeline state directly from Microsoft Graph and make safe, gated fixes.

## What you get

- A **pipeline model** and diagnostic method that turns a vague "install failed" into a named stage
  and a known cause.
- A **Diagnostic Playbook** covering the six failure branches — requirement not met, detection wrong,
  dependency/supersedence, download failure, exit-code decode, and ESP block — with exact checks and
  log locations for each.
- **Five PowerShell scripts** — read-only Discovery, Validation, and Report; and gated (**-WhatIf**)
  Remediation and pilot-targeting scripts.
- **Testing gates** (requirement met, installed, detected) that prove a fix, and **Best Practices**
  for detection rules and phased rollout that prevent recurrence.

## Business impact

- **Faster resolution:** failures are traced to their real cause in minutes, not iterated on for
  hours.
- **Fewer blocked users:** ESP failures are diagnosed and cleared so enrollment completes.
- **Lower risk:** all fixes are piloted and validated before fleet rollout; remediation is gated.
- **Retained capability:** the method and scripts stay with your team and are reusable for every
  future app.

## Bottom line

Every failed app install is traced to its real cause — requirement, detection, dependency, download,
exit code, or ESP — and fixed, with a repeatable method and scripts you keep, at a fraction of the
cost of ad-hoc troubleshooting or outside consulting.
