# 2. Requirements Guide — Azure Security Baseline & Governance

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify · Implement-if-missing.** Category-wide prerequisites are in `global-requirements-azure-solutions.md`. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim.

## 2.1 An Azure subscription and tenant
**Description:** At least one Azure subscription under a Microsoft Entra tenant.
**Why:** Policy, RBAC, and Defender for Cloud all operate against subscriptions anchored to a tenant.
**Verify:** `portal.azure.com` → **Subscriptions**; run `AZSEC-Discovery.ps1`.
**Implement-if-missing:** Create or associate a subscription under the tenant.

## 2.2 Elevated rights to assign policy and RBAC
**Description:** An operating account with **Owner** or **User Access Administrator** plus **Resource Policy Contributor** at the target scope (management group or subscription).
**Why:** Assigning initiatives and creating role assignments requires these rights; Defender plan changes require **Security Admin** or Owner.
**Verify:** Azure → **Access control (IAM)** at the target scope confirms the roles; `AZSEC-Discovery.ps1` reports current RBAC.
**Implement-if-missing:** Assign the minimum roles at the narrowest scope; prefer PIM eligible activation over standing access.

## 2.3 A governance scope design (management groups / subscriptions)
**Description:** A decision on which **management group(s)** and **subscription(s)** the baseline applies to, and the pilot subset.
**Why:** Assigning at the right node lets one guardrail cover many subscriptions; the pilot subset limits blast radius.
**Verify:** `portal.azure.com` → **Management groups**; run `AZSEC-Discovery.ps1` (lists the hierarchy).
**Implement-if-missing:** Create a management-group hierarchy and place subscriptions; use `AZSEC-Set-ScopeTargeting.ps1` to resolve and confirm the target scope.

## 2.4 Azure Policy available
**Description:** Azure Policy (built-in, no extra license) and the **Microsoft.PolicyInsights** resource provider registered.
**Why:** Guardrail initiatives and compliance state require the provider registered on each subscription.
**Verify:** Azure → **Subscriptions → Resource providers** shows **Microsoft.PolicyInsights** as Registered; `AZSEC-Validation.ps1` checks this.
**Implement-if-missing:** Register the provider (`Register-AzResourceProvider -ProviderNamespace Microsoft.PolicyInsights`).

## 2.5 A secure-configuration baseline definition
**Description:** The agreed baseline: require encryption, restrict public storage/network access, allowed locations, allowed SKUs/resource types, secure transfer, diagnostic logging.
**Why:** The baseline is what the guardrail initiatives enforce; without it there is nothing to assign.
**Verify:** A written baseline exists and maps to specific built-in policies/initiatives.
**Implement-if-missing:** Adopt the Microsoft cloud security benchmark initiative plus the named guardrail policies as the starting baseline; adjust to org standards.

## 2.6 Microsoft Defender for Cloud plan decision
**Description:** A decision on Defender for Cloud coverage — foundational CSPM (free, secure score + recommendations) and any enhanced/paid plans.
**Why:** Secure score, regulatory compliance, and recommendations come from Defender for Cloud; enhanced plans add workload protections at a cost.
**Verify:** `portal.azure.com` → **Microsoft Defender for Cloud → Environment settings**; `AZSEC-Discovery.ps1` reports plan status.
**Implement-if-missing:** Enable foundational CSPM on in-scope subscriptions; enable enhanced plans where the risk justifies the cost.

## 2.7 Change control, pilot scope, and rollback
**Description:** An approved change window, a named pilot scope, and a documented rollback before moving any guardrail from audit to deny or tightening RBAC.
**Why:** Deny policies and RBAC changes can block legitimate work; the audit-before-deny gate and rollback are the safety net.
**Verify:** An approved change record, the pilot scope, and a written back-out exist (per `global-requirements-azure-solutions.md` G5/G6).
**Implement-if-missing:** Export current assignments (`AZSEC-Report.ps1`), define the pilot scope, and write the rollback (remove/reassign the initiative in audit).

---
## Checklist
- [ ] Azure subscription + Entra tenant — `AZSEC-Discovery.ps1`
- [ ] Owner / User Access Administrator + Resource Policy Contributor at scope
- [ ] Governance scope design (management groups / subscriptions + pilot subset)
- [ ] Microsoft.PolicyInsights registered — `AZSEC-Validation.ps1`
- [ ] Secure-configuration baseline defined and mapped to policies
- [ ] Defender for Cloud plan decision made
- [ ] Change window, pilot scope, and rollback documented
