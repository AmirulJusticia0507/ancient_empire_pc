extends Node

func _ready() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	main.save_path = "user://campaign-smoke.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	add_child(main)
	await get_tree().process_frame

	_assert(main.in_main_menu, "game dibuka dari menu utama")
	_assert(is_equal_approx(main.start_btn.position.x + main.start_btn.size.x * 0.5, main.get_viewport_rect().size.x * 0.5), "tombol mulai berada di tengah")
	main._enter_game()
	_assert(not main.in_main_menu, "tombol mulai membuka permainan")
	main.stage = 7
	main.player_gold = 345
	main.units[0].hp = 3
	main.units[0].atk = 11
	main.units[0].pos = Vector2i(4, 4)
	main.buildings[2].owner = 0
	main._save_progress()
	main.stage = 1
	main.player_gold = 0
	main.units.clear()
	main.buildings.clear()
	_assert(main._load_progress() and main.stage == 7 and main.player_gold == 345, "progres level dan gold tersimpan")
	_assert(main.units[0].hp == 3 and main.units[0].atk == 11 and main.units[0].pos == Vector2i(4, 4), "kondisi pasukan tersimpan")
	_assert(main.buildings[2].owner == 0, "kepemilikan bangunan tersimpan")
	main._start_new_campaign()
	_assert(main.stage == 1 and main.player_gold == 200, "kampanye baru menghapus progres lama")
	_assert(not main.in_main_menu, "kampanye baru langsung membuka permainan")
	main.stage = 1
	main.player_gold = 200
	main._setup_battle()
	var initial_players = main.units.filter(func(u): return u.team == 0).size()
	var initial_enemies = main.units.filter(func(u): return u.team == 1).size()
	_assert(initial_players >= 3 and initial_players <= 5, "pemain mulai dengan 3-5 unit")
	_assert(initial_enemies >= 5 and initial_enemies <= 6, "musuh mulai dengan 5-6 unit")
	var initial_positions := {}
	for u in main.units:
		initial_positions[u.pos] = true
	_assert(initial_positions.size() == main.units.size(), "posisi awal unit tidak bertumpuk")
	_assert(main.turn == 0, "mulai di giliran pemain")

	var first_player = main.units[0]
	main._on_click(first_player.pos)
	await get_tree().process_frame
	_assert(main.selected != null, "unit terpilih")
	_assert(main.reachable.size() > 1, "petak gerak dihitung")

	var move_target = first_player.pos
	for cell in main.reachable.keys():
		if cell != first_player.pos:
			move_target = cell
			break
	main._on_click(move_target)
	await get_tree().create_timer(0.6).timeout
	_assert(main.selected == null, "seleksi dilepas setelah gerak")
	_assert(first_player.pos == move_target, "unit berpindah ke petak tujuan")

	main._on_end_turn_pressed()
	_assert(main.turn == 1, "giliran musuh dimulai")
	await get_tree().create_timer(8.0).timeout
	_assert(main.turn == 0, "giliran kembali ke pemain")

	main._restart()
	_assert(main.units.size() >= 8 and main.units.size() <= 11 and main.turn == 0, "restart mengacak state awal")
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
	var captured_building = main.buildings[2]
	main.units[0].pos = Vector2i(main.GRID_W - 1, 1)
	main.units[0].visual_pos = main._cell_center(main.units[0].pos)
	main.selected = main.units[0]
	var capture_gold_before = main.player_gold
	main._on_click(captured_building.pos)
	_assert(captured_building.owner == 0, "markas musuh bisa dikudeta")
	_assert(main.player_gold == capture_gold_before + 100, "kudeta memberi bonus gold")

	main._cheat_heal()
	main._cheat_power()
	var gold_cheat_before = main.player_gold
	main._cheat_gold()
	_assert(main.player_gold == gold_cheat_before + 500, "cheat gold menambah 500")
	var count_before_dragon = main.units.size()
	main._open_build_menu(main.buildings[0])
	main._on_build_action("recruit_dragon")
	_assert(main.units.size() == count_before_dragon + 1, "pasar dapat merekrut naga")
	_assert(main.units[-1].kind == "dragon" and main.units[-1].atk_range == 2, "naga pemain punya jangkauan 2")
	main._close_build_menu()
	main._cheat_toggle_god()
	_assert(main.god_mode, "cheat god mode aktif")
	main._cheat_kill_all()
	_assert(main.game_over, "cheat hapus semua musuh memicu kemenangan")
	_assert(main.victory, "kemenangan tercatat")

	main._next_stage()
	_assert(main.stage == 2, "lanjut ke pertempuran 2")
	_assert(main.units.size() >= 8 and main.units.size() <= 11, "jumlah unit level 2 diacak")
	_assert(main._stage_enemies(2)[0].hp > main._stage_enemies(1)[0].hp, "musuh makin kuat setiap level")

	main.stage = 100
	main._setup_battle()
	var has_dragon = false
	for u in main.units:
		if u.kind == "dragon":
			has_dragon = true
	_assert(has_dragon, "level 100 menampilkan naga final")
	_assert(main._stage_enemies(10)[0].kind == "warlord", "boss muncul setiap 10 level")
	_assert(main._stage_enemies(100).size() <= 8, "jumlah musuh sesuai kapasitas")
	var final_enemy = main.units.filter(func(u): return u.team == 1)[0]
	main._attack(main.units[0], final_enemy)
	_assert(main.attack_fx.size() == 1, "serangan memunculkan efek petir")
	main._cheat_kill_all()
	_assert(main.campaign_won, "menang level 100 menamatkan kampanye")

	print("SMOKE OK")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	get_tree().quit(0)


func _assert(condition: bool, label: String) -> void:
	if not condition:
		push_error("SMOKE FAIL: " + label)
		get_tree().quit(1)
