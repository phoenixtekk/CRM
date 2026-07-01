#!/usr/bin/env python3
"""
build-explore-pages.py — create 6 public "solution category" landing pages (free top-of-funnel)
on Wiki.js at explore/<slug>, each showcasing the paid solutions in that area with links to the
store, then repoint the home-page cards to them.

Env: WIKIJS_URL / WIKIJS_TOKEN (load ./.wikijs.env first).
Usage: python tools/build-explore-pages.py            (publishes pages + repoints home cards)
"""
import os, json, html, re
from urllib import request as u, error as e

URL, TOK = os.environ["WIKIJS_URL"].rstrip("/"), os.environ["WIKIJS_TOKEN"]
UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124 Safari/537.36"
STORE = "https://workplace.phoenixtekk.com"


def gql(query, variables=None, tolerate=None):
    body = json.dumps({"query": query, "variables": variables or {}}).encode()
    r = u.Request(URL + "/graphql", data=body, method="POST")
    r.add_header("Content-Type", "application/json"); r.add_header("Authorization", "Bearer " + TOK); r.add_header("User-Agent", UA)
    d = json.loads(u.urlopen(r, timeout=30).read())
    if d.get("errors"):
        codes = {(x.get("extensions") or {}).get("code") for x in d["errors"]}
        if tolerate and codes <= set(tolerate): return None
        raise SystemExit("GQL " + json.dumps(d["errors"])[:400])
    return d["data"]


def sol(name, tag, blurb, url_key):
    return {"name": name, "tag": tag, "blurb": blurb, "url_key": url_key}

AREAS = [
 {"slug": "microsoft-365-identity", "kicker": "KNOWLEDGE AREA · IDENTITY",
  "title": "Microsoft 365 & Identity",
  "tagline": "Identity is the new perimeter. Make Microsoft Entra the backbone of secure, frictionless sign-in across your estate.",
  "challenge": "Most breaches start with identity — over-permissive access, password-based sign-in, and Conditional Access that looks fine until it's tested. Getting Entra right is high-stakes and easy to misconfigure.",
  "deliver": "Field-tested configurations for Entra ID, Conditional Access, passwordless authentication, and data governance — the exact, ordered steps to stand up a hardened identity layer that Conditional Access can actually enforce.",
  "sols": [
    sol("Conditional Access Integration", "Zero Trust access", "Enforce access policies that hold up under audit — compliant, registered devices only.", "conditional-access-integration-commercial"),
    sol("Windows Hello for Business", "Passwordless", "Phishing-resistant, hardware-backed sign-in that replaces passwords on Windows.", "windows-hello-for-business-commercial"),
    sol("OneDrive for Business", "Data governance", "Known-folder backup and data protection done the right way, fleet-wide.", "onedrive-for-business-commercial"),
  ]},
 {"slug": "endpoint-device-management", "kicker": "KNOWLEDGE AREA · INTUNE",
  "title": "Endpoint & Device Management",
  "tagline": "Provision, manage, and validate every device — Windows and Mac — from the cloud, with zero-touch enrollment and policy you can prove.",
  "challenge": "Manual setup doesn't scale, and 'managed' means nothing if you can't validate it. Mixed Windows/Mac fleets, COD and BYOD, and enrollment edge cases turn device management into a moving target.",
  "deliver": "Complete enrollment and configuration playbooks — Autopilot, Apple ADE, compliance, and BYOD — with validation scripts and pass/fail gates so you know a device shipped correctly before it reaches a user.",
  "sols": [
    sol("Windows Autopilot", "Zero-touch", "Ship Windows devices that provision themselves on first boot.", "windows-autopilot-commercial"),
    sol("Device Compliance Policies", "Prove health", "Define what 'healthy' means and enforce it as a Conditional Access signal.", "device-compliance-policies-commercial"),
    sol("Corporate-Owned (COD) & BYOD", "Both models", "One user identity across company-owned and personal devices.", "cod-and-byod-device-management-commercial"),
    sol("macOS ADE with SSO", "Mac · Intune", "Zero-touch Mac enrollment into Intune with Entra Platform SSO.", "macos-ade-with-sso-commercial"),
    sol("macOS ADE with SSO (Jamf Pro + Intune)", "Mac · Jamf", "Keep Jamf as your Mac MDM; add Entra compliance + enforced SSO.", "macos-ade-with-sso-jamf-pro-commercial"),
    sol("Remote Help", "Assist", "Secure, compliant remote assistance built into Intune.", "remote-help-commercial"),
  ]},
 {"slug": "security-compliance", "kicker": "KNOWLEDGE AREA · DEFENSE",
  "title": "Security & Compliance",
  "tagline": "Risk reduction that survives an audit — endpoint hardening and defense-in-depth that actually reduces risk in production.",
  "challenge": "Security controls are easy to enable and hard to get right. Encryption gaps, unmanaged attack surface, no application control, and baselines that drift leave real exposure — and an audit will find it.",
  "deliver": "Production-proven hardening across the endpoint: encryption, attack-surface reduction, Defender integration, application control, firewall, privilege management, and security baselines — each with the verification to back up your compliance posture.",
  "sols": [
    sol("BitLocker Drive Encryption", "Encryption", "Fleet-wide disk encryption with key escrow and recovery you can trust.", "bitlocker-drive-encryption-commercial"),
    sol("Attack Surface Reduction (ASR) Rules", "Harden", "Close the common attack paths attackers actually use.", "attack-surface-reduction-rules-commercial"),
    sol("Microsoft Defender for Endpoint", "Detect & respond", "Integrate Defender for real endpoint detection and response.", "defender-for-endpoint-integration-commercial"),
    sol("Application Control (WDAC)", "Allow-listing", "Run only what you trust — application control without the lockout chaos.", "application-control-wdac-commercial"),
    sol("Windows Firewall Management", "Network", "Centrally managed host firewall policy across the fleet.", "windows-firewall-management-commercial"),
    sol("Endpoint Security Baselines", "Baselines", "Deploy and hold Microsoft security baselines without the drift.", "endpoint-security-baselines-commercial"),
    sol("Endpoint Privilege Management (EPM)", "Least privilege", "Remove local admin without breaking the people who need elevation.", "endpoint-privilege-management-commercial"),
  ]},
 {"slug": "infrastructure-cloud-ops", "kicker": "KNOWLEDGE AREA · INFRASTRUCTURE",
  "title": "Infrastructure & Cloud Ops",
  "tagline": "The platforms that keep small teams running large stacks — patched, current, and predictable.",
  "challenge": "Update management and hybrid infrastructure are where small teams quietly lose time and take on risk: unpatched fleets, manual update rings, and no repeatable process.",
  "deliver": "Cloud-managed update and infrastructure operations with the rings, schedules, and validation to keep the fleet current without firefighting — and the catalog here keeps expanding.",
  "sols": [
    sol("Windows Updates for Business", "Patch fleet", "Drive Windows updates through controlled rings — patched without the chaos.", "windows-updates-for-business-commercial"),
  ], "cross": True},
 {"slug": "automation-efficiency", "kicker": "KNOWLEDGE AREA · AUTOMATION",
  "title": "Automation & Efficiency",
  "tagline": "Shrink the work without inviting chaos. Every Phoenixtekk solution ships with tested PowerShell and Microsoft Graph automation.",
  "challenge": "Repetitive console clicks don't scale and invite mistakes — but home-grown scripts that nobody tested are their own risk. The win is automation you can actually trust in production.",
  "deliver": "Every solution in the catalog includes ready-to-run scripts — discovery, validation, fleet reporting, and safe remediation — so you replace manual effort with repeatable, tested automation. Dedicated automation packages are on the roadmap.",
  "sols": [
    sol("Defender for Endpoint Integration", "Graph scripts", "Discovery, validation, and reporting automation included.", "defender-for-endpoint-integration-commercial"),
    sol("Device Compliance Policies", "Validation", "Pass/fail validation scripts ship with the package.", "device-compliance-policies-commercial"),
    sol("Endpoint Privilege Management (EPM)", "Remediation", "Safe, scripted remediation and reporting out of the box.", "endpoint-privilege-management-commercial"),
  ], "cross": True},
 {"slug": "operational-standards", "kicker": "KNOWLEDGE AREA · METHOD",
  "title": "Operational Standards",
  "tagline": "The documentation discipline that turns one-off heroics into a service anyone on your team can deliver.",
  "challenge": "Tribal knowledge doesn't scale and walks out the door with people. Without a repeatable method, every project starts from scratch and quality is a coin flip.",
  "deliver": "Every Phoenixtekk solution follows one repeatable shape — Assess → Configure → Pilot → Validate → Expand — delivered as exact, click-by-click documentation plus tested scripts, so your team gets faster and more confident with every rollout.",
  "sols": [
    sol("Windows Hello for Business", "Pilot-first", "A clean example of the Assess→Validate→Expand method end to end.", "windows-hello-for-business-commercial"),
    sol("BitLocker Drive Encryption", "Runbook", "Repeatable runbook with verification gates.", "bitlocker-drive-encryption-commercial"),
    sol("Conditional Access Integration", "Documented", "Click-by-click, report-only first, then enforce.", "conditional-access-integration-commercial"),
  ], "cross": True},
]

WHY = (
  '<div class="ptd-section-head"><div class="ptd-kicker">THE PHOENIXTEKK WAY</div>'
  '<h2>Run it yourself — simpler, cheaper, proven</h2>'
  '<p class="ptd-sub" style="max-width:720px">You don’t need a consultant. Each package is self-guided, '
  'click-by-click documentation a single admin can follow end to end, backed by tested scripts. '
  'One fixed price instead of an open meter — buy once, deploy to unlimited devices, and keep the playbook forever.</p></div>'
)


def render(area):
    cards = []
    for s in area["sols"]:
        cards.append(
          '<div class="ptd-card">'
          f'<h3>{html.escape(s["name"])}</h3>'
          f'<div class="lead">{html.escape(s["tag"])}</div>'
          f'<p>{html.escape(s["blurb"])}</p>'
          '<span class="arrow">View on the marketplace →</span>'
          f'<a class="ptd-stretch" href="{STORE}/{s["url_key"]}" aria-label="{html.escape(s["name"])}"></a>'
          '</div>')
    sols_kicker = "BUILT INTO EVERY SOLUTION" if area.get("cross") else "SOLUTIONS IN THIS AREA"
    sols_head = "Built into every package" if area.get("cross") else "Ready-to-deploy packages"
    sols_sub = ("Representative examples — this benefit ships with every solution in the catalog."
                if area.get("cross") else "Each is a complete, downloadable package you can deploy today.")
    return (
      '<div class="ptd-root"><div class="ptd-main">'
      '<section class="ptd-section">'
      f'<div class="ptd-section-head"><div class="ptd-kicker">{area["kicker"]}</div>'
      f'<h1 class="ptd-headline"><span class="glow">{html.escape(area["title"])}</span></h1>'
      f'<p class="ptd-sub" style="max-width:680px">{html.escape(area["tagline"])}</p></div>'
      '<div class="ptd-section-head" style="margin-top:8px">'
      '<h2>The challenge</h2>'
      f'<p class="ptd-sub" style="max-width:720px">{html.escape(area["challenge"])}</p>'
      '<h2 style="margin-top:18px">What you get</h2>'
      f'<p class="ptd-sub" style="max-width:720px">{html.escape(area["deliver"])}</p></div>'
      '</section>'
      '<section class="ptd-section">'
      f'<div class="ptd-section-head"><div class="ptd-kicker">{sols_kicker}</div>'
      f'<h2>{sols_head}</h2><p class="ptd-sub" style="max-width:640px">{sols_sub}</p></div>'
      f'<div class="ptd-grid">{"".join(cards)}</div></section>'
      f'<section class="ptd-section">{WHY}'
      '<div class="ptd-cta-row">'
      f'<a class="ptd-btn ptd-btn-fire" href="{STORE}">Browse all solutions →</a>'
      '<a class="ptd-btn ptd-btn-ghost" href="/en/home">← Back to overview</a>'
      '</div></section>'
      '</div></div>')


FIND = 'query($p:String!){ pages { singleByPath(path:$p, locale:"en"){ id } } }'
CREATE = ('mutation($content:String!,$description:String!,$path:String!,$title:String!,$tags:[String]!){ '
          'pages { create(content:$content, description:$description, editor:"code", isPublished:true, '
          'isPrivate:false, locale:"en", path:$path, tags:$tags, title:$title){ responseResult{succeeded message} page{id} } } }')
UPDATE = ('mutation($id:Int!,$content:String!,$description:String!,$title:String!,$tags:[String]!){ '
          'pages { update(id:$id, content:$content, description:$description, editor:"code", isPublished:true, '
          'isPrivate:false, locale:"en", tags:$tags, title:$title){ responseResult{succeeded message} } } }')

print("== publishing explore pages ==")
slug_to_path = {}
for a in AREAS:
    path = f"explore/{a['slug']}"
    content = render(a)
    title = f"{a['title']} — Phoenixtekk Solutions"
    desc = a["tagline"][:180]
    tags = ["explore", "free", "landing", a["slug"]]
    found = gql(FIND, {"p": path}, tolerate={6003, "INTERNAL_SERVER_ERROR"})
    existing = found["pages"]["singleByPath"] if found else None
    if existing and existing.get("id"):
        gql(UPDATE, {"id": int(existing["id"]), "content": content, "description": desc, "title": title, "tags": tags})
        print(f"  UPDATE /{path}")
    else:
        gql(CREATE, {"content": content, "description": desc, "path": path, "title": title, "tags": tags})
        print(f"  CREATE /{path}")
    slug_to_path[a["title"]] = "/" + path

# ---- repoint home cards (page id 3) ----
print("== repointing home cards ==")
c = gql("{ pages { single(id:3){ content title description editor isPrivate isPublished locale tags{tag} } } }")["pages"]["single"]
content = c["content"]
# map card <h3>Title</h3> ... <a class="ptd-stretch" href="OLD"> -> new explore path
title_map = {
  "Microsoft 365 &amp; Identity": "/explore/microsoft-365-identity",
  "Endpoint &amp; Device Management": "/explore/endpoint-device-management",
  "Security &amp; Compliance": "/explore/security-compliance",
  "Infrastructure &amp; Cloud Ops": "/explore/infrastructure-cloud-ops",
  "Automation &amp; Efficiency": "/explore/automation-efficiency",
  "Operational Standards": "/explore/operational-standards",
}
new = content
for h3, newhref in title_map.items():
    # replace the href in the <a class="ptd-card" ...> OR the stretched link following this h3
    pat = re.compile(r'(<h3>' + re.escape(h3) + r'</h3>.*?href=")[^"]+(")', re.S)
    new, n = pat.subn(lambda m: m.group(1) + newhref + m.group(2), new, count=1)
    print(f'  {"OK" if n else "MISS"} {h3} -> {newhref}')
if new != content:
    tags = [t["tag"] for t in (c.get("tags") or [])]
    gql("mutation($id:Int!,$content:String!,$description:String!,$editor:String!,$isPrivate:Boolean!,$isPublished:Boolean!,$locale:String!,$tags:[String]!,$title:String!){ pages { update(id:$id,content:$content,description:$description,editor:$editor,isPrivate:$isPrivate,isPublished:$isPublished,locale:$locale,tags:$tags,title:$title){ responseResult{succeeded message} } } }",
        {"id": 3, "content": new, "description": c["description"] or "", "editor": c["editor"], "isPrivate": c["isPrivate"], "isPublished": c["isPublished"], "locale": c["locale"], "tags": tags, "title": c["title"]})
    print("  home cards updated")
else:
    print("  (no card hrefs changed)")
print("done.")
