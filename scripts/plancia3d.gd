## Il tavolo 3D: la mappa dell'Orlo, le navi (modelli del modulo TTS), città e spazioporti,
## la telecamera che si gira col mouse e gli effetti di luce delle azioni.
class_name Plancia3D
extends Node3D

signal sistema_cliccato(id: String)

const BW := 20.0
const BH := 20.0 * 2836.0 / 4096.0

var m: Motore
var cam: Camera3D
var perno: Node3D
var pezzi: Node3D
var evidenze: Node3D
var effetti: Node3D
var luce: DirectionalLight3D
var yaw := 0.0
var pitch := -66.0
var dist := 18.5
var centro := Vector3(0, 0, 0.35)
var trascina := false
var sposta := false
var ultimo_mouse := Vector2.ZERO
var mesh_nave: Mesh
var mesh_citta: Mesh
var mesh_porto: Mesh
var mesh_nave_danno: Mesh
var mat_nave := {}
var mat_danno := {}
var mat_citta := {}
var mat_porto := {}
var t := 0.0
var selezionabili := {}

func _ready() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	var sky := Sky.new()
	var pm := PanoramaSkyMaterial.new()
	pm.panorama = load("res://assets/3d/cielo.webp")
	pm.energy_multiplier = 2.2
	sky.sky_material = pm
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.58, 0.72)
	e.ambient_light_energy = 0.55
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.glow_enabled = true
	e.glow_intensity = 0.9
	e.glow_bloom = 0.08
	e.glow_hdr_threshold = 0.9
	env.environment = e
	add_child(env)
	luce = DirectionalLight3D.new()
	luce.rotation_degrees = Vector3(-55, -30, 0)
	luce.light_energy = 1.25
	luce.light_color = Color(1.0, 0.95, 0.86)
	luce.shadow_enabled = true
	add_child(luce)
	var riemp := DirectionalLight3D.new()
	riemp.rotation_degrees = Vector3(-35, 150, 0)
	riemp.light_energy = 0.35
	riemp.light_color = Color(0.55, 0.65, 1.0)
	add_child(riemp)
	perno = Node3D.new()
	add_child(perno)
	cam = Camera3D.new()
	cam.fov = 45
	perno.add_child(cam)
	_aggiorna_camera()
	# tavolo e mappa
	var tavolo := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(BW + 1.2, 0.3, BH + 1.2)
	tavolo.mesh = tm
	tavolo.position = Vector3(0, -0.17, 0)
	var tmat := StandardMaterial3D.new()
	tmat.albedo_color = Color(0.09, 0.07, 0.06)
	tmat.roughness = 0.6
	tmat.metallic = 0.2
	tavolo.material_override = tmat
	add_child(tavolo)
	var mappa := MeshInstance3D.new()
	var pl := PlaneMesh.new()
	pl.size = Vector2(BW, BH)
	mappa.mesh = pl
	var mm := StandardMaterial3D.new()
	mm.albedo_texture = load("res://assets/3d/mappa.webp")
	mm.roughness = 0.75
	mm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	mappa.material_override = mm
	add_child(mappa)
	pezzi = Node3D.new()
	add_child(pezzi)
	evidenze = Node3D.new()
	add_child(evidenze)
	effetti = Node3D.new()
	add_child(effetti)
	_prepara_modelli()

func _prepara_modelli() -> void:
	mesh_nave = _prima_mesh(load("res://assets/3d/nave.glb"))
	mesh_nave_danno = _prima_mesh(load("res://assets/3d/nave_danno.glb"))
	mesh_citta = _prima_mesh(load("res://assets/3d/citta.glb"))
	mesh_porto = _prima_mesh(load("res://assets/3d/porto.glb"))
	var tex_n := _tex(mesh_nave)
	var tex_d := _tex(mesh_nave_danno)
	for c in Dati.COLORI + ["impero", "piaga", "liberi"]:
		var col: Color = Dati.TINTA[c]
		var a := StandardMaterial3D.new()
		a.albedo_texture = tex_n
		a.albedo_color = col.lightened(0.15)
		a.metallic = 0.45
		a.roughness = 0.4
		a.rim_enabled = true
		a.rim = 0.4
		mat_nave[c] = a
		var b := StandardMaterial3D.new()
		b.albedo_texture = tex_d
		b.albedo_color = col.darkened(0.25)
		b.metallic = 0.3
		b.roughness = 0.7
		mat_danno[c] = b
		var ct := StandardMaterial3D.new()
		ct.albedo_color = col
		ct.metallic = 0.25
		ct.roughness = 0.45
		ct.emission_enabled = true
		ct.emission = col * 0.35
		mat_citta[c] = ct
		var pt := StandardMaterial3D.new()
		pt.albedo_color = col.darkened(0.1)
		pt.metallic = 0.6
		pt.roughness = 0.35
		mat_porto[c] = pt

func _prima_mesh(scena: PackedScene) -> Mesh:
	var n := scena.instantiate()
	var mi := _trova_mesh(n)
	var mesh: Mesh = mi.mesh if mi else BoxMesh.new()
	n.free()
	return mesh

func _trova_mesh(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D:
		return n
	for c in n.get_children():
		var r := _trova_mesh(c)
		if r:
			return r
	return null

func _tex(mesh: Mesh) -> Texture2D:
	var mat := mesh.surface_get_material(0)
	if mat is StandardMaterial3D:
		return mat.albedo_texture
	return null

# ---------------------------------------------------------------- coordinate
static func pos(id: String) -> Vector3:
	var uv := Dati.uv(Dati.POS[id])
	return Vector3((uv.x - 0.5) * BW, 0.0, (uv.y - 0.5) * BH)

static func pos_uv(p: Vector2) -> Vector3:
	var uv := Dati.uv(p)
	return Vector3((uv.x - 0.5) * BW, 0.0, (uv.y - 0.5) * BH)

static func pos_edificio(id: String, k: int) -> Vector3:
	if Dati.POS_EDIFICI.has(id) and k < Dati.POS_EDIFICI[id].size():
		return pos_uv(Dati.POS_EDIFICI[id][k])
	var c := pos(id)
	var ang := 0.9 + k * 1.3
	return c + Vector3(cos(ang), 0, sin(ang)) * 0.45

# ---------------------------------------------------------------- telecamera
func _aggiorna_camera() -> void:
	perno.position = centro
	perno.rotation_degrees = Vector3(pitch, yaw, 0)
	cam.position = Vector3(0, 0, dist)

func ruota(dx: float, dy: float) -> void:
	yaw -= dx
	pitch = clampf(pitch - dy, -88.0, -18.0)
	_aggiorna_camera()

func zoom(f: float) -> void:
	dist = clampf(dist * f, 5.0, 30.0)
	_aggiorna_camera()

func vista_iniziale() -> void:
	yaw = 0.0
	pitch = -66.0
	dist = 18.5
	centro = Vector3(0, 0, 0.35)
	_aggiorna_camera()

func vista_alto() -> void:
	yaw = 0.0
	pitch = -88.0
	dist = 16.5
	centro = Vector3(0, 0, 0)
	_aggiorna_camera()

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			zoom(0.9)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			zoom(1.1)
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				trascina = true
				ultimo_mouse = mb.position
				set_meta("mosso", 0.0)
			else:
				if trascina and float(get_meta("mosso", 0.0)) < 6.0:
					_clic(mb.position)
				trascina = false
		elif mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_MIDDLE:
			sposta = mb.pressed
			ultimo_mouse = mb.position
	elif ev is InputEventMouseMotion:
		var mm := ev as InputEventMouseMotion
		if trascina:
			set_meta("mosso", float(get_meta("mosso", 0.0)) + mm.relative.length())
			if float(get_meta("mosso", 0.0)) >= 6.0:
				ruota(mm.relative.x * 0.3, mm.relative.y * 0.25)
		elif sposta:
			var dx := mm.relative.x * dist * 0.0012
			var dz := mm.relative.y * dist * 0.0012
			var b := cam.global_transform.basis
			var avanti := Vector3(b.z.x, 0, b.z.z).normalized()
			var destra := Vector3(b.x.x, 0, b.x.z).normalized()
			centro -= destra * dx + avanti * dz
			centro.x = clampf(centro.x, -BW * 0.5, BW * 0.5)
			centro.z = clampf(centro.z, -BH * 0.5, BH * 0.5)
			_aggiorna_camera()
	elif ev is InputEventMagnifyGesture:
		zoom(1.0 / (ev as InputEventMagnifyGesture).factor)

func _clic(p: Vector2) -> void:
	var o := cam.project_ray_origin(p)
	var d := cam.project_ray_normal(p)
	if absf(d.y) < 0.001:
		return
	var tt := -o.y / d.y
	var hit := o + d * tt
	var best := ""
	var bd := 1.0
	for id in Dati.POS:
		var dd := pos(id).distance_to(hit)
		if dd < bd:
			bd = dd
			best = id
	if best != "":
		sistema_cliccato.emit(best)

# ---------------------------------------------------------------- pezzi
func aggiorna(motore: Motore) -> void:
	m = motore
	for c in pezzi.get_children():
		c.queue_free()
	var colori: Array = []
	for i in m.s["g"].size():
		colori.append(m.s["g"][i]["colore"])
	for id in m.s["mappa"]:
		if not m.in_gioco(id):
			_fuori(id)
			continue
		var c0 := pos(id)
		var navi: Array = m.s["mappa"][id]["navi"]
		# navi: in gruppi per giocatore, attorno al centro del sistema
		var gruppi := []
		for i in navi.size():
			if navi[i][0] + navi[i][1] > 0:
				gruppi.append(i)
		for gi in gruppi.size():
			var i: int = gruppi[gi]
			var base := _centro_gruppo(id, gi, gruppi.size())
			var k := 0
			var tot: int = navi[i][0] + navi[i][1]
			for f in navi[i][0]:
				_nave(base + _offset(k, tot), colori[i], false, i, id)
				k += 1
			for f in navi[i][1]:
				_nave(base + _offset(k, tot), colori[i], true, i, id)
				k += 1
			if tot > 6:
				_etichetta_3d(base + Vector3(0, 0.75, 0), str(tot), Dati.TINTA[colori[i]])
		var ed: Array = m.s["mappa"][id]["edifici"]
		for k in ed.size():
			var e = ed[k]
			if e == null:
				continue
			var p := pos_edificio(id, k)
			if e["t"] == "citta":
				_citta(p, colori[e["g"]], e["danno"])
			else:
				_porto(p, colori[e["g"]], e["danno"])
		# chi controlla il sistema: un alone del suo colore
		var ctrl := m.controllo(id)
		if ctrl >= 0:
			var anello := MeshInstance3D.new()
			var tor := TorusMesh.new()
			tor.inner_radius = 0.5 if not Dati.is_portale(id) else 0.42
			tor.outer_radius = tor.inner_radius + 0.035
			anello.mesh = tor
			var am := StandardMaterial3D.new()
			am.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			am.albedo_color = Dati.TINTA[colori[ctrl]]
			am.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			am.albedo_color.a = 0.75
			anello.material_override = am
			anello.position = c0 + Vector3(0, 0.02, 0)
			pezzi.add_child(anello)

func _fuori(id: String) -> void:
	var d := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.85 if not Dati.is_portale(id) else 0.55
	cyl.bottom_radius = cyl.top_radius
	cyl.height = 0.03
	d.mesh = cyl
	var mt := StandardMaterial3D.new()
	mt.albedo_color = Color(0.0, 0.0, 0.02, 0.88)
	mt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mt.roughness = 0.9
	d.material_override = mt
	d.position = pos(id) + Vector3(0, 0.02, 0)
	pezzi.add_child(d)
	var x := Label3D.new()
	x.text = "FUORI DAL GIOCO"
	x.font = load("res://assets/font/Titoli.ttf")
	x.font_size = 40
	x.pixel_size = 0.004
	x.modulate = Color(0.75, 0.68, 0.5)
	x.rotation_degrees = Vector3(-90, 0, 0)
	x.position = pos(id) + Vector3(0, 0.05, 0)
	pezzi.add_child(x)

func _centro_gruppo(id: String, gi: int, n: int) -> Vector3:
	var c := pos(id)
	if n <= 1:
		return c + Vector3(0, 0, 0.12)
	var ang := -PI * 0.5 + TAU * gi / n
	return c + Vector3(cos(ang), 0, sin(ang)) * 0.32

func _offset(k: int, tot: int) -> Vector3:
	if tot <= 1:
		return Vector3.ZERO
	var cols := mini(3, tot)
	var r := k / cols
	var c := k % cols
	return Vector3((c - (cols - 1) * 0.5) * 0.3, 0, r * 0.24 - 0.14)

func _nave(p: Vector3, colore: String, danno: bool, _i: int, _id: String) -> void:
	if colore == "piaga":
		_piaga(p, danno)
		return
	var n := MeshInstance3D.new()
	n.mesh = mesh_nave_danno if danno else mesh_nave
	n.material_override = mat_danno[colore] if danno else mat_nave[colore]
	n.scale = Vector3.ONE * 0.72
	n.position = p + Vector3(0, 0.0 if danno else 0.06, 0)
	n.rotation_degrees = Vector3(0, -35, 0)
	pezzi.add_child(n)
	if not danno:
		# luce del motore
		var fiamma := MeshInstance3D.new()
		var sp := SphereMesh.new()
		sp.radius = 0.025
		sp.height = 0.05
		fiamma.mesh = sp
		var fm := StandardMaterial3D.new()
		fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		fm.albedo_color = Color(0.5, 0.85, 1.0) * 2.5
		fiamma.material_override = fm
		fiamma.position = Vector3(0.45, 0.17, 0)
		n.add_child(fiamma)

## La Piaga: un grumo organico con spine; danneggiata è più scura e afflosciata.
func _piaga(p: Vector3, danno: bool) -> void:
	var nodo := Node3D.new()
	nodo.position = p + Vector3(0, 0.1 if not danno else 0.06, 0)
	pezzi.add_child(nodo)
	var mt := StandardMaterial3D.new()
	mt.albedo_color = Dati.TINTA["piaga"].darkened(0.45 if danno else 0.0)
	mt.roughness = 0.35
	mt.emission_enabled = not danno
	mt.emission = Color(0.4, 0.9, 0.2) * 0.35
	var corpo := MeshInstance3D.new()
	var sf := SphereMesh.new()
	sf.radius = 0.13
	sf.height = 0.2 if not danno else 0.13
	corpo.mesh = sf
	corpo.material_override = mt
	nodo.add_child(corpo)
	for k in 7:
		var sp := MeshInstance3D.new()
		var co := CylinderMesh.new()
		co.top_radius = 0.0
		co.bottom_radius = 0.035
		co.height = 0.16 if not danno else 0.09
		sp.mesh = co
		sp.material_override = mt
		var ang := TAU * k / 7.0
		sp.position = Vector3(cos(ang) * 0.1, 0.03, sin(ang) * 0.1)
		sp.rotation = Vector3(sin(ang) * 0.9, 0, -cos(ang) * 0.9)
		nodo.add_child(sp)

func _prisma(colore: Material, h: float, lato: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var pr := CylinderMesh.new()
	pr.radial_segments = 3
	pr.top_radius = lato
	pr.bottom_radius = lato
	pr.height = h
	mi.mesh = pr
	mi.material_override = colore
	return mi

func _citta(p: Vector3, colore: String, danno: bool) -> void:
	_edificio(mesh_citta, mat_citta[colore], p, danno)

func _porto(p: Vector3, colore: String, danno: bool) -> void:
	_edificio(mesh_porto, mat_porto[colore], p, danno)

## Miniature di città e spazioporti (modelli forniti dall'utente), tinte del colore del giocatore.
func _edificio(mesh: Mesh, base_mat: StandardMaterial3D, p: Vector3, danno: bool) -> void:
	var mat := base_mat
	if danno:
		mat = base_mat.duplicate()
		mat.albedo_color = mat.albedo_color.darkened(0.55)
		mat.emission_enabled = true
		mat.emission = Color(0.9, 0.25, 0.05) * 0.4
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.scale = Vector3.ONE * 0.021
	mi.position = p
	mi.rotation_degrees = Vector3(0 if not danno else 8, 180, 0 if not danno else -6)
	pezzi.add_child(mi)

func _etichetta_3d(p: Vector3, testo: String, col: Color) -> void:
	var l := Label3D.new()
	l.text = testo
	l.font = load("res://assets/font/TestoNero.ttf")
	l.font_size = 48
	l.pixel_size = 0.005
	l.modulate = col
	l.outline_size = 10
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = p
	pezzi.add_child(l)

# ---------------------------------------------------------------- sistemi selezionabili
func evidenzia(ids: Array) -> void:
	for c in evidenze.get_children():
		c.queue_free()
	selezionabili = {}
	for id in ids:
		if not Dati.POS.has(id) or selezionabili.has(id):
			continue
		selezionabili[id] = true
		var a := MeshInstance3D.new()
		var tor := TorusMesh.new()
		tor.inner_radius = 0.6
		tor.outer_radius = 0.68
		a.mesh = tor
		var am := StandardMaterial3D.new()
		am.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		am.albedo_color = Color(1.0, 0.85, 0.35) * 1.6
		a.material_override = am
		a.position = pos(id) + Vector3(0, 0.04, 0)
		evidenze.add_child(a)

func _process(delta: float) -> void:
	t += delta
	var s := 1.0 + sin(t * 4.0) * 0.06
	for c in evidenze.get_children():
		c.scale = Vector3(s, 1, s)

# ---------------------------------------------------------------- effetti delle azioni
func effetto(e: Dictionary, colori: Array) -> void:
	var tipo: String = e.get("tipo", "")
	match tipo:
		"battaglia":
			var p := pos(e["sis"])
			_lampo(p, Color(1.0, 0.45, 0.2), 6.0, 0.9)
			_scintille(p, Color(1.0, 0.6, 0.25), 60, 1.2)
			if e.has("g"):
				_raggi(p, Dati.TINTA[colori[e["g"]]], Dati.TINTA[colori[e["dif"]]])
		"distruggi":
			var p := pos(e["sis"])
			_lampo(p, Color(1.0, 0.35, 0.1), 9.0, 1.1)
			_scintille(p, Color(1.0, 0.5, 0.15), 90, 1.4)
			_onda(p, Color(1.0, 0.55, 0.2))
		"costruisci":
			var p := pos(e["sis"])
			var col: Color = Dati.TINTA[colori[e["g"]]]
			_lampo(p, col, 3.5, 0.9)
			_colonna(p, col)
		"nave":
			var p := pos(e["sis"])
			_lampo(p, Dati.TINTA[colori[e["g"]]], 2.5, 0.6)
		"ripara":
			var p := pos(e["sis"])
			_lampo(p, Color(0.4, 1.0, 0.6), 3.0, 0.8)
			_scintille(p, Color(0.5, 1.0, 0.7), 25, 0.8)
		"tassa":
			var p := pos(e["sis"])
			_lampo(p, Color(1.0, 0.85, 0.3), 3.0, 0.8)
			_colonna(p, Color(1.0, 0.85, 0.3))
		"muovi":
			_volo(pos(e["da"]), pos(e["a"]), colori[e["g"]], mini(int(e.get("n", 1)), 3))
		"dadi":
			var p := pos(e["sis"])
			_scintille(p + Vector3(0, 0.3, 0), Color(1.0, 0.3, 0.2), 30 + int(e.get("colpi", 0)) * 15, 0.9)
		"carta":
			var c: String = e.get("c", "")
			if c != "" and Dati.COLORE_SEME.has(Dati.seme(c)):
				_bagliore_mappa(Dati.COLORE_SEME[Dati.seme(c)])
			elif c != "":
				_bagliore_mappa(Color(0.75, 0.6, 1.0))
		"ambizione":
			_bagliore_mappa(Color(1.0, 0.8, 0.3))
		"oltraggio":
			_bagliore_mappa(Color(0.9, 0.15, 0.1))

func _lampo(p: Vector3, col: Color, energia: float, durata: float) -> void:
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = energia
	l.omni_range = 3.0
	l.position = p + Vector3(0, 0.6, 0)
	effetti.add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "light_energy", 0.0, durata).set_ease(Tween.EASE_OUT)
	tw.tween_callback(l.queue_free)

func _scintille(p: Vector3, col: Color, n: int, durata: float) -> void:
	var part := CPUParticles3D.new()
	part.amount = n
	part.lifetime = durata
	part.one_shot = true
	part.explosiveness = 0.9
	part.direction = Vector3(0, 1, 0)
	part.spread = 75
	part.initial_velocity_min = 1.0
	part.initial_velocity_max = 3.0
	part.gravity = Vector3(0, -3, 0)
	part.scale_amount_min = 0.5
	part.scale_amount_max = 1.2
	var sm := SphereMesh.new()
	sm.radius = 0.025
	sm.height = 0.05
	var mt := StandardMaterial3D.new()
	mt.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mt.albedo_color = col * 3.0
	mt.vertex_color_use_as_albedo = true
	sm.material = mt
	part.mesh = sm
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 0.3, 0.1, 0))
	part.color_ramp = g
	part.position = p + Vector3(0, 0.2, 0)
	effetti.add_child(part)
	part.emitting = true
	get_tree().create_timer(durata + 0.5).timeout.connect(part.queue_free)

func _onda(p: Vector3, col: Color) -> void:
	var a := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 0.2
	tor.outer_radius = 0.26
	a.mesh = tor
	var mt := StandardMaterial3D.new()
	mt.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mt.albedo_color = Color(col.r * 2.0, col.g * 2.0, col.b * 2.0, 1.0)
	a.material_override = mt
	a.position = p + Vector3(0, 0.1, 0)
	effetti.add_child(a)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(a, "scale", Vector3(5, 1, 5), 0.9)
	tw.tween_property(mt, "albedo_color:a", 0.0, 0.9)
	tw.chain().tween_callback(a.queue_free)

func _colonna(p: Vector3, col: Color) -> void:
	var c := MeshInstance3D.new()
	var cy := CylinderMesh.new()
	cy.top_radius = 0.18
	cy.bottom_radius = 0.28
	cy.height = 1.6
	c.mesh = cy
	var mt := StandardMaterial3D.new()
	mt.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mt.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mt.albedo_color = Color(col.r, col.g, col.b, 0.55)
	mt.cull_mode = BaseMaterial3D.CULL_DISABLED
	c.material_override = mt
	c.position = p + Vector3(0, 0.8, 0)
	c.scale = Vector3(1, 0.05, 1)
	effetti.add_child(c)
	var tw := create_tween()
	tw.tween_property(c, "scale", Vector3(1, 1, 1), 0.35).set_ease(Tween.EASE_OUT)
	tw.tween_property(mt, "albedo_color:a", 0.0, 0.8)
	tw.tween_callback(c.queue_free)

func _raggi(p: Vector3, ca: Color, cd: Color) -> void:
	for k in 6:
		var r := MeshInstance3D.new()
		var cy := CylinderMesh.new()
		cy.top_radius = 0.012
		cy.bottom_radius = 0.012
		cy.height = 0.9
		r.mesh = cy
		var mt := StandardMaterial3D.new()
		mt.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var col: Color = ca if k % 2 == 0 else cd
		mt.albedo_color = col * 3.0
		r.material_override = mt
		var ang := TAU * k / 6.0 + randf() * 0.4
		r.position = p + Vector3(cos(ang) * 0.25, 0.25, sin(ang) * 0.25)
		r.rotation = Vector3(PI * 0.5, -ang, 0)
		effetti.add_child(r)
		var tw := create_tween()
		tw.tween_interval(k * 0.08)
		tw.tween_property(r, "scale", Vector3(1, 0.01, 1), 0.25)
		tw.tween_callback(r.queue_free)

func _volo(a: Vector3, b: Vector3, colore: String, n: int) -> void:
	for k in n:
		var nv := MeshInstance3D.new()
		nv.mesh = mesh_nave
		nv.material_override = mat_nave[colore]
		nv.scale = Vector3.ONE * 0.72
		var off := Vector3((k - (n - 1) * 0.5) * 0.18, 0, 0)
		nv.position = a + off + Vector3(0, 0.1, 0)
		effetti.add_child(nv)
		var dir := (b - a)
		if dir.length() > 0.01:
			nv.rotation.y = atan2(dir.x, dir.z) + PI * 0.5
		var scia := CPUParticles3D.new()
		scia.amount = 40
		scia.lifetime = 0.5
		scia.local_coords = false
		scia.gravity = Vector3.ZERO
		scia.initial_velocity_min = 0.0
		scia.initial_velocity_max = 0.1
		var sm := SphereMesh.new()
		sm.radius = 0.02
		sm.height = 0.04
		var mt := StandardMaterial3D.new()
		mt.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mt.albedo_color = Color(0.5, 0.85, 1.0) * 2.5
		sm.material = mt
		scia.mesh = sm
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		scia.color_ramp = g
		scia.position = Vector3(0.45, 0.17, 0)
		nv.add_child(scia)
		var meta := (a + b) * 0.5 + Vector3(0, 0.9 + a.distance_to(b) * 0.12, 0)
		var tw := create_tween()
		tw.tween_interval(k * 0.1)
		tw.tween_method(func(x: float):
			var q0 := a.lerp(meta, x)
			var q1 := meta.lerp(b, x)
			nv.position = q0.lerp(q1, x) + off + Vector3(0, 0.1, 0), 0.0, 1.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_callback(nv.queue_free)

func _bagliore_mappa(col: Color) -> void:
	var l := DirectionalLight3D.new()
	l.light_color = col
	l.light_energy = 0.0
	l.rotation_degrees = Vector3(-80, 0, 0)
	effetti.add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "light_energy", 0.5, 0.25)
	tw.tween_property(l, "light_energy", 0.0, 0.9)
	tw.tween_callback(l.queue_free)
