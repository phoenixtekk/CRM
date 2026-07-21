# 7. Best Practices — Remote Help — Government (GCC High) Edition

- **Resolve the availability gate before anything else.** Confirm Remote Help's status for *your* tier
  (GCC vs GCC High / DoD) against current Microsoft documentation before you plan a rollout. It is the
  item most likely to have changed.
- **Never assume commercial parity, and never fabricate a `*.us` deployment.** If Remote Help is not
  available for GCC High / DoD, say so and move to the compliant alternative — do not force a
  configuration that isn't there.
- **Know that Intune GCC is the commercial instance.** For GCC, administer at the **commercial** portals
  (`intune.microsoft.com`) and script with `-Environment Global` — not `*.us`. Only GCC High / DoD use
  the `*.us` plane.
- **Verify every sovereign specific.** Endpoints, government SKU names, supported platforms, network
  endpoints, and Conditional Access scope all carry a **verify against current Microsoft documentation**
  flag — honor it.
- **Assign least-privilege RBAC.** View-only for tier-1, full control only where required; scope to a
  **user** scope group (the *All Devices* scope excludes unenrolled devices).
- **Protect helper accounts with Conditional Access** (MFA / compliant device) — supported on
  Windows/macOS only.
- **Deploy the app as Required** to helper and sharer groups; **exclude AVD** (unsupported in GCC).
- **Pilot a real, governed session** — helper + sharer + consent + capability — before broad rollout.
- **Keep the app current** (Windows Update / Microsoft AutoUpdate / Play Store) so features and fixes
  stay in place.
- **Don't SSL-inspect Remote Help traffic;** exclude the service endpoints from inspection.
- **Communicate consent and audit.** Sessions are consensual, on-screen-indicated, and logged (~30 days);
  no recordings are stored — document this to build trust and satisfy privacy stakeholders.
- **For GCC High / DoD, choose an *authorized* alternative.** Match your IL/ATO; never drop in an
  unauthorized consumer/commercial tool to fill the gap.
- **Monitor the roadmap.** Remote Help is *planned* for GCC High / DoD; re-run the availability gate
  periodically and adopt it (Path A) when it ships for your tier.
- **Document the decision.** Record which branch you took, the availability evidence, the RBAC role
  model, and (Path B) the alternative's authorization — for audits.
