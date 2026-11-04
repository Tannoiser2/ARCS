import sys,json;sys.path.insert(0,'/home/claude/lavoro')
import rendi_it as r
idx=json.load(open('/home/claude/camp/indice.json'))
sett=sys.argv[1]
fatti=set()
import glob
for t in glob.glob('/home/claude/camp/trad/*.json'): fatti|=set(json.load(open(t)))
for k,v in idx.items():
    if v['set']!=sett: continue
    for f in [v['fronte'] if not v['dup'] else None, v.get('retro') if v.get('retro') and not v.get('dup_r') else None]:
        if f and f in r.OCR and f not in fatti:
            d=r.descrivi(f)
            if not d: continue
            print('##',f); print('\n'.join(d))
