# Requirements

These are the prerequisites **specific to this toolkit**. They build on the shared category baseline in
`global-requirements-google.md` (a provisioned Workspace/Cloud Identity tenant with a super-admin, a
defined identity source of truth, a pilot OU/group, and change control) — verify those first, then the
solution-specific items below. Each item lists Description, Why required, How to verify, and How to
implement if missing.

## 1. Google Workspace super-admin (for one-time delegation setup only)

- **Description:** A Workspace **super-admin** account, used only to create the Google Cloud project,
  enable APIs, and authorize domain-wide delegation. Routine automation does **not** run as super-admin.
- **Why required:** Enabling Admin SDK APIs and adding a DWD grant with scopes are super-admin actions
  in the Admin console (**Security → Access and data control → API controls → Domain-wide delegation**).
- **How to verify:** Sign in to **admin.google.com**; confirm the account shows the **Super Admin** role
  under **Directory → Users → (account) → Admin roles and privileges**.
- **How to implement if missing:** Have an existing super-admin grant the role, or perform the one-time
  setup steps under an existing super-admin.

## 2. A dedicated Google Cloud project for automation

- **Description:** A Google Cloud project — `Automation Project – Workspace – Core` — that hosts the
  automation service identity and has the required APIs enabled: **Admin SDK API**, **Google Drive API**,
  and (if used) **Cloud Identity API**. The **Reports** and **Directory** capabilities are part of the
  Admin SDK API.
- **Why required:** API calls are billed/attributed to and quota-managed per project; keeping automation
  in its own project isolates it and simplifies audit.
- **How to verify:** In the Google Cloud console, **APIs & Services → Enabled APIs & services** lists
  the Admin SDK API and Drive API for the project.
- **How to implement if missing:** Create the project, then **enable** the Admin SDK API, Drive API, and
  Cloud Identity API from **APIs & Services → Library**.

## 3. Automation service identity with domain-wide delegation

- **Description:** A service account — `Automation SA – AdminSDK – Core` — with **domain-wide delegation**
  authorized in the Admin console for an **explicit, minimal scope list** (`DWD Grant – AdminSDK –
  LeastScope`), impersonating a least-privilege admin subject (`Impersonation Subject – Reports –
  ReadOnly`) rather than a super-admin.
- **Why required:** Directory / Reports / Drive / Groups calls act on domain user data and require a
  delegated identity; least-scope + least-privilege impersonation limits blast radius.
- **How to verify:** In the Admin console **API controls → Domain-wide delegation**, the service
  account's **client ID** is listed with exactly the intended scopes (no broader wildcard). Run the
  toolkit's auth validator (see §5) — it confirms each scope resolves.
- **How to implement if missing:** Create the service account, note its **OAuth client ID**, then add the
  DWD grant with the minimal scope list. Start with `*.readonly` scopes; add a write scope only for the
  provisioning tool.

## 4. No exported service-account key committed anywhere

- **Description:** Credentials are supplied at runtime via **Application Default Credentials (ADC)**, a
  **secrets manager**, or **Workload Identity** — never a `.json` key file stored in the repo or baked
  into an image.
- **Why required:** A leaked service-account key with DWD is a domain-wide compromise. The toolkit's
  security posture depends on keys never living in source control.
- **How to verify:** Repo scan finds no `*.json` key, no private-key material, and no credentials in
  environment files committed to version control. The scripts read credentials only from ADC / a secured
  path passed at runtime.
- **How to implement if missing:** Configure ADC (`gcloud auth application-default login` for local dev,
  or attached identity in cloud), or store the credential in a secrets manager and reference it by path
  at runtime. Remove and **rotate** any key that was previously committed.

## 5. Python 3.10+ toolchain with the Google client libraries

- **Description:** Python **3.10 or newer** with `google-api-python-client` and `google-auth` available
  (a virtual environment is recommended). The toolkit is otherwise standard-library-first.
- **Why required:** The scripts call the Google APIs through the official client and use modern Python
  typing/features.
- **How to verify:** `python --version` reports ≥ 3.10; `pip show google-api-python-client google-auth`
  reports installed versions.
- **How to implement if missing:** Install Python 3.10+, create a venv, and
  `pip install google-api-python-client google-auth`.

## 6. Least-privilege admin roles and OAuth scope inventory

- **Description:** A documented mapping of **which task needs which scope** and **which impersonation
  subject** it uses — read-only scopes for reporting (`admin.directory.user.readonly`,
  `admin.reports.audit.readonly`, `drive.readonly`, `admin.directory.group.readonly`) and write scopes
  only where a provisioning tool is run with `--apply`.
- **Why required:** Least-scope is the core security control; it must be explicit and reviewed, not
  incidental.
- **How to verify:** The scope inventory exists and matches the DWD grant; the auth validator (script 1)
  reports each configured scope and flags any scope that is broader than the task requires.
- **How to implement if missing:** Build the inventory from the tool set below, grant only those scopes,
  and review it as part of change control whenever a new automation is added.
