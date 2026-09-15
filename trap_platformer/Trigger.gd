extends Area2D

signal triggered(player)

var activated := false


func _ready():
	body_entered.connect(_on_body_entered)


func _on_body_entered(body):
	if body.name != "Player":
		return

	if activated:
		returnextends Area2D

signal triggered(player)

var activated := false


func _ready():

	monitoring = true
	collision_layer = 0
	collision_mask = 1

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()

	shape.size = Vector2(80, 120)

	collision.shape = shape

	add_child(collision)

	body_entered.connect(_on_body_entered)


func _on_body_entered(body):

	print("Trigger detected: ", body.name)

	if body.name != "Player":
		return

	if activated:
		return

	activated = true

	triggered.emit(body)

	activated = true
	triggered.emit(body)