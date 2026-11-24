extends RefCounted
## Rising strike from the linked hook, in facing-right local space.
const DURATION=44
const ACTIVE_FROM=10
const ACTIVE_TO=19
const LIFT=440.0
const DAMAGE=20
const KEYS=[
    [0,1.0,Vector2(4,-49),14.0,Vector2(24,12),Vector2(9,10)],
    [6,1.0,Vector2(0,-42),16.0,Vector2(17,25),Vector2(5,11)],
    [10,1.0,Vector2(8,-49),30.0,Vector2(40,7),Vector2(2,12)],
    [14,1.0,Vector2(10,-55),30.0,Vector2(38,-16),Vector2(3,14)],
    [19,1.0,Vector2(6,-55),19.0,Vector2(25,-33),Vector2(8,10)],
    [26,1.0,Vector2(2,-51),6.0,Vector2(16,-7),Vector2(8,9)],
    [44,0.0,Vector2(0,-50),0.0,Vector2(20,0),Vector2(7,10)]
]
static func pose(t:int)->Dictionary:
    var a:Array=KEYS[0]
    var b:Array=KEYS[1]
    for i in range(1,KEYS.size()):
        if t<=int(KEYS[i][0]):
            a=KEYS[i-1]
            b=KEYS[i]
            break
    var u:float=clampf(float(t-int(a[0]))/float(int(b[0])-int(a[0])),0,1)
    u=u*u*(3-2*u)
    return {"weight":lerpf(float(a[1]),float(b[1]),u),"hip":Vector2(a[2]).lerp(b[2],u),"lean":lerpf(float(a[3]),float(b[3]),u),"lead":Vector2(a[4]).lerp(b[4],u),"rear":Vector2(a[5]).lerp(b[5],u),"twist":-.6*sin(clampf(float(t)/26,0,1)*PI)}
