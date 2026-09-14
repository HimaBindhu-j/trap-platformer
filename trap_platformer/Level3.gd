extends Node2D

# =========================================================
# LEVEL 3 - THE DEATH CORRIDOR
# =========================================================

var platforms = [
	Rect2(20, 470, 130, 30),
	Rect2(190, 420, 90, 30),
	Rect2(330, 360, 85, 30),
	Rect2(465, 430, 80, 30),
	Rect2(590, 350, 85, 30),
	Rect2(720, 420, 75, 30),
	Rect2(835, 350, 105, 30)
]

var spikes = [
	Vector2(150, 470),
	Vector2(280, 420),
	Vector2(415, 360),
	Vector2(545, 430),
	Vector2(675, 350),
	Vector2(795, 420)
]

# =========================================================
# FALLING BLOCKS
# =========================================================

var falling_blocks: Array[Area2D] = []

var falling_data = [
	{"start": Vector2(235, 170), "bottom": 385.0, "speed": 330.0},
	{"start": Vector2(505, 120), "bottom": 395.0, "speed": 390.0},
	{"start": Vector2(745, 100), "bottom": 395.0, "speed": 450.0}
]

var falling_active: Array[bool] = []

# =========================================================
# MOVING TRAPS
# =========================================================

var moving_traps: Array[Area2D] = []

var moving_trap_starts = [
	Vector2(380, 315),
	Vector2(640, 300)
]

var moving_trap_ranges = [
	70.0,
	90.0
]

var moving_trap_speeds = [
	175.0,
	210.0
]

var moving_trap_directions = [
	1.0,
	1.0
]

# =========================================================
# DIAMONDS
# =========================================================

var diamonds = [
	Vector2(235, 375),
	Vector2(600, 305),
	Vector2(850, 305)
]

# =========================================================
# EXIT
# =========================================================

var exit_area: Area2D
var exit_enabled := false


func _ready():

	# =====================================================
	# PLATFORMS
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

		spike.body_entered.connect(_on_spike_body_entered)


	# =====================================================
	# FALLING BLOCKS
	# =====================================================

	for i in range(falling_data.size()):

		var block := Area2D.new()

		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()

		shape.size = Vector2(42, 42)
		collision.shape = shape

		block.position = falling_data[i]["start"]
		block.monitoring = true

		block.add_child(collision)
		add_child(block)

		block.body_entered.connect(_on_falling_block_body_entered)

		falling_blocks.append(block)
		falling_active.append(false)


	# =====================================================
	# MOVING TRAPS
	# =====================================================

	for i in range(moving_trap_starts.size()):

		var trap := Area2D.new()

		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()

		shape.size = Vector2(30, 30)
		collision.shape = shape

		trap.position = moving_trap_starts[i]
		trap.monitoring = true

		trap.add_child(collision)
		add_child(trap)

		trap.body_entered.connect(_on_moving_trap_body_entered)

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

	# EXIT IS NOW ON THE FINAL PLATFORM
	exit_area.position = Vector2(877, 325)

	exit_area.monitoring = false

	exit_area.add_child(exit_collision)
	add_child(exit_area)

	exit_area.body_entered.connect(_on_exit_body_entered)

	queue_redraw()

	call_deferred("_enable_exit")


func _process(delta):

	# =====================================================
	# FALLING BLOCK MOVEMENT
	# =====================================================

	for i in range(falling_blocks.size()):

		var block = falling_blocks[i]

		if not is_instance_valid(block):
			continue

		if not falling_active[i]:
			continue

		block.position.y += falling_data[i]["speed"] * delta

		if block.position.y >= falling_data[i]["bottom"]:

			block.position.y = falling_data[i]["bottom"]
			falling_active[i] = false


	# =====================================================
	# ACTIVATE FALLING BLOCK WHEN PLAYER IS NEAR
	# =====================================================

	var player = get_parent().get_node("Player")

	if is_instance_valid(player):

		for i in range(falling_blocks.size()):

			if falling_active[i]:
				continue

			var block = falling_blocks[i]

			var distance = abs(
				player.global_position.x -
				block.global_position.x
			)

			if distance < 80.0:
				falling_active[i] = true


	# =====================================================
	# MOVING TRAPS
	# =====================================================

	for i in range(moving_traps.size()):

		var trap = moving_traps[i]

		if not is_instance_valid(trap):
			continue

		trap.position.x += (
			moving_trap_speeds[i] *
			moving_trap_directions[i] *
			delta
		)

		var start_x = moving_trap_starts[i].x

		var min_x = start_x
		var max_x = start_x + moving_trap_ranges[i]

		if trap.position.x >= max_x:

			trap.position.x = max_x
			moving_trap_directions[i] = -1.0

		elif trap.position.x <= min_x:

			trap.position.x = min_x
			moving_trap_directions[i] = 1.0


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
# SPIKE HIT
# =========================================================

func _on_spike_body_entered(body):

	if body.name == "Player":
		get_parent().kill_player()


# =========================================================
# FALLING BLOCK HIT
# =========================================================

func _on_falling_block_body_entered(body):

	if body.name == "Player":
		get_parent().kill_player()


# =========================================================
# MOVING TRAP HIT
# =========================================================

func _on_moving_trap_body_entered(body):

	if body.name == "Player":
		get_parent().kill_player()


# =========================================================
# DIAMOND COLLECT
# =========================================================

func _on_diamond_body_entered(body, diamond):

	if body.name == "Player":

		var diamond_position = diamond.position

		get_parent().collect_diamond()

		diamonds.erase(diamond_position)

		diamond.queue_free()

		queue_redraw()


# =========================================================
# EXIT
# =========================================================

func _on_exit_body_entered(body):

	if body.name == "Player" and exit_enabled:

		get_parent().win_level()


# =========================================================
# DRAW LEVEL
# =========================================================

func _draw():

	# =====================================================
	# PLATFORMS
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
	# FALLING BLOCKS
	# =====================================================

	for block in falling_blocks:

		if is_instance_valid(block):

			draw_rect(
				Rect2(
					block.position - Vector2(21, 21),
					Vector2(42, 42)
				),
				Color("#c44569")
			)

			draw_line(
				block.position - Vector2(15, 15),
				block.position + Vector2(15, 15),
				Color("#ff9f43"),
				3
			)


	# =====================================================
	# MOVING TRAPS
	# =====================================================

	for trap in moving_traps:

		if is_instance_valid(trap):

			draw_rect(
				Rect2(
					trap.position - Vector2(15, 15),
					Vector2(30, 30)
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
	# EXIT - ON FINAL PLATFORM
	# =====================================================

	draw_rect(
		Rect2(860, 295, 55, 55),
		Color("#7ee787")
	)

	draw_rect(
		Rect2(868, 303, 39, 47),
		Color("#18202b")
	)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(866, 285),
		"EXIT",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		20,
		Color("#7ee787")
	)

	draw_circle(
		Vector2(887, 315),
		8,
		Color("#7ee787")
	)