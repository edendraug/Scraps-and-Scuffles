extends Node2D
class_name OffscreenIndicator

const MARGIN: float = 50.0
const CIRCLE_RADIUS: float = 24.0
const ARROW_LENGTH: float = 16.0
const ARROW_WIDTH: float = 12.0

var marker: OffscreenMarker
var indicator_color: Color
var outline_color: Color
var icon_texture: Texture2D

func setup(target_marker: OffscreenMarker) -> void:
	marker = target_marker
	indicator_color = marker.indicator_color
	outline_color = marker.outline_color
	icon_texture = marker.get_icon()
	
	# Tween in
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func hide_and_queue_free() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)

func _process(delta: float) -> void:
	if not is_instance_valid(marker):
		queue_free()
		return
	
	update_position()
	queue_redraw()
	if marker.is_animated_icon:
		icon_texture = marker.update_icon()
		print("updating icon...")

func update_position() -> void:
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return
	
	var viewport_size = get_viewport_rect().size
	var target_pos = marker.get_world_position()
	var camera_pos = camera.get_screen_center_position()
	var camera_zoom = camera.zoom
	
	# Convert world position to screen position
	var screen_pos = (target_pos - camera_pos) * camera_zoom + viewport_size / 2
	
	# Clamp to screen edges with marign
	var clamped_pos = Vector2(
		clamp(screen_pos.x, MARGIN, viewport_size.x - MARGIN),
		clamp(screen_pos.y, MARGIN, viewport_size.y - MARGIN)
	)
	
	global_position = clamped_pos


func _draw() -> void:
	if not is_instance_valid(marker):
		return
	
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return
	
	var viewport_size = get_viewport_rect().size
	var target_pos = marker.get_world_position()
	var camera_pos = camera.get_screen_center_position()
	var camera_zoom = camera.zoom
	
	# Get direction to target
	var screen_target = (target_pos - camera_pos) * camera_zoom + viewport_size / 2
	var direction = (screen_target - global_position).normalized()
	var arrow_angle = direction.angle()
	
	# Arrow points
	var arrow_tip = direction * (CIRCLE_RADIUS + ARROW_LENGTH)
	var perpendicular = Vector2(-direction.y, direction.x) * (ARROW_WIDTH / 2)
	var arrow_left = direction * CIRCLE_RADIUS + perpendicular
	var arrow_right = direction * CIRCLE_RADIUS - perpendicular
	
	# Build combined outline
	var outline_points = PackedVector2Array()
	
	# Start from right side of arrow base, go around circle, end at left side
	var spread_angle = atan2(ARROW_WIDTH / 2, CIRCLE_RADIUS)
	var start_angle = arrow_angle - spread_angle
	var end_angle = arrow_angle + spread_angle
	
	outline_points.append(arrow_right)
	outline_points.append(arrow_tip)
	outline_points.append(arrow_left)
	
	# Add circle arc
	var segments = 32
	for i in range(segments + 1):
		var t = float(i) / segments
		var angle = end_angle + t * (TAU - (end_angle - start_angle))
		if angle > TAU:
			angle -= TAU
		outline_points.append(Vector2(cos(angle), sin(angle)) * CIRCLE_RADIUS)
	
	# Draw filled shape
	draw_colored_polygon(outline_points, indicator_color)
	
	# Draw outline
	draw_polyline(outline_points, outline_color, 4.0, true)
	
	# Draw icon
	if icon_texture:
		var icon_size = icon_texture.get_size()
		var scale_factor = (CIRCLE_RADIUS * 1.4) / max(icon_size.x, icon_size.y)
		var scaled_size = icon_size * scale_factor
		var icon_rect = Rect2(-scaled_size / 2, scaled_size)
		draw_texture_rect(icon_texture, icon_rect, false)
