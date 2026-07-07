# Deliverables Summary

Everything included in this CMMC Level 2 readiness solution for Google Workspace, on one page. The
solution delivers **readiness** — control mapping, configuration method, and evidence, plus the SSP and
POA&M. It does **not** produce a CMMC assessment result or certification; those remain with your
assessor and compliance/legal team.

## Documentation

| Document | What it covers |
|---|---|
| **Solution Overview** | CMMC L2 / NIST 800-171 (14 families), the CUI boundary on Workspace, the reference model, benefits, limitations, and the deployment model. |
| **Requirements Guide** | Solution-specific prerequisites (edition/add-on for regulated controls, CUI-boundary input, assessor/compliance engagement, Assured Controls baseline, read-only API access, CUI-scoped change control) — each with verify/implement steps, on top of the shared Google requirements. |
| **Implementation Guide** | Assess → Design → Configure → Pilot → Validate → Expand: define the CUI boundary, map every family to a Workspace mechanism, configure + pilot + evidence, and generate the SSP/POA&M — with named artifacts, pass/fail gates, and rollbacks. |
| **Testing & Validation** | Ten tests (T1–T10) with expected pass/fail: boundary membership, sharing, context-aware access, 2SV, DLP, audit logging/export, data-region/encryption, app control, evidence completeness, SSP/POA&M completeness. |
| **Troubleshooting** | Common failure modes — API throttling/scope errors, incomplete evidence, DLP false positives, edition-gated features, boundary drift — with resolutions. |
| **Best Practices** | Boundary discipline, evidence hygiene, control-map-as-source-of-truth, change safety, least-privilege credentials, and holding the assessment boundary. |
| **Executive Summary** | Outcome, approach, and why the engagement is low-risk. |

## The 5 Python tools

All are **safe-by-default** (read-only or dry-run), use the Google Workspace **Admin SDK / Reports /
Drive / Groups** APIs, take least-privilege scopes, and hold **no credentials or keys in code**.

| Tool | What it does |
|---|---|
| **`assess-nist-controls.py`** | READ-ONLY. Maps the 14 NIST 800-171 families to Workspace settings and emits the `NIST 800-171 – Control Map – Org` matrix with a status per control (configured / partial / not-configured / manual / verify-edition). `--check-auth` verifies the credential. |
| **`collect-evidence.py`** | READ-ONLY. Exports configuration state (OU/user/group settings) and operational evidence (audit-log extracts) into a timestamped `Evidence – CUI Boundary – <date>` package, indexed to the control map. |
| **`cui-boundary-check.py`** | READ-ONLY. Scans the CUI boundary OU/groups for exposure — external Drive sharing, external/out-of-OU group members — and reports findings by severity (drives boundary tests T1/T2). |
| **`generate-ssp-poam.py`** | Local-only. Drafts the `SSP – CUI Boundary – Org` (statement per requirement) and `POA&M – CUI Boundary – Org` (row per open requirement) from the control map, for the compliance owner to review and own. |
| **`cui-scope-helper.py`** | DRY-RUN by default. Plans the named artifacts (boundary OU, pilot group, DLP/sharing/CAA/retention/export names) and the user→OU move list; with `--apply` performs only the low-risk, reversible scaffolding (create OU + pilot group, move users) — enforcing controls stay piloted/manual. |

## Outputs you finish with

- A completed **`NIST 800-171 – Control Map – Org`** matrix (control → setting → status → evidence).
- An indexed **`Evidence – CUI Boundary – <date>`** package (configuration + audit-log evidence).
- A clean **boundary-exposure** finding set.
- Reviewed **`SSP – CUI Boundary – Org`** and **`POA&M – CUI Boundary – Org`** documents.
- An **assessment-ready** tenant — configured, evidenced, and handed to your C3PAO/compliance team for
  the determination.
