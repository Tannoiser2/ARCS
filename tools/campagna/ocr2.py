import pytesseract,json,os
from PIL import Image
from concurrent.futures import ProcessPoolExecutor
def ocr(f):
    im=Image.open('/home/claude/camp/en/'+f).convert('RGB')
    S=2.0
    big=im.resize((int(im.width*S),int(im.height*S)),Image.LANCZOS)
    d=pytesseract.image_to_data(big,lang='eng',config='--psm 3',output_type=pytesseract.Output.DICT)
    righe={}
    for k in range(len(d['text'])):
        t=d['text'][k].strip()
        if not t: continue
        key=(d['block_num'][k],d['par_num'][k],d['line_num'][k])
        r=righe.setdefault(key,{'p':[]})
        r['p'].append([t,float(d['conf'][k])]+[int(d[z][k]/S) for z in ('left','top','width','height')])
    out=[]
    for key,r in sorted(righe.items()):
        ws=r['p']; buoni=[w for w in ws if w[1]>55 and any(c.isalpha() for c in w[0])]
        if not buoni: continue
        x0=min(w[2] for w in buoni);y0=min(w[3] for w in buoni);x1=max(w[2]+w[4] for w in buoni);y1=max(w[3]+w[5] for w in buoni)
        hs=sorted(w[5] for w in buoni)
        out.append({'w':[[w[0],round(w[1]),w[2],w[3],w[4],w[5]] for w in ws],'t':' '.join(w[0] for w in ws),'box':[x0,y0,x1,y1],'h':hs[len(hs)//2],'conf':sum(w[1] for w in buoni)/len(buoni),'blk':key[0],'par':key[1]})
    out.sort(key=lambda r:(r['box'][1],r['box'][0]))
    return f,{'w':im.width,'h':im.height,'righe':out}
if __name__=='__main__':
    files=sorted(os.listdir('/home/claude/camp/en'))
    res={}
    with ProcessPoolExecutor(4) as ex:
        for f,o in ex.map(ocr,files): res[f]=o
    json.dump(res,open('/home/claude/camp/ocr2.json','w'),ensure_ascii=False)
    print(len(res))
