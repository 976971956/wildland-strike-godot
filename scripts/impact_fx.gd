extends Node2D

var life := 0.24
var max_life := 0.24
var strength := 1
var direction := 1
var color := Color("#eaf8ee")
var core_color := Color("#fff7d1")
var impact_scale := 1.0
var ray_count_bonus := 0
var profile_id: StringName = &"fallback"

func setup(p_strength: int = 1, p_direction: int = 1, profile: Resource = null) -> void:
	strength = clampi(p_strength, 1, 3)
	direction = 1 if p_direction >= 0 else -1
	max_life = [0.18, 0.23, 0.29][strength - 1]
	life = max_life
	color = [Color("#eaf8ee"), Color("#ffd65c"), Color("#ff8a45")][strength - 1]
	if profile != null:
		profile_id = profile.profile_id
		color = profile.burst_color
		core_color = profile.core_color
		impact_scale = profile.impact_scale
		ray_count_bonus = profile.ray_count_bonus
	scale = Vector2.ONE * 0.42 * impact_scale
	rotation = direction * -0.045

func _process(delta: float) -> void:
	life -= delta
	var progress := 1.0 - life / max_life
	rotation += delta * direction * 1.8
	var punch_scale := lerpf(0.42, 1.35 + strength * 0.12, minf(progress * 4.8, 1.0)) * impact_scale
	scale = Vector2.ONE * punch_scale
	modulate.a = pow(clampf(life / max_life, 0.0, 1.0), 0.72)
	queue_redraw()
	if life <= 0.0:
		queue_free()

func _draw() -> void:
	var rays := 7 + strength * 3 + ray_count_bonus
	var outer := 20.0 + strength * 10.0
	for i in range(rays):
		var a := TAU * i / rays + 0.13
		var ray_length := outer * (1.0 if i % 2 == 0 else 0.64)
		draw_line(Vector2.from_angle(a) * 7.0, Vector2.from_angle(a) * ray_length, color, 3.0 + strength)
	# A directional white slash gives the impact a readable leading edge.
	var slash_from := Vector2(-direction * (16.0 + strength * 4.0), -18.0)
	var slash_to := Vector2(direction * (18.0 + strength * 7.0), 18.0)
	draw_line(slash_from, slash_to, Color(1, 1, 1, 0.96), 6.0 + strength * 2.0)
	draw_line(slash_from + Vector2(0, 6), slash_to + Vector2(0, 6), color, 3.0 + strength)
	draw_arc(Vector2.ZERO, 12.0 + strength * 4.0, 0, TAU, 24, Color(color, 0.72), 3.0)
	draw_circle(Vector2.ZERO, 6.0 + strength * 1.8, core_color)
