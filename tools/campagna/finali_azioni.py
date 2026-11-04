import json,cv2,os,numpy as np
from PIL import Image
ass=json.load(open('lavoro/assegna.json')); POS=json.load(open('lavoro/pos_crop.json'))
OUT='/home/claude/arcs/assets/carte'
AZ={}
for k,(s,v) in enumerate([(s,v) for s in ['cos','amm','agg','mob'] for v in range(2,7)]):
    AZ[(308,[1,2,3,4,5,8,9,10,11,12,15,16,17,18,19,22,23,24,25,26][k])]=f'{s}{v}'
for i,n in {0:'cos1',6:'cos7',7:'amm1',13:'amm7',14:'agg1',20:'agg7',21:'mob1',27:'mob7'}.items(): AZ[(310,i)]=n
ROT=[None,cv2.ROTATE_90_CLOCKWISE,cv2.ROTATE_180,cv2.ROTATE_90_COUNTERCLOCKWISE]
sift=cv2.SIFT_create(6000)
pages={}
os.makedirs('/tmp/az',exist_ok=True)
for k,(f,sc,r) in ass.items():
    d,i=map(int,k.split('_'))
    if d not in (308,310): continue
    nm=os.path.basename(f)[:-4]; pg=int(nm[1:3])
    if pg not in pages: pages[pg]=cv2.imread('/home/claude/scan300/p-%03d.jpg'%pg)
    crop=cv2.imread(f)
    t=cv2.imread('tts_carte/%d_%02d.jpg'%(d,i)); th,tw=t.shape[:2]
    W=360;H=int(round(W*th/tw)); tr=cv2.resize(t,(W,H))
    k1,d1=sift.detectAndCompute(cv2.cvtColor(tr,cv2.COLOR_BGR2GRAY),None)
    k2,d2=sift.detectAndCompute(cv2.cvtColor(cv2.resize(crop,None,fx=0.5,fy=0.5),cv2.COLOR_BGR2GRAY),None)
    m=cv2.BFMatcher().knnMatch(d1,d2,k=2)
    good=[a for a,b in (x for x in m if len(x)==2) if a.distance<0.75*b.distance]
    src=np.float32([k1[g.queryIdx].pt for g in good]);dst=np.float32([k2[g.trainIdx].pt for g in good])*2
    A,mask=cv2.estimateAffinePartial2D(src,dst,method=cv2.RANSAC,ransacReprojThreshold=6)
    M=np.array(POS[nm])@np.vstack([A,[0,0,1]])
    out=cv2.warpPerspective(pages[pg],np.linalg.inv(M),(W,H),flags=cv2.INTER_AREA,borderValue=(255,255,255))
    cv2.imwrite(f'/tmp/az/{nm}.png',out)
    print(nm,int(mask.sum()),end='; ')
