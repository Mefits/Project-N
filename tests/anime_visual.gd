extends SceneTree
const S=preload("res://lab/anime/preview.tscn")
func _initialize()->void:call_deferred("_run")
func _run()->void:
    root.size=Vector2i(960,540)
    var scene=S.instantiate()
    root.add_child(scene)
    await process_frame
    scene.set_process(false)
    scene.playing=false
    DirAccess.make_dir_recursive_absolute("res://reports/anime")
    for i in range(111):
        scene.seek(i*2)
        await process_frame
        await RenderingServer.frame_post_draw
        if root.get_texture().get_image().save_png("res://reports/anime/frame_%03d.png"%i)!=OK:push_error("Anime capture failed");quit(1);return
    scene.bones=true
    scene.seek(scene.model.contacts[1]-3)
    await process_frame
    await RenderingServer.frame_post_draw
    if root.get_texture().get_image().save_png("res://reports/anime/skeleton.png")!=OK:quit(1);return
    print("N anime graphical OK")
    quit()
