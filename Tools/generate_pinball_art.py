#!/usr/bin/env python3
"""Arte original da mesa Orbital Reactor; requer somente Python 3."""
from pathlib import Path
import importlib.util
import math
import random
import sys

sys.dont_write_bytecode = True

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "Assets" / "Pinball"
OUT.mkdir(parents=True, exist_ok=True)
spec = importlib.util.spec_from_file_location("orbital_pixel_art", ROOT / "Tools" / "generate_art.py")
art = importlib.util.module_from_spec(spec)
spec.loader.exec_module(art)
art.OUT = OUT
Canvas, mix, bolt, text = art.Canvas, art.mix, art.bolt, art.text


def ring(c, cx, cy, radius, color, width=1):
    # Segmentos inteiros mantêm o contorno nítido em baixa resolução.
    points = [(round(cx + math.cos(i * math.tau / 96) * radius), round(cy + math.sin(i * math.tau / 96) * radius)) for i in range(97)]
    for a, b in zip(points, points[1:]):
        c.line(a[0], a[1], b[0], b[1], color, width)


def rail(c, points, width=8):
    for a, b in zip(points, points[1:]):
        c.line(a[0] - width // 2 + 2, a[1] - width // 2 + 4, b[0] - width // 2 + 2, b[1] - width // 2 + 4, "#030b17", width + 4)
        c.line(a[0] - width // 2, a[1] - width // 2, b[0] - width // 2, b[1] - width // 2, "#253c51", width + 2)
        c.line(a[0] - width // 2, a[1] - width // 2, b[0] - width // 2, b[1] - width // 2, "#8ba1ac", width)
        c.line(a[0] - width // 2 + 1, a[1] - width // 2 + 1, b[0] - width // 2 + 1, b[1] - width // 2 + 1, "#d2dfd2", 2)
        c.line(a[0] + width // 2 - 2, a[1] + width // 2 - 2, b[0] + width // 2 - 2, b[1] + width // 2 - 2, "#3c5c73", 2)


def lamp(c, x, y, color="#75eddd", size=4):
    c.rect(x - 2, y - 2, size + 4, size + 4, "#080f1d")
    c.rect(x - 1, y - 1, size + 2, size + 2, "#2c4d5d")
    c.rect(x, y, size, size, color)
    c.rect(x, y, size, 1, "#e3fff0")


def dotted_orbit(c, cx, cy, rx, ry, tilt, color):
    for i in range(96):
        if i % 3 == 0:
            continue
        a = i * math.tau / 96
        x = math.cos(a) * rx
        y = math.sin(a) * ry
        xx = round(cx + x * math.cos(tilt) - y * math.sin(tilt))
        yy = round(cy + x * math.sin(tilt) + y * math.cos(tilt))
        c.rect(xx, yy, 2, 2, color)


def make_field():
    c = Canvas(640, 480, "#090f20")
    for y in range(0, 480, 2):
        c.rect(0, y, 640, 2, mix("#12213a", "#0a1326", y / 480))
    # Laterais de gabinete e painéis mecânicos fora da área de rebote.
    for side in (0, 1):
        x = 0 if side == 0 else 616
        c.rect(x, 0, 24, 480, "#19253c")
        c.line(x + 3, 0, x + 3, 479, "#41556e")
        c.line(x + 20, 0, x + 20, 479, "#080d19")
        for y in range(12, 465, 45):
            bolt(c, x + 10, y)
            c.rect(x + 7, y + 12, 10, 18, "#0c1426")
            c.rect(x + 9, y + 14, 2, 10, "#306d7d")
            c.rect(x + 13, y + 14, 2, 10, "#2d465e")
    # Maquinário de fundo, trilhas finas e ilhas de circuito.
    rng = random.Random(407)
    for x in (74, 132, 482, 530):
        for y in range(112, 310, 46):
            side = -1 if x < 300 else 1
            c.line(x, y, x + 14 * side, y + 14, "#233c52")
            c.line(x + 14 * side, y + 14, x + 14 * side, y + 36, "#233c52")
            c.rect(x + 14 * side - 2, y + 34, 5, 4, "#365369")
            c.rect(x + 3 * side, y, 2, 2, "#4c6a7c")
    for _ in range(155):
        x, y = rng.randrange(70, 540), rng.randrange(95, 384)
        if rng.random() < .55:
            c.pixel(x, y, "#294057")
    # Órbitas impressas no playfield, com baixo contraste.
    dotted_orbit(c, 310, 217, 164, 113, .12, "#2d4861")
    dotted_orbit(c, 310, 217, 119, 159, -.28, "#203d54")
    for x in (235, 310, 385):
        c.line(x, 88, x, 104, "#38586c", 2)
        c.line(x, 104, x - 4, 100, "#38586c", 2)
        c.line(x, 104, x + 4, 100, "#38586c", 2)
    # Coroa superior de metal escuro com encaixes individuais dos alvos.
    c.poly([(150, 34), (472, 34), (493, 47), (483, 89), (137, 89), (127, 47)], "#091321")
    c.poly([(153, 36), (470, 36), (489, 48), (479, 85), (141, 85), (131, 48)], "#2a4055")
    c.line(153, 37, 469, 37, "#6d8793", 2)
    c.rect(197, 43, 228, 16, "#111f33")
    text(c, "O R B I T A L", 272, 48, 1, "#8eafa8")
    for x in (235, 310, 385):
        c.rect(x - 20, 61, 40, 25, "#070f1f")
        c.rect(x - 17, 63, 34, 20, "#446075")
        lamp(c, x - 2, 83, "#7d795a", 3)
    for x in (148, 472):
        bolt(c, x, 49)
        bolt(c, x, 74)
    # Bases sob os bumpers, sem pintar a peça móvel/acesa.
    for x, y in ((235, 146), (385, 146), (310, 227)):
        c.ellipse(x, y + 4, 34, 31, "#070e1d")
        ring(c, x, y, 31, "#456074", 2)
        ring(c, x, y, 35, "#273f55")
        for angle in range(0, 360, 45):
            a = math.radians(angle)
            px, py = round(x + math.cos(a) * 34), round(y + math.sin(a) * 34)
            c.rect(px - 2, py - 2, 4, 4, "#566677")
    # Inlay do reator, deliberadamente mais escuro que bola e bumpers.
    c.poly([(270, 277), (350, 277), (365, 291), (365, 326), (350, 341), (270, 341), (255, 326), (255, 291)], "#101d31")
    c.line(270, 278, 349, 278, "#355165")
    c.line(270, 340, 349, 340, "#263f55")
    ring(c, 310, 310, 23, "#2a4a5d")
    ring(c, 310, 310, 28, "#263e55")
    c.poly([(310, 288), (328, 299), (328, 320), (310, 331), (292, 320), (292, 299)], "#1c3549")
    c.poly([(310, 295), (322, 302), (322, 316), (310, 323), (298, 316), (298, 302)], "#294b5a")
    c.poly([(310, 301), (317, 305), (317, 313), (310, 317), (303, 313), (303, 305)], "#3e6a69")
    text(c, "ORBITAL", 290, 349, 1, "#5a7b82")
    text(c, "REACTOR", 290, 361, 1, "#5a7b82")
    c.line(241, 352, 277, 352, "#314c60")
    c.line(344, 352, 379, 352, "#314c60")
    c.line(241, 364, 277, 364, "#314c60")
    c.line(344, 364, 379, 364, "#314c60")
    # Triângulos dos slingshots: superfície impressa sob o contorno físico.
    left = [(94, 298), (180, 370), (116, 370)]
    for points in (left, [(620 - x, y) for x, y in left]):
        c.poly(points, "#081321")
        a, b, d = points
        cx = sum(p[0] for p in points) / 3
        cy = sum(p[1] for p in points) / 3
        inner = [(round(cx + (x - cx) * .86), round(cy + (y - cy) * .86)) for x, y in points]
        c.poly(inner, "#9d784f")
        inner2 = [(round(cx + (x - cx) * .70), round(cy + (y - cy) * .70)) for x, y in points]
        c.poly(inner2, "#2e3f52")
        inner3 = [(round(cx + (x - cx) * .43), round(cy + (y - cy) * .43)) for x, y in points]
        c.poly(inner3, "#243c50")
        c.line(a[0] + (5 if a[0] < 310 else -5), a[1] + 15, b[0] + (-12 if a[0] < 310 else 12), b[1] - 7, "#e4b76b", 3)
        for x, y in points:
            bx = round(cx + (x - cx) * .70)
            by = round(cy + (y - cy) * .70)
            bolt(c, bx - 1, by - 1)
    # Guias inferiores nas mesmas coordenadas dos corpos estáticos.
    rail(c, [(58, 320), (78, 354), (150, 380), (196, 398)], 8)
    rail(c, [(550, 320), (530, 354), (458, 380), (424, 398)], 8)
    for x, y in ((71, 346), (178, 394), (544, 346), (439, 394)):
        bolt(c, x - 1, y - 1)
    # Encaixes das duas palhetas e marcas de drenagem.
    for x, y in ((208, 405), (412, 405)):
        c.ellipse(x, y + 2, 17, 16, "#070d1a")
        c.ellipse(x, y, 14, 14, "#39536c")
        ring(c, x, y, 13, "#8b9a9d", 2)
        ring(c, x, y, 19, "#2b4155")
    for x in (92, 526):
        for y in range(390, 459, 16):
            c.poly([(x - 6, y), (x, y + 5), (x + 6, y), (x + 6, y + 4), (x, y + 10), (x - 6, y + 4)], "#354c5d")
    c.rect(253, 467, 113, 10, "#21192d")
    text(c, "D R A I N", 283, 469, 1, "#7f4f64")
    # Canal do lançador: régua e iluminações de prontidão.
    c.rect(566, 102, 40, 358, "#07111e")
    c.rect(570, 112, 31, 346, "#162c3d")
    c.line(575, 122, 575, 448, "#294c59")
    c.line(599, 108, 599, 448, "#385363")
    for y in range(139, 421, 25):
        c.poly([(580, y + 7), (586, y), (592, y + 7), (590, y + 9), (586, y + 4), (582, y + 9)], "#5c6954")
    for y in range(420, 452, 6):
        c.rect(578, y, 18, 2, "#67747c")
        c.rect(580, y + 2, 14, 1, "#273c4a")
    c.rect(577, 453, 21, 5, "#c69b61")
    c.rect(580, 453, 15, 2, "#f2d298")
    # Trilhos externos e arco que conduz a bola ao topo da mesa.
    rail(c, [(58, 466), (34, 430), (30, 345), (30, 100), (42, 56), (68, 28), (104, 14), (538, 14), (574, 24), (598, 46), (612, 74), (616, 120), (616, 454)], 8)
    rail(c, [(558, 118), (558, 460)], 8)
    rail(c, [(568, 454), (616, 454)], 6)
    # Conectores, lâmpadas e pequenos indicadores do setor.
    for x, y in ((53, 82), (72, 48), (114, 26), (493, 26), (581, 68), (610, 108), (42, 250), (610, 277)):
        bolt(c, x - 1, y - 1)
    for x, y in ((65, 115), (65, 235), (535, 113), (535, 250)):
        lamp(c, x, y, "#81b9ac", 3)
    for x, y in ((161, 59), (450, 59)):
        c.rect(x, y, 8, 14, "#132233")
        for yy in range(y + 2, y + 12, 4):
            c.rect(x + 2, yy, 4, 1, "#a58d5c")
    c.save("playfield.png")


def make_bumper():
    c = Canvas(64, 64)
    c.ellipse(31, 32, 31, 30, (52, 182, 194, 24))
    c.ellipse(31, 34, 28, 27, (5, 14, 27, 220))
    c.ellipse(31, 31, 27, 27, "#0b1525")
    c.ellipse(31, 30, 25, 25, "#718e9b")
    c.ellipse(31, 28, 23, 22, "#b4c9c6")
    c.ellipse(31, 29, 21, 21, "#2b6274")
    c.ellipse(31, 28, 18, 18, "#4ec3c0")
    c.ellipse(31, 26, 15, 14, "#a2f0d9")
    c.ellipse(30, 24, 11, 9, "#d8ffe6")
    c.ellipse(30, 26, 9, 9, "#72c5bb")
    c.poly([(31, 17), (39, 22), (39, 31), (31, 36), (23, 31), (23, 22)], "#284e61")
    c.poly([(31, 20), (36, 23), (36, 29), (31, 32), (26, 29), (26, 23)], "#efffcd")
    c.rect(26, 20, 6, 2, "#ffffff")
    for degrees in range(0, 360, 60):
        a = math.radians(degrees)
        x, y = round(31 + math.cos(a) * 24), round(30 + math.sin(a) * 24)
        c.rect(x - 3, y - 2, 6, 4, "#1e3d51")
        c.rect(x - 2, y - 2, 4, 1, "#f0d79d")
    ring(c, 31, 30, 27, "#2e5c6d")
    c.save("bumper.png")


def make_flipper():
    c = Canvas(100, 24)
    points = [(10, 0), (18, 1), (91, 6), (97, 9), (99, 12), (97, 16), (91, 18), (18, 23), (9, 23), (3, 20), (0, 15), (0, 8), (4, 3)]
    c.poly(points, "#09111e")
    c.poly([(10, 1), (18, 2), (91, 7), (96, 10), (97, 13), (94, 16), (18, 21), (9, 21), (3, 17), (2, 10), (5, 5)], "#d6a765")
    c.poly([(11, 3), (18, 4), (90, 8), (94, 10), (94, 13), (90, 15), (18, 19), (9, 19), (5, 16), (5, 9), (7, 6)], "#dce7cf")
    c.poly([(22, 6), (86, 10), (89, 12), (86, 13), (22, 17)], "#73929a")
    c.line(23, 7, 86, 10, "#f0f5d7", 2)
    c.line(25, 15, 85, 13, "#31536b", 2)
    for x in range(28, 73, 8):
        c.line(x, 10, x + 3, 13, "#a5d6ca")
    c.ellipse(11, 11, 8, 8, "#344f66")
    c.ellipse(11, 10, 6, 6, "#94abb2")
    c.ellipse(11, 10, 3, 3, "#20374c")
    c.line(9, 9, 12, 12, "#c9d8ce", 2)
    c.rect(19, 5, 3, 13, "#416b77")
    c.rect(20, 6, 1, 11, "#9de5ce")
    c.save("flipper.png")


def make_ball():
    c = Canvas(20, 20)
    c.ellipse(9.5, 9.5, 9.5, 9.5, (107, 188, 214, 40))
    c.ellipse(9.5, 9.5, 8.5, 8.5, "#102c46")
    c.ellipse(9, 9, 8, 8, "#7397ab")
    c.ellipse(8, 7, 6.5, 5.5, "#dce9de")
    c.ellipse(7, 6, 4, 3, "#ffffff")
    c.rect(4, 6, 3, 3, "#ffffff")
    c.rect(5, 12, 9, 2, "#2c647e")
    c.rect(7, 15, 7, 1, "#bfdace")
    c.pixel(15, 10, "#e5f9e3")
    c.save("ball.png")
    c.save("life.png")


def make_target():
    c = Canvas(28, 18)
    c.poly([(3, 0), (24, 0), (27, 3), (27, 15), (24, 17), (3, 17), (0, 14), (0, 3)], "#06101d")
    c.rect(3, 1, 21, 15, "#a68798")
    c.rect(4, 2, 19, 2, "#f6d1c7")
    c.rect(3, 4, 2, 9, "#dc82a6")
    c.rect(6, 4, 16, 10, "#733e69")
    c.rect(8, 5, 12, 7, "#d96a99")
    c.rect(10, 5, 8, 3, "#ffe9cd")
    c.rect(8, 12, 12, 2, "#3f2b4f")
    c.rect(23, 5, 2, 8, "#334457")
    c.rect(5, 15, 18, 1, "#283c4d")
    c.save("target.png")


def make_logo():
    c = Canvas(560, 140)
    for x in (23, 372):
        c.poly([(x, 25), (x + 160, 25), (x + 147, 34), (x + 14, 34)], "#39576b")
        c.line(x + 8, 26, x + 151, 26, "#9cbaa9")
        for xx in range(x + 17, x + 142, 13):
            c.line(xx, 29, xx + 5, 29, "#142c43", 2)
    text(c, "SUPER", 207, 9, 5, "#132b43", .3)
    text(c, "SUPER", 206, 5, 5, "#9ce6d8", .3)
    mask = Canvas(560, 140)
    text(mask, "PINBALL", 48, 50, 11, "#ffffff", 1.5)
    coords = [(x, y) for y in range(mask.h) for x in range(mask.w) if mask.data[(y * mask.w + x) * 4 + 3]]
    for dx, dy, radius, color in ((5, 7, 4, "#030a17"), (4, 5, 3, "#294b64"), (0, 0, 3, "#081625"), (0, 0, 2, "#9ce7d9"), (0, 0, 0, "#ffffff")):
        for x, y in coords:
            c.rect(x + dx - radius, y + dy - radius, 1 + radius * 2, 1 + radius * 2, color)
    for x, y in coords:
        f = (y - 50) / 77
        if f < .42:
            color = mix("#ffffdc", "#e4b879", f / .42)
        elif f < .49:
            color = "#715763"
        else:
            color = mix("#e8b374", "#a85a61", (f - .49) * 1.8)
        c.pixel(x, y, color)
    for x, y in ((65, 51), (387, 52), (213, 115)):
        c.line(x - 5, y, x + 5, y, "#ffffff")
        c.line(x, y - 5, x, y + 5, "#ffffff")
        c.rect(x - 1, y - 1, 3, 3, "#ffffff")
    c.save("logo.png")


if __name__ == "__main__":
    make_field()
    make_bumper()
    make_flipper()
    make_ball()
    make_target()
    make_logo()
    print(f"Sete PNGs originais de pinball gerados em {OUT}")
