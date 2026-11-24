extends RefCounted
## Authored visual key poses. Coordinates are in facing-right root space.
## tick, pelvis, chest offset, head offset, shoulder width,
## near elbow/wrist (from shoulder), far elbow/wrist, lead ankle (kick only).
## All timings are proposed N timing, not measured anime footage.
const JAB=[
 [0,Vector2(0,-51),Vector2(3,-34),Vector2(8,-21),5.0,Vector2(10,13),Vector2(24,0),Vector2(-7,16),Vector2(9,10)],
 [3,Vector2(-6,-47),Vector2(-9,-32),Vector2(7,-21),7.0,Vector2(-5,18),Vector2(7,1),Vector2(-10,15),Vector2(13,0)],
 [6,Vector2(4,-48),Vector2(7,-33),Vector2(1,-22),6.0,Vector2(3,15),Vector2(14,0),Vector2(-10,14),Vector2(8,-5)],
 [8,Vector2(9,-51),Vector2(19,-31),Vector2(1,-22),3.0,Vector2(20,1),Vector2(45,-3),Vector2(-13,12),Vector2(6,-3)],
 [9,Vector2(10,-52),Vector2(23,-30),Vector2(0,-22),3.0,Vector2(20,0),Vector2(45,-2),Vector2(-14,13),Vector2(7,-6)],
 [13,Vector2(9,-51),Vector2(21,-31),Vector2(7,-21),4.0,Vector2(23,1),Vector2(47,-1),Vector2(-9,17),Vector2(11,6)],
 [18,Vector2(3,-49),Vector2(9,-33),Vector2(7,-21),6.0,Vector2(12,13),Vector2(28,1),Vector2(-8,15),Vector2(11,8)]
]
const CROSS=[
 [0,Vector2(3,-49),Vector2(10,-33),Vector2(7,-21),6.0,Vector2(12,12),Vector2(30,0),Vector2(-6,16),Vector2(10,8)],
 [4,Vector2(-8,-46),Vector2(-13,-31),Vector2(9,-22),10.0,Vector2(10,15),Vector2(27,-2),Vector2(-24,8),Vector2(-14,-9)],
 [7,Vector2(2,-47),Vector2(6,-34),Vector2(-1,-23),9.0,Vector2(-4,19),Vector2(10,7),Vector2(-14,8),Vector2(0,-8)],
 [9,Vector2(8,-50),Vector2(20,-30),Vector2(2,-23),2.0,Vector2(-12,17),Vector2(8,4),Vector2(19,3),Vector2(46,-1)],
 [11,Vector2(11,-51),Vector2(25,-28),Vector2(4,-22),2.0,Vector2(-13,17),Vector2(5,2),Vector2(22,0),Vector2(48,-2)],
 [16,Vector2(6,-48),Vector2(16,-31),Vector2(7,-22),6.0,Vector2(-4,19),Vector2(10,6),Vector2(14,12),Vector2(31,4)]
]
const HOOK=[
 [0,Vector2(4,-48),Vector2(15,-32),Vector2(7,-22),5.0,Vector2(0,18),Vector2(13,4),Vector2(16,9),Vector2(32,3)],
 [4,Vector2(-7,-43),Vector2(-15,-31),Vector2(9,-22),10.0,Vector2(-22,-6),Vector2(-15,-22),Vector2(11,15),Vector2(23,-2)],
 [7,Vector2(4,-46),Vector2(5,-34),Vector2(1,-22),10.0,Vector2(-7,-14),Vector2(13,-22),Vector2(-9,17),Vector2(10,10)],
 [10,Vector2(10,-47),Vector2(23,-30),Vector2(-1,-22),7.0,Vector2(23,-13),Vector2(38,6),Vector2(-13,13),Vector2(8,-3)],
 [14,Vector2(8,-46),Vector2(24,-28),Vector2(5,-22),3.0,Vector2(24,6),Vector2(39,15),Vector2(-12,15),Vector2(7,6)],
 [18,Vector2(1,-49),Vector2(9,-33),Vector2(7,-21),6.0,Vector2(12,18),Vector2(22,12),Vector2(-6,17),Vector2(10,9)],
 [31,Vector2(0,-51),Vector2(3,-34),Vector2(7,-21),5.0,Vector2(10,13),Vector2(24,0),Vector2(-7,16),Vector2(9,10)]
]
const KICK=[
 [0,Vector2(0,-50),Vector2(3,-34),Vector2(7,-21),5.0,Vector2(9,15),Vector2(23,1),Vector2(-7,17),Vector2(9,8),Vector2(24,-2)],
 [6,Vector2(-7,-46),Vector2(-6,-33),Vector2(8,-21),7.0,Vector2(7,18),Vector2(23,3),Vector2(-13,15),Vector2(7,9),Vector2(14,-16)],
 [12,Vector2(-10,-53),Vector2(-17,-30),Vector2(8,-22),7.0,Vector2(-3,20),Vector2(14,10),Vector2(-18,12),Vector2(-7,4),Vector2(12,-48)],
 [17,Vector2(-5,-56),Vector2(-24,-27),Vector2(10,-21),4.0,Vector2(-12,19),Vector2(5,9),Vector2(-21,7),Vector2(-10,-9),Vector2(61,-56)],
 [22,Vector2(-4,-56),Vector2(-22,-27),Vector2(10,-21),4.0,Vector2(-10,18),Vector2(6,7),Vector2(-20,9),Vector2(-9,-5),Vector2(65,-59)],
 [29,Vector2(-7,-51),Vector2(-15,-31),Vector2(8,-22),6.0,Vector2(4,18),Vector2(20,8),Vector2(-11,17),Vector2(4,7),Vector2(18,-45)],
 [41,Vector2(-3,-48),Vector2(-4,-34),Vector2(7,-21),6.0,Vector2(8,16),Vector2(22,2),Vector2(-8,16),Vector2(9,9),Vector2(24,-9)],
 [55,Vector2(0,-51),Vector2(3,-34),Vector2(7,-21),5.0,Vector2(10,13),Vector2(24,0),Vector2(-7,16),Vector2(9,10),Vector2(24,-2)]
]
static func keys(kind:String)->Array:
    match kind:
        "jab":return JAB
        "cross":return CROSS
        "hook":return HOOK
        _:return KICK
static func sample(kind:String,age:int)->Array:
    var k:Array=keys(kind)
    # Deliberately hold drawings on twos, except delivery, which is on ones.
    var t:int=age if (age>=6 and age<=11) or (kind=="finisher" and age>=13 and age<=23) else age-age%2
    if t>=int(k[-1][0]):return k[-1]
    for i in range(1,k.size()):
        if t<=int(k[i][0]):
            var a:Array=k[i-1]
            var b:Array=k[i]
            var u:float=clampf(float(t-int(a[0]))/float(int(b[0])-int(a[0])),0,1)
            var out:Array=[t]
            for n in range(1,a.size()):
                if a[n] is Vector2:out.append(Vector2(a[n]).lerp(b[n],u))
                else:out.append(lerpf(float(a[n]),float(b[n]),u))
            return out
    return k[-1]
