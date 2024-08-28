extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# Подбираем монетку если игрок пересекает область монетки
func _on_body_entered(body):
	if body in get_tree().get_nodes_in_group('player'):
		body.coin_collected(1)
		self.queue_free()
	pass # Replace with function body.
