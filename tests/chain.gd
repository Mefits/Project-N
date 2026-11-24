extends SceneTree
const W=preload("res://game/world.gd")
const J=preload("res://game/jab.gd")
const R=preload("res://game/rig.gd")
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
func string_run(w,mirror:bool=false,guard:bool=false,finish:bool=false)->Array:
    var attacker=w.jab_b if mirror else w.jab_a
    var sent:int=0
    var kinds:Array=[]
    var last:String=""
    var min_gap:float=999
    var support:Vector2=Vector2.ZERO
    var supporting:bool=false
    for i in range(250):
        var press:bool=i==0 or (sent==1 and attacker.kind=="jab" and attacker.age>=11) or (sent==2 and attacker.kind=="cross" and attacker.age>=11) or (finish and sent==3 and attacker.kind=="hook" and attacker.age>=11)
        if press:sent+=1
        var input:Dictionary={"jab":press}
        var other:Dictionary={"guard":guard}
        w.tick(other if mirror else input,input if mirror else other)
        if attacker.age>=0 and attacker.kind!=last:
            kinds.append(attacker.kind)
            last=attacker.kind
        var motor=w.b if mirror else w.a
        var p:Dictionary=w.rig_b.points if mirror else w.rig_a.points
        if attacker.age>=0 and attacker.kind in ["cross","hook","finisher"]:min_gap=minf(min_gap,absf(w.a.pos.x-w.b.pos.x))
        if attacker.kind=="finisher" and attacker.age>=0:
            if not supporting:
                support=motor.feet[1]
                supporting=true
            check(motor.feet[1]==support,"Finisher rear support")
            check(p.foot_far.distance_to(support-Vector2(0,2))<.5,"Finisher rendered support")
        for side in ["near","far"]:
            check(absf(p["shoulder_"+side].distance_to(p["elbow_"+side])-R.UPPER_ARM)<.001,"Chain upper arm")
            check(absf(p["elbow_"+side].distance_to(p["hand_"+side])-R.LOWER_ARM)<.001,"Chain forearm")
    if kinds.size()>1:check(min_gap>=51,"Combo separation maintained")
    print("N chain minimum gap: ",min_gap)
    return kinds
func _run()->void:
    var w=close_world()
    var x:float=w.a.pos.x
    var kinds:Array=string_run(w)
    check(kinds==["jab","cross","hook"],"Distinct lead/rear/hook")
    check(w.hits==3 and w.jab_b.hp==65 and w.jab_a.peak_chain==3,"Three confirmed contacts")
    check(w.a.pos.x>x+8 and w.a.pos.x<x+100,"Bounded pursuit")
    check(w.jab_a.age<0 and w.jab_a.chain_count==0,"Returns to guard")
    var mirror=close_world()
    check(string_run(mirror,true)==["jab","cross","hook"],"Mirrored sequence")
    check(mirror.hits==3 and mirror.jab_a.hp==65,"Mirror damage")
    var fin=close_world()
    check(string_run(fin,false,false,true)==["jab","cross","hook","finisher"],"Four distinct attacks")
    check(fin.hits==4 and fin.jab_b.hp==41 and fin.jab_a.peak_chain==4,"Four real contacts")
    var fmirror=close_world()
    check(string_run(fmirror,true,false,true)==["jab","cross","hook","finisher"] and fmirror.hits==4,"Mirrored finisher")
    var miss=close_world(170)
    check(string_run(miss)==["jab"] and miss.hits==0,"Whiff cannot unlock followup")
    var blocked=close_world()
    blocked.tick({},{"guard":true})
    for i in range(20):blocked.tick({},{"guard":true})
    check(string_run(blocked,false,true)==["jab"] and blocked.blocks==1 and blocked.hits==0,"Block cannot unlock followup")
    var parry=close_world()
    for i in range(100):
        parry.tick({"jab":i==0 or i==11},{"guard":i>=6})
    check(parry.parries==1 and parry.jab_a.attacks==1 and parry.jab_a.chain_buffer==0,"Parry clears chain")
    check(J.DURATION==36 and J.HEAVY_DURATION==58 and J.KICK.DURATION==64,"New baseline tempo")
    print("N chain failures: ",errors,"; sequence ",kinds,"; hits ",w.hits,"; travel ",w.a.pos.x-x)
    quit(0 if errors==0 else 1)
