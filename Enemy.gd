extends CharacterBody2D


var SPEED = 100.0


var target = null
@onready var nav_agent := $NavigationAgent2D as NavigationAgent2D

func _ready():
	load_params() # Загружаем параметры из файла конфигурации

func _physics_process(delta):
	if (self.global_position - nav_agent.get_final_position()).length() <= 10: # Если враг пришел к точке раньше окончания таймера вызываем срабатывание таймера вручную
		calculate_path_for_nav_agent() 
	var dir = to_local(nav_agent.get_next_path_position()).normalized()
	velocity = dir * SPEED
	move_and_slide()
	
	if velocity.x < 0: # Отображение спрайта врага в зависимости от направления движения
		$AnimatedSprite2D.scale.x = 1
	else:
		$AnimatedSprite2D.scale.x = -1

# Загружаем параметры из файла конфигурации
func load_params():
	var file = FileAccess.open('config.json', FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			var data = json.get_data()
			SPEED = data['enemy_params']['enemy_speed']


# Строим путь
func calculate_path_for_nav_agent():
	if target: # Если игрок в радиусе видимости
		nav_agent.target_position = Vector2(target.global_position)
	else: # Если игрока нет в радиусе видимости
		nav_agent.target_position = gen_path_point()
		$Timer.wait_time = 20
	$Timer.start()

# Задаем в качестве целевой точки для перемещения случаную точку на карте не являющюся стеной
func gen_path_point() -> Vector2:
	for i in range(10):
		var random_pos_x = randf() * $"../TileMap".MAP_WIDTH
		var random_pos_y = randf() * $"../TileMap".MAP_HEIGHT
		if $"../TileMap".map[random_pos_x][random_pos_y] == 1:
			return(Vector2(random_pos_x * 16, random_pos_y * 16))
	return(self.global_position)

# Игрок попал в радиус видимости
func _on_area_2d_body_entered(body):
	if body in get_tree().get_nodes_in_group('player'):
		self.target = body
		$Timer.wait_time = 0.3
		calculate_path_for_nav_agent()


# Игрок вышел из радиуса видимости
func _on_area_2d_body_exited(body):
	if body in get_tree().get_nodes_in_group('player'):
		self.target = null
		calculate_path_for_nav_agent()


# Игрок вошел в зону поражения врага
func _on_area_2d_2_body_entered(body):
	if body in get_tree().get_nodes_in_group('player'):
		get_tree().paused = true
		$"../Player/Camera/PauseMenu".show()
	pass # Replace with function body.
