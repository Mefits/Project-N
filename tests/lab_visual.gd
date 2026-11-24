extends SceneTree
const LAB=preload("res://lab/animation_lab.tscn")
var errors:int=0
func _initialize()->void:call_deferred("_run")
func check(ok:bool,msg:String)->void:
    if not ok:errors+=1;push_error(msg)
func capture(path:String)->void:
    await process_frame
    await RenderingServer.frame_post_draw
    check(root.get_texture().get_image().save_png(path)==OK,"Lab capture "+path)
func _run()->void:
    root.size=Vector2i(960,540)
    var scene=LAB.instantiate()
    root.add_child(scene)
    await process_frame
    scene.set_process(false)
    var original:Dictionary=scene.recording.trace()
    scene.seek(52)
    check(scene.index==52 and int(scene.scrub.value)==52,"Seek")
    scene.scrub.value=33
    check(scene.index==33,"Slider seeks")
    scene.seek(scene.index+1)
    check(scene.index==34,"Single step")
    scene.toggle_play()
    scene._process(1.0/30.0)
    check(scene.index==38,"Playback 1x")
    scene.speed=.25
    scene._process(1.0/30.0)
    check(scene.index==39,"Playback quarter speed")
    scene.seek(0)
    check(not scene.playing and scene.recording.trace()==original,"Playback never mutates trace")
    DirAccess.make_dir_recursive_absolute("res://reports/lab/run")
    for i in range(0,scene.recording.frames.size(),4):
        scene.seek(i)
        await capture("res://reports/lab/run/frame_%03d.png"%(i/4))
    scene.skeleton=true
    scene.seek(85)
    await capture("res://reports/lab/run_skeleton.png")
    scene.skeleton=false
    scene.load_scenario("jab")
    var m:Dictionary=scene.recording.metrics()
    check(m.contacts.size()==1,"Contact marker")
    DirAccess.make_dir_recursive_absolute("res://reports/lab/jab")
    for i in range(0,scene.recording.frames.size(),4):
        scene.seek(i)
        await capture("res://reports/lab/jab/frame_%03d.png"%(i/4))
    scene.seek(m.contacts[0])
    await capture("res://reports/lab/jab_contact.png")
    scene.export_trace()
    check(FileAccess.file_exists("user://animation_lab/jab.json"),"UI export JSON")
    await scene.export_frames()
    check(FileAccess.file_exists("user://animation_lab/jab/frame_0000.png"),"UI export PNG")
    check(scene.index==m.contacts[0] and not scene.exporting,"Export restores sample")
    scene.load_scenario("air")
    scene.seek(140)
    await capture("res://reports/lab/air.png")
    print("N lab graphical failures: ",errors)
    quit(0 if errors==0 else 1)
