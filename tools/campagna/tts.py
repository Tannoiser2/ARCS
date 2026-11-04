import json,re,os
D='/home/claude/src/Mods'
d=json.load(open(D+'/Workshop/3683918449.json'))
_idx=None
def fn(url):
    global _idx
    if not url: return None
    if _idx is None:
        _idx={}
        for sub in ('Images','Models','PDF'):
            for f in os.listdir(os.path.join(D,sub)): _idx[f.rsplit('.',1)[0]]=sub+'/'+f
    k=re.sub(r'[^A-Za-z0-9]','',url)
    if k in _idx: return D+'/'+_idx[k]
    for kk,v in _idx.items():
        if kk.endswith(k[-40:]): return D+'/'+v
    return None
def walk(objs,path=''):
    for o in objs:
        yield path,o
        for c in o.get('ContainedObjects') or []:
            yield from walk([c],path+'/'+(o.get('Nickname') or o['Name']))
        for k,v in (o.get('States') or {}).items():
            yield from walk([v],path+'/STATE'+k)
