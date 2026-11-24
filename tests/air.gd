extends SceneTree
const W=preload("res://game/world.gd")
const M=preload("res://game/motor.gd")
const R=preload("res://game/rig.gd")
const SCRIPT=preload("res://tests/air_input.gd")
var errors:int=0
func _initialize()->void:call_deferred("_run")
func check(ok:bool,msg:String)->void:
    if not ok:errors+=1;push_error(msg)
func close_world(gap:float=60)->RefCounted:
    var w=W.new()
    w.a.separate(150)
    w.b.separate(w.a.pos.x+gap-w.b.pos.x)
    w.rig_a.sample(w.a)
    w.rig_b.sample(w.b)
    return w
func execute(w,mirror:bool=false,follow:bool=true,finish:bool=true,guard:bool=false)->void:
    var seq=SCRIPT.new()
    var src=w.b if mirror else w.a
    var dst=w.a if mirror else w.b
    var a=w.jab_b if mirror else w.jab_a
    var b=w.jab_a if mirror else w.jab_b
    var kinds:Array=[]
    var last:String=""
    var peak:float=0
    var min_gap:float=999
    var slam_velocity:float=0
    var slam_landed:bool=false
    var old_slams:int=0
    var old_air_hits:int=0
    var old_launches:int=0
    var landing_ticks:int=0
    for i in range(420):
        var inp:Dictionary=seq.next(w,mirror,follow,finish)
        var old_src:Vector2=src.pos
        var old_dst:Vector2=dst.pos
        var frozen:bool=w.freeze>0
        var other:Dictionary={"guard":guard}
        w.tick(other if mirror else inp,inp if mirror else other)
        if frozen:check(src.pos==old_src and dst.pos==old_dst,"Air hitstop freezes roots")
        else:check(src.pos.distance_to(old_src)<10 and dst.pos.distance_to(old_dst)<10,"No teleport in aerial string")
        if a.age>=0 and a.kind!=last:
            kinds.append(a.kind)
            last=a.kind
        if not mirror and a.kind in ["air_cross","air_slam"] and a.active() and not frozen:
            var ar=w.rig_a
            var dr=w.rig_b
            print("N air active ",a.kind," ",a.age," roots ",src.pos," ",dst.pos," fist ",a.contact_point(ar,src.facing)," target ",dr.points.chest," ",dr.points.hips)
        if w.air_hits>old_air_hits:
            check(not src.grounded and not dst.grounded,"Air contact requires both airborne")
            old_air_hits=w.air_hits
        if w.slams>old_slams:
            slam_velocity=dst.velocity.y
            old_slams=w.slams
        if w.slams>0 and dst.grounded:
            slam_landed=true
            landing_ticks+=1
        peak=maxf(peak,M.FLOOR-minf(src.pos.y,dst.pos.y))
        if not src.grounded and not dst.grounded:min_gap=minf(min_gap,absf(src.pos.x-dst.pos.x))
        for rig in [w.rig_a,w.rig_b]:
            var p:Dictionary=rig.points
            for side in ["near","far"]:
                check(absf(p["thigh_"+side].distance_to(p["knee_"+side])-R.UPPER_LEG)<.001,"Air thigh length")
                check(absf(p["knee_"+side].distance_to(p["foot_"+side])-R.LOWER_LEG)<.001,"Air shin length")
                check(absf(p["shoulder_"+side].distance_to(p["elbow_"+side])-R.UPPER_ARM)<.001,"Air upper arm length")
                check(absf(p["elbow_"+side].distance_to(p["hand_"+side])-R.LOWER_ARM)<.001,"Air forearm length")
                check(p["foot_"+side].y<=M.FLOOR+.01,"Air floor safety")
    if guard or w.launches==0:
        check(w.air_hits==0 and w.pursuits==0 and w.slams==0,"No aerial chase without confirmed launch")
    elif follow:
        check(w.pursuits==1 and w.air_hits==(3 if finish else 2),"Air string confirmed")
        check(w.hits==(7 if finish else 6),"Actual total contacts")
        check(b.hp==(10 if finish else 28),"Actual HP loss")
        check(a.peak_chain==(7 if finish else 6),"Chain count persists")
        check(kinds.has("air_jab") and kinds.has("air_cross"),"Distinct aerial attacks")
        if finish:
            check(w.slams==1 and slam_velocity>=600 and slam_landed,"Downward strike and landing")
        else:check(w.slams==0,"No automatic finisher")
        check(peak<180 and min_gap>=37.9,"Bounded air following")
        check(src.grounded and dst.grounded and not src.pursuing and not dst.launched and not a.locked() and not b.locked(),"Both recover")
    else:check(w.hits==4 and w.pursuits==0 and w.air_hits==0,"Optional chase")
    print("N air case: ",kinds,"; hits ",w.hits,"; air ",w.air_hits,"; pursuit ",w.pursuits,"; peak ",peak,"; gap ",min_gap,"; slam ",slam_velocity,"; hp ",b.hp)
func _run()->void:
    execute(close_world())
    execute(close_world(),true)
    execute(close_world(),false,true,false)
    execute(close_world(),false,false)
    execute(close_world(170))
    var blocked=close_world()
    for i in range(25):blocked.tick({},{"guard":true})
    execute(blocked,false,true,true,true)
    print("N air failures: ",errors)
    quit(0 if errors==0 else 1)
