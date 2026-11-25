extends Node2D
const MODEL=preload("res://lab/anime/comparison.gd")
const SKIN=preload("res://game/smooth_skin.gd")
var model=MODEL.new()
var full_body:Array[Dictionary]=[]
var impact_clock:Array[int]=[]
var spatial:Array[Dictionary]=[]
const OLD_SKIN=preload("res://game/fighter_skin.gd")
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
    info.text="N 0.10.3d  ·  %03d / 220  ·  %.0f мс  ·  %s  ·  %d/4  ·  %.1f×"%[int(tick),tick*1000/120,f.a.kind,f.hits,speed]
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
    var names:Array=["A  ·  0.10.3c / 2D","B  ·  3D-скелет / проекция","C  ·  3D + усиленный hitstop"]
    for variant in range(3):
        var y:float=66+157*variant
        var floor_y:float=y+143
        draw_rect(Rect2(10,y,940,149),Color("#213542"))
        draw_string(ThemeDB.fallback_font,Vector2(22,y+24),names[variant],HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#e2e7eb"))
        draw_line(Vector2(12,floor_y),Vector2(948,floor_y),Color("#82968e"),1)
        var source_tick:int=impact_clock[int(tick)] if variant==2 else int(tick)
        var sample_frame:Dictionary=model.record.frames[source_tick]
        var p:Dictionary=full_body[source_tick] if variant==0 else spatial[source_tick]
        draw_set_transform(Vector2(10,floor_y-430),0,Vector2.ONE)
        if bones:
            _skeleton(p.a,Color("#6daac8"))
            _skeleton(p.b,Color("#c88b72"))
        elif variant==0:
            SKIN.draw(self,p.a,int(sample_frame.a.face),Color("#6daac8"))
            SKIN.draw(self,p.b,int(sample_frame.b.face),Color("#c88b72"))
        else:
            _depth_skin(p.a,p.za,int(sample_frame.a.face),Color("#6daac8"))
            _depth_skin(p.b,p.zb,int(sample_frame.b.face),Color("#c88b72"))
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
    _build_spatial()

# N 0.10.3d: original 3D reconstruction experiment; not measured mocap.
# X is arena horizontal, Y down, Z toward the camera. Orthographic projection
# keeps X/Y contact and floor anchors identical. Yaw keys are authored.
# The same 2D skin is projected and depth-sorted, not a replacement art pipeline.
func _lift(p:Vector2,z:float=0.0)->Vector3:
    return Vector3(p.x,p.y,z)

func _project(p:Vector3)->Vector2:
    return Vector2(p.x,p.y)

func _yaw_keys(kind:String,age:int)->Vector2:
    if age<0:return Vector2(25,15)
    var keys:Array
    match kind:
        "jab":keys=[[0,25,15],[4,-34,-12],[7,54,34],[10,68,39],[18,25,15]]
        "cross":keys=[[0,25,15],[4,70,42],[7,-28,-15],[10,-66,-35],[18,25,15]]
        "hook":keys=[[0,25,15],[4,-72,-40],[7,-26,-14],[10,82,48],[18,25,15]]
        "finisher":keys=[[0,25,15],[6,-24,-12],[12,55,30],[19,68,42],[29,35,25],[45,25,15]]
        _:return Vector2(25,15)
    for n in range(1,keys.size()):
        if age<=int(keys[n][0]):
            var a:Array=keys[n-1]
            var b:Array=keys[n]
            var u:float=smoothstep(float(a[0]),float(b[0]),float(age))
            return Vector2(lerpf(float(a[1]),float(b[1]),u),lerpf(float(a[2]),float(b[2]),u))
    return Vector2(25,15)

# Spatial two-bone solve. The 2D target stays fixed; if the old authored
# target is unreachable at nominal length, explicitly allow minimal stretch.
# The bend guide is an authored 3D direction, not a simulated spring.
func _joint3(a:Vector3,b:Vector3,guide:Vector3,l1:float,l2:float)->Vector3:
    var delta:Vector3=b-a
    var d:float=maxf(delta.length(),.001)
    var axis:Vector3=delta/d if delta.length()>.001 else Vector3.DOWN
    var scale:float=maxf(1.0,d/(l1+l2-.01))
    l1*=scale
    l2*=scale
    var along:float=(l1*l1-l2*l2+d*d)/(2.0*d)
    along=clampf(along,-l1,l1)
    var h:float=sqrt(maxf(0.0,l1*l1-along*along))
    var bend:Vector3=guide-a
    bend-=axis*bend.dot(axis)
    if bend.length_squared()<.001:bend=axis.cross(Vector3.FORWARD)
    if bend.length_squared()<.001:bend=axis.cross(Vector3.RIGHT)
    return a+axis*along+bend.normalized()*h

func _spatial_pose(base:Dictionary,f:Dictionary,attacker:bool)->Dictionary:
    var yaw:Vector2=_yaw_keys(f.kind,f.age) if attacker else Vector2(25.0,15.0)
    if not attacker and f.hurt>0:
        yaw.x=clampf(25.0+float(f.reaction.x)*1.1,-65.0,75.0)
        yaw.y=yaw.x*.5
    var face:float=float(f.face)
    var chest:Vector3=_lift(base.chest)
    var hip:Vector3=_lift(base.hips)
    var points:Dictionary={"hips":hip,"chest":chest,"head":_lift(base.head,2.0)}
    for j in range(2):
        var side:String="near" if j==0 else "far"
        var sign_side:float=1.0 if j==0 else -1.0
        var shoulder:Vector3=chest+Vector3(0,2,11*sign_side).rotated(Vector3.UP,deg_to_rad(yaw.x)*face)
        var thigh:Vector3=hip+Vector3(0,0,7*sign_side).rotated(Vector3.UP,deg_to_rad(yaw.y)*face)
        var hand:Vector3=_lift(base["hand_"+side],6.0*sign_side)
        var foot:Vector3=_lift(base["foot_"+side],7.0*sign_side)
        if attacker and f.age>=0:
            var striking:bool=f.strike=="hand_"+side
            if striking:
                # An extended blow returns to the target plane; a coiled
                # elbow starts wide in depth and sweeps inward through delivery.
                var drive:float=smoothstep(3.0,9.0,float(f.age))
                hand.z=lerpf(12.0*sign_side,0.0,drive)
            if f.kind=="finisher" and j==0:
                foot.z=lerpf(13.0,0.0,smoothstep(11.0,19.0,float(f.age)))
        if f.support[j]:foot=_lift(f.points["foot_"+side],7.0*sign_side)
        var elbow_guide:Vector3=_lift(base["elbow_"+side],shoulder.z+sign_side*13.0)
        var knee_guide:Vector3=_lift(base["knee_"+side],thigh.z+sign_side*5.0)
        points["shoulder_"+side]=shoulder
        points["elbow_"+side]=_joint3(shoulder,hand,elbow_guide,22.0,23.0)
        points["hand_"+side]=hand
        points["thigh_"+side]=thigh
        points["knee_"+side]=_joint3(thigh,foot,knee_guide,30.0,30.0)
        points["foot_"+side]=foot
    return points

func _build_spatial()->void:
    var changed:int=0
    var max_depth:float=0.0
    var max_arm:float=0.0
    var max_leg:float=0.0
    var reversed:int=0
    for i in range(full_body.size()):
        var frame:Dictionary=model.record.frames[i]
        if frame.frozen and i>0:
            spatial.append(spatial[-1].duplicate(true))
            continue
        var a:Dictionary=_spatial_pose(full_body[i].a,frame.a,true)
        var b:Dictionary=_spatial_pose(full_body[i].b,frame.b,false)
        var out:Dictionary={"a":{},"b":{},"za":{},"zb":{}}
        for fighter in ["a","b"]:
            var q:Dictionary=a if fighter=="a" else b
            var zkey:String="za" if fighter=="a" else "zb"
            for key in q:
                var v:Vector3=q[key]
                if not v.is_finite():push_error("Spatial nonfinite")
                out[fighter][key]=_project(v)
                out[zkey][key]=v.z
                max_depth=maxf(max_depth,absf(v.z))
            for j in range(2):
                var side:String="near" if j==0 else "far"
                if frame[fighter].support[j] and Vector2(out[fighter]["foot_"+side]).distance_to(frame[fighter].points["foot_"+side])>.001:push_error("Spatial support drift")
                max_arm=maxf(max_arm,maxf(Vector3(q["shoulder_"+side]).distance_to(q["elbow_"+side]),Vector3(q["elbow_"+side]).distance_to(q["hand_"+side])))
                max_leg=maxf(max_leg,maxf(Vector3(q["thigh_"+side]).distance_to(q["knee_"+side]),Vector3(q["knee_"+side]).distance_to(q["foot_"+side])))
            if float(out[zkey]["elbow_far"])>float(out[zkey]["elbow_near"]):reversed+=1
        if frame.contact_event and Vector2(out.a[frame.a.strike]).distance_to(frame.a.points[frame.a.strike])>.001:push_error("Spatial contact drift")
        if out.a!=full_body[i].a:changed+=1
        spatial.append(out)
    if changed<50 or max_depth<10.0:push_error("Spatial study insufficient motion")
    print("N 0.10.3d spatial: contacts ",model.contacts," changed ",changed," depth ",max_depth," arm max ",max_arm," leg max ",max_leg," depth order switches ",reversed)

func _depth_skin(p:Dictionary,z:Dictionary,face:int,accent:Color)->void:
    var layers:Array=[]
    for side in ["near","far"]:
        layers.append({"kind":"arm","side":side,"z":(float(z["shoulder_"+side])+float(z["elbow_"+side])+float(z["hand_"+side]))/3.0})
        layers.append({"kind":"leg","side":side,"z":(float(z["thigh_"+side])+float(z["knee_"+side])+float(z["foot_"+side]))/3.0})
    layers.append({"kind":"body","side":"","z":0.0})
    layers.append({"kind":"head","side":"","z":1.0})
    layers.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.z)<float(b.z))
    for layer in layers:
        var shade:float=clampf(-float(layer.z)/65.0,0.0,.29)
        match layer.kind:
            "arm":SKIN.arm(self,p,layer.side,face,accent,shade)
            "leg":SKIN.leg(self,p,layer.side,face,accent,shade)
            "body":SKIN.body(self,p,face,accent)
            "head":OLD_SKIN.head(self,p,face,accent)
