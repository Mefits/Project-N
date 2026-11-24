extends RefCounted
## Original aerial silhouettes. Local pelvis, lean, hands, ankle targets.
const APPROACH=32
const STRIKE=27
const SLAM=38
const CANCEL=15
const FIRST=[
    [0,1.0,Vector2(0,-49),15.0,Vector2(18,1),Vector2(7,8),Vector2(21,-20),Vector2(-20,-12)],
    [5,1.0,Vector2(-3,-48),-9.0,Vector2(10,3),Vector2(9,10),Vector2(16,-25),Vector2(-15,-8)],
    [9,1.0,Vector2(7,-49),23.0,Vector2(43,1),Vector2(5,10),Vector2(22,-22),Vector2(-24,-7)],
    [13,1.0,Vector2(8,-49),25.0,Vector2(44,3),Vector2(7,10),Vector2(23,-22),Vector2(-23,-7)],
    [18,1.0,Vector2(3,-48),11.0,Vector2(25,7),Vector2(9,10),Vector2(18,-25),Vector2(-16,-10)],
    [27,0.0,Vector2(0,-50),0.0,Vector2(20,0),Vector2(7,10),Vector2(24,-2),Vector2(-24,-2)]
]
const SECOND=[
    [0,1.0,Vector2(3,-48),12.0,Vector2(25,7),Vector2(9,10),Vector2(18,-25),Vector2(-16,-10)],
    [5,1.0,Vector2(-3,-46),-14.0,Vector2(12,6),Vector2(-12,5),Vector2(9,-27),Vector2(-23,-6)],
    [9,1.0,Vector2(7,-49),30.0,Vector2(7,10),Vector2(42,-8),Vector2(24,-15),Vector2(-19,-22)],
    [13,1.0,Vector2(8,-49),33.0,Vector2(8,11),Vector2(43,-9),Vector2(26,-12),Vector2(-18,-22)],
    [18,1.0,Vector2(2,-48),12.0,Vector2(11,8),Vector2(25,3),Vector2(18,-20),Vector2(-14,-18)],
    [27,0.0,Vector2(0,-50),0.0,Vector2(20,0),Vector2(7,10),Vector2(24,-2),Vector2(-24,-2)]
]
const DOWN=[
    [0,1.0,Vector2(1,-48),10.0,Vector2(14,2),Vector2(22,4),Vector2(18,-22),Vector2(-16,-18)],
    [5,1.0,Vector2(-2,-48),-13.0,Vector2(10,-32),Vector2(8,1),Vector2(10,-29),Vector2(-19,-15)],
    [10,1.0,Vector2(8,-47),35.0,Vector2(35,27),Vector2(3,13),Vector2(22,-22),Vector2(-22,-9)],
    [15,1.0,Vector2(9,-46),40.0,Vector2(25,36),Vector2(5,15),Vector2(17,-25),Vector2(-21,-8)],
    [22,1.0,Vector2(3,-49),20.0,Vector2(16,19),Vector2(6,12),Vector2(19,-14),Vector2(-17,-5)],
    [38,0.0,Vector2(0,-50),0.0,Vector2(20,0),Vector2(7,10),Vector2(24,-2),Vector2(-24,-2)]
]
static func pose(kind:String,t:int)->Dictionary:
    if kind=="air_approach":
        var u:float=smoothstep(0.0,8.0,float(t))
        return {"weight":.85,"hip":Vector2(0,-48),"lean":18.0,"lead":Vector2(25,-4),"rear":Vector2(3,12),"air_near":Vector2(18,-2).lerp(Vector2(24,-25),u),"air_far":Vector2(-24,-2).lerp(Vector2(-21,-12),u),"twist":.2}
    var keys:Array=FIRST if kind=="air_jab" else (SECOND if kind=="air_cross" else DOWN)
    var a:Array=keys[0]
    var b:Array=keys[1]
    for i in range(1,keys.size()):
        if t<=int(keys[i][0]):
            a=keys[i-1]
            b=keys[i]
            break
    var u:float=smoothstep(0.0,1.0,clampf(float(t-int(a[0]))/float(int(b[0])-int(a[0])),0,1))
    return {"weight":lerpf(float(a[1]),float(b[1]),u),"hip":Vector2(a[2]).lerp(b[2],u),"lean":lerpf(float(a[3]),float(b[3]),u),"lead":Vector2(a[4]).lerp(b[4],u),"rear":Vector2(a[5]).lerp(b[5],u),"air_near":Vector2(a[6]).lerp(b[6],u),"air_far":Vector2(a[7]).lerp(b[7],u),"twist":sin(clampf(float(t)/22,0,1)*PI)*(-.7 if kind=="air_jab" else .8)}
