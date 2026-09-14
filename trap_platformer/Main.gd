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


func _ready():

	level_start_time = Time.get_ticks_msec()

	last_safe_position = $Player.global_position

	queue_redraw()


func _process(_delta):

	if Input.is_action_just_pressed("restart"):

		get_tree().reload_current_scene()

		return


	if game_over or won:

		return


	var player = $Player


	# Save player's latest safe position
	# when standing on a platform.

	if player.is_on_floor():

		last_safe_position = player.global_position


	# Fall death

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


	# 3 lives finished
	if lives <= 0:

		game_over = true

		message = "LEVEL 1 FAILED!"

		$Player.velocity = Vector2.ZERO

		queue_redraw()

		return


	# Respawn at last safe position
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


	var elapsed_seconds := (
		Time.get_ticks_msec()
		- level_start_time
	) / 1000.0


	var achievement := 1


	if elapsed_seconds < 35:

		achievement = 3

	elif elapsed_seconds < 55:

		achievement = 2


	message = "LEVEL COMPLETE! ⭐ x%d" % achievement

	queue_redraw()


	# For now Level 1 completion
	# will lead to Level 2.

	if current_level == 1:

		current_level = 2

		call_deferred("_load_level_2")

	else:

		won = true

		$Player.velocity = Vector2.ZERO

		changing_level = false

		queue_redraw()


# =========================
# LOAD LEVEL 2
# =========================

func _load_level_2():

	$Player.global_position = Vector2(90, 430)

	$Player.velocity = Vector2.ZERO


	# Remove old level

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

	lives = 3

	diamonds_collected = 0

	level_start_time = Time.get_ticks_msec()

	last_safe_position = Vector2(90, 430)

	message = "LEVEL 2!"

	changing_level = false

	queue_redraw()


# =========================
# UI
# =========================

func _draw():

	# Background

	draw_rect(
		Rect2(0, 0, 960, 540),
		Color("#18202b")
	)


	# Game title

	draw_string(
		ThemeDB.fallback_font,
		Vector2(28, 35),
		"TRAP PLATFORMER",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		24,
		Color.WHITE
	)


	# Controls

	draw_string(
		ThemeDB.fallback_font,
		Vector2(28, 62),
		"A/D or ←/→ = Move     SPACE/W/↑ = Jump     R = Restart",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		Color("#b9c4d0")
	)


	# Level

	draw_string(
		ThemeDB.fallback_font,
		Vector2(430, 35),
		"Level %d" % current_level,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		20,
		Color.WHITE
	)


	# Lives

	draw_string(
		ThemeDB.fallback_font,
		Vector2(790, 35),
		"Lives: %d" % lives,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		20,
		Color("#ff6b81")
	)


	# Diamonds

	draw_string(
		ThemeDB.fallback_font,
		Vector2(790, 62),
		"Diamonds: %d / 3" % diamonds_collected,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		17,
		Color("#66d9ff")
	)


	# Message

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


	# Game over

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
			"Press R to restart Level 1",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			18,
			Color.WHITE
		)


	# Game complete

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