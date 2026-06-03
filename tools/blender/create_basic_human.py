from __future__ import annotations

import math
import shutil
from pathlib import Path

import bpy
from mathutils import Euler, Vector


ROOT = Path(__file__).resolve().parents[2]
BLEND_OUTPUT = ROOT / "assets_src" / "characters" / "basic_human.blend"
GLB_OUTPUT = ROOT / "assets_export" / "characters" / "basic_human.glb"
GAME_GLB_OUTPUT = ROOT / "game" / "assets_export" / "characters" / "basic_human.glb"
PREVIEW_OUTPUT = ROOT / "assets_export" / "characters" / "basic_human_preview.png"

FPS = 30
WALK_ANIMATION = "Human_Walk"
IDLE_ANIMATION = "Human_Idle"


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


def apply_object_transform(obj: bpy.types.Object) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)


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


def create_cube(
    name: str,
    location: tuple[float, float, float],
    scale: tuple[float, float, float],
    mat: bpy.types.Material,
    bevel_width: float = 0.035,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = scale
    assign_material(obj, mat)
    apply_object_transform(obj)

    if bevel_width > 0.0:
        bevel = obj.modifiers.new("Small bevel", "BEVEL")
        bevel.width = bevel_width
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

    bpy.ops.mesh.primitive_cylinder_add(vertices=28, radius=radius, depth=length, location=midpoint)
    obj = bpy.context.object
    obj.name = name
    obj.rotation_euler = direction.to_track_quat("Z", "Y").to_euler()
    assign_material(obj, mat)
    apply_object_transform(obj)

    bevel = obj.modifiers.new("Soft segment edges", "BEVEL")
    bevel.width = 0.012
    bevel.segments = 2
    obj.modifiers.new("Weighted normals", "WEIGHTED_NORMAL")
    return obj


def add_bone(
    armature: bpy.types.Object,
    name: str,
    head: tuple[float, float, float],
    tail: tuple[float, float, float],
    parent_name: str | None = None,
    connected: bool = False,
) -> bpy.types.EditBone:
    bone = armature.data.edit_bones.new(name)
    bone.head = head
    bone.tail = tail
    bone.use_deform = True
    if parent_name:
        bone.parent = armature.data.edit_bones[parent_name]
        bone.use_connect = connected
    return bone


def create_armature() -> bpy.types.Object:
    bpy.ops.object.armature_add(enter_editmode=True, location=(0.0, 0.0, 0.0))
    armature = bpy.context.object
    armature.name = "BasicHuman_Armature"
    armature.data.name = "BasicHuman_Skeleton"
    armature.show_in_front = True

    pelvis = armature.data.edit_bones[0]
    pelvis.name = "Pelvis"
    pelvis.head = (0.0, 0.0, 0.86)
    pelvis.tail = (0.0, 0.0, 1.12)
    pelvis.use_deform = True

    add_bone(armature, "Spine", (0.0, 0.0, 1.06), (0.0, 0.0, 1.86), "Pelvis")
    add_bone(armature, "Head", (0.0, -0.02, 1.86), (0.0, -0.03, 2.34), "Spine")

    add_bone(armature, "UpperArm_L", (-0.39, 0.0, 1.75), (-0.72, 0.0, 1.40), "Spine")
    add_bone(armature, "Forearm_L", (-0.72, 0.0, 1.40), (-0.92, 0.0, 0.96), "UpperArm_L", True)
    add_bone(armature, "UpperArm_R", (0.39, 0.0, 1.75), (0.72, 0.0, 1.40), "Spine")
    add_bone(armature, "Forearm_R", (0.72, 0.0, 1.40), (0.92, 0.0, 0.96), "UpperArm_R", True)

    add_bone(armature, "UpperLeg_L", (-0.20, 0.0, 0.96), (-0.24, 0.0, 0.50), "Pelvis")
    add_bone(armature, "LowerLeg_L", (-0.24, 0.0, 0.50), (-0.24, 0.0, 0.10), "UpperLeg_L", True)
    add_bone(armature, "Foot_L", (-0.24, 0.0, 0.10), (-0.24, -0.35, 0.08), "LowerLeg_L", True)
    add_bone(armature, "UpperLeg_R", (0.20, 0.0, 0.96), (0.24, 0.0, 0.50), "Pelvis")
    add_bone(armature, "LowerLeg_R", (0.24, 0.0, 0.50), (0.24, 0.0, 0.10), "UpperLeg_R", True)
    add_bone(armature, "Foot_R", (0.24, 0.0, 0.10), (0.24, -0.35, 0.08), "LowerLeg_R", True)

    bpy.ops.object.mode_set(mode="POSE")
    for pose_bone in armature.pose.bones:
        pose_bone.rotation_mode = "XYZ"
    bpy.ops.object.mode_set(mode="OBJECT")
    return armature


def bind_to_bone(obj: bpy.types.Object, armature: bpy.types.Object, bone_name: str) -> None:
    group = obj.vertex_groups.new(name=bone_name)
    group.add([vertex.index for vertex in obj.data.vertices], 1.0, "ADD")

    modifier = obj.modifiers.new("BasicHuman_Armature", "ARMATURE")
    modifier.object = armature
    obj.parent = armature


def rotation_from_degrees(values: tuple[float, float, float]) -> Euler:
    return Euler(tuple(math.radians(value) for value in values), "XYZ")


def reset_pose(armature: bpy.types.Object) -> None:
    for pose_bone in armature.pose.bones:
        pose_bone.location = (0.0, 0.0, 0.0)
        pose_bone.rotation_euler = (0.0, 0.0, 0.0)
        pose_bone.scale = (1.0, 1.0, 1.0)


def keyframe_bones(armature: bpy.types.Object, frame: int, rotations: dict[str, tuple[float, float, float]]) -> None:
    reset_pose(armature)
    for bone_name, rotation in rotations.items():
        armature.pose.bones[bone_name].rotation_euler = rotation_from_degrees(rotation)

    for pose_bone in armature.pose.bones:
        pose_bone.keyframe_insert(data_path="rotation_euler", frame=frame)


def add_pose_clip(
    armature: bpy.types.Object,
    name: str,
    frames: list[tuple[int, dict[str, tuple[float, float, float]]]],
) -> bpy.types.Action:
    armature.animation_data_create()
    action = bpy.data.actions.new(name)
    armature.animation_data.action = action

    for frame, rotations in frames:
        keyframe_bones(armature, frame, rotations)

    for curve in getattr(action, "fcurves", []):
        for keyframe in curve.keyframe_points:
            keyframe.interpolation = "SINE"

    track = armature.animation_data.nla_tracks.new()
    track.name = name
    strip = track.strips.new(name, frames[0][0], action)
    strip.name = name
    strip.frame_start = frames[0][0]
    strip.frame_end = frames[-1][0]
    strip.blend_type = "REPLACE"
    strip.use_auto_blend = False

    armature.animation_data.action = None
    reset_pose(armature)
    return action


def create_animation_clips(armature: bpy.types.Object) -> None:
    walk_frames = [
        (
            1,
            {
                "Spine": (1.0, 0.0, -2.0),
                "Head": (-1.0, 0.0, 1.0),
                "UpperArm_L": (24.0, 0.0, 2.0),
                "Forearm_L": (-16.0, 0.0, 0.0),
                "UpperArm_R": (-28.0, 0.0, -2.0),
                "Forearm_R": (-10.0, 0.0, 0.0),
                "UpperLeg_L": (-26.0, 0.0, 1.0),
                "LowerLeg_L": (8.0, 0.0, 0.0),
                "Foot_L": (8.0, 0.0, 0.0),
                "UpperLeg_R": (24.0, 0.0, -1.0),
                "LowerLeg_R": (22.0, 0.0, 0.0),
                "Foot_R": (-12.0, 0.0, 0.0),
            },
        ),
        (
            9,
            {
                "Spine": (0.0, 0.0, 1.6),
                "Head": (0.0, 0.0, -0.8),
                "UpperArm_L": (2.0, 0.0, -1.0),
                "Forearm_L": (-20.0, 0.0, 0.0),
                "UpperArm_R": (-5.0, 0.0, 1.0),
                "Forearm_R": (-14.0, 0.0, 0.0),
                "UpperLeg_L": (4.0, 0.0, -1.0),
                "LowerLeg_L": (32.0, 0.0, 0.0),
                "Foot_L": (-8.0, 0.0, 0.0),
                "UpperLeg_R": (-6.0, 0.0, 1.0),
                "LowerLeg_R": (12.0, 0.0, 0.0),
                "Foot_R": (5.0, 0.0, 0.0),
            },
        ),
        (
            17,
            {
                "Spine": (1.0, 0.0, 2.0),
                "Head": (-1.0, 0.0, -1.0),
                "UpperArm_L": (-28.0, 0.0, -2.0),
                "Forearm_L": (-10.0, 0.0, 0.0),
                "UpperArm_R": (24.0, 0.0, 2.0),
                "Forearm_R": (-16.0, 0.0, 0.0),
                "UpperLeg_L": (24.0, 0.0, -1.0),
                "LowerLeg_L": (22.0, 0.0, 0.0),
                "Foot_L": (-12.0, 0.0, 0.0),
                "UpperLeg_R": (-26.0, 0.0, 1.0),
                "LowerLeg_R": (8.0, 0.0, 0.0),
                "Foot_R": (8.0, 0.0, 0.0),
            },
        ),
        (
            25,
            {
                "Spine": (0.0, 0.0, -1.6),
                "Head": (0.0, 0.0, 0.8),
                "UpperArm_L": (-5.0, 0.0, 1.0),
                "Forearm_L": (-14.0, 0.0, 0.0),
                "UpperArm_R": (2.0, 0.0, -1.0),
                "Forearm_R": (-20.0, 0.0, 0.0),
                "UpperLeg_L": (-6.0, 0.0, 1.0),
                "LowerLeg_L": (12.0, 0.0, 0.0),
                "Foot_L": (5.0, 0.0, 0.0),
                "UpperLeg_R": (4.0, 0.0, -1.0),
                "LowerLeg_R": (32.0, 0.0, 0.0),
                "Foot_R": (-8.0, 0.0, 0.0),
            },
        ),
        (
            33,
            {
                "Spine": (1.0, 0.0, -2.0),
                "Head": (-1.0, 0.0, 1.0),
                "UpperArm_L": (24.0, 0.0, 2.0),
                "Forearm_L": (-16.0, 0.0, 0.0),
                "UpperArm_R": (-28.0, 0.0, -2.0),
                "Forearm_R": (-10.0, 0.0, 0.0),
                "UpperLeg_L": (-26.0, 0.0, 1.0),
                "LowerLeg_L": (8.0, 0.0, 0.0),
                "Foot_L": (8.0, 0.0, 0.0),
                "UpperLeg_R": (24.0, 0.0, -1.0),
                "LowerLeg_R": (22.0, 0.0, 0.0),
                "Foot_R": (-12.0, 0.0, 0.0),
            },
        ),
    ]

    idle_frames = [
        (1, {"Spine": (0.0, 0.0, 0.0), "Head": (0.0, 0.0, 0.0), "UpperArm_L": (2.0, 0.0, 0.0), "UpperArm_R": (2.0, 0.0, 0.0)}),
        (31, {"Spine": (1.0, 0.0, 0.0), "Head": (-0.4, 0.0, 0.0), "UpperArm_L": (3.0, 0.0, 0.0), "UpperArm_R": (3.0, 0.0, 0.0)}),
        (61, {"Spine": (0.0, 0.0, 0.0), "Head": (0.0, 0.0, 0.0), "UpperArm_L": (2.0, 0.0, 0.0), "UpperArm_R": (2.0, 0.0, 0.0)}),
    ]

    add_pose_clip(armature, WALK_ANIMATION, walk_frames)
    add_pose_clip(armature, IDLE_ANIMATION, idle_frames)


def create_model() -> None:
    clear_scene()

    skin = material("Warm skin", (0.86, 0.62, 0.42, 1.0))
    shirt = material("Muted blue shirt", (0.18, 0.34, 0.52, 1.0))
    pants = material("Dark work pants", (0.11, 0.13, 0.17, 1.0))
    shoes = material("Graphite shoes", (0.035, 0.04, 0.045, 1.0))
    eye_mat = material("Simple eyes", (0.02, 0.025, 0.03, 1.0))

    armature = create_armature()

    parts: list[tuple[bpy.types.Object, str]] = [
        (create_cube("Body_Torso", (0.0, 0.0, 1.45), (0.72, 0.34, 0.95), shirt, 0.06), "Spine"),
        (create_cube("Body_Hips", (0.0, 0.0, 0.96), (0.62, 0.32, 0.24), pants, 0.045), "Pelvis"),
        (create_sphere("Head_Sphere", (0.0, -0.03, 2.23), 0.34, skin), "Head"),
        (create_sphere("Eye_L", (-0.11, -0.36, 2.28), 0.035, eye_mat, (1.0, 0.45, 1.0)), "Head"),
        (create_sphere("Eye_R", (0.11, -0.36, 2.28), 0.035, eye_mat, (1.0, 0.45, 1.0)), "Head"),
        (create_limb_segment("Arm_L_Upper", (-0.39, 0.0, 1.75), (-0.72, 0.0, 1.40), 0.105, skin), "UpperArm_L"),
        (create_limb_segment("Arm_L_Lower", (-0.72, 0.0, 1.40), (-0.92, 0.0, 0.96), 0.095, skin), "Forearm_L"),
        (create_sphere("Hand_L", (-0.94, -0.01, 0.88), 0.105, skin), "Forearm_L"),
        (create_limb_segment("Arm_R_Upper", (0.39, 0.0, 1.75), (0.72, 0.0, 1.40), 0.105, skin), "UpperArm_R"),
        (create_limb_segment("Arm_R_Lower", (0.72, 0.0, 1.40), (0.92, 0.0, 0.96), 0.095, skin), "Forearm_R"),
        (create_sphere("Hand_R", (0.94, -0.01, 0.88), 0.105, skin), "Forearm_R"),
        (create_limb_segment("Leg_L_Upper", (-0.20, 0.0, 0.96), (-0.24, 0.0, 0.50), 0.125, pants), "UpperLeg_L"),
        (create_limb_segment("Leg_L_Lower", (-0.24, 0.0, 0.50), (-0.24, 0.0, 0.10), 0.11, pants), "LowerLeg_L"),
        (create_cube("Foot_L", (-0.24, -0.15, 0.055), (0.24, 0.44, 0.09), shoes, 0.025), "Foot_L"),
        (create_limb_segment("Leg_R_Upper", (0.20, 0.0, 0.96), (0.24, 0.0, 0.50), 0.125, pants), "UpperLeg_R"),
        (create_limb_segment("Leg_R_Lower", (0.24, 0.0, 0.50), (0.24, 0.0, 0.10), 0.11, pants), "LowerLeg_R"),
        (create_cube("Foot_R", (0.24, -0.15, 0.055), (0.24, 0.44, 0.09), shoes, 0.025), "Foot_R"),
    ]

    for obj, bone_name in parts:
        bind_to_bone(obj, armature, bone_name)

    create_animation_clips(armature)

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
    bpy.context.scene.frame_start = 1
    bpy.context.scene.frame_end = 33
    bpy.context.scene.frame_set(9)
    bpy.context.scene.render.fps = FPS

    BLEND_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    GLB_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    GAME_GLB_OUTPUT.parent.mkdir(parents=True, exist_ok=True)

    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_OUTPUT))
    bpy.ops.export_scene.gltf(
        filepath=str(GLB_OUTPUT),
        export_format="GLB",
        export_apply=True,
        use_selection=False,
        export_animations=True,
        export_animation_mode="NLA_TRACKS",
        export_nla_strips=True,
        export_force_sampling=True,
        export_frame_range=False,
        export_anim_slide_to_zero=True,
        export_skins=True,
        export_def_bones=True,
    )
    shutil.copy2(GLB_OUTPUT, GAME_GLB_OUTPUT)

    bpy.context.scene.render.filepath = str(PREVIEW_OUTPUT)
    bpy.ops.render.render(write_still=True)


if __name__ == "__main__":
    create_model()
