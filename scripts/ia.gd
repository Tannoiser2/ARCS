## Intelligenza artificiale: valuta ogni opzione simulando la scelta su una copia della partita
## e guardando come cambia la posizione (Potere, ambizioni, flotta, edifici, risorse, mano).
class_name IA
extends RefCounted

const RAMIFICAZIONE := ["turno", "guida", "segui", "dichiara", "sottrai"]
var rng := RandomNumberGenerator.new()
var facile := false

func _init() -> void:
	rng.seed = 4242

func scegli(m: Motore, a: Dictionary) -> int:
	var ops: Array = a["opzioni"]
	if ops.size() <= 1:
		return 0
	# stesso stato = stessa scelta su tutti i dispositivi (partite online)
	rng.seed = int(m.s["rng"]) * 31 + int(m.s["decisioni"]) * 2654435761
	var me: int = a["g"]
	var tipo: String = a.get("tipo", "")
	match tipo:
		"draft":
			return _draft(ops)
		"mulligan":
			var m_val := 0.0
			for c in m.s["g"][me]["mano"]:
				m_val += Dati.punti(c) + Dati.valore(c) * 0.3
			return 1 if m_val < 15.0 else 0
		"dadi":
			return _dadi(m, a)
	var profondo: bool = tipo in RAMIFICAZIONE
	var best := 0
	var bv := -INF
	for i in ops.size():
		var v := _valuta(m, me, i, profondo)
		v += rng.randf() * (6.0 if facile else 0.05)
		if v > bv:
			bv = v
			best = i
	return best

func _draft(ops: Array) -> int:
	var rank := ["edonista", "demagogo", "mistico", "arrivista", "guerriero", "antico", "ribelle", "divoratore",
		"l13", "l10", "l01", "l14", "l03", "l12", "l09", "l05", "l07", "l06", "l04", "l08", "l02", "l11"]
	var best := 0
	var bi := 999
	for i in ops.size():
		var v := str(ops[i]["v"])
		var k := rank.find(v)
		if k >= 0 and k < bi:
			bi = k
			best = i
	return best

## Dadi: Assalto se si è nettamente più forti, altrimenti Incursione; Razzia se c'è qualcosa da prendere.
func _dadi(m: Motore, a: Dictionary) -> int:
	var p: Dictionary = a["passo"]
	var me: int = a["g"]
	var j: int = p["dif"]
	var id: String = p["sis"]
	var mie: int = m.navi(id, me)
	var loro: int = m.navi(id, j)
	var ops: Array = a["opzioni"]
	var massimo: int = ops[0]["v"]
	var forte := mie >= loro * 2 + 1 or loro == 0
	var bottino := 0
	for r in m.s["g"][j]["risorse"]:
		if r != "":
			bottino += 1
	bottino += m.s["g"][j]["carte"].size()
	var tipo_d: String = ops[0].get("dadi", ["", 0])[0]
	var voglio := 0
	match tipo_d:
		"assalto":
			voglio = massimo if forte else 0
			if forte and bottino > 0 and loro <= 1:
				voglio = maxi(0, massimo - 2)
		"incursione":
			voglio = massimo
			if bottino > 0 and loro == 0:
				voglio = maxi(0, massimo - 2)
		"razzia":
			voglio = massimo if bottino > 0 else 0
	for i in ops.size():
		if int(ops[i]["v"]) == voglio:
			return i
	return 0

func _copia(m: Motore) -> Motore:
	var log = m.s["log"]
	var ev = m.s["eventi"]
	m.s["log"] = []
	m.s["eventi"] = []
	var c := Motore.new()
	c.s = m.s.duplicate(true)
	c.adj = m.adj
	m.s["log"] = log
	m.s["eventi"] = ev
	# i dadi della simulazione non devono rivelare quelli veri
	c.s["rng"] = (int(c.s["rng"]) * 1103515245 + 12345 + rng.randi()) & 0xFFFFFFFF
	if c.s["rng"] == 0:
		c.s["rng"] = 7
	return c

func _valuta(m: Motore, me: int, i: int, profondo: bool) -> float:
	var c := _copia(m)
	c.scegli(i)
	if profondo:
		# prosegue con scelte rapide finché tocca ancora a me nello stesso turno
		var passi := 0
		while passi < 14 and not c.s["fine"]:
			var a := c.attesa()
			if a.is_empty() or a["g"] != me:
				break
			var t: String = a.get("tipo", "")
			if t in ["guida", "segui"]:
				break
			var k := _rapida(c, me, a)
			c.scegli(k)
			passi += 1
	return valuta_posizione(c, me)

func _rapida(c: Motore, me: int, a: Dictionary) -> int:
	var ops: Array = a["opzioni"]
	if ops.size() <= 1:
		return 0
	var t: String = a.get("tipo", "")
	if t == "dadi":
		return _dadi(c, a)
	var best := 0
	var bv := -INF
	for i in ops.size():
		var x := _copia(c)
		x.scegli(i)
		var v := valuta_posizione(x, me)
		if v > bv:
			bv = v
			best = i
	return best

# ---------------------------------------------------------------- valutazione
func valuta_posizione(m: Motore, me: int) -> float:
	var n: int = m.s["n"]
	if m.s["fine"]:
		return 1000.0 if m.s["vincitore"] == me else -1000.0
	var prev := m.potere_previsto()
	var mio := _punteggio(m, me, prev)
	var altri := 0.0
	var max_altri := -INF
	for j in n:
		if j == me:
			continue
		var v := _punteggio(m, j, prev)
		altri += v
		max_altri = maxf(max_altri, v)
	return mio - 0.35 * altri / maxf(1, n - 1) - 0.35 * max_altri

func _punteggio(m: Motore, i: int, prev: Array) -> float:
	var g: Dictionary = m.s["g"][i]
	var v := 0.0
	v += g["potere"] * 10.0
	# ambizioni dichiarate: Potere atteso (più sicuro verso fine capitolo)
	var carte_rimaste := 0
	for j in m.s["n"]:
		carte_rimaste += m.s["g"][j]["mano"].size()
	var certezza: float = 0.55 + 0.45 * (1.0 - carte_rimaste / (6.0 * m.s["n"]))
	v += prev[i] * 9.0 * certezza
	# ambizioni non dichiarate in cui si è in testa
	for amb in Dati.AMBIZIONI:
		var pts := m.classifica_ambizione(amb)
		var mx := 0
		for k in pts.size():
			if k != i:
				mx = maxi(mx, pts[k])
		if pts[i] > mx:
			v += 1.2
		v += pts[i] * 0.6
	# flotta ed edifici
	for id in m.s["mappa"]:
		var nv: Array = m.s["mappa"][id]["navi"][i]
		var mio_ed := false
		for e in m.s["mappa"][id]["edifici"]:
			if e != null and e["g"] == i:
				mio_ed = true
				if e["t"] == "citta":
					v += 2.5 if e["danno"] else 4.5
				else:
					v += 2.0 if e["danno"] else 3.2
		v += nv[0] * 1.5 + nv[1] * 0.8
		var c := m.controllo(id)
		if c == i:
			if mio_ed:
				v += 1.2
			for e in m.s["mappa"][id]["edifici"]:
				if e != null and e["g"] != i:
					v += 1.5
	v += m.bonus_citta(i) * 0.6
	# risorse e carte
	for r in g["risorse"]:
		if r != "":
			v += 1.6
	if g["antichi"] != "":
		v += 1.6
	v += g["carte"].size() * 2.6
	v -= g["oltraggio"].size() * 2.2
	v += g["trofei"].size() * 0.7 + g["prigionieri"].size() * 0.7
	# corte
	for slot in m.s["corte"]:
		var a: int = slot["ag"][i]
		if a <= 0:
			continue
		var testa := true
		for j in m.s["n"]:
			if j != i and slot["ag"][j] >= a:
				testa = false
		v += a * (0.9 if testa else 0.35) + (1.5 if testa else 0.0)
	v += g["agenti"] * 0.15
	# mano e iniziativa
	for c in g["mano"]:
		v += 1.3 + Dati.punti(c) * 0.9 + Dati.valore(c) * 0.12
	if m.s["iniz"] == i or m.s["sottratta"] == i:
		v += 2.5
	return v
