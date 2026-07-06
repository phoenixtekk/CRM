# 7. Best Practices — Oracle C2M & WebLogic Patching & Upgrade Runbook (to 25.4)

- Lower environments first, always. Apply and validate in Dev, then Test/QA/UAT, and only reach
  Production after every lower environment has passed its gate — production is never the first place a
  patch or upgrade runs.
- Back up before you touch anything, and verify the backup. A backup you have not proven restorable is
  not a backup. Take the DB restore point/RMAN, Oracle Home, domain, and OUAF config backup, and gate
  the apply on `OC2MPATCH-Validation.sh --pre-check`.
- Read the patch README first, every time. Prerequisites, conflicts, ordering, and the documented
  rollback are patch-specific; most failed or half-applied changes come from skipping the README.
- Stay certified. Confirm OS/JDK/DB/WebLogic is a certified combination for the target C2M release
  before you patch or upgrade; align an uncertified stack as its own backed-up change first.
- Apply OUAF components in the right order. Database component before application-server component, then
  `initialSetup.sh`, then let the error-checker run — a failed error-check is a no-go, not a warning.
- Never force past an OPatch conflict. If `opatch apply` reports a conflict, stop and resolve per the
  README; forcing leaves the Oracle Home in an unsupported state.
- Treat an upgrade's rollback as restore-from-backup. A version upgrade (e.g. to 25.4) is reversed by
  restoring the Phase A backup, not by a simple back-out — confirm the restore path before you start.
- Validate against the baseline, not from memory. Capture the pre-change baseline with
  `OC2MPATCH-Discovery.sh` and compare with `OC2MPATCH-Report.sh` afterward, per node, so drift between
  nodes is caught.
- Gate every promotion on a decision. Promotion between environments is a go/no-go against a written
  gate, never a habit; a change that fails a lower gate does not move up.
- Do not invent patch numbers or apply unofficial fixes. Obtain patches and their READMEs from My
  Oracle Support only; point to the MOS note rather than reproducing gated content.
- Change control and a window for production. Every production apply runs inside an approved window,
  with a fresh backup and the rehearsed rollback ready, communicated to the support and business teams.
- Keep read-only tools read-only. Use `OC2MPATCH-Discovery.sh`, `OC2MPATCH-Validation.sh`, and
  `OC2MPATCH-Report.sh` to observe; keep `OC2MPATCH-Remediation.sh` in dry-run until a fix is
  deliberately approved.
