# 7. Best Practices — Application Retirement, Offboarding & Decommissioning

Field-proven habits that keep retirements safe, defensible, and repeatable.

## Decision discipline
- **Never retire an app nobody will vouch for without a named risk-acceptor.** "No owner" is
  evidence *for* retirement, but someone senior must sign that they accept the outage risk.
- **Name the trigger explicitly.** The trigger (EOL/EOS, security, redundancy, low utilisation, cost)
  sets the grace period and approver. A cost-driven retirement with a renewal date is a *deadline*,
  not a wish.
- **Separate install base from usage.** Intune tells you who *has* the app; it never tells you who
  *uses* it. Get a real usage signal (vendor console, SSO sign-ins, licence logs) before you call
  something "unused".

## Protecting data (the irreversible step)
- **Treat the uninstall as a one-way door.** Always determine per app what the uninstaller destroys,
  on a test device, before Wave 0.
- **Export before you assign.** Do not create the Uninstall assignment until required data is exported
  and verified. An assignment can reach a fast-syncing device in minutes.
- **Capture licence/activation state before removal.** Some products deactivate on uninstall; record
  the seat count and keys first.

## Campaign mechanics
- **Understand intent precedence.** **Required beats Uninstall.** The most common "nothing happened"
  cause is an old Required assignment still winning. Remove the install assignment; don't just stack
  an Uninstall on top.
- **Delete the app object LAST.** Deleting it does not uninstall anything and destroys your ability to
  target and report. It is the final cleanup step, never the first.
- **Use assigned groups, never a dynamic sweep.** A dynamic "all devices with the app" rule can
  uninstall the whole fleet in one sync. Assigned wave groups keep the blast radius chosen and
  auditable.
- **Always keep an exclusion group with an expiry in its name.** Exemptions that never expire become
  permanent shadow deployments.
- **Prefer supersedence for migrations.** When a replacement exists, "Uninstall previous version =
  Yes" guarantees a device is never left with neither app.
- **Deploy the replacement first, prove it, then remove the old app.** Never remove before the
  successor is validated on the same devices.

## Stragglers and reach
- **Define "done" in the presence of unreachable devices.** Set a completion threshold on *reachable*
  devices and require every remaining device to be dispositioned (offline / decommissioned /
  escalated / exempt). A campaign that waits for 100% of a fleet including dead devices never closes.
- **Escalate installer-level failures; don't debug them in the campaign.** A device whose uninstall
  genuinely errors is a Win32 uninstall failure remediation task — record and hand it off, keep the
  wave moving.

## Cleanup and proof
- **Clean up every artefact, not just the app.** Assignments, wave/exempt groups, detection and
  remediation scripts, WDAC / App Control rules, Conditional Access references, the enterprise
  application, and SCCM remnants. Orphaned app-control rules are a genuine security hazard — a stale
  *allow* widens attack surface; a stale *deny* blocks a future app with the same name.
- **Never delete a shared script or group.** The ImpactAnalyzer and ArtifactFinder flag shared
  objects — leave them.
- **The evidence pack is the deliverable.** "Is it gone?" must be answerable with data: final status,
  dispositioned residuals, zero artefacts, data-export record, licence numbers.
- **Monitor for reappearance.** Re-imaged machines, returned-from-offline devices, and lingering SCCM
  deployments bring apps back. Keep watching for 30–60 days and kill the source, not just the symptom.

## Naming and repeatability
- **One retirement code per campaign** (`APPRET-<code>`), used in every object name, so a whole
  campaign sorts and cleans up together.
- **Reuse the exact object names** from the Implementation Guide verbatim in scripts, testing, and the
  evidence pack.
- **Keep the decision record as the campaign's front page.** It carries the trigger, evidence,
  approver, data determination, wave dates, licence numbers, and cleanup checklist — the story of the
  retirement in one place.
