<?php
/**
 * create-endpoint.php — backend for the /create "solution generator".
 *
 * POST JSON:
 *   {"type":"pageview", ...}                 -> log arrival
 *   {"type":"generate", email, ask, ...}     -> triage against the catalog + QUEUE a build request
 *
 * Tiering: the requester's email is checked against the store's `customers` table.
 *   - recognized customer -> tier "customer": higher rate limit, priority flag, richer messaging.
 *   - otherwise           -> tier "anon": lower rate limit, standard queue.
 * Actual solution generation is NEVER run here — a request is triaged + queued; a gated worker
 * (owner in Claude Code, or a scheduled headless run) picks the queue and runs /generate-solution.
 *
 * Config: /home/workplace/.leadform.env  (LEAD_EMAIL, DOLIBARR_URL/API_KEY, SMTP_*, LEADFORM_DATA,
 *         CATALOG_INDEX=/home/workplace/leaddata/catalog-index.json).
 * Store DB creds are read from the Bagisto .env for customer recognition. No secrets in this file.
 */
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: https://workplace.phoenixtekk.com');
if ($_SERVER['REQUEST_METHOD'] !== 'POST') { http_response_code(405); echo '{"error":"POST only"}'; exit; }

function load_env($paths){ $o=[]; foreach($paths as $p){ if(is_file($p)) foreach(file($p,FILE_IGNORE_NEW_LINES|FILE_SKIP_EMPTY_LINES) as $ln){ $ln=trim($ln); if($ln===''||$ln[0]==='#'||strpos($ln,'=')===false) continue; [$k,$v]=explode('=',$ln,2); $o[trim($k)]=trim(trim($v),"\"'"); } } return $o; }
$env = load_env(['/home/workplace/.leadform.env', __DIR__.'/.leadform.env']);
$g = function($k,$d='') use ($env){ return isset($env[$k])&&$env[$k]!==''?$env[$k]:(getenv($k)?:$d); };

$DATA    = $g('LEADFORM_DATA','/home/workplace/leaddata'); @mkdir($DATA,0750,true);
$CATALOG = $g('CATALOG_INDEX', $DATA.'/catalog-index.json');
$LEAD_EMAIL = $g('LEAD_EMAIL','admin@phoenixtekk.io');
$DOL_URL = rtrim($g('DOLIBARR_URL','https://crm.phoenixtekk.com'),'/'); $DOL_KEY=$g('DOLIBARR_API_KEY','');

$raw=file_get_contents('php://input'); $d=json_decode($raw,true);
if(!is_array($d)){ http_response_code(400); echo '{"error":"bad json"}'; exit; }
$ip=$_SERVER['HTTP_CF_CONNECTING_IP']??($_SERVER['REMOTE_ADDR']??''); $ua=substr($_SERVER['HTTP_USER_AGENT']??'',0,400);
$now=gmdate('c'); $clean=function($s,$n=500){ return trim(mb_substr(preg_replace('/[\x00-\x1F\x7F]+/u',' ',(string)$s),0,$n)); };

// ---- pageview ----
if(($d['type']??'')==='pageview'){
  $row=['ts'=>$now,'ip'=>$ip,'src'=>$clean($d['src']??'create',60),'path'=>$clean($d['path']??'/create',120),'referrer'=>$clean($d['referrer']??'',300),'ua'=>$ua];
  @file_put_contents($DATA.'/pageviews.jsonl',json_encode($row)."\n",FILE_APPEND|LOCK_EX);
  echo '{"ok":true}'; exit;
}

// ---- generate ----
if(!empty($d['company_website'])){ echo '{"ok":true,"queued":true}'; exit; } // honeypot
$email=$clean($d['email']??'',160); $ask=$clean($d['ask']??'',4000); $src=$clean($d['src']??'create',60);
if(!filter_var($email,FILTER_VALIDATE_EMAIL)||strlen($ask)<6){ http_response_code(422); echo '{"error":"need a valid email and a longer description"}'; exit; }

// ---- tier via HMAC-signed session token from /api/me (real login) — spoof-proof ----
// A typed email can NO LONGER unlock customer perks; only a valid token from the store session can.
$tier='anon';
$SECRET=$g('CREATE_TOKEN_SECRET','');
if(!empty($d['token']) && $SECRET){
  $parts=explode('.',(string)$d['token'],2);
  if(count($parts)===2 && hash_equals(hash_hmac('sha256',$parts[0],$SECRET),$parts[1])){
    $pl=json_decode(base64_decode($parts[0]),true);
    if(is_array($pl) && (int)($pl['exp']??0)>time()){
      $tier='customer';
      if(!empty($pl['email'])) $email=$clean($pl['email'],160); // trust the SESSION email, not the posted one
    }
  }
}

// ---- anti-abuse: httpOnly cookie + IP (+ customer email), per-day caps ----
$cid=$_COOKIE['wm_c']??'';
if(!$cid){ $cid=bin2hex(random_bytes(8)); @setcookie('wm_c',$cid,['expires'=>time()+2592000,'path'=>'/','secure'=>true,'httponly'=>true,'samesite'=>'Lax']); }
$day=gmdate('Y-m-d'); $cap=($tier==='customer')?15:3;
$keys=($tier==='customer') ? ['c_'.md5($email)] : ['ck_'.md5($cid),'ip_'.md5($ip)];
$readHits=function($key) use ($DATA,$day){ $f=$DATA."/crl_$key.txt"; return is_file($f)?array_filter(explode(',',trim(file_get_contents($f))),fn($t)=>strpos($t,$day)===0):[]; };
foreach($keys as $key){ if(count($readHits($key))>=$cap){ http_response_code(429); echo json_encode(['error'=>'Daily request limit reached'.($tier==='anon'?' — sign in as a customer for more, or email admin@phoenixtekk.com.':'.'),'tier'=>$tier]); exit; } }
foreach($keys as $key){ $h=$readHits($key); $h[]=$day.'T'.gmdate('His'); @file_put_contents($DATA."/crl_$key.txt",implode(',',$h),LOCK_EX); }

// ---- triage against the catalog index ----
$STOP=array_flip(explode(' ','a an the of for to in on with and or via using use your you our we i want need implement implementation deploy deployment setup configure configuration solution solutions manage management enable how do get make build please can it that this at as is are be into across per'));
$SYN=['iphone'=>['ios','apple'],'ios'=>['iphone','apple','ipados'],'mac'=>['macos','apple'],'android'=>['googleplay'],'vpn'=>['globalprotect','anyconnect','tunnel','aovpn','plap'],'mfa'=>['conditional','authentication'],'dlp'=>['purview','loss'],'label'=>['labeling','sensitivity','purview'],'enroll'=>['enrollment','ade','autopilot'],'defender'=>['security'],'bitlocker'=>['encryption'],'pim'=>['privileged']];
$tok=function($s) use ($STOP){ $w=preg_split('/[^a-z0-9]+/',strtolower($s),-1,PREG_SPLIT_NO_EMPTY); return array_values(array_filter($w,fn($x)=>strlen($x)>1&&!isset($STOP[$x]))); };
$q=$tok($ask); $qe=$q; foreach($q as $t){ if(isset($SYN[$t])) $qe=array_merge($qe,$SYN[$t]); } $qe=array_unique($qe);
$matches=[];
if(is_file($CATALOG)){
  $cat=json_decode(file_get_contents($CATALOG),true) ?: [];
  foreach($cat as $c){
    $kw=$c['keywords']??[]; if(!$kw) continue; $hit=array_values(array_intersect($qe,$kw));
    if(!$hit) continue; $score=count($hit)/max(4,count($qe));
    $matches[]=['score'=>round($score,3),'title'=>$c['title']??'','category'=>$c['category']??'','price'=>$c['price']??null,'link'=>$c['link']??'','n'=>count($hit)];
  }
  usort($matches,fn($a,$b)=>$b['score']<=>$a['score']); $matches=array_slice($matches,0,4);
}
$verdict = (!empty($matches)&&$matches[0]['score']>=0.5)?'covered':(!empty($matches)?'partial':'new');

// ---- queue the request ----
$req=['ts'=>$now,'tier'=>$tier,'email'=>$email,'ask'=>$ask,'src'=>$src,'verdict'=>$verdict,
      'top_match'=>($matches[0]['title']??null),'ip'=>$ip,'status'=>'queued'];
@file_put_contents($DATA.'/create-queue.jsonl',json_encode($req)."\n",FILE_APPEND|LOCK_EX);

// ---- notify admin + auto-ack ----
$fromAddr=$g('SMTP_FROM','leads@phoenixtekk.com');
$adminSub="[/create] $tier request ($verdict): ".mb_substr($ask,0,50);
$adminBody="New /create request\n-------------------\nTier: $tier\nEmail: $email\nSource: $src\nVerdict: $verdict\nTop match: ".($matches[0]['title']??'(none)')."\nWhen: $now\n\nASK:\n$ask\n";
$ackSub="We got your request — Phoenixtekk Workplace Marketplace";
$ackBody="Hi,\n\nThanks — we received your request:\n\n  \"$ask\"\n\n".
  ($verdict==='new'
    ? "This looks new. We build new solutions typically within 1 business day and will email you the listing.\n"
    : "We may already have this — we'll confirm the best-fit solution and send you the link, or build any gap within ~1 business day.\n").
  "\nWhat you receive: a complete click-by-click implementation guide (Word/PDF) plus tested PowerShell\n".
  "scripts — the documentation to deploy it yourself or hand to your team. We productize the setup;\n".
  "we do not write custom software.\n".
  "\nBrowse the catalog: https://workplace.phoenixtekk.com\n\n— Phoenixtekk Workplace Marketplace\n";
if($g('SMTP_HOST')){
  smtp_send($g('SMTP_HOST'),(int)$g('SMTP_PORT','587'),$g('SMTP_USER'),$g('SMTP_PASS'),$fromAddr,$LEAD_EMAIL,$adminSub,$adminBody,$email);
  smtp_send($g('SMTP_HOST'),(int)$g('SMTP_PORT','587'),$g('SMTP_USER'),$g('SMTP_PASS'),$fromAddr,$email,$ackSub,$ackBody,$fromAddr);
} else { @mail($LEAD_EMAIL,$adminSub,$adminBody,"From: $fromAddr\r\n"); @mail($email,$ackSub,$ackBody,"From: $fromAddr\r\n"); }

// ---- Dolibarr prospect (tagged create + tier) ----
if($DOL_KEY){
  $note="/create request (tier=$tier, source=$src, verdict=$verdict)\nWhen:$now\nIP:$ip\n\nASK:\n$ask";
  $payload=json_encode(['name'=>$email,'email'=>$email,'client'=>2,'code_client'=>-1,'note_private'=>$note,'array_options'=>['options_lead_source'=>'create:'.$tier]]);
  $ch=curl_init("$DOL_URL/api/index.php/thirdparties");
  curl_setopt_array($ch,[CURLOPT_POST=>true,CURLOPT_POSTFIELDS=>$payload,CURLOPT_RETURNTRANSFER=>true,CURLOPT_TIMEOUT=>12,
    CURLOPT_HTTPHEADER=>['Content-Type: application/json','Accept: application/json',"DOLAPIKEY: $DOL_KEY"]]);
  curl_exec($ch); curl_close($ch);
}

echo json_encode(['ok'=>true,'tier'=>$tier,'verdict'=>$verdict,'queued'=>true,'matches'=>$matches]);

// ---- minimal SMTP (STARTTLS/implicit-TLS) ----
function smtp_send($host,$port,$user,$pass,$from,$to,$subject,$body,$replyTo){
  $implicit=((int)$port===465); $fp=@stream_socket_client(($implicit?"ssl://":"tcp://")."$host:$port",$e,$es,12); if(!$fp) return false;
  $rd=function() use($fp){ $d=''; while($l=fgets($fp,515)){ $d.=$l; if(isset($l[3])&&$l[3]==' ') break; } return $d; };
  $wr=function($c) use($fp){ fwrite($fp,$c."\r\n"); };
  $rd(); $wr("EHLO phoenixtekk.com"); $rd();
  if(!$implicit){ $wr("STARTTLS"); $rd(); if(!stream_socket_enable_crypto($fp,true,STREAM_CRYPTO_METHOD_TLS_CLIENT)){ fclose($fp); return false; } $wr("EHLO phoenixtekk.com"); $rd(); }
  if($user){ $wr("AUTH LOGIN"); $rd(); $wr(base64_encode($user)); $rd(); $wr(base64_encode($pass)); if(strpos($rd(),'235')===false){ fclose($fp); return false; } }
  $wr("MAIL FROM:<$from>"); $rd(); $wr("RCPT TO:<$to>"); $rd(); $wr("DATA"); $rd();
  $wr("From: $from\r\nTo: $to\r\nReply-To: $replyTo\r\nSubject: $subject\r\nContent-Type: text/plain; charset=UTF-8\r\n\r\n".$body."\r\n."); $ok=strpos($rd(),'250')!==false;
  $wr("QUIT"); fclose($fp); return $ok;
}
