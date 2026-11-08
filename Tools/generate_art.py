#!/usr/bin/env python3
"""Arte pixelada original e reproduzível. Requer somente Python 3."""
from pathlib import Path
import math
import random
import struct
import zlib

OUT = Path(__file__).resolve().parents[1] / "Assets" / "16bit"
OUT.mkdir(parents=True, exist_ok=True)


def rgba(c):
    # Aceita hexadecimal ou tuplas e completa o canal de transparência quando necessário.
    if isinstance(c, str):
        c = c.lstrip("#")
        return tuple(int(c[i:i + 2], 16) for i in (0, 2, 4)) + (255,)
    return tuple(c) if len(c) == 4 else tuple(c) + (255,)


def mix(a, b, f):
    a, b = rgba(a), rgba(b)
    return tuple(round(x + (y - x) * f) for x, y in zip(a, b))


class Canvas:
    def __init__(self, w, h, color=(0, 0, 0, 0)):
        self.w, self.h = w, h
        # Cada pixel ocupa quatro bytes: vermelho, verde, azul e transparência.
        self.data = bytearray(rgba(color) * (w * h))

    def pixel(self, x, y, c):
        x, y = int(x), int(y)
        if 0 <= x < self.w and 0 <= y < self.h:
            self.data[(y * self.w + x) * 4:(y * self.w + x) * 4 + 4] = bytes(rgba(c))

    def rect(self, x, y, w, h, c):
        x, y, w, h = int(x), int(y), int(w), int(h)
        col = bytes(rgba(c))
        for j in range(max(0, y), min(self.h, y + h)):
            a, b = max(0, x), min(self.w, x + w)
            if b > a:
                self.data[(j * self.w + a) * 4:(j * self.w + b) * 4] = col * (b - a)

    def line(self, x0, y0, x1, y1, c, size=1):
        count = max(abs(int(x1 - x0)), abs(int(y1 - y0)), 1)
        for t in range(count + 1):
            self.rect(round(x0 + (x1 - x0) * t / count), round(y0 + (y1 - y0) * t / count), size, size, c)

    def poly(self, points, c):
        # Preenche linhas horizontais entre os pares de interseções com as arestas.
        for y in range(max(0, min(p[1] for p in points)), min(self.h, max(p[1] for p in points) + 1)):
            xs = []
            for a, b in zip(points, points[1:] + points[:1]):
                if (a[1] <= y < b[1]) or (b[1] <= y < a[1]):
                    xs.append(a[0] + (y - a[1]) * (b[0] - a[0]) / (b[1] - a[1]))
            xs.sort()
            for a, b in zip(xs[::2], xs[1::2]):
                self.rect(math.ceil(a), y, math.floor(b) - math.ceil(a) + 1, 1, c)

    def ellipse(self, cx, cy, rx, ry, c):
        for y in range(max(0, int(cy - ry)), min(self.h, int(cy + ry) + 1)):
            dy = (y - cy) / ry
            if abs(dy) <= 1:
                dx = rx * math.sqrt(max(0, 1 - dy * dy))
                self.rect(round(cx - dx), y, round(dx * 2) + 1, 1, c)

    def blit(self, src, x, y, scale=1):
        for yy in range(src.h):
            for xx in range(src.w):
                color = tuple(src.data[(yy * src.w + xx) * 4:(yy * src.w + xx) * 4 + 4])
                if color[3]:
                    self.rect(x + xx * scale, y + yy * scale, scale, scale, color)

    def save(self, name):
        # Monta os blocos do PNG com tamanho e CRC, sem bibliotecas de imagem externas.
        def chunk(tag, body):
            return struct.pack(">I", len(body)) + tag + body + struct.pack(">I", zlib.crc32(tag + body) & 0xffffffff)
        # Filtro zero por linha; o bloco IDAT recebe os pixels comprimidos com zlib.
        raw = b"".join(b"\x00" + self.data[y * self.w * 4:(y + 1) * self.w * 4] for y in range(self.h))
        png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", self.w, self.h, 8, 6, 0, 0, 0))
        (OUT / name).write_bytes(png + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


# Alfabeto original de cinco colunas, com cantos e aberturas de painel eletrônico.
FONT = {
    "A": "01110/11011/10001/11111/10001/10001/10001",
    "B": "11110/10001/10001/11110/10001/10001/11110",
    "C": "01111/11000/10000/10000/10000/11000/01111",
    "D": "11100/10010/10001/10001/10001/10010/11100",
    "E": "11111/10000/10000/11110/10000/10000/11111",
    "F": "11111/10000/10000/11110/10000/10000/10000",
    "G": "01111/11000/10000/10111/10001/11001/01111",
    "H": "10001/10001/10001/11111/10001/10001/10001",
    "I": "11111/00100/00100/00100/00100/00100/11111",
    "J": "00111/00010/00010/00010/10010/11010/01100",
    "K": "10001/10010/10100/11100/10010/10001/10001",
    "L": "10000/10000/10000/10000/10000/10000/11111",
    "M": "10001/11011/11111/10101/10001/10001/10001",
    "N": "10001/11001/11101/10111/10011/10001/10001",
    "O": "01110/11011/10001/10001/10001/11011/01110",
    "P": "11110/10001/10001/11110/10000/10000/10000",
    "Q": "01110/11011/10001/10001/10101/11010/01101",
    "R": "11110/10001/10001/11110/10100/10010/10001",
    "S": "01111/11000/10000/01110/00001/00011/11110",
    "T": "11111/00100/00100/00100/00100/00100/00100",
    "U": "10001/10001/10001/10001/10001/11011/01110",
    "V": "10001/10001/10001/10001/11011/01110/00100",
    "W": "10001/10001/10001/10101/11111/11011/10001",
    "X": "10001/11011/01110/00100/01110/11011/10001",
    "Y": "10001/11011/01110/00100/00100/00100/00100",
    "Z": "11111/00011/00110/00100/01100/11000/11111",
    "0": "01110/11011/10011/10101/11001/11011/01110",
    "1": "00100/01100/00100/00100/00100/00100/01110",
    "2": "01110/10001/00001/00010/00100/01000/11111",
    "3": "11110/00001/00001/01110/00001/00001/11110",
    "4": "00010/00110/01010/10010/11111/00010/00010",
    "5": "11111/10000/10000/11110/00001/00001/11110",
    "6": "01110/11000/10000/11110/10001/10001/01110",
    "7": "11111/00001/00010/00100/01000/01000/01000",
    "8": "01110/10001/10001/01110/10001/10001/01110",
    "9": "01110/10001/10001/01111/00001/00011/01110",
    " ": "00000/00000/00000/00000/00000/00000/00000",
    "-": "00000/00000/00000/11111/00000/00000/00000",
    "_": "00000/00000/00000/00000/00000/00000/11111",
    ".": "00000/00000/00000/00000/00000/01100/01100",
    ",": "00000/00000/00000/00000/00110/00100/01000",
    ":": "00000/01100/01100/00000/01100/01100/00000",
    "/": "00001/00011/00010/00100/01000/11000/10000",
    "!": "00100/00100/00100/00100/00100/00000/00100",
    "?": "01110/10001/00001/00010/00100/00000/00100",
    "+": "00000/00100/00100/11111/00100/00100/00000",
    "=": "00000/00000/11111/00000/11111/00000/00000",
    "<": "00010/00100/01000/10000/01000/00100/00010",
    ">": "01000/00100/00010/00001/00010/00100/01000",
    "[": "01110/01000/01000/01000/01000/01000/01110",
    "]": "01110/00010/00010/00010/00010/00010/01110",
    "(": "00010/00100/01000/01000/01000/00100/00010",
    ")": "01000/00100/00010/00010/00010/00100/01000",
    "%": "11001/11010/00010/00100/01000/01011/10011",
    "#": "01010/01010/11111/01010/11111/01010/01010",
    "*": "00000/10101/01110/11111/01110/10101/00000",
    "'": "00100/00100/01000/00000/00000/00000/00000",
    '"': "01010/01010/01010/00000/00000/00000/00000",
    "•": "00000/00000/01110/01110/01110/00000/00000",
    "→": "00000/00100/00010/11111/00010/00100/00000",
    "←": "00000/00100/01000/11111/01000/00100/00000",
    "º": "01100/10010/10010/01100/00000/00000/00000",
    "ª": "01100/10010/11110/10010/00000/00000/00000",
    "&": "01100/10010/10100/01000/10101/10010/01101",
    ";": "00000/01100/01100/00000/01100/01000/10000",
    "|": "00100/00100/00100/00100/00100/00100/00100",
}


def glyph(character):
    import unicodedata
    if character in FONT:
        return FONT[character].split("/")
    # Reutiliza a letra base; make_font acrescenta os acentos ao desenhar o atlas.
    base = unicodedata.normalize("NFD", character.upper())[0]
    return FONT.get(base, FONT["?"]).split("/")


def text(canvas, value, x, y, scale=1, color="#e4f8ff", slant=0):
    for n, ch in enumerate(value.upper()):
        for yy, row in enumerate(glyph(ch)):
            for xx, v in enumerate(row):
                if v == "1":
                    # O deslocamento por linha inclina as letras sem suavizar os pixels.
                    canvas.rect(x + n * 6 * scale + xx * scale + int((6 - yy) * slant), y + yy * scale, scale, scale, color)


def frame(c, x, y, w, h, accent="#50d9e6", dark="#11192c"):
    c.rect(x, y, w, h, "#050b18")
    c.rect(x + 1, y + 1, w - 2, h - 2, "#56617d")
    c.rect(x + 2, y + 3, w - 4, h - 5, "#202c48")
    c.rect(x + 4, y + 5, w - 8, h - 9, dark)
    c.line(x + 8, y + 3, x + w - 9, y + 3, accent)
    c.line(x + 4, y + h - 3, x + w - 5, y + h - 3, "#0c1022")


def bolt(c, x, y):
    c.rect(x, y, 4, 4, "#090d1b")
    c.rect(x, y, 3, 3, "#74839c")
    c.line(x + 1, y, x + 1, y + 1, "#c0d2df")
    c.pixel(x + 1, y + 1, "#1d2943")


def stars(c, seed=1, count=150):
    # Sementes fixas mantêm os fundos idênticos a cada execução do gerador.
    rng = random.Random(seed)
    for _ in range(count):
        x, y = rng.randrange(c.w // 2) * 2, rng.randrange(c.h // 2) * 2
        col = rng.choice(["#1c2a47", "#23364d", "#32465c", "#41516c", "#607582"])
        c.rect(x, y, 2 if rng.random() < .3 else 1, 1, col)
        if rng.random() < .08:
            c.line(x - 2, y, x + 2, y, col)
            c.line(x, y - 2, x, y + 2, col)


def planet(c, cx, cy, radius, subdued=False):
    rng = random.Random(207)
    for y in range(-radius, radius + 1, 2):
        for x in range(-radius, radius + 1, 2):
            d = (x * x + y * y) / radius ** 2
            if d <= 1:
                light = max(0, 1 - math.hypot(x + radius * .35, y + radius * .4) / radius / 1.7)
                col = mix("#10182f" if subdued else "#15213b", "#25334f" if subdued else "#6285a3", light ** 2)
                if math.sin(y / 14 + math.sin(x / 25) * .8) > .4:
                    col = mix(col, "#233657" if subdued else "#344c7d", .4)
                if rng.random() < .09:
                    col = mix(col, "#586c81", .08 if subdued else .23)
                c.rect(cx + x, cy + y, 2, 2, col)
    for i in range(330):
        a = i * math.tau / 330
        px = int(math.cos(a) * radius * 1.6)
        py = int(math.sin(a) * radius * .32)
        xx, yy = cx + px, cy + py + int(px * -.25)
        if py > 0 or math.hypot(xx - cx, yy - cy) > radius:
            c.rect(xx, yy, 3, 2, "#293752" if subdued else "#82939e")


def make_arena():
    c = Canvas(640, 480, "#080f20")
    for y in range(0, 480, 2):
        c.rect(0, y, 640, 2, mix("#0d142a", "#070d1c", y / 480))
    planet(c, 460, 280, 125, True)
    stars(c, 51, 200)
    # Estruturas discretas junto às paredes, longe da leitura da bola.
    for side in (0, 1):
        x = side * 622
        c.rect(x, 0, 18, 480, "#111a2c")
        c.rect(x + (15 if side == 0 else 1), 0, 2, 480, "#27374d")
        for y in range(18, 456, 48):
            c.rect(x + 4, y, 9, 26, "#18253b")
            c.rect(x + 6, y + 4, 5, 2, "#34455d")
            c.rect(x + 5, y + 15, 2, 7, "#285261")
            bolt(c, x + 7, y + 30)
    for x in range(36, 610, 94):
        c.line(x, 410, x + 12, 398, "#182941")
        c.line(x + 12, 398, x + 12, 366, "#182941")
        c.rect(x + 10, 363, 5, 4, "#294153")
        c.line(x + 4, 478, x + 4, 450, "#1d3046")
        c.line(x + 4, 450, x + 16, 438, "#1d3046")
    for y in range(200, 445, 32):
        for x in range(34, 610, 32):
            c.pixel(x, y, "#16243a")
    c.line(24, 467, 616, 467, "#1e3447")
    for x in range(32, 618, 20):
        c.rect(x, 470, 8, 2, "#31394a")
    c.save("arena.png")


def make_cabinet():
    c = Canvas(960, 576, "#080e1c")
    for y in range(0, 576, 2):
        c.rect(0, y, 960, 1, "#0d1426")
    # Carcaça com duas janelas independentes.
    frame(c, 12, 52, 664, 504, "#6594a1")
    c.rect(24, 64, 640, 480, (0, 0, 0, 0))
    frame(c, 688, 52, 256, 504, "#50d9e6", "#111b30")
    # Trilhos e lâmpadas externas.
    for x in (16, 668, 692, 936):
        for y in (68, 136, 204, 272, 340, 408, 476, 536):
            c.rect(x, y, 4, 15, "#070c18")
            c.rect(x + 1, y + 2, 2, 8, "#50c4d4")
    for x, y in ((16, 56), (668, 56), (16, 548), (668, 548), (692, 56), (936, 56), (692, 548), (936, 548)):
        bolt(c, x, y)
    # Barra de fabricante, nervuras e conectores.
    c.rect(12, 10, 936, 32, "#1b263e")
    c.line(16, 10, 943, 10, "#62748d")
    c.line(16, 41, 943, 41, "#050a14")
    c.poly([(17, 14), (27, 14), (27, 35), (17, 35), (23, 25)], "#56e0de")
    c.poly([(31, 14), (41, 14), (41, 35), (31, 35), (37, 25)], "#d69d62")
    c.rect(654, 18, 26, 12, "#080f1e")
    for x in range(657, 678, 5):
        c.rect(x, 20, 2, 8, "#57c7c6")
    for x in range(850, 930, 8):
        c.line(x, 18, x - 5, 32, "#435674", 2)
    c.line(18, 563, 942, 563, "#26334a")
    for x in range(26, 655, 14):
        c.rect(x, 562, 7, 3, "#927552" if x % 3 else "#35445b")
    for x in range(699, 930, 12):
        c.rect(x, 561, 6, 4, "#35445b")
    c.save("cabinet.png")


def make_menu():
    c = Canvas(960, 576, "#070e20")
    # Nebulosa de bandas, em baixa resolução e paleta limitada.
    for y in range(0, 576, 2):
        for x in range(0, 960, 2):
            f = math.exp(-((x - 710) ** 2 / 190000 + (y - 190) ** 2 / 110000))
            noise = math.sin(x / 105 + y / 58) * .07
            c.rect(x, y, 2, 2, mix("#070e20", "#222347", max(0, f * .8 + noise)))
    planet(c, 765, 210, 145)
    stars(c, 12, 450)
    # Horizonte da estação espacial.
    c.poly([(0, 445), (120, 445), (145, 423), (196, 423), (196, 410), (245, 410), (269, 436), (328, 436), (345, 451), (475, 451), (475, 435), (533, 435), (550, 449), (666, 449), (699, 422), (771, 422), (804, 390), (848, 390), (848, 357), (883, 357), (898, 410), (960, 410), (960, 576), (0, 576)], "#0a1325")
    for x in range(12, 960, 54):
        height = 65 + (x * 19 % 53)
        c.rect(x, 476 - height // 4, 32, height, "#15243b")
        c.rect(x + 2, 476 - height // 4, 28, 2, "#3f5772")
        for yy in range(482, min(560, 476 + height), 10):
            c.rect(x + 7, yy, 5, 2, "#386976")
            c.rect(x + 18, yy, 5, 2, "#a27c5d" if yy % 3 else "#315361")
    # Doca em perspectiva.
    c.poly([(290, 510), (669, 510), (885, 576), (68, 576)], "#111e30")
    for x in range(-400, 1400, 110):
        c.line(480 + (x - 480) * .35, 510, x, 576, "#263953")
    for y in (518, 530, 546, 566):
        c.line(200, y, 760, y, "#21344b")
    # Estrutura da cabine, cantos mecânicos e painéis com parafusos.
    for side in (0, 1):
        x = side * 914
        c.poly([(x, 0), (x + 46, 0), (x + 33, 47), (x + 30, 519), (x + 46, 576), (x, 576)], "#18243d")
        c.line(x + 31, 50, x + 31, 519, "#61718b", 2)
        c.line(x + 27, 77, x + 27, 498, "#2c4f65")
        for y in range(58, 526, 52):
            c.rect(x + 11, y, 8, 22, "#08101f")
            c.rect(x + 13, y + 2, 4, 11, "#5ca7b7")
            bolt(c, x + 22, y + 29)
    c.rect(0, 0, 960, 12, "#1c2943")
    c.rect(0, 12, 960, 2, "#57708a")
    c.rect(0, 560, 960, 16, "#121d31")
    c.line(34, 560, 926, 560, "#527183")
    for x in (44, 911):
        bolt(c, x, 5)
        bolt(c, x, 565)
    # Dois pequenos satélites, desenhados por formas pixeladas.
    for x, y in ((97, 128), (847, 340)):
        c.poly([(x, y + 10), (x + 16, y), (x + 40, y + 8), (x + 28, y + 19), (x + 9, y + 18)], "#293e58")
        c.line(x + 7, y + 9, x + 27, y + 13, "#79949b", 2)
        c.rect(x - 23, y + 3, 20, 8, "#204d6c")
        c.rect(x + 41, y + 13, 25, 7, "#204d6c")
        c.line(x - 22, y + 5, x - 5, y + 5, "#4b84a3")
        c.rect(x + 17, y + 6, 7, 4, "#96d6d7")
    c.save("menu_background.png")


def make_sprites():
    colors = {"yellow": ("#ffd77a", "#b37531"), "blue": ("#67cfee", "#286595"), "gray": ("#bfcbd7", "#59667f"), "green": ("#88e8b4", "#318773"), "purple": ("#b597eb", "#674794"), "red": ("#f591a5", "#a94166")}
    for name, (light, base) in colors.items():
        c = Canvas(80, 24)
        c.poly([(3, 0), (76, 0), (79, 3), (79, 20), (76, 23), (3, 23), (0, 20), (0, 3)], "#050c1a")
        c.poly([(3, 1), (76, 1), (78, 3), (78, 19), (75, 22), (3, 22), (1, 19), (1, 4)], base)
        c.rect(5, 3, 68, 2, light)
        c.rect(3, 5, 2, 13, mix(light, "#fff9e1", .1))
        for y in range(6, 18):
            c.rect(6, y, 68, 1, mix(light, base, .35 + (y - 6) / 18))
        c.rect(5, 19, 69, 2, mix(base, "#07101e", .55))
        c.rect(13, 7, 53, 10, mix(base, "#0e1b32", .45))
        c.line(15, 8, 62, 8, mix(light, base, .4))
        c.line(14, 16, 65, 16, "#17223a")
        c.rect(17, 10, 4, 4, light)
        c.rect(23, 10, 23, 1, mix(light, base, .7))
        c.rect(23, 13, 19, 1, mix(light, base, .5))
        for x in (51, 56, 61):
            c.rect(x, 10, 2, 5, mix(light, "#ffffff", .3))
        for x in (7, 70):
            c.rect(x, 8, 3, 7, "#111a2b")
            c.pixel(x + 1, 8, light)
            c.pixel(x + 1, 14, mix(light, base, .4))
        c.save(f"block_{name}.png")
    c = Canvas(100, 24)
    c.poly([(7, 0), (21, 0), (26, 3), (74, 3), (79, 0), (92, 0), (99, 7), (99, 19), (95, 23), (5, 23), (0, 18), (0, 7)], "#070d1b")
    c.poly([(7, 1), (20, 1), (25, 4), (75, 4), (80, 1), (92, 1), (97, 7), (97, 18), (93, 21), (6, 21), (2, 17), (2, 7)], "#73879d")
    c.rect(7, 3, 13, 3, "#d1e1e1")
    c.rect(80, 3, 13, 3, "#d1e1e1")
    c.rect(23, 6, 54, 12, "#273951")
    c.rect(26, 7, 48, 2, "#b6d4dd")
    c.rect(27, 10, 46, 5, "#125665")
    c.rect(29, 10, 42, 2, "#6effdf")
    c.rect(33, 12, 34, 2, "#2fa7b3")
    c.rect(38, 15, 24, 2, "#14273e")
    for x in (5, 83):
        c.rect(x, 8, 11, 9, "#26364f")
        c.rect(x + 2, 8, 7, 2, "#dfb88c")
        for xx in range(x + 2, x + 10, 3):
            c.rect(xx, 12, 1, 4, "#95adbe")
    c.rect(17, 7, 4, 10, "#51b9cb")
    c.rect(78, 7, 4, 10, "#51b9cb")
    c.rect(27, 20, 15, 2, "#32a3be")
    c.rect(59, 20, 15, 2, "#32a3be")
    c.save("paddle.png")
    life = Canvas(24, 12)
    life.poly([(3, 1), (7, 1), (8, 3), (16, 3), (17, 1), (21, 1), (23, 4), (23, 9), (1, 9), (1, 4)], "#9eb6ca")
    life.rect(3, 3, 3, 4, "#e5ecdd")
    life.rect(18, 3, 3, 4, "#e5ecdd")
    life.rect(8, 4, 8, 3, "#5df1dd")
    life.rect(3, 9, 18, 2, "#294d6d")
    life.save("life.png")
    c = Canvas(24, 24)
    c.ellipse(11.5, 11.5, 11.5, 11.5, (45, 178, 216, 70))
    c.ellipse(11.5, 11.5, 10, 10, "#163d68")
    c.ellipse(11, 11, 9, 9, "#4c9dc5")
    c.ellipse(10, 10, 7, 7, "#9eecea")
    c.ellipse(9, 9, 5, 5, "#e7fff3")
    c.rect(6, 5, 5, 3, "#ffffff")
    c.rect(5, 8, 3, 4, "#ffffff")
    c.rect(15, 14, 3, 3, "#48aeca")
    c.rect(10, 19, 5, 1, "#71ecdc")
    c.save("ball.png")
    c = Canvas(12, 24)
    c.poly([(5, 0), (7, 0), (9, 6), (9, 16), (7, 23), (4, 23), (2, 16), (2, 6)], (245, 107, 150, 90))
    c.rect(4, 5, 4, 14, "#e85c93")
    c.rect(5, 3, 2, 15, "#ffe9b0")
    c.rect(5, 2, 2, 9, "#ffffff")
    c.rect(4, 16, 4, 3, "#873b76")
    c.save("bullet.png")
    c = Canvas(26, 26)
    c.poly([(6, 0), (19, 0), (25, 6), (25, 19), (19, 25), (6, 25), (0, 19), (0, 6)], "#10162c")
    c.poly([(6, 1), (19, 1), (24, 6), (24, 19), (19, 24), (6, 24), (1, 19), (1, 6)], "#e0ad58")
    c.poly([(7, 3), (18, 3), (22, 7), (22, 18), (18, 22), (7, 22), (3, 18), (3, 7)], "#32415e")
    c.line(7, 3, 18, 3, "#ffe8a3")
    c.poly([(14, 5), (8, 14), (12, 14), (10, 21), (19, 10), (14, 10), (17, 5)], "#fff3aa")
    c.line(7, 21, 9, 21, "#ff9d62")
    c.rect(4, 10, 1, 7, "#6cbdbf")
    c.rect(21, 10, 1, 7, "#6cbdbf")
    c.save("powerup.png")


def make_logo():
    c = Canvas(560, 140)
    # Aletas e selo acima do nome.
    for side in (0, 1):
        x = 22 if side == 0 else 371
        c.poly([(x, 25), (x + 160, 25), (x + 146, 34), (x + 14, 34)], "#416b80")
        c.line(x + 8, 26, x + 150, 26, "#a2c8c5")
        for xx in range(x + 16, x + 141, 13):
            c.line(xx, 29, xx + 5, 29, "#1c344a", 2)
    text(c, "SUPER", 207, 8, 5, "#15263d", .3)
    text(c, "SUPER", 206, 5, 5, "#d2e9d6", .3)
    text(c, "SUPER", 206, 5, 5, "#9ce6df", .3)
    mask = Canvas(560, 140)
    text(mask, "ARKANOID", 38, 52, 10, "#ffffff", 1.5)
    coords = [(x, y) for y in range(mask.h) for x in range(mask.w) if mask.data[(y * mask.w + x) * 4 + 3]]
    # Extrusão azul escura, contorno dourado e lâmina cromada.
    for dx, dy, radius, color in ((5, 8, 4, "#030a18"), (4, 6, 3, "#36476c"), (0, 0, 3, "#071124"), (0, 0, 2, "#dbbb7b"), (0, 0, 0, "#ffffff")):
        for x, y in coords:
            c.rect(x + dx - radius, y + dy - radius, 1 + radius * 2, 1 + radius * 2, color)
    for x, y in coords:
        f = (y - 52) / 70
        if f < .45:
            color = mix("#f2f3dc", "#8abac9", f / .45)
        elif f < .50:
            color = "#314b77"
        else:
            color = mix("#6cdddc", "#3771a2", (f - .5) * 2)
        c.pixel(x, y, color)
        if x % 17 == 0 and y == 56:
            c.pixel(x, y, "#ffffff")
    # Brilho em cruz, sem desfoque.
    for x, y in ((53, 53), (439, 54), (199, 113)):
        c.line(x - 5, y, x + 5, y, "#ffffff")
        c.line(x, y - 5, x, y + 5, "#ffffff")
        c.rect(x - 1, y - 1, 3, 3, "#ffffff")
    c.save("logo.png")


def make_font():
    # O atlas reúne os desenhos; o arquivo BMFont indica onde o Godot encontra cada letra.
    chars = sorted(set(chr(i) for i in range(32, 127)) | set("ÁÀÂÃÄÉÊÈÍÌÎÓÔÕÖÚÙÛÜÇáàâãäéêèíìîóôõöúùûüçºª×→←•"))
    atlas = Canvas(256, math.ceil(len(chars) / 16) * 20)
    records = []
    import unicodedata
    for i, ch in enumerate(chars):
        x, y = (i % 16) * 16, (i // 16) * 20
        # NFD separa a letra do acento, permitindo desenhar os sinais do português.
        special = unicodedata.normalize("NFD", ch)
        accented = len(special) > 1
        for yy, row in enumerate(glyph(ch)):
            for xx, v in enumerate(row):
                if v == "1":
                    atlas.rect(x + xx * 2, y + 3 + yy * 2, 2, 2, "#ffffff")
        if accented:
            mark = special[1]
            if mark == "\u0301":
                atlas.rect(x + 6, y, 4, 1, "#ffffff")
                atlas.rect(x + 4, y + 1, 4, 1, "#ffffff")
            elif mark == "\u0300":
                atlas.rect(x + 2, y, 4, 1, "#ffffff")
                atlas.rect(x + 4, y + 1, 4, 1, "#ffffff")
            elif mark in ("\u0303", "\u0302"):
                atlas.rect(x + 2, y + 1, 2, 1, "#ffffff")
                atlas.rect(x + 4, y, 4, 1, "#ffffff")
                atlas.rect(x + 8, y + 1, 2, 1, "#ffffff")
            elif mark == "\u0327":
                atlas.rect(x + 6, y + 17, 2, 1, "#ffffff")
                atlas.rect(x + 4, y + 18, 3, 1, "#ffffff")
        if ch == "×":
            atlas.rect(x, y, 16, 20, (0, 0, 0, 0))
            for k in range(5):
                atlas.rect(x + k * 2, y + 4 + k * 2, 2, 2, "#ffffff")
                atlas.rect(x + 8 - k * 2, y + 4 + k * 2, 2, 2, "#ffffff")
        # xadvance é a distância entre o início de uma letra e o início da próxima.
        records.append(f"char id={ord(ch)} x={x} y={y} width=10 height=19 xoffset=0 yoffset=-1 xadvance=12 page=0 chnl=15")
    atlas.save("arcade_font.png")
    # Os metadados associam o atlas à fonte e definem a altura das linhas no Godot.
    body = ['info face="Orbital Mono" size=16 bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=0,0', f'common lineHeight=20 base=17 scaleW={atlas.w} scaleH={atlas.h} pages=1 packed=0', 'page id=0 file="arcade_font.png"', f'chars count={len(chars)}']
    (OUT / "arcade.fnt").write_text("\n".join(body + records) + "\n")


if __name__ == "__main__":
    make_sprites()
    make_arena()
    make_cabinet()
    make_menu()
    make_logo()
    make_font()
    print(f"Recursos originais gerados em {OUT}")
