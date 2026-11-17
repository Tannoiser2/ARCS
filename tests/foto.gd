## Screenshot dell'interfaccia: xvfb-run godot --path . -s res://tests/foto.gd -- NOME PASSI_IA
extends SceneTree

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var nome := args[0] if args.size() > 0 else "partita"
	var passi := int(args[1]) if args.size() > 1 else 40
	var res := OS.get_environment("FOTO_RES")
	var dim := Vector2i(1600, 1000)
	if res != "":
		dim = Vector2i(int(res.split("x")[0]), int(res.split("x")[1]))
	DisplayServer.window_set_size(dim)
	root.size = dim
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	if nome == "menu" or nome.begins_with("menu_"):
		await _attendi(20)
		if nome.begins_with("menu_"):
			main.call("_" + nome)
			await _attendi(30)
		_scatta(nome)
		quit()
		return
	var dopo := OS.get_environment("FOTO_DOPO")
	main.scelta_n = 4 if nome != "due" else 2
	main.scelta_umani = [true, false, false, false]
	main.scelta_leader = nome == "leader"
	main.scelta_campagna = nome == "campagna"
	main._avvia_locale()
	main.velocita = 50.0
	# l'IA gioca anche per il giocatore umano fino al punto richiesto
	var ia := IA.new()
	for k in passi:
		var a: Dictionary = main.m.attesa()
		if a.is_empty():
			break
		main.m.scegli(ia.scegli(main.m, a))
	main.m.s["eventi"] = []
	main.mostrata = -1
	main._aggiorna_tutto()
	await _attendi(40)
	if dopo != "":
		main.call(dopo)
		await _attendi(30)
	_scatta(nome)
	if args.size() > 2:
		main.plancia.dist = float(args[2])
		main.plancia.pitch = -40.0
		if args.size() > 3:
			main.plancia.centro = main.plancia.pos(args[3])
		main.plancia._aggiorna_camera()
		await _attendi(20)
		_scatta(nome + "_vicino")
	quit()

func _attendi(n: int) -> void:
	for k in n:
		await process_frame

func _scatta(nome: String) -> void:
	var img := root.get_viewport().get_texture().get_image()
	var suff := OS.get_environment("FOTO_RES")
	var f := "/tmp/foto_%s%s.png" % [nome, "_" + suff if suff != "" else ""]
	img.save_png(f)
	print("foto salvata ", f)
