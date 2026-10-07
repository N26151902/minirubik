import itertools,random
src=[[1,4,2,0,3,5,6],[0,1,2,4,5,6,3],[0,2,5,3,1,4,6]]
tw=[[1,2,0,2,1,0,0],[0,0,0,1,2,1,2],[0,0,0,0,0,0,0]]
def quarter(p,o,f):
    return [p[src[f][d]] for d in range(7)],[(o[src[f][d]]+tw[f][d])%3 for d in range(7)]
# README geometry: x right, y up, z front. README positions 0..7; internal index i <-> README pos i+1; README pos0 fixed.
POS=[(-1,1,1),(1,1,1),(1,-1,1),(-1,-1,1),(1,1,-1),(1,-1,-1),(-1,-1,-1),(-1,1,-1)]
# renderer indexing: r=0..6 -> README pos r+1 ; r=7 -> README pos 0
RPOS=[POS[r+1] for r in range(7)]+[POS[0]]
FACEN={'U':(0,1,0),'D':(0,-1,0),'R':(1,0,0),'L':(-1,0,0),'F':(0,0,1),'B':(0,0,-1)}
def normals(c):  # three outward normals of corner at coord c
    return [(c[0],0,0),(0,c[1],0),(0,0,c[2])]
def cross(a,b): return (a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0])
def dot(a,b): return sum(x*y for x,y in zip(a,b))
def ordered(c,cw):
    # start with y-axis (U/D) normal, then cyclic order around corner
    ny=(0,c[1],0); nx=(c[0],0,0); nz=(0,0,c[2])
    # orientation of (ny,nx,nz) relative to corner direction
    s=dot(cross(ny,nx),nz)*1  # sign
    seq=[ny,nx,nz] if (s>0)==cw else [ny,nz,nx]
    return seq
def rot(v,axis,sgn):
    x,y,z=v
    if axis==0: return (x, -sgn*z, sgn*y)
    if axis==1: return (sgn*z, y, -sgn*x)
    return (-sgn*y, sgn*x, z)
TURN=[(0,1),(2,-1),(1,-1)]  # R: x=+1, B: z=-1, D: y=-1  (axis, layer)
def phys_solved():
    return {(c,n):n for c in RPOS for n in normals(c)}  # sticker color = home normal
def phys_turn(st,f,sgn):
    axis,layer=TURN[f]; new={}
    for (c,n),col in st.items():
        if c[axis]==layer: new[(rot(c,axis,sgn),rot(n,axis,sgn))]=col
        else: new[(c,n)]=col
    return new
def to_po(st,cw,tsign):
    p=[0]*7;o=[0]*7
    for r in range(7):
        c=RPOS[r]; seq=ordered(c,cw)
        cols=[st[(c,n)] for n in seq]
        # identify cubie by its color set = set of home normals
        home=None
        for h in range(8):
            if set(normals(RPOS[h]))==set(cols): home=h
        p[r]=home
        k=[i for i,col in enumerate(cols) if col[1]!=0][0]  # where U/D sticker sits
        o[r]=(tsign*k)%3
    return p,o
sol=None
for cw in (True,False):
  for tsign in (1,-1):
    for sg in itertools.product((1,-1),repeat=3):
      ok=True
      for f in range(3):
        st=phys_turn(phys_solved(),f,sg[f]); p,o=to_po(st,cw,tsign)
        if (p,o)!=quarter(list(range(7)),[0]*7,f): ok=False;break
      if ok:
        # random sequence check
        random.seed(0); st=phys_solved(); P,O=list(range(7)),[0]*7
        for _ in range(300):
            f=random.randrange(3); st=phys_turn(st,f,sg[f]); P,O=quarter(P,O,f)
            if to_po(st,cw,tsign)!=(P,O): ok=False;break
      if ok: sol=(cw,tsign,sg); print("MATCH",sol)

cw,tsign,sg=True,1,(-1,1,1)
FI={(0,1,0):0,(1,0,0):1,(0,0,1):2,(0,-1,0):3,(-1,0,0):4,(0,0,-1):5}
corner_faces=[[FI[n] for n in ordered(RPOS[r],cw)] for r in range(8)]
NET={0:[(-1,1,-1),(1,1,-1),(-1,1,1),(1,1,1)],   # U
     2:[(-1,1,1),(1,1,1),(-1,-1,1),(1,-1,1)],   # F
     3:[(-1,-1,1),(1,-1,1),(-1,-1,-1),(1,-1,-1)], # D
     4:[(-1,1,-1),(-1,1,1),(-1,-1,-1),(-1,-1,1)], # L
     1:[(1,1,1),(1,1,-1),(1,-1,1),(1,-1,-1)],   # R
     5:[(1,1,-1),(-1,1,-1),(1,-1,-1),(-1,-1,-1)]} # B
face_corner=[[RPOS.index(c) for c in NET[f]] for f in range(6)]
print("corner_faces",corner_faces); print("face_corner",face_corner)
def color(p,o,pos,face):
    c,ori=(7,0) if pos==7 else (p[pos],o[pos])
    fs=corner_faces[pos]; k=(fs.index(face)+3-ori)%3; return corner_faces[c][k]
def render(p,o): return [[color(p,o,face_corner[f][q],f) for q in range(4)] for f in range(6)]
def phys_render(st):
    return [[FI[st[(NET[f][q],[n for n in FACEN.values() if n==tuple(x for x in [ (1 if f==1 else -1 if f==4 else 0),(1 if f==0 else -1 if f==3 else 0),(1 if f==2 else -1 if f==5 else 0)])][0])]] for q in range(4)] for f in range(6)]
random.seed(5); bad=0
for trial in range(200):
    st=phys_solved(); P,O=list(range(7)),[0]*7
    for _ in range(random.randrange(1,25)):
        f=random.randrange(3); st=phys_turn(st,f,sg[f]); P,O=quarter(P,O,f)
    if render(P,O)!=phys_render(st): bad+=1
print("render vs physical mismatches:",bad)
names="WRGYOB"; s0=render(list(range(7)),[0]*7)
for f in range(3):
    r=render(*quarter(list(range(7)),[0]*7,f)); ch=[(F,q) for F in range(6) for q in range(4) if r[F][q]!=s0[F][q]]
    print("move",f,"changed",len(ch),ch,[''.join(names[c] for c in rr) for rr in r])
# emit .S tables
print(".byte "+", ".join(",".join(map(str,x)) for x in corner_faces))
print(".byte "+", ".join(",".join(map(str,x)) for x in face_corner))

# expected framebuffers for a C test
RGB=[0xffffff,0xff0000,0x00ff00,0xffff00,0xff8000,0x0000ff]
FX=[9,18,9,9,0,27]; FY=[0,7,7,14,7,7]
def fb(p,o):
    b=[0]*875; r=render(p,o)
    for f in range(6):
        for q in range(4):
            x=FX[f]+4*(q&1); y=FY[f]+3*(q>>1)
            for dy in range(3):
                for dx in range(4): b[(y+dy)*35+x+dx]=RGB[r[f][q]]
    return b
random.seed(9); states=[(list(range(7)),[0]*7)]
for f in range(3): states.append(quarter(list(range(7)),[0]*7,f))
for _ in range(16):
    P,O=list(range(7)),[0]*7
    for _ in range(random.randrange(2,20)): P,O=quarter(P,O,random.randrange(3))
    states.append((P,O))
with open('/home/claude/led/fast/expect.h','w') as fh:
    fh.write(f"#define NS {len(states)}\nstatic const unsigned char P[NS][7]={{"+",".join("{"+",".join(map(str,s[0]))+"}" for s in states)+"};\n")
    fh.write("static const unsigned char O[NS][7]={"+",".join("{"+",".join(map(str,s[1]))+"}" for s in states)+"};\n")
    fh.write("static const unsigned int FB[NS][875]={"+",".join("{"+",".join(hex(v) for v in fb(*s))+"}" for s in states)+"};\n")
