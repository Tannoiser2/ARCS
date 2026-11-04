extends SceneTree
func _init() -> void:
	var m := Motore.new()
	m.nuova_partita({"n": 4, "seme": 5})
	var ai := IA.new()
	var t := 0
	var k := 0
	var peggiore := 0
	var tipo_p := ""
	while not m.s["fine"] and k < 200:
		var a := m.attesa()
		var t0 := Time.get_ticks_usec()
		var c := ai.scegli(m, a)
		var dt := Time.get_ticks_usec() - t0
		t += dt
		if dt > peggiore:
			peggiore = dt
			tipo_p = a.get("tipo", "") + " " + str(a["opzioni"].size())
		m.scegli(c)
		k += 1
	print("ia media ms ", t / k / 1000.0, " peggiore ms ", peggiore / 1000, " ", tipo_p)
	quit()
