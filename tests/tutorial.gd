## Registra una partita per il tutorial: traccia di ogni decisione e foto ai passi richiesti.
## FOTO_RES=1366x1024 ARCS_SEME=... xvfb-run godot --path . -s res://tests/tutorial.gd -- GIOCATORI PASSI_MAX [foto1,foto2,...]
extends SceneTree

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 3
	var passi := int(args[1]) if args.size() > 1 else 400
	var foto := []
	if args.size() > 2:
		for x in args[2].split(","):
			foto.append(int(x))
	var res := OS.get_environment("FOTO_RES")
	var dim := Vector2i(1366, 1024) if res == "" else Vector2i(int(res.split("x")[0]), int(res.split("x")[1]))
	DisplayServer.window_set_size(dim)
	root.size = dim
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.scelta_n = n
	main.scelta_umani = [true, false, false, false]
	main._avvia_locale()
	main.velocita = 0.0
	main.m.s["log_max"] = 100000
	var ia := IA.new()
	var traccia := FileAccess.open("/tmp/tut_traccia.txt", FileAccess.WRITE)
	var visti: int = main.m.s["log"].size()
	var forzate := {}
	for x in OS.get_environment("TUT_SCELTE").split(";", false):
		forzate[int(x.split(":")[0])] = x.substr(x.find(":") + 1)
	for k in passi:
		var a: Dictionary = main.m.attesa()
		if a.is_empty() or int(main.m.s["capitolo"]) > 1 and not foto.is_empty() and k > foto.max():
			break
		if k in foto:
			main.m.s["eventi"] = []
			main.mostrata = -1
			main._aggiorna_tutto()
			await _attendi(40)
			var img := root.get_viewport().get_texture().get_image()
			img.save_png("/tmp/tut_%03d.png" % k)
			print("foto ", k)
			a = main.m.attesa()
		var scelta: int = ia.scegli(main.m, a)
		if forzate.has(k):
			var ops0: Array = a.get("opzioni", [])
			for q in ops0.size():
				if str(ops0[q].get("t", "")).begins_with(forzate[k]):
					scelta = q
					break
		var g: int = a.get("g", -1)
		traccia.store_line("#%d cap%d g%d [%s] %s" % [k, main.m.s["capitolo"], g, a.get("tipo", ""), a.get("testo", "")])
		if g == 0:
			var ops: Array = a.get("opzioni", [])
			for q in ops.size():
				traccia.store_line("    %s %s" % ["=>" if q == scelta else "  ", ops[q].get("t", "")])
		main.m.scegli(scelta)
		var lg: Array = main.m.s["log"]
		for q in range(visti, lg.size()):
			traccia.store_line("  | " + str(lg[q]))
		visti = lg.size()
		if int(main.m.s["capitolo"]) > 1 and foto.is_empty():
			traccia.store_line("FINE CAPITOLO al passo %d" % k)
			break
	traccia.close()
	quit()

func _attendi(n: int) -> void:
	for k in n:
		await process_frame
