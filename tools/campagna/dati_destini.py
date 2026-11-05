import json,glob,re,cv2,numpy as np,pytesseract
from PIL import Image
idx=json.load(open('camp/indice.json'))
tr={}
for f in glob.glob('camp/trad/*.json'): tr.update(json.load(open(f)))
tts={}
for e in json.load(open('lavoro/carte_tts.json')): tts['%d_%02d'%(e['deck'],e['i'])]=e
SETS={'STEWARD':'siniscalco','FOUNDER':'fondatore','MAGNATE':'magnate','ADVOCATE':'patrocinatore','CARETAKER':'curatore','PARTISAN':'partigiano','ADMIRAL':'ammiraglio','BELIEVER':'credente','PATHFINDER':'esploratore','HEGEMON':'egemone','PLANET BREAKER':'distruttore','PIRATE':'pirata','BLIGHT SPEAKER':'voce','PACIFIST':'pacifista','PEACEKEEPER':'paciere','WARDEN':'castellano','OVERLORD':'signore','SURVIVALIST':'sopravvissuto','REDEEMER':'redentore','GUARDIAN':'guardiano','NATURALIST':'naturalista','GATE WRAITH':'spettro','CONSPIRATOR':'cospiratore','JUDGE':'giudice'}
SEME={'Material':'materiale','Fuel':'carburante','Weapon':'armi','Relic':'reliquie','Psionic':'psico'}
TIPI={'GUILD':'gilda','VOX':'vox','LORE':'lore','LAW':'legge','EDICT':'editto','SETUP':'preparazione','OBJECTIVE':'obiettivo','RESOLUTION':'risoluzione','ABILITY':'abilita','TITLE':'titolo','SUMMIT':'vertice','REMINDER':'promemoria','EVENT':'evento','POLICY':'politica','DOCTRINE':'dottrina','ECONOMY':'economia','MONOPOLY':'monopolio','UPGRADE':'miglioria','RULES':'regole'}
def tipo(f):
    im=Image.open('camp/en/'+f).convert('L'); w,h=im.size
    c=im.crop((int(w*.28),int(h*.935),int(w*.72),int(h*.99))); c=c.resize((c.width*3,c.height*3))
    a=np.array(c)
    for inv in (False,True):
        b=Image.fromarray(np.where(a>180,0,255).astype('uint8')) if inv else c
        t=pytesseract.image_to_string(b,config='--psm 7').upper()
        for k,v in TIPI.items():
            if k in t: return v
    return ''
def chiavi(f):
    im=cv2.imread('camp/en/'+f); h,w=im.shape[:2]
    r=im[int(h*.01):int(h*.11), int(w*.05):int(w*.22)]
    hsv=cv2.cvtColor(r,cv2.COLOR_BGR2HSV)
    if (hsv[:,:,2]<60).mean()>0.3: return -1
    m=((hsv[:,:,2]<80)).astype(np.uint8)
    n,lab,st,_=cv2.connectedComponentsWithStats(m)
    return len([s for s in st[1:] if s[4]>60])
def pulisci(t): return re.sub(r'[*_~]','',t).replace(' / ','\n')
def nome_e_testo(f):
    t=tr.get(f)
    if not t: return '',''
    g=[x for x in t.get('g',[]) if x]
    ex=[e['t'] for e in t.get('extra',[]) if e.get('t')]
    tit=t.get('titolo') or next((e['t'] for e in t.get('extra',[]) if e.get('titolo')),None)
    corpo=g+[e['t'] for e in t.get('extra',[]) if e.get('t') and not e.get('titolo')]
    if not tit and g and g[0].upper()==g[0] and len(g[0])<45:
        tit=g[0]; corpo=corpo[1:]
    return (pulisci(tit or '').strip(), '\n'.join(pulisci(x) for x in corpo))
out={}
pref={}
for k,v in idx.items():
    if v['set'] in SETS: pref.setdefault(k[:3],[]).append(k)
for p,ks in pref.items():
    n=len([k for k in ks if not k.startswith('993')])
    for k in ks:
        v=idx[k]; d=SETS[v['set']]
        if k.startswith('993'):
            j=int(k[4:]); num=31-j
        elif d=='credente': num=31-int(k[4:])
        else: num=n-int(k[4:])
        e=tts.get(k,{})
        f=v['fronte']
        nm,tx=nome_e_testo(f)
        rec={'destino':d,'num':num,'nome':nm,'testo':tx,'tipo':tipo(f) if not k.startswith('993_1') and not k.startswith('993_2') or k in('993_28','993_29') else 'azione',
             'seme':SEME.get(e.get('desc','').strip(),'')}
        if rec['tipo']=='gilda': rec['costo']=chiavi(f)
        if v.get('retro') and __import__('os').path.exists('camp/en/'+v['retro']):
            nr,trr=nome_e_testo(v['retro']); rec['retro_nome']=nr; rec['retro_testo']=trr; rec['retro_tipo']=tipo(v['retro'])
        out[k]=rec
# corte della campagna
for k in ['364_%02d'%i for i in range(13)]:
    e=tts.get(k,{}); nm,tx=nome_e_testo(k+'.jpg')
    rec={'destino':'','num':0,'nome':nm,'testo':tx,'tipo':tipo(k+'.jpg'),'seme':SEME.get(e.get('desc','').strip(),'')}
    if rec['tipo']=='gilda': rec['costo']=chiavi(k+'.jpg')
    out[k]=rec
json.dump(out,open('arcs/assets/dati/destini.json','w'),ensure_ascii=False,indent=0)
from collections import Counter
print(len(out),Counter(r['tipo'] for r in out.values()))
for k in sorted(out)[:3]+['364_08','463_23']: print(k,out[k])
