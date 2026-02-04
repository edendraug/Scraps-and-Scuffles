extends Node2D

@onready var player : CharacterBody2D = get_parent()
@onready var anim : AnimationPlayer = get_node("AnimationPlayer")
@onready var anim_tree : AnimationTree = get_node("AnimationTree")

@onready var sub_viewport: SubViewport = $SubViewport
@onready var rendered_sprite: Sprite2D = $RenderedSprite

func _ready() -> void:	
	rendered_sprite.texture = sub_viewport.get_texture()

func _process(delta: float) -> void:
	update_animations()

func update_animations():
	anim_tree["parameters/look_direction/blend_position"] = player.input_dir.y
	
	if not player.is_on_floor():
		anim_tree["parameters/hit_direction/blend_position"] = Vector2.ZERO
	
	match player.current_state:
		player.State.IDLE, player.State.LOOK_UP, player.State.CROUCH:
			anim_tree["parameters/states/transition_request"] = "idle"
			anim_tree["parameters/hit_direction/blend_position"] = player.input_dir.y
		player.State.MOVE:
			anim_tree["parameters/states/transition_request"] = "move"
		player.State.JUMP, player.State.FALL:
			anim_tree["parameters/jump_velocity/blend_position"] = player.velocity.y
			anim_tree["parameters/states/transition_request"] = "jumping"
		player.State.SLIDE:
			anim_tree["parameters/states/transition_request"] = "slide"

func set_sprite_sheet(new_sprite_sheet: Texture2D):
	if not new_sprite_sheet:
		push_warning("PlayerSpriteManager: No sprite sheet provided")
		return
	
	# Find all Sprite2D nodes that need updating
	var sprites_to_update = []
	
	# Look in SubViewport for sprites
	if sub_viewport: 
		for child in sub_viewport.find_children("*", "", true):
			if child is Sprite2D:
				sprites_to_update.append(child)
	
	# Update all found sprites
	for sprite in sprites_to_update:
		sprite.texture = new_sprite_sheet
	
	print ("PlayerSpriteManager: Sprite sheet updated to ", new_sprite_sheet.resource_path)

func _on_player_just_hit() -> void:
	anim_tree.set("parameters/hit/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
