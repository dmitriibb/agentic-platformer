from __future__ import annotations

import math
import shutil
from pathlib import Path

import bpy


ROOT = Path(__file__).resolve().parents[2]
BLEND_OUTPUT = ROOT / "assets_src" / "weapons" / "simple_sword.blend"
GLB_OUTPUT = ROOT / "assets_export" / "weapons" / "simple_sword.glb"
GAME_GLB_OUTPUT = ROOT / "game" / "assets_export" / "weapons" / "simple_sword.glb"
PREVIEW_OUTPUT = ROOT / "assets_export" / "weapons" / "simple_sword_preview.png"


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()


def material(
    name: str,
    color: tuple[float, float, float, float],
    roughness: float,
    metallic: float = 0.0,
) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = color
        bsdf.inputs["Roughness"].default_value = roughness
        bsdf.inputs["Metallic"].default_value = metallic
    return mat


def assign_material(obj: bpy.types.Object, mat: bpy.types.Material) -> bpy.types.Object:
    obj.data.materials.append(mat)
    return obj


def apply_object_transform(obj: bpy.types.Object) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)


def create_cube(
    name: str,
    location: tuple[float, float, float],
    dimensions: tuple[float, float, float],
    mat: bpy.types.Material,
    bevel_width: float,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    assign_material(obj, mat)
    apply_object_transform(obj)

    if bevel_width > 0.0:
        bevel = obj.modifiers.new("Soft bevel", "BEVEL")
        bevel.width = bevel_width
        bevel.segments = 2
    obj.modifiers.new("Weighted normals", "WEIGHTED_NORMAL")
    return obj


def create_tip(mat: bpy.types.Material) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cone_add(vertices=4, radius1=0.17, radius2=0.0, depth=0.42, location=(1.48, 0.0, 0.0))
    obj = bpy.context.object
    obj.name = "Sword_Tip"
    obj.rotation_euler[1] = math.radians(90.0)
    assign_material(obj, mat)
    apply_object_transform(obj)
    obj.modifiers.new("Weighted normals", "WEIGHTED_NORMAL")
    return obj


def create_cylinder(
    name: str,
    location: tuple[float, float, float],
    radius: float,
    depth: float,
    axis: str,
    mat: bpy.types.Material,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=radius, depth=depth, location=location)
    obj = bpy.context.object
    obj.name = name
    if axis == "X":
        obj.rotation_euler[1] = math.radians(90.0)
    elif axis == "Y":
        obj.rotation_euler[0] = math.radians(90.0)
    assign_material(obj, mat)
    apply_object_transform(obj)
    obj.modifiers.new("Weighted normals", "WEIGHTED_NORMAL")
    return obj


def create_sphere(
    name: str,
    location: tuple[float, float, float],
    radius: float,
    mat: bpy.types.Material,
    scale: tuple[float, float, float] = (1.0, 1.0, 1.0),
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=16, radius=radius, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    assign_material(obj, mat)
    apply_object_transform(obj)
    return obj


def create_sword() -> None:
    clear_scene()

    steel = material("Brushed steel", (0.72, 0.78, 0.84, 1.0), 0.28, 0.35)
    edge = material("Bright blade edge", (0.9, 0.94, 0.98, 1.0), 0.22, 0.4)
    guard = material("Warm brass guard", (0.86, 0.58, 0.18, 1.0), 0.36, 0.2)
    grip = material("Dark leather grip", (0.08, 0.045, 0.028, 1.0), 0.62)
    pommel = material("Steel pommel", (0.55, 0.59, 0.64, 1.0), 0.34, 0.25)

    create_cube("Sword_Blade", (0.79, 0.0, 0.0), (1.38, 0.075, 0.18), steel, 0.01)
    create_cube("Sword_Blade_Ridge", (0.79, -0.002, 0.0), (1.32, 0.02, 0.035), edge, 0.004)
    create_cube("Sword_Blade_Edge_Top", (0.79, 0.0, 0.1), (1.27, 0.032, 0.032), edge, 0.004)
    create_cube("Sword_Blade_Edge_Bottom", (0.79, 0.0, -0.1), (1.27, 0.032, 0.032), edge, 0.004)
    create_tip(steel)
    create_cylinder("Sword_Guard_Bar", (0.02, 0.0, 0.0), 0.055, 0.78, "Y", guard)
    create_sphere("Sword_Guard_End_L", (0.02, -0.43, 0.0), 0.115, guard)
    create_sphere("Sword_Guard_End_R", (0.02, 0.43, 0.0), 0.115, guard)
    create_sphere("Sword_Guard_Center", (0.02, 0.0, 0.0), 0.073, guard, (1.0, 1.0, 0.7))
    create_cylinder("Sword_Grip", (-0.28, 0.0, 0.0), 0.065, 0.48, "X", grip)
    create_sphere("Sword_Pommel", (-0.6, 0.0, 0.0), 0.14, pommel)

    bpy.ops.object.empty_add(type="PLAIN_AXES", location=(0.0, 0.0, 0.0))
    root = bpy.context.object
    root.name = "SimpleSword_Root"

    for obj in [candidate for candidate in bpy.context.scene.objects if candidate != root]:
        obj.parent = root

    bpy.ops.object.light_add(type="AREA", location=(0.3, -2.4, 2.2))
    light = bpy.context.object
    light.name = "Preview_AreaLight"
    light.data.energy = 260
    light.data.size = 3.0

    bpy.ops.object.camera_add(location=(0.55, -3.2, 1.0), rotation=(math.radians(74.0), 0.0, 0.0))
    camera = bpy.context.object
    camera.name = "Preview_Camera"
    camera.data.lens = 48
    bpy.context.scene.camera = camera

    bpy.context.scene.render.engine = "BLENDER_EEVEE"
    bpy.context.scene.world.color = (0.04, 0.045, 0.052)
    bpy.context.scene.render.resolution_x = 900
    bpy.context.scene.render.resolution_y = 900

    BLEND_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    GLB_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    GAME_GLB_OUTPUT.parent.mkdir(parents=True, exist_ok=True)

    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_OUTPUT))
    bpy.ops.export_scene.gltf(
        filepath=str(GLB_OUTPUT),
        export_format="GLB",
        export_apply=True,
        use_selection=False,
        export_animations=False,
    )
    shutil.copy2(GLB_OUTPUT, GAME_GLB_OUTPUT)

    bpy.context.scene.render.filepath = str(PREVIEW_OUTPUT)
    bpy.ops.render.render(write_still=True)


if __name__ == "__main__":
    create_sword()
