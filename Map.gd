extends TileMap



const MAP_WIDTH = 128 # Размеры карты в тайлах
const MAP_HEIGHT = 128
const INITIAL_SAND_THRESHOLD = 0.45  # Порог для определения, будет ли клетка той по которой можно перемещаться
const ITERATIONS = 1  # Количество итераций клеточного автомата
const SAND_APPEAR_THRESHOLD = 5  # Количество соседей для изменения
const SAND_STAY_THRESHOLD = 4  # Количество соседей для того чтобы клетка осталась в исходном состоянии

var map = Array()
#@onready var noise = $TextureRect.texture.noise

# Параметры для добавления объектов на карту
var max_coin_count = 26
var coin_count = 26
var max_enemy_count = 7
var enemy_count = 7


func _input(event):
	if event.is_action_pressed("ui_cancel") and !get_tree().paused: # Открыть меня паузы и остановить игру
		get_tree().paused = true
		$"../Player/Camera/PauseMenu".show()

func _ready():
	load_params() # Загрузка переменных из файла конфигурации
	get_tree().paused = true # Останавливаем игру до нажатия на кнопку старт
	#add_objects_on_level() # Добавляем монетки и врагов
	pass

# Загрузка переменных из файла конфигурации
func load_params():
	var file = FileAccess.open('config.json', FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			var data = json.get_data()
			max_coin_count = data['game_data']['spawned_coins_amount']
			max_enemy_count = data['enemy_params']['enemy_count']

# Сохранение состояния карты и монет в файл
func save_map():
	var file = FileAccess.open('map.json', FileAccess.WRITE)
	if file:
		var data = {"map": map}
		var coin_positions = []
		for coin in get_tree().get_nodes_in_group('coins'):
			var pos = [coin.global_position.x, coin.global_position.y]
			coin_positions.append(pos)
		data['coin_positions'] = coin_positions
		var enemy_positions = []
		for enemy in get_tree().get_nodes_in_group('enemies'):
			var pos = [enemy.global_position.x, enemy.global_position.y]
			enemy_positions.append(pos)
		data['enemy_positions'] = enemy_positions
		data['player_position'] = [get_tree().get_nodes_in_group('player')[0].global_position.x, get_tree().get_nodes_in_group('player')[0].global_position.y]
		data['coins_score'] = {'coins_collected' : $"../Player".coins_collected, 'target_coins_count' : $"../Player".target_coins_count}
		var json = JSON.new()
		var json_string = json.stringify(data)
		file.store_string(json_string)
		file.close()
		print("Variables saved successfully.")
	else:
		print("Failed to open file for writing.")

# Загрузка состояния карты и монет из файла
func load_map():
	var file = FileAccess.open('map.json', FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			var data = json.get_data()
			if "map" in data:
				map = data["map"]
				print("Map loaded successfully")
				generate_tilemap()
			if 'coin_positions' in data:
				for elem in data["coin_positions"]:
					var coin = load("res://Coin.tscn").instantiate()
					get_parent().add_child.call_deferred(coin)
					coin.global_position = Vector2(elem[0], elem[1])
				print("Coins loaded successfully")
			if 'enemy_positions' in data:
				for elem in data["enemy_positions"]:
					var enemy = load("res://enemy.tscn").instantiate()
					get_parent().add_child.call_deferred(enemy)
					enemy.global_position = Vector2(elem[0], elem[1])
				print("enemies loaded successfully")
			if 'player_position' in data:
				get_tree().get_nodes_in_group('player')[0].global_position = Vector2(data['player_position'][0], data['player_position'][1])
				print('player pos loaded successfully')
			if 'coins_score' in data:
				$"../Player".coins_collected = data['coins_score']['coins_collected']
				$"../Player".target_coins_count = data['coins_score']['target_coins_count']
				$"../Player".coin_collected(0)
				print('coin data loaded successfully')
			else:
				print("Variable not found in the saved data.")
		else:
			print("Failed to parse JSON.")
		file.close()
	else:
		print("Failed to open file for reading.")
	$"../Player/Camera/Control".hide()
	get_tree().paused = false
	#$"../Player/Camera/PauseMenu".show()
func gen_map(): # Все методы отвечающие за генерацию карты собраны в один для вызова с кнопки

	initialize_map() # Инициализация карты
	clear_spawn_area() # Убираем стены в центре карты, чтобы исключить появление игрока в стене
	for i in range(ITERATIONS):
		run_cellular_automaton() # Применение клеточного автомата
	create_walls() # Добавляем стены на границы карты
	generate_tilemap() # Рендер TileMap на основе карты (вызов этой функции вызывает пролаг, его следует оптимизировать, но на это уйдет значительное количество времени, о том как правильно это сделать и почему могу подробно рассказать на интервью)


func add_objects_on_level():
	add_coins() # Добавляем монетки
	add_enemies() # Добавляем врагов

func add_enemies():
	enemy_count = max_enemy_count
	while enemy_count > 0:
		var random_pos_x = randf() * MAP_WIDTH
		var random_pos_y = randf() * MAP_HEIGHT
		if map[random_pos_x][random_pos_y] == 1:
			var enemy = load("res://enemy.tscn").instantiate()
			get_parent().add_child.call_deferred(enemy)
			enemy.position = Vector2(random_pos_x * 16, random_pos_y * 16)
			enemy_count -= 1



# Добавляем монетки
func add_coins():
	coin_count = max_coin_count
	while coin_count > 0:
		var random_pos_x = randf() * MAP_WIDTH
		var random_pos_y = randf() * MAP_HEIGHT
		if map[random_pos_x][random_pos_y] == 1:
			var coin = load("res://Coin.tscn").instantiate()
			get_parent().add_child.call_deferred(coin)
			coin.position = Vector2(random_pos_x * 16, random_pos_y * 16)
			coin_count -= 1

# Убираем стены в центре карты, чтобы исключить появление игрока в стене
func clear_spawn_area():
	for x in range(-10,10):
		for y in range(-10,10):
			map[int(MAP_WIDTH/2.0) + x][int(MAP_HEIGHT/2.0) + y] = 1


# Инициализация карты случайным распределением
func initialize_map():
	map.resize(MAP_WIDTH)
	for x in range(MAP_WIDTH):
		map[x] = Array()
		for y in range(MAP_HEIGHT):
			var random_value = randf() 
			if random_value > INITIAL_SAND_THRESHOLD:
				map[x].append(1)  # 1 означает клетку по которой можно перемещаться
			else:
				map[x].append(0)  # 0 означает стену

# Применение клеточного автомата
func run_cellular_automaton():
	var new_map = Array()
	new_map.resize(MAP_WIDTH)
	
	for x in range(MAP_WIDTH):
		new_map[x] = Array()
		for y in range(MAP_HEIGHT):
			var sand_neighbors = count_sand_neighbors(x, y)
			
			if map[x][y] == 1:  # Если по данной клетке можно перемещаться
				if sand_neighbors >= SAND_STAY_THRESHOLD:
					new_map[x].append(1)  # Оставляем
				else:
					new_map[x].append(0)  # Меняем на стену
			else:  # Если текущая клетка вода
				if sand_neighbors >= SAND_APPEAR_THRESHOLD:
					new_map[x].append(1)  # Меняем на клетку по которой можно перемещаться
				else:
					new_map[x].append(0)  # Оставляем
	
	map = new_map

# Подсчет соседей для клеточного автомата
func count_sand_neighbors(x, y):
	var count = 0
	
	for i in range(-1, 2):
		for j in range(-1, 2):
			if i == 0 and j == 0:
				continue
			
			var nx = x + i
			var ny = y + j
			
			if nx >= 0 and nx < MAP_WIDTH and ny >= 0 and ny < MAP_HEIGHT:
				if map[nx][ny] == 1:
					count += 1  # Считаем только клетки по которым можно перемещаться
	
	return count

# Устанавливаем тайл в TileMap на основе сгенерированной карты
func generate_tilemap():
	var tilemap = self
	
	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			if map[x][y] == 1:
				set_cell(0, Vector2i(x,y),5, Vector2i(0,0))
			else:
				set_cell(0, Vector2i(x,y),3, Vector2i(1,4))
				
# Создаем рамки по краям карты
func create_walls():
	for x in range(MAP_WIDTH):
		map[x][0] = 0
	for y in range(MAP_HEIGHT):
		map[0][y] = 0
	for x in range(MAP_WIDTH):
		map[x][MAP_WIDTH-1] = 0
	for y in range(MAP_HEIGHT):
		map[MAP_HEIGHT-1][y] = 0
		
func restart():
	for node in get_tree().get_nodes_in_group('enemies'): # Удаляем врагов
		node.queue_free()
	for node in get_tree().get_nodes_in_group('coins'): # Удаляем монетки
		node.queue_free()
	add_objects_on_level() # Генерируем монетки и врагов
	get_tree().paused = false # Снимаем игру с паузы
	$"../Player/Camera/Control".hide()
	$"../Player/Camera/PauseMenu".hide() # Прячем меню
	$"../Player/Camera/WinGame".hide()
	$"../Player".global_position = Vector2(1024,1024) # Отправляем игрока в точку спавна
	$"../Player".coins_collected = 0 # Сбрасываем счёт
	$"../Player".coin_collected(0) # Вызываем функцию собирания монетки для обновления отображения собранных монет


func close_game(): # Выход из игры
	get_tree().quit()
	pass # Replace with function body.

# Снимаем игру с паузы и прячем меню.
func _on_resume_button_pressed():
	get_tree().paused = false
	$"../Player/Camera/PauseMenu".hide()
	pass # Replace with function body.
