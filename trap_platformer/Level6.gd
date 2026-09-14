extends Node2D

# =========================================================
# LEVEL 6 - THE CRUSHER CORRIDOR
# =========================================================

# =========================================================
# FLOOR
# =========================================================

var platforms = [
	Rect2(20, 470, 180, 30),
	Rect2(200, 470, 180, 30),
	Rect2(380, 470, 180, 30),
	Rect2(560, 470, 180, 30),
	Rect2(740, 470, 200, 30)
]

# =========================================================
# UPPER SAFE PLATFORMS
# =========================================================

var upper_platforms = [
	Rect2(90, 350, 110, 25),
	Rect2(350, 300, 110, 25),
	Rect2(610, 340, 110, 25)
]

# =========================================================
# MOVING WALLS
# =========================================================

var moving_walls: Array[Area2D] = []

var wall_starts = [
	Vector2(270, 410),
	Vector2(500, 390),
	Vector2(720, 410)
]

var wall_ranges = [
	70.0,
	90.0,
	80.0
]

var wall_speeds = [
	160.0,
	190.0,
	210.0
]

var wall_directions = [
	1.0,
	-1.0,
	1.0
]

# =========================================================
# CRUSHERS
# =========================================================

var crushers: Array[Area2D] = []

var crusher_starts = [
	Vector2(150, 100),
	Vector2(430, 80),
	Vector2(680, 100),
	Vector2(850, 70)
]

var crusher_bottoms = [
	430.0,
	410.0,
	430.0,
	400.0
]

var crusher_speeds = [
	330.0,
	380.0,
	350.0,
	400.0
]

var crusher_directions = [
	1.0,
	1.0,
	1.0,
	1.0
]

# =========================================================
# SPIKES
# =========================================================

var spikes = [
	Vector2(200, 470),
	Vector2(380, 470),
	Vector2(560, 470),
	Vector2(740, 470)
]

# =========================================================
# DIAMONDS
# =========================================================

var diamonds = [
	Vector2(145, 320),
	Vector2(405, 270),
	Vector2(665, 310)
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
	# MOVING WALLS
	# =====================================================

	for i in range(wall_starts.size()):

		var wall := Area2D.new()

		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()

		shape.size = Vector2(35, 110)
		collision.shape = shape

		wall.position = wall_starts[i]
		wall.monitoring = true

		wall.add_child(collision)
		add_child(wall)

		wall.body_entered.connect(
			_on_moving_wall_body_entered
		)

		moving_walls.append(wall)


	# =====================================================
	# CRUSHERS
	# =====================================================

	for i in range(crusher_starts.size()):

		var crusher := Area2D.new()

		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()

		shape.size = Vector2(65, 45)
		collision.shape = shape

		crusher.position = crusher_starts[i]
		crusher.monitoring = true

		crusher.add_child(collision)
		add_child(crusher)

		crusher.body_entered.connect(
			_on_crusher_body_entered
		)

		crushers.append(crusher)


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

	exit_area.position = Vector2(890, 425)
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
	# MOVING WALLS
	# =====================================================

	for i in range(moving_walls.size()):

		var wall = moving_walls[i]

		if not is_instance_valid(wall):
			continue

		wall.position.x += (
			wall_speeds[i] *
			wall_directions[i] *
			delta
		)

		var min_x = wall_starts[i].x
		var max_x = (
			wall_starts[i].x +
			wall_ranges[i]
		)

		if wall.position.x >= max_x:

			wall.position.x = max_x
			wall_directions[i] = -1.0

		elif wall.position.x <= min_x:

			wall.position.x = min_x
			wall_directions[i] = 1.0


	# =====================================================
	# CRUSHERS
	# =====================================================

	for i in range(crushers.size()):

		var crusher = crushers[i]

		if not is_instance_valid(crusher):
			continue

		crusher.position.y += (
			crusher_speeds[i] *
			crusher_directions[i] *
			delta
		)

		if crusher.position.y >= crusher_bottoms[i]:

			crusher.position.y = crusher_bottoms[i]
			crusher_directions[i] = -1.0

		elif crusher.position.y <= crusher_starts[i].y:

			crusher.position.y = crusher_starts[i].y
			crusher_directions[i] = 1.0


	queue_redraw()


# =========================================================
# MOVING WALL HIT
# =========================================================

func _on_moving_wall_body_entered(body):

	if body.name == "Player":
		get_parent().kill_player()


# =========================================================
# CRUSHER HIT
# =========================================================

func _on_crusher_body_entered(body):

	if body.name == "Player":
		get_parent().kill_player()


# =========================================================
# SPIKE HIT
# =========================================================

func _on_spike_body_entered(body):

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
# ENABLE EXIT
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
	# MOVING WALLS
	# =====================================================

	for wall in moving_walls:

		if is_instance_valid(wall):

			draw_rect(
				Rect2(
					wall.position - Vector2(17.5, 55),
					Vector2(35, 110)
				),
				Color("#8e44ad")
			)

			draw_line(
				wall.position - Vector2(10, 45),
				wall.position + Vector2(10, 45),
				Color("#e056fd"),
				3
			)


	# =====================================================
	# CRUSHERS
	# =====================================================

	for crusher in crushers:

		if is_instance_valid(crusher):

			draw_rect(
				Rect2(
					crusher.position - Vector2(32.5, 22.5),
					Vector2(65, 45)
				),
				Color("#c44569")
			)

			draw_line(
				crusher.position - Vector2(25, 15),
				crusher.position + Vector2(25, 15),
				Color("#ff9f43"),
				4
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
		Rect2(862, 395, 55, 55),
		Color("#7ee787")
	)

	draw_rect(
		Rect2(870, 403, 39, 47),
		Color("#18202b")
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(868, 385),
		"EXIT",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		20,
		Color("#7ee787")
	)

	draw_circle(
		Vector2(889, 415),
		8,
		Color("#7ee787")
	)