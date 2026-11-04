import sys,json
from PIL import Image,ImageDraw
idx=json.load(open('/home/claude/lavoro/carte_tts.json'))
deck=int(sys.argv[1]); w=int(sys.argv[2]) if len(sys.argv)>2 else 200; cols=int(sys.argv[3]) if len(sys.argv)>3 else 8
seen={};
for e in idx:
    if e['deck']==deck and e['i'] not in seen: seen[e['i']]=e
es=[seen[k] for k in sorted(seen)]
ims=[Image.open('/home/claude/tts_carte/'+e['img']) for e in es]
h=int(ims[0].height*w/ims[0].width)
S=Image.new('RGB',(cols*w,((len(ims)+cols-1)//cols)*(h+14)),'black');dr=ImageDraw.Draw(S)
for k,(e,im) in enumerate(zip(es,ims)):
    x=(k%cols)*w;y=(k//cols)*(h+14)
    S.paste(im.resize((w,h)),(x,y)); dr.text((x+2,y+h),f"{e['i']} {e['nick']}"[:30],fill='white')
S.save(f'/tmp/foglio_{deck}.jpg',quality=85); print(len(es),S.size)
