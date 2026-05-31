from __future__ import annotations

import math
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[2]
BLEND_OUTPUT = ROOT / "assets_src" / "characters" / "basic_human.blend"
GLB_OUTPUT = ROOT / "assets_export" / "characters" / "basic_human.glb"
PREVIEW_OUTPUT = ROOT / "assets_export" / "characters" / "basic_human_preview.png"


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()


def material(name: str, color: tuple[float, float, float, float]) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = color
        bsdf.inputs["Roughness"].default_value = 0.72
    return mat


def assign_material(obj: bpy.types.Object, mat: bpy.types.Material) -> bpy.types.Object:
    obj.data.materials.append(mat)
    return obj


def create_sphere(
    name: str,
    location: tuple[float, float, float],
    radius: float,
    mat: bpy.types.Material,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=16, radius=radius, location=location)
    obj = bpy.context.object
    obj.name = name
    assign_material(obj, mat)
    return obj


def create_cube(
    name: str,
    location: tuple[float, float, float],
    scale: tuple[float, float, float],
    mat: bpy.types.Material,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    assign_material(obj, mat)

    bevel = obj.modifiers.new("Small bevel", "BEVEL")
    bevel.width = 0.06
    bevel.segments = 3
    obj.modifiers.new("Weighted normals", "WEIGHTED_NORMAL")
    return obj


def create_limb_segment(
    name: str,
    start: tuple[float, float, float],
    end: tuple[float, float, float],
    radius: float,
    mat: bpy.types.Material,
) -> bpy.types.Object:
    start_vec = Vector(start)
    end_vec = Vector(end)
    midpoint = (start_vec + end_vec) * 0.5
    direction = end_vec - start_vec
    length = direction.length

    bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=radius, depth=length, location=midpoint)
    obj = bpy.context.object
    obj.name = name
    obj.rotation_euler = direction.to_track_quat("Z", "Y").to_euler()
    assign_material(obj, mat)

    bevel = obj.modifiers.new("Soft segment edges", "BEVEL")
    bevel.width = 0.015
    bevel.segments = 2
    obj.modifiers.new("Weighted normals", "WEIGHTED_NORMAL")
    return obj


def create_eye(name: str, location: tuple[float, float, float], mat: bpy.types.Material) -> bpy.types.Object:
    eye = create_sphere(name, location, 0.035, mat)
    eye.scale.y = 0.45
    return eye


def create_model() -> None:
    clear_scene()

    skin = material("Warm skin", (0.86, 0.62, 0.42, 1.0))
    shirt = material("Muted blue shirt", (0.18, 0.34, 0.52, 1.0))
    pants = material("Dark work pants", (0.11, 0.13, 0.17, 1.0))
    joints = material("Joint markers", (0.95, 0.70, 0.22, 1.0))
    eye_mat = material("Simple eyes", (0.02, 0.025, 0.03, 1.0))

    root = bpy.data.objects.new("BasicHuman_Root", None)
    bpy.context.collection.objects.link(root)

    parts: list[bpy.types.Object] = []
    parts.append(create_sphere("Head_Sphere", (0.0, -0.03, 2.22), 0.34, skin))
    parts.append(create_cube("Body_OnePart", (0.0, 0.0, 1.45), (0.72, 0.34, 0.95), shirt))

    parts.append(create_limb_segment("Arm_L_Upper", (-0.45, 0.0, 1.78), (-0.83, 0.0, 1.36), 0.105, skin))
    parts.append(create_limb_segment("Arm_L_Lower", (-0.83, 0.0, 1.36), (-0.93, 0.0, 0.92), 0.095, skin))
    parts.append(create_limb_segment("Arm_R_Upper", (0.45, 0.0, 1.78), (0.83, 0.0, 1.36), 0.105, skin))
    parts.append(create_limb_segment("Arm_R_Lower", (0.83, 0.0, 1.36), (0.93, 0.0, 0.92), 0.095, skin))

    parts.append(create_limb_segment("Leg_L_Upper", (-0.22, 0.0, 0.98), (-0.27, 0.0, 0.48), 0.125, pants))
    parts.append(create_limb_segment("Leg_L_Lower", (-0.27, 0.0, 0.48), (-0.27, 0.0, 0.05), 0.11, pants))
    parts.append(create_limb_segment("Leg_R_Upper", (0.22, 0.0, 0.98), (0.27, 0.0, 0.48), 0.125, pants))
    parts.append(create_limb_segment("Leg_R_Lower", (0.27, 0.0, 0.48), (0.27, 0.0, 0.05), 0.11, pants))

    for name, location in [
        ("Shoulder_L_Joint", (-0.45, 0.0, 1.78)),
        ("Shoulder_R_Joint", (0.45, 0.0, 1.78)),
        ("Elbow_L_Joint", (-0.83, 0.0, 1.36)),
        ("Elbow_R_Joint", (0.83, 0.0, 1.36)),
        ("Knee_L_Joint", (-0.27, 0.0, 0.48)),
        ("Knee_R_Joint", (0.27, 0.0, 0.48)),
    ]:
        parts.append(create_sphere(name, location, 0.075, joints))

    parts.append(create_eye("Eye_L", (-0.11, -0.36, 2.27), eye_mat))
    parts.append(create_eye("Eye_R", (0.11, -0.36, 2.27), eye_mat))

    for obj in parts:
        obj.parent = root

    bpy.ops.object.light_add(type="AREA", location=(0.0, -3.5, 4.0))
    light = bpy.context.object
    light.name = "Preview_AreaLight"
    light.data.energy = 350
    light.data.size = 4.0

    bpy.ops.object.camera_add(location=(0.0, -6.2, 1.35), rotation=(math.radians(83), 0, 0))
    camera = bpy.context.object
    camera.name = "Preview_Camera"
    camera.data.lens = 38
    bpy.context.scene.camera = camera

    bpy.context.scene.render.engine = "BLENDER_EEVEE"
    bpy.context.scene.world.color = (0.04, 0.045, 0.055)
    bpy.context.scene.render.resolution_x = 900
    bpy.context.scene.render.resolution_y = 900

    BLEND_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    GLB_OUTPUT.parent.mkdir(parents=True, exist_ok=True)

    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_OUTPUT))
    bpy.ops.export_scene.gltf(
        filepath=str(GLB_OUTPUT),
        export_format="GLB",
        export_apply=True,
        use_selection=False,
    )

    bpy.context.scene.render.filepath = str(PREVIEW_OUTPUT)
    bpy.ops.render.render(write_still=True)


if __name__ == "__main__":
    create_model()
