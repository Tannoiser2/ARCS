## Campagna «L'Orlo Infestato»: obiettivi, grandi ambizioni e segnalini di ogni Destino.
## È la classe finale del motore della campagna (main.gd e i test la istanziano).
## Alcune regole dei Destini sono semplificate: vedi campagna/PROGETTO_MOTORE.md.
class_name MotoreOrlo
extends MotoreCarteDestini

## Pila delle carte azione Fedeli (la prima è in cima)
const PILA_FEDELI := ["fed9", "fed8", "fed7", "fed6", "fed5", "fed4", "fed3", "fed2", "fed1"]
const DOTTRINE := ["458_08", "458_03", "458_01"]
const RISORSA_AMB := {"magnate": "materiale", "generale": "armi", "custode": "reliquie", "empate": "psico"}

func D() -> Dictionary:
	return C()["dest"]

func _lista(k: String) -> Array:
	if not D().has(k):
		D()[k] = []
	return D()[k]

func _conta(k: String, i := -1) -> int:
	var key := k if i < 0 else "%s_%d" % [k, i]
	return int(D().get(key, 0))

func _incr(k: String, n := 1, i := -1) -> void:
	var key := k if i < 0 else "%s_%d" % [k, i]
	D()[key] = int(D().get(key, 0)) + n

# ================================================================ utilità
func dichiarata(amb: String) -> bool:
	for k in 3:
		if s["segnalini"][k]["amb"] == amb:
			return true
	return false

## Chi è (da solo) in testa a un'ambizione, -1 se nessuno.
func in_testa(amb: String) -> int:
	var best := -1
	var bv := int(s["virtuale"].get(amb, 0))
	var pari := false
	for i in s["n"]:
		var v := punteggio_ambizione(i, amb)
		if v > bv:
			bv = v
			best = i
			pari = false
		elif v == bv and v > 0:
			pari = true
	return -1 if pari else best

func sta_vincendo(i: int) -> bool:
	for amb in Dati.AMBIZIONI:
		if dichiarata(amb) and in_testa(amb) == i:
			return true
	return false

func _vince(i: int, punti: Array, virt: int) -> bool:
	if punti[i] <= 0 or punti[i] <= virt:
		return false
	for j in punti.size():
		if j != i and punti[j] >= punti[i]:
			return false
	return true

func pianeti_di(i: int) -> Array:
	var out := []
	for id in s["mappa"]:
		if not Dati.is_portale(id) and controllo_eventi(id) == i:
			out.append(id)
	return out

func sistemi_di(i: int) -> Array:
	var out := []
	for id in s["mappa"]:
		if controllo_eventi(id) == i:
			out.append(id)
	return out

func _settore(id: String) -> int:
	return int(id.substr(0, 1))

func navi_leali(i: int) -> int:
	var t := 0
	for id in s["mappa"]:
		t += navi(id, i)
	return t

func gilde(i: int) -> Array:
	return G(i)["carte"].filter(func(c): return Dati.info(c)[1] == "gilda")

func lore(i: int) -> Array:
	var out: Array = G(i)["carte"].filter(func(c): return Dati.info(c)[1] == "lore")
	out.append_array(G(i).get("lore", []))
	return out

func conta_risorse(i: int, t: String) -> int:
	var n := 0
	for x in G(i)["risorse"]:
		if x == t:
			n += 1
	return n

func ha_oltraggio(i: int, t: String) -> bool:
	return G(i)["oltraggio"].has(t)

func fuorilegge(i: int) -> bool:
	return i >= 0 and i < s["n"] and not reggente(i)

func _pianeti_casuali(k: int, escludi := []) -> Array:
	var tutti := []
	for id in s["mappa"]:
		if not Dati.is_portale(id) and not (id in escludi) and not s["fuori"].has(_settore(id)):
			tutti.append(id)
	_mescola(tutti)
	return tutti.slice(0, k)

# ================================================================ operazioni speciali di preparazione e risoluzione
func _spec_destino(i: int, d: String, nome: String) -> void:
	match nome:
		"golem":
			D()["golem"] = _pianeti_casuali(5)
			_log("5 Golem dormienti compaiono sulla mappa.")
		"golem_desta", "evento_extra", "autorita", "economia", "ricollocare", \
		"mondi_ripristina", "rifornisci_portali", "guardia_eden", "stirpe_piaga", \
		"emissari", "lore_corte", "instabili_scarti", "profeta", "miglioria_gratis", "portale_rivelato", "mondi_annota", \
		"martello_completo", "mondi_riserva", "bottino_ok", "testimoni_psico", "arsenale_corte", "togli_reliquie_virtuali", \
		"togli_mat_carb_virtuali", "testimoni", "fine_confederazione":
			pass
		"golem_focolare", "golem_via":
			D()["golem_" + str(i)] = 0
		"cessate_il_fuoco":
			D()["cessate"] = {}
			for sett in range(1, 7):
				D()["cessate"][str(sett)] = "pace"
			_log("I segnalini Cessate il Fuoco mettono tutti i settori in Pace.")
		"dicerie":
			D()["dicerie_note"] = {}
		"confederazione":
			D()["membri"] = range(s["n"])
		"monopoli":
			D()["monopoli"] = {"materiale": -1, "carburante": -1, "armi": -1, "reliquie": -1, "psico": -1}
		"monopoli_liberi":
			D()["monopoli"] = {"materiale": -1, "carburante": -1, "armi": -1, "reliquie": -1, "psico": -1}
		"pila_fedeli":
			D()["fedeli"] = PILA_FEDELI.duplicate()
			D()["fedeli_attaccati"] = {}
		"fedeli_corte":
			# le carte Fedeli rimaste nella pila entrano nel mazzo delle azioni
			_lista("fedeli_mazzo").append_array(D().get("fedeli", []))
			D()["fedeli"] = []
		"dottrina":
			D()["dottrina"] = "fes"
		"dottrina_maggioranza":
			var z := 0
			var sa := 0
			for amb in D().get("ideali", {}):
				if D()["ideali"][amb] == "fez":
					z += 1
				else:
					sa += 1
			D()["dottrina"] = "fez" if z > sa else "fes"
		"ideali_via":
			D()["ideali"] = {}
		"ammiraglia":
			_metti_ammiraglia(i)
		"rifornisci_ammiraglia:6":
			_rifornisci_flotta(i, 6)
		"portale":
			D()["indizi"] = []
			D()["portale"] = ""
			D()["pellegrini"] = 0
		"pellegrini":
			D()["pellegrini"] = 0
		"stendardi":
			D()["stendardi"] = []
		"stendardi_via":
			D()["stendardi"] = []
		"frammenti":
			D()["frammenti"] = _pianeti_casuali(6)
			D()["frammenti_presi"] = 0
			D()["spezzati"] = []
			D()["mondi_edifici"] = 0
			_log("6 Frammenti del Martello compaiono sulla mappa.")
		"bottino_via":
			D()["bottino"] = []
		"seggi":
			D()["seggi"] = []
		"seggi_via":
			D()["seggi"] = []
		"togli_armi_virtuali":
			s["virtuale"].erase("generale")
		"oltraggio_signore":
			for t in ["armi", "reliquie"]:
				if not ha_oltraggio(i, t):
					_oltraggio(i, t)
		"bunker":
			var dove := []
			for x in edifici_di(i):
				if not x[0] in dove:
					dove.append(x[0])
			if dove.size() < 3:
				dove.append_array(_pianeti_casuali(3 - dove.size(), dove))
			D()["bunker"] = dove.slice(0, 3)
		"passaggi":
			D()["passaggi"] = []
		"cospirazioni":
			D()["cospirazioni"] = []
		_:
			if nome.begins_with("migliorie:"):
				D()["migliorie_" + str(i)] = nome.substr(10)

## Ammiraglia: una nave speciale che si mette in un sistema con un tuo spazioporto (o una tua nave).
func _metti_ammiraglia(i: int) -> void:
	var dove := ""
	if not porti_di(i).is_empty():
		dove = porti_di(i)[0][0]
	else:
		for id in s["mappa"]:
			if navi(id, i) > 0:
				dove = id
				break
	if dove == "":
		dove = "%dg" % (_dado(6) + 1)
	D()["ammiraglia_" + str(i)] = dove
	_metti_navi(i, dove, 1, false)
	_log("%s mette la sua Ammiraglia in %s." % [_nome(i), _desc_sis(dove)])

# ================================================================ ganci del motore
func _h_ambizione(amb: String, punti: Array, virt: int, guadagni: Array) -> void:
	super(amb, punti, virt, guadagni)
	if not _attiva():
		return
	if D().get("confed_amb", "") == amb:
		_confederazione(amb, punti, virt, guadagni)
	for i in s["n"]:
		if not _vince(i, punti, virt):
			continue
		var gp: int = guadagni[i]
		match destino(i):
			"siniscalco":
				if atto() == 1 and primo() == i:
					avanza(i, gp, "Consolidare il Potere Imperiale")
			"fondatore":
				if atto() == 1 and fuorilegge(i):
					avanza(i, 3, "Ispirare Fiducia nella Causa")
			"curatore":
				if atto() == 1:
					avanza(i, 2 * _conta("golem", i), "Trovare i Golem")
			"partigiano":
				if atto() == 1 and not ha_oltraggio(i, RISORSA_AMB.get(amb, "")):
					avanza(i, 2, "Fare Appello ai Propri Sostenitori")
			"credente":
				if atto() == 1:
					var pila: Array = D().get("fedeli", [])
					avanza(i, 10 if pila.is_empty() else Dati.punti(pila[0]), "Diffondere la Buona Novella")
				elif atto() == 2 and amb in D().get("ideali", {}):
					avanza(i, gp, "Sviluppare gli Ideali della Propria Fede")
			"voce":
				var pg := 0
				for id in s["mappa"]:
					if navi(id, i) > 0:
						pg += s["mappa"][id]["navi"][piaga()][0] + s["mappa"][id]["navi"][piaga()][1]
				avanza(i, pg, "Contattare un'Intelligenza Antica")
			"signore":
				if primo() == i:
					avanza(i, gp, "Consolidare il Potere Imperiale")
			"sopravvissuto":
				avanza(i, mini(G(i)["prigionieri"].size(), D().get("bunker", []).size()), "Tenere al Sicuro la Gente")
			"spettro":
				avanza(i, D().get("passaggi", []).size(), "Far Crollare i Portali dell'Orlo")
	# Cospiratore: Cospirazioni giuste
	var co := in_gioco_destino("cospiratore")
	if co >= 0 and atto() == 3:
		var primo_ := -1
		for i in s["n"]:
			if _vince(i, punti, virt):
				primo_ = i
		for x in D().get("cospirazioni", []):
			if x[0] == amb and int(x[1]) == primo_:
				avanza(co, 1, "Cospirazione giusta")
	# Giudice: parità al primo posto
	var gi := in_gioco_destino("giudice")
	if gi >= 0:
		var mx := virt
		for v in punti:
			mx = maxi(mx, v)
		var quanti := 0
		for v in punti:
			if v == mx and mx > 0:
				quanti += 1
		if virt == mx and mx > 0:
			quanti += 1
		if quanti >= 2:
			avanza(gi, 1, "Riequilibrare l'Orlo")

func _h_dopo_punteggio(calcolate: Dictionary) -> void:
	super(calcolate)
	if not _attiva():
		return
	var n: int = s["n"]
	for i in n:
		var vinte := 0
		for amb in calcolate:
			var pts := []
			for j in n:
				pts.append(punteggio_ambizione(j, amb))
			if _vince(i, pts, int(s["virtuale"].get(amb, 0))):
				vinte += 1
		match destino(i):
			"redentore":
				if not calcolate.has("custode") or _vinta(i, "custode"):
					avanza(i, 3, "Sottomettere i Custodi")
				if vinte > 0:
					var q := 0
					while _togli_risorsa(i, "reliquie"):
						q += 1
					if q > 0:
						avanza(i, 2 * q, "Frantumare le Reliquie")
			"egemone":
				D()["egemone_vinte"] = vinte

func _vinta(i: int, amb: String) -> bool:
	var pts := []
	for j in s["n"]:
		pts.append(punteggio_ambizione(j, amb))
	return _vince(i, pts, int(s["virtuale"].get(amb, 0)))

func _h_fine_capitolo() -> void:
	super()
	if not _attiva():
		return
	var n: int = s["n"]
	var cap: int = s["capitolo"]
	# Cospirazioni su ambizioni non calcolate
	var co := in_gioco_destino("cospiratore")
	if co >= 0:
		for x in D().get("cospirazioni", []):
			if not dichiarata(x[0]):
				avanza(co, 1, "Cospirazione su un'ambizione non calcolata")
		D()["cospirazioni"] = []
	for i in n:
		var a := atto()
		match destino(i):
			"siniscalco":
				if a == 2:
					if primo() == i:
						var sett := {}
						for id in s["mappa"]:
							if s["mappa"][id]["navi"][imp()][0] > 0:
								sett[_settore(id)] = true
						avanza(i, sett.size(), "Espandere l'Impero")
					avanza(i, C()["tesoro"].size(), "Garantire il Tributo all'Imperatore")
			"fondatore":
				if a == 1 and fuorilegge(i):
					avanza(i, sistemi_di(i).size(), "Sfidare il Pugno dell'Impero")
				elif a == 2:
					avanza(i, _citta_libere_non_imperiali(), "Proteggere la Libertà nell'Orlo")
			"magnate":
				if a == 2:
					avanza(i, _monopoli_di(i), "...E Tenerselo")
			"patrocinatore":
				if a == 2:
					var semi := {}
					for c in gilde(i):
						semi[Dati.info(c)[2]] = true
					avanza(i, semi.size(), "Collegarsi con le Gilde")
					var meno := 0
					for j in n:
						if j != i and gilde(j).size() < gilde(i).size():
							meno += 1
					avanza(i, meno, "Migliorare la Propria Posizione")
			"curatore":
				if a == 2:
					var meno := 0
					for j in n:
						if j != i and lore(j).size() < lore(i).size():
							meno += 1
					avanza(i, meno, "Costruire la Collezione Più Grande")
				elif a == 3:
					D()["golem_lore_%d" % i] = false
					D()["golem_via_%d" % i] = false
					if _conta("golem", i) > 0 and not lore(i).is_empty():
						var l: String = lore(i)[0]
						G(i)["carte"].erase(l)
						D()["golem_lore_%d" % i] = true
						_log("%s nutre i Golem con %s." % [_nome(i), Dati.nome_corte(l)])
					if _conta("golem", i) > 0:
						_incr("golem", -1, i)
						D()["golem_via_%d" % i] = true
			"ammiraglio":
				if a == 2 and reggente(i):
					var k := 0
					for id in s["mappa"]:
						if not Dati.is_portale(id) and controllo(id) == imp():
							k += 1
					avanza(i, k, "Ampliare i Possedimenti della Marina")
			"egemone":
				if a == 2:
					var b: int = D().get("stendardi", []).size()
					avanza(i, b * (2 if int(D().get("egemone_vinte", 0)) > 0 else 1), "Piantare gli Stendardi del Nuovo Ordine")
			"pirata":
				if a == 2:
					var bott: Array = D().get("bottino", [])
					avanza(i, bott.size(), "Accrescere il Bottino di Risorse")
					var tipi := 0
					for t in Dati.RISORSE:
						var mio := bott.count(t)
						var piu := mio > 0
						for j in n:
							if j != i and conta_risorse(j, t) >= mio:
								piu = false
						if piu:
							tipi += 1
					avanza(i, 2 * tipi, "Umiliare i Rivali con le Ricchezze")
			"pacifista":
				if a == 2:
					if G(i)["trofei"].is_empty():
						avanza(i, 2, "Impegnarsi nel Pacifismo")
					if G(i)["prigionieri"].is_empty():
						avanza(i, 1, "Impegnarsi nel Pacifismo")
			"paciere":
				if a == 2:
					avanza(i, conta_risorse(i, "armi"), "Limitare la Disponibilità di Armi")
					avanza(i, pianeti_di(i).filter(func(x): return Dati.TIPO[x] == "armi").size(), "Controllare i Fabbricanti d'Armi")
			"castellano":
				if a == 2:
					var seggi := _seggi_di(i)
					avanza(i, 2 * seggi.size(), "Controllare i Seggi dei Feudi")
					var citta := 0
					for sett in _feudi_di(i):
						for id in s["mappa"]:
							if _settore(id) == sett:
								for e in s["mappa"][id]["edifici"]:
									if e != null and e["t"] == "citta":
										citta += 1
					avanza(i, citta, "Signoreggiare sui Feudi")
			"signore":
				var tipi := 0
				var tipi_p := {}
				for t in G(i)["oltraggio"]:
					if conta_risorse(i, t) > 0:
						tipi += 1
				for id in pianeti_di(i):
					if ha_oltraggio(i, Dati.TIPO[id]):
						tipi_p[Dati.TIPO[id]] = true
				avanza(i, tipi + 2 * tipi_p.size(), "Governare e Controllare con la Paura")
			"guardiano":
				if not dichiarata("tiranno") or in_testa("tiranno") == i:
					avanza(i, conta_risorse(i, "materiale") + conta_risorse(i, "carburante"), "Restituire alla Terra")
				if not _sostituta_dichiarata("eden") or _vinta(i, "magnate"):
					avanza(i, pianeti_di(i).filter(func(x): return Dati.TIPO[x] in ["materiale", "carburante"]).size(), "Custodire lo Splendore dell'Orlo")
			"naturalista":
				if _sostituta_dichiarata("stirpe") and not _vinta(i, "empate"):
					continue
				var k := 0
				for id in sistemi_di(i):
					if s["mappa"][id]["navi"][piaga()][0] > 0:
						k += 1
				avanza(i, k, "Vivere nel Giardino")
			"spettro":
				var pas: Array = D().get("passaggi", [])
				if not pas.is_empty() and controllo_eventi(pas[0]) == i:
					avanza(i, pas.size(), "Far Crollare i Portali dell'Orlo")
	D()["sostitute"] = {}
	D()["confed_amb"] = ""
	# grandi ambizioni dell'Atto III (si verificano qui, prima che i segnalini tornino)
	if atto() == 3:
		var gr := {}
		for i in n:
			if C()["lettera"][i] == "C":
				continue
			var fatte := 0
			for k in 2:
				if _grande_ambizione(i, k):
					fatte += 1
			gr[str(i)] = fatte
		for i in n:
			if ha_carta(i, "433_05") and C()["lettera"][i] != "C":
				var po: String = D().get("portale", "")
				if po != "" and controllo_eventi(po) == i:
					gr[str(i)] = mini(2, int(gr.get(str(i), 0)) + 1)
		D()["grandi_" + str(cap)] = gr
		for i in n:
			var fatte: int = gr.get(str(i), 0)
			if fatte > 0:
				var pt: int = GRANDI[clampi(cap, 1, 4)][fatte - 1]
				G(i)["potere"] += pt
				_log("%s realizza %s e ottiene %d Potere." % [_nome(i), "una grande ambizione" if fatte == 1 else "entrambe le grandi ambizioni", pt])
				_ev({"tipo": "grande_ambizione", "g": i, "n": fatte})

## Le grandi ambizioni si calcolano in _h_fine_capitolo.
## (Le ambizioni sostitute valgono solo per il capitolo in cui sono dichiarate.)
func _grande_ambizione(i: int, k: int) -> bool:
	var cap: int = s["capitolo"]
	var n: int = s["n"]
	match destino(i):
		"siniscalco":
			if k == 0:
				if not reggente(i):
					return false
				for j in n:
					if fuorilegge(j):
						for x in citta_di(j):
							if s["mappa"][x[0]]["navi"][imp()][0] <= 0:
								return false
				return true
			return primo() == i and C()["tesoro"].size() > cap
		"fondatore":
			return _citta_libere_non_imperiali() >= (3 if k == 0 else 7)
		"magnate":
			return _monopoli_di(i) >= (1 if k == 0 else 2)
		"patrocinatore":
			if k == 0:
				var semi := {}
				for c in gilde(i):
					semi[Dati.info(c)[2]] = true
				return semi.size() > cap
			var g := 0
			for slot in s["corte"]:
				if Dati.info(slot["c"])[1] == "gilda":
					g += 1
			return g * 2 > s["corte"].size()
		"curatore":
			return D().get("golem_lore_%d" % i, false) if k == 0 else D().get("golem_via_%d" % i, false)
		"partigiano":
			if k == 0:
				for j in n:
					if j != i and gilde(j).size() >= gilde(i).size():
						return false
				return true
			return s["iniz"] == i
		"ammiraglio":
			if k == 1:
				return false
			if not reggente(i) or pianeti_di(i).size() < 9:
				return false
			for j in n:
				if j != i and navi_leali(j) >= navi_leali(i):
					return false
			return true
		"credente":
			var ideali: Dictionary = D().get("ideali", {})
			var q := 0
			for x in s["segnalini"]:
				if x["amb"] != "" and x["amb"] in ideali:
					q += 1
			return q >= (2 if k == 0 else 3)
		"esploratore":
			if k == 0:
				var po: String = D().get("portale", "")
				return po != "" and controllo_eventi(po) == i
			return int(D().get("pellegrini", 0)) > cap
		"egemone":
			if k == 0:
				return not _rivale_vince(i, "tiranno")
			return D().get("stendardi", []).size() > cap
		"distruttore":
			if k == 0:
				if _rivale_vince(i, "generale"):
					return false
				for j in n:
					if G(j)["oltraggio"].is_empty():
						return false
				return true
			return int(D().get("mondi_edifici", 0)) > cap
		"pirata":
			var rif: String = D().get("rifugio", "")
			if D().get("bottino", []).size() < 2 or rif == "":
				return false
			if k == 0:
				for j in n:
					if j != i and ha_pezzi(rif, j):
						return false
				return true
			return ha_pezzi(rif, i)
		"voce":
			if k == 0:
				return not _rivale_vince(i, "generale")
			return _conta("fame") > cap
		"pacifista":
			if k == 0:
				return G(i)["trofei"].is_empty() and G(i)["prigionieri"].is_empty()
			var tot := 0
			for j in n:
				if j != i:
					tot += conta_risorse(j, "psico")
			return tot > conta_risorse(i, "psico")
		"paciere":
			return _settori_in_pace() >= (2 if k == 0 else 5)
		"castellano":
			if k == 0:
				return _feudi_di(i).size() > 0
			return _seggi_di(i).size() > cap
	return false

func _rivale_vince(i: int, amb: String) -> bool:
	if not dichiarata(amb):
		return false
	var t := in_testa(amb)
	return t >= 0 and t != i

func _h_dichiara(i: int, amb: String) -> void:
	super(i, amb)
	if not _attiva():
		return
	_scegli_sostituta(i, amb)
	if D().get("sponsor", "") == amb:
		D()["sponsor"] = ""
		if not C()["tesoro"].is_empty():
			_metti_risorsa_libera(i, C()["tesoro"].pop_front())
		for k in 3:
			if s["segnalini"][k]["amb"] == amb:
				G(i)["potere"] += valore_segnalino(k)[1]
				_log("Sponsor Imperiale: %s ottiene %d Potere." % [_nome(i), valore_segnalino(k)[1]])
				break
		if not reggente(i):
			C()["titolo"][i] = "reggente"
			_log("%s torna Reggente." % _nome(i))
	if destino(i) == "fondatore" and atto() >= 2 and C()["libretto"].has(carta("fondatore", 14)) and D().get("confed_amb", "") == "" \
			and D().get("membri", []).size() >= 2:
		D()["confed_amb"] = amb
		_log("%s aggiunge il segnalino Ambizione Confederazione a %s." % [_nome(i), Dati.NOME_AMBIZIONE[amb]])
	# Ideali: chi dichiara nel turno di una carta Fedele mette un Ideale del lato della Dottrina
	var cr := in_gioco_destino("credente")
	var fedele: bool = s.has("turno") and not s["turno"].is_empty() and Dati.is_fedele(str(s["turno"].get("c", "")))
	if cr >= 0 and atto() >= 2 and (fedele or i == cr):
		if not (D().get("ideali") is Dictionary):
			D()["ideali"] = {}
		if not D()["ideali"].has(amb):
			var lato: String = D().get("dottrina", "fes")
			if fedele:
				lato = Dati.seme(str(s["turno"]["c"]))
			D()["ideali"][amb] = lato
			_log("Un segnalino Ideale (%s) va sull'ambizione %s." % ["Zelo" if lato == "fez" else "Saggezza", Dati.NOME_AMBIZIONE[amb]])
	# Discepoli Fedeli: un punto azione in più
	if fedele and ha_carta(i, "993_29") and in_testa(amb) == i:
		s["turno"]["punti"] = int(s["turno"]["punti"]) + 1
		_log("Discepoli Fedeli: %s ottiene un punto azione in più." % _nome(i))
	var co := in_gioco_destino("cospiratore")
	if co >= 0 and atto() == 3 and i != co:
		# il Cospiratore scommette su chi vincerà l'ambizione appena dichiarata
		var t := in_testa(amb)
		if t < 0:
			t = i
		_lista("cospirazioni").append([amb, t])

func _h_iniziativa(i: int) -> void:
	super(i)
	if _attiva() and destino(i) == "partigiano" and atto() == 1:
		avanza(i, 1, "Seminare Discordia nell'Orlo")

func _h_carta_giocata(i: int, c: String, modo: String) -> void:
	super(i, c, modo)
	if _attiva() and destino(i) == "partigiano" and atto() == 2 and modo == "guida":
		avanza(i, 1, "Mostrare la Propria Guida")

func _h_trofeo(autore: int, b: int, cosa: String, id: String) -> void:
	super(autore, b, cosa, id)
	if not _attiva() or autore < 0 or autore >= s["n"]:
		return
	match destino(autore):
		"ammiraglio":
			if atto() == 1 and reggente(autore) and s["mappa"][id]["navi"][imp()][0] + s["mappa"][id]["navi"][imp()][1] > 0:
				avanza(autore, 1, "Dimostrare la Potenza della Marina")
			elif atto() == 2 and reggente(autore) and fuorilegge(b):
				avanza(autore, 2, "Schiacciare i Nemici dell'Impero")
		"pirata":
			if atto() >= 2 and cosa in ["citta", "porto"] and not Dati.is_portale(id):
				_lista("bottino").append(Dati.TIPO[id])
				_log("%s mette 1 %s nel Bottino Pirata." % [_nome(autore), Dati.NOME_RISORSA[Dati.TIPO[id]]])
	if destino(b) == "pirata" and b != autore:
		_scopri_diceria(autore)
	if b == lib() and autore in D().get("membri", []):
		D()["membri"].erase(autore)
		_log("%s non è più Membro della Confederazione." % _nome(autore))
	if b == piaga() or b >= s["n"]:
		return
	# Fame della Piaga: i pezzi Rivali distrutti dalla Piaga
	if autore == piaga():
		_incr("fame")

func _h_ruba(i: int, t: String) -> bool:
	if _attiva() and destino(i) == "pirata" and atto() >= 2:
		_lista("bottino").append(t)
		_log("%s mette 1 %s nel Bottino Pirata." % [_nome(i), Dati.NOME_RISORSA[t]])
		return true
	return super(i, t)

func _h_cattura(i: int, j: int) -> void:
	super(i, j)
	if not _attiva() or i < 0 or i >= s["n"]:
		return
	if destino(i) == "ammiraglio" and atto() == 2 and reggente(i) and reggente(j):
		avanza(i, 2, "Dominare i Reggenti Rivali")

func _h_acquisita(i: int, c: String) -> void:
	super(i, c)
	if not _attiva():
		return
	if destino(i) == "curatore" and atto() == 2 and Dati.info(c)[1] == "lore":
		avanza(i, 2, "Raccogliere il Sapere della Galassia")
	_h_acquisita_partigiana(i)
	# Sorveglianti delle Gilde: prendi una carta Gilda dal mazzo Corte
	if c == "428_23":
		for x in s["mazzo_corte"]:
			if Dati.info(x)[1] == "gilda":
				s["mazzo_corte"].erase(x)
				G(i)["carte"].append(x)
				_mescola(s["mazzo_corte"])
				_log("Sorveglianti delle Gilde: %s prende %s." % [_nome(i), Dati.nome_corte(x)])
				break
	if D().has("corti"):
		D()["corti"].erase(c)
	# carte Fedeli attaccate alla carta acquisita: vanno in mano
	var att: Dictionary = D().get("fedeli_attaccati", {})
	if att.has(c):
		G(i)["mano"].append(att[c])
		_lista("fedeli_mazzo").append(att[c])
		_log("%s prende in mano la carta azione %s." % [_nome(i), Dati.nome_carta_azione(att[c])])
		att.erase(c)

func _h_preludio_gilda(i: int, c: String) -> void:
	super(i, c)
	if _attiva() and destino(i) == "patrocinatore" and atto() == 1:
		avanza(i, 3, "Dimostrare il Proprio Valore ai Sorveglianti")

func _h_spendi(i: int, r: String) -> void:
	super(i, r)
	if _attiva() and destino(i) == "pacifista" and atto() == 2 and r == "psico" and dichiarata("empate"):
		avanza(i, 1, "Diffondere l'Empatia")

func _h_navi_imperiali(q: int, id: String) -> void:
	super(q, id)
	if not _attiva():
		return
	var am := in_gioco_destino("ammiraglio")
	if am >= 0 and atto() == 1 and reggente(am) and sta_vincendo(am):
		avanza(am, q, "Dimostrarsi un Nuovo Ammiraglio")

## Fine del turno di un giocatore: segnalini dei Destini che si prendono o si mettono sulla mappa.
func _h_fine_turno(i: int) -> void:
	super(i)
	if not _attiva():
		return
	var d := destino(i)
	match d:
		"curatore":
			var gl: Array = D().get("golem", [])
			for id in gl.duplicate():
				if navi(id, i) > 0:
					gl.erase(id)
					_incr("golem", 1, i)
					_log("%s risveglia un Golem in %s." % [_nome(i), _desc_sis(id)])
		"esploratore":
			if atto() == 2 and D().has("indizi"):
				var ind: Array = D()["indizi"]
				if D()["portale"] == "":
					for id in s["mappa"]:
						if navi(id, i) > 0 and not _settore(id) in ind and not s["fuori"].has(_settore(id)):
							ind.append(_settore(id))
							_log("%s trova un Indizio nel settore %d." % [_nome(i), _settore(id)])
							if obiettivo(i) > 1:
								avanza(i, 1, "Trovare il Portale")
							if ind.size() >= 4:
								D()["portale"] = id
								_log("Il Portale si apre in %s!" % _desc_sis(id))
								avanza(i, 8, "Trovare il Portale")
							break
			elif atto() == 3:
				var po: String = D().get("portale", "")
				if po != "" and navi(po, i) > 0:
					_incr("pellegrini")
		"egemone":
			var st: Array = _lista("stendardi")
			if st.size() < 8:
				for id in pianeti_di(i):
					if not id in st:
						st.append(id)
						_log("%s pianta uno Stendardo in %s." % [_nome(i), _desc_sis(id)])
						break
		"distruttore":
			var fr: Array = D().get("frammenti", [])
			for id in fr.duplicate():
				if navi(id, i) > 0:
					fr.erase(id)
					_incr("frammenti_presi")
					_log("%s raccoglie un Frammento del Martello." % _nome(i))
					if atto() == 2:
						avanza(i, 1, "Riparare il Martello Planetario")
			if _conta("frammenti_presi") >= 6 and int(D().get("martello_cap", 0)) != s["capitolo"]:
				for id in s["mappa"]:
					if Dati.is_portale(id) or navi(id, i) <= 0 or id in D().get("spezzati", []):
						continue
					var altri := false
					for e in s["mappa"][id]["edifici"]:
						if e != null and e["g"] != i:
							altri = true
					if not altri:
						continue
					D()["martello_cap"] = s["capitolo"]
					for k in s["mappa"][id]["edifici"].size():
						if s["mappa"][id]["edifici"][k] != null:
							_rimuovi_edificio(id, k)
							_incr("mondi_edifici")
					_lista("spezzati").append(id)
					_log("%s riduce in polvere %s con il Martello Planetario!" % [_nome(i), _desc_sis(id)])
					if atto() == 2:
						avanza(i, 6, "Ridurre un Pianeta in Polvere")
					break
		"pirata":
			if atto() >= 2 and D().get("rifugio", "") == "":
				for id in s["mappa"]:
					if not Dati.is_portale(id) and navi(id, i) > 0:
						D()["rifugio"] = id
						break
		"sopravvissuto":
			_costruisci_bunker(i)
		"castellano":
			var sg: Array = _lista("seggi")
			if sg.size() < 5:
				for x in citta_di(i):
					if not x[0] in sg:
						sg.append(x[0])
						_log("%s reclama un Seggio in %s." % [_nome(i), _desc_sis(x[0])])
						break
		"spettro":
			var pas: Array = _lista("passaggi")
			for id in s["mappa"]:
				if Dati.is_portale(id) and navi(id, i) > 0 and not id in pas:
					pas.append(id)
					_log("%s apre un Passaggio in %s." % [_nome(i), _desc_sis(id)])
					break
	# Stendardi e Seggi tornano a chi conquista il sistema
	var st2: Array = D().get("stendardi", [])
	var eg := in_gioco_destino("egemone")
	if eg >= 0 and i != eg:
		for id in st2.duplicate():
			if controllo_eventi(id) == i:
				st2.erase(id)

## Navi Spora / Guide delle Spore: una Piaga in un sistema con tue navi senza Piaga.
func _metti_spora(i: int) -> void:
	for id in s["mappa"]:
		if navi(id, i) > 0 and s["mappa"][id]["navi"][piaga()][0] + s["mappa"][id]["navi"][piaga()][1] == 0:
			if G(piaga())["navi"] <= 0:
				return
			_metti_piaga(id, false)
			_log("%s diffonde la Piaga in %s." % [_nome(i), _desc_sis(id)])
			if destino(i) == "voce" and atto() == 2:
				avanza(i, 1, "Diffondere le Spore di Nuova Vita")
			return

func _crisi_piaga() -> void:
	var so := in_gioco_destino("sopravvissuto")
	if so >= 0:
		for id in D().get("bunker", []):
			if s["mappa"][id]["navi"][piaga()][0] + s["mappa"][id]["navi"][piaga()][1] > 0:
				avanza(so, 1, "Proteggere dalla Piaga")
	super()

# ================================================================ Editti e Leggi dei Destini
func _p_editti(p: Dictionary) -> void:
	if not p.has("lista") and _attiva():
		_log("— Editti —")
		_ev({"tipo": "editti"})
		var l: Array = C()["editti"].duplicate()
		l.sort()
		if C()["libretto"].has("463_13") and l.has("03"):
			l.erase("03")
			l.append("quorum")
		for c in C()["libretto"]:
			if Dati.info(c)[1] == "editto" and not c in l:
				l.append(c)
		p["lista"] = l
		p["idx"] = 0
	super(p)

func _editto_extra(c: String) -> void:
	var n: int = s["n"]
	if c == "quorum":
		_quorum()
		return
	if _editto_extra2(c):
		return
	match c:
		"479_18":
			# Usare le Fonderie Imperiali: l'Ammiraglio sostituisce navi Leali con navi Imperiali
			var am := in_gioco_destino("ammiraglio")
			if am < 0 or not reggente(am):
				return
			var q := 0
			for x in porti_di(am):
				var id: String = x[0]
				if s["mappa"][id]["navi"][am][0] > 0 and G(imp())["navi"] > 0:
					s["mappa"][id]["navi"][am][0] -= 1
					G(am)["navi"] += 1
					s["mappa"][id]["navi"][imp()][0] += 1
					G(imp())["navi"] -= 1
					q += 1
					_h_navi_imperiali(1, id)
			if q > 0:
				_log("Usare le Fonderie Imperiali: %s sostituisce %d navi Leali con navi Imperiali." % [_nome(am), q])
		"427_09":
			_prendi_monopoli()
		"428_13":
			var pa := in_gioco_destino("patrocinatore")
			if pa < 0:
				return
			var semi := {}
			for g in gilde(pa):
				semi[Dati.info(g)[2]] = true
			for j in ordine_da(s["iniz"]):
				if j == pa:
					continue
				for g in gilde(j):
					if not semi.has(Dati.info(g)[2]):
						if G(j)["agenti"] > 0 and gilde(j).size() <= 2:
							G(j)["agenti"] -= 1
							C()["favori"][pa][str(j)] = int(C()["favori"][pa].get(str(j), 0)) + 1
							_log("Richiesta del Patrocinatore: %s dà un Favore a %s." % [_nome(j), _nome(pa)])
						else:
							G(j)["carte"].erase(g)
							G(pa)["carte"].append(g)
							if G(pa)["agenti"] > 0:
								G(pa)["agenti"] -= 1
								C()["favori"][j][str(pa)] = int(C()["favori"][j].get(str(pa), 0)) + 1
							_log("Richiesta del Patrocinatore: %s dà %s a %s." % [_nome(j), Dati.nome_corte(g), _nome(pa)])
						return
		"429_00":
			for i in n:
				for z in _conta("golem", i):
					var gl := gilde(i)
					if not gl.is_empty():
						G(i)["carte"].erase(gl[0])
						_log("I Golem consumano %s di %s." % [Dati.nome_corte(gl[0]), _nome(i)])
		"442_01":
			for i in n:
				var k := 0
				for id in s["mappa"]:
					if not _settore_in_pace(_settore(id)):
						continue
					var c_ := controllo(id)
					if c_ == i or (c_ == imp() and primo() == i and C()["politica"] == "pace"):
						k += 1
				if k > 0:
					G(i)["potere"] += 2 * k
					_log("Dividendi della Pace: %s ottiene %d Potere." % [_nome(i), 2 * k])
		"472_00":
			if dichiarata("empate"):
				for i in n:
					for t in G(i)["oltraggio"]:
						while _togli_risorsa(i, t):
							pass
					if not ha_oltraggio(i, "psico") and riserva("psico") > 0:
						_ottieni(i, "psico")
				_log("Rimprovero degli Empati.")
		"444_01":
			var re := in_gioco_destino("redentore")
			if re >= 0 and dichiarata("custode") and in_testa("custode") != re:
				var p1 := 0
				for k in 3:
					if s["segnalini"][k]["amb"] == "custode":
						p1 += valore_segnalino(k)[0]
				G(re)["potere"] -= p1
				_log("Rimprovero dei Custodi: %s perde %d Potere." % [_nome(re), p1])
		"450_00":
			var si := in_gioco_destino("signore")
			if si >= 0:
				var perdita: int = [0, 1, 3, 6, 8, 10][mini(5, G(si)["oltraggio"].size())]
				if perdita > 0:
					G(si)["potere"] -= perdita
					_log("L'Orlo rifiuta il Signore Supremo: %s perde %d Potere." % [_nome(si), perdita])
		"488_00":
			var ca := in_gioco_destino("castellano")
			if ca >= 0:
				var f := _feudi_di(ca).size()
				if f > 0:
					G(ca)["potere"] += 3 * f
					_log("I Signori ottengono Potere: %s ottiene %d Potere." % [_nome(ca), 3 * f])

## Protettori Imperiali: niente Crisi della Piaga nei sistemi controllati dall'Impero.
func _crisi_esclusa(id: String) -> bool:
	return _attiva() and C()["libretto"].has("463_18") and s["mappa"][id]["navi"][imp()][0] > 0

## Supremazia delle Gilde: nel calcolo del Potere le carte Gilda contano doppio.
func simboli(i: int, t: String) -> int:
	var n: int = super(i, t)
	if _attiva() and i >= 0 and i < s["n"] and C()["libretto"].has("428_01"):
		for c in gilde(i):
			if Dati.info(c)[2] == t:
				n += 1
	return n

## Tassare: Economia Chiusa, Legge Feudale, Sistema di Controllo dell'Ammiraglia, Contrabbandieri Pirati.
func _bersagli_tassa(i: int, solo_leali: bool) -> Array:
	var out: Array = super(i, solo_leali)
	if not _attiva() or i < 0 or i >= s["n"]:
		return out
	var ma := in_gioco_destino("magnate")
	if ma >= 0 and ma != i and reggente(ma) and reggente(i) and C()["libretto"].has("427_00"):
		out = out.filter(func(x): return s["mappa"][x[0]]["navi"][imp()][0] <= 0 or s["mappa"][x[0]]["edifici"][x[1]]["g"] == i)
	if solo_leali:
		return out
	var tassate: Array = s["turno"]["tassate"] if s.has("turno") and s["turno"].has("tassate") else []
	var extra := func(id: String) -> void:
		var ed: Array = s["mappa"][id]["edifici"]
		for k in ed.size():
			var e = ed[k]
			if e != null and e["t"] == "citta" and e["g"] != i and not ("%s:%d" % [id, k]) in tassate:
				var x := [id, k]
				if not x in out:
					out.append(x)
	var feudi := _feudi_di(i) if C()["libretto"].has("488_09") else []
	var am := ammiraglia(i)
	var settore_am := _settore(am) if am != "" and Dati.is_portale(am) and migliorie(i).has("controllo") else -1
	for id in s["mappa"]:
		if not in_gioco(id) or Dati.is_portale(id):
			continue
		if _settore(id) in feudi or _settore(id) == settore_am or (ha_carta(i, "487_07") and navi(id, i) > 0):
			extra.call(id)
	return out

# ================================================================ ambizioni nuove
## Guardia dell'Eden (al posto di Magnate) e Stirpe della Piaga (al posto di Empate).
func punteggio_ambizione(i: int, amb: String) -> int:
	if _attiva() and i >= 0 and i < s["n"]:
		var so: String = D().get("sostitute", {}).get(amb, "")
		if so == "eden":
			return pianeti_di(i).filter(func(x): return Dati.TIPO[x] in ["materiale", "carburante"]).size()
		if so == "stirpe":
			return sistemi_di(i).filter(func(x): return s["mappa"][x]["navi"][piaga()][0] > 0).size()
	return super(i, amb)

func _sostituta_dichiarata(so: String) -> bool:
	var amb := "magnate" if so == "eden" else "empate"
	return dichiarata(amb) and D().get("sostitute", {}).get(amb, "") == so

func nome_ambizione(amb: String) -> String:
	if _attiva():
		var so: String = D().get("sostitute", {}).get(amb, "")
		if so == "eden":
			return "Guardia dell'Eden"
		if so == "stirpe":
			return "Stirpe della Piaga"
	return Dati.NOME_AMBIZIONE[amb]

## Chi dichiara Magnate o Empate sceglie l'ambizione nuova se gli conviene di più.
func _scegli_sostituta(i: int, amb: String) -> void:
	var regole := {"magnate": ["473_00", "eden"], "empate": ["446_00", "stirpe"]}
	if not regole.has(amb) or not C()["libretto"].has(regole[amb][0]):
		return
	if not D().has("sostitute"):
		D()["sostitute"] = {}
	if D()["sostitute"].has(amb):
		return
	var prima := punteggio_ambizione(i, amb)
	D()["sostitute"][amb] = regole[amb][1]
	var dopo := punteggio_ambizione(i, amb)
	if dopo < prima or (dopo == prima and destino(i) not in ["guardiano", "naturalista"]):
		D()["sostitute"].erase(amb)
	else:
		_log("%s dichiara invece %s." % [_nome(i), nome_ambizione(amb)])

## Confederazione: i Membri sommano i loro valori; se vince la Confederazione il Potere si divide.
func _confederazione(amb: String, punti: Array, virt: int, guadagni: Array) -> void:
	var membri: Array = D().get("membri", [])
	var p1 := 0
	var p2 := 0
	for k in 3:
		if s["segnalini"][k]["amb"] == amb:
			var vs := valore_segnalino(k)
			p1 += vs[0]
			p2 += vs[1]
	var conf := 0
	for j in membri:
		conf += int(punti[j])
	var best_altro := virt
	var chi := -1
	var pari := false
	for j in s["n"]:
		if j in membri:
			continue
		if punti[j] > best_altro:
			best_altro = punti[j]
			chi = j
			pari = false
		elif punti[j] == best_altro and punti[j] > 0:
			pari = true
	for j in guadagni.size():
		guadagni[j] = 0
	if conf > best_altro and not membri.is_empty():
		var quota := (p1 + p2) / membri.size()
		for j in membri:
			guadagni[j] = quota
		_log("La Confederazione vince %s: %d Potere a ogni Membro." % [Dati.NOME_AMBIZIONE[amb], quota])
		var fo := in_gioco_destino("fondatore")
		if fo >= 0 and atto() == 2:
			avanza(fo, 2 * membri.size(), "Distribuire il Potere con Equità")
	elif chi >= 0 and not pari and best_altro > conf:
		guadagni[chi] = 2 * (p1 + p2)
		_log("%s batte la Confederazione e ottiene il doppio del Potere." % _nome(chi))

# ================================================================ Ammiraglie
## L'Ammiraglia segue la flotta: se nel suo sistema non restano navi, passa dove il giocatore ne ha di più.
func ammiraglia(i: int) -> String:
	var k := "ammiraglia_" + str(i)
	if not D().has(k):
		return ""
	var id: String = D()[k]
	if id != "" and navi(id, i) > 0:
		return id
	var best := ""
	var bv := 0
	for x in s["mappa"]:
		if navi(x, i) > bv:
			bv = navi(x, i)
			best = x
	D()[k] = best
	return best

func migliorie(i: int) -> Dictionary:
	var out := {}
	for parte in str(D().get("migliorie_" + str(i), "")).split(","):
		if "=" in parte:
			var kv := parte.split("=")
			out[kv[0]] = kv[1]
	return out

## Raggio Traente: chi attacca l'Ammiraglia non può razziare.
func _razzia_permessa(id: String, j: int) -> bool:
	if _attiva() and j < s["n"] and migliorie(j).has("raggio") and ammiraglia(j) == id:
		return false
	return super(id, j)

## Sistema Difensivo: l'Ammiraglia intercetta con 1 colpo per ogni spazioporto sulla sua plancia.
func _intercetta_extra(j: int, id: String) -> int:
	if not _attiva() or j >= s["n"] or ammiraglia(j) != id:
		return 0
	var k := 0
	for m_ in migliorie(j).values():
		if m_ == "porto":
			k += 1
	return k if migliorie(j).has("difesa") else 0

# ================================================================ Monopoli, Confederazione, Feudi, Pace
func _prendi_monopoli() -> void:
	if not D().has("monopoli"):
		return
	var mono: Dictionary = D()["monopoli"]
	var ma := in_gioco_destino("magnate")
	for t in mono:
		var in_gioco_ := 5 - int(s.get("fuori_risorse", {}).get(t, 0))
		for i in s["n"]:
			if int(mono[t]) != i and conta_risorse(i, t) * 2 > in_gioco_:
				mono[t] = i
				_log("%s ottiene il Monopolio: %s." % [_nome(i), Dati.NOME_RISORSA[t]])
				if i == ma:
					avanza(i, 1, "Accaparrarsi il Mercato")
				break

func _monopoli_di(i: int) -> int:
	var k := 0
	for t in D().get("monopoli", {}):
		if int(D()["monopoli"][t]) == i:
			k += 1
	return k

func _citta_libere_non_imperiali() -> int:
	var k := 0
	for id in s["mappa"]:
		for e in s["mappa"][id]["edifici"]:
			if e != null and e["g"] == lib() and e["t"] == "citta" and controllo(id) != imp():
				k += 1
	return k

func _seggi_di(i: int) -> Array:
	return D().get("seggi", []).filter(func(id): return controllo_eventi(id) == i)

func _feudi_di(i: int) -> Array:
	var out := []
	if destino(i) != "castellano":
		return out
	for id in D().get("seggi", []):
		if not _settore(id) in out:
			out.append(_settore(id))
	return out

## Un settore è in Pace se nessun suo sistema ha navi di due giocatori diversi.
func _settore_in_pace(sett: int) -> bool:
	if s["fuori"].has(sett):
		return false
	if D().has("cessate"):
		return D()["cessate"].get(str(sett), "guerra") == "pace"
	for id in s["mappa"]:
		if _settore(id) != sett:
			continue
		var q := 0
		for j in s["n"]:
			if navi(id, j) > 0:
				q += 1
		if q >= 2:
			return false
	return true

func _settori_in_pace() -> int:
	var k := 0
	for sett in range(1, 7):
		if _settore_in_pace(sett):
			k += 1
	return k

# ================================================================ carte azione Fedeli
func _lati_fedeli(i: int) -> Array:
	if _attiva():
		for c in DOTTRINE:
			if C()["libretto"].has(c):
				return [D().get("dottrina", "fes")]
	return super(i)

## Fede Pluralista: guidando con una carta Fedele si dichiara qualsiasi ambizione, come con un 7.
func _valore_dichiarazione(c: String) -> int:
	if _attiva() and Dati.is_fedele(c) and C()["libretto"].has("458_17"):
		return 7
	return super(c)

## Le carte Fedeli entrate in gioco restano nel mazzo delle azioni.
func _mazzo_azioni() -> Array:
	var m: Array = super()
	if s.has("camp") and C().has("dest"):
		for c in D().get("fedeli_mazzo", []):
			if not c in m:
				m.append(c)
	return m

## Insegnare (Diffondere la Fede): influenzando, il Credente elimina la carta azione in fondo agli scarti e
## attacca la prima carta Fedele della pila a una carta Gilda della Corte di un seme dei pianeti delle sue città.
func _p_az_influenzare(p: Dictionary) -> void:
	var i: int = p["g"]
	# Corti Feudali: il Signore mette il segnalino Corte del suo Feudo sulla carta vuota che influenza
	if _attiva() and _ha_r(p) and destino(i) == "castellano" and C()["libretto"].has("488_01") and p["r"] is int:
		var k: int = p["r"]
		if k >= 0 and k < s["corte"].size():
			var slot: Dictionary = s["corte"][k]
			var vuota: bool = slot["ag"].max() == 0
			var feudi := _feudi_di(i)
			if vuota and slot["c"] != "consiglio" and not feudi.is_empty():
				if not D().has("corti"):
					D()["corti"] = {}
				var usati: Array = D()["corti"].values()
				for f in feudi:
					if not f in usati:
						D()["corti"][slot["c"]] = f
						_log("%s mette il segnalino Corte del Feudo %d su %s." % [_nome(i), f, Dati.nome_corte(slot["c"])])
						break
	if _attiva() and not _ha_r(p) and not p.has("insegnato") and ha_carta(i, carta("credente", 3)) and not D().get("fedeli", []).is_empty():
		p["insegnato"] = true
		var semi := {}
		for x in citta_di(i):
			semi[Dati.TIPO.get(x[0], "")] = true
		var bersaglio := ""
		for slot in s["corte"]:
			var cc: String = slot["c"]
			if Dati.info(cc)[1] == "gilda" and semi.has(Dati.info(cc)[2]) and not D()["fedeli_attaccati"].has(cc):
				bersaglio = cc
				break
		var fondo := -1
		for q in range(s["scarti_azioni"].size() - 1, -1, -1):
			if not Dati.is_evento(s["scarti_azioni"][q]):
				fondo = q
				break
		if bersaglio != "" and fondo >= 0:
			s["scarti_azioni"].remove_at(fondo)
			var f: String = D()["fedeli"].pop_front()
			D()["fedeli_attaccati"][bersaglio] = f
			_log("Insegnare: %s attacca %s a %s." % [_nome(i), Dati.nome_carta_azione(f), Dati.nome_corte(bersaglio)])
	super(p)

# ================================================================ Magnate nei Vertici
func _h_dono(da: int, a: int, cosa: String) -> void:
	super(da, a, cosa)
	if _attiva() and destino(a) == "magnate" and atto() == 1:
		avanza(a, 2, "Concludere Affari con i Rivali (%s)" % cosa)

func _opzioni_vertice_extra(i: int, fatte: Array) -> Array:
	var ops := []
	if destino(i) == "magnate" and atto() == 1 and not "esporta" in fatte:
		var tot := 0
		for x in G(i)["risorse"]:
			if x != "":
				tot += 1
		if tot >= 3:
			ops.append({"t": "Esporta nel Nucleo Galattico (scarta 3 risorse)", "v": "esporta"})
	# Accordi di Pace: Mediare la Pace in un settore in Guerra dove controlli almeno un sistema
	if D().has("cessate") and C()["libretto"].has("442_00"):
		for sett in range(1, 7):
			if D()["cessate"].get(str(sett), "") == "guerra" and not ("pace:%d" % sett) in fatte:
				var miei := 0
				for id in s["mappa"]:
					if _settore(id) == sett and controllo_eventi(id) == i:
						miei += 1
				if miei >= 1:
					ops.append({"t": "Media la Pace nel settore %d" % sett, "v": "pace:%d" % sett})
	return ops

func _esegui_vertice_extra(i: int, v: String) -> void:
	if v.begins_with("pace:"):
		D()["cessate"][v.substr(5)] = "pace"
		_log("%s media la Pace nel settore %s." % [_nome(i), v.substr(5)])
		return
	if v == "esporta":
		var q := 0
		for k in 6:
			if q < 3 and G(i)["risorse"][k] != "":
				G(i)["risorse"][k] = ""
				q += 1
		_log("%s esporta 3 risorse nel Nucleo Galattico." % _nome(i))
		avanza(i, 2, "Esportare nel Nucleo Galattico")

# ================================================================ IA e interfaccia
func _attiva() -> bool:
	return s.has("camp") and C().has("destino") and C()["destino"].size() == s["n"]

## Per l'IA: ogni casella di obiettivo vale come un po' di Potere (di più se la fine dell'Atto è vicina).
func valore_ia(i: int) -> float:
	if not _attiva() or i < 0 or i >= s["n"]:
		return 0.0
	var ob := obiettivo(i)
	if ob < 0:
		return 0.0
	var d := destino(i)
	var a := atto()
	var partenza: int = PARTENZA.get(d, {}).get(a, [ob, ob, ob])[s["n"] - 2]
	var fatto := partenza - ob
	var v := fatto * 4.0
	if ob == 0:
		v += 40.0 if C()["lettera"][i] != "C" else 400.0
	elif a < 3:
		# Potere che si perderebbe all'Intervallo
		v -= ob * 3.0 * (float(s["capitolo"]) / 3.0)
	return v

## Segnalini dei Destini sulla mappa, per la plancia 3D: sistema -> elenco di nomi.
func segnalini_mappa() -> Dictionary:
	var out := {}
	if not _attiva():
		return out
	var add := func(id: String, nome: String):
		if not out.has(id):
			out[id] = []
		out[id].append(nome)
	for id in D().get("golem", []):
		add.call(id, "Golem")
	for id in D().get("frammenti", []):
		add.call(id, "Frammento")
	for id in D().get("stendardi", []):
		add.call(id, "Stendardo")
	for id in D().get("seggi", []):
		add.call(id, "Seggio")
	for id in D().get("bunker", []):
		add.call(id, "Bunker")
	for id in D().get("passaggi", []):
		add.call(id, "Passaggio")
	for id in D().get("spezzati", []):
		add.call(id, "Mondo Spezzato")
	for i in s["n"]:
		var am := ammiraglia(i)
		if am != "":
			add.call(am, "Ammiraglia " + _nome(i))
	if D().get("portale", "") != "":
		add.call(D()["portale"], "Portale")
	return out

# ================================================================ Cessate il Fuoco
## In un settore in Pace si danneggia (tranne la Piaga e i propri pezzi) solo spendendo 1 Armi.
func _avversari(i: int, id: String) -> Array:
	var out: Array = super(i, id)
	if not _attiva() or i < 0 or i >= s["n"]:
		return out
	if D().has("cessate") and _settore_in_pace(_settore(id)) and conta_risorsa(i, "armi") == 0:
		out = out.filter(func(j): return j == piaga())
	# Giorno di Festa: nei Feudi i giocatori non si danneggiano a vicenda
	var festa := false
	for slot in s["corte"]:
		if VOX.get(slot["c"], "") == "festa":
			festa = true
	if festa and _settore(id) in _feudi_tutti():
		out = out.filter(func(j): return j >= s["n"])
	return out

func _h_battaglia(i: int, j: int, id: String) -> void:
	super(i, j, id)
	if not _attiva() or i >= s["n"]:
		return
	var sett := _settore(id)
	if D().has("cessate") and j != piaga() and _settore_in_pace(sett) and _togli_risorsa(i, "armi"):
		D()["cessate"][str(sett)] = "guerra"
		_log("%s spende 1 Armi: il settore %d entra in Guerra." % [_nome(i), sett])
	# Legge Feudale: Signore e Vassallo che si danneggiano nel Feudo Recano Oltraggio
	if C()["libretto"].has("488_09") and j < s["n"]:
		var signore := in_gioco_destino("castellano")
		if signore >= 0 and sett in _feudi_di(signore):
			if (i == signore and _vassallo(j, sett)) or (j == signore and _vassallo(i, sett)):
				for x in s["mappa"]:
					if _settore(x) != sett or Dati.is_portale(x):
						continue
					for e in s["mappa"][x]["edifici"]:
						if e != null and e["t"] == "citta" and not G(i)["oltraggio"].has(Dati.TIPO[x]):
							_oltraggio(i, Dati.TIPO[x])
	# Empatia per Tutti: chi danneggia su un pianeta di una risorsa che possiede Reca Oltraggio
	if C()["libretto"].has("472_03") and not Dati.is_portale(id):
		var tp: String = Dati.TIPO[id]
		if conta_risorsa(i, tp) > 0 and not G(i)["oltraggio"].has(tp):
			_oltraggio(i, tp)

# ================================================================ Legge Marziale e Ufficiali Imperiali
func _marziale() -> bool:
	return _attiva() and C()["libretto"].has("479_01")

## Chi può Comandare la Flotta Imperiale.
func comanda_flotta(i: int) -> bool:
	if not reggente(i):
		return false
	if not _marziale():
		return true
	if destino(i) == "ammiraglio" or ha_carta(i, "479_19"):
		return true
	for c in RINNEGATI:
		if ha_carta(i, c):
			return true
	return false

func controllo(id: String) -> int:
	var c: int = super(id)
	if not _attiva():
		return c
	var nave_imp: bool = s["mappa"][id]["navi"][imp()][0] > 0
	if not nave_imp:
		return c
	var t: int = int(s["turno"]["g"]) if s.has("turno") and not s["turno"].is_empty() else -1
	# Ufficiali Imperiali: nel tuo turno controlli tutti i sistemi dell'Impero
	if t >= 0 and t < s["n"] and reggente(t) and ha_carta(t, "479_19"):
		return t
	if c >= 0 and c < s["n"] and not comanda_flotta(c):
		return imp()
	return c

func controllo_eventi(id: String) -> int:
	var c := controllo(id)
	if c == imp():
		return primo() if primo() >= 0 and comanda_flotta(primo()) else -1
	return c

func _ferma_fionda(i: int, y: String) -> bool:
	# Navi Spora: la Piaga non ferma più la Fionda
	if ha_carta(i, "436_11"):
		var pg: Array = s["mappa"][y]["navi"][piaga()]
		if pg[0] + pg[1] > 0:
			var c := controllo(y)
			if c < 0 or c == i:
				return false
	if _marziale() and s["mappa"][y]["navi"][imp()][0] > 0 and not comanda_flotta(i):
		return true
	return super(i, y)

# ================================================================ Feudi e Corti Feudali
func _feudi_tutti() -> Array:
	var ca := in_gioco_destino("castellano")
	return _feudi_di(ca) if ca >= 0 else []

func _vassallo(j: int, sett: int) -> bool:
	for x in citta_di(j):
		if _settore(x[0]) == sett:
			return true
	var am := ammiraglia(j)
	return am != "" and _settore(am) == sett

func _corte_permessa(i: int, k: int) -> bool:
	if not _attiva() or not C()["libretto"].has("488_01"):
		return true
	var c: String = s["corte"][k]["c"]
	var corti: Dictionary = D().get("corti", {})
	if not corti.has(c):
		return true
	var sett: int = int(corti[c])
	var ca := in_gioco_destino("castellano")
	return (i == ca and sett in _feudi_di(ca)) or _vassallo(i, sett)


# ================================================================ Bunker del Sopravvissuto
func _costruisci_bunker(i: int) -> void:
	var bk: Array = _lista("bunker")
	if G(i)["agenti"] <= 1:
		return
	for id in pianeti_di(i):
		if id in bk:
			continue
		bk.append(id)
		G(i)["agenti"] -= 1
		var vittima := -1
		for j in s["n"]:
			if j != i and G(j)["agenti"] > 0 and (vittima < 0 or G(j)["agenti"] > G(vittima)["agenti"]):
				vittima = j
		if vittima >= 0:
			G(vittima)["agenti"] -= 1
			G(i)["prigionieri"].append(vittima)
			_h_cattura(i, vittima)
		_log("%s costruisce un Bunker in %s." % [_nome(i), _desc_sis(id)])
		return

## Un Bunker è distrutto quando un Rivale resta solo nel suo sistema dopo una battaglia contro il Sopravvissuto.
func _bunker_dopo_battaglia(i: int, j: int, id: String) -> void:
	var so := in_gioco_destino("sopravvissuto")
	if so < 0 or j != so or i == so:
		return
	var bk: Array = D().get("bunker", [])
	if id in bk and navi(id, so) == 0 and navi(id, i) > 0:
		bk.erase(id)
		if not G(so)["prigionieri"].is_empty():
			G(so)["prigionieri"].pop_back()
		_log("%s distrugge il Bunker in %s." % [_nome(i), _desc_sis(id)])

func _p_battaglia(p: Dictionary) -> void:
	var fase: String = p["fase"]
	super(p)
	if fase == "dopo" and _attiva():
		_bunker_dopo_battaglia(int(p["g"]), int(p["dif"]), str(p["sis"]))

# ================================================================ Dicerie sul Rifugio
## Chi ruba al Pirata in combattimento scopre una Diceria Vera (il settore o il simbolo del Rifugio).
func _scopri_diceria(j: int) -> void:
	if not D().has("dicerie_note"):
		return
	var note: Array = D()["dicerie_note"].get(str(j), [])
	for x in ["settore", "simbolo"]:
		if not x in note:
			note.append(x)
			_log("%s scopre una Diceria sul Rifugio Pirata." % _nome(j))
			break
	D()["dicerie_note"][str(j)] = note

## Fine dell'Atto III: i Rivali del Pirata provano a indovinare il pianeta del Rifugio.
func _dicerie_finali() -> void:
	var pi := in_gioco_destino("pirata")
	var rif: String = D().get("rifugio", "")
	if pi < 0 or rif == "" or not D().has("dicerie_note"):
		return
	var preso := false
	for j in ordine_da(s["iniz"]):
		if j == pi:
			continue
		var note: Array = D()["dicerie_note"].get(str(j), [])
		var scelta := ""
		for id in pianeti_di(j):
			var ok := true
			if "settore" in note and _settore(id) != _settore(rif):
				ok = false
			if "simbolo" in note and id.substr(1) != rif.substr(1):
				ok = false
			if ok and (scelta == "" or id == rif):
				scelta = id
		if scelta == rif and note.size() == 2:
			G(j)["potere"] += 10
			G(pi)["potere"] -= 10
			_log("%s scopre il Rifugio Pirata: +10 Potere, il Pirata perde 10 Potere." % _nome(j))
			preso = true
	if not preso:
		G(pi)["potere"] += 10
		_log("Nessuno trova il Rifugio Pirata: %s ottiene 10 Potere." % _nome(pi))

func _fine_campagna(i: int, perche: String) -> void:
	if _attiva() and not D().get("dicerie_fatte", false):
		D()["dicerie_fatte"] = true
		_dicerie_finali()
		# il vincitore può cambiare dopo le Dicerie
		if perche.begins_with("ha più Potere"):
			for j in s["n"]:
				if G(j)["potere"] > G(i)["potere"]:
					i = j
	super(i, perche)

# ================================================================ Editti dei Destini (seconda parte)
func _editto_extra2(c: String) -> bool:
	var n: int = s["n"]
	match c:
		"442_02":
			var pa := in_gioco_destino("paciere")
			if D().has("cessate") and C()["politica"] == "guerra" and pa >= 0 and not reggente(pa):
				for sett in range(1, 7):
					var imp_ := 0
					for id in s["mappa"]:
						if _settore(id) == sett and controllo(id) == imp():
							imp_ += 1
					if imp_ >= 2 and D()["cessate"].get(str(sett), "") == "pace":
						D()["cessate"][str(sett)] = "guerra"
						_log("L'Impero rifiuta la Pace: il settore %d entra in Guerra." % sett)
						break
		"463_03":
			if primo() < 0:
				return true
			var sp := ""
			for amb in Dati.AMBIZIONI:
				if not dichiarata(amb) and in_testa(amb) == primo():
					sp = amb
					break
			if sp == "":
				for amb in Dati.AMBIZIONI:
					if not dichiarata(amb):
						sp = amb
						break
			D()["sponsor"] = sp
			for r_ in G(primo())["risorse"]:
				if r_ != "":
					_togli_risorsa(primo(), r_)
					C()["tesoro"].append(r_)
					break
			if sp != "":
				_log("Sponsor Imperiale: %s sponsorizza l'ambizione %s." % [_nome(primo()), Dati.NOME_AMBIZIONE[sp]])
		"449_00":
			var gi := in_gioco_destino("giudice")
			if gi < 0:
				return true
			# il Giudice dichiara un'ambizione con parità al primo posto, col segnalino che costa meno
			var scelta := ""
			for amb in Dati.AMBIZIONI:
				if dichiarata(amb):
					continue
				var mx := 0
				var q := 0
				for j in n:
					var v := punteggio_ambizione(j, amb)
					if v > mx:
						mx = v
						q = 1
					elif v == mx and v > 0:
						q += 1
				if q >= 2:
					scelta = amb
					break
			var k_best := -1
			for k in 3:
				if s["segnalini"][k]["amb"] == "" and (k_best < 0 or valore_segnalino(k)[1] < valore_segnalino(k_best)[1]):
					k_best = k
			if scelta != "" and k_best >= 0:
				s["segnalini"][k_best]["amb"] = scelta
				var costo: int = valore_segnalino(k_best)[1]
				G(gi)["potere"] -= costo
				_log("Il Giudice fissa l'agenda: %s dichiara %s e perde %d Potere." % [_nome(gi), Dati.NOME_AMBIZIONE[scelta], costo])
				_ev({"tipo": "dichiara", "g": gi, "amb": scelta})
		"468_00":
			var so := in_gioco_destino("sopravvissuto")
			if so < 0:
				return true
			for j in ordine_da(s["iniz"]):
				if j == so or G(j)["potere"] <= G(so)["potere"]:
					continue
				var miei: int = G(so)["prigionieri"].count(j)
				var bunker_j := ""
				for id in D().get("bunker", []):
					if controllo_eventi(id) == j:
						bunker_j = id
				if miei == 0 or bunker_j == "":
					continue
				var tp: String = Dati.TIPO[bunker_j]
				if G(so)["oltraggio"].has(tp) or miei >= 2:
					while G(so)["prigionieri"].has(j):
						G(so)["prigionieri"].erase(j)
						G(j)["agenti"] += 1
					_log("Rilascio dei Prigionieri: %s restituisce i Prigionieri a %s." % [_nome(so), _nome(j)])
				else:
					_oltraggio(so, tp)
		"471_12", "471_01":
			var membri: Array = D().get("membri", [])
			if membri.is_empty():
				C()["libretto"].erase(c)
				return true
			var gia := false
			for slot in s["corte"]:
				if VOX.get(slot["c"], "") == "armistizio":
					gia = true
			if not gia:
				for a in ["471_10", "471_11"]:
					if s["mazzo_corte"].has(a) or s["scarti_corte"].has(a) or _indice_corte(a) < 0:
						s["mazzo_corte"].erase(a)
						s["scarti_corte"].erase(a)
						s["corte"].append({"c": a, "ag": _zeri_int(n)})
						_log("Appello all'Armistizio: l'Armistizio entra nella Corte.")
						break
		"477_06":
			var trovata := false
			for a in ["364_12", "x12", "428_16"]:
				if _indice_corte(a) >= 0:
					trovata = true
			if not trovata:
				for a in ["x12", "428_16", "364_12"]:
					if s["mazzo_corte"].has(a):
						s["mazzo_corte"].erase(a)
						s["corte"].append({"c": a, "ag": _zeri_int(n)})
						break
			C()["consiglio"] = "sessione"
			_log("Le Gilde condannano il terrore: Fiasco Diplomatico entra nella Corte e il Consiglio torna In Sessione.")
		"463_13":
			pass
		_:
			return false
	return true

## Quorum Imperiale: Tributo del Primo Reggente, Azione di chi ha più spazioporti, Politica di chi ha più città.
func _quorum() -> void:
	var pol: String = C()["politica"]
	if primo() >= 0:
		_riscuoti_tributo(primo(), pol)
	var best_p := _unico_massimo(func(j): return porti_di(j).size())
	if best_p >= 0:
		_azione_imperiale(best_p, pol)
	var best_c := _unico_massimo(func(j): return citta_di(j).size())
	if best_c >= 0:
		_spingi({"k": "governa", "g": best_c, "solo_politica": true})

func _unico_massimo(f: Callable) -> int:
	var best := -1
	var bv := -1
	var pari := false
	for j in s["n"]:
		if not reggente(j):
			continue
		var v: int = f.call(j)
		if v > bv:
			bv = v
			best = j
			pari = false
		elif v == bv:
			pari = true
	return -1 if pari else best

# ================================================================ varianti delle azioni delle Gilde dei Destini
const VARIANTI_DESTINI := {"sgherri": "Rapire (Combattere): cattura gli agenti Rivali da una carta della Corte",
	"manipolare": "Manipolare (Influenzare): scambia una carta con un Rivale di cui hai un Prigioniero",
	"spiare": "Spiare (Influenzare): scambia la carta azione più alta con un Rivale",
	"rivolta": "Incitare alla Rivolta (Combattere): distruggi le navi danneggiate dove c'è una città Libera",
	"seminare": "Seminare (Costruire): Piaga danneggiata nel settore tirato",
	"generare": "Generare (Costruire): una Piaga danneggiata dove controlli Piaga integra",
	"raccogliere": "Raccogliere (Tassare): distruggi 1 Piaga danneggiata e ottieni 1 risorsa",
	"ricollocare": "Ricollocare (Costruire): città Libera e via l'Oltraggio",
	"recuperare": "Recuperare (Muovere): una Gilda degli scarti torna nella Corte",
	"contrattare": "Contrattare (Acquisire): un Rivale acquisisce, poi acquisisci tu"}
const PROFUGHI := {"475_06": "carburante", "475_03": "psico", "475_07": "materiale", "475_05": "armi", "475_04": "reliquie"}

func _varianti(i: int, a: String) -> Array:
	var v: Array = super(i, a)
	if not _attiva():
		return v
	match a:
		"combattere":
			if ha_carta(i, "479_12") or ha_carta(i, "479_13"): v.append("sgherri")
			if ha_carta(i, "471_00"): v.append("rivolta")
		"influenzare":
			if ha_carta(i, "467_06"): v.append("manipolare")
			if ha_carta(i, "477_23") and not s["turno"].get("spiato", false): v.append("spiare")
		"costruire":
			if ha_carta(i, "446_01"): v.append("seminare")
			if ha_carta(i, "436_11"): v.append("generare")
			for c in PROFUGHI:
				if ha_carta(i, c) and not "ricollocare" in v: v.append("ricollocare")
		"tassare":
			if ha_carta(i, "436_07"): v.append("raccogliere")
		"muovere":
			if ha_carta(i, "428_24"): v.append("recuperare")
		"acquisire":
			if ha_carta(i, "463_23"): v.append("contrattare")
	return v

func _nome_variante(x: String) -> String:
	return VARIANTI_DESTINI.get(x, super(x))

func _base_azione(a: String) -> String:
	if VARIANTI_DESTINI.has(a):
		return a
	return super(a)

func _azione_possibile(i: int, a: String) -> bool:
	match a:
		"sgherri": return not _bersagli_sgherri(i).is_empty()
		"manipolare": return not G(i)["prigionieri"].is_empty() and not G(i)["mano"].is_empty()
		"spiare": return not G(i)["mano"].is_empty()
		"rivolta": return not _sistemi_rivolta(i).is_empty()
		"seminare": return G(piaga())["navi"] > 0
		"generare": return not _sistemi_generare(i).is_empty()
		"raccogliere": return not _sistemi_raccogliere(i).is_empty()
		"ricollocare": return not _pianeti_ricollocare(i).is_empty()
		"recuperare":
			for c in s["scarti_corte"]:
				if Dati.info(c)[1] == "gilda":
					return true
			return false
		"contrattare": return not _bersagli_contrattare(i).is_empty()
	return super(i, a)

func _bersagli_sgherri(i: int) -> Array:
	var out := []
	var armi := simboli(i, "armi")
	for k in s["corte"].size():
		var r := 0
		for j in s["n"]:
			if j != i:
				r += s["corte"][k]["ag"][j]
		if r > 0 and r < armi:
			out.append(k)
	return out

func _p_az_sgherri(p: Dictionary) -> void:
	var i: int = p["g"]
	if _ha_r(p):
		var k: int = _r(p)
		for j in s["n"]:
			if j != i:
				for z in s["corte"][k]["ag"][j]:
					G(i)["prigionieri"].append(j)
					_h_cattura(i, j)
				s["corte"][k]["ag"][j] = 0
		_log("Sgherri di Corte: %s cattura gli agenti Rivali da %s." % [_nome(i), Dati.nome_corte(s["corte"][k]["c"])])
		return
	var ops := []
	for k in _bersagli_sgherri(i):
		ops.append({"t": "Cattura da " + Dati.nome_corte(s["corte"][k]["c"]), "v": k, "corte": k})
	_chiedi(p, i, "Sgherri di Corte: da quale carta catturi?", ops, "corte")

func _p_az_manipolare(p: Dictionary) -> void:
	var i: int = p["g"]
	var j: int = G(i)["prigionieri"][0]
	if G(j)["mano"].is_empty():
		return
	var sua: String = G(j)["mano"][0]
	for c in G(j)["mano"]:
		if Dati.punti(c) > Dati.punti(sua):
			sua = c
	var mia: String = G(i)["mano"][0]
	for c in G(i)["mano"]:
		if Dati.punti(c) < Dati.punti(mia):
			mia = c
	G(j)["mano"].erase(sua)
	G(i)["mano"].erase(mia)
	G(i)["mano"].append(sua)
	G(j)["mano"].append(mia)
	_log("Manipolatori Mentali: %s scambia una carta con %s." % [_nome(i), _nome(j)])

func _p_az_spiare(p: Dictionary) -> void:
	var i: int = p["g"]
	s["turno"]["spiato"] = true
	var j: int = (i + 1) % s["n"]
	if G(j)["mano"].is_empty():
		return
	var alta := func(m: Array) -> String:
		var b: String = m[0]
		for c in m:
			if Dati.valore(c) > Dati.valore(b):
				b = c
		return b
	var mia: String = alta.call(G(i)["mano"])
	G(i)["mano"].erase(mia)
	G(j)["mano"].append(mia)
	var sua: String = alta.call(G(j)["mano"])
	G(j)["mano"].erase(sua)
	G(i)["mano"].append(sua)
	_log("Informatori: %s scambia la carta azione più alta con %s." % [_nome(i), _nome(j)])

func _sistemi_rivolta(i: int) -> Array:
	var out := []
	for id in s["mappa"]:
		if not ha_pezzi(id, i):
			continue
		for e in s["mappa"][id]["edifici"]:
			if e != null and e["g"] == lib() and e["t"] == "citta" and not e["danno"]:
				out.append(id)
				break
	return out

func _p_az_rivolta(p: Dictionary) -> void:
	var i: int = p["g"]
	var best := ""
	var bv := -1
	for id in _sistemi_rivolta(i):
		var d := 0
		for j in s["mappa"][id]["navi"].size():
			if j != i and j != piaga() and j != lib():
				d += s["mappa"][id]["navi"][j][1]
		if d > bv:
			bv = d
			best = id
	if best == "":
		return
	for j in s["mappa"][best]["navi"].size():
		if j != i and j != piaga() and j != lib():
			var nv: Array = s["mappa"][best]["navi"][j]
			G(j)["navi"] += nv[1]
			nv[1] = 0
	_log("Combattenti per la Libertà: %s distrugge le navi danneggiate in %s." % [_nome(i), _desc_sis(best)])

func _p_az_seminare(p: Dictionary) -> void:
	var i: int = p["g"]
	var sett := _dado(6) + 1
	for id in s["mappa"]:
		if _settore(id) == sett and in_gioco(id) and navi(id, piaga()) == 0:
			_metti_piaga(id, true)
			_log("Seminare: %s mette Piaga in %s." % [_nome(i), _desc_sis(id)])
			return

func _sistemi_generare(i: int) -> Array:
	return sistemi_di(i).filter(func(id): return s["mappa"][id]["navi"][piaga()][0] > 0)

func _p_az_generare(p: Dictionary) -> void:
	var i: int = p["g"]
	var l := _sistemi_generare(i)
	if l.is_empty() or G(piaga())["navi"] <= 0:
		return
	var id: String = l[0]
	s["mappa"][id]["navi"][piaga()][0] -= 1
	s["mappa"][id]["navi"][piaga()][1] += 1
	_metti_piaga(id, true)
	_log("Navi Spora: %s fa crescere la Piaga in %s." % [_nome(i), _desc_sis(id)])
	if destino(i) == "voce" and atto() == 2:
		avanza(i, 1, "Diffondere le Spore di Nuova Vita")

func _sistemi_raccogliere(i: int) -> Array:
	return sistemi_di(i).filter(func(id): return s["mappa"][id]["navi"][piaga()][1] > 0)

func _p_az_raccogliere(p: Dictionary) -> void:
	var i: int = p["g"]
	var l := _sistemi_raccogliere(i)
	if l.is_empty():
		return
	var id: String = l[0]
	s["mappa"][id]["navi"][piaga()][1] -= 1
	G(piaga())["navi"] += 1
	var tp: String = "psico" if Dati.is_portale(id) else Dati.TIPO[id]
	_ottieni(i, tp)
	_log("Mietitori della Piaga: %s distrugge 1 Piaga in %s." % [_nome(i), _desc_sis(id)])

func _pianeti_ricollocare(i: int) -> Array:
	var out := []
	for c in PROFUGHI:
		if not ha_carta(i, c):
			continue
		for id in pianeti_di(i):
			if Dati.TIPO[id] == PROFUGHI[c] and _slot_libero(id) >= 0:
				out.append([c, id])
	return out

func _p_az_ricollocare(p: Dictionary) -> void:
	var i: int = p["g"]
	var l := _pianeti_ricollocare(i)
	if l.is_empty():
		return
	var c: String = l[0][0]
	var id: String = l[0][1]
	_metti_libera(id, "citta")
	G(i)["oltraggio"].erase(PROFUGHI[c])
	_riempi(i, PROFUGHI[c])
	G(i)["carte"].erase(c)
	_log("%s: %s costruisce una città Libera in %s e toglie il suo Oltraggio." % [Dati.nome_corte(c), _nome(i), _desc_sis(id)])

func _p_az_recuperare(p: Dictionary) -> void:
	var i: int = p["g"]
	for q in range(s["scarti_corte"].size() - 1, -1, -1):
		var c: String = s["scarti_corte"][q]
		if Dati.info(c)[1] == "gilda":
			s["scarti_corte"].remove_at(q)
			s["corte"].append({"c": c, "ag": _zeri_int(s["n"])})
			_log("Investigatori delle Gilde: %s rimette %s nella Corte." % [_nome(i), Dati.nome_corte(c)])
			if destino(i) == "patrocinatore" and atto() == 1:
				avanza(i, 2, "Tenere al Potere le Gilde")
			return

func _bersagli_contrattare(i: int) -> Array:
	var out := []
	for j in s["n"]:
		if j == i:
			continue
		for k in super_acquisibili(j):
			out.append([j, k])
	return out

func super_acquisibili(j: int) -> Array:
	return _carte_acquisibili(j)

func _p_az_contrattare(p: Dictionary) -> void:
	var i: int = p["g"]
	var l := _bersagli_contrattare(i)
	if l.is_empty():
		return
	var j: int = l[0][0]
	var k: int = l[0][1]
	# chi acquisisce non cattura: gli agenti tornano ai loro giocatori
	var miei: int = s["corte"][k]["ag"][i]
	for x in s["n"]:
		if x != j:
			G(x)["agenti"] += s["corte"][k]["ag"][x]
			s["corte"][k]["ag"][x] = 0
	_log("Mediatori: %s fa acquisire %s a %s." % [_nome(i), Dati.nome_corte(s["corte"][k]["c"]), _nome(j)])
	_acquisisci(j, k, false)
	_spingi({"k": "az_acquisire", "g": i})
	for z in miei:
		_spingi({"k": "az_influenzare", "g": i})

# ================================================================ Ammiraglie: Gru Navale e Propulsore a Scia
func _opzioni_costruire(i: int) -> Array:
	var out: Array = super(i)
	if not _attiva() or i < 0 or i >= s["n"] or G(i)["navi"] <= 0:
		return out
	var am := ammiraglia(i)
	if am == "" or not "porto" in migliorie(i).values():
		return out
	var usate: Array = s["turno"].get("porti", []) if s.has("turno") else []
	var volte := 2 if migliorie(i).has("gru") else 1
	for k in volte:
		var chiave := "%s:%d" % [am, -1 - k]
		if not chiave in usate:
			out.append(["nave", am, -1 - k])
			break
	return out

func _opzioni_preludio(i: int) -> Array:
	var ops: Array = super(i)
	if _attiva() and migliorie(i).has("scia") and ammiraglia(i) != "" and not s["turno"].get("scia", false):
		ops.append({"t": "Propulsore a Scia: muovi con la Fionda dall'Ammiraglia", "v": "carta:scia"})
	if _attiva() and ha_carta(i, "428_23") and not _sul_podio(i):
		ops = ops.filter(func(o): return not (str(o["v"]).begins_with("carta:") and Dati.info(str(o["v"]).substr(6))[1] == "gilda"))
	return ops

func _preludio_esegui(i: int, c: String) -> void:
	if c == "scia":
		s["turno"]["scia"] = true
		_spingi({"k": "az_muovere", "g": i})
		return
	super(i, c)

## Sorveglianti delle Gilde: per usare le carte Gilda bisogna essere primi o secondi in un'ambizione dichiarata.
func _sul_podio(i: int) -> bool:
	for amb in Dati.AMBIZIONI:
		if not dichiarata(amb):
			continue
		var sopra := 0
		var mio := punteggio_ambizione(i, amb)
		if mio <= 0:
			continue
		for j in s["n"]:
			if j != i and punteggio_ambizione(j, amb) > mio:
				sopra += 1
		if sopra <= 1:
			return true
	return false

# ================================================================ Fede: limiti degli Ideali e Sottrazione Partigiana
func _dichiarabile(i: int, amb: String, c: String) -> bool:
	if not _attiva():
		return super(i, amb, c)
	var ideali: Dictionary = D().get("ideali", {}) if D().get("ideali") is Dictionary else {}
	var dottrina: String = D().get("dottrina", "fes")
	var lib_: Array = C()["libretto"]
	if Dati.is_fedele(c):
		if (lib_.has("458_08") or lib_.has("458_03") or lib_.has("458_01")) and ideali.has(amb) and ideali[amb] != dottrina:
			return false
		if lib_.has("458_03") and not ideali.has(amb):
			return false
	elif lib_.has("458_01") and ideali.has(amb):
		return false
	return super(i, amb, c)

func _modi_sottrarre(i: int) -> Array:
	if _attiva() and (C()["libretto"].has("477_09") or (ha_carta(i, "477_22") and destino(i) == "partigiano")):
		return ["oltraggio"]
	return super(i)

## Sottrazione Partigiana in mano a chi non è il Partigiano: si elimina e toglie gli Oltraggi.
func _h_acquisita_partigiana(i: int) -> void:
	if ha_carta(i, "477_22") and destino(i) != "partigiano":
		G(i)["carte"].erase("477_22")
		G(i)["oltraggio"] = []
