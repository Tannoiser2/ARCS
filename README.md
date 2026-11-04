# Arcs - versione digitale

Versione digitale non ufficiale, per uso personale, di **Arcs: conflitto e collasso nell'Orlo**
(Cole Wehrle, Leder Games; edizione italiana MS Edizioni). Si gioca da 2 a 4 giocatori, con
avversari IA per i posti vuoti, sullo stesso dispositivo o online con gli amici.

Si gioca qui: https://tannoiser2.github.io/ARCS/

## Cosa c'è

- **Regole complete del gioco base**: round a prese con carta Guida, Superare, Cambiare, Copiare e
  sottrarre l'iniziativa; ambizioni Magnate, Tiranno, Generale, Custode ed Empate con i segnalini che si
  girano a ogni capitolo; tutte le azioni (Tassare, Costruire, Riparare, Muovere con la Fionda, Influenzare,
  Acquisire, Combattere); Preludio con le risorse e le carte; combattimento con dadi Assalto, Incursione e
  Razzia, intercettazione, razzia di risorse e carte Gilda, Oltraggio e Soggiogare la Corte; bonus delle
  città; il giocatore virtuale delle partite in 2.
- **Le 31 carte della Corte** (25 Gilde e 6 Vox) con tutti i loro effetti.
- **Leader & Lore**: gli 8 Leader e le 14 Lore, scelti col draft in ordine inverso.
- **Le 12 carte Preparazione** per 2, 3 e 4 giocatori (o una a caso).
- **Carte italiane** scansionate dall'edizione MS Edizioni, raddrizzate e ritagliate in automatico.
- **Tavolo 3D**: la mappa dell'Orlo, le navi integre e danneggiate del modulo di Tabletop Simulator colorate
  per giocatore, città e spazioporti, l'alone di chi controlla ogni sistema; lampi, scintille, scie dei motori,
  colonne di luce ed esplosioni a seconda delle azioni e delle carte giocate. Si gira trascinando, si avvicina
  con la rotella, si sposta col tasto destro.
- **IA** che valuta ogni scelta simulandone l'effetto (Potere atteso dalle ambizioni, flotta, edifici,
  risorse, carte e Corte).
- **Online** con stanze di 4 lettere su Firebase (i posti vuoti li guida l'IA) e **salvataggio** automatico
  (sul dispositivo e su Firebase) delle partite contro l'IA.

## Struttura

- `scripts/motore.gd` – le regole: tutto lo stato in un dizionario, decisioni numerate (stessa sequenza =
  stessa partita su tutti i dispositivi).
- `scripts/dati.gd` – mappa (tipi di pianeta, spazi Edificio, adiacenze), carte, Leader, Lore, preparazioni.
- `scripts/ia.gd` – l'intelligenza artificiale.
- `scripts/plancia3d.gd` – il tavolo 3D e gli effetti; `scripts/main.gd` – menu e interfaccia;
  `scripts/rete.gd` – Firebase.
- `tools/controlla_glifi.py` – controlla che ogni carattere dei testi esista nei font.
- `firebase/database.rules.json` – regole del database (radice `arcs`, da unire a quelle del progetto condiviso).

## Prove

```
godot --headless --path . -s res://tests/sim.gd -- 10 4 leader   # 10 partite tutte IA da 4 giocatori
xvfb-run godot --path . -s res://tests/foto.gd -- partita 60     # screenshot dell'interfaccia
```

## Pubblicazione

Il workflow `Pubblica` parte a mano (Actions → Pubblica → Run workflow) oppure con un commit che contiene
`[pubblica]`. Con i segreti `CLOUDFLARE_API_TOKEN` e `CLOUDFLARE_ACCOUNT_ID` pubblica anche sulla ludoteca
privata di Cloudflare.

I font sono Alegreya Sans, Marcellus SC e Cinzel (licenza SIL Open Font, in `assets/font/`).
