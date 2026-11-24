extends RefCounted
const REC=preload("res://lab/recording.gd")
const R=preload("res://game/rig.gd")
const POSE=preload("res://lab/anime/key_poses.gd")
var record=REC.new()
var authored:Array[Dictionary]=[]
var hybrid:Array[Dictionary]=[]
var contacts:Array[int]=[]
func _init()->void:
    record.record("ground")
    for i in range(record.frames.size()):
        if record.frames[i].contact_event:contacts.append(i)
    for i in range(record.frames.size()):
        var f:Dictionary=record.frames[i]
        if f.frozen and i>0:
            authored.append(authored[-1].duplicate(true))
            hybrid.append(hybrid[-1].duplicate(true))
            continue
        var a:Dictionary=_attacker(i)
        var b:Dictionary=_victim(i)
        authored.append({"a":a,"b":b})
        hybrid.append({"a":_secondary(a,f.a,true,i),"b":_secondary(b,f.b,false,i)})
func _world(local:Vector2,f:Dictionary)->Vector2:
    return Vector2(f.pos)+Vector2(local.x*float(f.face),local.y)
func _local(p:Vector2,f:Dictionary)->Vector2:
    var d:Vector2=p-Vector2(f.pos)
    return Vector2(d.x*float(f.face),d.y)
func _blend(a:Dictionary,b:Dictionary,u:float)->Dictionary:
    var p:Dictionary={}
    for k in a:p[k]=Vector2(a[k]).lerp(b[k],u)
    return p
func _legs(p:Dictionary,f:Dictionary,hip:Vector2,kick:Variant=null)->void:
    for j in range(2):
        var s:String="near" if j==0 else "far"
        var thigh:Vector2=hip+Vector2(3 if j==0 else -3,0)
        var foot:Vector2=_local(f.points["foot_"+s],f)
        if j==0 and kick is Vector2:foot=kick
        var leg:Array[Vector2]=R.chain(thigh,foot,30,30,-1)
        p["thigh_"+s]=_world(thigh,f)
        p["knee_"+s]=_world(leg[0],f)
        # Visual stretch/shortening is allowed. Never move the actual contact rig.
        p["foot_"+s]=_world(foot,f)
func _attacker(i:int)->Dictionary:
    var frame:Dictionary=record.frames[i]
    var f:Dictionary=frame.a
    if f.age<0:return f.points.duplicate(true)
    if not f.kind in ["jab","cross","hook","finisher"]:return f.points.duplicate(true)
    var key:Array=POSE.sample(f.kind,f.age)
    var hip:Vector2=key[1]
    var chest:Vector2=hip+Vector2(key[2])
    var p:Dictionary={"hips":_world(hip,f),"chest":_world(chest,f),"head":_world(chest+Vector2(key[3]),f)}
    for j in range(2):
        var s:String="near" if j==0 else "far"
        var shoulder:Vector2=chest+Vector2(float(key[4])*(1 if j==0 else -1),3 if j==0 else -1)
        p["shoulder_"+s]=_world(shoulder,f)
        p["elbow_"+s]=_world(shoulder+Vector2(key[5+j*2]),f)
        p["hand_"+s]=_world(shoulder+Vector2(key[6+j*2]),f)
    _legs(p,f,hip,key[9] if f.kind=="finisher" else null)
    # Blend from the actual previous displayed pose (not neutral) over 3 ticks.
    if f.age<3 and i>0:
        var prior:Dictionary=authored[-1].a
        p=_blend(prior,p,float(f.age+1)/3.0)
    # The actual contact frame uses the exact recorded striking endpoint.
    # During the 2 ticks leading into contact, approach it to avoid a discontinuity.
    for c in contacts:
        if c>=i and c-i<=2:
            var u:float=1.0-float(c-i)/3.0
            var strike:String=f.strike
            p[strike]=f.points[strike] if c==i else Vector2(p[strike]).lerp(f.points[strike],u)
            var j:String=("knee_near" if strike=="foot_near" else ("elbow_near" if strike=="hand_near" else "elbow_far"))
            p[j]=Vector2(p[j]).lerp(f.points[j],u*.45)
    if f.kind=="finisher" and f.age>=46:p=_blend(p,f.points,smoothstep(46.0,55.0,float(f.age)))
    # Preserve visible support anchors even during a clip transition.
    for j in range(2):
        if f.support[j]:
            var s:String="near" if j==0 else "far"
            p["foot_"+s]=f.points["foot_"+s]
    return p
func _victim(i:int)->Dictionary:
    var frame:Dictionary=record.frames[i]
    var f:Dictionary=frame.b
    var last:int=-1
    var next:int=-1
    for c in contacts:
        if c<=i:last=c
        elif next<0:next=c
    if last<0 or f.hurt<=0 or frame.contact_event:return f.points.duplicate(true)
    var t:int=i-last
    var impact_kind:String=record.frames[last].a.kind
    var kick:bool=impact_kind=="finisher"
    var cross:bool=impact_kind=="cross"
    var power:float=(1.0-smoothstep(9.0,32.0 if kick else 23.0,float(t)))*smoothstep(0.0,4.0,float(t))
    if next>=0:power*=smoothstep(0.0,5.0,float(next-i))
    # Start from original recorded support but independently author the upper body.
    # A normal idle guard pose is used instead of the hybrid hurt shoulders/arms.
    var hip:Vector2=_local(f.points.hips,f).lerp(Vector2(-9,-43 if kick else -47),power)
    var lean:float=lerpf(2.0,-48.0 if kick else (-36.0 if cross else -27.0),power)
    var chest:Vector2=hip+Vector2(0,-34).rotated(deg_to_rad(lean))
    var head:Vector2=chest+Vector2(0,-22).rotated(deg_to_rad(lean*.8-15*power))
    var p:Dictionary={"hips":_world(hip,f),"chest":_world(chest,f),"head":_world(head,f)}
    for j in range(2):
        var s:String="near" if j==0 else "far"
        var sh:Vector2=chest+Vector2(5 if j==0 else -5,2)
        var e:Vector2=Vector2(8,18) if j==0 else Vector2(-9,17)
        var hand:Vector2=Vector2(20,3) if j==0 else Vector2(6,10)
        var out_e:Vector2=Vector2(-18,11) if (j==0)==cross else Vector2(12,20)
        var out_h:Vector2=Vector2(-32,-2) if (j==0)==cross else Vector2(19,30)
        p["shoulder_"+s]=_world(sh,f)
        p["elbow_"+s]=_world(sh+e.lerp(out_e,power),f)
        p["hand_"+s]=_world(sh+hand.lerp(out_h,power),f)
    _legs(p,f,hip)
    # Fade back into the original pose at the end of the authored reaction.
    if next>=0 and next-i<=5:p=_blend(p,f.points,1.0-smoothstep(0.0,5.0,float(next-i)))
    if f.hurt<6:p=_blend(p,f.points,1.0-float(f.hurt)/6.0)
    return p
func _secondary(p0:Dictionary,f:Dictionary,attacker:bool,i:int)->Dictionary:
    var p:Dictionary=p0.duplicate(true)
    if record.frames[i].contact_event:return p
    if attacker:
        # Selective lag on the head and non-striking arm only. No root/feet/fist change.
        if f.age<0 or i<2:return p
        var old:Dictionary=authored[i-2].a
        var lag:Vector2=(Vector2(old.head)-Vector2(p.head)).limit_length(5)*.5
        p.head+=lag
        var side:String="near" if f.strike=="hand_far" else "far"
        for k in ["elbow_"+side,"hand_"+side]:
            p[k]+=(Vector2(old[k])-Vector2(p[k])).limit_length(7)*.35
    elif f.hurt>0:
        # Reuse the measured spring response selectively, not the baseline hurt pose.
        var angles:Vector4=f.reaction
        p.head=Vector2(p.chest)+(Vector2(p.head)-Vector2(p.chest)).rotated(deg_to_rad(angles.y*.32*f.face))
        for j in range(2):
            var side:String="near" if j==0 else "far"
            var sh:Vector2=p["shoulder_"+side]
            var a:float=deg_to_rad((angles.z if j==0 else angles.w)*.25*f.face)
            for k in ["elbow_"+side,"hand_"+side]:p[k]=sh+(Vector2(p[k])-sh).rotated(a)
    return p
func sample(i:int,variant:int)->Dictionary:
    if variant==0:return {"a":record.frames[i].a.points,"b":record.frames[i].b.points}
    return authored[i] if variant==1 else hybrid[i]
