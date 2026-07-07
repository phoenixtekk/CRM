# Executive Summary

**Outcome.** Windows Autopilot **device preparation** and Apple **Automated Device Enrollment
(ADE)** enrollments that reliably place each device into the correct security group **at the moment
of enrollment** — so compliance, configuration, and apps apply during provisioning instead of hours
later. This solution ends the recurring, deployment-blocking failure where saving the enrollment
policy's Device Group returns *"Unable to save device group… the Intune Provisioning Client
application is not an owner."*

**The problem it solves.** Enrollment-Time Grouping only works if a specific Microsoft first-party
service principal — the **Intune Provisioning Client** (AppId
`f1346770-5b25-470b-88bd-d5744ab7952c`) — is an **Owner** of the target group, and the group is a
narrowly-shaped object (Security, **Assigned** membership, **cloud-only**, not mail-enabled, not
role-assignable). Teams miss this because the failure appears **only after Save**, the service
principal's **display name varies by tenant**, and the portal simultaneously throws **unrelated
Azure Monitor `AuthorizationFailed` errors** that misdirect the investigation. Microsoft documents
the requirement for Windows; the identical Apple ADE flow is **barely documented**, so admins are
left guessing.

**Approach.** A prerequisites-first playbook plus a symptom → root-cause diagnostic tree. It gives
the exact group specification (each attribute with why/verify/fix), the owner-by-AppId requirement
and how to add it, the RBAC-scope rules, and named, ordered setup steps for **both** platforms —
then maps every error string to its real cause and explicitly neutralizes the Azure-log red herring.
Five Microsoft Graph PowerShell tools assess group readiness, add the owner (dry-run by default),
validate all prerequisites, and diagnose failures.

**Why it is low-risk.** Everything is **pilot-first** with explicit pass/fail gates and an instant,
non-destructive rollback (clear the Device Group setting), so already-enrolled devices are never
affected. The tooling is **read-only or `-WhatIf` by default**, requests **least-privilege** Graph
scopes, and stores **no secrets**. The result is a repeatable, evidence-backed configuration that
turns a stubborn zero-touch blocker into a solved, documented, and verifiable outcome across the
Windows and Apple fleets.
