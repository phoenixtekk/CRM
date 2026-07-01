# 7. Best Practices — Windows Hello for Business

- **Always pilot first.** Deploy to `WHfB-Pilot` (3–5 users), validate fully, then expand in waves. Never flip a tenant-wide switch on day one.
- **One authoritative source.** Govern WHfB only through the Intune Account protection policy. Keep the tenant-wide enrollment setting **Not configured** and retire legacy GPOs.
- **Require the TPM.** Keep **Use TPM: Yes** so credentials are always hardware-bound; exclude (don't downgrade) devices without a TPM.
- **Prefer Cloud Kerberos Trust.** It avoids PKI/NDES and per-user certificates — fewer moving parts, fewer failures. Reserve Certificate Trust for narrow legacy cases (out of scope here).
- **Standardize the PIN policy.** A 6-digit minimum balances security and usability; only add complexity where a compliance mandate requires it.
- **Pair with Conditional Access.** Once WHfB is broad, use Conditional Access to require phishing-resistant authentication for sensitive apps, completing the passwordless story.
- **Coordinate with BitLocker.** Any TPM clear/reset affects BitLocker — always have the BitLocker recovery key before touching the TPM.
- **Measure coverage.** Run **`WHfB-TenantReport.ps1`** on a schedule to track registration percentage and catch stalled users.
- **Document each wave.** Record which group, which date, and validation results in your change log for auditability.
- **Communicate to users.** A one-paragraph heads-up ("you'll be asked to set up a PIN — here's why") dramatically reduces help-desk tickets.
- **Keep Windows current.** WHfB and Cloud Kerberos Trust depend on recent cumulative updates; enforce Update rings.
