extends Node2D
class_name Pedestal

@export var player_name_label: Label
@export var platform_top_sprite: Sprite2D # The top platform that stays fixed
@export var column_sprite: Sprite2D # The stretchable middle part (have region enabled)
@export var base_sprite: Sprite2D # Optional bottom platform that stays fixed

@export var initial_column_height: float = 32.0 # Starting height of column

var player_id: int = -1
var character_name: String = ""

func _ready() -> void:
	# Store initial column height if not set
	if column_sprite and not column_sprite.region_enabled:
		push_warning("Pedestal column_sprite should have 'Region Enabled' for proper stretching!")

func setup(pid: int, char_name: String):
	player_id = pid
	character_name = char_name
	
	# Update label
	if player_name_label:
		if character_name.is_empty():
			player_name_label.text = "Player " + str(player_id + 1)
		else:
			player_name_label.text = character_name
	
	print("Pedestal setup for Player ", player_id, " (", character_name, ")")

func grow_to_height(height_increase: float, duration: float) -> Tween:
	print("=== GROW TO HEIGHT CALLED ===")
	print("  Height increase: ", height_increase)
	print("  Duration: ", duration)
	print("  Column sprite: ", column_sprite)
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	
	# Get initial column height
	if column_sprite and column_sprite.texture:
		var initial_height = column_sprite.texture.get_height()
		var new_total_height = (initial_height + height_increase)
		var scale_factor = new_total_height / initial_height
		
		print("  Initial height: ", initial_height)
		print("  New total height: ", new_total_height)
		print("  Scale factor: ", scale_factor)
		
		# Scale column
		var scale_tween = tween.tween_property(column_sprite, "scale:y", scale_factor, duration)
		scale_tween.finished.connect(func(): print("  Column scale tween finished! Final scale.y: ", column_sprite.scale.y))
		
		# If centered, we need to move the sprite up as it scales to keep bottom anchored
		if column_sprite.centered:
			# Calculate how much the center moves up when scaling
			var center_offset = height_increase / 2.0
			var new_y_pos = column_sprite.position.y - center_offset
			tween.parallel().tween_property(column_sprite, "position:y", new_y_pos, duration)
			print("  Moving column center from ", column_sprite.position.y, " to ", new_y_pos)
	else:
		print("  ERROR: No column sprite or texture!")
	
	# Move platform top sprite upward
	if platform_top_sprite:
		var top_target = platform_top_sprite.position + Vector2(0, -height_increase)
		print("  Moving top from ", platform_top_sprite.position, " to ", top_target)
		tween.parallel().tween_property(platform_top_sprite, "position", top_target, duration)
	
	# Move label upward
	if player_name_label:
		var label_target = player_name_label.position + Vector2(0, -height_increase * 2)
		tween.parallel().tween_property(player_name_label, "position", label_target, duration)
	
	return tween

# Alternative method for parallel animation - adds to existing tween
func grow_to_height_parallel(height_increase: float, duration: float, tween: Tween):
	# Get initial column height
	if column_sprite and column_sprite.texture:
		var initial_height = column_sprite.texture.get_height()
		var new_total_height = initial_height + height_increase
		var scale_factor = new_total_height / initial_height
		
		# Scale column (tween is already in parallel mode)
		tween.tween_property(column_sprite, "scale:y", scale_factor, duration)
		
		# If centered, move the sprite up as it scales
		if column_sprite.centered:
			var center_offset = height_increase / 2.0
			var new_y_pos = column_sprite.position.y - center_offset
			tween.tween_property(column_sprite, "position:y", new_y_pos, duration)
	
	# Move platform top sprite upward
	if platform_top_sprite:
		var top_target = platform_top_sprite.position + Vector2(0, -height_increase)
		tween.tween_property(platform_top_sprite, "position", top_target, duration)
	
	# Move label upward
	if player_name_label:
		var label_target = player_name_label.position + Vector2(0, -height_increase * 2)
		tween.tween_property(player_name_label, "position", label_target, duration)
