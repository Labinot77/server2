# fw-housing wall kit: (re)builds the collision of every fw_wall_<w>x<h> panel and re-exports the .ydr files.
#
# Every panel gets a CONCRETE collision mesh (panel-sized box) with the vanilla prop flags, in drawable space with no
# transform. (A Bound Box gets an offset transform and Sollumz writes the child bounding box without it: half the wall is culled.)
#
# 1. Open the wallkit.blend that make_wall_kit.py made (same folder as fw-walls/).
# 2. Scripting tab > Open > this file > Run Script.
# 3. fw-walls/stream/*.ydr are replaced. Copy them to your server, restart fw-walls, rejoin (clear your cache if needed).
import bpy, bmesh, os, shutil, re, sys

COLLISION = 'CONCRETE'
# Vanilla prop bound flags: what the bound IS (type) and what it collides WITH (include).
TYPE_FLAGS = ('map_weapon', 'map_dynamic', 'map_animal', 'map_cover', 'map_vehicle')
INCLUDE_FLAGS = ('vehicle_not_bvh', 'vehicle_bvh', 'ped', 'ragdoll', 'animal', 'animal_ragdoll', 'object', 'plant', 'projectile',
                 'explosion', 'forklift_forks', 'test_weapon', 'test_camera', 'test_ai', 'test_script', 'test_vehicle_wheel', 'glass')


def sz(suffix):
    """Find a loaded Sollumz module by its path, whatever the add-on folder is called."""
    for name, mod in sys.modules.items():
        if name.endswith(suffix) and 'sollumz' in name.lower():
            return mod
    raise RuntimeError('Sollumz is not enabled (Edit > Preferences > Add-ons).')


def popup(msg, icon='INFO'):
    print('fw wall collisions:', msg)
    bpy.context.window_manager.popup_menu(lambda self, _: self.layout.label(text=msg), title='Wall collisions', icon=icon)


def fail(msg):
    popup(msg, 'ERROR')
    raise RuntimeError(msg)


SollumType = sz('.sollumz_properties').SollumType
BOUND_TYPES = sz('.sollumz_properties').BOUND_TYPES
helper = sz('.tools.blenderhelper')
colmats = sz('.ybn.collision_materials')

blend_dir = bpy.path.abspath('//')
if not blend_dir:
    fail('Open the wallkit.blend made by make_wall_kit.py first.')
out = os.path.join(blend_dir, 'fw-walls', 'stream')
os.makedirs(out, exist_ok=True)

if bpy.context.mode != 'OBJECT':
    bpy.ops.object.mode_set(mode='OBJECT')

drawables = sorted((o for o in bpy.data.objects if o.sollum_type == SollumType.DRAWABLE and re.fullmatch(r'fw_wall_\d+x\d+', o.name)), key=lambda o: o.name)
if not drawables:
    fail('No fw_wall_<w>x<h> drawables in this file: run make_wall_kit.py first (or open its wallkit.blend).')

concrete = next(i for i, m in enumerate(colmats.collisionmats) if m.name == COLLISION)
col_mat = colmats.create_collision_material_from_index(concrete)


def remove_bounds(obj):
    for child in list(obj.children):
        remove_bounds(child)
        if child.sollum_type in BOUND_TYPES:
            bpy.data.objects.remove(child, do_unlink=True)


def mesh_extents(drawable):
    """Min / max corner of the panel's visible mesh, in drawable space (falls back to the name + 10 cm thick)."""
    meshes = [c for c in drawable.children_recursive if c.type == 'MESH' and c.sollum_type == SollumType.DRAWABLE_MODEL]
    if meshes:
        pts = [m.matrix_local @ v.co for m in meshes for v in m.data.vertices]
        return [min(p[i] for p in pts) for i in range(3)], [max(p[i] for p in pts) for i in range(3)]
    w, h = (int(n) / 100 for n in re.findall(r'\d+', drawable.name))
    return [-w / 2, -0.05, 0.0], [w / 2, 0.05, h]


def set_flags(obj):
    for flags, on in ((obj.composite_flags1, TYPE_FLAGS), (obj.composite_flags2, INCLUDE_FLAGS)):
        for name, prop in flags.bl_rna.properties.items():
            if prop.type == 'BOOLEAN':
                setattr(flags, name, name in on)


for d in drawables:
    remove_bounds(d)
    lo, hi = mesh_extents(d)

    composite = helper.create_empty_object(SollumType.BOUND_COMPOSITE, d.name + '.col')
    composite.parent = d

    # Collision mesh = box with the panel's exact extents, object at the drawable origin (identity transform).
    box = helper.create_blender_object(SollumType.BOUND_GEOMETRY, d.name + '.geom')
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co = [lo[i] if v.co[i] < 0 else hi[i] for i in range(3)]
    bm.to_mesh(box.data)
    bm.free()
    box.data.materials.append(col_mat)
    box.parent = composite
    set_flags(box)
    print(f'{d.name}: box {[round(hi[i] - lo[i], 3) for i in range(3)]} m')

# // Export the drawables (GEN8 / FiveM) \\
settings = sz('.sollumz_preferences').get_export_settings()
from szio.gta5 import AssetFormat, is_provider_available
NATIVE = is_provider_available(AssetFormat.NATIVE)
settings.target_formats = {'NATIVE'} if NATIVE else {'CWXML'}
settings.target_versions = {'GEN8'}
settings.limit_to_selected = True

bpy.ops.object.select_all(action='DESELECT')
for d in drawables:
    d.select_set(True)
bpy.context.view_layer.objects.active = drawables[0]
bpy.ops.sollumz.export_assets(directory=out, direct_export=True)
bpy.ops.wm.save_mainfile()

# Sollumz writes into stream/gen8/ (plus loose .dds folders): keep only the game files, straight in stream/.
for sub in ('gen8', 'GEN8'):
    folder = os.path.join(out, sub)
    if os.path.isdir(folder):
        for f in os.listdir(folder):
            if f.endswith(('.ydr', '.ytd', '.ytyp', '.xml')):
                os.replace(os.path.join(folder, f), os.path.join(out, f))
        shutil.rmtree(folder, ignore_errors=True)

if NATIVE:
    popup(f'Done: {len(drawables)} walls with collision exported to {out}', 'CHECKMARK')
else:
    popup('Exported as XML (.ydr.xml). Install PyMateria (Sollumz preferences > Dependencies) and run again for .ydr files.')
