class_name HandTrackingManager
extends Node3D

func setup():
	for hand in ["left", "right"]:
		# Create hand tracker
		var hand_tracker = XRNode3D.new()
		hand_tracker.name = hand.capitalize() + "HandTracker"
		hand_tracker.tracker = "/user/hand_tracker/" + hand
		hand_tracker.show_when_tracked = true
		add_child(hand_tracker)
		
		# Try to use Meta's hand mesh first
		var meta_mesh_available = setup_meta_hand_mesh(hand_tracker, hand)
		
		# Fallback to simple hand mesh if Meta mesh not available
		if not meta_mesh_available:
			setup_fallback_hand_mesh(hand_tracker, hand)
	
	print("Hand tracking setup complete!")

func setup_meta_hand_mesh(hand_tracker: XRNode3D, hand: String) -> bool:
	# Check if Meta hand tracking mesh is available
	if not ClassDB.class_exists("OpenXRFbHandTrackingMesh"):
		print("Meta hand tracking mesh not available, using fallback")
		return false
	
	# Add Meta's hand tracking mesh
	var hand_mesh = OpenXRFbHandTrackingMesh.new()
	hand_mesh.name = "OpenXRFbHandTrackingMesh"
	hand_mesh.hand = 0 if hand == "left" else 1
	hand_tracker.add_child(hand_mesh)
	
	# Add hand modifier as a child of the hand mesh
	var hand_modifier = XRHandModifier3D.new()
	hand_modifier.hand_tracker = "/user/hand_tracker/" + hand
	hand_mesh.add_child(hand_modifier)
	
	print("Using Meta hand mesh for " + hand + " hand")
	return true

func setup_fallback_hand_mesh(hand_tracker: XRNode3D, hand: String):
	# Create a simple hand mesh with skeleton
	var skeleton = Skeleton3D.new()
	skeleton.name = "Skeleton3D"
	hand_tracker.add_child(skeleton)
	
	# Create bones for the hand (simplified structure)
	# XR_HAND_JOINT order: Palm, Wrist, Thumb (4), Index (5), Middle (5), Ring (5), Pinky (5)
	var bone_names = [
		"Palm", "Wrist",
		"Thumb_Metacarpal", "Thumb_Proximal", "Thumb_Distal", "Thumb_Tip",
		"Index_Metacarpal", "Index_Proximal", "Index_Intermediate", "Index_Distal", "Index_Tip",
		"Middle_Metacarpal", "Middle_Proximal", "Middle_Intermediate", "Middle_Distal", "Middle_Tip",
		"Ring_Metacarpal", "Ring_Proximal", "Ring_Intermediate", "Ring_Distal", "Ring_Tip",
		"Little_Metacarpal", "Little_Proximal", "Little_Intermediate", "Little_Distal", "Little_Tip"
	]
	
	for bone_name in bone_names:
		skeleton.add_bone(bone_name)
	
	# Create simple visual representation
	create_simple_hand_visual(skeleton, hand)
	
	# Add hand modifier to drive the skeleton
	var hand_modifier = XRHandModifier3D.new()
	hand_modifier.hand_tracker = "/user/hand_tracker/" + hand
	hand_modifier.target = skeleton.get_path()
	hand_tracker.add_child(hand_modifier)
	
	print("Using fallback hand mesh for " + hand + " hand")

func create_simple_hand_visual(skeleton: Skeleton3D, hand: String):
	# Create a simple mesh instance with spheres for joints
	var multi_mesh_instance = MultiMeshInstance3D.new()
	multi_mesh_instance.name = "HandVisual"
	
	var multi_mesh = MultiMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.instance_count = skeleton.get_bone_count()
	
	# Create a simple sphere mesh for joints
	var sphere = SphereMesh.new()
	sphere.radius = 0.01
	sphere.height = 0.02
	multi_mesh.mesh = sphere
	
	# Create a simple material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.6, 0.5)  # Skin tone
	material.roughness = 0.7
	sphere.material = material
	
	multi_mesh_instance.multimesh = multi_mesh
	skeleton.add_child(multi_mesh_instance)
	
	# Position spheres at bone locations (will be updated by XRHandModifier3D)
	for i in skeleton.get_bone_count():
		multi_mesh.set_instance_transform(i, Transform3D())
