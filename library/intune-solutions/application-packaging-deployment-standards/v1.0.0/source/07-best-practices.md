# 7. Best Practices — Application Packaging & Deployment Standards

- **Name the app once, correctly, forever.** `<Publisher> <Product> – <Format> – v<Version>` with
  en-dash separators, no ticket numbers, no `Test`/`Copy`/`Final`. A catalog you can search is a
  catalog you can audit; a catalog of one-off names is a liability that grows with every package.

- **The version must agree in three places.** The app name, the detection rule, and the evidence
  folder all carry `v7.3.1`. A version that appears in the name but not the detection rule is the
  number-one cause of a fleet that reports Installed while running last quarter's build.

- **Decide the format at intake, in writing, from the tree.** Work the decision tree top to bottom
  and record the deciding question on the intake form. Prefer Microsoft Store (new) where it is
  available and auto-update is acceptable, then MSIX, then Win32 as the default. **Never** create a
  new LOB/MSI app — it is banned for new packages.

- **Detection observes, never acts.** A detection rule or script must be deterministic, specific,
  version-asserting, written by the vendor's installer (not your wrapper), and proven on a clean
  machine. Never `Win32_Product` (it triggers MSI self-repair on every cycle), never a folder-only
  check, never a shared runtime, never `HKCU` for a system-context install.

- **One authoritative detection rule per app.** Combining rule types produces ambiguous failures
  nobody can diagnose. If you genuinely need more than one, document why on the intake form and have
  it countersigned.

- **Never map a non-zero exit code to Success.** `1603` mapped to Success does not make a deployment
  work; it deletes your only signal that it failed. Declare `0`, `1707`, `3010`, `1641`, `1618`
  explicitly and add vendor codes only with a citation.

- **Let return codes and policy own reboots.** Use `/norestart`, set **No specific action** by
  default, and reserve forced restarts for unattended Ring 0/kiosk devices with the owner's written
  agreement. Never schedule a reboot-forcing Required app to land during business hours.

- **The reviewer is never the packager.** Sign-off is a second person from `ROLE – Package Approvers`
  who independently confirms the gates against what Intune actually shows, not against what the form
  claims. If you cannot separate the roles, record it as an exception with a manager's
  counter-signature — do not quietly skip the gate.

- **One exclusion group, applied to every Required assignment.** `APP – Exclusions – Do Not Deploy`
  on every deployment means an emergency exclusion is a single membership change, not an edit to
  fifty apps.

- **Never assign to All Devices or All Users.** They are not rings; they are the shortest path from a
  mistake to a fleet-wide outage. Assign to `APP – ` purpose-named groups only, in ring order.

- **Retain the evidence, not just the package.** The intake form, the acceptance checklist, the
  sign-off record, and the three-state detection proof live in `Application Package Records` for the
  app's lifetime. "Who approved this, when, against what test?" must have a filed answer.

- **Audit on a cadence, remediate with a preview.** Baseline before you announce, check new apps
  monthly, audit the whole catalog quarterly, and re-verify the standard itself annually. Run the
  metadata remediation script in its default preview mode first and only `-Apply` after the diff is
  reviewed.

- **Keep an honest exceptions register with expiry dates.** Not everything gets fixed; an exception
  with no review date is a permanent hole pretending to be a decision. Every waiver names an owner, a
  reason, and a date it will be revisited.

- **Re-verify Government-cloud format availability.** The Microsoft Store (new) app type and some app
  features have parity gaps in US Government clouds and different portal hosts. Confirm availability
  for your cloud before you commit the Store branch of the matrix, and re-check it at each annual
  review. Verify for GCC High against Microsoft's documentation — never assume the Commercial answer.
