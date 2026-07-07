#!/usr/bin/env python3
# bce_scope_config_helper.py — build access levels (dry-run) OR export the zero-trust scope inventory
#
# PURPOSE: Two modes. `build` composes an Access Context Manager access level (basic attribute
#          conditions or a CEL custom-level skeleton) and prints the exact gcloud/YAML it would apply —
#          it changes NOTHING unless --apply is passed. `export` produces a read-only inventory of the
#          current zero-trust scope (which backends are behind IAP, which access levels exist, which
#          broad firewall paths remain) for governance sign-off.
# HOW TO RUN: python bce_scope_config_helper.py build  --policy <ID> --name "<Title>"
#                    [--ip-ranges CIDR,CIDR] [--regions US,CA] [--require-corp-device] [--custom-cel]
#                    [--dry-run|--apply]
#             python bce_scope_config_helper.py export --org <ORG_ID> --project <P> [--format json|table]
#             (Python 3.10+, gcloud on PATH, ADC/`gcloud auth`; see --help)
# EXPECTED RESULTS: build -> printed YAML/gcloud (or applied level with --apply). export -> inventory
#          printed as table or JSON. Exit 0 on success.

import argparse
import json
import shutil
import subprocess
import sys

IAP_TCP_FORWARDING_RANGE = "35.235.240.0/20"
BROAD_RANGES = {"0.0.0.0/0", "::/0"}


def have_gcloud():
    if not shutil.which("gcloud"):
        print("ERROR: gcloud CLI not found on PATH.", file=sys.stderr)
        sys.exit(2)


def gcloud_json(args):
    out = subprocess.run(["gcloud"] + args + ["--format=json"], capture_output=True, text=True)
    if out.returncode != 0:
        print(f"  WARN: {' '.join(args)} -> {out.stderr.strip().splitlines()[:1]}", file=sys.stderr)
        return None
    try:
        return json.loads(out.stdout or "null")
    except json.JSONDecodeError:
        return None


def slugify(title):
    keep = [c.lower() if c.isalnum() else "_" for c in title]
    s = "".join(keep)
    while "__" in s:
        s = s.replace("__", "_")
    return s.strip("_")[:50] or "access_level"


# ---------- build mode ----------
def build_basic_yaml(args):
    """Emit a basic access-level YAML spec (attribute conditions)."""
    cond = {}
    if args.ip_ranges:
        cond["ipSubnetworks"] = [r.strip() for r in args.ip_ranges.split(",") if r.strip()]
    if args.regions:
        cond["regions"] = [r.strip() for r in args.regions.split(",") if r.strip()]
    if args.require_corp_device:
        # Device-policy shape is version-dependent; verify exact fields for your org's signal source.
        cond["devicePolicy"] = {"requireCorpOwned": True}  # verify in your organization
    spec = [{"conditions": [cond]}]
    return spec


def build_custom_cel(args):
    """Emit a CEL skeleton for a custom access level (combined logic to review)."""
    parts = []
    if args.ip_ranges:
        ranges = ",".join(f'"{r.strip()}"' for r in args.ip_ranges.split(","))
        parts.append(f"origin.ip in [{ranges}]  // verify CEL attribute names for your version")
    if args.regions:
        regs = ",".join(f'"{r.strip()}"' for r in args.regions.split(","))
        parts.append(f"origin.region_code in [{regs}]")
    if args.require_corp_device:
        parts.append("device.is_corp_owned == true  // verify device attribute for your signal source")
    expr = " && ".join(parts) or "true  // TODO: author the CEL condition"
    return expr


def run_build(args):
    if not args.policy or not args.name:
        print("ERROR: build requires --policy and --name.", file=sys.stderr)
        sys.exit(2)
    applying = args.apply and not args.dry_run
    print(f"== build access level '{args.name}' ==  mode: "
          f"{'APPLY' if applying else 'DRY-RUN (no changes)'}")
    level_id = slugify(args.name)
    if args.custom_cel:
        expr = build_custom_cel(args)
        print("\nCustom (CEL) access level — review this expression, keep it in version control:")
        print(f"  id:    {level_id}")
        print(f"  title: {args.name}")
        print(f"  expr:  {expr}")
        print("\nApply command (custom level via YAML):")
        print(f"  gcloud access-context-manager levels create {level_id} \\")
        print(f"    --policy={args.policy} --title=\"{args.name}\" \\")
        print(f"    --custom-level-spec custom_level.yaml   # containing the CEL 'expr' above")
        print("  NOTE: verify --custom-level-spec flag/shape for your gcloud version.")
    else:
        spec = build_basic_yaml(args)
        print("\nBasic access-level spec (write to level.yaml):")
        print(json.dumps(spec, indent=2))
        print("\nApply command:")
        print(f"  gcloud access-context-manager levels create {level_id} \\")
        print(f"    --policy={args.policy} --title=\"{args.name}\" \\")
        print(f"    --basic-level-spec level.yaml")
    if applying:
        print("\n[apply] Writing spec and creating the level is intentionally left to the operator so")
        print("        the YAML can be reviewed and version-controlled first. Copy the command above.")
        # We deliberately do NOT auto-create here; access-level creation is a governed change that
        # should go through the reviewed YAML. --apply is accepted for interface symmetry only.
    else:
        print("\n(No changes made. Review the YAML/CEL, then run the printed gcloud command.)")
    return 0


# ---------- export mode ----------
def run_export(args):
    if not args.org or not args.project:
        print("ERROR: export requires --org and --project.", file=sys.stderr)
        sys.exit(2)
    print(f"== export zero-trust scope (READ-ONLY) — org={args.org} project={args.project} ==")
    inventory = {"access_levels": [], "iap_backends": [], "residual_broad_firewalls": []}

    policies = gcloud_json(["access-context-manager", "policies", "list",
                            f"--organization={args.org}"]) or []
    for p in policies:
        pid = p.get("name", "").split("/")[-1]
        for lv in gcloud_json(["access-context-manager", "levels", "list", f"--policy={pid}"]) or []:
            inventory["access_levels"].append({
                "title": lv.get("title"),
                "has_device": "devicePolicy" in json.dumps(lv) or "custom" in lv})

    for b in gcloud_json(["compute", "backend-services", "list", f"--project={args.project}"]) or []:
        inventory["iap_backends"].append({
            "name": b.get("name"), "iap_enabled": bool(b.get("iap", {}).get("enabled"))})

    for r in gcloud_json(["compute", "firewall-rules", "list", f"--project={args.project}"]) or []:
        if r.get("direction") != "INGRESS" or r.get("disabled"):
            continue
        sources = set(r.get("sourceRanges", []))
        if sources & BROAD_RANGES:
            ports = set()
            for a in r.get("allowed", []):
                ports.update(a.get("ports", []) or [])
            inventory["residual_broad_firewalls"].append({
                "rule": r.get("name"), "sources": sorted(sources & BROAD_RANGES),
                "ports": sorted(ports)})

    if args.format == "json":
        print(json.dumps(inventory, indent=2))
    else:
        print(f"\naccess levels ({len(inventory['access_levels'])}):")
        for lv in inventory["access_levels"]:
            print(f"  - {lv['title']}  device_condition={lv['has_device']}")
        print(f"\nIAP backends ({len(inventory['iap_backends'])}):")
        for b in inventory["iap_backends"]:
            print(f"  - {b['name']}  iap_enabled={b['iap_enabled']}")
        print(f"\nresidual broad firewalls ({len(inventory['residual_broad_firewalls'])}) "
              f"— retire these as coverage expands:")
        for f in inventory["residual_broad_firewalls"]:
            print(f"  - {f['rule']}  {f['sources']} ports={f['ports']}")
    return 0


def main():
    ap = argparse.ArgumentParser(description="Build access levels (dry-run) or export zero-trust scope.")
    sub = ap.add_subparsers(dest="mode", required=True)

    b = sub.add_parser("build", help="Compose an access level (dry-run by default).")
    b.add_argument("--policy", help="Access Context Manager policy ID")
    b.add_argument("--name", help="Access level title, e.g. 'Access Level – Corp-Managed – v1'")
    b.add_argument("--ip-ranges", help="Comma-separated CIDRs for a trusted-network condition")
    b.add_argument("--regions", help="Comma-separated region codes, e.g. US,CA")
    b.add_argument("--require-corp-device", action="store_true",
                   help="Add a corp-managed device condition (verify signal source/fields)")
    b.add_argument("--custom-cel", action="store_true", help="Emit a CEL custom-level skeleton instead")
    b.add_argument("--dry-run", action="store_true", help="Default; print only.")
    b.add_argument("--apply", action="store_true",
                   help="Interface flag; access-level creation is still done via the reviewed YAML.")

    e = sub.add_parser("export", help="Export the current zero-trust scope inventory (read-only).")
    e.add_argument("--org", help="GCP Organization ID")
    e.add_argument("--project", help="Project to inventory")
    e.add_argument("--format", choices=["json", "table"], default="table")

    args = ap.parse_args()
    have_gcloud()
    if args.mode == "build":
        return run_build(args)
    return run_export(args)


if __name__ == "__main__":
    sys.exit(main())
