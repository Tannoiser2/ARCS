## Registro di una campagna completa con i Destini: godot --headless --path . -s res://tests/log_destini.gd -- SEME GIOCATORI
extends SceneTree
func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var seme := int(a[0]) if a.size() > 0 else 4242
	var n := int(a[1]) if a.size() > 1 else 3
	var m := MotoreOrlo.new()
	var nomi := []
	var ia := []
	for i in n:
		nomi.append("IA%d" % i)
		ia.append(true)
	# forza i Destini: LETTERA=destino,...
	var forza := {}
	if a.size() > 2:
		for x in a[2].split(","):
			forza[x.split("=")[0]] = x.split("=")[1]
	m.nuova_partita({"n": n, "nomi": nomi, "ia": ia, "seme": seme, "campagna": true, "forza": forza})
	m.s["log_max"] = 100000
	var ai := IA.new()
	var k := 0
	while not m.s["fine"] and k < 8000:
		m.scegli(ai.scegli(m, m.attesa()))
		k += 1
	var parole := ["Destino", "obiettivo", "Atto", "Intervallo", "libretto", "prende", "Potere", "vince", "campagna", "iniziativa", "Fine del capitolo", "ambizione"]
	for l in m.s["log"]:
		for w in parole:
			if w in l:
				print(l)
				break
	quit()
