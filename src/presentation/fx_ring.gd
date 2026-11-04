extends Node2D
## Anneau dessiné (utilisé par Fx.ring).

var color: Color = Color.WHITE
var width: float = 8.0
var radius: float = 4.0:
	set(v):
		radius = v
		queue_redraw()


func _draw() -> void:
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, color, width, true)
