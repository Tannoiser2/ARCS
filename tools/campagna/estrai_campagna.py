import sys,json,os,hashlib;sys.path.insert(0,'/home/claude/lavoro')
from tts import *
from PIL import Image
Image.MAX_IMAGE_PIXELS=None
OUT='/home/claude/camp/en'; os.makedirs(OUT,exist_ok=True)
SALTA_TOP={'Leaders','Lore','Setup Cards','4P Action Cards','Face Up Discard Deck'}
BASE_DECK={363,977,387,384,385,386,308,310,312,753}
cache={}
def cella(url,W,H,i):
    f=fn(url)
    if not f: return None
    if f not in cache:
        if len(cache)>8: cache.clear()
        cache[f]=Image.open(f).convert('RGB')
    im=cache[f]; cw,ch=im.width//W,im.height//H
    return im.crop(((i%W)*cw,(i//W)*ch,(i%W+1)*cw,(i//W+1)*ch))
idx={};hashes={}
for p,o in walk(d['ObjectStates']):
    if o['Name'] not in ('Card','CardCustom'): continue
    top=p.split('/')[1] if p else ''
    cid=o.get('CardID',0)
    for k,v in (o.get('CustomDeck') or {}).items():
        dk=int(k); i=cid%100 if cid else 0
        if dk in BASE_DECK or top in SALTA_TOP: continue
        if 982<=dk<=1116: continue
        key=f'{dk}_{i:02d}'
        if key in idx: continue
        W,H=v.get('NumWidth',1),v.get('NumHeight',1)
        fr=cella(v['FaceURL'],W,H,i)
        if fr is None: continue
        h=hashlib.md5(fr.tobytes()).hexdigest()
        rec={'nick':o.get('Nickname',''),'set':top or '(sciolte)','fronte':key+'.jpg','dup':hashes.get(h)}
        hashes.setdefault(h,key)
        if rec['dup'] is None: fr.save(f'{OUT}/{key}.jpg',quality=92)
        if v.get('UniqueBack'):
            bk=cella(v['BackURL'],W,H,i)
            if bk is not None:
                hb=hashlib.md5(bk.tobytes()).hexdigest()
                rec['retro']=key+'_r.jpg'; rec['dup_r']=hashes.get(hb)
                hashes.setdefault(hb,key+'_r')
                if rec['dup_r'] is None: bk.save(f'{OUT}/{key}_r.jpg',quality=92)
        idx[key]=rec
json.dump(idx,open('/home/claude/camp/indice.json','w'),indent=0,ensure_ascii=False)
import collections
c=collections.Counter(r['set'] for r in idx.values())
print(len(idx),'carte; immagini uniche',len(os.listdir(OUT)));print(c)
