class_name OfflineSynchronizer
extends MultiplayerSynchronizer

func _ready() -> void:
	assert(get_node(root_path) == owner, "Offline synchronizer `root_path` should 
	be pointing to the root of the scene.")

func get_properties_path() -> Array[NodePath]:
	return replication_config.get_properties()

func get_property(property_path: NodePath) -> Variant:
	var node_res: Array = owner.get_node_and_resource(property_path)
	assert(node_res[0], "Probably trying to synchronize `%s` which is a property 
	that doesn't exist, check that `OfflineSynchronizer` doesn't point to this property." % property_path)
	var node: Node = node_res[0]
	var p_path: NodePath = node_res[2]
	return node.get_indexed(p_path)
	
func set_property(property_path: NodePath, value: Variant) -> void:
	var node_res: Array = owner.get_node_and_resource(property_path)
	var node: Node = node_res[0]
	var p_path: NodePath = node_res[2]
	node.set_indexed(p_path, value)

func get_property_name(property_path: NodePath) -> StringName:
	return property_path.get_subname(property_path.get_subname_count()-1)
