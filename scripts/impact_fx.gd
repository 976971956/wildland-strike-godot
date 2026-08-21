extends Node2D

var life := 0.28
var color := Color.WHITE

func setup(p_color: Color = Color.WHITE) -> void:
	color = p_color

func _process(delta: float) -> void:
	life -= delta
	rotation += delta * 5.0
	scale += Vector2.ONE * delta * 2.5
	modulate.a = clamp(life / 0.28, 0.0, 1.0)
	queue_redraw()
	if life <= 0.0:
		queue_free()

func _draw() -> void:
	for i in range(8):
		var a := TAU * i / 8.0
		draw_line(Vector2.from_angle(a) * 5.0, Vector2.from_angle(a) * 24.0, color, 5.0)
	draw_circle(Vector2.ZERO, 7, Color("#fff3bd"))

