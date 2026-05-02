import bpy
import bmesh
from collections import defaultdict

# Effacer les objets existants dans la scène
for obj in list(bpy.data.objects):
    bpy.data.objects.remove(obj, do_unlink=True)

# ---------------------------------------------------------------------------
# Données du labyrinthe 10x10
# h_walls[i][j] = 1  → mur horizontal à y = i * CELL_SIZE, segment j  (11 x 10)
# v_walls[i][j] = 1  → mur vertical   à x = j * CELL_SIZE, segment i  (10 x 11)
# ---------------------------------------------------------------------------
h_walls_data = [
    "1111111111",
    "0011000110",
    "0110101100",
    "0000001110",
    "0100010011",
    "0011100000",
    "0111000000",
    "0000110100",
    "0011011010",
    "0110001000",
    "1111110111",
]

v_walls_data = [
    "10000100001",
    "10100110011",
    "11011110011",
    "10111101001",
    "11010111101",
    "11000111111",
    "11101011011",
    "11010001011",
    "11001101101",
    "10001010101",
]

CELL_SIZE       = 0.2
WALL_HEIGHT     = 0.12
WALL_THICKNESS  = 0.02
FLOOR_THICKNESS = 0.02
LEG_SIZE        = 0.04
LEG_HEIGHT      = 0.8
ROWS            = 10
COLS            = 10


def add_box(bm, cx, cy, cz, sx, sy, sz):
    hx, hy, hz = sx / 2, sy / 2, sz / 2
    v = [bm.verts.new(c) for c in [
        (cx - hx, cy - hy, cz - hz),
        (cx + hx, cy - hy, cz - hz),
        (cx + hx, cy + hy, cz - hz),
        (cx - hx, cy + hy, cz - hz),
        (cx - hx, cy - hy, cz + hz),
        (cx + hx, cy - hy, cz + hz),
        (cx + hx, cy + hy, cz + hz),
        (cx - hx, cy + hy, cz + hz),
    ]]
    bm.faces.new((v[0], v[3], v[2], v[1]))
    bm.faces.new((v[4], v[5], v[6], v[7]))
    bm.faces.new((v[0], v[1], v[5], v[4]))
    bm.faces.new((v[2], v[3], v[7], v[6]))
    bm.faces.new((v[0], v[4], v[7], v[3]))
    bm.faces.new((v[1], v[2], v[6], v[5]))


w      = COLS * CELL_SIZE
h      = ROWS * CELL_SIZE
Z_BASE = LEG_HEIGHT + FLOOR_THICKNESS  # face supérieure du plateau = bas des murs

LEG_INSET = 0.02
x_left    = -WALL_THICKNESS / 2 + LEG_SIZE / 2 + LEG_INSET
x_right   =  w + WALL_THICKNESS / 2 - LEG_SIZE / 2 - LEG_INSET
y_front   = -WALL_THICKNESS / 2 + LEG_SIZE / 2 + LEG_INSET
y_back    =  h + WALL_THICKNESS / 2 - LEG_SIZE / 2 - LEG_INSET


def clean_bmesh(bm):
    """Fusionne les sommets coïncidents et supprime les faces intérieures dupliquées."""
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-6)
    bm.verts.ensure_lookup_table()
    bm.faces.ensure_lookup_table()
    face_map = defaultdict(list)
    for face in bm.faces:
        face_map[frozenset(v.index for v in face.verts)].append(face)
    interior = [f for faces in face_map.values() if len(faces) > 1 for f in faces]
    if interior:
        bmesh.ops.delete(bm, geom=interior, context='FACES_ONLY')
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)


def make_object(name, bm):
    mesh = bpy.data.meshes.new(name)
    obj  = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    bm.to_mesh(mesh)
    bm.free()
    return obj


# ---------------------------------------------------------------------------
# Objet Murs (parois + piliers + pieds)
# ---------------------------------------------------------------------------
bm = bmesh.new()

# Murs horizontaux (le long de X, à y = i * CELL_SIZE)
for i, row in enumerate(h_walls_data):
    for j, val in enumerate(row):
        if val == '1':
            add_box(bm,
                    j * CELL_SIZE + CELL_SIZE / 2, i * CELL_SIZE,
                    Z_BASE + WALL_HEIGHT / 2,
                    CELL_SIZE, WALL_THICKNESS, WALL_HEIGHT)

# Murs verticaux (le long de Y, à x = j * CELL_SIZE)
for i, row in enumerate(v_walls_data):
    for j, val in enumerate(row):
        if val == '1':
            add_box(bm,
                    j * CELL_SIZE, i * CELL_SIZE + CELL_SIZE / 2,
                    Z_BASE + WALL_HEIGHT / 2,
                    WALL_THICKNESS, CELL_SIZE, WALL_HEIGHT)

# Piliers de jonction : uniquement si au moins un mur adjacent existe
for i in range(ROWS + 1):
    for j in range(COLS + 1):
        has_wall = (
            (j < COLS and h_walls_data[i][j]   == '1') or
            (j > 0    and h_walls_data[i][j-1] == '1') or
            (i < ROWS and v_walls_data[i][j]   == '1') or
            (i > 0    and v_walls_data[i-1][j] == '1')
        )
        if has_wall:
            add_box(bm,
                    j * CELL_SIZE, i * CELL_SIZE, Z_BASE + WALL_HEIGHT / 2,
                    WALL_THICKNESS, WALL_THICKNESS, WALL_HEIGHT)

# Pieds (bas à z=0, haut à z=LEG_HEIGHT)
for cx, cy in [(x_left, y_front), (x_right, y_front),
               (x_right, y_back),  (x_left, y_back)]:
    add_box(bm, cx, cy, LEG_HEIGHT / 2, LEG_SIZE, LEG_SIZE, LEG_HEIGHT)

clean_bmesh(bm)
make_object("Murs", bm)

# ---------------------------------------------------------------------------
# Objet Sol (plateau — face inférieure à z=LEG_HEIGHT, supérieure à z=Z_BASE)
# ---------------------------------------------------------------------------
bm = bmesh.new()
add_box(bm, w / 2, h / 2, LEG_HEIGHT + FLOOR_THICKNESS / 2,
        w + WALL_THICKNESS, h + WALL_THICKNESS, FLOOR_THICKNESS)
clean_bmesh(bm)
make_object("Sol", bm)

print("Labyrinthe généré avec succès !")
print(f"  Grille  : {COLS}x{ROWS} cellules de {CELL_SIZE} m")
print(f"  Murs    : hauteur={WALL_HEIGHT}  épaisseur={WALL_THICKNESS}")
print(f"  Sol     : {w + WALL_THICKNESS:.3f} x {h + WALL_THICKNESS:.3f} m  épaisseur={FLOOR_THICKNESS}")
print(f"  Sommets : {len(mesh.vertices)}  Faces : {len(mesh.polygons)}")
