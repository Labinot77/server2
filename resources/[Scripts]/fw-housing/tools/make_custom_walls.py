# fw-housing custom walls - one click build for Blender + Sollumz.
# 8 materials x 5 sizes = 40 wall panels (fw_cw_<material>_<size>), each with collision and a colour (tint) palette.
# Textures are generated here (tileable, 512 px per metre), nothing else is needed.
#
# 1. Open Blender, File > Save As > save a .blend in an empty folder.
# 2. Scripting tab > Open > this file > Run Script (takes a minute).
# 3. <folder>/fw-custom-walls/ is a ready resource: copy it to your server, `ensure fw-custom-walls`, restart,
#    clear your FiveM cache. fw-housing lists the panels under Structure > Custom Walls.
#
# MATERIALS / SIZES / TINTS must match Config.CustomWalls in fw-housing/config/sh_mlo.lua.
# Errors are shown in Window > Toggle System Console.
import bpy, bmesh, os, struct, sys, shutil
import numpy as np

RESOURCE, TXD = 'fw-custom-walls', 'fw_custom_walls'
THICK = 0.10   # m
PX = 512       # texture pixels per metre (textures repeat every metre)
SIZES = [('xs', 0.5, 0.5), ('s', 1.0, 1.0), ('m', 1.0, 2.5), ('l', 2.0, 2.5), ('xl', 3.0, 3.0)]
MATERIALS = ['plaster', 'woodlight', 'wooddark', 'tile', 'brick', 'brickred', 'stone', 'marble']
TINTS = ['#FFFFFF', '#EADDC4', '#CDB891', '#B5B5B5', '#6E6E6E', '#2B2B2B', '#9CAF88', '#2F4B37',
         '#9EC5E0', '#2E4A7D', '#B5583B', '#E3B5B0', '#D4A63A', '#8A6239', '#5A3D26', '#7A2633']
TYPE_FLAGS = ('map_weapon', 'map_dynamic', 'map_animal', 'map_cover', 'map_vehicle')
INCLUDE_FLAGS = ('vehicle_not_bvh', 'vehicle_bvh', 'ped', 'ragdoll', 'animal', 'animal_ragdoll', 'object', 'plant', 'projectile',
                 'explosion', 'forklift_forks', 'test_weapon', 'test_camera', 'test_ai', 'test_script', 'test_vehicle_wheel', 'glass')
rng = np.random.default_rng(7)


# // Tileable procedural textures (float RGB 0..1, PX x PX) \\

def noise(fx, fy=None, n=PX):
    """Periodic smooth noise 0..1; fx / fy = feature frequency per tile along x / y (anisotropic = streaks)."""
    fy = fx if fy is None else fy
    f = np.fft.fftfreq(n) * n
    filt = np.exp(-((f[None, :] / fx) ** 2 + (f[:, None] / fy) ** 2))
    v = np.real(np.fft.ifft2(np.fft.fft2(rng.random((n, n))) * filt))
    return (v - v.min()) / (np.ptp(v) + 1e-9)


def rgb(c):
    return np.array(c, dtype=np.float32) / 255


def shade(base, amount):
    return np.clip(base[None, None, :] * (1 + amount)[..., None], 0, 1)


def blocks(rows, cols, offset, gap):
    """Running bond grid: cell id per pixel and mortar mask."""
    y, x = np.mgrid[0:PX, 0:PX]
    h, w = PX // rows, PX // cols
    r = y // h
    xs = (x + (r % 2) * offset) % PX
    c = xs // w
    mortar = ((y % h) < gap) | ((xs % w) < gap)
    return r * cols + c, mortar


def tex_plaster():
    return shade(rgb((232, 230, 226)), (noise(3) - .5) * .06 + (noise(60) - .5) * .05)


def tex_wood(base, planks=4):
    y, x = np.mgrid[0:PX, 0:PX]
    w = PX // planks
    plank = x // w
    tone = rng.uniform(-.12, .12, planks)[plank]
    grain = (noise(90, 3) - .5) * .35 + (noise(25, 1.5) - .5) * .25
    seam = ((x % w) < 2) * -.45
    return shade(rgb(base), tone + grain + seam)


def tex_tile():
    cell, grout = blocks(4, 4, 0, 4)
    tone = rng.uniform(-.04, .04, 16)[cell]
    img = shade(rgb((236, 236, 232)), tone + (noise(40) - .5) * .03)
    img[grout] = rgb((160, 160, 158))
    return img


def tex_brick(base, mortar):
    cell, joint = blocks(16, 4, PX // 8, 5)
    tone = rng.uniform(-.18, .18, 64)[cell]
    img = shade(rgb(base), tone + (noise(80) - .5) * .25 + (noise(12) - .5) * .1)
    img[joint] = shade(rgb(mortar), (noise(100) - .5) * .15)[joint]
    return img


def tex_stone(cells=26):
    seeds = rng.random((cells, 2)) * PX
    tiled = np.concatenate([seeds + np.array([dx, dy]) * PX for dx in (-1, 0, 1) for dy in (-1, 0, 1)])
    ids, edge = np.zeros((PX, PX), np.int32), np.zeros((PX, PX), np.float32)
    x = np.arange(PX, dtype=np.float32)
    for r in range(0, PX, 64):  # chunked nearest / second nearest seed (wrapped = tileable)
        yy, xx = np.meshgrid(np.arange(r, r + 64, dtype=np.float32), x, indexing='ij')
        d = (xx[..., None] - tiled[:, 0]) ** 2 + (yy[..., None] - tiled[:, 1]) ** 2
        part = np.partition(d, 1, axis=-1)
        ids[r:r + 64] = np.argmin(d, axis=-1) % cells
        edge[r:r + 64] = np.sqrt(part[..., 1]) - np.sqrt(part[..., 0])
    tone = rng.uniform(-.2, .15, cells)[ids]
    img = shade(rgb((150, 146, 138)), tone + (noise(70) - .5) * .25 + (noise(8) - .5) * .12)
    img[edge < 4] = rgb((96, 94, 90))
    return img


def tex_marble():
    y, x = np.mgrid[0:PX, 0:PX] / PX
    phase = 2 * np.pi * (2 * x + y) + noise(4) * 5
    vein = np.exp(-(np.abs(np.sin(phase)) / .05) ** 2) * (0.4 + noise(10) * .6)
    return shade(rgb((240, 240, 238)), -vein * .32 + (noise(30) - .5) * .04)


GENERATORS = {
    'plaster': tex_plaster,
    'woodlight': lambda: tex_wood((198, 164, 120)),
    'wooddark': lambda: tex_wood((104, 70, 46)),
    'tile': tex_tile,
    'brick': lambda: tex_brick((98, 98, 102), (152, 152, 150)),
    'brickred': lambda: tex_brick((156, 72, 52), (178, 168, 152)),
    'stone': tex_stone,
    'marble': tex_marble,
}


# // DDS writers \\

def bc1(img):
    """DXT1 encode (bounding box endpoints), img = float RGB, size multiple of 4."""
    h, w = img.shape[:2]
    b = (img * 255).astype(np.float32).reshape(h // 4, 4, w // 4, 4, 3).transpose(0, 2, 1, 3, 4).reshape(-1, 16, 3)
    hi, lo = b.max(1), b.min(1)

    def p565(c):
        c = np.clip(np.round(c), 0, 255).astype(np.uint32)
        return ((c[:, 0] >> 3) << 11) | ((c[:, 1] >> 2) << 5) | (c[:, 2] >> 3)

    def u565(v):
        return np.stack([(v >> 11) * 255 / 31, ((v >> 5) & 63) * 255 / 63, (v & 31) * 255 / 31], -1).astype(np.float32)

    c0, c1 = p565(hi), p565(lo)
    swap = c0 < c1
    c0, c1 = np.where(swap, c1, c0), np.where(swap, c0, c1)
    e0, e1 = u565(c0), u565(c1)
    pal = np.stack([e0, e1, (2 * e0 + e1) / 3, (e0 + 2 * e1) / 3], 1)
    idx = np.argmin(((b[:, :, None, :] - pal[:, None, :, :]) ** 2).sum(-1), -1).astype(np.uint32)
    idx[c0 == c1] = 0
    bits = (idx << (np.arange(16, dtype=np.uint32) * 2)).sum(1).astype(np.uint32)
    return np.stack([c0 | (c1 << 16), bits], 1).astype('<u4').tobytes()


def write_dds(path, img):
    """BC1 with full mip chain down to 4x4."""
    mips, data = [], b''
    while True:
        mips.append(img)
        if img.shape[0] <= 4:
            break
        img = img.reshape(img.shape[0] // 2, 2, img.shape[1] // 2, 2, 3).mean((1, 3))
    for m in mips:
        data += bc1(m)
    n = PX
    header = struct.pack('<4s7I44x8I5I', b'DDS ', 124, 0xA1007, n, n, n * n // 2, 0, len(mips),
                         32, 0x4, 0x31545844, 0, 0, 0, 0, 0, 0x401008, 0, 0, 0, 0)
    with open(path, 'wb') as f:
        f.write(header + data)


def write_palette(path, width=32):
    """Uncompressed BGRA, one 1 px row per tint."""
    header = struct.pack('<4s7I44x8I5I', b'DDS ', 124, 0x100F, len(TINTS), width, width * 4, 0, 1,
                         32, 0x41, 0, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000, 0x1000, 0, 0, 0, 0)
    with open(path, 'wb') as f:
        f.write(header)
        for c in TINTS:
            r, g, b = bytes.fromhex(c[1:])
            f.write(bytes((b, g, r, 255)) * width)


# // Blender / Sollumz \\

def sz(suffix):
    for name, mod in sys.modules.items():
        if name.endswith(suffix) and 'sollumz' in name.lower():
            return mod
    raise RuntimeError('Sollumz is not enabled (Edit > Preferences > Add-ons).')


def popup(msg, icon='INFO'):
    print('fw custom walls:', msg)
    bpy.context.window_manager.popup_menu(lambda self, _: self.layout.label(text=msg), title='Custom walls', icon=icon)


def fail(msg):
    popup(msg, 'ERROR')
    raise RuntimeError(msg)


blend_dir = bpy.path.abspath('//')
if not blend_dir:
    fail('Save the .blend file first (File > Save As).')
tex_dir = os.path.join(blend_dir, 'textures')
out = os.path.join(blend_dir, RESOURCE, 'stream')
os.makedirs(tex_dir, exist_ok=True)
os.makedirs(out, exist_ok=True)

shaders = sz('.ydr.shader_materials')
mat_ops = sz('.ydr.operators.materials')
colmats = sz('.ybn.collision_materials')
helper = sz('.tools.blenderhelper')
SollumType = sz('.sollumz_properties').SollumType
scene = bpy.context.scene
if not hasattr(scene, 'sz_txds'):
    fail('Your Sollumz is too old: update it from github.com/Sollumz/Sollumz/releases')

settings = sz('.sollumz_preferences').get_export_settings()
from szio.gta5 import AssetFormat, is_provider_available
NATIVE = is_provider_available(AssetFormat.NATIVE)
settings.target_formats = {'NATIVE'} if NATIVE else {'CWXML'}
settings.target_versions = {'GEN8'}
settings.limit_to_selected = True

if bpy.context.mode != 'OBJECT':
    bpy.ops.object.mode_set(mode='OBJECT')

# Clean up a previous run
for obj in list(bpy.data.objects):
    if obj.name.startswith('fw_cw_'):
        bpy.data.objects.remove(obj, do_unlink=True)
for i in reversed(range(len(scene.ytyps))):
    if scene.ytyps[i].name == TXD:
        scene.ytyps.remove(i)

# Textures
images = {}
for m in MATERIALS:
    path = os.path.join(tex_dir, f'fw_cw_{m}.dds')
    write_dds(path, GENERATORS[m]())
    images[m] = bpy.data.images.load(path, check_existing=True)
    images[m].reload()
    print('fw custom walls: texture', m)
palette_path = os.path.join(tex_dir, 'fw_cw_palette.dds')
write_palette(palette_path)
palette = bpy.data.images.load(palette_path, check_existing=True)
palette.reload()

# One tint material per surface: texture x palette row (SetObjectTextureVariation picks the row)
materials = {}
for m in MATERIALS:
    mat = shaders.create_shader('default_tnt.sps')
    mat.name = f'fw_cw_{m}'
    for node in mat.node_tree.nodes:
        if isinstance(node, bpy.types.ShaderNodeTexImage):
            node.image = palette if node.name == 'TintPaletteSampler' else images[m]
            node.texture_properties.embedded = False
            if node.image == palette:
                node.interpolation = 'Closest'
    materials[m] = mat

# Panels: origin bottom centre, UVs in metres (texture repeats every metre)
panels = []
for mi, m in enumerate(MATERIALS):
    for si, (sid, W, H) in enumerate(SIZES):
        name = f'fw_cw_{m}_{sid}'
        T = THICK / 2
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
        mesh.materials.append(materials[m])
        obj = bpy.data.objects.new(name, mesh)
        obj.location = (si * 4.0, mi * 2.0, 0)
        scene.collection.objects.link(obj)
        mat_ops.post_create_shader_update_object(obj, materials[m])
        panels.append((name, obj, W, H))

bpy.ops.object.select_all(action='DESELECT')
for _, obj, _, _ in panels:
    obj.select_set(True)
bpy.context.view_layer.objects.active = panels[0][1]
scene.create_seperate_drawables = True
scene.auto_create_embedded_col = False
bpy.ops.sollumz.converttodrawable()
drawables = [bpy.data.objects[name] for name, _, _, _ in panels]

# Collision: Composite > Geometry (panel-sized box) in drawable space, vanilla prop flags
concrete = next(i for i, c in enumerate(colmats.collisionmats) if c.name == 'CONCRETE')
col_mat = colmats.create_collision_material_from_index(concrete)
for d, (_, _, W, H) in zip(drawables, panels):
    composite = helper.create_empty_object(SollumType.BOUND_COMPOSITE, d.name + '.col')
    composite.parent = d
    geom = helper.create_blender_object(SollumType.BOUND_GEOMETRY, d.name + '.geom')
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for vert in bm.verts:
        vert.co = (vert.co.x * W, vert.co.y * THICK, (vert.co.z + 0.5) * H)
    bm.to_mesh(geom.data)
    bm.free()
    geom.data.materials.append(col_mat)
    geom.parent = composite
    for flags, on in ((geom.composite_flags1, TYPE_FLAGS), (geom.composite_flags2, INCLUDE_FLAGS)):
        for fname, prop in flags.bl_rna.properties.items():
            if prop.type == 'BOOLEAN':
                setattr(flags, fname, fname in on)

# Texture dictionary
txds = scene.sz_txds.texture_dictionaries
for i in reversed(range(len(txds))):
    if txds[i].name == TXD:
        txds.remove(i)
txd = scene.sz_txds.new_texture_dictionary(TXD)
for img in list(images.values()) + [palette]:
    txd.new_texture(img)

# Archetypes: embedded collision only loads when the physics dictionary is the archetype's own name
bpy.ops.sollumz.createytyp()
scene.ytyps[scene.ytyp_index].name = TXD
bpy.ops.object.select_all(action='DESELECT')
for d in drawables:
    d.select_set(True)
bpy.context.view_layer.objects.active = drawables[0]
bpy.ops.sollumz.createarchetypefromselected()
for arch in scene.ytyps[scene.ytyp_index].archetypes:
    arch.texture_dictionary = TXD
    arch.lod_dist = 100.0
    arch.physics_dictionary = arch.asset_name
    arch.flags.total = '32'

# Export
bpy.ops.object.select_all(action='DESELECT')
for d in drawables:
    d.select_set(True)
bpy.ops.sollumz.export_assets(directory=out, direct_export=True)
txds.select(next(i for i, t in enumerate(txds) if t.name == TXD))
bpy.ops.sollumz.export_ytd(directory=out, direct_export=True)
bpy.ops.sollumz.export_ytyp_io(directory=out, direct_export=True)
bpy.ops.wm.save_mainfile()

# Sollumz writes into stream/gen8/: keep only the game files, straight in stream/
for sub in ('gen8', 'GEN8'):
    folder = os.path.join(out, sub)
    if os.path.isdir(folder):
        for f in os.listdir(folder):
            if f.endswith(('.ydr', '.ytd', '.ytyp', '.xml')):
                os.replace(os.path.join(folder, f), os.path.join(out, f))
        shutil.rmtree(folder, ignore_errors=True)

with open(os.path.join(out, '..', 'fxmanifest.lua'), 'w') as f:
    f.write("fx_version 'cerulean'\ngame 'gta5'\nthis_is_a_map 'yes'\n\n"
            f"data_file 'DLC_ITYP_REQUEST' 'stream/{TXD}.ytyp'\n")

files = sorted(os.listdir(out))
missing = [f for f in (TXD + '.ytd', TXD + '.ytyp') if f not in files and f + '.xml' not in files]
if missing:
    fail(f'{", ".join(missing)} was not exported: check the System Console for the Sollumz error and send it.')
if NATIVE:
    popup(f'Done: {len(files)} files in {out}', 'CHECKMARK')
else:
    popup('Exported as XML (.xml). Install PyMateria (Sollumz preferences > Dependencies) and run again for binary files.')
