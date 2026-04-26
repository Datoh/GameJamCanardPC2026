"""Génère assets/textures/journal_sutom.png — feuille A4 vue du dessus."""
import struct, zlib, os

W, H = 512, 724  # ratio A4 exact (1:√2)

pixels = bytearray(W * H * 4)

def set_px(x, y, r, g, b, a=255):
    if 0 <= x < W and 0 <= y < H:
        i = (y * W + x) * 4
        pixels[i:i+4] = bytes([r, g, b, a])

def fill_rect(x0, y0, x1, y1, r, g, b, a=255):
    for y in range(max(0, y0), min(H, y1)):
        for x in range(max(0, x0), min(W, x1)):
            set_px(x, y, r, g, b, a)

def draw_rect_border(x0, y0, x1, y1, r, g, b, t=1):
    for x in range(x0, x1):
        for dy in range(t):
            set_px(x, y0 + dy, r, g, b)
            set_px(x, y1 - 1 - dy, r, g, b)
    for y in range(y0, y1):
        for dx in range(t):
            set_px(x0 + dx, y, r, g, b)
            set_px(x1 - 1 - dx, y, r, g, b)

# ── Bitmap font 5×7 ───────────────────────────────────────────────────────────

GLYPHS = {
    'A':["01110","10001","10001","11111","10001","10001","10001"],
    'B':["11110","10001","10001","11110","10001","10001","11110"],
    'C':["01111","10000","10000","10000","10000","10000","01111"],
    'D':["11110","10001","10001","10001","10001","10001","11110"],
    'E':["11111","10000","10000","11110","10000","10000","11111"],
    'F':["11111","10000","10000","11110","10000","10000","10000"],
    'G':["01111","10000","10000","10111","10001","10001","01111"],
    'H':["10001","10001","10001","11111","10001","10001","10001"],
    'I':["11111","00100","00100","00100","00100","00100","11111"],
    'J':["11111","00010","00010","00010","00010","10010","01100"],
    'K':["10001","10010","10100","11000","10100","10010","10001"],
    'L':["10000","10000","10000","10000","10000","10000","11111"],
    'M':["10001","11011","10101","10101","10001","10001","10001"],
    'N':["10001","11001","10101","10011","10001","10001","10001"],
    'O':["01110","10001","10001","10001","10001","10001","01110"],
    'P':["11110","10001","10001","11110","10000","10000","10000"],
    'Q':["01110","10001","10001","10001","10101","10010","01101"],
    'R':["11110","10001","10001","11110","10100","10010","10001"],
    'S':["01111","10000","10000","01110","00001","00001","11110"],
    'T':["11111","00100","00100","00100","00100","00100","00100"],
    'U':["10001","10001","10001","10001","10001","10001","01110"],
    'V':["10001","10001","10001","10001","10001","01010","00100"],
    'W':["10001","10001","10001","10101","10101","11011","10001"],
    'X':["10001","10001","01010","00100","01010","10001","10001"],
    'Y':["10001","10001","01010","00100","00100","00100","00100"],
    'Z':["11111","00001","00010","00100","01000","10000","11111"],
    '0':["01110","10001","10011","10101","11001","10001","01110"],
    '1':["00100","01100","00100","00100","00100","00100","01110"],
    '2':["01110","10001","00001","00110","01000","10000","11111"],
    '3':["11111","00001","00010","00110","00001","10001","01110"],
    '4':["00010","00110","01010","10010","11111","00010","00010"],
    '5':["11111","10000","11110","00001","00001","10001","01110"],
    '6':["01110","10000","10000","11110","10001","10001","01110"],
    '7':["11111","00001","00010","00100","01000","01000","01000"],
    '8':["01110","10001","10001","01110","10001","10001","01110"],
    '9':["01110","10001","10001","01111","00001","00001","01110"],
    ' ':["00000","00000","00000","00000","00000","00000","00000"],
    '.':["00000","00000","00000","00000","00000","00000","00100"],
    ',':["00000","00000","00000","00000","00000","00100","00100"],
    '-':["00000","00000","00000","11111","00000","00000","00000"],
    "'":["00100","00100","00000","00000","00000","00000","00000"],
    '?':["01110","10001","00001","00110","00100","00000","00100"],
    '!':["00100","00100","00100","00100","00100","00000","00100"],
    ':':["00000","00100","00000","00000","00000","00100","00000"],
    '/':["00001","00001","00010","00100","01000","10000","10000"],
    'É':["11111","10000","10000","11110","10000","10000","11111"],
}

def draw_text(text, x, y, r, g, b, scale=1):
    cx = x
    for ch in text.upper():
        glyph = GLYPHS.get(ch, GLYPHS[' '])
        for row_i, row in enumerate(glyph):
            for col_i, bit in enumerate(row):
                if bit == '1':
                    for sy in range(scale):
                        for sx in range(scale):
                            set_px(cx + col_i * scale + sx, y + row_i * scale + sy, r, g, b)
        cx += (5 + 1) * scale
    return cx

def text_width(text, scale=1):
    return len(text) * 6 * scale

def draw_text_centered(text, y, r, g, b, scale=1, margin=16):
    tw = text_width(text, scale)
    x = max(margin, (W - tw) // 2)
    draw_text(text, x, y, r, g, b, scale)

def draw_hline(y, x0, x1, r, g, b, t=1):
    for dy in range(t):
        fill_rect(x0, y + dy, x1, y + dy + 1, r, g, b)

# ── Fond feuille A4 ───────────────────────────────────────────────────────────

# Ombre portée (effet de feuille posée sur le bureau)
fill_rect(6, 6, W, H, 60, 50, 40, 255)

# Feuille blanche légèrement crémeuse
fill_rect(0, 0, W - 6, H - 6, 248, 244, 232)

# Marges visibles (liseré léger)
draw_rect_border(0, 0, W - 6, H - 6, 180, 170, 150, 1)

# ── En-tête ───────────────────────────────────────────────────────────────────

MARGIN = 24
y = 20

draw_text_centered("LE JOURNAL DU SUTOM", y, 15, 15, 15, scale=2, margin=MARGIN)
y += 20

draw_hline(y, MARGIN, W - 6 - MARGIN, 15, 15, 15, t=3)
y += 6
draw_hline(y, MARGIN, W - 6 - MARGIN, 15, 15, 15, t=1)
y += 8

draw_text_centered("LE MOT DU JOUR / SAUREZ-VOUS LE TROUVER ?", y, 60, 55, 45, scale=1, margin=MARGIN)
y += 12

draw_hline(y, MARGIN, W - 6 - MARGIN, 15, 15, 15, t=1)
y += 5
draw_hline(y, MARGIN, W - 6 - MARGIN, 15, 15, 15, t=3)
y += 14

# ── Grille SUTOM ──────────────────────────────────────────────────────────────

COLS = 6
ROWS = 6
CELL = 52
GAP  = 5
GRID_W = COLS * CELL + (COLS - 1) * GAP
GRID_H = ROWS * CELL + (ROWS - 1) * GAP
GX = (W - 6 - GRID_W) // 2
GY = y

for row in range(ROWS):
    for col in range(COLS):
        cx = GX + col * (CELL + GAP)
        cy = GY + row * (CELL + GAP)
        if col == 0:
            # Lettre révélée : fond rouge journal
            fill_rect(cx, cy, cx + CELL, cy + CELL, 185, 38, 38)
            draw_rect_border(cx, cy, cx + CELL, cy + CELL, 120, 20, 20, t=2)
        else:
            fill_rect(cx, cy, cx + CELL, cy + CELL, 235, 230, 215)
            draw_rect_border(cx, cy, cx + CELL, cy + CELL, 140, 130, 110, t=2)

y = GY + GRID_H + 14

# ── Séparateur ────────────────────────────────────────────────────────────────

draw_hline(y, MARGIN, W - 6 - MARGIN, 15, 15, 15, t=1)
y += 4
draw_hline(y, MARGIN, W - 6 - MARGIN, 15, 15, 15, t=3)
y += 10

# ── Colonnes de texte fictif ──────────────────────────────────────────────────

COL_MID = W // 2 - 3
fill_rect(COL_MID, y, COL_MID + 1, H - 10, 140, 130, 110)

lorem = [
    "LOREM IPSUM DOLOR SIT",
    "AMET CONSECTETUR ELI",
    "SED DO EIUSMOD TEMPOR",
    "INCIDIDUNT LABORE ET",
    "DOLORE MAGNA ALIQUA UT",
    "ENIM AD MINIM VENIAM",
    "QUIS NOSTRUD EXERCIT",
    "ULLAMCO LABORIS NISI",
    "ALIQUIP EX EA COMMODO",
    "CONSEQUAT DUIS AUTE",
    "IRURE DOLOR REPREHEND",
    "VOLUPTATE VELIT ESSE",
]

col1_x = MARGIN
col2_x = COL_MID + 6

for i, line in enumerate(lorem):
    ly = y + i * 10
    if ly + 7 >= H - 10:
        break
    draw_text(line, col1_x, ly, 55, 48, 38, scale=1)
    draw_text(line[::-1], col2_x, ly, 55, 48, 38, scale=1)

# ── Encode PNG ────────────────────────────────────────────────────────────────

rgb = bytearray()
for i in range(0, len(pixels), 4):
    rgb += pixels[i:i+3]

raw = bytearray()
for row in range(H):
    raw.append(0)
    raw += rgb[row * W * 3:(row + 1) * W * 3]
compressed = zlib.compress(bytes(raw), 9)

ihdr_data = struct.pack(">II", W, H) + bytes([8, 2, 0, 0, 0])
out  = b'\x89PNG\r\n\x1a\n'
out += struct.pack(">I", 13) + b'IHDR' + ihdr_data + struct.pack(">I", zlib.crc32(b'IHDR' + ihdr_data) & 0xFFFFFFFF)
out += struct.pack(">I", len(compressed)) + b'IDAT' + compressed + struct.pack(">I", zlib.crc32(b'IDAT' + compressed) & 0xFFFFFFFF)
out += struct.pack(">I", 0) + b'IEND' + struct.pack(">I", zlib.crc32(b'IEND') & 0xFFFFFFFF)

out_path = os.path.join(os.path.dirname(__file__), "..", "assets", "textures", "journal_sutom.png")
with open(out_path, "wb") as f:
    f.write(out)
print(f"Texture générée : {os.path.abspath(out_path)}  ({W}×{H}px, A4)")
