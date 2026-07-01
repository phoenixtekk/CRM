# Global Requirements — Managed

These requirements are common to **every** Managed-category solution in the standard service model. They are the baseline operational prerequisites that any managed-services engagement assumes. Each is structured **Description / Why / Verify / Implement-if-missing**. Solution-specific requirements (see `02-requirements.md`) are layered on top of these.

> Naming convention: every created object is named `<Purpose> – <Scope> – <Stage>` and reused verbatim throughout the engagement.

---

## G1. A Microsoft 365 / Entra tenant (and any Azure subscriptions in scope)

- **Description:** An active Microsoft 365 / Microsoft Entra tenant, plus any Azure subscriptions the managed service covers.
- **Why:** All identity, licensing, monitoring, and service configuration is anchored to a tenant/subscription; nothing can be managed without one.
- **Verify:** Sign in to the **Microsoft 365 admin center** (`https://admin.microsoft.com`) → **Settings → Org settings** and confirm the tenant is active; in the **Azure portal** (`https://portal.azure.com`) → **Subscriptions** confirm the in-scope subscriptions.
- **Implement-if-missing:** Provision/associate the tenant and subscriptions before onboarding the managed service.

## G2. Administrative + reader roles (least privilege)

- **Description:** Appropriately scoped roles for the work — reader-level visibility broadly, with scoped admin (Exchange, Teams, SharePoint, Intune, Security, Azure RBAC) only where action is required, preferably PIM-eligible.
- **Why:** Every diagnostic and remediation action needs sufficient privilege; least-privilege scoping limits blast radius and satisfies audit.
- **Verify:** In **Entra admin center** → **Roles & admins**, confirm operating accounts hold required roles; in **Azure → Subscriptions → Access control (IAM)** confirm RBAC.
- **Implement-if-missing:** Assign the minimum roles; prefer **PIM** eligible activation over standing access.

## G3. Licensing baseline

- **Description:** Sufficient Microsoft 365 / Azure licensing for the in-scope users and the features the service relies on (e.g. **Entra ID P2** for Identity Protection, Defender plans for security signal).
- **Why:** Features and visibility (risk detections, advanced Defender, log retention) are gated by SKUs; a missing SKU silently removes a diagnostic capability.
- **Verify:** **Billing → Licenses** for M365; confirm the SKUs the service depends on are present and assigned.
- **Implement-if-missing:** Procure the required SKUs, or document the capability gap where a SKU is intentionally absent.

## G4. Monitoring, logging, and a system of record

- **Description:** Active monitoring/alerting for the in-scope estate, retained logs (Entra, Exchange, Azure Monitor / Log Analytics), and a ticketing/PSA system as the durable record.
- **Why:** You cannot respond to what you cannot see, and you cannot review an incident whose logs have aged out; the PSA is the audit trail.
- **Verify:** Confirm alerts route to the response team; confirm diagnostic settings export logs to a workspace with adequate retention; confirm a PSA incident queue exists.
- **Implement-if-missing:** Stand up alert routing, enable diagnostic logging with retention sized to your review window, and configure the PSA incident type.

## G5. Change control & maintenance window

- **Description:** An approved change-management process with maintenance windows, an emergency-change path, and a stakeholder communications plan.
- **Why:** Managed changes (and incident remediations) can be outward-facing and disruptive; controlled windows and comms reduce business impact and satisfy governance.
- **Verify:** Confirm an approved change record and window for disruptive actions, and a defined emergency-change rule for incidents.
- **Implement-if-missing:** Stand up a lightweight change/approval process; define the emergency-change rule; prepare comms templates.

## G6. Backup / rollback posture

- **Description:** A defined backup and rollback position for any change — config export, data backup, and a documented back-out before any disruptive action.
- **Why:** Changes are not always reversible by default; a tested rollback is the safety net for remediations and bulk operations.
- **Verify:** Confirm pre-change state is captured and a written rollback exists for each disruptive change.
- **Implement-if-missing:** Export current configuration/state; document and (where feasible) rehearse the rollback before executing.
