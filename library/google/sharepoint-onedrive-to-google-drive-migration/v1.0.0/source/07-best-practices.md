# 7. Best Practices — SharePoint Online & OneDrive → Google Drive / Shared Drives Migration

Field-proven practices for moving SPO/OneDrive to Google Drive/Shared Drives **without losing access**,
with a focus on shared-drive structure.

## Shared-drive structure
- **Team content goes to a Shared Drive, never a personal My Drive.** A SharePoint site/library is
  team-owned; putting it in one person's My Drive gives that person a kill switch over everyone's
  access and loses the content when they leave. Map site/library content to **Shared Drives** and
  personal OneDrive content to the same user's **My Drive**.
- **One Shared Drive per library (or per clean access boundary), not one giant drive.** A Shared Drive
  caps at **500,000 items** and **600 members** (100 of them groups), and Google recommends staying
  well under **100 levels** of folder nesting ([Google — shared drive limits](https://support.google.com/a/answer/7338880)).
  Split large sites across drives so no drive nears a limit and each has a coherent membership.
- **Set access at the Shared Drive with groups, then vary per-folder/-file only where needed.** Add a
  group as a member at the right role and let it cascade; reserve per-item permissions for the
  exceptions. This keeps membership legible and avoids thousands of one-off grants.
- **Put restricted content in its own top-level folder before migrating.** Google shows
  previously-hidden folders **greyed out** (visible, not accessible) after migration; isolating
  restricted items in separate top-level folders keeps that behavior clean and predictable.
- **Keep folder trees shallow.** Deep SharePoint nesting is technically supported but hurts usability
  and can complicate permission mapping — flatten obviously-over-nested trees during the mapping step.

## Permissions & sharing
- **Complete the identity map before you migrate — it is the whole game.** Every source principal that
  holds a permission or share must resolve to a Google identity; **anything missing is silently
  dropped** and the file arrives with lost access ([CloudM — Drive permission changes](https://support.cloudm.io/hc/en-us/articles/25031144447644-Google-Drive-Permission-Changes-Microsoft-365-to-Google-Workspace)).
  Treat map completeness as a gate.
- **Map permission levels to roles deliberately — do not flatten.** Translate each SharePoint level to
  the closest Google role (Full Control → Manager, manage-content → Content manager, Contribute →
  Contributor, read+comment → Commenter, read → Viewer) against the source tenant's *actual* levels,
  and have owners confirm the intent is preserved ([Google — shared drive roles](https://developers.google.com/workspace/drive/api/guides/ref-roles)).
- **Apply folder-level permissions to folders, file-level to files.** This is the accurate default;
  reserve root/drive-level grants for cases where the top-level access should genuinely cascade to
  everything — over-using them over-shares.
- **Never let a migration silently widen access.** Translate anyone-with-the-link shares only where
  policy allows; otherwise down-scope to domain/named access and flag for owner review. A migration
  that broadens sharing is a security incident, not a success.
- **Tell users about the greyed-out folders.** Brief them ahead of cutover so a visible-but-locked
  folder reads as expected behavior, not a bug.

## Method
- **Map once, migrate many.** Freeze the content, permission, identity, and sharing maps before Wave 0;
  deciding mapping per wave (or letting the tool default it) is the biggest source of inconsistent
  structure and flattened permissions.
- **Prove the whole mapping on a named pilot.** Wave 0 (a representative site + OneDrive sample)
  exercises files, permissions, identity, and sharing end to end — cheaper to find a mapping defect on
  one site than across a business unit.
- **Fix the mapping, not just the item.** Every validation exception is a defect in the content,
  permission, identity, or sharing artifact — fix it there so later waves inherit the fix.
- **Validate per item, every wave.** Reconcile files, check that roles match, confirm no dropped
  principals, and verify sharing — for every wave, before it passes. A tool's "success" is not
  validation.
- **One scope, one wave, fixed.** Assign every site/library/OneDrive to exactly one wave and never move
  a confirmed scope between waves — that risks duplicate content.
- **Cut over only after validation is clean.** Set source content read-only / decommission only once
  users are confirmed to have access at the mapped roles — never before.
- **Keep the tool internals with the vendor.** This solution owns the mapping, translation, and
  validation; the engine's console steps live in the vendor's docs — so a tool change touches the
  engine, not the method.
