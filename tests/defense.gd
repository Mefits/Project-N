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
func _run()->void:
    for mode in ["jab","heavy","kick"]:
        var w=close_world()
        for i in range(130):
            w.tick({mode:i==25},{"guard":true})
            var p:Dictionary=w.rig_b.points
            for side in ["near","far"]:
                check(absf(p["shoulder_"+side].distance_to(p["elbow_"+side])-R.UPPER_ARM)<.001,"Guard arm length")
                check(absf(p["elbow_"+side].distance_to(p["hand_"+side])-R.LOWER_ARM)<.001,"Guard forearm length")
        check(w.blocks==1 and w.parries==0 and w.hits==0 and w.jab_b.hp==100,"Held block "+mode)
        check(w.frozen_ticks==J.BLOCK_FREEZE,"Block hitstop")
    var p=close_world()
    for i in range(100):
        p.tick({"jab":i==0},{"guard":i>=6 and i<18})
        if p.parries==1:
            check(p.jab_a.hurt>0 and p.jab_a.age<0,"Parry interrupts attacker")
            break
    check(p.parries==1 and p.hits==0 and p.jab_b.hp==100,"Timed parry")
    # Release guard, counter during the stagger. Hitstop accepts input but freezes age.
    for i in range(100):p.tick({},{"jab":i==1})
    check(p.hits==1 and p.jab_a.hp==90,"Parry counterattack")
    var mirror=close_world()
    for i in range(90):mirror.tick({"guard":i>=6},{"jab":i==0})
    check(mirror.parries==1 and mirror.jab_a.hp==100,"Mirror parry")
    var early=close_world()
    for i in range(100):early.tick({"jab":i==25},{"guard":true})
    check(early.blocks==1 and early.parries==0,"Held guard cannot retrigger parry")
    var late=close_world()
    for i in range(100):late.tick({"jab":i==0},{"guard":i>=25})
    check(late.hits==1 and late.parries==0 and late.blocks==0,"Late guard fails")
    var air=close_world()
    air.tick({},{"jump":true})
    air.tick({},{"guard":true})
    check(not air.jab_b.guarding,"No air guard in this milestone")
    var back=close_world()
    back.tick({},{"guard":true})
    check(back.jab_b.defense(back.b,back.b.pos.x+20)=="hit","No rear defense")
    var attacking=close_world()
    for i in range(8):attacking.tick({"heavy":i==0},{})
    attacking.tick({"guard":true},{})
    check(not attacking.jab_a.guarding and attacking.jab_a.age>=0,"No guard cancel mid attack")
    var whiff=close_world(160)
    for i in range(90):whiff.tick({"jab":i==0},{"guard":i>=6})
    check(whiff.hits==0 and whiff.blocks==0 and whiff.parries==0 and whiff.frozen_ticks==0,"No defense event without contact")
    print("N defense failures: ",errors)
    quit(0 if errors==0 else 1)
