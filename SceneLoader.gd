extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	#save_game()
	var load_button = $Node2D/Player/Camera/Control/Button4
	load_button.connect("pressed", Callable(self, "load"))
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass



func save_game():
	var scene_to_save = $Node2D
	var packed_scene = PackedScene.new()
	packed_scene.pack(scene_to_save)
	var file = FileAccess.open('Game.tscn', FileAccess.WRITE)
	if file:
		file.store_var(packed_scene.instantiate())
		file.close()
		print("Scene saved successfully.")
	else:
		print("Failed to save scene.")
func load_game():
	get_children()[0].queue_free()
	var file = FileAccess.open('Game.tscn', FileAccess.READ)
	if file:
		# Загружаем сохранённую PackedScene
		var saved_scene = file.get_var()
		file.close()
		
		# Замена текущей сцены на загруженную
		get_tree().current_scene.queue_free()
		get_tree().root.add_child(saved_scene)
		get_tree().current_scene = saved_scene
		print("Scene loaded successfully.")
	else:
		print("Failed to load scene.")
