# 1. Solution Overview — Remote Help

## What Remote Help is
Remote Help is Microsoft's cloud-based remote-assistance application, integrated with Microsoft
Intune. A help-desk technician (the **helper**) can securely view and, with consent, control an
enrolled user's device (the **sharer**) — authenticated through Microsoft Entra, governed by
**role-based access control (RBAC)**, shown the device's **compliance** status, and recorded in
an **audit** trail.

## How it works
1. Remote Help is **enabled** in the Intune tenant settings (license required).
2. The **Remote Help app** is deployed to devices through Intune.
3. **RBAC roles** determine who can help, who can request help, and whether full control is allowed.
4. A session starts with both parties signing in with **Entra** credentials; the sharer grants consent; the helper sees the device's **compliance** state before assisting.
5. The session is **audited** (who helped whom, when).

## Security model
- **Entra-authenticated** helpers and sharers — no anonymous access.
- **RBAC** — least-privilege roles (e.g. Help Desk Operator) control capabilities.
- **Compliance visibility** — helpers see if the device is compliant before connecting.
- **Conditional control** — view-only vs full control configurable; elevation prompts respected.
- **Audited** — sessions are logged for accountability.

## Benefits
- **Secure** — replaces risky third-party/ad-hoc tools with an Entra-governed, audited service.
- **Least privilege** — RBAC ensures only authorized staff assist, with the right capabilities.
- **Trust signals** — compliance state surfaces device risk to the helper.
- **Integrated** — managed and reported within the Intune ecosystem you already run.

## Limitations (be honest with buyers)
- Requires a **Remote Help license** (Intune Suite or the Remote Help standalone add-on).
- The **Remote Help app** must be deployed to participating devices.
- Network access to the Remote Help service endpoints is required.
- Cross-tenant / unenrolled-device assistance has specific settings and limits.

## The standard deployment model
> **Enable Remote Help → deploy the app via Intune → assign RBAC roles → configure security
> options → pilot a session → expand.** repeatable pattern: **Assess → Configure → Pilot →
> Validate → Expand.**
