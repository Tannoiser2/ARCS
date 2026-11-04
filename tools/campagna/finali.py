import json,cv2,os,numpy as np
from PIL import Image
ass=json.load(open('lavoro/assegna.json'))
OUT='/home/claude/arcs/assets/carte'
AZ={}
for k,(s,v) in enumerate([(s,v) for s in ['cos','amm','agg','mob'] for v in range(2,7)]):
    AZ[(308,[1,2,3,4,5,8,9,10,11,12,15,16,17,18,19,22,23,24,25,26][k])]=f'{s}{v}'
for i,n in {0:'cos1',6:'cos7',7:'amm1',13:'amm7',14:'agg1',20:'agg7',21:'mob1',27:'mob7'}.items(): AZ[(310,i)]=n
LEAD=['antico','mistico','divoratore','arrivista','ribelle','guerriero','edonista','demagogo']
def nome(d,i):
    if d==363: return f'c{i+1:02d}'
    if d==977: return 'l01'
    if d==387: return f'l{i+1:02d}'
    if d==384: return LEAD[i]
    if d in(308,310): return AZ[(d,i)]
    if d==312: return f'prep_{i:02d}'
ROT=[None,cv2.ROTATE_90_CLOCKWISE,cv2.ROTATE_180,cv2.ROTATE_90_COUNTERCLOCKWISE]
WID={363:500,977:500,387:500,384:420,308:360,310:360,312:500}
sift=cv2.SIFT_create(4000)
for k,(f,sc,r) in ass.items():
    d,i=map(int,k.split('_'))
    im=cv2.imread(f)
    if ROT[r] is not None: im=cv2.rotate(im,ROT[r])
    t=cv2.imread('tts_carte/%d_%02d.jpg'%(d,i)); th,tw=t.shape[:2]
    W=WID[d]; H=int(round(W*th/tw))
    tr=cv2.resize(t,(W,H)); 
    k1,d1=sift.detectAndCompute(cv2.cvtColor(tr,cv2.COLOR_BGR2GRAY),None)
    k2,d2=sift.detectAndCompute(cv2.cvtColor(im,cv2.COLOR_BGR2GRAY),None)
    m=cv2.BFMatcher().knnMatch(d1,d2,k=2)
    good=[a for a,b in (x for x in m if len(x)==2) if a.distance<0.75*b.distance]
    src=np.float32([k1[g.queryIdx].pt for g in good]);dst=np.float32([k2[g.trainIdx].pt for g in good])
    A,mask=cv2.estimateAffinePartial2D(src,dst,method=cv2.RANSAC,ransacReprojThreshold=5)
    M=np.vstack([A,[0,0,1]])
    out=cv2.warpPerspective(im,np.linalg.inv(M),(W,H),flags=cv2.INTER_AREA,borderValue=(255,255,255))
    s=np.hypot(A[0,0],A[1,0])
    Image.fromarray(cv2.cvtColor(out,cv2.COLOR_BGR2RGB)).save(f'{OUT}/{nome(d,i)}.webp',quality=86,method=6)
    print(nome(d,i),int(mask.sum()),round(s,2),round(np.degrees(np.arctan2(A[1,0],A[0,0])),1))
