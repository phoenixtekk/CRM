# 7. Best Practices — Migrating the Microsoft Entra Connect Source Anchor to mS-DS-ConsistencyGuid

- Change the anchor BEFORE you migrate a single production object. objectGUID is regenerated on a
  domain/forest move; if you migrate first, the migrated objects look new to Entra and duplicate. The
  switch to mS-DS-ConsistencyGuid is the precondition for the whole consolidation, not a follow-up.
- Prove the empty-attribute precondition, don't assume it. The wizard only seeds mS-DS-ConsistencyGuid
  where it is empty; a single pre-existing value stops it. Run `SRCANCHOR-Test-Preconditions.ps1` on
  every in-scope OU and reach a zero count before opening the wizard.
- Never blindly clear mS-DS-ConsistencyGuid. If it is already populated, find out what put it there (a
  prior Connect install, an earlier migration, a manual stamp) and confirm it is safe before clearing
  or excluding — clearing a live anchor breaks the link.
- Grant the AD DS connector (sync) account exactly the permission it needs. Write mS-DS-ConsistencyGuid
  on the in-scope OUs — no more. Delegate it at the OU, verify with `SRCANCHOR-Check-Permissions.ps1`,
  and remove it later only if your change control requires it.
- Back up the Connect configuration first and record it. The switch is effectively permanent; export
  the configuration and log it in the `Source Anchor – Change & Backup Record` with the server, the
  ADSync database location, and the change date.
- Confirm the seed is a no-op for existing users. After the wizard, verify the seeded
  mS-DS-ConsistencyGuid equals each object's prior immutableId (objectGUID Base64) — that equality is
  what guarantees no re-sync and no duplicates at cutover.
- Treat Quest ODM's attribute stamp as a coordination contract. The anchor only survives the move if
  Quest copies mS-DS-ConsistencyGuid onto the target; confirm that mapping in Quest (per Quest's docs)
  and prove it on the pilot before any production wave.
- Pilot the end-to-end hard-match, not just the wizard. Migrate one `PILOT – Source Anchor –
  Validation Users` object through Quest and confirm Entra updates the *same* user — the wizard
  succeeding is necessary but not sufficient.
- Do not revert mid-migration. The anchor switch is one-way in practice; reverting to objectGUID after
  waves have started re-breaks already-migrated users. Rely on the pre-change backup and the gates, not
  a rollback.
- Mind AD FS only when it applies. If sign-in is AD FS, open TCP 80/443/5985 to the primary AD FS
  server so the wizard can update the claim rules; if sign-in is PHS/PTA/cloud auth, this does not
  apply — don't over-scope firewall changes.
- Remember it is a single-forest linking attribute. mS-DS-ConsistencyGuid links within one forest; a
  genuine multi-forest topology needs additional matching planning before you rely on it.
