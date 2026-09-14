extends Node2D

var platforms = [
	Rect2(20, 470, 130, 30),
	Rect2(180, 410, 100, 25),
	Rect2(310, 350, 100, 25),
	Rect2(440, 430, 100, 25),
	Rect2(570, 350, 100, 25),
	Rect2(700, 410, 100, 25),
	Rect2(830, 350, 110, 30)
]

var upper_platforms = [
	Rect2(230, 270, 100, 25),
	Rect2(480, 250, 100, 25),
	Rect2(730, 230, 100, 25)
]

var spikes = [
	Vector2(150, 470),
	Vector2(280, 410),
	Vector2(410, 350),
	Vector2(540, 430),
	Vector2(670, 350),
	Vector2(800, 410)
]

var moving_walls: Array[Area2D] = []

var wall_starts = [
	Vector2(240, 360),
	Vector2(500, 360),
	Vector2(750, 330)
]

var wall_ranges = [
	80.0,
	90.0,
	80.0
]

var wall_speeds = [
	190.0,
	210.0,
	220.0
]

var wall_directions = [
	1.0,
	-1.0,
	1.0
]

var crushers: Array[Area2D] = []

var crusher_starts = [
	Vector2(350, 100),
	Vector2(610, 100),
	Vector2(850, 100)
]

var crusher_bottoms = [
	400.0,
	390.0,
	390.0
]

var crusher_speeds = [
	360.0,
	400.0,
	430.0
]

var crusher_directions = [
	1.0,
	1.0,
	1.0
]

var fake_platforms = [
	Rect2(335, 290, 80, 22),
	Rect2(595, 290, 80, 22)
]

var fake_collisions: Array[CollisionShape2D] = []
var fake_triggered = [false, false]
var fake_timers = [0.0, 0.0]

var diamonds = [
	Vector2(245, 225),
	Vector2(495, 205),
	Vector2(745, 185)
]

var exit_area: Area2D
var exit_enabled := false


func _ready():

	# Main platforms
	for p in platforms:
		var body := StaticBody2D.new()
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()

		shape.size = p.size
		collision.shape = shape
		body.position = p.position + p.size / 2.0

		body.add_child(collision)
		add_child(body)


	# Upper platforms
	for p in upper_platforms:
		var body := StaticBody2D.new()
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()

		shape.size = p.size
		collision.shape = shape
		body.position = p.position + p.size / 2.0

		body.add_child(collision)
		add_child(body)


	# Spikes
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

		spike.body_entered.connect(_on_spike_body_entered)


	# Moving walls
	for i in range(wall_starts.size()):

		var wall := Area2D.new()
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()

		shape.size = Vector2(35, 100)
		collision.shape = shape

		wall.position = wall_starts[i]
		wall.monitoring = true

		wall.add_child(collision)
		add_child(wall)

		wall.body_entered.connect(_on_wall_body_entered)

		moving_walls.append(wall)


	# Crushers
	for i in range(crusher_starts.size()):

		var crusher := Area2D.new()
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()

		shape.size = Vector2(60, 45)
		collision.shape = shape

		crusher.position = crusher_starts[i]
		crusher.monitoring = true

		crusher.add_child(collision)
		add_child(crusher)

		crusher.body_entered.connect(_on_crusher_body_entered)

		crushers.append(crusher)


	# Fake platforms
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

		fake_collisions.append(collision)

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


	# Diamonds
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


	# Final exit
	exit_area = Area2D.new()

	var exit_collision := CollisionShape2D.new()
	var exit_shape := RectangleShape2D.new()

	exit_shape.size = Vector2(45, 50)
	exit_collision.shape = exit_shape

	exit_area.position = Vector2(885, 305)
	exit_area.monitoring = false

	exit_area.add_child(exit_collision)
	add_child(exit_area)

	exit_area.body_entered.connect(_on_exit_body_entered)

	queue_redraw()

	call_deferred("_enable_exit")


func _process(delta):

	# Moving walls
	for i in range(moving_walls.size()):

		var wall = moving_walls[i]

		if not is_instance_valid(wall):
			continue

		wall.position.x += (
			wall_speeds[i]
			* wall_directions[i]
			* delta
		)

		var min_x = wall_starts[i].x
		var max_x = min_x + wall_ranges[i]

		if wall.position.x >= max_x:
			wall.position.x = max_x
			wall_directions[i] = -1.0

		elif wall.position.x <= min_x:
			wall.position.x = min_x
			wall_directions[i] = 1.0


	# Crushers
	for i in range(crushers.size()):

		var crusher = crushers[i]

		if not is_instance_valid(crusher):
			continue

		crusher.position.y += (
			crusher_speeds[i]
			* crusher_directions[i]
			* delta
		)

		if crusher.position.y >= crusher_bottoms[i]:

			crusher.position.y = crusher_bottoms[i]
			crusher_directions[i] = -1.0

		elif crusher.position.y <= crusher_starts[i].y:

			crusher.position.y = crusher_starts[i].y
			crusher_directions[i] = 1.0


	# Fake platforms
	for i in range(fake_platforms.size()):

		if not fake_triggered[i]:
			continue

		fake_timers[i] -= delta

		if fake_timers[i] <= 0.0:

			fake_collisions[i].disabled = true
			fake_timers[i] = 0.0


	queue_redraw()


func _on_spike_body_entered(body):

	if body.name == "Player":
		get_parent().kill_player()


func _on_wall_body_entered(body):

	if body.name == "Player":
		get_parent().kill_player()


func _on_crusher_body_entered(body):

	if body.name == "Player":
		get_parent().kill_player()


func _on_fake_platform_entered(body, index):

	if body.name != "Player":
		return

	if fake_triggered[index]:
		return

	fake_triggered[index] = true
	fake_timers[index] = 0.4


func _on_diamond_body_entered(body, diamond):

	if body.name == "Player":

		var diamond_position = diamond.position

		get_parent().collect_diamond()

		diamonds.erase(diamond_position)

		diamond.queue_free()

		queue_redraw()


func _enable_exit():

	await get_tree().create_timer(0.5).timeout

	exit_enabled = true

	if is_instance_valid(exit_area):
		exit_area.monitoring = true


func _on_exit_body_entered(body):

	if body.name == "Player" and exit_enabled:
		get_parent().win_level()


func _draw():

	# Main platforms
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


	# Upper platforms
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


	# Fake platforms
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
			Color("#f0c674"),
			3
		)


	# Spikes
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


	# Moving walls
	for wall in moving_walls:

		if is_instance_valid(wall):

			draw_rect(
				Rect2(
					wall.position - Vector2(17.5, 50),
					Vector2(35, 100)
				),
				Color("#8e44ad")
			)

			draw_line(
				wall.position - Vector2(10, 40),
				wall.position + Vector2(10, 40),
				Color("#e056fd"),
				3
			)


	# Crushers
	for crusher in crushers:

		if is_instance_valid(crusher):

			draw_rect(
				Rect2(
					crusher.position - Vector2(30, 22.5),
					Vector2(60, 45)
				),
				Color("#c44569")
			)

			draw_line(
				crusher.position - Vector2(23, 14),
				crusher.position + Vector2(23, 14),
				Color("#ff9f43"),
				4
			)


	# Diamonds
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


	# Final exit
	draw_rect(
		Rect2(857, 275, 55, 55),
		Color("#7ee787")
	)

	draw_rect(
		Rect2(865, 283, 39, 47),
		Color("#18202b")
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(863, 265),
		"FINAL EXIT",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		18,
		Color("#7ee787")
	)

	draw_circle(
		Vector2(884, 295),
		8,
		Color("#7ee787")
	)