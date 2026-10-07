extends Node

func _ready() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame

	_assert(main.in_main_menu, "game dibuka dari menu utama")
	_assert(is_equal_approx(main.start_btn.position.x + main.start_btn.size.x * 0.5, main.get_viewport_rect().size.x * 0.5), "tombol mulai berada di tengah")
	main._enter_game()
	_assert(not main.in_main_menu, "tombol mulai membuka permainan")
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
	main._show_main_menu()
	_assert(main.in_main_menu, "permainan bisa kembali ke menu utama")
	main._enter_game()

	_assert(main.buildings.size() == 4, "bangunan tersedia")
	var before_count = main.units.size()
	var gold_before = main.player_gold
	main._open_build_menu(main.buildings[1])
	main._on_build_action("recruit_warrior")
	_assert(main.units.size() == before_count + 1, "rekrut menambah unit pemain")
	_assert(main.player_gold == gold_before - 60, "rekrut memotong gold")
	main._close_build_menu()
	main.selected = main.units[0]
	main._open_build_menu(main.buildings[0])
	main._on_build_action("whetstone")
	_assert(main.units[0].atk == 6, "asah menambah ATK +2")
	main._close_build_menu()

	main._cheat_heal()
	main._cheat_power()
	var gold_cheat_before = main.player_gold
	main._cheat_gold()
	main._cheat_toggle_god()
	_assert(main.god_mode, "cheat god mode aktif")
	_assert(main.player_gold == gold_cheat_before + 500, "cheat gold menambah 500")
	main._cheat_kill_all()
	_assert(main.game_over, "cheat hapus semua musuh memicu kemenangan")
	_assert(main.victory, "kemenangan tercatat")

	main._next_stage()
	_assert(main.stage == 2, "lanjut ke pertempuran 2")
	_assert(main.units.size() == 7, "jumlah unit level 2 sesuai kapasitas")
	_assert(main._stage_enemies(2)[0].hp > main._stage_enemies(1)[0].hp, "musuh makin kuat setiap level")

	main.stage = 100
	main._setup_battle()
	var has_dragon = false
	for u in main.units:
		if u.kind == "dragon":
			has_dragon = true
	_assert(has_dragon, "level 100 menampilkan naga final")
	_assert(main._stage_enemies(10)[0].kind == "warlord", "boss muncul setiap 10 level")
	_assert(main._stage_enemies(100).size() <= main.ENEMY_SPOTS.size(), "musuh tidak bertumpuk")
	main._attack(main.units[0], main.units[3])
	_assert(main.attack_fx.size() == 1, "serangan memunculkan efek petir")
	main._cheat_kill_all()
	_assert(main.campaign_won, "menang level 100 menamatkan kampanye")

	print("SMOKE OK")
	get_tree().quit(0)


func _assert(condition: bool, label: String) -> void:
	if not condition:
		push_error("SMOKE FAIL: " + label)
		get_tree().quit(1)
