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

## Checkpoint 5
- Added a `Human_Sword_Attack` clip to the Blender human source and regenerated the character GLBs.
- Wired player melee to play the sword attack clip without locomotion overriding it.
- Added a longer windup, slash, follow-through, and recovery timeline for player body and sword visuals.
- Delayed melee damage until the slash window while preserving a shorter active hit window.
- Updated the combat smoke test to verify the imported attack clip and delayed melee damage.

## Checkpoint 6
- Added left and right hand bones to the generated human armature.
- Moved the player sword into the skinned character model and weighted it to `Hand_R`.
- Disabled the player hitbox's separate sword visual so the visible blade no longer floats independently.
- Softened root-level melee motion to a subtle weight shift instead of rotating the whole player.
- Retuned melee duration, cooldown, and damage delay for a more readable slash.

## Checkpoint 7
- Reoriented the held sword so the blade points forward from the right-hand grip instead of sideways across the character.
- Revised `Human_Sword_Attack` into an overhead descending cut: ready, lift, high guard, downward chop, follow-through, recovery.
- Added right-hand rotation keys so the blade follows the palm through the swing.
- Regenerated and reimported the character GLB after the sword orientation and animation changes.
- Confirmed the combat smoke test still passes with the rigged sword mesh and delayed melee damage.
