extends Node

func _ready() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame

	_assert(main.units.size() == 7, "jumlah unit awal")
	_assert(main.turn == 0, "mulai di giliran pemain")

	main._on_click(Vector2i(1, 1))
	await get_tree().process_frame
	_assert(main.selected != null, "unit terpilih")
	_assert(main.reachable.size() > 1, "petak gerak dihitung")

	main._on_click(Vector2i(1, 2))
	await get_tree().create_timer(0.6).timeout
	_assert(main.selected == null, "seleksi dilepas setelah gerak")
	var moved = false
	for u in main.units:
		if u.pos == Vector2i(1, 2):
			moved = true
	_assert(moved, "unit berpindah ke petak tujuan")

	main._on_end_turn_pressed()
	_assert(main.turn == 1, "giliran musuh dimulai")
	await get_tree().create_timer(8.0).timeout
	_assert(main.turn == 0, "giliran kembali ke pemain")

	main._restart()
	_assert(main.units.size() == 7 and main.turn == 0, "restart mengembalikan state")

	print("SMOKE OK")
	get_tree().quit(0)


func _assert(condition: bool, label: String) -> void:
	if not condition:
		push_error("SMOKE FAIL: " + label)
		get_tree().quit(1)
