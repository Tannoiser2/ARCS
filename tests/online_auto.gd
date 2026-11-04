extends SceneTree
## Prova online: due istanze (host e ospite) giocano sul finto Firebase; le decisioni umane le prende l'IA.
## ARCS_ROLE=host|guest ARCS_CODEFILE=file  (più FR_DB_URL, FR_AUTH_URL, FR_REFRESH_URL, FR_SESSION)
var main
func _initialize():
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()
func _w(s: float):
	await create_timer(s).timeout
func _run():
	await _w(0.3)
	var role := OS.get_environment("ARCS_ROLE")
	var cf := OS.get_environment("ARCS_CODEFILE")
	var maxd := int(OS.get_environment("ARCS_MAXD")) if OS.get_environment("ARCS_MAXD") != "" else 150
	main.scelta_n = 3
	main.scelta_leader = true
	main._menu_online()
	main.on_nome.text = "Host" if role == "host" else "Ospite"
	if role == "host":
		await main._online_crea()
		var f := FileAccess.open(cf, FileAccess.WRITE)
		f.store_string(main.codice)
		f.close()
		while true:
			var room: Dictionary = await main.net.room(main.codice)
			if Rete._as_dict(room.get("seats", {})).size() >= 2:
				break
			await _w(0.4)
		await main._online_inizia()
	else:
		var code := ""
		while code == "":
			if FileAccess.file_exists(cf):
				code = FileAccess.get_file_as_string(cf).strip_edges()
			await _w(0.3)
		main.on_codice.text = code
		await main._online_entra()
		while not main.in_partita:
			await _w(0.3)
	main.velocita = 60.0
	var ia := IA.new()
	var t0 := Time.get_ticks_msec()
	while not main.m.s["fine"] and int(main.m.s["decisioni"]) < maxd and Time.get_ticks_msec() - t0 < 300000:
		await process_frame
		var a: Dictionary = main.m.attesa()
		if not a.is_empty() and main.umano(a["g"]) and main.mostrata == int(main.m.s["decisioni"]):
			main.mostrata = -5
			await main._decidi(ia.scegli(main.m, a))
	print("ARCS fine ", role, " decisioni ", main.m.s["decisioni"], " impronta ", str(main.m.s["g"]).hash(), " ", str(main.m.s["mappa"]).hash())
	quit()
