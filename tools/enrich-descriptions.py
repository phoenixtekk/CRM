#!/usr/bin/env python3
"""
enrich-descriptions.py — rewrite each solution's listing descriptions into richer, more compelling
marketing copy, then write them back into each library/.../listing/bagisto-products.json.

The copy leads with the productized value: self-guided, click-by-click documentation + tested
PowerShell scripts mean you can run the implementation YOURSELF — simpler, cheaper, and proven —
instead of paying multi-day consulting rates. A shared, vibrant template carries the brand value
blocks; a per-solution data table supplies the unique hook / problem / what's-inside / outcome.

After running this, publish the new copy with the loader's --update-content (it re-styles HTML and
re-attaches downloads + image). Usage:
    python tools/enrich-descriptions.py
"""
import json, pathlib, re

LIB = pathlib.Path(__file__).resolve().parent.parent / "library" / "intune-solutions"

# ---- shared, reusable value blocks (brand messaging; intentionally consistent across products) ----
def diy_block(title):
    return (
        "<h4>Run it yourself — simpler, cheaper, and proven</h4>"
        f"<p>You do <strong>not</strong> need a consultant on site to deploy {title}. This package hands you the "
        "exact, field-tested method as <strong>self-guided, click-by-click documentation</strong> that a "
        "non-expert administrator can follow from start to finish — backed by ready-to-run PowerShell scripts "
        "that do the heavy lifting. You implement with confidence, on your own schedule, and keep the playbook "
        "forever.</p>"
        "<ul>"
        "<li><strong>Simpler</strong> — exact navigation in the right order, written for a novice admin. Click to implement; the &ldquo;why&rdquo; lives in the overview so the steps stay short and uncluttered.</li>"
        "<li><strong>Cheaper</strong> — one fixed, transparent price instead of an open meter. A comparable consulting engagement runs <strong>$1,500&ndash;$3,000 per day across several days</strong>; this is a fraction of that, with nothing left to bill.</li>"
        "<li><strong>Tested</strong> — a pilot-first method (<strong>Assess &rarr; Configure &rarr; Pilot &rarr; Validate &rarr; Expand</strong>) with validation scripts and clear pass/fail gates, so you <em>know</em> it worked before you roll out to the fleet.</li>"
        "</ul>"
    )

PHX_WAY = (
    "<h4>The Phoenixtekk way</h4>"
    "<p>Every Phoenixtekk solution follows the same repeatable shape, so each one you deploy feels familiar and "
    "low-risk — and your team gets faster and more confident with every rollout. Buy once, deploy to unlimited "
    "devices, and reuse the playbook for the next wave and the next project.</p>"
)

DELIVERY = ("<p><em>Delivered as a branded Word document and PDF, plus all five PowerShell scripts in a single "
            "ZIP &mdash; yours to keep and reuse across unlimited devices.</em></p>")

def npo_block(title):
    return (
        "<h4>Run it yourself — and stretch every dollar</h4>"
        f"<p>The complete commercial package at <strong>40% below</strong> the standard price. You get the same "
        f"self-guided, click-by-click documentation and tested PowerShell scripts to deploy {title} yourself — "
        "simpler, cheaper, and proven — instead of paying <strong>$1,500&ndash;$3,000/day</strong> for consulting. "
        "One fixed price, implementable today, with a playbook your team owns and reuses forever.</p>"
        "<p><strong>Eligibility:</strong> Non-profit pricing requires verification of qualifying non-profit "
        "status. Verification may be requested at or after checkout.</p>"
    )

def commercial_html(d):
    inside = "".join(f"<li>{x}</li>" for x in d["inside"])
    return (
        f"<h3>{d['hook']}</h3>"
        f"<p>{d['problem']}</p>"
        + diy_block(d["title"])
        + "<h4>What's inside</h4><ul>" + inside + "</ul>"
        + PHX_WAY
        + "<h4>The bottom line</h4>" + f"<p>{d['outcome']}</p>"
        + DELIVERY
    )

def nonprofit_html(d):
    inside = "".join(f"<li>{x}</li>" for x in d["inside"][:5])
    return (
        f"<h3>{d['hook']}</h3>"
        f"<p>{d['problem']}</p>"
        + npo_block(d["title"])
        + "<h4>What's inside</h4><ul>" + inside + "</ul>"
        + DELIVERY
    )

# ----------------------------- per-solution content -----------------------------
S = {
 "windows-hello-for-business": {
   "title":"Windows Hello for Business",
   "short":"Kill the password. Deploy phishing-resistant, passwordless Windows sign-in yourself with self-guided, tested steps — for a fraction of consulting cost.",
   "hook":"Replace passwords with phishing-resistant, passwordless sign-in",
   "problem":"Passwords are the single most-attacked credential in your environment &mdash; phished, reused, sprayed, and reset all day long. Windows Hello for Business removes the password entirely, replacing it with a hardware-bound credential unlocked by a PIN or biometric that never leaves the device. There is nothing to phish and nothing to steal.",
   "inside":[
     "<strong>Solution Overview</strong> &mdash; what WHfB is, how Cloud Kerberos Trust works, and exactly which model to use (no PKI, NDES, or per-user certificates).",
     "<strong>Requirements Guide</strong> &mdash; every prerequisite (licensing, Entra, Intune, TPM, network) with how to <em>verify</em> it and how to <em>implement</em> it if missing.",
     "<strong>Implementation Guide</strong> &mdash; exact, ordered, click-by-click Microsoft Intune steps.",
     "<strong>5 PowerShell scripts</strong> &mdash; device-readiness discovery, provisioning validation, tenant-wide registration reporting (Microsoft Graph), safe remediation, and hybrid Entra Kerberos enablement.",
     "<strong>Testing &amp; Troubleshooting Guides</strong> with clear pass/fail gates, plus field-proven Best Practices.",
   ],
   "outcome":"A measurable move to phishing-resistant, passwordless authentication: fewer help-desk password resets, a stronger Zero Trust and compliance posture, and a faster sign-in your users actually enjoy &mdash; deployable by a single administrator in a controlled pilot within a day.",
   "meta":"Deploy phishing-resistant, passwordless Windows Hello for Business yourself with Intune. Self-guided, tested steps and scripts at a fraction of consulting cost.",
 },
 "onedrive-for-business": {
   "title":"OneDrive for Business",
   "short":"Silently back up every user's Desktop, Documents, and Pictures to the cloud. Do it yourself with self-guided, tested steps — far cheaper than consulting.",
   "hook":"Silent, automatic file backup and ransomware resilience",
   "problem":"When files live only on a laptop, one lost, stolen, or wiped device means lost work &mdash; and a ransomware hit can take a whole team offline. OneDrive for Business turns every user's Desktop, Documents, and Pictures into cloud-backed, version-protected, roam-anywhere storage &mdash; silently, with zero action from the user.",
   "inside":[
     "<strong>Solution Overview</strong> &mdash; Silent Sign-In, Known Folder Move, and Files On-Demand explained in plain language.",
     "<strong>Requirements Guide</strong> &mdash; every prerequisite with how to verify and implement if missing.",
     "<strong>Implementation Guide</strong> &mdash; exact, ordered Intune Settings Catalog steps.",
     "<strong>5 PowerShell scripts</strong> &mdash; Tenant ID retrieval, readiness discovery, configuration validation, usage reporting (Microsoft Graph), and safe remediation.",
     "<strong>Testing &amp; Troubleshooting Guides</strong> with pass/fail gates, plus Best Practices.",
   ],
   "outcome":"Automatic, silent file protection across the fleet: ransomware and device-loss resilience, seamless roaming between devices, and far fewer &lsquo;I lost my files&rsquo; tickets &mdash; deployable by one administrator and validated before you expand.",
   "meta":"Configure OneDrive Known Folder backup yourself with Intune — Silent Sign-In, KFM, Files On-Demand. Self-guided, tested steps far below consulting cost.",
 },
 "windows-autopilot": {
   "title":"Windows Autopilot",
   "short":"Ship new PCs straight to users for zero-touch setup. Stand up Autopilot yourself with self-guided, tested steps — for a fraction of consulting cost.",
   "hook":"Zero-touch device provisioning — no imaging, no technician",
   "problem":"Manually imaging and hand-configuring every new PC is slow, inconsistent, and ties up a technician for every device. Windows Autopilot replaces all of that with cloud-driven provisioning: a new device ships straight to the user, who powers it on, signs in once, and walks away with a fully managed, policy-compliant, app-loaded workstation.",
   "inside":[
     "<strong>Solution Overview</strong> &mdash; how Autopilot works and which deployment mode to use.",
     "<strong>Requirements Guide</strong> &mdash; every prerequisite with how to verify and implement if missing.",
     "<strong>Implementation Guide</strong> &mdash; exact, ordered Intune steps: auto-enrollment, registration, deployment profile, and Enrollment Status Page.",
     "<strong>5 PowerShell scripts</strong> &mdash; hardware-hash collection, readiness discovery, validation, tenant reporting, and remediation.",
     "<strong>Testing &amp; Troubleshooting Guides</strong> with pass/fail gates, plus Best Practices.",
   ],
   "outcome":"Faster onboarding, perfectly consistent builds, and zero technician imaging &mdash; new devices are ready in minutes, not hours, and the process is identical every time.",
   "meta":"Stand up zero-touch Windows Autopilot yourself with Intune. Self-guided, tested steps and scripts at a fraction of consulting cost.",
 },
 "device-compliance-policies": {
   "title":"Device Compliance Policies",
   "short":"Prove device health and enforce it automatically. Build compliance policies yourself with self-guided, tested steps — far cheaper than consulting.",
   "hook":"Provable device health, automatically enforced",
   "problem":"An unmanaged device with no encryption, a weak PIN, or an outdated OS is a breach waiting to happen &mdash; and most organizations have no automated way to <em>prove</em> a device is healthy before it touches company data. Device Compliance Policies define the health rules every device must meet, evaluate them continuously, and feed that status straight into Conditional Access.",
   "inside":[
     "<strong>Solution Overview</strong> &mdash; how compliance evaluation and enforcement work end to end.",
     "<strong>Requirements Guide</strong> &mdash; every prerequisite with how to verify and implement if missing.",
     "<strong>Implementation Guide</strong> &mdash; exact, ordered Intune steps: rules, actions for noncompliance, assignment, and Conditional Access pairing.",
     "<strong>5 PowerShell scripts</strong> &mdash; health discovery, compliance validation, tenant reporting, safe remediation, and conflict checking.",
     "<strong>Testing &amp; Troubleshooting Guides</strong> with pass/fail gates, plus Best Practices.",
   ],
   "outcome":"A hard, provable health bar for every device &mdash; encryption, Secure Boot, OS, password, and Defender &mdash; with automated notify-then-block actions that power Zero Trust access without manual effort.",
   "meta":"Build Windows device compliance policies yourself with Intune — encryption, Secure Boot, password, Defender. Self-guided, tested steps below consulting cost.",
 },
 "conditional-access-integration": {
   "title":"Conditional Access Integration",
   "short":"Make compliant devices and MFA hard requirements. Roll out Conditional Access yourself — safely, with self-guided, tested steps — for far less than consulting.",
   "hook":"Zero Trust access enforcement — deployed safely, lockout-free",
   "problem":"Device compliance and MFA only protect you if access is actually <em>gated</em> on them. Conditional Access is the enforcement engine: it evaluates every sign-in &mdash; is the device compliant? did the user pass MFA? is this legacy authentication? &mdash; and allows, challenges, or blocks accordingly. Done wrong, it locks people out; done right, it is the backbone of Zero Trust.",
   "inside":[
     "<strong>Solution Overview</strong> &mdash; how Conditional Access evaluates and enforces sign-ins, and how it consumes Intune signals.",
     "<strong>Requirements Guide</strong> &mdash; every prerequisite, including the all-important break-glass accounts, with verify/implement steps.",
     "<strong>Implementation Guide</strong> &mdash; exact, ordered steps that build every policy in <strong>Report-only</strong> first, so you see the impact before you enforce.",
     "<strong>5 PowerShell scripts</strong> &mdash; device-state discovery, access validation, policy reporting, sign-in analysis, and break-glass verification.",
     "<strong>Testing &amp; Troubleshooting Guides</strong> (including lockout recovery), plus Best Practices.",
   ],
   "outcome":"A strong access baseline &mdash; require a compliant device, require MFA, block legacy authentication &mdash; rolled out safely with break-glass accounts and Report-only piloting, so only healthy, authenticated users get in and nobody gets locked out.",
   "meta":"Roll out Conditional Access yourself with Intune — compliant device + MFA, block legacy auth, break-glass safety. Self-guided, tested, far below consulting cost.",
 },
 "defender-for-endpoint-integration": {
   "title":"Microsoft Defender for Endpoint Integration",
   "short":"Auto-onboard EDR and turn device risk into access control. Wire up Defender + Intune yourself with self-guided, tested steps — far cheaper than consulting.",
   "hook":"Full EDR coverage with automatic onboarding and risk-based access",
   "problem":"Antivirus alone does not stop a modern attacker. Microsoft Defender for Endpoint adds endpoint detection and response, behavioral protection, and a live device <strong>risk score</strong> &mdash; and when you integrate it with Intune, devices onboard automatically and that risk score flows straight into compliance and Conditional Access, so a compromised device loses access on its own.",
   "inside":[
     "<strong>Solution Overview</strong> &mdash; how the Intune &harr; Defender integration works end to end.",
     "<strong>Requirements Guide</strong> &mdash; every prerequisite (including licensing) with verify/implement steps.",
     "<strong>Implementation Guide</strong> &mdash; exact, ordered steps across the Defender portal and Intune: connector, EDR onboarding policy, and risk-into-compliance.",
     "<strong>5 PowerShell scripts</strong> &mdash; onboarding discovery, sensor validation, tenant reporting, safe remediation, and connector status.",
     "<strong>Testing &amp; Troubleshooting Guides</strong> with pass/fail gates, plus Best Practices.",
   ],
   "outcome":"Automatic EDR onboarding for the whole fleet and a risk score wired into access control &mdash; compromised devices are flagged and cut off automatically, all managed from a single pane.",
   "meta":"Integrate Defender for Endpoint with Intune yourself — auto EDR onboarding + risk-into-compliance. Self-guided, tested steps far below consulting cost.",
 },
 "bitlocker-drive-encryption": {
   "title":"BitLocker Drive Encryption",
   "short":"Silently encrypt every drive and escrow keys to Entra. Deploy BitLocker yourself with self-guided, tested steps — for a fraction of consulting cost.",
   "hook":"Fleet-wide full-disk encryption with escrowed recovery keys",
   "problem":"A laptop left in a taxi is only a breach if its drive is readable. BitLocker encrypts the whole disk so a lost or stolen device exposes nothing &mdash; and managed through Intune it turns on <strong>silently</strong> on TPM devices, with every <strong>recovery key escrowed to Microsoft Entra ID</strong> so your help desk can always recover access.",
   "inside":[
     "<strong>Solution Overview</strong> &mdash; how Intune-managed BitLocker works, silently, with key escrow.",
     "<strong>Requirements Guide</strong> &mdash; every prerequisite (edition, TPM, UEFI, Entra) with verify/implement steps.",
     "<strong>Implementation Guide</strong> &mdash; exact, ordered Intune disk-encryption steps (XTS-AES 256, OS + fixed drives, escrow-before-enable).",
     "<strong>5 PowerShell scripts</strong> &mdash; readiness discovery, encryption validation, tenant reporting, safe remediation, and recovery-key retrieval.",
     "<strong>Testing &amp; Troubleshooting Guides</strong> with pass/fail gates, plus Best Practices.",
   ],
   "outcome":"Every drive encrypted to XTS-AES 256, enabled with no user friction, and every recovery key safely escrowed &mdash; device-loss data protection and a compliance cornerstone, with the recovery process documented for your help desk.",
   "meta":"Deploy BitLocker yourself with Intune — silent XTS-AES 256 encryption + keys escrowed to Entra. Self-guided, tested steps far below consulting cost.",
 },
 "endpoint-security-baselines": {
   "title":"Endpoint Security Baselines",
   "short":"Apply Microsoft's recommended hardening in one move — conflict-free. Do it yourself with self-guided, tested steps for a fraction of consulting cost.",
   "hook":"Expert hardening, applied in one move — without the guesswork",
   "problem":"Hardening Windows by hand means choosing among hundreds of security settings and getting some of them wrong. Security Baselines apply Microsoft's own recommended, pre-configured set of hardening settings in a single move &mdash; expert-grade posture without the guesswork &mdash; then let you customize and keep it current as Microsoft updates the baseline.",
   "inside":[
     "<strong>Solution Overview</strong> &mdash; what baselines are, the available baselines, and how they apply.",
     "<strong>Requirements Guide</strong> &mdash; every prerequisite with verify/implement steps.",
     "<strong>Implementation Guide</strong> &mdash; exact, ordered Intune steps including conflict detection/resolution and version updates.",
     "<strong>5 PowerShell scripts</strong> &mdash; posture discovery, baseline validation, tenant reporting, conflict checking, and remediation.",
     "<strong>Testing &amp; Troubleshooting Guides</strong> with pass/fail gates, plus Best Practices.",
   ],
   "outcome":"A consistent, Microsoft-recommended hardening posture across the fleet &mdash; hundreds of vetted settings applied at once, conflicts resolved, and a clear path to stay current &mdash; without manual setting-by-setting work.",
   "meta":"Deploy Microsoft security baselines yourself with Intune — hundreds of hardening settings, conflict-aware. Self-guided, tested steps below consulting cost.",
 },
 "attack-surface-reduction-rules": {
   "title":"Attack Surface Reduction (ASR) Rules",
   "short":"Block the behaviors malware relies on — Audit-first so nothing breaks. Deploy ASR yourself with self-guided, tested steps for far less than consulting.",
   "hook":"Behavior-based malware prevention — without breaking your apps",
   "problem":"Most malware uses the same handful of tricks: a macro spawning PowerShell, an attachment launching an executable, credential theft from LSASS. Attack Surface Reduction rules block those behaviors at the source &mdash; and rolled out <strong>Audit-first</strong>, you see exactly what would be blocked, add exclusions for legitimate apps, then enforce with total confidence.",
   "inside":[
     "<strong>Solution Overview</strong> &mdash; what ASR rules block and how Audit/Block modes work.",
     "<strong>Requirements Guide</strong> &mdash; every prerequisite with verify/implement steps.",
     "<strong>Implementation Guide</strong> &mdash; exact, ordered steps: Audit &rarr; review &rarr; exclude &rarr; Block.",
     "<strong>5 PowerShell scripts</strong> &mdash; posture discovery, rule validation, audit-event reporting, remediation, and a GUID&rarr;name rule reference.",
     "<strong>Testing &amp; Troubleshooting Guides</strong> with pass/fail gates, plus Best Practices.",
   ],
   "outcome":"Whole classes of attack blocked at the behavior level &mdash; Office child processes, LSASS credential theft, malicious email payloads, obfuscated scripts, ransomware &mdash; rolled out without breaking a single line-of-business app.",
   "meta":"Deploy Attack Surface Reduction rules yourself with Intune — Audit-first, then Block. Self-guided, tested steps far below consulting cost.",
 },
 "windows-firewall-management": {
   "title":"Windows Firewall Management",
   "short":"Enforce the host firewall fleet-wide with default-deny inbound. Do it yourself with self-guided, tested steps for a fraction of consulting cost.",
   "hook":"A consistently enforced host firewall across the entire fleet",
   "problem":"The host firewall is the last line of defense on every endpoint &mdash; but on unmanaged fleets it is often disabled, inconsistently configured, or full of stale rules. This solution manages Windows Defender Firewall centrally through Intune: on across every profile, default-deny inbound, standardized rules, and full state reporting.",
   "inside":[
     "<strong>Solution Overview</strong> &mdash; Intune-managed firewall policy explained.",
     "<strong>Requirements Guide</strong> &mdash; every prerequisite with verify/implement steps.",
     "<strong>Implementation Guide</strong> &mdash; exact, ordered Intune steps: profiles on, default actions, and managed rules.",
     "<strong>5 PowerShell scripts</strong> &mdash; firewall discovery, validation, rule reporting, remediation, and conflict checking.",
     "<strong>Testing &amp; Troubleshooting Guides</strong> with pass/fail gates, plus Best Practices.",
   ],
   "outcome":"The firewall on for every profile, default-deny inbound, a single managed rule set instead of per-device drift, and fleet-wide visibility &mdash; the highest-value host posture, consistently enforced.",
   "meta":"Manage Windows Defender Firewall yourself with Intune — all profiles on, default-deny inbound, managed rules. Self-guided, tested steps below consulting cost.",
 },
 "application-control-wdac": {
   "title":"Application Control (WDAC)",
   "short":"Allowlist trusted code and block everything else — Audit-first, with recovery. Deploy WDAC yourself with self-guided, tested steps for far less than consulting.",
   "hook":"Kernel-enforced allowlisting — deployed safely",
   "problem":"Antivirus asks &ldquo;is this file known-bad?&rdquo; Application Control asks the stronger question: &ldquo;is this code explicitly trusted?&rdquo; &mdash; and blocks everything else. WDAC is kernel-enforced allowlisting that stops untrusted executables, scripts, and installers from running at all. Rolled out Audit-first with a clear recovery path, it delivers powerful protection without locking your users out.",
   "inside":[
     "<strong>Solution Overview</strong> &mdash; allowlisting, the trust models, and Audit/Enforce modes.",
     "<strong>Requirements Guide</strong> &mdash; every prerequisite with verify/implement steps.",
     "<strong>Implementation Guide</strong> &mdash; exact, ordered steps: Audit &rarr; add trust &rarr; Enforce, with a documented recovery path.",
     "<strong>5 PowerShell scripts</strong> &mdash; policy discovery, validation, audit-event reporting, recovery/remediation, and tenant policy reporting.",
     "<strong>Testing &amp; Troubleshooting Guides</strong> with pass/fail gates, plus Best Practices.",
   ],
   "outcome":"Strong, kernel-enforced protection against untrusted code &mdash; including unknown malware and unsanctioned apps &mdash; deployed safely with audit-first validation, managed-installer trust, and a recovery path that keeps you in control.",
   "meta":"Deploy WDAC / App Control for Business yourself with Intune — allowlist trusted code, Audit-first, with recovery. Self-guided, tested, below consulting cost.",
 },
 "remote-help": {
   "title":"Remote Help",
   "short":"Give your help desk secure, audited, RBAC-governed remote assistance. Stand it up yourself with self-guided, tested steps for a fraction of consulting cost.",
   "hook":"Secure, audited remote assistance — not risky ad-hoc tools",
   "problem":"Ad-hoc remote-support tools are a security liability: unverified helpers, no role controls, no audit trail, and third-party software you do not fully trust. Remote Help is Microsoft's cloud remote-assistance solution built into the Intune ecosystem &mdash; helpers are authenticated with Microsoft Entra, gated by role-based access control, shown the device's compliance state, and every session is audited.",
   "inside":[
     "<strong>Solution Overview</strong> &mdash; how Remote Help works and its security model.",
     "<strong>Requirements Guide</strong> &mdash; every prerequisite (including licensing) with verify/implement steps.",
     "<strong>Implementation Guide</strong> &mdash; exact, ordered Intune steps: enable, deploy the app, assign RBAC, and run a session.",
     "<strong>5 PowerShell scripts</strong> &mdash; app discovery, validation, tenant settings check, remediation, and a session/usage report.",
     "<strong>Testing &amp; Troubleshooting Guides</strong> with pass/fail gates, plus Best Practices.",
   ],
   "outcome":"A secure, audited, role-controlled help desk &mdash; Entra-authenticated helpers, compliance-aware sessions, and a full audit trail &mdash; that replaces risky ad-hoc tools with a service you fully govern.",
   "meta":"Stand up Microsoft Remote Help yourself with Intune — secure, Entra-authenticated, RBAC-governed, audited. Self-guided, tested steps below consulting cost.",
 },
}

def main():
    updated = 0
    for slug, d in S.items():
        jpath = LIB / slug / "v1.0.0" / "listing" / "bagisto-products.json"
        if not jpath.exists():
            print(f"SKIP {slug} (no listing json)"); continue
        data = json.loads(jpath.read_text(encoding="utf-8"))
        for p in data["products"]:
            if p["audience"] == "commercial":
                p["short_description"] = f"<p>{d['short']}</p>"
                p["description"] = commercial_html(d)
                p["meta_description"] = d["meta"]
            else:
                p["short_description"] = (f"<p>{d['short']} <strong>Qualifying non-profits save 40%.</strong></p>")
                p["description"] = nonprofit_html(d)
                p["meta_description"] = "Qualifying non-profits, 40% below commercial. " + d["meta"]
        jpath.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
        updated += 1
        print(f"enriched {slug}")
    print(f"\nUpdated {updated} solution listing(s). Now publish with the loader --update-content.")

if __name__ == "__main__":
    main()
