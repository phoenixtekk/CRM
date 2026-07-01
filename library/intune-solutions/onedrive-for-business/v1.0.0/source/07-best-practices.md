# 7. Best Practices — OneDrive for Business

- **Always pilot first.** Deploy to `ODFB-Pilot` (3–5 users), validate fully, then expand in waves. Large Desktop/Documents/Pictures folders make the first sync slow — pilot reveals timing.
- **One authoritative source.** Govern OneDrive only through the Intune Settings Catalog profile. Retire legacy GPOs that set the same registry keys.
- **Get the Tenant ID right.** KFM silently fails without a valid Tenant ID — verify it with `Get-TenantId.ps1` and double-check it in **Review + create**.
- **Enable Files On-Demand.** It keeps local disks lean and makes KFM safe on small-SSD devices.
- **Block personal accounts** where data governance matters (**Prevent users from syncing personal OneDrive accounts**).
- **Communicate to users.** A short heads-up ("your Desktop, Documents, and Pictures are now backed up to OneDrive automatically") prevents confusion and tickets.
- **Stage large migrations.** Roll out KFM by department/wave so first-sync uploads don't saturate the network at once.
- **Never SSL-inspect OneDrive traffic.** It is unsupported and breaks sync — exclude OneDrive/SharePoint URLs from inspection.
- **Teach "Always keep on this device"** for the few files users truly need offline (travel, field work).
- **Measure adoption.** Run `ODFB-TenantReport.ps1` on a schedule to track provisioning and storage growth, and catch users who never synced.
- **Protect against ransomware.** OneDrive version history + Files Restore is your recovery path — confirm version history works (Testing Test 6) and document the restore procedure for the help desk.
