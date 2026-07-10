# 6. Troubleshooting — Azure Virtual Desktop: Deployment, Golden Image & FSLogix

Common failures on the build/deploy/FSLogix/scaling side, as **symptom → cause → fix**. Run `AVDDEP-Discovery.ps1` and `AVDDEP-Validate.ps1` first — most issues show up there. (Client-connection problems from Windows/macOS belong to the companion *AVD Remote Access* solution.)

---

## Image build & gallery

**Symptom — image version stuck in *Creating* or *Failed* replication.**
- **Cause:** Region replication in progress, quota shortfall in a target region, or a generalize/capture that did not complete cleanly.
- **Fix:** Check the version's replication status per region; ensure compute quota exists in each target region; if the capture failed, redeploy the build VM and re-capture. Confirm the build VM was **generalized** (OS state *Generalized*) before capture.

**Symptom — new session hosts won't build from the gallery image ("image not found" / generation mismatch).**
- **Cause:** The image definition generation (Gen1/Gen2) or security type does not match the VM size, or the `galleryImageId` points at a definition instead of a specific version.
- **Fix:** Ensure the definition is **Gen2** and the VM size supports it (and Trusted Launch if used). Point `galleryImageId` at a full **version** resource ID (`.../versions/1.0.0`), not the definition.

**Symptom — every host looks slightly different despite "using the image."**
- **Cause:** Some hosts were created from a Marketplace image or an older version, i.e. snowflakes.
- **Fix:** `AVDDEP-Validate.ps1` (Test 2) flags hosts whose image does not trace to the expected version — redeploy those from `AVDDEP-SessionHosts.bicep` pinned to the correct version.

## Session-host deployment (Bicep)

**Symptom — VMs deploy but never appear as session hosts in the host pool.**
- **Cause:** Expired or reused host-pool **registration token** (the single most common cause).
- **Fix:** Registration tokens are short-lived. Let the Bicep template mint a fresh token at deploy time (do not reuse an old one). Redeploy so a new token is issued, then confirm hosts appear as **Available**.

**Symptom — `what-if` wants to delete or recreate resources you did not change.**
- **Cause:** Manual drift — someone edited the estate in the portal after the last deploy.
- **Fix:** Reconcile the template to reality (import the manual change into the Bicep or revert the manual change) until `what-if` reports **no changes** (Testing T7). Never expand to production on a dirty what-if.

**Symptom — deployment fails on the admin password parameter.**
- **Cause:** Password complexity not met, or the secure parameter was left empty.
- **Fix:** Supply a compliant password via a **secure parameter or Key Vault reference** — never hard-code it. Meet Windows complexity rules (length + character classes).

## FSLogix / profiles

**Symptom — users get a fresh temporary profile every logon; no VHDX on the share.**
- **Cause:** FSLogix not enabled, wrong `VHDLocations`, or the user lacks Modify rights on the share.
- **Fix:** Confirm `HKLM\SOFTWARE\FSLogix\Profiles` has `Enabled=1` and the correct UNC in `VHDLocations` (`AVDDEP-Validate.ps1`, Test 4). Set share permissions so **Users = Modify**. Verify the storage is joined to the identity source the hosts authenticate to.

**Symptom — logons are very slow.**
- **Cause:** Undersized/high-latency profile storage, cross-region profile I/O, or antivirus scanning the VHDX.
- **Fix:** Use **premium** Azure Files or the correct Azure NetApp Files service level, **co-located** with the hosts. Exclude the FSLogix VHDX path from AV real-time scanning per your vendor's AVD guidance.

**Symptom — "profile already in use" / users locked out of their profile.**
- **Cause:** A prior session did not release the container (host crash), or the same user is active on two hosts.
- **Fix:** Confirm breadth-first load balancing and single-session-per-user behavior; clear the stale lock on the container; ensure `DeleteLocalProfileWhenVHDShouldApply=1` so local remnants don't conflict.

## RBAC

**Symptom — operators can't manage the host pool, or hold far more rights than they should.**
- **Cause:** Missing Desktop Virtualization role, or broad standing Owner/Contributor at subscription scope.
- **Fix:** Assign **Desktop Virtualization Host Pool Contributor** / **Desktop Virtualization Contributor** scoped to the host pool/RG; remove broad Owner from operators and prefer **PIM** eligibility (`AVDDEP-Validate.ps1`, Test 5).

## Scaling & cost

**Symptom — idle hosts never power down; the bill keeps climbing.**
- **Cause:** No scaling plan assigned, plan disabled, or the AVD service principal lacks Power On/Off rights.
- **Fix:** Confirm `AVD – Scaling Plan – Pilot` is **enabled and assigned** to the host pool (`AVDDEP-Report.ps1`), and that the required custom role for power actions is granted (the portal prompts for it during plan creation).

**Symptom — users get disconnected during the day.**
- **Cause:** Ramp-down schedule set too aggressively / `rampDownForceLogoffUsers` enabled during business hours.
- **Fix:** Review the schedule times and thresholds in the scaling plan; keep force-logoff off for interactive audiences and set a sensible `rampDownWaitTimeMinutes`.

## Drain / patch

**Symptom — updating a host disconnected an active user mid-session.**
- **Cause:** A host was patched or replaced without draining first.
- **Fix:** Always **drain then replace**. Preview with `AVDDEP-Maintenance.ps1` (default `-WhatIf`) to see active session counts, drain with `-Apply` in a maintenance window, let sessions finish, then deploy replacement hosts from the new image version. Rollback = `-Undrain -Apply` or redeploy the prior image version.
