# Paints the owner's horse reference picture onto the untextured horse .glb as vertex colors.
# Usage: python3 bake_horse.py OUT.glb SOURCE.glb REFERENCE.png  (view boxes below match that picture)
import sys,json,struct; sys.path.insert(0,'.')
from glbio import *
from PIL import Image
import numpy as np
SRC=sys.argv[2] if len(sys.argv) > 2 else 'cavalo_sem_cor.glb'
IMG=sys.argv[3] if len(sys.argv) > 3 else 'cavalo_referencia.png'
OUT=sys.argv[1]
im=np.asarray(Image.open(IMG).convert('RGB')).astype(float)
bg=np.array([32,31,38]); mask=(np.abs(im-bg).sum(2)>45)
j,b=load(SRC)
p=j['meshes'][0]['primitives'][0]
P=acc(j,b,p['attributes']['POSITION']).astype(float); N=acc(j,b,p['attributes']['NORMAL']).astype(float)
mn=P.min(0); mx=P.max(0); rg=mx-mn
def samp(u,v):
    u=np.clip(u.astype(int),0,im.shape[1]-1); v=np.clip(v.astype(int),0,im.shape[0]-1)
    return im[v,u], mask[v,u]
x,y,z=P[:,0],P[:,1],P[:,2]
ty=lambda y0,y1: y0+(mx[1]-y)/rg[1]*(y1-y0)
side_c,side_ok=samp(862-(x-mn[0])/rg[0]*(862-370), ty(622,962))
front_c,front_ok=samp(107+(mx[2]-z)/rg[2]*125, ty(622,962))
back_c,back_ok=samp(969+(z-mn[2])/rg[2]*126, ty(622,966))
top_c,top_ok=samp(1286+(z-mn[2])/rg[2]*117, 621+(mx[0]-x)/rg[0]*360)
ws=np.abs(N[:,2])**3*side_ok+1e-4
wf=np.clip(N[:,0],0,1)**3*front_ok
wb=np.clip(-N[:,0],0,1)**3*back_ok
wt=np.clip(N[:,1],0,1)**3*top_ok
wd=np.clip(-N[:,1],0,1)**3*side_ok
W=ws+wf+wb+wt+wd
col=(side_c*(ws+wd)[:,None]+front_c*wf[:,None]+back_c*wb[:,None]+top_c*wt[:,None])/W[:,None]
# Vertices no view covered keep the coat color.
coat=np.array([128,60,40.]); bad=((side_ok|front_ok|back_ok|top_ok)==False)
col[bad]=coat
lin=(col/255.0)
C=np.concatenate([lin,np.ones((len(lin),1))],1).astype(np.float32)
# append accessor
pad=(4-len(b)%4)%4; b+=b'\0'*pad
off=len(b); b+=C.tobytes()
j['bufferViews'].append({'buffer':0,'byteOffset':off,'byteLength':C.nbytes,'target':34962})
j['accessors'].append({'bufferView':len(j['bufferViews'])-1,'componentType':5126,'count':len(C),'type':'VEC4'})
p['attributes']['COLOR_0']=len(j['accessors'])-1
j['materials']=[{'name':'cavalo','pbrMetallicRoughness':{'baseColorFactor':[1,1,1,1],'metallicFactor':0,'roughnessFactor':0.9}}]
p['material']=0
j['buffers'][0]['byteLength']=len(b)
js=json.dumps(j).encode(); js+=b' '*((4-len(js)%4)%4)
with open(OUT,'wb') as f:
    f.write(struct.pack('<III',0x46546C67,2,12+8+len(js)+8+len(b)))
    f.write(struct.pack('<II',len(js),0x4E4F534A)); f.write(js)
    f.write(struct.pack('<II',len(b),0x004E4942)); f.write(bytes(b))
print('ok',len(C),'uncovered',bad.sum())
# preview side raster
g=np.zeros((400,520,3),np.uint8)
order=np.argsort(z)  # draw far first (z small)
for i in order:
    u=int(10+(mx[0]-x[i])/rg[0]*500); v=int(10+(mx[1]-y[i])/rg[1]*380)
    g[v:v+2,u:u+2]=np.clip(col[i],0,255)
Image.fromarray(g).save('preview_side.png')
