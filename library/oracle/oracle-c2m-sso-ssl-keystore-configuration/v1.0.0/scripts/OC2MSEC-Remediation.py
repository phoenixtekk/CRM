# OC2MSEC-Remediation.py — DRY-RUN-by-default WLST remediation of C2M/WebLogic SSL and keystore config.
#
# PURPOSE
#     Bring a target server to the intended secure posture: point it at the Custom Identity and Custom
#     Trust keystores, set the server private-key alias, enable SSL on the intended port, set the
#     minimum TLS floor, and set client-certificate enforcement. By default it only PRINTS the changes
#     it would make (dry run) and changes nothing; pass -execute to apply inside a proper edit session.
#     Keystore and key passphrases are read at runtime from the vault helper or an interactive prompt,
#     never from a stored value. Inputs are given as environment variables without angle brackets:
#     OC2MSEC_SERVER, OC2MSEC_IDENTITY, OC2MSEC_TRUST, OC2MSEC_ALIAS, OC2MSEC_SSL_PORT, OC2MSEC_TLS_FLOOR.
#
# HOW TO RUN
#     java weblogic.WLST OC2MSEC-Remediation.py                 (dry run — prints intended changes only)
#     java weblogic.WLST OC2MSEC-Remediation.py -execute        (applies the changes)
#     Set OC2MSEC_SERVER=your-server, OC2MSEC_IDENTITY=your-keystore-dir/C2MSEC-Identity-Pilot.jks, etc.
#
# EXPECTED RESULTS
#     Dry run: a numbered list of the exact attribute settings that WOULD be applied, and the message
#     "DRY RUN - no changes made". With -execute: the same settings applied, then save()/activate() and
#     "Applied and activated". Re-run OC2MSEC-Validation.py to confirm PASS.
#
# NOTES
#     White-label — the repeatable, safe way to remediate C2M security. DRY-RUN by default; never prints
#     private keys or passphrases (they are prompted/injected and referenced only as SET at apply time).

import os
import sys

EXECUTE = '-execute' in sys.argv

SERVER = os.environ.get('OC2MSEC_SERVER', 'your-server')
IDENTITY = os.environ.get('OC2MSEC_IDENTITY', 'your-keystore-dir/C2MSEC-Identity-Pilot.jks')
TRUST = os.environ.get('OC2MSEC_TRUST', 'your-keystore-dir/C2MSEC-Trust-Pilot.jks')
ALIAS = os.environ.get('OC2MSEC_ALIAS', 'c2msec-server')
SSL_PORT = int(os.environ.get('OC2MSEC_SSL_PORT', '7002'))
TLS_FLOOR = os.environ.get('OC2MSEC_TLS_FLOOR', 'TLSv1.2')
CLIENT_CERT = os.environ.get('OC2MSEC_CLIENT_CERT', 'false').lower() == 'true'


def get_secret(purpose):
    # Prefer a vault helper if the environment provides one; otherwise prompt interactively.
    # The value is used only in-memory to set the MBean and is never printed or stored by this script.
    helper = os.environ.get('OC2MSEC_VAULT_CMD')
    if helper:
        import subprocess
        return subprocess.check_output([helper, purpose]).strip()
    try:
        import getpass
        return getpass.getpass('Enter %s passphrase (input hidden): ' % purpose)
    except Exception:
        # WLST fallback: raw_input echoes, so only use in a non-production, interactive shell.
        return raw_input('Enter %s passphrase: ' % purpose)


def plan():
    steps = [
        "Servers/%s: KeyStores = CustomIdentityAndCustomTrust" % SERVER,
        "Servers/%s: CustomIdentityKeyStoreFileName = %s (type JKS)" % (SERVER, IDENTITY),
        "Servers/%s: CustomIdentityKeyStorePassPhrase = SET (from vault/prompt)" % SERVER,
        "Servers/%s: CustomTrustKeyStoreFileName = %s (type JKS)" % (SERVER, TRUST),
        "Servers/%s: CustomTrustKeyStorePassPhrase = SET (from vault/prompt)" % SERVER,
        "Servers/%s/SSL: Enabled = true, ListenPort = %d" % (SERVER, SSL_PORT),
        "Servers/%s/SSL: ServerPrivateKeyAlias = %s, PassPhrase = SET" % (SERVER, ALIAS),
        "Servers/%s/SSL: MinimumTLSProtocolVersion = %s" % (SERVER, TLS_FLOOR),
        "Servers/%s/SSL: ClientCertificateEnforced = %s" % (SERVER, str(CLIENT_CERT).lower()),
    ]
    return steps


def show_plan():
    print('=== OC2MSEC Remediation plan for server: %s ===' % SERVER)
    i = 1
    for step in plan():
        print('  %d. %s' % (i, step))
        i += 1


def apply_changes():
    id_pass = get_secret('identity keystore')
    tr_pass = get_secret('trust keystore')
    key_pass = get_secret('server private key')

    edit()
    startEdit()
    cd('/Servers/%s' % SERVER)
    cmo.setKeyStores('CustomIdentityAndCustomTrust')
    cmo.setCustomIdentityKeyStoreFileName(IDENTITY)
    cmo.setCustomIdentityKeyStoreType('JKS')
    cmo.setCustomIdentityKeyStorePassPhrase(id_pass)
    cmo.setCustomTrustKeyStoreFileName(TRUST)
    cmo.setCustomTrustKeyStoreType('JKS')
    cmo.setCustomTrustKeyStorePassPhrase(tr_pass)

    cd('/Servers/%s/SSL/%s' % (SERVER, SERVER))
    cmo.setEnabled(true)
    cmo.setListenPort(SSL_PORT)
    cmo.setServerPrivateKeyAlias(ALIAS)
    cmo.setServerPrivateKeyPassPhrase(key_pass)
    cmo.setClientCertificateEnforced(CLIENT_CERT)
    try:
        cmo.setMinimumTLSProtocolVersion(TLS_FLOOR)
    except Exception:
        print('  note: MinimumTLSProtocolVersion attribute not settable on this version — verify name.')

    save()
    activate()
    print('Applied and activated. Restart SSL (or the server), then run OC2MSEC-Validation.py.')


def connect_admin():
    url = os.environ.get('WLS_ADMIN_URL')
    user = os.environ.get('WLS_ADMIN_USER')
    if url and user:
        connect(user, url=url)
    else:
        connect()


def main():
    show_plan()
    if not EXECUTE:
        print('\nDRY RUN - no changes made. Re-run with -execute to apply.')
        return
    connect_admin()
    apply_changes()
    try:
        disconnect()
    except Exception:
        pass


main()
