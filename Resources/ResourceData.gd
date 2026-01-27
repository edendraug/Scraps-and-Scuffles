extends Resource
class_name CraftableResource

#Values
@export var display_name: String
@export var display_description: String
@export var pickup_scene: PackedScene
@export var variations: int = 1 # The number of frames the sprite has (used to generate random sprite for pickups)
@export var animated: bool = false

@export var icon: Texture2D
