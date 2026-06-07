# Level Building

This project uses declarative JSON level files plus a small Godot runtime builder. Level authors and agents should edit readable level data instead of hardcoding room geometry in gameplay scripts.

## Current Files

- `game/levels/prototype_room.json`: current declarative room definition.
- `game/scripts/level_builder.gd`: reads level JSON and creates Godot nodes.
- `game/scripts/main.gd`: creates `GameWorld` and asks `LevelBuilder` to load the active level.

The current active level is selected in `game/scripts/main.gd`:

```gdscript
const LEVEL_PATH := "res://levels/prototype_room.json"
```

Use `game/levels/` for runtime-loaded JSON files because Godot can load them with `res://levels/...`.

## Why Levels Are JSON

Godot `.tscn` files are text and can be edited, but they include Godot-specific scene details that are noisy for level design. JSON keeps gameplay-critical layout easy to read, diff, validate, and edit by humans or agents.

The intended split is:

- JSON level files describe what exists and where.
- `level_builder.gd` converts that data into Godot nodes.
- Gameplay behavior remains in GDScript components such as player, hazards, checkpoints, and props.

## Basic Level Shape

A level file is one JSON object:

```json
{
  "name": "PrototypeRoom",
  "environment": {},
  "lights": [],
  "player": {},
  "camera": {},
  "objects": []
}
```

Most positions, sizes, rotations, and colors are arrays:

- 3D vectors: `[x, y, z]`
- Colors: `[r, g, b, a]` with values from `0.0` to `1.0`
- Rotations: `rotation_degrees`, also `[x, y, z]`

## Supported Top-Level Sections

### `name`

Creates a root `Node3D` under `GameWorld` with this name.

```json
"name": "PrototypeRoom"
```

### `environment`

Creates a `WorldEnvironment`.

```json
"environment": {
  "background_color": [0.08, 0.09, 0.11, 1.0],
  "ambient_light_color": [0.38, 0.42, 0.48, 1.0],
  "ambient_light_energy": 0.7
}
```

### `lights`

Currently supports directional lights.

```json
"lights": [
  {
    "type": "directional",
    "name": "Sun",
    "rotation_degrees": [-50.0, -35.0, 0.0],
    "energy": 2.2
  }
]
```

### `objects`

Currently supports `box` objects. A box with `"collision": true` becomes a `StaticBody3D` with a `BoxMesh` and `BoxShape3D`.

```json
"objects": [
  {
    "type": "box",
    "name": "Floor",
    "position": [0.0, -0.25, 0.0],
    "size": [14.0, 0.5, 6.0],
    "color": [0.22, 0.24, 0.25, 1.0],
    "collision": true
  }
]
```

Use boxes for early blockout geometry such as floors, walls, platforms, and simple barriers.

### `player`

Creates a `CharacterBody3D`, attaches the configured script, adds a visual container, loads the GLB visual if available, and adds collision.

```json
"player": {
  "name": "Player",
  "position": [0.0, 0.02, 0.0],
  "script": "res://scripts/player_controller.gd",
  "controller": {
    "move_speed": 6.6,
    "jump_velocity": 8.5,
    "gravity": 22.0,
    "max_air_jumps": 1,
    "min_x": -13.45,
    "max_x": 13.45
  },
  "visual": {
    "container_name": "Visual",
    "scene": "res://assets_export/characters/basic_human.glb",
    "instance_name": "BasicHuman",
    "rotation_degrees": [0.0, 90.0, 0.0],
    "scale": [0.9, 0.9, 0.9],
    "fallback_color": [0.95, 0.68, 0.22, 1.0]
  },
  "collision": {
    "type": "capsule",
    "name": "Collision",
    "position": [0.0, 1.1, 0.0],
    "radius": 0.32,
    "height": 2.2
  }
}
```

The optional `controller` object sets exported variables on the player script. Use it for level-specific movement tuning such as horizontal bounds, gravity, jump strength, and double-jump count.

Supported player collision types:

- `capsule`
- `box`

### `camera`

Creates a `Camera3D`, places it, and points it at `look_at`.

```json
"camera": {
  "name": "Camera3D",
  "position": [0.0, 5.4, 10.0],
  "look_at": [0.0, 0.9, 0.0],
  "current": true
}
```

## How To Create A New Level

1. Copy `game/levels/prototype_room.json` to a new file under `game/levels/`.
2. Change the top-level `name`.
3. Edit `objects` to define floors, walls, platforms, and barriers.
4. Move the `player.position` to the desired spawn point.
5. Adjust `camera.position` and `camera.look_at`.
6. Update `LEVEL_PATH` in `game/scripts/main.gd` to load the new level.
7. Validate with Godot:

```powershell
C:\programms\godot\godot.bat --headless --path game --scene res://scenes/main.tscn --quit-after 3
```

In Codex, run Godot outside the filesystem sandbox as described in `AGENTS.md`.

## How To Extend The Builder

When adding a new level object type:

1. Add a new JSON object shape to this document.
2. Add a new case in `LevelBuilder._add_object()`.
3. Implement a small `_add_*` method that creates the Godot nodes.
4. Keep Godot-specific details inside `level_builder.gd`.
5. Add one example object to a test or prototype level.
6. Validate the main scene headlessly.

Good future object types:

- `platform`
- `hazard`
- `checkpoint`
- `camera_zone`
- `scene_instance`
- `pickup`

Prefer reusable Godot scenes for objects with behavior. The JSON should place and configure them; the behavior should live in scripts or packed scenes.

## Agent Rules

- Treat `game/levels/*.json` as the source of truth for level layout.
- Do not reintroduce hardcoded room geometry into `main.gd`.
- Keep level files readable and explicit, even if that means a little repetition.
- Preserve the 2.5D convention: visual world is 3D, gameplay mostly stays on a constrained plane.
- Add builder support before using new JSON object types.
- Validate JSON syntax and run the Godot scene after level-format changes.
