# OC2MPATCH-ScopeHelper.py — WLST helper: environment/target list and lower-first progression.
#
# PURPOSE
#     Build the ordered environment/target list for a patch or upgrade and confirm the lower-first
#     progression (Dev -> Test/QA/UAT -> Production), and — when connected to a domain — read the
#     admin/managed-server layout and state so the change targets the right nodes. Read-only WLST:
#     it connects, reads server state, and prints the plan; it changes no configuration. Set the
#     connection values for your-admin-url and your-env before running.
#
# HOW TO RUN
#     wlst.sh OC2MPATCH-ScopeHelper.py
#     Provide connection details via environment variables (see below) or edit the defaults.
#     Read-only: it does not edit, deploy, or apply anything.
#
# EXPECTED RESULTS
#     A printed plan: the environment order with Production last, and — if a connection is made —
#     the domain's admin and managed servers with their current state (RUNNING/ADMIN/etc.), so you
#     confirm the correct, healthy target list before Phase B.
#
# NOTES
#     Oracle — C2M/WebLogic patching. Read-only WLST (Jython). The repeatable way: use the same
#     ordered progression for every change so production is never patched before lower environments.

import os

# --- Environment progression (lower first; Production always last) ---
# Override with OC2MPATCH_ENV_ORDER as a comma-separated list, e.g. "dev,test,uat,prod".
env_order_raw = os.environ.get("OC2MPATCH_ENV_ORDER", "dev,test,uat,prod")
env_order = [e.strip() for e in env_order_raw.split(",") if e.strip()]

print("")
print("=== OC2MPATCH — scope / target helper (read-only WLST) ===")
print("Environment progression (lower first, Production last):")
i = 1
for env in env_order:
    tag = ""
    if env.lower() in ("prod", "production"):
        tag = "   <-- Production: apply LAST, only after every lower env passes its gate"
    print("  %d. %s%s" % (i, env, tag))
    i = i + 1

# Guard: Production must be last in the order.
if env_order and env_order[-1].lower() not in ("prod", "production"):
    print("  WARNING: Production is not last in the progression — fix OC2MPATCH_ENV_ORDER.")

# --- Optional: connect to the domain (read-only) to list servers for the current env ---
admin_url = os.environ.get("OC2MPATCH_ADMIN_URL", "t3://your-admin-url:7001")
admin_user = os.environ.get("OC2MPATCH_ADMIN_USER", "your-wls-admin")
admin_pass = os.environ.get("OC2MPATCH_ADMIN_PASS", "")  # supply via env; never hard-code

print("")
print("-- Domain server layout (read-only; skipped if no connection details) --")
if admin_pass == "":
    print("  (set OC2MPATCH_ADMIN_PASS to connect and list servers; skipping live read)")
else:
    try:
        connect(admin_user, admin_pass, admin_url)  # noqa: F821 (WLST builtin)
        domainRuntime()                              # noqa: F821 (WLST builtin)
        srvs = cmo.getServerRuntimes()               # noqa: F821 (WLST builtin)
        for s in srvs:
            print("  server: %-24s state: %s" % (s.getName(), s.getState()))
        print("  Expected before Phase B: intended targets present; before Gate C: all RUNNING")
        disconnect()                                 # noqa: F821 (WLST builtin)
    except Exception, e:   # Jython 2.x syntax
        print("  (could not connect: %s) — verify OC2MPATCH_ADMIN_URL/USER/PASS" % str(e))

print("")
print("=== Scope plan complete — apply lower environments first, Production last ===")
