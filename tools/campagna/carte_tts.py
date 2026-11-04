import sys,json,os;sys.path.insert(0,'/home/claude/lavoro')
from tts import *
from PIL import Image
Image.MAX_IMAGE_PIXELS=None
OUT='/home/claude/tts_carte';os.makedirs(OUT,exist_ok=True)
cache={};idx=[]
seen=set()
for p,o in walk(d['ObjectStates']):
    if o['Name'] not in('Card','CardCustom'): continue
    cid=o.get('CardID'); 
    for k,v in (o.get('CustomDeck') or {}).items():
        dk=int(k); i=cid%100 if cid else 0
        key=(dk,i, o.get('Nickname'))
        f=fn(v['FaceURL'])
        if not f: continue
        name=f'{dk}_{i:02d}.jpg'
        if (dk,i) not in seen:
            seen.add((dk,i))
            if f not in cache: cache[f]=Image.open(f).convert('RGB')
            im=cache[f]; W,H=v.get('NumWidth',1),v.get('NumHeight',1)
            cw,ch=im.width//W,im.height//H
            c=im.crop(((i%W)*cw,(i//W)*ch,(i%W+1)*cw,(i//W+1)*ch))
            c.save(f'{OUT}/{name}',quality=90)
            b=fn(v['BackURL'])
            if b and v.get('UniqueBack'):
                pass
        idx.append({'deck':dk,'i':i,'img':name,'nick':o.get('Nickname'),'desc':o.get('Description'),'gm':o.get('GMNotes'),'path':p,'back':os.path.basename(fn(v['BackURL']) or '')})
        if len(cache)>6: cache.clear()
json.dump(idx,open('/home/claude/lavoro/carte_tts.json','w'),indent=0)
print(len(idx),len(seen))
