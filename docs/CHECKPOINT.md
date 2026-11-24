# 0.01
Verify locomotion foundation and graphical smoke; no combat yet.

Explicit screen-coordinate perpendicular for IK; test knee direction and actual support-point contact, faster sprint step cadence.

## 0.02
Guard retarget, fixed support, mirrored pose loop, constant limb lengths; capture 24 real frames at 20 fps. Retain previous locomotion tests. No combat or VFX added.

## 0.03
Reference-based locomotion posture, velocity-predicted step targets, fixed swing durations, guard backpedal, airborne tuck/extension and landing compression. Regression of mirrored stance and support; real 20 FPS capture sequences for walk/run/back/jump. No combat changes.

Final 0.03 checkpoint: initial regression passed; repeat after correcting opposing arm swing and adding its test.

## 0.04
Jab milestone: all locomotion regressions, one hit, held-key protection, mirrored hit, miss, trade, airborne rejection, six freeze ticks, root knockback, real 30 fps capture. No hybrid joint physics yet.

## 0.05
Heavy rear-hand attack, contact-derived torque, bounded angular spring dynamics with delayed channels, hitstop freeze and A/B reset. Verify old locomotion/jab, hybrid strength/lever/lag/settle, heavy miss/contact/trade, symmetry, bone lengths and actual capture comparisons.

Correct float32 clamp comparison: reset angular velocity only when a hard angular limit is exceeded, not on rounding. Keep original tests unchanged.

## 0.06
Freeze hybrid implementation, authored reaction default, draw-only original provisional skin. Retain all tests; explicitly enable hybrid in regression; verify toggling art preserves world state. Capture authored jab, authored heavy and same heavy with mannequin for comparison.

Correct tapered limb contour winding after visual log exposed self-intersection. Treat all Godot ERROR lines in graphical capture as failures.

Graphical CI uses Godot Dummy audio driver because the runner has no sound device; polygon errors remain fatal. Previous run confirms all gameplay tests passed and no triangulation errors after the contour fix.

## 0.06.2
Accepted hybrid default restored, smooth continuous limb skin and bent cloth contours; F6 A/B. Verify actual contours over extreme bends and sampled gameplay poses, old regression and real captures. No new combat actions.

## 0.07
Front kick with rear-foot support and buffered movement transition; validate hit/miss, mirrored contact, single damage, airborne rejection, interruption, lift/reach, leg length, skin contours and real frame captures. Preserve existing regressions.

## Repository migration
N 0.07 imported from Mefits/pixelfxGadot@5f0e077d3fd73bb280327ef617be9359a52cd588. Verified source CI: https://github.com/Mefits/pixelfxGadot/actions/runs/45494456164. No gameplay changes. CI now targets main in Mefits/Project-N.

## 0.08
Ground guard and timed parry, mirrored contacts, no guard cancel during attack, no defense in air or against rear contact, counter opportunity, no events on whiff; regression and real block/parry counter capture. Keep existing attack profiles, physical reaction and skin unchanged.

## 0.09a
Retimed baseline attacks and sprint stride, first three-hit grounded string. Test run support, cadence, old contacts/defense at new timings, chain hit-confirm, buffered transition, mirrored string, interruption and whiff. Capture real chain frames. No air/combo finisher yet.

## 0.09b
Four-hit confirmed string and proportional approach, distinct hurt overlays, gait-only sprint flight. Validate actual contacts, mirrored finisher, support, minimum gap and cadence, capture real frames. Keep old regressions.

## 0.09c
Alternate rising strike, true ballistic launch and return to ground. Verify mirrored launch, damage, contact gating, hitstop freeze, floor, bone lengths, recovery and previous kick chain; capture normal and mirrored launcher from real Godot. No aerial followup yet.

## 0.10
Optional pursuit, linked aerial lead/rear/downward strikes. Verify 7 actual contacts, two directions, no finisher without input, no pursuit on block/whiff, hitstop, bounded trajectories, landing/recovery and prior regressions. Engine frame captures. No effects yet.

0.10 tuning: first CI confirmed the first air hit but second missed; narrower cross and slam approach goals, vertical offset and upward wrist path. Keep actual contact radius unchanged.

Trace showed cross fist 20–25 px above target chest; retarget down toward torso, reduce vertical follow offset. No hit radius change.

## 0.10.1
Aerial pose polish, attacker descent on confirmed slam, one floor impact, prone hold and rise, recovery. Same air sequence and 112-frame captures for A/B; preserve damage and collision geometry. CI requires verified landing timing and no extra hits.

## 0.10.2 — Animation Lab
Separate lab scene, real fixed-tick World recording with immutable snapshots, deterministic inputs for ten motions, scrub, single tick, playback rates, skin/skeleton, trajectories and anchor markers, contact/hitstop timeline, trace and 30 fps engine PNG export. Baseline diagnostic only: no candidate animation or Mocap yet. Test same-trace repeat, scenario contact counts, freeze, UI navigation, playback and export. Game sources unchanged.

## 0.10.3 — isolated real-motion retarget experiment
CMU 09_01 run BVH read from the credited Hahne conversion, hierarchical FK with ordered rotations, source indices 1–90. Derived sagittal projection, root travel removed, normalized by source leg length. Compare baseline 52-tick steady cycle, source 89 intervals, N length-corrected transfer and an authored 66-tick style hypothesis. Source projection is not direct game animation; candidate floor fitting is not planted-foot IK and a cycle seam is not solved. Test exact segment lengths, finite points and clearance, immutable baseline, actual graphical comparison. No gameplay files changed. See lab/mocap/SOURCE.md. Do not promote candidate into game until visual review and support/root-motion adaptation.

## 0.10.3a — authored animation A/B/C direction study
# Anime direction A/B/C study
Baseline 0.10.3 actual four-hit World trace, identical input, root, contact ticks, hitstop and camera. No effects. Reference: supplied martial arts row sheet (jab/punch/front kick/stagger, source FPS unknown), only silhouettes examined; no source pixels copied. The anime exaggeration is an authored hypothesis, not extracted from Storm footage.
A = unchanged game render. B = independently keyed pelvis, chest, head, shoulders, elbows and hands, deliberate stepped pose cadence, different preparation/delivery paths, authored victim recoil. Feet use the baseline support and visual knee IK, kick uses keyed ankle. At real contact the striking endpoint and victim pose match baseline; a short visual blend approaches the contact. C = same B plus small head/non-striking-arm lag and selective recorded victim spring angles. No new collision, physics, or playable moves. All poses still use same old skin; no 3D depth system. No claim of true smear art; transient visual length variation is allowed.
Pose beats (attack-local ticks at 120 Hz, proposed):
jab 0 entry, 3 compression, 6 pelvis leads, 8 extension, 9 contact anchor, 13 follow, 18 recover.
cross 0 entry, 4 windup, 7 pelvis leads, 9 extension, 11 contact anchor, 16 recovery.
hook 0 entry, 4 windup, 7 raised arm, 10 contact, 14 follow-through, 18 withdrawal, 31 return.
kick 0 entry, 6 lift, 12 chamber, 17–22 strike, 29 retract, 41 settle, 55 return. Actual contact tick comes from recorded World rather than these proposed ages.
Review identical 60 fps previews in real time and half speed. Judge strong silhouette, perceived impact, lead/lag and readable contacts; not mechanical correctness alone. Potential mismatch: intermediate visual strike geometry differs from live physics; this remains a study. B's lower-body support is still procedural; C only differs in secondary visual motion. No gameplay promotion until owner compares. 
