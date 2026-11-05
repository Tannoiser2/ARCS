## Campagna «L'Orlo Infestato»: effetti delle carte Vox e Gilda dei set dei Destini.
## Le scelte facoltative («puoi...») delle carte Vox sono risolte in automatico nel modo più utile per chi le usa.
class_name MotoreCarteDestini
extends MotoreDestini

## Carte Vox dei Destini: codice -> effetto
const VOX := {
	"427_03": "estorsione", "427_04": "estorsione", "428_04": "gilde_ritirano", "428_10": "fiera",
	"428_15": "conflitto", "428_16": "fiasco", "463_21": "intrigo_corte",
	"429_02": "culto_golem", "429_03": "culto_golem", "429_04": "culto_golem",
	"429_10": "guerriero", "429_11": "protettore", "429_12": "cercatore", "429_13": "raccoglitore",
	"433_00": "cercare_portale", "433_01": "cercare_portale", "433_02": "cercare_portale", "433_06": "pellegrinaggio",
	"436_02": "piaga_incombe", "436_03": "panico", "436_04": "epurazione", "436_05": "epurazione", "436_06": "epurazione",
	"456_00": "tempeste", "458_14": "complotto",
	"463_07": "disertori", "463_08": "disertori", "479_05": "disertori", "479_06": "disertori", "479_10": "disertori",
	"479_11": "disertori", "463_11": "rappresaglia", "463_17": "impero_cade", "467_02": "contro_egemonia",
	"467_03": "contro_egemonia", "471_10": "armistizio", "471_11": "armistizio", "471_20": "intrigo_politico",
	"471_21": "intrigo_politico", "471_22": "intrigo_politico", "472_05": "empati", "472_06": "empati",
	"475_01": "divorapianeti", "477_04": "terrorismo", "477_05": "terrorismo", "477_11": "oltraggio_dilaga",
	"477_12": "oltraggio_dilaga", "479_03": "rivolta", "479_04": "rivolta", "479_08": "caos",
	"487_02": "dicerie", "487_03": "dicerie", "487_06": "chiamata_armi", "488_05": "festa", "488_06": "festa"}
## Effetto «Appena Acquisita» uguale a una carta del gioco base
const VOX_BASE := {"conflitto": "c30", "oltraggio_dilaga": "c28", "rivolta": "c26"}
## Carte Vox senza Crisi
const SENZA_CRISI := ["armistizio"]

## Carte Gilda dei Destini con Preludio o effetti propri
const REGGENTE_MINORE := ["463_05", "463_06", "463_15", "463_16"]
const RINNEGATI := ["479_14", "479_15"]
const ADULATORI := ["475_10", "450_01"]
const BELLICHE := ["442_05", "442_06"]
const EMISSARI := {"472_07": "empate", "428_17": "empate", "428_20": "magnate", "428_21": "magnate", "428_19": "generale", "428_18": "custode"}
const MAESTRI := {"428_07": ["generale", "armi"], "428_08": ["magnate", "carburante"], "428_09": ["magnate", "materiale"],
	"428_05": ["empate", "psico"], "428_06": ["custode", "reliquie"]}
const COMPAGNI_FEDELI := ["458_13", "458_06", "458_15"]
const CARTELLI := {"427_16": "reliquie", "427_17": "psico", "427_18": "armi"}

func _dc() -> Dictionary:
	if not C().has("carte_dest"):
		C()["carte_dest"] = {}
	return C()["carte_dest"]

func effetto_vox(c: String) -> String:
	return VOX.get(c, "")

# ================================================================ Corte: togliere una carta
func _indice_corte(c: String) -> int:
	for q in s["corte"].size():
		if s["corte"][q]["c"] == c:
			return q
	return -1

## Scarta una carta Vox dalla Corte (gli agenti tornano nelle riserve).
func _scarta_vox(k: int) -> void:
	var slot: Dictionary = s["corte"][k]
	for j in s["n"]:
		G(j)["agenti"] += slot["ag"][j]
	s["corte"].remove_at(k)
	s["scarti_corte"].append(slot["c"])
	_rifornisci_corte_in(k)

func _rimescola_vox(k: int) -> void:
	var slot: Dictionary = s["corte"][k]
	for j in s["n"]:
		G(j)["agenti"] += slot["ag"][j]
	s["corte"].remove_at(k)
	s["mazzo_corte"].append(slot["c"])
	_mescola(s["mazzo_corte"])
	_rifornisci_corte_in(k)

func _elimina_vox(k: int) -> void:
	s["corte"].remove_at(k)
	_rifornisci_corte_in(k)

# ================================================================ Crisi della Corte
func _ha_crisi(c: String) -> bool:
	if VOX.has(c):
		return not VOX[c] in SENZA_CRISI
	return super(c)

func _p_crisi_vox(p: Dictionary) -> void:
	var c: String = p["c"]
	if not VOX.has(c):
		super(p)
		return
	var k := _indice_corte(c)
	if k < 0:
		return
	var e: String = VOX[c]
	var simb: String = C()["dado_evento"][1] if C()["dado_evento"].size() > 1 else "a"
	var sett: int = int(C()["dado_numero"])
	var nome := Dati.nome_corte(c)
	_log("Crisi di %s." % nome)
	match e:
		"estorsione":
			for t in Dati.RISORSE:
				var mx := 0
				for i in s["n"]:
					mx = maxi(mx, conta_risorsa(i, t))
				if mx > 0:
					for i in s["n"]:
						if conta_risorsa(i, t) == mx:
							_togli_risorsa(i, t)
			_scarta_vox(k)
		"gilde_ritirano":
			if simb in ["a", "b"]:
				for i in ordine_da(s["iniz"]):
					_seppellisci_gilda(i)
			_seppellisci(k)
		"fiera":
			_seppellisci(k)
		"conflitto":
			var date := []
			for i in ordine_da(s["iniz"]):
				var gl := _gilde_di(i)
				date.append(gl[0] if not gl.is_empty() else "")
			var ord := ordine_da(s["iniz"])
			for q in ord.size():
				var x: String = date[q]
				if x != "":
					G(ord[q])["carte"].erase(x)
					G(ord[(q + 1) % ord.size()])["carte"].append(x)
			_seppellisci(k)
		"fiasco":
			for i in ordine_da(s["iniz"]):
				var gl := _gilde_di(i)
				while gl.size() > G(i)["agenti"]:
					var x: String = gl.pop_back()
					G(i)["carte"].erase(x)
					s["scarti_corte"].append(x)
			_seppellisci(k)
		"intrigo_corte":
			C()["consiglio"] = "sessione"
			for q in s["corte"].size():
				if s["corte"][q]["c"] == "consiglio":
					for j in s["n"]:
						s["corte"][q]["ag"][j] += s["corte"][k]["ag"][j]
						s["corte"][k]["ag"][j] = 0
			_seppellisci(k)
		"culto_golem":
			for i in ordine_da(s["iniz"]):
				if int(D_().get("golem_%d" % i, 0)) > 0 and not citta_di(i).is_empty():
					var x: Array = citta_di(i)[0]
					_rimuovi_edificio(x[0], x[1])
					_log("Culto dei Golem: %s rimette una città sulla plancia." % _nome(i))
			_seppellisci(k)
		"guerriero":
			var g := int(_dc().get("guerriero", -1))
			if g >= 0:
				for id in s["mappa"]:
					var nv: Array = s["mappa"][id]["navi"][g]
					G(g)["navi"] += nv[1]
					nv[1] = 0
		"protettore":
			var g := int(_dc().get("protettore", -1))
			for id in s["mappa"]:
				for j in s["mappa"][id]["navi"].size():
					if j != g and j != piaga():
						var nv: Array = s["mappa"][id]["navi"][j]
						nv[0] += nv[1]
						nv[1] = 0
		"cercatore":
			var g := int(_dc().get("cercatore", -1))
			if g >= 0:
				for l in ["a", "b", "c"]:
					if l != simb:
						continue
					for q in range(1, 7):
						var id := "%d%s" % [q, l]
						var nv: Array = s["mappa"][id]["navi"][g]
						var porta := "%dg" % sett
						s["mappa"][porta]["navi"][g][0] += nv[0]
						s["mappa"][porta]["navi"][g][1] += nv[1]
						nv[0] = 0
						nv[1] = 0
		"raccoglitore":
			var g := int(_dc().get("raccoglitore", -1))
			if g >= 0:
				for t in Dati.RISORSE:
					while _togli_risorsa(g, t):
						pass
		"cercare_portale":
			for i in ordine_da(s["iniz"]):
				var best := ""
				for id in s["mappa"]:
					if navi(id, i) > 0 and (best == "" or navi(id, i) > navi(best, i)):
						best = id
				if best != "":
					var nv: Array = s["mappa"][best]["navi"][i]
					if nv[1] > 0:
						nv[1] -= 1
					else:
						nv[0] -= 1
		"pellegrinaggio":
			if simb == "a":
				for i in ordine_da(s["iniz"]):
					var gl := _gilde_di(i)
					if not gl.is_empty():
						G(i)["carte"].erase(gl[0])
						s["scarti_corte"].append(gl[0])
		"piaga_incombe":
			for id in s["mappa"]:
				if Dati.settore(id) == sett:
					var pg: Array = s["mappa"][id]["navi"][piaga()]
					pg[0] += pg[1]
					pg[1] = 0
			for q in range(1, 7):
				var id := "%d%s" % [q, simb]
				if s["mappa"].has(id) and in_gioco(id) and navi(id, piaga()) == 0:
					_metti_piaga(id, true)
			_seppellisci(k)
		"panico":
			for i in ordine_da(s["iniz"]):
				var q := 0
				for id in s["mappa"]:
					if navi(id, piaga()) > 0:
						for ed in s["mappa"][id]["edifici"]:
							if ed != null and ed["g"] == i:
								q += 1
				_ritira_agenti(i, q)
			_seppellisci(k)
		"epurazione":
			for i in s["n"]:
				var q := _trofei_piaga(i)
				if q > 0:
					G(i)["potere"] += 2 * q
					_log("Epurazione della Piaga: %s ottiene %d Potere." % [_nome(i), 2 * q])
			_seppellisci(k)
		"tempeste":
			_seppellisci(k)
		"complotto":
			for i in s["n"]:
				var f := _fedele_piu_alta(G(i)["mano"])
				if f != "":
					G(i)["mano"].erase(f)
					s["scarti_azioni"].append(f)
		"disertori":
			var fl := -1
			for i in ordine_da(s["iniz"]):
				if not reggente(i):
					fl = i
					break
			if fl >= 0:
				_diserta(sett, fl)
			_seppellisci(k)
		"rappresaglia":
			_rappresaglia(-1)
			_seppellisci(k)
		"impero_cade":
			if simb == "a":
				for i in ordine_da(s["iniz"]):
					if reggente(i):
						_lascia_impero(i)
				for id in s["mappa"]:
					_colpisci(imp(), id, s["mappa"][id]["navi"][imp()][0])
				_scarta_vox(k)
		"contro_egemonia":
			_seppellisci(k)
		"intrigo_politico":
			var ord := ordine_da(0)
			var n: int = s["n"]
			for i in ord:
				var dest := []
				if simb in ["a", "c"]:
					dest.append((i + 1) % n)
				if simb in ["b", "c"]:
					dest.append((i - 1 + n) % n)
				for j in dest:
					if j != i and G(i)["agenti"] > 0:
						G(i)["agenti"] -= 1
						C()["favori"][j][str(i)] = int(C()["favori"][j].get(str(i), 0)) + 1
			_log("Intrigo Politico: i giocatori si scambiano Favori.")
			_seppellisci(k)
		"empati":
			var minimo := 0
			for i in s["n"]:
				if G(i)["potere"] < G(minimo)["potere"]:
					minimo = i
			_riempi(minimo, "psico")
			_scarta_vox(k)
		"divorapianeti":
			var fe: Array = FACCE_EVENTO[_dado(6)]
			if fe[1] == simb:
				var id := "%d%s" % [sett, simb]
				if s["mappa"].has(id) and in_gioco(id):
					_spezza(id)
		"terrorismo":
			_terrorismo(true)
			_rimescola_vox(k)
		"oltraggio_dilaga":
			var id := "%d%s" % [sett, simb]
			if Dati.TIPO.has(id):
				for i in ordine_da(s["iniz"]):
					if not G(i)["oltraggio"].has(Dati.TIPO[id]):
						_oltraggio(i, Dati.TIPO[id])
			_scarta_vox(k)
		"rivolta":
			for id in s["mappa"]:
				for j in s["mappa"][id]["navi"].size():
					var nv: Array = s["mappa"][id]["navi"][j]
					if nv[1] > 0:
						G(j)["navi"] += nv[1]
						nv[1] = 0
			_log("Rivolta di Massa: tutte le navi danneggiate sono distrutte.")
			_seppellisci(k)
		"caos":
			pass
		"dicerie":
			_scarta_vox(k)
		"chiamata_armi":
			var best := 0
			for i in s["n"]:
				if _n_risorse(i) > _n_risorse(best):
					best = i
			if not s["scarti_azioni"].is_empty():
				G(best)["mano"].append(s["scarti_azioni"].pop_front())
			_scarta_vox(k)
		"festa":
			_elimina_vox(k)

# ================================================================ Appena Acquisita
func _p_vox(p: Dictionary) -> void:
	var c: String = p["c"]
	if not VOX.has(c):
		super(p)
		return
	var e: String = VOX[c]
	if VOX_BASE.has(e):
		# stesso effetto della carta base; negli scarti va la carta del Destino
		p["orig"] = c
		p["c"] = VOX_BASE[e]
		super(p)
		return
	var i: int = p["g"]
	var nome := Dati.nome_corte(c)
	var dove := "scarti"
	match e:
		"estorsione":
			var best := -1
			for j in s["n"]:
				if j != i and _n_risorse(j) > 0 and (best < 0 or _n_risorse(j) > _n_risorse(best)):
					best = j
			if best >= 0:
				for t in G(best)["risorse"]:
					if t != "":
						_togli_risorsa(best, t)
						_ottieni_diretto(i, t)
						_log("%s ruba 1 %s a %s." % [_nome(i), Dati.NOME_RISORSA[t], _nome(best)])
						break
		"gilde_ritirano":
			for j in ordine_da(s["iniz"]):
				if j != i:
					_seppellisci_gilda(j)
			dove = "mazzo"
		"fiera":
			for q in s["corte"].size():
				if Dati.info(s["corte"][q]["c"])[1] == "gilda":
					for j in s["n"]:
						if j != i:
							G(j)["agenti"] += s["corte"][q]["ag"][j]
							s["corte"][q]["ag"][j] = 0
			dove = "mazzo"
		"fiasco":
			for j in ordine_da(s["iniz"]):
				if j == i:
					continue
				var gl := _gilde_di(j)
				while gl.size() > G(j)["agenti"]:
					var x: String = gl.pop_back()
					G(j)["carte"].erase(x)
					s["scarti_corte"].append(x)
			dove = "mazzo"
		"intrigo_corte":
			C()["consiglio"] = "sessione"
			dove = "mazzo"
		"culto_golem":
			var gl: Array = D_().get("golem", [])
			if not gl.is_empty():
				gl.pop_front()
				D_()["golem_%d" % i] = int(D_().get("golem_%d" % i, 0)) + 1
				_log("%s prende un Golem." % _nome(i))
		"guerriero", "protettore", "cercatore", "raccoglitore":
			_dc()[e] = i
			_log("%s prende il Golem %s." % [_nome(i), e.capitalize()])
		"cercare_portale":
			var po: String = D_().get("portale", "")
			if po != "" and controllo_eventi(po) == i:
				var q := 0
				for j in s["n"]:
					if j != i:
						q += navi(po, j)
						s["mappa"][po]["navi"][j] = [0, 0]
				if q > 0:
					G(i)["potere"] += 2 * q
					_log("%s elimina %d navi nel Portale e ottiene %d Potere." % [_nome(i), q, 2 * q])
			dove = "rimescola"
		"pellegrinaggio":
			var gl := _gilde_di(i)
			if not gl.is_empty():
				var seme: String = Dati.info(gl[0])[2]
				for j in s["n"]:
					if j != i:
						for x in _gilde_di(j):
							if Dati.info(x)[2] == seme:
								G(j)["carte"].erase(x)
								s["scarti_corte"].append(x)
			dove = "rimescola"
		"piaga_incombe", "panico":
			var best := -1
			var bv := 0
			for q in range(1, 7):
				var d := 0
				var mio := false
				for id in s["mappa"]:
					if Dati.settore(id) == q:
						d += s["mappa"][id]["navi"][piaga()][1]
						if ha_pezzi(id, i):
							mio = true
				if mio and d > bv:
					bv = d
					best = q
			if best > 0:
				for id in s["mappa"]:
					if Dati.settore(id) == best:
						var pg: Array = s["mappa"][id]["navi"][piaga()]
						for z in pg[1]:
							if e == "panico":
								G(i)["trofei"].append({"t": "nave", "g": piaga()})
							else:
								G(piaga())["navi"] += 1
						pg[1] = 0
				_log("%s distrugge la Piaga danneggiata nel settore %d." % [_nome(i), best])
			dove = "mazzo"
		"epurazione":
			var q := _trofei_piaga(i)
			G(i)["potere"] += 2 * q
			for j in s["n"]:
				if j != i:
					var tieni := []
					for t in G(j)["trofei"]:
						if int(t["g"]) == piaga():
							G(piaga())["navi"] += 1
						else:
							tieni.append(t)
					G(j)["trofei"] = tieni
			_log("Epurazione della Piaga: %s ottiene %d Potere." % [_nome(i), 2 * q])
		"complotto":
			var f := _fedele_piu_alta(s["scarti_azioni"])
			if f != "":
				s["scarti_azioni"].erase(f)
				G(i)["mano"].append(f)
				_mescola(s["scarti_azioni"])
				_log("%s prende in mano %s." % [_nome(i), Dati.nome_carta_azione(f)])
		"tempeste", "dicerie", "armistizio":
			pass
		"disertori":
			if not reggente(i):
				var best := -1
				var bv := 0
				for q in range(1, 7):
					var n_ := 0
					for id in s["mappa"]:
						if Dati.settore(id) == q:
							n_ += navi(id, imp())
					if n_ > bv:
						bv = n_
						best = q
				if best > 0:
					_diserta(best, i)
			dove = "mazzo"
		"rappresaglia":
			if reggente(i):
				_rappresaglia(-1)
			dove = "mazzo"
		"impero_cade":
			dove = "mazzo"
		"contro_egemonia":
			if destino(i) != "egemone":
				var st: Array = D_().get("stendardi", [])
				for id in st.duplicate():
					if controllo_eventi(id) == i:
						st.erase(id)
						G(i)["trofei"].append({"t": "stendardo", "g": in_gioco_destino("egemone")})
		"intrigo_politico":
			for j in s["n"]:
				if j != i and G(j)["agenti"] > 0:
					G(j)["agenti"] -= 1
					C()["favori"][i][str(j)] = int(C()["favori"][i].get(str(j), 0)) + 1
			_log("%s prende 1 Favore da ogni Rivale." % _nome(i))
		"empati":
			_riempi(i, "psico")
		"divorapianeti":
			var colpi := 0
			for z in 2:
				if _dado(2) == 0:
					colpi += 1
			if colpi >= 2:
				G(i)["potere"] += 3
				if not s["scarti_azioni"].is_empty():
					G(i)["mano"].append(s["scarti_azioni"].pop_front())
				_log("%s ottiene 3 Potere da %s." % [_nome(i), nome])
				dove = "mazzo"
		"terrorismo":
			_terrorismo(false)
			dove = "rimescola"
		"caos":
			if not reggente(i):
				C()["titolo"][i] = "reggente"
				_log("%s torna Reggente." % _nome(i))
			_spingi({"k": "az_influenzare", "g": i})
			dove = "rimescola"
		"chiamata_armi":
			if not s["scarti_azioni"].is_empty():
				G(i)["mano"].append(s["scarti_azioni"].pop_front())
		"festa":
			dove = "mazzo"
	match dove:
		"scarti":
			s["scarti_corte"].append(c)
		"mazzo":
			s["mazzo_corte"].append(c)
		"rimescola":
			s["mazzo_corte"].append(c)
			_mescola(s["mazzo_corte"])

# ================================================================ aiuti delle carte Vox
func D_() -> Dictionary:
	return C().get("dest", {})

func _gilde_di(i: int) -> Array:
	return G(i)["carte"].filter(func(x): return Dati.info(x)[1] == "gilda")

func _seppellisci_gilda(i: int) -> void:
	var gl := _gilde_di(i)
	if gl.is_empty():
		return
	G(i)["carte"].erase(gl[0])
	s["mazzo_corte"].append(gl[0])
	_log("%s seppellisce %s." % [_nome(i), Dati.nome_corte(gl[0])])

func _n_risorse(i: int) -> int:
	var q := 0
	for r in G(i)["risorse"]:
		if r != "":
			q += 1
	return q

func _riempi(i: int, t: String) -> void:
	var q := 0
	for k in spazi_aperti(i):
		if G(i)["risorse"][k] == "" and riserva(t) > 0:
			G(i)["risorse"][k] = t
			q += 1
	if q > 0:
		_log("%s ottiene %d %s." % [_nome(i), q, Dati.NOME_RISORSA[t]])

func _trofei_piaga(i: int) -> int:
	var q := 0
	for t in G(i)["trofei"]:
		if int(t["g"]) == piaga():
			q += 1
	return q

func _ritira_agenti(i: int, q: int) -> void:
	for slot in s["corte"]:
		while q > 0 and slot["ag"][i] > 0:
			slot["ag"][i] -= 1
			G(i)["agenti"] += 1
			q -= 1

## Disertori Imperiali: nel settore le navi imperiali diventano navi del Fuorilegge.
func _diserta(sett: int, fl: int) -> void:
	var q := 0
	for id in s["mappa"]:
		if Dati.settore(id) != sett:
			continue
		var nv: Array = s["mappa"][id]["navi"][imp()]
		var tot: int = nv[0] + nv[1]
		var messe := mini(tot, G(fl)["navi"])
		if messe > 0:
			_metti_navi(fl, id, messe, false)
		G(imp())["navi"] += tot
		nv[0] = 0
		nv[1] = 0
		q += messe
	if q > 0:
		_log("Disertori Imperiali: %d navi imperiali del settore %d passano a %s." % [q, sett, _nome(fl)])

## Rappresaglia della Flotta: ogni nave imperiale colpisce 1 nave di ogni Fuorilegge nel suo sistema.
func _rappresaglia(_sett: int) -> void:
	for id in s["mappa"]:
		var ni: int = s["mappa"][id]["navi"][imp()][0]
		if ni <= 0:
			continue
		for j in s["n"]:
			if not reggente(j) and navi(id, j) > 0:
				_colpisci(j, id, ni)

func _terrorismo(anche_leali: bool) -> void:
	for i in s["n"]:
		for id in s["mappa"]:
			if Dati.is_portale(id) or not G(i)["oltraggio"].has(Dati.TIPO.get(id, "")):
				continue
			for j in s["mappa"][id]["navi"].size():
				if j < s["n"] and not anche_leali:
					continue
				var nv: Array = s["mappa"][id]["navi"][j]
				G(j)["navi"] += nv[1]
				nv[1] = 0
			for k in s["mappa"][id]["edifici"].size():
				var ed = s["mappa"][id]["edifici"][k]
				if ed != null and ed["danno"] and (anche_leali or ed["g"] >= s["n"]):
					_rimuovi_edificio(id, k)

## Mondo Spezzato: gli edifici del pianeta sono distrutti.
func _spezza(id: String) -> void:
	for k in s["mappa"][id]["edifici"].size():
		if s["mappa"][id]["edifici"][k] != null:
			_rimuovi_edificio(id, k)
			D_()["mondi_edifici"] = int(D_().get("mondi_edifici", 0)) + 1
	if not D_().has("spezzati"):
		D_()["spezzati"] = []
	D_()["spezzati"].append(id)
	_log("%s diventa un Mondo Spezzato." % _desc_sis(id))

# ================================================================ carte Gilda dei Destini: Preludio
func _preludio_carta(i: int, c: String) -> Dictionary:
	var v := "carta:" + c
	if c in REGGENTE_MINORE and _segnalino_libero() >= 0:
		return {"t": "Reggente Minore: scartalo e dichiara una qualsiasi ambizione", "v": v, "carta": c}
	if c in RINNEGATI and reggente(i) and not _sistemi_controllati(i).is_empty() and G(imp())["navi"] > 0:
		return {"t": "Ammiragli Rinnegati: scartali, 3 navi Imperiali in un sistema che controlli", "v": v, "carta": c}
	if c in ADULATORI and not _sistemi_controllati(i).is_empty():
		return {"t": "Adulatori: scartali, 3 navi in un sistema che controlli", "v": v, "carta": c}
	if c in BELLICHE and riserva("armi") > 0:
		return {"t": "Attività Belliche: scartala, riempi gli spazi liberi di Armi", "v": v, "carta": c}
	if c == "444_00" and not s["turno"].get("recinto", false) and _ha_risorse(i):
		return {"t": "Recinto delle Reliquie: scarta 1 risorsa per 1 Reliquia", "v": v, "carta": c}
	if c in COMPAGNI_FEDELI and _fedele_giocata() >= 0:
		for x in G(i)["mano"]:
			if not Dati.is_evento(x):
				return {"t": "%s: scarta una carta azione e mettila accanto alla carta Fedele giocata" % Dati.nome_corte(c), "v": v, "carta": c}
	if EMISSARI.has(c) and _segnalino_libero() >= 0:
		return {"t": "%s: attaccala alla Corte e dichiara %s" % [Dati.nome_corte(c), Dati.NOME_AMBIZIONE[EMISSARI[c]]], "v": v, "carta": c}
	return super(i, c)

func _preludio_esegui(i: int, c: String) -> void:
	if c in REGGENTE_MINORE:
		_scarta_corte(i, c)
		_spingi({"k": "dichiara_libera", "g": i})
	elif c in RINNEGATI:
		_scarta_corte(i, c)
		_spingi({"k": "tre_navi_imperiali", "g": i})
	elif c in ADULATORI:
		_scarta_corte(i, c)
		_spingi({"k": "tre_navi", "g": i})
	elif c in BELLICHE:
		_scarta_corte(i, c)
		_riempi(i, "armi")
	elif c == "444_00":
		s["turno"]["recinto"] = true
		_spingi({"k": "trafficante", "g": i})
	elif c in COMPAGNI_FEDELI:
		var scarto := ""
		for x in _ordina_mano(G(i)["mano"]):
			if not Dati.is_evento(x):
				scarto = x
				break
		G(i)["mano"].erase(scarto)
		s["scarti_azioni"].append(scarto)
		G(i)["carte"].erase(c)
		var gi := _fedele_giocata()
		s["leghe"].append({"g": i, "c": c, "carta": s["giocate"][gi]["c"]})
		_log("%s mette %s accanto a %s." % [_nome(i), Dati.nome_corte(c), Dati.nome_carta_azione(s["giocate"][gi]["c"])])
	elif EMISSARI.has(c):
		_scarta_corte(i, c)
		_dichiara(i, EMISSARI[c], false)
	else:
		super(i, c)

func _fedele_giocata() -> int:
	for k in s["giocate"].size():
		if Dati.is_fedele(s["giocate"][k]["c"]) and s["giocate"][k]["modo"] != "sottrai":
			return k
	return -1

func _fedele_piu_alta(l: Array) -> String:
	var best := ""
	for x in l:
		if Dati.is_fedele(x) and (best == "" or Dati.valore(x) > Dati.valore(best)):
			best = x
	return best

func _p_dichiara_libera(p: Dictionary) -> void:
	var i: int = p["g"]
	if _ha_r(p):
		_dichiara(i, _r(p), false)
		return
	var ops := []
	for a in Dati.AMBIZIONI:
		var gia := false
		for k in 3:
			if s["segnalini"][k]["amb"] == a:
				gia = true
		if not gia:
			ops.append({"t": "Dichiara " + Dati.NOME_AMBIZIONE[a], "v": a, "amb": a})
	if ops.is_empty():
		return
	_chiedi(p, i, "Quale ambizione dichiari?", ops, "ambizione")

func _p_tre_navi_imperiali(p: Dictionary) -> void:
	var i: int = p["g"]
	if _ha_r(p):
		var id: String = _r(p)
		var q := mini(3, G(imp())["navi"])
		s["mappa"][id]["navi"][imp()][0] += q
		G(imp())["navi"] -= q
		_log("%s mette %d navi Imperiali in %s." % [_nome(i), q, _desc_sis(id)])
		_ev({"tipo": "nave", "sis": id, "g": imp()})
		_h_navi_imperiali(q, id)
		return
	var ops := []
	for id in _sistemi_controllati(i):
		ops.append({"t": _desc_sis(id), "v": id, "sis": id})
	_chiedi(p, i, "Dove metti 3 navi Imperiali?", ops, "sistema")

# ================================================================ carte Gilda dei Destini: effetti continui
func _h_dichiara(i: int, amb: String) -> void:
	super(i, amb)
	if not s.has("camp"):
		return
	# Maestri della Gilda: rubano una carta Gilda del seme dell'ambizione
	for c in G(i)["carte"].duplicate():
		if MAESTRI.has(c) and MAESTRI[c][0] == amb:
			for j in s["n"]:
				if j == i or ha_carta(j, "c22"):
					continue
				var preso := false
				for x in _gilde_di(j):
					if Dati.info(x)[2] == MAESTRI[c][1] and Dati.info(x)[3] >= 0:
						G(j)["carte"].erase(x)
						G(i)["carte"].append(x)
						_log("%s: %s ruba %s a %s." % [Dati.nome_corte(c), _nome(i), Dati.nome_corte(x), _nome(j)])
						preso = true
						break
				if preso:
					break
	# Flotte da Parata: 2 navi in una città Libera; il Fondatore diventa Fuorilegge nell'Atto I
	if ha_carta(i, "471_25"):
		for id in s["mappa"]:
			var libera := false
			for ed in s["mappa"][id]["edifici"]:
				if ed != null and ed["g"] == lib() and ed["t"] == "citta":
					libera = true
			if libera:
				_metti_navi(i, id, 2, false)
				_log("Flotte da Parata: %s mette 2 navi in %s." % [_nome(i), _desc_sis(id)])
				break
		if reggente(i) and destino(i) == "fondatore" and atto() == 1:
			_lascia_impero(i)
	# Lega dei Mercanti: 2 risorse congelate sulla carta
	if ha_carta(i, "427_25"):
		var lega: Array = _dc().get("lega_%d" % i, [])
		for t in ["materiale", "carburante"]:
			if riserva(t) > 0 and lega.size() < 4:
				lega.append(t)
				s["fuori_risorse"][t] = int(s["fuori_risorse"].get(t, 0)) + 1
		_dc()["lega_%d" % i] = lega

func simboli(i: int, t: String) -> int:
	var n: int = super(i, t)
	if s.has("camp") and C().has("carte_dest") and i >= 0 and i < s["n"]:
		n += _dc().get("lega_%d" % i, []).count(t)
	return n

func _h_acquisita(i: int, c: String) -> void:
	super(i, c)
	# Confidenti del Consiglio
	if s.has("camp") and Dati.info(c)[1] == "gilda" and ha_carta(i, "463_10") and C()["consiglio"] != "sessione":
		C()["consiglio"] = "sessione"
		_log("Confidenti del Consiglio: il Consiglio Imperiale torna In Sessione.")

func _h_dopo_punteggio(calcolate: Dictionary) -> void:
	super(calcolate)
	if not s.has("camp"):
		return
	# Cartelli dei Destini: i Rivali scartano quella risorsa
	for i in s["n"]:
		for c in CARTELLI:
			if ha_carta(i, c):
				for j in s["n"]:
					if j != i:
						while _togli_risorsa(j, CARTELLI[c]):
							pass

## Seppellisci le carte che lo richiedono quando si diventa Fuorilegge.
func _lascia_impero(i: int) -> void:
	super(i)
	for c in G(i)["carte"].duplicate():
		if c in RINNEGATI or c in ["479_19", "463_20"]:
			G(i)["carte"].erase(c)
			s["mazzo_corte"].append(c)
			_log("%s seppellisce %s." % [_nome(i), Dati.nome_corte(c)])

## Armistizio nella Corte: i Membri della Confederazione non si attaccano né attaccano gli edifici Liberi.
func _avversari(i: int, id: String) -> Array:
	var out: Array = super(i, id)
	if not s.has("camp") or not C().has("dest"):
		return out
	var armistizio := false
	for slot in s["corte"]:
		if VOX.get(slot["c"], "") == "armistizio":
			armistizio = true
	var membri: Array = D_().get("membri", [])
	if armistizio and i in membri:
		out = out.filter(func(j): return j != lib() and not j in membri)
	return out
