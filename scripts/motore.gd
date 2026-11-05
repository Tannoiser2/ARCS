## Regole di Arcs (gioco base + Leader & Lore).
## Tutto lo stato sta nel dizionario `s`; il gioco avanza per decisioni numerate:
## attesa() dice chi deve scegliere e tra quali opzioni, scegli(i) applica la scelta.
## Stessa sequenza di scelte (e stesso seme) = stessa partita su tutti i dispositivi.
class_name Motore
extends RefCounted

var s: Dictionary = {}
var adj: Dictionary = {}

const SOGLIA := {2: 33, 3: 30, 4: 27}

# ================================================================ casuale deterministico
func _rnd() -> int:
	var x: int = int(s["rng"])
	x = (x ^ (x << 13)) & 0xFFFFFFFF
	x = x ^ (x >> 17)
	x = (x ^ (x << 5)) & 0xFFFFFFFF
	if x == 0:
		x = 2463534242
	s["rng"] = x
	return x

func _dado(n: int) -> int:
	return _rnd() % n

func _mescola(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := _dado(i + 1)
		var t = a[i]
		a[i] = a[j]
		a[j] = t

# ================================================================ nuova partita
## cfg: {n, nomi:[], ia:[bool], leader:bool, seme:int, prep:int (-1 = a caso)}
func nuova_partita(cfg: Dictionary) -> void:
	var n: int = int(cfg.get("n", 4))
	s = {"n": n, "rng": int(cfg.get("seme", 12345)) & 0xFFFFFFFF, "log": [], "eventi": [], "pila": [], "attesa": {},
		"capitolo": 1, "fine": false, "vincitore": -1, "leader": bool(cfg.get("leader", false)), "decisioni": 0,
		"facile": bool(cfg.get("facile", false))}
	if s["rng"] == 0:
		s["rng"] = 99991
	for k in 5:
		_rnd()
	var g := []
	for i in n:
		g.append({"nome": str(cfg["nomi"][i]) if cfg.has("nomi") else "Giocatore %d" % (i + 1),
			"colore": Dati.COLORI[i], "ia": bool(cfg["ia"][i]) if cfg.has("ia") else i > 0,
			"potere": 0, "risorse": ["", "", "", "", "", ""], "citta_plancia": [true, true, true, true, true],
			"navi": 15, "porti": 5, "agenti": 10, "trofei": [], "prigionieri": [], "oltraggio": [],
			"carte": [], "lore": [], "leader": "", "mano": [], "antichi": ""})
	s["g"] = g
	# preparazione
	var preps: Array = Dati.PREPARAZIONI[n]
	var pi: int = int(cfg.get("prep", -1))
	if pi < 0 or pi >= preps.size():
		pi = _dado(preps.size())
	s["prep"] = pi
	var prep: Dictionary = preps[pi]
	s["fuori"] = prep["fuori"].duplicate()
	_calcola_adiacenze()
	s["mappa"] = {}
	for id in Dati.sistemi():
		var sl := []
		if not Dati.is_portale(id):
			for k in Dati.SPAZI[id]:
				sl.append(null)
		s["mappa"][id] = {"navi": _zeri(n), "edifici": sl}
	s["iniz"] = _dado(n)
	s["sottratta"] = -1
	# ambizioni: posizione di ogni segnalino ("" = disponibile) e lato
	s["segnalini"] = [{"amb": "", "girato": false}, {"amb": "", "girato": false}, {"amb": "", "girato": false}]
	s["virtuale"] = {}
	s["fuori_risorse"] = {}
	if n == 2:
		for sett in s["fuori"]:
			for l in ["a", "b", "c"]:
				var t: String = Dati.TIPO["%d%s" % [sett, l]]
				s["fuori_risorse"][t] = int(s["fuori_risorse"].get(t, 0)) + 1
				var amb: String = {"materiale": "magnate", "carburante": "magnate", "armi": "generale", "reliquie": "custode", "psico": "empate"}[t]
				s["virtuale"][amb] = int(s["virtuale"].get(amb, 0)) + 1
	# corte
	var corte := []
	for i in range(1, 32):
		corte.append("c%02d" % i)
	_mescola(corte)
	s["mazzo_corte"] = corte
	s["scarti_corte"] = []
	s["corte"] = []
	for k in (3 if n == 2 else 4):
		_rifornisci_corte()
	s["azioni"] = Dati.carte_azione(n)
	s["scarti_azioni"] = []
	s["giocate"] = []
	s["leghe"] = []
	s["passi"] = 0
	_log("Preparazione «%s», %d giocatori. Inizia %s." % [prep["nome"], n, _nome(s["iniz"])])
	if s["leader"]:
		var leaders: Array = Dati.LEADER_ORDINE.duplicate()
		_mescola(leaders)
		var lore := []
		for i in range(1, 15):
			lore.append("l%02d" % i)
		_mescola(lore)
		s["offerta_leader"] = leaders.slice(0, n + 1)
		s["offerta_lore"] = lore.slice(0, n + 1)
		_spingi({"k": "capitolo"})
		_spingi({"k": "piazza_tutti"})
		_spingi({"k": "draft"})
	else:
		_spingi({"k": "capitolo"})
		_spingi({"k": "piazza_tutti"})
	_avanza()

# ---------------------------------------------------------------- agganci per la campagna
func _mazzo_azioni() -> Array:
	return Dati.carte_azione(s["n"])

func _opzioni_evento(_i: int) -> Array:
	return []

func _punti_evento(_i: int) -> int:
	return 0

func _dopo_round() -> void:
	pass

# ---------------------------------------------------------------- agganci per i Destini
func _h_ambizione(_amb: String, _punti: Array, _virt: int, _guadagni: Array) -> void:
	pass

func _h_dopo_punteggio(_calcolate: Dictionary) -> void:
	pass

func _h_fine_capitolo() -> void:
	pass

func _h_dichiara(_i: int, _amb: String) -> void:
	pass

func _h_iniziativa(_i: int) -> void:
	pass

func _h_trofeo(_autore: int, _b: int, _cosa: String, _id: String) -> void:
	pass

func _h_acquisita(_i: int, _c: String) -> void:
	pass

func _h_preludio_gilda(_i: int, _c: String) -> void:
	pass

func _h_cattura(_i: int, _j: int) -> void:
	pass

func _h_carta_giocata(_i: int, _c: String, _modo: String) -> void:
	pass

func _h_spendi(_i: int, _r: String) -> void:
	pass

## Gancio: una risorsa rubata; true se la gestisce il gancio (non va nell'area del ladro).
func _h_ruba(_i: int, _t: String) -> bool:
	return false

func _h_fine_turno(_i: int) -> void:
	pass

func _h_navi_imperiali(_n: int, _id: String) -> void:
	pass

## Valore aggiuntivo di una posizione per l'IA (obiettivi della campagna).
func valore_ia(_i: int) -> float:
	return 0.0

func _zeri(n: int) -> Array:
	var a := []
	for i in n:
		a.append([0, 0])
	return a

func _calcola_adiacenze() -> void:
	adj = Dati.adiacenze_base()
	var fuori: Array = s["fuori"]
	for sett in fuori:
		for l in ["g", "a", "b", "c"]:
			var id := "%d%s" % [sett, l]
			for x in adj[id]:
				adj[x].erase(id)
			adj[id] = []
	# segnalino Rotta: i portali confinanti con un settore fuori dal gioco diventano adiacenti
	for sett in fuori:
		var prev: int = sett
		var next: int = sett
		while prev in fuori:
			prev = (prev + 4) % 6 + 1
			if prev == sett:
				break
		while next in fuori:
			next = next % 6 + 1
			if next == sett:
				break
		var a := "%dg" % prev
		var b := "%dg" % next
		if a != b and not b in adj[a]:
			adj[a].append(b)
			adj[b].append(a)

func carica(stato: Dictionary) -> void:
	s = stato
	_calcola_adiacenze()

func in_gioco(id: String) -> bool:
	return not Dati.settore(id) in s["fuori"]

# ================================================================ pila dei passi
func _spingi(p: Dictionary) -> void:
	s["pila"].append(p)

func attesa() -> Dictionary:
	return s["attesa"]

## Applica la scelta i (indice nelle opzioni dell'attesa corrente).
func scegli(i: int) -> void:
	var a: Dictionary = s["attesa"]
	if a.is_empty():
		return
	var ops: Array = a["opzioni"]
	i = clampi(i, 0, ops.size() - 1)
	var passo: Dictionary = a["passo"]
	s["attesa"] = {}
	s["decisioni"] = int(s["decisioni"]) + 1
	passo["r"] = ops[i]["v"]
	_spingi(passo)
	_avanza()

func _chiedi(passo: Dictionary, g: int, testo: String, opzioni: Array, tipo := "") -> void:
	if opzioni.is_empty():
		opzioni = [{"t": "Continua", "v": null}]
	s["attesa"] = {"g": g, "testo": testo, "opzioni": opzioni, "passo": passo, "tipo": tipo}

func _avanza() -> void:
	var guard := 0
	while s["attesa"].is_empty() and not s["pila"].is_empty() and not s["fine"]:
		guard += 1
		if guard > 20000:
			push_error("ciclo infinito nel motore")
			return
		var p: Dictionary = s["pila"].pop_back()
		call("_p_" + str(p["k"]), p)

## Confronto sicuro tra un valore qualsiasi e una stringa.
func _e(v, x: String) -> bool:
	return v is String and v == x

## Prende la risposta dal passo (e la toglie), null se non c'è.
func _r(p: Dictionary):
	if p.has("r"):
		var v = p["r"]
		p.erase("r")
		return v
	return null

func _ha_r(p: Dictionary) -> bool:
	return p.has("r")

# ================================================================ utilità
func _log(t: String) -> void:
	s["log"].append(t)
	if s["log"].size() > int(s.get("log_max", 300)):
		s["log"].pop_front()

func _ev(e: Dictionary) -> void:
	s["eventi"].append(e)

func _nome(i: int) -> String:
	return str(s["g"][i]["nome"])

func G(i: int) -> Dictionary:
	return s["g"][i]

func ha_lore(i: int, l: String) -> bool:
	return l in G(i)["lore"]

func ha_carta(i: int, c: String) -> bool:
	return c in G(i)["carte"]

func leader(i: int) -> String:
	return str(G(i)["leader"])

func ordine_da(i: int) -> Array:
	var o := []
	for k in s["n"]:
		o.append((i + k) % s["n"])
	return o

func controllo(id: String) -> int:
	var best := -1
	var bv := 0
	var pari := false
	var navi: Array = s["mappa"][id]["navi"]
	for i in navi.size():
		var f: int = navi[i][0]
		if f > bv:
			bv = f
			best = i
			pari = false
		elif f == bv and f > 0:
			pari = true
	return -1 if pari or bv == 0 else best

func navi(id: String, i: int) -> int:
	return s["mappa"][id]["navi"][i][0] + s["mappa"][id]["navi"][i][1]

func ha_pezzi(id: String, i: int) -> bool:
	if navi(id, i) > 0:
		return true
	for e in s["mappa"][id]["edifici"]:
		if e != null and e["g"] == i:
			return true
	return false

func edifici_di(i: int) -> Array:
	var out := []
	for id in s["mappa"]:
		var ed: Array = s["mappa"][id]["edifici"]
		for k in ed.size():
			if ed[k] != null and ed[k]["g"] == i:
				out.append([id, k])
	return out

func porti_di(i: int) -> Array:
	return edifici_di(i).filter(func(x): return s["mappa"][x[0]]["edifici"][x[1]]["t"] == "porto")

func citta_di(i: int) -> Array:
	return edifici_di(i).filter(func(x): return s["mappa"][x[0]]["edifici"][x[1]]["t"] == "citta")

func spazi_aperti(i: int) -> int:
	var cp: Array = G(i)["citta_plancia"]
	var n := 2
	if not cp[0]:
		n += 1
	if not cp[1]:
		n += 1
	if not cp[2]:
		n += 2
	return n

func bonus_citta(i: int) -> int:
	var cp: Array = G(i)["citta_plancia"]
	if not cp[3] and not cp[4]:
		return 5
	if not cp[3]:
		return 2
	return 0

func conta_risorsa(i: int, t: String) -> int:
	var n := 0
	for r in G(i)["risorse"]:
		if r == t:
			n += 1
	if G(i)["antichi"] == t:
		n += 1
	return n

func riserva(t: String) -> int:
	var n: int = 5 - int(s.get("fuori_risorse", {}).get(t, 0))
	for i in s["n"]:
		n -= conta_risorsa(i, t)
	return n

func simboli(i: int, t: String) -> int:
	var n := conta_risorsa(i, t)
	for c in G(i)["carte"]:
		if Dati.info(c)[2] == t:
			n += 1
	return n

func armi_totali(i: int) -> int:
	return simboli(i, "armi")

func agenti_corte(ci: int, i: int) -> int:
	return int(s["corte"][ci]["ag"][i])

func carte_in_mano() -> bool:
	for i in s["n"]:
		if not G(i)["mano"].is_empty():
			return true
	return false

func _desc_sis(id: String) -> String:
	if Dati.is_portale(id):
		return "portale %s" % id.substr(0, 1)
	return "%s (%s)" % [id.to_upper(), Dati.NOME_RISORSA[Dati.TIPO[id]]]

func nome_sis(id: String) -> String:
	return _desc_sis(id)

func _rifornisci_corte() -> void:
	if s["mazzo_corte"].is_empty():
		return
	var c: String = s["mazzo_corte"].pop_front()
	s["corte"].append({"c": c, "ag": _zeri_int(s["n"])})

func _zeri_int(n: int) -> Array:
	var a := []
	for i in n:
		a.append(0)
	return a

# ================================================================ risorse
## Ottiene 1 risorsa dalla riserva (se c'è). Se gli spazi sono pieni chiede cosa scartare.
func _p_ottieni(p: Dictionary) -> void:
	var i: int = p["g"]
	var t: String = p["t"]
	if _ha_r(p):
		var v = _r(p)
		if _e(v, "nuova"):
			_log("%s rinuncia a 1 %s." % [_nome(i), Dati.NOME_RISORSA[t]])
			return
		var slot: int = v
		_log("%s scarta 1 %s per fare spazio." % [_nome(i), Dati.NOME_RISORSA[G(i)["risorse"][slot]]])
		G(i)["risorse"][slot] = t
		_ev({"tipo": "risorsa", "g": i, "t": t})
		return
	if riserva(t) <= 0:
		_log("Non c'è più %s nella riserva." % Dati.NOME_RISORSA[t])
		return
	var aperti := spazi_aperti(i)
	for k in aperti:
		if G(i)["risorse"][k] == "":
			G(i)["risorse"][k] = t
			_log("%s ottiene 1 %s." % [_nome(i), Dati.NOME_RISORSA[t]])
			_ev({"tipo": "risorsa", "g": i, "t": t})
			return
	if ha_lore(i, "l13") and G(i)["antichi"] == "":
		G(i)["antichi"] = t
		_log("%s ottiene 1 %s (Antichi Possedimenti)." % [_nome(i), Dati.NOME_RISORSA[t]])
		return
	var ops := [{"t": "Rinuncia alla nuova %s" % Dati.NOME_RISORSA[t], "v": "nuova"}]
	for k in aperti:
		ops.append({"t": "Scarta %s (spazio %d)" % [Dati.NOME_RISORSA[G(i)["risorse"][k]], k + 1], "v": k})
	_chiedi(p, i, "Spazi Risorsa pieni: cosa scarti per prendere 1 %s?" % Dati.NOME_RISORSA[t], ops, "scarta")

func _ottieni(i: int, t: String) -> void:
	_spingi({"k": "ottieni", "g": i, "t": t})

func _togli_risorsa(i: int, t: String) -> bool:
	if G(i)["antichi"] == t:
		G(i)["antichi"] = ""
		return true
	var r: Array = G(i)["risorse"]
	for k in range(r.size() - 1, -1, -1):
		if r[k] == t:
			r[k] = ""
			return true
	return false

## Una città torna sulla plancia (nello spazio libero più a destra): può coprire una risorsa.
func _restituisci_citta(i: int) -> void:
	var cp: Array = G(i)["citta_plancia"]
	for k in range(4, -1, -1):
		if not cp[k]:
			cp[k] = true
			break
	_sistema_risorse(i)

func _sistema_risorse(i: int) -> void:
	var r: Array = G(i)["risorse"]
	var aperti := spazi_aperti(i)
	var tenute := []
	for x in r:
		if x != "":
			tenute.append(x)
	for k in 6:
		r[k] = ""
	for k in mini(aperti, tenute.size()):
		r[k] = tenute[k]
	if tenute.size() > aperti:
		_log("%s scarta %d risorse che non ha più spazio per tenere." % [_nome(i), tenute.size() - aperti])

func _oltraggio(i: int, t: String) -> void:
	_log("%s Reca Oltraggio: %s." % [_nome(i), Dati.NOME_RISORSA[t]])
	_ev({"tipo": "oltraggio", "g": i, "t": t})
	var r: Array = G(i)["risorse"]
	for k in r.size():
		if r[k] == t:
			r[k] = ""
	if G(i)["antichi"] == t:
		G(i)["antichi"] = ""
	var tieni := []
	for c in G(i)["carte"]:
		if Dati.info(c)[2] == t and not Dati.LEALI.has(c):
			s["scarti_corte"].append(c)
		else:
			tieni.append(c)
	G(i)["carte"] = tieni
	if not t in G(i)["oltraggio"]:
		G(i)["oltraggio"].append(t)
		if G(i)["agenti"] > 0:
			G(i)["agenti"] -= 1

# ================================================================ draft Leader & Lore
func _p_draft(p: Dictionary) -> void:
	var n: int = s["n"]
	if not p.has("ordine"):
		var o := []
		for k in n:
			o.append((s["iniz"] - 1 - k + n * 2) % n)
		p["ordine"] = o
		p["pos"] = 0
	if _ha_r(p):
		var v: String = _r(p)
		var i: int = p["ordine"][p["pos"] % n]
		if v.begins_with("l"):
			G(i)["lore"].append(v)
			s["offerta_lore"].erase(v)
			_log("%s sceglie la Lore %s." % [_nome(i), Dati.LORE[v][0]])
		else:
			G(i)["leader"] = v
			s["offerta_leader"].erase(v)
			_log("%s sceglie il Leader %s." % [_nome(i), Dati.LEADER[v]["nome"]])
		p["pos"] += 1
	while p["pos"] < n * 2:
		var i: int = p["ordine"][p["pos"] % n]
		var ops := []
		if G(i)["leader"] == "":
			for l in s["offerta_leader"]:
				ops.append({"t": "Leader: " + Dati.LEADER[l]["nome"], "v": l, "leader": l})
		if G(i)["lore"].is_empty():
			for l in s["offerta_lore"]:
				ops.append({"t": "Lore: " + Dati.LORE[l][0], "v": l, "lore": l})
		if ops.is_empty():
			p["pos"] += 1
			continue
		_chiedi(p, i, "Scegli una carta Leader o una carta Lore", ops, "draft")
		return

func _p_piazza_tutti(_p: Dictionary) -> void:
	var prep: Dictionary = Dati.PREPARAZIONI[s["n"]][s["prep"]]
	var o := ordine_da(s["iniz"])
	for k in o.size():
		var i: int = o[k]
		var pos: Array = prep["p"][k]
		var part: Dictionary = Dati.PARTENZA_BASE
		var ris := []
		if leader(i) != "":
			part = Dati.LEADER[leader(i)]
			ris = Dati.LEADER[leader(i)]["risorse"]
		var lett := ["A", "B", "C", "C"]
		for j in pos.size():
			var spec: Array = part[lett[j]]
			var id: String = pos[j]
			if spec[0] == "citta":
				_metti_citta(i, id, false)
			elif spec[0] == "porto":
				_metti_porto(i, id, false)
			_metti_navi(i, id, int(spec[1]), false)
		if ris.is_empty():
			ris = [Dati.TIPO[pos[0]] if not Dati.is_portale(pos[0]) else "materiale", Dati.TIPO[pos[1]] if not Dati.is_portale(pos[1]) else "carburante"]
		for t in ris:
			for kk in 6:
				if G(i)["risorse"][kk] == "":
					G(i)["risorse"][kk] = t
					break
		if leader(i) == "mistico":
			G(i)["oltraggio"].append("materiale")
			G(i)["oltraggio"].append("carburante")
			G(i)["agenti"] -= 2
	_ev({"tipo": "preparazione"})

func _metti_navi(i: int, id: String, n: int, danneggiate: bool) -> int:
	var k := mini(n, G(i)["navi"])
	if k <= 0:
		return 0
	G(i)["navi"] -= k
	s["mappa"][id]["navi"][i][1 if danneggiate else 0] += k
	return k

func _slot_libero(id: String) -> int:
	var ed: Array = s["mappa"][id]["edifici"]
	for k in ed.size():
		if ed[k] == null:
			return k
	return -1

func _metti_citta(i: int, id: String, danno: bool) -> bool:
	var cp: Array = G(i)["citta_plancia"]
	var idx := cp.find(true)
	if idx < 0:
		return false
	var k := _slot_libero(id)
	if k < 0:
		s["mappa"][id]["edifici"].append(null)
		k = s["mappa"][id]["edifici"].size() - 1
	cp[idx] = false
	s["mappa"][id]["edifici"][k] = {"t": "citta", "g": i, "danno": danno}
	return true

func _metti_porto(i: int, id: String, danno: bool) -> bool:
	if G(i)["porti"] <= 0:
		return false
	var k := _slot_libero(id)
	if k < 0:
		s["mappa"][id]["edifici"].append(null)
		k = s["mappa"][id]["edifici"].size() - 1
	G(i)["porti"] -= 1
	s["mappa"][id]["edifici"][k] = {"t": "porto", "g": i, "danno": danno}
	return true

# ================================================================ capitolo e round
func _p_capitolo(p: Dictionary) -> void:
	var n: int = s["n"]
	if not p.has("fatto"):
		p["fatto"] = true
		var mazzo: Array = _mazzo_azioni()
		_mescola(mazzo)
		for i in n:
			G(i)["mano"] = mazzo.slice(i * 6, i * 6 + 6)
		s["scarti_azioni"] = mazzo.slice(n * 6)
		s["azioni"] = []
		s["passi"] = 0
		_log("— Capitolo %d —" % s["capitolo"])
		_ev({"tipo": "capitolo", "n": s["capitolo"]})
		if n == 2:
			var altro: int = (s["iniz"] + 1) % 2
			_chiedi(p, altro, "Vuoi scartare la tua mano di 6 carte e pescarne altre 6?", [
				{"t": "Tengo queste carte", "v": false}, {"t": "Scarto e ripesco", "v": true}], "mulligan")
			p["altro"] = altro
			return
	if _ha_r(p):
		if _r(p):
			var altro: int = p["altro"]
			var vecchie: Array = G(altro)["mano"]
			_mescola(s["scarti_azioni"])
			G(altro)["mano"] = s["scarti_azioni"].slice(0, 6)
			s["scarti_azioni"] = s["scarti_azioni"].slice(6) + vecchie
			_mescola(s["scarti_azioni"])
			_log("%s scarta la mano e ripesca 6 carte." % _nome(altro))
	_spingi({"k": "round"})

func _p_round(_p: Dictionary) -> void:
	if not carte_in_mano():
		_spingi({"k": "fine_capitolo"})
		return
	s["giocate"] = []
	s["leghe"] = []
	s["sottratta"] = -1
	s["iniz_prima"] = s["iniz"]
	s["guida"] = {}
	s["dichiarata_round"] = false
	_spingi({"k": "fine_round"})
	_spingi({"k": "turno_guida", "g": s["iniz"]})

func _passa_iniziativa() -> void:
	var n: int = s["n"]
	var da: int = s["iniz"]
	for k in range(1, n + 1):
		var j := (da + k) % n
		if not G(j)["mano"].is_empty():
			s["iniz"] = j
			break
	s["passi"] = int(s["passi"]) + 1
	var con_carte := 0
	for i in n:
		if not G(i)["mano"].is_empty():
			con_carte += 1
	if s["passi"] >= con_carte:
		_log("Tutti passano: il capitolo termina.")
		for i in n:
			s["scarti_azioni"].append_array(G(i)["mano"])
			G(i)["mano"] = []

func _p_turno_guida(p: Dictionary) -> void:
	var i: int = p["g"]
	if _ha_r(p):
		var v = _r(p)
		if _e(v, "passa"):
			_log("%s passa l'iniziativa." % _nome(i))
			_passa_iniziativa()
			s["round_finito"] = true
			return
		var c: String = v
		G(i)["mano"].erase(c)
		s["passi"] = 0
		s["guida"] = {"c": c, "g": i, "valore": Dati.valore(c)}
		s["giocate"].append({"g": i, "c": c, "modo": "guida", "su": true})
		_h_carta_giocata(i, c, "guida")
		_log("%s guida con %s." % [_nome(i), Dati.nome_carta_azione(c)])
		_ev({"tipo": "carta", "g": i, "c": c, "modo": "guida"})
		_inizia_turno(i, c, "guida")
		# i seguaci, in senso orario
		var o := ordine_da(i)
		for k in range(o.size() - 1, 0, -1):
			_spingi({"k": "turno_segui", "g": o[k]})
		_spingi({"k": "turno"})
		_spingi({"k": "dichiara", "g": i, "c": c})
		return
	if G(i)["mano"].is_empty():
		_log("%s non ha carte e passa l'iniziativa." % _nome(i))
		_passa_iniziativa()
		s["round_finito"] = true
		return
	var ops := []
	for c in _ordina_mano(G(i)["mano"]):
		if Dati.is_evento(c):
			continue
		ops.append({"t": "Guida con " + Dati.nome_carta_azione(c), "v": c, "mano": c})
	ops.append({"t": "Passa l'iniziativa", "v": "passa"})
	_chiedi(p, i, "Hai l'iniziativa: gioca una carta Guida", ops, "guida")

func _ordina_mano(m: Array) -> Array:
	var a := m.duplicate()
	a.sort_custom(func(x, y): return x < y)
	return a

func _p_turno_segui(p: Dictionary) -> void:
	var i: int = p["g"]
	if s.get("round_finito", false):
		return
	if G(i)["mano"].is_empty():
		return
	var guida: Dictionary = s["guida"]
	var gs := Dati.seme(guida["c"])
	if _ha_r(p):
		var v: Array = _r(p)
		var c: String = v[0]
		var modo: String = v[1]
		G(i)["mano"].erase(c)
		s["giocate"].append({"g": i, "c": c, "modo": modo, "su": modo != "copia"})
		_h_carta_giocata(i, c, modo)
		var desc: String = {"supera": "Supera con", "cambia": "Cambia con", "copia": "Copia (carta coperta)", "evento": "gioca"}[modo]
		_log("%s %s%s." % [_nome(i), desc, "" if modo == "copia" else " " + Dati.nome_carta_azione(c)])
		_ev({"tipo": "carta", "g": i, "c": c if modo != "copia" else "", "modo": modo})
		_inizia_turno(i, c, modo)
		if modo == "supera" and Dati.valore(c) == 7 and s["sottratta"] < 0 and s["iniz"] != i:
			s["sottratta"] = i
			_log("%s sottrae l'iniziativa con un 7!" % _nome(i))
			_ev({"tipo": "sottrai", "g": i})
		_spingi({"k": "turno"})
		_spingi({"k": "pre_segui", "g": i, "c": c, "modo": modo})
		return
	var ops := []
	ops.append_array(_opzioni_evento(i))
	for c in _ordina_mano(G(i)["mano"]):
		if Dati.is_evento(c):
			continue
		var cs := Dati.seme(c)
		if cs == gs and Dati.valore(c) > int(guida["valore"]):
			ops.append({"t": "Supera con %s (%d azioni)" % [Dati.nome_carta_azione(c), Dati.punti(c)], "v": [c, "supera"], "mano": c, "modo": "supera"})
		if cs != gs:
			ops.append({"t": "Cambia con %s (1 azione)" % Dati.nome_carta_azione(c), "v": [c, "cambia"], "mano": c, "modo": "cambia"})
	for c in _ordina_mano(G(i)["mano"]):
		if Dati.is_evento(c):
			continue
		ops.append({"t": "Copia scartando coperta %s (1 azione %s)" % [Dati.nome_carta_azione(c), Dati.NOME_SEME[gs]], "v": [c, "copia"], "mano": c, "modo": "copia"})
	_chiedi(p, i, "%s ha guidato con %s: Supera, Cambia o Copia" % [_nome(guida["g"]), Dati.nome_carta_azione(guida["c"])], ops, "segui")

func _inizia_turno(i: int, c: String, modo: String) -> void:
	var seme := Dati.seme(c)
	var pt := Dati.punti(c)
	if modo == "copia":
		seme = Dati.seme(s["guida"]["c"])
		pt = 1
	elif modo == "cambia":
		pt = 1
	elif modo == "evento":
		seme = Dati.seme(s["guida"]["c"])
		pt = _punti_evento(i)
	s["turno"] = {"g": i, "c": c, "modo": modo, "seme": seme, "punti": pt, "armi": false, "tassate": [],
		"porti": [], "spesi": [], "preludio": true, "acquisite": [], "tecnopreti": false, "trafficante": false,
		"dopo": ""}

## Seguace: sottrarre l'iniziativa, Bardi Galattici.
func _p_pre_segui(p: Dictionary) -> void:
	var i: int = p["g"]
	if _ha_r(p):
		var v = _r(p)
		if v is String and v.begins_with("sottrai:"):
			var c: String = v.substr(8)
			G(i)["mano"].erase(c)
			s["giocate"].append({"g": i, "c": c, "modo": "sottrai", "su": false})
			s["sottratta"] = i
			_log("%s sottrae l'iniziativa giocando una carta in più." % _nome(i))
			_ev({"tipo": "sottrai", "g": i})
		elif _e(v, "bardi"):
			var amb: String = Dati.AMBIZIONE_DI_VALORE.get(Dati.valore(p["c"]), "")
			_dichiara(i, amb, false)
		p["fatto_" + str(p.get("fase", 0))] = true
	if not p.has("fatto_0"):
		p["fase"] = 0
		if s["sottratta"] < 0 and s["iniz"] != i and not G(i)["mano"].is_empty():
			var ops := [{"t": "Non sottrarre l'iniziativa", "v": "no"}]
			for c in _ordina_mano(G(i)["mano"]):
				if Dati.is_evento(c):
					continue
				ops.append({"t": "Sottrai l'iniziativa scartando %s" % Dati.nome_carta_azione(c), "v": "sottrai:" + c, "mano": c})
			_chiedi(p, i, "Vuoi sottrarre l'iniziativa giocando una carta Azione in più a faccia in giù?", ops, "sottrai")
			return
		p["fatto_0"] = true
	if not p.has("fatto_1"):
		p["fase"] = 1
		if ha_carta(i, "c25") and p["modo"] != "copia" and not s["dichiarata_round"]:
			var amb: String = Dati.AMBIZIONE_DI_VALORE.get(Dati.valore(p["c"]), "")
			if amb != "" and _segnalino_libero() >= 0:
				_chiedi(p, i, "Bardi Galattici: dichiari l'ambizione %s della tua carta?" % Dati.NOME_AMBIZIONE[amb],
					[{"t": "No", "v": "no"}, {"t": "Dichiara " + Dati.NOME_AMBIZIONE[amb], "v": "bardi"}], "dichiara")
				return
		p["fatto_1"] = true

# ---------------------------------------------------------------- ambizioni
func _segnalino_libero() -> int:
	var best := -1
	var bv := -1
	for k in 3:
		var sg: Dictionary = s["segnalini"][k]
		if sg["amb"] == "":
			var v: int = Dati.SEGNALINI[k][1 if sg["girato"] else 0][0]
			if v > bv:
				bv = v
				best = k
	return best

func valore_segnalino(k: int) -> Array:
	var sg: Dictionary = s["segnalini"][k]
	return Dati.SEGNALINI[k][1 if sg["girato"] else 0]

func _dichiara(i: int, amb: String, zero: bool) -> void:
	var k := _segnalino_libero()
	if k < 0 or amb == "":
		return
	s["segnalini"][k]["amb"] = amb
	s["dichiarata_round"] = true
	_log("%s dichiara l'ambizione %s." % [_nome(i), Dati.NOME_AMBIZIONE[amb]])
	_ev({"tipo": "ambizione", "g": i, "amb": amb})
	if zero and not s["guida"].is_empty():
		var no_zero: bool = ha_carta(i, "c18") and amb in ["custode", "empate"]
		if not no_zero:
			s["guida"]["valore"] = 0
	# effetti alla dichiarazione
	if leader(i) == "arrivista":
		_spingi({"k": "scegli_risorsa", "g": i, "motivo": "Arrivista: scegli una risorsa da ottenere"})
	if leader(i) == "demagogo":
		_spingi({"k": "demagogo", "g": i})
	if ha_carta(i, "c17"):
		_spingi({"k": "veggenti", "g": i})
	_h_dichiara(i, amb)

func _p_dichiara(p: Dictionary) -> void:
	var i: int = p["g"]
	var c: String = p["c"]
	if _ha_r(p):
		var v = _r(p)
		if not _e(v, "no"):
			if leader(i) == "edonista":
				_spingi({"k": "dichiara_dopo", "g": i, "amb": v})
				_spingi({"k": "dai_gilda", "g": i})
			else:
				_dichiara(i, v, true)
		return
	if _segnalino_libero() < 0:
		return
	var val := Dati.valore(c)
	var possibili := []
	if val == 7:
		possibili = Dati.AMBIZIONI.duplicate()
	elif Dati.AMBIZIONE_DI_VALORE.has(val):
		possibili = [Dati.AMBIZIONE_DI_VALORE[val]]
	if possibili.is_empty():
		return
	if leader(i) == "edonista" and G(i)["carte"].filter(func(x): return Dati.info(x)[1] == "gilda").is_empty():
		return
	var ops := [{"t": "Non dichiarare", "v": "no"}]
	var k := _segnalino_libero()
	var vs := valore_segnalino(k)
	for a in possibili:
		ops.append({"t": "Dichiara %s (%d/%d Potere)" % [Dati.NOME_AMBIZIONE[a], vs[0], vs[1]], "v": a, "amb": a})
	_chiedi(p, i, "Vuoi dichiarare un'ambizione prima delle tue azioni?", ops, "dichiara")

func _p_dichiara_dopo(p: Dictionary) -> void:
	_dichiara(p["g"], p["amb"], true)

## Edonista (Generoso): dà 1 carta Gilda al Rivale con meno Potere.
func _p_dai_gilda(p: Dictionary) -> void:
	var i: int = p["g"]
	var meno := -1
	for j in s["n"]:
		if j != i and (meno < 0 or G(j)["potere"] < G(meno)["potere"]):
			meno = j
	if _ha_r(p):
		var c: String = _r(p)
		G(i)["carte"].erase(c)
		G(meno)["carte"].append(c)
		_log("%s dà %s a %s." % [_nome(i), Dati.nome_corte(c), _nome(meno)])
		return
	var ops := []
	for c in G(i)["carte"]:
		if Dati.info(c)[1] == "gilda":
			ops.append({"t": "Dai " + Dati.nome_corte(c), "v": c, "carta": c})
	_chiedi(p, i, "Generoso: dai 1 carta Gilda a %s" % _nome(meno), ops, "carta")

func _p_scegli_risorsa(p: Dictionary) -> void:
	var i: int = p["g"]
	if _ha_r(p):
		var t = _r(p)
		if not _e(t, "no"):
			_ottieni(i, t)
		return
	var ops := []
	for t in Dati.RISORSE:
		if riserva(t) > 0:
			ops.append({"t": Dati.NOME_RISORSA[t], "v": t, "risorsa": t})
	if ops.is_empty():
		return
	ops.append({"t": "Nessuna", "v": "no"})
	_chiedi(p, i, p["motivo"], ops, "risorsa")

func _p_demagogo(p: Dictionary) -> void:
	var i: int = p["g"]
	if not p.has("fatte"):
		p["fatte"] = []
	if _ha_r(p):
		var v = _r(p)
		if _e(v, "basta"):
			return
		_influenza(i, int(v))
		p["fatte"].append(int(v))
	if G(i)["agenti"] <= 0:
		return
	var ops := [{"t": "Basta così", "v": "basta"}]
	for k in s["corte"].size():
		if not k in p["fatte"]:
			ops.append({"t": "Influenza " + Dati.nome_corte(s["corte"][k]["c"]), "v": k, "corte": k})
	if ops.size() == 1:
		return
	_chiedi(p, i, "Ardito: Influenza le carte della Corte che vuoi (una volta ciascuna)", ops, "corte")

func _p_veggenti(p: Dictionary) -> void:
	var i: int = p["g"]
	if _ha_r(p):
		var v = _r(p)
		if v is Array:
			var j: int = v[0]
			var mia: String = v[1]
			var sua: String = v[2]
			G(i)["mano"].erase(mia)
			G(j)["mano"].erase(sua)
			G(i)["mano"].append(sua)
			G(j)["mano"].append(mia)
			_log("Veggenti: %s scambia una carta con %s." % [_nome(i), _nome(j)])
		elif v is int:
			p["j"] = v
		else:
			return
	if not p.has("j"):
		var ops := [{"t": "Non guardare", "v": "no"}]
		for j in s["n"]:
			if j != i and not G(j)["mano"].is_empty():
				ops.append({"t": "Guarda la mano di " + _nome(j), "v": j})
		if ops.size() == 1:
			return
		_chiedi(p, i, "Veggenti: guarda la mano di un Rivale", ops)
		return
	if p.has("fatto"):
		return
	p["fatto"] = true
	var j: int = p["j"]
	var ops := [{"t": "Non scambiare", "v": "no"}]
	for sua in G(j)["mano"]:
		for mia in G(i)["mano"]:
			ops.append({"t": "Prendi %s e dai %s" % [Dati.nome_carta_azione(sua), Dati.nome_carta_azione(mia)], "v": [j, mia, sua]})
	_chiedi(p, i, "Mano di %s: %s" % [_nome(j), ", ".join(G(j)["mano"].map(func(x): return Dati.nome_carta_azione(x)))], ops)

# ---------------------------------------------------------------- il turno: preludio e azioni
func _p_turno(p: Dictionary) -> void:
	var t: Dictionary = s["turno"]
	var i: int = t["g"]
	if _ha_r(p):
		var v = _r(p)
		_esegui_scelta_turno(p, v)
		return
	var ops := []
	if t["preludio"]:
		ops.append_array(_opzioni_preludio(i))
	if t["punti"] > 0:
		ops.append_array(_opzioni_azioni(i))
	ops.append({"t": "Termina il turno" if not t["preludio"] or t["punti"] <= 0 else "Termina il turno (senza azioni)", "v": "fine"})
	var testo := ""
	if t["punti"] > 0:
		testo = "%s: %d azion%s %s" % [Dati.nome_carta_azione(t["c"]) if t["modo"] != "copia" else "Copia", t["punti"], "e" if t["punti"] == 1 else "i", Dati.NOME_SEME[t["seme"]]]
	else:
		testo = "Azioni finite"
	if t["preludio"]:
		testo += " — Preludio: puoi spendere risorse e usare le carte"
	_chiedi(p, i, testo, ops, "turno")

func _azioni_disponibili(i: int) -> Array:
	var t: Dictionary = s["turno"]
	var a: Array = Dati.AZIONI_SEME[t["seme"]].duplicate()
	if t["armi"] and not "combattere" in a:
		a.append("combattere")
	if t["modo"] in ["copia", "cambia"]:
		pass
	return a

func _opzioni_azioni(i: int) -> Array:
	var ops := []
	for a in _azioni_disponibili(i):
		for x in _varianti(i, a):
			if _azione_possibile(i, x):
				ops.append({"t": _nome_variante(x), "v": "az:" + x, "azione": x})
	return ops

## Azioni nuove delle carte (si fanno al posto di quella principale).
func _varianti(i: int, a: String) -> Array:
	var v := [a]
	match a:
		"costruire":
			if ha_carta(i, "c02"): v.append("estrarre")
			if ha_carta(i, "c09"): v.append("sintetizzare")
			if ha_carta(i, "c12"): v.append("reclutare")
			if ha_lore(i, "l01"): v.append("evocare")
			if ha_lore(i, "l10"): v.append("nutrire")
		"influenzare":
			if ha_carta(i, "c12"): v.append("giustiziare")
		"combattere":
			if ha_carta(i, "c14"): v.append("rapire")
			if ha_lore(i, "l02"): v.append("sparare")
		"tassare":
			if ha_carta(i, "c23"): v.append("commerciare")
		"riparare":
			if ha_lore(i, "l10"): v.append("potare")
	return v

const NOMI_VARIANTI := {"estrarre": "Estrarre (Costruire): ottieni 1 Materiale",
	"sintetizzare": "Sintetizzare (Costruire): ottieni 1 Carburante",
	"reclutare": "Reclutare (Costruire): Prigionieri in risorse",
	"evocare": "Evocare (Costruire): nave in una città che controlli",
	"nutrire": "Nutrire (Costruire): Tassa una città Leale",
	"giustiziare": "Giustiziare (Influenzare): Prigionieri nei Trofei",
	"rapire": "Rapire (Combattere): cattura agenti dalla Corte",
	"sparare": "Sparare (Combattere): Cannoni Galattici",
	"commerciare": "Commerciare (Tassare): scambia una risorsa",
	"potare": "Potare (Riparare): scambia spazioporto e città"}

func _nome_variante(x: String) -> String:
	return NOMI_VARIANTI.get(x, Dati.NOME_AZIONE.get(x, x))

func _azione_possibile(i: int, a: String) -> bool:
	match a:
		"tassare": return not _bersagli_tassa(i, false).is_empty()
		"nutrire": return not _bersagli_tassa(i, true).is_empty()
		"costruire": return not _opzioni_costruire(i).is_empty()
		"riparare": return not _opzioni_riparare(i).is_empty()
		"influenzare": return G(i)["agenti"] > 0 and not s["corte"].is_empty()
		"acquisire": return not _carte_acquisibili(i).is_empty()
		"muovere": return not _origini_movimento(i).is_empty()
		"combattere": return not _sistemi_battaglia(i).is_empty()
		"estrarre": return riserva("materiale") > 0
		"sintetizzare": return riserva("carburante") > 0
		"reclutare": return not G(i)["prigionieri"].is_empty()
		"giustiziare": return not G(i)["prigionieri"].is_empty()
		"evocare": return not s["turno"]["tecnopreti"] and G(i)["navi"] > 0 and not _citta_controllate(i).is_empty()
		"rapire": return not _bersagli_rapire(i).is_empty()
		"sparare": return not _bersagli_sparare(i).is_empty()
		"commerciare": return not _bersagli_commercio(i).is_empty()
		"potare": return not edifici_di(i).is_empty()
	return true

func _opzioni_preludio(i: int) -> Array:
	var t: Dictionary = s["turno"]
	var ops := []
	# risorse
	var tipi_spendibili := {}
	for r in G(i)["risorse"] + [G(i)["antichi"]]:
		if r != "":
			tipi_spendibili[r] = true
	for r in tipi_spendibili:
		var come := [r]
		for c in Dati.LEALI:
			if ha_carta(i, c) and not Dati.LEALI[c] in come:
				come.append(Dati.LEALI[c])
		for x in come:
			var ignora: bool = false
			for c in Dati.LEALI:
				if ha_carta(i, c) and Dati.LEALI[c] == x:
					ignora = true
			if x in G(i)["oltraggio"] and not ignora:
				continue
			var cosa: String = {"materiale": "Costruire o Riparare", "carburante": "Muovere", "armi": "Combattere con questa carta",
				"reliquie": "Acquisire", "psico": "1 azione della carta Guida"}[x]
			if x == "armi" and t["armi"]:
				continue
			var testo := "Spendi %s: %s" % [Dati.NOME_RISORSA[r], cosa]
			if x != r:
				testo = "Spendi %s come %s: %s" % [Dati.NOME_RISORSA[r], Dati.NOME_RISORSA[x], cosa]
			ops.append({"t": testo, "v": "spendi:%s:%s" % [r, x], "risorsa": r})
	# carte con Preludio
	for c in G(i)["carte"]:
		var o := _preludio_carta(i, c)
		if not o.is_empty():
			ops.append(o)
	return ops

func _preludio_carta(i: int, c: String) -> Dictionary:
	var t: Dictionary = s["turno"]
	var v := "carta:" + c
	match c:
		"c02": return {"t": "Attività Minerarie: riempi gli spazi liberi di Materiale", "v": v, "carta": c}
		"c09": return {"t": "Alleanza Logistica: riempi gli spazi liberi di Carburante", "v": v, "carta": c}
		"c03":
			if _rivali_con(i, "materiale"): return {"t": "Cartello del Materiale: scartalo e ruba 1 Materiale", "v": v, "carta": c}
		"c06":
			if _rivali_con(i, "carburante"): return {"t": "Cartello del Carburante: scartalo e ruba 1 Carburante", "v": v, "carta": c}
		"c04", "c05", "c10", "c11":
			for gi in s["giocate"].size():
				var gg: Dictionary = s["giocate"][gi]
				if gg["su"] and Dati.seme(gg["c"]) == Dati.LEGHE[c] and gg["modo"] != "sottrai":
					return {"t": "%s: mettila accanto alla carta giocata (torna in mano)" % Dati.nome_corte(c), "v": v, "carta": c}
		"c08": return {"t": "Guardiani dei Portali: scartala, 1 nave in ogni portale", "v": v, "carta": c}
		"c12", "c13", "c14":
			if not _sistemi_controllati(i).is_empty():
				return {"t": "%s: scartala, 3 navi in un sistema che controlli" % Dati.nome_corte(c), "v": v, "carta": c}
		"c16":
			if s["sottratta"] < 0 and s["iniz"] != i and t["preludio"] and t.get("fatte_preludio", 0) == 0:
				return {"t": "Spie del Reticolo: scartala e sottrai l'iniziativa", "v": v, "carta": c}
		"c17":
			if not s["scarti_azioni"].is_empty():
				return {"t": "Veggenti: scartala con altre carte e ripesca dal fondo degli scarti", "v": v, "carta": c}
		"c20": return {"t": "Persuasore: scartala e ruba 1 carta Gilda o 1 risorsa", "v": v, "carta": c}
		"c23": return {"t": "Negoziatore Anziano: scartalo per 1 Materiale, 1 Carburante e 1 Armi", "v": v, "carta": c}
		"c24":
			if not t["trafficante"] and _ha_risorse(i):
				return {"t": "Trafficante di Reliquie: scarta 1 risorsa per 1 Reliquia", "v": v, "carta": c}
	return {}

func _ha_risorse(i: int) -> bool:
	for r in G(i)["risorse"]:
		if r != "":
			return true
	return G(i)["antichi"] != ""

func _rivali_con(i: int, t: String) -> bool:
	for j in s["n"]:
		if j != i and conta_risorsa(j, t) > 0 and not ha_carta(j, "c22"):
			return true
	return false

func _esegui_scelta_turno(p: Dictionary, v) -> void:
	var t: Dictionary = s["turno"]
	var i: int = t["g"]
	if _e(v, "fine"):
		_fine_turno()
		return
	var sv: String = v
	if sv.begins_with("az:"):
		var a := sv.substr(3)
		if t["preludio"]:
			_chiudi_preludio()
		t["punti"] -= 1
		_spingi(p)
		_spingi({"k": "az_" + _base_azione(a), "g": i, "a": a, "da": "punto"})
		return
	t["fatte_preludio"] = int(t.get("fatte_preludio", 0)) + 1
	if sv.begins_with("spendi:"):
		var parti := sv.split(":")
		var r: String = parti[1]
		var come: String = parti[2]
		_togli_risorsa(i, r)
		t["spesi"].append(r)
		_h_spendi(i, r)
		_log("%s spende 1 %s%s." % [_nome(i), Dati.NOME_RISORSA[r], "" if r == come else " come " + Dati.NOME_RISORSA[come]])
		_ev({"tipo": "spendi", "g": i, "t": r})
		_spingi(p)
		match come:
			"materiale":
				_spingi({"k": "scegli_azione", "g": i, "tra": ["costruire", "riparare"]})
			"carburante":
				_spingi({"k": "scegli_azione", "g": i, "tra": ["muovere"]})
			"armi":
				t["armi"] = true
			"reliquie":
				_spingi({"k": "scegli_azione", "g": i, "tra": ["acquisire"]})
			"psico":
				_spingi({"k": "scegli_azione", "g": i, "tra": Dati.AZIONI_SEME[Dati.seme(s["guida"]["c"])]})
		return
	if sv.begins_with("carta:"):
		var c := sv.substr(6)
		_spingi(p)
		_preludio_esegui(i, c)

func _base_azione(a: String) -> String:
	match a:
		"estrarre", "sintetizzare", "reclutare", "evocare", "nutrire": return a
		"giustiziare", "rapire", "sparare", "commerciare", "potare": return a
	return a

## Una risorsa spesa: scegli quale azione fare (con le sue varianti).
func _p_scegli_azione(p: Dictionary) -> void:
	var i: int = p["g"]
	if _ha_r(p):
		var a = _r(p)
		if _e(a, "no"):
			return
		_spingi({"k": "az_" + a, "g": i, "a": a, "da": "risorsa"})
		return
	var ops := []
	for a in p["tra"]:
		for x in _varianti(i, a):
			if _azione_possibile(i, x):
				ops.append({"t": _nome_variante(x), "v": x, "azione": x})
	ops.append({"t": "Nessuna azione", "v": "no"})
	_chiedi(p, i, "Quale azione fai con la risorsa spesa?", ops, "azione")

func _chiudi_preludio() -> void:
	var t: Dictionary = s["turno"]
	t["preludio"] = false
	t["spesi"] = []

func _fine_turno() -> void:
	var t: Dictionary = s["turno"]
	var i: int = t["g"]
	t["preludio"] = false
	_h_fine_turno(i)
	# Eliminazione: senza spazioporti né navi si rientra con 3 navi in un portale
	var ha := false
	for id in s["mappa"]:
		if navi(id, i) > 0:
			ha = true
			break
	if not ha and porti_di(i).is_empty():
		_spingi({"k": "rientro", "g": i})

func _p_rientro(p: Dictionary) -> void:
	var i: int = p["g"]
	if _ha_r(p):
		var id: String = _r(p)
		_metti_navi(i, id, 3, false)
		_log("%s rientra con 3 navi nel %s." % [_nome(i), _desc_sis(id)])
		_ev({"tipo": "nave", "sis": id, "g": i})
		return
	var ops := []
	for k in range(1, 7):
		var id := "%dg" % k
		if in_gioco(id):
			ops.append({"t": _desc_sis(id), "v": id, "sis": id})
	_chiedi(p, i, "Non hai navi né spazioporti: scegli un portale dove mettere 3 navi", ops, "sistema")

# ---------------------------------------------------------------- preludi delle carte
func _preludio_esegui(i: int, c: String) -> void:
	var t: Dictionary = s["turno"]
	match c:
		"c02", "c09":
			var tipo := "materiale" if c == "c02" else "carburante"
			_scarta_corte(i, c)
			var liberi := 0
			for k in spazi_aperti(i):
				if G(i)["risorse"][k] == "":
					liberi += 1
			var presi := 0
			for k in liberi:
				if riserva(tipo) > 0:
					_metti_risorsa_libera(i, tipo)
					presi += 1
				else:
					for j in ordine_da(i):
						if j != i and conta_risorsa(j, tipo) > 0 and not ha_carta(j, "c22"):
							_togli_risorsa(j, tipo)
							_metti_risorsa_libera(i, tipo)
							presi += 1
							break
			_log("%s ottiene %d %s." % [_nome(i), presi, Dati.NOME_RISORSA[tipo]])
		"c03", "c06":
			_scarta_corte(i, c)
			_spingi({"k": "ruba_risorsa", "g": i, "t": "materiale" if c == "c03" else "carburante"})
		"c04", "c05", "c10", "c11":
			G(i)["carte"].erase(c)
			var gi := -1
			for k in s["giocate"].size():
				var gg: Dictionary = s["giocate"][k]
				if gg["su"] and Dati.seme(gg["c"]) == Dati.LEGHE[c] and gg["modo"] != "sottrai":
					gi = k
			s["leghe"].append({"g": i, "c": c, "carta": s["giocate"][gi]["c"]})
			_log("%s mette %s accanto a %s." % [_nome(i), Dati.nome_corte(c), Dati.nome_carta_azione(s["giocate"][gi]["c"])])
		"c08":
			_scarta_corte(i, c)
			for k in range(1, 7):
				var id := "%dg" % k
				if in_gioco(id):
					_metti_navi(i, id, 1, false)
					_ev({"tipo": "nave", "sis": id, "g": i})
		"c12", "c13", "c14":
			_scarta_corte(i, c)
			_spingi({"k": "tre_navi", "g": i})
		"c16":
			_scarta_corte(i, c)
			s["sottratta"] = i
			_log("%s sottrae l'iniziativa con le Spie del Reticolo." % _nome(i))
			_ev({"tipo": "sottrai", "g": i})
		"c17":
			_scarta_corte(i, c)
			_spingi({"k": "veggenti_preludio", "g": i})
		"c20":
			_scarta_corte(i, c)
			_spingi({"k": "persuasore", "g": i})
		"c23":
			_scarta_corte(i, c)
			_ottieni(i, "armi")
			_ottieni(i, "carburante")
			_ottieni(i, "materiale")
		"c24":
			t["trafficante"] = true
			_spingi({"k": "trafficante", "g": i})

func _metti_risorsa_libera(i: int, t: String) -> void:
	for k in spazi_aperti(i):
		if G(i)["risorse"][k] == "":
			G(i)["risorse"][k] = t
			return

func _scarta_corte(i: int, c: String) -> void:
	G(i)["carte"].erase(c)
	s["scarti_corte"].append(c)
	if Dati.info(c)[1] == "gilda" and s.has("turno") and not s["turno"].is_empty():
		_h_preludio_gilda(i, c)
	_ev({"tipo": "carta_corte", "g": i, "c": c})

func _p_ruba_risorsa(p: Dictionary) -> void:
	var i: int = p["g"]
	if _ha_r(p):
		var j: int = _r(p)
		_togli_risorsa(j, p["t"])
		_log("%s ruba 1 %s a %s." % [_nome(i), Dati.NOME_RISORSA[p["t"]], _nome(j)])
		if not _h_ruba(i, p["t"]):
			_ottieni_diretto(i, p["t"])
		return
	var ops := []
	for j in s["n"]:
		if j != i and conta_risorsa(j, p["t"]) > 0 and not ha_carta(j, "c22"):
			ops.append({"t": "Ruba a " + _nome(j), "v": j})
	if ops.is_empty():
		return
	_chiedi(p, i, "A chi rubi 1 %s?" % Dati.NOME_RISORSA[p["t"]], ops)

## Una risorsa presa da un Rivale (non dalla riserva): stessa logica degli spazi.
func _ottieni_diretto(i: int, t: String) -> void:
	_spingi({"k": "ottieni_diretto", "g": i, "t": t})

func _p_ottieni_diretto(p: Dictionary) -> void:
	var i: int = p["g"]
	var t: String = p["t"]
	if _ha_r(p):
		var v = _r(p)
		if v is int:
			G(i)["risorse"][v] = t
		return
	for k in spazi_aperti(i):
		if G(i)["risorse"][k] == "":
			G(i)["risorse"][k] = t
			_ev({"tipo": "risorsa", "g": i, "t": t})
			return
	if ha_lore(i, "l13") and G(i)["antichi"] == "":
		G(i)["antichi"] = t
		return
	var ops := [{"t": "Rinuncia a %s" % Dati.NOME_RISORSA[t], "v": "nuova"}]
	for k in spazi_aperti(i):
		ops.append({"t": "Scarta %s" % Dati.NOME_RISORSA[G(i)["risorse"][k]], "v": k})
	_chiedi(p, i, "Spazi pieni: cosa scarti per tenere 1 %s?" % Dati.NOME_RISORSA[t], ops, "scarta")

func _p_tre_navi(p: Dictionary) -> void:
	var i: int = p["g"]
	if _ha_r(p):
		var id: String = _r(p)
		_metti_navi(i, id, 3, false)
		_log("%s mette 3 navi in %s." % [_nome(i), _desc_sis(id)])
		_ev({"tipo": "nave", "sis": id, "g": i})
		return
	var ops := []
	for id in _sistemi_controllati(i):
		ops.append({"t": _desc_sis(id), "v": id, "sis": id})
	_chiedi(p, i, "Dove metti 3 navi? (un sistema che controlli)", ops, "sistema")

func _sistemi_controllati(i: int) -> Array:
	var out := []
	for id in s["mappa"]:
		if in_gioco(id) and controllo(id) == i:
			out.append(id)
	return out

func _p_veggenti_preludio(p: Dictionary) -> void:
	var i: int = p["g"]
	if not p.has("via"):
		p["via"] = []
	if _ha_r(p):
		var v = _r(p)
		if _e(v, "basta"):
			var n: int = p["via"].size() + 1
			for k in n:
				if s["scarti_azioni"].is_empty():
					break
				G(i)["mano"].append(s["scarti_azioni"].pop_front())
			s["scarti_azioni"].append_array(p["via"])
			_log("%s ripesca %d carte dal fondo degli scarti." % [_nome(i), n])
			return
		G(i)["mano"].erase(v)
		p["via"].append(v)
	var ops := [{"t": "Basta: ripesca", "v": "basta"}]
	for c in G(i)["mano"]:
		ops.append({"t": "Scarta anche " + Dati.nome_carta_azione(c), "v": c, "mano": c})
	_chiedi(p, i, "Veggenti: scarta le carte che vuoi (ne ripeschi altrettante più una)", ops)

func _p_persuasore(p: Dictionary) -> void:
	var i: int = p["g"]
	if _ha_r(p):
		var v: Array = _r(p)
		var j: int = v[0]
		if v[1] == "carta":
			var c: String = v[2]
			G(j)["carte"].erase(c)
			if c == "c22":
				s["mazzo_corte"].append(c)
				_log("%s ruba i Guardiani Giurati a %s: vengono sepolti." % [_nome(i), _nome(j)])
			else:
				G(i)["carte"].append(c)
				_log("%s ruba %s a %s." % [_nome(i), Dati.nome_corte(c), _nome(j)])
		else:
			_togli_risorsa(j, v[2])
			_log("%s ruba 1 %s a %s." % [_nome(i), Dati.NOME_RISORSA[v[2]], _nome(j)])
			_ottieni_diretto(i, v[2])
		return
	var ops := []
	for j in s["n"]:
		if j == i:
			continue
		var protetto := ha_carta(j, "c22")
		for c in G(j)["carte"]:
			if Dati.info(c)[1] == "gilda" and (not protetto or c == "c22"):
				ops.append({"t": "Ruba %s a %s" % [Dati.nome_corte(c), _nome(j)], "v": [j, "carta", c], "carta": c})
		if not protetto:
			var visti := {}
			for r in G(j)["risorse"] + [G(j)["antichi"]]:
				if r != "" and not visti.has(r):
					visti[r] = true
					ops.append({"t": "Ruba 1 %s a %s" % [Dati.NOME_RISORSA[r], _nome(j)], "v": [j, "risorsa", r], "risorsa": r})
	if ops.is_empty():
		return
	_chiedi(p, i, "Persuasore: cosa rubi?", ops)

func _p_trafficante(p: Dictionary) -> void:
	var i: int = p["g"]
	if _ha_r(p):
		var r = _r(p)
		if _e(r, "no"):
			return
		_togli_risorsa(i, r)
		_ottieni(i, "reliquie")
		return
	var ops := [{"t": "Nessuna", "v": "no"}]
	var visti := {}
	for r in G(i)["risorse"] + [G(i)["antichi"]]:
		if r != "" and not visti.has(r):
			visti[r] = true
			ops.append({"t": "Scarta 1 " + Dati.NOME_RISORSA[r], "v": r, "risorsa": r})
	_chiedi(p, i, "Trafficante di Reliquie: quale risorsa scarti per 1 Reliquia?", ops)

# ================================================================ azioni principali
# ---------------------------------------------------------------- Tassare
func _bersagli_tassa(i: int, solo_leali: bool) -> Array:
	var out := []
	var tassate: Array = s["turno"]["tassate"] if s.has("turno") else []
	for id in s["mappa"]:
		if not in_gioco(id):
			continue
		var ed: Array = s["mappa"][id]["edifici"]
		for k in ed.size():
			var e = ed[k]
			if e == null or e["t"] != "citta":
				continue
			var chiave := "%s:%d" % [id, k]
			if chiave in tassate:
				continue
			if e["g"] == i:
				if leader(i) == "arrivista" and controllo(id) != i:
					continue
				out.append([id, k])
			elif not solo_leali and controllo(id) == i:
				out.append([id, k])
	return out

func _desc_citta(g: int, i: int) -> String:
	if g == i:
		return "Leale"
	if g >= s["n"]:
		return "Libera"
	return "di " + _nome(g)

func _tipi_citta(id: String) -> Array:
	if not Dati.is_portale(id):
		return [Dati.TIPO[id]]
	var out := []
	var sett := Dati.settore(id)
	for l in ["a", "b", "c"]:
		var pid := "%d%s" % [sett, l]
		for e in s["mappa"][pid]["edifici"]:
			if e != null and e["t"] == "citta" and not Dati.TIPO[pid] in out:
				out.append(Dati.TIPO[pid])
	return out

func _p_az_tassare(p: Dictionary) -> void:
	_tassa(p, false)

func _p_az_nutrire(p: Dictionary) -> void:
	_tassa(p, true)

func _tassa(p: Dictionary, nutrire: bool) -> void:
	var i: int = p["g"]
	if _ha_r(p):
		var v: Array = _r(p)
		var id: String = v[0]
		var k: int = v[1]
		var e: Dictionary = s["mappa"][id]["edifici"][k]
		s["turno"]["tassate"].append("%s:%d" % [id, k])
		var tipi := _tipi_citta(id)
		_ev({"tipo": "tassa", "sis": id, "g": i})
		if tipi.size() > 1:
			_spingi({"k": "scegli_tra", "g": i, "tra": tipi})
		elif tipi.size() == 1:
			_ottieni(i, tipi[0])
		_log("%s tassa la città %s in %s." % [_nome(i), _desc_citta(e["g"], i), _desc_sis(id)])
		if e["g"] != i and e["g"] < s["n"]:
			var j: int = e["g"]
			if G(j)["agenti"] > 0:
				G(j)["agenti"] -= 1
				G(i)["prigionieri"].append(j)
				_h_cattura(i, j)
				_log("%s cattura 1 agente di %s." % [_nome(i), _nome(j)])
		var modo: String = s["turno"]["modo"]
		if modo in ["copia", "cambia"] and p.get("da", "") == "punto":
			if leader(i) == "mistico":
				_ottieni(i, "psico")
			if leader(i) == "divoratore":
				_ottieni(i, "carburante")
		return
	var ops := []
	for x in _bersagli_tassa(i, nutrire):
		var e: Dictionary = s["mappa"][x[0]]["edifici"][x[1]]
		ops.append({"t": "Tassa la città %s in %s" % [_desc_citta(e["g"], i), _desc_sis(x[0])], "v": x, "sis": x[0]})
	_chiedi(p, i, "Quale città tassi?", ops, "sistema")

func _p_scegli_tra(p: Dictionary) -> void:
	var i: int = p["g"]
	if _ha_r(p):
		_ottieni(i, _r(p))
		return
	var ops := []
	for t in p["tra"]:
		ops.append({"t": Dati.NOME_RISORSA[t], "v": t, "risorsa": t})
	_chiedi(p, i, "Quale risorsa ottieni?", ops, "risorsa")

func _bersagli_commercio(i: int) -> Array:
	var out := []
	for id in s["mappa"]:
		if not in_gioco(id) or controllo(id) != i:
			continue
		for e in s["mappa"][id]["edifici"]:
			if e != null and e["t"] == "citta" and e["g"] != i:
				out.append([id, e["g"]])
	return out

func _p_az_commerciare(p: Dictionary) -> void:
	var i: int = p["g"]
	if _ha_r(p):
		var v: Array = _r(p)
		if v.size() == 2:
			p["scelta"] = v
		else:
			var j: int = v[0]
			var prendi: String = v[1]
			var dai: String = v[2]
			_togli_risorsa(j, prendi)
			_togli_risorsa(i, dai)
			_metti_risorsa_libera(j, dai)
			_metti_risorsa_libera(i, prendi)
			_log("%s commercia con %s: prende %s e dà %s." % [_nome(i), _nome(j), Dati.NOME_RISORSA[prendi], Dati.NOME_RISORSA[dai]])
			return
	if not p.has("scelta"):
		var ops := []
		for x in _bersagli_commercio(i):
			ops.append({"t": "Commercia con %s (città in %s)" % [_nome(x[1]), _desc_sis(x[0])], "v": x, "sis": x[0]})
		_chiedi(p, i, "Con chi commerci?", ops, "sistema")
		return
	var id: String = p["scelta"][0]
	var j: int = p["scelta"][1]
	var tipo: String = Dati.TIPO[id] if not Dati.is_portale(id) else _tipi_citta(id)[0]
	var ops := []
	if conta_risorsa(j, tipo) > 0:
		var visti := {}
		for r in G(i)["risorse"]:
			if r != "" and conta_risorsa(j, r) == 0 and not visti.has(r):
				visti[r] = true
				ops.append({"t": "Prendi %s, dai %s" % [Dati.NOME_RISORSA[tipo], Dati.NOME_RISORSA[r]], "v": [j, tipo, r]})
	if ops.is_empty():
		_log("Commercio impossibile con %s." % _nome(j))
		return
	_chiedi(p, i, "Cosa scambi?", ops)

# ---------------------------------------------------------------- Costruire
func _opzioni_costruire(i: int) -> Array:
	var out := []
	var t: Dictionary = s["turno"] if s.has("turno") else {}
	var ha_citta: bool = G(i)["citta_plancia"].has(true)
	for id in s["mappa"]:
		if not in_gioco(id) or not ha_pezzi(id, i):
			continue
		var libero := _slot_libero(id) >= 0
		if Dati.is_portale(id):
			var ha_ed := false
			for e in s["mappa"][id]["edifici"]:
				if e != null and e["g"] == i:
					ha_ed = true
			if ha_lore(i, "l08") and G(i)["porti"] > 0 and not ha_ed:
				out.append(["porto", id])
			if ha_lore(i, "l11") and ha_citta and not ha_ed:
				out.append(["citta", id])
			continue
		if libero:
			if ha_citta:
				out.append(["citta", id])
			if G(i)["porti"] > 0:
				out.append(["porto", id])
		elif ha_lore(i, "l09") and ha_citta and conta_risorsa(i, Dati.TIPO[id]) > 0:
			var gia := false
			for e in s["mappa"][id]["edifici"]:
				if e != null and e.get("volante", false):
					gia = true
			if not gia:
				out.append(["volante", id])
	if G(i)["navi"] > 0:
		for x in porti_di(i):
			var chiave := "%s:%d" % [x[0], x[1]]
			if in_gioco(x[0]) and not (chiave in t.get("porti", [])):
				out.append(["nave", x[0], x[1]])
	return out

func _p_az_costruire(p: Dictionary) -> void:
	var i: int = p["g"]
	if _ha_r(p):
		var v: Array = _r(p)
		var id: String = v[1]
		var c := controllo(id)
		var danno := c >= 0 and c != i
		match v[0]:
			"citta":
				_metti_citta(i, id, danno)
				_log("%s costruisce una città in %s%s." % [_nome(i), _desc_sis(id), " (danneggiata)" if danno else ""])
			"volante":
				_togli_risorsa(i, Dati.TIPO[id])
				_metti_citta(i, id, danno)
				var ed: Array = s["mappa"][id]["edifici"]
				for e in ed:
					if e != null and e["g"] == i and e["t"] == "citta":
						e["volante"] = true
				_log("%s costruisce una Città Volante in %s." % [_nome(i), _desc_sis(id)])
			"porto":
				_metti_porto(i, id, danno)
				_log("%s costruisce uno spazioporto in %s%s." % [_nome(i), _desc_sis(id), " (danneggiato)" if danno else ""])
			"nave":
				s["turno"]["porti"].append("%s:%d" % [id, v[2]])
				if ha_lore(i, "l05"):
					danno = false
				_metti_navi(i, id, 1, danno)
				_log("%s costruisce una nave in %s%s." % [_nome(i), _desc_sis(id), " (danneggiata)" if danno else ""])
		_ev({"tipo": "costruisci", "sis": id, "g": i, "cosa": v[0]})
		return
	var ops := []
	for x in _opzioni_costruire(i):
		var nomi := {"citta": "Città", "porto": "Spazioporto", "nave": "Nave", "volante": "Città Volante"}
		ops.append({"t": "%s in %s" % [nomi[x[0]], _desc_sis(x[1])], "v": x, "sis": x[1], "cosa": x[0]})
	_chiedi(p, i, "Cosa costruisci?", ops, "sistema")

func _p_az_estrarre(p: Dictionary) -> void:
	_ottieni(p["g"], "materiale")

func _p_az_sintetizzare(p: Dictionary) -> void:
	_ottieni(p["g"], "carburante")

func _p_az_reclutare(p: Dictionary) -> void:
	var i: int = p["g"]
	if _ha_r(p):
		var n: int = _r(p)
		for k in n:
			var j: int = G(i)["prigionieri"].pop_back()
			G(j)["agenti"] += 1
			_spingi({"k": "scegli_risorsa", "g": i, "motivo": "Reclutare: scegli la risorsa"})
		_log("%s restituisce %d prigionieri." % [_nome(i), n])
		return
	var ops := []
	for n in range(1, G(i)["prigionieri"].size() + 1):
		ops.append({"t": "Restituisci %d prigionier%s" % [n, "o" if n == 1 else "i"], "v": n})
	_chiedi(p, i, "Reclutare: quanti Prigionieri restituisci?", ops)

func _p_az_giustiziare(p: Dictionary) -> void:
	var i: int = p["g"]
	if _ha_r(p):
		var n: int = _r(p)
		for k in n:
			var j: int = G(i)["prigionieri"].pop_back()
			G(i)["trofei"].append({"t": "agente", "g": j})
		_log("%s giustizia %d prigionieri." % [_nome(i), n])
		return
	var ops := []
	for n in range(1, G(i)["prigionieri"].size() + 1):
		ops.append({"t": "Sposta %d nei Trofei" % n, "v": n})
	_chiedi(p, i, "Giustiziare: quanti Prigionieri sposti nei Trofei?", ops)

func _citta_controllate(i: int) -> Array:
	var out := []
	for id in s["mappa"]:
		if in_gioco(id) and controllo(id) == i:
			for e in s["mappa"][id]["edifici"]:
				if e != null and e["t"] == "citta" and not id in out:
					out.append(id)
	return out

func _p_az_evocare(p: Dictionary) -> void:
	var i: int = p["g"]
	if _ha_r(p):
		var id: String = _r(p)
		s["turno"]["tecnopreti"] = true
		_metti_navi(i, id, 1, false)
		_log("%s evoca una nave in %s." % [_nome(i), _desc_sis(id)])
		_ev({"tipo": "costruisci", "sis": id, "g": i, "cosa": "nave"})
		return
	var ops := []
	for id in _citta_controllate(i):
		ops.append({"t": _desc_sis(id), "v": id, "sis": id})
	_chiedi(p, i, "Evocare: in quale città che controlli costruisci 1 nave?", ops, "sistema")

# ---------------------------------------------------------------- Riparare
func _opzioni_riparare(i: int) -> Array:
	var out := []
	for id in s["mappa"]:
		if s["mappa"][id]["navi"][i][1] > 0:
			out.append(["nave", id])
		var ed: Array = s["mappa"][id]["edifici"]
		for k in ed.size():
			if ed[k] != null and ed[k]["g"] == i and ed[k]["danno"]:
				out.append(["edificio", id, k])
	return out

func _p_az_riparare(p: Dictionary) -> void:
	var i: int = p["g"]
	if _ha_r(p):
		var v: Array = _r(p)
		var id: String = v[1]
		if v[0] == "nave":
			s["mappa"][id]["navi"][i][1] -= 1
			s["mappa"][id]["navi"][i][0] += 1
			_log("%s ripara una nave in %s." % [_nome(i), _desc_sis(id)])
		else:
			s["mappa"][id]["edifici"][v[2]]["danno"] = false
			_log("%s ripara un edificio in %s." % [_nome(i), _desc_sis(id)])
		_ev({"tipo": "ripara", "sis": id, "g": i})
		return
	var ops := []
	for x in _opzioni_riparare(i):
		var cosa := "nave"
		if x[0] == "edificio":
			cosa = "città" if s["mappa"][x[1]]["edifici"][x[2]]["t"] == "citta" else "spazioporto"
		ops.append({"t": "Ripara %s in %s" % [cosa, _desc_sis(x[1])], "v": x, "sis": x[1]})
	_chiedi(p, i, "Cosa ripari?", ops, "sistema")

func _p_az_potare(p: Dictionary) -> void:
	var i: int = p["g"]
	if _ha_r(p):
		var v: Array = _r(p)
		var e: Dictionary = s["mappa"][v[0]]["edifici"][v[1]]
		if e["t"] == "porto" and G(i)["citta_plancia"].has(true):
			G(i)["porti"] += 1
			G(i)["citta_plancia"][G(i)["citta_plancia"].find(true)] = false
			e["t"] = "citta"
		elif e["t"] == "citta" and G(i)["porti"] > 0:
			G(i)["porti"] -= 1
			_restituisci_citta(i)
			e["t"] = "porto"
		_log("%s pota un edificio in %s." % [_nome(i), _desc_sis(v[0])])
		return
	var ops := []
	for x in edifici_di(i):
		var e: Dictionary = s["mappa"][x[0]]["edifici"][x[1]]
		ops.append({"t": "%s in %s" % ["Da città a spazioporto" if e["t"] == "citta" else "Da spazioporto a città", _desc_sis(x[0])], "v": x, "sis": x[0]})
	_chiedi(p, i, "Potare: quale edificio sostituisci?", ops, "sistema")

# ---------------------------------------------------------------- Influenzare e Acquisire
func _influenza(i: int, k: int) -> void:
	if G(i)["agenti"] <= 0 or k >= s["corte"].size():
		return
	G(i)["agenti"] -= 1
	s["corte"][k]["ag"][i] += 1
	_log("%s influenza %s." % [_nome(i), Dati.nome_corte(s["corte"][k]["c"])])
	_ev({"tipo": "influenza", "g": i, "corte": k})

func _p_az_influenzare(p: Dictionary) -> void:
	var i: int = p["g"]
	if _ha_r(p):
		_influenza(i, int(_r(p)))
		return
	var ops := []
	for k in s["corte"].size():
		ops.append({"t": "Influenza " + Dati.nome_corte(s["corte"][k]["c"]), "v": k, "corte": k})
	_chiedi(p, i, "Su quale carta della Corte metti un agente?", ops, "corte")

func _carte_acquisibili(i: int) -> Array:
	var out := []
	for k in s["corte"].size():
		var m: int = s["corte"][k]["ag"][i]
		if m <= 0:
			continue
		var ok := true
		for j in s["n"]:
			if j != i and s["corte"][k]["ag"][j] >= m:
				ok = false
		if leader(i) == "demagogo" and m < 2 and Dati.info(s["corte"][k]["c"])[1] == "gilda":
			ok = false
		if ok:
			out.append(k)
	return out

func _p_az_acquisire(p: Dictionary) -> void:
	var i: int = p["g"]
	if _ha_r(p):
		var k: int = _r(p)
		var modo: String = s["turno"]["modo"]
		_acquisisci(i, k, false)
		if leader(i) == "edonista" and modo in ["copia", "cambia"] and p.get("da", "") == "punto" and G(i)["agenti"] > 0:
			_spingi({"k": "az_influenzare", "g": i, "facoltativa": true})
		return
	var ops := []
	for k in _carte_acquisibili(i):
		ops.append({"t": "Acquisisci " + Dati.nome_corte(s["corte"][k]["c"]), "v": k, "corte": k})
	_chiedi(p, i, "Quale carta della Corte acquisisci?", ops, "corte")

## Prende la carta k della Corte. soggiogo: gli agenti Rivali diventano Trofei.
func _acquisisci(i: int, k: int, soggiogo: bool) -> void:
	var slot: Dictionary = s["corte"][k]
	var c: String = slot["c"]
	for j in s["n"]:
		var a: int = slot["ag"][j]
		if a <= 0:
			continue
		if j == i:
			G(i)["agenti"] += a
		else:
			for z in a:
				if soggiogo:
					G(i)["trofei"].append({"t": "agente", "g": j})
				else:
					G(i)["prigionieri"].append(j)
					_h_cattura(i, j)
	s["corte"].remove_at(k)
	_log("%s acquisisce %s." % [_nome(i), Dati.nome_corte(c)])
	_ev({"tipo": "acquisisci", "g": i, "c": c})
	_h_acquisita(i, c)
	if s.has("turno"):
		s["turno"]["acquisite"].append(c)
	if Dati.info(c)[1] == "vox":
		_spingi({"k": "rifornisci"})
		_spingi({"k": "vox", "g": i, "c": c})
	else:
		G(i)["carte"].append(c)
		_rifornisci_corte_in(k)

func _rifornisci_corte_in(k: int) -> void:
	if s["mazzo_corte"].is_empty():
		return
	var c: String = s["mazzo_corte"].pop_front()
	s["corte"].insert(mini(k, s["corte"].size()), {"c": c, "ag": _zeri_int(s["n"])})

func _p_rifornisci(_p: Dictionary) -> void:
	var target := 3 if s["n"] == 2 else 4
	while s["corte"].size() < target and not s["mazzo_corte"].is_empty():
		_rifornisci_corte()

# ---------------------------------------------------------------- Vox
func _p_vox(p: Dictionary) -> void:
	var i: int = p["g"]
	var c: String = p["c"]
	var v: Variant = _r(p) if _ha_r(p) else null
	match c:
		"c26":
			if v != null:
				for l in ["g", "a", "b", "c"]:
					var id := "%d%s" % [v, l]
					_metti_navi(i, id, 1, false)
					_ev({"tipo": "nave", "sis": id, "g": i})
				_log("Rivolta di Massa: %s mette 1 nave in ogni sistema del settore %d." % [_nome(i), v])
				s["scarti_corte"].append(c)
				return
			var ops := []
			for k in range(1, 7):
				if not k in s["fuori"]:
					ops.append({"t": "Settore %d" % k, "v": k, "sis": "%dg" % k})
			_chiedi(p, i, "Rivolta di Massa: scegli un settore", ops, "sistema")
		"c27":
			s["scarti_corte"].append(c)
			if v != null:
				if not _e(v, "no"):
					_dichiara(i, v, false)
				return
			if _segnalino_libero() < 0:
				return
			p["c"] = c
			s["scarti_corte"].erase(c)
			var ops := [{"t": "Non dichiarare", "v": "no"}]
			for a in Dati.AMBIZIONI:
				ops.append({"t": "Dichiara " + Dati.NOME_AMBIZIONE[a], "v": a, "amb": a})
			s["scarti_corte"].append(c)
			_chiedi(p, i, "Richieste Populiste: dichiara una qualsiasi ambizione", ops, "dichiara")
		"c28":
			if v != null:
				s["scarti_corte"].append(c)
				for j in ordine_da(i):
					_oltraggio(j, v)
				return
			var ops := []
			for t in Dati.RISORSE:
				ops.append({"t": Dati.NOME_RISORSA[t], "v": t, "risorsa": t})
			_chiedi(p, i, "L'Oltraggio Dilaga: scegli il tipo (tutti, anche tu, Recano Oltraggio)", ops, "risorsa")
		"c29":
			if v != null:
				if not _e(v, "no"):
					var id: String = v[0]
					var k: int = v[1]
					var e: Dictionary = s["mappa"][id]["edifici"][k]
					s["mappa"][id]["edifici"][k] = null
					_restituisci_citta(e["g"])
					_log("Canto di Libertà: la città in %s torna a %s." % [_desc_sis(id), _nome(e["g"])])
					if s["sottratta"] < 0 and s["iniz"] != i:
						s["sottratta"] = i
						_log("%s sottrae l'iniziativa." % _nome(i))
				s["mazzo_corte"].append(c)
				_mescola(s["mazzo_corte"])
				return
			var ops := [{"t": "Non fare nulla", "v": "no"}]
			for id in s["mappa"]:
				if in_gioco(id) and controllo(id) == i:
					var ed: Array = s["mappa"][id]["edifici"]
					for k in ed.size():
						if ed[k] != null and ed[k]["t"] == "citta":
							ops.append({"t": "Città di %s in %s" % [_nome(ed[k]["g"]), _desc_sis(id)], "v": [id, k], "sis": id})
			_chiedi(p, i, "Canto di Libertà: quale città che controlli torna sulla plancia del proprietario?", ops, "sistema")
		"c30":
			if v != null:
				if not _e(v, "no"):
					var j: int = v[0]
					var cc: String = v[1]
					G(j)["carte"].erase(cc)
					if cc == "c22":
						s["mazzo_corte"].append(cc)
					else:
						G(i)["carte"].append(cc)
					_log("Conflitto fra Gilde: %s ruba %s a %s." % [_nome(i), Dati.nome_corte(cc), _nome(j)])
				var gilde := []
				var resto := []
				for x in s["scarti_corte"]:
					if Dati.info(x)[1] == "gilda":
						gilde.append(x)
					else:
						resto.append(x)
				s["scarti_corte"] = resto + [c]
				s["mazzo_corte"].append_array(gilde)
				_mescola(s["mazzo_corte"])
				return
			var ops := [{"t": "Non rubare", "v": "no"}]
			for j in s["n"]:
				if j == i:
					continue
				var protetto := ha_carta(j, "c22")
				for cc in G(j)["carte"]:
					if Dati.info(cc)[1] == "gilda" and (not protetto or cc == "c22"):
						ops.append({"t": "Ruba %s a %s" % [Dati.nome_corte(cc), _nome(j)], "v": [j, cc], "carta": cc})
			_chiedi(p, i, "Conflitto fra Gilde: puoi rubare 1 carta Gilda", ops, "carta")
		"c31":
			s["scarti_corte"].append(c)
			if not s["scarti_azioni"].is_empty():
				G(i)["mano"].append(s["scarti_azioni"].pop_front())
				_log("In Azione!: %s pesca 1 carta dal fondo degli scarti." % _nome(i))

# ---------------------------------------------------------------- Muovere
func _origini_movimento(i: int) -> Array:
	var out := []
	for id in s["mappa"]:
		if in_gioco(id) and navi(id, i) > 0 and not adj[id].is_empty():
			out.append(id)
	return out

## Destinazioni: adiacenti, o con la Fionda (da uno spazioporto Leale) attraverso i portali non controllati da Rivali.
func destinazioni(i: int, da: String) -> Array:
	var out: Array = adj[da].duplicate()
	var fionda := false
	for e in s["mappa"][da]["edifici"]:
		if e != null and e["t"] == "porto" and e["g"] == i:
			fionda = true
	if not fionda:
		return out
	var visti := {da: true}
	var coda := [da]
	while not coda.is_empty():
		var x: String = coda.pop_front()
		for y in adj[x]:
			if visti.has(y):
				continue
			visti[y] = true
			if not y in out:
				out.append(y)
			if Dati.is_portale(y):
				var c := controllo(y)
				if c < 0 or c == i:
					coda.append(y)
	return out

func _p_az_muovere(p: Dictionary) -> void:
	var i: int = p["g"]
	if _ha_r(p):
		var v = _r(p)
		if v is String and v == "annulla":
			return
		if not p.has("da"):
			pass
		if not p.has("orig"):
			p["orig"] = v
		elif not p.has("dest"):
			p["dest"] = v
		else:
			var f: int = v[0]
			var d: int = v[1]
			var o: String = p["orig"]
			var t: String = p["dest"]
			s["mappa"][o]["navi"][i][0] -= f
			s["mappa"][o]["navi"][i][1] -= d
			s["mappa"][t]["navi"][i][0] += f
			s["mappa"][t]["navi"][i][1] += d
			_log("%s muove %d nav%s da %s a %s." % [_nome(i), f + d, "e" if f + d == 1 else "i", _desc_sis(o), _desc_sis(t)])
			_ev({"tipo": "muovi", "g": i, "da": o, "a": t, "n": f + d})
			_dopo_movimento(i, t)
			if ha_lore(i, "l03") and f > 0 and not p.get("seconda", false):
				_spingi({"k": "sprinter", "g": i, "da": t, "max": f})
			return
	if not p.has("orig"):
		var ops := []
		for id in _origini_movimento(i):
			ops.append({"t": "Muovi da %s (%d navi)" % [_desc_sis(id), navi(id, i)], "v": id, "sis": id})
		_chiedi(p, i, "Da quale sistema muovi?", ops, "sistema")
		return
	if not p.has("dest"):
		var ops := []
		for id in destinazioni(i, p["orig"]):
			ops.append({"t": "Verso " + _desc_sis(id), "v": id, "sis": id})
		_chiedi(p, i, "Verso quale sistema?", ops, "sistema")
		return
	var f0: int = s["mappa"][p["orig"]]["navi"][i][0]
	var d0: int = s["mappa"][p["orig"]]["navi"][i][1]
	var mx := 99
	if leader(i) == "ribelle":
		mx = 2
	var ops := []
	for tot in range(mini(f0 + d0, mx), 0, -1):
		for f in range(mini(f0, tot), -1, -1):
			var d := tot - f
			if d > d0 or d < 0:
				continue
			var testo := "%d nav%s" % [tot, "e" if tot == 1 else "i"]
			if d0 > 0:
				testo += " (%d integr%s, %d danneggiat%s)" % [f, "a" if f == 1 else "e", d, "a" if d == 1 else "e"]
			ops.append({"t": testo, "v": [f, d]})
	_chiedi(p, i, "Quante navi muovi da %s a %s?" % [_desc_sis(p["orig"]), _desc_sis(p["dest"])], ops, "quante")

func _dopo_movimento(i: int, t: String) -> void:
	# Portali Attrezzati: chi entra in un portale controllato con spazioporto integro cede un agente
	if not Dati.is_portale(t):
		return
	var c := controllo(t)
	if c < 0 or c == i or not ha_lore(c, "l08"):
		return
	for e in s["mappa"][t]["edifici"]:
		if e != null and e["t"] == "porto" and e["g"] == c and not e["danno"] and G(i)["agenti"] > 0:
			G(i)["agenti"] -= 1
			G(c)["prigionieri"].append(i)
			_h_cattura(c, i)
			_log("Portali Attrezzati: %s cattura 1 agente di %s." % [_nome(c), _nome(i)])
			return

func _p_sprinter(p: Dictionary) -> void:
	var i: int = p["g"]
	if _ha_r(p):
		var v = _r(p)
		if _e(v, "no"):
			return
		if not p.has("dest"):
			p["dest"] = v
		else:
			var n: int = v
			var o: String = p["da"]
			var t: String = p["dest"]
			s["mappa"][o]["navi"][i][0] -= n
			s["mappa"][t]["navi"][i][0] += n
			_log("Propulsori a Curvatura: %s muove ancora %d navi verso %s." % [_nome(i), n, _desc_sis(t)])
			_ev({"tipo": "muovi", "g": i, "da": o, "a": t, "n": n})
			_dopo_movimento(i, t)
			return
	var disp: int = mini(p["max"], s["mappa"][p["da"]]["navi"][i][0])
	if disp <= 0:
		return
	if not p.has("dest"):
		var ops := [{"t": "Non muovere ancora", "v": "no"}]
		for id in adj[p["da"]]:
			ops.append({"t": "Ancora verso " + _desc_sis(id), "v": id, "sis": id})
		_chiedi(p, i, "Propulsori a Curvatura: muovi ancora le navi integre?", ops, "sistema")
		return
	var ops := []
	for n in range(disp, 0, -1):
		ops.append({"t": "%d nav%s" % [n, "e" if n == 1 else "i"], "v": n})
	_chiedi(p, i, "Quante navi integre muovi ancora?", ops, "quante")

# ---------------------------------------------------------------- Combattere
func _sistemi_battaglia(i: int) -> Array:
	var out := []
	for id in s["mappa"]:
		if not in_gioco(id) or navi(id, i) <= 0:
			continue
		if not _avversari(i, id).is_empty():
			out.append(id)
	return out

## Chi si può attaccare in un sistema (la campagna aggiunge Impero, Piaga e Stati Liberi).
func _avversari(i: int, id: String) -> Array:
	var out := []
	for j in s["n"]:
		if j != i and ha_pezzi(id, j):
			out.append(j)
	return out

func _p_az_combattere(p: Dictionary) -> void:
	var i: int = p["g"]
	if _ha_r(p):
		var v = _r(p)
		if not p.has("sis"):
			p["sis"] = v
		elif not p.has("dif"):
			p["dif"] = v
	if not p.has("sis"):
		var ops := []
		for id in _sistemi_battaglia(i):
			ops.append({"t": "Combatti in " + _desc_sis(id), "v": id, "sis": id})
		_chiedi(p, i, "Dove combatti?", ops, "sistema")
		return
	if not p.has("dif"):
		var ops := []
		for j in _avversari(i, p["sis"]):
			ops.append({"t": "Attacca " + _nome(j), "v": j, "giocatore": j})
		if ops.size() == 1:
			p["dif"] = ops[0]["v"]
		else:
			_chiedi(p, i, "Chi attacchi?", ops, "giocatore")
			return
	var bp := {"k": "battaglia", "g": i, "sis": p["sis"], "dif": p["dif"], "fase": "inizio", "modo": s["turno"]["modo"], "da": p.get("da", "")}
	_spingi(bp)

func _edifici_in(id: String, j: int) -> Array:
	var out := []
	var ed: Array = s["mappa"][id]["edifici"]
	for k in ed.size():
		if ed[k] != null and ed[k]["g"] == j:
			out.append(k)
	return out

func _p_battaglia(p: Dictionary) -> void:
	var i: int = p["g"]
	var j: int = p["dif"]
	var id: String = p["sis"]
	var r: Variant = _r(p) if _ha_r(p) else null
	match p["fase"]:
		"inizio":
			_ev({"tipo": "battaglia", "sis": id, "g": i, "dif": j})
			_log("%s combatte contro %s in %s." % [_nome(i), _nome(j), _desc_sis(id)])
			p["integre_inizio"] = s["mappa"][id]["navi"][i][1] == 0
			p["fase"] = "railgun"
			if leader(i) == "guerriero" and p["modo"] in ["copia", "cambia"] and p["da"] == "punto":
				p["fase"] = "tattico"
			_spingi(p)
		"tattico":
			p["fase"] = "railgun"
			if r == null:
				_spingi(p)
				_chiedi(p, i, "Tattico: vuoi Muovere prima di combattere?", [{"t": "No, combatti", "v": "no"}, {"t": "Muovi prima", "v": "si"}])
				s["pila"].pop_back()
				return
			_spingi(p)
			if _e(r, "si"):
				_spingi({"k": "az_muovere", "g": i})
		"railgun":
			p["fase"] = "dadi"
			_spingi(p)
			if ha_lore(j, "l12") and s["mappa"][id]["navi"][j][0] > 0 and navi(id, i) > 0:
				_log("Cannoni a Rotaia: %s subisce 1 colpo." % _nome(i))
				_spingi({"k": "colpi_navi", "g": i, "bersaglio": i, "sis": id, "n": 1, "chi_sceglie": i, "da": j})
		"dadi":
			var n := navi(id, i)
			if n <= 0:
				_log("%s non ha più navi per combattere." % _nome(i))
				return
			var extra := 0
			if leader(i) == "ribelle":
				extra += 2
			if ha_carta(i, "c08") and Dati.is_portale(id):
				extra += 2
			var tot := n + extra
			if not p.has("assalto"):
				if r != null:
					p["assalto"] = r
				else:
					var ops := []
					for k in range(mini(6, tot), -1, -1):
						ops.append({"t": "%d dad%s Assalto" % [k, "o" if k == 1 else "i"], "v": k, "dadi": ["assalto", k]})
					_spingi(p)
					_chiedi(p, i, "Hai %d dadi da scegliere: quanti dadi Assalto?" % tot, ops, "dadi")
					s["pila"].pop_back()
					return
			var rest: int = tot - int(p["assalto"])
			if not p.has("incursione"):
				if r != null:
					p["incursione"] = r
					r = null
				else:
					var ops := []
					for k in range(mini(6, rest), -1, -1):
						ops.append({"t": "%d dad%s Incursione" % [k, "o" if k == 1 else "i"], "v": k, "dadi": ["incursione", k]})
					_spingi(p)
					_chiedi(p, i, "Restano %d dadi: quanti dadi Incursione?" % rest, ops, "dadi")
					s["pila"].pop_back()
					return
			rest -= int(p["incursione"])
			if not p.has("razzia"):
				var razzia_ok := _razzia_permessa(id, j)
				if not razzia_ok or rest <= 0:
					p["razzia"] = 0
				elif r != null:
					p["razzia"] = r
				else:
					var ops := []
					for k in range(mini(6, rest), -1, -1):
						ops.append({"t": "%d dad%s Razzia" % [k, "o" if k == 1 else "i"], "v": k, "dadi": ["razzia", k]})
					_spingi(p)
					_chiedi(p, i, "Restano %d dadi: quanti dadi Razzia?" % rest, ops, "dadi")
					s["pila"].pop_back()
					return
			_tira(p)
			p["fase"] = "colpi_attaccante"
			_spingi(p)
		"colpi_attaccante":
			p["fase"] = "intercetta"
			_spingi(p)
			var auto: int = p["autocolpi"]
			if auto > 0:
				_spingi({"k": "colpi_navi", "g": i, "bersaglio": i, "sis": id, "n": auto, "chi_sceglie": i, "da": j})
		"intercetta":
			p["fase"] = "colpi_difensore"
			_spingi(p)
			if p["intercetta"] and navi(id, i) > 0:
				var f: int = s["mappa"][id]["navi"][j][0]
				if f > 0:
					_log("%s intercetta: %d colpi a %s." % [_nome(j), f, _nome(i)])
					_spingi({"k": "colpi_navi", "g": i, "bersaglio": i, "sis": id, "n": f, "chi_sceglie": i, "da": j})
		"colpi_difensore":
			p["fase"] = "colpi_edifici"
			_spingi(p)
			if p["colpi"] > 0:
				_spingi({"k": "colpi_misti", "g": i, "bersaglio": j, "sis": id, "n": p["colpi"], "edifici_dopo": true})
		"colpi_edifici":
			p["fase"] = "razzia_fase"
			_spingi(p)
			if p["colpi_edifici"] > 0:
				_spingi({"k": "colpi_misti", "g": i, "bersaglio": j, "sis": id, "n": p["colpi_edifici"], "solo_edifici": true})
		"razzia_fase":
			p["fase"] = "dopo"
			_spingi(p)
			if p["chiavi"] > 0 and navi(id, i) > 0:
				_spingi({"k": "razzia", "g": i, "dif": j, "chiavi": p["chiavi"]})
		"dopo":
			if ha_lore(i, "l07"):
				if s["mappa"][id]["navi"][i][1] > 0:
					s["mappa"][id]["navi"][i][1] -= 1
					s["mappa"][id]["navi"][i][0] += 1
					_log("Droni Riparatori: %s ripara una nave." % _nome(i))
			if leader(j) == "antico" and p.get("trofei_presi", false) and G(j)["agenti"] > 0:
				_spingi({"k": "az_influenzare", "g": j})
			if leader(i) == "guerriero" and p["modo"] in ["copia", "cambia"] and p["da"] == "punto" and not p.get("mosso", false):
				_spingi({"k": "tattico_dopo", "g": i})

func _p_tattico_dopo(p: Dictionary) -> void:
	var i: int = p["g"]
	if _ha_r(p):
		if _e(_r(p), "si"):
			_spingi({"k": "az_muovere", "g": i})
		return
	if _origini_movimento(i).is_empty():
		return
	_chiedi(p, i, "Tattico: vuoi Muovere dopo la battaglia?", [{"t": "No", "v": "no"}, {"t": "Muovi", "v": "si"}])

func _razzia_permessa(id: String, j: int) -> bool:
	if j >= s["n"]:
		return false
	if ha_lore(j, "l05"):
		for e in s["mappa"][id]["edifici"]:
			if e != null and e["g"] == j and e["t"] == "porto" and not e["danno"]:
				return false
	if not _edifici_in(id, j).is_empty():
		return true
	return edifici_di(j).is_empty()

const FACCE_ASSALTO := [[2, 1, 0], [0, 0, 0], [2, 0, 0], [1, 1, 0], [1, 0, 1], [1, 1, 0]]  # colpi, autocolpi, intercetta
const FACCE_RAZZIA := [[1, 1, 0, 0], [0, 0, 1, 2], [1, 0, 0, 1], [0, 1, 0, 1], [0, 0, 1, 0], [1, 1, 0, 0]]  # edifici, auto, intercetta, chiavi

func _tira(p: Dictionary) -> void:
	var i: int = p["g"]
	var j: int = p["dif"]
	var id: String = p["sis"]
	var na: int = p["assalto"]
	var ni: int = p["incursione"]
	var nr: int = p["razzia"]
	var fa := []
	var fi := []
	var fr := []
	for k in na:
		fa.append(_dado(6))
	for k in ni:
		fi.append(_dado(6))
	for k in nr:
		fr.append(_dado(6))
	# Incursori: ritira i dadi Incursione a vuoto fino ai simboli Armi
	if ha_carta(i, "c13"):
		var lim := armi_totali(i)
		for k in fi.size():
			if lim <= 0:
				break
			if fi[k] % 2 == 1:
				fi[k] = _dado(6)
				lim -= 1
	# Siluri Traccianti: ritira i dadi Assalto peggiori (1 per nave integra)
	if ha_lore(i, "l14"):
		var lim: int = s["mappa"][id]["navi"][i][0]
		for k in fa.size():
			if lim <= 0:
				break
			var f: Array = FACCE_ASSALTO[fa[k]]
			if f[0] - f[1] <= 0:
				fa[k] = _dado(6)
				lim -= 1
	var colpi := 0
	var auto := 0
	var inter := false
	var ced := 0
	var chiavi := 0
	for x in fa:
		colpi += FACCE_ASSALTO[x][0]
		auto += FACCE_ASSALTO[x][1]
		if FACCE_ASSALTO[x][2] > 0:
			inter = true
	for x in fi:
		if x % 2 == 0:
			colpi += 1
	for x in fr:
		ced += FACCE_RAZZIA[x][0]
		auto += FACCE_RAZZIA[x][1]
		if FACCE_RAZZIA[x][2] > 0:
			inter = true
		chiavi += FACCE_RAZZIA[x][3]
	if ha_lore(j, "l04") and na > 0:
		auto += 1
	if ha_lore(i, "l06") and p.get("integre_inizio", false) and auto > 0:
		auto -= 1
	p["colpi"] = colpi
	p["autocolpi"] = auto
	p["intercetta"] = inter
	p["colpi_edifici"] = ced
	p["chiavi"] = chiavi
	p["facce"] = {"assalto": fa, "incursione": fi, "razzia": fr}
	_log("Dadi: %d colpi, %d colpi agli edifici, %d chiavi, %d colpi subiti%s." % [colpi, ced, chiavi, auto, ", intercettazione" if inter else ""])
	_ev({"tipo": "dadi", "g": i, "sis": id, "facce": p["facce"], "colpi": colpi, "auto": auto, "inter": inter, "ced": ced, "chiavi": chiavi})

## Colpi alle navi di un giocatore (chi_sceglie decide se distribuire o concentrare).
func _p_colpi_navi(p: Dictionary) -> void:
	var b: int = p["bersaglio"]
	var id: String = p["sis"]
	var n: int = p["n"]
	var navi_b: Array = s["mappa"][id]["navi"][b]
	if navi_b[0] + navi_b[1] <= 0 or n <= 0:
		return
	var strategia = _r(p) if _ha_r(p) else null
	if strategia == null:
		# se il risultato non cambia non serve chiedere
		if navi_b[1] == 0 and n <= navi_b[0]:
			strategia = "distribuisci"
		elif navi_b[0] == 0:
			strategia = "concentra"
		else:
			_chiedi(p, p["chi_sceglie"], "%d colp%s alle navi di %s in %s: come li assegni?" % [n, "o" if n == 1 else "i", _nome(b), _desc_sis(id)], [
				{"t": "Danneggia prima le navi integre", "v": "distribuisci"},
				{"t": "Distruggi prima le navi danneggiate", "v": "concentra"}], "colpi")
			return
	_assegna_colpi_navi(b, id, n, strategia, p.get("da", -1))

func _assegna_colpi_navi(b: int, id: String, n: int, strategia: String, autore: int) -> int:
	var navi_b: Array = s["mappa"][id]["navi"][b]
	var distrutte := 0
	for k in n:
		if navi_b[0] + navi_b[1] <= 0:
			return k
		if strategia == "distribuisci":
			if navi_b[0] > 0:
				navi_b[0] -= 1
				navi_b[1] += 1
			else:
				navi_b[1] -= 1
				distrutte += 1
				_distrutto(b, autore, "nave", id)
		else:
			if navi_b[1] > 0:
				navi_b[1] -= 1
				distrutte += 1
				_distrutto(b, autore, "nave", id)
			else:
				navi_b[0] -= 1
				navi_b[1] += 1
	return n

## Un pezzo di b distrutto da autore: va nei Trofei di autore.
func _distrutto(b: int, autore: int, cosa: String, id: String) -> void:
	_ev({"tipo": "distruggi", "sis": id, "g": b, "cosa": cosa})
	if autore >= 0 and autore != b:
		G(autore)["trofei"].append({"t": cosa, "g": b})
		_h_trofeo(autore, b, cosa, id)
		if s["pila"].size() > 0:
			for q in range(s["pila"].size() - 1, -1, -1):
				if s["pila"][q]["k"] == "battaglia":
					if int(s["pila"][q]["g"]) == autore:
						s["pila"][q]["trofei_presi"] = true
					break
	else:
		match cosa:
			"nave": G(b)["navi"] += 1
			"porto": G(b)["porti"] += 1
			"citta": _restituisci_citta(b)

## Colpi al difensore: prima le navi, poi gli edifici (oppure solo edifici).
func _p_colpi_misti(p: Dictionary) -> void:
	var i: int = p["g"]
	var b: int = p["bersaglio"]
	var id: String = p["sis"]
	var n: int = p["n"]
	if n <= 0:
		return
	var navi_b: Array = s["mappa"][id]["navi"][b]
	if not p.get("solo_edifici", false) and navi_b[0] + navi_b[1] > 0:
		var strategia = _r(p) if _ha_r(p) else null
		if strategia == null:
			var bisogno: int = navi_b[1] * 1 + navi_b[0] * 2
			if navi_b[1] == 0 and n <= navi_b[0] or n >= bisogno or navi_b[0] == 0:
				strategia = "concentra" if n >= bisogno or navi_b[0] == 0 else "distribuisci"
			else:
				_chiedi(p, i, "%d colp%s alle navi di %s: come li assegni?" % [n, "o" if n == 1 else "i", _nome(b)], [
					{"t": "Distruggi prima le navi danneggiate", "v": "concentra"},
					{"t": "Danneggia prima le navi integre", "v": "distribuisci"}], "colpi")
				return
		var usati := 0
		while usati < n and navi_b[0] + navi_b[1] > 0:
			_assegna_colpi_navi(b, id, 1, strategia, i)
			usati += 1
		n -= usati
		if n <= 0:
			return
		p["n"] = n
	# edifici
	var eds := _edifici_in(id, b)
	if eds.is_empty():
		return
	var scelta = _r(p) if _ha_r(p) else null
	if scelta == null:
		if eds.size() == 1:
			scelta = eds[0]
		else:
			var ops := []
			for k in eds:
				var e: Dictionary = s["mappa"][id]["edifici"][k]
				ops.append({"t": "Colpisci %s%s" % ["la città" if e["t"] == "citta" else "lo spazioporto", " (danneggiat%s)" % ("a" if e["t"] == "citta" else "o") if e["danno"] else ""], "v": k})
			_chiedi(p, i, "Quale edificio di %s colpisci?" % _nome(b), ops, "edificio")
			return
	var k: int = scelta
	var e: Dictionary = s["mappa"][id]["edifici"][k]
	if not e["danno"]:
		e["danno"] = true
		_log("%s danneggia %s di %s." % [_nome(i), "una città" if e["t"] == "citta" else "uno spazioporto", _nome(b)])
	else:
		s["mappa"][id]["edifici"][k] = null
		if e.get("volante", false) or k >= (Dati.SPAZI.get(id, 0)):
			pass
		_log("%s distrugge %s di %s!" % [_nome(i), "una città" if e["t"] == "citta" else "uno spazioporto", _nome(b)])
		_distrutto(b, i, e["t"], id)
		if e["t"] == "citta":
			for t in _tipi_citta_distrutta(id):
				_oltraggio(b, t)
			if leader(b) != "antico" and b < s["n"]:
				_spingi({"k": "soggioga", "g": i, "dif": b})
	p["n"] = n - 1
	if p["n"] > 0:
		_spingi(p)

func _tipi_citta_distrutta(id: String) -> Array:
	if not Dati.is_portale(id):
		return [Dati.TIPO[id]]
	return _tipi_citta(id)

func _p_soggioga(p: Dictionary) -> void:
	var i: int = p["g"]
	var b: int = p["dif"]
	if _ha_r(p):
		var k = _r(p)
		if k is int:
			_log("%s Soggioga la Corte." % _nome(i))
			_acquisisci(i, k, true)
		return
	var ops := []
	for k in s["corte"].size():
		if s["corte"][k]["ag"][b] > 0:
			ops.append({"t": "Prendi " + Dati.nome_corte(s["corte"][k]["c"]), "v": k, "corte": k})
	if ops.is_empty():
		return
	_chiedi(p, i, "Soggiogare la Corte: prendi una carta con agenti di %s" % _nome(b), ops, "corte")

func _p_razzia(p: Dictionary) -> void:
	var i: int = p["g"]
	var j: int = p["dif"]
	if _ha_r(p):
		var v = _r(p)
		if _e(v, "basta"):
			return
		var cosa: Array = v
		if cosa[0] == "risorsa":
			var slot: int = cosa[1]
			var t: String
			if slot == 99:
				t = G(j)["antichi"]
				G(j)["antichi"] = ""
				p["chiavi"] -= 3
			else:
				t = G(j)["risorse"][slot]
				G(j)["risorse"][slot] = ""
				p["chiavi"] -= Dati.COSTO_SPAZIO[slot]
			_log("%s razzia 1 %s a %s." % [_nome(i), Dati.NOME_RISORSA[t], _nome(j)])
			_ev({"tipo": "razzia", "g": i, "da": j})
			_spingi(p)
			_ottieni_diretto(i, t)
			return
		var c: String = cosa[1]
		p["chiavi"] -= Dati.info(c)[3]
		G(j)["carte"].erase(c)
		if c == "c22":
			s["mazzo_corte"].append(c)
			_log("%s razzia i Guardiani Giurati a %s: vengono sepolti." % [_nome(i), _nome(j)])
			p["sbloccato"] = true
		else:
			G(i)["carte"].append(c)
			_log("%s razzia %s a %s." % [_nome(i), Dati.nome_corte(c), _nome(j)])
		_ev({"tipo": "razzia", "g": i, "da": j})
	var k: int = p["chiavi"]
	if k <= 0:
		return
	var protetto: bool = ha_carta(j, "c22") and not p.get("sbloccato", false)
	var ops := [{"t": "Basta così", "v": "basta"}]
	if not protetto:
		for slot in 6:
			var t: String = G(j)["risorse"][slot]
			if t != "" and Dati.COSTO_SPAZIO[slot] <= k:
				ops.append({"t": "Ruba %s (costo %d)" % [Dati.NOME_RISORSA[t], Dati.COSTO_SPAZIO[slot]], "v": ["risorsa", slot], "risorsa": t})
		if G(j)["antichi"] != "" and k >= 3:
			ops.append({"t": "Ruba %s da Antichi Possedimenti (costo 3)" % Dati.NOME_RISORSA[G(j)["antichi"]], "v": ["risorsa", 99]})
	for c in G(j)["carte"]:
		if Dati.info(c)[1] == "gilda" and Dati.info(c)[3] >= 0 and Dati.info(c)[3] <= k and (not protetto or c == "c22"):
			ops.append({"t": "Ruba %s (costo %d)" % [Dati.nome_corte(c), Dati.info(c)[3]], "v": ["carta", c], "carta": c})
	if ops.size() == 1:
		return
	_chiedi(p, i, "Razzia: hai %d chiav%s da spendere su %s" % [k, "e" if k == 1 else "i", _nome(j)], ops, "razzia")

# ---------------------------------------------------------------- azioni Combattere speciali
func _bersagli_rapire(i: int) -> Array:
	var out := []
	var a := armi_totali(i)
	for k in s["corte"].size():
		var riv := 0
		for j in s["n"]:
			if j != i:
				riv += s["corte"][k]["ag"][j]
		if riv > 0 and riv < a:
			out.append(k)
	return out

func _p_az_rapire(p: Dictionary) -> void:
	var i: int = p["g"]
	if _ha_r(p):
		var k: int = _r(p)
		for j in s["n"]:
			if j != i:
				for z in s["corte"][k]["ag"][j]:
					G(i)["prigionieri"].append(j)
					_h_cattura(i, j)
				s["corte"][k]["ag"][j] = 0
		_log("%s rapisce gli agenti Rivali da %s." % [_nome(i), Dati.nome_corte(s["corte"][k]["c"])])
		return
	var ops := []
	for k in _bersagli_rapire(i):
		ops.append({"t": "Rapisci da " + Dati.nome_corte(s["corte"][k]["c"]), "v": k, "corte": k})
	_chiedi(p, i, "Rapire: da quale carta della Corte catturi gli agenti?", ops, "corte")

func _bersagli_sparare(i: int) -> Array:
	var out := []
	for id in s["mappa"]:
		if not in_gioco(id) or s["mappa"][id]["navi"][i][0] <= 0:
			continue
		for y in adj[id]:
			for j in s["n"]:
				if j != i and ha_pezzi(y, j):
					out.append([id, y, j])
	return out

func _p_az_sparare(p: Dictionary) -> void:
	var i: int = p["g"]
	if _ha_r(p):
		var v: Array = _r(p)
		var n: int = s["mappa"][v[0]]["navi"][i][0]
		var colpi := 0
		for k in n:
			if _dado(6) % 2 == 0:
				colpi += 1
		_log("%s spara da %s su %s di %s: %d colpi." % [_nome(i), _desc_sis(v[0]), _desc_sis(v[1]), _nome(v[2]), colpi])
		_ev({"tipo": "battaglia", "sis": v[1], "g": i, "dif": v[2]})
		if colpi > 0:
			_spingi({"k": "colpi_misti", "g": i, "bersaglio": v[2], "sis": v[1], "n": colpi})
		return
	var ops := []
	for x in _bersagli_sparare(i):
		ops.append({"t": "Da %s su %s (%s)" % [_desc_sis(x[0]), _desc_sis(x[1]), _nome(x[2])], "v": x, "sis": x[1]})
	_chiedi(p, i, "Cannoni Galattici: da dove spari e su chi?", ops, "sistema")

# ================================================================ fine round e capitolo
func _p_fine_round(_p: Dictionary) -> void:
	var finito: bool = s.get("round_finito", false)
	s["round_finito"] = false
	if not finito:
		if s["sottratta"] >= 0:
			s["iniz"] = s["sottratta"]
		else:
			var best := -1
			var bv := -1
			var gs := Dati.seme(s["guida"]["c"]) if not s["guida"].is_empty() else ""
			for gg in s["giocate"]:
				if gg["modo"] == "supera" and Dati.valore(gg["c"]) > bv:
					bv = Dati.valore(gg["c"])
					best = gg["g"]
			if best >= 0:
				s["iniz"] = best
		_log("Fine del round: l'iniziativa è di %s." % _nome(s["iniz"]))
		if s["iniz"] != int(s.get("iniz_prima", -1)):
			_h_iniziativa(s["iniz"])
	# Leghe: la carta giocata torna in mano a chi ha usato la Lega
	var riprese := []
	for l in s["leghe"]:
		riprese.append(l["carta"])
		G(l["g"])["mano"].append(l["carta"])
		s["scarti_corte"].append(l["c"])
		_log("%s riprende in mano %s." % [_nome(l["g"]), Dati.nome_carta_azione(l["carta"])])
	for gg in s["giocate"]:
		if not gg["c"] in riprese:
			s["scarti_azioni"].append(gg["c"])
	s["giocate"] = []
	s["leghe"] = []
	s["guida"] = {}
	_ev({"tipo": "fine_round"})
	_spingi({"k": "round"})
	_dopo_round()

func punteggio_ambizione(i: int, amb: String) -> int:
	match amb:
		"magnate":
			var n := simboli(i, "materiale") + simboli(i, "carburante")
			if ha_carta(i, "c03"):
				n += riserva("materiale")
			if ha_carta(i, "c06"):
				n += riserva("carburante")
			return n
		"tiranno": return G(i)["prigionieri"].size()
		"generale": return G(i)["trofei"].size()
		"custode": return simboli(i, "reliquie")
		"empate": return simboli(i, "psico")
	return 0

func _p_fine_capitolo(_p: Dictionary) -> void:
	var n: int = s["n"]
	_log("— Fine del capitolo %d: calcolo del Potere —" % s["capitolo"])
	var calcolate := {}
	for amb in Dati.AMBIZIONI:
		var p1 := 0
		var p2 := 0
		var ha := false
		for k in 3:
			if s["segnalini"][k]["amb"] == amb:
				ha = true
				var vs := valore_segnalino(k)
				p1 += vs[0]
				p2 += vs[1]
		if not ha:
			continue
		var punti := []
		for i in n:
			punti.append(punteggio_ambizione(i, amb))
		var virt: int = s["virtuale"].get(amb, 0)
		var guadagni := _classifica(punti, virt, p1, p2, amb)
		calcolate[amb] = guadagni
		_h_ambizione(amb, punti, virt, guadagni)
		for i in n:
			if guadagni[i] > 0:
				G(i)["potere"] += guadagni[i]
				_log("%s ottiene %d Potere da %s." % [_nome(i), guadagni[i], Dati.NOME_AMBIZIONE[amb]])
	_ev({"tipo": "punteggio", "risultati": calcolate})
	_h_dopo_punteggio(calcolate)
	# restituire Trofei e Prigionieri
	if calcolate.has("generale"):
		for i in n:
			if calcolate["generale"][i] > 0:
				for t in G(i)["trofei"]:
					_restituisci_pezzo(t)
				G(i)["trofei"] = []
	if calcolate.has("tiranno"):
		for i in n:
			if calcolate["tiranno"][i] > 0:
				for j in G(i)["prigionieri"]:
					G(j)["agenti"] += 1
				G(i)["prigionieri"] = []
	# Cartelli e Divoratore
	for i in n:
		if ha_carta(i, "c03"):
			for j in n:
				if j != i:
					while _togli_risorsa(j, "materiale"):
						pass
		if ha_carta(i, "c06"):
			for j in n:
				if j != i:
					while _togli_risorsa(j, "carburante"):
						pass
		if leader(i) == "divoratore" and calcolate.has("magnate"):
			while _togli_risorsa(i, "carburante"):
				pass
	_h_fine_capitolo()
	for k in 3:
		s["segnalini"][k]["amb"] = ""
	for k in [2, 1, 0]:
		if not s["segnalini"][k]["girato"]:
			s["segnalini"][k]["girato"] = true
			break
	_controlla_fine()

## Fine della partita (gioco base: 5 capitoli o soglia di Potere). La campagna la ridefinisce.
func _controlla_fine() -> void:
	var n: int = s["n"]
	var soglia: int = SOGLIA[n]
	var finita: bool = s["capitolo"] >= 5
	for i in n:
		if G(i)["potere"] >= soglia:
			finita = true
	if finita:
		var best := -1
		for i in ordine_da(s["iniz"]):
			if best < 0 or G(i)["potere"] > G(best)["potere"]:
				best = i
		s["vincitore"] = best
		s["fine"] = true
		s["attesa"] = {}
		_log("La partita è finita: vince %s con %d Potere!" % [_nome(best), G(best)["potere"]])
		_ev({"tipo": "fine", "g": best})
		return
	s["capitolo"] += 1
	_spingi({"k": "capitolo"})

func _restituisci_pezzo(t: Dictionary) -> void:
	var j: int = t["g"]
	match t["t"]:
		"nave": G(j)["navi"] += 1
		"porto": G(j)["porti"] += 1
		"agente": G(j)["agenti"] += 1
		"citta": _restituisci_citta(j)

## Potere per un'ambizione: primo (unico) p1, pari al primo p2 ciascuno, secondo (unico) p2.
func _classifica(punti: Array, virt: int, p1: int, p2: int, amb: String) -> Array:
	var n: int = punti.size()
	var out := []
	for i in n:
		out.append(0)
	var tutti := punti.duplicate()
	tutti.append(virt)
	var mx := 0
	for v in tutti:
		mx = maxi(mx, v)
	if mx <= 0:
		return out
	var primi := []
	for k in tutti.size():
		if tutti[k] == mx:
			primi.append(k)
	var speciale := ""
	if amb == "tiranno":
		speciale = "antico"
	elif amb == "empate":
		speciale = "guerriero"
	if primi.size() == 1:
		var w: int = primi[0]
		if w < n:
			if leader(w) == speciale and speciale != "":
				out[w] = p2
			else:
				out[w] = p1 + bonus_citta(w)
		# secondo posto
		var mx2 := 0
		for k in tutti.size():
			if k != w:
				mx2 = maxi(mx2, tutti[k])
		if mx2 > 0:
			var secondi := []
			for k in tutti.size():
				if k != w and tutti[k] == mx2:
					secondi.append(k)
			if secondi.size() == 1 and secondi[0] < n:
				var q: int = secondi[0]
				if not (leader(q) == speciale and speciale != ""):
					out[q] = p2
	else:
		for k in primi:
			if k < n and not (leader(k) == speciale and speciale != ""):
				out[k] = p2
	return out

# ================================================================ informazioni per l'interfaccia
func classifica_ambizione(amb: String) -> Array:
	var out := []
	for i in s["n"]:
		out.append(punteggio_ambizione(i, amb))
	return out

func potere_previsto() -> Array:
	var tot := []
	for i in s["n"]:
		tot.append(0)
	for amb in Dati.AMBIZIONI:
		var p1 := 0
		var p2 := 0
		var ha := false
		for k in 3:
			if s["segnalini"][k]["amb"] == amb:
				ha = true
				var vs := valore_segnalino(k)
				p1 += vs[0]
				p2 += vs[1]
		if ha:
			var g := _classifica(classifica_ambizione(amb), s["virtuale"].get(amb, 0), p1, p2, amb)
			for i in s["n"]:
				tot[i] += g[i]
	return tot
