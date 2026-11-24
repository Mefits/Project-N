extends SceneTree
const W=preload("res://game/world.gd")
const M=preload("res://game/motor.gd")
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
func run_launch(w,mirror:bool=false,guard:bool=false)->void:
    var attacker=w.jab_b if mirror else w.jab_a
    var defender=w.jab_a if mirror else w.jab_b
    var src=w.b if mirror else w.a
    var dst=w.a if mirror else w.b
    var sent:int=0
    var peak:float=0
    var air_ticks:int=0
    var landed:bool=false
    var had_air:bool=false
    var last_hits:int=0
    for i in range(300):
        var press:bool=i==0 or (sent==1 and attacker.kind=="jab" and attacker.age>=11) or (sent==2 and attacker.kind=="cross" and attacker.age>=11) or (sent==3 and attacker.kind=="hook" and attacker.age>=11)
        if press:sent+=1
        var input:Dictionary={"jab":press,"launch":press and sent==4}
        var other:Dictionary={"guard":guard}
        var frozen:bool=w.freeze>0
        var before:Vector2=dst.pos
        w.tick(other if mirror else input,input if mirror else other)
        if frozen:check(dst.pos==before,"Hitstop freezes launched root")
        if w.launches>0:
            peak=maxf(peak,M.FLOOR-dst.pos.y)
            if not dst.grounded:
                had_air=true
                air_ticks+=1
                check(defender.locked(),"Launch recovery locked in air")
                check(dst.launched,"Launched motor state")
            elif had_air:landed=true
            check(src.grounded,"Launcher remains on ground")
        var p:Dictionary=w.rig_a.points if mirror else w.rig_b.points
        for side in ["near","far"]:
            check(absf(p["thigh_"+side].distance_to(p["knee_"+side])-R.UPPER_LEG)<.001,"Launch thigh length")
            check(absf(p["knee_"+side].distance_to(p["foot_"+side])-R.LOWER_LEG)<.001,"Launch shin length")
            check(p["foot_"+side].y<=M.FLOOR+.01,"No floor penetration")
        check(w.hits>=last_hits,"Monotonic contact count")
        last_hits=w.hits
    if guard or not had_air:
        check(w.launches==0,"No launch without actual hit")
    else:
        check(w.hits==4 and w.launches==1 and attacker.peak_chain==4,"Four contacts, one launcher")
        check(defender.hp==45,"Launch branch damage")
        check(peak>85 and peak<105 and air_ticks>90,"Ballistic launch height and duration")
        check(landed and dst.grounded and not dst.launched and absf(dst.pos.y-M.FLOOR)<.01,"Lands and clears launch state")
        check(not defender.locked(),"Control returns after landing")
        print("N launch peak: ",peak," px; air ticks: ",air_ticks,"; mirror: ",mirror)
func _run()->void:
    var w=close_world()
    run_launch(w)
    check(w.launches==1 and w.jab_a.kind=="launcher","Launch branch selected")
    var mirror=close_world()
    run_launch(mirror,true)
    check(mirror.launches==1,"Mirror launch")
    var far=close_world(170)
    run_launch(far)
    check(far.hits==0 and far.launches==0,"Whiff cannot launch")
    var blocked=close_world()
    for i in range(25):blocked.tick({},{"guard":true})
    run_launch(blocked,false,true)
    check(blocked.blocks==1 and blocked.launches==0,"Blocked string cannot launch")
    var direct=close_world()
    direct.jab_a.kind="launcher"
    direct.jab_a.age=0
    direct.jab_a.chain_count=4
    for i in range(70):direct.tick({},{"guard":true})
    check(direct.blocks+direct.parries==1 and direct.launches==0 and direct.b.grounded,"Defended launcher cannot lift")
    print("N launch failures: ",errors)
    quit(0 if errors==0 else 1)
