# Solution Overview

## What this is

An enterprise organization running Google Workspace at scale (tens of thousands of users) cannot
administer or evidence its tenant with the Admin console and manual screenshots alone. Provisioning,
license moves, sharing reviews, and audit "reports" pasted from console screens do not scale, are not
repeatable, and are not defensible to auditors.

This solution builds an **Admin SDK & API automation and reporting toolkit**: a secure service
identity, least-scope authenticated Python against the Google Workspace **Directory**, **Reports**,
**Drive**, and **Groups** APIs, a set of reusable automation and reporting patterns (provisioning,
license, sharing, login/audit reports), and a scheduling model — so that administration and evidence
become automated, repeatable, and auditable.

It is deliberately **distinct** from an Apps Script / AppSheet governance solution. This toolkit is
about **building** first-party administrative automation and reporting against Google's Admin SDK and
REST APIs from an external Python runtime, using a properly configured service identity — not about
governing citizen-developer platforms.

The toolkit is **safe by default**. Every discovery and reporting tool is read-only; every tool that
can change the tenant defaults to `--dry-run` and only mutates when the operator passes `--apply`.
**No credentials, keys, or secrets are ever written into code.** Authentication uses OAuth, a secured
service-account credential, or Application Default Credentials (ADC), with the **narrowest** OAuth
scopes each task requires.

## How it works

The toolkit has five layers.

1. **Secure service identity.** A dedicated Google Cloud project holds a **service account** used for
   automation. For APIs that act on user data (Directory, Reports, Drive, Groups) the service account is
   granted **domain-wide delegation (DWD)** in the Admin console, authorized for an **explicit, minimal
   list of OAuth scopes** and impersonating a **least-privilege admin** subject — never a super-admin
   for routine reads. Alternatively, an OAuth client (installed-app / user consent) is used for
   interactive, per-admin operations. The service-account **key is never committed**; credentials come
   from ADC, a secrets manager, or Workload Identity where the runtime supports it.

2. **Least-scope authentication.** A single auth helper centralizes credential acquisition and scope
   selection so every tool requests only the scopes it needs — for example
   `admin.directory.user.readonly` for a user report versus `admin.directory.user` only for a
   provisioning tool run with `--apply`. Read-only scopes are the default; write scopes are opt-in.

3. **Authenticated API access.** A thin, reusable API-client layer wraps the Google API Python client
   (`google-api-python-client`) with automatic **pagination**, **exponential-backoff retry** on 429 /
   5xx responses, and consistent error handling — so every tool talks to Directory / Reports / Drive /
   Groups the same way.

4. **Reusable automation & reporting patterns.** On top of the client sit the patterns the toolkit
   ships: user / OU / license **provisioning** (idempotent, dry-run first), **Drive sharing exposure**
   reporting, **login / admin audit** reporting from the Reports API, and **group membership /
   configuration** reporting — each producing a named, timestamped artifact (CSV/JSON) suitable for
   audit evidence.

5. **Scheduling model.** A scheduling/config helper renders the exact command lines, cron / Cloud
   Scheduler / Task Scheduler entries, and least-scope service-identity requirements needed to run each
   report on a cadence — so recurring evidence is produced automatically and consistently.

## Reference model

The toolkit is built and operated to a single naming convention. Every artifact it creates is named
`<Purpose> – <Scope> – <Stage>` and that exact name is reused in testing, troubleshooting, and the
scripts:

| Artifact | Name (this solution) |
|---|---|
| Automation Google Cloud project | `Automation Project – Workspace – Core` |
| Automation service account | `Automation SA – AdminSDK – Core` |
| Domain-wide-delegation grant | `DWD Grant – AdminSDK – LeastScope` |
| Least-privilege impersonation subject | `Impersonation Subject – Reports – ReadOnly` |
| Discovery / assessment report | `Discovery Report – Tenant – Assess` |
| User/OU/license provisioning run | `Provisioning Run – Finance-OU – Pilot` |
| Drive sharing exposure report | `Sharing Report – External – Validate` |
| Login/admin audit report | `Audit Report – Login – Validate` |
| Scheduled report definition | `Schedule Definition – Reports – Expand` |

## Benefits

- **Repeatable, auditable administration** — provisioning and reports run identically every time and
  emit dated evidence files, replacing manual screenshots.
- **Least privilege by construction** — every task requests only the scopes it needs; write access is
  opt-in and dry-run first.
- **No secrets in code** — credentials come from ADC / a secured credential / a secrets manager; keys
  are never committed or exported into the repo.
- **Safe to run** — read-only or `--dry-run` by default; a destructive run requires an explicit
  `--apply` and prints exactly what it will change first.
- **Portable** — standard-library-first Python plus the official Google client; runs on any Python
  3.10+ host, in a container, or in a scheduler.

## Limitations

- The toolkit **automates and reports on** Workspace; it does not replace the Admin console for
  interactive, one-off, or preview-only settings.
- **Reports API data latency** varies by application; some activity events surface with a delay
  (**verify the current latency for your event types** in Google's documentation). Reports are
  point-in-time evidence, not real-time monitoring.
- Some Workspace/Gemini settings are **not exposed by a stable public API** (flag "verify in your
  tenant"); those remain console-managed and are out of scope for automation here.
- Domain-wide delegation is powerful; it must be scoped and reviewed as described in Best Practices.

## Deployment model

This solution follows the house model — **Assess → Design → Configure → Pilot → Validate → Expand** —
pilot-first, with explicit pass/fail gates and a documented rollback for any production change
(provisioning writes especially). You stand up and validate the service identity and read-only
reporting first, prove automation on a **pilot OU/group** in dry-run, then apply and expand.
