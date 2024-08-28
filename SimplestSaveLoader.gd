extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass



func save_scene():
	var current_scene = get_tree().current_scene
	
	if current_scene:
		# Создаем PackedScene и упаковываем текущую сцену
		var packed_scene = PackedScene.new()
		packed_scene.pack(current_scene)
		
		# Сохраняем PackedScene в файл
		var save_result = ResourceSaver.save(packed_scene, 'save.tscn')
		if save_result == OK:
			print("Scene saved successfully.")
		else:
			print("Failed to save scene.")
	else:
		print("No current scene to save.")

func load_scene():
	# Проверяем существует ли файл
	if not FileAccess.file_exists('save.tscn'):
		print("Save file does not exist.")
		return
	
	# Загружаем PackedScene из файла
	var packed_scene = ResourceLoader.load('save.tscn')
	if packed_scene is PackedScene:
		# Инстанцируем сцену и добавляем её в дерево
		var new_scene = packed_scene.instantiate()
		if new_scene:
			# Очистка текущей сцены
			if get_tree().current_scene:
				get_tree().current_scene.queue_free()
			
			# Добавление новой загруженной сцены
			get_tree().root.add_child(new_scene)
			get_tree().current_scene = new_scene
			print("Scene loaded successfully.")
		else:
			print("Failed to instantiate the scene.")
	else:
		print("Failed to load scene.")
