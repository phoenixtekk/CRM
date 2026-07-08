# 7. Best Practices — Microsoft Purview ITAR Compliance Program

- **Restrict to authorized U.S. persons — and let export-control/legal draw the lines.** The whole
  program hinges on two determinations: **what is ITAR/USML-controlled** and **who is an authorized U.S.
  person**. Both are export-control/legal calls — capture them in `ITAR Scope – Record`, never invent
  them.
- **Confirm the sovereign cloud first.** ITAR technical data generally requires **GCC High**; verify the
  cloud/tenant with export-control/legal **before** any controlled data lands. This is a licensing/tenant
  determination, not a technical default — **verify your licensing/tenant.**
- **Protect what travels.** Use label **encryption restricted to authorized U.S. persons** so a technical-
  data document stays protected wherever it goes — a network boundary doesn't prevent a deemed export; a
  label that travels does.
- **Treat access as export.** Under ITAR, a foreign person's **access** to technical data is a deemed
  export — so least privilege, authorized-person scoping, and DLP recipient conditions are the core
  mitigations, not afterthoughts.
- **Build a custom SIT for your markings.** Generic detectors miss export-controlled technical data; a
  `SIT - ITAR/USML Markers` keyed to your real markings is the single biggest accuracy win for DLP and
  auto-labeling.
- **Simulate auto-labeling.** Always run `Auto-Label - ITAR Technical Data - Pilot` in simulation and
  review matches before turning it on — it labels controlled data at scale and mistakes are visible.
- **Audit DLP before you enforce — then hard-block unauthorized recipients.** Run
  `DLP Policy - ITAR Export-Controlled - Audit` in test mode, tune out false positives (authorized
  recipients), and only then enforce. For ITAR, prefer keeping the recipient **hard-block** on and tuning
  exceptions over disabling — under-blocking is an unauthorized-export risk.
- **Cover the endpoint.** Onboard workstations so endpoint DLP governs **copy to USB, print, and browser
  upload** of technical data — common real-world leak paths.
- **Retain export records, with disposition review.** Set export-record retention from the schedule (a
  records/legal determination); use disposition review so nothing is auto-deleted unreviewed.
- **Evidence continuously.** Work the mapped improvement actions in Compliance Manager as you configure
  (an export-control template where available, otherwise **NIST SP 800-171** / a custom assessment) so the
  program is audit-ready — configuration without evidence is not compliance.
- **Name every object by purpose and stage.** Use `<Purpose> - <Scope> - <Stage>` (rename `... - Audit`
  to `... - Enforce` at the gate) so the portal shows exactly where each control sits.
- **Never widen beyond authorized persons.** When you expand from pilot to production, expand the scope
  **within** the authorized-U.S.-person population only — never to "All users."
- **Document the objects and the rollback.** Record the scope, authorized-person list, SIT, policy names,
  authorized recipients, and the rollback (revert DLP to audit while keeping the hard-block; auto-labeling
  to simulation; disable a retention policy) for repeatability and change control. **Applicability, USML
  classification, U.S.-person status, and any disclosure decision remain export-control/legal's.**
