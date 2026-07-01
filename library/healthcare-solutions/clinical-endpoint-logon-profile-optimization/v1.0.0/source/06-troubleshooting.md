# 6. Troubleshooting — Clinical Endpoint Logon & Profile Performance Optimization (FSLogix)

Symptom-driven fixes for the most common issues across the deployment. Work top-down within each symptom. Object names match `03-implementation.md`: Win32 app `FSLogix Agent – Clinical Endpoints – Deploy`, device group `Clinical – Logon Optimization` (pilot subset `Clinical – Logon Optimization – Pilot`), settings profiles `FSLogix Profile – Clinical Endpoints – Container` and `Fast Logon – Clinical Endpoints – Tuning`, and profile share `Clinical Profiles – FSLogix – Share`. Storage-platform values are owned by your **storage / infrastructure team** and Imprivata policy by your **Imprivata administrator** — escalate to them where indicated rather than guessing.

The FSLogix log is the first stop for most issues: on the endpoint, review `C:\ProgramData\FSLogix\Logs\Profile` (and `ODFC` if the Office Container is used). The User Profile Service and Application event logs corroborate.

---

## Slow logon (little or no improvement vs. baseline)

- **Confirm FSLogix is actually attaching, not falling back.** In `C:\ProgramData\FSLogix\Logs\Profile`, confirm the container **attaches** at sign-in. If Windows is silently building a local profile instead, the speed gain is lost — see "Container won't attach" below.
- **Confirm fast-logon tuning applied.** In `Devices > Configuration > Fast Logon – Clinical Endpoints – Tuning`, confirm **Succeeded** on the device and that *Delete cached copies of roaming profiles*, the first-sign-in animation disable, and OOBE-experience trims are in effect.
- **Check share latency.** Attach speed depends on the profile share. With the storage team, check round-trip/latency to `Clinical Profiles – FSLogix – Share` (SMB/445) from the endpoint; a slow or distant share erases the benefit. Ensure the share is regionally close (Azure Files) or on responsive storage.
- **Check container size / bloat.** A bloated VHD(X) attaches slowly — see "Profile bloat" below; add exclusions and re-measure.
- **Remove legacy roaming profile.** If an old roaming-profile path still applies to the user/OU, the two models fight and sign-in stays slow. Remove the legacy roaming-profile config for the clinical OU.
- **Re-measure properly.** Compare against the recorded baseline with the same method (`CLINLOGON-Set-FSLogixBaseline.ps1`), over repeated sign-ins — not a single warm-cache run.

## Container won't attach (temporary profile / "signed in with a temporary profile")

- **Check share permissions first.** The leading cause. Confirm both layers on `Clinical Profiles – FSLogix – Share` (R2): the **share-level** permission and the **NTFS / Azure Files Kerberos** ACLs (Users create/list/read this-folder-only; Creator Owner modify subfolders/files). For Azure Files, confirm Kerberos identity-based auth is enabled and the **Storage File Data SMB Share Contributor** role is assigned. Escalate to the storage team.
- **Check the VHD Locations path.** In `FSLogix Profile – Clinical Endpoints – Container`, confirm **VHD Locations** is exactly the storage-team-supplied share path and is reachable over SMB/445 from the endpoint (G5). A wrong/blocked path fails the attach.
- **Check the directory identity.** Confirm the user exists/enabled in the directory the share trusts and is in the permission group (R8). For Azure Files, confirm Entra/AD Kerberos is configured for the storage account.
- **Check for a locked VHD(X).** If the user's container is still attached/locked from a prior session (common on fast switching), the new attach fails. See "Conflicts with Imprivata" and tune *Locked Retry Count/Interval*; confirm prior sessions sign out cleanly.
- **Read the FSLogix profile log.** `C:\ProgramData\FSLogix\Logs\Profile` states the precise reason (permissions, path, lock, disk full) — fix the stated cause rather than guessing.

## Share permission errors

- **Distinguish the two layers.** A share that "looks" permissioned at the NTFS level can still fail at the share level (and vice-versa). Have the storage team confirm **both** explicitly against the FSLogix model.
- **Azure Files specifics.** Confirm identity-based authentication (Kerberos) is enabled on the storage account, the share-level RBAC role is assigned to the profile users/group, and the on-share directory ACLs follow the model. Missing any one yields access-denied on container create/attach.
- **Creator Owner inheritance.** If users can't create their own folder, confirm *Users* has Create-folder/append on **this folder only** and *Creator Owner* has Modify on **subfolders and files** so each user owns only their container.
- **Escalate to storage.** Do not loosen permissions to "make it work" (e.g., granting broad write) — that exposes other clinicians' containers. Fix to the model with the storage team.

## Profile bloat (container too large / share filling up)

- **Tighten redirections/exclusions.** Identify what is growing in the container (caches, temp, browser profile, indexable content, app caches) and add it to `redirections.xml` / the FSLogix exclusion settings so it stays local instead of roaming (R7). This is the primary fix.
- **Confirm dynamic disk + sane max.** Confirm **Is Dynamic = 1** so share usage tracks real data, and that **Size In MBs** is a sane per-container max — raising the max should be a last resort after exclusions.
- **Find app misbehavior.** If an EHR/clinical app is caching large data into the profile, work with the app owner to relocate or exclude that cache.
- **Review on a schedule.** Run `CLINLOGON-Report.ps1` to track container sizes and catch creep early; prune exclusions as new caches appear.

## Profile corruption

- **Read the log and event records.** The FSLogix profile log plus User Profile Service / ESENT events identify corruption and its trigger (dirty detach, share interruption, antivirus locking the VHD(X)).
- **Exclude AV from the VHD(X).** Ensure endpoint antivirus excludes the FSLogix VHD(X) files and the agent processes per Microsoft's FSLogix AV-exclusion guidance — AV locking the container is a classic corruption cause. Confirm with your security team.
- **Ensure clean detach.** Corruption often follows an unclean sign-out (power-off, forced unload). Confirm *Do not forcefully unload the users registry at logoff* = `Disabled` and that sessions sign out cleanly (especially on tap-and-go — see below).
- **Recover a single user.** For a corrupted individual container, work with the storage team to restore from snapshot/backup; never delete a user's container without a restore plan.

## Conflicts with Imprivata (tap-and-go fast switching)

- **Confirm tap-out detaches the container.** On shared single-session WOWs, the container only detaches on a full **sign-out**. If Imprivata tap-out only **locks**, the prior user's container stays attached and the next clinician's attach can fail. With the **Imprivata administrator**, confirm the agreed session model (R9) — typically full sign-out on tap-out so the container detaches.
- **Tune locked-VHD retries.** Where rapid A→B→A switching causes occasional locked-VHD retries, raise FSLogix **Locked Retry Count / Locked Retry Interval** in `FSLogix Profile – Clinical Endpoints – Container` modestly so a just-detaching container is given time to release. Do not change Imprivata appliance policy from here — escalate it.
- **Watch attribution.** If a clinician lands in the wrong profile after a switch, treat as a defect: confirm the prior container detached and the directory identity mapping is correct; re-run test T7.
- **Keep the two solutions' ownership separate.** Imprivata appliance/computer-policy values are owned by the Imprivata admin (separate solution); this solution owns only the FSLogix-side settings that let the two coexist.

## Agent or configuration won't apply (Intune)

- **Check detection rules.** A "failed" agent install with FSLogix actually present usually means wrong detection criteria. Confirm the rule matches the installed agent file/version or the `FSLogix Apps` uninstall registry key.
- **Check command lines.** Confirm the silent install/uninstall command lines are the documented FSLogix switches (`/install /quiet /norestart`, `/uninstall /quiet /norestart`) — do not invent switches.
- **Check requirements.** Confirm the device meets the app's OS architecture (`64-bit`) / minimum OS (R4); a mismatch leaves the app **Not applicable**.
- **Check assignment, conflicts, and sync.** Confirm the app and both profiles are assigned **Required**/targeted to the device's group (`Clinical – Logon Optimization – Pilot` during pilot). In `Devices > Configuration`, check for a **conflict** state where another policy or a legacy GPO sets the same FSLogix value — pick one authoritative plane (R3). Force an Intune sync and review the device's policy state.
- **Remediate.** After the root cause is addressed, use `CLINLOGON-Remediation.ps1 -Apply` to safely clear stale local cached profiles and/or re-point the FSLogix config to the named share for the device.

---

## Escalation map

| Issue domain | Escalate to |
|--------------|-------------|
| Profile share path, permissions, Azure Files Kerberos, quota/capacity, backup/snapshot | Storage / infrastructure team |
| Imprivata tap-out behavior, session timing, appliance/computer policy | Imprivata administrator (separate solution) |
| FSLogix/Windows licensing entitlement | Licensing owner |
| Intune app/profile/group delivery, GPO/ADMX, device management, reporting | Intune / AD administrator |
| Antivirus exclusions for the VHD(X), compliance sign-off | Security / compliance team |
| Network reachability to Microsoft / profile storage (SMB 445, Kerberos) | Networking team |
