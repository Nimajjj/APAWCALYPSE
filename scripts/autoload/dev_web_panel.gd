extends Node
## Dashboard d'equilibrage servi en HTTP local (http://127.0.0.1:8088).
## Edite TOUTES les stats du jeu via GameConfig (global, persos, armes, ennemis),
## meme hors partie. Les changements s'appliquent en direct aux entites en jeu ;
## le bouton "Sauvegarder" les rend permanents (user://, recharges au demarrage).
## Actif uniquement en build debug/editeur.

const PORT := 8088

var _server := TCPServer.new()
var _peers: Array = []


func _ready() -> void:
	if not OS.is_debug_build():
		return
	var err := _server.listen(PORT, "127.0.0.1")
	if err != OK:
		push_warning("DevWebPanel: impossible d'ecouter sur le port %d (err %d)" % [PORT, err])
		return
	print("DevWebPanel : dashboard dispo sur http://127.0.0.1:%d" % PORT)


func _process(_delta: float) -> void:
	if not _server.is_listening():
		return
	while _server.is_connection_available():
		_peers.append(_server.take_connection())
	for peer in _peers.duplicate():
		peer.poll()
		if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			_peers.erase(peer)
			continue
		if peer.get_available_bytes() <= 0:
			continue
		var raw: Array = peer.get_data(peer.get_available_bytes())
		var text: String = (raw[1] as PackedByteArray).get_string_from_utf8()
		_handle_request(peer, text)
		peer.disconnect_from_host()
		_peers.erase(peer)


func _handle_request(peer: StreamPeerTCP, text: String) -> void:
	var first_line: String = text.split("\r\n")[0]
	var parts := first_line.split(" ")
	if parts.size() < 2:
		return
	var path: String = parts[1]
	var query := ""
	var q := path.find("?")
	if q >= 0:
		query = path.substr(q + 1)
		path = path.substr(0, q)

	if path == "/state":
		_send(peer, JSON.stringify(GameConfig.get_state()), "application/json")
	elif path == "/set":
		var a := _parse_query(query)
		GameConfig.set_value(a.get("cat", ""), a.get("field", ""), float(a.get("value", "0")))
		_send(peer, "{\"ok\":true}", "application/json")
	elif path == "/save":
		var ok: bool = GameConfig.save()
		_send(peer, "{\"ok\":%s}" % ("true" if ok else "false"), "application/json")
	else:
		_send(peer, _html_page(), "text/html; charset=utf-8")


func _parse_query(query: String) -> Dictionary:
	var out: Dictionary = {}
	for pair in query.split("&", false):
		var kv := pair.split("=")
		if kv.size() == 2:
			out[kv[0].uri_decode()] = kv[1].uri_decode()
	return out


func _send(peer: StreamPeerTCP, body: String, content_type: String) -> void:
	var data := body.to_utf8_buffer()
	var head := "HTTP/1.1 200 OK\r\nContent-Type: %s\r\nContent-Length: %d\r\nAccess-Control-Allow-Origin: *\r\nConnection: close\r\n\r\n" % [content_type, data.size()]
	peer.put_data(head.to_utf8_buffer())
	peer.put_data(data)


func _html_page() -> String:
	return """<!DOCTYPE html><html lang=fr><head><meta charset=utf-8>
<meta name=viewport content="width=device-width,initial-scale=1">
<title>APAWCALYPSE — Dashboard dev</title>
<style>
 body{background:#14101a;color:#eee;font-family:system-ui,sans-serif;margin:0;padding:18px;}
 h1{color:#ffd24d;font-size:20px;margin:0 0 6px;}
 .bar{position:sticky;top:0;background:#14101a;padding:8px 0;z-index:5;border-bottom:1px solid #333;margin-bottom:8px;}
 details{margin:8px 0;border:1px solid #2b2536;border-radius:8px;overflow:hidden;}
 summary{cursor:pointer;padding:8px 12px;background:#1d1828;color:#8fbcff;font-size:15px;}
 .body{padding:6px 12px;}
 .row{display:flex;align-items:center;gap:10px;margin:5px 0;}
 .row label{flex:0 0 160px;font-size:13px;color:#cfcfd6;}
 .row input[type=range]{flex:1;}
 .row .v{flex:0 0 60px;text-align:right;font-variant-numeric:tabular-nums;color:#ffd24d;font-size:13px;}
 button{background:#3a2d10;color:#ffd24d;border:1px solid #ffd24d;border-radius:6px;padding:7px 14px;cursor:pointer;margin-right:8px;}
 #msg{color:#9affc0;font-size:13px;margin-left:6px;}
 #warn{color:#ff8a8a;font-size:13px;}
</style></head><body>
<h1>APAWCALYPSE — Equilibrage (live + sauvegarde)</h1>
<div class=bar>
 <button onclick=save()>💾 Sauvegarder</button>
 <button onclick=load()>↻ Rafraichir</button>
 <span id=msg></span><span id=warn></span>
</div>
<div id=cats></div>
<script>
let dragging=false, built=false;
const inputs={};  // "cat|key" -> {s,v}
function mkRow(cat,f){
 const r=document.createElement('div');r.className='row';
 const l=document.createElement('label');l.textContent=f.label;
 const s=document.createElement('input');s.type='range';s.min=f.min;s.max=f.max;s.step=f.step;s.value=f.value;
 const v=document.createElement('span');v.className='v';v.textContent=(+f.value).toFixed(2);
 s.oninput=()=>{v.textContent=(+s.value).toFixed(2);dragging=true;
   fetch(`/set?cat=${encodeURIComponent(cat)}&field=${encodeURIComponent(f.key)}&value=${s.value}`);};
 s.onchange=()=>{dragging=false;};
 inputs[cat+'|'+f.key]={s,v};
 r.append(l,s,v);return r;
}
function build(d){
 const host=document.getElementById('cats');host.innerHTML='';
 for(const k in inputs)delete inputs[k];
 d.categories.forEach((c,i)=>{
  const det=document.createElement('details');if(i<1)det.open=true;
  const sum=document.createElement('summary');sum.textContent=c.label;det.append(sum);
  const b=document.createElement('div');b.className='body';
  c.fields.forEach(f=>b.append(mkRow(c.id,f)));
  det.append(b);host.append(det);
 });
 built=true;
}
// Met a jour les valeurs sans toucher au DOM (preserve les sections ouvertes).
function update(d){
 d.categories.forEach(c=>c.fields.forEach(f=>{
  const o=inputs[c.id+'|'+f.key];if(!o)return;
  if(document.activeElement!==o.s){o.s.value=f.value;o.v.textContent=(+f.value).toFixed(2);}
 }));
}
function load(force){
 fetch('/state').then(r=>r.json()).then(d=>{
  document.getElementById('warn').textContent='';
  if(!built||force)build(d);else update(d);
 }).catch(e=>{document.getElementById('warn').textContent='Jeu non connecte ('+e+')';});
}
function save(){
 fetch('/save').then(r=>r.json()).then(d=>{
  const m=document.getElementById('msg');
  m.textContent=d.ok?'Sauvegarde !':'Echec sauvegarde';
  setTimeout(()=>m.textContent='',2000);
 });
}
load(true);
setInterval(()=>{if(!dragging)load(false);},2500);
</script></body></html>"""
