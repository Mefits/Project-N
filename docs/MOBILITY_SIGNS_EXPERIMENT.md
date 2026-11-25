# N — mobility and hand signs / experiment 04

Open project.godot in Godot 4.4.1, press F5. Isolated sandbox at 60 Hz. N main arena and Lab unchanged.

M4 owner feedback: halve dash speed (1700 to 850 px/s), retain duration 0.18s and cooldown. Use inertia continuously with no horizontal movement command, including during signs; double the previous seal coasting deceleration (ground 330 to 660, air 60 to 120). This halves stopping time and distance at equal initial speed in the continuous model. Active movement acceleration, max run speed and gravity unchanged. Jump/double jump replaces velocity with current horizontal movement direction times RUN (zero without input or while signing) and original upward impulse; cancels ongoing dash but does not refund air dash charges. No unlimited jumps.

A/D move; WASD selects aim outside signing, arrows override aim. Shift + ASD prepares Bolt; Shift + ADAD prepares Orb. Removed Rush and the free dash code. J cast, K dash, Space jump/double jump, L/Escape cancel. F4 toggles optional quick double-Space dash (260ms). F3 target, R reset. Removed F2 latch mode. Readiness remains 8 seconds. All balance values provisional.