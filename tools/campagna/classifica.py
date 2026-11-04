import cv2,numpy as np,json,glob,os
from scipy.optimize import linear_sum_assignment
idx=json.load(open('/home/claude/lavoro/carte_tts.json'))
DECKS={363:'corte',977:'lore',387:'lore',384:'leader',308:'azione',310:'azione',312:'prep'}
cards={}
for e in idx:
    if e['deck'] in DECKS: cards[(e['deck'],e['i'])]=e
keys=sorted(cards)
sift=cv2.SIFT_create(1500)
def feat(im):
    g=cv2.cvtColor(im,cv2.COLOR_BGR2GRAY); k=500/max(g.shape); g=cv2.resize(g,None,fx=k,fy=k,interpolation=cv2.INTER_AREA)
    return sift.detectAndCompute(g,None)
T={k:feat(cv2.imread('/home/claude/tts_carte/'+cards[k]['img'])) for k in keys}
crops=sorted(glob.glob('/home/claude/carte_scan/*.jpg'))
bf=cv2.BFMatcher()
ROT=[None,cv2.ROTATE_90_CLOCKWISE,cv2.ROTATE_180,cv2.ROTATE_90_COUNTERCLOCKWISE]
score=np.zeros((len(crops),len(keys)));rotb=np.zeros((len(crops),len(keys)),int)
for ci,f in enumerate(crops):
    im=cv2.imread(f)
    for ri,r in enumerate(ROT):
        rim=im if r is None else cv2.rotate(im,r)
        kc,dc=feat(rim)
        if dc is None: continue
        for ki,k in enumerate(keys):
            kt,dt=T[k]
            if dt is None: continue
            m=bf.knnMatch(dt,dc,k=2)
            good=[a for a,b in (x for x in m if len(x)==2) if a.distance<0.75*b.distance]
            if len(good)<8: continue
            src=np.float32([kt[g.queryIdx].pt for g in good]);dst=np.float32([kc[g.trainIdx].pt for g in good])
            H,mask=cv2.estimateAffinePartial2D(src,dst,method=cv2.RANSAC,ransacReprojThreshold=6)
            if H is None: continue
            # scala e rotazione ~ identità
            s=np.hypot(H[0,0],H[1,0]); ang=abs(np.degrees(np.arctan2(H[1,0],H[0,0])))
            if ang>8 or not(0.7<s*max(cv2.imread('/home/claude/tts_carte/'+cards[k]['img']).shape[:2])/ max(rim.shape[:2])*1<1.4): pass
            n=int(mask.sum()) if ang<8 else 0
            if n>score[ci,ki]: score[ci,ki]=n; rotb[ci,ki]=ri
    print(os.path.basename(f), cards[keys[int(score[ci].argmax())]]['nick'], int(score[ci].max()),flush=True)
np.save('/home/claude/lavoro/score.npy',score); np.save('/home/claude/lavoro/rot.npy',rotb)
json.dump({'crops':crops,'keys':[list(k) for k in keys]},open('/home/claude/lavoro/score.json','w'))
