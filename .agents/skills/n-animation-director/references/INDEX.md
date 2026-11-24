# Curated reference index (read on demand)

Three core sources, not three independently installed agents. This index records useful concepts, not copied upstream instructions.

| Task | Primary reading | Use |
|---|---|---|
| Motion QA, support, transition diagnostics | [ref2game animation](https://github.com/studioigor/ref2game/blob/main/claude/references/animation.md), sections 10, 12, 14 | Frame review, joint traces, measured support and discontinuities. Adapt to N; do not copy its JavaScript tooling or isometric assumptions. |
| Pose design and timing | [ProkStudio sprite-animation](https://github.com/ProkStudio/skills/blob/main/skills/game/2d/sprite-animation/SKILL.md) | Extremes before interpolation, timing/spacing, secondary motion. Use for animation design, not a requirement for sprite sheets. |
| Combat readability | [Rivals guide](https://www.rivalslib.com/workshop_guide/art/anticipation_action_recovery.html) | Clear windup/active/recovery silhouettes and fast transitions, preserve player feedback. Not a frame-data specification for N. |

Optional lookup only when needed:
- [Ultimate Frame Data: Ryu](https://ultimateframedata.com/ryu): gameplay timing reference, not N's required balance or direct animation assets. Distinguish hitboxes from actual frame poses.
- [KinemIQ motion capture](https://kinemiq.app/free-motion-capture-data/): optional dataset source; page lists ACCAD CC BY 3.0 and 100STYLE CC BY 4.0. Verify exact clip license/credit, retain attribution. No clips downloaded or imported yet. Prefer raw public source if export inaccessible.
- Prior user-supplied martial arts and Naruto sheets: reference only unless license permits redistribution; use only if available in current working context.
- Storm footage: style/choreography reference, no extracted commercial art shipped. Select exact accessible footage and verify its timebase.
- Skullgirls GDC and Sakurai videos: optional theory only, not mandatory reading. Do not claim to have analyzed video content from a title or description.

The previously suggested GD-Agentic-Skills Godot animation link could not be reopened during this pass; excluded from core. N's existing code and Godot official documentation are the technical authority. No source code or asset licensing assumptions.

Each task records its selected references and pose sheet with the milestone. Keep source list small. Expand only when a specific unresolved motion defect calls for it.
