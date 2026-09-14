extends Node2D

# =========================================================
# LEVEL 5 - THE DISAPPEARING FLOOR
# =========================================================

# =========================================================
# FLOOR SECTIONS
# =========================================================

var floor_sections = [
	Rect2(20, 470, 120, 30),
	Rect2(140, 470, 120, 30),
	Rect2(260, 470, 120, 30),
	Rect2(380, 470, 120, 30),
	Rect2(500, 470, 120, 30),
	Rect2(620, 470, 120, 30),
	Rect2(740, 470, 100, 30),
	Rect2(840, 470, 100, 30)
]

var floor_bodies: Array[StaticBody2D] = []
var floor_collisions: Array[CollisionShape2D] = []

var disappearing: Array[bool] = []
var disappear_timers: Array[float] = []

# =========================================================
# UPPER PLATFORMS
# =========================================================

var upper_platforms = [
	Rect2(210, 350, 90, 25),
	Rect2(450, 300, 100, 25),
	Rect2(690, 350, 90, 25)
]

# =========================================================
# SPIKES
# =========================================================

var spikes = [
	Vector2(300, 470),
	Vector2(540, 470),
	Vector2(760, 470)
]

# =========================================================
# MOVING TRAPS
# =========================================================

var moving_traps: Array[Area2D] = []

var moving_starts = [
	Vector2(350, 390),
	Vector2(600, 280)
]

var moving_ranges = [
	120.0,
	100.0
]

var moving_speeds = [
	170.0,
	200.0
]

var moving_directions = [
	1.0,
	-1.0
]

# =========================================================
# DIAMONDS
# =========================================================

var diamonds = [
	Vector2(255, 315),
	Vector2(495, 265),
	Vector2(735, 315)
]

# =========================================================
# EXIT
# =========================================================

var exit_area: Area2D
var exit_enabled := false


func _ready():

	# =====================================================
	# FLOOR
	# =====================================================

	for i in range(floor_sections.size()):

		var p = floor_sections[i]

		var body := StaticBody2D.new()

		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()

		shape.size = p.size
		collision.shape = shape

		body.position = p.position + p.size / 2.0

		body.add_child(collision)
		add_child(body)

		floor_bodies.append(body)
		floor_collisions.append(collision)

		disappearing.append(false)
		disappear_timers.append(0.0)


	# =====================================================
	# UPPER PLATFORMS
	# =====================================================

	for p in upper_platforms:

		var body := StaticBody2D.new()

		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()

		shape.size = p.size
		collision.shape = shape

		body.position = p.position + p.size / 2.0

		body.add_child(collision)
		add_child(body)


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
	# MOVING TRAPS
	# =====================================================

	for i in range(moving_starts.size()):

		var trap := Area2D.new()

		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()

		shape.size = Vector2(32, 32)
		collision.shape = shape

		trap.position = moving_starts[i]
		trap.monitoring = true

		trap.add_child(collision)
		add_child(trap)

		trap.body_entered.connect(
			_on_moving_trap_body_entered
		)

		moving_traps.append(trap)


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

	exit_area.position = Vector2(885, 425)
	exit_area.monitoring = false

	exit_area.add_child(exit_collision)
	add_child(exit_area)

	exit_area.body_entered.connect(
		_on_exit_body_entered
	)

	queue_redraw()

	call_deferred("_enable_exit")


func _process(delta):

	var player = get_parent().get_node("Player")

	if not is_instance_valid(player):
		return


	# =====================================================
	# DISAPPEARING FLOOR
	# =====================================================

	for i in range(floor_sections.size()):

		if disappearing[i]:
			continue

		var p = floor_sections[i]

		var player_x = player.global_position.x
		var section_end = p.position.x + p.size.x

		# Once player passes a section, it starts disappearing
		if player_x > section_end + 20:

			disappearing[i] = true
			disappear_timers[i] = 0.55


	# =====================================================
	# DISAPPEAR TIMERS
	# =====================================================

	for i in range(floor_sections.size()):

		if not disappearing[i]:
			continue

		if floor_collisions[i].disabled:
			continue

		disappear_timers[i] -= delta

		if disappear_timers[i] <= 0.0:

			floor_collisions[i].disabled = true


	# =====================================================
	# MOVING TRAPS
	# =====================================================

	for i in range(moving_traps.size()):

		var trap = moving_traps[i]

		if not is_instance_valid(trap):
			continue

		trap.position.x += (
			moving_speeds[i] *
			moving_directions[i] *
			delta
		)

		var min_x = moving_starts[i].x
		var max_x = (
			moving_starts[i].x +
			moving_ranges[i]
		)

		if trap.position.x >= max_x:

			trap.position.x = max_x
			moving_directions[i] = -1.0

		elif trap.position.x <= min_x:

			trap.position.x = min_x
			moving_directions[i] = 1.0


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
	# FLOOR
	# =====================================================

	for i in range(floor_sections.size()):

		if floor_collisions[i].disabled:
			continue

		var p = floor_sections[i]

		var floor_color = Color("#52606d")

		if disappearing[i]:
			floor_color = Color("#c44569")

		draw_rect(
			p,
			floor_color
		)

		draw_line(
			p.position,
			p.position + Vector2(p.size.x, 0),
			Color("#8c9aa8"),
			3
		)


	# =====================================================
	# UPPER PLATFORMS
	# =====================================================

	for p in upper_platforms:

		draw_rect(
			p,
			Color("#46515c")
		)

		draw_line(
			p.position,
			p.position + Vector2(p.size.x, 0),
			Color("#9aa7b2"),
			3
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
	# MOVING TRAPS
	# =====================================================

	for trap in moving_traps:

		if is_instance_valid(trap):

			draw_rect(
				Rect2(
					trap.position - Vector2(16, 16),
					Vector2(32, 32)
				),
				Color("#ff9f43")
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
		Rect2(857, 395, 55, 55),
		Color("#7ee787")
	)

	draw_rect(
		Rect2(865, 403, 39, 47),
		Color("#18202b")
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(863, 385),
		"EXIT",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		20,
		Color("#7ee787")
	)

	draw_circle(
		Vector2(884, 415),
		8,
		Color("#7ee787")
	)