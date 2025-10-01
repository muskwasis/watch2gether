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
		
		var hand_mesh = OpenXRFbHandTrackingMesh.new()
		hand_mesh.name = "OpenXRFbHandTrackingMesh"
		hand_mesh.hand = 0 if hand == "left" else 1
		hand_tracker.add_child(hand_mesh)
		
		var hand_modifier = XRHandModifier3D.new()
		hand_modifier.hand_tracker = "/user/hand_tracker/" + hand
		hand_mesh.add_child(hand_modifier)
		
		# Add physics capsules to fingertips
		setup_fingertip_colliders(hand_mesh, hand)

func setup_fingertip_colliders(hand_mesh: Node3D, hand: String):
	# Get the skeleton from the hand mesh
	var skeleton = hand_mesh.get_node_or_null("Skeleton3D")
	if not skeleton:
		print("Warning: No skeleton found in hand mesh for " + hand + " hand")
		return
	
	# Fingertip bone names in OpenXR hand skeleton
	var fingertip_bones = [
		"Thumb_Tip",
		"Index_Tip", 
		"Middle_Tip",
		"Ring_Tip",
		"Little_Tip"
	]
	
	for bone_name in fingertip_bones:
		var bone_idx = skeleton.find_bone(bone_name)
		if bone_idx == -1:
			print("Warning: Bone " + bone_name + " not found in skeleton")
			continue
		
		# Create bone attachment
		var bone_attachment = BoneAttachment3D.new()
		bone_attachment.bone_name = bone_name
		bone_attachment.name = bone_name + "_Attachment"
		skeleton.add_child(bone_attachment)
		
		# Create physics body
		var area = Area3D.new()
		area.name = bone_name + "_Area"
		bone_attachment.add_child(area)
		
		# Create capsule collision shape
		var collision_shape = CollisionShape3D.new()
		var capsule = CapsuleShape3D.new()
		capsule.radius = 0.01  # 1cm radius
		capsule.height = 0.03  # 3cm height
		collision_shape.shape = capsule
		area.add_child(collision_shape)
		
		# Optional: Add visual representation for debugging
		# create_debug_visual(area, capsule)
	
	print("Added fingertip colliders for " + hand + " hand")
