# 8. Deliverables Summary — macOS Automated Device Enrollment with SSO

Everything included in this solution package, and what each piece is for.

## Documentation (this guide)
- **Executive Summary** — the business case and outcome in one page.
- **Solution Overview** — what ADE and Platform SSO are, how they work together, the authentication
  methods, benefits, and honest limitations.
- **Requirements Guide** — every Apple/Intune prerequisite with how to **verify** and how to
  **implement if missing**, plus the category-level Global Requirements.
- **Implementation Guide** — exact, ordered, click-by-click steps across four phases: connect Apple
  to Intune, assign devices and define the enrollment experience, deploy Company Portal + Platform
  SSO, then pilot/validate/expand.
- **Testing & Validation** — eight tests with explicit pass/fail gates and an acceptance gate.
- **Troubleshooting** — top-down diagnosis for enrollment and Platform SSO failures.
- **Best Practices** — identity, enrollment hygiene, the all-important token/certificate lifecycle,
  OS/updates, rollout discipline, and security posture.

## PowerShell scripts (Microsoft Graph) — `ADEMAC-Scripts.zip`
All scripts are tenant-side (run from an admin workstation with the Microsoft Graph PowerShell SDK);
each has a header explaining **Purpose · How to run · Expected results**.

1. **`ADEMAC-Discovery.ps1`** — tenant readiness: APNs certificate status/expiry, ADE/enrollment
   token status/expiry, macOS enrollment profiles, Company Portal assignment, and Platform SSO
   profile presence. Flags anything expiring within 30 days.
2. **`ADEMAC-Validation.ps1`** — validates a specific Mac: enrolled, supervised, ADE, SSO profile
   applied, Entra-registered, and compliant — with a clear PASS/FAIL summary.
3. **`ADEMAC-DeviceReport.ps1`** — tenant-wide CSV report of macOS devices: enrollment type, OS
   version, ownership/supervision, Platform SSO registration state, and compliance.
4. **`ADEMAC-Remediation.ps1`** — safe remediation: re-sync the ADE token, re-assign the
   enrollment/SSO profiles to a target group, and surface tokens/certs nearing expiry. Read-only by
   default; changes require an explicit confirmation switch.
5. **`Set-PlatformSSOProfile.ps1`** — creates and assigns the Platform SSO (SSO app extension)
   configuration profile with the correct Microsoft Enterprise SSO identifiers, URLs, and Secure
   Enclave method.

## Hero image
- **`ADEMAC-hero.png`** — the branded product image (1200×1200) used on the marketplace listing.

## How it's delivered
A branded **Word** document and **PDF** (cover, table of contents, page numbers, and a scripts
appendix), plus all five PowerShell scripts in a single **ZIP** — yours to keep and reuse across
**unlimited devices**.
