## Verifiche mirate delle regole dei Destini: godot --headless --path . -s res://tests/prova_destini.gd
extends SceneTree

var errori := 0

func controlla(cond: bool, cosa: String) -> void:
	if cond:
		print("ok   ", cosa)
	else:
		errori += 1
		print("ERRORE ", cosa)

func nuova() -> MotoreOrlo:
	var m := MotoreOrlo.new()
	m.nuova_partita({"n": 3, "nomi": ["A", "B", "C"], "ia": [true, true, true], "seme": 4242, "campagna": true})
	var ai := IA.new()
	# fino alla prima decisione di gioco dopo la scelta dei Destini
	var k := 0
	while k < 40 and m.C()["destino"].has(""):
		m.scegli(ai.scegli(m, m.attesa()))
		k += 1
	return m

func _init() -> void:
	var ai := IA.new()
	var k := 0
	var m := nuova()
	controlla(not m.C()["destino"].has(""), "tutti hanno un Destino")
	controlla(m.obiettivo(0) > 0, "segnalino obiettivo sulla casella di partenza")
	# avanzamento
	var prima := m.obiettivo(0)
	m.avanza(0, 2)
	controlla(m.obiettivo(0) == prima - 2, "avanza di 2")
	# Dividendi della Pace
	var pw: int = m.G(0)["potere"]
	m._editto_extra("442_01")
	controlla(m.G(0)["potere"] >= pw, "Dividendi della Pace non tolgono Potere")
	# Signore Supremo
	m.C()["destino"][1] = "signore"
	m.G(1)["oltraggio"] = ["armi", "reliquie"]
	pw = m.G(1)["potere"]
	m._editto_extra("450_00")
	controlla(m.G(1)["potere"] == pw - 3, "Signore Supremo con 2 Oltraggi perde 3 Potere")
	# Guardia dell'Eden
	m.C()["libretto"].append("473_00")
	m.C()["destino"][2] = "guardiano"
	m.D()["sostitute"] = {}
	m._scegli_sostituta(2, "magnate")
	controlla(m.D()["sostitute"].get("magnate", "") == "eden", "il Guardiano dichiara Guardia dell'Eden")
	controlla(m.nome_ambizione("magnate") == "Guardia dell'Eden", "nome dell'ambizione sostituta")
	# Supremazia delle Gilde
	m.G(0)["carte"] = ["c01"]
	var t: String = Dati.info("c01")[2]
	var v1 := m.simboli(0, t)
	m.C()["libretto"].append("428_01")
	controlla(m.simboli(0, t) == v1 + 1, "Supremazia delle Gilde: la Gilda conta doppio")
	# Confederazione
	m.D()["membri"] = [0, 1]
	m.s["segnalini"][0]["amb"] = "tiranno"
	var g := [0, 0, 0]
	m._confederazione("tiranno", [2, 2, 3], 0, g)
	controlla(g[0] > 0 and g[0] == g[1] and g[2] == 0, "la Confederazione vince e divide il Potere")
	# Ammiraglia con Raggio Traente
	m.C()["destino"][0] = "pirata"
	m._spec_destino(0, "pirata", "ammiraglia")
	m.D()["migliorie_0"] = "raggio=porto,difesa=porto"
	var dove := m.ammiraglia(0)
	controlla(dove != "", "l'Ammiraglia è sulla mappa")
	controlla(not m._razzia_permessa(dove, 0), "Raggio Traente impedisce la razzia")
	controlla(m._intercetta_extra(0, dove) == 2, "Sistema Difensivo: 2 colpi con 2 spazioporti")
	# Intervallo fino all'Atto II
	m.C()["obiettivo"][0] = 0
	m.s["pila"] = [{"k": "intervallo", "fase": 0}]
	m.s["attesa"] = {}
	ai = IA.new()
	k = 0
	m._avanza()
	while k < 200 and int(m.C()["atto"]) == 1:
		var a := m.attesa()
		if a.is_empty():
			break
		m.scegli(ai.scegli(m, a))
		k += 1
	controlla(int(m.C()["atto"]) == 2, "dopo l'Intervallo comincia l'Atto II")
	print("errori: ", errori)
	quit()
