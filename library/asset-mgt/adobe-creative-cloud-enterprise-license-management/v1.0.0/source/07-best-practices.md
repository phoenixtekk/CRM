# 7. Best Practices — Adobe Creative Cloud for Enterprise License Management

- Assign through product profiles and user groups, not one user at a time. Profile-based assignment is
  what keeps the seat inventory readable and right-sizing possible.
- Right-size before you reclaim. Many seats are not idle, they are over-provisioned — an all-apps seat
  used as a single app. Downsizing recovers cost without removing anyone's access.
- Never reclaim without a confirmation owner. Removing a user from a profile revokes access; require a
  recorded approval in `Right-Sizing Register – Pilot Scope – Validate` before any removal.
- Reuse freed seats before buying new ones. Reassign reclaimed seats from the waiting list first; a
  freed seat is the cheapest seat you will ever provision.
- Use a clear idle threshold and write it down. Define what "idle" means (for example no activity in N
  days) in `Review Cadence – Adobe Estate – Expand` so reclamation is consistent and defensible.
- Reconcile to the entitlement record every cycle. Tie the seat inventory to the purchased counts and
  renewal dates so you enter renewal knowing your true-down number.
- Prefer the Adobe User Management API where available, fall back to CSV cleanly. Programmatic reads
  are repeatable; an Admin Console export is the reliable fallback when the API is not available.
- Keep API credentials out of the scripts. Store secrets in a secret store or environment variables,
  never in source control, and grant the integration least privilege.
- Run reclamation as a routine, not a renewal fire drill. A recurring review tied to the renewal date
  turns a stressful true-up into a known quantity.
- Pilot first, every time. Prove the inventory, classification, and reclamation on one high-value
  scope (often the all-apps profile) before applying the process to the whole estate.
- Defer Adobe internals to Adobe. Identity and SSO setup, exact console menus, and API authentication
  are Adobe-owned and change; follow Adobe's official documentation and keep this process around it.
