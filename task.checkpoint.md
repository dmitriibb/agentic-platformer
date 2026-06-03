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
