extends RefCounted
## Three authored attacks, basic guard/parry and bounded spring reaction. Fixed 120 Hz.
const REACTION=preload("res://game/impact_reaction.gd")
const KICK=preload("res://game/kick_pose.gd")
const CHAIN=preload("res://game/chain_pose.gd")
const LAUNCH=preload("res://game/launch_pose.gd")
const AIR=preload("res://game/air_pose.gd")
const BUFFER_TICKS=22
const BLEND_TICKS=5
const HEAVY_DURATION=58
const HEAVY_ACTIVE_FROM=18
const HEAVY_ACTIVE_TO=26
const HEAVY_DAMAGE=25
const HEAVY_KNOCKBACK=235.0
const HEAVY_HURT=50
const HEAVY_HITSTOP=10
const DURATION=36
const ACTIVE_FROM=9
const ACTIVE_TO=17
const HURT_TICKS=26
const DAMAGE=10
const KNOCKBACK=145.0
const HITSTOP=6
# tick, blend, hip x/y, chest angle, lead/rear wrist relative to shoulder
# Martial Arts jab right-facing row: compact start, extension, hold, recovery.
const KEYS=[
    [0,0.0,0.0,-50.0,0.0,Vector2(20,0),Vector2(7,10)],
    [7,1.0,-3.0,-49.0,-5.0,Vector2(14,5),Vector2(9,7)],
    [12,1.0,4.0,-51.0,12.0,Vector2(40,-1),Vector2(9,6)],
    [15,1.0,7.0,-51.0,17.0,Vector2(44,-2),Vector2(8,5)],
    [22,1.0,6.0,-51.0,14.0,Vector2(43,-1),Vector2(8,6)],
    [32,1.0,2.0,-50.0,6.0,Vector2(25,5),Vector2(7,10)],
    [48,0.0,0.0,-50.0,0.0,Vector2(20,0),Vector2(7,10)]
]
# Heavy uses the rear fist, compact preparation, full torso drive and longer recovery.
const HEAVY_KEYS=[
    [0,0.0,0.0,-50.0,0.0,Vector2(20,0),Vector2(7,10)],
    [10,1.0,-5.0,-48.0,-12.0,Vector2(17,2),Vector2(-12,9)],
    [20,1.0,-1.0,-49.0,-4.0,Vector2(17,5),Vector2(3,8)],
    [24,1.0,6.0,-51.0,19.0,Vector2(10,9),Vector2(42,-2)],
    [29,1.0,9.0,-51.0,28.0,Vector2(6,10),Vector2(44,-3)],
    [36,1.0,7.0,-50.0,23.0,Vector2(8,10),Vector2(42,0)],
    [51,1.0,1.0,-49.0,8.0,Vector2(17,5),Vector2(20,13)],
    [80,0.0,0.0,-50.0,0.0,Vector2(20,0),Vector2(7,10)]
]
const PARRY_WINDOW=10
const PARRY_STUN=36
const PARRY_FREEZE=9
const BLOCK_FREEZE=4
var guard_held:bool=false
var guard_edge:bool=false
var guarding:bool=false
var guard_blend:float=0
var parry_left:int=0
var blockstun:int=0
var reaction=REACTION.new()
var kind:String="jab"
var heavy_latch:bool=false
var kick_latch:bool=false
var kick_pending:int=0
var queued_kind:String="jab"
var hurt_total:int=HURT_TICKS
var hurt_heavy:bool=false
var hurt_style:String=""
var finish_pending:int=0
var launch_requested:bool=false
var launch_buffer:bool=false
var age:int=-1
var hurt:int=0
var hp:int=100
var attacks:int=0
var connected:bool=false
var contact_hit:bool=false
var chain_buffer:int=0
var chain_count:int=0
var peak_chain:int=0
var transition_pose:Dictionary={}
var latch:bool=false
var queued:bool=false
func capture(pressed:bool,heavy:bool=false,kick:bool=false,guard:bool=false,launch:bool=false)->void:
    if guard and not guard_held:guard_edge=true
    guard_held=guard
    if kick and not kick_latch:
        queued=true
        queued_kind="kick"
    elif heavy and not heavy_latch:
        queued=true
        queued_kind="heavy"
    elif pressed and not latch:
        queued=true
        queued_kind="jab"
        launch_requested=launch
    latch=pressed
    heavy_latch=heavy
    kick_latch=kick
func airborne_attack()->bool:return kind in ["air_approach","air_jab","air_cross","air_slam"] and age>=0
func start_pursuit(m)->void:
    transition_pose=_attack_pose()
    kind="air_approach"
    age=0
    connected=false
    contact_hit=false
    chain_buffer=0
    m.pursuit_jump()
func duration()->int:
    if kind=="air_approach":return AIR.APPROACH
    if kind in ["air_jab","air_cross"]:return AIR.STRIKE
    if kind=="air_slam":return AIR.SLAM
    if kind=="launcher":return LAUNCH.DURATION
    if kind in ["cross","hook"]:return CHAIN.DURATION
    if kind=="finisher":return 56
    if kind=="kick":return KICK.DURATION
    return HEAVY_DURATION if kind=="heavy" else DURATION
func fist()->String:
    if kind in ["kick","finisher"]:return "foot_near"
    return "hand_far" if kind in ["heavy","cross","air_cross"] else "hand_near"
func contact_point(rig,face:int)->Vector2:
    var p:Vector2=rig.points[fist()]
    # Kick reaches the visible forefoot, rather than the ankle joint alone.
    if kind in ["kick","finisher"]:p.x+=9*face
    return p
func kicking()->bool:return kind in ["kick","finisher"] and age>=0
func profile()->Dictionary:
    if kind=="air_jab":return {"damage":8,"knockback":65.0,"hurt":100,"freeze":4,"strength":.9,"heavy":false,"style":"air_jab","juggle":-125.0}
    if kind=="air_cross":return {"damage":9,"knockback":75.0,"hurt":100,"freeze":5,"strength":1.1,"heavy":false,"style":"air_cross","juggle":-100.0}
    if kind=="air_slam":return {"damage":18,"knockback":110.0,"hurt":100,"freeze":8,"strength":1.8,"heavy":true,"style":"air_slam","slam":650.0}
    if kind=="launcher":return {"damage":LAUNCH.DAMAGE,"knockback":100.0,"hurt":116,"freeze":8,"strength":1.65,"heavy":true,"style":"launcher","lift":LAUNCH.LIFT}
    if kind=="cross":return {"damage":9,"knockback":85.0,"hurt":32,"freeze":4,"strength":.85,"heavy":false,"style":"cross"}
    if kind=="hook":return {"damage":16,"knockback":70.0,"hurt":48,"freeze":7,"strength":1.3,"heavy":true,"style":"hook"}
    if kind=="finisher":return {"damage":24,"knockback":260.0,"hurt":50,"freeze":9,"strength":2.1,"heavy":true,"style":"finisher"}
    if kind=="kick":return {"damage":KICK.DAMAGE,"knockback":KICK.KNOCKBACK,"hurt":KICK.HURT,"freeze":KICK.HITSTOP,"strength":1.6,"heavy":true}
    return {"damage":HEAVY_DAMAGE,"knockback":HEAVY_KNOCKBACK,"hurt":HEAVY_HURT,"freeze":HEAVY_HITSTOP,"strength":2.0,"heavy":true} if kind=="heavy" else {"damage":DAMAGE,"knockback":KNOCKBACK,"hurt":HURT_TICKS,"freeze":HITSTOP,"strength":1.0,"heavy":false}
func tick(m)->void:
    reaction.step()
    if hurt>0:hurt-=1
    if airborne_attack() and (m.grounded or not m.pursuing):
        age=-1
        chain_buffer=0
        chain_count=0
        transition_pose={}
        queued=false
    if chain_buffer>0:chain_buffer-=1
    if finish_pending>0:finish_pending-=1
    if age>=0:
        age+=1
        if age>=duration() and finish_pending>0:age=duration()-1
        elif age>=duration():
            age=-1
            chain_count=0
            chain_buffer=0
            launch_buffer=false
            transition_pose={}
    if airborne_attack() and queued and queued_kind=="jab":
        chain_buffer=BUFFER_TICKS
        queued=false
    if airborne_attack() and chain_buffer>0 and hurt==0 and hp>0 and ((kind=="air_approach" and age>=6) or (kind in ["air_jab","air_cross"] and contact_hit and age>=AIR.CANCEL)):
        transition_pose=_attack_pose()
        kind="air_jab" if kind=="air_approach" else ("air_cross" if kind=="air_jab" else "air_slam")
        age=0
        connected=false
        contact_hit=false
        chain_buffer=0
        chain_count+=1
        peak_chain=maxi(peak_chain,chain_count)
        attacks+=1
    if queued and queued_kind=="jab" and kind in ["jab","cross","hook"] and age>=0 and hurt==0:
        chain_buffer=BUFFER_TICKS
        launch_buffer=kind=="hook" and launch_requested
        queued=false
    var cancel:int=19 if kind=="jab" else CHAIN.CANCEL_FROM
    if kind=="hook" and age>=cancel and chain_buffer>0 and contact_hit and hurt==0 and hp>0:
        if launch_buffer:
            transition_pose=_attack_pose()
            kind="launcher"
            age=0
            connected=false
            contact_hit=false
            chain_count=4
            peak_chain=maxi(peak_chain,chain_count)
            attacks+=1
            finish_pending=0
        elif finish_pending==0:finish_pending=40
        launch_buffer=false
        chain_buffer=0
    if finish_pending>0 and kind=="hook" and age>=0 and hurt==0 and m.grounded and m.swing<0 and absf(m.velocity.x)<=20:
        transition_pose=_attack_pose()
        kind="finisher"
        age=0
        connected=false
        contact_hit=false
        chain_count=4
        peak_chain=maxi(peak_chain,chain_count)
        attacks+=1
        finish_pending=0
    if age>=cancel and chain_buffer>0 and contact_hit and kind in ["jab","cross"] and hurt==0 and hp>0:
        transition_pose=_attack_pose()
        kind="cross" if kind=="jab" else "hook"
        age=0
        connected=false
        contact_hit=false
        chain_buffer=0
        chain_count+=1
        peak_chain=maxi(peak_chain,chain_count)
        attacks+=1

    if blockstun>0:blockstun-=1
    if parry_left>0:parry_left-=1
    var eligible:bool=m.grounded and age<0 and hurt==0 and hp>0
    guarding=eligible and (guard_held or blockstun>0)
    if guard_edge and guarding and blockstun==0:parry_left=PARRY_WINDOW
    guard_edge=false
    if not guarding or not guard_held:parry_left=0
    guard_blend=move_toward(guard_blend,1.0 if guarding else 0.0,.20)
    if guarding:
        queued=false
        kick_pending=0
    if kick_pending>0:kick_pending-=1
    if not m.grounded or hurt>0 or hp<=0:kick_pending=0
    if queued and hp>0 and hurt==0 and age<0 and m.grounded:
        if queued_kind=="kick":kick_pending=48
        else:
            kick_pending=0
            age=0
            kind=queued_kind
            transition_pose={}
            chain_count=1 if kind=="jab" else 0
            peak_chain=maxi(peak_chain,chain_count)
            contact_hit=false
            connected=false
            attacks+=1
    if kick_pending>0 and age<0 and m.grounded and m.swing<0 and absf(m.velocity.x)<=20:
        age=0
        kind="kick"
        chain_count=0
        contact_hit=false
        transition_pose={}
        connected=false
        attacks+=1
        kick_pending=0
    queued=false
func locked()->bool:return age>=0 or hurt>0 or hp<=0 or blockstun>0
func active()->bool:
    if kind=="air_approach":return false
    if kind in ["air_jab","air_cross"]:return age>=8 and age<=13 and not connected
    if kind=="air_slam":return age>=9 and age<=15 and not connected
    if kind=="launcher":return age>=LAUNCH.ACTIVE_FROM and age<=LAUNCH.ACTIVE_TO and not connected
    if kind=="finisher":return age>=17 and age<=24 and not connected
    if kind in ["cross","hook"]:return age>=CHAIN.ACTIVE_FROM and age<=CHAIN.ACTIVE_TO and not connected
    if kind=="kick":return age>=KICK.ACTIVE_FROM and age<=KICK.ACTIVE_TO and not connected
    return age>=(HEAVY_ACTIVE_FROM if kind=="heavy" else ACTIVE_FROM) and age<=(HEAVY_ACTIVE_TO if kind=="heavy" else ACTIVE_TO) and not connected
func defense(m,source_x:float)->String:
    if not guarding or not m.grounded or (source_x-m.pos.x)*m.facing<=0:return "hit"
    if parry_left>0 and blockstun==0:return "parry"
    return "block"
func receive_block(m,direction:int,attack:Dictionary)->void:
    parry_left=0
    blockstun=12 if float(attack.strength)<1.5 else 20
    m.velocity.x=float(attack.knockback)*.24*direction
    reaction.impulse(.24,.65,float(direction*m.facing))
func receive_parry()->void:
    parry_left=0
    blockstun=0
func punish_parried(m,direction:int)->void:
    chain_buffer=0
    launch_buffer=false
    finish_pending=0
    chain_count=0
    transition_pose={}
    age=-1
    hurt=PARRY_STUN
    hurt_total=hurt
    hurt_heavy=false
    hurt_style=""
    queued=false
    kick_pending=0
    guarding=false
    parry_left=0
    guard_blend=0
    m.velocity.x=24.0*direction
    reaction.impulse(.6,.8,float(direction*m.facing))
func receive(m,direction:int,attack:Dictionary,lever:float)->void:
    finish_pending=0
    launch_buffer=false
    chain_buffer=0
    chain_count=0
    transition_pose={}
    guarding=false
    guard_blend=0
    parry_left=0
    blockstun=0
    hp=maxi(0,hp-int(attack.damage))
    age=-1
    hurt=int(attack.hurt)
    hurt_total=hurt
    hurt_heavy=bool(attack.heavy)
    hurt_style=str(attack.get("style",""))
    queued=false
    kick_pending=0
    m.velocity.x=float(attack.knockback)*direction
    reaction.impulse(float(attack.strength),lever,float(direction*m.facing))
    m.pursuing=false
    if attack.has("lift"):m.launch(float(attack.lift))
    if attack.has("juggle") and not m.grounded:m.velocity.y=minf(m.velocity.y,float(attack.juggle))
    if attack.has("slam") and not m.grounded:
        m.velocity.y=float(attack.slam)
        m.slammed=true
func pose(hybrid:bool=false)->Dictionary:
    if hurt>0:
        var u:float=float(hurt)/hurt_total
        if hurt_style in ["air_jab","air_cross","air_slam"]:
            var slam:bool=hurt_style=="air_slam"
            return {"weight":u*.85,"hip":Vector2(-4,-44 if slam else -49),"lean":38.0 if slam else -24.0,"lead":Vector2(12,25),"rear":Vector2(-10,19),"twist":.6,"air_near":Vector2(22,-14),"air_far":Vector2(-18,-22)}
        if hurt_style=="launcher":
            return {"weight":u*(.75 if hybrid else 1.0),"hip":Vector2(-3,-48),"lean":-30.0,"lead":Vector2(5,21),"rear":Vector2(-9,15),"twist":.55}
        if hurt_style in ["cross","hook","finisher"]:
            var lean:float=-13.0 if hurt_style=="cross" else (-22.0 if hurt_style=="hook" else -34.0)
            return {"weight":u*(.6 if hybrid else 1.0),"hip":Vector2(-4,-48 if hurt_style=="cross" else -43),"lean":lean,"lead":Vector2(9,15) if hurt_style=="cross" else Vector2(-4,18),"rear":Vector2(2,7) if hurt_style=="cross" else Vector2(14,22),"twist":-.6 if hurt_style=="cross" else .7}
        if hybrid:
            # Small authored loss of balance; actual upper-body motion comes from springs.
            return {"weight":u*.55,"hip":Vector2(-2,-45 if hurt_heavy else -48),"lean":-5.0,"lead":Vector2(16,8),"rear":Vector2(6,12)}
        return {"weight":u,"hip":Vector2(-5,-44) if hurt_heavy else Vector2(-3,-47),"lean":-36.0 if hurt_heavy else -24.0,"lead":Vector2(8,19),"rear":Vector2(-6,20)}
    if age<0:
        if guard_blend>0:
            var recoil:float=clampf(float(blockstun)/20,0,1)
            return {"weight":guard_blend,"hip":Vector2(-2,-48),"lean":3.0-10.0*recoil,"lead":Vector2(24,-7)+Vector2(-5,4)*recoil,"rear":Vector2(17,4)+Vector2(-4,3)*recoil}
        return {}
    return _attack_pose()
func _attack_pose()->Dictionary:
    if kind=="kick":return KICK.pose(age)
    if kind in ["cross","hook","finisher","launcher","air_approach","air_jab","air_cross","air_slam"]:
        var target:Dictionary=AIR.pose(kind,age) if airborne_attack() else (LAUNCH.pose(age) if kind=="launcher" else (KICK.pose(int(float(age)*64.0/56.0)) if kind=="finisher" else CHAIN.pose(kind,age)))
        if not transition_pose.is_empty() and age<BLEND_TICKS:
            var blend:float=smoothstep(0.0,float(BLEND_TICKS),float(age))
            var mixed:Dictionary={"weight":lerpf(float(transition_pose.weight),float(target.weight),blend),"hip":Vector2(transition_pose.hip).lerp(target.hip,blend),"lean":lerpf(float(transition_pose.lean),float(target.lean),blend),"lead":Vector2(transition_pose.lead).lerp(target.lead,blend),"rear":Vector2(transition_pose.rear).lerp(target.rear,blend),"twist":lerpf(float(transition_pose.get("twist",0)),float(target.get("twist",0)),blend)}
            if target.has("kick_foot"):mixed["kick_foot"]=Vector2(24,-2).lerp(target.kick_foot,blend)
            for key in ["air_near","air_far"]:
                if target.has(key):mixed[key]=Vector2(transition_pose.get(key,Vector2(24 if key=="air_near" else -24,-2))).lerp(target[key],blend)
            return mixed
        return target
    var pose_tick:float=float(age)*(80.0/HEAVY_DURATION if kind=="heavy" else 48.0/DURATION)
    var keys:Array=HEAVY_KEYS if kind=="heavy" else KEYS
    var a:Array=keys[0]
    var b:Array=keys[1]
    for i in range(1,keys.size()):
        if pose_tick<=float(keys[i][0]):
            a=keys[i-1]
            b=keys[i]
            break
    var u:float=(pose_tick-float(a[0]))/float(int(b[0])-int(a[0]))
    u=u*u*(3-2*u)
    return {"weight":lerpf(float(a[1]),float(b[1]),u),"hip":Vector2(lerpf(float(a[2]),float(b[2]),u),lerpf(float(a[3]),float(b[3]),u)),"lean":lerpf(float(a[4]),float(b[4]),u),"lead":Vector2(a[5]).lerp(b[5],u),"rear":Vector2(a[6]).lerp(b[6],u)}
