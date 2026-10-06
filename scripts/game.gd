extends Node2D

const GRID_W := 9
const GRID_H := 6
const TILE := 72
const ORIGIN := Vector2(90, 150)
const MOVE_RANGE := 3
const ATTACK_RANGE := 1
const DIRS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

const COLOR_TILE := Color(0.20, 0.18, 0.15)
const COLOR_TILE_ALT := Color(0.23, 0.21, 0.17)
const COLOR_LINE := Color(0.36, 0.33, 0.28)
const COLOR_MOVE := Color(0.30, 0.60, 1.0, 0.28)
const COLOR_SELECT := Color(1.0, 0.85, 0.35)
const COLOR_PLAYER := Color(0.25, 0.50, 0.95)
const COLOR_ENEMY := Color(0.90, 0.28, 0.25)
const COLOR_TEXT := Color(0.95, 0.93, 0.88)


class Unit:
	var pos: Vector2i
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
var turn := 0
var game_over := false
var message := ""
var end_turn_btn: Button
var restart_btn: Button
var font: Font


func _ready() -> void:
	font = ThemeDB.fallback_font
	_build_ui()
	_setup_units()
	queue_redraw()


func _build_ui() -> void:
	var panel_x := ORIGIN.x + GRID_W * TILE + 40

	end_turn_btn = Button.new()
	end_turn_btn.text = "Akhiri Giliran (E)"
	end_turn_btn.position = Vector2(panel_x, ORIGIN.y)
	end_turn_btn.size = Vector2(220, 52)
	end_turn_btn.pressed.connect(_on_end_turn_pressed)
	add_child(end_turn_btn)

	restart_btn = Button.new()
	restart_btn.text = "Mulai Ulang (R)"
	restart_btn.position = Vector2(panel_x, ORIGIN.y + 64)
	restart_btn.size = Vector2(220, 52)
	restart_btn.pressed.connect(_restart)
	add_child(restart_btn)


func _setup_units() -> void:
	units.clear()
	units.append(Unit.new(Vector2i(1, 1), 0, 14, 4))
	units.append(Unit.new(Vector2i(1, 4), 0, 14, 4))
	units.append(Unit.new(Vector2i(2, 2), 0, 12, 5))
	units.append(Unit.new(Vector2i(6, 0), 1, 12, 3))
	units.append(Unit.new(Vector2i(7, 2), 1, 12, 3))
	units.append(Unit.new(Vector2i(6, 3), 1, 10, 4))
	units.append(Unit.new(Vector2i(7, 5), 1, 12, 3))
	selected = null
	reachable = {}
	turn = 0
	game_over = false
	message = "Giliran pemain: pilih unit, klik petak tujuan."
	_refresh_ui()
	queue_redraw()


func _refresh_ui() -> void:
	if end_turn_btn:
		end_turn_btn.disabled = turn != 0 or game_over
	if restart_btn:
		restart_btn.disabled = not game_over


func _draw() -> void:
	_draw_board()
	if selected:
		for cell in reachable.keys():
			draw_rect(_cell_rect(cell), COLOR_MOVE, true)
	_draw_units()
	if selected:
		draw_rect(_cell_rect(selected.pos).grow(2.0), COLOR_SELECT, false, 3.0)
	_draw_hud()


func _draw_board() -> void:
	for y in GRID_H:
		for x in GRID_W:
			var cell := Vector2i(x, y)
			var base := COLOR_TILE if (x + y) % 2 == 0 else COLOR_TILE_ALT
			draw_rect(_cell_rect(cell), base, true)
			draw_rect(_cell_rect(cell), COLOR_LINE, false, 1.0)


func _draw_units() -> void:
	for u in units:
		var center := _cell_center(u.pos)
		var col := COLOR_PLAYER if u.team == 0 else COLOR_ENEMY
		draw_circle(center, TILE * 0.34, col)
		draw_arc(center, TILE * 0.34, 0.0, TAU, 32, col.lightened(0.35), 2.0)
		var bar_w := TILE * 0.68
		var bar_pos := center + Vector2(-bar_w * 0.5, TILE * 0.30)
		draw_rect(Rect2(bar_pos, Vector2(bar_w, 7)), Color(0, 0, 0, 0.65), true)
		var ratio := clampf(float(u.hp) / float(u.max_hp), 0.0, 1.0)
		draw_rect(Rect2(bar_pos, Vector2(bar_w * ratio, 7)), Color(0.25, 0.85, 0.25), true)
		_draw_text(str(u.hp), center + Vector2(-7, 6), 18, Color.WHITE)
		_draw_text("ATK %d" % u.atk, center + Vector2(-22, TILE * 0.46), 12, COLOR_TEXT)


func _draw_hud() -> void:
	_draw_text("Ancient Empire PC", ORIGIN + Vector2(0, -96), 30, COLOR_SELECT)
	_draw_text(message, ORIGIN + Vector2(0, -58), 18, COLOR_TEXT)
	var hint := "Klik unit sendiri, klik petak untuk bergerak, klik musuh bersebelahan untuk menyerang."
	_draw_text(hint, ORIGIN + Vector2(0, -28), 14, Color(0.75, 0.73, 0.68))
	if game_over:
		_draw_text("Tekan R atau tombol Mulai Ulang.", ORIGIN + Vector2(0, GRID_H * TILE + 30), 18, COLOR_SELECT)


func _draw_text(text: String, pos: Vector2, size: int, color: Color) -> void:
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_restart()
		elif event.keycode == KEY_E and not game_over:
			_on_end_turn_pressed()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
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
			message = "Pilih petak tujuan atau musuh bersebelahan."
		queue_redraw()
		return
	if selected and reachable.has(cell) and _unit_at(cell) == null:
		selected.pos = cell
		selected.moved = true
		selected = null
		reachable = {}
		message = "Unit bergerak. Pilih unit lain atau akhiri giliran."
		queue_redraw()
		return
	if selected and u != null and u.team == 1 and _manhattan(selected.pos, u.pos) <= ATTACK_RANGE:
		_attack(selected, u)
		selected.moved = true
		selected = null
		reachable = {}
		queue_redraw()
		return
	selected = null
	reachable = {}
	message = "Pilih unit sendiri terlebih dahulu."
	queue_redraw()


func _attack(attacker: Unit, defender: Unit) -> void:
	defender.hp -= attacker.atk
	var who := "Pemain" if attacker.team == 0 else "Musuh"
	message = "%s menyerang! Musuh kehilangan %d HP." % [who, attacker.atk]
	if defender.hp <= 0:
		units.erase(defender)
		message = "%s menghabisi satu unit musuh!" % who
	_check_game_over()


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


func _on_end_turn_pressed() -> void:
	if game_over or turn != 0:
		return
	selected = null
	reachable = {}
	turn = 1
	message = "Giliran musuh..."
	_refresh_ui()
	queue_redraw()
	_enemy_turn()


func _enemy_turn() -> void:
	await get_tree().create_timer(0.25).timeout
	for e in units.duplicate():
		if game_over:
			break
		if e.team != 1 or not units.has(e):
			continue
		await get_tree().create_timer(0.2).timeout
		var target = _nearest_player(e.pos)
		if target == null:
			break
		if _manhattan(e.pos, target.pos) <= ATTACK_RANGE:
			_attack(e, target)
		else:
			var step := _step_toward(e, target)
			if step != e.pos:
				e.pos = step
			if _manhattan(e.pos, target.pos) <= ATTACK_RANGE:
				_attack(e, target)
		queue_redraw()
	if game_over:
		_refresh_ui()
		return
	for u in units:
		if u.team == 0:
			u.moved = false
	turn = 0
	message = "Giliran pemain: pilih unit, klik petak tujuan."
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


func _cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(ORIGIN + Vector2(cell) * TILE, Vector2(TILE, TILE))


func _cell_center(cell: Vector2i) -> Vector2:
	return ORIGIN + Vector2(cell) * TILE + Vector2(TILE, TILE) * 0.5


func _cell_at(pos: Vector2) -> Vector2i:
	var local := pos - ORIGIN
	return Vector2i(int(floor(local.x / TILE)), int(floor(local.y / TILE)))


func _in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < GRID_W and cell.y < GRID_H


func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)
