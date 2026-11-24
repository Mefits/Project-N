extends Node2D
const REC=preload("res://lab/recording.gd")
const SOFT=preload("res://game/smooth_skin.gd")
var recording=REC.new()
var index:int=0
var playing:bool=false
var speed:float=1
var accumulator:float=0
var skeleton:bool=false
var trails:bool=true
var anchors:bool=true
var exporting:bool=false
var scrub:HSlider
var info:Label
var detail:Label
var status:Label
var play_button:Button
var selector:OptionButton
func _ready()->void:
    var top:=HBoxContainer.new()
    top.position=Vector2(16,12)
    add_child(top)
    selector=OptionButton.new()
    for label in REC.LABELS:selector.add_item(label)
    selector.select(2)
    top.add_child(selector)
    selector.item_selected.connect(func(i:int):load_scenario(REC.SCENARIOS[i]))
    play_button=_button(top,"Пуск",toggle_play)
    _button(top,"|<",func():seek(0))
    _button(top,"-1",func():seek(index-1))
    _button(top,"+1",func():seek(index+1))
    var rate:=OptionButton.new()
    for label in ["1×","0.5×","0.25×"]:rate.add_item(label)
    top.add_child(rate)
    rate.item_selected.connect(func(i:int):speed=[1.0,.5,.25][i])
    _button(top,"Скелет",func():skeleton=not skeleton;queue_redraw())
    _button(top,"Следы",func():trails=not trails;queue_redraw())
    _button(top,"Опора",func():anchors=not anchors;queue_redraw())
    _button(top,"JSON",export_trace)
    _button(top,"PNG 30fps",export_frames)
    _button(top,"Игра",func():if not exporting:get_tree().change_scene_to_file("res://game/arena.tscn"))
    info=Label.new()
    info.position=Vector2(16,47)
    add_child(info)
    detail=Label.new()
    detail.position=Vector2(16,72)
    detail.add_theme_font_size_override("font_size",12)
    add_child(detail)
    scrub=HSlider.new()
    scrub.position=Vector2(20,462)
    scrub.size=Vector2(920,24)
    scrub.step=1
    scrub.value_changed.connect(func(v:float):seek(int(v)))
    add_child(scrub)
    status=Label.new()
    status.position=Vector2(20,495)
    status.add_theme_font_size_override("font_size",12)
    add_child(status)
    load_scenario("run")
func _button(parent:HBoxContainer,label:String,cb:Callable)->Button:
    var b:=Button.new()
    b.text=label
    b.focus_mode=Control.FOCUS_NONE
    parent.add_child(b)
    b.pressed.connect(cb)
    return b
func load_scenario(name:String)->void:
    if exporting:return
    playing=false
    play_button.text="Пуск"
    recording.record(name)
    selector.select(REC.SCENARIOS.find(name))
    scrub.max_value=recording.frames.size()-1
    seek(0)
    var m:Dictionary=recording.metrics()
    status.text="Замер: шаги %d · отрыв %d тиков · пик корня %.1f px/s · ошибка опоры %.2f px · контакты %s"%[m.step_ticks.size(),m.flight_ticks,m.max_root_speed,m.max_rendered_support_error,str(m.contacts)]
func seek(value:int)->void:
    if recording.frames.is_empty() or exporting:return
    _set_index(value)
    playing=false
    play_button.text="Пуск"
func _set_index(value:int)->void:
    index=clampi(value,0,recording.frames.size()-1)
    scrub.set_value_no_signal(index)
    var f:Dictionary=recording.frames[index]
    var a:Dictionary=f.a
    info.text="N Animation Lab   |   %s   |   тик %03d / %03d   |   %.1f мс"%[recording.scenario,index,recording.frames.size()-1,f.ms]
    detail.text="A: %s / %d  ·  %s  ·  скорость (%.0f, %.0f)  |  попадания %d  ·  стоп %d  ·  B: HP %d, падение %d"%[a.kind,a.age,"контакт" if f.contact_event else ("активен" if a.active else ("воздух" if not a.grounded else ("отрыв" if a.flight else "опора"))),a.velocity.x,a.velocity.y,f.hits,f.freeze,f.b.hp,f.b.down]
    queue_redraw()
func toggle_play()->void:
    if exporting:return
    if index==recording.frames.size()-1:_set_index(0)
    playing=not playing
    accumulator=0
    play_button.text="Пауза" if playing else "Пуск"
func _process(dt:float)->void:
    if not playing or exporting:return
    accumulator+=dt*120*speed
    var n:int=int(accumulator)
    if n>0:
        accumulator-=n
        _set_index(index+n)
        if index==recording.frames.size()-1:
            playing=false
            play_button.text="Пуск"
func _unhandled_key_input(e:InputEvent)->void:
    if not e is InputEventKey or not e.pressed or e.echo or exporting:return
    match e.physical_keycode:
        KEY_SPACE:toggle_play()
        KEY_LEFT:seek(index-1)
        KEY_RIGHT:seek(index+1)
        KEY_HOME:seek(0)
func export_trace()->void:
    var dir:String="user://animation_lab"
    DirAccess.make_dir_recursive_absolute(dir)
    var path:String=dir+"/"+recording.scenario+".json"
    var err:Error=recording.save_trace(path)
    status.text=("JSON: "+ProjectSettings.globalize_path(path)) if err==OK else "Ошибка JSON: "+str(err)
func export_frames()->void:
    if exporting:return
    playing=false
    play_button.text="Пуск"
    exporting=true
    var original:int=index
    var dir:String="user://animation_lab/"+recording.scenario
    DirAccess.make_dir_recursive_absolute(dir)
    var err:Error=recording.save_trace(dir+"/trace.json")
    if err==OK:
        for i in range(0,recording.frames.size(),4):
            _set_index(i)
            await get_tree().process_frame
            await RenderingServer.frame_post_draw
            err=get_viewport().get_texture().get_image().save_png(dir+"/frame_%04d.png"%(i/4))
            if err!=OK:break
    exporting=false
    _set_index(original)
    status.text=("PNG 30 fps: "+ProjectSettings.globalize_path(dir)) if err==OK else "Ошибка экспорта: "+str(err)
func _line(p:Dictionary,a:String,b:String,c:Color)->void:
    draw_line(p[a],p[b],c,2,true)
func _figure(f:Dictionary,c:Color)->void:
    var p:Dictionary=f.points
    if not skeleton:SOFT.draw(self,p,int(f.face),c)
    else:
        _line(p,"hips","chest",c)
        _line(p,"chest","head",c)
        for s in ["near","far"]:
            _line(p,"chest","shoulder_"+s,c)
            _line(p,"shoulder_"+s,"elbow_"+s,c)
            _line(p,"elbow_"+s,"hand_"+s,c)
            _line(p,"hips","thigh_"+s,c)
            _line(p,"thigh_"+s,"knee_"+s,c)
            _line(p,"knee_"+s,"foot_"+s,c)
        for key in p:draw_circle(p[key],3,c)
    if anchors and f.grounded:
        for i in range(2):
            draw_circle(f.feet[i],4,Color("#68d3a3") if f.support[i] else Color("#e2a85b"))
func _draw()->void:
    draw_rect(Rect2(0,0,960,540),Color("#172632"))
    draw_rect(Rect2(0,100,960,330),Color("#213542"))
    for x in range(0,960,40):draw_line(Vector2(x,100),Vector2(x,430),Color("#2b414d"),1)
    draw_line(Vector2(0,430),Vector2(960,430),Color("#82968e"),2)
    if recording.frames.is_empty():return
    var f:Dictionary=recording.frames[index]
    if trails:
        for key in ["hand_near","foot_near","hips"]:
            var pts:=PackedVector2Array()
            for i in range(maxi(0,index-24),index+1):pts.append(recording.frames[i].a.points[key])
            if pts.size()>1:draw_polyline(pts,Color("#d2b677") if key=="hand_near" else Color("#699cae"),1.5,true)
    _figure(f.a,Color("#6daac8"))
    _figure(f.b,Color("#c88b72"))
    if f.contact_event or f.freeze>0:
        draw_arc(f.contact,9,0,TAU,24,Color("#ffd18a"),2,true)
    var n:float=maxf(1,recording.frames.size()-1)
    for i in range(recording.frames.size()):
        var s:Dictionary=recording.frames[i]
        var x:float=20+920*i/n
        if s.a.active:draw_line(Vector2(x,450),Vector2(x,455),Color("#dc915f"),2)
        if s.frozen:draw_line(Vector2(x,443),Vector2(x,448),Color("#ad9ad9"),2)
        if s.contact_event:draw_line(Vector2(x,437),Vector2(x,455),Color("#ffd18a"),2)
