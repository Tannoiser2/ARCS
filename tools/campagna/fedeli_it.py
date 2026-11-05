"""Carte azione Fedeli in italiano: riscrive le due strisce verticali (Zelo e Saggezza)."""
import cv2, numpy as np
from PIL import Image, ImageDraw, ImageFont
F='/home/claude/arcs/assets/font/'
BOX=(476,140,568,620)
def striscia(im, titolo, sotto):
    x0,y0,x1,y1=BOX
    reg=im.crop(BOX).rotate(90,expand=True)   # testo orizzontale
    a=np.array(reg).astype(int)
    bg=np.median(a.reshape(-1,3),axis=0)
    d=np.abs(a-bg).sum(2)
    m=(d>90).astype(np.uint8)*255
    scuri=a[d>150]
    col=tuple(int(v) for v in (np.median(scuri,axis=0) if len(scuri) else (60,60,150)))
    m=cv2.dilate(m,np.ones((5,5),np.uint8))
    bgr=cv2.cvtColor(np.array(reg).astype(np.uint8),cv2.COLOR_RGB2BGR)
    bgr=cv2.inpaint(bgr,m,5,cv2.INPAINT_TELEA)
    reg=Image.fromarray(cv2.cvtColor(bgr,cv2.COLOR_BGR2RGB))
    dr=ImageDraw.Draw(reg); W,H=reg.size
    ft=ImageFont.truetype(F+'Titoli.ttf',34)
    s=34
    while ft.getlength(titolo)>W-20: s-=1; ft=ImageFont.truetype(F+'Titoli.ttf',s)
    dr.text(((W-ft.getlength(titolo))/2,H-46),titolo,font=ft,fill=col,stroke_width=1,stroke_fill=col)
    parti=sotto.split(' o ')
    z=22
    while True:
        fs=ImageFont.truetype(F+'Testo.ttf',z); fb=ImageFont.truetype(F+'TestoNero.ttf',z)
        tot=sum(fs.getlength(p) for p in parti)+fb.getlength(' o ')*(len(parti)-1)
        if tot<W-16 or z<12: break
        z-=1
    x=(W-tot)/2
    for k,p in enumerate(parti):
        dr.text((x,8),p,font=fs,fill=col); x+=fs.getlength(p)
        if k<len(parti)-1:
            dr.text((x,8),' o ',font=fb,fill=col); x+=fb.getlength(' o ')
    im.paste(reg.rotate(-90,expand=True),(x0,y0))
for i in range(19,28):
    im=Image.open('/home/claude/camp/en/993_%d.jpg'%i).convert('RGB')
    striscia(im,'SAGGEZZA FEDELE','Costruire o Riparare o Acquisire')
    im=im.rotate(180)
    striscia(im,'ZELO FEDELE','Muovere o Influenzare o Combattere o Tassare')
    im=im.rotate(180)
    im.save('/home/claude/camp/it/993_%d.jpg'%i,quality=90)
print('ok')
