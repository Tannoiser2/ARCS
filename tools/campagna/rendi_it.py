#!/usr/bin/env python3
"""Ricompone in italiano le carte della campagna (immagini inglesi del modulo TTS).

Per ogni immagine: le righe di testo lette con l'OCR sono raggruppate in paragrafi; ogni paragrafo
tradotto viene cancellato (inpainting dei soli tratti del testo, lo sfondo resta) e riscritto in
italiano nello stesso spazio, con i font del gioco digitale. *grassetto* e _corsivo_ nel testo tradotto.
"""
import json, os, sys, glob, re
import numpy as np, cv2
from PIL import Image, ImageDraw, ImageFont

R = '/home/claude/camp'
FONT = '/home/claude/arcs/assets/font/'
OCR = json.load(open(R + '/ocr2.json'))

def gruppi(f):
    o = OCR[f]
    H = o['h']
    gr = {}
    ordine = []
    for r in o['righe']:
        if r['box'][1] > H * 0.925:
            continue
        k = (r['blk'], r['par'])
        if k not in gr:
            gr[k] = []
            ordine.append(k)
        gr[k].append(r)
    lista = [gr[k] for k in ordine]
    # unisce i paragrafi spezzati dall'OCR (stessa colonna, righe vicine, frase non finita)
    out = []
    for g in lista:
        if out:
            p = out[-1]
            ult = p[-1]
            gap = g[0]['box'][1] - ult['box'][3]
            stesso_x = abs(g[0]['box'][0] - p[0]['box'][0]) < 40 or abs(g[0]['box'][0] - ult['box'][0]) < 40
            fine = ult['t'].rstrip()[-1:] in '.:!?)'
            simile_h = abs(g[0]['h'] - ult['h']) <= 4
            if gap < ult['h'] * 1.2 and stesso_x and not fine and simile_h:
                p.extend(g)
                continue
        out.append(list(g))
    return out

def descrivi(f):
    out = []
    for i, g in enumerate(gruppi(f)):
        out.append('%d|%s' % (i, ' / '.join(r['t'] for r in g)))
    return out

def font(nome, size):
    return ImageFont.truetype(FONT + nome, max(8, int(size)))

def token(testo):
    """Divide il testo in parole con stile: (parola, 'n'|'b'|'i'), '\n' per andare a capo."""
    out = []
    stile = 'n'
    for par_i, par in enumerate(testo.split('\n')):
        if par_i:
            out.append(('\n', stile))
        for w in par.split(' '):
            if not w:
                continue
            s = stile
            pre = ''
            while w and w[0] in '*_':
                c = w[0]; w = w[1:]
                stile = ('b' if stile != 'b' else 'n') if c == '*' else ('i' if stile != 'i' else 'n')
                s = stile
            chiudi = None
            while w and w[-1] in '*_':
                chiudi = w[-1]; w = w[:-1]
            out.append((w, s))
            if chiudi:
                stile = 'n'
    return out

PICCOLE = {'di', 'del', 'della', 'dei', 'delle', 'dello', 'degli', 'con', 'e', 'a', 'al', 'alla', 'ai', 'alle', 'in', 'nel',
    'nella', 'nei', 'da', 'dal', 'dalla', 'per', 'il', 'la', 'le', 'lo', 'gli', 'i', 'un', 'una', 'uno', 'o', 'su', 'sul', 'sulla'}

def maiuscoletto(t):
    out = []
    for k, w in enumerate(t.split(' ')):
        if re.fullmatch(r'[IVX]+', w):
            out.append(w)
        elif w.isupper() or w.islower():
            lw = w.lower()
            if k > 0 and lw in PICCOLE:
                out.append(lw)
            elif "'" in lw:
                a, b = lw.split("'", 1)
                out.append(a[:1].upper() + a[1:] + "'" + b[:1].upper() + b[1:])
            else:
                out.append(lw[:1].upper() + lw[1:])
        else:
            out.append(w)
    return ' '.join(out)

def impagina(testo, size, larg, titolo):
    if titolo:
        f = {'n': font('Titoli.ttf', size), 'b': font('Titoli.ttf', size), 'i': font('Titoli.ttf', size)}
    else:
        f = {'n': font('Testo.ttf', size), 'b': font('TestoNero.ttf', size), 'i': font('TestoCorsivo.ttf', size)}
    righe = [[]]
    x = 0
    sp = f['n'].getlength(' ')
    for w, s in token(testo):
        if w == '\n':
            righe.append([]); x = 0; continue
        lw = f[s].getlength(w)
        if righe[-1] and x + sp + lw > larg:
            righe.append([]); x = 0
        if righe[-1]:
            x += sp
        righe[-1].append((w, s, x))
        x += lw
    alt = size * (1.0 if titolo else 1.18)
    return f, righe, alt * len(righe)

def larghezza_riga(f, riga):
    if not riga:
        return 0
    w, s, x = riga[-1]
    return x + f[s].getlength(w)

def cancella(img, box):
    x0, y0, x1, y1 = box
    reg = img[y0:y1, x0:x1]
    if reg.size == 0:
        return None
    bg = np.median(reg.reshape(-1, 3), axis=0)
    diff = np.abs(reg.astype(int) - bg).sum(2)
    m = (diff > 70).astype(np.uint8) * 255
    testo_px = reg[m > 0]
    col = None
    if len(testo_px) > 10:
        lum = testo_px.mean(1)
        # i pixel più lontani dallo sfondo danno il colore del testo
        d = np.abs(testo_px.astype(int) - bg).sum(1)
        col = tuple(int(c) for c in np.median(testo_px[d >= np.percentile(d, 60)], axis=0)[::-1])
    m = cv2.dilate(m, np.ones((5, 5), np.uint8))
    full = np.zeros(img.shape[:2], np.uint8)
    full[y0:y1, x0:x1] = m
    out = cv2.inpaint(img, full, 6, cv2.INPAINT_TELEA)
    img[:] = out
    return col

def rendi(f, trad, dest):
    img = cv2.imread(R + '/en/' + f)
    H, W = img.shape[:2]
    gs = gruppi(f)
    lista = trad.get('g', [])
    boxes = []
    for g in gs:
        x0 = min(r['box'][0] for r in g); y0 = min(r['box'][1] for r in g)
        x1 = max(r['box'][2] for r in g); y1 = max(r['box'][3] for r in g)
        hh = sorted(r['h'] for r in g)[len(g) // 2]
        boxes.append([x0, y0, x1, y1, hh])
    lavori = []
    for i, g in enumerate(gs):
        if i >= len(lista) or lista[i] is None:
            continue
        x0, y0, x1, y1, hh = boxes[i]
        testo_en = ' '.join(r['t'] for r in g)
        lettere = [c for c in testo_en if c.isalpha()]
        titolo = hh >= 25 and lettere and sum(c.isupper() for c in lettere) / len(lettere) > 0.75
        ruotato = (y1 - y0) > (x1 - x0) * 1.6 and len(g) <= 2
        # spazio disponibile: fino al gruppo successivo (o al piede della carta)
        sotto = int(H * 0.925) - 4
        for j in range(i + 1, len(gs)):
            if j < len(lista) and lista[j] == '':
                continue
            if boxes[j][1] > y1:
                sotto = min(sotto, boxes[j][1] - 4)
                break
        pad = 4
        # conta anche le parole lette con poca sicurezza (l'OCR spesso le scarta)
        for r in g:
            for w in r.get('w', []):
                if sum(c.isalnum() for c in w[0]) >= (2 if titolo else 1) and w[5] < hh * 1.8:
                    x0 = min(x0, w[2]); x1 = max(x1, w[2] + w[4])
        if testo_en.lower().startswith('wait to resolve'):
            box = [int(W * 0.13), 4, int(W * 0.87), int(H * 0.145)]
            col = cancella(img, box)
            lavori.append(("ATTENDI L'INTERVALLO\nPER RISOLVERLA", box, int(H * 0.034), col, True, box[3], box[0], box[2], False))
            continue
        if titolo:
            # i titoli su più righe a volte l'OCR non li legge tutti: si pulisce tutta la fascia
            box = [max(0, x0 - 45), max(0, int(y0 - hh * 0.12)), min(W, x1 + 45), min(H, int(max(y1 + 4, min(sotto, y1 + hh * 1.5))))]
        else:
            box = [max(0, x0 - 28), max(0, y0 - pad), min(W, x1 + pad), min(H, y1 + pad)]
        col = cancella(img, box)
        lavori.append((lista[i].replace(' / ', '\n'), box, hh, col, titolo and not ruotato, sotto, x0, x1, ruotato))
    pil = Image.fromarray(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))
    d = ImageDraw.Draw(pil)
    # una sola dimensione per tutto il corpo della carta (la più piccola che serve)
    def misura(testo, box, hh, titolo, sotto, x0, x1):
        if titolo:
            larg = max(x1 - x0 + 40, int(W * 0.8))
        else:
            larg = x1 - x0 + 6
        size = hh / (0.66 if titolo else 0.74)
        alt_max = max(box[3] - box[1], sotto - box[1])
        if titolo:
            alt_max = min(alt_max, hh * 2.6)
        while True:
            fnt, righe, alt = impagina(testo, size, larg, titolo)
            if alt <= alt_max + 2 or size < 9:
                break
            size *= 0.95
        return size, larg
    corpo = 999
    for testo, box, hh, col, titolo, sotto, x0, x1, rot in lavori:
        if testo and not titolo and not rot:
            corpo = min(corpo, misura(testo, box, hh, titolo, sotto, x0, x1)[0])
    for testo, box, hh, col, titolo, sotto, x0, x1, rot in lavori:
        if testo == '':
            continue
        if rot:
            # testo verticale (letto dal basso verso l'alto)
            bw, bh = box[3] - box[1], box[2] - box[0]
            tmp = Image.new('RGBA', (bw, bh), (0, 0, 0, 0))
            dt = ImageDraw.Draw(tmp)
            size = hh / 0.7
            while size > 8:
                fnt, righe, alt = impagina(testo, size, bw - 4, False)
                if alt <= bh:
                    break
                size *= 0.94
            yy = (bh - alt) / 2
            for riga in righe:
                lw = larghezza_riga(fnt, riga)
                for w, st, x in riga:
                    dt.text(((bw - lw) / 2 + x, yy), w, font=fnt[st], fill=col or (30, 25, 20))
                yy += size * 1.18
            tmp = tmp.rotate(90, expand=True)
            pil.paste(tmp, (box[0], box[1]), tmp)
            continue
        if col is None:
            col = (30, 25, 20)
        if titolo:
            testo = maiuscoletto(testo)
        size, larg = misura(testo, box, hh, titolo, sotto, x0, x1)
        if not titolo:
            size = corpo
        fnt, righe, alt = impagina(testo, size, larg, titolo)
        y = box[1] + (2 if not titolo else max(0, (box[3] - box[1] - alt) / 2) - size * 0.12)
        cx = (x0 + x1) / 2
        for riga in righe:
            lw = larghezza_riga(fnt, riga)
            ox = cx - lw / 2 if titolo else x0
            for w, s, x in riga:
                if titolo:
                    d.text((ox + x, y), w, font=fnt[s], fill=col, stroke_width=max(1, int(size / 24)), stroke_fill=col)
                else:
                    d.text((ox + x, y), w, font=fnt[s], fill=col)
            y += size * (1.0 if titolo else 1.18)
    # fascia verticale a sinistra (carte Preparazione e Obiettivo dei Destini)
    if trad.get('fascia'):
        img2 = cv2.cvtColor(np.array(pil), cv2.COLOR_RGB2BGR)
        x1f = int(W * 0.15)
        reg = img2[int(H * 0.02):int(H * 0.92), 0:x1f]
        bg = np.median(reg.reshape(-1, 3), axis=0)
        m = (np.abs(reg.astype(int) - bg).sum(2) > 90).astype(np.uint8) * 255
        m = cv2.dilate(m, np.ones((5, 5), np.uint8))
        full = np.zeros(img2.shape[:2], np.uint8)
        full[int(H * 0.02):int(H * 0.92), 0:x1f] = m
        img2 = cv2.inpaint(img2, full, 6, cv2.INPAINT_TELEA)
        pil = Image.fromarray(cv2.cvtColor(img2, cv2.COLOR_BGR2RGB))
        bh = int(H * 0.9)
        fn = font("Titoli.ttf", W * 0.06)
        testo = maiuscoletto(trad['fascia'])
        tmp = Image.new('RGBA', (bh, x1f), (0, 0, 0, 0))
        dt = ImageDraw.Draw(tmp)
        tw = fn.getlength(testo)
        dt.text((bh - tw - H * 0.02, x1f * 0.3), testo, font=fn, fill=(235, 228, 215), stroke_width=1, stroke_fill=(235, 228, 215))
        tmp = tmp.rotate(90, expand=True)
        pil.paste(tmp, (0, int(H * 0.02)), tmp)
    if trad.get('titolo_box'):
        x0b, y0b, x1b, y1b = trad['titolo_box']
        img2 = cv2.cvtColor(np.array(pil), cv2.COLOR_RGB2BGR)
        col = cancella(img2, [x0b, y0b, x1b, y1b]) or (250, 245, 235)
        pil = Image.fromarray(cv2.cvtColor(img2, cv2.COLOR_BGR2RGB))
        dt = ImageDraw.Draw(pil)
        testo = maiuscoletto(trad['titolo'])
        size = (y1b - y0b) * 0.42
        while size > 10:
            fnt, righe, alt = impagina(testo, size, x1b - x0b - 10, True)
            if alt <= (y1b - y0b) - 6:
                break
            size *= 0.95
        y = y0b + ((y1b - y0b) - alt) / 2 - size * 0.1
        for riga in righe:
            lw = larghezza_riga(fnt, riga)
            for w, st, x in riga:
                dt.text(((x0b + x1b) / 2 - lw / 2 + x, y), w, font=fnt[st], fill=col, stroke_width=max(1, int(size / 24)), stroke_fill=col)
            y += size
    # riquadri aggiuntivi che l'OCR non ha letto o ha unito male: {"box": [x0,y0,x1,y1], "t": testo, "titolo": bool}
    for ex in trad.get('extra', []):
        x0b, y0b, x1b, y1b = ex['box']
        img2 = cv2.cvtColor(np.array(pil), cv2.COLOR_RGB2BGR)
        cancella(img2, [x0b, y0b, x1b, y1b])
        col = tuple(ex.get('col', (30, 25, 20)))
        pil = Image.fromarray(cv2.cvtColor(img2, cv2.COLOR_BGR2RGB))
        dt = ImageDraw.Draw(pil)
        tit = ex.get('titolo', False)
        testo = maiuscoletto(ex['t']) if tit else ex['t'].replace(' / ', '\n')
        size = ex.get('size', (y1b - y0b) * 0.6 if tit else (corpo if corpo < 999 else 26))
        while size > 9:
            fnt, righe, alt = impagina(testo, size, x1b - x0b, tit)
            if alt <= (y1b - y0b) + 2:
                break
            size *= 0.95
        y = y0b + (max(0, ((y1b - y0b) - alt) / 2) - size * 0.1 if tit else 0)
        for riga in righe:
            lw = larghezza_riga(fnt, riga)
            ox = (x0b + x1b) / 2 - lw / 2 if tit else x0b
            for w, st, x in riga:
                if tit:
                    dt.text((ox + x, y), w, font=fnt[st], fill=col, stroke_width=max(1, int(size / 24)), stroke_fill=col)
                else:
                    dt.text((ox + x, y), w, font=fnt[st], fill=col)
            y += size * (1.0 if tit else 1.18)
    # parti dell'illustrazione da rimettere com'erano (icone e segnalini toccati dalla pulizia)
    if trad.get('ripristina'):
        orig = Image.open(R + '/en/' + f).convert('RGB')
        for bx in trad['ripristina']:
            pil.paste(orig.crop(tuple(bx)), (bx[0], bx[1]))
    d = ImageDraw.Draw(pil)
    # piede: tipo della carta
    piede = trad.get('piede')
    if piede is not False:
        fatto = False
        for r in OCR[f]['righe']:
            if r['box'][1] <= H * 0.925:
                continue
            for w in r.get('w', []):
                parola = re.sub(r'[^A-Z]', '', w[0].upper())
                it = PIEDI.get(parola)
                if it and w[1] > 20:
                    fatto = True
                    x, y, ww, hh = w[2:6]
                    img2 = cv2.cvtColor(np.array(pil), cv2.COLOR_RGB2BGR)
                    col = cancella(img2, [max(0, x - 3), max(0, y - 3), min(W, x + ww + 3), min(H, y + hh + 3)]) or (30, 25, 20)
                    pil = Image.fromarray(cv2.cvtColor(img2, cv2.COLOR_BGR2RGB))
                    d = ImageDraw.Draw(pil)
                    hh = min(hh, int(H * 0.026))
                    fn = font('Titoli.ttf', hh * 1.05)
                    it2 = maiuscoletto(it)
                    lw = fn.getlength(it2)
                    d.text((x + ww / 2 - lw / 2, y - hh * 0.2), it2, font=fn, fill=col, stroke_width=1, stroke_fill=col)
        if not fatto:
            pil = piede_fallback(pil)
    pil.save(dest, quality=88)

def piede_fallback(pil):
    import pytesseract
    W, H = pil.size
    x0, x1, y0, y1 = int(W * 0.28), int(W * 0.72), int(H * 0.935), int(H * 0.99)
    reg = pil.crop((x0, y0, x1, y1))
    from PIL import ImageOps
    big = reg.resize((reg.width * 3, reg.height * 3))
    d = pytesseract.image_to_data(big, config='--psm 7', output_type=pytesseract.Output.DICT)
    if not any(PIEDI.get(re.sub(r'[^A-Z]', '', t.upper())) for t in d['text']):
        # testo chiaro su fascia scura: si riprova in negativo
        g = np.array(big.convert('L'))
        d = pytesseract.image_to_data(Image.fromarray(np.where(g > 180, 0, 255).astype('uint8')), config='--psm 7', output_type=pytesseract.Output.DICT)
    for k in range(len(d['text'])):
        parola = re.sub(r'[^A-Z]', '', d['text'][k].upper())
        it = PIEDI.get(parola)
        if not it:
            continue
        x = x0 + d['left'][k] // 3; y = y0 + d['top'][k] // 3; ww = d['width'][k] // 3; hh = d['height'][k] // 3
        img2 = cv2.cvtColor(np.array(pil), cv2.COLOR_RGB2BGR)
        col = cancella(img2, [x - 3, y - 3, x + ww + 3, y + hh + 3]) or (30, 25, 20)
        pil = Image.fromarray(cv2.cvtColor(img2, cv2.COLOR_BGR2RGB))
        dr = ImageDraw.Draw(pil)
        fn = font('Titoli.ttf', min(max(hh * 1.3, H * 0.027), H * 0.03))
        it2 = maiuscoletto(it)
        lw = fn.getlength(it2)
        dr.text((x + ww / 2 - lw / 2, y - hh * 0.2), it2, font=fn, fill=col, stroke_width=1, stroke_fill=col)
        break
    return pil

PIEDI = {'GUILD': 'GILDA', 'EDICT': 'EDITTO', 'SETUP': 'PREPARAZIONE', 'RESOLUTION': 'RISOLUZIONE', 'LAW': 'LEGGE',
         'OBJECTIVE': 'OBIETTIVO', 'ABILITY': 'ABILITÀ', 'TITLE': 'TITOLO', 'EVENT': 'EVENTO', 'VOX': 'VOX',
         'LORE': 'LORE', 'ARTIFACT': 'ARTEFATTO', 'BURDENED': 'GRAVATO', 'WINDFALL': 'FORTUNA', 'POLICY': 'POLITICA',
         'UPGRADE': 'MIGLIORIA', 'COUNCIL': 'CONSIGLIO IMPERIALE', 'IMPERIAL': ' ', 'FATE': 'DESTINO',
         'CARD': ' ', 'REMINDER': 'PROMEMORIA', 'RULES': 'REGOLE', 'ECONOMY': 'ECONOMIA', 'MONOPOLY': 'MONOPOLIO', 'SUMMIT': 'VERTICE'}

if __name__ == '__main__':
    os.makedirs(R + '/it', exist_ok=True)
    trad = {}
    for t in sorted(glob.glob(R + '/trad/*.json')):
        trad.update(json.load(open(t)))
    solo = sys.argv[1:]
    n = 0
    for f, tr in trad.items():
        if solo and not any(f.startswith(s) for s in solo):
            continue
        rendi(f, tr, R + '/it/' + f)
        n += 1
    print('ricomposte', n)
