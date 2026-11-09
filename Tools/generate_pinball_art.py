#!/usr/bin/env python3
"""Arte vetorial original e reproduzível do Orbital Reactor. Só requer Python 3."""
from pathlib import Path
from xml.sax.saxutils import escape
import math
import random

OUT = Path(__file__).resolve().parents[1] / 'Assets' / 'Pinball'
OUT.mkdir(parents=True, exist_ok=True)

# Alfabeto vetorial próprio: traços contínuos, sem fontes externas ou dependências.
GLYPHS = {
 'A':'M0 7L2.5 0 5 7M1 4.5H4', 'B':'M0 7V0H3.2Q5 0 5 1.8Q5 3.5 3.2 3.5H0M3.2 3.5Q5.3 3.5 5.3 5.3Q5.3 7 3.2 7Z',
 'C':'M5 0H1.5Q0 0 0 1.5V5.5Q0 7 1.5 7H5', 'D':'M0 7V0H2.5Q5 0 5 3.5Q5 7 2.5 7Z',
 'E':'M5 0H0V7H5M0 3.5H4', 'F':'M0 7V0H5M0 3.5H4', 'G':'M5 1Q4.5 0 2.5 0Q0 0 0 3.5Q0 7 2.5 7H5V4H3',
 'H':'M0 0V7M5 0V7M0 3.5H5', 'I':'M0 0H5M2.5 0V7M0 7H5', 'J':'M0 5.5Q0 7 2 7Q5 7 5 4V0',
 'K':'M0 0V7M5 0L0 3.5 5 7', 'L':'M0 0V7H5', 'M':'M0 7V0L2.5 4 5 0V7', 'N':'M0 7V0L5 7V0',
 'O':'M2.5 0Q0 0 0 3.5Q0 7 2.5 7Q5 7 5 3.5Q5 0 2.5 0Z', 'P':'M0 7V0H3Q5 0 5 2Q5 4 3 4H0',
 'Q':'M2.5 0Q0 0 0 3.5Q0 7 2.5 7Q5 7 5 3.5Q5 0 2.5 0ZM3.5 5.5L6 8', 'R':'M0 7V0H3Q5 0 5 2Q5 4 3 4H0M3 4L5 7',
 'S':'M5 0H2Q0 0 0 1.8Q0 3.5 2.5 3.5Q5 3.5 5 5.2Q5 7 3 7H0', 'T':'M0 0H5M2.5 0V7',
 'U':'M0 0V4.5Q0 7 2.5 7Q5 7 5 4.5V0', 'V':'M0 0L2.5 7 5 0', 'W':'M0 0L1 7 2.5 3.5 4 7 5 0',
 'X':'M0 0L5 7M5 0L0 7', 'Y':'M0 0L2.5 3.5 5 0M2.5 3.5V7', 'Z':'M0 0H5L0 7H5',
 '0':'M2.5 0Q0 0 0 3.5Q0 7 2.5 7Q5 7 5 3.5Q5 0 2.5 0ZM1 6L4 1', '1':'M1 1.5L3 0V7M1 7H5',
 '2':'M0 1.5Q0 0 2.5 0Q5 0 5 1.8Q5 3 0 7H5', '3':'M0 0H3Q5 0 5 1.7Q5 3.5 2 3.5Q5 3.5 5 5.2Q5 7 3 7H0',
 '4':'M4 7V0L0 5H5', '5':'M5 0H0V3.5H3Q5 3.5 5 5.2Q5 7 3 7H0', '6':'M5 0H2Q0 0 0 3.5V5Q0 7 2.5 7Q5 7 5 5Q5 3 2.5 3Q0 3 0 5',
 '7':'M0 0H5L1 7', '8':'M2.5 0Q0 0 0 1.7Q0 3.5 2.5 3.5Q5 3.5 5 5.2Q5 7 2.5 7Q0 7 0 5.2Q0 3.5 2.5 3.5Q5 3.5 5 1.7Q5 0 2.5 0Z',
 '9':'M0 7H3Q5 7 5 3.5V2Q5 0 2.5 0Q0 0 0 2Q0 4 2.5 4Q5 4 5 2', '+':'M0 3.5H5M2.5 1V6', '-':'M0 3.5H5', '/':'M0 7L5 0', '.':'M2.5 6.7V7'
}
DEFS = '''<defs>
 <linearGradient id="field" x2="0.15" y2="1"><stop stop-color="#173744"/><stop offset=".56" stop-color="#132837"/><stop offset="1" stop-color="#091522"/></linearGradient>
 <linearGradient id="chrome" x2=".25" y2="1"><stop stop-color="#edf5e9"/><stop offset=".18" stop-color="#a4b8b8"/><stop offset=".37" stop-color="#536d77"/><stop offset=".51" stop-color="#e6ede0"/><stop offset=".65" stop-color="#839ca2"/><stop offset="1" stop-color="#354757"/></linearGradient>
 <linearGradient id="gold" x2=".3" y2="1"><stop stop-color="#ffdf9d"/><stop offset=".5" stop-color="#bd8950"/><stop offset="1" stop-color="#82603e"/></linearGradient>
 <linearGradient id="cream" x2=".3" y2="1"><stop stop-color="#ffefd1"/><stop offset=".48" stop-color="#e8d1a2"/><stop offset="1" stop-color="#b99361"/></linearGradient>
 <linearGradient id="rubber" x2=".2" y2="1"><stop stop-color="#ff776a"/><stop offset=".4" stop-color="#cb414d"/><stop offset="1" stop-color="#752936"/></linearGradient>
 <radialGradient id="ball" cx=".29" cy=".23" r=".8"><stop stop-color="#fff"/><stop offset=".16" stop-color="#f4f6ed"/><stop offset=".43" stop-color="#adc6cb"/><stop offset=".66" stop-color="#253e53"/><stop offset=".81" stop-color="#7595a3"/><stop offset="1" stop-color="#dae4dd"/></radialGradient>
 <radialGradient id="teal" cx=".36" cy=".25"><stop stop-color="#e5fff2"/><stop offset=".32" stop-color="#91efce"/><stop offset=".75" stop-color="#27a4a2"/><stop offset="1" stop-color="#155d74"/></radialGradient>
 <radialGradient id="amber" cx=".36" cy=".25"><stop stop-color="#fff3b6"/><stop offset=".42" stop-color="#f4ba65"/><stop offset="1" stop-color="#995437"/></radialGradient>
 <radialGradient id="planet" cx=".31" cy=".24"><stop stop-color="#f1d2a0"/><stop offset=".45" stop-color="#b98b67"/><stop offset=".77" stop-color="#776b69"/><stop offset="1" stop-color="#293f51"/></radialGradient>
 <linearGradient id="visor" x2=".8" y2="1"><stop stop-color="#6fcec2"/><stop offset=".4" stop-color="#247988"/><stop offset="1" stop-color="#112739"/></linearGradient>
 <pattern id="grain" width="4" height="4" patternUnits="userSpaceOnUse"><circle cx="1" cy="1" r=".3" fill="#f9e6b4" opacity=".08"/></pattern>
</defs>'''

class SVG:
    def __init__(self, w, h):
        self.parts = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">', DEFS]
    def add(self, markup): self.parts.append(markup)
    def path(self, d, fill='none', stroke='none', width=1, extra=''):
        self.add(f'<path d="{d}" fill="{fill}" stroke="{stroke}" stroke-width="{width}" stroke-linejoin="round" stroke-linecap="round" {extra}/>')
    def circle(self, x, y, r, fill, stroke='none', width=1, extra=''):
        self.add(f'<circle cx="{x}" cy="{y}" r="{r}" fill="{fill}" stroke="{stroke}" stroke-width="{width}" {extra}/>')
    def ellipse(self, x, y, rx, ry, fill, stroke='none', width=1, extra=''):
        self.add(f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="{fill}" stroke="{stroke}" stroke-width="{width}" {extra}/>')
    def rect(self, x,y,w,h,fill,rx=0,extra=''):
        self.add(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{fill}" {extra}/>')
    def text(self, value, x, y, size=12, color='#dac294', tracking=2, weight=.65):
        scale=size/7
        total=(len(value)*5+(len(value)-1)*tracking)*scale
        self.add(f'<g transform="translate({x-total/2:.2f} {y}) scale({scale:.3f})" fill="none" stroke="{color}" stroke-width="{weight}" stroke-linejoin="round" stroke-linecap="round">')
        for i,ch in enumerate(value.upper()):
            if ch in GLYPHS:self.add(f'<path transform="translate({i*(5+tracking)} 0)" d="{GLYPHS[ch]}"/>')
        self.add('</g>')
    def save(self,name):
        (OUT/name).write_text('\n'.join(self.parts+['</svg>']))


def star(c,x,y,r=7,color='#d7b77c'):
    c.path(f'M{x} {y-r}L{x+1.8} {y-1.8} {x+r} {y} {x+1.8} {y+1.8} {x} {y+r} {x-1.8} {y+1.8} {x-r} {y} {x-1.8} {y-1.8}Z', color)


def bolt(c,x,y):
    c.circle(x,y,3.4,'url(#chrome)','#101e2a',.8)
    c.path(f'M{x-1} {y+1.3}L{x+1} {y-1.3}',stroke='#33434a',width=1)


def rail(c,pts,width=8):
    d='M'+'L'.join(f'{x} {y}' for x,y in pts)
    c.path(d,stroke='#040c17',width=width+6,extra='transform="translate(1 3)"')
    c.path(d,stroke='#293f4b',width=width+2)
    c.path(d,stroke='url(#chrome)',width=width)
    c.path(d,stroke='#d1dfd7',width=1.2,extra='transform="translate(-1 -1)" opacity=".75"')


def lamp(c,x,y,color='amber',arrow=False):
    c.circle(x,y,17,f'url(#{color})',extra='opacity=".05"')
    if arrow:
        d=f'M{x} {y-14}L{x+10} {y}H{x+4}V{y+14}H{x-4}V{y}H{x-10}Z'
        c.path(d,'#0b1723','#ad915c',1.2)
        c.path(d,f'url(#{color})',extra=f'transform="translate({x*.2:.2f} {y*.2:.2f}) scale(.8)" opacity=".58"')
    else:
        c.circle(x,y,12,'#081420','#c0a06c',1.2)
        c.circle(x,y,8.5,f'url(#{color})',extra='opacity=".65"')
        c.path(f'M{x-4} {y-5}Q{x} {y-7} {x+3} {y-5}',stroke='#ffe8b0',width=1,extra='opacity=".5"')


def saturn(c,x,y,r=65,quiet=False):
    opacity='opacity=".5"' if quiet else ''
    c.add(f'<g {opacity}>')
    c.ellipse(x,y+4,r*1.85,r*.45,'none','#745b48',10,extra=f'transform="rotate(-18 {x} {y+4})"')
    c.ellipse(x,y+4,r*1.85,r*.45,'none','#d9b886',2,extra=f'transform="rotate(-18 {x} {y+4})"')
    c.circle(x,y,r,'url(#planet)','#e0c192',1.5)
    for dy in (-34,-22,-9,7,19,32):
        yy=y+dy*r/65
        half=math.sqrt(max(0,r*r-(yy-y)**2))
        c.path(f'M{x-half} {yy}Q{x} {yy+6} {x+half} {yy}',stroke='#fff0cc' if dy<0 else '#704d4d',width=3,extra='opacity=".14"')
    c.path(f'M{x-r*1.76} {y+r*.43}Q{x+r*.2} {y+r*.58} {x+r*1.76} {y-r*.43}',stroke='#b1855c',width=10)
    c.path(f'M{x-r*1.76} {y+r*.40}Q{x+r*.2} {y+r*.54} {x+r*1.76} {y-r*.46}',stroke='#f1ce8f',width=2)
    c.add('</g>')


def rocket(c,x,y,scale=1):
    c.add(f'<g transform="translate({x} {y}) rotate(23) scale({scale})">')
    c.path('M-8 32L0 71 8 32Z','url(#amber)',extra='opacity=".75"')
    c.path('M-4 34L0 56 4 34Z','#fff4b5')
    c.path('M-12 15L-24 33-18 1-8-10Z','url(#rubber)','#152333',1)
    c.path('M12 15L24 33 18 1 8-10Z','url(#rubber)','#152333',1)
    c.path('M0-52C-20-25-16 10-10 34H10C16 10 20-25 0-52Z','url(#cream)','#172d3c',2)
    c.path('M0-52Q-10-37-12-26H12Q10-37 0-52Z','url(#rubber)')
    c.circle(0,-11,8,'url(#visor)','#8c7154',2)
    c.path('M-3-15Q0-19 4-16',stroke='#d5f2dc',width=2)
    c.path('M-9 19H9',stroke='#a34b42',width=4)
    c.path('M-10 28H10',stroke='#9f754c',width=3)
    c.add('</g>')


def make_field():
    c=SVG(640,900)
    c.rect(0,0,640,900,'url(#field)')
    c.rect(0,0,640,900,'url(#grain)')
    rng=random.Random(816)
    for _ in range(245):
        x,y=rng.randrange(43,550),rng.randrange(30,869)
        c.circle(x,y,rng.choice([.5,.6,1]),rng.choice(['#729296','#a38458','#c9bd92']),extra=f'opacity="{rng.uniform(.15,.5):.2f}"')
    # Faixas impressas guiam o olhar; nenhuma simula uma rampa ou bloqueio físico.
    for side in (False,True):
        c.add('<g transform="translate(620 0) scale(-1 1)">' if side else '<g>')
        c.path('M108 178L147 157 196 193 186 212 148 184 123 197 123 336 108 349Z','#b78a53',extra='opacity=".8"')
        c.path('M115 195V331',stroke='#c65850',width=5)
        c.path('M149 529L246 609',stroke='#af8553',width=11)
        c.path('M153 540L231 605',stroke='#b54948',width=4)
        c.path('M167 624L252 695',stroke='#51898a',width=10)
        c.path('M170 630L250 697',stroke='#a9bd9d',width=1.2)
        c.add('</g>')
    for x,y,r in [(158,189,7),(454,202,8),(198,309,5),(442,371,6),(179,552,6),(449,561,8),(243,705,5),(377,705,5)]:star(c,x,y,r)
    # Coroa e três rollovers, separados por trilhos metálicos reais.
    c.path('M112 29H528L551 42 541 56H104L91 43Z','url(#cream)','#182632',2)
    c.path('M120 35H521',stroke='#bd4b46',width=4)
    c.text('ORBITAL REACTOR',321,42,9,'#543e35',tracking=3,weight=.7)
    for i,x in enumerate((230,310,390)):
        c.ellipse(x,103,19,26,'#0c1a27','#ad9a70',1.2)
        c.ellipse(x,102,15,21,'#2c5a5d',extra='opacity=".45"')
        c.text('ABC'[i],x,93,17,'#c1cfaf',weight=.7)
        c.text('ROLLOVER',x,145,5.5,'#9cae9a',tracking=1.2)
    for x in (190,270,350,430):
        top = 95 if x == 430 else 65
        rail(c,[(x,top),(x,135)],8)
        for y in (top,135):
            c.circle(x,y,7,'url(#rubber)','#0a1721',1)
            bolt(c,x,y)
    c.text('POP JETS',310,183,10,'#d4bd8a',tracking=2)
    for x,y in ((240,245),(380,245),(310,345)):
        c.circle(x,y,46,'#080f1a',extra='opacity=".7"')
        c.circle(x,y,41,'url(#rubber)','#ecd9a4',1)
        c.circle(x,y,35,'#1d3f4a','#876b46',2)
        for deg in range(0,360,45):
            a=math.radians(deg);star(c,x+math.cos(a)*40,y+math.sin(a)*40,2.5,'#f2d99f')
    c.text('5 HITS ADVANCE BONUS',310,399,7,'#a6c0ae',tracking=1.1)
    # Alvos laterais e lâmpadas impressas da bancada.
    c.path('M111 359H138L154 375V503L138 521H111Z','url(#cream)','#10222e',2)
    c.path('M137 371V508',stroke='#a93e42',width=9)
    for y in (390,438,486):
        c.rect(114,y-18,19,36,'#233947',4)
        lamp(c,166,y)
        c.text('250',196,y-4,7,'#c4aa77',tracking=1.2)
    c.text('TARGET BANK',165,536,8,'#d9bd85',tracking=1)
    c.text('+1000',165,552,9,'#9bbbad',tracking=1.8)
    # Ilustração espacial serigrafada em cores quentes, com assimetria de backglass.
    c.path('M230 460Q310 412 404 470',stroke='#254f5b',width=38,extra='opacity=".55"')
    saturn(c,312,520,62)
    rocket(c,399,452,.8)
    c.path('M215 588H415',stroke='#cda56a',width=1.2)
    c.text('ORBITAL',315,594,23,'#ddc38b',tracking=2.3,weight=.8)
    c.text('REACTOR',315,626,12,'#91c3b1',tracking=3.4,weight=.7)
    for i,x in enumerate((250,280,310,340,370)):
        lamp(c,x,666,'amber' if i==0 else 'teal')
        c.text(str(i+1),x,662,7,'#f5e1a7',tracking=0,weight=.7)
    c.text('BONUS MULTIPLIER',310,688,7,'#b6b99a',tracking=1.4)
    for x in (205,415):
        for y in (422,467):lamp(c,x,y,'teal',True)
    for x in (64,540):
        c.text('ORBIT',x,562,6,'#d7ba83',tracking=1)
        for y in (596,629,662):lamp(c,x,y,'amber',True)
    # Plásticos dos slingshots: borracha vermelha, marfim impresso e parafusos aparentes.
    for right in (False,True):
        c.add('<g transform="translate(620 0) scale(-1 1)">' if right else '<g>')
        c.path('M110 678L196 750H132Z','#050d17',stroke='#050d17',width=8,extra='transform="translate(1 3)"')
        c.path('M110 678L196 750H132Z','url(#cream)','url(#rubber)',5)
        c.path('M121 697L181 744H138Z','#244c59','#a98954',1.5)
        c.path('M126 706L172 741H141Z','#316a70',extra='opacity=".7"')
        star(c,147,731,8,'#dfc594')
        for x,y in ((120,697),(176,744),(137,744)):bolt(c,x,y)
        c.add('</g>')
    guides=[[(58,740),(78,774),(150,800),(196,818)],[(550,740),(530,774),(458,800),(424,818)],[(94,520),(80,420),(80,180),(105,122),(146,88)],[(516,520),(526,410),(526,180),(500,124),(465,88)]]
    for pts in guides:rail(c,pts)
    for x,y in ((208,825),(412,825)):
        c.circle(x,y+2,19,'#050d17')
        c.circle(x,y,15,'url(#chrome)','#d5c28b',1.5)
    for x in (92,526):
        for y in range(797,866,16):c.path(f'M{x-6} {y}L{x} {y+7} {x+6} {y}',stroke='#a38559',width=2.5)
    c.text('BALL IN PLAY',310,780,7,'#b4a077',tracking=1.2)
    lamp(c,310,751)
    c.path('M153 872H466L478 900H140Z','url(#cream)','#ad8252',1)
    c.path('M160 877H460',stroke='#a84645',width=2)
    c.text('SUPER PINBALL',310,882,7,'#503c35',tracking=1.4,weight=.75)
    c.text('3 BALLS / ORBITAL REACTOR',310,895,4,'#6c5340',tracking=1.1)
    # Mola e canal do lançador: a bola pode retornar e ser relançada.
    c.rect(568,120,37,753,'#081421',8)
    c.rect(574,127,24,741,'#223b47',5)
    c.path('M577 134V864',stroke='#557b79',width=1)
    c.path('M600 126V870',stroke='#c2c6ad',width=1.3)
    for y in range(165,810,34):c.path(f'M581 {y+7}L587 {y} 593 {y+7}',stroke='#b3945e',width=2)
    for y in range(848,872,4):c.path(f'M580 {y}Q589 {y-3} 598 {y}',stroke='url(#chrome)',width=1.7)
    c.rect(578,871,23,7,'url(#gold)',2)
    outer=[(58,886),(34,850),(30,765),(30,100),(42,56),(68,28),(104,14),(538,14),(574,24),(598,46),(612,74),(616,120),(616,874)]
    rail(c,outer);rail(c,[(558,118),(558,880)]);rail(c,[(568,874),(616,874)],6)
    # Laterais do gabinete com perfis dourados e madeira escura.
    for x in (0,620):
        c.rect(x,0,20,900,'#36282b')
        c.rect(x+1,0,3,900,'url(#gold)')
        c.rect(x+6,0,10,900,'#50352e')
        c.path(f'M{x+17} 0V900',stroke='#080f18',width=2)
        for y in range(13,900,47):
            bolt(c,x+10,y)
            c.path(f'M{x+8} {y+12}V{y+28}',stroke='#886042',width=1)
    for x,y in ((52,81),(72,48),(114,26),(493,26),(581,68),(610,108)):bolt(c,x,y)
    c.save('playfield.svg')


def make_skins():
    c=SVG(64,64)
    c.circle(32,34,29,'#07111d',extra='opacity=".6"')
    c.circle(32,31,28,'url(#rubber)','#edce96',1)
    c.circle(32,30,25,'url(#chrome)','#0c2430',1)
    c.circle(32,29,21,'url(#cream)','#b99156',1)
    c.circle(32,28,17,'url(#teal)','#27797a',1)
    c.ellipse(29,23,9,5,'#d6fff0',extra='opacity=".6"')
    c.path('M32 18L35 25 43 25 37 30 39 38 32 34 25 38 27 30 21 25 29 25Z','#f7eac1','#3d756d',.8)
    for x,y in ((14,20),(49,20),(32,51)):bolt(c,x,y)
    c.save('bumper.svg')
    c=SVG(100,24)
    c.path('M12 1C-2 1-2 23 12 23L91 18Q100 16 99 12Q99 8 91 6Z','url(#rubber)','#5e2433',1)
    c.path('M12 4C2 4 2 20 12 20L90 16Q96 15 96 12Q96 10 90 9Z','url(#cream)','#f8e8bc',.6)
    c.path('M24 8L88 11Q92 12 88 13L24 17Z','#d2a768',extra='opacity=".6"')
    c.path('M24 9L86 12',stroke='#fff4d8',width=1.2)
    c.circle(12,12,6.5,'url(#chrome)','#5d665f',1)
    bolt(c,12,12)
    c.save('flipper.svg')
    c=SVG(20,20)
    c.circle(10,10,9.4,'url(#ball)','#132d3c',.6)
    c.ellipse(6.9,5.7,3.6,2.6,'#fff',extra='opacity=".88"')
    c.path('M5 14Q10 18 15 12',stroke='#d4e7e0',width=1.3,extra='opacity=".7"')
    c.save('ball.svg');c.save('life.svg')
    c=SVG(28,18)
    c.rect(.5,.5,27,17,'url(#chrome)',3)
    c.rect(3,2.5,22,13,'url(#rubber)',2)
    c.rect(6,4,16,8,'url(#amber)',1.6)
    c.path('M8 5H19',stroke='#fff1c2',width=1.5)
    c.path('M5 14H23',stroke='#6d293c',width=1.4)
    c.save('target.svg')


def make_menu():
    c=SVG(720,1120)
    c.rect(0,0,720,1120,'url(#field)')
    rng=random.Random(914)
    for _ in range(220):
        x,y=rng.randrange(38,680),rng.randrange(35,1090)
        c.circle(x,y,rng.choice([.5,1,1.4]),'#a1bfaf',extra=f'opacity="{rng.uniform(.12,.45):.2f}"')
    saturn(c,360,305,110,True)
    rocket(c,586,390,.9)
    for x,y,r in ((110,170,10),(594,180,13),(128,430,7),(576,930,12)):star(c,x,y,r,'#b3a075')
    c.path('M80 820Q130 930 268 993',stroke='#9a784c',width=3,extra='opacity=".4"')
    c.path('M90 833Q150 944 273 1000',stroke='#9a4140',width=9,extra='opacity=".3"')
    for x in (20,690):
        c.rect(x,19,10,1082,'#1c242b',2)
        c.rect(x+1,19,2,1082,'url(#gold)')
        c.path(f'M{x+7} 20V1100',stroke='#6c4e37',width=1)
        for y in range(36,1100,54):bolt(c,x+5,y)
    for y in (20,1090):
        c.rect(20,y,680,10,'#1b2731',2)
        c.rect(23,y,674,2,'url(#gold)')
    c.save('menu_background.svg')
    c=SVG(560,140)
    c.path('M35 27H170M390 27H525',stroke='url(#gold)',width=3)
    c.path('M50 33H165M395 33H510',stroke='#825443',width=1.5)
    c.text('SUPER',280,13,22,'#e9d7ab',tracking=4,weight=.7)
    c.text('PINBALL',282,62,60,'#061320',tracking=1.3,weight=1.1)
    c.text('PINBALL',280,56,60,'url(#gold)',tracking=1.3,weight=.95)
    c.text('ORBITAL REACTOR',280,128,9,'#a6d6c1',tracking=3,weight=.65)
    star(c,45,55,7,'#fff1c1');star(c,514,112,6,'#fff1c1')
    c.save('logo.svg')


if __name__ == '__main__':
    make_field();make_skins();make_menu()
    print(f'Oito SVGs originais de pinball gerados em {OUT}')
