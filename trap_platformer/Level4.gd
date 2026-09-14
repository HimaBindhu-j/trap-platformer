extends Node2D

# =========================================================
# LEVEL 4 - THE FAKE WORLD
# =========================================================

# =========================================================
# MAIN UPPER ROUTE
# =========================================================

var platforms = [
	# Starting area
	Rect2(20, 470, 170, 30),

	# Upper route
	Rect2(120, 350, 120, 25),
	Rect2(280, 270, 130, 25),
	Rect2(470, 210, 120, 25),

	# Right side
	Rect2(650, 280, 120, 25),
	Rect2(820, 190, 120, 25)
]

# =========================================================
# LOWER SAFE ROUTE
# =========================================================

var lower_platforms = [
	Rect2(200, 520, 180, 30),
	Rect2(410, 520, 170, 30),
	Rect2(610, 520, 170, 30),
	Rect2(800, 520, 140, 30)
]

# =========================================================
# FAKE PLATFORMS
# =========================================================

var fake_platforms = [
	Rect2(260, 370, 100, 25),
	Rect2(430, 310, 100, 25),
	Rect2(610, 380, 100, 25)
]

var fake_bodies: Array[StaticBody2D] = []
var fake_collisions: Array[CollisionShape2D] = []
var fake_triggered: Array[bool] = []
var fake_timers: Array[float] = []

# =========================================================
# SPIKES - ONLY FEW
# =========================================================

var spikes = [
	Vector2(190, 470),
	Vector2(380, 520),
	Vector2(580, 520),
	Vector2(780, 520)
]

# =========================================================
# MOVING TRAP
# =========================================================

var moving_trap: Area2D
var moving_trap_start := Vector2(500, 450)
var moving_trap_direction := 1.0
var moving_trap_speed := 190.0
var moving_trap_range := 220.0

# =========================================================
# DIAMONDS
# =========================================================

var diamonds = [
	Vector2(175, 320),
	Vector2(525, 180),
	Vector2(860, 160)
]

# =========================================================
# EXIT
# =========================================================

var exit_area: Area2D
var exit_enabled := false


func _ready():

	# =====================================================
	# MAIN UPPER PLATFORMS
	# =====================================================

	for p in platforms:

		var body := StaticBody2D.new()

		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()

		shape.size = p.size
		collision.shape = shape

		body.position = p.position + p.size / 2.0

		body.add_child(collision)
		add_child(body)


	# =====================================================
	# LOWER SAFE ROUTE
	# =====================================================

	for p in lower_platforms:

		var body := StaticBody2D.new()

		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()

		shape.size = p.size
		collision.shape = shape

		body.position = p.position + p.size / 2.0

		body.add_child(collision)
		add_child(body)


	# =====================================================
	# FAKE PLATFORMS
	# =====================================================

	for i in range(fake_platforms.size()):

		var p = fake_platforms[i]

		var body := StaticBody2D.new()

		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()

		shape.size = p.size
		collision.shape = shape

		body.position = p.position + p.size / 2.0

		body.add_child(collision)
		add_child(body)

		fake_bodies.append(body)
		fake_collisions.append(collision)

		fake_triggered.append(false)
		fake_timers.append(0.0)

		# Area detects player
		var sensor := Area2D.new()

		var sensor_collision := CollisionShape2D.new()
		var sensor_shape := RectangleShape2D.new()

		sensor_shape.size = p.size
		sensor_collision.shape = sensor_shape

		sensor.position = p.position + p.size / 2.0
		sensor.monitoring = true

		sensor.add_child(sensor_collision)
		add_child(sensor)

		sensor.body_entered.connect(
			_on_fake_platform_entered.bind(i)
		)


	# =====================================================
	# SPIKES
	# =====================================================

	for s in spikes:

		var spike := Area2D.new()

		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()

		shape.size = Vector2(24, 25)
		collision.shape = shape

		spike.position = s + Vector2(12, -12)
		spike.monitoring = true

		spike.add_child(collision)
		add_child(spike)

		spike.body_entered.connect(
			_on_spike_body_entered
		)


	# =====================================================
	# MOVING TRAP
	# =====================================================

	moving_trap = Area2D.new()

	var trap_collision := CollisionShape2D.new()
	var trap_shape := RectangleShape2D.new()

	trap_shape.size = Vector2(40, 40)
	trap_collision.shape = trap_shape

	moving_trap.position = moving_trap_start
	moving_trap.monitoring = true

	moving_trap.add_child(trap_collision)
	add_child(moving_trap)

	moving_trap.body_entered.connect(
		_on_moving_trap_body_entered
	)


	# =====================================================
	# DIAMONDS
	# =====================================================

	for d in diamonds.duplicate():

		var diamond := Area2D.new()

		var collision := CollisionShape2D.new()
		var shape := CircleShape2D.new()

		shape.radius = 10
		collision.shape = shape

		diamond.position = d
		diamond.monitoring = true

		diamond.add_child(collision)
		add_child(diamond)

		diamond.body_entered.connect(
			_on_diamond_body_entered.bind(diamond)
		)


	# =====================================================
	# EXIT
	# =====================================================

	exit_area = Area2D.new()

	var exit_collision := CollisionShape2D.new()
	var exit_shape := RectangleShape2D.new()

	exit_shape.size = Vector2(45, 50)
	exit_collision.shape = exit_shape

	exit_area.position = Vector2(870, 165)
	exit_area.monitoring = false

	exit_area.add_child(exit_collision)
	add_child(exit_area)

	exit_area.body_entered.connect(
		_on_exit_body_entered
	)

	queue_redraw()

	call_deferred("_enable_exit")


func _process(delta):

	# =====================================================
	# FAKE PLATFORM TIMER
	# =====================================================

	for i in range(fake_platforms.size()):

		if not fake_triggered[i]:
			continue

		fake_timers[i] -= delta

		if fake_timers[i] <= 0.0:

			fake_collisions[i].disabled = true
			fake_timers[i] = 0.0


	# =====================================================
	# MOVING TRAP
	# =====================================================

	if is_instance_valid(moving_trap):

		moving_trap.position.x += (
			moving_trap_speed *
			moving_trap_direction *
			delta
		)

		var min_x = moving_trap_start.x
		var max_x = (
			moving_trap_start.x +
			moving_trap_range
		)

		if moving_trap.position.x >= max_x:

			moving_trap.position.x = max_x
			moving_trap_direction = -1.0

		elif moving_trap.position.x <= min_x:

			moving_trap.position.x = min_x
			moving_trap_direction = 1.0


	queue_redraw()


# =========================================================
# FAKE PLATFORM
# =========================================================

func _on_fake_platform_entered(body, index):

	if body.name != "Player":
		return

	if fake_triggered[index]:
		return

	fake_triggered[index] = true

	# Player has a short time to jump away
	fake_timers[index] = 0.35

	queue_redraw()


# =========================================================
# SPIKE
# =========================================================

func _on_spike_body_entered(body):

	if body.name == "Player":
		get_parent().kill_player()


# =========================================================
# MOVING TRAP
# =========================================================

func _on_moving_trap_body_entered(body):

	if body.name == "Player":
		get_parent().kill_player()


# =========================================================
# DIAMOND
# =========================================================

func _on_diamond_body_entered(body, diamond):

	if body.name == "Player":

		var diamond_position = diamond.position

		get_parent().collect_diamond()

		diamonds.erase(diamond_position)

		diamond.queue_free()

		queue_redraw()


# =========================================================
# EXIT ENABLE
# =========================================================

func _enable_exit():

	await get_tree().create_timer(0.5).timeout

	exit_enabled = true

	if is_instance_valid(exit_area):
		exit_area.monitoring = true


# =========================================================
# EXIT
# =========================================================

func _on_exit_body_entered(body):

	if body.name == "Player" and exit_enabled:

		get_parent().win_level()


# =========================================================
# DRAW
# =========================================================

func _draw():

	# =====================================================
	# UPPER PLATFORMS
	# =====================================================

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


	# =====================================================
	# LOWER ROUTE
	# =====================================================

	for p in lower_platforms:

		draw_rect(
			p,
			Color("#46515c")
		)

		draw_line(
			p.position,
			p.position + Vector2(p.size.x, 0),
			Color("#7d8994"),
			3
		)


	# =====================================================
	# FAKE PLATFORMS
	# =====================================================

	for i in range(fake_platforms.size()):

		if fake_collisions[i].disabled:
			continue

		var p = fake_platforms[i]

		draw_rect(
			p,
			Color("#a67c52")
		)

		draw_line(
			p.position,
			p.position + Vector2(p.size.x, 0),
			Color("#e6b86a"),
			3
		)

		# Cracks after activation
		if fake_triggered[i]:

			draw_line(
				p.position + Vector2(15, 5),
				p.position + Vector2(35, 20),
				Color("#ff4d6d"),
				2
			)

			draw_line(
				p.position + Vector2(60, 5),
				p.position + Vector2(45, 20),
				Color("#ff4d6d"),
				2
			)


	# =====================================================
	# SPIKES
	# =====================================================

	for s in spikes:

		var points = PackedVector2Array([
			s,
			s + Vector2(12, -25),
			s + Vector2(24, 0)
		])

		draw_colored_polygon(
			points,
			Color("#ff4d6d")
		)


	# =====================================================
	# MOVING TRAP
	# =====================================================

	if is_instance_valid(moving_trap):

		draw_rect(
			Rect2(
				moving_trap.position - Vector2(20, 20),
				Vector2(40, 40)
			),
			Color("#ff9f43")
		)

		draw_line(
			moving_trap.position - Vector2(12, 12),
			moving_trap.position + Vector2(12, 12),
			Color("#fff3b0"),
			3
		)


	# =====================================================
	# DIAMONDS
	# =====================================================

	for d in diamonds:

		var diamond_points = PackedVector2Array([
			d + Vector2(0, -12),
			d + Vector2(10, 0),
			d + Vector2(0, 12),
			d + Vector2(-10, 0)
		])

		draw_colored_polygon(
			diamond_points,
			Color("#66d9ff")
		)


	# =====================================================
	# EXIT
	# =====================================================

	draw_rect(
		Rect2(842, 135, 55, 55),
		Color("#7ee787")
	)

	draw_rect(
		Rect2(850, 143, 39, 47),
		Color("#18202b")
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(848, 125),
		"EXIT",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		20,
		Color("#7ee787")
	)

	draw_circle(
		Vector2(869, 155),
		8,
		Color("#7ee787")
	)