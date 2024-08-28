extends CharacterBody2D


var SPEED = 300.0
var JUMP_VELOCITY = -400.0

var gravity = 700
var double_jump = true

var coins_collected = 0
var target_coins_count = 1

func _ready():
	load_params()
	$Camera/Label2.text = str(coins_collected) + '/' + str(target_coins_count) # Записываем счёт


# Загружаем параметры игрока из файла
func load_params():
	var file = FileAccess.open('config.json', FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			var data = json.get_data()
			SPEED = data['player_params']['speed']
			JUMP_VELOCITY = data['player_params']['jump_velocity']
			gravity = data['player_params']['gravity']
			target_coins_count = data['game_data']['target_coins_count']
			
func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor(): # Добавляем гравитацию когда не стоим на полу
		if velocity.y < 400:
			velocity.y += gravity * delta
		$Sprite2D.animation = 'jump'
	

	if Input.is_action_just_pressed("ui_accept"): # Прыгем по нажатию назначенной кнопки
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		elif double_jump: # Двойной прыжок расходуется при применении в воздухе
			velocity.y = JUMP_VELOCITY
			double_jump = false


	var direction = Input.get_axis("ui_left", "ui_right") # Считываем ввод на передвижение
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	move_and_slide()
	if velocity.x > 0:
		$Sprite2D.scale.x = -0.395
	elif velocity.x < 0:
		$Sprite2D.scale.x = 0.395
	if is_on_floor(): # обновляем двойной прыжок когда встаем на пол
		double_jump = true
		if abs(velocity.x) > 50:
			$Sprite2D.animation = 'move'
		else:
			$Sprite2D.animation = 'idle'

# Функция вызываемая при собирании монетки и обновляющая надпись о количестве монет
func coin_collected(count):
	coins_collected += count
	$Camera/Label2.text = str(coins_collected) + '/' + str(target_coins_count)
	if coins_collected >= target_coins_count:
		$Camera/WinGame.show()
		get_tree().paused = true
