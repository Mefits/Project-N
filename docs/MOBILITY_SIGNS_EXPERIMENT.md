# N — mobility and hand signs / experiment 03

Open project.godot in Godot 4.4.1, press F5. This branch's default scene is the isolated 60 Hz control sandbox, not the main arena. All physics constants, camera, techniques and target motion are retained from M2. No mouse input.

A/D move; WASD outside signing sets one of eight aim directions, retained when released. Arrow keys optionally override aim, including during signs. Shift + WASD prepares WDS (Bolt), SWDW (Orb), ADW (Rush). Release Shift, J casts toward aim, K dashes, Space jumps/double jumps, L or Escape cancels. F4 enables optional double-Space dash (second press within 260 ms), K remains available. F2 toggles coast (default) vs latched movement; F3 toggles target; R reset. Signs do not change aim while held; independent arrows remain available. 8-second preparation lifetime, no real opponent attacks. Controls and timing are experimental; no new animations or changes to main or Lab.

Test keyboard-only mobility, directional attacks and simultaneous movement/seals. Especially compare K against double Space and whether aiming with WASD or arrows feels more natural.