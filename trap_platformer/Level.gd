extends Node2D

# =========================
# LEVEL 1 - HARD MODE
# =========================

var platforms = [
	Rect2(20, 470, 150, 30),
	Rect2(210, 420, 100, 30),
	Rect2(340, 350, 90, 30),
	Rect2(465, 410, 95, 30),
	Rect2(595, 330, 90, 30),
	Rect2(720, 400, 85, 30),
	Rect2(835, 470, 105, 30)
]

# Ground / platform spikes
var spikes = [
	Vector2(175, 470),
	Vector2(315, 420),
	Vector2(430, 350),
	Vector2(560, 410),
	Vector2(685, 330),
	Vector2(805, 400)
]

# =========================
# MOVING TRAP
# =========================

var moving_trap: Area2D
var moving_trap_start_x := 500.0
var moving_trap_range := 100.0
var moving_trap_speed := 2.2
var moving_trap_direction := 1.0

# =========================
# FALLING TRAP
# =========================

var falling_trap: Area2D
var falling_trap_start_y := 170.0
var falling_trap_speed := 4.5
var falling_trap_x := 630.0

# =========================
# DIAMONDS
# =========================

var diamonds = [
	Vector2(265, 380),
	Vector2(510, 370),
	Vector2(760, 360)
]

# =========================
# EXIT
# =========================

var exit_area: Area2D
var exit_enabled := false


func _ready():

	# -------------------------
	# Platforms
	# -------------------------

	for p in platforms:

		var body := StaticBody2D.new()
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()

		rect.size = p.size
		shape.shape = rect

		body.position = p.position + p.size / 2.0

		body.add_child(shape)
		add_child(body)


	# -------------------------
	# Spikes
	# -------------------------

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

		spike.body_entered.connect(
			_on_spike_body_entered
		)


	# -------------------------
	# Moving Trap
	# -------------------------

	moving_trap = Area2D.new()

	var moving_shape := CollisionShape2D.new()
	var moving_rect := RectangleShape2D.new()

	moving_rect.size = Vector2(30, 30)
	moving_shape.shape = moving_rect

	moving_trap.position = Vector2(
		moving_trap_start_x,
		300
	)

	moving_trap.monitoring = true

	moving_trap.add_child(moving_shape)
	add_child(moving_trap)

	moving_trap.body_entered.connect(
		_on_moving_trap_body_entered
	)


	# -------------------------
	# Falling Trap
	# -------------------------

	falling_trap = Area2D.new()

	var falling_shape := CollisionShape2D.new()
	var falling_rect := RectangleShape2D.new()

	falling_rect.size = Vector2(32, 32)
	falling_shape.shape = falling_rect

	falling_trap.position = Vector2(
		falling_trap_x,
		falling_trap_start_y
	)

	falling_trap.monitoring = true

	falling_trap.add_child(falling_shape)
	add_child(falling_trap)

	falling_trap.body_entered.connect(
		_on_falling_trap_body_entered
	)


	# -------------------------
	# Diamonds
	# -------------------------

	for d in diamonds:

		var diamond := Area2D.new()

		var diamond_shape := CollisionShape2D.new()
		var diamond_rect := RectangleShape2D.new()

		diamond_rect.size = Vector2(22, 22)
		diamond_shape.shape = diamond_rect

		diamond.position = d
		diamond.monitoring = true

		diamond.add_child(diamond_shape)
		add_child(diamond)

		diamond.body_entered.connect(
			_on_diamond_body_entered.bind(diamond)
		)


	# -------------------------
	# Exit
	# -------------------------

	exit_area = Area2D.new()

	var exit_shape := CollisionShape2D.new()
	var exit_rect := RectangleShape2D.new()

	exit_rect.size = Vector2(45, 50)
	exit_shape.shape = exit_rect

	exit_area.position = Vector2(877, 445)
	exit_area.monitoring = false

	exit_area.add_child(exit_shape)
	add_child(exit_area)

	exit_area.body_entered.connect(
		_on_exit_body_entered
	)

	queue_redraw()

	call_deferred("_enable_exit")


func _process(delta):

	# -------------------------
	# Moving trap
	# -------------------------

	if moving_trap != null:

		moving_trap.position.x += (
			moving_trap_direction
			* moving_trap_speed
			* 60.0
			* delta
		)

		if moving_trap.position.x >= (
			moving_trap_start_x
			+ moving_trap_range
		):

			moving_trap.position.x = (
				moving_trap_start_x
				+ moving_trap_range
			)

			moving_trap_direction = -1.0

		elif moving_trap.position.x <= moving_trap_start_x:

			moving_trap.position.x = moving_trap_start_x
			moving_trap_direction = 1.0


	# -------------------------
	# Falling trap
	# -------------------------

	if falling_trap != null:

		falling_trap.position.y += (
			falling_trap_speed
			* 60.0
			* delta
		)

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


func _on_moving_trap_body_entered(body):

	if body.name == "Player":
		get_parent().kill_player()


func _on_falling_trap_body_entered(body):

	if body.name == "Player":
		get_parent().kill_player()


func _on_diamond_body_entered(body, diamond):

	if body.name == "Player":

		get_parent().collect_diamond()

		diamond.queue_free()


func _on_exit_body_entered(body):

	if body.name == "Player" and exit_enabled:

		get_parent().win_level()


func _draw():

	# -------------------------
	# Platforms
	# -------------------------

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


	# -------------------------
	# Spikes
	# -------------------------

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


	# -------------------------
	# Moving Trap
	# -------------------------

	if moving_trap != null:

		draw_rect(
			Rect2(
				moving_trap.position - Vector2(15, 15),
				Vector2(30, 30)
			),
			Color("#ff9f43")
		)


	# -------------------------
	# Falling Trap
	# -------------------------

	if falling_trap != null:

		draw_rect(
			Rect2(
				falling_trap.position - Vector2(16, 16),
				Vector2(32, 32)
			),
			Color("#ff9f43")
		)


	# -------------------------
	# Diamonds
	# -------------------------

	for d in diamonds:

		var points = PackedVector2Array([
			d + Vector2(0, -12),
			d + Vector2(10, 0),
			d + Vector2(0, 12),
			d + Vector2(-10, 0)
		])

		draw_colored_polygon(
			points,
			Color("#66d9ff")
		)


	# -------------------------
	# Exit
	# -------------------------

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