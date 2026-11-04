## Partite automatiche tutte IA: godot --headless --path . -s res://tests/sim.gd -- PARTITE GIOCATORI [leader]
extends SceneTree

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var partite := int(args[0]) if args.size() > 0 else 10
	var n := int(args[1]) if args.size() > 1 else 4
	var con_leader := args.size() > 2 and args[2] == "leader"
	var vittorie := {}
	var capitoli := 0
	var decisioni := 0
	var t0 := Time.get_ticks_msec()
	for k in partite:
		var m := Motore.new()
		var nomi := []
		var ia := []
		for i in n:
			nomi.append("IA %d" % (i + 1))
			ia.append(true)
		m.nuova_partita({"n": n, "nomi": nomi, "ia": ia, "seme": 1000 + k * 7919, "leader": con_leader})
		var ai := IA.new()
		var passi := 0
		while not m.s["fine"] and passi < 6000:
			var a := m.attesa()
			if a.is_empty():
				push_error("partita %d bloccata senza attesa" % k)
				break
			m.scegli(ai.scegli(m, a))
			passi += 1
		if not m.s["fine"]:
			push_error("partita %d non finita dopo %d decisioni (capitolo %d)" % [k, passi, m.s["capitolo"]])
			print("\n".join(m.s["log"].slice(-30)))
		else:
			vittorie[m.s["vincitore"]] = vittorie.get(m.s["vincitore"], 0) + 1
			capitoli += m.s["capitolo"]
		decisioni += passi
		var poteri := []
		for i in n:
			poteri.append(m.s["g"][i]["potere"])
		print("partita %d: vince %d, capitolo %d, potere %s, decisioni %d" % [k, m.s["vincitore"], m.s["capitolo"], str(poteri), passi])
	print("vittorie %s, capitoli medi %.1f, decisioni medie %d, %d ms" % [str(vittorie), float(capitoli) / max(1, partite), decisioni / max(1, partite), Time.get_ticks_msec() - t0])
	quit()
