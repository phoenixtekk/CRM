# Executive Summary — Android Enterprise Enrollment Troubleshooting (Managed Google Play, Web Enrollment & "Can't Add a Google Account")

Android Enterprise enrollment fails in maddening ways: a device won't **add a Google account** to Gmail or
the device, **web / account-driven enrollment** works in a dev tenant but stalls in production, enrollment
breaks **after an AMAPI migration**, or the managed Google Play **binding/connector** errors and apps never
deliver. The cause is rarely where the error appears — it sits one or two layers down. This solution is a
**layered enrollment diagnostic playbook**: a symptom-to-root-cause decision tree that walks the moving
parts in the order that isolates a fault fastest, with the exact check and the exact fix at each node.

This is a complete, deploy-it-today package for turning a recurring class of enrollment tickets into a
repeatable triage, written so an Intune administrator can follow it without prior Android-Enterprise
troubleshooting experience.

## What you get
- A plain-language **Solution Overview** of the enrollment moving parts — managed Google Play binding, the
  enrollment-method path, network endpoints, the identity/account-add flow, dev-vs-prod configuration, and
  AMAPI vs legacy — and the Reproduce → Isolate → Resolve method.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite, on top of the
  category-wide Global Requirements.
- A **Diagnostic Playbook** — a symptom-to-root-cause tree with six nodes (binding, dev-vs-prod, method path,
  endpoints, post-AMAPI, account model), each with exact checks in the Intune admin center, Microsoft Graph,
  device logs, and endpoint reachability, plus a pass/fail gate and a rollback.
- **Five PowerShell (Microsoft Graph) tools**: a read-only enrollment-readiness assessment, a managed-Google-
  Play binding health checker, an endpoint-reachability + dev-vs-prod config-diff helper, a symptom-to-cause
  diagnostic report, and a `-WhatIf`-gated scope-group helper. Read-only by default; no credentials in code.
- **Testing and Troubleshooting** guides with the fix-confirmation gates that tell you a symptom is actually
  resolved before you expand to the fleet.

## What this delivers
A named, repeatable workflow: a `Binding Health – Android – Baseline`, an `Enrollment Readiness – Android –
Assessed`, an `Endpoint Allowlist – Android – Verified`, a `Diagnostic Report – Android – <symptom>`, and a
fix proven on a reproduction device and an `Enrollment Scope – Android – Pilot` group before it touches the
fleet — so devices enroll, Google accounts add, and the ticket class stops recurring.

## The deployment model
Assess to Design to Configure to Pilot to Validate to Expand.

## A note on evolving behavior
The Intune, Graph, managed Google Play, and Google Admin steps are authored from Microsoft's and Google's
public documentation. The **AMAPI transition, web/account-driven enrollment, and whether a change forces
device re-enrollment are actively evolving** — the solution flags every such point to **verify against
current Microsoft guidance / your tenant** rather than asserting a behavior that may change.

## Outcome
Android enrollments that stall — accounts that won't add, dev-works-prod-fails, post-AMAPI breakage —
diagnosed by a repeatable decision tree to root cause and fixed, with fewer escalations and a lower
enrollment-failure ticket volume.
