extends RefCounted
## Visual style: palette, fonts, textures and drawing helpers.

const FONT_DISPLAY := preload("res://assets/fonts/RussoOne-Regular.ttf")
const FONT_BOLD := preload("res://assets/fonts/Rajdhani-Bold.ttf")
const FONT_SEMI := preload("res://assets/fonts/Rajdhani-SemiBold.ttf")

const BG := preload("res://assets/bg.jpg")
const LOGO := preload("res://assets/logo.png")
const BLOCKS := [
	preload("res://assets/blocks/block_0.png"), preload("res://assets/blocks/block_1.png"),
	preload("res://assets/blocks/block_2.png"), preload("res://assets/blocks/block_3.png"),
	preload("res://assets/blocks/block_4.png"), preload("res://assets/blocks/block_5.png"),
	preload("res://assets/blocks/block_6.png"),
]
const ICONS := {
	"left": preload("res://assets/icons/left.png"),
	"right": preload("res://assets/icons/right.png"),
	"up": preload("res://assets/icons/up.png"),
	"down": preload("res://assets/icons/down.png"),
	"drop": preload("res://assets/icons/drop.png"),
	"rotate": preload("res://assets/icons/rotate.png"),
	"rotate_ccw": preload("res://assets/icons/rotate_ccw.png"),
	"hold": preload("res://assets/icons/hold.png"),
	"pause": preload("res://assets/icons/pause.png"),
	"play": preload("res://assets/icons/play.png"),
	"sound_on": preload("res://assets/icons/sound_on.png"),
	"sound_off": preload("res://assets/icons/sound_off.png"),
	"music_on": preload("res://assets/icons/music_on.png"),
	"music_off": preload("res://assets/icons/music_off.png"),
	"trophy": preload("res://assets/icons/trophy.png"),
	"home": preload("res://assets/icons/home.png"),
	"retry": preload("res://assets/icons/retry.png"),
}

# Palette
const TEXT := Color("f2f4ff")
const MUTED := Color("8f97c9")
const GOLD := Color("ffd34d")
const CYAN := Color("36e2ff")
const PINK := Color("ff4fb8")
const PANEL := Color(0.07, 0.08, 0.2, 0.72)
const PANEL_BORDER := Color(1, 1, 1, 0.1)
const PIECE_COLORS := [
	Color("ff6fae"), Color("3de8b5"), Color("ffc247"), Color("4db8ff"),
	Color("9a7bff"), Color("ff7a4d"), Color("b6e04a"),
]
const MEDALS := [Color("ffd34d"), Color("d5def0"), Color("e3955f")]

# Button colour schemes: [face, bottom edge]
const BTN_PRIMARY := [Color("19c7e6"), Color("0d6f99")]
const BTN_ACCENT := [Color("9b5cff"), Color("5a2bb3")]
const BTN_GLASS := [Color(1, 1, 1, 0.09), Color(0, 0, 0, 0.35)]
const BTN_DANGER := [Color("c43d5e"), Color("6e1d33")]

static var _label_font: FontVariation


## Letter-spaced small caps font for captions.
static func caption_font() -> Font:
	if _label_font == null:
		_label_font = FontVariation.new()
		_label_font.base_font = FONT_BOLD
		_label_font.spacing_glyph = 3
	return _label_font


static func panel_box(bg: Color = PANEL, radius: int = 16, border: Color = PANEL_BORDER,
		glow: Color = Color(0, 0, 0, 0), glow_size: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.set_border_width_all(2)
	s.border_color = border
	s.shadow_color = glow
	s.shadow_size = glow_size
	s.anti_aliasing = true
	return s


## Chunky "pressable" button face: a coloured top with a darker bottom edge.
static func button_box(scheme: Array, pressed: bool, radius: int = 18) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	var face: Color = scheme[0]
	s.bg_color = face.lightened(0.12) if pressed else face
	s.set_corner_radius_all(radius)
	s.border_color = scheme[1]
	s.border_width_bottom = 2 if pressed else 7
	s.border_width_top = 5 if pressed else 0
	s.border_blend = false
	if face.a < 1.0:
		s.border_width_left = 2
		s.border_width_right = 2
		s.border_width_top = 2 if not pressed else 6
		s.border_color = Color(1, 1, 1, 0.14)
	s.shadow_color = Color(0, 0, 0, 0.3)
	s.shadow_size = 6
	s.shadow_offset = Vector2(0, 3)
	s.anti_aliasing = true
	return s


static func draw_block(ci: CanvasItem, kind: int, rect: Rect2, alpha: float = 1.0) -> void:
	ci.draw_texture_rect(BLOCKS[kind], rect, false, Color(1, 1, 1, alpha))


static func draw_ghost(ci: CanvasItem, kind: int, rect: Rect2) -> void:
	var c: Color = PIECE_COLORS[kind]
	var s := StyleBoxFlat.new()
	s.bg_color = Color(c.r, c.g, c.b, 0.12)
	s.set_corner_radius_all(5)
	s.set_border_width_all(2)
	s.border_color = Color(c.r, c.g, c.b, 0.55)
	s.anti_aliasing = true
	ci.draw_style_box(s, rect.grow(-2))


## Draws a piece (rotation 0) centred on `center`.
static func draw_piece_centered(ci: CanvasItem, cells: Array, kind: int, center: Vector2,
		cell: float, alpha: float = 1.0) -> void:
	var lo := Vector2(99, 99)
	var hi := Vector2(-99, -99)
	for c in cells:
		lo = Vector2(minf(lo.x, c.x), minf(lo.y, c.y))
		hi = Vector2(maxf(hi.x, c.x), maxf(hi.y, c.y))
	var origin := center - (hi - lo + Vector2.ONE) * cell * 0.5 - lo * cell
	for c in cells:
		draw_block(ci, kind, Rect2(origin + Vector2(c) * cell, Vector2(cell, cell)), alpha)


static func text(ci: CanvasItem, font: Font, pos: Vector2, s: String, size: int,
		color: Color = TEXT, align: int = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1,
		outline: int = 0, outline_color: Color = Color(0.03, 0.02, 0.1, 0.9)) -> void:
	if outline > 0:
		ci.draw_string_outline(font, pos, s, align, width, size, outline, outline_color)
	ci.draw_string(font, pos, s, align, width, size, color)


static func draw_icon(ci: CanvasItem, icon: String, center: Vector2, size: float,
		color: Color = TEXT) -> void:
	ci.draw_texture_rect(ICONS[icon], Rect2(center - Vector2(size, size) * 0.5, Vector2(size, size)), false, color)
