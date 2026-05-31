# Agent Instructions

## Project Direction

This project is a 2.5D platformer built with Godot 4.6 Standard and GDScript.

Use a 3D visual presentation with gameplay constrained mostly to a 2D plane. Prefer practical, scriptable workflows that local agents can inspect, modify, validate, and run from the command line.

## Engine And Language

- Use Godot 4.6 Standard.
- Use GDScript for gameplay and tooling.
- Do not introduce C#/.NET unless explicitly requested.
- Do not add a different game engine unless explicitly requested.

## Files And Editing

- Do not hand-edit Godot cache/import folders such as `.godot/`.
- Prefer text-based Godot scenes and resources.
- Keep gameplay rules, level definitions, character stats, camera settings, and build settings readable and version-controlled.
- Keep generated files separate from source files where practical.
- Keep changes small, focused, and easy to review.

## Recommended Project Structure

```text
game/                 # Godot project; project.godot lives here
docs/                 # Design notes, technical docs, planning docs
tools/                # Helper scripts for validation, export, asset processing
levels/               # Source level definitions, preferably JSON
assets_src/           # Blender files, source textures, AI drafts
assets_export/        # Generated runtime assets such as .glb/.gltf/.png
builds/               # Local build output; should not be committed
```

## Level Pipeline

- Prefer data-driven level definitions in `levels/`.
- Use a clear text format such as JSON for gameplay-critical layout data.
- Generate Godot scenes from level data instead of burying all gameplay structure in manually edited scene files.
- Add validators for jump distances, reachable checkpoints, spawn safety, missing collisions, and missing camera zones.
- Use the Godot editor for inspection and polish, but keep the primary gameplay layout understandable to agents.

## Asset Pipeline

- Use Blender source files in `assets_src/`.
- Export runtime assets to `assets_export/` as `.glb` or `.gltf`.
- Normalize scale, origins, naming, and collision conventions before importing assets into Godot.
- Treat AI-generated 3D assets as drafts that may need cleanup.
- Optimize assets for Android later, but keep mobile constraints in mind from the start.
- Blender is expected to be available on `PATH` as `blender`.
- Check Blender availability with `blender --version`.
- Run Blender automation in background mode, for example: `blender --background --python tools/blender/create_basic_human.py`.
- Open a source asset in the Blender UI with a command such as `blender assets_src/characters/basic_human.blend`, or by opening the `.blend` file directly.
- Keep Blender automation scripts in `tools/blender/`.
- Do not commit Blender local backup files such as `.blend1`, `.blend2`, or similar numbered backups.
- Prefer regenerating `.glb` files from `.blend` sources and scripts instead of hand-editing exported runtime files.

## Build And Validation

- Prefer repeatable scripts in `tools/`.
- Useful scripts to add:
  - `tools/doctor.ps1`
  - `tools/export-windows.ps1`
  - `tools/export-android-debug.ps1`
  - `tools/validate-levels.ps1`
  - `tools/blender-export-assets.ps1`
- Use Godot command-line export once export presets exist.
- Run validation before large content changes.

## Version Control

- Commit source files, scripts, docs, level data, and project settings.
- Do not commit local build output.
- Use Git LFS for large binary assets when the project starts adding real art/audio files.
- Git LFS stores large binary files outside normal Git history and leaves lightweight pointer files in the repository. This keeps clones, diffs, and agent workflows manageable as art/audio files grow.
- Agents must not paste, rewrite, or manually edit Git LFS pointer files. Treat the real asset file as the source and let Git LFS manage storage.
- Before adding large assets, check that Git LFS is installed with `git lfs version` and initialized with `git lfs install`.
- Keep source art in `assets_src/` and generated runtime assets in `assets_export/`.
- Prefer adding repeatable export scripts instead of committing many hand-exported variants.
- If a binary asset changes often, keep notes about why it changed in nearby docs or commit messages because normal text diffs will not explain binary changes.
- Recommended Git LFS patterns:

```text
*.blend
*.glb
*.gltf
*.png
*.jpg
*.jpeg
*.wav
*.ogg
*.mp4
```

## Agent Behavior

- Read existing files before making changes.
- Follow the current project structure and naming conventions.
- Prefer simple, explicit solutions over clever abstractions.
- When adding systems, include a small validation path or test scene where practical.
- Do not perform destructive git or filesystem operations unless explicitly requested.
