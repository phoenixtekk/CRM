# Global Requirements (Managed) — MSP Tool Stack Design & Standup — PSA, RMM & Patch Management

These requirements apply to **every** solution in the Managed category, not just this one. They describe the baseline operating conditions a managed-services practice must have in place before any Managed solution can be implemented safely and repeatably. Satisfy these in addition to the solution-specific requirements (R1–R12) in `02-requirements.md`. Each item follows the same Description / Why required / How to verify / How to implement if missing structure.

---

## GM1 — An MSP practice with admin access to its PSA/RMM/patch tooling

- **Description:** An operating managed-services practice (or an internal IT function adopting the managed model) with administrative access to whatever PSA, RMM, and patch tooling it runs.
- **Why required:** Every Managed solution configures or operates these platforms; without administrative access the work cannot be performed.
- **How to verify:** Confirm you can sign in to each platform's admin console with an account that holds full administrative rights.
- **How to implement if missing:** Obtain administrative access from the platform owner, or provision the platforms if the practice does not yet have them.

## GM2 — MFA and least-privilege on the tooling

- **Description:** Multi-factor authentication enforced on all administrative tooling and a least-privilege role model for human and service accounts.
- **Why required:** Managed tooling has privileged, cross-client reach; a single compromised or over-privileged account can affect every client the practice serves.
- **How to verify:** Confirm MFA is enforced for all users and that roles grant only the access each user needs.
- **How to implement if missing:** Enforce MFA in each tool, define least-privilege roles, and reassign users to the minimum role required.

## GM3 — A CMDB / asset source of truth

- **Description:** A configuration management database or asset inventory designated as the authoritative record of managed configurations and devices.
- **Why required:** Managed operations depend on knowing what is under management; ambiguity about the asset set leads to gaps in monitoring, patching, and billing.
- **How to verify:** Confirm a CMDB/asset source exists (typically the PSA's configurations module fed by the RMM) and is treated as authoritative.
- **How to implement if missing:** Designate the PSA configurations module as the CMDB and establish the RMM→PSA asset feed to populate it.

## GM4 — Change control

- **Description:** A defined change-control process for changes to managed environments and to the tooling itself.
- **Why required:** Uncontrolled changes to fleet-wide tooling or client environments cause outages that span many clients at once.
- **How to verify:** Confirm a change-control process exists (request → review → approval → implementation → review) and is used for tooling changes.
- **How to implement if missing:** Adopt a lightweight change-control process and route tooling/policy changes through it; high-impact changes (patch policy, integration config) require review before applying.

## GM5 — Secure secrets storage

- **Description:** A secure secrets store (password manager / secrets vault) for all credentials, API keys, and service accounts.
- **Why required:** Managed solutions handle privileged credentials; insecure storage is an immediate, fleet-wide risk.
- **How to verify:** Confirm a secrets store is in use and credentials are stored there, never in scripts, spreadsheets, or chat.
- **How to implement if missing:** Adopt a secrets store, migrate all credentials into it, and rotate anything previously stored insecurely.

## GM6 — A pilot / test client

- **Description:** A pilot or test client (or representative test environment) for validating changes before broad rollout.
- **Why required:** Validating against one safe client before expanding prevents a faulty change from reaching the entire base.
- **How to verify:** Confirm a pilot/test client or environment is designated and available.
- **How to implement if missing:** Select a low-risk client or stand up an internal test company with a few test devices.

## GM7 — A runbook / documentation home

- **Description:** A documentation platform where operating standards, runbooks, and configuration records are maintained and accessible to the team.
- **Why required:** Managed operations are only repeatable and auditable when standards and procedures are written down and findable.
- **How to verify:** Confirm a documentation home exists and the team can access it.
- **How to implement if missing:** Stand up or designate a documentation home and create a section for the practice's operating standards.

---

## Global requirements checklist

| # | Requirement | Verified |
|---|-------------|----------|
| GM1 | MSP practice with admin access to its tooling | ☐ |
| GM2 | MFA + least-privilege on the tooling | ☐ |
| GM3 | CMDB / asset source of truth | ☐ |
| GM4 | Change control | ☐ |
| GM5 | Secure secrets storage | ☐ |
| GM6 | Pilot / test client | ☐ |
| GM7 | Runbook / documentation home | ☐ |
