# Trova ogni carta TTS (inglese) nelle scansioni italiane con SIFT e la raddrizza alla stessa geometria
import cv2,numpy as np,json,glob,os
idx=json.load(open('/home/claude/lavoro/carte_tts.json'))
DECKS={363:'corte',977:'lore',387:'lore',384:'leader',308:'azione',310:'azione',312:'prep'}
cards={}
for e in idx:
    if e['deck'] in DECKS: cards[(e['deck'],e['i'])]=e
sift=cv2.SIFT_create(4000)
S=0.5
pages=[]
for f in sorted(glob.glob('/home/claude/scan300/p-*.jpg')):
    im=cv2.imread(f); sm=cv2.resize(im,None,fx=S,fy=S,interpolation=cv2.INTER_AREA)
    kp,des=sift.detectAndCompute(cv2.cvtColor(sm,cv2.COLOR_BGR2GRAY),None)
    pages.append((f,im,kp,des))
fl=cv2.FlannBasedMatcher(dict(algorithm=1,trees=5),dict(checks=50))
OUT='/home/claude/carte_it';os.makedirs(OUT,exist_ok=True)
res={}
for key,e in sorted(cards.items()):
    t=cv2.imread('/home/claude/tts_carte/'+e['img']); th,tw=t.shape[:2]
    sc=400/tw; ts=cv2.resize(t,None,fx=sc,fy=sc,interpolation=cv2.INTER_AREA)
    kt,dt=sift.detectAndCompute(cv2.cvtColor(ts,cv2.COLOR_BGR2GRAY),None)
    best=None
    for pi,(f,im,kp,des) in enumerate(pages):
        m=fl.knnMatch(dt,des,k=2)
        good=[a for a,b in m if a.distance<0.7*b.distance]
        if len(good)<12: continue
        src=np.float32([kt[g.queryIdx].pt for g in good]); dst=np.float32([kp[g.trainIdx].pt for g in good])
        H,mask=cv2.findHomography(src,dst,cv2.RANSAC,4.0)
        if H is None: continue
        n=int(mask.sum())
        if not best or n>best[0]: best=(n,pi,H)
    if not best: print(key,e['nick'],'NON TROVATA'); continue
    n,pi,H=best
    # da coordinate carta (dimensione ts) a pagina piena
    A=np.diag([1/S,1/S,1])@H@np.diag([sc,sc,1])
    W,Hh=int(tw*1.0),int(th*1.0)
    # uscita a 300dpi circa: altezza ~1050
    k=1050/th; Wo,Ho=int(tw*k),int(th*k)
    M=A@np.diag([1/k,1/k,1])
    out=cv2.warpPerspective(pages[pi][1],M,(Wo,Ho),flags=cv2.WARP_INVERSE_MAP|cv2.INTER_CUBIC) if False else cv2.warpPerspective(pages[pi][1],np.linalg.inv(M),(Wo,Ho),flags=cv2.INTER_CUBIC)
    nome=f"{DECKS[e['deck']]}_{e['deck']}_{e['i']:02d}"
    cv2.imwrite(f'{OUT}/{nome}.jpg',out,[cv2.IMWRITE_JPEG_QUALITY,90])
    res[nome]={'nick':e['nick'],'pagina':pi,'inlier':n}
    print(nome,e['nick'],pi,n)
json.dump(res,open('/home/claude/lavoro/carte_it.json','w'),indent=0)
