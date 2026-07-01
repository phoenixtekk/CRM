# 7. Best Practices — Netskope + Entra ID SSO & Identity-Based Policy Enforcement

- **Pilot first, always.** Prove SSO, SCIM, and identity policy on `Netskope Identity - Pilot - Stage` before assigning `Netskope Identity - Corp - Prod` — the single most important practice.
- **Keep an emergency local admin.** Before switching the Netskope admin console to SAML, confirm a working local/break-glass Netskope admin so an IdP outage can't lock you out.
- **Scope provisioning to assigned users and groups.** Set SCIM scope to "sync only assigned users and groups" so Netskope mirrors exactly the population you intend — no accidental fleet-wide provisioning.
- **Provision groups, target policy by group.** Let SCIM carry Entra groups into Netskope and write `Identity Steering Policy - Corp - Prod` against those groups, not individuals — assign once, repeat everywhere.
- **Mind the lifecycle.** SCIM is the mechanism that de-provisions leavers; test a leaver explicitly so access actually follows HR reality.
- **Name everything consistently.** Use `<Purpose> - <Scope> - <Stage>` for the enterprise app, provisioning, groups, and policy, and reuse the names verbatim — it makes audits and the scripts line up.
- **Don't duplicate Conditional Access.** This integration governs Netskope's inline policy on the user's traffic; Conditional Access governs the authentication gate. Layer them; don't try to re-implement one in the other.
- **Confirm claims and mappings early.** Mismatched SAML claims or SCIM attribute mappings are the usual cause of "signed in but not recognized" — verify them against the Netskope documentation before piloting.
- **Watch the logs.** Track the enterprise app's Entra sign-in logs and provisioning logs, plus Netskope policy hits, with `NSSSO-Report.ps1`, and chase failures.
- **Document the rollback.** Record how to revert SSO to local admin, pause provisioning, and disable the identity policy, so any change is reversible within the change window.
