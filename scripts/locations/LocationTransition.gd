extends Node
## Utility script for handling location transitions
## Handles player movement between different game locations


## Transition to a new location
## [code]location_path[/code] - Path to the location scene to transition to
func transition_to(location_path: String) -> void:
	var scene_loader = Node.new()
	add_child(scene_loader)
	# TODO: Implement actual scene transition logic
	scene_loader.queue_free()


## Get the current location the player is in
func get_current_location() -> Node:
	var locations = get_tree().get_nodes_in_group("location")
	if not locations.is_empty():
		return locations[0]
	return null


## Check if player can transition to a specific location
func can_transition_to(location_path: String) -> bool:
	# TODO: Implement transition permission logic
	return true
