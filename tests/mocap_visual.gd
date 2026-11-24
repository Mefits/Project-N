extends SceneTree
const S=preload("res://lab/mocap/preview.tscn")
func _initialize()->void:call_deferred("_run")
func _run()->void:
    root.size=Vector2i(960,540)
    var scene=S.instantiate()
    root.add_child(scene)
    await process_frame
    scene.set_process(false)
    scene.playing=false
    for mode in ["phase","native"]:
        scene.synced=mode=="phase"
        DirAccess.make_dir_recursive_absolute("res://reports/mocap/"+mode)
        for i in range(67):
            scene.seek(i*4)
            await process_frame
            await RenderingServer.frame_post_draw
            if root.get_texture().get_image().save_png("res://reports/mocap/"+mode+"/frame_%03d.png"%i)!=OK:push_error("Mocap capture failed");quit(1);return
    print("N mocap graphical OK")
    quit()
