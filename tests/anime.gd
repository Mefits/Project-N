extends SceneTree
const MODEL=preload("res://lab/anime/comparison.gd")
var errors:int=0
func _initialize()->void:call_deferred("_run")
func check(ok:bool,msg:String)->void:
    if not ok:errors+=1;push_error(msg)
func _run()->void:
    var m=MODEL.new()
    var baseline:Dictionary=m.record.trace()
    check(m.contacts.size()==4 and m.record.frames[-1].hits==4,"Four real baseline contacts")
    var changes:int=0
    var secondary:int=0
    var max_stretch:float=0
    var max_support:float=0
    for i in range(m.record.frames.size()):
        var f:Dictionary=m.record.frames[i]
        var a:Dictionary=m.sample(i,0)
        var b:Dictionary=m.sample(i,1)
        var c:Dictionary=m.sample(i,2)
        if a!=b:changes+=1
        if b!=c:secondary+=1
        for p in [b,c]:
            for side in ["a","b"]:
                for key in p[side]:check(Vector2(p[side][key]).is_finite(),"Finite visual point")
                for j in range(2):
                    var s:String="near" if j==0 else "far"
                    if f[side].support[j] and not f.frozen:
                        var err:float=Vector2(p[side]["foot_"+s]).distance_to(f[side].points["foot_"+s])
                        max_support=maxf(max_support,err)
                        check(err<.001,"Support unchanged")
                    max_stretch=maxf(max_stretch,Vector2(p[side]["elbow_"+s]).distance_to(p[side]["hand_"+s]))
        if f.contact_event:
            check(b.a[f.a.strike]==a.a[f.a.strike] and c.a[f.a.strike]==a.a[f.a.strike],"Exact contact endpoint")
            check(b.b==a.b and c.b==a.b,"Exact victim at contact")
        if i>0 and f.frozen:
            check(b==m.sample(i-1,1) and c==m.sample(i-1,2),"Hold contact frame")
        check(b.a[f.a.strike]==c.a[f.a.strike],"Secondary cannot alter strike")
    check(changes>30 and secondary>20,"Variants visibly differ")
    check(m.record.trace()==baseline,"No simulation mutation")
    print("N anime contact ticks: ",m.contacts,"; changed ",changes,"; secondary ",secondary,"; support error ",max_support,"; max visual forearm ",max_stretch)
    print("N anime failures: ",errors)
    quit(0 if errors==0 else 1)
