extends SceneTree
func _init() -> void:
	var m := Motore.new()
	m.nuova_partita({"n": 4, "seme": 5, "leader": true})
	var ai := IA.new()
	var tempi := []
	for k in 250:
		var a := m.attesa()
		if a.is_empty():
			break
		var t0 := Time.get_ticks_usec()
		m.scegli(ai.scegli(m, a))
		tempi.append(Time.get_ticks_usec() - t0)
	tempi.sort()
	print("dimensione stato: ", var_to_str(m.s).length(), "  ia mediana ms ", tempi[tempi.size() / 2] / 1000.0, " p95 ", tempi[int(tempi.size() * 0.95)] / 1000.0, " max ", tempi[-1] / 1000.0)
	quit()
