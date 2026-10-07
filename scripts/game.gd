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
const ACCENT := Color("#38bdf8")
const ACCENT_WARM := Color("#fbbf24")
const PLAYER_COL := Color("#3b82f6")
const ENEMY_COL := Color("#ef4444")
const TEXT_COL := Color("#e5e7eb")
const MUTED_COL := Color("#94a3b8")
const HP_OK := Color("#22c55e")
const HP_LOW := Color("#f97316")


class Unit:
	var pos: Vector2i
	var visual_pos := Vector2.ZERO
	var team: int
	var hp: int
	var max_hp: int
	var atk: int
	var moved := false

	func _init(p: Vector2i, t: int, h: int, a: int) -> void:
		pos = p
		team = t
		hp = h
		max_hp = h
		atk = a


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

var end_turn_btn: Button
var restart_btn: Button
var font: Font

var sb_board: StyleBoxFlat
var sb_tile_a: StyleBoxFlat
var sb_tile_b: StyleBoxFlat
var sb_hover: StyleBoxFlat
var sb_move: StyleBoxFlat
var sb_attack: StyleBoxFlat
var sb_hud: StyleBoxFlat
var sb_pill_player: StyleBoxFlat
var sb_pill_enemy: StyleBoxFlat
var sb_pill_over: StyleBoxFlat


func _ready() -> void:
	font = ThemeDB.fallback_font
	_build_styleboxes()
	_build_ui()
	_setup_units()
	set_process(true)
	queue_redraw()


func _build_styleboxes() -> void:
	sb_board = _make_box(PANEL_BG, 22, 1, PANEL_LINE, 16, Color(0, 0, 0, 0.45))
	sb_tile_a = _make_box(TILE_A, 12)
	sb_tile_b = _make_box(TILE_B, 12)
	sb_hover = _make_box(TILE_HOVER, 12, 2, ACCENT)
	sb_move = _make_box(Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.22), 12, 1, Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.55))
	sb_attack = _make_box(Color(ENEMY_COL.r, ENEMY_COL.g, ENEMY_COL.b, 0.20), 12, 2, Color(ENEMY_COL.r, ENEMY_COL.g, ENEMY_COL.b, 0.8))
	sb_hud = _make_box(Color(0.06, 0.09, 0.16, 0.9), 22, 1, PANEL_LINE, 18, Color(0, 0, 0, 0.5))
	sb_pill_player = _make_box(Color(PLAYER_COL.r, PLAYER_COL.g, PLAYER_COL.b, 0.22), 18, 1, PLAYER_COL)
	sb_pill_enemy = _make_box(Color(ENEMY_COL.r, ENEMY_COL.g, ENEMY_COL.b, 0.22), 18, 1, ENEMY_COL)
	sb_pill_over = _make_box(Color(ACCENT_WARM.r, ACCENT_WARM.g, ACCENT_WARM.b, 0.22), 18, 1, ACCENT_WARM)


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
	restart_btn = _make_button("Mulai Ulang  (R)", Vector2(panel_x + 30, 615), Vector2(420, 58))
	restart_btn.pressed.connect(_restart)


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


func _setup_units() -> void:
	units.clear()
	units.append(Unit.new(Vector2i(1, 1), 0, 14, 4))
	units.append(Unit.new(Vector2i(1, 4), 0, 14, 4))
	units.append(Unit.new(Vector2i(2, 2), 0, 12, 5))
	units.append(Unit.new(Vector2i(6, 0), 1, 12, 3))
	units.append(Unit.new(Vector2i(7, 2), 1, 12, 3))
	units.append(Unit.new(Vector2i(6, 3), 1, 10, 4))
	units.append(Unit.new(Vector2i(7, 5), 1, 12, 3))
	for u in units:
		u.visual_pos = _cell_center(u.pos)
	selected = null
	reachable = {}
	attackable = {}
	floaters.clear()
	turn = 0
	game_over = false
	message = "Giliran pemain. Pilih unit, lalu klik petak tujuan."
	_refresh_ui()
	queue_redraw()


func _refresh_ui() -> void:
	if end_turn_btn:
		end_turn_btn.disabled = turn != 0 or game_over
	if restart_btn:
		restart_btn.disabled = not game_over


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
	_draw_units()
	_draw_hud()
	_draw_floaters()


func _draw_background() -> void:
	var vs := get_viewport_rect().size
	var pts := PackedVector2Array([Vector2.ZERO, Vector2(vs.x, 0), vs, Vector2(0, vs.y)])
	var cols := PackedColorArray([BG_TOP, BG_TOP, BG_BOTTOM, BG_BOTTOM])
	draw_polygon(pts, cols)


func _draw_tiles() -> void:
	for y in GRID_H:
		for x in GRID_W:
			var cell := Vector2i(x, y)
			var sb := sb_tile_a if (x + y) % 2 == 0 else sb_tile_b
			if cell == hovered and not game_over and turn == 0:
				sb = sb_hover
			draw_style_box(sb, _cell_rect(cell))


func _draw_highlights() -> void:
	if selected == null:
		return
	for cell in reachable.keys():
		draw_style_box(sb_move, _cell_rect(cell))
	for cell in attackable.keys():
		draw_style_box(sb_attack, _cell_rect(cell))


func _draw_units() -> void:
	for u in units:
		var center: Vector2 = u.visual_pos
		var radius := TILE * 0.31
		var base := PLAYER_COL if u.team == 0 else ENEMY_COL
		var lifted := center + Vector2(0, -3)
		draw_circle(center + Vector2(0, 6), radius, Color(0, 0, 0, 0.35))
		draw_circle(lifted, radius, base.darkened(0.25))
		draw_circle(lifted, radius - 3.0, base.darkened(0.05))
		draw_circle(lifted - Vector2(0, radius * 0.35), radius * 0.55, Color(1, 1, 1, 0.18))
		if u == selected:
			var pulse := 0.5 + 0.5 * sin(time * 5.0)
			draw_arc(lifted, radius + 5.0 + pulse * 3.0, 0.0, TAU, 48, Color(ACCENT_WARM, 0.55 + 0.45 * pulse), 3.0, true)
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
	_draw_text("PC  •  turn-based tactics prototype", Vector2(72, 122), 16, MUTED_COL)
	_draw_text(message, Vector2(70, 668), 18, TEXT_COL)
	var hint := "Klik unit sendiri  ›  klik petak untuk bergerak  ›  klik musuh bersebelahan untuk menyerang."
	_draw_text(hint, Vector2(70, 694), 14, MUTED_COL)

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
	_draw_team_stat(0, Vector2(790, 240))
	_draw_text("MUSUH", Vector2(790, 330), 14, MUTED_COL)
	_draw_team_stat(1, Vector2(790, 340))

	if game_over:
		_draw_centered("Tekan R atau tombol Mulai Ulang", Rect2(Vector2(760, 470), Vector2(480, 40)), 18, ACCENT_WARM)


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
		elif event.keycode == KEY_E and not game_over:
			_on_end_turn_pressed()
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
	if selected and u != null and u.team == 1 and _manhattan(selected.pos, u.pos) <= ATTACK_RANGE:
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
	defender.hp -= attacker.atk
	var who := "Pemain" if attacker.team == 0 else "Musuh"
	message = "%s menyerang! Musuh kehilangan %d HP." % [who, attacker.atk]
	_spawn_floater(defender.visual_pos + Vector2(0, -10), "-%d" % attacker.atk, ENEMY_COL if defender.team == 1 else PLAYER_COL)
	if defender.hp <= 0:
		var dead_pos: Vector2 = defender.visual_pos
		units.erase(defender)
		_spawn_floater(dead_pos + Vector2(0, -34), "KO", ACCENT_WARM)
		message = "%s menghabisi satu unit!" % who
	_check_game_over()


func _spawn_floater(pos: Vector2, text: String, color: Color) -> void:
	floaters.append({"pos": pos, "text": text, "color": color, "life": 0.9})
	queue_redraw()


func _compute_reachable(unit: Unit) -> Dictionary:
	var result := {unit.pos: 0}
	var frontier := [unit.pos]
	while not frontier.is_empty():
		var cur: Vector2i = frontier.pop_front()
		var dist: int = result[cur]
		if dist >= MOVE_RANGE:
			continue
		for dir in DIRS:
			var nxt: Vector2i = cur + dir
			if not _in_bounds(nxt) or result.has(nxt):
				continue
			if _unit_at(nxt) != null:
				continue
			result[nxt] = dist + 1
			frontier.append(nxt)
	return result


func _compute_attackable(unit: Unit) -> Dictionary:
	var result := {}
	for dir in DIRS:
		var nxt: Vector2i = unit.pos + dir
		if not _in_bounds(nxt):
			continue
		var other = _unit_at(nxt)
		if other != null and other.team != unit.team:
			result[nxt] = true
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
		if _manhattan(e.pos, target.pos) > ATTACK_RANGE:
			var step := _step_toward(e, target)
			if step != e.pos:
				await _move_unit(e, step)
		if not units.has(target):
			continue
		if _manhattan(e.pos, target.pos) <= ATTACK_RANGE:
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
		message = "Kemenangan! Semua musuh dikalahkan."
	elif players == 0:
		game_over = true
		message = "Kalah! Semua unitmu dihabisi."
	if game_over:
		_refresh_ui()


func _restart() -> void:
	_setup_units()


func _unit_at(cell: Vector2i) -> Unit:
	for u in units:
		if u.pos == cell:
			return u
	return null


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
