extends Node2D

var platforms = [
	Rect2(20, 470, 160, 30),
	Rect2(210, 410, 110, 25),
	Rect2(350, 330, 110, 25),
	Rect2(500, 410, 110, 25),
	Rect2(640, 300, 110, 25),
	Rect2(790, 400, 150, 30)
]

var safe_platforms = [
	Rect2(180, 520, 170, 30),
	Rect2(390, 520, 170, 30),
	Rect2(600, 520, 170, 30)
]

var spikes = [
	Vector2(180, 470),
	Vector2(320, 410),
	Vector2(460, 330),
	Vector2(610, 410),
	Vector2(750, 300)
]

var surprise_trap: Area2D
var moving_trap: Area2D
var moving_direction := 1.0

var diamonds = [
	Vector2(255, 365),
	Vector2(685, 255),
	Vector2(850, 365)
]

var fake_exit: Area2D
var real_exit: Area2D
var real_exit_enabled := false


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

	# Lower safe platforms
	for p in safe_platforms:
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

	# Moving trap
	moving_trap = Area2D.new()

	var moving_collision := CollisionShape2D.new()
	var moving_shape := RectangleShape2D.new()

	moving_shape.size = Vector2(35, 35)
	moving_collision.shape = moving_shape

	moving_trap.position = Vector2(400, 270)
	moving_trap.monitoring = true

	moving_trap.add_child(moving_collision)
	add_child(moving_trap)

	moving_trap.body_entered.connect(_on_moving_trap_body_entered)

	# Surprise trap
	surprise_trap = Area2D.new()

	var surprise_collision := CollisionShape2D.new()
	var surprise_shape := RectangleShape2D.new()

	surprise_shape.size = Vector2(70, 20)
	surprise_collision.shape = surprise_shape

	surprise_trap.position = Vector2(700, 360)
	surprise_trap.monitoring = true

	surprise_trap.add_child(surprise_collision)
	add_child(surprise_trap)

	surprise_trap.body_entered.connect(_on_surprise_trap_body_entered)

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

		diamond.body_entered.connect(_on_diamond_body_entered.bind(diamond))

	# Fake exit
	fake_exit = Area2D.new()

	var fake_collision := CollisionShape2D.new()
	var fake_shape := RectangleShape2D.new()

	fake_shape.size = Vector2(50, 50)
	fake_collision.shape = fake_shape

	fake_exit.position = Vector2(525, 360)
	fake_exit.monitoring = true

	fake_exit.add_child(fake_collision)
	add_child(fake_exit)

	fake_exit.body_entered.connect(_on_fake_exit_body_entered)

	# Real exit
	real_exit = Area2D.new()

	var real_collision := CollisionShape2D.new()
	var real_shape := RectangleShape2D.new()

	real_shape.size = Vector2(50, 50)
	real_collision.shape = real_shape

	real_exit.position = Vector2(865, 355)
	real_exit.monitoring = false

	real_exit.add_child(real_collision)
	add_child(real_exit)

	real_exit.body_entered.connect(_on_real_exit_body_entered)

	queue_redraw()

	call_deferred("_enable_real_exit")


func _process(delta):

	# Moving trap
	if is_instance_valid(moving_trap):
		moving_trap.position.x += 180.0 * moving_direction * delta

		if moving_trap.position.x >= 570:
			moving_trap.position.x = 570
			moving_direction = -1.0

		elif moving_trap.position.x <= 400:
			moving_trap.position.x = 400
			moving_direction = 1.0

	queue_redraw()


func _on_spike_body_entered(body):
	if body.name == "Player":
		get_parent().kill_player()


func _on_moving_trap_body_entered(body):
	if body.name == "Player":
		get_parent().kill_player()


func _on_surprise_trap_body_entered(body):
	if body.name == "Player":
		get_parent().kill_player()


func _on_fake_exit_body_entered(body):
	if body.name == "Player":
		get_parent().kill_player()


func _on_diamond_body_entered(body, diamond):
	if body.name == "Player":
		var diamond_position = diamond.position

		get_parent().collect_diamond()

		diamonds.erase(diamond_position)
		diamond.queue_free()

		queue_redraw()


func _enable_real_exit():
	await get_tree().create_timer(0.5).timeout

	real_exit_enabled = true

	if is_instance_valid(real_exit):
		real_exit.monitoring = true


func _on_real_exit_body_entered(body):
	if body.name == "Player" and real_exit_enabled:
		get_parent().win_level()


func _draw():

	# Main platforms
	for p in platforms:
		draw_rect(p, Color("#52606d"))
		draw_line(
			p.position,
			p.position + Vector2(p.size.x, 0),
			Color("#8c9aa8"),
			3
		)

	# Lower safe platforms
	for p in safe_platforms:
		draw_rect(p, Color("#46515c"))
		draw_line(
			p.position,
			p.position + Vector2(p.size.x, 0),
			Color("#7d8994"),
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

	# Moving trap
	if is_instance_valid(moving_trap):
		draw_rect(
			Rect2(
				moving_trap.position - Vector2(17.5, 17.5),
				Vector2(35, 35)
			),
			Color("#ff9f43")
		)

		draw_line(
			moving_trap.position - Vector2(12, 12),
			moving_trap.position + Vector2(12, 12),
			Color("#fff3b0"),
			3
		)

	# Surprise trap
	if is_instance_valid(surprise_trap):
		draw_rect(
			Rect2(
				surprise_trap.position - Vector2(35, 10),
				Vector2(70, 20)
			),
			Color("#c44569")
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

	# Fake exit
	if is_instance_valid(fake_exit):
		draw_rect(
			Rect2(
				fake_exit.position - Vector2(25, 25),
				Vector2(50, 50)
			),
			Color("#ff4d6d")
		)

		draw_string(
			ThemeDB.fallback_font,
			fake_exit.position + Vector2(-22, -32),
			"FAKE",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			18,
			Color("#ff4d6d")
		)

	# Real exit
	if is_instance_valid(real_exit):
		draw_rect(
			Rect2(
				real_exit.position - Vector2(27.5, 27.5),
				Vector2(55, 55)
			),
			Color("#7ee787")
		)

		draw_rect(
			Rect2(
				real_exit.position - Vector2(19.5, 19.5),
				Vector2(39, 47)
			),
			Color("#18202b")
		)

		draw_string(
			ThemeDB.fallback_font,
			real_exit.position + Vector2(-20, -35),
			"EXIT",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			20,
			Color("#7ee787")
		)

		draw_circle(
			real_exit.position + Vector2(0, -10),
			8,
			Color("#7ee787")
		)