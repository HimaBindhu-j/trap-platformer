extends Area2D

signal triggered(player)

var activated := false
var trigger_size := Vector2(100, 100)


func setup(size: Vector2):
	trigger_size = size


func _ready():

	monitoring = true

	collision_layer = 0
	collision_mask = 1

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()

	shape.size = trigger_size
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