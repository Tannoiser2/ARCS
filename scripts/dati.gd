## Dati fissi di Arcs: mappa dell'Orlo, carte, Leader, Lore, preparazioni.
class_name Dati
extends RefCounted

const RISORSE := ["materiale", "carburante", "armi", "reliquie", "psico"]
const NOME_RISORSA := {"materiale": "Materiale", "carburante": "Carburante", "armi": "Armi",
	"reliquie": "Reliquie", "psico": "Psicoenergia"}
const COLORE_RISORSA := {"materiale": Color(0.62, 0.36, 0.72), "carburante": Color(0.78, 0.66, 0.24),
	"armi": Color(0.86, 0.36, 0.18), "reliquie": Color(0.40, 0.78, 0.86), "psico": Color(0.90, 0.42, 0.66)}

const AMBIZIONI := ["magnate", "tiranno", "generale", "custode", "empate"]
const NOME_AMBIZIONE := {"magnate": "Magnate", "tiranno": "Tiranno", "generale": "Generale",
	"custode": "Custode", "empate": "Empate"}
## valore della carta Azione -> ambizione che si può dichiarare
const AMBIZIONE_DI_VALORE := {2: "magnate", 3: "tiranno", 4: "generale", 5: "custode", 6: "empate"}
## segnalini Ambizione: [primo, secondo] sul lato blu e sul lato arancione
const SEGNALINI := [[[5, 3], [9, 4]], [[3, 2], [6, 3]], [[2, 0], [4, 2]]]

const SEMI := ["amm", "agg", "cos", "mob"]
const NOME_SEME := {"amm": "Amministrazione", "agg": "Aggressione", "cos": "Costruzione", "mob": "Mobilitazione"}
const AZIONI_SEME := {"amm": ["tassare", "riparare", "influenzare"], "agg": ["combattere", "muovere", "acquisire"],
	"cos": ["costruire", "riparare"], "mob": ["muovere", "influenzare"]}
const PUNTI := {"amm": [4, 4, 3, 3, 3, 2, 1], "agg": [3, 3, 2, 2, 2, 2, 1], "cos": [4, 4, 3, 3, 2, 2, 1],
	"mob": [4, 4, 3, 3, 2, 2, 1]}
const NOME_AZIONE := {"tassare": "Tassare", "riparare": "Riparare", "influenzare": "Influenzare",
	"combattere": "Combattere", "muovere": "Muovere", "acquisire": "Acquisire", "costruire": "Costruire"}
const COLORE_SEME := {"amm": Color(0.62, 0.62, 0.58), "agg": Color(0.72, 0.16, 0.16), "cos": Color(0.90, 0.45, 0.15),
	"mob": Color(0.18, 0.55, 0.62)}

## Plancia giocatore: 6 spazi Risorsa con il loro costo di razzia (chiavi).
const COSTO_SPAZIO := [3, 1, 1, 2, 1, 3]
## Le 5 città sulla plancia: la 1ª libera lo spazio 3, la 2ª il 4, la 3ª il 5 e il 6, la 4ª il bonus +2, la 5ª il +3.

const COLORI := ["bianco", "giallo", "verde", "rosso"]
const NOME_COLORE := {"bianco": "Bianco", "giallo": "Giallo", "verde": "Turchese", "rosso": "Rosso"}
const TINTA := {"bianco": Color(0.92, 0.90, 0.86), "giallo": Color(0.96, 0.74, 0.18), "verde": Color(0.20, 0.72, 0.74),
	"rosso": Color(0.86, 0.22, 0.20), "impero": Color(0.52, 0.48, 0.66), "piaga": Color(0.42, 0.70, 0.22),
	"liberi": Color(0.80, 0.72, 0.56)}
const TTS_COLORE := {"bianco": "White", "giallo": "Yellow", "verde": "Teal", "rosso": "Red"}

# ---------------- mappa ----------------
## Tipo dei pianeti per settore (a, b, c) e numero di spazi Edificio.
const TIPO := {
	"1a": "armi", "1b": "carburante", "1c": "materiale",
	"2a": "psico", "2b": "armi", "2c": "reliquie",
	"3a": "materiale", "3b": "carburante", "3c": "armi",
	"4a": "reliquie", "4b": "carburante", "4c": "materiale",
	"5a": "armi", "5b": "reliquie", "5c": "psico",
	"6a": "materiale", "6b": "carburante", "6c": "psico"}
const SPAZI := {
	"1a": 2, "1b": 1, "1c": 2, "2a": 1, "2b": 1, "2c": 2, "3a": 1, "3b": 1, "3c": 2,
	"4a": 2, "4b": 2, "4c": 1, "5a": 1, "5b": 1, "5c": 2, "6a": 1, "6b": 2, "6c": 1}

## Posizione dei sistemi sul tabellone (u, v in 0..1 sull'immagine della mappa ritagliata).
## Pianeti: centro del pianeta; portali: centro del settore dell'anello.
const POS := {
	"1g": Vector2(720, 285), "2g": Vector2(895, 420), "3g": Vector2(870, 600),
	"4g": Vector2(660, 680), "5g": Vector2(480, 545), "6g": Vector2(500, 370),
	"1a": Vector2(615, 110), "1b": Vector2(790, 135), "1c": Vector2(975, 100),
	"2a": Vector2(1085, 235), "2b": Vector2(1245, 345), "2c": Vector2(1175, 485),
	"3a": Vector2(1175, 615), "3b": Vector2(1010, 680), "3c": Vector2(1020, 840),
	"4a": Vector2(800, 820), "4b": Vector2(600, 860), "4c": Vector2(440, 805),
	"5a": Vector2(160, 785), "5b": Vector2(260, 590), "5c": Vector2(110, 485),
	"6a": Vector2(250, 360), "6b": Vector2(200, 190), "6c": Vector2(390, 135)}
## Spazi Edificio (triangoli) disegnati sulla mappa.
const POS_EDIFICI := {
	"1a": [Vector2(580, 127), Vector2(642, 99)], "1b": [Vector2(787, 121)],
	"1c": [Vector2(954, 86), Vector2(1008, 129)], "2a": [Vector2(1097, 243)], "2b": [Vector2(1256, 340)],
	"2c": [Vector2(1154, 480), Vector2(1210, 510)], "3a": [Vector2(1192, 612)], "3b": [Vector2(1008, 678)],
	"3c": [Vector2(1000, 873), Vector2(1053, 832)], "4a": [Vector2(785, 812), Vector2(838, 852)],
	"4b": [Vector2(586, 859), Vector2(638, 899)], "4c": [Vector2(436, 830)], "5a": [Vector2(152, 791)],
	"5b": [Vector2(248, 599)], "5c": [Vector2(82, 518), Vector2(135, 478)], "6a": [Vector2(246, 374)],
	"6b": [Vector2(176, 216), Vector2(229, 175)], "6c": [Vector2(380, 129)]}
## La mappa ritagliata copre x 900..6100 e y 0..3600 dell'immagine originale; le coordinate sopra sono
## in pixel di un'anteprima 1400x1000 di x 900..6100, y 0..3720.
static func uv(p: Vector2) -> Vector2:
	return Vector2(p.x / 1400.0, p.y * 3.72 / 3600.0)

static func sistemi() -> Array:
	var out := []
	for s in range(1, 7):
		out.append("%dg" % s)
		for l in ["a", "b", "c"]:
			out.append("%d%s" % [s, l])
	return out

static func settore(id: String) -> int:
	return int(id.substr(0, 1))

static func is_portale(id: String) -> bool:
	return id.ends_with("g")

## Adiacenze di base (senza settori fuori dal gioco).
static func adiacenze_base() -> Dictionary:
	var a := {}
	for id in sistemi():
		a[id] = []
	var link := func(x: String, y: String):
		if not y in a[x]:
			a[x].append(y)
		if not x in a[y]:
			a[y].append(x)
	for s in range(1, 7):
		var g := "%dg" % s
		for l in ["a", "b", "c"]:
			link.call(g, "%d%s" % [s, l])
		link.call("%da" % s, "%db" % s)
		link.call("%db" % s, "%dc" % s)
		link.call(g, "%dg" % (s % 6 + 1))
	# bordi sottili tra settori confinanti (gli altri sono crepe spesse)
	link.call("2c", "3a")
	link.call("5c", "6a")
	return a

# ---------------- carte Corte ----------------
## id: [nome italiano, tipo ("gilda"/"vox"), simbolo risorsa, costo razzia]
const CORTE := {
	"consiglio": ["Consiglio Imperiale", "consiglio", "", 0],
	"x11": ["Intrigo a Corte", "vox", "", 0],
	"x12": ["Fiasco Diplomatico", "vox", "", 0],
	"c01": ["Ingegneri Leali", "gilda", "materiale", 3],
	"c02": ["Attività Minerarie", "gilda", "materiale", 2],
	"c03": ["Cartello del Materiale", "gilda", "materiale", 3],
	"c04": ["Lega dei Custodi", "gilda", "materiale", 2],
	"c05": ["Lega dei Costruttori", "gilda", "materiale", 2],
	"c06": ["Cartello del Carburante", "gilda", "carburante", 3],
	"c07": ["Piloti Leali", "gilda", "carburante", 3],
	"c08": ["Guardiani dei Portali", "gilda", "carburante", 2],
	"c09": ["Alleanza Logistica", "gilda", "carburante", 2],
	"c10": ["Lega dei Navigatori", "gilda", "carburante", 2],
	"c11": ["Lega dei Combattenti", "gilda", "armi", 2],
	"c12": ["Guardie Carcerarie", "gilda", "armi", 2],
	"c13": ["Incursori", "gilda", "armi", 2],
	"c14": ["Sicari di Corte", "gilda", "armi", 2],
	"c15": ["Marine Leali", "gilda", "armi", 3],
	"c16": ["Spie del Reticolo", "gilda", "psico", 2],
	"c17": ["Veggenti", "gilda", "psico", 2],
	"c18": ["Ordine Segreto", "gilda", "psico", 2],
	"c19": ["Empati Leali", "gilda", "psico", 3],
	"c20": ["Persuasore", "gilda", "psico", 2],
	"c21": ["Custodi Leali", "gilda", "reliquie", 3],
	"c22": ["Guardiani Giurati", "gilda", "reliquie", 1],
	"c23": ["Negoziatore Anziano", "gilda", "reliquie", 2],
	"c24": ["Trafficante di Reliquie", "gilda", "reliquie", 2],
	"c25": ["Bardi Galattici", "gilda", "reliquie", 1],
	"c26": ["Rivolta di Massa", "vox", "", 0],
	"c27": ["Richieste Populiste", "vox", "", 0],
	"c28": ["L'Oltraggio Dilaga", "vox", "", 0],
	"c29": ["Canto di Libertà", "vox", "", 0],
	"c30": ["Conflitto fra Gilde", "vox", "", 0],
	"c31": ["In Azione!", "vox", "", 0],
}
## Le carte "Leali": spendi qualsiasi risorsa come quella del loro tipo e la tieni se Rechi Oltraggio.
const LEALI := {"c01": "materiale", "c07": "carburante", "c15": "armi", "c19": "psico", "c21": "reliquie"}
## Le Leghe: si mettono accanto a una carta giocata a faccia in su di quel seme e la riportano in mano.
const LEGHE := {"c04": "amm", "c05": "cos", "c10": "mob", "c11": "agg"}

## Breve promemoria in italiano dell'effetto (il testo completo è sulla carta scansionata).
const TESTO_CORTE := {
	"consiglio": "Acquisendolo, a fine round puoi convocare un Vertice; se sei Reggente diventi Primo Reggente, se sei Fuorilegge rubi dal Tesoro Imperiale; poi scegli se risolvere le Crisi o gli Editti.",
	"x11": "Crisi: il Consiglio Imperiale torna In Sessione e riceve gli agenti di questa carta; seppelliscila. Appena Acquisita: il Consiglio torna In Sessione.",
	"x12": "Crisi: chi ha più carte Gilda che agenti in riserva scarta Gilde fino a pareggiare; seppelliscila. Appena Acquisita: i Rivali risolvono la Crisi.",
	"c01": "Spendi qualsiasi risorsa come Materiale. Se Rechi Oltraggio tieni questa carta.",
	"c02": "Estrarre (Costruire): ottieni 1 Materiale. Preludio: scartala per riempire di Materiale gli spazi liberi.",
	"c03": "Tieni qui la riserva di Materiale (vale per Magnate). Dopo il calcolo i Rivali scartano il Materiale. Preludio: scartala per rubare 1 Materiale.",
	"c04": "Preludio: mettila accanto a una carta Amministrazione giocata a faccia in su; a fine round la prendi in mano.",
	"c05": "Preludio: mettila accanto a una carta Costruzione giocata a faccia in su; a fine round la prendi in mano.",
	"c06": "Tieni qui la riserva di Carburante (vale per Magnate). Dopo il calcolo i Rivali scartano il Carburante. Preludio: scartala per rubare 1 Carburante.",
	"c07": "Spendi qualsiasi risorsa come Carburante. Se Rechi Oltraggio tieni questa carta.",
	"c08": "Quando combatti in un portale scegli 2 dadi in più. Preludio: scartala per mettere 1 nave in ogni portale.",
	"c09": "Sintetizzare (Costruire): ottieni 1 Carburante. Preludio: scartala per riempire di Carburante gli spazi liberi.",
	"c10": "Preludio: mettila accanto a una carta Mobilitazione giocata a faccia in su; a fine round la prendi in mano.",
	"c11": "Preludio: mettila accanto a una carta Aggressione giocata a faccia in su; a fine round la prendi in mano.",
	"c12": "Reclutare (Costruire): restituisci Prigionieri per 1 risorsa ciascuno. Giustiziare (Influenzare): sposta i Prigionieri nei Trofei. Preludio: scartala per mettere 3 navi in un sistema che controlli.",
	"c13": "Dopo il tiro in combattimento ritira dadi Incursione fino ai tuoi simboli Armi. Preludio: scartala per mettere 3 navi in un sistema che controlli.",
	"c14": "Rapire (Combattere): cattura gli agenti Rivali su una carta della Corte con meno agenti dei tuoi simboli Armi. Preludio: scartala per mettere 3 navi in un sistema che controlli.",
	"c15": "Spendi qualsiasi risorsa come Armi. Se Rechi Oltraggio tieni questa carta.",
	"c16": "Preludio: prima di ogni altra azione, scartala per sottrarre l'iniziativa.",
	"c17": "Quando dichiari un'ambizione guarda la mano di un Rivale e puoi scambiare 1 carta. Preludio: scartala con altre carte e ripesca dal fondo degli scarti.",
	"c18": "Quando dichiari Custode o Empate non metti il segnalino Zero.",
	"c19": "Spendi qualsiasi risorsa come Psicoenergia. Se Rechi Oltraggio tieni questa carta.",
	"c20": "Preludio: scartala per rubare 1 carta Gilda o 1 risorsa.",
	"c21": "Spendi qualsiasi risorsa come Reliquie. Se Rechi Oltraggio tieni questa carta.",
	"c22": "I Rivali non possono rubarti risorse né altre carte Gilda. Se viene rubata, seppelliscila.",
	"c23": "Commerciare (Tassare): scambia 1 risorsa con un Rivale di cui controlli una città. Preludio: scartala per 1 Materiale, 1 Carburante e 1 Armi.",
	"c24": "Preludio: una volta per turno scarta 1 risorsa per ottenere 1 Reliquia.",
	"c25": "Quando Superi o Cambi puoi dichiarare l'ambizione della tua carta se nel round non ne è stata dichiarata una. Niente segnalino Zero.",
	"c26": "Appena Acquisita: scegli un settore e metti 1 nave in ogni suo sistema.",
	"c27": "Appena Acquisita: dichiara una qualsiasi ambizione.",
	"c28": "Appena Acquisita: scegli un tipo di risorsa; ogni giocatore Reca Oltraggio di quel tipo.",
	"c29": "Appena Acquisita: puoi riportare sulla plancia una città che controlli e sottrarre l'iniziativa. Rimescola la carta nel mazzo.",
	"c30": "Appena Acquisita: puoi rubare 1 carta Gilda a un Rivale. Rimescola le Gilde scartate nel mazzo Corte.",
	"c31": "Appena Acquisita: pesca 1 carta Azione dal fondo degli scarti.",
}

# ---------------- Leader & Lore ----------------
## risorse iniziali, partenze A/B/C: [edificio, navi]
const LEADER := {
	"antico": {"nome": "Antico", "risorse": ["reliquie", "materiale"], "A": ["citta", 3], "B": ["porto", 3], "C": ["", 2],
		"testo": "Amato: dopo aver difeso, se l'attaccante ha preso Trofei puoi Influenzare; i Rivali non Soggiogano la Corte combattendo contro di te. Onesto: a Tiranno non prendi il 2° posto, ma prendi il Potere del 2° posto se sei primo."},
	"mistico": {"nome": "Mistico", "risorse": ["psico", "reliquie"], "A": ["citta", 3], "B": ["porto", 3], "C": ["", 2],
		"testo": "Sintonizzato: quando Copi o Cambi per Tassare ottieni anche 1 Psicoenergia. Criptico: nella preparazione metti agenti negli spazi Oltraggio Materiale e Carburante."},
	"divoratore": {"nome": "Divoratore di Carburante", "risorse": ["carburante", "carburante"], "A": ["citta", 3], "B": ["porto", 3], "C": ["", 2],
		"testo": "Insaziabile: quando Copi o Cambi per Tassare ottieni anche 1 Carburante. Eccessivo: dopo il calcolo del Potere, se Magnate è stata calcolata scarti tutto il Carburante."},
	"arrivista": {"nome": "Arrivista", "risorse": ["psico", "materiale"], "A": ["citta", 4], "B": ["porto", 3], "C": ["", 2],
		"testo": "Ambizioso: quando dichiari un'ambizione puoi ottenere una qualsiasi risorsa. Inesperto: non puoi Tassare le tue città che non controlli."},
	"ribelle": {"nome": "Ribelle", "risorse": ["materiale", "armi"], "A": ["porto", 4], "B": ["", 5], "C": ["", 2],
		"testo": "Devoto: in combattimento scegli 2 dadi aggiuntivi. Disorganizzato: non puoi muovere più di 2 navi alla volta."},
	"guerriero": {"nome": "Guerriero", "risorse": ["armi", "materiale"], "A": ["citta", 3], "B": ["porto", 3], "C": ["", 2],
		"testo": "Tattico: quando Copi o Cambi per Combattere puoi Muovere prima o dopo. Violento: a Empate non prendi il 2° posto, ma prendi il Potere del 2° posto se sei primo."},
	"edonista": {"nome": "Edonista", "risorse": ["reliquie", "materiale"], "A": ["citta", 3], "B": ["citta", 3], "C": ["", 3],
		"testo": "Carismatico: quando Copi o Cambi per Acquisire puoi Influenzare prima o dopo. Generoso: per dichiarare un'ambizione devi dare 1 carta Gilda al Rivale con meno Potere."},
	"demagogo": {"nome": "Demagogo", "risorse": ["psico", "armi"], "A": ["citta", 3], "B": ["porto", 3], "C": ["", 2],
		"testo": "Ardito: quando dichiari un'ambizione puoi Influenzare una volta ogni carta della Corte. Paranoico: non puoi Acquisire Gilde con un solo agente Leale (ignoralo se Soggioghi la Corte)."},
}
const LEADER_ORDINE := ["antico", "mistico", "divoratore", "arrivista", "ribelle", "guerriero", "edonista", "demagogo"]
const PARTENZA_BASE := {"A": ["citta", 3], "B": ["porto", 3], "C": ["", 2]}

const LORE := {
	"l01": ["Tecnopreti", "Evocare (Costruire): una volta per turno costruisci 1 nave in una qualsiasi città che controlli."],
	"l02": ["Cannoni Galattici", "Sparare (Combattere): tira dadi Incursione per le tue navi integre in un sistema contro un difensore in un sistema adiacente."],
	"l03": ["Propulsori a Curvatura", "Quando muovi navi Leali integre puoi muoverle ancora una volta."],
	"l04": ["Scudi Riflettenti", "Quando difendi, aggiungi un colpo all'attaccante se ha tirato dadi Assalto."],
	"l05": ["Porti Nascosti", "Costruisci sempre navi integre. Se difendi con uno spazioporto integro, l'attaccante non sceglie dadi Razzia."],
	"l06": ["Disgregatore di Segnale", "Se attacchi con tutte le navi integre, ignori 1 colpo che subisci."],
	"l07": ["Droni Riparatori", "Dopo aver combattuto da attaccante ripari 1 nave Leale attaccante."],
	"l08": ["Portali Attrezzati", "Puoi costruire spazioporti nei portali (max 1). Le navi Rivali che entrano in un tuo portale con uno spazioporto integro ti danno 1 agente prigioniero."],
	"l09": ["Città Volanti", "Puoi costruire città sui pianeti fuori dagli spazi Edificio (max 1 per pianeta) spendendo 1 risorsa del tipo del pianeta."],
	"l10": ["Strutture Viventi", "Nutrire (Costruire): Tassa una città Leale. Potare (Riparare): sostituisci uno spazioporto Leale con una città Leale o viceversa."],
	"l11": ["Portali Abitati", "Puoi costruire città nei portali (max 1). Una città nel portale ha i tipi di tutte le città del suo settore."],
	"l12": ["Cannoni a Rotaia", "Quando difendi, se hai navi integre l'attaccante subisce 1 colpo prima di scegliere i dadi."],
	"l13": ["Antichi Possedimenti", "Questa carta ha uno spazio Risorsa con costo di razzia 3."],
	"l14": ["Siluri Traccianti", "Quando attacchi, dopo il tiro puoi ritirare 1 dado Assalto per ogni nave Leale integra attaccante."],
}

# ---------------- preparazioni ----------------
## nome, settori fuori dal gioco, partenze per giocatore [A, B, C] (2 giocatori: C e D sono entrambi C)
const PREPARAZIONI := {
	2: [
		{"nome": "Frontiere", "fuori": [1, 6], "p": [["5c", "4c", "3g", "3c"], ["3a", "5a", "5g", "4a"]], "img": "prep_312_00"},
		{"nome": "Origini", "fuori": [1, 4], "p": [["5a", "6a", "5g", "5c"], ["3c", "3a", "3g", "2a"]], "img": "prep_312_02"},
		{"nome": "Confini 1", "fuori": [2, 5], "p": [["4b", "3b", "1g", "6a"], ["6c", "3c", "4g", "1b"]], "img": "prep_312_01"},
		{"nome": "Confini 2", "fuori": [1, 4], "p": [["5b", "2a", "3g", "6b"], ["2b", "6a", "5g", "3c"]], "img": "prep_312_03"},
	],
	3: [
		{"nome": "Frontiere", "fuori": [2, 3], "p": [["1c", "4c", "6g"], ["5c", "1b", "5g"], ["4b", "6a", "1g"]], "img": "prep_312_05"},
		{"nome": "Origini", "fuori": [5, 6], "p": [["2c", "3b", "3g"], ["1c", "2a", "2g"], ["1a", "4c", "4g"]], "img": "prep_312_06"},
		{"nome": "Conflitto", "fuori": [3, 6], "p": [["1c", "2b", "1g"], ["2c", "1b", "2g"], ["1a", "2a", "4g"]], "img": "prep_312_07"},
		{"nome": "Confini", "fuori": [1, 4], "p": [["3c", "5b", "2g"], ["5c", "2a", "3g"], ["2c", "3a", "5g"]], "img": "prep_312_04"},
	],
	4: [
		{"nome": "Frontiere", "fuori": [5], "p": [["1c", "3b", "2g"], ["2c", "6c", "3g"], ["4b", "2a", "6g"], ["1a", "6a", "4g"]], "img": "prep_312_10"},
		{"nome": "Confini 1", "fuori": [3], "p": [["4a", "6c", "1g"], ["4c", "5c", "6g"], ["5a", "1c", "4g"], ["6a", "1a", "5g"]], "img": "prep_312_08"},
		{"nome": "Confini 2", "fuori": [4], "p": [["5c", "3a", "2g"], ["3c", "5b", "1g"], ["2c", "1c", "3g"], ["1a", "2a", "5g"]], "img": "prep_312_09"},
		{"nome": "Confini 3", "fuori": [6], "p": [["3c", "5b", "1g"], ["1a", "3a", "2g"], ["1c", "4c", "3g"], ["4a", "2b", "5g"]], "img": "prep_312_11"},
	],
}

## Mazzo Azioni: id "<seme><valore>"
static func carte_azione(n: int) -> Array:
	var out := []
	for s in SEMI:
		for v in range(1, 8):
			if n < 4 and (v == 1 or v == 7):
				continue
			out.append("%s%d" % [s, v])
	return out

static func is_evento(c: String) -> bool:
	return c.begins_with("evt")

static func seme(c: String) -> String:
	return c.substr(0, 3)

static func valore(c: String) -> int:
	return int(c.substr(3))

static func punti(c: String) -> int:
	if is_evento(c):
		return 0
	return PUNTI[seme(c)][valore(c) - 1]

static func nome_carta_azione(c: String) -> String:
	if is_evento(c):
		return "Evento"
	return "%s %d" % [NOME_SEME[seme(c)], valore(c)]

static func nome_corte(c: String) -> String:
	return CORTE[c][0] if CORTE.has(c) else c
