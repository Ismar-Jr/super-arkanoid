## Coordenadas locais compartilhadas pelos trilhos visuais e suas colisões.
extends RefCounted

const SPAWN := Vector2(590, 426)
static var OUTER := PackedVector2Array([
	Vector2(58, 466), Vector2(34, 430), Vector2(30, 345), Vector2(30, 100),
	Vector2(42, 56), Vector2(68, 28), Vector2(104, 14), Vector2(538, 14),
	Vector2(574, 24), Vector2(598, 46), Vector2(612, 74), Vector2(616, 120), Vector2(616, 454)])
static var GUIDES := [
	PackedVector2Array([Vector2(558, 118), Vector2(558, 460)]),
	PackedVector2Array([Vector2(568, 454), Vector2(616, 454)]),
	PackedVector2Array([Vector2(58, 320), Vector2(78, 354), Vector2(150, 380), Vector2(196, 398)]),
	PackedVector2Array([Vector2(550, 320), Vector2(530, 354), Vector2(458, 380), Vector2(424, 398)])]
static var SLING_LEFT := PackedVector2Array([Vector2(94, 298), Vector2(180, 370), Vector2(116, 370)])
static var SLING_RIGHT := PackedVector2Array([Vector2(526, 298), Vector2(504, 370), Vector2(440, 370)])
