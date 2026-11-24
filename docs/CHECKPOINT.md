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
