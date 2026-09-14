extends Node2D

var lives := 3
var won := false
var game_over := false
var message := ""

var current_level := 1
var changing_level := false


func _ready():
	queue_redraw()


func _process(_delta):
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()

	if game_over or won:
		return

	var player = $Player

	if player.global_position.y > 650:
		kill_player()


func kill_player():
	if game_over or won or changing_level:
		return

	lives -= 1

	if lives <= 0:
		game_over = true
		message = "LIVES OVER!"
		$Player.velocity = Vector2.ZERO
		queue_redraw()
		return

	$Player.global_position = Vector2(90, 430)
	$Player.velocity = Vector2.ZERO
	message = "OUCH! Try again..."
	queue_redraw()


func win_level():
	# Never allow a second win during transition
	if won or game_over or changing_level:
		return

	if current_level == 1:
		changing_level = true

		# Immediately move player away from Level 1 exit
		$Player.global_position = Vector2(90, 430)
		$Player.velocity = Vector2.ZERO

		message = "LEVEL 2!"
		queue_redraw()

		call_deferred("_load_level_2")

	else:
		won = true
		message = "GAME COMPLETE! 🎉"
		$Player.velocity = Vector2.ZERO
		queue_redraw()


func _load_level_2():
	# Remove Level 1
	var old_level = $Level
	old_level.queue_free()

	# Wait until Level 1 is completely removed
	await get_tree().process_frame

	# Create Level 2
	var new_level := Node2D.new()
	new_level.name = "Level"
	new_level.set_script(load("res://Level2.gd"))
	add_child(new_level)

	# Make absolutely sure player starts at Level 2 start
	$Player.global_position = Vector2(90, 430)
	$Player.velocity = Vector2.ZERO

	current_level = 2

	message = "LEVEL 2!"

	queue_redraw()

	# Keep transition locked briefly
	await get_tree().create_timer(0.2).timeout

	changing_level = false


func _draw():
	# Background
	draw_rect(
		Rect2(0, 0, 960, 540),
		Color("#18202b")
	)

	# Title
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

	# Level number
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
		Vector2(820, 35),
		"Lives: %d" % lives,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		20,
		Color("#ff6b81")
	)

	# Message
	if message != "":
		draw_string(
			ThemeDB.fallback_font,
			Vector2(380, 85),
			message,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			20,
			Color("#ffd166")
		)

	# Game Over
	if game_over:
		draw_rect(
			Rect2(260, 190, 440, 140),
			Color("#111820")
		)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(350, 245),
			"GAME OVER!",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			40,
			Color("#ff6b81")
		)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(370, 275),
			"LIVES OVER",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			20,
			Color.WHITE
		)

		draw_string(
			ThemeDB.fallback_font,
			Vector2(330, 305),
			"Press R to try again",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			18,
			Color.WHITE
		)

	# Game Complete
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
