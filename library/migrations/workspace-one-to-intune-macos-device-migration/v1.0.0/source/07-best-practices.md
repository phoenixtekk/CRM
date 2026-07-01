# 7. Best Practices — Workspace ONE to Intune: macOS Device Migration

- Migrate in rings, always. A small `WS1MAC Migration - Pilot Ring` proves ABM reassignment,
  re-enrollment, and parity before the `WS1MAC Migration - Production Ring` fleet moves — the single
  most important practice.
- Build parity before you reassign. Have the settings-catalog policy, custom `.mobileconfig` profiles,
  and shell scripts assigned to the ring so configuration is waiting the moment a Mac re-enrolls — not
  scrambled together after.
- Inventory and map the source posture first. Export the Workspace ONE macOS configuration and map
  every item to its Intune surface (settings catalog, custom profile, shell script) with the parity
  tag `WS1MAC-Parity-vX`; you cannot rebuild what you have not catalogued.
- Reassign in ABM and release from the source as one coordinated move. ABM reassignment plus the
  Workspace ONE-side release is what lets the Mac re-enroll cleanly; doing one without the other
  leaves a device half-managed.
- Prefer ADE for corporate Macs. Automated Device Enrollment makes re-enrollment hands-off and
  consistent; reserve Account-driven enrollment for genuinely user-initiated cases.
- Keep the APNs certificate and ADE token healthy. An expired APNs certificate stops all Apple
  management; a stale token will not sync reassigned Macs. Check both with `WS1MAC-Discovery.ps1`
  before each wave.
- Treat FileVault keys and certificates as explicit parity items. They do not carry over with the
  device; plan their re-issue under the new authority rather than assuming continuity.
- Communicate per ring. Tell users what re-enrollment looks like, when it happens, and who to contact;
  clear comms cut tickets and failed enrollments, especially for non-ADE Macs.
- Keep the rollback ready. The fastest safe rollback for a single Mac is to reassign it in ABM back to
  the Workspace ONE MDM server; rehearse it on the pilot before any production wave.
- Validate parity, do not assume it. Run `WS1MAC-Validation.ps1` per device and `WS1MAC-Report.ps1`
  per ring after every wave, and chase any drift with `WS1MAC-Remediation.ps1` (preview first).
- Decommission only after parity is confirmed. Remove a Mac from Workspace ONE only once it is
  enrolled in Intune at full parity, so you always have a coexistence fallback.
