## Campagna «L'Orlo Infestato»: obiettivi, grandi ambizioni e segnalini di ogni Destino.
## È la classe finale del motore della campagna (main.gd e i test la istanziano).
## Alcune regole dei Destini sono semplificate: vedi campagna/PROGETTO_MOTORE.md.
class_name MotoreOrlo
extends MotoreDestini

const VALORI_FEDELI := [1, 2, 3, 4, 5, 6, 7]
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
		"golem_desta", "evento_extra", "autorita", "economia", "dottrina", "dottrina_maggioranza", "ricollocare", \
		"mondi_ripristina", "rifornisci_portali", "dicerie", "cessate_il_fuoco", "guardia_eden", "stirpe_piaga", \
		"emissari", "lore_corte", "instabili_scarti", "profeta", "miglioria_gratis", "portale_rivelato", "mondi_annota", \
		"martello_completo", "mondi_riserva", "bottino_ok", "testimoni_psico", "arsenale_corte", "togli_reliquie_virtuali", \
		"togli_mat_carb_virtuali", "testimoni", "fine_confederazione":
			pass
		"golem_focolare", "golem_via":
			D()["golem_" + str(i)] = 0
		"confederazione":
			D()["membri"] = range(s["n"])
		"monopoli":
			D()["monopoli"] = {"materiale": -1, "carburante": -1, "armi": -1, "reliquie": -1, "psico": -1}
		"monopoli_liberi":
			D()["monopoli"] = {"materiale": -1, "carburante": -1, "armi": -1, "reliquie": -1, "psico": -1}
		"pila_fedeli":
			D()["fedeli"] = VALORI_FEDELI.duplicate()
		"fedeli_corte":
			D()["fedeli"] = []
		"ideali_via":
			D()["ideali"] = []
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
					avanza(i, 10 if pila.is_empty() else int(pila[0]), "Diffondere la Buona Novella")
				elif atto() == 2 and amb in D().get("ideali", []):
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
					_prendi_monopoli()
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
				avanza(i, pianeti_di(i).filter(func(x): return Dati.TIPO[x] in ["materiale", "carburante"]).size(), "Custodire lo Splendore dell'Orlo")
			"naturalista":
				var k := 0
				for id in sistemi_di(i):
					if s["mappa"][id]["navi"][piaga()][0] > 0:
						k += 1
				avanza(i, k, "Vivere nel Giardino")
			"spettro":
				var pas: Array = D().get("passaggi", [])
				if not pas.is_empty() and controllo_eventi(pas[0]) == i:
					avanza(i, pas.size(), "Far Crollare i Portali dell'Orlo")
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
		D()["grandi_" + str(cap)] = gr
		for i in n:
			var fatte: int = gr.get(str(i), 0)
			if fatte > 0:
				var pt: int = GRANDI[clampi(cap, 1, 4)][fatte - 1]
				G(i)["potere"] += pt
				_log("%s realizza %s e ottiene %d Potere." % [_nome(i), "una grande ambizione" if fatte == 1 else "entrambe le grandi ambizioni", pt])
				_ev({"tipo": "grande_ambizione", "g": i, "n": fatte})

## Le grandi ambizioni si calcolano in _h_fine_capitolo.
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
			var ideali: Array = D().get("ideali", [])
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
	var cr := in_gioco_destino("credente")
	if cr >= 0 and atto() >= 2 and i == cr:
		var ideali: Array = _lista("ideali")
		if not amb in ideali:
			ideali.append(amb)
			_log("Un segnalino Ideale va sull'ambizione %s." % Dati.NOME_AMBIZIONE[amb])
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
	# Diffondere la Fede: influenzando, il Credente attacca una carta Fedele alla Corte
	if destino(i) == "credente" and atto() == 1 and not D().get("fedeli", []).is_empty():
		D()["fedeli"].pop_front()

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
		"castellano":
			var sg: Array = _lista("seggi")
			if sg.size() < 5:
				for x in citta_di(i):
					if not x[0] in sg:
						sg.append(x[0])
						_log("%s reclama un Seggio in %s." % [_nome(i), _desc_sis(x[0])])
						break
		"voce":
			_metti_spora(i)
		"naturalista":
			_metti_spora(i)
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

# ================================================================ Monopoli, Confederazione, Feudi, Pace
func _prendi_monopoli() -> void:
	if not D().has("monopoli"):
		return
	var mono: Dictionary = D()["monopoli"]
	var ma := in_gioco_destino("magnate")
	for t in mono:
		if int(mono[t]) >= 0:
			continue
		for i in s["n"]:
			if conta_risorse(i, t) >= 3:
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
func _settori_in_pace() -> int:
	var k := 0
	for sett in range(1, 7):
		if s["fuori"].has(sett):
			continue
		var pace := true
		for id in s["mappa"]:
			if _settore(id) != sett:
				continue
			var q := 0
			for j in s["n"]:
				if navi(id, j) > 0:
					q += 1
			if q >= 2:
				pace = false
		if pace:
			k += 1
	return k

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
	return ops

func _esegui_vertice_extra(i: int, v: String) -> void:
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
	if D().get("portale", "") != "":
		add.call(D()["portale"], "Portale")
	return out
