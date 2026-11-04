"""Plance giocatore in italiano: cancella i testi inglesi della plancia TTS e li riscrive."""
import cv2, numpy as np
from PIL import Image, ImageDraw, ImageFont
F='/home/claude/arcs/assets/font/'
SRC='/home/claude/src/Mods/Images/'
FILE={'giallo':'httpsdldropboxusercontentcomsaeue0uv0yfso1auplayerboardjpgdl0.jpg','verde':'httpsdldropboxusercontentcomsuyew4d7m1cr5quaplayerboard2jpgdl0.jpg',
 'rosso':'httpsdldropboxusercontentcomsqgwpo2fx5c4wk0zplayerboard3jpgdl0.jpg','bianco':'httpsdldropboxusercontentcoms8pmd3f430x6cxsbplayerboard4jpgdl0.jpg'}
BOX=[(160,450,510,980),(688,455,1070,975),(1330,385,1710,515),(2030,390,2372,550),(1962,250,2125,318),(2262,250,2425,318)]
W=(236,232,222)
def f(n,s): return ImageFont.truetype(F+n,s)
def scrivi(d,x,y,parti,larg,size,inter=1.22):
    # parti: lista di (testo, font)
    parole=[]
    for t,fn in parti:
        for w in t.split(' '):
            if w: parole.append((w,fn))
    cx=x; cy=y; sp=f('Testo.ttf',size).getlength(' ')
    for w,fn in parole:
        if w=='\\n': cx=x; cy+=size*inter; continue
        lw=fn.getlength(w)
        if cx>x and cx+lw>x+larg: cx=x; cy+=size*inter
        d.text((cx,cy),w,font=fn,fill=W); cx+=lw+sp
    return cy+size*inter
for col,fl in FILE.items():
    im=cv2.imread(SRC+fl)
    hsv=cv2.cvtColor(im,cv2.COLOR_BGR2HSV)
    mask=np.zeros(im.shape[:2],np.uint8)
    for x0,y0,x1,y1 in BOX:
        reg=hsv[y0:y1,x0:x1]
        m=((reg[:,:,2]>120)&(reg[:,:,1]<70)).astype(np.uint8)*255
        mask[y0:y1,x0:x1]=cv2.dilate(m,np.ones((5,5),np.uint8))
    im=cv2.inpaint(im,mask,5,cv2.INPAINT_TELEA)
    pil=Image.fromarray(cv2.cvtColor(im,cv2.COLOR_BGR2RGB)); d=ImageDraw.Draw(pil)
    n=f('Testo.ttf',30); b=f('TestoNero.ttf',30); t=f('Titoli.ttf',44)
    d.text((168,456),'RISORSE',font=t,fill=W,stroke_width=1,stroke_fill=W)
    y=scrivi(d,168,512,[('Potete spendere qualsiasi risorsa nel',n),('Preludio',b),('del vostro turno, dopo aver giocato una carta Azione ma prima di spenderne i punti.',n)],335,30)
    scrivi(d,168,y+10,[('Le risorse',n),('Oltraggiate',b),('non si spendono per il loro Preludio. L\'Oltraggio è spiegato nell\'azione Combattere.',n)],335,30)
    for yy,tit,txt in [(464,'MATERIALE:','Costruire o Riparare.'),(592,'CARBURANTE:','Muovere.'),(680,'ARMI:','in questo turno la carta Azione vi fa Combattere.'),(809,'RELIQUIE:','Acquisire.'),(896,'PSICOENERGIA:','un\'azione della carta Guida.')]:
        if yy in (464,):
            d.text((694,yy-2),tit,font=b,fill=W); d.text((694,yy+38),txt,font=n,fill=W)
        else:
            scrivi(d,694,yy-2,[(tit,b),(txt,n)],370,30,1.3)
    tt=f('Titoli.ttf',62); s=f('Testo.ttf',24)
    for cx,tit,sub in [(1515,'TROFEI','DALLA DISTRUZIONE DI PEZZI ALTRUI'),(2200,'PRIGIONIERI','DALL\'ACQUISIRE E DAL TASSARE')]:
        lw=tt.getlength(tit); d.text((cx-lw/2,396),tit,font=tt,fill=W,stroke_width=1,stroke_fill=W)
        lw=s.getlength(sub); d.text((cx-lw/2,484),sub,font=s,fill=W)
    s2=f('TestoNero.ttf',22)
    for cx in (2043,2343):
        for k,r in enumerate(['PER AMBIZIONE','VINTA']):
            lw=s2.getlength(r); d.text((cx-lw/2,256+k*26),r,font=s2,fill=W)
    pil=pil.resize((1290,517),Image.LANCZOS)
    pil.save('/home/claude/arcs/assets/plance/plancia_%s.webp'%col,quality=86)
print('ok')

# ---------------- plancia delle Ambizioni (colonna destra della mappa TTS)
Image.MAX_IMAGE_PIXELS=None
im=cv2.imread('/tmp/ambfull.png')
hsv=cv2.cvtColor(im,cv2.COLOR_BGR2HSV)
BOXA=[(120,110,890,220),(230,310,790,365),(330,770,830,870),(330,1225,860,1375),(600,1440,905,1600),(300,1690,900,1845),(600,1900,905,2060),(330,2185,830,2285),(330,2655,830,2755),(180,3130,830,3240)]
mask=np.zeros(im.shape[:2],np.uint8)
for x0,y0,x1,y1 in BOXA:
    reg=hsv[y0:y1,x0:x1]
    m=((reg[:,:,2]>120)&(reg[:,:,1]<80)).astype(np.uint8)*255
    mask[y0:y1,x0:x1]=cv2.dilate(m,np.ones((7,7),np.uint8))
im=cv2.inpaint(im,mask,7,cv2.INPAINT_TELEA)
pil=Image.fromarray(cv2.cvtColor(im,cv2.COLOR_BGR2RGB)); d=ImageDraw.Draw(pil)
def centra(txt,fn,cx,y):
    lw=fn.getlength(txt); d.text((cx-lw/2,y),txt,font=fn,fill=W,stroke_width=2,stroke_fill=W)
centra('AMBIZIONI',f('Titoli.ttf',96),506,112)
centra('SEGNALINI DISPONIBILI',f('Titoli.ttf',44),506,312)
for y,t in [(778,'MAGNATE'),(1278,'TIRANNO'),(1748,'GENERALE'),(2193,'CUSTODE'),(2663,'EMPATE')]:
    fn=f('Titoli.ttf',76)
    d.text((360,y),t,font=fn,fill=W,stroke_width=2,stroke_fill=W)
s=f('Titoli.ttf',38)
for y,riga in [(1450,['I PRIGIONIERI','TORNANO A FINE','CAPITOLO']),(1910,['I TROFEI','TORNANO A FINE','CAPITOLO'])]:
    for k,r in enumerate(riga):
        lw=s.getlength(r); d.text((895-lw,y+k*52),r,font=s,fill=W)
centra('CAPITOLO',f('Titoli.ttf',100),506,3135)
pil=pil.crop((45,0,1013,3560)).resize((330,1214),Image.LANCZOS)
pil.save('/home/claude/arcs/assets/plance/ambizioni.webp',quality=88)
