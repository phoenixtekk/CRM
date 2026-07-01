# 7. Best Practices — Remote Help

- **Assign least-privilege RBAC.** Give help-desk staff the minimum role needed; reserve full control for roles that truly require it.
- **Decide the unenrolled-device policy deliberately.** Default to **not** allowing assistance to unenrolled devices unless you have a clear need.
- **Deploy the app as Required.** Push Remote Help to helper and sharer groups via Intune so it's always present when needed.
- **Pilot a real session.** Validate helper + sharer + consent + control end-to-end before broad rollout.
- **Use compliance signals.** Train helpers to check the device compliance indicator before assisting.
- **Keep the app current.** Ensure the Remote Help app updates so features and fixes stay in place.
- **Don't SSL-inspect Remote Help traffic.** Exclude the service endpoints from inspection to avoid broken sessions.
- **Review the audit/usage data.** Periodically run `RHELP-SessionReport.ps1` to monitor who is assisting whom.
- **Communicate consent.** Make sure end users know sessions require their consent and are audited — it builds trust.
- **Document the role model.** Record which roles can help, control, and assist unenrolled devices for audits.
