extends Node2D

# ==================================================
# LEVEL 4 - FAKE PLATFORMS
# ==================================================

# -------------------------
# NORMAL PLATFORMS
# -------------------------

var normal_platforms = [
	Rect2(20, 470, 150, 30),
	Rect2(205, 420, 100, 30),
	Rect2(355, 350, 90, 30),
	Rect2(500, 410, 100, 30),
	Rect2(650, 350, 90, 30),
	Rect2(790, 420, 80, 30),
	Rect2(875, 470, 65, 30)
]


# -------------------------
# FAKE PLATFORMS
# -------------------------

var fake_platforms = [
	Rect2(305, 420, 50, 30),
	Rect2(445, 350, 55, 30),
	Rect2(600, 410, 50, 30),
	Rect2(740, 350, 50, 30)
]


var fake_bodies: Array[StaticBody2D] = []
var fake_active: Array[bool] = []


# ==================================================
# SPIKES
# ==================================================

var spikes = [
	Vector2(170, 470),
	Vector2(305, 470),
	Vector2(445, 470),
	Vector2(600, 470),
	Vector2(740, 470)
]


# ==================================================
# DIAMONDS
# ==================================================

var diamonds = [
	Vector2(255, 375),
	Vector2(525, 365),
	Vector2(820, 375)
]


# ==================================================
# EXIT
# ==================================================

var exit_area: Area2D
var exit_enabled := false


# ==================================================
# READY
# ==================================================

func _ready():

	# -------------------------
	# Normal platforms
	# -------------------------

	for p in normal_platforms:

		var body := StaticBody2D.new()
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()

		rect.size = p.size
		shape.shape = rect

		body.position = p.position + p.size / 2.0

		body.add_child(shape)
		add_child(body)


	# -------------------------
	# Fake platforms
	# -------------------------

	for p in fake_platforms:

		var body := StaticBody2D.new()
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()

		rect.size = p.size
		shape.shape = rect

		body.position = p.position + p.size / 2.0

		body.add_child(shape)
		add_child(body)

		fake_bodies.append(body)
		fake_active.append(true)


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
	# Diamonds
	# -------------------------

	for d in diamonds:

		var diamond := Area2D.new()

		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()

		rect.size = Vector2(22, 22)
		shape.shape = rect

		diamond.position = d
		diamond.monitoring = true

		diamond.add_child(shape)
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

	exit_area.position = Vector2(900, 445)
	exit_area.monitoring = false

	exit_area.add_child(exit_shape)
	add_child(exit_area)

	exit_area.body_entered.connect(
		_on_exit_body_entered
	)


	queue_redraw()

	call_deferred("_enable_exit")


# ==================================================
# PROCESS
# ==================================================

func _process(_delta):

	queue_redraw()


# ==================================================
# FAKE PLATFORM TRIGGER
# ==================================================

func _on_fake_platform_body_entered(body, index):

	if body.name != "Player":
		return

	if not fake_active[index]:
		return

	# Wait a short moment before disappearing.
	await get_tree().create_timer(0.25).timeout

	if not is_instance_valid(fake_bodies[index]):
		return

	fake_active[index] = false

	fake_bodies[index].queue_free()

	queue_redraw()


# ==================================================
# SPIKE COLLISION
# ==================================================

func _on_spike_body_entered(body):

	if body.name == "Player":

		get_parent().kill_player()


# ==================================================
# DIAMOND
# ==================================================

func _on_diamond_body_entered(body, diamond):

	if body.name == "Player":

		var diamond_position = diamond.position

		get_parent().collect_diamond()

		diamonds.erase(diamond_position)

		diamond.queue_free()

		queue_redraw()


# ==================================================
# EXIT
# ==================================================

func _on_exit_body_entered(body):

	if body.name == "Player" and exit_enabled:

		get_parent().win_level()


# ==================================================
# EXIT DELAY
# ==================================================

func _enable_exit():

	await get_tree().create_timer(0.5).timeout

	exit_enabled = true

	if is_instance_valid(exit_area):

		exit_area.monitoring = true


# ==================================================
# DRAW
# ==================================================

func _draw():

	# -------------------------
	# Normal platforms
	# -------------------------

	for p in normal_platforms:

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
	# Fake platforms
	# -------------------------

	for i in range(fake_platforms.size()):

		if fake_active[i]:

			var p = fake_platforms[i]

			draw_rect(
				p,
				Color("#8a7d6a")
			)

			draw_line(
				p.position,
				p.position + Vector2(p.size.x, 0),
				Color("#d6c7ad"),
				3
			)


	# -------------------------
	# Spikes
	# -------------------------

	for s in spikes:

		var points = PackedVector2Array([
			s + Vector2(0, 0),
			s + Vector2(12, -25),
			s + Vector2(24, 0)
		])

		draw_colored_polygon(
			points,
			Color("#ff4d6d")
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
		Rect2(875, 415, 55, 55),
		Color("#7ee787")
	)

	draw_rect(
		Rect2(883, 423, 39, 47),
		Color("#18202b")
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(881, 405),
		"EXIT",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		20,
		Color("#7ee787")
	)

	draw_circle(
		Vector2(902, 435),
		8,
		Color("#7ee787")
	)