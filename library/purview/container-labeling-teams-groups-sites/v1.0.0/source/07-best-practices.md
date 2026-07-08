# 7. Best Practices — Container Labeling (Teams, Groups & Sites)

- **Govern the container and the file — they are complementary, not either/or.** Container labels set
  privacy, guest, sharing, and device access for the Team/Group/Site; file/email labels classify and
  encrypt the content inside. Deploy container labeling knowing it is the perimeter half; pair it with
  file labeling for defense in depth.
- **Enable container labeling once, deliberately, and pilot it.** Setting `EnableMIPLabels = True` and
  running the label sync is a tenant-level change to how labels behave org-wide. Dry-run it, apply it in
  a change window, and verify the enablement method against current Microsoft guidance — the
  directory-settings surface is evolving.
- **Design the taxonomy before you touch a container.** Three clear tiers (General / Confidential /
  Highly Confidential) with explicit privacy/guest/sharing/device settings beat a sprawl of one-off
  labels. Fewer, well-understood tiers are adopted; many overlapping ones are ignored.
- **Set a default container label so new containers are governed from birth.** A default label on the
  policy (e.g. `Container – General`) means a newly created Team/site is never fully ungoverned — the
  common failure mode this solution exists to prevent.
- **Pilot guest and device controls on a ring first — they generate tickets when wrong.** "Block access
  from unmanaged devices" or "no guests" applied to a busy site without piloting will surprise users.
  Prove behavior on a handful of named containers and pilot users before the estate.
- **Always dry-run applies.** Run the apply script with `-WhatIf` and read every line before `-Commit`;
  it prints the exact reverse command per container so rollback is trivial.
- **Respect the SharePoint tenant sharing ceiling.** A container label can only **tighten** sharing, not
  loosen it beyond the tenant `SharingCapability`. Confirm the tenant baseline supports the taxonomy, or
  the "New and existing guests" tier will silently do nothing.
- **Verify the unmanaged-device control against your licensing.** The limited/blocked device-access
  settings require **Entra ID P1** and SharePoint Conditional Access. Where P1 is absent, scope the
  labels to privacy/guest/external-sharing and record the device control as deferred — don't assume it
  is active.
- **Report coverage on a schedule and treat drift as an incident.** Re-run the reporting script
  regularly; an in-scope container that lost its label or drifted from its tier is a governance gap to
  close, not a cosmetic issue.
- **Apply labels with PowerShell for scale, the portal for authoring.** Author labels (with their
  container settings) in the Purview portal where they are reviewable; apply them across many containers
  with the provided scripts. Don't hand-edit label definitions in code.
- **Keep the tier determination with the business.** Which data is Confidential vs Highly Confidential,
  and who may be a guest, are compliance/data-owner/privacy/legal decisions. You provide the technical
  mapping and the evidence; they own the determination.
- **Treat portal paths as provisional.** The Purview portal and the protection-settings page names are
  actively changing — verify each path in your tenant rather than trusting a screenshot from last
  quarter.
