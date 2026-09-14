extends Node2D

# LEVEL 3 PLATFORMS
var platforms = [
	Rect2(20, 470, 150, 30),
	Rect2(210, 410, 120, 30),
	Rect2(370, 350, 110, 30),
	Rect2(520, 430, 120, 30),
	Rect2(680, 360, 110, 30),
	Rect2(820, 470, 120, 30)
]

# LEVEL 3 SPIKES
var spikes = [
	Vector2(175, 470),
	Vector2(330, 410),
	Vector2(480, 350),
	Vector2(650, 430),
	Vector2(795, 470)
]

# FALLING TRAP
var falling_trap: Area2D
var falling_trap_start_y := 180.0
var falling_trap_speed := 5.0
var falling_trap_x := 570.0

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

	# Create falling trap
	falling_trap = Area2D.new()

	var trap_shape := CollisionShape2D.new()
	var trap_rect := RectangleShape2D.new()

	trap_rect.size = Vector2(32, 32)
	trap_shape.shape = trap_rect

	falling_trap.position = Vector2(
		falling_trap_x,
		falling_trap_start_y
	)

	falling_trap.monitoring = true
	falling_trap.add_child(trap_shape)
	add_child(falling_trap)

	falling_trap.body_entered.connect(
		_on_falling_trap_body_entered
	)

	# Create exit
	exit_area = Area2D.new()

	var exit_shape := CollisionShape2D.new()
	var exit_rect := RectangleShape2D.new()

	exit_rect.size = Vector2(45, 50)
	exit_shape.shape = exit_rect

	exit_area.position = Vector2(877.5, 445)
	exit_area.monitoring = false

	exit_area.add_child(exit_shape)
	add_child(exit_area)

	exit_area.body_entered.connect(
		_on_exit_body_entered
	)

	queue_redraw()

	# Delay exit activation
	call_deferred("_enable_exit")


func _process(delta):
	if falling_trap == null:
		return

	# Falling movement
	falling_trap.position.y += (
		falling_trap_speed * 60.0 * delta
	)

	# Reset trap after it falls down
	if falling_trap.position.y >= 430:
		falling_trap.position.y = falling_trap_start_y

	queue_redraw()


func _enable_exit():
	await get_tree().create_timer(0.3).timeout

	exit_enabled = true

	if is_instance_valid(exit_area):
		exit_area.monitoring = true


func _on_spike_body_entered(body):
	if body.name == "Player":
		get_parent().kill_player()


func _on_falling_trap_body_entered(body):
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

	# Falling trap
	if falling_trap != null:
		draw_rect(
			Rect2(
				falling_trap.position - Vector2(16, 16),
				Vector2(32, 32)
			),
			Color("#ff9f43")
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