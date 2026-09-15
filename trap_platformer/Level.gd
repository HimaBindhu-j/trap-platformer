extends Node2D


# =========================================================
# PLATFORMS
# =========================================================

var platforms = [
	Rect2(20, 470, 160, 30),
	Rect2(220, 410, 120, 30),
	Rect2(380, 340, 110, 30),
	Rect2(530, 420, 120, 30),
	Rect2(680, 350, 110, 30),
	Rect2(820, 470, 120, 30)
]

var platform_bodies: Array[StaticBody2D] = []


# =========================================================
# SPIKES
# =========================================================

var spikes = [
	Vector2(185, 470),
	Vector2(340, 410),
	Vector2(495, 340),
	Vector2(655, 420),
	Vector2(795, 470)
]


# =========================================================
# MOVING TRAP
# =========================================================

var moving_trap: Area2D

var moving_trap_start_x := 610.0
var moving_trap_range := 100.0
var moving_trap_speed := 2.0
var moving_trap_direction := 1.0

var trap_activated := false


# =========================================================
# DISAPPEARING PLATFORM
# =========================================================

var disappearing_platform_index := 1

var disappearing_trigger: Area2D

var disappearing_platform_active := true


# =========================================================
# REAL EXIT
# =========================================================

var exit_area: Area2D

var exit_position := Vector2(877, 445)

var exit_enabled := false


# =========================================================
# FAKE EXIT
# =========================================================

var fake_exit_trigger: Area2D

var fake_exit_used := false


# =========================================================
# READY
# =========================================================

func _ready():

	# -------------------------------------------------------
	# MOVING TRAP TRIGGER
	# -------------------------------------------------------

	var level_trigger = preload("res://Trigger.gd").new()

	level_trigger.setup(Vector2(100, 100))
	level_trigger.position = Vector2(300, 430)

	add_child(level_trigger)

	level_trigger.triggered.connect(
		_on_level_triggered
	)


	# -------------------------------------------------------
	# CREATE PLATFORMS
	# -------------------------------------------------------

	for i in range(platforms.size()):

		var p = platforms[i]

		var body := StaticBody2D.new()
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()

		shape.size = p.size
		collision.shape = shape

		body.position = p.position + p.size / 2.0

		body.add_child(collision)

		add_child(body)

		platform_bodies.append(body)


	# -------------------------------------------------------
	# DISAPPEARING PLATFORM TRIGGER
	# -------------------------------------------------------

	disappearing_trigger = preload("res://Trigger.gd").new()

	disappearing_trigger.setup(Vector2(100, 80))
	disappearing_trigger.position = Vector2(280, 350)

	add_child(disappearing_trigger)

	disappearing_trigger.triggered.connect(
		_on_disappearing_platform_triggered
	)


	# -------------------------------------------------------
	# CREATE SPIKES
	# -------------------------------------------------------

	for spike_position in spikes:

		var spike := Area2D.new()

		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()

		shape.size = Vector2(24, 25)
		collision.shape = shape

		spike.position = spike_position + Vector2(12, -12)

		spike.monitoring = true
		spike.collision_layer = 2
		spike.collision_mask = 1

		spike.add_child(collision)

		add_child(spike)

		spike.body_entered.connect(
			_on_spike_body_entered
		)


	# -------------------------------------------------------
	# MOVING TRAP
	# -------------------------------------------------------

	moving_trap = Area2D.new()

	var trap_collision := CollisionShape2D.new()
	var trap_shape := RectangleShape2D.new()

	trap_shape.size = Vector2(30, 30)

	trap_collision.shape = trap_shape

	moving_trap.position = Vector2(
		moving_trap_start_x,
		300
	)

	moving_trap.monitoring = true
	moving_trap.collision_layer = 2
	moving_trap.collision_mask = 1

	moving_trap.add_child(trap_collision)

	add_child(moving_trap)

	moving_trap.body_entered.connect(
		_on_moving_trap_body_entered
	)


	# -------------------------------------------------------
	# REAL EXIT
	# -------------------------------------------------------

	exit_area = Area2D.new()

	var exit_collision := CollisionShape2D.new()
	var exit_shape := RectangleShape2D.new()

	exit_shape.size = Vector2(45, 50)

	exit_collision.shape = exit_shape

	exit_area.position = exit_position

	exit_area.monitoring = false
	exit_area.collision_layer = 2
	exit_area.collision_mask = 1

	exit_area.add_child(exit_collision)

	add_child(exit_area)

	exit_area.body_entered.connect(
		_on_exit_body_entered
	)


	# -------------------------------------------------------
	# FAKE EXIT TRIGGER
	# -------------------------------------------------------

	fake_exit_trigger = preload("res://Trigger.gd").new()

	# Bigger area so player doesn't have to touch exact point
	fake_exit_trigger.setup(Vector2(120, 100))

	# This is BEFORE the real exit
	fake_exit_trigger.position = Vector2(810, 420)

	add_child(fake_exit_trigger)

	fake_exit_trigger.triggered.connect(
		_on_fake_exit_triggered
	)


	queue_redraw()

	call_deferred("_enable_exit")


# =========================================================
# PROCESS
# =========================================================

func _process(delta):

	# -------------------------------------------------------
	# MOVING TRAP
	# -------------------------------------------------------

	if moving_trap == null:
		return

	if not trap_activated:
		return


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


	queue_redraw()


# =========================================================
# ENABLE EXIT
# =========================================================

func _enable_exit():

	await get_tree().create_timer(0.3).timeout

	if not is_instance_valid(exit_area):
		return

	exit_enabled = true
	exit_area.monitoring = true


# =========================================================
# MOVING TRAP TRIGGER
# =========================================================

func _on_level_triggered(player):

	print("MOVING TRAP ACTIVATED!")

	trap_activated = true


# =========================================================
# DISAPPEARING PLATFORM
# =========================================================

func _on_disappearing_platform_triggered(player):

	if not disappearing_platform_active:
		return

	disappearing_platform_active = false

	print("DISAPPEARING PLATFORM ACTIVATED!")


	await get_tree().create_timer(0.3).timeout


	if disappearing_platform_index < platform_bodies.size():

		var platform = platform_bodies[
			disappearing_platform_index
		]

		if is_instance_valid(platform):

			platform.queue_free()


	queue_redraw()


# =========================================================
# FAKE EXIT
# =========================================================

func _on_fake_exit_triggered(player):

	if fake_exit_used:
		return

	fake_exit_used = true

	print("FAKE EXIT ACTIVATED!")

	# Small delay so player sees the fake exit first
	await get_tree().create_timer(0.25).timeout


	# -------------------------------------------------------
	# MOVE REAL EXIT
	# -------------------------------------------------------

	exit_position.x -= 150


	if is_instance_valid(exit_area):

		exit_area.position = exit_position


	queue_redraw()

	print("EXIT MOVED TO: ", exit_position)


# =========================================================
# SPIKE COLLISION
# =========================================================

func _on_spike_body_entered(body):

	if body.name == "Player":

		get_parent().kill_player()


# =========================================================
# MOVING TRAP COLLISION
# =========================================================

func _on_moving_trap_body_entered(body):

	if body.name == "Player":

		get_parent().kill_player()


# =========================================================
# EXIT COLLISION
# =========================================================

func _on_exit_body_entered(body):

	if body.name != "Player":
		return

	if not exit_enabled:
		return

	print("REAL EXIT REACHED!")

	get_parent().win_level()


# =========================================================
# DRAW
# =========================================================

func _draw():

	# -------------------------------------------------------
	# PLATFORMS
	# -------------------------------------------------------

	for i in range(platforms.size()):

		if i == disappearing_platform_index:

			if not disappearing_platform_active:
				continue

		var p = platforms[i]

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


	# -------------------------------------------------------
	# SPIKES
	# -------------------------------------------------------

	for spike_position in spikes:

		var points = PackedVector2Array([
			spike_position,
			spike_position + Vector2(12, -25),
			spike_position + Vector2(24, 0)
		])

		draw_colored_polygon(
			points,
			Color("#ff4d6d")
		)


	# -------------------------------------------------------
	# MOVING TRAP
	# -------------------------------------------------------

	if moving_trap != null:

		draw_rect(
			Rect2(
				moving_trap.position - Vector2(15, 15),
				Vector2(30, 30)
			),
			Color("#ff9f43")
		)


	# -------------------------------------------------------
	# REAL EXIT
	# -------------------------------------------------------

	if exit_area != null:

		var pos = exit_area.position

		# Outer green door
		draw_rect(
			Rect2(
				pos - Vector2(27.5, 30),
				Vector2(55, 55)
			),
			Color("#7ee787")
		)

		# Inner dark door
		draw_rect(
			Rect2(
				pos - Vector2(19.5, 22),
				Vector2(39, 47)
			),
			Color("#18202b")
		)

		# EXIT text
		draw_string(
			ThemeDB.fallback_font,
			pos + Vector2(-21, -30),
			"EXIT",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			20,
			Color("#7ee787")
		)

		# Door light
		draw_circle(
			pos + Vector2(0, -10),
			8,
			Color("#7ee787")
		)