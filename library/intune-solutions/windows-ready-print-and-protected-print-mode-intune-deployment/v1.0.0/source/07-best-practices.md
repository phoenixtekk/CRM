# Best Practices

## Assess before you enforce
- **Never enable WPP fleet-wide before the compatibility assessment.** WPP removes incompatible printers
  and their drivers; the assessment (drivers, Mopria/IPP, eSCL scan) is what turns that from a production
  surprise into a planned change.
- Treat the **pre/post inventory diff** as the acceptance test — the only removals should be the ones the
  assessment predicted.

## Scope deliberately
- WPP is **device-scoped** — it affects **every user** on the PC. Plan shared/kiosk/lab devices with that
  in mind.
- Always attach an **OS-version filter (24H2+)** to every assignment so ineligible devices are never
  targeted (and don't show spurious "Not applicable" errors).
- Keep **non-compliant devices out of scope** (non-Mopria hardware, eSCL-less scanners) and track them as
  exceptions to closure — don't hold the whole rollout for a handful of laggards, and don't force WPP over
  a known gap.

## Modern path first, then harden
- Stand up the **modern print path** (direct IPP/Mopria or **Universal Print**) **before** removing the
  legacy print-server/Point-and-Print path. Enabling WPP with no replacement path in place is how you
  create "can't print at all."
- Enable **IPP/IPPS on the printers** and confirm **Mopria certification** as part of readiness — the
  client side is only half of driverless printing.

## Roll out in rings
- Pilot → ring 1 → ring 2 → broad, each gated on the prior ring's validation and help-desk signal.
- Hold each ring long enough to catch **periodic** workflows (month-end runs, label/receipt printers,
  scan-heavy roles).

## Prevent regression
- Document the **standard modern onboarding**: new printers arrive as **IPP/Mopria or Universal Print**,
  never as a new third-party driver.
- Keep the **assessment scripts in rotation** (e.g., as a Proactive Remediation) to catch a third-party
  driver creeping back in before it spreads.
- Align with Microsoft's **V3/V4 driver end-of-servicing** direction — treat any new third-party driver
  request as an exception that needs justification, not a default.

## Evidence & handoff
- Keep the assessment matrix, the pre/post diff, the WPP-enabled proof, and the exception list with the
  change record.
- Feed confirmed blockers (specific non-Mopria models, eSCL-less scanners) into procurement so
  replacements are Ready-Print-compatible.

## Sovereign clouds
- Use `intune.microsoft.us` and the same CSP; **confirm Universal Print availability in your sovereign
  cloud** before designing a cloud-print path, and document which path each population uses.
