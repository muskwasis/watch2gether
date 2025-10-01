extends Node3D

var xr_interface: XRInterface
var fb_capsule_ext

func _ready():
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print("OpenXR initialized successfully")
		# Turn off v-sync!
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		# Change our main viewport to output to the HMD
		get_viewport().use_xr = true
		create_hand_trackers()
		# place_capsules()
	await get_tree().create_timer(3.0).timeout
	create_ground_plane()
	spawn_cubes()
	
# Configuration variables
@export var cube_count: int = 1022
@export var spawn_area_size: Vector3 = Vector3(0.5, 5, 0.5)
@export var spawn_height: float = 10.0
@export var cube_size: Vector3 = Vector3(.1, .1, .1)
@export var cube_material: StandardMaterial3D
@export var ground_size: Vector2 = Vector2(8, 8)

func create_hand_trackers():
	for hand in ["left", "right"]:
		# Create hand tracker
		var hand_tracker = XRNode3D.new()
		hand_tracker.name = hand.capitalize() + "HandTracker"
		hand_tracker.tracker = "/user/hand_tracker/" + hand
		hand_tracker.show_when_tracked = true
		add_child(hand_tracker)
		
		# this like, works
		var hand_mesh = OpenXRFbHandTrackingMesh.new()
		hand_mesh.name = "OpenXRFbHandTrackingMesh"
		hand_mesh.hand = 0 if hand == "left" else 1
		hand_tracker.add_child(hand_mesh)
		
		var hand_modifier = XRHandModifier3D.new()
		hand_modifier.hand_tracker = "/user/hand_tracker/" + hand
		hand_mesh.add_child(hand_modifier)
		
func create_ground_plane():
	# Create StaticBody3D for the ground
	var static_body = StaticBody3D.new()
	static_body.name = "Ground"
	static_body.position = Vector3.ZERO
	
	# Create MeshInstance3D for visual representation
	var mesh_instance = MeshInstance3D.new()
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = ground_size
	mesh_instance.mesh = plane_mesh
	
	# Create ground material
	var ground_material = StandardMaterial3D.new()
	ground_material.albedo_color = Color(0.4, 0.6, 0.3, 1.0)  # Green ground
	ground_material.roughness = 0.8
	mesh_instance.material_override = ground_material
	
	# Create CollisionShape3D for physics
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(ground_size.x, 0.1, ground_size.y)  # Thin box for ground collision
	collision_shape.shape = box_shape
	collision_shape.position.y = -0.05  # Offset slightly down so surface is at y=0
	
	# Add components to static body
	static_body.add_child(mesh_instance)
	static_body.add_child(collision_shape)
	
	# Add static body to scene
	add_child(static_body)

func spawn_cubes():
	for i in range(cube_count):
		create_cube(i)

func create_cube(index: int):
	# Create RigidBody3D
	var rigid_body = RigidBody3D.new()
	rigid_body.name = "Cube_" + str(index)
	
	# Set random position within spawn area
	var random_pos = Vector3(
		randf_range(-spawn_area_size.x / 2, spawn_area_size.x / 2),
		spawn_height + randf_range(0, spawn_area_size.y),
		randf_range(-spawn_area_size.z / 2, spawn_area_size.z / 2)
	)
	rigid_body.position = random_pos
	
	# Add random rotation
	rigid_body.rotation = Vector3(
		randf_range(0, PI),
		randf_range(0, PI),
		randf_range(0, PI)
	)
	
	# Create MeshInstance3D for visual representation
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = cube_size
	mesh_instance.mesh = box_mesh
	
	# Apply material if provided
	if cube_material:
		mesh_instance.material_override = cube_material
	else:
		# Create a simple material with random color
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(randf(), randf(), randf(), 1.0)
		mesh_instance.material_override = material
	
	# Create CollisionShape3D for physics
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = cube_size
	collision_shape.shape = box_shape
	
	# Add components to rigid body
	rigid_body.add_child(mesh_instance)
	rigid_body.add_child(collision_shape)
	
	# Add some random initial velocity for more interesting physics
	rigid_body.linear_velocity = Vector3(
		randf_range(-2, 2),
		randf_range(-1, 1),
		randf_range(-2, 2)
	)
	
	# Add angular velocity for spinning
	rigid_body.angular_velocity = Vector3(
		randf_range(-3, 3),
		randf_range(-3, 3),
		randf_range(-3, 3)
	)
	
	# Add rigid body to scene
	add_child(rigid_body)

# Optional: Function to spawn more cubes during runtime
func spawn_additional_cubes(count: int):
	for i in range(count):
		create_cube(get_child_count() + i)

# Optional: Clear all spawned cubes
func clear_cubes():
	for child in get_children():
		if child is RigidBody3D:
			child.queue_free()
			

@export var hand_tracking_mesh: Node3D
func place_capsules():
	var skeleton = find_child("*", true, false) as Skeleton3D
	if not skeleton:
		skeleton = hand_tracking_mesh.find_child("*", true, false) as Skeleton3D
	for tip in ["Thumb_Tip", "Index_Tip", "Middle_Tip", "Ring_Tip", "Little_Tip"]:
		var bone_idx = skeleton.find_bone(tip)
		if bone_idx == -1:
			continue
			
		var attachment = BoneAttachment3D.new()
		attachment.bone_idx = bone_idx
		skeleton.add_child(attachment)
		
		var capsule = MeshInstance3D.new()
		var mesh = CapsuleMesh.new()
		mesh.radius = 0.008
		mesh.height = 0.016
		capsule.mesh = mesh
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color.CYAN
		material.flags_transparent = true
		material.albedo_color.a = 0.7
		capsule.material_override = material
		
		var area = Area3D.new()
		var shape = CollisionShape3D.new()
		var capsule_shape = CapsuleShape3D.new()
		capsule_shape.radius = 0.008
		capsule_shape.height = 0.016
		shape.shape = capsule_shape
		
		attachment.add_child(capsule)
		capsule.add_child(area)
		area.add_child(shape)
# print fps to the console
const TIMER_LIMIT = 2.0
var timer = 1.0
func _process(delta):
	timer += delta
	if timer > TIMER_LIMIT: # Prints every 2 seconds
		timer = 0.0
		print("fps: " + str(Engine.get_frames_per_second()))
