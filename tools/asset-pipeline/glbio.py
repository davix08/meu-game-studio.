import json,struct,numpy as np
CT={5126:np.float32,5125:np.uint32,5123:np.uint16,5121:np.uint8}
NC={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}
def load(f):
    b=open(f,'rb').read()
    l=struct.unpack('<I',b[12:16])[0]
    j=json.loads(b[20:20+l])
    off=20+l; bl=struct.unpack('<I',b[off:off+4])[0]; binb=b[off+8:off+8+bl]
    return j,bytearray(binb)
def acc(j,binb,i):
    a=j['accessors'][i]; bv=j['bufferViews'][a['bufferView']]
    o=bv.get('byteOffset',0)+a.get('byteOffset',0)
    n=a['count']*NC[a['type']]
    arr=np.frombuffer(binb,dtype=CT[a['componentType']],count=n,offset=o)
    return arr.reshape(a['count'],NC[a['type']]) if NC[a['type']]>1 else arr
