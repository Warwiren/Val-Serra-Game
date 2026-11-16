# V09B.5 — mesure du recul du pied d appui entre deux images (cycles candidats d Aren, profil droit).
# Usage : python3 tools/p49/foulee_v09b5.py <dossier ValSerra_V09B5_Aren_Marche_Course_Revue/>
import sys, json
from PIL import Image
P=sys.argv[1]
def mask(fn):
    im=Image.open(fn).convert('RGBA'); a=im.getchannel('A').load(); W,H=im.size
    return a,W,H
out={}
for kind in ['walk','run']:
  for sz in ['96x112','64x72']:
    suf='.png' if sz=='96x112' else '_PREVIEW.png'
    ms=[mask(P+f'frames_{kind}_{sz}/{kind}_right_{i:02d}{suf}') for i in range(8)]
    W,H=ms[0][1],ms[0][2]
    ground=max(y for y in range(H) for x in range(W) if ms[0][0][x,y]>127)
    band=6 if sz=='96x112' else 4
    rows=range(ground-band+1,ground+1)
    res=[]
    for i in range(8):
        a,_,_=ms[i]; b,_,_=ms[(i+1)%8]
        A={(x,y) for x in range(W) for y in rows if a[x,y]>127}
        B={(x,y) for x in range(W) for y in rows if b[x,y]>127}
        best=None
        for dx in range(-40,12):
            sh={(x+dx,y) for (x,y) in A}
            inter=len(sh&B)
            if best is None or inter>best[1]: best=(dx,inter)
        res.append({'de':i,'a':(i+1)%8,'dx':best[0],'recouvrement_px':best[1],'px_sol_i':len(A)})
    out[f'{kind}_{sz}']={'ligne_sol':ground,'paires':res}
print(json.dumps(out,indent=1))
