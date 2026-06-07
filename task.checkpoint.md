# Task Checkpoints

## Checkpoint 1
- Added an articulated Blender human generator with `Human_Walk` and `Human_Idle` animation clips.
- Exported the animated human GLB to root assets and mirrored it into the Godot project.
- Replaced the cube player visual with a human GLB wrapper, human-sized collision, and animation-driven player controller logic.
- Fixed Godot startup by replacing raw GLB `preload()` with guarded dynamic `ResourceLoader` loading and a fallback visual.
- Confirmed Godot must be run outside the Codex sandbox for this project; unsandboxed import and headless startup now succeed.

## Checkpoint 2
- Replaced the fragile animated empty-node model with a lightweight armature/skinned human export.
- Removed visible joint marker pieces so limbs no longer appear as detached yellow pivots during walking.
- Flipped player visual yaw so moving right faces right and moving left faces left.
- Confirmed Godot imports `Human_Idle`, `Human_Walk`, a 13-bone skeleton, and 17 skinned mesh instances.

## Checkpoint 3
- Added `game/levels/prototype_room.json` as the declarative source for the current room.
- Added `game/scripts/level_builder.gd` to build environment, lights, boxes, player, collision, visual, and camera from JSON.
- Refactored `game/scripts/main.gd` so world setup delegates to the level builder.
- Confirmed `main.tscn` runs headlessly with the JSON-backed level.

## Checkpoint 4
- Expanded `prototype_room.json` into a wider platformer-style room.
- Added several elevated box platforms and a landing block through declarative level data.
- Added `player.controller` tuning support in `level_builder.gd`.
- Added one extra airborne jump plus JSON-configurable player horizontal bounds.
- Confirmed `main.tscn` runs headlessly after the platforming changes.
