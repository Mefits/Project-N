extends RefCounted
## First linked hand string: lead straight -> rear straight -> short lead hook.
## Original authored local poses, distinct attack paths; no sprite copying.
const DURATION=32
const ACTIVE_FROM=9
const ACTIVE_TO=15
const CANCEL_FROM=17
const CROSS=[
    [0,1.0,Vector2(3,-50),6.0,Vector2(26,1),Vector2(6,10)],
    [4,1.0,Vector2(-2,-49),-8.0,Vector2(16,4),Vector2(-10,9)],
    [9,1.0,Vector2(7,-51),23.0,Vector2(8,9),Vector2(43,-2)],
    [12,1.0,Vector2(9,-51),29.0,Vector2(6,10),Vector2(44,0)],
    [16,1.0,Vector2(5,-50),18.0,Vector2(11,7),Vector2(34,3)],
    [23,1.0,Vector2(0,-50),3.0,Vector2(20,0),Vector2(10,11)],
    [32,0.0,Vector2(0,-50),0.0,Vector2(20,0),Vector2(7,10)]
]
const HOOK=[
    [0,1.0,Vector2(3,-50),12.0,Vector2(15,7),Vector2(30,4)],
    [4,1.0,Vector2(-3,-48),-12.0,Vector2(-9,-3),Vector2(13,9)],
    [9,1.0,Vector2(6,-49),20.0,Vector2(34,2),Vector2(6,13)],
    [12,1.0,Vector2(9,-48),27.0,Vector2(39,10),Vector2(5,14)],
    [16,1.0,Vector2(7,-49),18.0,Vector2(29,12),Vector2(9,9)],
    [23,1.0,Vector2(1,-50),4.0,Vector2(18,3),Vector2(8,10)],
    [32,0.0,Vector2(0,-50),0.0,Vector2(20,0),Vector2(7,10)]
]
static func pose(kind:String,t:int)->Dictionary:
    var keys:Array=CROSS if kind=="cross" else HOOK
    var a:Array=keys[0]
    var b:Array=keys[1]
    for i in range(1,keys.size()):
        if t<=int(keys[i][0]):
            a=keys[i-1]
            b=keys[i]
            break
    var u:float=clampf(float(t-int(a[0]))/float(int(b[0])-int(a[0])),0,1)
    u=u*u*(3-2*u)
    return {"weight":lerpf(float(a[1]),float(b[1]),u),"hip":Vector2(a[2]).lerp(b[2],u),"lean":lerpf(float(a[3]),float(b[3]),u),"lead":Vector2(a[4]).lerp(b[4],u),"rear":Vector2(a[5]).lerp(b[5],u)}
