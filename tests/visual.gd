extends SceneTree
const S=preload("res://game/arena.tscn")
const W=preload("res://game/world.gd")
const AIR_INPUT=preload("res://tests/air_input.gd")
func _initialize()->void:call_deferred("_run")
func capture(name:String)->void:
    await process_frame
    await RenderingServer.frame_post_draw
    var image:Image=root.get_texture().get_image()
    if image.save_png("res://reports/"+name+".png")!=OK:push_error("Capture failed")
func sequence(scene,name:String,count:int,kind:String)->void:
    scene.world=W.new()
    scene.debug=false
    DirAccess.make_dir_recursive_absolute("res://reports/"+name)
    for frame in range(count):
        for i in range(6):
            var n:int=frame*6+i
            var input:Dictionary={}
            if kind=="walk":input={"move":1 if frame<20 else 0}
            elif kind=="run":input={"move":1 if frame<24 else 0,"run":frame<24}
            elif kind=="back":input={"move":-1 if frame<20 else 0}
            elif kind=="jump":input={"jump":n==12}
            scene.world.tick(input,{})
        scene.queue_redraw()
        await capture(name+"/frame_%03d"%frame)
func impact_sequence(scene,name:String,hybrid:bool,heavy:bool)->void:
    scene.world=W.new()
    scene.world.hybrid_enabled=hybrid
    scene.world.a.separate(150)
    scene.world.b.separate(scene.world.a.pos.x+66-scene.world.b.pos.x)
    scene.world.rig_a.sample(scene.world.a)
    scene.world.rig_b.sample(scene.world.b)
    scene.debug=false
    DirAccess.make_dir_recursive_absolute("res://reports/"+name)
    for frame in range(44):
        for i in range(4):
            scene.world.tick({"heavy":heavy and frame==3 and i==0,"jab":not heavy and frame==3 and i==0},{})
        scene._hud()
        scene.queue_redraw()
        await capture(name+"/frame_%03d"%frame)
    if scene.world.hits!=1:push_error("Impact capture missed: "+name);quit(1)
func kick_sequence(scene,name:String,hit:bool,mirror:bool=false)->void:
    scene.world=W.new()
    scene.world.a.separate(150)
    scene.world.b.separate(scene.world.a.pos.x+(72 if hit else 130)-scene.world.b.pos.x)
    scene.world.rig_a.sample(scene.world.a)
    scene.world.rig_b.sample(scene.world.b)
    scene.artistic=true
    scene.smooth_skin=true
    scene.debug=false
    DirAccess.make_dir_recursive_absolute("res://reports/"+name)
    for frame in range(45):
        for i in range(4):
            var input:Dictionary={"kick":frame==3 and i==0}
            scene.world.tick({} if mirror else input,input if mirror else {})
        scene._hud()
        scene.queue_redraw()
        await capture(name+"/frame_%03d"%frame)
    if scene.world.hits!=(1 if hit else 0):push_error("Kick capture contact mismatch "+name);quit(1)
func defense_sequence(scene,name:String,parry:bool)->void:
    scene.world=W.new()
    scene.world.a.separate(150)
    scene.world.b.separate(scene.world.a.pos.x+60-scene.world.b.pos.x)
    scene.world.rig_a.sample(scene.world.a)
    scene.world.rig_b.sample(scene.world.b)
    scene.debug=false
    DirAccess.make_dir_recursive_absolute("res://reports/"+name)
    var counter_sent:bool=false
    for frame in range(52):
        for i in range(4):
            var n:int=frame*4+i
            var left:Dictionary={"jab":n==24}
            var right:Dictionary={"guard":n>= (30 if parry else 0) and not counter_sent}
            if parry and scene.world.parries==1 and not counter_sent and scene.world.freeze==0:
                right={"jab":true}
                counter_sent=true
            scene.world.tick(left,right)
        scene._hud()
        scene.queue_redraw()
        await capture(name+"/frame_%03d"%frame)
    if parry:
        if scene.world.parries!=1 or scene.world.hits!=1:push_error("Parry capture mismatch");quit(1)
    elif scene.world.blocks!=1 or scene.world.hits!=0:push_error("Block capture mismatch");quit(1)
func chain_sequence(scene,name:String,mirror:bool=false,finish:bool=false,launch:bool=false)->void:
    scene.world=W.new()
    scene.world.a.separate(150)
    scene.world.b.separate(scene.world.a.pos.x+60-scene.world.b.pos.x)
    scene.world.rig_a.sample(scene.world.a)
    scene.world.rig_b.sample(scene.world.b)
    scene.debug=false
    DirAccess.make_dir_recursive_absolute("res://reports/"+name)
    var sent:int=0
    for frame in range(88 if launch else (82 if finish else 60)):
        for i in range(4):
            var n:int=frame*4+i
            var attacker=scene.world.jab_b if mirror else scene.world.jab_a
            var press:bool=n==12 or (sent==1 and attacker.kind=="jab" and attacker.age>=11) or (sent==2 and attacker.kind=="cross" and attacker.age>=11) or (finish and sent==3 and attacker.kind=="hook" and attacker.age>=11)
            if press:sent+=1
            var input:Dictionary={"jab":press,"launch":launch and press and sent==4}
            scene.world.tick({} if mirror else input,input if mirror else {})
        scene._hud()
        scene.queue_redraw()
        await capture(name+"/frame_%03d"%frame)
    if scene.world.hits!=(4 if finish else 3):push_error("Chain capture mismatch "+name);quit(1)
    if launch and scene.world.launches!=1:push_error("Launch capture mismatch");quit(1)
func air_sequence(scene,name:String,mirror:bool=false)->void:
    scene.world=W.new()
    scene.world.a.separate(150)
    scene.world.b.separate(scene.world.a.pos.x+60-scene.world.b.pos.x)
    scene.world.rig_a.sample(scene.world.a)
    scene.world.rig_b.sample(scene.world.b)
    scene.debug=false
    var seq=AIR_INPUT.new()
    DirAccess.make_dir_recursive_absolute("res://reports/"+name)
    for frame in range(112):
        for i in range(4):
            var input:Dictionary={} if frame<3 else seq.next(scene.world,mirror)
            scene.world.tick({} if mirror else input,input if mirror else {})
        scene._hud()
        scene.queue_redraw()
        await capture(name+"/frame_%03d"%frame)
    if scene.world.air_hits!=3 or scene.world.slams!=1 or scene.world.hits!=7:push_error("Air capture mismatch "+name);quit(1)
func check_skin(scene,state:Dictionary,tick0:int)->void:
    if scene.world.ticks!=tick0 or scene.world.rig_a.points!=state:
        push_error("Skin altered simulation")
        quit(1)
func _run()->void:
    root.size=Vector2i(960,540)
    DirAccess.make_dir_recursive_absolute("res://reports")
    var scene=S.instantiate()
    root.add_child(scene)
    await process_frame
    scene.set_physics_process(false)
    scene.world=preload("res://game/world.gd").new()
    scene.queue_redraw()
    await capture("stance")
    DirAccess.make_dir_recursive_absolute("res://reports/guard")
    for frame in range(24):
        scene.queue_redraw()
        await capture("guard/frame_%03d"%frame)
        for tick in range(6):scene.world.tick({}, {})
    for i in range(47):scene.world.tick({"move":1,"run":true},{})
    scene.debug=true
    scene.queue_redraw()
    await capture("running")
    for i in range(32):scene.world.tick({"move":1,"jump":i==0},{})
    scene.queue_redraw()
    await capture("jump")
    await sequence(scene,"walk",32,"walk")
    await sequence(scene,"run",36,"run")
    await sequence(scene,"back",32,"back")
    await sequence(scene,"leap",30,"jump")
    scene.world=W.new()
    scene.world.a.separate(150)
    scene.world.b.separate(scene.world.a.pos.x+66-scene.world.b.pos.x)
    scene.world.rig_a.sample(scene.world.a)
    scene.world.rig_b.sample(scene.world.b)
    scene.debug=false
    DirAccess.make_dir_recursive_absolute("res://reports/jab")
    for frame in range(34):
        for i in range(4):
            scene.world.tick({"jab":frame==3 and i==0},{})
        scene._hud()
        scene.queue_redraw()
        await capture("jab/frame_%03d"%frame)
    if scene.world.hits!=1:push_error("Jab capture missed");quit(1);return
    await impact_sequence(scene,"heavy_hybrid",true,true)
    scene.smooth_skin=false
    await impact_sequence(scene,"heavy_old_skin",true,true)
    await sequence(scene,"run_old_skin",36,"run")
    scene.smooth_skin=true
    await impact_sequence(scene,"heavy_authored",false,true)
    await impact_sequence(scene,"jab_hybrid",true,false)
    await impact_sequence(scene,"jab_authored",false,false)
    scene.artistic=false
    await impact_sequence(scene,"heavy_mannequin",false,true)
    scene.artistic=true
    await kick_sequence(scene,"kick_hit",true)
    await kick_sequence(scene,"kick_miss",false)
    await kick_sequence(scene,"kick_mirror",true,true)
    await defense_sequence(scene,"block",false)
    await defense_sequence(scene,"parry_counter",true)
    await chain_sequence(scene,"chain")
    await chain_sequence(scene,"chain_mirror",true)
    await chain_sequence(scene,"chain_four",false,true)
    await chain_sequence(scene,"chain_launch",false,true,true)
    await chain_sequence(scene,"launch_mirror",true,true,true)
    await air_sequence(scene,"air_full")
    await air_sequence(scene,"air_mirror",true)
    var state:Dictionary=scene.world.rig_a.points.duplicate(true)
    var tick0:int=scene.world.ticks
    scene._toggle_skin()
    check_skin(scene,state,tick0)
    scene._toggle_skin()
    check_skin(scene,state,tick0)
    scene._toggle_smooth()
    check_skin(scene,state,tick0)
    scene._toggle_smooth()
    check_skin(scene,state,tick0)
    scene._pause()
    if not scene.paused:quit(1);return
    scene._reset()
    if scene.world.ticks!=0:quit(1);return
    print("N graphical smoke OK")
    quit()
