## Partita intera passando dall'interfaccia: il posto umano sceglie con l'IA ma tramite main._decidi.
## xvfb-run godot --path . -s res://tests/ui_auto.gd -- DECISIONI [leader]
extends SceneTree

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var maxd := int(args[0]) if args.size() > 0 else 300
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.scelta_n = 3
	main.scelta_umani = [true, false, true, false]
	main.scelta_leader = args.size() > 1 and args[1] == "leader"
	main.scelta_campagna = args.size() > 1 and args[1] == "campagna"
	main._avvia_locale()
	main.velocita = 200.0
	var ia := IA.new()
	var frames := 0
	while not main.m.s["fine"] and int(main.m.s["decisioni"]) < maxd and frames < 200000:
		await process_frame
		frames += 1
		if main.has_meta("cambio_aperto"):
			# schermata "passa il dispositivo": premi il pulsante
			main.remove_meta("cambio_aperto")
			main.mostrata = -1
			for c in main.schermo.get_children():
				if c is ColorRect and c.color.a > 0.9:
					c.queue_free()
			continue
		var a: Dictionary = main.m.attesa()
		if a.is_empty():
			continue
		if main.umano(a["g"]) and main.mostrata == int(main.m.s["decisioni"]):
			main._decidi(ia.scegli(main.m, a))
	print("decisioni ", main.m.s["decisioni"], " capitolo ", main.m.s["capitolo"], " fine ", main.m.s["fine"], " frame ", frames)
	quit()
