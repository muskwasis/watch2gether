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
		
		for joint_name in ["thumb_tip", "index_tip", "middle_tip", "ring_tip", "pinky_tip"]:
			var node := hand_modifier.get_node(joint_name)
			if node:
				add_fingertip_capsule(node)

func add_fingertip_capsule(xr_hand):
	# Common fingertip joint names from XRHandModifier3D
	var tip_names = ["thumb_tip", "index_tip", "middle_tip", "ring_tip", "pinky_tip"]
	for joint_name in tip_names:
		var joint_node: Node3D = xr_hand.get_node(joint_name)
		if joint_node:
			var body := AnimatableBody3D.new()

			var col := CollisionShape3D.new()
			var shape := CapsuleShape3D.new()
			shape.radius = 0.012   # ~1.2 cm
			shape.height = 0.025   # ~2.5 cm
			col.shape = shape
			body.add_child(col)

			# Attach the capsule directly under the fingertip node
			joint_node.add_child(body)
