# Motore della campagna «L'Orlo Infestato» — progetto

Sintesi in italiano (parafrasi mia) delle regole della campagna e di come le
inseriamo nel motore esistente (`scripts/motore.gd`). Serve da guida per lo
sviluppo a tappe.

## Regole da implementare (Atto I)

### Struttura
- Tre Atti. Atti I e II: 3 capitoli. Atto III: 4 capitoli. Nessuna fine anticipata per soglia di Potere.
- Vince chi ha più Potere sommato dei tre Atti (parità: Destino A > B > C, poi ordine di turno).
  Nell'Atto III un Destino C vince subito a fine capitolo se l'obiettivo è a 0 e ha almeno 1 Potere.
- Obiettivo dell'Atto: segnalino obiettivo sul tracciato del Potere (partenza dall'orologio della carta,
  a volte in base al numero di giocatori); avanzare = scendere verso 0. A 0 l'obiettivo è completato.
  Se fallito, all'Intervallo si perde Potere pari alla casella del segnalino.
- Atto III: i Destini A/B hanno 2 grandi ambizioni (punteggio a fine capitolo secondo la tessera capitolo).

### Preparazione Atto I
1. Niente carte preparazione: nessun ammasso fuori gioco.
2. Corte: 15 carte CC (Gilda e Vox della campagna) + 1 Lore a caso per giocatore mescolata nel mazzo
   dopo aver distribuito la Corte (3 carte in 2 giocatori, 4 altrimenti). Consiglio Imperiale In Sessione
   come carta più a sinistra della Corte.
3. Azioni: carte 2-6 (+1 e 7 in 4 giocatori) + 2 carte Evento (2-3 giocatori) o 3 (4 giocatori).
4. Segnalini ambizione sul lato basso; segnalino zero nello spazio «ambizione dichiarata».
5. Editti nel libretto: in 2 giocatori «Le Delegazioni delle Gilde Partono» (00); i 3 «Governare l'Orlo
   Imperiale» (03-05) mescolati, quello in cima è la Politica attiva (Pace, Escalation o Guerra).
6. Tiro numerico: ammasso uscito e il successivo in senso orario sono imperiali: 1 nave imperiale in
   ogni sistema (8 navi).
7. Tiro evento: 1 città Libera su ogni pianeta del simbolo uscito fuori dagli ammassi imperiali.
8. 1 Piaga danneggiata in ogni sistema fuori dagli ammassi imperiali.
9. 2 giocatori: le 6 risorse dei pianeti degli ammassi imperiali vanno sui riquadri ambizione
   (Materiale e Carburante su Magnate, Armi su Generale, Reliquie su Custode, Psicoenergia su Empate).
10. Ogni giocatore pesca 2 Destini A, ne sceglie 1 in segreto; prepara secondo la carta obiettivo (lato
    preparazione), poi la gira; segnalino obiettivo sulla casella indicata; Potere 0; titolo Reggente.
    Se nessuno ha la tessera Primo Reggente, la prende chi ha l'iniziativa.
11. In ordine di turno: 3 navi + 1 edificio in uno spazio vuoto di un pianeta con nave imperiale, e
    1 risorsa di quel tipo. Poi di nuovo in ordine inverso.
12. Città Libere in tutti gli spazi edificio vuoti dei pianeti con navi imperiali.
13. 6 carte in mano; in 2 giocatori chi non ha l'iniziativa può fare mulligan (le Evento restano).

### Impero
- L'Impero controlla ogni sistema con almeno 1 nave imperiale integra, ignorando le navi Leali.
- Il Primo Reggente controlla i sistemi dell'Impero per ambizioni, obiettivi ed eventi.
- Legge della Presenza: nel turno di un Reggente, nei sistemi dove ha pezzi Leali, se il sistema è
  dell'Impero lo controlla lui e può usare le navi imperiali (muovere, riparare, combattere, costruire,
  tassare le città che controlla).
- Legge del Movimento: un Reggente muove al massimo 1 nave imperiale per ogni nave Leale che muove
  insieme a lei verso lo stesso sistema. Controllo dei portali e Catapulta:
  impero ferma i Fuorilegge; Reggente ferma Fuorilegge e Reggenti Rivali soli; Fuorilegge ferma tutti.
- Legge della Tregua: i Reggenti non danneggiano navi imperiali (salvo colpi subiti attaccando) e non
  danneggiano né tassano Reggenti Rivali nei sistemi con navi imperiali. In battaglia il Reggente
  attaccante può aggiungere le navi imperiali; il Reggente in difesa deve aggiungerle.
- Fuorilegge: in battaglia sceglie come difensore un Reggente o l'Impero (difendono le navi imperiali;
  il Primo Reggente prende i Trofei).

### Eventi
- Carta Evento: si gioca solo seguendo (non guida, non copia, non si scarta per sottrarre); dà le stesse
  azioni della carta di guida, salvo che un Rivale abbia già giocato un Evento o acquisito il Consiglio
  in questo round. Chi ha l'iniziativa e solo Eventi in mano deve passare l'iniziativa.
- A fine round con Eventi giocati (dopo il controllo dell'iniziativa): chi ha l'iniziativa può convocare
  un Vertice, poi tira dado evento e numerico: simbolo Crisi → Crisi; simbolo Editto → Editti.
  Se nello stesso round è stato acquisito il Consiglio, si risolve il Consiglio al posto dell'Evento.

### Consiglio Imperiale
- In Sessione: si influenza e acquisisce. Acquisito: si gira su Deciso; a fine round torna in Corte e:
  1) chi l'ha preso può convocare un Vertice; 2) se Reggente diventa Primo Reggente (tiene il Tesoro);
  3) se Fuorilegge ruba dal Tesoro fino ai suoi spazi risorsa vuoti, il Primo Reggente perde 1 Potere
  per risorsa; 4) sceglie se risolvere Crisi o Editti.
- Deciso: non si influenza né acquisisce; torna In Sessione a inizio Atto o con «Appellarsi al Consiglio».

### Stati Liberi
- Si possono usare gli edifici Liberi che si controllano (tassare città Libere senza catturare agenti,
  costruire navi e Catapulta dai porti Liberi, ripararli). Si possono danneggiare/distruggere (Trofei,
  distruggere una città Libera Reca Oltraggio). In battaglia «Stati Liberi» come difensore: difendono gli
  edifici Liberi. Razzia: esattamente 1 risorsa del tipo del pianeta spendendo una chiave.

### Vertice
- Richiamo all'Ordine (solo chi convoca): Restituire Favori (forzare azioni di Trattativa, 1 Favore
  ciascuna, Trasferire Beni costa il costo di razzia), Appellarsi al Consiglio (In Sessione), Lasciare
  l'Impero (diventa Fuorilegge; se Primo Reggente la tessera va al Reggente con più Potere, altrimenti
  il Tesoro torna nella riserva perdendo 1 Potere a risorsa), Rifondare l'Impero (se non ci sono
  Reggenti torna Reggente e prende la tessera).
- Trattative (con consenso): Cedere il Controllo, Delegare l'Autorità, Promettere un Favore,
  Trasferire Beni, Invitare nell'Impero (Primo Reggente rende Reggente un Fuorilegge).
- Nel digitale: trattative proposte e accettate con finestre di scelta; l'IA accetta solo scambi che
  la sua valutazione giudica vantaggiosi.

### Crisi
Ordine: Crisi della Piaga → Crisi dei Destini (carte dei giocatori, in ordine di turno) → Crisi della
Corte (testo Crisi delle carte Vox da sinistra a destra; prima le carte attaccate).
- Crisi della Piaga: ogni Piaga integra infligge 3 colpi, danneggiata 1; prima alle navi imperiali, poi
  a ogni giocatore con navi Leali nel sistema (ogni colpo a ciascuno), integre prima delle danneggiate.
- Dadi: «ammasso tirato» (numerico), «pianeti del simbolo» (evento), «pianeta tirato» (combinazione).

### Piaga
- Resistente: 2 colpi per danneggiare o distruggere. Si distrugge come Trofeo. Difensore in battaglia
  (colpita solo con colpi, non intercetta). Ferma la Catapulta. Se manca, si prende da chi ha più Trofei
  di Piaga.

### Editti (in ordine di numero)
- 00 (2 giocatori): seppellisci le Gilde senza agenti in Corte e rifornisci.
- 03-05 Governare l'Orlo Imperiale: il Primo Reggente applica la Politica o la cambia (mette in cima
  un'altra carta). Applicare: Tributo da ogni Reggente (Pace: Reliquie o Psicoenergia; Escalation:
  Materiale, Carburante o Armi; Guerra: Trofei o Prigionieri non imperiali né di Reggenti) nel Tesoro
  (anche 1 suo, se l'ha); chi non ha nulla dà 1 agente come Favore; chi non ha agenti può diventare
  Fuorilegge. Poi Azione Imperiale: Pace = ogni Reggente ottiene il bonus città scoperto; Escalation =
  2 navi imperiali integre in un sistema dell'Impero (o su un porto Leale); Guerra = 1 Armi a ogni
  Reggente (dalla riserva o dal Tesoro).
- Tesoro Imperiale: risorse congelate (contano per le ambizioni, non si spendono), si svuota
  all'Intervallo.

### Regole nuove
- Gilde protette (X al posto del costo): non si tolgono se non Recando Oltraggio del loro seme.
- Carte attaccate: sopra una carta della Corte senza carta attaccata; si acquisiscono insieme.
- Risorse congelate: non spendibili/scartabili, ma rubabili e contano.
- Gettoni dei Destini: non danneggiabili e non Leali salvo indicazione.

### Intervallo (fine Atti I e II)
A) Carte Risoluzione dei Destini; chi ha fallito perde Potere pari al segnalino obiettivo.
B) Corte: tutto torna nel mazzo tranne il Consiglio; agenti ai giocatori; scarti della Corte eliminati.
C) Trofei e Prigionieri restituiti; risorse congelate (anche Tesoro) nella riserva; 2 giocatori: risorse
   dei riquadri nella riserva.
D) Ripara la Piaga danneggiata; distruggi navi, edifici e Migliorie danneggiati; distruggi gli edifici
   nei sistemi con Piaga e senza navi.
E) Iniziativa a chi ha più Potere; chi ha più di 1 Potere ne perde metà (arrotondando a perdere meno).
F) Chi ha completato pesca 1 Destino (B dopo Atto I, C dopo Atto II), chi ha fallito ne pesca 2 e
   rimette il suo; si sceglie in segreto.

### Preparazione Atti II e III
Come l'Atto precedente (Potere compreso), con: segnalini ambizione girati (1 in Atto II, 2 in III);
Corte rimescolata e distribuita, Consiglio In Sessione; Piaga danneggiata su ogni portale senza Piaga e
senza navi; tiro evento: in ogni ammasso Piaga sul pianeta del simbolo (o su tutti i suoi pianeti senza
Piaga se c'era già); 2 giocatori: risorse di 2 ammassi tirati sui riquadri; preparazione del Destino.

## Modello dati (stato `s`)
- `s.camp` = {atto, destini[i], titolo[i] ("reggente"/"fuorilegge"), primo (indice o -1), tesoro [],
  consiglio ("sessione"/"deciso"), consiglio_preso (indice o -1), editti [id...], politica ("pace",
  "escalation", "guerra"), favori[i] {colore: n}, obiettivo[i] (casella), evento_giocato (indice o -1)}.
- Mappa: per sistema `imp` [integre, danneggiate], `piaga` [integre, danneggiate]; edifici Liberi con
  `g = -2`.
- `controllo(id)` resta per i giocatori; nuovo `controllo_per(id, i)` applica Impero e Legge della
  Presenza. Il Primo Reggente conta come controllore dei sistemi dell'Impero per ambizioni ed eventi.
- Carte dei Destini: codice per id della carta (es. `463_02`), testo e immagine da `campagna/carte.json`.

## Tappe
1. Base dell'Atto I: preparazione, Impero (controllo e leggi), Piaga, città Libere, carte Evento,
   Consiglio, Crisi della Piaga, Editto Governare l'Orlo, Tesoro, fine Atto dopo 3 capitoli,
   modalità «Campagna» nel menu. Vertice ridotto: Richiamo all'Ordine (Lasciare l'Impero, Appellarsi al
   Consiglio, Rifondare l'Impero).
2. Corte della campagna (15 carte CC con Crisi) e le 8 carte Destino A con i loro set dell'Atto I.
3. Trattative del Vertice e Favori; IA che negozia.
4. Intervallo, scelta del Destino B, Ammiraglie, Atto II.
5. Atto III, Destini C, grandi ambizioni e obiettivi finali.
6. Salvataggio della campagna fra un Atto e l'altro (locale e Firebase).

## Stato (motore dei Destini)
Catena delle classi: `Motore` → `MotoreCampagna` (campagna.gd) → `MotoreDestini` (destini.gd) →
`MotoreOrlo` (orlo.gd, classe finale usata da main.gd e dai test).

- **destini.gd**: dati delle carte dei Destini (`assets/dati/destini.json`, caricati in `Dati.EXTRA`),
  numeri delle carte di ogni set (`NUM`), alias delle Gilde uguali a quelle del gioco base (`ALIAS`),
  tabelle `PREP` (preparazione per Atto) e `RIS` (risoluzione all'Intervallo, completato o no),
  scelta del Destino (si pescano 2 carte, se ne tiene 1; all'Intervallo chi ha completato pesca 1
  carta e può tenere il Destino, chi non l'ha completato ne pesca 2), libretto delle regole,
  segnalino obiettivo (`avanza`), Intervallo A–F, preparazione degli Atti II e III, Atto III di 4
  capitoli, vincitore finale (più Potere; parità A > B > C; un Destino C con obiettivo a 0 e almeno 1
  Potere vince subito alla fine del capitolo).
- **orlo.gd**: obiettivi di tutti i 24 Destini, grandi ambizioni dei Destini A e B nell'Atto III
  (2/4, 3/8, 4/14, 5/20 Potere per capitolo), segnalini sulla mappa, Trattative del Vertice
  (cedere una risorsa per un Favore), valore degli obiettivi per l'IA (`valore_ia`).
- **Combattimento**: chiunque attacca Piaga e Stati Liberi; solo i Fuorilegge attaccano l'Impero;
  Legge della Tregua (Reggenti non si attaccano dove c'è una nave imperiale integra).

### Semplificazioni da rivedere
- Segnalini dei Destini automatici alla fine del turno del loro giocatore: Golem e Frammenti si
  prendono con una propria nave nel sistema; Stendardi, Seggi e Passaggi si mettono su un sistema
  controllato (Passaggi: portali con proprie navi); Indizi uno per settore, il Portale al 4º Indizio;
  Pellegrini +1 per turno con navi sul Portale; Navi Spora / Guide delle Spore mettono 1 Piaga.
- Martello Planetario: con tutti i Frammenti, una volta per capitolo distrugge gli edifici Rivali di un
  pianeta con proprie navi.
- Monopoli: con l'Editto Ottenere Monopoli li prende chi ha più della metà delle risorse di quel tipo
  in gioco (le risorse non passano sulla carta Monopolio).
- Pila Fedeli: valori 1–7, ne esce una quando il Credente acquisisce una carta; Ideali sulle ambizioni
  che il Credente dichiara (Atti II e III).
- Cospirazioni: una per ogni ambizione dichiarata da un Rivale, sul giocatore in testa in quel momento.
- Pace: settore senza navi di due giocatori diversi nello stesso sistema.
- Ammiraglie: una nave che segue la flotta (se il suo sistema si svuota passa dove il giocatore ha più
  navi). Funzionano Raggio Traente (niente razzia contro l'Ammiraglia) e Sistema Difensivo
  (intercetta con 1 colpo per spazioporto sulla plancia); Propulsore a Scia, Gru Navale e Sistema di
  Controllo non ancora.
- Ambizioni nuove: chi dichiara Magnate o Empate sceglie da solo Guardia dell'Eden o Stirpe della Piaga
  (se sono nel libretto) quando gli conviene; il Fondatore mette il segnalino Confederazione sulla
  prima ambizione che dichiara negli Atti II e III; si perde l'adesione distruggendo un edificio Libero.
- Editti dei Destini con effetto: Fonderie Imperiali, Ottenere Monopoli, Richiesta del Patrocinatore,
  I Golem Saziano la loro Fame, Dividendi della Pace, Rimprovero degli Empati, Rimprovero dei Custodi
  (solo con Custode dichiarata), L'Orlo Rifiuta il Signore Supremo, I Signori Ottengono Potere.
  Leggi con effetto: Protettori Imperiali, Supremazia delle Gilde. Gli altri Editti e Leggi (Fede,
  Armistizi, Cessate il Fuoco, Legge Marziale, Corti Feudali, Economia Chiusa, Sottrazione Partigiana,
  Bunker resistenti, Dicerie...) sono consultabili nel libretto ma non hanno ancora effetto.
