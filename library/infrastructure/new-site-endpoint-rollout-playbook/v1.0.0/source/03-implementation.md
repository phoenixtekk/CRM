# 3. Implementation Guide — New-Site Endpoint Rollout Playbook

Follow these steps **in order**, in the **Microsoft Intune admin center**
(`https://intune.microsoft.com`) and the **Microsoft Entra admin center**
(`https://entra.microsoft.com`). The order matches the dependency chain: network/identity →
provisioning → baseline → apps/printers → validation → go-live → expand.

> Model: the first site is the pilot. Run the full sequence for the pilot site, pass the go-live
> gate, then repeat for each subsequent site by cloning the site group and assignments and changing
> only the site name. Name every object created `<Purpose> – <Site> – <Stage>` (e.g.
> `New Site – Site A – Pilot`).

## Step 1 — Confirm network and identity readiness
1. From a device on the new site's network, browse to `https://login.microsoftonline.com` and
   `https://enrollment.manage.microsoft.com` — both must load.
2. Run `NEWSITE-Discovery.ps1` on a device at the site to check cloud reachability, DNS, and time
   sync.
3. Do not continue until the site is reachable; provisioning and everything after it depend on this.

## Step 2 — Build the site device group
1. Entra → **Groups → New group**.
2. **Group type:** Security. **Group name:** `New Site – Site A – Pilot` (use `Production` as the
   Stage for sites after the pilot). **Membership type:** Assigned (or a dynamic rule on the site's
   device-name prefix or enrollment tag). **Create**.
3. Alternatively, run `NEWSITE-Set-SiteGroupTargeting.ps1 -SiteName "Site A" -Stage "Pilot"` to
   create the group and add the site's devices by name pattern or device ID list.

## Step 3 — Provision the site's devices
1. Enroll the site's devices using your configured method:
   - Autopilot: Intune → **Devices → Enrollment → Windows → Windows Autopilot deployment profiles**;
     confirm the site's imported devices are assigned a profile, then run the out-of-box experience
     on each device.
   - Automatic enrollment: join each device to Entra ID (**Settings → Accounts → Access work or
     school → Connect → Join this device to Microsoft Entra ID**), which auto-enrolls it.
2. Confirm each device appears under Intune → **Devices → All devices** and is a member of the site
   device group (sync the group membership if you used a static list).

## Step 4 — Apply the existing baseline to the site
1. Intune → **Devices → Compliance**; open your standard compliance policy → **Properties →
   Assignments → Edit → Add groups →** `New Site – Site A – Pilot`. **Review + save**.
2. Intune → **Endpoint security → Security baselines**; open your standard baseline → **Properties →
   Assignments →** add `New Site – Site A – Pilot`. **Save**.
3. Assign any standard configuration profiles the fleet uses to the same site group. You are reusing
   existing policies — do not author new ones.

## Step 5 — Deploy the site's apps
1. Intune → **Apps → Windows**; for each app in the site's app set, open the app → **Properties →
   Assignments → Edit**.
2. Under **Required**, **Add group →** `New Site – Site A – Pilot`. **Review + save**.
3. Keep the assignment name consistent in your records as `App Deployment – Site A – Pilot`.

## Step 6 — Deploy the site's printers
1. Use your existing printer method:
   - Universal Print: Intune → **Devices → Configuration**; open your Universal Print printer profile
     (or create a configuration that provisions the site's printers) → **Assignments → Add groups →**
     `New Site – Site A – Pilot`. **Save**.
   - Print server / connector: assign your printer-deployment configuration to the site group the
     same way.
2. Record the assignment as `Printer Deployment – Site A – Pilot`.

## Step 7 — Validate each device
1. On each provisioned device, sync policy (**Settings → Accounts → Access work or school → Info →
   Sync**).
2. Run `NEWSITE-Validation.ps1` on each device → confirms it is enrolled, baseline-compliant, the
   site apps are installed, and the site printers are present.
3. Run `NEWSITE-Report.ps1` → shows the site's overall rollout status (provisioned / baselined /
   app-ready / validated counts) from Intune.

## Step 8 — Run the go-live checklist
Open the site only when every item passes. Use `NEWSITE-Report.ps1` and `NEWSITE-Validation.ps1` as
the evidence.

- [ ] Network/identity confirmed at the site (Step 1)
- [ ] All site devices enrolled and in the site group (Step 3)
- [ ] Baseline compliant on all devices — compliance policy + security baseline applied (Step 4)
- [ ] Site apps installed on all devices (Step 5)
- [ ] Site printers present and a test page prints (Step 6)
- [ ] Each device passes `NEWSITE-Validation.ps1`
- [ ] A representative user can sign in, open the site apps, and print
- [ ] Any failures remediated with `NEWSITE-Remediation.ps1` and re-validated

## Step 9 — Expand to the next site
1. Repeat Steps 2–8 for the next site, naming its group `New Site – Site B – Production` and its
   assignments accordingly.
2. Reuse the identical baseline, and the app/printer assignment pattern — change only the site name
   and Stage.
3. Re-run `NEWSITE-Report.ps1` per site to confirm each new site passes the same go-live gate.

---
### Order of operations
`Confirm network/identity → site device group → provision devices → apply baseline → deploy site
apps → deploy site printers → validate → go-live checklist → expand`
