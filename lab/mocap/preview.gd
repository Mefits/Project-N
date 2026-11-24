extends Node2D
const MODEL=preload("res://lab/mocap/retarget.gd")
const SOFT=preload("res://game/smooth_skin.gd")
var model=MODEL.new()
var tick:float=0
var playing:bool=true
var synced:bool=true
var bones:bool=false
var label:Label
var slider:HSlider
func _ready()->void:
    var bar:=HBoxContainer.new()
    bar.position=Vector2(16,10)
    add_child(bar)
    _button(bar,"Пуск / пауза",func():playing=not playing)
    _button(bar,"-1",func():playing=false;seek(tick-1))
    _button(bar,"+1",func():playing=false;seek(tick+1))
    _button(bar,"Начало",func():playing=false;seek(0))
    _button(bar,"Фаза / исходный темп",func():synced=not synced;seek(tick))
    _button(bar,"Скелет / облик",func():bones=not bones;queue_redraw())
    _button(bar,"Лаборатория",func():get_tree().change_scene_to_file("res://lab/animation_lab.tscn"))
    label=Label.new()
    label.position=Vector2(16,45)
    add_child(label)
    slider=HSlider.new()
    slider.position=Vector2(20,506)
    slider.size=Vector2(920,23)
    slider.max_value=356
    slider.step=1
    slider.value_changed.connect(func(v:float):playing=false;seek(v))
    add_child(slider)
    seek(0)
func _button(bar:HBoxContainer,txt:String,cb:Callable)->void:
    var b:=Button.new()
    b.text=txt
    bar.add_child(b)
    b.pressed.connect(cb)
func seek(t:float)->void:
    tick=clampf(t,0,356)
    slider.set_value_no_signal(tick)
    label.text="N  /  0.10.3   ·   %s   ·   %.0f мс   ·   без переноса в игровой бой"%["одинаковая фаза, цикл 742 мс" if synced else "исходный темп каждого цикла",tick*1000/120]
    queue_redraw()
func _process(dt:float)->void:
    if playing:seek(fposmod(tick+120*dt,356))
func _skeleton(p:Dictionary,raw:bool,c:Color)->void:
    var links:Array=[]
    if raw:
        links=[["Hips","Spine1"],["Spine1","Head"]]
        for s in ["Left","Right"]:
            links.append_array([["Spine1",s+"Arm"],[s+"Arm",s+"ForeArm"],[s+"ForeArm",s+"Hand"],["Hips",s+"UpLeg"],[s+"UpLeg",s+"Leg"],[s+"Leg",s+"Foot"],[s+"Foot",s+"ToeBase"]])
    else:
        links=[["hips","chest"],["chest","head"]]
        for s in ["near","far"]:
            links.append_array([["chest","shoulder_"+s],["shoulder_"+s,"elbow_"+s],["elbow_"+s,"hand_"+s],["hips","thigh_"+s],["thigh_"+s,"knee_"+s],["knee_"+s,"foot_"+s]])
    for l in links:draw_line(p[l[0]],p[l[1]],c,2,true)
    for key in p:draw_circle(p[key],2.5,c)
func _draw()->void:
    draw_rect(Rect2(0,0,960,540),Color("#172632"))
    var names:Array=["01  N — ручной бег / 433 мс","02  CMU — проекция 3D / 742 мс","03  Перенос на кости N / 742 мс","04  Стилизация N / 550 мс"]
    for panel in range(4):
        var x:float=16+470*(panel%2)
        var y:float=80+207*(panel/2 if panel%2==0 else (panel-1)/2)
        var origin:=Vector2(x+235,y+181)
        draw_rect(Rect2(x,y,458,198),Color("#213542"))
        draw_string(ThemeDB.fallback_font,Vector2(x+10,y+23),names[panel],HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#e2e7eb"))
        draw_line(Vector2(x+12,origin.y),Vector2(x+446,origin.y),Color("#82968e"),1)
        draw_line(Vector2(origin.x,y+32),origin,Color("#354b59"),1)
        var p:Dictionary=model.pose_at(tick,panel,synced)
        draw_set_transform(origin,0,Vector2(1.15,1.15))
        var c:Color=Color("#b4c5cf") if panel==1 else Color("#6daac8")
        if panel==1 or bones:_skeleton(p,panel==1,c)
        else:SOFT.draw(self,p,1,c)
        draw_set_transform(Vector2.ZERO)
