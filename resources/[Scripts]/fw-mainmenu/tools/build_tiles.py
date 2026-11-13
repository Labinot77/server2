"""
Rebuilds html/tiles/ from your streamed GTA minimap textures.

    pip install pillow
    python build_tiles.py "<path to>/assets-replace/stream/[Minimap]" ../html/tiles

Reads minimap_0_0.ytd .. minimap_2_1.ytd (six 3072x3072 DXT5 textures, 2 columns x 3 rows),
stitches them into a 6144x9216 map and writes 512px webp tiles for 4 zoom levels.
The world calibration in html/app.js (CAL) matches GTA's standard minimap layout, so it stays valid
as long as the textures keep the same size and layout.
"""
import io, os, shutil, struct, sys, zlib
from PIL import Image


def read_ytd_texture(path):
    raw = open(path, 'rb').read()
    if raw[:4] != b'RSC7':
        raise ValueError(f'{path}: not an RSC7 resource')
    data = zlib.decompress(raw[16:], -15)
    q = lambda o: struct.unpack_from('<Q', data, o)[0]
    tex = q(q(0x30) & 0xFFFFFFF) & 0xFFFFFFF          # first texture of the dictionary
    w, h = struct.unpack_from('<HH', data, tex + 0x50)
    fmt = data[tex + 0x58:tex + 0x5C]
    if fmt not in (b'DXT5', b'DXT1'):
        raise ValueError(f'{path}: unsupported texture format {fmt}')
    size = w * h if fmt == b'DXT5' else w * h // 2
    pixels = data[8192:8192 + size]                     # graphics page, top mip level
    dds = b'DDS ' + struct.pack('<7I', 124, 0x1 | 0x2 | 0x4 | 0x1000 | 0x80000, h, w, size, 0, 1) + b'\0' * 44
    dds += struct.pack('<2I4s5I', 32, 0x4, fmt, 0, 0, 0, 0, 0) + struct.pack('<5I', 0x1000, 0, 0, 0, 0)
    return Image.open(io.BytesIO(dds + pixels)).convert('RGB')


def main(src, out):
    pieces = {(r, c): read_ytd_texture(os.path.join(src, f'minimap_{r}_{c}.ytd')) for r in range(3) for c in range(2)}
    tw, th = pieces[(0, 0)].size
    full = Image.new('RGB', (tw * 2, th * 3))
    for (r, c), im in pieces.items():
        full.paste(im, (c * tw, r * th))
    W, H = full.size
    print('map', W, 'x', H)

    T = 512
    shutil.rmtree(out, ignore_errors=True)
    for k in range(4):
        w, h = W >> k, H >> k
        level = full if k == 0 else full.resize((w, h), Image.LANCZOS)
        d = os.path.join(out, str(k))
        os.makedirs(d)
        for ty in range((h + T - 1) // T):
            for tx in range((w + T - 1) // T):
                level.crop((tx * T, ty * T, min(w, (tx + 1) * T), min(h, (ty + 1) * T))).save(
                    os.path.join(d, f'{tx}_{ty}.webp'), 'WEBP', quality=85, method=6)
        print('level', k, f'{w}x{h}')


if __name__ == '__main__':
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
