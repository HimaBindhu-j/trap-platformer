extends CharacterBody2D

const SPEED := 260.0
const JUMP := -470.0
const GRAVITY := 1200.0

func _ready():
    queue_redraw()

func _physics_process(delta):
    if not is_on_floor():
        velocity.y += GRAVITY * delta

    var dir := Input.get_axis("move_left", "move_right")
    velocity.x = move_toward(velocity.x, dir * SPEED, 1400.0 * delta)

    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = JUMP

    move_and_slide()
    queue_redraw()

func _draw():
    draw_rect(Rect2(-14, -20, 28, 40), Color("#5ee7df"))
    draw_circle(Vector2(-6, -6), 3, Color("#18202b"))
    draw_circle(Vector2(6, -6), 3, Color("#18202b"))
    draw_line(Vector2(-7, 7), Vector2(7, 7), Color("#18202b"), 2)
