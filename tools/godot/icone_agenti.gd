## Crea le icone 2D degli agenti (miniatura fornita dall'utente) per ogni colore.
## xvfb-run godot --path . -s res://tools/godot/icone_agenti.gd
extends SceneTree

func _init() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(128, 128)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var mondo := Node3D.new()
	vp.add_child(mondo)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 28.0
	cam.position = Vector3(0, 12.8, 40)
	cam.rotation_degrees = Vector3(0, 0, 0)
	mondo.add_child(cam)
	var luce := DirectionalLight3D.new()
	luce.rotation_degrees = Vector3(-40, -35, 0)
	luce.light_energy = 1.3
	mondo.add_child(luce)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.55, 0.6)
	e.background_mode = Environment.BG_CLEAR_COLOR
	env.environment = e
	mondo.add_child(env)
	var scena: Node = load("res://assets/3d/agente_mini.glb").instantiate()
	mondo.add_child(scena)
	var mesh: MeshInstance3D = _trova(scena)
	for c in ["bianco", "giallo", "verde", "rosso", "impero", "liberi"]:
		var mt := StandardMaterial3D.new()
		mt.albedo_color = Dati.TINTA[c]
		mt.roughness = 0.5
		mt.metallic = 0.2
		mesh.material_override = mt
		for k in 4:
			await process_frame
		var img := vp.get_texture().get_image()
		img.save_png("res://assets/ui/agente_%s.png" % c)
		print("agente ", c)
	quit()

func _trova(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D:
		return n
	for c in n.get_children():
		var r := _trova(c)
		if r != null:
			return r
	return null
