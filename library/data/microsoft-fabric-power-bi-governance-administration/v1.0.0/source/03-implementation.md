# 3. Implementation Guide — Microsoft Fabric & Power BI Governance & Administration

Follow these steps in order. Every object you create is named with one convention —
`<Purpose> – <Scope> – <Stage>` — and reused by that exact name in later steps, in testing, in
troubleshooting, and in the scripts. Do everything against the **pilot ring first**; nothing goes
tenant-wide until the Validate step and a change approval.

Portal paths are current at time of writing; Microsoft moves menus, so if a path differs, search the
admin portal for the setting name. Sign in throughout at `https://app.powerbi.com` with an account that
holds the Fabric Administrator / Power BI Administrator role.

Objects created in this guide (reuse these exact names):
- Groups: `Governance Pilot Ring – Fabric – Ring1`, `Fabric Admins – Platform – Prod`, `BI Creators – Analytics – Pilot`, `BI Content Certifiers – Analytics – Prod`, `Fabric Admin API Apps – Platform – Prod`
- Baseline: `Tenant Governance Baseline – Fabric/Power BI – v1`
- Capacity: `Fabric Capacity – Analytics – Prod`
- Workspaces: `Sales BI – Content – Dev`, `Sales BI – Content – Test`, `Sales BI – Content – Prod`
- Pipeline: `Deployment Pipeline – Sales BI – DevTestProd`

---

## Step 0 — Assess (inventory before you change anything)
1. On the workstation, open PowerShell and run the discovery script:
   `powershell -ExecutionPolicy Bypass -File .\FABGOV-Discovery.ps1`
2. Sign in when prompted (delegated admin). The script prints current **tenant settings** of interest,
   the list of **capacities**, a **workspace inventory** (with those that are personal or orphaned
   flagged), and a **sharing/export** summary from the activity log.
3. Save the output. This is your "before" picture and the evidence you will compare against in Validate.
4. Create the five security groups from requirement 2.3 in Entra → Groups if they do not exist. Add a
   handful of willing users to `Governance Pilot Ring – Fabric – Ring1` — this is your safe test
   audience for tenant-scoped settings.

---

## Step 1 — Configure the tenant-settings baseline (scoped to the pilot ring)
You will author `Tenant Governance Baseline – Fabric/Power BI – v1`. For **every** setting below, in the
admin portal, set it to **apply to specific security groups** and choose `Governance Pilot Ring – Fabric
– Ring1` (except where noted), so you are testing on the ring, not the tenant. Do not select "The entire
organization" yet.

1. Go to Settings (gear) → **Admin portal** → **Tenant settings**.
2. **Export and sharing settings** — configure and pilot-scope each:
   - **Publish to web** → set to **disabled** (or "Only existing embed codes"); publish-to-web exposes
     reports anonymously and is the highest-risk export.
   - **Export to Excel / Export data** → enable only for `Governance Pilot Ring – Fabric – Ring1` during
     pilot.
   - **Share content with external users** / **Guest users can access** → enable only for a named group,
     not the whole org.
   - **Allow users to apply sensitivity labels** — leave alignment to the Purview solution; note it here
     but defer classification decisions to compliance.
3. **Workspace settings**:
   - **Create workspaces (new experience)** → apply to **specific security groups** →
     `BI Creators – Analytics – Pilot`. This stops anyone from spinning up a workspace.
4. **Content certification** (Export and sharing / Discovery):
   - **Certification** → enable, apply to `BI Content Certifiers – Analytics – Prod`, and set the
     certification support URL to your governance page. Only certifiers can mark content "Certified".
5. **Admin API settings**:
   - **Service principals can access read-only admin APIs** → enable for
     `Fabric Admin API Apps – Platform – Prod` (needed by 2.6). *Verify the exact setting name; the
     admin-API surface changes.*
   - **Enhance admin API responses with detailed metadata / DAX and mashup expressions** → enable so the
     scanner returns lineage detail for monitoring.
6. Record every change (setting, before value, after value) in your change-control record. Do **not**
   flip anything to "entire organization" in this step.

> Any setting that is in preview or that gates on a specific license (for example some Fabric workload
> or Copilot-in-Fabric settings) is marked as such in the portal — *verify current availability and
> licensing in your tenant before relying on it.*

---

## Step 2 — Configure capacity management and workload settings
1. Admin portal → **Capacity settings** → open `Fabric Capacity – Analytics – Prod`.
2. Under **Workloads / capacity settings**, review the workload limits (for example semantic-model
   memory, max intermediate row set) and set them to your agreed values. Leave defaults unless you have
   a measured reason to change them.
3. Under **Contributor permissions / capacity admins**, set the capacity admins to
   `Fabric Admins – Platform – Prod` and restrict who can assign workspaces to this capacity.
4. Turn on capacity monitoring: install the **Microsoft Fabric Capacity Metrics** app from
   `https://app.powerbi.com` → Apps → Get apps → search "Fabric Capacity Metrics", and connect it to
   `Fabric Capacity – Analytics – Prod`. This is your utilization and throttling view.
5. Note the capacity's SKU and region for the cost baseline; the `FABGOV-Report.ps1` script will pull
   utilization to compare against it.

---

## Step 3 — Build the workspace architecture and access model
1. In the Power BI service, click **Workspaces → New workspace**. Create three workspaces:
   `Sales BI – Content – Dev`, `Sales BI – Content – Test`, `Sales BI – Content – Prod`.
2. For each workspace, open **Workspace settings → Premium/License** and assign it to
   `Fabric Capacity – Analytics – Prod` (Prod and Test at minimum; Dev may stay on shared/Pro during
   pilot).
3. Assign **roles to groups, never to individuals** (open each workspace → **Manage access → Add people
   or groups**):
   - `Sales BI – Content – Dev` → `BI Creators – Analytics – Pilot` = **Contributor**;
     `Fabric Admins – Platform – Prod` = **Admin**.
   - `Sales BI – Content – Test` → `BI Content Certifiers – Analytics – Prod` = **Member**;
     `Fabric Admins – Platform – Prod` = **Admin**.
   - `Sales BI – Content – Prod` → viewers get access via an **app** or a Viewer group, not direct
     edit; `Fabric Admins – Platform – Prod` = **Admin** only. Keep Prod edit rights minimal.
4. You now have a role model where creation is gated, editing is delegated to Dev, and Prod is
   promotion-only.

---

## Step 4 — Create the deployment pipeline (dev → test → prod lifecycle)
1. In the service, go to **Deployment pipelines** (left nav) → **Create pipeline**. Name it
   `Deployment Pipeline – Sales BI – DevTestProd`. Choose three stages (Development, Test, Production).
2. **Assign a workspace to each stage**: Development → `Sales BI – Content – Dev`, Test →
   `Sales BI – Content – Test`, Production → `Sales BI – Content – Prod`.
3. Put a piece of pilot content (a simple report + semantic model) in `Sales BI – Content – Dev`.
4. Click **Deploy to Test**, then later **Deploy to Production**, to prove the promotion path. Use the
   **compare** view to confirm only intended changes move forward.
5. Set **deployment rules** on the Production stage (for example, point the semantic model at the
   production data source) so promotion swaps connections automatically instead of by hand.
6. Manage pipeline access so only `Fabric Admins – Platform – Prod` can deploy to Production — promotion
   to prod is a governed action.

---

## Step 5 — Turn on admin monitoring
1. Admin portal → **Monitoring / Audit logs**: confirm the **activity log** is being retained and, if
   your organization streams it, that it flows to your Microsoft 365 / Purview audit pipeline. (Purview-
   side reporting is delivered by the Purview solutions; here you only confirm the log is available.)
2. Admin portal → open the **admin monitoring** / **Feature usage and adoption** report if available in
   your tenant, and the **Fabric Capacity Metrics** app from Step 2 — these are your standing dashboards.
3. Confirm the **scanner API** is reachable by running `FABGOV-Discovery.ps1` again; it should now return
   the enhanced metadata you enabled in Step 1.5.
4. Schedule `FABGOV-Report.ps1` (see the testing guide) to produce the weekly capacity-and-activity
   summary, using the service principal from requirement 2.6 for unattended runs.

---

## Step 6 — Pilot and Validate
1. With everything scoped to `Governance Pilot Ring – Fabric – Ring1`, have the ring users work
   normally for a short pilot window: create content in Dev, promote through the pipeline, share, and
   export.
2. Run `FABGOV-Validate.ps1`. It checks that the baseline settings resolve as intended for the ring,
   that workspace roles match the model, that the workspaces are on the right capacity, and that the
   pipeline stages are paired correctly. See the testing guide for the pass/fail gates.
3. Confirm nothing legitimate broke (a ring user can still do their real work; only the risky actions are
   constrained).
4. Record results and obtain change approval (global G8) before any tenant-wide application.

---

## Step 7 — Expand (tenant-wide, under change control)
1. For each approved tenant setting, return to Admin portal → Tenant settings and change the scope from
   `Governance Pilot Ring – Fabric – Ring1` to the approved production scope (a broad "all except"
   group, or the entire organization where the business approved it). Change **one setting at a time**
   and re-run `FABGOV-Validate.ps1` after each.
2. Onboard additional workloads by repeating Steps 3–4 with new `<Workload> – Content – Dev/Test/Prod`
   workspaces and their own pipeline, reusing the same groups and capacity model.
3. Keep `FABGOV-Report.ps1` on its schedule and review capacity utilization and sharing/export trends at
   your governance cadence. Any regression or unexpected spend is your signal to revisit a setting under
   change control (with the recorded rollback).
