extends RefCounted
## Read-only recording of the real World, sampled at every 120 Hz tick.
const W=preload("res://game/world.gd")
const AIR=preload("res://tests/air_input.gd")
const BASELINE="e16ff0a7fa74306c4282773cbfff5e6309f896d3"
const SCENARIOS=["idle","walk","run","jump","jab","heavy","kick","guard","ground","air"]
const LABELS=["Стойка","Ходьба","Бег","Прыжок","Джеб","Тяжёлый","Удар ногой","Блок","Наземное комбо","Воздушное / падение"]
var frames:Array[Dictionary]=[]
var scenario:String="run"
var hybrid:bool=true
var stop:bool=true
func _fighter(m,j,r)->Dictionary:
    var support:Array[bool]=[]
    for i in range(2):
        support.append(m.grounded and m.swing!=i and m.released_foot!=i and m.down_ticks==0 and not (i==0 and j.kicking()))
    return {"pos":m.pos,"velocity":m.velocity,"face":m.facing,"points":r.points.duplicate(true),"feet":m.feet.duplicate(),"support":support,"grounded":m.grounded,"swing":m.swing,"steps":m.steps,"flight":m.run_flight,"air_time":m.airborne_time,"down":m.down_ticks,"dive":m.diving,"landing":m.dive_landing,"kind":j.kind,"age":j.age,"active":j.active(),"connected":j.connected,"hurt":j.hurt,"guard":j.guarding,"hp":j.hp,"chain":j.chain_count,"strike":j.fist(),"reaction":j.reaction.angles}
func _snapshot(w,left:Dictionary,right:Dictionary,event:bool,frozen:bool)->Dictionary:
    return {"tick":w.ticks,"ms":w.ticks*1000.0/120.0,"a":_fighter(w.a,w.jab_a,w.rig_a),"b":_fighter(w.b,w.jab_b,w.rig_b),"hits":w.hits,"blocks":w.blocks,"parries":w.parries,"launches":w.launches,"air_hits":w.air_hits,"slams":w.slams,"impacts":w.ground_impacts,"freeze":w.freeze,"frozen":frozen,"contact_event":event,"contact":w.last_contact,"result":w.last_result if event else "","left":left.duplicate(true),"right":right.duplicate(true)}
func record(name:String,hybrid_on:bool=true,hitstop_on:bool=true)->void:
    scenario=name
    hybrid=hybrid_on
    stop=hitstop_on
    frames.clear()
    var w=W.new()
    w.hybrid_enabled=hybrid
    w.hitstop_enabled=stop
    var close:bool=name in ["jab","heavy","kick","guard","ground","air"]
    if close:
        w.a.separate(150)
        w.b.separate(w.a.pos.x+(72 if name=="kick" else (66 if name in ["jab","heavy"] else 60))-w.b.pos.x)
    else:
        w.a.separate(-140)
        w.b.separate(220)
    w.rig_a.sample(w.a)
    w.rig_b.sample(w.b)
    var seq=AIR.new()
    var sent:int=0
    var count:int=420 if name=="air" else (300 if name=="ground" else (216 if name in ["run","walk","jump"] else 144))
    frames.append(_snapshot(w,{},{},false,false))
    for i in range(count):
        var l:Dictionary={}
        var r:Dictionary={}
        match name:
            "walk","run":
                l={"move":1 if i>=12 and i<156 else 0,"run":name=="run" and i>=12 and i<156}
            "jump":l={"jump":i==12}
            "jab","heavy","kick":l={name:i==12}
            "guard":
                l={"guard":true}
                r={"jab":i==24}
            "ground":
                var j=w.jab_a
                var press:bool=i==12 or (sent==1 and j.kind=="jab" and j.age>=11) or (sent==2 and j.kind=="cross" and j.age>=11) or (sent==3 and j.kind=="hook" and j.age>=11)
                if press:sent+=1
                l={"jab":press}
            "air":
                if i>=12:l=seq.next(w)
        var contacts:int=w.hits+w.blocks+w.parries
        var frozen:bool=w.freeze>0
        w.tick(l,r)
        frames.append(_snapshot(w,l,r,w.hits+w.blocks+w.parries>contacts,frozen))
static func json_value(v:Variant)->Variant:
    if v is Vector2:return [v.x,v.y]
    if v is Vector4:return [v.x,v.y,v.z,v.w]
    if v is Dictionary:
        var d:Dictionary={}
        for k in v:d[k]=json_value(v[k])
        return d
    if v is Array:
        var a:Array=[]
        for x in v:a.append(json_value(x))
        return a
    return v
func trace()->Dictionary:
    return {"schema":1,"motion_baseline":BASELINE,"scenario":scenario,"tick_hz":120,"hybrid":hybrid,"hitstop":stop,"frames":json_value(frames)}
func save_trace(path:String)->Error:
    var f=FileAccess.open(path,FileAccess.WRITE)
    if f==null:return FileAccess.get_open_error()
    f.store_string(JSON.stringify(trace()))
    f.close()
    return OK
func metrics()->Dictionary:
    var contact_ticks:Array[int]=[]
    var step_ticks:Array[int]=[]
    var flight:int=0
    var last_step:int=0
    var max_speed:float=0
    var max_fist_speed:float=0
    var max_drift:float=0
    var max_foot_error:float=0
    var action_start:int=-1
    var recovery:int=-1
    for i in range(1,frames.size()):
        var f:Dictionary=frames[i]
        var a:Dictionary=f.a
        var p:Dictionary=frames[i-1].a
        if f.contact_event:contact_ticks.append(i)
        if a.steps>last_step:step_ticks.append(i)
        last_step=a.steps
        if a.flight:flight+=1
        max_speed=maxf(max_speed,absf(a.velocity.x))
        if a.age>=0 and action_start<0:action_start=i
        if action_start>=0 and a.age<0 and recovery<0:recovery=i
        if not f.frozen:
            max_fist_speed=maxf(max_fist_speed,Vector2(a.points.hand_near).distance_to(p.points.hand_near)*120)
        for n in range(2):
            if a.support[n]:
                var key:String="foot_near" if n==0 else "foot_far"
                max_foot_error=maxf(max_foot_error,Vector2(a.points[key]).distance_to(Vector2(a.feet[n])-Vector2(0,2)))
                if p.support[n]:max_drift=maxf(max_drift,Vector2(a.feet[n]).distance_to(p.feet[n]))
    return {"contacts":contact_ticks,"step_ticks":step_ticks,"flight_ticks":flight,"max_root_speed":max_speed,"max_near_hand_speed":max_fist_speed,"max_anchor_drift":max_drift,"max_rendered_support_error":max_foot_error,"action_start":action_start,"first_recovery":recovery}
