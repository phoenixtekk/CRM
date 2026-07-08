# 7. Best Practices — Sensitivity Labeling for Power BI & Microsoft Fabric (Microsoft Purview)

- **Confirm the analytics information-protection surface before you design anything.** The Power BI/Fabric
  tenant-setting names, the export-restriction behavior, and the Fabric-item coverage are evolving — read
  them from the admin portal and Microsoft's current docs for *your* tenant rather than assuming a setting
  or an entitlement that may have moved.
- **Reuse your existing sensitivity labels — don't invent BI-only labels.** Analytics consumes the same
  Purview Information Protection labels as files and email. One taxonomy across documents, mail, and BI is
  what makes classification consistent and inheritance meaningful.
- **Export inheritance is the point — validate it first.** The reason to label analytics is that the
  Excel/PowerPoint/PDF export carries the label and its encryption. Prove that end-to-end on the pilot
  before anything else; a labeling program that doesn't protect exports has missed its own goal.
- **Turn source inheritance on so classification flows, not restarts.** Where upstream sources are
  labeled, let the label inherit into the content so the BI layer isn't a place where protection quietly
  drops. Where sources are unlabeled, rely on artifact labeling and record inheritance as **partial**.
- **Delegate the tenant settings to a group and pilot there.** Scope the information-protection settings
  to `BI Labeling – Enabled Users` and enable for a pilot workspace/group first — never flip them
  tenant-wide on day one. Mandatory labeling and export restriction are felt immediately by creators and
  consumers.
- **Turn on mandatory labeling last, and communicate first.** Requiring a label on new/changed content
  drives coverage but surprises creators mid-flow if sprung on them. Enable it only after the pilot
  validates and after you've told creators what will change.
- **Right-size export restriction.** Blocking every export is rarely the intent; the intent is that a
  protected export **stays protected**. Configure the restriction so authorized users still get their
  work done and unauthorized access is what's blocked.
- **Mind the licensing dependency per user and per workspace.** Labeling needs the AIP entitlement **and**
  Power BI Pro/PPU (or a capacity) for the affected users. Confirm both; where a user or workspace lacks
  the licensing, record the capability as **deferred** rather than assuming it applies.
- **Keep automation safe-by-default and secret-free.** Run discovery, validation, and reporting read-only;
  gate every write behind `-WhatIf` → `-Commit`; sign in interactively with modern auth. No credentials,
  tokens, or secrets belong in a script or a document.
- **Re-report on a schedule.** New workspaces and creators appear constantly. Re-run `IPPBI-Report.ps1`
  periodically so `Analytics Labels – Coverage Report` stays a live evidence artifact, not a one-time
  snapshot.
- **Keep determinations with their owners.** The solution configures and evidences analytics labeling;
  which content is sensitive, and any regulatory/records obligation on the data it surfaces, is a
  determination for compliance, privacy, and data-governance. Keep that separation explicit.
