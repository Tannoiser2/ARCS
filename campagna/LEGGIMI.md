# Campagna «The Blighted Reach»: carte in italiano

Non esiste ancora l'edizione italiana della campagna: le carte vengono ricomposte in italiano partendo dalle
immagini inglesi del modulo TTS.

1. `tools/campagna/estrai_campagna.py` estrae dal modulo le carte (fronte e retro) in `camp/en/` e scrive `indice.json`.
2. `tools/campagna/ocr2.py` legge il testo inglese di ogni carta, riga per riga, con la posizione (`ocr2.json`).
3. Le traduzioni stanno in `traduzioni/*.json`: per ogni immagine, l'elenco `g` dei paragrafi in italiano nello stesso
   ordine dei paragrafi inglesi (`null` = lascia com'è, `""` = cancella). `*grassetto*`, `_corsivo_`, ` / ` = a capo.
   Facoltativi: `fascia` (scritta verticale delle carte Preparazione/Obiettivo), `titolo` + `titolo_box`.
4. `tools/campagna/rendi_it.py` cancella il testo inglese (solo i tratti delle lettere: lo sfondo resta) e scrive
   quello italiano con i font del gioco.
5. `tools/campagna/stampa.py SET` mostra i paragrafi ancora da tradurre di un Destino.

Glossario: Regent = Reggente, Outlaw = Fuorilegge, First Regent = Primo Reggente, Imperial Trust = Tesoro Imperiale,
Favor = Favore, Summit = Vertice, Crisis = Crisi, Edict = Editto, Blight = Piaga, Free city = città Libera,
Flagship = Ammiraglia, Fate = Destino, Act = Atto, Intermission = Intervallo, objective = obiettivo,
grand ambition = grande ambizione, scrap = elimina, bury = seppellisci, Imperial Council = Consiglio Imperiale.
Destini: Steward = Siniscalco, Founder = Fondatore, Magnate = Magnate, Advocate = Patrocinatore,
Caretaker = Curatore, Partisan = Partigiano, Admiral = Ammiraglio, Believer = Credente, Pathfinder = Esploratore,
Hegemon = Egemone, Planet Breaker = Distruttore di Pianeti, Pirate = Pirata, Blight Speaker = Voce della Piaga,
Pacifist = Pacifista, Peacekeeper = Paciere, Warden = Castellano, Judge = Giudice, Conspirator = Cospiratore,
Gate Wraith = Spettro dei Portali, Naturalist = Naturalista, Guardian = Guardiano, Redeemer = Redentore,
Survivalist = Sopravvissuto, Overlord = Signore Supremo.
