"""Deterministic BVH forward kinematics; source CMU 09_01, Hahne conversion.
No external packages. Usage: python lab/mocap/import_bvh.py input.bvh output.json
"""
import sys,re,json,math,hashlib
def mul(a,b):
    return [sum(a[3*(i//3)+k]*b[3*k+i%3] for k in range(3)) for i in range(9)]
def mv(a,b):
    return [sum(a[3*i+k]*b[k] for k in range(3)) for i in range(3)]
def add(a,b): return [x+y for x,y in zip(a,b)]
def rot(axis,v):
    c,s=math.cos(math.radians(v)),math.sin(math.radians(v))
    return {"X":[1,0,0,0,c,-s,0,s,c],"Y":[c,0,s,0,1,0,-s,0,c],"Z":[c,-s,0,s,c,0,0,0,1]}[axis]
def parse(text):
    h,m=text.split("MOTION",1)
    tokens=iter(re.findall(r'[{}]|[^\s{}]+',h))
    assert next(tokens)=="HIERARCHY"
    nodes=[]; channels=0
    def node(kind,parent):
        nonlocal channels
        name=next(tokens)
        if kind=="End": name=nodes[parent]["name"]+"_end"
        assert next(tokens)=="{"
        index=len(nodes)
        n={"name":name,"parent":parent,"offset":[],"channels":[],"start":channels}
        nodes.append(n)
        for t in tokens:
            if t=="}": break
            if t=="OFFSET": n["offset"]=[float(next(tokens)) for _ in range(3)]
            elif t=="CHANNELS":
                n["channels"]=[next(tokens) for _ in range(int(next(tokens)))]
                n["start"]=channels; channels+=len(n["channels"])
            else: node(t,index)
    node(next(tokens),-1)
    lines=m.strip().splitlines()
    count=int(lines[0].split(":")[1]); dt=float(lines[1].split(":")[1])
    rows=[[float(v) for v in line.split()] for line in lines[2:] if line.strip()]
    assert len(rows)==count and all(len(r)==channels for r in rows)
    def fk(row):
        P=[]; R=[]; out={}
        for n in nodes:
            t=n["offset"].copy(); q=[1,0,0,0,1,0,0,0,1]
            for j,c in enumerate(n["channels"]):
                v=row[n["start"]+j]
                if c.endswith("position"): t["XYZ".index(c[0])]+=v
                else: q=mul(q,rot(c[0],v))
            p=n["parent"]
            P.append(t if p<0 else add(P[p],mv(R[p],t)))
            R.append(q if p<0 else mul(R[p],q))
            out[n["name"]]=P[-1]
        return out
    return dt,[fk(row) for row in rows]
def convert(text):
    dt,frames=parse(text)
    first,last=1,90
    keys=["Hips","Spine1","Head","LeftArm","LeftForeArm","LeftHand","RightArm","RightForeArm","RightHand","LeftUpLeg","LeftLeg","LeftFoot","LeftToeBase","RightUpLeg","RightLeg","RightFoot","RightToeBase"]
    f=frames[first:last+1]
    # +Z is forward, +Y is up. Ground level estimated from lowest toe
    # in this excerpt, not a measured ground-force contact.
    floor=min(x[k][1] for x in f for k in ["LeftToeBase","RightToeBase"])
    scale=60.0/(math.dist(f[0]["LeftUpLeg"],f[0]["LeftLeg"])+math.dist(f[0]["LeftLeg"],f[0]["LeftFoot"]))
    data=[]
    for p in f:
        root=p["Hips"]
        data.append({k:[round((p[k][2]-root[2])*scale,5),round(-(p[k][1]-floor)*scale,5)] for k in keys})
    return {"source":"CMU 09_01 / Bruce Hahne BVH conversion","blob":"3b3a6e279754eaa9b885df60e3d184474d7bc301","frame_time":dt,"source_count":len(frames),"first":first,"last":last,"scale":scale,"source_root_travel":f[-1]["Hips"][2]-f[0]["Hips"][2],"floor":floor,"frames":data}
if __name__=="__main__":
    with open(sys.argv[1],encoding="utf-8") as f: d=convert(f.read())
    with open(sys.argv[2],"w",encoding="utf-8") as f: json.dump(d,f,separators=(",",":"))
