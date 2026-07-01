# 5. Testing & Validation — MSP Tool Stack Design & Standup — PSA, RMM & Patch Management

This is **Stage Validate**. Verify each plane (PSA, RMM, patch) and each integration with explicit PASS/FAIL evidence before expanding the model to the full client base. Run `MSPSTACK-Validation.ps1` for the automated checks and complete the manual checks below. Capture evidence (screenshots, exported CSVs from `MSPSTACK-Report.ps1`) in the documentation home.

A stage **PASSES** only when every check in its table passes. Any FAIL must be remediated (see `06-troubleshooting.md` and `MSPSTACK-Remediation.ps1`) and re-tested before proceeding.

---

## V1 — PSA validation

| Check | Method | PASS criteria |
|-------|--------|---------------|
| Boards/queues exist | PSA console → service boards/queues list | `Service Desk – Reactive – Triage`, `…– Dispatch`, `Projects – Onboarding – Delivery`, `NOC – Alerts – Automated` all present |
| SLA attached | Open `Service Desk – Reactive – Triage` | SLA is attached and active |
| Time→billing flow | Create a test ticket, log time, generate a draft invoice | Logged time appears on a billable agreement |
| Roles defined | PSA → Security/Roles | Administrator, technician, dispatcher, read-only roles exist |
| MFA enforced | PSA → Security → MFA/SSO | MFA required for all users |

## V2 — RMM validation

| Check | Method | PASS criteria |
|-------|--------|---------------|
| Policies exist | RMM → Policies | `Monitoring Policy – Workstation – Standard`, `…– Server – Standard`, `Automation Policy – Maintenance – Nightly` present |
| Agent reporting | RMM → Devices | Pilot endpoints show online with recent check-in |
| Monitors firing | Trigger a test condition (e.g. stop a monitored service) | An alert is raised on the endpoint |
| Automation runs | Run `Automation Policy – Maintenance – Nightly` on demand | Completes with success result |
| MFA enforced | RMM → Administration → Security | MFA required for all users |

## V3 — Patch validation

| Check | Method | PASS criteria |
|-------|--------|---------------|
| Rings exist | RMM patch section, or Intune → Devices → Manage updates → Windows updates → Update rings | `Patch Ring – Pilot – Stage0` … `– Critical Servers – Stage3` all present |
| Deferrals correct | Open each ring | Deferral = 0 / 3 / 7 / 7 days respectively |
| Assignments correct | Each ring's Assignments tab | Each ring assigned to its matching device group |
| Compliance reporting | RMM patch report, or Intune → Devices → Monitor → Windows Update reports | Pilot devices report patch status |

## V4 — Integration validation

| Check | Method | PASS criteria |
|-------|--------|---------------|
| Integration named & active | RMM/PSA integrations list | `Integration – PSA-RMM – Bi-Directional` shows connected |
| Alert→ticket | Trigger a test RMM alert | A ticket appears on `NOC – Alerts – Automated` for the correct company |
| Auto-close | Clear the test alert | The ticket auto-resolves |
| Asset/CMDB feed | RMM → discover an asset | The asset appears as a PSA configuration item under the right company |
| Site↔company mapping | Onboarded pilot site | `Client Site – {ClientName} – Production` maps to the matching PSA company |

## V5 — Onboarding validation

| Check | Method | PASS criteria |
|-------|--------|---------------|
| Site + company created | RMM/PSA | Pilot client has one site and one company, correctly named |
| Policies/rings bound | RMM device groups | Pilot groups bound to monitoring/automation policies and patch rings |
| Agents deployed | RMM → Devices | Pilot endpoints report in |
| End-to-end flow | Trigger alert → ticket → resolve | Full alert→ticket→close cycle works for the pilot client |

---

## Automated validation

Run `MSPSTACK-Validation.ps1` to evaluate the machine-checkable items (object presence, agent check-in, integration connectivity, ring deferrals) and emit a PASS/FAIL summary. Run `MSPSTACK-Report.ps1` to export stack-coverage and onboarding-status CSVs as validation evidence. Treat the automated output as supporting evidence alongside the manual checks — both must pass.

## Exit criteria

Stage Validate is complete when V1–V5 all PASS and the evidence is filed in the documentation home. Only then proceed to Stage Operate (`07-best-practices.md`) and expand onboarding to the full client base.
