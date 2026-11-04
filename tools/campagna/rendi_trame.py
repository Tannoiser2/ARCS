"""Ricompone in italiano le carte Destino B e C (trame 217 e 218).

Il pannello bianco viene ripulito per intero e il testo viene reimpaginato:
titolo, motto in corsivo, intestazione tra le due linee, voci accanto ai numeri
romani (B) o un paragrafo unico (C). Il testo *tra asterischi* va in rosso grassetto.
Uso: python3 rendi_trame.py [prefisso...]
"""
import sys, json, glob, os
import numpy as np
from PIL import Image, ImageDraw
sys.path.insert(0, os.path.dirname(__file__))
import rendi_it as r

R = '/home/claude/camp'
NERO = (25, 22, 22)
ROSSO = (193, 44, 47)


def disegna_paragrafo(d, testo, size, x0, x1, y, centra=False, corsivo=False):
    fnt, righe, alt = r.impagina(testo, size, x1 - x0, False)
    for riga in righe:
        lw = r.larghezza_riga(fnt, riga)
        ox = (x0 + x1) / 2 - lw / 2 if centra else x0
        for w, st, x in riga:
            f = fnt['i'] if corsivo else fnt[st]
            d.text((ox + x, y), w, font=f, fill=ROSSO if st == 'b' else NERO)
        y += size * 1.18
    return y


def altezza(testo, size, larg):
    return r.impagina(testo, size, larg, False)[2]


def cerchi(a, y0, y1):
    """Righe occupate dai cerchi neri dei numeri romani (colonna x 130-215)."""
    col = (a[y0:y1, 130:215].max(2) < 80).sum(1)
    out, dentro = [], False
    for i, v in enumerate(col):
        if v > 25 and not dentro:
            out.append(y0 + i); dentro = True
        elif v <= 5 and dentro:
            dentro = False
    return out


def rendi(f, t):
    pil = Image.open(R + '/en/' + f).convert('RGB')
    a = np.array(pil).astype(int)
    W, H = pil.size
    d = ImageDraw.Draw(pil)
    # intestazione "YOUR/ANOTHER PATH TO POWER"
    hb = None
    for g in r.gruppi(f):
        for x in g:
            if 'PATH TO' in x['t'].upper() or 'POWER' in x['t'].upper():
                hb = x['box']
    hy0, hy1 = hb[1], hb[3]
    # titolo e motto
    d.rectangle([62, 738, 764, hy0 - 12], fill='white')
    fn = r.font('Titoli.ttf', 66)
    tit = r.maiuscoletto(t['titolo'])
    d.text((W / 2 - fn.getlength(tit) / 2, 742), tit, font=fn, fill=NERO, stroke_width=2, stroke_fill=NERO)
    size = 31
    while altezza(t['motto'], size, 600) > hy0 - 12 - 826 and size > 20:
        size *= 0.96
    disegna_paragrafo(d, t['motto'], size, 113, 713, 826, centra=True, corsivo=True)
    # intestazione tradotta
    testo_h = "UN'ALTRA VIA AL POTERE" if t.get('altra') else 'LA TUA VIA AL POTERE'
    fh = r.font('Testo.ttf', 33)
    lw = fh.getlength(testo_h)
    cx = (hb[0] + hb[2]) / 2
    d.rectangle([min(hb[0] - 6, cx - lw / 2 - 16), hy0 - 6, max(hb[2] + 6, cx + lw / 2 + 16), hy1 + 8], fill='white')
    d.text((cx - lw / 2, hy0 - 6), testo_h, font=fh, fill=NERO)
    fondo = 1300
    if t.get('voci'):
        top = hy1 + 14
        cs = cerchi(a, top, fondo)
        d.rectangle([226, top, 768, fondo + 15], fill='white')
        cs = cs[:len(t['voci'])]
        size = 32
        while size > 18:
            ok = True
            for i, v in enumerate(t['voci']):
                lim = (cs[i + 1] - 8) if i + 1 < len(cs) else fondo
                if cs[i] - 4 + altezza(v, size, 515) > lim:
                    ok = False
            if ok:
                break
            size *= 0.96
        for i, v in enumerate(t['voci']):
            disegna_paragrafo(d, v, size, 236, 751, cs[i] - 4)
    else:
        top = hy1 + 18
        d.rectangle([96, top, 768, fondo + 15], fill='white')
        size = 32
        while altezza(t['testo'], size, 615) > fondo - top - 10 and size > 18:
            size *= 0.96
        disegna_paragrafo(d, t['testo'], size, 108, 723, top + 8)
    # "Complexity:"
    tr = {'complessita': True, 'g': []}
    pil.save('/tmp/_trama.jpg', quality=95)
    os.makedirs(R + '/it', exist_ok=True)
    tmp = R + '/en/_tmp_trama.jpg'
    pil.save(tmp, quality=97)
    r.OCR['_tmp_trama.jpg'] = {'righe': [], 'h': H, 'w': W}
    r.rendi('_tmp_trama.jpg', tr, R + '/it/' + f)
    os.remove(tmp)


if __name__ == '__main__':
    trad = json.load(open(R + '/trad_trame/trame_bc.json'))
    solo = sys.argv[1:]
    n = 0
    for f, t in trad.items():
        if solo and not any(f.startswith(s) for s in solo):
            continue
        rendi(f, t); n += 1
    print('ricomposte', n)
