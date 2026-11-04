## Arcs: menu, tavolo 3D, interfaccia della partita, IA, gioco online e salvataggi.
extends Node

const F_LOGO := preload("res://assets/font/Logo.ttf")
const F_TITOLO := preload("res://assets/font/Titoli.ttf")
const F_TESTO := preload("res://assets/font/Testo.ttf")
const F_NERO := preload("res://assets/font/TestoNero.ttf")
const F_CORSIVO := preload("res://assets/font/TestoCorsivo.ttf")

const C_SPAZIO := Color(0.03, 0.03, 0.07, 0.93)
const C_ORO := Color(0.88, 0.68, 0.32)
const C_ORO_CHIARO := Color(1.0, 0.86, 0.55)
const C_PERGAMENA := Color(0.94, 0.89, 0.78)
const C_TESTO := Color(0.93, 0.9, 0.84)
const C_SPENTO := Color(0.62, 0.6, 0.56)
const C_ROSSO := Color(0.85, 0.25, 0.2)
const SALVA_LOCALE := "user://partita_arcs.txt"

var ui: CanvasLayer
var schermo: Control
var net: Rete
var m: Motore
var ia: IA
var plancia: Plancia3D
var vista: SubViewport

var in_partita := false
var online := false
var codice := ""
var mio_posto := 0
var posti := []          # per ogni giocatore: posto online (-1 = IA); in locale: 0 umano, -1 IA
var attesa_ia := 0.0
var velocita := 1.0
var mostrata := -1
var aspetto_rete := false
var ultimo_log := 0
var ultimo_umano := -1
var salvataggio_in_corso := false
var ultimo_salvataggio := 0.0
var cambio_mostrato := -1

# elementi dell'interfaccia
var top_info: Label
var top_guida: HBoxContainer
var col_giocatori: VBoxContainer
var corte_box: HBoxContainer
var titolo_corte: Label
var amb_box: Control
var info_camp: Label
var diario: RichTextLabel
var pannello_scelte: VBoxContainer
var titolo_scelte: Label
var mano_box: HBoxContainer
var mano_titolo: Label
var banner: PanelContainer
var zoom_layer: Control
var dadi_box: PanelContainer
var giocate_box: HBoxContainer

func _ready() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	schermo = Control.new()
	schermo.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(schermo)
	net = Rete.new()
	add_child(net)
	mostra_menu()

# ============================================================ mattoni dell'interfaccia
func stile(bg: Color, bordo := Color(0, 0, 0, 0), spessore := 0, raggio := 6) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = bordo
	s.set_border_width_all(spessore)
	s.set_corner_radius_all(raggio)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s

func etichetta(testo: String, font: Font = F_TESTO, size := 17, col := C_TESTO) -> Label:
	var l := Label.new()
	l.text = testo
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l

func testo_lungo(testo: String, size := 16, col := C_TESTO) -> Label:
	var l := etichetta(testo, F_TESTO, size, col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func bottone(testo: String, cb: Callable, col := Color(0.16, 0.12, 0.08), size := 17) -> Button:
	var b := Button.new()
	b.text = testo
	b.add_theme_font_override("font", F_TITOLO)
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", C_ORO_CHIARO)
	b.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	b.add_theme_stylebox_override("normal", stile(col, C_ORO * Color(1, 1, 1, 0.7), 1, 5))
	b.add_theme_stylebox_override("hover", stile(col.lightened(0.2), C_ORO_CHIARO, 2, 5))
	b.add_theme_stylebox_override("pressed", stile(col.darkened(0.3), C_ORO_CHIARO, 2, 5))
	b.add_theme_stylebox_override("disabled", stile(Color(0.12, 0.12, 0.12), Color(0.3, 0.3, 0.3), 1, 5))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.pressed.connect(cb)
	return b

func pannello(bg := C_SPAZIO, bordo := C_ORO * Color(1, 1, 1, 0.55)) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", stile(bg, bordo, 1, 8))
	return p

func immagine(path: String, w: float, h: float) -> TextureRect:
	var t := TextureRect.new()
	if path.begins_with("camp:"):
		_texture_campagna(path.substr(5), t)
	elif ResourceLoader.exists(path):
		t.texture = load(path)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(w, h)
	return t

func img_carta(c: String) -> String:
	if Dati.is_evento(c):
		return img_camp("309_28")
	match c:
		"consiglio":
			var deciso: bool = m != null and m.s.has("camp") and m.s["camp"]["consiglio"] == "deciso"
			return img_camp("973_00", deciso)
		"x11": return img_camp("364_11")
		"x12": return img_camp("364_12")
	if c.length() == 6 and c[3] == "_":
		return img_camp(c)
	return "res://assets/carte/%s.webp" % c

var elenco_camp := {}

## Percorso «camp:» dell'immagine di una carta della campagna (fronte o retro, senza doppioni).
func img_camp(id: String, retro := false) -> String:
	if elenco_camp.is_empty():
		var f := FileAccess.open("res://assets/dati/carte_campagna.json", FileAccess.READ)
		if f != null:
			var d = JSON.parse_string(f.get_as_text())
			if d is Dictionary:
				elenco_camp = d
	var e: Dictionary = elenco_camp.get(id, {})
	return "camp:" + str(e.get("retro" if retro else "fronte", id + ("_r" if retro else "")))

# ---------------------------------------------------------------- immagini della campagna
## Le carte della campagna non sono nel pacchetto: si scaricano dal sito quando servono.
var cache_camp := {}
var attese_camp := {}

func _texture_campagna(nome: String, t: TextureRect) -> void:
	if cache_camp.has(nome):
		t.texture = cache_camp[nome]
		return
	if attese_camp.has(nome):
		attese_camp[nome].append(weakref(t))
		return
	attese_camp[nome] = [weakref(t)]
	if OS.has_feature("web"):
		var base = JavaScriptBridge.eval("location.href.replace(/[?#].*$/, '').replace(/[^/]*$/, '')")
		var req := HTTPRequest.new()
		add_child(req)
		req.request_completed.connect(func(_r, codice, _h, corpo: PackedByteArray):
			var img := Image.new()
			if codice == 200 and img.load_webp_from_buffer(corpo) == OK:
				_texture_pronta(nome, ImageTexture.create_from_image(img))
			req.queue_free())
		req.request(str(base) + "campagna/img/%s.webp" % nome)
	else:
		var img := Image.new()
		if img.load(ProjectSettings.globalize_path("res://campagna/img/%s.webp" % nome)) == OK:
			_texture_pronta(nome, ImageTexture.create_from_image(img))

func _texture_pronta(nome: String, tex: Texture2D) -> void:
	cache_camp[nome] = tex
	for w in attese_camp.get(nome, []):
		var t = w.get_ref()
		if t != null:
			t.texture = tex
	attese_camp.erase(nome)

func pulisci() -> void:
	in_partita = false
	for c in schermo.get_children():
		c.queue_free()
	plancia = null

## Agente: icona della miniatura fornita dall'utente, con il numero se più di uno.
func icona_agente(colore: String, d := 20.0, n := 1) -> Control:
	var box := Control.new()
	box.custom_minimum_size = Vector2(d, d)
	box.size = Vector2(d, d)
	var path := "res://assets/ui/agente_%s.png" % colore
	if not ResourceLoader.exists(path):
		return pallino(Dati.TINTA.get(colore, Color.GRAY), d, str(n) if n > 1 else "")
	var t := immagine(path, d, d)
	t.size = Vector2(d, d)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(t)
	if n > 1:
		var l := etichetta(str(n), F_NERO, int(d * 0.55), Color(1, 1, 1))
		l.add_theme_constant_override("outline_size", 4)
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		l.position = Vector2(d * 0.62, d * 0.35)
		box.add_child(l)
	return box

func pallino(col: Color, d := 14.0, testo := "") -> PanelContainer:
	var p := PanelContainer.new()
	var s := stile(col, Color(0, 0, 0, 0.7), 1, int(d / 2))
	s.content_margin_left = 0
	s.content_margin_right = 0
	s.content_margin_top = 0
	s.content_margin_bottom = 0
	p.add_theme_stylebox_override("panel", s)
	p.custom_minimum_size = Vector2(d, d)
	if testo != "":
		var l := etichetta(testo, F_NERO, int(d * 0.72), Color(0.05, 0.05, 0.05) if col.get_luminance() > 0.5 else Color(1, 1, 1))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		p.add_child(l)
	return p

func _sfondo_menu() -> void:
	var img := immagine("res://assets/3d/mappa.webp", 0, 0)
	img.set_anchors_preset(Control.PRESET_FULL_RECT)
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	img.modulate = Color(0.45, 0.42, 0.5)
	schermo.add_child(img)
	var velo := ColorRect.new()
	velo.color = Color(0.02, 0.01, 0.05, 0.55)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	schermo.add_child(velo)

# ============================================================ menu
func mostra_menu() -> void:
	pulisci()
	_sfondo_menu()
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_CENTER)
	v.custom_minimum_size = Vector2(520, 560)
	v.position = Vector2(-260, -290)
	v.add_theme_constant_override("separation", 12)
	schermo.add_child(v)
	var logo := etichetta("ARCS", F_LOGO, 110, C_ORO_CHIARO)
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.0))
	logo.add_theme_constant_override("outline_size", 10)
	v.add_child(logo)
	var sub := etichetta("Conflitto e collasso nell'Orlo", F_TITOLO, 24, C_PERGAMENA)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	v.add_child(Control.new())
	v.add_child(bottone("NUOVA PARTITA", _menu_nuova, Color(0.25, 0.14, 0.06), 24))
	v.add_child(bottone("CONTINUA", _menu_continua, Color(0.16, 0.12, 0.08), 22))
	v.add_child(bottone("GIOCA ONLINE", _menu_online, Color(0.08, 0.16, 0.22), 22))
	v.add_child(bottone("REGOLE IN BREVE", _menu_regole, Color(0.12, 0.1, 0.14), 20))
	var nota := etichetta("Versione digitale non ufficiale per uso personale. Arcs è un gioco di Cole Wehrle (Leder Games), edizione italiana MS Edizioni.", F_CORSIVO, 14, C_SPENTO)
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nota.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(nota)

var scelta_n := 3
var scelta_umani := [true, false, false, false]
var scelta_nomi := ["Tu", "Rivale 1", "Rivale 2", "Rivale 3"]
var scelta_leader := false
var scelta_prep := -1
var scelta_facile := false
var scelta_campagna := false

func _menu_nuova() -> void:
	pulisci()
	_sfondo_menu()
	var box := pannello()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.custom_minimum_size = Vector2(700, 600)
	box.position = Vector2(-350, -300)
	schermo.add_child(box)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	box.add_child(v)
	v.add_child(etichetta("NUOVA PARTITA", F_TITOLO, 34, C_ORO_CHIARO))
	var r := HBoxContainer.new()
	r.add_child(etichetta("Giocatori:", F_NERO, 19))
	for n in [2, 3, 4]:
		var b := bottone(str(n), func():
			scelta_n = n
			scelta_prep = -1
			_menu_nuova(), Color(0.4, 0.25, 0.08) if scelta_n == n else Color(0.14, 0.1, 0.07), 20)
		b.custom_minimum_size = Vector2(54, 0)
		r.add_child(b)
	v.add_child(r)
	for i in scelta_n:
		var rr := HBoxContainer.new()
		rr.add_theme_constant_override("separation", 10)
		rr.add_child(pallino(Dati.TINTA[Dati.COLORI[i]], 22))
		var le := LineEdit.new()
		le.text = scelta_nomi[i]
		le.max_length = 18
		le.custom_minimum_size = Vector2(240, 0)
		le.text_changed.connect(func(t): scelta_nomi[i] = t)
		rr.add_child(le)
		var tb := bottone("UMANO" if scelta_umani[i] else "IA", func():
			scelta_umani[i] = not scelta_umani[i]
			_menu_nuova(), Color(0.12, 0.25, 0.14) if scelta_umani[i] else Color(0.2, 0.1, 0.1), 16)
		tb.custom_minimum_size = Vector2(110, 0)
		rr.add_child(tb)
		v.add_child(rr)
	var lb := CheckBox.new()
	lb.text = "Leader & Lore (poteri asimmetrici, si scelgono a inizio partita)"
	lb.button_pressed = scelta_leader
	lb.add_theme_font_override("font", F_TESTO)
	lb.add_theme_font_size_override("font_size", 17)
	lb.toggled.connect(func(x): scelta_leader = x)
	v.add_child(lb)
	var cb := CheckBox.new()
	cb.text = "Campagna «L'Orlo Infestato» (Atto I: Impero, Piaga, Eventi, Consiglio Imperiale)"
	cb.button_pressed = scelta_campagna
	cb.add_theme_font_override("font", F_TESTO)
	cb.add_theme_font_size_override("font_size", 17)
	cb.toggled.connect(func(x): scelta_campagna = x)
	v.add_child(cb)
	var fb := CheckBox.new()
	fb.text = "IA più indulgente"
	fb.button_pressed = scelta_facile
	fb.add_theme_font_override("font", F_TESTO)
	fb.add_theme_font_size_override("font_size", 17)
	fb.toggled.connect(func(x): scelta_facile = x)
	v.add_child(fb)
	var rp := HBoxContainer.new()
	rp.add_theme_constant_override("separation", 6)
	rp.add_child(etichetta("Preparazione:", F_NERO, 18))
	var ob := OptionButton.new()
	ob.add_theme_font_override("font", F_TESTO)
	ob.add_item("A caso", 0)
	var preps: Array = Dati.PREPARAZIONI[scelta_n]
	for k in preps.size():
		ob.add_item("%s (fuori: settore %s)" % [preps[k]["nome"], ", ".join(preps[k]["fuori"].map(func(x): return str(x)))], k + 1)
	ob.selected = scelta_prep + 1
	ob.item_selected.connect(func(k): scelta_prep = k - 1)
	rp.add_child(ob)
	v.add_child(rp)
	v.add_child(testo_lungo("Consiglio per la prima partita: gioco base senza Leader & Lore. Partita da circa 30-45 minuti per giocatore.", 15, C_SPENTO))
	var rb := HBoxContainer.new()
	rb.add_theme_constant_override("separation", 12)
	rb.add_child(bottone("INIZIA", _avvia_locale, Color(0.35, 0.18, 0.05), 24))
	rb.add_child(bottone("INDIETRO", mostra_menu))
	v.add_child(rb)

func _avvia_locale() -> void:
	online = false
	m = MotoreCampagna.new() if scelta_campagna else Motore.new()
	var ia_flags := []
	posti = []
	for i in scelta_n:
		ia_flags.append(not scelta_umani[i])
		posti.append(0 if scelta_umani[i] else -1)
	var seme := int(Time.get_unix_time_from_system() * 1000.0) % 1000000007
	m.nuova_partita({"n": scelta_n, "nomi": scelta_nomi.slice(0, scelta_n), "ia": ia_flags, "leader": scelta_leader,
		"seme": seme, "prep": scelta_prep, "facile": scelta_facile, "campagna": scelta_campagna})
	m.s["posti"] = posti.duplicate()
	ia = IA.new()
	ia.facile = scelta_facile
	_apri_partita()

func _menu_continua() -> void:
	var st = null
	if FileAccess.file_exists(SALVA_LOCALE):
		var f := FileAccess.open(SALVA_LOCALE, FileAccess.READ)
		st = str_to_var(f.get_as_text())
	if not (st is Dictionary):
		_avviso("Cerco un salvataggio su Firebase...")
		var t := await net.carica_partita()
		if t.has("v"):
			st = str_to_var(str(t["v"]))
	if not (st is Dictionary) or not st.has("mappa"):
		_avviso("Nessuna partita salvata.")
		return
	online = false
	m = MotoreCampagna.new() if st.has("camp") else Motore.new()
	m.carica(st)
	posti = m.s.get("posti", [])
	if posti.size() != m.s["n"]:
		posti = []
		for i in m.s["n"]:
			posti.append(-1 if m.s["g"][i]["ia"] else 0)
	ia = IA.new()
	ia.facile = bool(m.s.get("facile", false))
	_apri_partita()

func _avviso(t: String) -> void:
	var p := pannello(Color(0.1, 0.05, 0.03, 0.96), C_ORO)
	p.set_anchors_preset(Control.PRESET_CENTER_TOP)
	p.position = Vector2(-280, 70)
	p.custom_minimum_size = Vector2(560, 0)
	var l := testo_lungo(t, 18, C_ORO_CHIARO)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	ui.add_child(p)
	get_tree().create_timer(3.0).timeout.connect(p.queue_free)

const REGOLE := """[b]Lo scopo.[/b] Guidate una società spaziale nell'Orlo. Ottenete Potere soddisfacendo le [b]ambizioni[/b] dichiarate durante la partita. Vince chi raggiunge 33 (2 giocatori), 30 (3) o 27 (4) Potere a fine capitolo, oppure chi ne ha di più dopo il 5° capitolo.

[b]Il round.[/b] Chi ha l'[b]iniziativa[/b] gioca la carta Guida e fa un'azione per ogni punto azione, scegliendo tra quelle del seme. Gli altri, in senso orario, possono [b]Superare[/b] (stesso seme, valore più alto: tutte le azioni della carta), [b]Cambiare[/b] (altro seme: 1 azione della propria carta) o [b]Copiare[/b] (carta coperta: 1 azione del seme della Guida). Chi Supera col valore più alto prende l'iniziativa, a meno che qualcuno la [b]sottragga[/b] giocando una carta in più coperta.

[b]Ambizioni.[/b] Chi guida può dichiarare l'ambizione della carta (2 Magnate, 3 Tiranno, 4 Generale, 5 Custode, 6 Empate): il valore della Guida diventa 0. A fine capitolo, per ogni ambizione dichiarata, il primo prende il valore alto dei segnalini, il secondo quello basso. Magnate: Materiale e Carburante. Tiranno: Prigionieri. Generale: Trofei. Custode: Reliquie. Empate: Psicoenergia (risorse e carte Gilda).

[b]Azioni.[/b] [i]Amministrazione[/i]: Tassare, Riparare, Influenzare. [i]Aggressione[/i]: Combattere, Muovere, Acquisire. [i]Costruzione[/i]: Costruire, Riparare. [i]Mobilitazione[/i]: Muovere, Influenzare. Si controlla un sistema con più navi integre di ogni Rivale. Si tassa una propria città o una città Rivale in un sistema che si controlla (catturando un agente). Dagli spazioporti Leali si attiva la Fionda per viaggiare lungo i portali.

[b]Risorse.[/b] Nel Preludio (prima di spendere i punti azione) si spendono risorse per azioni extra: Materiale costruisce o ripara, Carburante muove, Armi permette di Combattere con la carta, Reliquie acquisisce, Psicoenergia dà un'azione del seme Guida.

[b]Combattimento.[/b] Dadi Incursione (sicuri), Assalto (forti ma rischiosi) e Razzia (rubano risorse e carte, colpiscono gli edifici). Distruggere una città fa Recare Oltraggio al suo proprietario e permette di Soggiogare la Corte.

[b]Comandi.[/b] Trascina il tavolo per girarlo, rotella per avvicinarti, tasto destro per spostarti. Clicca i sistemi illuminati, le carte della Corte o della mano per scegliere; clicca una carta qualsiasi per ingrandirla."""

func _menu_regole() -> void:
	pulisci()
	_sfondo_menu()
	var box := pannello()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 60
	box.offset_right = -60
	box.offset_top = 40
	box.offset_bottom = -40
	schermo.add_child(box)
	var v := VBoxContainer.new()
	box.add_child(v)
	v.add_child(etichetta("REGOLE IN BREVE", F_TITOLO, 32, C_ORO_CHIARO))
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.text = REGOLE
	rt.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rt.add_theme_font_override("normal_font", F_TESTO)
	rt.add_theme_font_override("bold_font", F_NERO)
	rt.add_theme_font_override("italics_font", F_CORSIVO)
	rt.add_theme_font_size_override("normal_font_size", 18)
	rt.add_theme_font_size_override("bold_font_size", 18)
	rt.add_theme_font_size_override("italics_font_size", 18)
	v.add_child(rt)
	v.add_child(bottone("INDIETRO", mostra_menu))

# ============================================================ online
var on_nome: LineEdit
var on_codice: LineEdit
var on_stato: Label
var lobby_box: VBoxContainer

func _menu_online() -> void:
	pulisci()
	_sfondo_menu()
	var box := pannello()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.custom_minimum_size = Vector2(640, 540)
	box.position = Vector2(-320, -270)
	schermo.add_child(box)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	box.add_child(v)
	v.add_child(etichetta("GIOCA ONLINE", F_TITOLO, 34, C_ORO_CHIARO))
	v.add_child(testo_lungo("Chi crea la stanza usa le impostazioni di Nuova partita (numero di giocatori, Leader & Lore, preparazione). Gli amici entrano col codice; i posti vuoti li guida l'IA.", 16, C_SPENTO))
	var r1 := HBoxContainer.new()
	v.add_child(r1)
	r1.add_child(etichetta("Il tuo nome:", F_NERO, 18))
	on_nome = LineEdit.new()
	on_nome.custom_minimum_size = Vector2(260, 0)
	on_nome.text = str(net.load_session().get("name", "Comandante"))
	on_nome.max_length = 18
	r1.add_child(on_nome)
	v.add_child(etichetta("Stanza per %d giocatori%s%s" % [scelta_n, ", con Leader & Lore" if scelta_leader else "", ", campagna Atto I" if scelta_campagna else ""], F_TESTO, 16))
	v.add_child(bottone("CREA UNA STANZA", _online_crea, Color(0.3, 0.16, 0.06), 20))
	var r2 := HBoxContainer.new()
	v.add_child(r2)
	on_codice = LineEdit.new()
	on_codice.placeholder_text = "CODICE"
	on_codice.max_length = 4
	on_codice.custom_minimum_size = Vector2(120, 0)
	r2.add_child(on_codice)
	r2.add_child(bottone("ENTRA", _online_entra, Color(0.08, 0.2, 0.3), 20))
	var sess := net.load_session()
	if str(sess.get("room", "")) != "":
		r2.add_child(bottone("RIENTRA IN %s" % sess["room"], func():
			on_codice.text = str(sess["room"])
			_online_entra(), Color(0.08, 0.16, 0.22), 16))
	on_stato = testo_lungo("", 17, C_ORO_CHIARO)
	v.add_child(on_stato)
	lobby_box = VBoxContainer.new()
	v.add_child(lobby_box)
	v.add_child(bottone("INDIETRO", mostra_menu))

func _online_crea() -> void:
	on_stato.text = "Creo la stanza..."
	net._save({"name": on_nome.text})
	var cfg := {"n": scelta_n, "leader": scelta_leader, "prep": scelta_prep, "campagna": scelta_campagna}
	var c := await net.create_room(on_nome.text, cfg)
	if c == "":
		on_stato.text = "Non riesco a creare la stanza: " + net.last_error
		return
	codice = c
	mio_posto = 0
	net.remember_room(c, 0)
	on_stato.text = "Stanza %s creata. Dai il codice agli amici, poi premi INIZIA." % c
	_lobby(true)

func _online_entra() -> void:
	var c := on_codice.text.strip_edges().to_upper()
	if c.length() != 4:
		on_stato.text = "Il codice ha 4 lettere."
		return
	on_stato.text = "Entro nella stanza %s..." % c
	net._save({"name": on_nome.text})
	var p := await net.join_room(c, on_nome.text, 4)
	if p < 0:
		on_stato.text = "Non riesco a entrare (stanza piena, inesistente o già iniziata). " + net.last_error
		return
	codice = c
	mio_posto = p
	net.remember_room(c, p)
	var room := await net.room(c)
	if room.get("status", "") == "playing":
		_avvia_da_stanza(room)
		return
	on_stato.text = "Sei nella stanza %s, posto %d. Aspetta che chi l'ha creata inizi la partita." % [c, p + 1]
	_lobby(false)

func _lobby(host: bool) -> void:
	for ch in lobby_box.get_children():
		ch.queue_free()
	var lista := etichetta("", F_TESTO, 17)
	lobby_box.add_child(lista)
	if host:
		lobby_box.add_child(bottone("INIZIA LA PARTITA", _online_inizia, Color(0.4, 0.2, 0.05), 20))
	while is_instance_valid(lista) and not in_partita:
		var room := await net.room(codice)
		if not is_instance_valid(lista):
			return
		var seats := Rete._as_dict(room.get("seats", {}))
		var t := "Giocatori nella stanza:\n"
		for k in seats:
			t += "  %d. %s\n" % [int(k) + 1, seats[k].get("name", "?")]
		lista.text = t
		if not host and room.get("status", "") == "playing":
			_avvia_da_stanza(room)
			return
		await get_tree().create_timer(1.5).timeout

func _online_inizia() -> void:
	var room := await net.room(codice)
	var seats := Rete._as_dict(room.get("seats", {}))
	var cfg = JSON.parse_string(str(room.get("cfg", "{}")))
	if not (cfg is Dictionary):
		cfg = {}
	var n: int = clampi(maxi(int(cfg.get("n", 3)), seats.size()), 2, 4)
	var chiavi := seats.keys()
	chiavi.sort_custom(func(a, b): return int(a) < int(b))
	var seat_arr := []
	var nomi := []
	for k in n:
		if k < chiavi.size():
			seat_arr.append(int(chiavi[k]))
			nomi.append(str(seats[chiavi[k]].get("name", "?")))
		else:
			seat_arr.append(-1)
			nomi.append("IA %d" % (k + 1))
	var game := {"n": n, "seat": seat_arr, "nomi": nomi, "seme": int(Time.get_unix_time_from_system()) % 1000000,
		"leader": bool(cfg.get("leader", false)), "prep": int(cfg.get("prep", -1)), "campagna": bool(cfg.get("campagna", false))}
	if not await net.start_room(codice, game):
		on_stato.text = "Non riesco a iniziare: " + net.last_error
		return
	room["game"] = JSON.stringify(game)
	_avvia_da_stanza(room)

func _avvia_da_stanza(room: Dictionary) -> void:
	var game = JSON.parse_string(str(room.get("game", "{}")))
	if not (game is Dictionary):
		on_stato.text = "Dati della partita illeggibili."
		return
	online = true
	var n := int(game["n"])
	posti = []
	var ia_flags := []
	for k in n:
		posti.append(int(game["seat"][k]))
		ia_flags.append(int(game["seat"][k]) < 0)
	var camp := bool(game.get("campagna", false))
	m = MotoreCampagna.new() if camp else Motore.new()
	m.nuova_partita({"n": n, "nomi": game["nomi"], "ia": ia_flags, "leader": bool(game["leader"]), "seme": int(game["seme"]),
		"prep": int(game["prep"]), "campagna": camp})
	ia = IA.new()
	# si rigiocano le decisioni già prese: chi rientra ritrova la partita al punto giusto
	var log := await net.get_decisions(codice, 0)
	var guard := 0
	while not m.s["fine"] and guard < 20000:
		guard += 1
		var a := m.attesa()
		if a.is_empty():
			break
		var posto: int = posti[a["g"]]
		var n_dec: int = m.s["decisioni"]
		if posto < 0:
			m.scegli(ia.scegli(m, a))
		elif log.has(n_dec):
			m.scegli(int(log[n_dec].get("i", 0)))
		else:
			break
	m.s["eventi"] = []
	_apri_partita()

# ============================================================ la partita
func umano(i: int) -> bool:
	if i < 0 or i >= posti.size():
		return false
	if online:
		return posti[i] == mio_posto
	return posti[i] >= 0

func io() -> int:
	## il giocatore "di riferimento" del dispositivo (per la mano mostrata)
	var a := m.attesa()
	if not a.is_empty() and umano(a["g"]):
		return a["g"]
	if ultimo_umano >= 0:
		return ultimo_umano
	for i in m.s["n"]:
		if umano(i):
			return i
	return -1

func umani_locali() -> int:
	var n := 0
	for i in m.s["n"]:
		if umano(i):
			n += 1
	return n

func _apri_partita() -> void:
	pulisci()
	in_partita = true
	mostrata = -1
	ultimo_log = 0
	cambio_mostrato = -1
	var sfondo := ColorRect.new()
	sfondo.color = Color(0.01, 0.01, 0.03)
	sfondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	schermo.add_child(sfondo)
	var cont := SubViewportContainer.new()
	cont.set_anchors_preset(Control.PRESET_FULL_RECT)
	cont.offset_left = 296
	cont.offset_right = -422
	cont.offset_top = 44
	cont.offset_bottom = -226
	cont.stretch = true
	schermo.add_child(cont)
	vista = SubViewport.new()
	vista.msaa_3d = Viewport.MSAA_2X
	vista.handle_input_locally = true
	cont.add_child(vista)
	plancia = Plancia3D.new()
	vista.add_child(plancia)
	plancia.sistema_cliccato.connect(_sistema_cliccato)
	_costruisci_hud()
	m.s["eventi"] = []
	_aggiorna_tutto()

func _costruisci_hud() -> void:
	# barra in alto
	var top := pannello(Color(0.02, 0.02, 0.05, 0.9))
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 44
	top.mouse_filter = Control.MOUSE_FILTER_STOP
	schermo.add_child(top)
	var th := HBoxContainer.new()
	th.add_theme_constant_override("separation", 16)
	top.add_child(th)
	th.add_child(etichetta("ARCS", F_LOGO, 26, C_ORO_CHIARO))
	top_info = etichetta("", F_NERO, 18)
	th.add_child(top_info)
	top_guida = HBoxContainer.new()
	top_guida.add_theme_constant_override("separation", 8)
	top_guida.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	th.add_child(top_guida)
	th.add_child(bottone("VISTA", func():
		if plancia.pitch < -80:
			plancia.vista_iniziale()
		else:
			plancia.vista_alto(), Color(0.1, 0.1, 0.14), 15))
	th.add_child(bottone("-", func(): plancia.zoom(1.15), Color(0.1, 0.1, 0.14), 15))
	th.add_child(bottone("+", func(): plancia.zoom(0.87), Color(0.1, 0.1, 0.14), 15))
	th.add_child(bottone("MENU", _menu_partita, Color(0.14, 0.1, 0.08), 15))
	# giocatori a sinistra
	var sx := ScrollContainer.new()
	sx.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	sx.offset_top = 50
	sx.offset_bottom = -232
	sx.offset_right = 296
	sx.offset_left = 4
	sx.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	schermo.add_child(sx)
	col_giocatori = VBoxContainer.new()
	col_giocatori.add_theme_constant_override("separation", 6)
	col_giocatori.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sx.add_child(col_giocatori)
	# a destra: Corte, ambizioni, diario
	var dx := VBoxContainer.new()
	dx.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	dx.offset_left = -278
	dx.offset_right = -6
	dx.offset_top = 50
	dx.offset_bottom = -232
	dx.add_theme_constant_override("separation", 6)
	schermo.add_child(dx)
	var pc := pannello(Color(0.05, 0.035, 0.02, 0.9))
	dx.add_child(pc)
	var vc := VBoxContainer.new()
	pc.add_child(vc)
	titolo_corte = etichetta("LA CORTE", F_TITOLO, 17, C_ORO_CHIARO)
	vc.add_child(titolo_corte)
	corte_box = HBoxContainer.new()
	corte_box.add_theme_constant_override("separation", 4)
	vc.add_child(corte_box)
	# plancia delle Ambizioni accanto alla mappa
	amb_box = Control.new()
	amb_box.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	amb_box.offset_left = -420
	amb_box.offset_right = -280
	amb_box.offset_top = 50
	amb_box.offset_bottom = -232
	amb_box.clip_contents = true
	schermo.add_child(amb_box)
	info_camp = testo_lungo("", 13, Color(0.8, 0.76, 0.95))
	info_camp.visible = false
	dx.add_child(info_camp)
	var pd := pannello(Color(0.02, 0.02, 0.04, 0.85))
	pd.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dx.add_child(pd)
	diario = RichTextLabel.new()
	diario.bbcode_enabled = true
	diario.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	diario.custom_minimum_size = Vector2(260, 60)
	diario.scroll_following = true
	diario.add_theme_font_override("normal_font", F_TESTO)
	diario.add_theme_font_override("bold_font", F_NERO)
	diario.add_theme_font_size_override("normal_font_size", 14)
	diario.add_theme_font_size_override("bold_font_size", 14)
	diario.add_theme_color_override("default_color", Color(0.85, 0.82, 0.76))
	pd.add_child(diario)
	# in basso: mano e scelte
	var basso := pannello(Color(0.02, 0.02, 0.05, 0.93))
	basso.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	basso.offset_top = -226
	schermo.add_child(basso)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	basso.add_child(hb)
	var vm := VBoxContainer.new()
	vm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(vm)
	var riga := HBoxContainer.new()
	mano_titolo = etichetta("La tua mano", F_TITOLO, 17, C_ORO_CHIARO)
	riga.add_child(mano_titolo)
	giocate_box = HBoxContainer.new()
	giocate_box.add_theme_constant_override("separation", 10)
	giocate_box.set_anchors_preset(Control.PRESET_TOP_WIDE)
	giocate_box.offset_left = 300
	giocate_box.offset_right = -426
	giocate_box.offset_top = 52
	giocate_box.alignment = BoxContainer.ALIGNMENT_CENTER
	giocate_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	schermo.add_child(giocate_box)
	vm.add_child(riga)
	var sm := ScrollContainer.new()
	sm.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sm.custom_minimum_size = Vector2(0, 170)
	vm.add_child(sm)
	mano_box = HBoxContainer.new()
	mano_box.add_theme_constant_override("separation", 6)
	sm.add_child(mano_box)
	var vs := VBoxContainer.new()
	vs.custom_minimum_size = Vector2(470, 0)
	hb.add_child(vs)
	titolo_scelte = testo_lungo("", 17, C_ORO_CHIARO)
	titolo_scelte.add_theme_font_override("font", F_NERO)
	vs.add_child(titolo_scelte)
	var ss := ScrollContainer.new()
	ss.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ss.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vs.add_child(ss)
	pannello_scelte = VBoxContainer.new()
	pannello_scelte.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pannello_scelte.add_theme_constant_override("separation", 3)
	ss.add_child(pannello_scelte)
	# livelli sopra
	dadi_box = pannello(Color(0.05, 0.03, 0.02, 0.95), C_ORO)
	dadi_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	dadi_box.position = Vector2(-220, 60)
	dadi_box.visible = false
	schermo.add_child(dadi_box)
	banner = pannello(Color(0.06, 0.03, 0.01, 0.94), C_ORO_CHIARO)
	banner.set_anchors_preset(Control.PRESET_CENTER)
	banner.visible = false
	schermo.add_child(banner)
	zoom_layer = Control.new()
	zoom_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	zoom_layer.visible = false
	schermo.add_child(zoom_layer)

func _menu_partita() -> void:
	var p := pannello(Color(0.03, 0.02, 0.02, 0.97), C_ORO)
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.position = Vector2(-200, -170)
	p.custom_minimum_size = Vector2(400, 0)
	schermo.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	v.add_child(etichetta("MENU", F_TITOLO, 26, C_ORO_CHIARO))
	v.add_child(bottone("IA: %s" % ("VELOCE" if velocita > 1.5 else "NORMALE"), func():
		velocita = 1.0 if velocita > 1.5 else 3.0
		p.queue_free(), Color(0.12, 0.1, 0.08)))
	if not online:
		v.add_child(bottone("SALVA ADESSO", func():
			_salva(true)
			_avviso("Partita salvata.")
			p.queue_free(), Color(0.12, 0.14, 0.08)))
	v.add_child(bottone("REGOLE IN BREVE", func():
		p.queue_free()
		_mostra_regole_partita(), Color(0.12, 0.1, 0.14)))
	v.add_child(bottone("TORNA AL MENU", func():
		_salva(true)
		mostra_menu(), Color(0.25, 0.08, 0.06)))
	v.add_child(bottone("CHIUDI", p.queue_free))

func _mostra_regole_partita() -> void:
	var p := pannello(Color(0.03, 0.02, 0.02, 0.97), C_ORO)
	p.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.offset_left = 80
	p.offset_right = -80
	p.offset_top = 60
	p.offset_bottom = -60
	schermo.add_child(p)
	var v := VBoxContainer.new()
	p.add_child(v)
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.text = REGOLE
	rt.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rt.add_theme_font_override("normal_font", F_TESTO)
	rt.add_theme_font_override("bold_font", F_NERO)
	rt.add_theme_font_override("italics_font", F_CORSIVO)
	rt.add_theme_font_size_override("normal_font_size", 17)
	rt.add_theme_font_size_override("bold_font_size", 17)
	rt.add_theme_font_size_override("italics_font_size", 17)
	v.add_child(rt)
	v.add_child(bottone("CHIUDI", p.queue_free))

# ---------------------------------------------------------------- ciclo
func _process(delta: float) -> void:
	if not in_partita or m == null:
		return
	if m.s["fine"]:
		if mostrata != -2:
			mostrata = -2
			_aggiorna_tutto()
			_mostra_fine()
		return
	var a := m.attesa()
	if a.is_empty():
		return
	var g: int = a["g"]
	if posti[g] < 0:
		attesa_ia += delta * velocita
		var pausa := 0.75 if a.get("tipo", "") in ["guida", "segui"] else 0.4
		if attesa_ia >= pausa:
			attesa_ia = 0.0
			_mostra_attesa_ia(g)
			var k := ia.scegli(m, a)
			m.scegli(k)
			_aggiorna_tutto()
			if not online:
				_salva(false)
	elif umano(g):
		var n: int = m.s["decisioni"]
		if mostrata != n:
			if not online and umani_locali() > 1 and ultimo_umano >= 0 and ultimo_umano != g and cambio_mostrato != n:
				cambio_mostrato = n
				_passa_dispositivo(g)
				return
			if cambio_mostrato == n and has_meta("cambio_aperto"):
				return
			mostrata = n
			ultimo_umano = g
			_aggiorna_tutto()
			_mostra_scelte(a)
	elif online and not aspetto_rete:
		_aspetta_remoto()

func _passa_dispositivo(g: int) -> void:
	set_meta("cambio_aperto", true)
	var velo := ColorRect.new()
	velo.color = Color(0, 0, 0, 0.92)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	schermo.add_child(velo)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_CENTER)
	v.position = Vector2(-220, -80)
	v.custom_minimum_size = Vector2(440, 0)
	velo.add_child(v)
	var l := etichetta("Tocca a %s" % m.s["g"][g]["nome"], F_TITOLO, 34, Dati.TINTA[m.s["g"][g]["colore"]])
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	v.add_child(testo_lungo("Passa il dispositivo: la mano è nascosta finché non premi il pulsante.", 17))
	v.add_child(bottone("SONO PRONTO", func():
		remove_meta("cambio_aperto")
		velo.queue_free()
		ultimo_umano = g
		mostrata = -1, Color(0.3, 0.16, 0.05), 22))

func _mostra_attesa_ia(g: int) -> void:
	titolo_scelte.text = "%s sta decidendo..." % m.s["g"][g]["nome"]

func _aspetta_remoto() -> void:
	aspetto_rete = true
	var n: int = m.s["decisioni"]
	var d = await net.get_decision(codice, n)
	if d is Dictionary and d.has("i") and int(m.s["decisioni"]) == n:
		m.scegli(int(d["i"]))
		_aggiorna_tutto()
	else:
		await get_tree().create_timer(1.0).timeout
	aspetto_rete = false

func _decidi(i: int) -> void:
	_chiudi_zoom()
	for c in pannello_scelte.get_children():
		if c is Button:
			c.disabled = true
	if online:
		var n: int = m.s["decisioni"]
		var ok := await net.post_decision(codice, n, {"i": i})
		if not ok:
			_avviso("Rete: non riesco a inviare la mossa (" + net.last_error + "). Riprova.")
			mostrata = -1
			return
	m.scegli(i)
	plancia.evidenzia([])
	_aggiorna_tutto()
	if not online:
		_salva(false)

func _salva(subito: bool) -> void:
	if online or m == null:
		return
	m.s["posti"] = posti.duplicate()
	var testo := var_to_str(m.s)
	var f := FileAccess.open(SALVA_LOCALE, FileAccess.WRITE)
	if f:
		f.store_string(testo)
		f.close()
	var ora := Time.get_unix_time_from_system()
	if (subito or ora - ultimo_salvataggio > 30.0) and not salvataggio_in_corso:
		ultimo_salvataggio = ora
		salvataggio_in_corso = true
		await net.salva_partita({"v": testo})
		salvataggio_in_corso = false

# ---------------------------------------------------------------- scelte
func _mostra_scelte(a: Dictionary) -> void:
	for c in pannello_scelte.get_children():
		c.queue_free()
	if a.get("tipo", "") == "draft":
		_mostra_draft(a)
	var g: int = a["g"]
	titolo_scelte.text = str(a["testo"])
	titolo_scelte.add_theme_color_override("font_color", Dati.TINTA[m.s["g"][g]["colore"]].lightened(0.3))
	var sis := []
	var ops: Array = a["opzioni"]
	for i in ops.size():
		var o: Dictionary = ops[i]
		if o.has("sis"):
			sis.append(o["sis"])
		var b := bottone(str(o["t"]), _decidi.bind(i), _colore_opzione(o), 15)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if o.has("risorsa") and ResourceLoader.exists("res://assets/ui/ris_%s.png" % o["risorsa"]):
			b.icon = load("res://assets/ui/ris_%s.png" % o["risorsa"])
			b.expand_icon = false
			b.add_theme_constant_override("icon_max_width", 22)
		elif o.has("amb"):
			b.icon = load("res://assets/ui/amb_%s.png" % o["amb"])
			b.add_theme_constant_override("icon_max_width", 28)
		pannello_scelte.add_child(b)
	plancia.evidenzia(sis)
	_aggiorna_mano()
	_aggiorna_corte()

## Draft di Leader e Lore: le carte in grande, si sceglie cliccando.
func _mostra_draft(a: Dictionary) -> void:
	var velo := ColorRect.new()
	velo.color = Color(0.0, 0.0, 0.02, 0.86)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	schermo.add_child(velo)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 30
	v.offset_right = -30
	v.offset_top = 20
	v.offset_bottom = -20
	v.add_theme_constant_override("separation", 10)
	velo.add_child(v)
	var g: Dictionary = m.s["g"][a["g"]]
	v.add_child(etichetta("%s: %s" % [g["nome"], a["testo"]], F_TITOLO, 28, Dati.TINTA[g["colore"]].lightened(0.2)))
	v.add_child(testo_lungo("Ognuno prende 1 Leader e 1 Lore, in ordine inverso di turno. Clicca una carta per sceglierla.", 16, C_SPENTO))
	var ops: Array = a["opzioni"]
	for gruppo in ["leader", "lore"]:
		var riga := HBoxContainer.new()
		riga.add_theme_constant_override("separation", 12)
		riga.alignment = BoxContainer.ALIGNMENT_CENTER
		for i in ops.size():
			var o: Dictionary = ops[i]
			if not o.has(gruppo):
				continue
			var c: String = o[gruppo]
			var box := VBoxContainer.new()
			var im := immagine(img_carta(c), 160 if gruppo == "leader" else 170, 272 if gruppo == "leader" else 238)
			im.tooltip_text = _nome_carta(c)
			box.add_child(im)
			var b := bottone("SCEGLI", func():
				velo.queue_free()
				_decidi(i), Color(0.3, 0.16, 0.05), 15)
			box.add_child(b)
			im.gui_input.connect(func(ev):
				if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_RIGHT:
					_mostra_zoom(img_carta(c)))
			riga.add_child(box)
		if riga.get_child_count() > 0:
			v.add_child(etichetta("LEADER" if gruppo == "leader" else "LORE", F_TITOLO, 22, C_ORO_CHIARO))
			v.add_child(riga)
	v.add_child(etichetta("Tasto destro su una carta per ingrandirla.", F_CORSIVO, 14, C_SPENTO))

func _colore_opzione(o: Dictionary) -> Color:
	var v = o.get("v")
	if v is String:
		var sv: String = v
		if sv == "fine" or sv == "no" or sv == "basta" or sv == "passa":
			return Color(0.18, 0.08, 0.06)
		if sv.begins_with("spendi:"):
			return Color(0.1, 0.14, 0.2)
		if sv.begins_with("carta:"):
			return Color(0.2, 0.15, 0.04)
		if sv.begins_with("az:"):
			return Color(0.08, 0.16, 0.1)
	if o.has("modo"):
		return {"supera": Color(0.1, 0.18, 0.08), "cambia": Color(0.08, 0.13, 0.2), "copia": Color(0.14, 0.12, 0.12)}.get(o["modo"], Color(0.16, 0.12, 0.08))
	return Color(0.16, 0.12, 0.08)

func _scelte_per(chiave: String, valore) -> Array:
	var a := m.attesa()
	var out := []
	if a.is_empty() or not umano(a["g"]) or mostrata != int(m.s["decisioni"]):
		return out
	var ops: Array = a["opzioni"]
	for i in ops.size():
		if ops[i].has(chiave) and ops[i][chiave] == valore:
			out.append(i)
	return out

func _sistema_cliccato(id: String) -> void:
	var idx := _scelte_per("sis", id)
	if idx.size() == 1:
		_decidi(idx[0])
	elif idx.size() > 1:
		_menu_rapido("Cosa fai in %s?" % m.nome_sis(id), idx)
	else:
		_info_sistema(id)

func _menu_rapido(titolo: String, idx: Array) -> void:
	var a := m.attesa()
	var p := pannello(Color(0.04, 0.03, 0.02, 0.97), C_ORO)
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.position = Vector2(-230, -160)
	p.custom_minimum_size = Vector2(460, 0)
	schermo.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	p.add_child(v)
	v.add_child(etichetta(titolo, F_NERO, 18, C_ORO_CHIARO))
	for i in idx:
		var o: Dictionary = a["opzioni"][i]
		var b := bottone(str(o["t"]), func():
			p.queue_free()
			_decidi(i), _colore_opzione(o), 15)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		v.add_child(b)
	v.add_child(bottone("ANNULLA", p.queue_free, Color(0.15, 0.06, 0.05), 14))

func _info_sistema(id: String) -> void:
	if not m.in_gioco(id):
		return
	var t := m.nome_sis(id)
	var c := m.controllo(id)
	t += " — controllo: " + (m.s["g"][c]["nome"] if c >= 0 else "nessuno")
	var righe := []
	for i in m.s["n"]:
		var nv: Array = m.s["mappa"][id]["navi"][i]
		if nv[0] + nv[1] > 0:
			righe.append("%s: %d navi integre, %d danneggiate" % [m.s["g"][i]["nome"], nv[0], nv[1]])
	for e in m.s["mappa"][id]["edifici"]:
		if e != null:
			righe.append("%s di %s%s" % ["Città" if e["t"] == "citta" else "Spazioporto", m.s["g"][e["g"]]["nome"], " (danneggiato)" if e["danno"] else ""])
	_avviso(t + ("\n" + "\n".join(righe) if not righe.is_empty() else ""))

# ---------------------------------------------------------------- aggiornamento
func _aggiorna_tutto() -> void:
	if m == null or plancia == null:
		return
	var colori := []
	for i in m.s["n"]:
		colori.append(m.s["g"][i]["colore"])
	var eventi: Array = m.s["eventi"]
	plancia.aggiorna(m)
	for e in eventi:
		plancia.effetto(e, colori)
		_effetto_2d(e)
	m.s["eventi"] = []
	_aggiorna_top()
	_aggiorna_giocatori()
	_aggiorna_corte()
	_aggiorna_ambizioni()
	_aggiorna_mano()
	_aggiorna_diario()
	var a := m.attesa()
	if a.is_empty() or not umano(a["g"]):
		for c in pannello_scelte.get_children():
			c.queue_free()
		plancia.evidenzia([])
		if not a.is_empty():
			titolo_scelte.text = "Tocca a %s" % m.s["g"][a["g"]]["nome"]
			titolo_scelte.add_theme_color_override("font_color", Dati.TINTA[colori[a["g"]]].lightened(0.3))

func _aggiorna_top() -> void:
	var iz: int = m.s["iniz"]
	top_info.text = "Capitolo %d   Iniziativa: %s%s" % [m.s["capitolo"], m.s["g"][iz]["nome"], "  (sottratta da %s)" % m.s["g"][m.s["sottratta"]]["nome"] if m.s["sottratta"] >= 0 else ""]
	if m.s.has("camp"):
		var cp: Dictionary = m.s["camp"]
		top_info.text = "Atto %s, cap. %d/3   Iniziativa: %s" % [["I", "II", "III"][int(cp["atto"]) - 1], m.s["capitolo"], m.s["g"][iz]["nome"]]
		info_camp.text = "Politica imperiale: %s   Consiglio: %s   Tesoro Imperiale: %d" % [MotoreCampagna.NOME_POLITICA[cp["politica"]],
			"In Sessione" if cp["consiglio"] == "sessione" else "Deliberato", cp["tesoro"].size()]
		info_camp.visible = true
	top_info.add_theme_color_override("font_color", Dati.TINTA[m.s["g"][iz]["colore"]].lightened(0.2))
	for c in top_guida.get_children():
		c.queue_free()
	var gd: Dictionary = m.s.get("guida", {})
	if not gd.is_empty():
		pass
	# tracciato del Potere
	for i in m.s["n"]:
		var g: Dictionary = m.s["g"][i]
		top_guida.add_child(pallino(Dati.TINTA[g["colore"]], 22, str(g["potere"])))
	top_guida.add_child(etichetta("/ %d" % Motore.SOGLIA[m.s["n"]], F_TESTO, 15, C_SPENTO))
	# carte giocate in questo round
	for c in giocate_box.get_children():
		c.queue_free()
	for gg in m.s.get("giocate", []):
		var col: Color = Dati.TINTA[m.s["g"][gg["g"]]["colore"]]
		var w := VBoxContainer.new()
		var path := img_carta(gg["c"]) if gg["su"] else "res://assets/carte/retro_azione.webp"
		var im := immagine(path, 66, 92)
		im.tooltip_text = "%s: %s" % [m.s["g"][gg["g"]]["nome"], {"guida": "Guida", "supera": "Supera", "cambia": "Cambia", "copia": "Copia", "sottrai": "sottrae l'iniziativa", "evento": "Evento"}[gg["modo"]]]
		if gg["su"]:
			im.gui_input.connect(_clic_zoom.bind(path))
		w.add_child(im)
		var barra := ColorRect.new()
		barra.color = col
		barra.custom_minimum_size = Vector2(66, 4)
		w.add_child(barra)
		var mp := pannello(Color(0, 0, 0, 0.75), col)
		var modo := etichetta({"guida": "GUIDA", "supera": "SUPERA", "cambia": "CAMBIA", "copia": "COPIA", "sottrai": "SOTTRAE", "evento": "EVENTO"}[gg["modo"]], F_TITOLO, 11, col.lightened(0.3))
		modo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mp.add_child(modo)
		w.add_child(mp)
		giocate_box.add_child(w)

const PB_W := 270.0
const PB_H := 108.0
const PB_SLOT := [0.100, 0.212, 0.325, 0.443, 0.560, 0.676]
const PB_CITTA := [0.326, 0.443, 0.605, 0.798, 0.908]
const PB_OLTRAGGIO := {"materiale": 0.505, "carburante": 0.606, "armi": 0.707, "reliquie": 0.808, "psico": 0.909}

func _aggiorna_giocatori() -> void:
	for c in col_giocatori.get_children():
		c.queue_free()
	var a := m.attesa()
	for i in m.s["n"]:
		var g: Dictionary = m.s["g"][i]
		var col: Color = Dati.TINTA[g["colore"]]
		var turno: bool = not a.is_empty() and a["g"] == i
		var p := pannello(Color(0.03, 0.03, 0.06, 0.9) if not turno else Color(0.1, 0.07, 0.03, 0.95), col * Color(1, 1, 1, 1.0 if turno else 0.5))
		col_giocatori.add_child(p)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 2)
		p.add_child(v)
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 6)
		r.add_child(pallino(col, 18))
		var nome := etichetta(g["nome"], F_TITOLO, 16, col.lightened(0.25))
		nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nome.clip_text = true
		nome.custom_minimum_size = Vector2(40, 0)
		r.add_child(nome)
		if m.s.has("camp"):
			var cp: Dictionary = m.s["camp"]
			var titolo: String = "REGGENTE" if cp["titolo"][i] == "reggente" else "FUORILEGGE"
			if int(cp["primo"]) == i:
				titolo = "PRIMO REGGENTE"
			r.add_child(etichetta(titolo, F_TITOLO, 10, Color(0.75, 0.7, 0.95) if cp["titolo"][i] == "reggente" else Color(0.95, 0.5, 0.4)))
		if m.s["iniz"] == i:
			r.add_child(etichetta("INIZIATIVA", F_NERO, 10, C_ORO_CHIARO))
		r.add_child(etichetta("%d" % g["potere"], F_NERO, 19, C_ORO_CHIARO))
		v.add_child(r)
		v.add_child(_plancia_giocatore(i))
		var info := "Navi %d  Spazioporti %d  Agenti %d  Mano %d" % [g["navi"], g["porti"], g["agenti"], g["mano"].size()]
		if m.s.has("camp"):
			var favori := 0
			for x in m.s["camp"]["favori"][i].values():
				favori += int(x)
			if favori > 0:
				info += "   Favori %d" % favori
		var li := etichetta(info, F_TESTO, 12, C_SPENTO)
		li.clip_text = true
		li.custom_minimum_size = Vector2(40, 0)
		v.add_child(li)
		# carte Gilda, Leader e Lore
		var cc := HFlowContainer.new()
		cc.add_theme_constant_override("h_separation", 3)
		cc.add_theme_constant_override("v_separation", 3)
		var lista: Array = []
		if g["leader"] != "":
			lista.append(g["leader"])
		lista.append_array(g["lore"])
		lista.append_array(g["carte"])
		for c in lista:
			var im := immagine(img_carta(c), 34, 48)
			im.tooltip_text = _nome_carta(c)
			im.gui_input.connect(_clic_zoom.bind(img_carta(c)))
			cc.add_child(im)
		if not lista.is_empty():
			v.add_child(cc)

## La plancia giocatore stampata, con sopra risorse, città ancora da costruire, Oltraggio, Trofei e Prigionieri.
func _plancia_giocatore(i: int) -> Control:
	var g: Dictionary = m.s["g"][i]
	var col: Color = Dati.TINTA[g["colore"]]
	var box := Control.new()
	box.custom_minimum_size = Vector2(PB_W, PB_H)
	var file := "res://assets/plance/plancia_%s.webp" % g["colore"]
	var sf := immagine(file, PB_W, PB_H)
	sf.size = Vector2(PB_W, PB_H)
	sf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(sf)
	# città ancora sulla plancia (coprono spazi risorsa o bonus)
	for k in 5:
		if g["citta_plancia"][k]:
			var t := Control.new()
			t.position = Vector2(PB_CITTA[k] * PB_W - 10, 0.25 * PB_H - 10)
			t.size = Vector2(20, 20)
			t.mouse_filter = Control.MOUSE_FILTER_IGNORE
			t.draw.connect(func():
				t.draw_colored_polygon(PackedVector2Array([Vector2(10, 1), Vector2(19, 18), Vector2(1, 18)]), col)
				t.draw_polyline(PackedVector2Array([Vector2(10, 1), Vector2(19, 18), Vector2(1, 18), Vector2(10, 1)]), Color(0, 0, 0, 0.8), 1.2))
			box.add_child(t)
	# risorse
	for k in 6:
		var tr: String = g["risorse"][k]
		if tr == "":
			continue
		var ic := immagine("res://assets/ui/ris_%s.png" % tr, 21, 21)
		ic.size = Vector2(21, 21)
		ic.position = Vector2(PB_SLOT[k] * PB_W - 10.5, 0.237 * PB_H - 10.5)
		ic.tooltip_text = Dati.NOME_RISORSA[tr] + (" (Oltraggio)" if tr in g["oltraggio"] else "")
		if tr in g["oltraggio"]:
			ic.modulate = Color(1, 0.5, 0.5)
		box.add_child(ic)
	if g["antichi"] != "":
		var ia_ := immagine("res://assets/ui/ris_%s.png" % g["antichi"], 22, 22)
		ia_.size = Vector2(22, 22)
		ia_.position = Vector2(0.385 * PB_W, 0.03 * PB_H)
		box.add_child(ia_)
	# Oltraggio: un agente sull'icona della risorsa
	for t in g["oltraggio"]:
		var ag := icona_agente(g["colore"], 15)
		ag.position = Vector2(0.236 * PB_W - 7, PB_OLTRAGGIO[t] * PB_H - 8)
		ag.tooltip_text = "Oltraggio " + Dati.NOME_RISORSA[t]
		box.add_child(ag)
	# Trofei e Prigionieri
	_pezzi_in_riquadro(box, g["trofei"].map(func(x): return int(x["g"])), Rect2(0.47 * PB_W, 0.47 * PB_H, 0.24 * PB_W, 0.46 * PB_H), "Trofei")
	_pezzi_in_riquadro(box, g["prigionieri"], Rect2(0.765 * PB_W, 0.47 * PB_H, 0.18 * PB_W, 0.46 * PB_H), "Prigionieri", true)
	if m.bonus_citta(i) > 0:
		var b := etichetta("+%d" % m.bonus_citta(i), F_NERO, 14, C_ORO_CHIARO)
		b.position = Vector2(0.83 * PB_W, 0.02 * PB_H)
		box.add_child(b)
	return box

func _pezzi_in_riquadro(box: Control, chi: Array, r: Rect2, cosa: String, agenti := false) -> void:
	if chi.is_empty():
		return
	var conta := {}
	for j in chi:
		conta[j] = int(conta.get(j, 0)) + 1
	var fl := HFlowContainer.new()
	fl.position = r.position
	fl.size = r.size
	fl.add_theme_constant_override("h_separation", 2)
	fl.add_theme_constant_override("v_separation", 2)
	fl.tooltip_text = "%s: %d" % [cosa, chi.size()]
	for j in conta:
		var c: Color = Dati.TINTA[m.s["g"][j]["colore"]] if j < m.s["g"].size() else Color(0.6, 0.6, 0.6)
		if agenti and j < m.s["g"].size():
			fl.add_child(icona_agente(m.s["g"][j]["colore"], 20, conta[j]))
		else:
			fl.add_child(pallino(c, 15, str(conta[j])))
	box.add_child(fl)

func _nome_carta(c: String) -> String:
	if Dati.CORTE.has(c):
		return Dati.CORTE[c][0] + ": " + Dati.TESTO_CORTE[c]
	if Dati.LORE.has(c):
		return Dati.LORE[c][0] + ": " + Dati.LORE[c][1]
	if Dati.LEADER.has(c):
		return Dati.LEADER[c]["nome"] + ": " + Dati.LEADER[c]["testo"]
	return c

func _aggiorna_corte() -> void:
	if corte_box == null:
		return
	for c in corte_box.get_children():
		c.queue_free()
	for k in m.s["corte"].size():
		var slot: Dictionary = m.s["corte"][k]
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 2)
		var path := img_carta(slot["c"])
		var im := immagine(path, 50, 70)
		im.tooltip_text = _nome_carta(slot["c"])
		var scelte := _scelte_per("corte", k)
		if not scelte.is_empty():
			var bordo := pannello(Color(0, 0, 0, 0), C_ORO_CHIARO)
			bordo.add_theme_stylebox_override("panel", stile(Color(1.0, 0.8, 0.3, 0.25), C_ORO_CHIARO, 3, 4))
			bordo.add_child(im)
			v.add_child(bordo)
		else:
			v.add_child(im)
		im.gui_input.connect(_clic_corte.bind(k, path))
		var ag := HBoxContainer.new()
		ag.add_theme_constant_override("separation", 2)
		for i in m.s["n"]:
			var n: int = slot["ag"][i]
			if n > 0:
				ag.add_child(icona_agente(m.s["g"][i]["colore"], 24, n))
		v.add_child(ag)
		corte_box.add_child(v)
	titolo_corte.text = "LA CORTE   (mazzo %d, scarti %d)" % [m.s["mazzo_corte"].size(), m.s["scarti_corte"].size()]

func _clic_corte(ev: InputEvent, k: int, path: String) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		var idx := _scelte_per("corte", k)
		if idx.size() == 1:
			_decidi(idx[0])
		elif idx.size() > 1:
			_menu_rapido("Carta della Corte", idx)
		else:
			_mostra_zoom(path)

func _clic_zoom(ev: InputEvent, path: String) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_mostra_zoom(path)

func _mostra_zoom(path: String) -> void:
	for c in zoom_layer.get_children():
		c.queue_free()
	zoom_layer.visible = true
	var velo := ColorRect.new()
	velo.color = Color(0, 0, 0, 0.6)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	velo.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			_chiudi_zoom())
	zoom_layer.add_child(velo)
	var im := immagine(path, 0, 0)
	im.set_anchors_preset(Control.PRESET_FULL_RECT)
	im.offset_top = 60
	im.offset_bottom = -60
	im.mouse_filter = Control.MOUSE_FILTER_IGNORE
	zoom_layer.add_child(im)

func _chiudi_zoom() -> void:
	if zoom_layer:
		zoom_layer.visible = false

const AMB_K := 140.0 / 330.0
const AMB_ESAGONI := [Vector2(85, 190), Vector2(170, 190), Vector2(256, 190)]
const AMB_RIQUADRI := {"magnate": 268, "tiranno": 428, "generale": 588, "custode": 745, "empate": 905}
const AMB_CAPITOLI := [52, 113, 175, 237, 297]

## La plancia delle Ambizioni stampata, con i segnalini, i punteggi correnti e il capitolo.
func _aggiorna_ambizioni() -> void:
	for c in amb_box.get_children():
		c.queue_free()
	var k := AMB_K
	var sf := immagine("res://assets/plance/ambizioni.webp", 330 * k, 1214 * k)
	sf.size = Vector2(330 * k, 1214 * k)
	sf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	amb_box.add_child(sf)
	# segnalini disponibili negli esagoni
	var libero := 0
	for q in 3:
		if m.s["segnalini"][q]["amb"] == "":
			var sg := _segnalino(m.valore_segnalino(q), m.s["segnalini"][q]["girato"])
			sg.position = AMB_ESAGONI[libero] * k - Vector2(17, 11)
			amb_box.add_child(sg)
			libero += 1
	for amb in Dati.AMBIZIONI:
		var top: float = AMB_RIQUADRI[amb]
		var dich := 0
		for q in 3:
			if m.s["segnalini"][q]["amb"] == amb:
				var sg := _segnalino(m.valore_segnalino(q), m.s["segnalini"][q]["girato"])
				sg.position = Vector2(232 - dich * 46, top + 48) * k
				amb_box.add_child(sg)
				dich += 1
		var pts := m.classifica_ambizione(amb)
		var riga := HBoxContainer.new()
		riga.add_theme_constant_override("separation", 1)
		riga.position = Vector2(18, top + 82) * k
		for i in m.s["n"]:
			if pts[i] > 0 or dich > 0:
				riga.add_child(pallino(Dati.TINTA[m.s["g"][i]["colore"]] * Color(1, 1, 1, 1.0 if pts[i] > 0 else 0.4), 13, str(pts[i])))
		var virt: int = m.s["virtuale"].get(amb, 0)
		if virt > 0:
			riga.add_child(pallino(Color(0.4, 0.4, 0.4), 15, str(virt)))
		riga.tooltip_text = Dati.NOME_AMBIZIONE[amb]
		amb_box.add_child(riga)
		if dich > 0:
			var alone := Panel.new()
			alone.add_theme_stylebox_override("panel", stile(Color(1, 0.8, 0.3, 0.08), C_ORO_CHIARO, 2, 6))
			alone.position = Vector2(14, top - 8) * k
			alone.size = Vector2(304, 124) * k
			alone.mouse_filter = Control.MOUSE_FILTER_IGNORE
			amb_box.add_child(alone)
	# capitolo in corso
	var cap: int = clampi(int(m.s["capitolo"]), 1, 5)
	var anello := Panel.new()
	anello.add_theme_stylebox_override("panel", stile(Color(1, 0.75, 0.2, 0.35), C_ORO_CHIARO, 3, 20))
	anello.size = Vector2(66, 66) * k
	anello.position = Vector2(AMB_CAPITOLI[cap - 1] - 30, 1152 - 30) * k
	anello.mouse_filter = Control.MOUSE_FILTER_IGNORE
	amb_box.add_child(anello)
	# riserva delle risorse
	var ris := HFlowContainer.new()
	ris.position = Vector2(0, 1214 * k + 2)
	ris.size = Vector2(140, 40)
	ris.add_theme_constant_override("h_separation", 3)
	for t in Dati.RISORSE:
		ris.add_child(immagine("res://assets/ui/ris_%s.png" % t, 14, 14))
		ris.add_child(etichetta(str(m.riserva(t)), F_NERO, 11))
	ris.tooltip_text = "Risorse nella riserva"
	amb_box.add_child(ris)

func _segnalino(vs: Array, girato: bool) -> PanelContainer:
	var p := PanelContainer.new()
	var col := Color(0.85, 0.48, 0.12) if girato else Color(0.18, 0.42, 0.62)
	var s := stile(col, Color(0, 0, 0, 0.8), 1, 4)
	s.content_margin_left = 4
	s.content_margin_right = 4
	s.content_margin_top = 0
	s.content_margin_bottom = 0
	p.add_theme_stylebox_override("panel", s)
	p.add_child(etichetta("%d/%d" % [vs[0], vs[1]], F_NERO, 13, Color(1, 1, 1)))
	return p

func _aggiorna_mano() -> void:
	if mano_box == null:
		return
	for c in mano_box.get_children():
		c.queue_free()
	var me := io()
	if me < 0 or (not online and umani_locali() > 1 and has_meta("cambio_aperto")):
		mano_titolo.text = "Mano nascosta"
		return
	var g: Dictionary = m.s["g"][me]
	mano_titolo.text = "Mano di %s (%d carte)" % [g["nome"], g["mano"].size()]
	var mano: Array = g["mano"].duplicate()
	mano.sort()
	for c in mano:
		var path := img_carta(c)
		var scelte := _scelte_per("mano", c)
		var im := immagine(path, 104, 145)
		im.tooltip_text = Dati.nome_carta_azione(c)
		if not scelte.is_empty():
			var bordo := PanelContainer.new()
			var st := stile(Color(1.0, 0.8, 0.3, 0.2), C_ORO_CHIARO, 3, 6)
			st.content_margin_left = 3
			st.content_margin_right = 3
			st.content_margin_top = 3
			st.content_margin_bottom = 3
			bordo.add_theme_stylebox_override("panel", st)
			bordo.add_child(im)
			mano_box.add_child(bordo)
		else:
			mano_box.add_child(im)
		im.gui_input.connect(_clic_mano.bind(c, path))

func _clic_mano(ev: InputEvent, c: String, path: String) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		var idx := _scelte_per("mano", c)
		if idx.size() == 1:
			_decidi(idx[0])
		elif idx.size() > 1:
			_menu_rapido(Dati.nome_carta_azione(c), idx)
		else:
			_mostra_zoom(path)

func _aggiorna_diario() -> void:
	var log: Array = m.s["log"]
	if ultimo_log > log.size():
		ultimo_log = 0
		diario.clear()
	for k in range(ultimo_log, log.size()):
		var t: String = log[k]
		if t.begins_with("—"):
			diario.append_text("[b]%s[/b]\n" % t)
		else:
			diario.append_text(t + "\n")
	ultimo_log = log.size()

# ---------------------------------------------------------------- effetti 2D
func _effetto_2d(e: Dictionary) -> void:
	match e.get("tipo", ""):
		"capitolo":
			_mostra_banner("CAPITOLO %d" % e["n"], "Ognuno pesca 6 carte Azione", C_ORO_CHIARO)
		"ambizione":
			var g: Dictionary = m.s["g"][e["g"]]
			_mostra_banner(Dati.NOME_AMBIZIONE[e["amb"]].to_upper(), "%s dichiara l'ambizione" % g["nome"], Dati.TINTA[g["colore"]], "res://assets/ui/amb_%s.png" % e["amb"])
		"sottrai":
			var g: Dictionary = m.s["g"][e["g"]]
			_mostra_banner("INIZIATIVA SOTTRATTA", g["nome"], Dati.TINTA[g["colore"]])
		"oltraggio":
			var g: Dictionary = m.s["g"][e["g"]]
			_mostra_banner("OLTRAGGIO", "%s Reca Oltraggio: %s" % [g["nome"], Dati.NOME_RISORSA[e["t"]]], C_ROSSO, "res://assets/ui/ris_%s.png" % e["t"])
		"acquisisci":
			var g: Dictionary = m.s["g"][e["g"]]
			_mostra_banner(Dati.nome_corte(e["c"]).to_upper(), "acquisita da %s" % g["nome"], Dati.TINTA[g["colore"]])
		"dadi":
			_mostra_dadi(e)
		"punteggio":
			var righe := []
			for amb in e["risultati"]:
				var gg: Array = e["risultati"][amb]
				var parti := []
				for i in gg.size():
					if gg[i] > 0:
						parti.append("%s +%d" % [m.s["g"][i]["nome"], gg[i]])
				righe.append("%s: %s" % [Dati.NOME_AMBIZIONE[amb], ", ".join(parti) if not parti.is_empty() else "nessuno"])
			_mostra_banner("FINE DEL CAPITOLO", "\n".join(righe) if not righe.is_empty() else "Nessuna ambizione dichiarata", C_ORO_CHIARO, "", 4.5)

func _mostra_banner(titolo: String, sotto: String, col: Color, icona := "", durata := 2.2) -> void:
	for c in banner.get_children():
		c.queue_free()
	banner.visible = true
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	banner.add_child(v)
	if icona != "":
		var im := immagine(icona, 64, 52)
		v.add_child(im)
	var l := etichetta(titolo, F_TITOLO, 38, col.lightened(0.2))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	var s := etichetta(sotto, F_TESTO, 18, C_PERGAMENA)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(s)
	banner.custom_minimum_size = Vector2(460, 0)
	banner.reset_size()
	banner.position = Vector2(-230, -170)
	banner.modulate = Color(1, 1, 1, 0)
	var tw := create_tween()
	tw.tween_property(banner, "modulate:a", 1.0, 0.2)
	tw.tween_interval(durata / maxf(velocita, 1.0))
	tw.tween_property(banner, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func(): banner.visible = false)

class FacciaDado extends Control:
	var tipo := ""
	var faccia := 0
	func _draw() -> void:
		var col: Color = {"assalto": Color(0.72, 0.16, 0.12), "incursione": Color(0.2, 0.5, 0.52), "razzia": Color(0.85, 0.48, 0.15)}[tipo]
		draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), col)
		draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), Color(0, 0, 0, 0.8), false, 2.0)
		var simboli := []
		if tipo == "incursione":
			if faccia % 2 == 0:
				simboli = ["colpo"]
		elif tipo == "assalto":
			var f: Array = Motore.FACCE_ASSALTO[faccia]
			for k in f[0]:
				simboli.append("colpo")
			for k in f[1]:
				simboli.append("subito")
			for k in f[2]:
				simboli.append("intercetta")
		else:
			var f: Array = Motore.FACCE_RAZZIA[faccia]
			for k in f[0]:
				simboli.append("edificio")
			for k in f[1]:
				simboli.append("subito")
			for k in f[2]:
				simboli.append("intercetta")
			for k in f[3]:
				simboli.append("chiave")
		var n := simboli.size()
		for k in n:
			var c := Vector2(size.x * (k + 1) / (n + 1), size.y * 0.5)
			_simbolo(simboli[k], c, size.x * 0.17)
	func _simbolo(s: String, c: Vector2, r: float) -> void:
		match s:
			"colpo":
				var pts := PackedVector2Array()
				for k in 10:
					var rr := r if k % 2 == 0 else r * 0.45
					var a := -PI / 2 + k * PI / 5
					pts.append(c + Vector2(cos(a), sin(a)) * rr)
				draw_colored_polygon(pts, Color(1, 0.95, 0.85))
			"subito":
				draw_arc(c, r * 0.8, 0, TAU, 20, Color(0.05, 0.05, 0.05), 3.0)
			"intercetta":
				var pts := PackedVector2Array([c + Vector2(-r, -r * 0.8), c + Vector2(r, -r * 0.8), c + Vector2(r * 0.8, r * 0.2), c + Vector2(0, r), c + Vector2(-r * 0.8, r * 0.2)])
				draw_colored_polygon(pts, Color(0.1, 0.12, 0.2))
			"edificio":
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, r * 0.8), c + Vector2(-r, r * 0.8)]), Color(1, 0.95, 0.85))
			"chiave":
				draw_circle(c + Vector2(0, -r * 0.45), r * 0.42, Color(0.15, 0.08, 0.02))
				draw_rect(Rect2(c + Vector2(-r * 0.14, -r * 0.2), Vector2(r * 0.28, r * 1.1)), Color(0.15, 0.08, 0.02))

func _mostra_dadi(e: Dictionary) -> void:
	for c in dadi_box.get_children():
		c.queue_free()
	dadi_box.visible = true
	var v := VBoxContainer.new()
	dadi_box.add_child(v)
	var g: Dictionary = m.s["g"][e["g"]]
	v.add_child(etichetta("Battaglia di %s in %s" % [g["nome"], m.nome_sis(e["sis"])], F_TITOLO, 18, C_ORO_CHIARO))
	var r := HFlowContainer.new()
	r.custom_minimum_size = Vector2(420, 0)
	r.add_theme_constant_override("h_separation", 4)
	for tipo in ["assalto", "incursione", "razzia"]:
		for f in e["facce"][tipo]:
			var d := FacciaDado.new()
			d.tipo = tipo
			d.faccia = f
			d.custom_minimum_size = Vector2(46, 46)
			r.add_child(d)
	v.add_child(r)
	v.add_child(etichetta("Colpi %d   Agli edifici %d   Chiavi %d   Subiti %d%s" % [e["colpi"], e["ced"], e["chiavi"], e["auto"], "   Intercettazione" if e["inter"] else ""], F_NERO, 15))
	v.add_child(etichetta("stella = colpo, cerchio = colpo subito, scudo = intercettazione, triangolo = colpo agli edifici, chiave = razzia", F_CORSIVO, 12, C_SPENTO))
	dadi_box.reset_size()
	dadi_box.position = Vector2(-dadi_box.size.x * 0.5, 56)
	dadi_box.modulate = Color(1, 1, 1, 1)
	var tw := create_tween()
	tw.tween_interval(4.0 / maxf(velocita, 1.0))
	tw.tween_property(dadi_box, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func(): dadi_box.visible = false)

func _mostra_fine() -> void:
	var p := pannello(Color(0.04, 0.02, 0.01, 0.97), C_ORO_CHIARO)
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.position = Vector2(-260, -200)
	p.custom_minimum_size = Vector2(520, 0)
	schermo.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	var w: int = m.s["vincitore"]
	var g: Dictionary = m.s["g"][w]
	var t := etichetta("VINCE %s" % g["nome"].to_upper(), F_TITOLO, 36, Dati.TINTA[g["colore"]].lightened(0.2))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var ord := range(m.s["n"])
	ord.sort_custom(func(a, b): return m.s["g"][a]["potere"] > m.s["g"][b]["potere"])
	for i in ord:
		var r := HBoxContainer.new()
		r.add_child(pallino(Dati.TINTA[m.s["g"][i]["colore"]], 20))
		var n := etichetta(m.s["g"][i]["nome"], F_NERO, 20)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(n)
		r.add_child(etichetta("%d Potere" % m.s["g"][i]["potere"], F_NERO, 20, C_ORO_CHIARO))
		v.add_child(r)
	v.add_child(bottone("TORNA AL MENU", func():
		if FileAccess.file_exists(SALVA_LOCALE) and not online:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SALVA_LOCALE))
		mostra_menu(), Color(0.3, 0.16, 0.05), 20))
	v.add_child(bottone("GUARDA IL TAVOLO", p.queue_free))
