# 7. Best Practices — Dynamic Device Targeting in Intune

- Group for the broad audience, filter for the exception. Use a dynamic group for stable populations
  reused by many assignments; use a reusable filter to narrow or carve out a single assignment — the
  single most important practice for keeping object counts low.
- Name everything with `<Purpose> – <Scope> – <Stage>` and reuse the names verbatim. A consistent
  taxonomy makes coverage, intent, and audits obvious.
- Prefer stable attributes. Target on `enrollmentProfileName`, `deviceOwnership`, and
  `deviceCategory` over free-form device names; they are more reliable and less prone to drift.
- Keep attribute data clean. Membership and filter rules are only as accurate as ownership,
  category, model, and enrollment-profile values — populate them at enrollment.
- Validate effective targeting, not intent. Overlapping filters and exclusions produce non-obvious
  results; confirm the real audience on a pilot with `DYNTGT-Validation.ps1` before expanding.
- Pilot before broad. Target a small pilot group first; expand only after the effective targeting
  passes the gate.
- Reuse filters instead of minting groups. One filter attached to many assignments beats a new group
  for every OS/model/ownership combination.
- Mind evaluation lag. Dynamic membership is not instant; allow time after enrollment or an attribute
  change before expecting a device to appear.
- Watch for drift. Run `DYNTGT-Report.ps1` on a cadence to catch in-scope devices missing an
  assignment or devices matched by no group.
- Document the taxonomy. Record every group name, filter name, and rule for audits and repeatability.
