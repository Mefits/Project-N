extends RefCounted
## Isolated preview; does not alter motor or combat rig.
const REC=preload("res://lab/recording.gd")
const R=preload("res://game/rig.gd")
const BASE_TICKS=52.0
const STYLE_TICKS=66.0
var data:Dictionary
var baseline=REC.new()
func _init()->void:
    data=JSON.parse_string(FileAccess.get_file_as_string("res://lab/mocap/run_projection.json"))
    baseline.record("run")
func source_ticks()->float:return (data.frames.size()-1)*float(data.frame_time)*120
func source_at(phase:float)->Dictionary:
    var x:float=clampf(phase,0,1)*(data.frames.size()-1)
    var i:int=mini(int(x),data.frames.size()-2)
    var u:float=x-i
    var a:Dictionary=data.frames[i]
    var b:Dictionary=data.frames[i+1]
    var p:Dictionary={}
    for k in a:p[k]=Vector2(a[k][0],a[k][1]).lerp(Vector2(b[k][0],b[k][1]),u)
    return p
func baseline_at(phase:float)->Dictionary:
    var i:int=66+roundi(clampf(phase,0,1)*BASE_TICKS)
    var f:Dictionary=baseline.frames[i].a
    var p:Dictionary={}
    for k in f.points:p[k]=Vector2(f.points[k])-Vector2(f.pos)
    return p
static func segment(from:Vector2,to:Vector2,length:float,angle:float=0)->Vector2:
    var d:Vector2=to-from
    if d.length()<.0001:d=Vector2.DOWN
    return d.normalized().rotated(deg_to_rad(angle))*length
func transfer(s:Dictionary,styled:bool=false)->Dictionary:
    var p:Dictionary={}
    var hip:Vector2=s.Hips+Vector2(0,9)
    var torso:Vector2=segment(s.Hips,s.Spine1,R.TORSO,14.0 if styled else 0.0)
    p.hips=hip
    p.chest=hip+torso
    p.head=p.chest+segment(s.Spine1,s.Head,R.NECK,-5.0 if styled else 0.0)
    for i in range(2):
        var side:String="near" if i==0 else "far"
        var source:String="Left" if i==0 else "Right"
        var sign0:float=1.0 if i==0 else -1.0
        var thigh:Vector2=hip+Vector2(2*sign0,0)
        var upper:Vector2=segment(s[source+"UpLeg"],s[source+"Leg"],R.UPPER_LEG)
        var lower:Vector2=segment(s[source+"Leg"],s[source+"Foot"],R.LOWER_LEG)
        if styled:
            upper=Vector2.DOWN.rotated(Vector2.DOWN.angle_to(upper)*1.12)*R.UPPER_LEG
            lower=Vector2.DOWN.rotated(Vector2.DOWN.angle_to(lower)*1.05)*R.LOWER_LEG
        p["thigh_"+side]=thigh
        p["knee_"+side]=thigh+upper
        p["foot_"+side]=thigh+upper+lower
        var shoulder:Vector2=p.chest+Vector2(5*sign0,2).rotated(Vector2.UP.angle_to(torso))
        var arm:Vector2=segment(s[source+"Arm"],s[source+"ForeArm"],R.UPPER_ARM)
        var fore:Vector2=segment(s[source+"ForeArm"],s[source+"Hand"],R.LOWER_ARM)
        if styled:
            arm=Vector2.DOWN.rotated(Vector2.DOWN.angle_to(arm)*1.18)*R.UPPER_ARM
            fore=Vector2.DOWN.rotated(Vector2.DOWN.angle_to(fore)*1.06)*R.LOWER_ARM
        p["shoulder_"+side]=shoulder
        p["elbow_"+side]=shoulder+arm
        p["hand_"+side]=shoulder+arm+fore
    # Preview ground fit: projected toe height is a proxy only, not planted IK.
    # Preserve actual source flight clearance where feasible; no forced anchoring.
    var toe:float=maxf(float(s.LeftToeBase.y),float(s.RightToeBase.y))
    var desired_bottom:float=minf(-2.0,toe-2.0)
    var lowest:float=maxf(p.foot_near.y,p.foot_far.y)
    for key in p:p[key].y+=desired_bottom-lowest
    return p
func pose_at(tick:float,panel:int,synced:bool)->Dictionary:
    var duration:float=BASE_TICKS if panel==0 else (STYLE_TICKS if panel==3 else source_ticks())
    var phase:float=fposmod(tick,source_ticks())/source_ticks() if synced else fposmod(tick,duration)/duration
    if panel==0:return baseline_at(phase)
    var s:Dictionary=source_at(phase)
    return s if panel==1 else transfer(s,panel==3)
func measures()->Dictionary:
    var min_hip:float=INF
    var max_hip:float=-INF
    var max_lean:float=0
    var min_lean:float=INF
    for i in range(data.frames.size()):
        var p:Dictionary=transfer(source_at(float(i)/(data.frames.size()-1)),true)
        min_hip=minf(min_hip,p.hips.y)
        max_hip=maxf(max_hip,p.hips.y)
        var lean:float=rad_to_deg(Vector2.UP.angle_to(p.chest-p.hips))
        min_lean=minf(min_lean,lean)
        max_lean=maxf(max_lean,lean)
    return {"source_ms":source_ticks()*1000/120,"baseline_ms":BASE_TICKS*1000/120,"style_ms":STYLE_TICKS*1000/120,"style_hip_range":max_hip-min_hip,"style_lean_min":min_lean,"style_lean_max":max_lean}
