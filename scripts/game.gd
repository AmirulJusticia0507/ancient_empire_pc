extends Node2D

const GRID_W := 9
const GRID_H := 6
const TILE := 74
const ORIGIN := Vector2(70, 170)
const MOVE_RANGE := 3
const ATTACK_RANGE := 1
const DIRS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

const BG_TOP := Color("#0b1120")
const BG_BOTTOM := Color("#1e293b")
const PANEL_BG := Color("#0f172a")
const PANEL_LINE := Color("#334155")
const TILE_A := Color("#1e293b")
const TILE_B := Color("#243244")
const TILE_HOVER := Color("#2f4058")
const GRASS_A := Color("#214336")
const GRASS_B := Color("#28503d")
const WATER := Color("#173b59")
const ROAD := Color("#5b4a36")
const ACCENT := Color("#38bdf8")
const ACCENT_WARM := Color("#fbbf24")
const PLAYER_COL := Color("#3b82f6")
const ENEMY_COL := Color("#ef4444")
const TEXT_COL := Color("#e5e7eb")
const MUTED_COL := Color("#94a3b8")
const HP_OK := Color("#22c55e")
const HP_LOW := Color("#f97316")
const GOLD_COL := Color("#facc15")
const BARRACKS := "barracks"
const MARKET := "market"
const RECRUIT_COST := 60
const ARCHER_COST := 90
const POTION_COST := 40
const WHETSTONE_COST := 50
const KILL_REWARD := 50
const MAX_STAGE := 100
const REGIONS := ["Bukit Zamrud", "Hutan Kabut", "Rawa Sunyi", "Gurun Bara", "Pesisir Badai", "Dataran Beku", "Lembah Bayangan", "Benteng Langit", "Tanah Terlarang"]
const ENEMY_SPOTS := [Vector2i(7, 0), Vector2i(7, 2), Vector2i(6, 3), Vector2i(7, 5), Vector2i(6, 1), Vector2i(5, 4)]


class Building:
	var pos: Vector2i
	var type: String
	var owner: int

	func _init(p: Vector2i, t: String, o: int) -> void:
		pos = p
		type = t
		owner = o


class Unit:
	var pos: Vector2i
	var visual_pos := Vector2.ZERO
	var team: int
	var hp: int
	var max_hp: int
	var atk: int
	var moved := false
	var kind := "soldier"
	var move_range: int = MOVE_RANGE
	var atk_range: int = ATTACK_RANGE

	func _init(p: Vector2i, t: int, h: int, a: int, k := "soldier", mr := MOVE_RANGE, ar := ATTACK_RANGE) -> void:
		pos = p
		team = t
		hp = h
		max_hp = h
		atk = a
		kind = k
		move_range = mr
		atk_range = ar


var units := []
var selected: Unit = null
var reachable := {}
var attackable := {}
var hovered := Vector2i(-1, -1)
var turn := 0
var game_over := false
var message := ""
var time := 0.0
var animating := false
var floaters := []
var god_mode := false
var buildings := []
var player_gold := 0
var active_building: Building = null
var stage := 1
var victory := false
var campaign_won := false
var stage_title := ""

var end_turn_btn: Button
var restart_btn: Button
var next_btn: Button
var build_buttons := []
var close_menu_btn: Button
var font: Font
var unit_tex := {}


func _load_textures() -> void:
	unit_tex["soldier"] = load("res://assets/icons/soldier.svg")
	unit_tex["archer"] = load("res://assets/icons/archer.svg")
	unit_tex["brute"] = load("res://assets/icons/brute.svg")
	unit_tex["warlord"] = load("res://assets/icons/warlord.svg")
	unit_tex["dragon"] = load("res://assets/icons/dragon.svg")

var sb_board: StyleBoxFlat
var sb_tile_a: StyleBoxFlat
var sb_tile_b: StyleBoxFlat
var sb_grass_a: StyleBoxFlat
var sb_grass_b: StyleBoxFlat
var sb_water: StyleBoxFlat
var sb_road: StyleBoxFlat
var sb_hover: StyleBoxFlat
var sb_move: StyleBoxFlat
var sb_attack: StyleBoxFlat
var sb_hud: StyleBoxFlat
var sb_pill_player: StyleBoxFlat
var sb_pill_enemy: StyleBoxFlat
var sb_pill_over: StyleBoxFlat
var sb_result: StyleBoxFlat


func _ready() -> void:
	font = ThemeDB.fallback_font
	_load_textures()
	_build_styleboxes()
	_build_ui()
	_start_campaign()
	set_process(true)
	queue_redraw()


func _build_styleboxes() -> void:
	sb_board = _make_box(PANEL_BG, 22, 1, PANEL_LINE, 16, Color(0, 0, 0, 0.45))
	sb_tile_a = _make_box(TILE_A, 12)
	sb_tile_b = _make_box(TILE_B, 12)
	sb_grass_a = _make_box(GRASS_A, 12)
	sb_grass_b = _make_box(GRASS_B, 12)
	sb_water = _make_box(WATER, 12, 1, Color("#25658a"))
	sb_road = _make_box(ROAD, 12)
	sb_hover = _make_box(TILE_HOVER, 12, 2, ACCENT)
	sb_move = _make_box(Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.22), 12, 1, Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.55))
	sb_attack = _make_box(Color(ENEMY_COL.r, ENEMY_COL.g, ENEMY_COL.b, 0.20), 12, 2, Color(ENEMY_COL.r, ENEMY_COL.g, ENEMY_COL.b, 0.8))
	sb_hud = _make_box(Color(0.06, 0.09, 0.16, 0.9), 22, 1, PANEL_LINE, 18, Color(0, 0, 0, 0.5))
	sb_pill_player = _make_box(Color(PLAYER_COL.r, PLAYER_COL.g, PLAYER_COL.b, 0.22), 18, 1, PLAYER_COL)
	sb_pill_enemy = _make_box(Color(ENEMY_COL.r, ENEMY_COL.g, ENEMY_COL.b, 0.22), 18, 1, ENEMY_COL)
	sb_pill_over = _make_box(Color(ACCENT_WARM.r, ACCENT_WARM.g, ACCENT_WARM.b, 0.22), 18, 1, ACCENT_WARM)
	sb_result = _make_box(Color(0.035, 0.055, 0.10, 0.98), 26, 2, ACCENT_WARM, 28, Color(0, 0, 0, 0.72))


func _make_box(bg: Color, radius: int, border := 0, border_col := Color(0, 0, 0, 0), shadow := 0, shadow_col := Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.anti_aliasing = true
	if border > 0:
		sb.set_border_width_all(border)
		sb.border_color = border_col
	if shadow > 0:
		sb.shadow_size = shadow
		sb.shadow_color = shadow_col
		sb.shadow_offset = Vector2(0, 6)
	return sb


func _build_ui() -> void:
	var panel_x := 760.0
	end_turn_btn = _make_button("Akhiri Giliran  (E)", Vector2(panel_x + 30, 545), Vector2(420, 58))
	end_turn_btn.pressed.connect(_on_end_turn_pressed)
	restart_btn = _make_button("Coba Lagi  (R)", Vector2(panel_x + 30, 545), Vector2(420, 58))
	restart_btn.pressed.connect(_restart)
	restart_btn.visible = false
	next_btn = _make_button("Lanjut  (N)", Vector2(panel_x + 30, 615), Vector2(420, 58))
	next_btn.pressed.connect(_next_stage)
	next_btn.visible = false

	var bx := 203.0
	var ys := [300.0, 356.0, 412.0, 468.0]
	var defs := [
		["recruit_warrior", "Rekrut Prajurit  —  %dg" % RECRUIT_COST],
		["recruit_archer", "Rekrut Pemanah  —  %dg" % ARCHER_COST],
		["potion", "Beli Ramuan (pulih penuh)  —  %dg" % POTION_COST],
		["whetstone", "Beli Asah (+2 ATK)  —  %dg" % WHETSTONE_COST]
	]
	for i in defs.size():
		var btn := _make_button(defs[i][1], Vector2(bx, ys[i]), Vector2(400, 48))
		btn.add_theme_font_size_override("font_size", 18)
		btn.visible = false
		btn.pressed.connect(_on_build_action.bind(defs[i][0]))
		build_buttons.append(btn)
	close_menu_btn = _make_button("Tutup", Vector2(bx, 500), Vector2(400, 44))
	close_menu_btn.add_theme_font_size_override("font_size", 18)
	close_menu_btn.visible = false
	close_menu_btn.pressed.connect(_close_build_menu)


func _make_button(text: String, pos: Vector2, size: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_color_override("font_color", TEXT_COL)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(0.5, 0.55, 0.62, 0.6))
	b.add_theme_stylebox_override("normal", _make_box(Color("#1d2b3f"), 14, 1, PANEL_LINE))
	b.add_theme_stylebox_override("hover", _make_box(Color("#24405c"), 14, 1, ACCENT))
	b.add_theme_stylebox_override("pressed", _make_box(Color("#152238"), 14, 1, ACCENT))
	b.add_theme_stylebox_override("disabled", _make_box(Color(0.10, 0.13, 0.20, 0.5), 14, 1, Color(0.25, 0.3, 0.38, 0.5)))
	add_child(b)
	return b


func _start_campaign() -> void:
	stage = 1
	campaign_won = false
	player_gold = 200
	_setup_battle()


func _stage_enemies(s: int) -> Array:
	var list := []
	var tier := (s - 1) / 10
	var enemy_count := mini(4 + (s - 1) / 20, ENEMY_SPOTS.size())
	var is_boss := s % 10 == 0
	if is_boss:
		var final_boss := s == MAX_STAGE
		list.append({
			"kind": "dragon" if final_boss else "warlord",
			"hp": 60 + tier * 9,
			"atk": 7 + tier,
			"mr": 2,
			"ar": 2 if final_boss else 1
		})
	for i in enemy_count - list.size():
		list.append({"kind": "brute", "hp": 12 + ceili(float(s - 1) / 2.0), "atk": 3 + tier})
	return list


func _stage_title(s: int) -> String:
	if s == MAX_STAGE:
		return "Sarang Naga Abadi"
	if s % 10 == 0:
		return "Panglima Wilayah %d" % (s / 10)
	return REGIONS[((s - 1) / 10) % REGIONS.size()]


func _setup_battle() -> void:
	units.clear()
	var player_tier := (stage - 1) / 10
	units.append(Unit.new(Vector2i(1, 1), 0, 14 + player_tier * 4, 4 + player_tier, "soldier"))
	units.append(Unit.new(Vector2i(1, 4), 0, 14 + player_tier * 4, 4 + player_tier, "soldier"))
	units.append(Unit.new(Vector2i(2, 2), 0, 12 + player_tier * 4, 5 + player_tier, "soldier"))
	var enemies := _stage_enemies(stage)
	for i in enemies.size():
		var e: Dictionary = enemies[i]
		var pos: Vector2i = ENEMY_SPOTS[i % ENEMY_SPOTS.size()]
		units.append(Unit.new(pos, 1, e.hp, e.atk, e.kind, e.get("mr", MOVE_RANGE), e.get("ar", ATTACK_RANGE)))
	for u in units:
		u.visual_pos = _cell_center(u.pos)
	buildings.clear()
	buildings.append(Building.new(Vector2i(0, 0), MARKET, 0))
	buildings.append(Building.new(Vector2i(0, 5), BARRACKS, 0))
	buildings.append(Building.new(Vector2i(8, 0), BARRACKS, 1))
	buildings.append(Building.new(Vector2i(8, 5), MARKET, 1))
	selected = null
	reachable = {}
	attackable = {}
	floaters.clear()
	turn = 0
	game_over = false
	victory = false
	god_mode = false
	stage_title = _stage_title(stage)
	_close_build_menu()
	message = "Pertempuran %d: %s. Giliran pemain." % [stage, stage_title]
	_refresh_ui()
	queue_redraw()


func _refresh_ui() -> void:
	if end_turn_btn == null:
		return
	if game_over:
		end_turn_btn.visible = false
		next_btn.visible = victory and not campaign_won
		restart_btn.visible = not next_btn.visible
		restart_btn.text = "Main Lagi  (R)" if campaign_won else "Coba Lagi  (R)"
		var result_button_pos := Vector2(440, 500)
		next_btn.position = result_button_pos
		restart_btn.position = result_button_pos
	else:
		end_turn_btn.position = Vector2(790, 545)
		end_turn_btn.visible = true
		end_turn_btn.disabled = turn != 0 or animating
		next_btn.visible = false
		restart_btn.visible = false


func _process(delta: float) -> void:
	time += delta
	var active := selected != null or animating or not floaters.is_empty()
	for f in floaters:
		f.life -= delta
		f.pos.y -= 34.0 * delta
	floaters = floaters.filter(func(f): return f.life > 0.0)
	if active:
		queue_redraw()


func _draw() -> void:
	_draw_background()
	draw_style_box(sb_board, _board_rect())
	_draw_tiles()
	_draw_highlights()
	_draw_buildings()
	_draw_units()
	_draw_hud()
	_draw_build_menu()
	_draw_floaters()
	if game_over:
		_draw_result_overlay()


func _draw_background() -> void:
	var vs := get_viewport_rect().size
	var pts := PackedVector2Array([Vector2.ZERO, Vector2(vs.x, 0), vs, Vector2(0, vs.y)])
	var cols := PackedColorArray([BG_TOP, BG_TOP, BG_BOTTOM, BG_BOTTOM])
	draw_polygon(pts, cols)
	# Soft atmospheric glows keep the battlefield from feeling like a flat UI grid.
	draw_circle(Vector2(170, 90), 230, Color(0.05, 0.40, 0.36, 0.10))
	draw_circle(Vector2(1110, 650), 310, Color(0.12, 0.28, 0.55, 0.10))


func _draw_tiles() -> void:
	for y in GRID_H:
		for x in GRID_W:
			var cell := Vector2i(x, y)
			var terrain := _terrain_at(cell)
			var sb := sb_tile_a if (x + y) % 2 == 0 else sb_tile_b
			if terrain == "grass":
				sb = sb_grass_a if (x + y) % 2 == 0 else sb_grass_b
			elif terrain == "water":
				sb = sb_water
			elif terrain == "road":
				sb = sb_road
			if cell == hovered and not game_over and turn == 0:
				sb = sb_hover
			draw_style_box(sb, _cell_rect(cell))
			_draw_terrain_detail(cell, terrain)


func _terrain_at(cell: Vector2i) -> String:
	if cell in [Vector2i(3, 0), Vector2i(4, 0), Vector2i(4, 1), Vector2i(8, 3)]:
		return "water"
	if cell.y == 3 or cell in [Vector2i(2, 2), Vector2i(6, 4)]:
		return "road"
	return "grass"


func _draw_terrain_detail(cell: Vector2i, terrain: String) -> void:
	var rect := _cell_rect(cell)
	var center := rect.get_center()
	if terrain == "water":
		for i in 2:
			var y := center.y - 9.0 + i * 17.0
			draw_line(Vector2(center.x - 20, y), Vector2(center.x + 20, y), Color(0.25, 0.68, 0.84, 0.35), 2.0)
	elif terrain == "road":
		draw_line(Vector2(rect.position.x + 10, center.y), Vector2(rect.end.x - 10, center.y), Color(0.83, 0.68, 0.45, 0.20), 3.0)
	elif (cell.x * 7 + cell.y * 11) % 4 == 0:
		for offset in [-7.0, 0.0, 7.0]:
			draw_line(center + Vector2(offset, 18), center + Vector2(offset + 3, 10), Color(0.35, 0.68, 0.42, 0.32), 1.5)


func _draw_highlights() -> void:
	if selected == null:
		return
	for cell in reachable.keys():
		draw_style_box(sb_move, _cell_rect(cell))
	for cell in attackable.keys():
		draw_style_box(sb_attack, _cell_rect(cell))


func _draw_buildings() -> void:
	for b in buildings:
		var center := _cell_center(b.pos)
		var col := PLAYER_COL if b.owner == 0 else ENEMY_COL
		var base := center + Vector2(0, 4)
		draw_rect(Rect2(base + Vector2(-TILE * 0.28, -TILE * 0.10), Vector2(TILE * 0.56, TILE * 0.42)), col.darkened(0.25), true)
		draw_rect(Rect2(base + Vector2(-TILE * 0.28, -TILE * 0.10), Vector2(TILE * 0.56, TILE * 0.42)), col, false, 2.0)
		var roof := PackedVector2Array([
			base + Vector2(-TILE * 0.34, -TILE * 0.10),
			base + Vector2(0, -TILE * 0.44),
			base + Vector2(TILE * 0.34, -TILE * 0.10)
		])
		draw_colored_polygon(roof, col)
		if b.type == MARKET:
			_draw_text("$", base + Vector2(-6, 18), 18, Color("#0b1120"))
		else:
			_draw_text("A", base + Vector2(-7, 18), 18, Color("#0b1120"))
		if b == active_building:
			draw_rect(_cell_rect(b.pos).grow(1.0), ACCENT_WARM, false, 3.0)


func _draw_units() -> void:
	for u in units:
		var center: Vector2 = u.visual_pos
		var base := PLAYER_COL if u.team == 0 else ENEMY_COL
		var radius := TILE * 0.40
		draw_circle(center + Vector2(0, 7), radius * 0.95, Color(0, 0, 0, 0.30))
		draw_circle(center, radius, base.darkened(0.35))
		draw_circle(center, radius - 2.5, base)
		draw_circle(center - Vector2(0, radius * 0.35), radius * 0.5, Color(1, 1, 1, 0.10))
		if u == selected:
			var pulse := 0.5 + 0.5 * sin(time * 5.0)
			draw_arc(center, radius + 5.0 + pulse * 3.0, 0.0, TAU, 48, Color(ACCENT_WARM, 0.55 + 0.45 * pulse), 3.0, true)
		var tex = unit_tex.get(u.kind)
		if tex != null:
			var size := Vector2(TILE * 0.94, TILE * 0.94)
			draw_texture_rect(tex, Rect2(center - size * 0.5 + Vector2(0, -2), size), false)
		_draw_hp(u, center)


func _draw_hp(u: Unit, center: Vector2) -> void:
	var w := TILE * 0.66
	var h := 8.0
	var pos := center + Vector2(-w * 0.5, TILE * 0.30)
	_draw_capsule(Rect2(pos, Vector2(w, h)), Color(0, 0, 0, 0.55))
	var ratio := clampf(float(u.hp) / float(u.max_hp), 0.0, 1.0)
	var col := HP_OK if ratio > 0.4 else HP_LOW
	if ratio > 0.0:
		_draw_capsule(Rect2(pos, Vector2(w * ratio, h)), col)
	_draw_text("%d" % u.hp, center + Vector2(-7, 7), 18, Color.WHITE)
	_draw_text("ATK %d" % u.atk, center + Vector2(-20, TILE * 0.46), 12, MUTED_COL)


func _draw_capsule(rect: Rect2, color: Color) -> void:
	var r := rect.size.y * 0.5
	draw_rect(Rect2(rect.position + Vector2(r, 0), Vector2(maxf(rect.size.x - 2.0 * r, 0.0), rect.size.y)), color, true)
	draw_circle(rect.position + Vector2(r, r), r, color)
	draw_circle(rect.position + Vector2(rect.size.x - r, r), r, color)


func _draw_hud() -> void:
	var panel := Rect2(Vector2(760, 90), Vector2(480, 600))
	draw_style_box(sb_hud, panel)
	_draw_text("ANCIENT EMPIRE", Vector2(70, 90), 40, TEXT_COL)
	_draw_text("Pertempuran %d/%d  •  %s" % [stage, MAX_STAGE, stage_title], Vector2(72, 122), 16, ACCENT)
	_draw_text(message, Vector2(70, 668), 18, TEXT_COL)
	var hint := "Klik unit › petak untuk bergerak › musuh bersebelahan untuk serang."
	_draw_text(hint, Vector2(70, 692), 14, MUTED_COL)
	_draw_text("Bangunan: $ pasar (item)  •  A barak (rekrut)  •  klik bangunanmu saat giliranmu.",
		Vector2(70, 714), 13, Color(0.6, 0.64, 0.7))

	_draw_text("STATUS GILIRAN", Vector2(790, 130), 14, MUTED_COL)
	var pill := Rect2(Vector2(790, 140), Vector2(420, 52))
	var text := "GILIRAN PEMAIN"
	var sb := sb_pill_player
	var col := PLAYER_COL
	if game_over:
		text = "PERMAINAN SELESAI"
		sb = sb_pill_over
		col = ACCENT_WARM
	elif turn == 1:
		text = "GILIRAN MUSUH"
		sb = sb_pill_enemy
		col = ENEMY_COL
	draw_style_box(sb, pill)
	_draw_centered(text, pill, 22, col)

	_draw_text("PEMAIN", Vector2(790, 230), 14, MUTED_COL)
	_draw_text("Gold: %d" % player_gold, Vector2(1090, 230), 14, GOLD_COL)
	_draw_team_stat(0, Vector2(790, 240))
	_draw_text("MUSUH", Vector2(790, 330), 14, MUTED_COL)
	_draw_team_stat(1, Vector2(790, 340))

	_draw_text("TUJUAN MISI", Vector2(790, 445), 14, MUTED_COL)
	_draw_text("Kalahkan seluruh pasukan musuh", Vector2(790, 474), 19, TEXT_COL)
	_draw_text("Taklukkan 100 level; boss muncul setiap 10 level.", Vector2(790, 500), 13, MUTED_COL)
	if god_mode:
		_draw_text("GOD MODE AKTIF", Vector2(1080, 522), 14, ACCENT)

	if game_over:
		_draw_centered("Hasil pertempuran ditampilkan di arena", Rect2(Vector2(760, 578), Vector2(480, 30)), 16, ACCENT_WARM)


func _draw_result_overlay() -> void:
	var viewport_size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.01, 0.02, 0.05, 0.72), true)
	var card := Rect2(Vector2(320, 190), Vector2(560, 410))
	draw_style_box(sb_result, card)
	var color := ACCENT_WARM if victory else ENEMY_COL
	var badge := "KEMENANGAN" if victory else "PERTEMPURAN KALAH"
	var title := "Kerajaan Diselamatkan!" if campaign_won else ("Medan Tempur Dikuasai" if victory else "Pasukanmu Tumbang")
	var detail := "Naga telah dikalahkan. Kampanye selesai." if campaign_won else ("Pertempuran %d/%d selesai. Bersiap ke wilayah berikutnya." % [stage, MAX_STAGE] if victory else "Susun ulang strategi dan coba pertempuran ini lagi.")
	_draw_centered(badge, Rect2(card.position + Vector2(0, 38), Vector2(card.size.x, 30)), 16, color)
	_draw_centered(title, Rect2(card.position + Vector2(0, 88), Vector2(card.size.x, 54)), 34, TEXT_COL)
	_draw_centered(detail, Rect2(card.position + Vector2(30, 150), Vector2(card.size.x - 60, 36)), 17, MUTED_COL)
	_draw_centered("Sisa pasukan  %d    |    Gold  %d" % [_team_count(0), player_gold], Rect2(card.position + Vector2(40, 205), Vector2(card.size.x - 80, 36)), 18, TEXT_COL)
	if victory:
		for x in [70.0, 120.0, 440.0, 490.0]:
			draw_circle(card.position + Vector2(x, 72 + fmod(x, 37)), 4, Color(color, 0.8))


func _team_count(team: int) -> int:
	var count := 0
	for unit in units:
		if unit.team == team:
			count += 1
	return count


func _draw_team_stat(team: int, top_left: Vector2) -> void:
	var count := 0
	var hp_total := 0
	var hp_max := 0
	for u in units:
		if u.team == team:
			count += 1
			hp_total += u.hp
			hp_max += u.max_hp
	var col := PLAYER_COL if team == 0 else ENEMY_COL
	var card := Rect2(top_left, Vector2(420, 76))
	draw_style_box(_make_box(Color(0.09, 0.12, 0.20, 0.85), 14, 1, PANEL_LINE), card)
	draw_circle(top_left + Vector2(38, 38), 16, col)
	_draw_text("%d unit" % count, top_left + Vector2(70, 32), 20, TEXT_COL)
	var ratio := 0.0 if hp_max == 0 else float(hp_total) / float(hp_max)
	var bar := Rect2(top_left + Vector2(70, 46), Vector2(320, 12))
	_draw_capsule(bar, Color(0, 0, 0, 0.5))
	if ratio > 0.0:
		_draw_capsule(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)), col)


func _draw_floaters() -> void:
	for f in floaters:
		var a: float = clampf(f.life / 0.9, 0.0, 1.0)
		var c: Color = f.color
		c.a = a
		_draw_text(f.text, f.pos, 26, c)


func _draw_text(text: String, pos: Vector2, size: int, color: Color) -> void:
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _draw_centered(text: String, rect: Rect2, size: int, color: Color) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var pos := rect.position + Vector2((rect.size.x - w) * 0.5, rect.size.y * 0.5 + size * 0.35)
	_draw_text(text, pos, size, color)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_restart()
		elif event.keycode == KEY_N:
			_next_stage()
		elif event.keycode == KEY_E and not game_over:
			_on_end_turn_pressed()
		elif event.keycode == KEY_K:
			_cheat_kill_all()
		elif event.keycode == KEY_H:
			_cheat_heal()
		elif event.keycode == KEY_G:
			_cheat_toggle_god()
		elif event.keycode == KEY_M:
			_cheat_reset_moves()
		elif event.keycode == KEY_P:
			_cheat_power()
		return
	if event is InputEventMouseMotion:
		var cell := _cell_at(event.position)
		if cell != hovered:
			hovered = cell
			queue_redraw()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not animating:
			_on_click(_cell_at(event.position))


func _on_click(cell: Vector2i) -> void:
	if game_over or turn != 0:
		return
	if not _in_bounds(cell):
		return
	var b = _building_at(cell)
	if b != null:
		if b.owner == 0:
			_open_build_menu(b)
		else:
			message = "Itu bangunan milik musuh."
		queue_redraw()
		return
	var u = _unit_at(cell)
	if u != null and u.team == 0:
		if u.moved:
			message = "Unit ini sudah bergerak giliran ini."
		else:
			selected = u
			reachable = _compute_reachable(u)
			attackable = _compute_attackable(u)
			message = "Pilih petak tujuan atau musuh bersebelahan."
		queue_redraw()
		return
	if selected and reachable.has(cell) and _unit_at(cell) == null:
		await _move_unit(selected, cell)
		selected.moved = true
		selected = null
		reachable = {}
		attackable = {}
		message = "Unit bergerak. Pilih unit lain atau akhiri giliran."
		queue_redraw()
		return
	if selected and u != null and u.team == 1 and _manhattan(selected.pos, u.pos) <= selected.atk_range:
		_attack(selected, u)
		selected.moved = true
		selected = null
		reachable = {}
		attackable = {}
		queue_redraw()
		return
	selected = null
	reachable = {}
	attackable = {}
	message = "Pilih unit sendiri terlebih dahulu."
	queue_redraw()


func _move_unit(u: Unit, cell: Vector2i) -> void:
	animating = true
	var from: Vector2 = u.visual_pos
	var to := _cell_center(cell)
	u.pos = cell
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(func(p): u.visual_pos = p; queue_redraw(), from, to, 0.18)
	await tween.finished
	animating = false


func _attack(attacker: Unit, defender: Unit) -> void:
	if god_mode and defender.team == 0:
		_spawn_floater(defender.visual_pos + Vector2(0, -10), "IMMUNE", ACCENT)
		message = "Cheat aktif: unit pemain kebal!"
		return
	defender.hp -= attacker.atk
	var who := "Pemain" if attacker.team == 0 else "Musuh"
	message = "%s menyerang! Musuh kehilangan %d HP." % [who, attacker.atk]
	_spawn_floater(defender.visual_pos + Vector2(0, -10), "-%d" % attacker.atk, ENEMY_COL if defender.team == 1 else PLAYER_COL)
	if defender.hp <= 0:
		var dead_pos: Vector2 = defender.visual_pos
		var was_enemy := defender.team == 1
		units.erase(defender)
		_spawn_floater(dead_pos + Vector2(0, -34), "KO", ACCENT_WARM)
		message = "%s menghabisi satu unit!" % who
		if was_enemy and attacker.team == 0:
			player_gold += KILL_REWARD
			_spawn_floater(dead_pos + Vector2(0, -60), "+%dg" % KILL_REWARD, GOLD_COL)
	_check_game_over()


func _spawn_floater(pos: Vector2, text: String, color: Color) -> void:
	floaters.append({"pos": pos, "text": text, "color": color, "life": 0.9})
	queue_redraw()


func _cheat_kill_all() -> void:
	var dead := []
	for u in units:
		if u.team == 1:
			_spawn_floater(u.visual_pos + Vector2(0, -34), "KO", ACCENT_WARM)
			dead.append(u)
	for u in dead:
		units.erase(u)
	message = "Cheat: semua musuh dilenyapkan!"
	selected = null
	reachable = {}
	attackable = {}
	_check_game_over()
	queue_redraw()


func _cheat_heal() -> void:
	for u in units:
		if u.team == 0:
			u.hp = u.max_hp
			_spawn_floater(u.visual_pos + Vector2(0, -10), "FULL", HP_OK)
	message = "Cheat: semua unit pemain dipulihkan."
	queue_redraw()


func _cheat_toggle_god() -> void:
	god_mode = not god_mode
	message = "Cheat: mode kebal %s." % ("AKTIF" if god_mode else "NONAKTIF")
	queue_redraw()


func _cheat_reset_moves() -> void:
	for u in units:
		if u.team == 0:
			u.moved = false
	selected = null
	reachable = {}
	attackable = {}
	message = "Cheat: semua unit pemain bisa bergerak lagi."
	queue_redraw()


func _cheat_power() -> void:
	for u in units:
		if u.team == 0:
			u.atk += 5
			_spawn_floater(u.visual_pos + Vector2(0, -10), "+5 ATK", ACCENT_WARM)
	message = "Cheat: serangan unit pemain +5."
	queue_redraw()


func _compute_reachable(unit: Unit) -> Dictionary:
	var result := {unit.pos: 0}
	var frontier := [unit.pos]
	while not frontier.is_empty():
		var cur: Vector2i = frontier.pop_front()
		var dist: int = result[cur]
		if dist >= unit.move_range:
			continue
		for dir in DIRS:
			var nxt: Vector2i = cur + dir
			if not _in_bounds(nxt) or result.has(nxt):
				continue
			if _unit_at(nxt) != null or _building_at(nxt) != null:
				continue
			result[nxt] = dist + 1
			frontier.append(nxt)
	return result


func _compute_attackable(unit: Unit) -> Dictionary:
	var result := {}
	for u in units:
		if u.team != unit.team and _manhattan(unit.pos, u.pos) <= unit.atk_range:
			result[u.pos] = true
	return result


func _on_end_turn_pressed() -> void:
	if game_over or turn != 0 or animating:
		return
	selected = null
	reachable = {}
	attackable = {}
	turn = 1
	message = "Giliran musuh bergerak..."
	_refresh_ui()
	queue_redraw()
	_enemy_turn()


func _enemy_turn() -> void:
	await get_tree().create_timer(0.3).timeout
	for e in units.duplicate():
		if game_over:
			break
		if e.team != 1 or not units.has(e):
			continue
		var target = _nearest_player(e.pos)
		if target == null:
			break
		if _manhattan(e.pos, target.pos) > e.atk_range:
			var step := _step_toward(e, target)
			if step != e.pos:
				await _move_unit(e, step)
		if not units.has(target):
			continue
		if _manhattan(e.pos, target.pos) <= e.atk_range:
			_attack(e, target)
			queue_redraw()
			await get_tree().create_timer(0.25).timeout
	if game_over:
		_refresh_ui()
		return
	for u in units:
		if u.team == 0:
			u.moved = false
	turn = 0
	message = "Giliran pemain. Pilih unit, lalu klik petak tujuan."
	_refresh_ui()
	queue_redraw()


func _nearest_player(from: Vector2i) -> Unit:
	var best: Unit = null
	var best_dist := 1 << 30
	for u in units:
		if u.team != 0:
			continue
		var d: int = _manhattan(from, u.pos)
		if d < best_dist:
			best_dist = d
			best = u
	return best


func _step_toward(unit: Unit, target: Unit) -> Vector2i:
	var prev := {unit.pos: unit.pos}
	var frontier := [unit.pos]
	while not frontier.is_empty():
		var cur: Vector2i = frontier.pop_front()
		if cur == target.pos:
			break
		for dir in DIRS:
			var nxt: Vector2i = cur + dir
			if not _in_bounds(nxt) or prev.has(nxt):
				continue
			if _unit_at(nxt) != null and nxt != target.pos:
				continue
			if _building_at(nxt) != null:
				continue
			prev[nxt] = cur
			frontier.append(nxt)
	if not prev.has(target.pos):
		return unit.pos
	var node: Vector2i = target.pos
	while prev[node] != unit.pos and prev[node] != node:
		node = prev[node]
	return node


func _check_game_over() -> void:
	var players := 0
	var enemies := 0
	for u in units:
		if u.team == 0:
			players += 1
		else:
			enemies += 1
	if enemies == 0:
		game_over = true
		victory = true
		if stage >= MAX_STAGE:
			campaign_won = true
			message = "NAGA TEWAS! Kampanye selesai — kamu menang!"
		else:
			message = "Kemenangan! Pertempuran %d selesai. Tekan N untuk lanjut." % stage
	elif players == 0:
		game_over = true
		victory = false
		message = "Kalah! Coba lagi pertempuran ini."
	if game_over:
		_refresh_ui()


func _next_stage() -> void:
	if not game_over or not victory or campaign_won:
		return
	stage += 1
	player_gold += 100 + (stage - 1) * 25
	_setup_battle()


func _restart() -> void:
	if campaign_won:
		_start_campaign()
	else:
		_setup_battle()


func _unit_at(cell: Vector2i) -> Unit:
	for u in units:
		if u.pos == cell:
			return u
	return null


func _building_at(cell: Vector2i) -> Building:
	for b in buildings:
		if b.pos == cell:
			return b
	return null


func _spawn_unit_near(building: Building, team: int, hp: int, atk: int, kind := "soldier") -> bool:
	var candidates := []
	for dir in DIRS:
		var c: Vector2i = building.pos + dir
		if _in_bounds(c) and _unit_at(c) == null and _building_at(c) == null:
			candidates.append(c)
	if candidates.is_empty():
		for y in GRID_H:
			for x in GRID_W:
				var c := Vector2i(x, y)
				if _unit_at(c) == null and _building_at(c) == null:
					candidates.append(c)
		if candidates.is_empty():
			return false
	var spawn: Vector2i = candidates[0]
	var best := 1 << 30
	for c in candidates:
		var d: int = absi(c.x - building.pos.x) + absi(c.y - building.pos.y)
		if d < best:
			best = d
			spawn = c
	var u := Unit.new(spawn, team, hp, atk, kind)
	u.visual_pos = _cell_center(spawn)
	units.append(u)
	_spawn_floater(u.visual_pos + Vector2(0, -20), "BARU", GOLD_COL)
	return true


func _open_build_menu(building: Building) -> void:
	active_building = building
	var is_barracks := building.type == BARRACKS
	build_buttons[0].visible = is_barracks
	build_buttons[1].visible = is_barracks
	build_buttons[2].visible = not is_barracks
	build_buttons[3].visible = not is_barracks
	build_buttons[0].position = Vector2(203, 320)
	build_buttons[1].position = Vector2(203, 392)
	build_buttons[2].position = Vector2(203, 320)
	build_buttons[3].position = Vector2(203, 392)
	build_buttons[0].disabled = player_gold < RECRUIT_COST
	build_buttons[1].disabled = player_gold < ARCHER_COST
	build_buttons[2].disabled = player_gold < POTION_COST
	build_buttons[3].disabled = player_gold < WHETSTONE_COST
	close_menu_btn.visible = true
	message = "%s dibuka. Gold: %d." % ["Barak" if is_barracks else "Pasar", player_gold]
	queue_redraw()


func _close_build_menu() -> void:
	active_building = null
	for btn in build_buttons:
		btn.visible = false
	if close_menu_btn:
		close_menu_btn.visible = false


func _on_build_action(action: String) -> void:
	match action:
		"recruit_warrior":
			_try_recruit(14, 4, RECRUIT_COST, "Prajurit", "soldier")
		"recruit_archer":
			_try_recruit(10, 6, ARCHER_COST, "Pemanah", "archer")
		"potion":
			_try_item("potion")
		"whetstone":
			_try_item("whetstone")


func _try_recruit(hp: int, atk: int, cost: int, label: String, kind: String) -> void:
	if active_building == null or player_gold < cost:
		message = "Gold tidak cukup."
		return
	if _spawn_unit_near(active_building, 0, hp, atk, kind):
		player_gold -= cost
		message = "%s direkrut (-%dg). Sisa gold: %d." % [label, cost, player_gold]
	else:
		message = "Tidak ada petak kosong untuk unit baru."
	_open_build_menu(active_building)


func _try_item(kind: String) -> void:
	if selected == null or selected.team != 0:
		message = "Pilih dulu unit pemain yang ingin dipakai item."
		return
	var cost := POTION_COST if kind == "potion" else WHETSTONE_COST
	if player_gold < cost:
		message = "Gold tidak cukup."
		return
	if kind == "potion":
		selected.hp = selected.max_hp
		_spawn_floater(selected.visual_pos + Vector2(0, -10), "FULL", HP_OK)
		message = "Ramuan dipakai: unit pulih penuh (-%dg)." % cost
	else:
		selected.atk += 2
		_spawn_floater(selected.visual_pos + Vector2(0, -10), "+2 ATK", ACCENT_WARM)
		message = "Asah dipakai: +2 ATK (-%dg)." % cost
	player_gold -= cost
	_open_build_menu(active_building)
	queue_redraw()


func _draw_build_menu() -> void:
	if active_building == null:
		return
	var panel := Rect2(Vector2(173, 220), Vector2(460, 380))
	draw_style_box(_make_box(Color(0.05, 0.07, 0.13, 0.97), 20, 2, ACCENT, 20, Color(0, 0, 0, 0.55)), panel)
	var title := "BARAK" if active_building.type == BARRACKS else "PASAR"
	_draw_centered(title, Rect2(Vector2(173, 240), Vector2(460, 40)), 26, ACCENT)
	_draw_centered("Gold: %d" % player_gold, Rect2(Vector2(173, 276), Vector2(460, 24)), 16, GOLD_COL)
	if active_building.type == MARKET:
		_draw_centered("Pilih unit pemain dulu untuk memakai item.", Rect2(Vector2(173, 448), Vector2(460, 24)), 13, MUTED_COL)


func _board_rect() -> Rect2:
	return Rect2(ORIGIN - Vector2(18, 18), Vector2(GRID_W * TILE, GRID_H * TILE) + Vector2(36, 36))


func _cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(ORIGIN + Vector2(cell) * TILE + Vector2(3, 3), Vector2(TILE - 6, TILE - 6))


func _cell_center(cell: Vector2i) -> Vector2:
	return ORIGIN + Vector2(cell) * TILE + Vector2(TILE, TILE) * 0.5


func _cell_at(pos: Vector2) -> Vector2i:
	var local := pos - ORIGIN
	return Vector2i(int(floor(local.x / TILE)), int(floor(local.y / TILE)))


func _in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < GRID_W and cell.y < GRID_H


func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)
