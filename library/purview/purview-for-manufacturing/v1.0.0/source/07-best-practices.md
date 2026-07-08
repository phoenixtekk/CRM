# 7. Best Practices — Microsoft Purview for Manufacturing

- **Classify IP and CUI separately — and let the business/legal decide the lines.** Keep a small
  taxonomy (`MFG-Public` → `MFG-Internal` → `MFG-Confidential-IP` → `MFG-CUI` →
  `MFG-CUI-Export-Controlled`) people can reason about. The **CUI and export-control (ITAR/EAR)
  determinations are legal/compliance calls** — capture them, never invent them.
- **Protect what travels.** Manufacturing runs on external sharing; use label **encryption scoped to
  named partner domains** for `MFG-Confidential-IP` so a shared drawing stays protected, and restrict
  the CUI labels to authorized recipients only. Protection that travels beats a network boundary.
- **Build a custom SIT for your part/drawing numbers.** Generic financial/PII detectors miss
  engineering IP; a `SIT - MFG Part/Drawing Number` keyed to your real format is the single biggest
  accuracy win for DLP and auto-labeling. Prefer the built-in **CUI classifier/SITs** for CUI where
  your plan/cloud provides them.
- **Simulate auto-labeling.** Always run `Auto-Label - CUI and Export-Controlled - Pilot` in
  simulation and review matches before turning it on — it labels IP/CUI at scale and mistakes are
  visible to engineers and suppliers.
- **Audit DLP before you enforce.** The single most important practice: run
  `DLP Policy - Manufacturing IP and CUI - Audit` in test mode, review matches, tune out false
  positives (legitimate supplier domains, decoy part numbers), and only then enforce. A blocked-work
  storm on the shop floor is the fastest way to lose trust in DLP.
- **Hard-block export-controlled data; block-with-override elsewhere.** Treat ITAR/EAR sends to
  unauthorized recipients as a hard block; for internal IP, block-with-override plus a policy tip
  keeps engineers productive while capturing the risk decision.
- **Cover the endpoint.** Onboard engineering workstations so endpoint DLP can govern **copy to USB,
  print, and browser upload** of labelled drawings — the common real-world IP-leak paths.
- **Name every object by purpose and stage.** Use `<Purpose> - <Scope> - <Stage>` (rename
  `... - Audit` to `... - Enforce` at the gate) so the portal shows exactly where each policy sits in
  its lifecycle.
- **Match retention to the records schedule, and use disposition review.** Set durations from the
  records/DFARS schedule (a records/compliance determination), not a guess; use disposition review for
  CUI/contract records so nothing is auto-deleted unreviewed. Deletion is irreversible.
- **Evidence CMMC / NIST 800-171 as you go.** Work the mapped improvement actions in Compliance
  Manager (`Assessment - CMMC / NIST 800-171 - Manufacturing`) while you configure, so the program is
  assessor-ready — configuration without evidence is not compliance.
- **Verify licensing and cloud for CUI.** Auto-labeling at rest, endpoint DLP, trainable classifiers,
  and advanced records need E5 / E5 Compliance; DIB tenants often need **GCC / GCC High** for CUI —
  **verify your licensing/tenant** rather than assuming a feature is present.
- **Document the objects and the rollback.** Record the taxonomy, SIT, policy names, partner domains,
  scopes, and the rollback (revert DLP to audit; auto-labeling back to simulation; disable a retention
  policy) for repeatability and change control.
