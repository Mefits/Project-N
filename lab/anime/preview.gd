extends Node2D
const MODEL=preload("res://lab/anime/comparison.gd")
const SKIN=preload("res://game/smooth_skin.gd")
var model=MODEL.new()
var full_body:Array[Dictionary]=[]
var impact_clock:Array[int]=[]
var spatial:Array[Dictionary]=[]
const REF_REC=preload("res://lab/recording.gd")
const REF_RIG=preload("res://game/rig.gd")
var ref_record=REF_REC.new()
var ref_frames:Array[Dictionary]=[]
var ref_contact:int=-1
var lunge_hit:Dictionary={}
var lunge_miss:Dictionary={}
var combo_direct:Array[Dictionary]=[]
var combo_staged:Array[Dictionary]=[]
var combo_clock:Array[int]=[]
const OLD_SKIN=preload("res://game/fighter_skin.gd")
const EXTRA_HOLD=[0,2,4,6] # additional 120 Hz ticks; only in replay C
var tick:float=0
var playing:bool=true
var speed:float=1.0
var bones:bool=false
var slider:HSlider
var info:Label
func _ready()->void:
    _build_reference()
    _build_lunge()
    _build_reference_combo()
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
    info.text="N 0.10.3g  ·  %03d / 220  ·  %.0f мс  ·  Pain / solo choreography  ·  %.1f×"%[int(tick),tick*1000/120,speed]
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
    var names:Array=["A  ·  Перенос поз / плавно","B  ·  Те же позы / резкая постановка"]
    for variant in range(2):
        var y:float=66+235*variant
        var floor_y:float=y+218
        draw_rect(Rect2(10,y,940,229),Color("#213542"))
        draw_string(ThemeDB.fallback_font,Vector2(22,y+24),names[variant],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#e2e7eb"))
        draw_line(Vector2(12,floor_y),Vector2(948,floor_y),Color("#82968e"),1)
        var source_tick:int=combo_clock[int(tick)] if variant==1 else int(tick)
        var p:Dictionary=combo_staged[source_tick] if variant==1 else combo_direct[source_tick]
        var phase:String="Подготовка" if source_tick<24 else ("Выпад" if source_tick<=32 else ("Удар сверху" if source_tick<=52 else ("Разворот / удар ногой" if source_tick<=84 else "Приземление")))
        draw_string(ThemeDB.fallback_font,Vector2(620,y+24),phase,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#b6c6d0"))
        draw_set_transform(Vector2(10,floor_y-430),0,Vector2.ONE)
        if bones:_skeleton(p,Color("#6daac8"))
        else:SKIN.draw(self,p,1,Color("#6daac8"))
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

# 0.10.3e reference-only study. User supplied archive "2d anim ref.zip",
# NARUTO REF/54589.png, Kakashi, Naruto Shinobi Rumble (DS), sheet credit Floaj.
# Source crop in ORIGINAL pixels (0,810)-(490,910); first three cells;
# points below are visually estimated in the 3x enlarged crop. Fourth
# airborne pose is NOT part of this grounded test. No source pixels shipped.
# Source playback FPS unknown. Proposed N ages: 0 entry, 3 crouch, 6 load,
# actual recorded contact = extension, hold through actual hitstop, then recover.
const REF_NAMES=["hips","chest","head","shoulder_near","elbow_near","hand_near","shoulder_far","elbow_far","hand_far","thigh_near","knee_near","foot_near","thigh_far","knee_far","foot_far"]
const REF_RAW=[
    [Vector2(168,216),Vector2(166,175),Vector2(176,144),Vector2(146,177),Vector2(147,208),Vector2(159,253),Vector2(185,175),Vector2(190,200),Vector2(166,216),Vector2(175,218),Vector2(214,237),Vector2(211,278),Vector2(155,218),Vector2(106,238),Vector2(94,278)],
    [Vector2(545,216),Vector2(547,167),Vector2(565,132),Vector2(521,164),Vector2(518,198),Vector2(522,234),Vector2(563,163),Vector2(572,190),Vector2(541,192),Vector2(552,218),Vector2(581,238),Vector2(566,278),Vector2(533,218),Vector2(479,243),Vector2(450,278)],
    [Vector2(925,209),Vector2(962,171),Vector2(998,145),Vector2(979,168),Vector2(1030,168),Vector2(1082,168),Vector2(946,173),Vector2(915,178),Vector2(933,195),Vector2(938,214),Vector2(971,239),Vector2(951,276),Vector2(915,216),Vector2(867,243),Vector2(819,270)]
]
func _reference_key(k:int,f:Dictionary)->Dictionary:
    var raw:Array=REF_RAW[k]
    var origin:Vector2=Vector2((Vector2(raw[11]).x+Vector2(raw[14]).x)*.5,280.0)
    var p:Dictionary={}
    for n in range(REF_NAMES.size()):
        var v:Vector2=(Vector2(raw[n])-origin)*.65
        p[REF_NAMES[n]]=Vector2(f.pos)+Vector2(v.x*float(f.face),v.y)
    return p

func _mix_reference(a:Dictionary,b:Dictionary,u:float)->Dictionary:
    var p:Dictionary={}
    for k in a:p[k]=Vector2(a[k]).lerp(b[k],u)
    return p

func _reference_pose(f:Dictionary,contact_age:int)->Dictionary:
    var base:Dictionary=f.points
    if f.kind!="jab" or f.age<0:return base.duplicate(true)
    var a:float=float(f.age)
    var p0:Dictionary=_reference_key(0,f)
    var p1:Dictionary=_reference_key(1,f)
    var p2:Dictionary=_reference_key(2,f)
    var ca:float=float(contact_age)
    if a<=3.0:return _mix_reference(base,p0,smoothstep(0.0,3.0,a))
    if a<=6.0:return _mix_reference(p0,p1,smoothstep(3.0,6.0,a))
    if a<=ca:return _mix_reference(p1,p2,pow(clampf((a-6.0)/maxf(1.0,ca-6.0),0.0,1.0),2.0))
    return _mix_reference(p2,base,smoothstep(ca,ca+14.0,a))

func _adapt_reference(raw:Dictionary,f:Dictionary,i:int)->Dictionary:
    var base:Dictionary=f.points
    if f.kind!="jab" or f.age<0:return base.duplicate(true)
    var p:Dictionary=raw.duplicate(true)
    # Fit the raw silhouette to the true root and contact geometry, without
    # replacing it with the old pose. The exact planted feet are immutable.
    var face:float=float(f.face)
    var source_hand:Vector2=p[f.strike]
    var baseline_hand:Vector2=base[f.strike]
    var approach:float=1.0-smoothstep(0.0,4.0,absf(float(i-ref_contact)))
    var correction:Vector2=(baseline_hand-source_hand)*approach
    var hip_offset:Vector2=correction.limit_length(24.0)*.60
    for k in ["hips","chest","head","shoulder_near","shoulder_far","elbow_near","elbow_far","hand_near","hand_far","thigh_near","thigh_far"]:
        p[k]=Vector2(p[k])+hip_offset
    p[f.strike]=source_hand.lerp(baseline_hand,approach)
    # Retain the source knee/elbow direction, solve length using the actual
    # end target. 2D length may shorten through apparent depth.
    for j in range(2):
        var side:String="near" if j==0 else "far"
        var foot:String="foot_"+side
        var thigh:String="thigh_"+side
        var knee:String="knee_"+side
        if f.support[j]:p[foot]=base[foot]
        var d:Vector2=Vector2(p[foot])-Vector2(p[thigh])
        var bend:float=1.0 if d.cross(Vector2(p[knee])-Vector2(p[thigh]))>=0.0 else -1.0
        var leg:Array[Vector2]=REF_RIG.chain(p[thigh],p[foot],30.0,30.0,bend)
        p[knee]=leg[0]
        var sh:String="shoulder_"+side
        var el:String="elbow_"+side
        var hand:String="hand_"+side
        var arm_d:Vector2=Vector2(p[hand])-Vector2(p[sh])
        var arm_bend:float=1.0 if arm_d.cross(Vector2(p[el])-Vector2(p[sh]))>=0.0 else -1.0
        var arm:Array[Vector2]=REF_RIG.chain(p[sh],p[hand],22.0,23.0,arm_bend)
        p[el]=arm[0]
        if hand!=f.strike or i!=ref_contact:p[hand]=arm[1]
    # At the actual impact the exact endpoint remains non-negotiable.
    if i==ref_contact:p[f.strike]=base[f.strike]
    return p

func _build_reference()->void:
    ref_record.record("jab")
    var ca:int=10
    var hits:int=0
    for i in range(ref_record.frames.size()):
        if ref_record.frames[i].contact_event:
            ref_contact=i
            ca=int(ref_record.frames[i].a.age)
            hits+=1
    if hits!=1:push_error("Reference study expected one actual jab contact")
    var max_support:float=0.0
    var max_error:float=0.0
    var changed:int=0
    for i in range(ref_record.frames.size()):
        var frame:Dictionary=ref_record.frames[i]
        var f:Dictionary=frame.a
        var raw:Dictionary=_reference_pose(f,ca)
        var fitted:Dictionary=_adapt_reference(raw,f,i)
        if frame.frozen and i>0:
            raw=ref_frames[-1][1].a.duplicate(true)
            fitted=ref_frames[-1][2].a.duplicate(true)
        if not frame.frozen:
            for j in range(2):
                var side:String="near" if j==0 else "far"
                if f.support[j]:
                    max_support=maxf(max_support,Vector2(fitted["foot_"+side]).distance_to(f.points["foot_"+side]))
        for p in [raw,fitted]:
            for k in p:
                if not Vector2(p[k]).is_finite():push_error("Reference nonfinite joint")
        if frame.contact_event:max_error=Vector2(fitted[f.strike]).distance_to(f.points[f.strike])
        if fitted!=f.points:changed+=1
        ref_frames.append({0:{"a":f.points,"b":frame.b.points},1:{"a":raw,"b":frame.b.points},2:{"a":fitted,"b":frame.b.points}})
    if max_support>.001 or max_error>.001 or changed<10:push_error("Reference retarget constraint failure")
    print("N 0.10.3e reference: contact ",ref_contact," age ",ca," changed ",changed," support error ",max_support," contact error ",max_error)

# N 0.10.3f: independent deterministic lab attack. The original 0.10.3e B
# silhouettes are preserved as the main authority; no correction to old jab.
# Source frame times are unknown; 120 Hz timeline below is authored.
# 0-8 prepare, 8-13 coil, 13-23 acceleration / step, 23-29 follow through,
# 29-55 recover with two authored foot steps. Root travels 34 px and stays.
# Active window 18-24. Same swept torso radius (17 px) as World.
# Hitstop 10 ticks only on actual collision; no target snapping or auto-hit.
# This is a separate lab simulation, not a playable attack in World.
const LUNGE_TRAVEL=34.0
const LUNGE_FREEZE=10
const LUNGE_START=12

func _lunge_key(k:int,root_pos:Vector2,face:int)->Dictionary:
    return _reference_key(k,{"pos":root_pos,"face":face})

func _lunge_move(p:Dictionary,dx:Vector2)->Dictionary:
    var out:Dictionary={}
    for key in p:out[key]=Vector2(p[key])+dx
    return out

func _lunge_guard(origin:Vector2,face:int)->Dictionary:
    # Use the actual idle victim pose, mirrored if necessary.
    var source:Dictionary=ref_record.frames[0].b
    var out:Dictionary={}
    for key in source.points:
        var v:Vector2=Vector2(source.points[key])-Vector2(source.pos)
        out[key]=origin+Vector2(v.x*float(face)/float(source.face),v.y)
    return out

func _lunge_curve(age:int,start:Vector2,face:int)->Dictionary:
    var t:float=float(age)
    var drive:float=pow(clampf((t-13.0)/10.0,0.0,1.0),2.0)
    var shift:Vector2=Vector2(LUNGE_TRAVEL*drive*float(face),0)
    var k0:Dictionary=_lunge_key(0,start,face)
    var k1:Dictionary=_lunge_key(1,start,face)
    var k2:Dictionary=_lunge_key(2,start,face)
    var p:Dictionary
    if t<8.0:p=_mix_reference(k0,k1,smoothstep(0.0,8.0,t)*.65)
    elif t<13.0:p=_mix_reference(k0,k1,lerpf(.65,1.0,smoothstep(8.0,13.0,t)))
    elif t<=23.0:p=_mix_reference(k1,k2,drive)
    elif t<=29.0:p=k2.duplicate(true)
    else:p=_mix_reference(k2,k0,smoothstep(29.0,50.0,t))
    p=_lunge_move(p,shift)
    # Explicit stepping tracks. Feet hold on the floor before release and after
    # landing; knees follow the correction partly, preserving traced silhouette.
    for j in range(2):
        var side:String="near" if j==0 else "far"
        var key:String="foot_"+side
        var knee:String="knee_"+side
        var initial:Vector2=k0[key]
        var final:Vector2=Vector2(k2[key])+Vector2(LUNGE_TRAVEL*face,0)
        var rest:Vector2=Vector2(k0[key])+Vector2(LUNGE_TRAVEL*face,0)
        initial.y=start.y-2.0
        final.y=start.y-2.0
        rest.y=start.y-2.0
        var begin:float=13.0 if j==0 else 16.0
        var end:float=23.0 if j==0 else 25.0
        var recovery_begin:float=40.0 if j==0 else 30.0
        var recovery_end:float=53.0 if j==0 else 40.0
        var target:Vector2=initial
        if t>=begin:
            var u:float=clampf((t-begin)/(end-begin),0.0,1.0)
            target=initial.lerp(final,smoothstep(0.0,1.0,u))
            target.y-=sin(PI*u)*(9.0 if j==0 else 5.0)
        if t>=recovery_begin:
            var u:float=clampf((t-recovery_begin)/(recovery_end-recovery_begin),0.0,1.0)
            target=final.lerp(rest,smoothstep(0.0,1.0,u))
            target.y-=sin(PI*u)*6.0
        p[knee]=Vector2(p[knee])+(target-Vector2(p[key]))*.55
        p[key]=target
    return {"pose":p,"root":start+shift}

func _lunge_victim(base:Dictionary,elapsed:int,face:int)->Dictionary:
    if elapsed<=0:return base.duplicate(true)
    var t:float=float(elapsed)
    var slide:float=44.0*(1.0-pow(1.0-clampf(t/36.0,0.0,1.0),3.0))
    var recoil:float=smoothstep(0.0,5.0,t)*(1.0-smoothstep(11.0,32.0,t))
    var out:Dictionary=_lunge_move(base,Vector2(float(face)*slide,0))
    var pivot:Vector2=out.hips
    # Rotate the upper body away from incoming strike; leave feet on ground.
    for key in ["chest","head","shoulder_near","shoulder_far","elbow_near","elbow_far","hand_near","hand_far"]:
        out[key]=pivot+(Vector2(out[key])-pivot).rotated(deg_to_rad(38.0*recoil*float(face)))
    return out

func _lunge_sweep(previous:Vector2,current:Vector2,target:Dictionary)->float:
    var distance:float=INF
    for u in [0.0,.25,.5,.75,1.0]:
        var center:Vector2=Vector2(target.chest).lerp(target.hips,u)
        distance=minf(distance,center.distance_to(Geometry2D.get_closest_point_to_segment(center,previous,current)))
    return distance

func _simulate_lunge(gap:float,face:int)->Dictionary:
    var start:=Vector2(400.0 if face==1 else 560.0,430.0)
    var target_origin:Vector2=start+Vector2(gap*face,0)
    var target:Dictionary=_lunge_guard(target_origin,-face)
    var frames:Array[Dictionary]=[]
    var age:int=0
    var freeze:int=0
    var hit_tick:int=-1
    var hit_age:int=-1
    var after:int=0
    var previous:Vector2=_lunge_curve(0,start,face).pose.hand_near
    var hit_distance:float=-1.0
    var hold_count:int=0
    var max_step:float=0.0
    var previous_root:Vector2=start
    for i in range(221):
        var frozen:bool=freeze>0
        if frozen:
            var copy:Dictionary=frames[-1].duplicate(true)
            copy.frozen=true
            frames.append(copy)
            freeze-=1
            hold_count+=1
            continue
        var sample:Dictionary=_lunge_curve(age,start,face)
        var p:Dictionary=sample.pose
        var root_pos:Vector2=sample.root
        var b:Dictionary=_lunge_victim(target,after,face)
        if i>=LUNGE_START and age>=18 and age<=24 and hit_tick<0:
            var dist:float=_lunge_sweep(previous,p.hand_near,b)
            if dist<=17.0 and (target_origin.x-root_pos.x)*face>=38.0:
                hit_tick=i
                hit_age=age
                hit_distance=dist
                freeze=LUNGE_FREEZE
        frames.append({"a":p,"b":b,"root":root_pos,"hits":int(hit_tick>=0),"frozen":false,"age":age})
        if hit_tick>=0 and i>hit_tick:after+=1
        elif hit_tick==i:after=1
        max_step=maxf(max_step,root_pos.distance_to(previous_root))
        previous_root=root_pos
        previous=p.hand_near
        if i>=LUNGE_START:age=mini(age+1,55)
    return {"frames":frames,"hit":hit_tick,"age":hit_age,"distance":hit_distance,"hold":hold_count,"max_step":max_step}

func _build_lunge()->void:
    lunge_hit=_simulate_lunge(170.0,1)
    lunge_miss=_simulate_lunge(230.0,1)
    var mirror:Dictionary=_simulate_lunge(170.0,-1)
    var mirror_miss:Dictionary=_simulate_lunge(230.0,-1)
    if lunge_hit.hit<0 or lunge_miss.hit>=0 or mirror_miss.hit>=0 or mirror.age!=lunge_hit.age:
        push_error("Lunge hit/miss/mirror regression")
    if lunge_hit.hold!=LUNGE_FREEZE or lunge_miss.hold!=0 or mirror.hold!=LUNGE_FREEZE:
        push_error("Lunge hitstop regression")
    for trial in [lunge_hit,lunge_miss,mirror,mirror_miss]:
        if trial.max_step>7.0:push_error("Lunge root discontinuity")
        for frame in trial.frames:
            for fighter in ["a","b"]:
                for key in frame[fighter]:
                    if not Vector2(frame[fighter][key]).is_finite():push_error("Lunge nonfinite joint")
            for side in ["near","far"]:
                if Vector2(frame.a["foot_"+side]).y>430.001:push_error("Lunge floor violation")
        if trial.hit>=0:
            var hit_frame:Dictionary=trial.frames[trial.hit]
            for i in range(1,LUNGE_FREEZE+1):
                var frozen_frame:Dictionary=trial.frames[trial.hit+i]
                if frozen_frame.a!=hit_frame.a or frozen_frame.b!=hit_frame.b:push_error("Lunge frozen pose changed")
    print("N 0.10.3f lunge: hit tick ",lunge_hit.hit," age ",lunge_hit.age," distance ",lunge_hit.distance," whiff ",lunge_miss.hit," mirrored ",mirror.age," hold ",lunge_hit.hold," root max step ",lunge_hit.max_step)

# 0.10.3g, source-only reference: user archive 2d anim ref.zip, 54569.png
# Pain, Naruto Shinobi Rumble, sheet ripped by ShadeDBZ.
# Original sheet y=458..610; second row, ten cells, x=0..1039.
# Visually estimated joints in a 2x crop, local to each cell. Smear cells 1
# and 8 omitted; cell 4 included as approximate downswing, obscured joints
# estimated under cloak. Attack labels are our interpretation, not extracted
# move names. The user identified 0.10.3e/f as CHIDORI; preserve it separately.
# Source FPS and exact displacement unknown. Timeline, root path, landing,
# and hold lengths authored for N. No source pixels or VFX in this study.
# This is SOLO choreography: accents are not gameplay hitstop, no hit claims.
# Joint order is REF_NAMES. Hip-relative normalization preserves silhouette.
const PAIN_KEYS=[
    [[73,85],[62,54],[59,20],[70,52],[99,64],[93,57],[53,48],[29,36],[44,37],[76,85],[88,105],[78,130],[65,86],[65,104],[42,128]],
    [[75,87],[102,61],[111,36],[113,56],[133,55],[154,56],[95,62],[85,76],[74,72],[78,87],[87,104],[51,104],[67,87],[46,105],[19,115]],
    [[66,87],[82,55],[94,27],[86,53],[103,72],[108,66],[75,48],[57,64],[72,75],[75,88],[88,105],[66,131],[60,85],[56,109],[62,123]],
    [[75,94],[99,61],[113,43],[102,59],[116,72],[119,94],[91,52],[67,44],[62,54],[80,96],[79,117],[62,112],[70,94],[58,111],[42,125]],
    [[82,78],[91,56],[106,46],[93,59],[99,83],[89,104],[86,51],[76,27],[57,30],[83,80],[73,109],[55,119],[74,80],[56,111],[36,134]],
    [[63,82],[68,51],[64,22],[72,49],[81,28],[65,15],[59,48],[53,67],[64,72],[68,83],[82,95],[72,97],[57,84],[52,109],[35,132]],
    [[64,78],[55,49],[38,31],[62,48],[83,49],[93,66],[49,48],[43,66],[15,68],[68,82],[80,95],[64,107],[57,83],[48,112],[45,137]],
    [[54,85],[43,56],[32,30],[43,48],[51,68],[39,77],[31,47],[16,67],[15,49],[58,82],[88,63],[122,48],[51,88],[40,109],[57,116]]
]
# tick, source key (-1 guard), authored hip root in px, curve type to this key.
# Three linked motions; gather poses are outgoing poses, not idle resets.
const COMBO_BEATS=[
    [0,-1,Vector2(365,379),0],
    [12,-1,Vector2(365,379),0],
    [24,0,Vector2(391,359),0],
    [32,1,Vector2(438,335),1],
    [42,2,Vector2(460,326),0],
    [48,3,Vector2(477,328),1],
    [52,4,Vector2(489,335),1],
    [60,5,Vector2(502,337),0],
    [68,6,Vector2(518,341),0],
    [76,7,Vector2(552,348),1],
    [82,7,Vector2(557,355),0],
    [96,2,Vector2(575,372),0],
    [112,-1,Vector2(585,379),0],
    [220,-1,Vector2(585,379),0]
]
const COMBO_ACCENTS={32:4,52:6,76:8}

func _combo_key(index:int,root_pos:Vector2)->Dictionary:
    var p:Dictionary={}
    if index<0:
        var source:Dictionary=ref_record.frames[0].a.points
        var offset:Vector2=Vector2(root_pos.x,430.0)-Vector2(ref_record.frames[0].a.pos)
        for k in source:p[k]=Vector2(source[k])+offset
        return p
    var raw:Array=PAIN_KEYS[index]
    var origin:=Vector2(float(raw[0][0]),float(raw[0][1]))
    for n in range(REF_NAMES.size()):
        var q:=Vector2(float(raw[n][0]),float(raw[n][1]))
        p[REF_NAMES[n]]=root_pos+(q-origin)*.90
    return p

func _combo_pose(t:int,staged:bool)->Dictionary:
    for n in range(1,COMBO_BEATS.size()):
        var a:Array=COMBO_BEATS[n-1]
        var b:Array=COMBO_BEATS[n]
        if t>int(b[0]):continue
        var u:float=clampf(float(t-int(a[0]))/float(int(b[0])-int(a[0])),0,1)
        var curve:float=smoothstep(0.0,1.0,u)
        if staged and int(b[3])==1:
            # Preserve the load, then sharply accelerate into the contact shape.
            curve=pow(u,2.15)
        var p:Dictionary=_mix_reference(_combo_key(int(a[1]),a[2]),_combo_key(int(b[1]),b[2]),curve)
        return p
    return _combo_key(-1,Vector2(585,379))

func _build_reference_combo()->void:
    var max_delta:float=0.0
    var changed:int=0
    var floor_error:float=0.0
    for t in range(221):
        var a:Dictionary=_combo_pose(t,false)
        var b:Dictionary=_combo_pose(t,true)
        combo_direct.append(a)
        combo_staged.append(b)
        if a!=b:changed+=1
        for p in [a,b]:
            for key in p:
                if not Vector2(p[key]).is_finite():push_error("Combo nonfinite joint")
            for side in ["near","far"]:
                floor_error=maxf(floor_error,Vector2(p["foot_"+side]).y-430.0)
        if t>0:
            for key in b:
                max_delta=maxf(max_delta,Vector2(b[key]).distance_to(combo_staged[t-1][key]))
        combo_clock.append(t)
        for repeat in range(int(COMBO_ACCENTS.get(t,0))):combo_clock.append(t)
    # Check original pose preservation and deterministic visual holds.
    for beat in COMBO_BEATS:
        var expected:Dictionary=_combo_key(int(beat[1]),beat[2])
        var t:int=int(beat[0])
        for key in expected:
            if Vector2(combo_direct[t][key]).distance_to(expected[key])>.001 or Vector2(combo_staged[t][key]).distance_to(expected[key])>.001:push_error("Combo key drift")
    for beat in COMBO_ACCENTS:
        var count:int=combo_clock.count(beat)
        if count!=int(COMBO_ACCENTS[beat])+1:push_error("Combo accent hold count")
    if combo_clock.size()!=239 or changed<10 or floor_error>.01 or max_delta>45.0:push_error("Combo continuity / floor / cadence")
    print("N 0.10.3g solo combo: 8 reference poses, 3 linked strikes; accents ",COMBO_ACCENTS," staged frames changed ",changed," max point step ",max_delta," floor error ",floor_error)
