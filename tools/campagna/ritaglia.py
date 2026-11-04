import cv2,numpy as np,glob,os
out='/home/claude/carte_scan'; os.makedirs(out,exist_ok=True)
for f in glob.glob(out+'/*'): os.remove(f)
tot=0
import json
POS={}
for f in sorted(glob.glob('/home/claude/scan300/p-*.jpg')):
    pg=int(f[-7:-4]); im=cv2.imread(f)
    mn=cv2.GaussianBlur(im.min(2),(0,0),4); m=(mn<229).astype(np.uint8)*255
    m=cv2.morphologyEx(m,cv2.MORPH_CLOSE,np.ones((3,3),np.uint8))
    # riempi i buchi
    inv=255-m; n,lab,st,_=cv2.connectedComponentsWithStats(inv)
    for i in range(1,n):
        if st[i][4]<150000: m[lab==i]=255
    m=cv2.erode(m,np.ones((41,41),np.uint8))
    cs,_=cv2.findContours(m,cv2.RETR_EXTERNAL,cv2.CHAIN_APPROX_SIMPLE)
    k=0
    for c in sorted(cs,key=lambda c:(cv2.boundingRect(c)[1]//300,cv2.boundingRect(c)[0])):
        r=cv2.minAreaRect(c); (cx,cy),(rw,rh),a=r; r=((cx,cy),(rw+40,rh+40),a); (cx,cy),(rw,rh),a=r
        if rw*rh<250000: continue
        box=cv2.boxPoints(r)
        # ordina i vertici e raddrizza
        s=box.sum(1); dif=np.diff(box,axis=1).ravel()
        tl,br=box[np.argmin(s)],box[np.argmax(s)]; tr,bl=box[np.argmin(dif)],box[np.argmax(dif)]
        W=int(np.linalg.norm(tr-tl)); H=int(np.linalg.norm(bl-tl))
        M=cv2.getPerspectiveTransform(np.float32([tl,tr,br,bl]),np.float32([[0,0],[W,0],[W,H],[0,H]]))
        cr=cv2.warpPerspective(im,M,(W,H))
        cell=(990,495) if (H<600 or (W>H and H<1000 and W>1800)) else (770,1065)
        # le carte Leader: la parte bianca in basso si confonde col foglio
        if 690<H<720 and 750<W<800:
            M2=cv2.getPerspectiveTransform(np.float32([tl,tr,br,bl]),np.float32([[0,0],[W,0],[W,H],[0,H]]))
            cr=cv2.warpPerspective(im,M2,(W,1360),borderValue=(255,255,255))
        nx=max(1,round(cr.shape[1]/cell[0])); ny=max(1,round(cr.shape[0]/cell[1]))
        if cr.shape[0]>1300 and cr.shape[1]<800: nx,ny=1,1
        for yy in range(ny):
            for xx in range(nx):
                h0,w0=cr.shape[0]//ny,cr.shape[1]//nx
                sub=cr[yy*h0:(yy+1)*h0,xx*w0:(xx+1)*w0]
                cv2.imwrite(f'{out}/p{pg:02d}_{k:02d}.jpg',sub,[cv2.IMWRITE_JPEG_QUALITY,92])
                Mi=np.linalg.inv(M2 if (690<H<720 and 750<W<800) else M)@np.array([[1,0,xx*w0],[0,1,yy*h0],[0,0,1.0]])
                POS[f'p{pg:02d}_{k:02d}']=Mi.tolist(); k+=1;tot+=1
    print(pg,k,end='; ')
print('tot',tot)
json.dump(POS,open('/home/claude/lavoro/pos_crop.json','w'))
