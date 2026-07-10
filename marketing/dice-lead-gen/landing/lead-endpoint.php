<?php
/**
 * lead-endpoint.php — intake sink for the Workplace Marketplace lead-gen landing page.
 *
 * Accepts JSON POST of two kinds:
 *   {"type":"pageview", ...}  -> append a visit row to the pageview log (attribution)
 *   {"type":"lead", name,email,description,src,utm_*,referrer,...} ->
 *        (1) email the lead to LEAD_EMAIL, (2) create a prospect in Dolibarr (crm.phoenixtekk.com),
 *        (3) always append to leads.jsonl so nothing is ever lost.
 *
 * CONFIG — create a repo-EXTERNAL env file next to this script's data dir (chmod 600), e.g.
 *   /home/workplace/.leadform.env   with:
 *      LEAD_EMAIL=admin@phoenixtekk.io
 *      DOLIBARR_URL=https://crm.phoenixtekk.com
 *      DOLIBARR_API_KEY=xxxxxxxx            # Dolibarr: Home > Setup > Users > (user) > API key
 *      # optional SMTP (else PHP mail() is used):
 *      SMTP_HOST= ; SMTP_PORT=587 ; SMTP_USER= ; SMTP_PASS= ; SMTP_FROM=leads@phoenixtekk.com
 * Never commit real secrets. This file contains NONE.
 */

header('Content-Type: application/json');
$ORIGIN_OK = 'https://workplace.phoenixtekk.com';
header('Access-Control-Allow-Origin: ' . $ORIGIN_OK);
header('Vary: Origin');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') { http_response_code(405); echo '{"error":"POST only"}'; exit; }

// ---- load env ----
function load_env($paths) {
  $out = [];
  foreach ($paths as $p) {
    if (is_file($p)) foreach (file($p, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $ln) {
      $ln = trim($ln);
      if ($ln === '' || $ln[0] === '#' || strpos($ln, '=') === false) continue;
      [$k, $v] = explode('=', $ln, 2);
      $out[trim($k)] = trim(trim($v), "\"'");
    }
  }
  return $out;
}
$env = load_env(['/home/workplace/.leadform.env', __DIR__ . '/.leadform.env', getenv('HOME') . '/.leadform.env']);
$g = function($k, $d = '') use ($env) { return isset($env[$k]) && $env[$k] !== '' ? $env[$k] : (getenv($k) ?: $d); };

// ---- data dir: OUTSIDE the web root (never serve leads.jsonl) ----
$DATA = $g('LEADFORM_DATA', '/home/workplace/leaddata');
@mkdir($DATA, 0750, true);

$LEAD_EMAIL = $g('LEAD_EMAIL', 'admin@phoenixtekk.io');
$DOL_URL    = rtrim($g('DOLIBARR_URL', 'https://crm.phoenixtekk.com'), '/');
$DOL_KEY    = $g('DOLIBARR_API_KEY', '');

// ---- read body ----
$raw = file_get_contents('php://input');
$d = json_decode($raw, true);
if (!is_array($d)) { http_response_code(400); echo '{"error":"bad json"}'; exit; }

$ip  = $_SERVER['HTTP_CF_CONNECTING_IP'] ?? ($_SERVER['HTTP_X_FORWARDED_FOR'] ?? ($_SERVER['REMOTE_ADDR'] ?? ''));
$ua  = substr($_SERVER['HTTP_USER_AGENT'] ?? '', 0, 400);
$now = gmdate('c');
$clean = function($s, $n = 500) { return trim(mb_substr(preg_replace('/[\x00-\x1F\x7F]+/u', ' ', (string)$s), 0, $n)); };

$type = $d['type'] ?? 'lead';

// ============ pageview ============
if ($type === 'pageview') {
  $row = [
    'ts' => $now, 'ip' => $ip, 'ua' => $ua,
    'src' => $clean($d['src'] ?? '', 60),
    'utm_source' => $clean($d['utm_source'] ?? '', 60),
    'utm_medium' => $clean($d['utm_medium'] ?? '', 60),
    'utm_campaign' => $clean($d['utm_campaign'] ?? '', 80),
    'referrer' => $clean($d['referrer'] ?? '', 300),
    'path' => $clean($d['path'] ?? '', 300),
  ];
  @file_put_contents($DATA . '/pageviews.jsonl', json_encode($row) . "\n", FILE_APPEND | LOCK_EX);
  echo '{"ok":true}'; exit;
}

// ============ lead ============
// spam honeypot
if (!empty($d['company_website'])) { echo '{"ok":true}'; exit; } // silently drop bots
// rate limit: max 5 leads / 10 min per IP AND per httpOnly cookie
$cid = $_COOKIE['wm_c'] ?? '';
if (!$cid) { $cid = bin2hex(random_bytes(8)); @setcookie('wm_c', $cid, ['expires'=>time()+2592000,'path'=>'/','secure'=>true,'httponly'=>true,'samesite'=>'Lax']); }
$rlKeys = ['rl_'.md5($ip), 'rlc_'.md5($cid)];
foreach ($rlKeys as $key) {
  $f = $DATA."/$key.txt";
  $h = is_file($f) ? array_filter(explode(',', trim(file_get_contents($f))), fn($t)=>(time()-(int)$t)<600) : [];
  if (count($h) >= 5) { http_response_code(429); echo '{"error":"rate"}'; exit; }
}
foreach ($rlKeys as $key) {
  $f = $DATA."/$key.txt";
  $h = is_file($f) ? array_filter(explode(',', trim(file_get_contents($f))), fn($t)=>(time()-(int)$t)<600) : [];
  $h[] = time(); @file_put_contents($f, implode(',', $h), LOCK_EX);
}

$name  = $clean($d['name'] ?? '', 120) ?: 'Website visitor';
$email = $clean($d['email'] ?? '', 160);
$desc  = $clean($d['description'] ?? '', 4000);
$src   = $clean($d['src'] ?? 'direct', 60);
$utm_s = $clean($d['utm_source'] ?? $src, 60);
$utm_c = $clean($d['utm_campaign'] ?? '', 80);
$ref   = $clean($d['referrer'] ?? '', 300);

if (!filter_var($email, FILTER_VALIDATE_EMAIL) || strlen($desc) < 4) {
  http_response_code(422); echo '{"error":"need valid email + description"}'; exit;
}

$lead = compact('name','email','desc','src','utm_s','utm_c','ref','ip','ua') + ['ts' => $now];
// (1) never-lose store
@file_put_contents($DATA . '/leads.jsonl', json_encode($lead) . "\n", FILE_APPEND | LOCK_EX);

// (2) email
$subject = "New Workplace lead [$src]: " . mb_substr($desc, 0, 60);
$body =
  "New lead from the Workplace Marketplace landing page\n" .
  "----------------------------------------------------\n" .
  "Name:        $name\n" .
  "Email:       $email\n" .
  "Source:      $src   (utm_source=$utm_s, campaign=$utm_c)\n" .
  "Referrer:    $ref\n" .
  "IP:          $ip\n" .
  "When (UTC):  $now\n\n" .
  "ASK (\"Describe the solution you want\"):\n$desc\n";
$headers = "From: " . $g('SMTP_FROM', 'leads@phoenixtekk.com') . "\r\nReply-To: $email\r\nContent-Type: text/plain; charset=UTF-8\r\n";
$mailed = false;
if ($g('SMTP_HOST')) {
  $mailed = smtp_send($g('SMTP_HOST'), (int)$g('SMTP_PORT','587'), $g('SMTP_USER'), $g('SMTP_PASS'),
                      $g('SMTP_FROM','leads@phoenixtekk.com'), $LEAD_EMAIL, $subject, $body, $email);
}
if (!$mailed) { $mailed = @mail($LEAD_EMAIL, $subject, $body, $headers); }

// (2b) auto-reply to the requester — the "built in 1 day" acknowledgement
$fromAddr = $g('SMTP_FROM', 'leads@phoenixtekk.com');
$ackSubject = "We got your request — Phoenixtekk Workplace Marketplace";
$ackBody =
  "Hi " . ($name !== 'Website visitor' ? $name : 'there') . ",\n\n" .
  "Thanks for reaching out to the Workplace Marketplace. We received your request:\n\n" .
  "  \"" . $desc . "\"\n\n" .
  "Here's what happens next:\n" .
  "  1. We check whether it's already one of our 380+ ready-to-deploy solutions.\n" .
  "  2. If it is, we'll send you the direct link.\n" .
  "  3. If it's new and buildable, we build it — typically within 1 business day — and send you the listing.\n\n" .
  "What you receive is the DOCUMENTATION to deploy it: a complete click-by-click implementation guide\n" .
  "(Word/PDF) plus tested PowerShell scripts. We productize the setup; we don't write custom software.\n\n" .
  "Either way, you'll hear back from us within 1 business day.\n\n" .
  "Browse the full catalog any time: https://workplace.phoenixtekk.com\n\n" .
  "— The Phoenixtekk Workplace Marketplace team\n";
$ackHeaders = "From: $fromAddr\r\nContent-Type: text/plain; charset=UTF-8\r\n";
if ($g('SMTP_HOST')) {
  smtp_send($g('SMTP_HOST'), (int)$g('SMTP_PORT','587'), $g('SMTP_USER'), $g('SMTP_PASS'),
            $fromAddr, $email, $ackSubject, $ackBody, $fromAddr);
} else { @mail($email, $ackSubject, $ackBody, $ackHeaders); }

// (3) Dolibarr prospect (crm.phoenixtekk.com)
$crm = ['ok' => false, 'id' => null];
if ($DOL_KEY) {
  $note = "Workplace Marketplace lead\nSource: $src (utm_source=$utm_s, campaign=$utm_c)\nReferrer: $ref\nIP: $ip\nWhen: $now\n\nASK:\n$desc";
  $payload = json_encode([
    'name'         => ($name !== 'Website visitor' ? $name : $email),
    'email'        => $email,
    'client'       => 2,            // 2 = prospect
    'code_client'  => -1,           // auto
    'note_private' => $note,
    'array_options'=> ['options_lead_source' => $src],
  ]);
  $ch = curl_init("$DOL_URL/api/index.php/thirdparties");
  curl_setopt_array($ch, [
    CURLOPT_POST => true, CURLOPT_POSTFIELDS => $payload, CURLOPT_RETURNTRANSFER => true,
    CURLOPT_TIMEOUT => 12,
    CURLOPT_HTTPHEADER => ['Content-Type: application/json', 'Accept: application/json', "DOLAPIKEY: $DOL_KEY"],
  ]);
  $resp = curl_exec($ch); $code = curl_getinfo($ch, CURLINFO_HTTP_CODE); curl_close($ch);
  if ($code >= 200 && $code < 300) { $crm = ['ok' => true, 'id' => is_numeric(trim($resp, '"')) ? trim($resp, '"') : $resp]; }
  else { @file_put_contents($DATA . '/crm_errors.log', "$now [$code] $resp\n", FILE_APPEND); }
}

echo json_encode(['ok' => true, 'emailed' => (bool)$mailed, 'crm' => $crm['ok']]);

// ---- minimal SMTP (STARTTLS) sender; returns bool ----
function smtp_send($host,$port,$user,$pass,$from,$to,$subject,$body,$replyTo) {
  $implicit = ((int)$port === 465);           // 465 = implicit TLS; 587/25 = STARTTLS
  $proto = $implicit ? "ssl://" : "tcp://";
  $fp = @stream_socket_client("$proto$host:$port", $e, $es, 12);
  if (!$fp) return false;
  $rd = function() use ($fp){ $d=''; while($l=fgets($fp,515)){ $d.=$l; if(isset($l[3])&&$l[3]==' ') break; } return $d; };
  $wr = function($c) use ($fp){ fwrite($fp,$c."\r\n"); };
  $rd(); $wr("EHLO phoenixtekk.com"); $rd();
  if(!$implicit){
    $wr("STARTTLS"); $rd();
    if(!stream_socket_enable_crypto($fp,true,STREAM_CRYPTO_METHOD_TLS_CLIENT)){ fclose($fp); return false; }
    $wr("EHLO phoenixtekk.com"); $rd();
  }
  if($user){ $wr("AUTH LOGIN"); $rd(); $wr(base64_encode($user)); $rd(); $wr(base64_encode($pass)); if(strpos($rd(),'235')===false){ fclose($fp); return false; } }
  $wr("MAIL FROM:<$from>"); $rd(); $wr("RCPT TO:<$to>"); $rd(); $wr("DATA"); $rd();
  $hdr="From: $from\r\nTo: $to\r\nReply-To: $replyTo\r\nSubject: $subject\r\nContent-Type: text/plain; charset=UTF-8\r\n\r\n";
  $wr($hdr.$body."\r\n."); $okc = strpos($rd(),'250')!==false;
  $wr("QUIT"); fclose($fp); return $okc;
}
