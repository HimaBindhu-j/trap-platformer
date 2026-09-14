extends Node2D

# ==================================================
# LEVEL 3 - THE FALLING CEILING
# ==================================================

# -------------------------
# PLATFORM LAYOUT
# -------------------------

var platforms = [
	Rect2(20, 470, 150, 30),
	Rect2(210, 420, 105, 30),
	Rect2(350, 470, 100, 30),
	Rect2(485, 390, 105, 30),
	Rect2(625, 470, 100, 30),
	Rect2(755, 410, 95, 30),
	Rect2(845, 470, 95, 30)
]


# -------------------------
# SPIKES
# -------------------------

var spikes = [
	Vector2(175, 470),
	Vector2(315, 420),
	Vector2(450, 470),
	Vector2(590, 390),
	Vector2(725, 470),
	Vector2(815, 410)
]


# ==================================================
# FALLING CEILING BLOCKS
# ==================================================

var falling_blocks: Array[Area2D] = []

var falling_block_data = [
	{
		"start": Vector2(270, 130),
		"bottom": 390.0,
		"speed": 5.0
	},
	{
		"start": Vector2(515, 110),
		"bottom": 360.0,
		"speed": 6.0
	},
	{
		"start": Vector2(680, 140),
		"bottom": 430.0,
		"speed": 5.5
	},
	{
		"start": Vector2(850, 120),
		"bottom": 390.0,
		"speed": 6.5
	}
]


# ==================================================
# DIAMONDS
# ==================================================

var diamonds = [
	Vector2(260, 375),
	Vector2(535, 345),
	Vector2(795, 365)
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
	# Create platforms
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
	# Create spikes
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
	# Create falling blocks
	# -------------------------

	for data in falling_block_data:

		var block := Area2D.new()

		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()

		rect.size = Vector2(38, 38)
		shape.shape = rect

		block.position = data["start"]
		block.monitoring = true

		block.add_child(shape)
		add_child(block)

		block.body_entered.connect(
			_on_falling_block_body_entered
		)

		falling_blocks.append(block)


	# -------------------------
	# Create diamonds
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
	# Create exit
	# -------------------------

	exit_area = Area2D.new()

	var exit_shape := CollisionShape2D.new()
	var exit_rect := RectangleShape2D.new()

	exit_rect.size = Vector2(45, 50)
	exit_shape.shape = exit_rect

	exit_area.position = Vector2(877, 445)

	# Prevent accidental instant exit
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

func _process(delta):

	# -------------------------
	# Move falling blocks
	# -------------------------

	for i in range(falling_blocks.size()):

		var block = falling_blocks[i]
		var data = falling_block_data[i]

		block.position.y += (
			data["speed"] * 60.0 * delta
		)

		# Reset block to ceiling
		if block.position.y >= data["bottom"]:

			block.position.y = data["start"].y


	queue_redraw()


# ==================================================
# EXIT ACTIVATION
# ==================================================

func _enable_exit():

	await get_tree().create_timer(0.5).timeout

	exit_enabled = true

	if is_instance_valid(exit_area):

		exit_area.monitoring = true


# ==================================================
# SPIKE COLLISION
# ==================================================

func _on_spike_body_entered(body):

	if body.name == "Player":

		get_parent().kill_player()


# ==================================================
# FALLING BLOCK COLLISION
# ==================================================

func _on_falling_block_body_entered(body):

	if body.name == "Player":

		get_parent().kill_player()


# ==================================================
# DIAMOND COLLECTION
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
# DRAW
# ==================================================

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
	# Falling ceiling blocks
	# -------------------------

	for block in falling_blocks:

		if block != null:

			draw_rect(
				Rect2(
					block.position - Vector2(19, 19),
					Vector2(38, 38)
				),
				Color("#ff9f43")
			)

			# Warning mark
			draw_string(
				ThemeDB.fallback_font,
				block.position + Vector2(-7, 7),
				"!",
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				22,
				Color("#18202b")
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