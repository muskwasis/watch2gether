class_name HandTrackingManager
extends XROrigin3D

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
