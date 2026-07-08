# 1. Solution Overview — Microsoft Purview ISO 27701 Compliance Program

## What this delivers
This solution stands up an **ISO/IEC 27701-aligned privacy program in Microsoft Purview**. ISO 27701 is
the **Privacy Information Management System (PIMS)** extension to ISO/IEC 27001/27002 — it adds
privacy-specific controls for organizations acting as **PII controllers** (Clause 7 / its guidance) and
**PII processors** (Clause 8 / its guidance). The program maps those PIMS requirements to the Microsoft
Purview controls that **evidence** them, scores the posture in **Compliance Manager**, configures and
**pilots the technical controls in simulation/test**, and produces an **evidence register** — so the
capability is in place, validated, and defensible.

## Why ISO 27701 needs Purview
- **A PIMS is evidence-driven.** Certification and management review depend on demonstrable controls and
  records — not intentions. Purview supplies the technical controls (labels, DLP, retention, audit) and
  the evidence trail.
- **Personal data (PII) must be protected, minimized, and retained lawfully.** Sensitivity labels + DLP
  protect PII; data-lifecycle/retention enforces retention limitation and disposal; audit provides
  accountability.
- **Controller vs processor duties differ.** ISO 27701 splits obligations for controllers and
  processors; the control map records which apply and how each is evidenced.
- **It builds on ISO 27001.** Where an ISO 27001 ISMS already exists, this program **extends** it with
  the privacy overlay rather than starting over.

## How it works in Purview
1. **Compliance Manager** hosts an **ISO 27701** assessment (availability varies by plan/cloud — verify)
   so PIMS requirements become scored **improvement actions** with owners, status, and evidence slots.
2. A **control map** ties each in-scope PIMS clause/control to the Purview control that evidences it
   (labels, DLP, retention, audit, DSR method).
3. **Personal-data protection controls** — a PII sensitivity label, auto-labeling, DLP over PII, and a
   retention label — are configured and **piloted in simulation/audit** before enforcement.
4. A **data-subject-request (DSR) method** (Priva Subject Rights Requests where licensed, or eDiscovery/
   content search) answers access/correction/erasure requests; **decisions remain privacy/legal's**.
5. An **evidence register** captures, per control, the owner, implementation/test status, and proof —
   the artifact an auditor or the management review reads.

## What you can control
- The PIMS control map and which Purview control evidences each clause.
- The PII label taxonomy, auto-labeling, and DLP scope/actions (audit → enforce).
- Retention durations/disposition for PII (from the retention schedule — a records/legal input).
- The DSR method and the evidence-register contents.

## Benefits
- **Certification-ready evidence** — PIMS controls mapped, scored, and evidenced in one place.
- **PII protected and minimized** — labels + DLP + retention piloted before they enforce.
- **Controller/processor clarity** — obligations recorded and evidenced by role.
- **Extends, doesn't replace** — layers cleanly on an existing ISO 27001 ISMS.

## Limitations (be honest with buyers)
- Auto-labeling at rest, endpoint DLP, trainable classifiers, advanced records, and premium Compliance
  Manager assessments require **Microsoft 365 E5 / E5 Compliance** — the Requirements Guide names the
  licensing; **verify your licensing/tenant**.
- **ISO 27701 applicability, scope of the PIMS, controller/processor determination, retention schedules,
  DPIA outcomes, lawful basis, and — above all — the certification decision are compliance/privacy/legal
  determinations.** This solution provides the technical configuration and evidence, **not** the
  determination and **not** a certification.
- Purview evidences the **technical** controls; organizational PIMS controls (governance, training,
  contracts, supplier management) live outside Purview and are referenced, not configured here.

## The standard deployment model
> **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce)**, with a **DLP
> audit gate** before any policy enforces, simulation for auto-labeling, and a documented rollback.
