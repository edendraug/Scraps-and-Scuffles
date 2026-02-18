extends VisibleOnScreenNotifier2D
class_name OffscreenMarker

@export var icon: Texture2D
@export var indicator_color: Color = Color.WHITE
@export var outline_color: Color = Color.BLACK
@export var enabled: bool = true
@export var detection_margin: float = 70.0

var is_animated_icon: bool = false

func _ready() -> void:
	# Expand the dectection rect to create a buffer
	rect = Rect2(-detection_margin, -detection_margin, detection_margin * 2, detection_margin * 2)
	if not enabled:
		return
	
	call_deferred("_setup_signals")

func _setup_signals() -> void:
	screen_entered.connect(_on_screen_entered)
	screen_exited.connect(_on_screen_exited)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Check initial state
	if not is_on_screen():
		_on_screen_exited()

func _on_screen_entered() -> void:
	if not enabled:
		return
	OffscreenManager.remove_indicator(self)

func _on_screen_exited() -> void:
	if not enabled:
		return
	OffscreenManager.create_indicator(self)

func get_world_position() -> Vector2:
	return get_parent().global_position

func update_icon() -> Texture2D:
	for child in get_parent().get_children():
		if child is AnimatedSprite2D:
			var current_anim = child.animation
			var current_frame = child.frame
			return child.get_sprite_frames().get_frame_texture(current_anim, current_frame)
	return icon

func get_icon() -> Texture2D:
	# Use assigned icon first
	if icon:
		return icon
		
	# Try to find Sprite2D on parent
	var parent = get_parent()
	if parent.is_in_group("Players"):
		if parent.character_data:
			return parent.character_data.portrait
	elif parent is Sprite2D or parent is AnimatedSprite2D:
		return parent.texture
	
	for child in parent.get_children():
		if child is Sprite2D: # Static Sprite
			return child.texture
		elif child is AnimatedSprite2D: # Animated Sprite
			is_animated_icon = true
			var current_anim = child.animation
			var current_frame = child.frame
			return child.get_sprite_frames().get_frame_texture(current_anim, current_frame)
	
	# Fallback to default
	return load("res://icon.svg")
