# 7. Best Practices — Delivery Optimization

## Download mode & grouping
- **Prefer Group (2)** for any organization with more than one subnet/VLAN — it is the mode that
  produces the biggest bandwidth saving by letting devices peer across internal networks.
- **Scope the group to the physical network, not the whole tenant.** Match `DOGroupIDSource` to how
  your networks actually segment: **DHCP Option 234 (3)** or **AD Site (1)** for per-site peering;
  reserve **Entra tenant ID (5)** for small orgs where all devices genuinely share networks.
- **Don't over-narrow either** — restricting to subnet when a site has several small subnets can strand
  devices with no peers. Validate real peering (Test 4) before committing.
- **Never use Bypass (100) on Windows 11** — it is deprecated. Use **HTTP Only (0)** to disable peering
  or **Simple (99)** for offline networks.

## Bandwidth
- **Use absolute (KB/s) caps on low-bandwidth branch circuits** — Microsoft's own recommendation — and
  reserve percentage caps for well-provisioned sites.
- **Throttle background hard, foreground gently.** Users wait on foreground (interactive) content;
  monthly updates are background and can be squeezed.
- **Use business-hours limits** to protect the WAN during the workday and open the taps after hours.
- **Leave the 20 GB monthly upload cap** unless you have a specific reason to lower it; uploads to
  internet peers only apply in Internet (3) mode.

## Cache
- **Give the cache room.** A bigger, longer-lived cache (`DOMaxCacheSize`/`DOAbsoluteMaxCacheSize`,
  `DOMaxCacheAge`) keeps more content available for peers, which raises the peer hit-rate and the saving.
- **Relocate the cache** (`DOModifyCacheDrive`) on devices with small OS drives so DO isn't starved.

## Microsoft Connected Cache (MCC)
- **Consider MCC when peering alone leaves too much HTTP traffic** — large sites, or sites where the
  *first* copy of every distinct file still crosses the internet. MCC eliminates that first copy.
- **Keep MCC as a separate project.** Standing up and operating a cache node is its own engagement;
  this solution only points DO at an existing node (`DOCacheHost` / `DOCacheHostSource`).

## Operations & measurement
- **Baseline before, measure after.** Always capture peer/HTTP/cache bytes before enabling Group mode
  and after, so the saving is a number, not a claim (`DELOPT-Report-Savings.ps1`).
- **Watch the Intune Delivery Optimization report** for fleet-wide trends after each rollout wave.
- **Roll out in waves** and re-measure — savings compound as more devices share content.
- **Keep one authority.** Set DO only from this Intune policy; remove conflicting GPO/ConfigMgr DO
  settings so group scoping stays intact.

## Boundaries (what DO is *not*)
- DO does **not** choose or schedule updates — that is **Windows Update for Business** (update rings /
  what & when).
- DO does **not** patch third-party apps (**Third-Party App Patching**) or package Win32 apps
  (**Win32 App Packaging & Deployment**).
- DO optimizes the **delivery** of all of the above. Deploy those solutions for the *what/when*; deploy
  this one so it all arrives **efficiently**.
