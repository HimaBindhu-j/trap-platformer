extends Node2D

var deaths := 0
var won := false
var message := ""

func _ready():
	queue_redraw()

func _process(_delta):
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()

	var player = $Player
	if player.global_position.y > 650:
		deaths += 1
		player.global_position = Vector2(90, 430)
		player.velocity = Vector2.ZERO
		message = "OUCH! Try again..."
		queue_redraw()

	if player.global_position.x > 880 and not won:
		won = true
		message = "LEVEL COMPLETE! 🎉"
		player.velocity = Vector2.ZERO
		queue_redraw()
func kill_player():
	deaths += 1
	$Player.global_position = Vector2(90, 430)
	$Player.velocity = Vector2.ZERO
	message = "OUCH! Try again..."
	queue_redraw()

func _draw():
	draw_rect(Rect2(0, 0, 960, 540), Color("#18202b"))
	draw_string(ThemeDB.fallback_font, Vector2(28, 35),
		"TRAP PLATFORMER", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(28, 62),
		"A/D or ←/→ = Move     SPACE/W/↑ = Jump     R = Restart",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#b9c4d0"))

	if message != "":
		draw_string(ThemeDB.fallback_font, Vector2(330, 55),
			message, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#ffd166"))

		draw_string(ThemeDB.fallback_font, Vector2(28, 530),
		   "Deaths: %d" % deaths, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#ff8fa3"))

	if won:
		draw_rect(Rect2(260, 190, 440, 110), Color("#111820"))
		draw_string(ThemeDB.fallback_font, Vector2(350, 245),
			"YOU WIN!", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color("#7ee787"))
		draw_string(ThemeDB.fallback_font, Vector2(320, 275),
			"Press R to play again", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
