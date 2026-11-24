extends Node2D
const MODEL=preload("res://lab/anime/comparison.gd")
const SKIN=preload("res://game/smooth_skin.gd")
var model=MODEL.new()
var tick:float=0
var playing:bool=true
var speed:float=1.0
var bones:bool=false
var slider:HSlider
var info:Label
func _ready()->void:
    var bar:=HBoxContainer.new()
    bar.position=Vector2(12,8)
    add_child(bar)
    _button(bar,"Пуск / пауза",func():playing=not playing)
    _button(bar,"-1",func():playing=false;seek(tick-1))
    _button(bar,"+1",func():playing=false;seek(tick+1))
    _button(bar,"Начало",func():playing=false;seek(0))
    _button(bar,"1× / 0.5×",func():speed=.5 if speed==1.0 else 1.0;seek(tick))
    _button(bar,"Скелет / облик",func():bones=not bones;queue_redraw())
    _button(bar,"Лаборатория",func():get_tree().change_scene_to_file("res://lab/animation_lab.tscn"))
    info=Label.new()
    info.position=Vector2(12,40)
    info.add_theme_font_size_override("font_size",12)
    add_child(info)
    slider=HSlider.new()
    slider.position=Vector2(520,40)
    slider.size=Vector2(420,20)
    slider.max_value=220
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
    tick=clampf(t,0,220)
    slider.set_value_no_signal(tick)
    var f:Dictionary=model.record.frames[int(tick)]
    info.text="N 0.10.3a  ·  %03d / 220  ·  %.0f мс  ·  %s  ·  %d/4  ·  %.1f×"%[int(tick),tick*1000/120,f.a.kind,f.hits,speed]
    queue_redraw()
func _process(dt:float)->void:
    if playing:seek(fposmod(tick+120*dt*speed,221))
func _skeleton(p:Dictionary,c:Color)->void:
    var links:Array=[["hips","chest"],["chest","head"]]
    for s in ["near","far"]:
        links.append_array([["chest","shoulder_"+s],["shoulder_"+s,"elbow_"+s],["elbow_"+s,"hand_"+s],["hips","thigh_"+s],["thigh_"+s,"knee_"+s],["knee_"+s,"foot_"+s]])
    for l in links:draw_line(p[l[0]],p[l[1]],c,2,true)
    for k in p:draw_circle(p[k],2.5,c)
func _draw()->void:
    draw_rect(Rect2(0,0,960,540),Color("#172632"))
    var names:Array=["A  ·  Текущий гибрид","B  ·  Авторская анимация","C  ·  B + вторичное движение"]
    var f:Dictionary=model.record.frames[int(tick)]
    for variant in range(3):
        var y:float=66+157*variant
        var floor_y:float=y+143
        draw_rect(Rect2(10,y,940,149),Color("#213542"))
        draw_string(ThemeDB.fallback_font,Vector2(22,y+24),names[variant],HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#e2e7eb"))
        draw_line(Vector2(12,floor_y),Vector2(948,floor_y),Color("#82968e"),1)
        var p:Dictionary=model.sample(int(tick),variant)
        draw_set_transform(Vector2(10,floor_y-430),0,Vector2.ONE)
        if bones:
            _skeleton(p.a,Color("#6daac8"))
            _skeleton(p.b,Color("#c88b72"))
        else:
            SKIN.draw(self,p.a,int(f.a.face),Color("#6daac8"))
            SKIN.draw(self,p.b,int(f.b.face),Color("#c88b72"))
        draw_set_transform(Vector2.ZERO)
