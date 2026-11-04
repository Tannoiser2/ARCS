import pytesseract,json,os,sys
from PIL import Image,ImageOps
from concurrent.futures import ProcessPoolExecutor
idx=json.load(open('/home/claude/camp/indice.json'))
def ocr(f):
    im=Image.open('/home/claude/camp/en/'+f).convert('RGB')
    S=2.0
    big=im.resize((int(im.width*S),int(im.height*S)),Image.LANCZOS)
    d=pytesseract.image_to_data(big,lang='eng',config='--psm 3',output_type=pytesseract.Output.DICT)
    blocchi={}
    for k in range(len(d['text'])):
        t=d['text'][k].strip()
        if not t or float(d['conf'][k])<20: continue
        key=(d['block_num'][k],d['par_num'][k])
        b=blocchi.setdefault(key,{'parole':[],'box':[9e9,9e9,0,0],'righe':set(),'h':[]})
        x,y,w,h=[int(d[z][k]/S) for z in ('left','top','width','height')]
        b['parole'].append(t); b['righe'].add(d['line_num'][k]); b['h'].append(h)
        bb=b['box']; bb[0]=min(bb[0],x);bb[1]=min(bb[1],y);bb[2]=max(bb[2],x+w);bb[3]=max(bb[3],y+h)
    out=[]
    for key,b in sorted(blocchi.items()):
        out.append({'testo':' '.join(b['parole']),'box':b['box'],'righe':len(b['righe']),'h':sorted(b['h'])[len(b['h'])//2]})
    return f,{'w':im.width,'h':im.height,'blocchi':out}
files=[]
for k,r in idx.items():
    if not r['dup']: files.append(r['fronte'])
    if r.get('retro') and not r.get('dup_r'): files.append(r['retro'])
files=[f for f in files if os.path.exists('/home/claude/camp/en/'+f)]
res={}
with ProcessPoolExecutor(4) as ex:
    for f,o in ex.map(ocr,files): res[f]=o
json.dump(res,open('/home/claude/camp/ocr.json','w'),indent=0,ensure_ascii=False)
print(len(res))
