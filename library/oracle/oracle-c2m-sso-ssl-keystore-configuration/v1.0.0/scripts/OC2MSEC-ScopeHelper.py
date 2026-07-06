# OC2MSEC-ScopeHelper.py — read-only WLST helper that stages pilot vs domain scope for C2M security work.
#
# PURPOSE
#     Enumerate the WebLogic servers in the domain and split them into the pilot scope
#     (Security Target - Pilot - Stage1, typically one managed server or the lower environment) and the
#     domain scope (Security Target - Domain - Stage2, the remaining in-scope servers), so keystore,
#     SSL, and SSO settings are applied consistently and in the right order. It emits, for each scoped
#     server, the exact OC2MSEC_SERVER value and a ready-to-run OC2MSEC-Remediation.py dry-run command,
#     so the operator drives expansion server by server. Read-only — it selects and prints scope; it
#     changes nothing. Set the pilot server with OC2MSEC_PILOT (no angle brackets).
#
# HOW TO RUN
#     java weblogic.WLST OC2MSEC-ScopeHelper.py
#     Optionally: export OC2MSEC_PILOT=your-pilot-server   (else the first server is treated as pilot).
#
# EXPECTED RESULTS
#     Two lists on screen and in Security-Target-Scope.txt: Stage1 (pilot) and Stage2 (domain), each
#     line showing the server name and the dry-run remediation command to run for it. Read-only: no
#     edit session; nothing is changed.
#
# NOTES
#     White-label — the repeatable way to sequence pilot-then-domain rollout. Read-only; never prints
#     private keys or passphrases.

import os

OUT_FILE = os.environ.get('OC2MSEC_OUT', 'Security-Target-Scope.txt')
PILOT = os.environ.get('OC2MSEC_PILOT', '')
STAGE1 = 'Security Target - Pilot - Stage1'
STAGE2 = 'Security Target - Domain - Stage2'


def connect_readonly():
    url = os.environ.get('WLS_ADMIN_URL')
    user = os.environ.get('WLS_ADMIN_USER')
    if url and user:
        connect(user, url=url)
    else:
        connect()


def remediation_cmd(server):
    return ('OC2MSEC_SERVER=%s java weblogic.WLST OC2MSEC-Remediation.py   '
            '# dry run; add -execute to apply' % server)


def build_scope():
    domainConfig()
    servers = [s.getName() for s in cmo.getServers()]

    if not servers:
        return ['No servers found in the domain.']

    pilot = PILOT if PILOT in servers else servers[0]
    stage1 = [pilot]
    stage2 = [s for s in servers if s != pilot]

    lines = ['=== C2M Security Scope Helper ===', '']
    lines.append('[%s] (do this first, pass the gate before expanding)' % STAGE1)
    for s in stage1:
        lines.append('  %-24s %s' % (s, remediation_cmd(s)))
    lines.append('')
    lines.append('[%s] (apply only after the pilot passes)' % STAGE2)
    if stage2:
        for s in stage2:
            lines.append('  %-24s %s' % (s, remediation_cmd(s)))
    else:
        lines.append('  (single-server domain — no additional servers to expand to)')
    lines.append('')
    lines.append('Reuse the same aliases (c2msec-server) and asserter (C2MSEC-SSO-Asserter) on every server;')
    lines.append('each server presents its own identity certificate, with consistent trust and SSO.')
    return lines


def main():
    connect_readonly()
    lines = build_scope()
    text = '\n'.join(lines)
    print(text)
    try:
        f = open(OUT_FILE, 'w')
        f.write(text + '\n')
        f.close()
        print('\nWrote scope -> %s' % OUT_FILE)
    except Exception, e:
        print('Could not write %s: %s' % (OUT_FILE, str(e)))
    try:
        disconnect()
    except Exception:
        pass


main()
