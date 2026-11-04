extends SceneTree
func _init() -> void:
	var m := Motore.new()
	var n := int(OS.get_cmdline_user_args()[0]) if OS.get_cmdline_user_args().size() > 0 else 3
	m.nuova_partita({"n": n, "seme": 77, "leader": true})
	var ai := IA.new()
	var k := 0
	while not m.s["fine"] and k < 3000:
		m.scegli(ai.scegli(m, m.attesa()))
		k += 1
	print("\n".join(m.s["log"]))
	quit()
