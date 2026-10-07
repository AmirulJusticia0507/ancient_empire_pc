extends Node

func _ready() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main._open_build_menu(main.buildings[1])
	for i in 5:
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://tests/shot.png")
	print("SHOT SAVED")
	get_tree().quit(0)
