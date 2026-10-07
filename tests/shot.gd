extends Node

func _ready() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main.stage = 100
	main._setup_battle()
	main._enter_game()
	for i in 5:
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://tests/shot.png")
	print("SHOT SAVED")
	get_tree().quit(0)
