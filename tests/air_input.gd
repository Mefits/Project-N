extends RefCounted
## Real keyboard-equivalent edges, never directly edit combat state.
var sent:int=0
var chased:bool=false
var delay:int=0
func next(w,mirror:bool=false,follow:bool=true,finish:bool=true)->Dictionary:
    var j=w.jab_b if mirror else w.jab_a
    var m=w.b if mirror else w.a
    var t=w.a if mirror else w.b
    var press:bool=sent==0 or (sent==1 and j.kind=="jab" and j.age>=11) or (sent==2 and j.kind=="cross" and j.age>=11) or (sent==3 and j.kind=="hook" and j.age>=11)
    if press:
        sent+=1
        return {"jab":true,"launch":sent==4}
    if follow and not chased and j.kind=="launcher" and j.contact_hit and t.launched:
        if w.freeze>0:return {}
        chased=true
        return {"jump":true}
    if chased and not m.grounded and (sent==4 and j.kind=="air_approach" and j.age>=7 or sent==5 and j.kind=="air_jab" and j.age>=11 or finish and sent==6 and j.kind=="air_cross" and j.age>=11):
        sent+=1
        return {"jab":true}
    return {}
