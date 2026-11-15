# Blender (Sollumz): stretch the tablet screen's UVs over the whole screen texture (0..1), so a DUI page fills
# the screen. Import sf_prop_sf_tablet_01a_dui_01.ydr (and _02), run this in the Scripting tab, export again.
# Then in fw-dui config/sh_config.lua set the tablet's Resolution = { 1280, 1016 } and remove its Viewport.
import bpy

TEXTURE = 'prop_arena_tablet_drone_screen'

def uses_screen(mat):
    return mat and mat.use_nodes and any(
        n.type == 'TEX_IMAGE' and n.image and TEXTURE in n.image.name.lower() for n in mat.node_tree.nodes)

fixed = 0
for ob in bpy.data.objects:
    if ob.type != 'MESH' or not ob.data.uv_layers:
        continue
    me, slots = ob.data, [i for i, s in enumerate(ob.material_slots) if uses_screen(s.material)]
    loops = [l for p in me.polygons if p.material_index in slots for l in p.loop_indices]
    if not loops:
        continue
    uv = me.uv_layers[0].data
    us, vs = [uv[i].uv.x for i in loops], [uv[i].uv.y for i in loops]
    u0, u1, v0, v1 = min(us), max(us), min(vs), max(vs)
    for i in loops:
        uv[i].uv.x = (uv[i].uv.x - u0) / (u1 - u0)
        uv[i].uv.y = (uv[i].uv.y - v0) / (v1 - v0)
    fixed += 1
    print(f'{ob.name}: UV {u0:.3f}..{u1:.3f} x {v0:.3f}..{v1:.3f} -> 0..1')

print(f'Fixed {fixed} screen mesh(es)' if fixed else f'No mesh uses {TEXTURE}')
