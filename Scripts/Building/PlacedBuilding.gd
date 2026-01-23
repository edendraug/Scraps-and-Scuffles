@tool
extends StaticBody2D
class_name PlacedBuilding

@export var building_data: BuildingData:
	set(value):
		building_data = value
		if Engine.is_editor_hint():
			update_collision_from_data()
	get:
		return building_data

@export var create_hit_detection_area: bool = true
@export var damage_texture: Texture2D # Damage sprite sheet
@export var damage_shader: Shader
@export var particle_emitter: CPUParticles2D

var current_health: int
var grid_position: Vector2i
var hit_area: Area2D
var building_sprite: Sprite2D
var damage_material: ShaderMaterial

var initialized : bool = false

func _ready() -> void:
	# Initialize health if building_data is already set in editor/inspector
	if building_data:
		if not Engine.is_editor_hint():
			initialize(building_data)
		else:
			update_collision_from_data()

func find_sprite() -> Sprite2D:
	# Look for Sprite2D child
	for child in get_children():
		if child is Sprite2D:
			return child
	return null

func initialize(data: BuildingData):
	building_data = data
	current_health = data.max_health
	building_sprite = find_sprite()
	if particle_emitter and data.particle_texture:
		particle_emitter.texture = data.particle_texture
	
	add_to_group("Buildings")
	
	# Store grid position for later reference
	grid_position = BuildingManager.world_to_grid(global_position)
	
	# Generate collision at runtime
	update_collision_from_data()
	
	# Setup damage shader
	setup_damage_shader()
	initialized = true


func take_damage(amount: int, hit_pos: Vector2) -> void:
	print(self.name, ": I got hit for %s damage." % amount)
	print(self.name, ": %s health remaining." % current_health)
	current_health -= amount
	
	# Update damage shader
	update_damage_visual()
	
	# Visual feedback (flash white or shake)
	damage_feedback()
	
	if current_health <= 0:
		destroy()

func damage_feedback():
	#Simple white flash effect
	var original_modulate = modulate
	modulate = Color(2, 2, 2, 1)
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self):
		modulate = original_modulate
	
	# Emit particles
	if particle_emitter:
		particle_emitter.emitting = true

func destroy():
	# Drop resources (partial refund)
	drop_resources()
	
	# Unregister from BuildingManager
	BuildingManager.unregister_building(self)
	
	#Destruction effect (optional - add particles, sound etc.)
	destruction_effect()
	
	queue_free()

func drop_resources():
	if not building_data or not building_data.drop_resources_on_destroy:
		return
	
	# Calculate drop percentage based on building type
	var drop_percent = building_data.get_grop_percentage()
	
	var wood_drop = int(building_data.wood_cost * drop_percent)
	var stone_drop = int(building_data.stone_cost * drop_percent)
	var energy_drop = int(building_data.energy_cost * drop_percent)
	
	# Spawn resource pickups at this position
	if wood_drop > 0:
		spawn_resource_pickup("wood", wood_drop)
	if stone_drop > 0:
		spawn_resource_pickup("stone", stone_drop)
	if energy_drop > 0:
		spawn_resource_pickup("energy", energy_drop)

func spawn_resource_pickup(resource_type: String, amount: int):
	var resource_data = InventoryManager.get_resource_by_name(resource_type)
	if not resource_data or not resource_data.pickup_scene:
		push_warning("PlacedBuilding: Cannot spawn pickup for '%s' - missing resource data or pickup scene" % resource_type)
		return
	
	# Spawn each pickup with slight random offset
	for i in range(amount):
		var pickup = resource_data.pickup_scene.instantiate()
		get_tree().current_scene.add_child(pickup)
		
		#Random offset so pickups don't stack perfectly
		var offset = Vector2(randf_range(-20,20), randf_range(-20,20))
		pickup.global_position = global_position + offset
		
		if pickup.has_method("setup"):
			pickup.setup(resource_data)

func destruction_effect():
	if particle_emitter:
		particle_emitter.emitting = true
	
# Optional: Add method to repair/heal the building
func repair(amount: float):
	pass

func setup_damage_shader():
	print("setup_damage_shader called")
	print("  building sprite: ", building_sprite)
	print(" damage_shader: ", damage_shader)
	print("  damage_texture: ", damage_texture)
	
	if not building_sprite or not damage_shader or not damage_texture:
		return
	
	# Create shader material
	damage_material = ShaderMaterial.new()
	damage_material.shader = damage_shader
	
	# Set shader parameters
	damage_material.set_shader_parameter("damage_texture", damage_texture)
	damage_material.set_shader_parameter("damage_percent", 0.0)
	damage_material.set_shader_parameter("total_frames", 6)
	damage_material.set_shader_parameter("damage_frame_size", Vector2(16, 16))
	damage_material.set_shader_parameter("enable_color_shift", false)
	damage_material.set_shader_parameter("blend_strength", 0.8)
	
	# Apply material to sprite
	building_sprite.material = damage_material
	print("  Damage shader applied successfully!")

func update_damage_visual():
	if not damage_material or not building_data:
		print("update_damage_visual: Missing material or building_data")
		return
	
	# Calculate damage percentage (0.0 = full health, 1.0 = destroyed)
	var damage_percent = 1.0 - (float(current_health) / float(building_data.max_health))
	damage_percent = clamp(damage_percent, 0.0, 1.0)
	
	print("Updating damage visual: ", damage_percent, " (health: ", current_health, "/", building_data.max_health, ")")
	
	# Update shader paramter
	damage_material.set_shader_parameter("damage_percent", damage_percent)

func update_collision_from_data():
	if not building_data:
		return
	
	# Clear existing auto-generated collision shapes
	for child in get_children():
		if child is CollisionShape2D and child.has_meta("auto_generated"):
			child.queue_free()
		if child is Area2D and child.has_meta("auto_generated"):
			child.queue_free()
	
	# Get occupied cells from building data
	var occupied_cells = building_data.get_occupied_cells()
	
	if occupied_cells.is_empty():
		return
		
	# Get grid size from BuildingManager (or default if in editor)
	var grid_size = 32
	if not Engine.is_editor_hint() and BuildingManager:
		grid_size = BuildingManager.grid_size
	
	if create_hit_detection_area:
		hit_area = Area2D.new()
		hit_area.set_meta("auto_generated_hit_are", true)
		hit_area.name = "HitDetectionArea"
		add_child(hit_area)
	
	# Set collision layers/masks for hit detection
	# Adjust these to match you project's layer setup
	hit_area.collision_layer = 3
	hit_area.collision_mask = 0
	
	if Engine.is_editor_hint() and get_tree().edited_scene_root:
		hit_area.owner = get_tree().edited_scene_root
	
	
	# Create collision shape for each occupied cell
	for cell_offset in occupied_cells:
		var collision = CollisionShape2D.new()
		collision.set_meta("auto_generated", true)
		# Create a rectangle shape for this grid cell
		var shape = RectangleShape2D.new()
		shape.size = Vector2(grid_size, grid_size)
		collision.shape = shape
		# Position the collision shape
		collision.position = Vector2(cell_offset.x * grid_size, cell_offset.y * grid_size)
		add_child(collision)
		
		# In editor, set owner so it saves with the scene
		if Engine.is_editor_hint() and get_tree().edited_scene_root:
			collision.owner = get_tree().edited_scene_root
		
		if create_hit_detection_area and hit_area:
			var hit_collision = CollisionShape2D.new()
			hit_collision.set_meta("auto_generated", true)
			var hit_shape = RectangleShape2D.new()
			hit_shape.size = Vector2(grid_size, grid_size)
			hit_collision.shape = hit_shape
			# Position the collision shape
			hit_collision.position = Vector2(cell_offset.x * grid_size, cell_offset.y * grid_size)
			hit_area.add_child(hit_collision)
