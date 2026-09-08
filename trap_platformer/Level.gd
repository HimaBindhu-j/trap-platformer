extends Node2D

var platforms = [
	Rect2(20, 470, 180, 30),
	Rect2(250, 420, 150, 30),
	Rect2(460, 350, 150, 30),
	Rect2(660, 430, 120, 30),
	Rect2(805, 470, 135, 30)
]

var spikes = [
	Vector2(205, 470),
	Vector2(420, 420),
	Vector2(610, 350),
	Vector2(780, 430)
]

func _ready():
	for p in platforms:
		var body := StaticBody2D.new()
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()

		rect.size = p.size
		shape.shape = rect
		body.position = p.position + p.size / 2.0

		body.add_child(shape)
		add_child(body)

	for s in spikes:
		var spike := Area2D.new()
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()

		rect.size = Vector2(24, 25)
		shape.shape = rect
		spike.position = s + Vector2(12, -12)
		spike.monitoring = true

		spike.add_child(shape)
		add_child(spike)

		spike.body_entered.connect(_on_spike_body_entered)

	# Exit collision area
	var exit_area := Area2D.new()
	var exit_shape := CollisionShape2D.new()
	var exit_rect := RectangleShape2D.new()

	exit_rect.size = Vector2(45, 50)
	exit_shape.shape = exit_rect

	exit_area.position = Vector2(877.5, 445)
	exit_area.add_child(exit_shape)
	add_child(exit_area)

	exit_area.body_entered.connect(_on_exit_body_entered)

	queue_redraw()


func _on_spike_body_entered(body):
	if body.name == "Player":
		get_parent().kill_player()


func _on_exit_body_entered(body):
	if body.name == "Player":
		get_parent().win_level()


func _draw():
	for p in platforms:
		draw_rect(p, Color("#52606d"))
		draw_line(
			p.position,
			p.position + Vector2(p.size.x, 0),
			Color("#8c9aa8"),
			3
		)

	for s in spikes:
		var pts = PackedVector2Array([
			s + Vector2(0, 0),
			s + Vector2(12, -25),
			s + Vector2(24, 0)
		])

		draw_colored_polygon(pts, Color("#ff4d6d"))

	# Exit
	draw_rect(
		Rect2(855, 420, 45, 50),
		Color("#7ee787")
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(850, 405),
		"EXIT",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		20,
		Color("#7ee787")
	)
