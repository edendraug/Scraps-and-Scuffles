extends Resource
class_name BuildingData

#Values
@export var object_name: String
@export var object_description: String
@export var health: int
enum Type {Natural, Building}
@export var object_type := Type.Natural
@export var drop_resource : CraftableResource
@export var drop_amount : int

#Textures
@export var world_texture: Texture2D
@export var ui_texture: Texture2D
