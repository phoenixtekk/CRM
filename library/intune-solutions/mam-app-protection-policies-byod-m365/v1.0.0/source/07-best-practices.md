# 7. Best Practices — MAM App Protection Policies for BYOD

- Pilot first, always. Assign to `MAM Users – BYOD – Pilot` and validate on a real unenrolled device before touching production — the single most important practice.
- Enforce with Conditional Access. App Protection Policies protect data, but only `CA – Require APP – M365` guarantees corporate resources are reachable only from a protected app. Deploy both.
- Start Conditional Access in Report-only. Review sign-in impact before flipping `CA – Require APP – M365` to On, and always exclude break-glass accounts.
- Keep iOS and Android policies in sync. Mirror the same data-protection and access settings across `BYOD – App Protection – iOS` and `BYOD – App Protection – Android` so behavior is consistent.
- Limit save-as to org locations. Block save-as except OneDrive/SharePoint so corporate data does not land in personal cloud or the camera roll.
- Require an app PIN and encryption. These are the baseline that makes a lost phone a non-event for corporate data.
- Set a sensible offline grace period. Balance security and usability — too short frustrates travelers; too long weakens the wipe guarantee.
- Prefer selective wipe over device wipe on BYOD. Remove corporate data only; never wipe an employee's personal phone. Communicate this clearly to build trust and adoption.
- Respect privacy to speed adoption. Tell users MAM cannot see or wipe personal data — this is the message that gets BYOD accepted.
- Assign to groups, not users. Add new BYOD users to the scope groups; they inherit protection automatically.
- Watch coverage. Track which users/apps report a policy with `MAMAPP-Report.ps1` and chase the gaps.
- Document the settings. Record the data-protection and access values, the app list, and the CA grant for audits and repeatability.
