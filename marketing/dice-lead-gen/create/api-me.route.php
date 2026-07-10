
/* === lead-gen /create session bridge — appended to Bagisto routes/web.php ===
 * Returns the logged-in store customer + a short-lived HMAC-signed token that the
 * standalone /create/create-endpoint.php verifies to grant the "customer" tier.
 * Secret lives in /home/workplace/.leadform.env (CREATE_TOKEN_SECRET); never in the repo.
 * routes/web.php is auto-grouped under 'web' (Laravel 11 withRouting), so the session/guard exist. */
Route::get('/api/me', function () {
    $resp = ['authenticated' => false];
    try {
        $g = auth()->guard('customer');
        if ($g->check()) {
            $c = $g->user();
            $secret = '';
            $envf = '/home/workplace/.leadform.env';
            if (is_file($envf)) {
                foreach (file($envf) as $ln) {
                    if (strncmp($ln, 'CREATE_TOKEN_SECRET=', 20) === 0) {
                        $secret = trim(substr(trim($ln), 20), " \"'");
                    }
                }
            }
            $payload = base64_encode(json_encode(['email' => $c->email, 'cid' => $c->id, 'exp' => time() + 1800]));
            $sig = $secret ? hash_hmac('sha256', $payload, $secret) : '';
            $resp = ['authenticated' => true, 'email' => $c->email, 'token' => $payload . '.' . $sig];
        }
    } catch (\Throwable $e) { $resp = ['authenticated' => false]; }
    return response()->json($resp);
});
