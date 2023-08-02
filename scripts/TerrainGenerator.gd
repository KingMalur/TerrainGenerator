@tool
extends Node3D


## TERRAIN GENERATOR
##
## Generates a chunked mesh-array based terrain.
## Can also create a navigation meshes and collision shapes based on that terrain.

signal terrain_generated
signal water_mesh_generated
signal collision_mesh_generated
signal navigation_regions_generated

const CENTER_OFFSET: float = 0.5

@export_category("DEBUG")
## Creates a base mesh, collisions, nav-mesh & water at start of the scene
@export var d_create_on_start: bool = false
## Always create a new seed on start
@export var d_new_seed_on_start: bool = false
## Prints out various information like chunk-size, chunk-positions, etc.
@export var d_print_values: bool = false
## Prints out vertex-/uv-positions, etc. (can fill up the print queue!)
@export var d_print_granular_values: bool = false
## Ignores the max_terrain_height setting
@export var d_ignore_max_terrain_height: bool = false

@export_category("Workflow")
@export var reset_all: bool = false: set = _set_reset_all
@export var create_new_terrain: bool = false: set = _create_new_terrain
@export var create_water_mesh: bool = false: set = _create_water_mesh
@export var create_collision_mesh: bool = false: set = _create_collision_mesh
@export var create_navigation_region: bool = false: set = _create_navigation_region

@export_category("Noise Configuration")
@export var noise_seed: int = 0: set = _apply_noise_seed
@export var generate_new_seed: bool = false: set = _generate_new_seed
@export var generate_terrain_on_new_seed: bool = true
@export var noise_offset: float = 0.1
## Controls the ROUGHNESS of the terrain mesh on the y-axis
## Try to balance noise_height_modifier & heightmap_modifier!
@export var noise_height_modifier: float = 20.0
@export var noise_frequency: float = 0.25
@export var noise_type = FastNoiseLite.TYPE_VALUE_CUBIC

@export_category("Terrain Configuration")
@export var center_terrain: bool = false
@export_enum("16:16", "32:32", "64:64") var chunk_size: int = 16
@export_range(64, 1024, 64) var terrain_x_size: int = 64
@export_range(64, 1024, 64) var terrain_z_size: int = 64
## How many substeps should be performed in one/1 "unit of mesh" (1: 1u = 1 side, 4: 1u = 4 sides)
@export_enum("1:1", "2:2", "4:4") var terrain_resolution: int = 1
## How "big" one unit in Godot should be -> 1:16 max to really stretch terrain (might look bad..)
@export_range(1, 16, 1) var terrain_unit_size: int = 1
## The generated terrains maximum height
@export var max_terrain_height: float = 10.0
## Eases the generated heights towards the maximum height
@export var ease_towards_max_terrain_height: bool = false
## The curve used to ease towards max_terrain_height
## Reference: https://raw.githubusercontent.com/godotengine/godot-docs/master/img/ease_cheatsheet.png
@export var easing_curve_max_terrain_height: Curve
## Eases towards the edge of the mesh (to generate islands)
@export var ease_towards_edge: bool = false
## Teh curve used to ease towards the edge of the mesh
@export var easing_curve_edge: Curve

@export_category("Heightmap Configuration")
@export var sample_heightmap: bool = false
## Modifies the HEIGHT based on the HEIGHTMAP of the terrain mesh on the y-axis
## Try to balance heightmap_modifier & noise_height_modifier!
@export var heightmap_modifier: float = 10.0
@export var heightmap_tex: Texture2D

@export_category("Name Configuration")
@export var chunk_base_name: String = "Chunk at "
@export var navigation_region_base_name: String = "Nav-Region #"
@export var collision_mesh_base_name: String = "Col-Mesh #"
@export var collision_shape_base_name: String = "Col-Shape #"
@export var water_mesh_base_name: String = "Water-Mesh #"

@export_category("Misc Configuration")
@export var shader_material: ShaderMaterial
@export var navigation_mesh: NavigationMesh

var _fast_noise_lite: FastNoiseLite

var _water_mesh_created: bool = false

var _is_editor: bool = OS.has_feature("editor")

var _start_time: int = 0
var _stop_time: int = 0


func _ready() -> void:
	if _is_editor:
		return
	
	if d_create_on_start:
		# To get some information about the generated mesh at runtime
		d_print_values = true
		# To avoid a re-creation of the terrain
		generate_terrain_on_new_seed = false
		if d_new_seed_on_start:
			_generate_new_seed()
		_create_new_terrain()
		_create_water_mesh()
		_create_navigation_region()
		_create_collision_mesh()


@warning_ignore("unused_parameter")
func _update(delta) -> void:
	pass


@warning_ignore("unused_parameter")
func _set_reset_all(new_value: bool = false) -> void:
	print("Resetting..")
	_start_timer()
	
	_delete_all()
	
	_stop_timer()
	
	reset_all = false


@warning_ignore("unused_parameter")
func _create_new_terrain(new_value: bool = false) -> void:
	print("Generating terrain..")
	_start_timer()
	
	_delete_all()
	_generate_terrain()
	
	terrain_generated.emit()
	_stop_timer()
	
	create_new_terrain = false


@warning_ignore("unused_parameter")
func _create_collision_mesh(new_value: bool = false) -> void:
	print("Creating collision mesh..")
	_start_timer()
	
	_delete_collision_meshes()
	
	var count = 0
	for child in get_children():
		# Filter for chunk-objects
		if !child.name.begins_with(chunk_base_name):
			continue
		
		# Create static_body for attaching collision_shape
		var static_body = StaticBody3D.new()
		var tmp_collision_mesh_base_name = collision_mesh_base_name + "%s"
		static_body.name = tmp_collision_mesh_base_name % count
		add_child(static_body)
		if _is_editor:
			static_body.set_owner(get_tree().edited_scene_root)
		# Create collision_shape and add as child of static_body
		var collision_shape = CollisionShape3D.new()
		var tmp_collision_shape_name = collision_shape_base_name + "%s"
		collision_shape.name = tmp_collision_shape_name % count
		static_body.add_child(collision_shape)
		if _is_editor:
			collision_shape.set_owner(get_tree().edited_scene_root)
		
		# Create collision_shape
		var mesh: Mesh = child.mesh
		if mesh:
			collision_shape.shape = mesh.create_trimesh_shape()
		
		count += 1
	
	collision_mesh_generated.emit()
	_stop_timer()
	
	create_collision_mesh = false


func _delete_collision_meshes():
	for child in get_children():
		# Filter for collision_mesh-objects
		if !child.name.begins_with(collision_mesh_base_name):
			continue
		child.free()


@warning_ignore("unused_parameter")
func _create_navigation_region(new_value: bool = false) -> void:
	print("Creating navigation regions..")
	_start_timer()
	
	_delete_navigation_regions()
	
	var count = 0
	for child in get_children():
		# Filter for chunk-objects
		if !child.name.begins_with(chunk_base_name):
			continue
		
		# Create navigation_region
		var navigation_region = NavigationRegion3D.new()
		navigation_region.navigation_mesh = navigation_mesh
		var tmp_navigation_region_base_name = navigation_region_base_name + "%s"
		navigation_region.name = tmp_navigation_region_base_name % count
		add_child(navigation_region)
		if _is_editor:
			navigation_region.set_owner(get_tree().edited_scene_root)
		
		# Reparent chunk-child to navigation_region
		child.reparent(navigation_region)
		if _is_editor:
			child.set_owner(get_tree().edited_scene_root)
		
		# TODO: Check for water mesh and eliminate all vertexes below water level
		if _water_mesh_created:
			pass
		
		# BAKE!
		navigation_region.bake_navigation_mesh()
		
		# Reparent chunk-child to TerrainGenerator-node
		# -> Easier for later manipulation (just loop through children)
		child.reparent(self)
		if _is_editor:
			child.set_owner(get_tree().edited_scene_root)
		
		# For naming in scene tree
		count += 1
	
	navigation_regions_generated.emit()
	_stop_timer()
	
	create_navigation_region = false


func _delete_navigation_regions():
	for child in get_children():
		# Filter for navigation_region-objects
		if !child.name.begins_with(navigation_region_base_name):
			continue
		child.free()


@warning_ignore("unused_parameter")
func _create_water_mesh(new_value: bool = false) -> void:
	print("Creating water mesh..")
	_start_timer()
	
	_delete_water_meshes()
	
	# Basically a huge plain mesh with at water shader
	# Needs to look through the chunks and find a good base water level
	# If navigation is already created -> recreate the navigation meshes
	
	water_mesh_generated.emit()
	_stop_timer()
	
	_water_mesh_created = true
	
	create_water_mesh = false


func _delete_water_meshes():
	for child in get_children():
		# Filter for water_mesh-objects
		if !child.name.begins_with(water_mesh_base_name):
			continue
		child.free()
	
	_water_mesh_created = false


@warning_ignore("unused_parameter")
func _generate_new_seed(new_value: bool = false) -> void:
	_instance_noise_lite()
	noise_seed = RandomNumberGenerator.new().randi()
	
	if generate_terrain_on_new_seed:
		_create_new_terrain()
	
	generate_new_seed = false


func _apply_noise_seed(new_value: int) -> void:
	noise_seed = new_value
	_instance_noise_lite()
	_fast_noise_lite.seed = noise_seed
	
	if d_print_values: print("New Seed: %s" % noise_seed)


func _instance_noise_lite() -> void:
	if !_fast_noise_lite:
		_fast_noise_lite = FastNoiseLite.new()


func _setup_noise_lite() -> void:
	_instance_noise_lite()
	_fast_noise_lite.frequency = noise_frequency
	_fast_noise_lite.noise_type = noise_type


@warning_ignore("unused_parameter")
func _process(delta) -> void:
	pass


func _delete_all() -> void:
	for child in get_children():
		child.free()


func _generate_terrain() -> void:
	_instance_noise_lite()
	_setup_noise_lite()
	
	@warning_ignore("integer_division")
	var x_chunk_amount: int = terrain_x_size / chunk_size
	@warning_ignore("integer_division")
	var z_chunk_amount: int = terrain_z_size / chunk_size
	var amount_chunks: int = x_chunk_amount * z_chunk_amount
	@warning_ignore("integer_division")
	if d_print_values: print("Generating %s chunks in a %sx%s grid." %
		 [amount_chunks, z_chunk_amount, x_chunk_amount])
	
	@warning_ignore("integer_division")
	for chunk_z in z_chunk_amount:
		# ! ALL POSITIONS (CHUNKS INCLUDED) GET SET IN THE VERTICES !
		for chunk_x in x_chunk_amount:
			_generate_chunk(Vector2(chunk_x, chunk_z))


func _update_shader(mesh_instance: MeshInstance3D) -> void:
	if get_child_count() <= 0:
		return
	
	mesh_instance.material_override = shader_material
	# TODO: Test automatic setting of rock_height, etc.
	# var mat = mesh_instance.get_active_material(0)


func _generate_chunk(chunk_position: Vector2) -> void:
	var chunk = MeshInstance3D.new()
	var a_mesh = ArrayMesh.new()
	var surface_tool = SurfaceTool.new()
	
	var chunk_start_z = chunk_position.y * chunk_size * terrain_unit_size
	var chunk_max_z = chunk_start_z + chunk_size * terrain_unit_size
	var chunk_start_x = chunk_position.x * chunk_size * terrain_unit_size
	var chunk_max_x = chunk_start_x + chunk_size * terrain_unit_size
	
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for z in range(chunk_start_z, chunk_max_z + 1, terrain_unit_size):
		# TERRAIN RESOLUTION EXPLANATION
		# Steps for res: 1
		# z
		# Steps for res: 2
		# z, z + 0.5
		# Steps for res: 4
		# z, z + 0.25, z + 0.5, z + 0.75
		var z_float: float = z * 1.0
		while z_float < (z + 1) * 1.0:
			if z_float > chunk_max_z:
				break # Break out to avoid drawing too far in z direction
			for x in range(chunk_start_x, chunk_max_x + 1, terrain_unit_size):
				var x_float: float = x * 1.0
				while x_float < (x + 1) * 1.0:
					if x_float > chunk_max_x:
						break # Break out to avoid drawing too far in x direction
					
					var y: float = _fast_noise_lite \
						.get_noise_2d( \
							(x_float / terrain_unit_size) * noise_offset, \
							(z_float / terrain_unit_size) * noise_offset \
						) * noise_height_modifier
					
					y = _sample_heightmap(x_float, y, z_float)
					y = _ease_towards_max_terrain_height(y)
					y = _ease_towards_edge(x_float, y, z_float)
					
					var uv = Vector2()
					uv.x = inverse_lerp(chunk_start_x, chunk_max_x, x_float)
					uv.y = inverse_lerp(chunk_start_z, chunk_max_z, z_float)
					
					surface_tool.set_uv(uv)
					if d_print_granular_values: print("UV at %s" % uv)
					
					var x_vertex: float = x_float
					var z_vertex: float = z_float
					if center_terrain:
						x_vertex -= terrain_x_size * terrain_unit_size * CENTER_OFFSET
						z_vertex -= terrain_z_size * terrain_unit_size * CENTER_OFFSET
					
					var vertex = Vector3(x_vertex, y, z_vertex)
					surface_tool.add_vertex(vertex)
					if d_print_granular_values: print("Vertex at %s" % vertex)
					x_float += 1.0 / (terrain_resolution * 1.0)
#				while x_float < (x + 1) * 1.0:
			z_float += 1.0 / (terrain_resolution * 1.0)
#			for x in range(chunk_start_x, chunk_max_x + 1):
#		while z_float < (z + 1) * 1.0:
#	for z in range(chunk_start_z, chunk_max_z + 1):
	
#	INDEX EXPLANATION
#	Vertices with terrain resolution
#	index starts at 1 for these examples
#	normal ==  new
#	0---1  ==  1-2-3-4
#	| / |  ==  5-6-7-8
#	| / |  ==  10-11-12-13
#   2---3  ==  14-15-16-17
#	1-2-5, 5,2,6
#	2-3-6, 6,3,7
	var vert = 0
	for z in (chunk_size * terrain_resolution):
		for x in (chunk_size * terrain_resolution):
			surface_tool.add_index(vert + 0)
			surface_tool.add_index(vert + 1)
			surface_tool.add_index(vert + (chunk_size * terrain_resolution) + 1)
			surface_tool.add_index(vert + (chunk_size * terrain_resolution) + 1)
			surface_tool.add_index(vert + 1)
			surface_tool.add_index(vert + (chunk_size * terrain_resolution) + 2)
			vert += 1
		vert += 1
	
	surface_tool.generate_normals()
	a_mesh = surface_tool.commit()
	
	chunk.mesh = a_mesh
	var tmp_chunk_base_name = chunk_base_name + "%s"
	var chunk_name = tmp_chunk_base_name % (chunk_position * chunk_size)
	chunk.name = chunk_name
	
	add_child(chunk)
	if _is_editor:
		chunk.set_owner(get_tree().edited_scene_root)
	_update_shader(chunk)


func _sample_heightmap(x: float, y: float, z: float) -> float:
	if sample_heightmap:
		# HEIGHTMAP SAMPLING EXPLANATION
		# |----------------------| Width/Height terrain
		# |--------- | Width/Height heightmap
		# |----------------x-----| X on Width/Height chunk
		# X / Width/Height terrain -> progress in percent
		var heightmap_y = 0
		var heightmap_percent_z = z / (terrain_z_size * terrain_unit_size * 1.0)
		var heightmap_percent_x = x / (terrain_x_size * terrain_unit_size * 1.0)
		# clamp with (max - 1) to avoid index too high error
		# -> small inacuracies but not enough to fix completely
		var heightmap_z = clamp( \
			heightmap_percent_z * heightmap_tex.get_height(), \
			0, \
			heightmap_tex.get_height() - 1)
		var heightmap_x = clamp( \
			heightmap_percent_x * heightmap_tex.get_width(), \
			0, \
			heightmap_tex.get_width() - 1)
		var heightmap_color = heightmap_tex \
			.get_image() \
			.get_pixel( \
				heightmap_x, \
				heightmap_z)
		# White equals r=1, b=1, g=1
		# Add all three together and divide by 3 to get the average
		heightmap_y = (heightmap_color.r + heightmap_color.g + heightmap_color.b) / 3.0
		if d_print_granular_values: print("Y-Value in Heightmap: %s" % heightmap_y)
		# Project the heightmap on the terrain
		y += heightmap_y * heightmap_modifier
	
	return y


func _ease_towards_max_terrain_height(y: float) -> float:
	if d_ignore_max_terrain_height:
		return y
	
	if ease_towards_max_terrain_height:
		var percentage: float = abs(y) / max_terrain_height
		var ease_value: float = easing_curve_max_terrain_height.sample(percentage)
		var y_sign: float = 1.0 if y >= 0.0 else -1.0
		y = max_terrain_height * ease_value * y_sign
	else:
		if y > max_terrain_height:
			y = max_terrain_height
	
	return y


func _ease_towards_edge(x: float, y: float, z: float) -> float:
	if !ease_towards_edge:
		return y
	if y <= 0:
		return y
	
	# TODO: Move calculation of middle, mid_point_ & distance_to_middle
	# outside of this function
	var middle: Vector3 = Vector3(
		terrain_x_size * terrain_unit_size / 2.0, \
		0, \
		terrain_z_size * terrain_unit_size / 2.0)
	
	var mid_point_on_short_side: Vector3 = Vector3(0, 0, terrain_z_size * terrain_unit_size / 2.0)
	if terrain_x_size < terrain_z_size:
		mid_point_on_short_side = Vector3(terrain_x_size * terrain_unit_size / 2.0, 0, 0)
	
	var distance_to_middle: float = middle.distance_to(mid_point_on_short_side)
	var point_on_mesh: Vector3 = Vector3(x, 0, z)
	var distance_point_to_middle: float = middle.distance_to(point_on_mesh)
	var curve_offset: float = clampf((distance_point_to_middle / distance_to_middle), 0.0, 1.0)
	
	var value_on_curve: float = easing_curve_edge.sample(curve_offset)
	
	y *= value_on_curve
	
	return y


func _start_timer() -> void:
	_start_time = Time.get_ticks_msec()


func _stop_timer() -> void:
	_stop_time = Time.get_ticks_msec()
	var time_diff = _stop_time - _start_time
	print("Elapsed time in seconds: %s" % (time_diff / 1000.0))
