## Motore della campagna «L'Orlo Infestato» (Atto I, prima tappa).
## Estende il motore del gioco base: Impero, Piaga, Stati Liberi, carte Evento, Consiglio Imperiale,
## Crisi, Editti, Tesoro Imperiale e fine dell'Atto dopo 3 capitoli.
## L'Impero, la Piaga e gli Stati Liberi sono «giocatori fittizi» con indice n, n+1 e n+2:
## hanno navi ed edifici sulla mappa ma non giocano turni.
class_name MotoreCampagna
extends Motore

const CORTE_CC := ["c02", "c05", "c08", "c09", "c13", "c11", "c16", "c20", "c22", "c23", "c27", "x11", "x12"]
## Facce del dado evento: tipo di evento e simbolo del pianeta (a, b, c)
const FACCE_EVENTO := [["crisi", "a"], ["crisi", "b"], ["crisi", "c"], ["editto", "a"], ["editto", "b"], ["editto", "c"]]
const NOME_SIMBOLO := {"a": "triangolo", "b": "esagono", "c": "luna"}
const POLITICHE := ["pace", "escalation", "guerra"]
const NOME_POLITICA := {"pace": "Pace", "escalation": "Escalation", "guerra": "Guerra"}
const TRIBUTO := {"pace": ["reliquie", "psico"], "escalation": ["materiale", "carburante", "armi"], "guerra": []}

func imp() -> int:
	return s["n"]

func piaga() -> int:
	return s["n"] + 1

func lib() -> int:
	return s["n"] + 2

func C() -> Dictionary:
	return s["camp"]

func reggente(i: int) -> bool:
	return i >= 0 and i < s["n"] and C()["titolo"][i] == "reggente"

func primo() -> int:
	return int(C()["primo"])

func _nome(i: int) -> String:
	if i == imp():
		return "l'Impero"
	if i == piaga():
		return "la Piaga"
	if i == lib():
		return "gli Stati Liberi"
	return super(i)

# ================================================================ preparazione dell'Atto I
func nuova_partita(cfg: Dictionary) -> void:
	if not cfg.get("campagna", false):
		super(cfg)
		return
	var n: int = int(cfg.get("n", 4))
	s = {"n": n, "rng": int(cfg.get("seme", 12345)) & 0xFFFFFFFF, "log": [], "eventi": [], "pila": [], "attesa": {},
		"capitolo": 1, "fine": false, "vincitore": -1, "leader": false, "decisioni": 0,
		"facile": bool(cfg.get("facile", false))}
	if s["rng"] == 0:
		s["rng"] = 99991
	for k in 5:
		_rnd()
	var g := []
	for i in n:
		g.append(_giocatore(str(cfg["nomi"][i]) if cfg.has("nomi") else "Giocatore %d" % (i + 1), Dati.COLORI[i],
			bool(cfg["ia"][i]) if cfg.has("ia") else i > 0))
	g.append(_giocatore("Impero", "impero", false))
	g.append(_giocatore("Piaga", "piaga", false))
	g.append(_giocatore("Stati Liberi", "liberi", false))
	g[n]["navi"] = 60
	g[n + 1]["navi"] = 24
	g[n + 2]["porti"] = 14
	s["g"] = g
	s["prep"] = -1
	s["fuori"] = []
	_calcola_adiacenze()
	s["mappa"] = {}
	for id in Dati.sistemi():
		var sl := []
		if not Dati.is_portale(id):
			for k in Dati.SPAZI[id]:
				sl.append(null)
		s["mappa"][id] = {"navi": _zeri(n + 3), "edifici": sl}
	s["iniz"] = _dado(n)
	s["sottratta"] = -1
	s["segnalini"] = [{"amb": "", "girato": false}, {"amb": "", "girato": false}, {"amb": "", "girato": false}]
	s["virtuale"] = {}
	s["fuori_risorse"] = {}
	var politiche: Array = POLITICHE.duplicate()
	_mescola(politiche)
	s["camp"] = {"atto": 1, "titolo": [], "primo": -1, "tesoro": [], "consiglio": "sessione", "consiglio_preso": -1,
		"evento": -1, "evento_vuoto": false, "politica": politiche[0], "editti": ["03"] + (["00"] if n == 2 else []),
		"favori": [], "citta_libere": 28, "imperiali": [], "dado_evento": [], "dado_numero": 0}
	for i in n:
		C()["titolo"].append("reggente")
		C()["favori"].append({})
	# settori imperiali
	var sett := _dado(6) + 1
	var imperiali := [sett, sett % 6 + 1]
	C()["imperiali"] = imperiali
	for id in Dati.sistemi():
		if Dati.settore(id) in imperiali:
			s["mappa"][id]["navi"][imp()][0] = 1
			G(imp())["navi"] -= 1
	var fe: Array = FACCE_EVENTO[_dado(6)]
	for id in Dati.sistemi():
		if Dati.settore(id) in imperiali:
			continue
		if not Dati.is_portale(id) and id.ends_with(fe[1]):
			_metti_libera(id, "citta")
		s["mappa"][id]["navi"][piaga()][1] = 1
		G(piaga())["navi"] -= 1
	if n == 2:
		for id in Dati.sistemi():
			if Dati.settore(id) in imperiali and not Dati.is_portale(id):
				var t: String = Dati.TIPO[id]
				var amb: String = {"materiale": "magnate", "carburante": "magnate", "armi": "generale", "reliquie": "custode", "psico": "empate"}[t]
				s["virtuale"][amb] = int(s["virtuale"].get(amb, 0)) + 1
				s["fuori_risorse"][t] = int(s["fuori_risorse"].get(t, 0)) + 1
	# Corte: Consiglio Imperiale a sinistra, poi le carte della campagna
	var corte: Array = CORTE_CC.duplicate()
	_mescola(corte)
	s["mazzo_corte"] = corte
	s["scarti_corte"] = []
	s["corte"] = [{"c": "consiglio", "ag": _zeri_int(n)}]
	for k in (3 if n == 2 else 4):
		_rifornisci_corte()
	s["azioni"] = []
	s["scarti_azioni"] = []
	s["giocate"] = []
	s["leghe"] = []
	s["passi"] = 0
	C()["primo"] = s["iniz"]
	_log("Campagna, Atto I: settori imperiali %d e %d. Politica imperiale: %s. Primo Reggente: %s." % [
		imperiali[0], imperiali[1], NOME_POLITICA[C()["politica"]], _nome(s["iniz"])])
	_spingi({"k": "capitolo"})
	_spingi({"k": "piazza_campagna", "giro": 0, "fatti": 0})
	_avanza()

func _giocatore(nome: String, colore: String, ia_: bool) -> Dictionary:
	return {"nome": nome, "colore": colore, "ia": ia_, "potere": 0, "risorse": ["", "", "", "", "", ""],
		"citta_plancia": [true, true, true, true, true], "navi": 15, "porti": 5, "agenti": 10, "trofei": [],
		"prigionieri": [], "oltraggio": [], "carte": [], "lore": [], "leader": "", "mano": [], "antichi": ""}

func _metti_libera(id: String, t: String) -> bool:
	var k := _slot_libero(id)
	if k < 0:
		return false
	if t == "citta":
		if int(C()["citta_libere"]) <= 0:
			return false
		C()["citta_libere"] = int(C()["citta_libere"]) - 1
	else:
		if G(lib())["porti"] <= 0:
			return false
		G(lib())["porti"] -= 1
	s["mappa"][id]["edifici"][k] = {"t": t, "g": lib(), "danno": false}
	return true

func _restituisci_citta(i: int) -> void:
	if s.has("camp") and i == lib():
		C()["citta_libere"] = int(C()["citta_libere"]) + 1
		return
	super(i)

## Piazzamento iniziale: in ordine di turno e poi a ritroso, 3 navi + 1 edificio su un pianeta con nave imperiale.
func _p_piazza_campagna(p: Dictionary) -> void:
	var n: int = s["n"]
	var ordine := ordine_da(s["iniz"])
	var tot: int = n * 2
	var k: int = p["fatti"]
	if k >= tot:
		# città Libere negli spazi vuoti dei pianeti imperiali
		for id in s["mappa"]:
			if s["mappa"][id]["navi"][imp()][0] > 0 and not Dati.is_portale(id):
				while _metti_libera(id, "citta"):
					pass
		return
	var i: int = ordine[k] if k < n else ordine[tot - 1 - k]
	if _ha_r(p):
		var v: Array = _r(p)
		var id: String = v[0]
		_metti_navi(i, id, 3, false)
		if v[1] == "citta":
			_metti_citta(i, id, false)
		else:
			_metti_porto(i, id, false)
		_ottieni(i, Dati.TIPO[id])
		_log("%s si stabilisce in %s." % [_nome(i), _desc_sis(id)])
		p["fatti"] = k + 1
		p.erase("r")
		_spingi(p)
		return
	var ops := []
	for id in s["mappa"]:
		if Dati.is_portale(id) or s["mappa"][id]["navi"][imp()][0] <= 0 or _slot_libero(id) < 0:
			continue
		if G(i)["citta_plancia"].count(true) > 0:
			ops.append({"t": "%s: 3 navi e una città" % _desc_sis(id), "v": [id, "citta"], "sis": id})
		if G(i)["porti"] > 0:
			ops.append({"t": "%s: 3 navi e uno spazioporto" % _desc_sis(id), "v": [id, "porto"], "sis": id})
	if ops.is_empty():
		p["fatti"] = k + 1
		_spingi(p)
		return
	_spingi(p)
	_chiedi(p, i, "Preparazione: scegli un pianeta con una nave imperiale", ops, "sistema")
	s["pila"].pop_back()

# ================================================================ controllo
## L'Impero controlla ogni sistema con una nave imperiale integra. Nel turno di un Reggente con pezzi Leali
## nel sistema (Legge della Presenza), il controllo è suo.
func controllo(id: String) -> int:
	if not s.has("camp"):
		return super(id)
	if s["mappa"][id]["navi"][imp()][0] > 0:
		var t: int = int(s["turno"]["g"]) if s.has("turno") and not s["turno"].is_empty() else -1
		if reggente(t) and ha_pezzi(id, t):
			return t
		return imp()
	var best := -1
	var bv := 0
	var pari := false
	var navi_: Array = s["mappa"][id]["navi"]
	for i in s["n"]:
		var f: int = navi_[i][0]
		if f > bv:
			bv = f
			best = i
			pari = false
		elif f == bv and f > 0:
			pari = true
	return -1 if pari or bv == 0 else best

## Controllo per ambizioni, obiettivi ed eventi: il Primo Reggente controlla i sistemi dell'Impero.
func controllo_eventi(id: String) -> int:
	var c := controllo(id)
	if c == imp():
		return primo()
	return c

func destinazioni(i: int, da: String) -> Array:
	if not s.has("camp"):
		return super(i, da)
	var out: Array = adj[da].duplicate()
	var fionda := false
	for e in s["mappa"][da]["edifici"]:
		if e != null and e["t"] == "porto" and (e["g"] == i or (e["g"] == lib() and controllo(da) == i)):
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
			if Dati.is_portale(y) and not _ferma_fionda(i, y):
				coda.append(y)
	return out

## La Fionda si ferma sulla Piaga e sui portali controllati da chi la blocca.
func _ferma_fionda(i: int, y: String) -> bool:
	var pg: Array = s["mappa"][y]["navi"][piaga()]
	if pg[0] + pg[1] > 0:
		return true
	var c := controllo(y)
	if c < 0 or c == i:
		return false
	if c == imp():
		return not reggente(i)
	if reggente(c):
		return not reggente(i) or true
	return true

# ================================================================ carte Evento
func _mazzo_azioni() -> Array:
	var m: Array = Dati.carte_azione(s["n"])
	if s.has("camp"):
		for k in (3 if s["n"] == 4 else 2):
			m.append("evt%d" % (k + 1))
	return m

func _opzioni_evento(i: int) -> Array:
	var ops := []
	for c in G(i)["mano"]:
		if Dati.is_evento(c):
			ops.append({"t": "Gioca un Evento (azioni come la Guida)", "v": [c, "evento"], "mano": c, "modo": "evento"})
			break
	return ops

func _punti_evento(i: int) -> int:
	var vuoto: bool = int(C()["evento"]) >= 0 or int(C()["consiglio_preso"]) >= 0
	if int(C()["evento"]) < 0:
		C()["evento"] = i
	if vuoto:
		_log("L'Evento di %s non dà azioni: un altro Evento o il Consiglio sono già stati giocati." % _nome(i))
		return 0
	return Dati.punti(s["guida"]["c"])

## A fine round: il Consiglio acquisito o l'Evento giocato scatenano gli eventi.
func _dopo_round() -> void:
	if not s.has("camp"):
		return
	var cp: int = C()["consiglio_preso"]
	var ev: int = C()["evento"]
	C()["consiglio_preso"] = -1
	C()["evento"] = -1
	if cp >= 0:
		_spingi({"k": "consiglio", "g": cp})
	elif ev >= 0:
		_spingi({"k": "evento", "g": s["iniz"]})

func _p_evento(p: Dictionary) -> void:
	var i: int = p["g"]
	if not p.has("vertice"):
		p["vertice"] = true
		_spingi(p)
		_spingi({"k": "vertice_chiedi", "g": i})
		return
	var fe: Array = FACCE_EVENTO[_dado(6)]
	var num := _dado(6) + 1
	C()["dado_evento"] = fe
	C()["dado_numero"] = num
	_log("Dado evento: %s (%s); dado numerico: %d." % ["Crisi" if fe[0] == "crisi" else "Editti", NOME_SIMBOLO[fe[1]], num])
	_ev({"tipo": "dado_evento", "faccia": fe, "numero": num})
	if fe[0] == "crisi":
		_spingi({"k": "crisi", "tirato": true})
	else:
		_spingi({"k": "editti"})

# ================================================================ Consiglio Imperiale
func _acquisisci(i: int, k: int, soggiogo: bool) -> void:
	if not s.has("camp") or s["corte"][k]["c"] != "consiglio":
		super(i, k, soggiogo)
		return
	var slot: Dictionary = s["corte"][k]
	for j in s["n"]:
		var a: int = slot["ag"][j]
		if a <= 0:
			continue
		if j == i:
			G(i)["agenti"] += a
		else:
			for z in a:
				G(i)["prigionieri"].append(j)
		slot["ag"][j] = 0
	C()["consiglio"] = "deciso"
	C()["consiglio_preso"] = i
	_log("%s acquisisce il Consiglio Imperiale: a fine round ne decide gli esiti." % _nome(i))
	_ev({"tipo": "acquisisci", "g": i, "c": "consiglio"})
	if s.has("turno"):
		s["turno"]["acquisite"].append("consiglio")

func _carte_acquisibili(i: int) -> Array:
	var out: Array = super(i)
	if s.has("camp") and C()["consiglio"] == "deciso":
		out = out.filter(func(k): return s["corte"][k]["c"] != "consiglio")
	return out

func _p_az_influenzare(p: Dictionary) -> void:
	if not s.has("camp") or _ha_r(p):
		super(p)
		return
	var i: int = p["g"]
	var ops := []
	for k in s["corte"].size():
		if s["corte"][k]["c"] == "consiglio" and C()["consiglio"] == "deciso":
			continue
		ops.append({"t": "Influenza " + Dati.nome_corte(s["corte"][k]["c"]), "v": k, "corte": k})
	_chiedi(p, i, "Su quale carta della Corte metti un agente?", ops, "corte")

func _p_rifornisci(_p: Dictionary) -> void:
	var target := (3 if s["n"] == 2 else 4) + (1 if s.has("camp") else 0)
	while s["corte"].size() < target and not s["mazzo_corte"].is_empty():
		_rifornisci_corte()

func _p_consiglio(p: Dictionary) -> void:
	var i: int = p["g"]
	if not p.has("fase"):
		p["fase"] = 1
		_spingi(p)
		_spingi({"k": "vertice_chiedi", "g": i})
		return
	if p["fase"] == 1:
		p["fase"] = 2
		if reggente(i):
			if primo() != i:
				C()["primo"] = i
				_log("%s diventa Primo Reggente e prende il Tesoro Imperiale." % _nome(i))
				_ev({"tipo": "primo", "g": i})
		else:
			var spazi := 0
			for r in G(i)["risorse"]:
				if r == "":
					spazi += 1
			var rubate := 0
			while spazi > 0 and not C()["tesoro"].is_empty():
				var t: String = C()["tesoro"].pop_back()
				_metti_risorsa_libera(i, t)
				spazi -= 1
				rubate += 1
			if rubate > 0:
				if primo() >= 0:
					G(primo())["potere"] -= rubate
				_log("%s ruba %d risorse dal Tesoro Imperiale." % [_nome(i), rubate])
	if _ha_r(p):
		if _e(_r(p), "crisi"):
			_spingi({"k": "crisi", "tirato": false})
		else:
			_spingi({"k": "editti"})
		return
	_chiedi(p, i, "Consiglio Imperiale: cosa risolvi?", [{"t": "Le Crisi", "v": "crisi"}, {"t": "Gli Editti", "v": "editti"}], "consiglio")

# ================================================================ Vertice (Richiamo all'Ordine)
func _p_vertice_chiedi(p: Dictionary) -> void:
	var i: int = p["g"]
	if _ha_r(p):
		if _e(_r(p), "si"):
			_spingi({"k": "vertice", "g": i})
		return
	_chiedi(p, i, "Vuoi convocare un Vertice?", [{"t": "No", "v": "no"}, {"t": "Sì, convoco il Vertice", "v": "si"}], "vertice")

func _p_vertice(p: Dictionary) -> void:
	var i: int = p["g"]
	if _ha_r(p):
		var v = _r(p)
		if _e(v, "fine"):
			_log("Il Vertice si chiude.")
			return
		match str(v):
			"consiglio":
				C()["consiglio"] = "sessione"
				_log("%s si appella al Consiglio: torna In Sessione." % _nome(i))
			"lascia":
				_lascia_impero(i)
			"rifonda":
				C()["titolo"][i] = "reggente"
				C()["primo"] = i
				_log("%s rifonda l'Impero e diventa Primo Reggente." % _nome(i))
		p.erase("r")
		p["fatte"] = p.get("fatte", []) + [str(v)]
	var ops := [{"t": "Chiudi il Vertice", "v": "fine"}]
	var fatte: Array = p.get("fatte", [])
	if C()["consiglio"] == "deciso" and not "consiglio" in fatte:
		ops.append({"t": "Appellati al Consiglio (torna In Sessione)", "v": "consiglio"})
	if reggente(i):
		ops.append({"t": "Lascia l'Impero (diventi Fuorilegge)", "v": "lascia"})
	else:
		var regg := false
		for j in s["n"]:
			if reggente(j):
				regg = true
		if not regg:
			ops.append({"t": "Rifonda l'Impero (torni Reggente e Primo Reggente)", "v": "rifonda"})
	_spingi(p)
	_chiedi(p, i, "Vertice, Richiamo all'Ordine: cosa fai?", ops, "vertice")
	s["pila"].pop_back()

func _lascia_impero(i: int) -> void:
	C()["titolo"][i] = "fuorilegge"
	_log("%s lascia l'Impero e diventa Fuorilegge." % _nome(i))
	_ev({"tipo": "fuorilegge", "g": i})
	if primo() == i:
		var best := -1
		for j in s["n"]:
			if reggente(j) and (best < 0 or G(j)["potere"] > G(best)["potere"]):
				best = j
		if best >= 0:
			C()["primo"] = best
			_log("%s diventa Primo Reggente." % _nome(best))
		else:
			var tot: int = C()["tesoro"].size()
			C()["tesoro"] = []
			G(i)["potere"] -= tot
			C()["primo"] = -1
			if tot > 0:
				_log("Non ci sono più Reggenti: il Tesoro torna nella riserva e %s perde %d Potere." % [_nome(i), tot])

# ================================================================ Crisi
func _p_crisi(p: Dictionary) -> void:
	if not p.get("tirato", false) and not p.has("dadi"):
		p["dadi"] = true
		C()["dado_evento"] = FACCE_EVENTO[_dado(6)]
		C()["dado_numero"] = _dado(6) + 1
		_log("Dadi delle Crisi: simbolo %s, settore %d." % [NOME_SIMBOLO[C()["dado_evento"][1]], C()["dado_numero"]])
	_log("— Crisi —")
	_ev({"tipo": "crisi"})
	_crisi_piaga()
	# Crisi della Corte: le carte Vox da sinistra a destra (si spingono a ritroso)
	var vox := []
	for slot in s["corte"]:
		var c: String = slot["c"]
		if c in ["c27", "x11", "x12"]:
			vox.append(c)
	for k in range(vox.size() - 1, -1, -1):
		_spingi({"k": "crisi_vox", "c": vox[k]})

## Ogni Piaga integra infligge 3 colpi, danneggiata 1: prima alle navi imperiali, poi a ogni giocatore.
func _crisi_piaga() -> void:
	for id in s["mappa"]:
		var pg: Array = s["mappa"][id]["navi"][piaga()]
		var colpi: int = pg[0] * 3 + pg[1]
		if colpi <= 0:
			continue
		var resto := _colpisci(imp(), id, colpi)
		var colpiti := false
		if resto > 0:
			for i in s["n"]:
				if navi(id, i) > 0:
					_colpisci(i, id, resto)
					colpiti = true
		if colpiti or resto < colpi:
			_ev({"tipo": "crisi_piaga", "sis": id})
			_log("La Piaga colpisce in %s." % _desc_sis(id))

func _colpisci(b: int, id: String, n: int) -> int:
	var nv: Array = s["mappa"][id]["navi"][b]
	var k := 0
	while k < n and nv[0] + nv[1] > 0:
		if nv[0] > 0:
			nv[0] -= 1
			nv[1] += 1
		else:
			nv[1] -= 1
			G(b)["navi"] += 1
			_ev({"tipo": "distruggi", "sis": id, "g": b, "cosa": "nave"})
		k += 1
	return n - k

func _p_crisi_vox(p: Dictionary) -> void:
	var c: String = p["c"]
	var k := -1
	for q in s["corte"].size():
		if s["corte"][q]["c"] == c:
			k = q
	if k < 0:
		return
	match c:
		"c27":
			# Richieste Populiste: il segnalino dichiarato più forte torna disponibile
			var best := -1
			for q in 3:
				if s["segnalini"][q]["amb"] != "" and (best < 0 or valore_segnalino(q)[0] > valore_segnalino(best)[0]):
					best = q
			if best >= 0:
				_log("Richieste Populiste: il segnalino di %s torna disponibile." % Dati.NOME_AMBIZIONE[s["segnalini"][best]["amb"]])
				s["segnalini"][best]["amb"] = ""
		"x11":
			# Intrigo a Corte: Consiglio In Sessione, gli agenti passano al Consiglio, la carta si seppellisce
			C()["consiglio"] = "sessione"
			for q in s["corte"].size():
				if s["corte"][q]["c"] == "consiglio":
					for j in s["n"]:
						s["corte"][q]["ag"][j] += s["corte"][k]["ag"][j]
			_seppellisci(k)
			_log("Intrigo a Corte: il Consiglio torna In Sessione.")
		"x12":
			# Fiasco Diplomatico: chi ha più carte Gilda che agenti in riserva ne scarta
			for i in ordine_da(s["iniz"]):
				var gilde: Array = G(i)["carte"].filter(func(x): return Dati.CORTE.has(x) and Dati.CORTE[x][1] == "gilda")
				while gilde.size() > G(i)["agenti"]:
					var x: String = gilde.pop_back()
					G(i)["carte"].erase(x)
					s["scarti_corte"].append(x)
					_log("Fiasco Diplomatico: %s scarta %s." % [_nome(i), Dati.nome_corte(x)])
			_seppellisci(k)

func _seppellisci(k: int) -> void:
	var slot: Dictionary = s["corte"][k]
	for j in s["n"]:
		G(j)["agenti"] += slot["ag"][j]
	s["corte"].remove_at(k)
	s["mazzo_corte"].append(slot["c"])
	_rifornisci_corte_in(k)

# ================================================================ Editti
func _p_editti(p: Dictionary) -> void:
	if not p.has("lista"):
		_log("— Editti —")
		_ev({"tipo": "editti"})
		var l: Array = C()["editti"].duplicate()
		l.sort()
		p["lista"] = l
		p["idx"] = 0
	var k: int = p["idx"]
	if k >= p["lista"].size():
		return
	p["idx"] = k + 1
	_spingi(p)
	match str(p["lista"][k]):
		"00":
			var q := 0
			while q < s["corte"].size():
				var slot: Dictionary = s["corte"][q]
				var c: String = slot["c"]
				var vuota: bool = slot["ag"].max() == 0
				if Dati.CORTE.has(c) and Dati.CORTE[c][1] == "gilda" and vuota:
					s["corte"].remove_at(q)
					s["mazzo_corte"].append(c)
				else:
					q += 1
			_p_rifornisci({})
			_log("Le Delegazioni delle Gilde Partono: le Gilde senza agenti tornano in fondo al mazzo.")
		"03":
			if primo() >= 0:
				_spingi({"k": "governa", "g": primo()})

func _p_governa(p: Dictionary) -> void:
	var i: int = p["g"]
	var pol: String = C()["politica"]
	if _ha_r(p):
		var v: String = _r(p)
		if v != "applica":
			C()["politica"] = v
			_log("%s cambia la Politica imperiale: ora è %s." % [_nome(i), NOME_POLITICA[v]])
			_ev({"tipo": "politica", "p": v})
			return
		_applica_politica(i, pol)
		return
	var ops := [{"t": "Applica la Politica di %s" % NOME_POLITICA[pol], "v": "applica"}]
	for x in POLITICHE:
		if x != pol:
			ops.append({"t": "Passa a una Politica di %s" % NOME_POLITICA[x], "v": x})
	_chiedi(p, i, "Governare l'Orlo Imperiale: la Politica è %s" % NOME_POLITICA[pol], ops, "politica")

func _applica_politica(i: int, pol: String) -> void:
	_log("%s applica la Politica di %s." % [_nome(i), NOME_POLITICA[pol]])
	# Riscuotere il Tributo
	for j in s["n"]:
		if not reggente(j):
			continue
		var preso := false
		if pol == "guerra":
			if j == i:
				continue
			for q in G(j)["trofei"].size():
				var t: Dictionary = G(j)["trofei"][q]
				if int(t["g"]) != imp() and not reggente(int(t["g"])):
					G(i)["trofei"].append(t)
					G(j)["trofei"].remove_at(q)
					preso = true
					break
			if not preso:
				for q in G(j)["prigionieri"].size():
					var x: int = G(j)["prigionieri"][q]
					if not reggente(x):
						G(i)["prigionieri"].append(x)
						G(j)["prigionieri"].remove_at(q)
						preso = true
						break
		else:
			for t in TRIBUTO[pol]:
				if _togli_risorsa(j, t):
					C()["tesoro"].append(t)
					preso = true
					break
		if not preso and j != i:
			if G(j)["agenti"] > 0:
				G(j)["agenti"] -= 1
				C()["favori"][i][str(j)] = int(C()["favori"][i].get(str(j), 0)) + 1
				_log("%s non può pagare il tributo: dà un agente come Favore." % _nome(j))
			else:
				_lascia_impero(j)
	_ev({"tipo": "tributo", "g": i})
	# Azione imperiale
	match pol:
		"pace":
			for j in s["n"]:
				if reggente(j):
					var b := bonus_citta(j)
					if b > 0:
						G(j)["potere"] += b
						_log("Celebrare la Reggenza: %s ottiene %d Potere." % [_nome(j), b])
		"escalation":
			var dove := ""
			for id in s["mappa"]:
				if s["mappa"][id]["navi"][imp()][0] > 0:
					dove = id
					break
			if dove == "" and not porti_di(i).is_empty():
				dove = porti_di(i)[0][0]
			if dove != "":
				var q := mini(2, G(imp())["navi"])
				s["mappa"][dove]["navi"][imp()][0] += q
				G(imp())["navi"] -= q
				_log("Requisire Navi: 2 navi imperiali in %s." % _desc_sis(dove))
		"guerra":
			for j in s["n"]:
				if reggente(j):
					if riserva("armi") > 0:
						_ottieni(j, "armi")
					elif C()["tesoro"].has("armi"):
						C()["tesoro"].erase("armi")
						_metti_risorsa_libera(j, "armi")

## Le risorse del Tesoro contano per le ambizioni del Primo Reggente.
func simboli(i: int, t: String) -> int:
	var n: int = super(i, t)
	if s.has("camp") and i == primo():
		n += C()["tesoro"].count(t)
	return n

# ================================================================ fine dell'Atto
func _controlla_fine() -> void:
	if not s.has("camp"):
		super()
		return
	if s["capitolo"] < 3:
		s["capitolo"] += 1
		_spingi({"k": "capitolo"})
		return
	var n: int = s["n"]
	var best := -1
	for i in ordine_da(s["iniz"]):
		if best < 0 or G(i)["potere"] > G(best)["potere"]:
			best = i
	s["vincitore"] = best
	s["fine"] = true
	s["attesa"] = {}
	_log("Fine dell'Atto I: è in testa %s con %d Potere." % [_nome(best), G(best)["potere"]])
	_ev({"tipo": "fine", "g": best})

## Legge della Tregua: un Reggente non tassa le città di Reggenti Rivali nei sistemi con navi imperiali.
func _bersagli_tassa(i: int, solo_leali: bool) -> Array:
	var out: Array = super(i, solo_leali)
	if not s.has("camp") or not reggente(i):
		return out
	return out.filter(func(x):
		var g: int = s["mappa"][x[0]]["edifici"][x[1]]["g"]
		if g == i or g >= s["n"] or not reggente(g):
			return true
		var nv: Array = s["mappa"][x[0]]["navi"][imp()]
		return nv[0] + nv[1] == 0)

# ================================================================ carte Vox della campagna
func _p_vox(p: Dictionary) -> void:
	if not s.has("camp") or not p["c"] in ["x11", "x12"]:
		super(p)
		return
	var i: int = p["g"]
	if p["c"] == "x11":
		C()["consiglio"] = "sessione"
		_log("Intrigo a Corte: il Consiglio Imperiale torna In Sessione.")
	else:
		for j in ordine_da(s["iniz"]):
			if j == i:
				continue
			var gilde: Array = G(j)["carte"].filter(func(x): return Dati.CORTE.has(x) and Dati.CORTE[x][1] == "gilda")
			while gilde.size() > G(j)["agenti"]:
				var x: String = gilde.pop_back()
				G(j)["carte"].erase(x)
				s["scarti_corte"].append(x)
				_log("Fiasco Diplomatico: %s scarta %s." % [_nome(j), Dati.nome_corte(x)])
	s["mazzo_corte"].append(p["c"])
