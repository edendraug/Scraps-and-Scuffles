extends Resource
class_name CharacterData

@export var character_name: String = "Character"
@export var character_scene: PackedScene # The full player character scene
@export var sprite_sheet: Texture2D # Full sprite sheet for gameplay
@export var icon_sprite: Texture2D # Static display icon
@export var portrait: Texture2D # Opional: For HUB/menus

# Future: Could add cosmetic variations, colors, etc.
# @export var skin_variants: Array[Texture2D] = []
