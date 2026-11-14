# fw-housing wall kit v2 - one click build for Blender + Sollumz (uses fw_wall_plaster.dds, not .png).
#
# 1. Put this file and fw_wall_plaster.dds in one folder, open Blender, File > Save As > save a .blend in that folder.
# 2. Scripting tab > Open > this file > Run Script.
# 3. Done (popup + System Console): <folder>/fw-walls/stream/ contains 16 fw_wall_*.ydr, fw_walls.ytd and fw_walls.ytyp.
#    The whole fw-walls folder is a ready resource: copy it to your server, ensure fw-walls before fw-housing.
#
# Needs a recent Sollumz (with the "Texture Dictionaries" panel). Errors are shown in Window > Toggle System Console.
import bpy, bmesh, os, sys

SIZES = [25, 50, 100, 200]          # cm, widths and heights
THICK = 0.10                        # m
TXD, TEX, YTYP = 'fw_walls', 'fw_wall_plaster', 'fw_walls'
COLLISION = 'CONCRETE'


def sz(suffix):
    """Find a loaded Sollumz module by its path, whatever the add-on folder is called."""
    for name, mod in sys.modules.items():
        if name.endswith(suffix) and 'sollumz' in name.lower():
            return mod
    raise RuntimeError('Sollumz is not enabled (Edit > Preferences > Add-ons).')


def fail(msg):
    bpy.context.window_manager.popup_menu(lambda self, _: self.layout.label(text=msg), title='Wall kit', icon='ERROR')
    raise RuntimeError(msg)


blend_dir = bpy.path.abspath('//')
if not blend_dir:
    fail('Save the .blend file first (File > Save As), next to fw_wall_plaster.dds.')
png = os.path.join(blend_dir, TEX + '.dds')  # GTA textures must be DDS
if not os.path.isfile(png):
    fail(f'{TEX}.dds not found in {blend_dir} (download it and put it next to the .blend)')
out = os.path.join(blend_dir, 'fw-walls', 'stream')
os.makedirs(out, exist_ok=True)

shaders = sz('.ydr.shader_materials')
mat_ops = sz('.ydr.operators.materials')
colmats = sz('.ybn.collision_materials')
bounds = sz('.tools.boundhelper')
SollumType = sz('.sollumz_properties').SollumType
scene = bpy.context.scene
if not hasattr(scene, 'sz_txds'):
    fail('Your Sollumz is too old: update it from github.com/Sollumz/Sollumz/releases')

# FiveM = GEN8. Binary .ydr needs Sollumz's PyMateria (Windows), otherwise CodeWalker XML is written.
settings = sz('.sollumz_preferences').get_export_settings()
from szio.gta5 import AssetFormat, is_provider_available
NATIVE = is_provider_available(AssetFormat.NATIVE)
settings.target_formats = {'NATIVE'} if NATIVE else {'CWXML'}
settings.target_versions = {'GEN8'}
settings.limit_to_selected = True

if bpy.context.mode != 'OBJECT':
    bpy.ops.object.mode_set(mode='OBJECT')

# // Clean up a previous run \\
for obj in list(bpy.data.objects):
    if obj.name.startswith('fw_wall_'):
        bpy.data.objects.remove(obj, do_unlink=True)
for i in reversed(range(len(scene.ytyps))):
    if scene.ytyps[i].name == YTYP:
        scene.ytyps.remove(i)

# // Shared material: Sollumz default.sps with the plaster texture, read from fw_walls.ytd \\
image = bpy.data.images.load(png, check_existing=True)
mat = shaders.create_shader('default.sps')
mat.name = TEX
for node in mat.node_tree.nodes:
    if isinstance(node, bpy.types.ShaderNodeTexImage):
        node.image = image
        node.texture_properties.embedded = False

# // 16 panels, origin bottom centre, UVs in metres \\
meshes = []
for wi, w in enumerate(SIZES):
    for hi, h in enumerate(SIZES):
        name = f'fw_wall_{w}x{h}'
        W, H, T = w / 100, h / 100, THICK / 2
        bm = bmesh.new()
        v = [bm.verts.new(c) for c in [(-W/2, -T, 0), (W/2, -T, 0), (W/2, T, 0), (-W/2, T, 0),
                                       (-W/2, -T, H), (W/2, -T, H), (W/2, T, H), (-W/2, T, H)]]
        for f in [(0, 1, 5, 4), (2, 3, 7, 6), (1, 2, 6, 5), (3, 0, 4, 7), (4, 5, 6, 7), (3, 2, 1, 0)]:
            bm.faces.new([v[i] for i in f])
        uv = bm.loops.layers.uv.new('UVMap')
        for face in bm.faces:
            n = face.normal
            for loop in face.loops:
                c = loop.vert.co
                loop[uv].uv = (c.y, c.z) if abs(n.x) > 0.5 else (c.x, c.y) if abs(n.z) > 0.5 else (c.x, c.z)
        mesh = bpy.data.meshes.new(name)
        bm.to_mesh(mesh)
        bm.free()
        mesh.materials.append(mat)
        obj = bpy.data.objects.new(name, mesh)
        obj.location = (wi * 3.0, hi * 3.0, 0)
        scene.collection.objects.link(obj)
        mat_ops.post_create_shader_update_object(obj, mat)
        meshes.append(obj)

# // Convert: one drawable per panel \\
bpy.ops.object.select_all(action='DESELECT')
for obj in meshes:
    obj.select_set(True)
bpy.context.view_layer.objects.active = meshes[0]
scene.create_seperate_drawables = True
scene.auto_create_embedded_col = False
bpy.ops.sollumz.converttodrawable()

concrete = next(i for i, m in enumerate(colmats.collisionmats) if m.name == COLLISION)
col_mat = colmats.create_collision_material_from_index(concrete)
drawables = [bpy.data.objects[f'fw_wall_{w}x{h}'] for w in SIZES for h in SIZES]

# Embedded collision: Composite > Geometry with prop flags (BVH + map flags is for .ybn map collision).
for d in drawables:
    model = next(c for c in d.children if c.type == 'MESH')
    col = bpy.data.objects.new(d.name + '_col', model.data.copy())
    scene.collection.objects.link(col)
    col.data.materials.clear()
    col.data.materials.append(col_mat)
    col.parent = d
    composite = bounds.convert_obj_to_composite(col, SollumType.BOUND_GEOMETRY, scene.sz_default_flag_preset_name)
    composite.parent = d
    composite.name = d.name + '.col'
    # Prop collision: type OBJECT, collides with peds, vehicles, weapons, cameras and the map.
    geom = next(c for c in composite.children)
    for flag in geom.composite_flags1.bl_rna.properties.keys():
        if geom.composite_flags1.bl_rna.properties[flag].type == 'BOOLEAN':
            setattr(geom.composite_flags1, flag, flag == 'object')
    for flag in ('map_weapon', 'map_dynamic', 'map_animal', 'map_cover', 'map_vehicle'):
        setattr(geom.composite_flags2, flag, True)

# // Texture dictionary fw_walls.ytd \\
txds = scene.sz_txds.texture_dictionaries
for i in reversed(range(len(txds))):
    if txds[i].name == TXD:
        txds.remove(i)
scene.sz_txds.new_texture_dictionary(TXD).new_texture(image)

# // YTYP with one archetype per panel \\
bpy.ops.sollumz.createytyp()
scene.ytyps[scene.ytyp_index].name = YTYP
bpy.ops.object.select_all(action='DESELECT')
for d in drawables:
    d.select_set(True)
bpy.context.view_layer.objects.active = drawables[0]
bpy.ops.sollumz.createarchetypefromselected()
for arch in scene.ytyps[scene.ytyp_index].archetypes:
    arch.texture_dictionary = TXD
    arch.lod_dist = 100.0
    arch.physics_dictionary = ''  # collision is embedded in the .ydr

# // Export \\
bpy.ops.object.select_all(action='DESELECT')
for d in drawables:
    d.select_set(True)
bpy.ops.sollumz.export_assets(directory=out, direct_export=True)
bpy.ops.sollumz.export_ytd(directory=out, direct_export=True)
bpy.ops.sollumz.export_ytyp_io(directory=out, direct_export=True)

bpy.ops.wm.save_mainfile()
# Version subfolders (gen8/) -> straight into stream/
for sub in ('gen8', 'GEN8'):
    folder = os.path.join(out, sub)
    if os.path.isdir(folder):
        for f in os.listdir(folder):
            os.replace(os.path.join(folder, f), os.path.join(out, f))
        os.rmdir(folder)

with open(os.path.join(out, '..', 'fxmanifest.lua'), 'w') as f:
    f.write("fx_version 'cerulean'\ngame 'gta5'\nthis_is_a_map 'yes'\n\ndata_file 'DLC_ITYP_REQUEST' 'stream/fw_walls.ytyp'\n")

files = sorted(os.listdir(out))
print('fw wall kit:', len(files), 'files in', out, files)
msg = f'Done: {len(files)} files in {out}' if NATIVE else \
    'Exported as XML (.ydr.xml). Install PyMateria (Sollumz preferences > Dependencies) and run again for .ydr files.'
bpy.context.window_manager.popup_menu(lambda self, _: self.layout.label(text=msg), title='Wall kit', icon='CHECKMARK' if NATIVE else 'INFO')
