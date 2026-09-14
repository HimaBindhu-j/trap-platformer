extends Node2D

var platforms = [
	Rect2(20, 470, 160, 30),
	Rect2(220, 410, 120, 30),
	Rect2(380, 340, 110, 30),
	Rect2(530, 420, 120, 30),
	Rect2(680, 350, 110, 30),
	Rect2(820, 470, 120, 30)
]

var spikes = [
	Vector2(185, 470),
	Vector2(340, 410),
	Vector2(495, 340),
	Vector2(655, 420),
	Vector2(795, 470)
]

var exit_area: Area2D
var exit_enabled := false


func _ready():
	# Create platforms
	for p in platforms:
		var body := StaticBody2D.new()
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()

		rect.size = p.size
		shape.shape = rect
		body.position = p.position + p.size / 2.0

		body.add_child(shape)
		add_child(body)

	# Create spikes
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

	# Create exit
	exit_area = Area2D.new()

	var exit_shape := CollisionShape2D.new()
	var exit_rect := RectangleShape2D.new()

	exit_rect.size = Vector2(45, 50)
	exit_shape.shape = exit_rect

	exit_area.position = Vector2(877.5, 445)

	# Exit is OFF during level loading
	exit_area.monitoring = false

	exit_area.add_child(exit_shape)
	add_child(exit_area)

	exit_area.body_entered.connect(_on_exit_body_entered)

	queue_redraw()

	# Enable exit only after transition is finished
	call_deferred("_enable_exit")


func _enable_exit():
	# Wait a little longer so player is safely inside Level 2
	await get_tree().create_timer(0.3).timeout

	exit_enabled = true

	if is_instance_valid(exit_area):
		exit_area.monitoring = true


func _on_spike_body_entered(body):
	if body.name == "Player":
		get_parent().kill_player()


func _on_exit_body_entered(body):
	if body.name == "Player" and exit_enabled:
		get_parent().win_level()


func _draw():
	# Platforms
	for p in platforms:
		draw_rect(
			p,
			Color("#52606d")
		)

		draw_line(
			p.position,
			p.position + Vector2(p.size.x, 0),
			Color("#8c9aa8"),
			3
		)

	# Spikes
	for s in spikes:
		var pts = PackedVector2Array([
			s + Vector2(0, 0),
			s + Vector2(12, -25),
			s + Vector2(24, 0)
		])

		draw_colored_polygon(
			pts,
			Color("#ff4d6d")
		)

	# Exit
	draw_rect(
		Rect2(850, 415, 55, 55),
		Color("#7ee787")
	)

	draw_rect(
		Rect2(858, 423, 39, 47),
		Color("#18202b")
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(856, 405),
		"EXIT",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		20,
		Color("#7ee787")
	)

	draw_circle(
		Vector2(877, 435),
		8,
		Color("#7ee787")
	)