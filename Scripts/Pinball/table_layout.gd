## Medidas locais da mesa; arte, trilhos e testes seguem a mesma geometria.
extends RefCounted

const SIZE := Vector2(640, 900)
const SPAWN := Vector2(590, 846)
const FLIPPERS := [Vector2(208, 825), Vector2(412, 825)]
const ROLLOVERS := [Vector2(230, 105), Vector2(310, 105), Vector2(390, 105)]
static var TOP_DIVIDERS := [
	PackedVector2Array([Vector2(190, 65), Vector2(190, 135)]),
	PackedVector2Array([Vector2(270, 65), Vector2(270, 135)]),
	PackedVector2Array([Vector2(350, 65), Vector2(350, 135)]),
	PackedVector2Array([Vector2(430, 95), Vector2(430, 135)])]
static var OUTER := PackedVector2Array([
	Vector2(58, 886), Vector2(34, 850), Vector2(30, 765), Vector2(30, 100),
	Vector2(42, 56), Vector2(68, 28), Vector2(104, 14), Vector2(538, 14),
	Vector2(574, 24), Vector2(598, 46), Vector2(612, 74), Vector2(616, 120), Vector2(616, 874)])
static var GUIDES := [
	PackedVector2Array([Vector2(558, 118), Vector2(558, 880)]),
	PackedVector2Array([Vector2(568, 874), Vector2(616, 874)]),
	PackedVector2Array([Vector2(58, 740), Vector2(78, 774), Vector2(150, 800), Vector2(196, 818)]),
	PackedVector2Array([Vector2(550, 740), Vector2(530, 774), Vector2(458, 800), Vector2(424, 818)]),
	PackedVector2Array([Vector2(94, 520), Vector2(80, 420), Vector2(80, 180), Vector2(105, 122), Vector2(146, 88)]),
	PackedVector2Array([Vector2(516, 520), Vector2(526, 410), Vector2(526, 180), Vector2(500, 124), Vector2(465, 88)])]
# A menor passagem tem 32,8 px livres para uma esfera de diâmetro 20 px.
static var SLING_LEFT := PackedVector2Array([Vector2(110, 678), Vector2(196, 750), Vector2(132, 750)])
static var SLING_RIGHT := PackedVector2Array([Vector2(510, 678), Vector2(488, 750), Vector2(424, 750)])
