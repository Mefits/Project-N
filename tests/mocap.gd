extends SceneTree
const MODEL=preload("res://lab/mocap/retarget.gd")
const R=preload("res://game/rig.gd")
var errors:int=0
func _initialize()->void:call_deferred("_run")
func check(ok:bool,msg:String)->void:
    if not ok:errors+=1;push_error(msg)
func _run()->void:
    var m=MODEL.new()
    check(m.data.source_count==149 and m.data.frames.size()==90,"Source count")
    check(absf(m.source_ticks()-89)<.01,"Source timebase")
    var baseline:Dictionary=m.baseline.trace()
    var knee_range:float=0
    for i in range(180):
        var s:Dictionary=m.source_at(float(i)/179)
        for styled in [false,true]:
            var p:Dictionary=m.transfer(s,styled)
            for key in p:check(Vector2(p[key]).is_finite(),"Finite retarget")
            check(absf(p.chest.distance_to(p.hips)-R.TORSO)<.001,"Torso length")
            check(absf(p.head.distance_to(p.chest)-R.NECK)<.001,"Neck length")
            for side in ["near","far"]:
                check(absf(p["thigh_"+side].distance_to(p["knee_"+side])-R.UPPER_LEG)<.001,"Thigh length")
                check(absf(p["knee_"+side].distance_to(p["foot_"+side])-R.LOWER_LEG)<.001,"Shin length")
                check(absf(p["shoulder_"+side].distance_to(p["elbow_"+side])-R.UPPER_ARM)<.001,"Arm length")
                check(absf(p["elbow_"+side].distance_to(p["hand_"+side])-R.LOWER_ARM)<.001,"Forearm length")
                check(p["foot_"+side].y<=-1.99,"Floor clearance")
    check(m.baseline.trace()==baseline,"No gameplay trace mutation")
    print("N mocap metrics: ",JSON.stringify(m.measures()))
    print("N mocap failures: ",errors)
    quit(0 if errors==0 else 1)
