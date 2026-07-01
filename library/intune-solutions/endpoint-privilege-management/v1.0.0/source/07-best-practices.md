# 7. Best Practices — Endpoint Privilege Management (EPM)

- **Always pilot first.** Deploy to `EPM-Pilot` (3–5 users), validate fully, then expand in waves. Never enable EPM tenant-wide on day one.
- **Observe before you enforce.** Run the base policy with **reporting on** and a **Deny all** default first; let real elevations surface in the report, then codify the legitimate ones into rules.
- **Default to User confirmed.** Make **User confirmed** your standard elevation type and require a **business justification** (and Windows authentication for sensitive apps). Reserve **Automatic** for a small set of fully trusted, signed software.
- **Prefer certificate rules over hashes.** Certificate-based rules survive application updates; hash rules break on every new build. Use hashes only for unsigned, fixed binaries. `New-EpmElevationRule.ps1` gives you both.
- **Keep rules narrow.** Scope each rule to a specific file name + signer; control **child process** behavior so an elevated installer can't become a backdoor to a full admin shell.
- **Remove standing local admin — that's the point.** EPM only pays off once users are standard users. Plan the removal (communications + a support-approved safety valve) and execute it after rules are proven.
- **Use Support approved for high-risk apps.** Route rare or sensitive elevations through admin approval rather than a blanket rule.
- **Layer your defenses.** EPM governs *elevation*, not *what may run*. Pair it with **WDAC/App Control** and **Attack Surface Reduction** for defense in depth.
- **Review the elevation report on a schedule.** Watch for new denied attempts (rules to add) and unexpected automatic elevations (rules to tighten). `EPM-ElevationReport.ps1` exports this for review.
- **Communicate to users.** A short heads-up ("you're now a standard user — here's how to run approved apps elevated and who to contact") dramatically reduces help-desk tickets.
- **Document each wave.** Record which group, which date, which rules, and validation results in your change log for auditability.
- **Keep Windows and the EPM client current.** EPM depends on a supported, patched Windows build and a healthy client extension; enforce Update rings and monitor client health with `EPM-Discovery.ps1`.
