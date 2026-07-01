# 7. Best Practices — Entra ID + ABM Federation & Account Auto-Provisioning

- **Pilot the scope, not the federation alone.** Federation is domain-wide for Apple sign-in, so the
  control you have is provisioning scope — keep SCIM scoped to `Managed Apple ID Provisioning – Pilot –
  Stage` until conflicts are resolved and the pilot passes. This is the single most important practice.
- **Resolve existing-Apple-ID conflicts before widening.** Run the ABM domain-capture report, give
  users a clear change-window deadline, and re-check before expanding. Conflicts are the number-one
  cause of provisioning and enrollment failures.
- **Use SCIM as primary, JIT as backfill.** SCIM gives scoped, auditable, reversible provisioning and
  de-provisioning with the user lifecycle; just-in-time creation on first federated sign-in catches
  anyone a cycle hasn't reached. Rely on both.
- **Keep the three models cleanly separated.** One enrollment profile and one compliance policy per
  device/user; COD by device group, BYOD by user group, Shared by device group. Never double-assign.
- **Be accurate about shared iPhones.** iPhones have no Apple "Shared iPad" — build shared on
  **no-affinity enrollment + restrictions + a Managed Apple ID / shared app sign-in**, and say so.
- **Name everything consistently.** Use the `<Purpose> – <Scope> – <Stage>` convention verbatim across
  groups, ADE profiles, and compliance policies so docs, scripts, and the console all match.
- **Protect the Apple credentials.** Record the **company Apple ID** used for the APNs certificate and
  the **ADE token** Apple ID; both renew yearly — a lapse breaks all iPhone management.
- **Keep break-glass ready.** Per the global requirements, keep cloud-only emergency-access accounts
  excluded from broad policies before changing identity/sign-in.
- **Validate every wave.** Run `ABMPROV-Discovery.ps1`, `ABMPROV-Validation.ps1`, and
  `ABMPROV-Report.ps1` before and after each expansion; don't widen on assumption.
- **Have a rollback.** To stop provisioning, set the job **Off** and remove the pilot group's
  assignment; full federation removal is an ABM-side action (deferred to Apple docs) — coordinate it
  because it affects sign-in.
- **De-provision with the lifecycle.** Let SCIM remove Managed Apple IDs when a user leaves scope; do
  not orphan accounts.
