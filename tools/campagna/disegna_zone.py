import json,glob,sys
from PIL import Image,ImageDraw
z=json.load(open('lavoro/zone.json'))
im=Image.open(glob.glob('src/Mods/Images/*9AA198FE535536C3A5D9593C0A92D797276C.jpg')[0]).convert('RGB')
W,H=im.size
k=float(sys.argv[1]); cx=float(sys.argv[2]); cy=float(sys.argv[3])
dr=ImageDraw.Draw(im)
for name,pts in z.items():
    for (x,y) in pts:
        px=cx+(x-2.81)*k; py=cy-(y+0.637)*k
        r=30 if '_b' not in name else 18
        dr.ellipse((px-r,py-r,px+r,py+r),outline=(0,255,0) if '_b' not in name else (255,0,0),width=10)
        if '_b' not in name: dr.text((px+35,py-20),name,fill=(0,255,0),font_size=60)
im.resize((1400,748)).save('/tmp/mapz.jpg')
