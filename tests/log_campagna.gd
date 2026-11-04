extends SceneTree
func _init() -> void:
	var m := MotoreCampagna.new()
	m.nuova_partita({"n": 3, "nomi": ["A","B","C"], "ia": [true,true,true], "seme": 4242, "campagna": true})
	var ai := IA.new()
	var k := 0
	while not m.s["fine"] and k < 3000:
		m.scegli(ai.scegli(m, m.attesa()))
		k += 1
	for l in m.s["log"]:
		if "Dado" in l or "Crisi" in l or "Editti" in l or "Consiglio" in l or "Vertice" in l or "Piaga" in l or "Politica" in l or "Primo" in l or "Fuorilegge" in l or "Evento" in l or "Tesoro" in l or "Fine" in l or "Capitolo" in l or "Liber" in l:
			print(l)
	quit()
