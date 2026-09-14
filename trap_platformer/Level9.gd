extends Node2D

var platforms = [
	Rect2(20, 470, 140, 30),
	Rect2(190, 420, 100, 25),
	Rect2(320, 350, 90, 25),
	Rect2(450, 430, 100, 25),
	Rect2(590, 340, 90, 25),
	Rect2(720, 420, 90, 25),
	Rect2(850, 350, 90, 30)
]

var upper_platforms = [
	Rect2(250, 270, 90, 25),
	Rect2(500, 230, 90, 25),
	Rect2(740, 250, 90, 25)
]

var spikes = [
	Vector2(160, 470),
	Vector2(290, 420),
	Vector2(410, 350),
	Vector2(550, 430),
	Vector2(680, 340),
	Vector2(810, 420)
]

var moving_traps: Array[Area2D] = []

var moving_starts = [
	Vector2(230, 360),
	Vector2(470, 330),
	Vector2(700, 330)
]

var moving_ranges = [
	100.0,
	100.0,
	90.0
]

var moving_speeds = [
	190.0,
	210.0,
	220.0
]

var moving_directions = [
	1.0,
	-1.0,
	1.0
]

var falling_traps: Array[Area2D] = []

var falling_starts = [
	Vector2(275, 120),
	Vector2(525, 100),
	Vector2(770, 110)
]

var falling_bottoms = [
	330.0,
	390.0,
	380.0
]

var falling_speeds = [
	350.0,
	400.0,
	450.0
]

var falling_directions = [
	1.0,
	1.0,
	1.0
]

var diamonds = [
	Vector2(230, 375),
	Vector2(535, 185),
	Vector2(770, 205)
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


	# Moving traps
	for i in range(moving_starts.size()):

		var trap := Area2D.new()
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()

		shape.size = Vector2(34, 34)
		collision.shape = shape

		trap.position = moving_starts[i]
		trap.monitoring = true

		trap.add_child(collision)
		add_child(trap)

		trap.body_entered.connect(_on_moving_trap_body_entered)

		moving_traps.append(trap)


	# Falling traps
	for i in range(falling_starts.size()):

		var trap := Area2D.new()
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()

		shape.size = Vector2(42, 42)
		collision.shape = shape

		trap.position = falling_starts[i]
		trap.monitoring = true

		trap.add_child(collision)
		add_child(trap)

		trap.body_entered.connect(_on_falling_trap_body_entered)

		falling_traps.append(trap)


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


	# Exit
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

	# Moving traps
	for i in range(moving_traps.size()):

		var trap = moving_traps[i]

		if not is_instance_valid(trap):
			continue

		trap.position.x += (
			moving_speeds[i]
			* moving_directions[i]
			* delta
		)

		var min_x = moving_starts[i].x
		var max_x = min_x + moving_ranges[i]

		if trap.position.x >= max_x:

			trap.position.x = max_x
			moving_directions[i] = -1.0

		elif trap.position.x <= min_x:

			trap.position.x = min_x
			moving_directions[i] = 1.0


	# Falling traps
	for i in range(falling_traps.size()):

		var trap = falling_traps[i]

		if not is_instance_valid(trap):
			continue

		trap.position.y += (
			falling_speeds[i]
			* falling_directions[i]
			* delta
		)

		if trap.position.y >= falling_bottoms[i]:

			trap.position.y = falling_bottoms[i]
			falling_directions[i] = -1.0

		elif trap.position.y <= falling_starts[i].y:

			trap.position.y = falling_starts[i].y
			falling_directions[i] = 1.0

	queue_redraw()


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


	# Moving traps
	for trap in moving_traps:

		if is_instance_valid(trap):

			draw_rect(
				Rect2(
					trap.position - Vector2(17, 17),
					Vector2(34, 34)
				),
				Color("#ff9f43")
			)

			draw_line(
				trap.position - Vector2(11, 11),
				trap.position + Vector2(11, 11),
				Color("#fff3b0"),
				3
			)


	# Falling traps
	for trap in falling_traps:

		if is_instance_valid(trap):

			draw_rect(
				Rect2(
					trap.position - Vector2(21, 21),
					Vector2(42, 42)
				),
				Color("#c44569")
			)

			draw_line(
				trap.position - Vector2(15, 15),
				trap.position + Vector2(15, 15),
				Color("#ff9f43"),
				3
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


	# Exit
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
		"EXIT",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		20,
		Color("#7ee787")
	)

	draw_circle(
		Vector2(884, 295),
		8,
		Color("#7ee787")
	)