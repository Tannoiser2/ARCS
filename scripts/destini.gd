## Campagna «L'Orlo Infestato»: Destini, obiettivi, libretto delle regole, Intervallo e Atti II e III.
## Le regole dei singoli Destini stanno nelle sottoclassi (destini_a.gd, destini_b.gd, destini_c.gd).
class_name MotoreDestini
extends MotoreCampagna

const DESTINI_A := ["siniscalco", "fondatore", "magnate", "patrocinatore", "curatore", "partigiano", "ammiraglio", "credente"]
const DESTINI_B := ["esploratore", "egemone", "distruttore", "pirata", "voce", "pacifista", "paciere", "castellano"]
const DESTINI_C := ["signore", "sopravvissuto", "redentore", "guardiano", "naturalista", "spettro", "cospiratore", "giudice"]
const NOME_DESTINO := {"siniscalco": "Siniscalco", "fondatore": "Fondatore", "magnate": "Magnate", "patrocinatore": "Patrocinatore",
	"curatore": "Curatore", "partigiano": "Partigiano", "ammiraglio": "Ammiraglio", "credente": "Credente",
	"esploratore": "Esploratore", "egemone": "Egemone", "distruttore": "Distruttore di Pianeti", "pirata": "Pirata",
	"voce": "Voce della Piaga", "pacifista": "Pacifista", "paciere": "Paciere", "castellano": "Castellano",
	"signore": "Signore Supremo", "sopravvissuto": "Sopravvissuto", "redentore": "Redentore", "guardiano": "Guardiano",
	"naturalista": "Naturalista", "spettro": "Spettro dei Portali", "cospiratore": "Cospiratore", "giudice": "Giudice"}
## carta Destino (fronte con la descrizione) di ogni Destino
const CARTA_DESTINO := {"siniscalco": "216_00", "fondatore": "216_01", "magnate": "216_02", "patrocinatore": "216_03",
	"curatore": "216_04", "partigiano": "216_05", "ammiraglio": "216_06", "credente": "216_07",
	"esploratore": "217_08", "egemone": "217_09", "distruttore": "217_10", "pirata": "217_11", "voce": "217_12",
	"pacifista": "217_13", "paciere": "217_14", "castellano": "217_15", "signore": "218_16", "sopravvissuto": "218_17",
	"redentore": "218_18", "guardiano": "218_19", "naturalista": "218_20", "spettro": "218_21", "cospiratore": "218_22",
	"giudice": "218_23"}
## prefisso delle immagini del set di ogni Destino
const PREFISSO := {"siniscalco": "463", "fondatore": "471", "magnate": "427", "patrocinatore": "428", "curatore": "429",
	"partigiano": "477", "ammiraglio": "479", "credente": "458", "esploratore": "433", "egemone": "467", "distruttore": "475",
	"pirata": "487", "voce": "436", "pacifista": "472", "paciere": "442", "castellano": "488", "signore": "450",
	"sopravvissuto": "468", "redentore": "444", "guardiano": "473", "naturalista": "446", "spettro": "456",
	"cospiratore": "474", "giudice": "449"}
## casella di partenza dell'obiettivo: destino -> atto -> [2, 3, 4 giocatori]
const PARTENZA := {
	"siniscalco": {1: [20, 17, 14], 2: [22, 22, 22]},
	"fondatore": {1: [18, 16, 14], 2: [12, 14, 16]},
	"magnate": {1: [10, 10, 10], 2: [12, 12, 12]},
	"patrocinatore": {1: [18, 18, 18], 2: [12, 12, 12]},
	"curatore": {1: [18, 18, 18], 2: [7, 8, 9]},
	"partigiano": {1: [12, 11, 10], 2: [18, 14, 12]},
	"ammiraglio": {1: [13, 13, 13], 2: [30, 30, 30]},
	"credente": {1: [10, 9, 8], 2: [20, 18, 16]},
	"esploratore": {2: [8, 8, 8]}, "egemone": {2: [14, 14, 14]}, "distruttore": {2: [12, 12, 12]},
	"pirata": {2: [24, 21, 18]}, "voce": {2: [18, 16, 14]}, "pacifista": {2: [16, 14, 12]},
	"paciere": {2: [18, 16, 14]}, "castellano": {2: [22, 22, 22]},
	"signore": {3: [20, 20, 20]}, "sopravvissuto": {3: [22, 18, 14]}, "redentore": {3: [16, 14, 12]},
	"guardiano": {3: [15, 15, 15]}, "naturalista": {3: [18, 16, 14]}, "spettro": {3: [24, 21, 18]},
	"cospiratore": {3: [12, 9, 6]}, "giudice": {3: [6, 6, 6]}}
## Potere delle grandi ambizioni nell'Atto III: capitolo -> [una, entrambe]
const GRANDI := {1: [2, 4], 2: [3, 8], 3: [4, 14], 4: [5, 20]}

## Preparazione: destino -> atto -> operazioni. Numeri = numeri delle carte del set.
## prendi / libretto / via_libretto / corte / cima / elimina / primo / spec
const PREP := {
	"siniscalco": {1: [["prendi", [2, 3]], ["primo"]], 2: [["libretto", [13]]],
		3: [["libretto", [23]], ["spec", "autorita"]]},
	"fondatore": {1: [["prendi", [2]]], 2: [["prendi", [13]], ["libretto", [14, 15, 22]], ["spec", "confederazione"]],
		3: [["via_libretto", [15]], ["libretto", [26]], ["prendi", [27]]]},
	"magnate": {1: [["prendi", [2]]], 2: [["libretto", [18, 19, 20]], ["spec", "monopoli"]],
		3: [["libretto", [27]], ["spec", "economia"]]},
	"patrocinatore": {1: [["prendi", [2, 3]]], 2: [["libretto", [13, 14]]], 3: [["prendi", [24]], ["libretto", [25]]]},
	"curatore": {1: [["prendi", [2, 3, 4]], ["libretto", [5, 6]], ["spec", "golem"]],
		2: [["prendi", [13]], ["libretto", [14]], ["spec", "evento_extra"], ["spec", "golem_desta"]],
		3: [["libretto", [21]], ["spec", "golem_desta"]]},
	"partigiano": {1: [["prendi", [2, 3]]], 2: [["libretto", [16]], ["prendi", [17]]], 3: [["prendi", [25]]]},
	"ammiraglio": {1: [["prendi", [2]], ["libretto", [3]], ["spec", "primo_ammiraglio"]], 2: [["corte", [13]]],
		3: [["libretto", [20]]]},
	"credente": {1: [["prendi", [2, 3]], ["libretto", [13, 14]], ["spec", "pila_fedeli"]],
		2: [["libretto", [21]], ["via_libretto", [14]], ["libretto", [23]], ["spec", "dottrina"]],
		3: [["libretto", [30, 31]], ["spec", "dottrina_maggioranza"]]},
	"esploratore": {2: [["spec", "ammiraglia"], ["spec", "migliorie:scia=porto,scafo=citta"], ["prendi", [2]], ["spec", "portale"]],
		3: [["prendi", [8]], ["cima", [9]], ["spec", "pellegrini"]]},
	"egemone": {2: [["spec", "ammiraglia"], ["spec", "migliorie:difesa=porto,scia=porto"], ["spec", "rifornisci_ammiraglia:6"],
		["spec", "elimina_navi:4"], ["prendi", [2, 4]], ["libretto", [3]], ["spec", "stendardi"]], 3: [["prendi", [12]]]},
	"distruttore": {2: [["spec", "ammiraglia"], ["spec", "migliorie:scia=porto"], ["prendi", [2, 3]], ["spec", "frammenti"]],
		3: [["spec", "mondi_ripristina"]]},
	"pirata": {2: [["spec", "ammiraglia"], ["spec", "migliorie:raggio=porto,difesa=porto"], ["prendi", [2, 3]],
		["spec", "rifornisci_portali"]], 3: [["corte", [9, 10]], ["libretto", [11, 12]], ["spec", "dicerie"]]},
	"voce": {2: [["prendi", [2]], ["spec", "elimina_navi:2"], ["spec", "rifornisci:8"]], 3: [["prendi", [13]]]},
	"pacifista": {2: [["spec", "togli_oltraggio"], ["prendi", [2, 3]], ["spec", "testimoni"], ["spec", "rifornisci:8"]],
		3: [["libretto", [9, 11, 12]]]},
	"paciere": {2: [["spec", "togli_armi_virtuali"], ["spec", "togli_oltraggio"], ["spec", "oltraggio:armi"], ["prendi", [2, 3]],
		["spec", "rifornisci:8"]], 3: [["spec", "togli_armi_virtuali"], ["libretto", [8, 9, 10, 11]], ["spec", "cessate_il_fuoco"]]},
	"castellano": {2: [["prendi", [2]], ["libretto", [9, 10]], ["spec", "seggi"], ["spec", "rifornisci:8"]],
		3: [["libretto", [18, 19]]]},
	"signore": {3: [["spec", "ricollocare"], ["prendi", [2]], ["libretto", [3]], ["spec", "oltraggio_signore"]]},
	"sopravvissuto": {3: [["spec", "ricollocare"], ["prendi", [2, 3]], ["libretto", [4, 5]], ["spec", "bunker"]]},
	"redentore": {3: [["spec", "ricollocare"], ["spec", "oltraggio:reliquie"], ["prendi", [2]], ["libretto", [3]], ["cima", [4]],
		["spec", "togli_reliquie_virtuali"]]},
	"guardiano": {3: [["spec", "ricollocare"], ["spec", "oltraggio:carburante"], ["spec", "oltraggio:materiale"],
		["spec", "togli_mat_carb_virtuali"], ["prendi", [2, 3]], ["libretto", [4]], ["spec", "guardia_eden"]]},
	"naturalista": {3: [["spec", "ricollocare"], ["prendi", [2, 3]], ["libretto", [4]], ["spec", "stirpe_piaga"]]},
	"spettro": {3: [["spec", "ricollocare"], ["prendi", [2, 3]], ["libretto", [5]], ["cima", [6]], ["spec", "passaggi"]]},
	"cospiratore": {3: [["spec", "ricollocare"], ["prendi", [2, 3]], ["libretto", [4, 5]], ["spec", "cospirazioni"]]},
	"giudice": {3: [["spec", "ricollocare"], ["prendi", [2, 3, 4]], ["libretto", [5]]]}}

## Risoluzione all'Intervallo: destino -> atto -> {"ok": [...], "ko": [...]}
const RIS := {
	"siniscalco": {1: {"ok": [["corte", [5, 6, 7]], ["libretto", [8]], ["elimina", [9, 10, 11]]],
			"ko": [["elimina", [5, 6, 7, 8]], ["corte", [9, 10, 11, 3]]]},
		2: {"ok": [["corte", [15, 16, 17]], ["elimina", [18, 19, 20, 21]]], "ko": [["elimina", [15, 16, 17]], ["corte", [18, 19, 20, 21]]]}},
	"fondatore": {1: {"ok": [["prendi", [4]], ["corte", [5, 6, 7]]], "ko": [["elimina", [4, 5, 6, 7]], ["corte", [8, 9, 10, 11]]]},
		2: {"ok": [["prendi", [24]], ["elimina", [8, 9, 10, 11]]],
			"ko": [["elimina", [24, 13]], ["spec", "fine_confederazione"], ["corte", [8, 9, 10, 11]]]}},
	"magnate": {1: {"ok": [["corte", [4, 5, 6]], ["spec", "cc_scarti"]], "ko": [["elimina", [4, 5, 6]], ["corte", [7, 8, 9, 10, 11]]]},
		2: {"ok": [["prendi", [22]], ["elimina", [7, 8, 9, 10, 11, 23, 24]], ["spec", "cc_scarti"]],
			"ko": [["elimina", [22]], ["spec", "monopoli_liberi"], ["corte", [23, 24]]]}},
	"patrocinatore": {1: {"ok": [["corte", [3, 5, 6, 7, 8, 9, 10]], ["elimina", [11]]],
			"ko": [["corte", [3]], ["spec", "emissari"], ["elimina", [10]], ["corte", [11]]]},
		2: {"ok": [["corte", [16, 17, 18, 19, 20, 21]], ["elimina", [22]]],
			"ko": [["elimina", [16, 17, 18, 19, 20, 21]], ["corte", [22]], ["via_libretto", [13]]]}},
	"curatore": {1: {"ok": [["elimina", [2]], ["spec", "golem_focolare"], ["spec", "lore_corte"], ["corte", [8, 9, 10, 11]]],
			"ko": [["elimina", [2]], ["corte", [4]], ["spec", "golem_via"]]},
		2: {"ok": [["corte", [17, 18, 19]]], "ko": [["elimina", [17, 18, 19]], ["spec", "instabili_scarti"]]}},
	"partigiano": {1: {"ok": [["corte", [5, 6, 7, 8, 9]], ["prendi", [10]], ["elimina", [11, 12, 13, 14]]],
			"ko": [["elimina", [5, 6, 7, 8, 9, 3]], ["corte", [10, 11, 12, 13, 14]], ["spec", "togli_oltraggio"]]},
		2: {"ok": [["libretto", [19]], ["corte", [20, 21]], ["elimina", [22, 23]]], "ko": [["elimina", [19, 20, 21]], ["corte", [22, 23]]]}},
	"ammiraglio": {1: {"ok": [["prendi", [5]], ["corte", [6, 7, 8, 9]], ["elimina", [10, 11]]],
			"ko": [["via_libretto", [3]], ["elimina", [5, 6, 7]], ["corte", [8, 9, 10, 11]]]},
		2: {"ok": [["elimina", [15, 16]], ["corte", [17, 18]]], "ko": [["corte", [15, 16]], ["elimina", [17, 18]]]}},
	"credente": {1: {"ok": [["prendi", [16]], ["corte", [17]], ["elimina", [3, 18, 19]], ["spec", "fedeli_corte"]],
			"ko": [["elimina", [3, 16, 17]], ["corte", [18, 19]], ["spec", "fedeli_corte"]]},
		2: {"ok": [["spec", "profeta"], ["elimina", [26, 27, 28]]],
			"ko": [["spec", "ideali_via"], ["elimina", [25]], ["corte", [26]], ["via_libretto", [21, 23]], ["libretto", [27, 28]]]}},
	"esploratore": {2: {"ok": [["corte", [5]], ["elimina", [6]], ["spec", "miglioria_gratis"]],
		"ko": [["elimina", [5, 2, 3]], ["corte", [6]], ["spec", "portale_rivelato"]]}},
	"egemone": {2: {"ok": [["prendi", [6]], ["corte", [7, 8]], ["elimina", [9, 10]]],
		"ko": [["elimina", [6]], ["corte", [7, 8, 9, 10]], ["spec", "stendardi_via"]]}},
	"distruttore": {2: {"ok": [["elimina", [11]], ["spec", "mondi_annota"]],
		"ko": [["corte", [11]], ["spec", "martello_completo"], ["spec", "mondi_riserva"], ["elimina", [4]]]}},
	"pirata": {2: {"ok": [["prendi", [5]], ["elimina", [6, 7]], ["spec", "bottino_ok"]],
		"ko": [["corte", [3, 5, 6, 7]], ["spec", "bottino_via"]]}},
	"voce": {2: {"ok": [["prendi", [4]], ["corte", [5, 6, 7, 8, 9]], ["elimina", [10, 11]]],
		"ko": [["elimina", [4, 5, 6, 7, 8]], ["corte", [9, 10, 11]]]}},
	"pacifista": {2: {"ok": [["elimina", [2, 5, 6, 7]], ["spec", "testimoni_psico"]],
		"ko": [["elimina", [2]], ["corte", [5, 6, 7]], ["spec", "testimoni_via"]]}},
	"paciere": {2: {"ok": [["corte", [5, 6]]], "ko": [["elimina", [2]], ["spec", "arsenale_corte"]]}},
	"castellano": {2: {"ok": [["prendi", [12]], ["corte", [13, 14]], ["elimina", [15, 16]]],
		"ko": [["spec", "seggi_via"], ["elimina", [12, 13, 14]], ["corte", [15, 16]]]}}}

static var NUM := {}
static var ALIAS := {}
static var _caricati := false

## Carica i dati delle carte dei Destini (nomi, tipi, semi, costi, testi) da assets/dati/destini.json.
static func carica_dati() -> void:
	if _caricati:
		return
	_caricati = true
	var f := FileAccess.open("res://assets/dati/destini.json", FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	if not (d is Dictionary):
		return
	var nomi_base := {}
	for c in Dati.CORTE:
		nomi_base[str(Dati.CORTE[c][0]).to_upper()] = c
	for k in d:
		var e: Dictionary = d[k]
		Dati.EXTRA[k] = [_nome_bello(str(e.get("nome", ""))), str(e.get("tipo", "")), str(e.get("seme", "")), int(e.get("costo", 0))]
		Dati.EXTRA_TESTO[k] = str(e.get("testo", ""))
		var dest := str(e.get("destino", ""))
		if dest != "":
			if not NUM.has(dest):
				NUM[dest] = {}
			NUM[dest][int(e.get("num", 0))] = k
		if str(e.get("tipo", "")) == "gilda" and nomi_base.has(str(e.get("nome", "")).to_upper()):
			ALIAS[k] = nomi_base[str(e.get("nome", "")).to_upper()]

static func _nome_bello(t: String) -> String:
	if t == "":
		return ""
	var out := []
	for w in t.to_lower().split(" "):
		if w in ["di", "del", "della", "dei", "delle", "dello", "degli", "il", "la", "le", "lo", "gli", "e", "per", "a", "al", "alla", "con", "da", "in", "nel", "nella", "sul", "sulla"]:
			out.append(w)
		elif w.length() > 0:
			out.append(w[0].to_upper() + w.substr(1))
	var r := " ".join(out)
	return r[0].to_upper() + r.substr(1)

func _init() -> void:
	carica_dati()

# ================================================================ utilità
func destino(i: int) -> String:
	if not s.has("camp") or not C().has("destino") or i < 0 or i >= s["n"]:
		return ""
	return C()["destino"][i]

func in_gioco_destino(d: String) -> int:
	if not s.has("camp") or not C().has("destino"):
		return -1
	for i in s["n"]:
		if C()["destino"][i] == d:
			return i
	return -1

func atto() -> int:
	return int(C()["atto"])

## Codice della carta n del set di un Destino (con l'alias se è una copia di una carta base).
func carta(d: String, n: int) -> String:
	var k: String = NUM.get(d, {}).get(n, "")
	return ALIAS.get(k, k)

func nel_libretto(c: String) -> bool:
	return C()["libretto"].has(c)

func obiettivo(i: int) -> int:
	return int(C()["obiettivo"][i])

## Avanza il segnalino obiettivo verso 0.
func avanza(i: int, n: int, motivo := "") -> void:
	if n <= 0 or i < 0 or i >= s["n"] or obiettivo(i) < 0:
		return
	var prima := obiettivo(i)
	if prima == 0:
		return
	C()["obiettivo"][i] = maxi(0, prima - n)
	_log("%s avanza di %d nell'obiettivo%s (%d)." % [_nome(i), prima - obiettivo(i), " (" + motivo + ")" if motivo != "" else "", obiettivo(i)])
	_ev({"tipo": "obiettivo", "g": i, "da": prima, "a": obiettivo(i)})
	if obiettivo(i) == 0:
		_log("%s ha completato il suo obiettivo!" % _nome(i))

func ha_carta(i: int, c: String) -> bool:
	if i < 0 or i >= s["n"]:
		return false
	return super(i, c)

## Togli una carta (codice) da ogni zona: area dei giocatori, libretto, Corte, mazzo e scarti.
func _elimina_carta(c: String) -> void:
	for i in s["n"]:
		if G(i)["carte"].has(c):
			G(i)["carte"].erase(c)
			return
	if C()["libretto"].has(c):
		C()["libretto"].erase(c)
		return
	for k in s["corte"].size():
		if s["corte"][k]["c"] == c:
			_seppellisci(k)
			s["mazzo_corte"].erase(c)
			return
	if s["mazzo_corte"].has(c):
		s["mazzo_corte"].erase(c)
		return
	if s["scarti_corte"].has(c):
		s["scarti_corte"].erase(c)

# ================================================================ inizio: scelta e preparazione dei Destini
func _p_inizio_destini(_p: Dictionary) -> void:
	var n: int = s["n"]
	C()["destino"] = []
	C()["lettera"] = []
	C()["obiettivo"] = []
	C()["libretto"] = []
	C()["dest"] = {}
	C()["storia"] = []
	C()["potere_atti"] = []
	for i in n:
		C()["destino"].append("")
		C()["lettera"].append("")
		C()["obiettivo"].append(-1)
	var mazzo: Array = DESTINI_A.duplicate()
	_mescola(mazzo)
	C()["mazzo_A"] = mazzo
	var b: Array = DESTINI_B.duplicate()
	_mescola(b)
	C()["mazzo_B"] = b
	var c: Array = DESTINI_C.duplicate()
	_mescola(c)
	C()["mazzo_C"] = c
	if n == 2:
		C()["libretto"].append("972_01")
	_spingi({"k": "dopo_destini"})
	_spingi({"k": "prepara_destini", "idx": 0})
	_spingi({"k": "scegli_destini", "idx": 0, "lettera": "A"})

## Ogni giocatore pesca i Destini della lettera dell'Atto e ne sceglie uno in segreto.
func _p_scegli_destini(p: Dictionary) -> void:
	var ordine := ordine_da(s["iniz"])
	var k: int = p["idx"]
	if k >= ordine.size():
		for i in s["n"]:
			_log("%s sceglie il Destino %s." % [_nome(i), NOME_DESTINO[destino(i)]])
			_ev({"tipo": "destino", "g": i, "d": destino(i)})
		return
	var i: int = ordine[k]
	if _ha_r(p):
		var v: String = _r(p)
		var vecchio := destino(i)
		if vecchio != "" and vecchio != v:
			_cambia_destino(i, vecchio)
		C()["destino"][i] = v
		C()["lettera"][i] = "A" if v in DESTINI_A else ("B" if v in DESTINI_B else "C")
		for x in p.get("offerta", []):
			if x != v and x != vecchio:
				C()["mazzo_" + str(p["lettera"])].append(x)
		p["idx"] = k + 1
		p.erase("offerta")
		_spingi(p)
		return
	var lettera: String = p["lettera"]
	var mazzo: Array = C()["mazzo_" + lettera]
	var quanti: int = p.get("quanti", {}).get(str(i), 2)
	var offerta := []
	if not p.has("offerta"):
		for z in quanti:
			if not mazzo.is_empty():
				offerta.append(mazzo.pop_front())
		p["offerta"] = offerta
	offerta = p["offerta"]
	var ops := []
	var attuale := destino(i)
	if attuale != "" and p.get("tieni", {}).get(str(i), false):
		ops.append({"t": "Resta %s (Destino %s)" % [NOME_DESTINO[attuale], C()["lettera"][i]], "v": attuale, "destino": attuale, "carta": CARTA_DESTINO[attuale]})
	for d in offerta:
		ops.append({"t": "%s (Destino %s)" % [NOME_DESTINO[d], lettera], "v": d, "destino": d, "carta": CARTA_DESTINO[d]})
	_spingi(p)
	_chiedi(p, i, "Scegli il tuo Destino", ops, "destino")
	s["pila"].pop_back()

## Cambiando Destino si elimina la parte del set che non è in gioco e si restituiscono i Favori.
func _cambia_destino(i: int, vecchio: String) -> void:
	_log("%s abbandona il Destino %s." % [_nome(i), NOME_DESTINO[vecchio]])
	for j in s["n"]:
		var f: int = int(C()["favori"][i].get(str(j), 0))
		G(j)["agenti"] += f
	C()["favori"][i] = {}

func _p_prepara_destini(p: Dictionary) -> void:
	var ordine := ordine_da(s["iniz"])
	var k: int = p["idx"]
	if k >= ordine.size():
		return
	p["idx"] = k + 1
	_spingi(p)
	var i: int = ordine[k]
	var d := destino(i)
	var a := atto()
	# segnalino obiettivo
	if PARTENZA.has(d) and PARTENZA[d].has(a):
		C()["obiettivo"][i] = int(PARTENZA[d][a][s["n"] - 2])
	else:
		C()["obiettivo"][i] = -1
	_log("Preparazione del Destino %s di %s (Atto %s)." % [NOME_DESTINO[d], _nome(i), ["I", "II", "III"][a - 1]])
	var ops: Array = PREP.get(d, {}).get(a, [])
	for q in range(ops.size() - 1, -1, -1):
		_spingi({"k": "op_destino", "g": i, "d": d, "op": ops[q]})

func _p_dopo_destini(_p: Dictionary) -> void:
	if primo() < 0:
		C()["primo"] = s["iniz"]
		_log("%s prende la tessera Primo Reggente." % _nome(s["iniz"]))

## Esegue un'operazione di preparazione o di risoluzione di un Destino.
func _p_op_destino(p: Dictionary) -> void:
	var i: int = p["g"]
	var d: String = p["d"]
	var op: Array = p["op"]
	var nums: Array = op[1] if op.size() > 1 and op[1] is Array else []
	match str(op[0]):
		"prendi":
			for n in nums:
				var c := carta(d, n)
				if c != "":
					_elimina_carta(c)
					G(i)["carte"].append(c)
					_log("%s prende %s." % [_nome(i), Dati.nome_corte(c)])
		"libretto":
			for n in nums:
				var c := carta(d, n)
				if c != "" and not C()["libretto"].has(c):
					C()["libretto"].append(c)
					_log("Nel libretto delle regole entra %s." % Dati.nome_corte(c))
					_ev({"tipo": "libretto", "c": c})
		"via_libretto":
			for n in nums:
				C()["libretto"].erase(carta(d, n))
		"corte":
			for n in nums:
				var c := carta(d, n)
				if c != "":
					_elimina_carta(c)
					s["mazzo_corte"].append(c)
			_mescola(s["mazzo_corte"])
		"cima":
			for n in nums:
				var c := carta(d, n)
				if c != "":
					_elimina_carta(c)
					s["mazzo_corte"].push_front(c)
		"elimina":
			for n in nums:
				var c := carta(d, n)
				if c != "":
					_elimina_carta(c)
		"primo":
			C()["primo"] = i
			_log("%s prende la tessera Primo Reggente." % _nome(i))
		"spec":
			_spec(i, d, str(op[1]), p)

## Operazioni speciali dei Destini: le definiscono le sottoclassi.
func _spec(i: int, d: String, nome: String, _p: Dictionary) -> void:
	match nome:
		"primo_ammiraglio":
			if in_gioco_destino("siniscalco") < 0:
				C()["primo"] = i
				_log("%s prende la tessera Primo Reggente." % _nome(i))
		"togli_oltraggio":
			G(i)["oltraggio"] = []
		"cc_scarti":
			for c in ["c02", "c09"]:
				if s["scarti_corte"].has(c):
					s["scarti_corte"].erase(c)
					s["mazzo_corte"].append(c)
			_mescola(s["mazzo_corte"])
		_:
			if nome.begins_with("oltraggio:"):
				_oltraggio(i, nome.substr(10))
			elif nome.begins_with("rifornisci:"):
				_rifornisci_flotta(i, int(nome.substr(11)))
			elif nome.begins_with("elimina_navi:"):
				_elimina_navi(i, int(nome.substr(13)))
			else:
				_spec_destino(i, d, nome)

func _spec_destino(_i: int, _d: String, _nome_: String) -> void:
	pass

## Rifornisci la flotta: 1 nave alla volta nei sistemi finché non ne hai n sulla mappa.
func _rifornisci_flotta(i: int, n: int) -> void:
	var sulla_mappa := 0
	for id in s["mappa"]:
		sulla_mappa += navi(id, i)
	var dove: Array = _sistemi_controllati(i)
	if dove.is_empty():
		for x in edifici_di(i):
			dove.append(x[0])
	if dove.is_empty():
		dove = ["%dg" % (_dado(6) + 1)]
	var k := 0
	while sulla_mappa < n and G(i)["navi"] > 0:
		_metti_navi(i, dove[k % dove.size()], 1, false)
		sulla_mappa += 1
		k += 1
	_log("%s rifornisce la flotta." % _nome(i))

func _elimina_navi(i: int, n: int) -> void:
	var tolte := mini(n, G(i)["navi"])
	G(i)["navi"] -= tolte
	n -= tolte
	for id in s["mappa"]:
		while n > 0 and navi(id, i) > 0:
			var nv: Array = s["mappa"][id]["navi"][i]
			if nv[1] > 0:
				nv[1] -= 1
			else:
				nv[0] -= 1
			n -= 1

# ================================================================ fine dei capitoli, degli Atti e della campagna
func capitoli_atto() -> int:
	return 4 if atto() == 3 else 3

func _controlla_fine() -> void:
	if not s.has("camp") or not C().has("destino"):
		super()
		return
	# obiettivi finali dei Destini C (Atto III)
	if atto() == 3:
		var vincitori := []
		for i in s["n"]:
			if C()["lettera"][i] == "C" and obiettivo(i) == 0 and G(i)["potere"] >= 1:
				vincitori.append(i)
		if not vincitori.is_empty():
			var best: int = vincitori[0]
			for i in vincitori:
				if G(i)["potere"] > G(best)["potere"]:
					best = i
			_fine_campagna(best, "completa il suo obiettivo finale")
			return
	if s["capitolo"] < capitoli_atto():
		s["capitolo"] += 1
		_spingi({"k": "capitolo"})
		return
	if atto() < 3:
		_spingi({"k": "intervallo", "fase": 0})
		return
	var best := -1
	var ordine_lettere := {"A": 0, "B": 1, "C": 2}
	for i in ordine_da(s["iniz"]):
		if best < 0:
			best = i
			continue
		var pi_: int = G(i)["potere"]
		var pb: int = G(best)["potere"]
		if pi_ > pb or (pi_ == pb and ordine_lettere[C()["lettera"][i]] < ordine_lettere[C()["lettera"][best]]):
			best = i
	_fine_campagna(best, "ha più Potere alla fine dell'Atto III")

func _fine_campagna(i: int, perche: String) -> void:
	s["vincitore"] = i
	s["fine"] = true
	s["attesa"] = {}
	_log("La campagna è finita: vince %s (%s) con %d Potere!" % [_nome(i), perche, G(i)["potere"]])
	_ev({"tipo": "fine", "g": i})

## Grandi ambizioni dell'Atto III (Destini A e B): le sottoclassi dicono se sono realizzate.
func _grande_ambizione(_i: int, _k: int) -> bool:
	return false

# ================================================================ Intervallo
func _p_intervallo(p: Dictionary) -> void:
	var n: int = s["n"]
	match int(p["fase"]):
		0:
			_log("— Intervallo dopo l'Atto %s —" % ["I", "II"][atto() - 1])
			_ev({"tipo": "intervallo"})
			C()["potere_atti"].append(s["g"].slice(0, n).map(func(g): return g["potere"]))
			p["fase"] = 1
			_spingi(p)
			# A) risoluzione dei Destini
			for i in range(n - 1, -1, -1):
				var d := destino(i)
				var ok := obiettivo(i) == 0
				var ops: Array = RIS.get(d, {}).get(atto(), {}).get("ok" if ok else "ko", [])
				for q in range(ops.size() - 1, -1, -1):
					_spingi({"k": "op_destino", "g": i, "d": d, "op": ops[q]})
				if not ok and obiettivo(i) > 0:
					G(i)["potere"] -= obiettivo(i)
					_log("%s non ha completato l'obiettivo e perde %d Potere." % [_nome(i), obiettivo(i)])
				C()["storia"].append({"atto": atto(), "g": i, "d": d, "ok": ok})
		1:
			# B) Corte
			for slot in s["corte"]:
				for j in n:
					G(j)["agenti"] += slot["ag"][j]
				if slot["c"] != "consiglio":
					s["mazzo_corte"].append(slot["c"])
			s["corte"] = [{"c": "consiglio", "ag": _zeri_int(n)}]
			s["scarti_corte"] = []
			_mescola(s["mazzo_corte"])
			# C) Trofei, Prigionieri, risorse congelate
			for i in n:
				for t in G(i)["trofei"]:
					_restituisci_pezzo(t)
				G(i)["trofei"] = []
				for j in G(i)["prigionieri"]:
					if j < n:
						G(j)["agenti"] += 1
				G(i)["prigionieri"] = []
			C()["tesoro"] = []
			if n == 2:
				s["virtuale"] = {}
				s["fuori_risorse"] = {}
			# D) Piaga riparata, pezzi danneggiati distrutti, edifici senza navi distrutti dalla Piaga
			for id in s["mappa"]:
				var m: Dictionary = s["mappa"][id]
				var pg: Array = m["navi"][piaga()]
				pg[0] += pg[1]
				pg[1] = 0
				for j in m["navi"].size():
					var d_: int = m["navi"][j][1]
					if d_ > 0 and j != piaga():
						G(j)["navi"] += d_
						m["navi"][j][1] = 0
				var con_navi := false
				for j in m["navi"].size():
					if j != piaga() and m["navi"][j][0] + m["navi"][j][1] > 0:
						con_navi = true
				for k in m["edifici"].size():
					var e = m["edifici"][k]
					if e == null:
						continue
					if e["danno"] or (pg[0] > 0 and not con_navi):
						_rimuovi_edificio(id, k)
			# E) iniziativa e Potere dimezzato
			var best := 0
			for i in n:
				if G(i)["potere"] > G(best)["potere"]:
					best = i
			s["iniz"] = best
			for i in n:
				var pw: int = G(i)["potere"]
				if pw > 1:
					G(i)["potere"] = pw - pw / 2
			_log("L'iniziativa va a %s. Il Potere di chi ne ha più di 1 si dimezza." % _nome(best))
			p["fase"] = 2
			_spingi(p)
			# F) scelta del Destino
			var lettera := "B" if atto() == 1 else "C"
			var quanti := {}
			var tieni := {}
			for i in n:
				var ok := obiettivo(i) == 0
				quanti[str(i)] = 1 if ok else 2
				tieni[str(i)] = ok
			_spingi({"k": "scegli_destini", "idx": 0, "lettera": lettera, "quanti": quanti, "tieni": tieni})
		2:
			_nuovo_atto()

func _rimuovi_edificio(id: String, k: int) -> void:
	var e: Dictionary = s["mappa"][id]["edifici"][k]
	s["mappa"][id]["edifici"][k] = null
	var g: int = e["g"]
	if g == lib():
		if e["t"] == "citta":
			C()["citta_libere"] = int(C()["citta_libere"]) + 1
		else:
			G(lib())["porti"] += 1
		return
	if e["t"] == "citta":
		_restituisci_citta(g)
	else:
		G(g)["porti"] += 1
	_ev({"tipo": "distruggi", "sis": id, "g": g, "cosa": e["t"]})

## Preparazione degli Atti II e III.
func _nuovo_atto() -> void:
	var n: int = s["n"]
	C()["atto"] = atto() + 1
	var a := atto()
	_log("— Atto %s —" % ["I", "II", "III"][a - 1])
	_ev({"tipo": "atto", "n": a})
	# A) segnalini ambizione: i più bassi girati
	for k in 3:
		s["segnalini"][k] = {"amb": "", "girato": false}
	var girati := 1 if a == 2 else 2
	for k in girati:
		s["segnalini"][2 - k]["girato"] = true
	# B) Corte
	for k in (3 if n == 2 else 4):
		_rifornisci_corte()
	C()["consiglio"] = "sessione"
	# C) Piaga sui portali senza Piaga né navi
	for id in s["mappa"]:
		if not Dati.is_portale(id):
			continue
		var vuoto := true
		for j in s["mappa"][id]["navi"].size():
			if s["mappa"][id]["navi"][j][0] + s["mappa"][id]["navi"][j][1] > 0:
				vuoto = false
		if vuoto:
			_metti_piaga(id, true)
	# D) Piaga sul pianeta del simbolo tirato in ogni settore
	var fe: Array = FACCE_EVENTO[_dado(6)]
	for sett in range(1, 7):
		var id := "%d%s" % [sett, fe[1]]
		var pg: Array = s["mappa"][id]["navi"][piaga()]
		if pg[0] + pg[1] == 0:
			_metti_piaga(id, true)
		else:
			for l in ["a", "b", "c"]:
				var id2 := "%d%s" % [sett, l]
				var pg2: Array = s["mappa"][id2]["navi"][piaga()]
				if pg2[0] + pg2[1] == 0:
					_metti_piaga(id2, true)
	# E) 2 giocatori: risorse di 2 settori tirati sui riquadri
	if n == 2:
		for z in 2:
			var sett := _dado(6) + 1
			for l in ["a", "b", "c"]:
				var t: String = Dati.TIPO["%d%s" % [sett, l]]
				var amb: String = {"materiale": "magnate", "carburante": "magnate", "armi": "generale", "reliquie": "custode", "psico": "empate"}[t]
				if riserva(t) > 0:
					s["virtuale"][amb] = int(s["virtuale"].get(amb, 0)) + 1
					s["fuori_risorse"][t] = int(s["fuori_risorse"].get(t, 0)) + 1
	s["capitolo"] = 1
	_spingi({"k": "capitolo"})
	_spingi({"k": "prepara_destini", "idx": 0})

func _metti_piaga(id: String, danneggiata: bool) -> void:
	if G(piaga())["navi"] <= 0:
		# si prende da chi ha più Trofei di Piaga
		var best := -1
		var bv := 0
		for i in s["n"]:
			var c := 0
			for t in G(i)["trofei"]:
				if int(t["g"]) == piaga():
					c += 1
			if c > bv:
				bv = c
				best = i
		if best < 0:
			return
		for q in G(best)["trofei"].size():
			if int(G(best)["trofei"][q]["g"]) == piaga():
				G(best)["trofei"].remove_at(q)
				break
		G(piaga())["navi"] += 1
	G(piaga())["navi"] -= 1
	s["mappa"][id]["navi"][piaga()][1 if danneggiata else 0] += 1

# ================================================================ dati per l'interfaccia
func info_destino(i: int) -> Dictionary:
	if not s.has("camp") or not C().has("destino"):
		return {}
	var d := destino(i)
	if d == "":
		return {}
	return {"destino": d, "nome": NOME_DESTINO[d], "lettera": C()["lettera"][i], "obiettivo": obiettivo(i),
		"carta": CARTA_DESTINO[d], "prep": carta_obiettivo(d)}

## Carta Preparazione del primo Atto di un Destino (l'obiettivo è sul retro).
func carta_obiettivo(d: String) -> String:
	var preps := []
	for n in NUM.get(d, {}):
		if Dati.info(NUM[d][n])[1] == "preparazione":
			preps.append(n)
	preps.sort()
	if preps.is_empty():
		return ""
	var primo_atto := 1 if d in DESTINI_A else (2 if d in DESTINI_B else 3)
	var k := clampi(atto() - primo_atto, 0, preps.size() - 1)
	return NUM[d][preps[k]]
