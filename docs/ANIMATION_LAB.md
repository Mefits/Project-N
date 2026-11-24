# Animation Lab — 0.10.2 acceptance specification (planned)

Goal: repeatable motion inspection of the existing Godot characters without modifying the playable arena. No separate game, no effects or abilities. The lab should reuse World, Motor, Rig and skin and deterministic scripted inputs. Baseline 0.10.1 preserved.

Minimum working slice:
- Select existing idle, walk, run, jump, jab, heavy, kick, guard, ground string, air string, fall/get-up scenarios. Start with idle/run/jab/full-air if a smaller first slice is needed.
- Play/pause, restart, previous/next sample and scrub. Real 1x playback and labeled slow playback. Show simulation tick and elapsed ms; no resimulation from arbitrary state without deterministic replay.
- Same camera and scale for comparison, skeleton/skin toggle, optional trajectory trails and planted foot markers. Show contact, hitstop, support and active/recovery intervals where actually available.
- Export numeric joint/root/state trace, actual engine PNG frame sheet and correctly timed GIF or frame directory, plus version and scenario parameters. Baseline vs candidate from identical inputs and sampling.
- Run as separate scene/test path; normal arena and all current controls remain unchanged. Headless deterministic replay and graphical smoke test; verify controls change the displayed sample and do not mutate the original world.
- Initial deliverable should include a real run A/B baseline diagnostic and a jab/contact example; no new movement implementation until lab works. Mark any absent controls as incomplete.

0.10.3: one Mocap retarget experiment, source/projection/stylized comparison. If unavailable, report and continue with inspectable references, not fabricated motion data.
0.10.4: idle/walk/run/jump/land in small checkpoints.
0.10.5: single attacks, defense, hit reactions.
0.10.6: ground/air chains, spacing, knockdown/get-up, interrupted transitions.
Effects and sign system remain deferred until owner agrees motion quality is ready.

## Implementation 0.10.2
Open `res://lab/animation_lab.tscn` and F6 in Godot, or `godot --path . res://lab/animation_lab.tscn`. 120 Hz immutable snapshots; JSON vector arrays, actual inputs, contact and support state, real engine frames every four ticks (30 fps). Playback rates 1, .5, .25. The UI uses the same renderer and fixed view; traces are saved to user://animation_lab. Anchor drift and rendered ankle error reported separately (support markers are motor flags, not force measurements). Trace baseline identifies the motion commit; artifact REVISION identifies the lab commit. Candidate A/B overlay is deferred until first retarget candidate; this checkpoint records baseline only. No source motion imported.

## 0.10.3
Open `lab/mocap/preview.tscn` (F6). Four panels: current N, actual projected CMU capture, length-normalized N transfer, authored faster/stylized transfer. Default phase mode displays each at the same fractional cycle, not native speed; switch to native for timing. Original lab remains unchanged. Source and reproducible offline importer in lab/mocap; no network runtime dependency. This is an in-place motion study, not a motor-integrated candidate.
