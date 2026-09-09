extends Node2D

var platforms = [
	Rect2(20, 470, 180, 30),   # Start
	Rect2(250, 420, 140, 30),  # Platform 2
	Rect2(440, 360, 120, 30),  # Platform 3
	Rect2(610, 410, 110, 30),  # Platform 4
	Rect2(760, 350, 120, 30),  # Platform 5
	Rect2(805, 470, 135, 30)   # Exit platform
]

var spikes = [
	Vector2(205, 470),
	Vector2(420, 420),
	Vector2(610, 350),
	Vector2(780, 430)
]

# Moving trap
var moving_trap: Area2D
var moving_trap_start_y := 360.0
var moving_trap_range := 60.0
var moving_trap_speed := 2.0
var moving_trap_direction := 1.0


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

	# Create exit collision area
	var exit_area := Area2D.new()
	var exit_shape := CollisionShape2D.new()
	var exit_rect := RectangleShape2D.new()

	exit_rect.size = Vector2(45, 50)
	exit_shape.shape = exit_rect

	exit_area.position = Vector2(877.5, 445)
	exit_area.add_child(exit_shape)
	add_child(exit_area)

	exit_area.body_entered.connect(_on_exit_body_entered)

	# Create moving trap
	moving_trap = Area2D.new()

	var trap_shape := CollisionShape2D.new()
	var trap_rect := RectangleShape2D.new()

	trap_rect.size = Vector2(28, 28)
	trap_shape.shape = trap_rect

	moving_trap.position = Vector2(700, moving_trap_start_y)
	moving_trap.monitoring = true

	moving_trap.add_child(trap_shape)
	add_child(moving_trap)

	moving_trap.body_entered.connect(_on_moving_trap_body_entered)

	queue_redraw()


func _process(delta):
	if moving_trap == null:
		return

	# Move trap up and down
	moving_trap.position.y += (
		moving_trap_direction
		* moving_trap_speed
		* 60.0
		* delta
	)

	# Move down until maximum position
	if moving_trap.position.y >= moving_trap_start_y + moving_trap_range:
		moving_trap.position.y = moving_trap_start_y + moving_trap_range
		moving_trap_direction = -1.0

	# Move up until starting position
	elif moving_trap.position.y <= moving_trap_start_y:
		moving_trap.position.y = moving_trap_start_y
		moving_trap_direction = 1.0

	queue_redraw()


func _on_spike_body_entered(body):
	if body.name == "Player":
		get_parent().kill_player()


func _on_moving_trap_body_entered(body):
	if body.name == "Player":
		get_parent().kill_player()


func _on_exit_body_entered(body):
	if body.name == "Player":
		get_parent().win_level()


func _draw():
	# Draw platforms
	for p in platforms:
		draw_rect(p, Color("#52606d"))
		draw_line(
			p.position,
			p.position + Vector2(p.size.x, 0),
			Color("#8c9aa8"),
			3
		)

	# Draw spikes
	for s in spikes:
		var pts = PackedVector2Array([
			s + Vector2(0, 0),
			s + Vector2(12, -25),
			s + Vector2(24, 0)
		])

		draw_colored_polygon(pts, Color("#ff4d6d"))

	# Draw moving trap
	if moving_trap != null:
		draw_rect(
			Rect2(
				moving_trap.position - Vector2(14, 14),
				Vector2(28, 28)
			),
			Color("#ff9f43")
		)

	# Draw exit
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
