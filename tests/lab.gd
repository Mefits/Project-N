extends SceneTree
const REC=preload("res://lab/recording.gd")
var failures:int=0
func _initialize()->void:call_deferred("_run")
func check(ok:bool,msg:String)->void:
    if not ok:failures+=1;push_error(msg)
func _run()->void:
    DirAccess.make_dir_recursive_absolute("res://reports/lab")
    for name in REC.SCENARIOS:
        var a=REC.new()
        var b=REC.new()
        a.record(name)
        b.record(name)
        check(a.trace()==b.trace(),"Deterministic replay "+name)
        check(a.frames[0].tick==0,"Tick zero")
        for i in range(a.frames.size()):
            var f:Dictionary=a.frames[i]
            check(f.tick==i,"Fixed step index")
            for p in [f.a,f.b]:
                for key in p.points:check(Vector2(p.points[key]).is_finite(),"Finite joint")
            if i>0 and f.frozen:
                check(f.a.points==a.frames[i-1].a.points and f.b.points==a.frames[i-1].b.points,"Frozen render pose")
        var final:Dictionary=a.frames[-1]
        if name in ["jab","heavy","kick"]:check(final.hits==1,"Single contact "+name)
        if name=="guard":check(final.blocks==1 and final.hits==0,"Block")
        if name=="ground":check(final.hits==4,"Ground chain")
        if name=="air":check(final.hits==7 and final.air_hits==3 and final.impacts==1,"Air chain")
        if name=="run":
            check(a.metrics().max_root_speed>=239,"Sprint speed")
            check(a.metrics().flight_ticks>0,"Sprint flight")
        if name in ["run","jab","air"]:
            check(a.save_trace("res://reports/lab/"+name+".json")==OK,"Export trace "+name)
            var f=FileAccess.open("res://reports/lab/"+name+".json",FileAccess.READ)
            var decoded:Variant=JSON.parse_string(f.get_as_text())
            check(decoded is Dictionary and decoded.frames.size()==a.frames.size(),"Read exported trace")
            check(decoded.frames[0].a.points.hips is Array,"JSON joint coordinate array")
        print("N lab ",name,": ",JSON.stringify(a.metrics()))
    print("N lab failures: ",failures)
    quit(0 if failures==0 else 1)
