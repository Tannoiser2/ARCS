import sys,glob,os
from PIL import Image
pre=sys.argv[1]; w=int(sys.argv[2]) if len(sys.argv)>2 else 330; cols=int(sys.argv[3]) if len(sys.argv)>3 else 5
fs=sorted(glob.glob(f'/home/claude/camp/it/{pre}_*.jpg'))
if len(sys.argv)>4: fs=[f for f in fs if any(k in os.path.basename(f) for k in sys.argv[4].split(','))]
ims=[Image.open(f) for f in fs]
hs=[int(i.height*w/i.width) for i in ims]; H=max(hs)
S=Image.new('RGB',(cols*w,((len(ims)+cols-1)//cols)*H),'black')
for k,im in enumerate(ims): S.paste(im.resize((w,hs[k])),((k%cols)*w,(k//cols)*H))
S.save(f'/tmp/it_{pre}.jpg',quality=85); print(len(ims),S.size)
