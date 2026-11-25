extends Node2D
const MODEL=preload("res://lab/anime/comparison.gd")
const SKIN=preload("res://game/smooth_skin.gd")
var model=MODEL.new()
var full_body:Array[Dictionary]=[]
var impact_clock:Array[int]=[]
const EXTRA_HOLD=[0,2,4,6] # additional 120 Hz ticks; only in replay C
var tick:float=0
var playing:bool=true
var speed:float=1.0
var bones:bool=false
var slider:HSlider
var info:Label
func _ready()->void:
    _build_study()
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
    info.text="N 0.10.3c  ·  %03d / 220  ·  %.0f мс  ·  %s  ·  %d/4  ·  %.1f×"%[int(tick),tick*1000/120,f.a.kind,f.hits,speed]
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
    var names:Array=["A  ·  0.10.3b авторская","B  ·  Постановка всего тела","C  ·  B + усиленный hitstop"]
    for variant in range(3):
        var y:float=66+157*variant
        var floor_y:float=y+143
        draw_rect(Rect2(10,y,940,149),Color("#213542"))
        draw_string(ThemeDB.fallback_font,Vector2(22,y+24),names[variant],HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#e2e7eb"))
        draw_line(Vector2(12,floor_y),Vector2(948,floor_y),Color("#82968e"),1)
        var source_tick:int=impact_clock[int(tick)] if variant==2 else int(tick)
        var sample_frame:Dictionary=model.record.frames[source_tick]
        var p:Dictionary=model.sample(source_tick,1) if variant==0 else full_body[source_tick]
        draw_set_transform(Vector2(10,floor_y-430),0,Vector2.ONE)
        if bones:
            _skeleton(p.a,Color("#6daac8"))
            _skeleton(p.b,Color("#c88b72"))
        else:
            SKIN.draw(self,p.a,int(sample_frame.a.face),Color("#6daac8"))
            SKIN.draw(self,p.b,int(sample_frame.b.face),Color("#c88b72"))
        draw_set_transform(Vector2.ZERO)

# 0.10.3c original authored hypothesis. Same world, positions, hits and support.
# Staging beats (120 Hz): jab/cross/hook load 0-4, drive 4-9, recover 9-19;
# kick chamber 3-12, extension 12-19, retraction 23-39. No measured reference timing.
# Local hip, shoulder and thigh depth are projection proxies, not a 3D rig.
func _staged_attacker(i:int,base:Dictionary)->Dictionary:
    var f:Dictionary=model.record.frames[i].a
    var p:Dictionary=base.duplicate(true)
    if f.age<0 or not f.kind in ["jab","cross","hook","finisher"]:return p
    var age:float=float(f.age)
    var kick:bool=f.kind=="finisher"
    var load:float=smoothstep(0.0,12.0 if kick else 4.0,age)*(1.0-smoothstep(12.0 if kick else 4.0,19.0 if kick else 9.0,age))
    var drive:float=smoothstep(12.0 if kick else 4.0,19.0 if kick else 9.0,age)*(1.0-smoothstep(23.0 if kick else 10.0,39.0 if kick else 19.0,age))
    var face:float=float(f.face)
    var twist:float=(load-drive)*(-1.0 if f.kind=="cross" else 1.0)
    var hip:Vector2=Vector2(base.hips)+Vector2((-4.0*load+(0.0 if kick else 3.0)*drive)*face,4.0*load-1.0*drive)
    # Projected hip/shoulder counter-rotation; endpoints stay authored.
    var hips_delta:Vector2=hip-Vector2(base.hips)
    p.hips=hip
    p.chest=Vector2(base.chest)+hips_delta*.65
    p.head=Vector2(base.head)+hips_delta*.4
    for j in range(2):
        var side:String="near" if j==0 else "far"
        var sign_side:float=1.0 if j==0 else -1.0
        var shoulder_key:String="shoulder_"+side
        var sh_delta:Vector2=hips_delta*.65+Vector2(4.0*twist*sign_side*face,-2.0*twist*sign_side)
        p[shoulder_key]=Vector2(base[shoulder_key])+sh_delta
        p["elbow_"+side]=Vector2(base["elbow_"+side])+sh_delta*.5
        # Endpoints retain the 0.10.3b strike / guard trajectory.
        var thigh:Vector2=hip+Vector2((3.0+3.0*twist)*sign_side*face,2.0*twist*sign_side)
        var foot:Vector2=base["foot_"+side]
        if f.support[j]:foot=f.points["foot_"+side]
        var d:Vector2=foot-thigh
        var length:float=d.length()
        var axis:Vector2=d.normalized() if length>.001 else Vector2.DOWN
        var normal:=Vector2(axis.y,-axis.x)*face
        # Author projected knee silhouettes with bounded bend. Rear leg braces,
        # lead leg compresses then extends; no sliding of planted ankle targets.
        var bend:float=sqrt(maxf(0.0,900.0-length*length*.25))
        var style:float=(1.0+0.18*load-0.18*drive) if j==0 else (1.0-0.18*load+0.12*drive)
        if kick and j==0:style=1.0+.12*load
        var knee:Vector2=thigh+d*.5+normal*minf(bend*style,29.0)
        p["thigh_"+side]=thigh
        p["knee_"+side]=knee
        p["foot_"+side]=foot
    # Preserve the real contact endpoint, even during the finisher.
    if model.record.frames[i].contact_event:p[f.strike]=f.points[f.strike]
    return p

func _build_study()->void:
    var max_leg:float=0.0
    for i in range(model.record.frames.size()):
        var frame:Dictionary=model.record.frames[i]
        var previous:Dictionary=model.sample(i,1)
        var p:Dictionary={"a":_staged_attacker(i,previous.a),"b":previous.b.duplicate(true)}
        if frame.frozen and i>0:p=full_body[-1].duplicate(true)
        full_body.append(p)
        if frame.contact_event and p.a[frame.a.strike]!=frame.a.points[frame.a.strike]:
            push_error("0.10.3c contact endpoint drift")
        if not frame.frozen:
            for j in range(2):
                var side:String="near" if j==0 else "far"
                if frame.a.support[j] and Vector2(p.a["foot_"+side]).distance_to(frame.a.points["foot_"+side])>.001:
                    push_error("0.10.3c support drift")
                max_leg=maxf(max_leg,Vector2(p.a["thigh_"+side]).distance_to(p.a["knee_"+side]))
                max_leg=maxf(max_leg,Vector2(p.a["knee_"+side]).distance_to(p.a["foot_"+side]))
        for fighter in ["a","b"]:
            for key in p[fighter]:
                if not Vector2(p[fighter][key]).is_finite():push_error("0.10.3c nonfinite pose")
    # Build deterministic retime map from source ticks and inserted duplicates.
    impact_clock.clear()
    for i in range(221):
        impact_clock.append(i)
        var c:int=model.contacts.find(i)
        if c>=0:
            for repeat in range(EXTRA_HOLD[c]):impact_clock.append(i)
    if impact_clock.size()!=233:push_error("0.10.3c unexpected retime length")
    if max_leg>40.0:push_error("0.10.3c visual leg exceeded 40 px limit")
    print("N 0.10.3c study: ",model.contacts," extra hold ",EXTRA_HOLD," max projected leg ",max_leg)
