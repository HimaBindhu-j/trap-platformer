extends Node2D

# =========================
# GAME STATE
# =========================

var lives := 3
var won := false
var game_over := false
var message := ""

var current_level := 1
var changing_level := false


# =========================
# LEVEL STATS
# =========================

var diamonds_collected := 0
var level_start_time := 0

# Last safe position
var last_safe_position := Vector2(90, 430)


# =========================
# READY
# =========================

func _ready():

	level_start_time = Time.get_ticks_msec()

	last_safe_position = $Player.global_position

	queue_redraw()


# =========================
# PROCESS
# =========================

func _process(_delta):

	# -------------------------
	# Restart
	# -------------------------

	if Input.is_action_just_pressed("restart"):

		get_tree().reload_current_scene()

		return


	# =========================
	# DEVELOPER LEVEL TESTING
	# =========================

	if Input.is_key_pressed(KEY_1):
		test_level(1)
		return

	if Input.is_key_pressed(KEY_2):
		test_level(2)
		return

	if Input.is_key_pressed(KEY_3):
		test_level(3)
		return

	if Input.is_key_pressed(KEY_4):
		test_level(4)
		return

	if Input.is_key_pressed(KEY_5):
		test_level(5)
		return

	if Input.is_key_pressed(KEY_6):
		test_level(6)
		return

	if Input.is_key_pressed(KEY_7):
		test_level(7)
		return

	if Input.is_key_pressed(KEY_8):
		test_level(8)
		return

	if Input.is_key_pressed(KEY_9):
		test_level(9)
		return

	if Input.is_key_pressed(KEY_0):
		test_level(10)
		return


	# -------------------------
	# Stop after game over / win
	# -------------------------

	if game_over or won:

		return


	var player = $Player


	# -------------------------
	# Save latest safe position
	# -------------------------

	if player.is_on_floor():

		last_safe_position = player.global_position


	# -------------------------
	# Player falls
	# -------------------------

	if player.global_position.y > 650:

		kill_player()


	queue_redraw()


# =========================
# PLAYER DEATH
# =========================

func kill_player():

	if game_over or won or changing_level:

		return


	lives -= 1


	# -------------------------
	# All lives lost
	# -------------------------

	if lives <= 0:

		game_over = true

		message = "LEVEL %d FAILED!" % current_level

		$Player.velocity = Vector2.ZERO

		queue_redraw()

		return


	# -------------------------
	# Respawn
	# -------------------------

	$Player.global_position = last_safe_position

	$Player.velocity = Vector2.ZERO

	message = "OUCH! Lives left: %d" % lives

	queue_redraw()


# =========================
# DIAMOND COLLECTION
# =========================

func collect_diamond():

	diamonds_collected += 1

	message = "Diamond collected! 💎"

	queue_redraw()


# =========================
# LEVEL COMPLETE
# =========================

func win_level():

	if won or game_over or changing_level:

		return


	changing_level = true


	# -------------------------
	# LEVEL 1 → LEVEL 2
	# -------------------------

	if current_level == 1:

		message = "LEVEL 2!"

		queue_redraw()

		call_deferred("_load_level_2")


	# -------------------------
	# LEVEL 2 → LEVEL 3
	# -------------------------

	elif current_level == 2:

		message = "LEVEL 3!"

		queue_redraw()

		call_deferred("_load_level_3")


	# -------------------------
	# LEVEL 3 → GAME COMPLETE
	# -------------------------

	else:

		won = true

		message = "GAME COMPLETE! 🎉"

		$Player.velocity = Vector2.ZERO

		changing_level = false

		queue_redraw()


# =========================
# LOAD LEVEL 2
# =========================

func _load_level_2():

	# Reset player
	$Player.global_position = Vector2(90, 430)

	$Player.velocity = Vector2.ZERO


	# Remove current level
	var old_level = $Level

	old_level.queue_free()


	# Wait one frame
	await get_tree().process_frame


	# Create Level 2
	var new_level := Node2D.new()

	new_level.name = "Level"

	new_level.set_script(
		load("res://Level2.gd")
	)

	add_child(new_level)


	# Reset Level 2 stats
	current_level = 2

	lives = 3

	diamonds_collected = 0

	level_start_time = Time.get_ticks_msec()

	last_safe_position = Vector2(90, 430)

	message = "LEVEL 2!"

	queue_redraw()


	# Small transition lock
	await get_tree().create_timer(0.2).timeout

	changing_level = false


# =========================
# LOAD LEVEL 3
# =========================

func _load_level_3():

	# Reset player
	$Player.global_position = Vector2(90, 430)

	$Player.velocity = Vector2.ZERO


	# Remove current level
	var old_level = $Level

	old_level.queue_free()


	# Wait one frame
	await get_tree().process_frame


	# Create Level 3
	var new_level := Node2D.new()

	new_level.name = "Level"

	new_level.set_script(
		load("res://Level3.gd")
	)

	add_child(new_level)


	# Reset Level 3 stats
	current_level = 3

	lives = 3

	diamonds_collected = 0

	level_start_time = Time.get_ticks_msec()

	last_safe_position = Vector2(90, 430)

	$Player.global_position = Vector2(90, 430)

	$Player.velocity = Vector2.ZERO

	message = "LEVEL 3!"

	queue_redraw()


	# Small transition lock
	await get_tree().create_timer(0.2).timeout

	changing_level = false


# =========================
# DEVELOPER LEVEL TESTING
# =========================

func test_level(level_number: int):

	if changing_level:

		return


	changing_level = true

	current_level = level_number

	lives = 3

	diamonds_collected = 0

	game_over = false

	won = false

	message = "TESTING LEVEL %d" % level_number


	# -------------------------
	# Remove current level
	# -------------------------

	var old_level = $Level

	old_level.queue_free()


	# Wait one frame
	await get_tree().process_frame


	# -------------------------
	# Create requested level
	# -------------------------

	var new_level := Node2D.new()

	new_level.name = "Level"


	var level_path = "res://Level%d.gd" % level_number


	# Level 1 uses Level.gd
	if level_number == 1:

		level_path = "res://Level.gd"


	var level_script = load(level_path)


	# Safety check
	if level_script == null:

		message = "Level %d not created yet!" % level_number

		changing_level = false

		queue_redraw()

		return


	new_level.set_script(level_script)

	add_child(new_level)


	# -------------------------
	# Reset player
	# -------------------------

	$Player.global_position = Vector2(90, 430)

	$Player.velocity = Vector2.ZERO

	last_safe_position = $Player.global_position

	level_start_time = Time.get_ticks_msec()


	queue_redraw()


	# Small transition lock
	await get_tree().create_timer(0.2).timeout

	changing_level = false


# =========================
# UI
# =========================

func _draw():

	# -------------------------
	# Background
	# -------------------------

	draw_rect(
		Rect2(0, 0, 960, 540),
		Color("#18202b")
	)


	# -------------------------
	# Game title
	# -------------------------

	draw_string(
		ThemeDB.fallback_font,
		Vector2(28, 35),
		"TRAP PLATFORMER",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		24,
		Color.WHITE
	)


	# -------------------------
	# Controls
	# -------------------------

	draw_string(
		ThemeDB.fallback_font,
		Vector2(28, 62),
		"A/D or ←/→ = Move     SPACE/W/↑ = Jump     R = Restart",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		Color("#b9c4d0")
	)


	# -------------------------
	# Level
	# -------------------------

	draw_string(
		ThemeDB.fallback_font,
		Vector2(430, 35),
		"Level %d" % current_level,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		20,
		Color.WHITE
	)


	# -------------------------
	# Lives
	# -------------------------

	draw_string(
		ThemeDB.fallback_font,
		Vector2(790, 35),
		"Lives: %d" % lives,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		20,
		Color("#ff6b81")
	)


	# -------------------------
	# Diamonds
	# -------------------------

	draw_string(
		ThemeDB.fallback_font,
		Vector2(790, 62),
		"Diamonds: %d / 3" % diamonds_collected,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		17,
		Color("#66d9ff")
	)


	# -------------------------
	# Message
	# -------------------------

	if message != "":

		draw_string(
			ThemeDB.fallback_font,
			Vector2(360, 90),
			message,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			20,
			Color("#ffd166")
		)


	# -------------------------
	# Level Failed
	# -------------------------

	if game_over:

		draw_rect(
			Rect2(260, 190, 440, 140),
			Color("#111820")
		)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(330, 245),
			"LEVEL FAILED!",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			38,
			Color("#ff6b81")
		)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(350, 280),
			"3 lives lost",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			20,
			Color.WHITE
		)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(330, 310),
			"Press R to restart Level %d" % current_level,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			18,
			Color.WHITE
		)


	# -------------------------
	# Game Complete
	# -------------------------

	if won:

		draw_rect(
			Rect2(260, 190, 440, 140),
			Color("#111820")
		)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(320, 245),
			"GAME COMPLETE!",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			36,
			Color("#7ee787")
		)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(370, 280),
			"You beat all levels!",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			20,
			Color.WHITE
		)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(365, 310),
			"Press R to play again",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			18,
			Color.WHITE
		)
